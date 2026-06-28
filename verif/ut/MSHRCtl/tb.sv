// 自动生成 scripts/gen_mshrctl.py —— 勿手改
// MSHRCtl 双例化逐拍比对: golden MSHRCtl vs 可读重写 MSHRCtl_xs。
// 子 MSHR/仲裁器为两侧共享的 golden 黑盒, 故比对聚焦控制阵列 glue + 路由/仲裁互联。
`timescale 1ns/1ps
`define CHK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic io_fromMainPipe_mshr_alloc_s3_valid;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit;
  logic [30:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag;
  logic [8:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set;
  logic [2:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty;
  logic [1:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients;
  logic [1:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch;
  logic [2:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr;
  logic io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_release;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack;
  logic io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct;
  logic [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_channel;
  logic [8:0] io_fromMainPipe_mshr_alloc_s3_bits_task_set;
  logic [30:0] io_fromMainPipe_mshr_alloc_s3_bits_task_tag;
  logic [5:0] io_fromMainPipe_mshr_alloc_s3_bits_task_off;
  logic [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_alias;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword;
  logic [3:0] io_fromMainPipe_mshr_alloc_s3_bits_task_opcode;
  logic [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_param;
  logic [6:0] io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft;
  logic [4:0] io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData;
  logic [7:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] io_fromMainPipe_mshr_alloc_s3_bits_task_srcID;
  logic [11:0] io_fromMainPipe_mshr_alloc_s3_bits_task_txnID;
  logic [10:0] io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID;
  logic [11:0] io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID;
  logic [6:0] io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag;
  logic io_mshrTask_ready;
  logic io_pipeStatusVec_0_valid;
  logic io_pipeStatusVec_1_valid;
  logic io_toTXREQ_ready;
  logic io_toTXRSP_ready;
  logic io_toSourceB_ready;
  logic io_grantStatus_0_valid;
  logic [8:0] io_grantStatus_0_set;
  logic [30:0] io_grantStatus_0_tag;
  logic io_grantStatus_1_valid;
  logic [8:0] io_grantStatus_1_set;
  logic [30:0] io_grantStatus_1_tag;
  logic io_grantStatus_2_valid;
  logic [8:0] io_grantStatus_2_set;
  logic [30:0] io_grantStatus_2_tag;
  logic io_grantStatus_3_valid;
  logic [8:0] io_grantStatus_3_set;
  logic [30:0] io_grantStatus_3_tag;
  logic io_grantStatus_4_valid;
  logic [8:0] io_grantStatus_4_set;
  logic [30:0] io_grantStatus_4_tag;
  logic io_grantStatus_5_valid;
  logic [8:0] io_grantStatus_5_set;
  logic [30:0] io_grantStatus_5_tag;
  logic io_grantStatus_6_valid;
  logic [8:0] io_grantStatus_6_set;
  logic [30:0] io_grantStatus_6_tag;
  logic io_grantStatus_7_valid;
  logic [8:0] io_grantStatus_7_set;
  logic [30:0] io_grantStatus_7_tag;
  logic io_grantStatus_8_valid;
  logic [8:0] io_grantStatus_8_set;
  logic [30:0] io_grantStatus_8_tag;
  logic io_grantStatus_9_valid;
  logic [8:0] io_grantStatus_9_set;
  logic [30:0] io_grantStatus_9_tag;
  logic io_grantStatus_10_valid;
  logic [8:0] io_grantStatus_10_set;
  logic [30:0] io_grantStatus_10_tag;
  logic io_grantStatus_11_valid;
  logic [8:0] io_grantStatus_11_set;
  logic [30:0] io_grantStatus_11_tag;
  logic io_grantStatus_12_valid;
  logic [8:0] io_grantStatus_12_set;
  logic [30:0] io_grantStatus_12_tag;
  logic io_grantStatus_13_valid;
  logic [8:0] io_grantStatus_13_set;
  logic [30:0] io_grantStatus_13_tag;
  logic io_grantStatus_14_valid;
  logic [8:0] io_grantStatus_14_set;
  logic [30:0] io_grantStatus_14_tag;
  logic io_grantStatus_15_valid;
  logic [8:0] io_grantStatus_15_set;
  logic [30:0] io_grantStatus_15_tag;
  logic io_resps_sinkC_valid;
  logic [8:0] io_resps_sinkC_set;
  logic [30:0] io_resps_sinkC_tag;
  logic [2:0] io_resps_sinkC_respInfo_opcode;
  logic [2:0] io_resps_sinkC_respInfo_param;
  logic io_resps_sinkC_respInfo_last;
  logic io_resps_sinkC_respInfo_denied;
  logic io_resps_sinkC_respInfo_corrupt;
  logic io_resps_rxrsp_valid;
  logic [7:0] io_resps_rxrsp_mshrId;
  logic [6:0] io_resps_rxrsp_respInfo_chiOpcode;
  logic [10:0] io_resps_rxrsp_respInfo_srcID;
  logic [11:0] io_resps_rxrsp_respInfo_dbID;
  logic [2:0] io_resps_rxrsp_respInfo_resp;
  logic [3:0] io_resps_rxrsp_respInfo_pCrdType;
  logic [1:0] io_resps_rxrsp_respInfo_respErr;
  logic io_resps_rxrsp_respInfo_traceTag;
  logic io_resps_rxdat_valid;
  logic [7:0] io_resps_rxdat_mshrId;
  logic io_resps_rxdat_respInfo_last;
  logic io_resps_rxdat_respInfo_corrupt;
  logic [6:0] io_resps_rxdat_respInfo_chiOpcode;
  logic [10:0] io_resps_rxdat_respInfo_homeNID;
  logic [11:0] io_resps_rxdat_respInfo_dbID;
  logic [2:0] io_resps_rxdat_respInfo_resp;
  logic [1:0] io_resps_rxdat_respInfo_respErr;
  logic io_resps_rxdat_respInfo_traceTag;
  logic io_resps_rxdat_respInfo_dataCheckErr;
  logic [8:0] io_nestedwb_set;
  logic [30:0] io_nestedwb_tag;
  logic io_nestedwb_c_set_dirty;
  logic io_nestedwb_c_set_tip;
  logic io_nestedwb_b_inv_dirty;
  logic io_nestedwb_b_toB;
  logic io_nestedwb_b_toN;
  logic io_nestedwb_b_toClean;
  logic io_aMergeTask_valid;
  logic [7:0] io_aMergeTask_bits_id;
  logic [5:0] io_aMergeTask_bits_task_off;
  logic [1:0] io_aMergeTask_bits_task_alias;
  logic [43:0] io_aMergeTask_bits_task_vaddr;
  logic io_aMergeTask_bits_task_isKeyword;
  logic [3:0] io_aMergeTask_bits_task_opcode;
  logic [2:0] io_aMergeTask_bits_task_param;
  logic [6:0] io_aMergeTask_bits_task_sourceId;
  logic io_replResp_valid;
  logic [30:0] io_replResp_bits_tag;
  logic [2:0] io_replResp_bits_way;
  logic io_replResp_bits_meta_dirty;
  logic [1:0] io_replResp_bits_meta_state;
  logic io_replResp_bits_meta_clients;
  logic [1:0] io_replResp_bits_meta_alias;
  logic io_replResp_bits_meta_prefetch;
  logic [2:0] io_replResp_bits_meta_prefetchSrc;
  logic io_replResp_bits_meta_accessed;
  logic io_replResp_bits_meta_tagErr;
  logic io_replResp_bits_meta_dataErr;
  logic [7:0] io_replResp_bits_mshrId;
  logic io_replResp_bits_retry;
  logic io_pCrd_0_grant;
  logic io_pCrd_1_grant;
  logic io_pCrd_2_grant;
  logic io_pCrd_3_grant;
  logic io_pCrd_4_grant;
  logic io_pCrd_5_grant;
  logic io_pCrd_6_grant;
  logic io_pCrd_7_grant;
  logic io_pCrd_8_grant;
  logic io_pCrd_9_grant;
  logic io_pCrd_10_grant;
  logic io_pCrd_11_grant;
  logic io_pCrd_12_grant;
  logic io_pCrd_13_grant;
  logic io_pCrd_14_grant;
  logic io_pCrd_15_grant;
  wire g_io_toReqArb_blockA_s1;
  wire i_io_toReqArb_blockA_s1;
  wire g_io_toReqArb_blockB_s1;
  wire i_io_toReqArb_blockB_s1;
  wire [7:0] g_io_toMainPipe_mshr_alloc_ptr;
  wire [7:0] i_io_toMainPipe_mshr_alloc_ptr;
  wire g_io_mshrTask_valid;
  wire i_io_mshrTask_valid;
  wire [2:0] g_io_mshrTask_bits_channel;
  wire [2:0] i_io_mshrTask_bits_channel;
  wire [2:0] g_io_mshrTask_bits_txChannel;
  wire [2:0] i_io_mshrTask_bits_txChannel;
  wire [8:0] g_io_mshrTask_bits_set;
  wire [8:0] i_io_mshrTask_bits_set;
  wire [30:0] g_io_mshrTask_bits_tag;
  wire [30:0] i_io_mshrTask_bits_tag;
  wire [5:0] g_io_mshrTask_bits_off;
  wire [5:0] i_io_mshrTask_bits_off;
  wire [1:0] g_io_mshrTask_bits_alias;
  wire [1:0] i_io_mshrTask_bits_alias;
  wire g_io_mshrTask_bits_isKeyword;
  wire i_io_mshrTask_bits_isKeyword;
  wire [3:0] g_io_mshrTask_bits_opcode;
  wire [3:0] i_io_mshrTask_bits_opcode;
  wire [2:0] g_io_mshrTask_bits_param;
  wire [2:0] i_io_mshrTask_bits_param;
  wire [2:0] g_io_mshrTask_bits_size;
  wire [2:0] i_io_mshrTask_bits_size;
  wire [6:0] g_io_mshrTask_bits_sourceId;
  wire [6:0] i_io_mshrTask_bits_sourceId;
  wire g_io_mshrTask_bits_denied;
  wire i_io_mshrTask_bits_denied;
  wire g_io_mshrTask_bits_corrupt;
  wire i_io_mshrTask_bits_corrupt;
  wire g_io_mshrTask_bits_mshrTask;
  wire i_io_mshrTask_bits_mshrTask;
  wire [7:0] g_io_mshrTask_bits_mshrId;
  wire [7:0] i_io_mshrTask_bits_mshrId;
  wire g_io_mshrTask_bits_aliasTask;
  wire i_io_mshrTask_bits_aliasTask;
  wire g_io_mshrTask_bits_useProbeData;
  wire i_io_mshrTask_bits_useProbeData;
  wire g_io_mshrTask_bits_mshrRetry;
  wire i_io_mshrTask_bits_mshrRetry;
  wire g_io_mshrTask_bits_readProbeDataDown;
  wire i_io_mshrTask_bits_readProbeDataDown;
  wire g_io_mshrTask_bits_fromL2pft;
  wire i_io_mshrTask_bits_fromL2pft;
  wire g_io_mshrTask_bits_dirty;
  wire i_io_mshrTask_bits_dirty;
  wire [2:0] g_io_mshrTask_bits_way;
  wire [2:0] i_io_mshrTask_bits_way;
  wire g_io_mshrTask_bits_meta_dirty;
  wire i_io_mshrTask_bits_meta_dirty;
  wire [1:0] g_io_mshrTask_bits_meta_state;
  wire [1:0] i_io_mshrTask_bits_meta_state;
  wire g_io_mshrTask_bits_meta_clients;
  wire i_io_mshrTask_bits_meta_clients;
  wire [1:0] g_io_mshrTask_bits_meta_alias;
  wire [1:0] i_io_mshrTask_bits_meta_alias;
  wire g_io_mshrTask_bits_meta_prefetch;
  wire i_io_mshrTask_bits_meta_prefetch;
  wire [2:0] g_io_mshrTask_bits_meta_prefetchSrc;
  wire [2:0] i_io_mshrTask_bits_meta_prefetchSrc;
  wire g_io_mshrTask_bits_meta_accessed;
  wire i_io_mshrTask_bits_meta_accessed;
  wire g_io_mshrTask_bits_meta_tagErr;
  wire i_io_mshrTask_bits_meta_tagErr;
  wire g_io_mshrTask_bits_meta_dataErr;
  wire i_io_mshrTask_bits_meta_dataErr;
  wire g_io_mshrTask_bits_metaWen;
  wire i_io_mshrTask_bits_metaWen;
  wire g_io_mshrTask_bits_tagWen;
  wire i_io_mshrTask_bits_tagWen;
  wire g_io_mshrTask_bits_dsWen;
  wire i_io_mshrTask_bits_dsWen;
  wire g_io_mshrTask_bits_replTask;
  wire i_io_mshrTask_bits_replTask;
  wire g_io_mshrTask_bits_cmoTask;
  wire i_io_mshrTask_bits_cmoTask;
  wire [4:0] g_io_mshrTask_bits_reqSource;
  wire [4:0] i_io_mshrTask_bits_reqSource;
  wire g_io_mshrTask_bits_mergeA;
  wire i_io_mshrTask_bits_mergeA;
  wire [5:0] g_io_mshrTask_bits_aMergeTask_off;
  wire [5:0] i_io_mshrTask_bits_aMergeTask_off;
  wire [1:0] g_io_mshrTask_bits_aMergeTask_alias;
  wire [1:0] i_io_mshrTask_bits_aMergeTask_alias;
  wire [43:0] g_io_mshrTask_bits_aMergeTask_vaddr;
  wire [43:0] i_io_mshrTask_bits_aMergeTask_vaddr;
  wire g_io_mshrTask_bits_aMergeTask_isKeyword;
  wire i_io_mshrTask_bits_aMergeTask_isKeyword;
  wire [2:0] g_io_mshrTask_bits_aMergeTask_opcode;
  wire [2:0] i_io_mshrTask_bits_aMergeTask_opcode;
  wire [2:0] g_io_mshrTask_bits_aMergeTask_param;
  wire [2:0] i_io_mshrTask_bits_aMergeTask_param;
  wire [6:0] g_io_mshrTask_bits_aMergeTask_sourceId;
  wire [6:0] i_io_mshrTask_bits_aMergeTask_sourceId;
  wire g_io_mshrTask_bits_aMergeTask_meta_dirty;
  wire i_io_mshrTask_bits_aMergeTask_meta_dirty;
  wire [1:0] g_io_mshrTask_bits_aMergeTask_meta_state;
  wire [1:0] i_io_mshrTask_bits_aMergeTask_meta_state;
  wire g_io_mshrTask_bits_aMergeTask_meta_clients;
  wire i_io_mshrTask_bits_aMergeTask_meta_clients;
  wire [1:0] g_io_mshrTask_bits_aMergeTask_meta_alias;
  wire [1:0] i_io_mshrTask_bits_aMergeTask_meta_alias;
  wire g_io_mshrTask_bits_aMergeTask_meta_accessed;
  wire i_io_mshrTask_bits_aMergeTask_meta_accessed;
  wire g_io_mshrTask_bits_snpHitRelease;
  wire i_io_mshrTask_bits_snpHitRelease;
  wire g_io_mshrTask_bits_snpHitReleaseToInval;
  wire i_io_mshrTask_bits_snpHitReleaseToInval;
  wire g_io_mshrTask_bits_snpHitReleaseToClean;
  wire i_io_mshrTask_bits_snpHitReleaseToClean;
  wire g_io_mshrTask_bits_snpHitReleaseWithData;
  wire i_io_mshrTask_bits_snpHitReleaseWithData;
  wire [7:0] g_io_mshrTask_bits_snpHitReleaseIdx;
  wire [7:0] i_io_mshrTask_bits_snpHitReleaseIdx;
  wire g_io_mshrTask_bits_snpHitReleaseMeta_dirty;
  wire i_io_mshrTask_bits_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_mshrTask_bits_snpHitReleaseMeta_state;
  wire [1:0] i_io_mshrTask_bits_snpHitReleaseMeta_state;
  wire g_io_mshrTask_bits_snpHitReleaseMeta_clients;
  wire i_io_mshrTask_bits_snpHitReleaseMeta_clients;
  wire [1:0] g_io_mshrTask_bits_snpHitReleaseMeta_alias;
  wire [1:0] i_io_mshrTask_bits_snpHitReleaseMeta_alias;
  wire g_io_mshrTask_bits_snpHitReleaseMeta_prefetch;
  wire i_io_mshrTask_bits_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
  wire g_io_mshrTask_bits_snpHitReleaseMeta_accessed;
  wire i_io_mshrTask_bits_snpHitReleaseMeta_accessed;
  wire g_io_mshrTask_bits_snpHitReleaseMeta_tagErr;
  wire i_io_mshrTask_bits_snpHitReleaseMeta_tagErr;
  wire g_io_mshrTask_bits_snpHitReleaseMeta_dataErr;
  wire i_io_mshrTask_bits_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_mshrTask_bits_tgtID;
  wire [10:0] i_io_mshrTask_bits_tgtID;
  wire [11:0] g_io_mshrTask_bits_txnID;
  wire [11:0] i_io_mshrTask_bits_txnID;
  wire [10:0] g_io_mshrTask_bits_homeNID;
  wire [10:0] i_io_mshrTask_bits_homeNID;
  wire [11:0] g_io_mshrTask_bits_dbID;
  wire [11:0] i_io_mshrTask_bits_dbID;
  wire [6:0] g_io_mshrTask_bits_chiOpcode;
  wire [6:0] i_io_mshrTask_bits_chiOpcode;
  wire [2:0] g_io_mshrTask_bits_resp;
  wire [2:0] i_io_mshrTask_bits_resp;
  wire [2:0] g_io_mshrTask_bits_fwdState;
  wire [2:0] i_io_mshrTask_bits_fwdState;
  wire g_io_mshrTask_bits_retToSrc;
  wire i_io_mshrTask_bits_retToSrc;
  wire g_io_mshrTask_bits_likelyshared;
  wire i_io_mshrTask_bits_likelyshared;
  wire g_io_mshrTask_bits_expCompAck;
  wire i_io_mshrTask_bits_expCompAck;
  wire g_io_mshrTask_bits_allowRetry;
  wire i_io_mshrTask_bits_allowRetry;
  wire g_io_mshrTask_bits_memAttr_allocate;
  wire i_io_mshrTask_bits_memAttr_allocate;
  wire g_io_mshrTask_bits_memAttr_cacheable;
  wire i_io_mshrTask_bits_memAttr_cacheable;
  wire g_io_mshrTask_bits_memAttr_ewa;
  wire i_io_mshrTask_bits_memAttr_ewa;
  wire g_io_mshrTask_bits_traceTag;
  wire i_io_mshrTask_bits_traceTag;
  wire g_io_mshrTask_bits_dataCheckErr;
  wire i_io_mshrTask_bits_dataCheckErr;
  wire g_io_toTXREQ_valid;
  wire i_io_toTXREQ_valid;
  wire [3:0] g_io_toTXREQ_bits_qos;
  wire [3:0] i_io_toTXREQ_bits_qos;
  wire [10:0] g_io_toTXREQ_bits_tgtID;
  wire [10:0] i_io_toTXREQ_bits_tgtID;
  wire [11:0] g_io_toTXREQ_bits_txnID;
  wire [11:0] i_io_toTXREQ_bits_txnID;
  wire [6:0] g_io_toTXREQ_bits_opcode;
  wire [6:0] i_io_toTXREQ_bits_opcode;
  wire [2:0] g_io_toTXREQ_bits_size;
  wire [2:0] i_io_toTXREQ_bits_size;
  wire [47:0] g_io_toTXREQ_bits_addr;
  wire [47:0] i_io_toTXREQ_bits_addr;
  wire g_io_toTXREQ_bits_likelyshared;
  wire i_io_toTXREQ_bits_likelyshared;
  wire g_io_toTXREQ_bits_allowRetry;
  wire i_io_toTXREQ_bits_allowRetry;
  wire [3:0] g_io_toTXREQ_bits_pCrdType;
  wire [3:0] i_io_toTXREQ_bits_pCrdType;
  wire g_io_toTXREQ_bits_memAttr_allocate;
  wire i_io_toTXREQ_bits_memAttr_allocate;
  wire g_io_toTXREQ_bits_memAttr_cacheable;
  wire i_io_toTXREQ_bits_memAttr_cacheable;
  wire g_io_toTXREQ_bits_memAttr_ewa;
  wire i_io_toTXREQ_bits_memAttr_ewa;
  wire g_io_toTXREQ_bits_snpAttr;
  wire i_io_toTXREQ_bits_snpAttr;
  wire g_io_toTXREQ_bits_expCompAck;
  wire i_io_toTXREQ_bits_expCompAck;
  wire g_io_toTXRSP_valid;
  wire i_io_toTXRSP_valid;
  wire [10:0] g_io_toTXRSP_bits_tgtID;
  wire [10:0] i_io_toTXRSP_bits_tgtID;
  wire [11:0] g_io_toTXRSP_bits_txnID;
  wire [11:0] i_io_toTXRSP_bits_txnID;
  wire [4:0] g_io_toTXRSP_bits_opcode;
  wire [4:0] i_io_toTXRSP_bits_opcode;
  wire g_io_toTXRSP_bits_traceTag;
  wire i_io_toTXRSP_bits_traceTag;
  wire g_io_toSourceB_valid;
  wire i_io_toSourceB_valid;
  wire [2:0] g_io_toSourceB_bits_opcode;
  wire [2:0] i_io_toSourceB_bits_opcode;
  wire [1:0] g_io_toSourceB_bits_param;
  wire [1:0] i_io_toSourceB_bits_param;
  wire [47:0] g_io_toSourceB_bits_address;
  wire [47:0] i_io_toSourceB_bits_address;
  wire [255:0] g_io_toSourceB_bits_data;
  wire [255:0] i_io_toSourceB_bits_data;
  wire [7:0] g_io_releaseBufWriteId;
  wire [7:0] i_io_releaseBufWriteId;
  wire g_io_nestedwbDataId_valid;
  wire i_io_nestedwbDataId_valid;
  wire [7:0] g_io_nestedwbDataId_bits;
  wire [7:0] i_io_nestedwbDataId_bits;
  wire g_io_msInfo_0_valid;
  wire i_io_msInfo_0_valid;
  wire [2:0] g_io_msInfo_0_bits_channel;
  wire [2:0] i_io_msInfo_0_bits_channel;
  wire [8:0] g_io_msInfo_0_bits_set;
  wire [8:0] i_io_msInfo_0_bits_set;
  wire [2:0] g_io_msInfo_0_bits_way;
  wire [2:0] i_io_msInfo_0_bits_way;
  wire [30:0] g_io_msInfo_0_bits_reqTag;
  wire [30:0] i_io_msInfo_0_bits_reqTag;
  wire g_io_msInfo_0_bits_willFree;
  wire i_io_msInfo_0_bits_willFree;
  wire g_io_msInfo_0_bits_aliasTask;
  wire i_io_msInfo_0_bits_aliasTask;
  wire g_io_msInfo_0_bits_needRelease;
  wire i_io_msInfo_0_bits_needRelease;
  wire g_io_msInfo_0_bits_blockRefill;
  wire i_io_msInfo_0_bits_blockRefill;
  wire g_io_msInfo_0_bits_meta_dirty;
  wire i_io_msInfo_0_bits_meta_dirty;
  wire [1:0] g_io_msInfo_0_bits_meta_state;
  wire [1:0] i_io_msInfo_0_bits_meta_state;
  wire g_io_msInfo_0_bits_meta_clients;
  wire i_io_msInfo_0_bits_meta_clients;
  wire [1:0] g_io_msInfo_0_bits_meta_alias;
  wire [1:0] i_io_msInfo_0_bits_meta_alias;
  wire g_io_msInfo_0_bits_meta_prefetch;
  wire i_io_msInfo_0_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_0_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_0_bits_meta_prefetchSrc;
  wire g_io_msInfo_0_bits_meta_accessed;
  wire i_io_msInfo_0_bits_meta_accessed;
  wire g_io_msInfo_0_bits_meta_tagErr;
  wire i_io_msInfo_0_bits_meta_tagErr;
  wire g_io_msInfo_0_bits_meta_dataErr;
  wire i_io_msInfo_0_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_0_bits_metaTag;
  wire [30:0] i_io_msInfo_0_bits_metaTag;
  wire g_io_msInfo_0_bits_dirHit;
  wire i_io_msInfo_0_bits_dirHit;
  wire g_io_msInfo_0_bits_isAcqOrPrefetch;
  wire i_io_msInfo_0_bits_isAcqOrPrefetch;
  wire g_io_msInfo_0_bits_isPrefetch;
  wire i_io_msInfo_0_bits_isPrefetch;
  wire [2:0] g_io_msInfo_0_bits_param;
  wire [2:0] i_io_msInfo_0_bits_param;
  wire g_io_msInfo_0_bits_mergeA;
  wire i_io_msInfo_0_bits_mergeA;
  wire g_io_msInfo_0_bits_w_grantfirst;
  wire i_io_msInfo_0_bits_w_grantfirst;
  wire g_io_msInfo_0_bits_s_release;
  wire i_io_msInfo_0_bits_s_release;
  wire g_io_msInfo_0_bits_s_refill;
  wire i_io_msInfo_0_bits_s_refill;
  wire g_io_msInfo_0_bits_s_cmoresp;
  wire i_io_msInfo_0_bits_s_cmoresp;
  wire g_io_msInfo_0_bits_s_cmometaw;
  wire i_io_msInfo_0_bits_s_cmometaw;
  wire g_io_msInfo_0_bits_w_releaseack;
  wire i_io_msInfo_0_bits_w_releaseack;
  wire g_io_msInfo_0_bits_w_replResp;
  wire i_io_msInfo_0_bits_w_replResp;
  wire g_io_msInfo_0_bits_w_rprobeacklast;
  wire i_io_msInfo_0_bits_w_rprobeacklast;
  wire g_io_msInfo_0_bits_replaceData;
  wire i_io_msInfo_0_bits_replaceData;
  wire g_io_msInfo_0_bits_releaseToClean;
  wire i_io_msInfo_0_bits_releaseToClean;
  wire g_io_msInfo_1_valid;
  wire i_io_msInfo_1_valid;
  wire [2:0] g_io_msInfo_1_bits_channel;
  wire [2:0] i_io_msInfo_1_bits_channel;
  wire [8:0] g_io_msInfo_1_bits_set;
  wire [8:0] i_io_msInfo_1_bits_set;
  wire [2:0] g_io_msInfo_1_bits_way;
  wire [2:0] i_io_msInfo_1_bits_way;
  wire [30:0] g_io_msInfo_1_bits_reqTag;
  wire [30:0] i_io_msInfo_1_bits_reqTag;
  wire g_io_msInfo_1_bits_willFree;
  wire i_io_msInfo_1_bits_willFree;
  wire g_io_msInfo_1_bits_aliasTask;
  wire i_io_msInfo_1_bits_aliasTask;
  wire g_io_msInfo_1_bits_needRelease;
  wire i_io_msInfo_1_bits_needRelease;
  wire g_io_msInfo_1_bits_blockRefill;
  wire i_io_msInfo_1_bits_blockRefill;
  wire g_io_msInfo_1_bits_meta_dirty;
  wire i_io_msInfo_1_bits_meta_dirty;
  wire [1:0] g_io_msInfo_1_bits_meta_state;
  wire [1:0] i_io_msInfo_1_bits_meta_state;
  wire g_io_msInfo_1_bits_meta_clients;
  wire i_io_msInfo_1_bits_meta_clients;
  wire [1:0] g_io_msInfo_1_bits_meta_alias;
  wire [1:0] i_io_msInfo_1_bits_meta_alias;
  wire g_io_msInfo_1_bits_meta_prefetch;
  wire i_io_msInfo_1_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_1_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_1_bits_meta_prefetchSrc;
  wire g_io_msInfo_1_bits_meta_accessed;
  wire i_io_msInfo_1_bits_meta_accessed;
  wire g_io_msInfo_1_bits_meta_tagErr;
  wire i_io_msInfo_1_bits_meta_tagErr;
  wire g_io_msInfo_1_bits_meta_dataErr;
  wire i_io_msInfo_1_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_1_bits_metaTag;
  wire [30:0] i_io_msInfo_1_bits_metaTag;
  wire g_io_msInfo_1_bits_dirHit;
  wire i_io_msInfo_1_bits_dirHit;
  wire g_io_msInfo_1_bits_isAcqOrPrefetch;
  wire i_io_msInfo_1_bits_isAcqOrPrefetch;
  wire g_io_msInfo_1_bits_isPrefetch;
  wire i_io_msInfo_1_bits_isPrefetch;
  wire [2:0] g_io_msInfo_1_bits_param;
  wire [2:0] i_io_msInfo_1_bits_param;
  wire g_io_msInfo_1_bits_mergeA;
  wire i_io_msInfo_1_bits_mergeA;
  wire g_io_msInfo_1_bits_w_grantfirst;
  wire i_io_msInfo_1_bits_w_grantfirst;
  wire g_io_msInfo_1_bits_s_release;
  wire i_io_msInfo_1_bits_s_release;
  wire g_io_msInfo_1_bits_s_refill;
  wire i_io_msInfo_1_bits_s_refill;
  wire g_io_msInfo_1_bits_s_cmoresp;
  wire i_io_msInfo_1_bits_s_cmoresp;
  wire g_io_msInfo_1_bits_s_cmometaw;
  wire i_io_msInfo_1_bits_s_cmometaw;
  wire g_io_msInfo_1_bits_w_releaseack;
  wire i_io_msInfo_1_bits_w_releaseack;
  wire g_io_msInfo_1_bits_w_replResp;
  wire i_io_msInfo_1_bits_w_replResp;
  wire g_io_msInfo_1_bits_w_rprobeacklast;
  wire i_io_msInfo_1_bits_w_rprobeacklast;
  wire g_io_msInfo_1_bits_replaceData;
  wire i_io_msInfo_1_bits_replaceData;
  wire g_io_msInfo_1_bits_releaseToClean;
  wire i_io_msInfo_1_bits_releaseToClean;
  wire g_io_msInfo_2_valid;
  wire i_io_msInfo_2_valid;
  wire [2:0] g_io_msInfo_2_bits_channel;
  wire [2:0] i_io_msInfo_2_bits_channel;
  wire [8:0] g_io_msInfo_2_bits_set;
  wire [8:0] i_io_msInfo_2_bits_set;
  wire [2:0] g_io_msInfo_2_bits_way;
  wire [2:0] i_io_msInfo_2_bits_way;
  wire [30:0] g_io_msInfo_2_bits_reqTag;
  wire [30:0] i_io_msInfo_2_bits_reqTag;
  wire g_io_msInfo_2_bits_willFree;
  wire i_io_msInfo_2_bits_willFree;
  wire g_io_msInfo_2_bits_aliasTask;
  wire i_io_msInfo_2_bits_aliasTask;
  wire g_io_msInfo_2_bits_needRelease;
  wire i_io_msInfo_2_bits_needRelease;
  wire g_io_msInfo_2_bits_blockRefill;
  wire i_io_msInfo_2_bits_blockRefill;
  wire g_io_msInfo_2_bits_meta_dirty;
  wire i_io_msInfo_2_bits_meta_dirty;
  wire [1:0] g_io_msInfo_2_bits_meta_state;
  wire [1:0] i_io_msInfo_2_bits_meta_state;
  wire g_io_msInfo_2_bits_meta_clients;
  wire i_io_msInfo_2_bits_meta_clients;
  wire [1:0] g_io_msInfo_2_bits_meta_alias;
  wire [1:0] i_io_msInfo_2_bits_meta_alias;
  wire g_io_msInfo_2_bits_meta_prefetch;
  wire i_io_msInfo_2_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_2_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_2_bits_meta_prefetchSrc;
  wire g_io_msInfo_2_bits_meta_accessed;
  wire i_io_msInfo_2_bits_meta_accessed;
  wire g_io_msInfo_2_bits_meta_tagErr;
  wire i_io_msInfo_2_bits_meta_tagErr;
  wire g_io_msInfo_2_bits_meta_dataErr;
  wire i_io_msInfo_2_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_2_bits_metaTag;
  wire [30:0] i_io_msInfo_2_bits_metaTag;
  wire g_io_msInfo_2_bits_dirHit;
  wire i_io_msInfo_2_bits_dirHit;
  wire g_io_msInfo_2_bits_isAcqOrPrefetch;
  wire i_io_msInfo_2_bits_isAcqOrPrefetch;
  wire g_io_msInfo_2_bits_isPrefetch;
  wire i_io_msInfo_2_bits_isPrefetch;
  wire [2:0] g_io_msInfo_2_bits_param;
  wire [2:0] i_io_msInfo_2_bits_param;
  wire g_io_msInfo_2_bits_mergeA;
  wire i_io_msInfo_2_bits_mergeA;
  wire g_io_msInfo_2_bits_w_grantfirst;
  wire i_io_msInfo_2_bits_w_grantfirst;
  wire g_io_msInfo_2_bits_s_release;
  wire i_io_msInfo_2_bits_s_release;
  wire g_io_msInfo_2_bits_s_refill;
  wire i_io_msInfo_2_bits_s_refill;
  wire g_io_msInfo_2_bits_s_cmoresp;
  wire i_io_msInfo_2_bits_s_cmoresp;
  wire g_io_msInfo_2_bits_s_cmometaw;
  wire i_io_msInfo_2_bits_s_cmometaw;
  wire g_io_msInfo_2_bits_w_releaseack;
  wire i_io_msInfo_2_bits_w_releaseack;
  wire g_io_msInfo_2_bits_w_replResp;
  wire i_io_msInfo_2_bits_w_replResp;
  wire g_io_msInfo_2_bits_w_rprobeacklast;
  wire i_io_msInfo_2_bits_w_rprobeacklast;
  wire g_io_msInfo_2_bits_replaceData;
  wire i_io_msInfo_2_bits_replaceData;
  wire g_io_msInfo_2_bits_releaseToClean;
  wire i_io_msInfo_2_bits_releaseToClean;
  wire g_io_msInfo_3_valid;
  wire i_io_msInfo_3_valid;
  wire [2:0] g_io_msInfo_3_bits_channel;
  wire [2:0] i_io_msInfo_3_bits_channel;
  wire [8:0] g_io_msInfo_3_bits_set;
  wire [8:0] i_io_msInfo_3_bits_set;
  wire [2:0] g_io_msInfo_3_bits_way;
  wire [2:0] i_io_msInfo_3_bits_way;
  wire [30:0] g_io_msInfo_3_bits_reqTag;
  wire [30:0] i_io_msInfo_3_bits_reqTag;
  wire g_io_msInfo_3_bits_willFree;
  wire i_io_msInfo_3_bits_willFree;
  wire g_io_msInfo_3_bits_aliasTask;
  wire i_io_msInfo_3_bits_aliasTask;
  wire g_io_msInfo_3_bits_needRelease;
  wire i_io_msInfo_3_bits_needRelease;
  wire g_io_msInfo_3_bits_blockRefill;
  wire i_io_msInfo_3_bits_blockRefill;
  wire g_io_msInfo_3_bits_meta_dirty;
  wire i_io_msInfo_3_bits_meta_dirty;
  wire [1:0] g_io_msInfo_3_bits_meta_state;
  wire [1:0] i_io_msInfo_3_bits_meta_state;
  wire g_io_msInfo_3_bits_meta_clients;
  wire i_io_msInfo_3_bits_meta_clients;
  wire [1:0] g_io_msInfo_3_bits_meta_alias;
  wire [1:0] i_io_msInfo_3_bits_meta_alias;
  wire g_io_msInfo_3_bits_meta_prefetch;
  wire i_io_msInfo_3_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_3_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_3_bits_meta_prefetchSrc;
  wire g_io_msInfo_3_bits_meta_accessed;
  wire i_io_msInfo_3_bits_meta_accessed;
  wire g_io_msInfo_3_bits_meta_tagErr;
  wire i_io_msInfo_3_bits_meta_tagErr;
  wire g_io_msInfo_3_bits_meta_dataErr;
  wire i_io_msInfo_3_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_3_bits_metaTag;
  wire [30:0] i_io_msInfo_3_bits_metaTag;
  wire g_io_msInfo_3_bits_dirHit;
  wire i_io_msInfo_3_bits_dirHit;
  wire g_io_msInfo_3_bits_isAcqOrPrefetch;
  wire i_io_msInfo_3_bits_isAcqOrPrefetch;
  wire g_io_msInfo_3_bits_isPrefetch;
  wire i_io_msInfo_3_bits_isPrefetch;
  wire [2:0] g_io_msInfo_3_bits_param;
  wire [2:0] i_io_msInfo_3_bits_param;
  wire g_io_msInfo_3_bits_mergeA;
  wire i_io_msInfo_3_bits_mergeA;
  wire g_io_msInfo_3_bits_w_grantfirst;
  wire i_io_msInfo_3_bits_w_grantfirst;
  wire g_io_msInfo_3_bits_s_release;
  wire i_io_msInfo_3_bits_s_release;
  wire g_io_msInfo_3_bits_s_refill;
  wire i_io_msInfo_3_bits_s_refill;
  wire g_io_msInfo_3_bits_s_cmoresp;
  wire i_io_msInfo_3_bits_s_cmoresp;
  wire g_io_msInfo_3_bits_s_cmometaw;
  wire i_io_msInfo_3_bits_s_cmometaw;
  wire g_io_msInfo_3_bits_w_releaseack;
  wire i_io_msInfo_3_bits_w_releaseack;
  wire g_io_msInfo_3_bits_w_replResp;
  wire i_io_msInfo_3_bits_w_replResp;
  wire g_io_msInfo_3_bits_w_rprobeacklast;
  wire i_io_msInfo_3_bits_w_rprobeacklast;
  wire g_io_msInfo_3_bits_replaceData;
  wire i_io_msInfo_3_bits_replaceData;
  wire g_io_msInfo_3_bits_releaseToClean;
  wire i_io_msInfo_3_bits_releaseToClean;
  wire g_io_msInfo_4_valid;
  wire i_io_msInfo_4_valid;
  wire [2:0] g_io_msInfo_4_bits_channel;
  wire [2:0] i_io_msInfo_4_bits_channel;
  wire [8:0] g_io_msInfo_4_bits_set;
  wire [8:0] i_io_msInfo_4_bits_set;
  wire [2:0] g_io_msInfo_4_bits_way;
  wire [2:0] i_io_msInfo_4_bits_way;
  wire [30:0] g_io_msInfo_4_bits_reqTag;
  wire [30:0] i_io_msInfo_4_bits_reqTag;
  wire g_io_msInfo_4_bits_willFree;
  wire i_io_msInfo_4_bits_willFree;
  wire g_io_msInfo_4_bits_aliasTask;
  wire i_io_msInfo_4_bits_aliasTask;
  wire g_io_msInfo_4_bits_needRelease;
  wire i_io_msInfo_4_bits_needRelease;
  wire g_io_msInfo_4_bits_blockRefill;
  wire i_io_msInfo_4_bits_blockRefill;
  wire g_io_msInfo_4_bits_meta_dirty;
  wire i_io_msInfo_4_bits_meta_dirty;
  wire [1:0] g_io_msInfo_4_bits_meta_state;
  wire [1:0] i_io_msInfo_4_bits_meta_state;
  wire g_io_msInfo_4_bits_meta_clients;
  wire i_io_msInfo_4_bits_meta_clients;
  wire [1:0] g_io_msInfo_4_bits_meta_alias;
  wire [1:0] i_io_msInfo_4_bits_meta_alias;
  wire g_io_msInfo_4_bits_meta_prefetch;
  wire i_io_msInfo_4_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_4_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_4_bits_meta_prefetchSrc;
  wire g_io_msInfo_4_bits_meta_accessed;
  wire i_io_msInfo_4_bits_meta_accessed;
  wire g_io_msInfo_4_bits_meta_tagErr;
  wire i_io_msInfo_4_bits_meta_tagErr;
  wire g_io_msInfo_4_bits_meta_dataErr;
  wire i_io_msInfo_4_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_4_bits_metaTag;
  wire [30:0] i_io_msInfo_4_bits_metaTag;
  wire g_io_msInfo_4_bits_dirHit;
  wire i_io_msInfo_4_bits_dirHit;
  wire g_io_msInfo_4_bits_isAcqOrPrefetch;
  wire i_io_msInfo_4_bits_isAcqOrPrefetch;
  wire g_io_msInfo_4_bits_isPrefetch;
  wire i_io_msInfo_4_bits_isPrefetch;
  wire [2:0] g_io_msInfo_4_bits_param;
  wire [2:0] i_io_msInfo_4_bits_param;
  wire g_io_msInfo_4_bits_mergeA;
  wire i_io_msInfo_4_bits_mergeA;
  wire g_io_msInfo_4_bits_w_grantfirst;
  wire i_io_msInfo_4_bits_w_grantfirst;
  wire g_io_msInfo_4_bits_s_release;
  wire i_io_msInfo_4_bits_s_release;
  wire g_io_msInfo_4_bits_s_refill;
  wire i_io_msInfo_4_bits_s_refill;
  wire g_io_msInfo_4_bits_s_cmoresp;
  wire i_io_msInfo_4_bits_s_cmoresp;
  wire g_io_msInfo_4_bits_s_cmometaw;
  wire i_io_msInfo_4_bits_s_cmometaw;
  wire g_io_msInfo_4_bits_w_releaseack;
  wire i_io_msInfo_4_bits_w_releaseack;
  wire g_io_msInfo_4_bits_w_replResp;
  wire i_io_msInfo_4_bits_w_replResp;
  wire g_io_msInfo_4_bits_w_rprobeacklast;
  wire i_io_msInfo_4_bits_w_rprobeacklast;
  wire g_io_msInfo_4_bits_replaceData;
  wire i_io_msInfo_4_bits_replaceData;
  wire g_io_msInfo_4_bits_releaseToClean;
  wire i_io_msInfo_4_bits_releaseToClean;
  wire g_io_msInfo_5_valid;
  wire i_io_msInfo_5_valid;
  wire [2:0] g_io_msInfo_5_bits_channel;
  wire [2:0] i_io_msInfo_5_bits_channel;
  wire [8:0] g_io_msInfo_5_bits_set;
  wire [8:0] i_io_msInfo_5_bits_set;
  wire [2:0] g_io_msInfo_5_bits_way;
  wire [2:0] i_io_msInfo_5_bits_way;
  wire [30:0] g_io_msInfo_5_bits_reqTag;
  wire [30:0] i_io_msInfo_5_bits_reqTag;
  wire g_io_msInfo_5_bits_willFree;
  wire i_io_msInfo_5_bits_willFree;
  wire g_io_msInfo_5_bits_aliasTask;
  wire i_io_msInfo_5_bits_aliasTask;
  wire g_io_msInfo_5_bits_needRelease;
  wire i_io_msInfo_5_bits_needRelease;
  wire g_io_msInfo_5_bits_blockRefill;
  wire i_io_msInfo_5_bits_blockRefill;
  wire g_io_msInfo_5_bits_meta_dirty;
  wire i_io_msInfo_5_bits_meta_dirty;
  wire [1:0] g_io_msInfo_5_bits_meta_state;
  wire [1:0] i_io_msInfo_5_bits_meta_state;
  wire g_io_msInfo_5_bits_meta_clients;
  wire i_io_msInfo_5_bits_meta_clients;
  wire [1:0] g_io_msInfo_5_bits_meta_alias;
  wire [1:0] i_io_msInfo_5_bits_meta_alias;
  wire g_io_msInfo_5_bits_meta_prefetch;
  wire i_io_msInfo_5_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_5_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_5_bits_meta_prefetchSrc;
  wire g_io_msInfo_5_bits_meta_accessed;
  wire i_io_msInfo_5_bits_meta_accessed;
  wire g_io_msInfo_5_bits_meta_tagErr;
  wire i_io_msInfo_5_bits_meta_tagErr;
  wire g_io_msInfo_5_bits_meta_dataErr;
  wire i_io_msInfo_5_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_5_bits_metaTag;
  wire [30:0] i_io_msInfo_5_bits_metaTag;
  wire g_io_msInfo_5_bits_dirHit;
  wire i_io_msInfo_5_bits_dirHit;
  wire g_io_msInfo_5_bits_isAcqOrPrefetch;
  wire i_io_msInfo_5_bits_isAcqOrPrefetch;
  wire g_io_msInfo_5_bits_isPrefetch;
  wire i_io_msInfo_5_bits_isPrefetch;
  wire [2:0] g_io_msInfo_5_bits_param;
  wire [2:0] i_io_msInfo_5_bits_param;
  wire g_io_msInfo_5_bits_mergeA;
  wire i_io_msInfo_5_bits_mergeA;
  wire g_io_msInfo_5_bits_w_grantfirst;
  wire i_io_msInfo_5_bits_w_grantfirst;
  wire g_io_msInfo_5_bits_s_release;
  wire i_io_msInfo_5_bits_s_release;
  wire g_io_msInfo_5_bits_s_refill;
  wire i_io_msInfo_5_bits_s_refill;
  wire g_io_msInfo_5_bits_s_cmoresp;
  wire i_io_msInfo_5_bits_s_cmoresp;
  wire g_io_msInfo_5_bits_s_cmometaw;
  wire i_io_msInfo_5_bits_s_cmometaw;
  wire g_io_msInfo_5_bits_w_releaseack;
  wire i_io_msInfo_5_bits_w_releaseack;
  wire g_io_msInfo_5_bits_w_replResp;
  wire i_io_msInfo_5_bits_w_replResp;
  wire g_io_msInfo_5_bits_w_rprobeacklast;
  wire i_io_msInfo_5_bits_w_rprobeacklast;
  wire g_io_msInfo_5_bits_replaceData;
  wire i_io_msInfo_5_bits_replaceData;
  wire g_io_msInfo_5_bits_releaseToClean;
  wire i_io_msInfo_5_bits_releaseToClean;
  wire g_io_msInfo_6_valid;
  wire i_io_msInfo_6_valid;
  wire [2:0] g_io_msInfo_6_bits_channel;
  wire [2:0] i_io_msInfo_6_bits_channel;
  wire [8:0] g_io_msInfo_6_bits_set;
  wire [8:0] i_io_msInfo_6_bits_set;
  wire [2:0] g_io_msInfo_6_bits_way;
  wire [2:0] i_io_msInfo_6_bits_way;
  wire [30:0] g_io_msInfo_6_bits_reqTag;
  wire [30:0] i_io_msInfo_6_bits_reqTag;
  wire g_io_msInfo_6_bits_willFree;
  wire i_io_msInfo_6_bits_willFree;
  wire g_io_msInfo_6_bits_aliasTask;
  wire i_io_msInfo_6_bits_aliasTask;
  wire g_io_msInfo_6_bits_needRelease;
  wire i_io_msInfo_6_bits_needRelease;
  wire g_io_msInfo_6_bits_blockRefill;
  wire i_io_msInfo_6_bits_blockRefill;
  wire g_io_msInfo_6_bits_meta_dirty;
  wire i_io_msInfo_6_bits_meta_dirty;
  wire [1:0] g_io_msInfo_6_bits_meta_state;
  wire [1:0] i_io_msInfo_6_bits_meta_state;
  wire g_io_msInfo_6_bits_meta_clients;
  wire i_io_msInfo_6_bits_meta_clients;
  wire [1:0] g_io_msInfo_6_bits_meta_alias;
  wire [1:0] i_io_msInfo_6_bits_meta_alias;
  wire g_io_msInfo_6_bits_meta_prefetch;
  wire i_io_msInfo_6_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_6_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_6_bits_meta_prefetchSrc;
  wire g_io_msInfo_6_bits_meta_accessed;
  wire i_io_msInfo_6_bits_meta_accessed;
  wire g_io_msInfo_6_bits_meta_tagErr;
  wire i_io_msInfo_6_bits_meta_tagErr;
  wire g_io_msInfo_6_bits_meta_dataErr;
  wire i_io_msInfo_6_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_6_bits_metaTag;
  wire [30:0] i_io_msInfo_6_bits_metaTag;
  wire g_io_msInfo_6_bits_dirHit;
  wire i_io_msInfo_6_bits_dirHit;
  wire g_io_msInfo_6_bits_isAcqOrPrefetch;
  wire i_io_msInfo_6_bits_isAcqOrPrefetch;
  wire g_io_msInfo_6_bits_isPrefetch;
  wire i_io_msInfo_6_bits_isPrefetch;
  wire [2:0] g_io_msInfo_6_bits_param;
  wire [2:0] i_io_msInfo_6_bits_param;
  wire g_io_msInfo_6_bits_mergeA;
  wire i_io_msInfo_6_bits_mergeA;
  wire g_io_msInfo_6_bits_w_grantfirst;
  wire i_io_msInfo_6_bits_w_grantfirst;
  wire g_io_msInfo_6_bits_s_release;
  wire i_io_msInfo_6_bits_s_release;
  wire g_io_msInfo_6_bits_s_refill;
  wire i_io_msInfo_6_bits_s_refill;
  wire g_io_msInfo_6_bits_s_cmoresp;
  wire i_io_msInfo_6_bits_s_cmoresp;
  wire g_io_msInfo_6_bits_s_cmometaw;
  wire i_io_msInfo_6_bits_s_cmometaw;
  wire g_io_msInfo_6_bits_w_releaseack;
  wire i_io_msInfo_6_bits_w_releaseack;
  wire g_io_msInfo_6_bits_w_replResp;
  wire i_io_msInfo_6_bits_w_replResp;
  wire g_io_msInfo_6_bits_w_rprobeacklast;
  wire i_io_msInfo_6_bits_w_rprobeacklast;
  wire g_io_msInfo_6_bits_replaceData;
  wire i_io_msInfo_6_bits_replaceData;
  wire g_io_msInfo_6_bits_releaseToClean;
  wire i_io_msInfo_6_bits_releaseToClean;
  wire g_io_msInfo_7_valid;
  wire i_io_msInfo_7_valid;
  wire [2:0] g_io_msInfo_7_bits_channel;
  wire [2:0] i_io_msInfo_7_bits_channel;
  wire [8:0] g_io_msInfo_7_bits_set;
  wire [8:0] i_io_msInfo_7_bits_set;
  wire [2:0] g_io_msInfo_7_bits_way;
  wire [2:0] i_io_msInfo_7_bits_way;
  wire [30:0] g_io_msInfo_7_bits_reqTag;
  wire [30:0] i_io_msInfo_7_bits_reqTag;
  wire g_io_msInfo_7_bits_willFree;
  wire i_io_msInfo_7_bits_willFree;
  wire g_io_msInfo_7_bits_aliasTask;
  wire i_io_msInfo_7_bits_aliasTask;
  wire g_io_msInfo_7_bits_needRelease;
  wire i_io_msInfo_7_bits_needRelease;
  wire g_io_msInfo_7_bits_blockRefill;
  wire i_io_msInfo_7_bits_blockRefill;
  wire g_io_msInfo_7_bits_meta_dirty;
  wire i_io_msInfo_7_bits_meta_dirty;
  wire [1:0] g_io_msInfo_7_bits_meta_state;
  wire [1:0] i_io_msInfo_7_bits_meta_state;
  wire g_io_msInfo_7_bits_meta_clients;
  wire i_io_msInfo_7_bits_meta_clients;
  wire [1:0] g_io_msInfo_7_bits_meta_alias;
  wire [1:0] i_io_msInfo_7_bits_meta_alias;
  wire g_io_msInfo_7_bits_meta_prefetch;
  wire i_io_msInfo_7_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_7_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_7_bits_meta_prefetchSrc;
  wire g_io_msInfo_7_bits_meta_accessed;
  wire i_io_msInfo_7_bits_meta_accessed;
  wire g_io_msInfo_7_bits_meta_tagErr;
  wire i_io_msInfo_7_bits_meta_tagErr;
  wire g_io_msInfo_7_bits_meta_dataErr;
  wire i_io_msInfo_7_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_7_bits_metaTag;
  wire [30:0] i_io_msInfo_7_bits_metaTag;
  wire g_io_msInfo_7_bits_dirHit;
  wire i_io_msInfo_7_bits_dirHit;
  wire g_io_msInfo_7_bits_isAcqOrPrefetch;
  wire i_io_msInfo_7_bits_isAcqOrPrefetch;
  wire g_io_msInfo_7_bits_isPrefetch;
  wire i_io_msInfo_7_bits_isPrefetch;
  wire [2:0] g_io_msInfo_7_bits_param;
  wire [2:0] i_io_msInfo_7_bits_param;
  wire g_io_msInfo_7_bits_mergeA;
  wire i_io_msInfo_7_bits_mergeA;
  wire g_io_msInfo_7_bits_w_grantfirst;
  wire i_io_msInfo_7_bits_w_grantfirst;
  wire g_io_msInfo_7_bits_s_release;
  wire i_io_msInfo_7_bits_s_release;
  wire g_io_msInfo_7_bits_s_refill;
  wire i_io_msInfo_7_bits_s_refill;
  wire g_io_msInfo_7_bits_s_cmoresp;
  wire i_io_msInfo_7_bits_s_cmoresp;
  wire g_io_msInfo_7_bits_s_cmometaw;
  wire i_io_msInfo_7_bits_s_cmometaw;
  wire g_io_msInfo_7_bits_w_releaseack;
  wire i_io_msInfo_7_bits_w_releaseack;
  wire g_io_msInfo_7_bits_w_replResp;
  wire i_io_msInfo_7_bits_w_replResp;
  wire g_io_msInfo_7_bits_w_rprobeacklast;
  wire i_io_msInfo_7_bits_w_rprobeacklast;
  wire g_io_msInfo_7_bits_replaceData;
  wire i_io_msInfo_7_bits_replaceData;
  wire g_io_msInfo_7_bits_releaseToClean;
  wire i_io_msInfo_7_bits_releaseToClean;
  wire g_io_msInfo_8_valid;
  wire i_io_msInfo_8_valid;
  wire [2:0] g_io_msInfo_8_bits_channel;
  wire [2:0] i_io_msInfo_8_bits_channel;
  wire [8:0] g_io_msInfo_8_bits_set;
  wire [8:0] i_io_msInfo_8_bits_set;
  wire [2:0] g_io_msInfo_8_bits_way;
  wire [2:0] i_io_msInfo_8_bits_way;
  wire [30:0] g_io_msInfo_8_bits_reqTag;
  wire [30:0] i_io_msInfo_8_bits_reqTag;
  wire g_io_msInfo_8_bits_willFree;
  wire i_io_msInfo_8_bits_willFree;
  wire g_io_msInfo_8_bits_aliasTask;
  wire i_io_msInfo_8_bits_aliasTask;
  wire g_io_msInfo_8_bits_needRelease;
  wire i_io_msInfo_8_bits_needRelease;
  wire g_io_msInfo_8_bits_blockRefill;
  wire i_io_msInfo_8_bits_blockRefill;
  wire g_io_msInfo_8_bits_meta_dirty;
  wire i_io_msInfo_8_bits_meta_dirty;
  wire [1:0] g_io_msInfo_8_bits_meta_state;
  wire [1:0] i_io_msInfo_8_bits_meta_state;
  wire g_io_msInfo_8_bits_meta_clients;
  wire i_io_msInfo_8_bits_meta_clients;
  wire [1:0] g_io_msInfo_8_bits_meta_alias;
  wire [1:0] i_io_msInfo_8_bits_meta_alias;
  wire g_io_msInfo_8_bits_meta_prefetch;
  wire i_io_msInfo_8_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_8_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_8_bits_meta_prefetchSrc;
  wire g_io_msInfo_8_bits_meta_accessed;
  wire i_io_msInfo_8_bits_meta_accessed;
  wire g_io_msInfo_8_bits_meta_tagErr;
  wire i_io_msInfo_8_bits_meta_tagErr;
  wire g_io_msInfo_8_bits_meta_dataErr;
  wire i_io_msInfo_8_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_8_bits_metaTag;
  wire [30:0] i_io_msInfo_8_bits_metaTag;
  wire g_io_msInfo_8_bits_dirHit;
  wire i_io_msInfo_8_bits_dirHit;
  wire g_io_msInfo_8_bits_isAcqOrPrefetch;
  wire i_io_msInfo_8_bits_isAcqOrPrefetch;
  wire g_io_msInfo_8_bits_isPrefetch;
  wire i_io_msInfo_8_bits_isPrefetch;
  wire [2:0] g_io_msInfo_8_bits_param;
  wire [2:0] i_io_msInfo_8_bits_param;
  wire g_io_msInfo_8_bits_mergeA;
  wire i_io_msInfo_8_bits_mergeA;
  wire g_io_msInfo_8_bits_w_grantfirst;
  wire i_io_msInfo_8_bits_w_grantfirst;
  wire g_io_msInfo_8_bits_s_release;
  wire i_io_msInfo_8_bits_s_release;
  wire g_io_msInfo_8_bits_s_refill;
  wire i_io_msInfo_8_bits_s_refill;
  wire g_io_msInfo_8_bits_s_cmoresp;
  wire i_io_msInfo_8_bits_s_cmoresp;
  wire g_io_msInfo_8_bits_s_cmometaw;
  wire i_io_msInfo_8_bits_s_cmometaw;
  wire g_io_msInfo_8_bits_w_releaseack;
  wire i_io_msInfo_8_bits_w_releaseack;
  wire g_io_msInfo_8_bits_w_replResp;
  wire i_io_msInfo_8_bits_w_replResp;
  wire g_io_msInfo_8_bits_w_rprobeacklast;
  wire i_io_msInfo_8_bits_w_rprobeacklast;
  wire g_io_msInfo_8_bits_replaceData;
  wire i_io_msInfo_8_bits_replaceData;
  wire g_io_msInfo_8_bits_releaseToClean;
  wire i_io_msInfo_8_bits_releaseToClean;
  wire g_io_msInfo_9_valid;
  wire i_io_msInfo_9_valid;
  wire [2:0] g_io_msInfo_9_bits_channel;
  wire [2:0] i_io_msInfo_9_bits_channel;
  wire [8:0] g_io_msInfo_9_bits_set;
  wire [8:0] i_io_msInfo_9_bits_set;
  wire [2:0] g_io_msInfo_9_bits_way;
  wire [2:0] i_io_msInfo_9_bits_way;
  wire [30:0] g_io_msInfo_9_bits_reqTag;
  wire [30:0] i_io_msInfo_9_bits_reqTag;
  wire g_io_msInfo_9_bits_willFree;
  wire i_io_msInfo_9_bits_willFree;
  wire g_io_msInfo_9_bits_aliasTask;
  wire i_io_msInfo_9_bits_aliasTask;
  wire g_io_msInfo_9_bits_needRelease;
  wire i_io_msInfo_9_bits_needRelease;
  wire g_io_msInfo_9_bits_blockRefill;
  wire i_io_msInfo_9_bits_blockRefill;
  wire g_io_msInfo_9_bits_meta_dirty;
  wire i_io_msInfo_9_bits_meta_dirty;
  wire [1:0] g_io_msInfo_9_bits_meta_state;
  wire [1:0] i_io_msInfo_9_bits_meta_state;
  wire g_io_msInfo_9_bits_meta_clients;
  wire i_io_msInfo_9_bits_meta_clients;
  wire [1:0] g_io_msInfo_9_bits_meta_alias;
  wire [1:0] i_io_msInfo_9_bits_meta_alias;
  wire g_io_msInfo_9_bits_meta_prefetch;
  wire i_io_msInfo_9_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_9_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_9_bits_meta_prefetchSrc;
  wire g_io_msInfo_9_bits_meta_accessed;
  wire i_io_msInfo_9_bits_meta_accessed;
  wire g_io_msInfo_9_bits_meta_tagErr;
  wire i_io_msInfo_9_bits_meta_tagErr;
  wire g_io_msInfo_9_bits_meta_dataErr;
  wire i_io_msInfo_9_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_9_bits_metaTag;
  wire [30:0] i_io_msInfo_9_bits_metaTag;
  wire g_io_msInfo_9_bits_dirHit;
  wire i_io_msInfo_9_bits_dirHit;
  wire g_io_msInfo_9_bits_isAcqOrPrefetch;
  wire i_io_msInfo_9_bits_isAcqOrPrefetch;
  wire g_io_msInfo_9_bits_isPrefetch;
  wire i_io_msInfo_9_bits_isPrefetch;
  wire [2:0] g_io_msInfo_9_bits_param;
  wire [2:0] i_io_msInfo_9_bits_param;
  wire g_io_msInfo_9_bits_mergeA;
  wire i_io_msInfo_9_bits_mergeA;
  wire g_io_msInfo_9_bits_w_grantfirst;
  wire i_io_msInfo_9_bits_w_grantfirst;
  wire g_io_msInfo_9_bits_s_release;
  wire i_io_msInfo_9_bits_s_release;
  wire g_io_msInfo_9_bits_s_refill;
  wire i_io_msInfo_9_bits_s_refill;
  wire g_io_msInfo_9_bits_s_cmoresp;
  wire i_io_msInfo_9_bits_s_cmoresp;
  wire g_io_msInfo_9_bits_s_cmometaw;
  wire i_io_msInfo_9_bits_s_cmometaw;
  wire g_io_msInfo_9_bits_w_releaseack;
  wire i_io_msInfo_9_bits_w_releaseack;
  wire g_io_msInfo_9_bits_w_replResp;
  wire i_io_msInfo_9_bits_w_replResp;
  wire g_io_msInfo_9_bits_w_rprobeacklast;
  wire i_io_msInfo_9_bits_w_rprobeacklast;
  wire g_io_msInfo_9_bits_replaceData;
  wire i_io_msInfo_9_bits_replaceData;
  wire g_io_msInfo_9_bits_releaseToClean;
  wire i_io_msInfo_9_bits_releaseToClean;
  wire g_io_msInfo_10_valid;
  wire i_io_msInfo_10_valid;
  wire [2:0] g_io_msInfo_10_bits_channel;
  wire [2:0] i_io_msInfo_10_bits_channel;
  wire [8:0] g_io_msInfo_10_bits_set;
  wire [8:0] i_io_msInfo_10_bits_set;
  wire [2:0] g_io_msInfo_10_bits_way;
  wire [2:0] i_io_msInfo_10_bits_way;
  wire [30:0] g_io_msInfo_10_bits_reqTag;
  wire [30:0] i_io_msInfo_10_bits_reqTag;
  wire g_io_msInfo_10_bits_willFree;
  wire i_io_msInfo_10_bits_willFree;
  wire g_io_msInfo_10_bits_aliasTask;
  wire i_io_msInfo_10_bits_aliasTask;
  wire g_io_msInfo_10_bits_needRelease;
  wire i_io_msInfo_10_bits_needRelease;
  wire g_io_msInfo_10_bits_blockRefill;
  wire i_io_msInfo_10_bits_blockRefill;
  wire g_io_msInfo_10_bits_meta_dirty;
  wire i_io_msInfo_10_bits_meta_dirty;
  wire [1:0] g_io_msInfo_10_bits_meta_state;
  wire [1:0] i_io_msInfo_10_bits_meta_state;
  wire g_io_msInfo_10_bits_meta_clients;
  wire i_io_msInfo_10_bits_meta_clients;
  wire [1:0] g_io_msInfo_10_bits_meta_alias;
  wire [1:0] i_io_msInfo_10_bits_meta_alias;
  wire g_io_msInfo_10_bits_meta_prefetch;
  wire i_io_msInfo_10_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_10_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_10_bits_meta_prefetchSrc;
  wire g_io_msInfo_10_bits_meta_accessed;
  wire i_io_msInfo_10_bits_meta_accessed;
  wire g_io_msInfo_10_bits_meta_tagErr;
  wire i_io_msInfo_10_bits_meta_tagErr;
  wire g_io_msInfo_10_bits_meta_dataErr;
  wire i_io_msInfo_10_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_10_bits_metaTag;
  wire [30:0] i_io_msInfo_10_bits_metaTag;
  wire g_io_msInfo_10_bits_dirHit;
  wire i_io_msInfo_10_bits_dirHit;
  wire g_io_msInfo_10_bits_isAcqOrPrefetch;
  wire i_io_msInfo_10_bits_isAcqOrPrefetch;
  wire g_io_msInfo_10_bits_isPrefetch;
  wire i_io_msInfo_10_bits_isPrefetch;
  wire [2:0] g_io_msInfo_10_bits_param;
  wire [2:0] i_io_msInfo_10_bits_param;
  wire g_io_msInfo_10_bits_mergeA;
  wire i_io_msInfo_10_bits_mergeA;
  wire g_io_msInfo_10_bits_w_grantfirst;
  wire i_io_msInfo_10_bits_w_grantfirst;
  wire g_io_msInfo_10_bits_s_release;
  wire i_io_msInfo_10_bits_s_release;
  wire g_io_msInfo_10_bits_s_refill;
  wire i_io_msInfo_10_bits_s_refill;
  wire g_io_msInfo_10_bits_s_cmoresp;
  wire i_io_msInfo_10_bits_s_cmoresp;
  wire g_io_msInfo_10_bits_s_cmometaw;
  wire i_io_msInfo_10_bits_s_cmometaw;
  wire g_io_msInfo_10_bits_w_releaseack;
  wire i_io_msInfo_10_bits_w_releaseack;
  wire g_io_msInfo_10_bits_w_replResp;
  wire i_io_msInfo_10_bits_w_replResp;
  wire g_io_msInfo_10_bits_w_rprobeacklast;
  wire i_io_msInfo_10_bits_w_rprobeacklast;
  wire g_io_msInfo_10_bits_replaceData;
  wire i_io_msInfo_10_bits_replaceData;
  wire g_io_msInfo_10_bits_releaseToClean;
  wire i_io_msInfo_10_bits_releaseToClean;
  wire g_io_msInfo_11_valid;
  wire i_io_msInfo_11_valid;
  wire [2:0] g_io_msInfo_11_bits_channel;
  wire [2:0] i_io_msInfo_11_bits_channel;
  wire [8:0] g_io_msInfo_11_bits_set;
  wire [8:0] i_io_msInfo_11_bits_set;
  wire [2:0] g_io_msInfo_11_bits_way;
  wire [2:0] i_io_msInfo_11_bits_way;
  wire [30:0] g_io_msInfo_11_bits_reqTag;
  wire [30:0] i_io_msInfo_11_bits_reqTag;
  wire g_io_msInfo_11_bits_willFree;
  wire i_io_msInfo_11_bits_willFree;
  wire g_io_msInfo_11_bits_aliasTask;
  wire i_io_msInfo_11_bits_aliasTask;
  wire g_io_msInfo_11_bits_needRelease;
  wire i_io_msInfo_11_bits_needRelease;
  wire g_io_msInfo_11_bits_blockRefill;
  wire i_io_msInfo_11_bits_blockRefill;
  wire g_io_msInfo_11_bits_meta_dirty;
  wire i_io_msInfo_11_bits_meta_dirty;
  wire [1:0] g_io_msInfo_11_bits_meta_state;
  wire [1:0] i_io_msInfo_11_bits_meta_state;
  wire g_io_msInfo_11_bits_meta_clients;
  wire i_io_msInfo_11_bits_meta_clients;
  wire [1:0] g_io_msInfo_11_bits_meta_alias;
  wire [1:0] i_io_msInfo_11_bits_meta_alias;
  wire g_io_msInfo_11_bits_meta_prefetch;
  wire i_io_msInfo_11_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_11_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_11_bits_meta_prefetchSrc;
  wire g_io_msInfo_11_bits_meta_accessed;
  wire i_io_msInfo_11_bits_meta_accessed;
  wire g_io_msInfo_11_bits_meta_tagErr;
  wire i_io_msInfo_11_bits_meta_tagErr;
  wire g_io_msInfo_11_bits_meta_dataErr;
  wire i_io_msInfo_11_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_11_bits_metaTag;
  wire [30:0] i_io_msInfo_11_bits_metaTag;
  wire g_io_msInfo_11_bits_dirHit;
  wire i_io_msInfo_11_bits_dirHit;
  wire g_io_msInfo_11_bits_isAcqOrPrefetch;
  wire i_io_msInfo_11_bits_isAcqOrPrefetch;
  wire g_io_msInfo_11_bits_isPrefetch;
  wire i_io_msInfo_11_bits_isPrefetch;
  wire [2:0] g_io_msInfo_11_bits_param;
  wire [2:0] i_io_msInfo_11_bits_param;
  wire g_io_msInfo_11_bits_mergeA;
  wire i_io_msInfo_11_bits_mergeA;
  wire g_io_msInfo_11_bits_w_grantfirst;
  wire i_io_msInfo_11_bits_w_grantfirst;
  wire g_io_msInfo_11_bits_s_release;
  wire i_io_msInfo_11_bits_s_release;
  wire g_io_msInfo_11_bits_s_refill;
  wire i_io_msInfo_11_bits_s_refill;
  wire g_io_msInfo_11_bits_s_cmoresp;
  wire i_io_msInfo_11_bits_s_cmoresp;
  wire g_io_msInfo_11_bits_s_cmometaw;
  wire i_io_msInfo_11_bits_s_cmometaw;
  wire g_io_msInfo_11_bits_w_releaseack;
  wire i_io_msInfo_11_bits_w_releaseack;
  wire g_io_msInfo_11_bits_w_replResp;
  wire i_io_msInfo_11_bits_w_replResp;
  wire g_io_msInfo_11_bits_w_rprobeacklast;
  wire i_io_msInfo_11_bits_w_rprobeacklast;
  wire g_io_msInfo_11_bits_replaceData;
  wire i_io_msInfo_11_bits_replaceData;
  wire g_io_msInfo_11_bits_releaseToClean;
  wire i_io_msInfo_11_bits_releaseToClean;
  wire g_io_msInfo_12_valid;
  wire i_io_msInfo_12_valid;
  wire [2:0] g_io_msInfo_12_bits_channel;
  wire [2:0] i_io_msInfo_12_bits_channel;
  wire [8:0] g_io_msInfo_12_bits_set;
  wire [8:0] i_io_msInfo_12_bits_set;
  wire [2:0] g_io_msInfo_12_bits_way;
  wire [2:0] i_io_msInfo_12_bits_way;
  wire [30:0] g_io_msInfo_12_bits_reqTag;
  wire [30:0] i_io_msInfo_12_bits_reqTag;
  wire g_io_msInfo_12_bits_willFree;
  wire i_io_msInfo_12_bits_willFree;
  wire g_io_msInfo_12_bits_aliasTask;
  wire i_io_msInfo_12_bits_aliasTask;
  wire g_io_msInfo_12_bits_needRelease;
  wire i_io_msInfo_12_bits_needRelease;
  wire g_io_msInfo_12_bits_blockRefill;
  wire i_io_msInfo_12_bits_blockRefill;
  wire g_io_msInfo_12_bits_meta_dirty;
  wire i_io_msInfo_12_bits_meta_dirty;
  wire [1:0] g_io_msInfo_12_bits_meta_state;
  wire [1:0] i_io_msInfo_12_bits_meta_state;
  wire g_io_msInfo_12_bits_meta_clients;
  wire i_io_msInfo_12_bits_meta_clients;
  wire [1:0] g_io_msInfo_12_bits_meta_alias;
  wire [1:0] i_io_msInfo_12_bits_meta_alias;
  wire g_io_msInfo_12_bits_meta_prefetch;
  wire i_io_msInfo_12_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_12_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_12_bits_meta_prefetchSrc;
  wire g_io_msInfo_12_bits_meta_accessed;
  wire i_io_msInfo_12_bits_meta_accessed;
  wire g_io_msInfo_12_bits_meta_tagErr;
  wire i_io_msInfo_12_bits_meta_tagErr;
  wire g_io_msInfo_12_bits_meta_dataErr;
  wire i_io_msInfo_12_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_12_bits_metaTag;
  wire [30:0] i_io_msInfo_12_bits_metaTag;
  wire g_io_msInfo_12_bits_dirHit;
  wire i_io_msInfo_12_bits_dirHit;
  wire g_io_msInfo_12_bits_isAcqOrPrefetch;
  wire i_io_msInfo_12_bits_isAcqOrPrefetch;
  wire g_io_msInfo_12_bits_isPrefetch;
  wire i_io_msInfo_12_bits_isPrefetch;
  wire [2:0] g_io_msInfo_12_bits_param;
  wire [2:0] i_io_msInfo_12_bits_param;
  wire g_io_msInfo_12_bits_mergeA;
  wire i_io_msInfo_12_bits_mergeA;
  wire g_io_msInfo_12_bits_w_grantfirst;
  wire i_io_msInfo_12_bits_w_grantfirst;
  wire g_io_msInfo_12_bits_s_release;
  wire i_io_msInfo_12_bits_s_release;
  wire g_io_msInfo_12_bits_s_refill;
  wire i_io_msInfo_12_bits_s_refill;
  wire g_io_msInfo_12_bits_s_cmoresp;
  wire i_io_msInfo_12_bits_s_cmoresp;
  wire g_io_msInfo_12_bits_s_cmometaw;
  wire i_io_msInfo_12_bits_s_cmometaw;
  wire g_io_msInfo_12_bits_w_releaseack;
  wire i_io_msInfo_12_bits_w_releaseack;
  wire g_io_msInfo_12_bits_w_replResp;
  wire i_io_msInfo_12_bits_w_replResp;
  wire g_io_msInfo_12_bits_w_rprobeacklast;
  wire i_io_msInfo_12_bits_w_rprobeacklast;
  wire g_io_msInfo_12_bits_replaceData;
  wire i_io_msInfo_12_bits_replaceData;
  wire g_io_msInfo_12_bits_releaseToClean;
  wire i_io_msInfo_12_bits_releaseToClean;
  wire g_io_msInfo_13_valid;
  wire i_io_msInfo_13_valid;
  wire [2:0] g_io_msInfo_13_bits_channel;
  wire [2:0] i_io_msInfo_13_bits_channel;
  wire [8:0] g_io_msInfo_13_bits_set;
  wire [8:0] i_io_msInfo_13_bits_set;
  wire [2:0] g_io_msInfo_13_bits_way;
  wire [2:0] i_io_msInfo_13_bits_way;
  wire [30:0] g_io_msInfo_13_bits_reqTag;
  wire [30:0] i_io_msInfo_13_bits_reqTag;
  wire g_io_msInfo_13_bits_willFree;
  wire i_io_msInfo_13_bits_willFree;
  wire g_io_msInfo_13_bits_aliasTask;
  wire i_io_msInfo_13_bits_aliasTask;
  wire g_io_msInfo_13_bits_needRelease;
  wire i_io_msInfo_13_bits_needRelease;
  wire g_io_msInfo_13_bits_blockRefill;
  wire i_io_msInfo_13_bits_blockRefill;
  wire g_io_msInfo_13_bits_meta_dirty;
  wire i_io_msInfo_13_bits_meta_dirty;
  wire [1:0] g_io_msInfo_13_bits_meta_state;
  wire [1:0] i_io_msInfo_13_bits_meta_state;
  wire g_io_msInfo_13_bits_meta_clients;
  wire i_io_msInfo_13_bits_meta_clients;
  wire [1:0] g_io_msInfo_13_bits_meta_alias;
  wire [1:0] i_io_msInfo_13_bits_meta_alias;
  wire g_io_msInfo_13_bits_meta_prefetch;
  wire i_io_msInfo_13_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_13_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_13_bits_meta_prefetchSrc;
  wire g_io_msInfo_13_bits_meta_accessed;
  wire i_io_msInfo_13_bits_meta_accessed;
  wire g_io_msInfo_13_bits_meta_tagErr;
  wire i_io_msInfo_13_bits_meta_tagErr;
  wire g_io_msInfo_13_bits_meta_dataErr;
  wire i_io_msInfo_13_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_13_bits_metaTag;
  wire [30:0] i_io_msInfo_13_bits_metaTag;
  wire g_io_msInfo_13_bits_dirHit;
  wire i_io_msInfo_13_bits_dirHit;
  wire g_io_msInfo_13_bits_isAcqOrPrefetch;
  wire i_io_msInfo_13_bits_isAcqOrPrefetch;
  wire g_io_msInfo_13_bits_isPrefetch;
  wire i_io_msInfo_13_bits_isPrefetch;
  wire [2:0] g_io_msInfo_13_bits_param;
  wire [2:0] i_io_msInfo_13_bits_param;
  wire g_io_msInfo_13_bits_mergeA;
  wire i_io_msInfo_13_bits_mergeA;
  wire g_io_msInfo_13_bits_w_grantfirst;
  wire i_io_msInfo_13_bits_w_grantfirst;
  wire g_io_msInfo_13_bits_s_release;
  wire i_io_msInfo_13_bits_s_release;
  wire g_io_msInfo_13_bits_s_refill;
  wire i_io_msInfo_13_bits_s_refill;
  wire g_io_msInfo_13_bits_s_cmoresp;
  wire i_io_msInfo_13_bits_s_cmoresp;
  wire g_io_msInfo_13_bits_s_cmometaw;
  wire i_io_msInfo_13_bits_s_cmometaw;
  wire g_io_msInfo_13_bits_w_releaseack;
  wire i_io_msInfo_13_bits_w_releaseack;
  wire g_io_msInfo_13_bits_w_replResp;
  wire i_io_msInfo_13_bits_w_replResp;
  wire g_io_msInfo_13_bits_w_rprobeacklast;
  wire i_io_msInfo_13_bits_w_rprobeacklast;
  wire g_io_msInfo_13_bits_replaceData;
  wire i_io_msInfo_13_bits_replaceData;
  wire g_io_msInfo_13_bits_releaseToClean;
  wire i_io_msInfo_13_bits_releaseToClean;
  wire g_io_msInfo_14_valid;
  wire i_io_msInfo_14_valid;
  wire [2:0] g_io_msInfo_14_bits_channel;
  wire [2:0] i_io_msInfo_14_bits_channel;
  wire [8:0] g_io_msInfo_14_bits_set;
  wire [8:0] i_io_msInfo_14_bits_set;
  wire [2:0] g_io_msInfo_14_bits_way;
  wire [2:0] i_io_msInfo_14_bits_way;
  wire [30:0] g_io_msInfo_14_bits_reqTag;
  wire [30:0] i_io_msInfo_14_bits_reqTag;
  wire g_io_msInfo_14_bits_willFree;
  wire i_io_msInfo_14_bits_willFree;
  wire g_io_msInfo_14_bits_aliasTask;
  wire i_io_msInfo_14_bits_aliasTask;
  wire g_io_msInfo_14_bits_needRelease;
  wire i_io_msInfo_14_bits_needRelease;
  wire g_io_msInfo_14_bits_blockRefill;
  wire i_io_msInfo_14_bits_blockRefill;
  wire g_io_msInfo_14_bits_meta_dirty;
  wire i_io_msInfo_14_bits_meta_dirty;
  wire [1:0] g_io_msInfo_14_bits_meta_state;
  wire [1:0] i_io_msInfo_14_bits_meta_state;
  wire g_io_msInfo_14_bits_meta_clients;
  wire i_io_msInfo_14_bits_meta_clients;
  wire [1:0] g_io_msInfo_14_bits_meta_alias;
  wire [1:0] i_io_msInfo_14_bits_meta_alias;
  wire g_io_msInfo_14_bits_meta_prefetch;
  wire i_io_msInfo_14_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_14_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_14_bits_meta_prefetchSrc;
  wire g_io_msInfo_14_bits_meta_accessed;
  wire i_io_msInfo_14_bits_meta_accessed;
  wire g_io_msInfo_14_bits_meta_tagErr;
  wire i_io_msInfo_14_bits_meta_tagErr;
  wire g_io_msInfo_14_bits_meta_dataErr;
  wire i_io_msInfo_14_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_14_bits_metaTag;
  wire [30:0] i_io_msInfo_14_bits_metaTag;
  wire g_io_msInfo_14_bits_dirHit;
  wire i_io_msInfo_14_bits_dirHit;
  wire g_io_msInfo_14_bits_isAcqOrPrefetch;
  wire i_io_msInfo_14_bits_isAcqOrPrefetch;
  wire g_io_msInfo_14_bits_isPrefetch;
  wire i_io_msInfo_14_bits_isPrefetch;
  wire [2:0] g_io_msInfo_14_bits_param;
  wire [2:0] i_io_msInfo_14_bits_param;
  wire g_io_msInfo_14_bits_mergeA;
  wire i_io_msInfo_14_bits_mergeA;
  wire g_io_msInfo_14_bits_w_grantfirst;
  wire i_io_msInfo_14_bits_w_grantfirst;
  wire g_io_msInfo_14_bits_s_release;
  wire i_io_msInfo_14_bits_s_release;
  wire g_io_msInfo_14_bits_s_refill;
  wire i_io_msInfo_14_bits_s_refill;
  wire g_io_msInfo_14_bits_s_cmoresp;
  wire i_io_msInfo_14_bits_s_cmoresp;
  wire g_io_msInfo_14_bits_s_cmometaw;
  wire i_io_msInfo_14_bits_s_cmometaw;
  wire g_io_msInfo_14_bits_w_releaseack;
  wire i_io_msInfo_14_bits_w_releaseack;
  wire g_io_msInfo_14_bits_w_replResp;
  wire i_io_msInfo_14_bits_w_replResp;
  wire g_io_msInfo_14_bits_w_rprobeacklast;
  wire i_io_msInfo_14_bits_w_rprobeacklast;
  wire g_io_msInfo_14_bits_replaceData;
  wire i_io_msInfo_14_bits_replaceData;
  wire g_io_msInfo_14_bits_releaseToClean;
  wire i_io_msInfo_14_bits_releaseToClean;
  wire g_io_msInfo_15_valid;
  wire i_io_msInfo_15_valid;
  wire [2:0] g_io_msInfo_15_bits_channel;
  wire [2:0] i_io_msInfo_15_bits_channel;
  wire [8:0] g_io_msInfo_15_bits_set;
  wire [8:0] i_io_msInfo_15_bits_set;
  wire [2:0] g_io_msInfo_15_bits_way;
  wire [2:0] i_io_msInfo_15_bits_way;
  wire [30:0] g_io_msInfo_15_bits_reqTag;
  wire [30:0] i_io_msInfo_15_bits_reqTag;
  wire g_io_msInfo_15_bits_willFree;
  wire i_io_msInfo_15_bits_willFree;
  wire g_io_msInfo_15_bits_aliasTask;
  wire i_io_msInfo_15_bits_aliasTask;
  wire g_io_msInfo_15_bits_needRelease;
  wire i_io_msInfo_15_bits_needRelease;
  wire g_io_msInfo_15_bits_blockRefill;
  wire i_io_msInfo_15_bits_blockRefill;
  wire g_io_msInfo_15_bits_meta_dirty;
  wire i_io_msInfo_15_bits_meta_dirty;
  wire [1:0] g_io_msInfo_15_bits_meta_state;
  wire [1:0] i_io_msInfo_15_bits_meta_state;
  wire g_io_msInfo_15_bits_meta_clients;
  wire i_io_msInfo_15_bits_meta_clients;
  wire [1:0] g_io_msInfo_15_bits_meta_alias;
  wire [1:0] i_io_msInfo_15_bits_meta_alias;
  wire g_io_msInfo_15_bits_meta_prefetch;
  wire i_io_msInfo_15_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_15_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_15_bits_meta_prefetchSrc;
  wire g_io_msInfo_15_bits_meta_accessed;
  wire i_io_msInfo_15_bits_meta_accessed;
  wire g_io_msInfo_15_bits_meta_tagErr;
  wire i_io_msInfo_15_bits_meta_tagErr;
  wire g_io_msInfo_15_bits_meta_dataErr;
  wire i_io_msInfo_15_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_15_bits_metaTag;
  wire [30:0] i_io_msInfo_15_bits_metaTag;
  wire g_io_msInfo_15_bits_dirHit;
  wire i_io_msInfo_15_bits_dirHit;
  wire g_io_msInfo_15_bits_isAcqOrPrefetch;
  wire i_io_msInfo_15_bits_isAcqOrPrefetch;
  wire g_io_msInfo_15_bits_isPrefetch;
  wire i_io_msInfo_15_bits_isPrefetch;
  wire [2:0] g_io_msInfo_15_bits_param;
  wire [2:0] i_io_msInfo_15_bits_param;
  wire g_io_msInfo_15_bits_mergeA;
  wire i_io_msInfo_15_bits_mergeA;
  wire g_io_msInfo_15_bits_w_grantfirst;
  wire i_io_msInfo_15_bits_w_grantfirst;
  wire g_io_msInfo_15_bits_s_release;
  wire i_io_msInfo_15_bits_s_release;
  wire g_io_msInfo_15_bits_s_refill;
  wire i_io_msInfo_15_bits_s_refill;
  wire g_io_msInfo_15_bits_s_cmoresp;
  wire i_io_msInfo_15_bits_s_cmoresp;
  wire g_io_msInfo_15_bits_s_cmometaw;
  wire i_io_msInfo_15_bits_s_cmometaw;
  wire g_io_msInfo_15_bits_w_releaseack;
  wire i_io_msInfo_15_bits_w_releaseack;
  wire g_io_msInfo_15_bits_w_replResp;
  wire i_io_msInfo_15_bits_w_replResp;
  wire g_io_msInfo_15_bits_w_rprobeacklast;
  wire i_io_msInfo_15_bits_w_rprobeacklast;
  wire g_io_msInfo_15_bits_replaceData;
  wire i_io_msInfo_15_bits_replaceData;
  wire g_io_msInfo_15_bits_releaseToClean;
  wire i_io_msInfo_15_bits_releaseToClean;
  wire g_io_msStatus_0_valid;
  wire i_io_msStatus_0_valid;
  wire [2:0] g_io_msStatus_0_bits_channel;
  wire [2:0] i_io_msStatus_0_bits_channel;
  wire [8:0] g_io_msStatus_0_bits_set;
  wire [8:0] i_io_msStatus_0_bits_set;
  wire [30:0] g_io_msStatus_0_bits_reqTag;
  wire [30:0] i_io_msStatus_0_bits_reqTag;
  wire g_io_msStatus_0_bits_is_miss;
  wire i_io_msStatus_0_bits_is_miss;
  wire g_io_msStatus_0_bits_is_prefetch;
  wire i_io_msStatus_0_bits_is_prefetch;
  wire g_io_msStatus_1_valid;
  wire i_io_msStatus_1_valid;
  wire [2:0] g_io_msStatus_1_bits_channel;
  wire [2:0] i_io_msStatus_1_bits_channel;
  wire [8:0] g_io_msStatus_1_bits_set;
  wire [8:0] i_io_msStatus_1_bits_set;
  wire [30:0] g_io_msStatus_1_bits_reqTag;
  wire [30:0] i_io_msStatus_1_bits_reqTag;
  wire g_io_msStatus_1_bits_is_miss;
  wire i_io_msStatus_1_bits_is_miss;
  wire g_io_msStatus_1_bits_is_prefetch;
  wire i_io_msStatus_1_bits_is_prefetch;
  wire g_io_msStatus_2_valid;
  wire i_io_msStatus_2_valid;
  wire [2:0] g_io_msStatus_2_bits_channel;
  wire [2:0] i_io_msStatus_2_bits_channel;
  wire [8:0] g_io_msStatus_2_bits_set;
  wire [8:0] i_io_msStatus_2_bits_set;
  wire [30:0] g_io_msStatus_2_bits_reqTag;
  wire [30:0] i_io_msStatus_2_bits_reqTag;
  wire g_io_msStatus_2_bits_is_miss;
  wire i_io_msStatus_2_bits_is_miss;
  wire g_io_msStatus_2_bits_is_prefetch;
  wire i_io_msStatus_2_bits_is_prefetch;
  wire g_io_msStatus_3_valid;
  wire i_io_msStatus_3_valid;
  wire [2:0] g_io_msStatus_3_bits_channel;
  wire [2:0] i_io_msStatus_3_bits_channel;
  wire [8:0] g_io_msStatus_3_bits_set;
  wire [8:0] i_io_msStatus_3_bits_set;
  wire [30:0] g_io_msStatus_3_bits_reqTag;
  wire [30:0] i_io_msStatus_3_bits_reqTag;
  wire g_io_msStatus_3_bits_is_miss;
  wire i_io_msStatus_3_bits_is_miss;
  wire g_io_msStatus_3_bits_is_prefetch;
  wire i_io_msStatus_3_bits_is_prefetch;
  wire g_io_msStatus_4_valid;
  wire i_io_msStatus_4_valid;
  wire [2:0] g_io_msStatus_4_bits_channel;
  wire [2:0] i_io_msStatus_4_bits_channel;
  wire [8:0] g_io_msStatus_4_bits_set;
  wire [8:0] i_io_msStatus_4_bits_set;
  wire [30:0] g_io_msStatus_4_bits_reqTag;
  wire [30:0] i_io_msStatus_4_bits_reqTag;
  wire g_io_msStatus_4_bits_is_miss;
  wire i_io_msStatus_4_bits_is_miss;
  wire g_io_msStatus_4_bits_is_prefetch;
  wire i_io_msStatus_4_bits_is_prefetch;
  wire g_io_msStatus_5_valid;
  wire i_io_msStatus_5_valid;
  wire [2:0] g_io_msStatus_5_bits_channel;
  wire [2:0] i_io_msStatus_5_bits_channel;
  wire [8:0] g_io_msStatus_5_bits_set;
  wire [8:0] i_io_msStatus_5_bits_set;
  wire [30:0] g_io_msStatus_5_bits_reqTag;
  wire [30:0] i_io_msStatus_5_bits_reqTag;
  wire g_io_msStatus_5_bits_is_miss;
  wire i_io_msStatus_5_bits_is_miss;
  wire g_io_msStatus_5_bits_is_prefetch;
  wire i_io_msStatus_5_bits_is_prefetch;
  wire g_io_msStatus_6_valid;
  wire i_io_msStatus_6_valid;
  wire [2:0] g_io_msStatus_6_bits_channel;
  wire [2:0] i_io_msStatus_6_bits_channel;
  wire [8:0] g_io_msStatus_6_bits_set;
  wire [8:0] i_io_msStatus_6_bits_set;
  wire [30:0] g_io_msStatus_6_bits_reqTag;
  wire [30:0] i_io_msStatus_6_bits_reqTag;
  wire g_io_msStatus_6_bits_is_miss;
  wire i_io_msStatus_6_bits_is_miss;
  wire g_io_msStatus_6_bits_is_prefetch;
  wire i_io_msStatus_6_bits_is_prefetch;
  wire g_io_msStatus_7_valid;
  wire i_io_msStatus_7_valid;
  wire [2:0] g_io_msStatus_7_bits_channel;
  wire [2:0] i_io_msStatus_7_bits_channel;
  wire [8:0] g_io_msStatus_7_bits_set;
  wire [8:0] i_io_msStatus_7_bits_set;
  wire [30:0] g_io_msStatus_7_bits_reqTag;
  wire [30:0] i_io_msStatus_7_bits_reqTag;
  wire g_io_msStatus_7_bits_is_miss;
  wire i_io_msStatus_7_bits_is_miss;
  wire g_io_msStatus_7_bits_is_prefetch;
  wire i_io_msStatus_7_bits_is_prefetch;
  wire g_io_msStatus_8_valid;
  wire i_io_msStatus_8_valid;
  wire [2:0] g_io_msStatus_8_bits_channel;
  wire [2:0] i_io_msStatus_8_bits_channel;
  wire [8:0] g_io_msStatus_8_bits_set;
  wire [8:0] i_io_msStatus_8_bits_set;
  wire [30:0] g_io_msStatus_8_bits_reqTag;
  wire [30:0] i_io_msStatus_8_bits_reqTag;
  wire g_io_msStatus_8_bits_is_miss;
  wire i_io_msStatus_8_bits_is_miss;
  wire g_io_msStatus_8_bits_is_prefetch;
  wire i_io_msStatus_8_bits_is_prefetch;
  wire g_io_msStatus_9_valid;
  wire i_io_msStatus_9_valid;
  wire [2:0] g_io_msStatus_9_bits_channel;
  wire [2:0] i_io_msStatus_9_bits_channel;
  wire [8:0] g_io_msStatus_9_bits_set;
  wire [8:0] i_io_msStatus_9_bits_set;
  wire [30:0] g_io_msStatus_9_bits_reqTag;
  wire [30:0] i_io_msStatus_9_bits_reqTag;
  wire g_io_msStatus_9_bits_is_miss;
  wire i_io_msStatus_9_bits_is_miss;
  wire g_io_msStatus_9_bits_is_prefetch;
  wire i_io_msStatus_9_bits_is_prefetch;
  wire g_io_msStatus_10_valid;
  wire i_io_msStatus_10_valid;
  wire [2:0] g_io_msStatus_10_bits_channel;
  wire [2:0] i_io_msStatus_10_bits_channel;
  wire [8:0] g_io_msStatus_10_bits_set;
  wire [8:0] i_io_msStatus_10_bits_set;
  wire [30:0] g_io_msStatus_10_bits_reqTag;
  wire [30:0] i_io_msStatus_10_bits_reqTag;
  wire g_io_msStatus_10_bits_is_miss;
  wire i_io_msStatus_10_bits_is_miss;
  wire g_io_msStatus_10_bits_is_prefetch;
  wire i_io_msStatus_10_bits_is_prefetch;
  wire g_io_msStatus_11_valid;
  wire i_io_msStatus_11_valid;
  wire [2:0] g_io_msStatus_11_bits_channel;
  wire [2:0] i_io_msStatus_11_bits_channel;
  wire [8:0] g_io_msStatus_11_bits_set;
  wire [8:0] i_io_msStatus_11_bits_set;
  wire [30:0] g_io_msStatus_11_bits_reqTag;
  wire [30:0] i_io_msStatus_11_bits_reqTag;
  wire g_io_msStatus_11_bits_is_miss;
  wire i_io_msStatus_11_bits_is_miss;
  wire g_io_msStatus_11_bits_is_prefetch;
  wire i_io_msStatus_11_bits_is_prefetch;
  wire g_io_msStatus_12_valid;
  wire i_io_msStatus_12_valid;
  wire [2:0] g_io_msStatus_12_bits_channel;
  wire [2:0] i_io_msStatus_12_bits_channel;
  wire [8:0] g_io_msStatus_12_bits_set;
  wire [8:0] i_io_msStatus_12_bits_set;
  wire [30:0] g_io_msStatus_12_bits_reqTag;
  wire [30:0] i_io_msStatus_12_bits_reqTag;
  wire g_io_msStatus_12_bits_is_miss;
  wire i_io_msStatus_12_bits_is_miss;
  wire g_io_msStatus_12_bits_is_prefetch;
  wire i_io_msStatus_12_bits_is_prefetch;
  wire g_io_msStatus_13_valid;
  wire i_io_msStatus_13_valid;
  wire [2:0] g_io_msStatus_13_bits_channel;
  wire [2:0] i_io_msStatus_13_bits_channel;
  wire [8:0] g_io_msStatus_13_bits_set;
  wire [8:0] i_io_msStatus_13_bits_set;
  wire [30:0] g_io_msStatus_13_bits_reqTag;
  wire [30:0] i_io_msStatus_13_bits_reqTag;
  wire g_io_msStatus_13_bits_is_miss;
  wire i_io_msStatus_13_bits_is_miss;
  wire g_io_msStatus_13_bits_is_prefetch;
  wire i_io_msStatus_13_bits_is_prefetch;
  wire g_io_msStatus_14_valid;
  wire i_io_msStatus_14_valid;
  wire [2:0] g_io_msStatus_14_bits_channel;
  wire [2:0] i_io_msStatus_14_bits_channel;
  wire [8:0] g_io_msStatus_14_bits_set;
  wire [8:0] i_io_msStatus_14_bits_set;
  wire [30:0] g_io_msStatus_14_bits_reqTag;
  wire [30:0] i_io_msStatus_14_bits_reqTag;
  wire g_io_msStatus_14_bits_is_miss;
  wire i_io_msStatus_14_bits_is_miss;
  wire g_io_msStatus_14_bits_is_prefetch;
  wire i_io_msStatus_14_bits_is_prefetch;
  wire g_io_msStatus_15_valid;
  wire i_io_msStatus_15_valid;
  wire [2:0] g_io_msStatus_15_bits_channel;
  wire [2:0] i_io_msStatus_15_bits_channel;
  wire [8:0] g_io_msStatus_15_bits_set;
  wire [8:0] i_io_msStatus_15_bits_set;
  wire [30:0] g_io_msStatus_15_bits_reqTag;
  wire [30:0] i_io_msStatus_15_bits_reqTag;
  wire g_io_msStatus_15_bits_is_miss;
  wire i_io_msStatus_15_bits_is_miss;
  wire g_io_msStatus_15_bits_is_prefetch;
  wire i_io_msStatus_15_bits_is_prefetch;
  wire g_io_pCrd_0_query_valid;
  wire i_io_pCrd_0_query_valid;
  wire [3:0] g_io_pCrd_0_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_0_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_0_query_bits_srcID;
  wire [10:0] i_io_pCrd_0_query_bits_srcID;
  wire g_io_pCrd_1_query_valid;
  wire i_io_pCrd_1_query_valid;
  wire [3:0] g_io_pCrd_1_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_1_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_1_query_bits_srcID;
  wire [10:0] i_io_pCrd_1_query_bits_srcID;
  wire g_io_pCrd_2_query_valid;
  wire i_io_pCrd_2_query_valid;
  wire [3:0] g_io_pCrd_2_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_2_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_2_query_bits_srcID;
  wire [10:0] i_io_pCrd_2_query_bits_srcID;
  wire g_io_pCrd_3_query_valid;
  wire i_io_pCrd_3_query_valid;
  wire [3:0] g_io_pCrd_3_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_3_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_3_query_bits_srcID;
  wire [10:0] i_io_pCrd_3_query_bits_srcID;
  wire g_io_pCrd_4_query_valid;
  wire i_io_pCrd_4_query_valid;
  wire [3:0] g_io_pCrd_4_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_4_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_4_query_bits_srcID;
  wire [10:0] i_io_pCrd_4_query_bits_srcID;
  wire g_io_pCrd_5_query_valid;
  wire i_io_pCrd_5_query_valid;
  wire [3:0] g_io_pCrd_5_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_5_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_5_query_bits_srcID;
  wire [10:0] i_io_pCrd_5_query_bits_srcID;
  wire g_io_pCrd_6_query_valid;
  wire i_io_pCrd_6_query_valid;
  wire [3:0] g_io_pCrd_6_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_6_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_6_query_bits_srcID;
  wire [10:0] i_io_pCrd_6_query_bits_srcID;
  wire g_io_pCrd_7_query_valid;
  wire i_io_pCrd_7_query_valid;
  wire [3:0] g_io_pCrd_7_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_7_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_7_query_bits_srcID;
  wire [10:0] i_io_pCrd_7_query_bits_srcID;
  wire g_io_pCrd_8_query_valid;
  wire i_io_pCrd_8_query_valid;
  wire [3:0] g_io_pCrd_8_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_8_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_8_query_bits_srcID;
  wire [10:0] i_io_pCrd_8_query_bits_srcID;
  wire g_io_pCrd_9_query_valid;
  wire i_io_pCrd_9_query_valid;
  wire [3:0] g_io_pCrd_9_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_9_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_9_query_bits_srcID;
  wire [10:0] i_io_pCrd_9_query_bits_srcID;
  wire g_io_pCrd_10_query_valid;
  wire i_io_pCrd_10_query_valid;
  wire [3:0] g_io_pCrd_10_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_10_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_10_query_bits_srcID;
  wire [10:0] i_io_pCrd_10_query_bits_srcID;
  wire g_io_pCrd_11_query_valid;
  wire i_io_pCrd_11_query_valid;
  wire [3:0] g_io_pCrd_11_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_11_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_11_query_bits_srcID;
  wire [10:0] i_io_pCrd_11_query_bits_srcID;
  wire g_io_pCrd_12_query_valid;
  wire i_io_pCrd_12_query_valid;
  wire [3:0] g_io_pCrd_12_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_12_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_12_query_bits_srcID;
  wire [10:0] i_io_pCrd_12_query_bits_srcID;
  wire g_io_pCrd_13_query_valid;
  wire i_io_pCrd_13_query_valid;
  wire [3:0] g_io_pCrd_13_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_13_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_13_query_bits_srcID;
  wire [10:0] i_io_pCrd_13_query_bits_srcID;
  wire g_io_pCrd_14_query_valid;
  wire i_io_pCrd_14_query_valid;
  wire [3:0] g_io_pCrd_14_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_14_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_14_query_bits_srcID;
  wire [10:0] i_io_pCrd_14_query_bits_srcID;
  wire g_io_pCrd_15_query_valid;
  wire i_io_pCrd_15_query_valid;
  wire [3:0] g_io_pCrd_15_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_15_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_15_query_bits_srcID;
  wire [10:0] i_io_pCrd_15_query_bits_srcID;
  wire g_io_l2Miss;
  wire i_io_l2Miss;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;

  MSHRCtl u_g (
    .clock(clock),
    .reset(reset),
    .io_toReqArb_blockA_s1(g_io_toReqArb_blockA_s1),
    .io_toReqArb_blockB_s1(g_io_toReqArb_blockB_s1),
    .io_fromMainPipe_mshr_alloc_s3_valid(io_fromMainPipe_mshr_alloc_s3_valid),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire(io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe(io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe(io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_release(io_fromMainPipe_mshr_alloc_s3_bits_state_s_release),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack(io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill(io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp(io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack(io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp(io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack(io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct(io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_channel(io_fromMainPipe_mshr_alloc_s3_bits_task_channel),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_set(io_fromMainPipe_mshr_alloc_s3_bits_task_set),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_tag(io_fromMainPipe_mshr_alloc_s3_bits_task_tag),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_off(io_fromMainPipe_mshr_alloc_s3_bits_task_off),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_alias(io_fromMainPipe_mshr_alloc_s3_bits_task_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword(io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_opcode(io_fromMainPipe_mshr_alloc_s3_bits_task_opcode),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_param(io_fromMainPipe_mshr_alloc_s3_bits_task_param),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId(io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask(io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft(io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource(io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_srcID(io_fromMainPipe_mshr_alloc_s3_bits_task_srcID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_txnID(io_fromMainPipe_mshr_alloc_s3_bits_task_txnID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID(io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID(io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode(io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc(io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag(io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag),
    .io_toMainPipe_mshr_alloc_ptr(g_io_toMainPipe_mshr_alloc_ptr),
    .io_mshrTask_ready(io_mshrTask_ready),
    .io_mshrTask_valid(g_io_mshrTask_valid),
    .io_mshrTask_bits_channel(g_io_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel(g_io_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set(g_io_mshrTask_bits_set),
    .io_mshrTask_bits_tag(g_io_mshrTask_bits_tag),
    .io_mshrTask_bits_off(g_io_mshrTask_bits_off),
    .io_mshrTask_bits_alias(g_io_mshrTask_bits_alias),
    .io_mshrTask_bits_isKeyword(g_io_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode(g_io_mshrTask_bits_opcode),
    .io_mshrTask_bits_param(g_io_mshrTask_bits_param),
    .io_mshrTask_bits_size(g_io_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId(g_io_mshrTask_bits_sourceId),
    .io_mshrTask_bits_denied(g_io_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt(g_io_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask(g_io_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId(g_io_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask(g_io_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData(g_io_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry(g_io_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown(g_io_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft(g_io_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_dirty(g_io_mshrTask_bits_dirty),
    .io_mshrTask_bits_way(g_io_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty(g_io_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state(g_io_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients(g_io_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias(g_io_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch(g_io_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc(g_io_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed(g_io_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr(g_io_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr(g_io_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen(g_io_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen(g_io_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen(g_io_mshrTask_bits_dsWen),
    .io_mshrTask_bits_replTask(g_io_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask(g_io_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_reqSource(g_io_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA(g_io_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off(g_io_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias(g_io_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr(g_io_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword(g_io_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode(g_io_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param(g_io_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId(g_io_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty(g_io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state(g_io_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients(g_io_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias(g_io_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_accessed(g_io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_snpHitRelease(g_io_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval(g_io_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean(g_io_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData(g_io_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx(g_io_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty(g_io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state(g_io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients(g_io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias(g_io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch(g_io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc(g_io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed(g_io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr(g_io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr(g_io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID(g_io_mshrTask_bits_tgtID),
    .io_mshrTask_bits_txnID(g_io_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID(g_io_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID(g_io_mshrTask_bits_dbID),
    .io_mshrTask_bits_chiOpcode(g_io_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp(g_io_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState(g_io_mshrTask_bits_fwdState),
    .io_mshrTask_bits_retToSrc(g_io_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared(g_io_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck(g_io_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry(g_io_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate(g_io_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable(g_io_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_ewa(g_io_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag(g_io_mshrTask_bits_traceTag),
    .io_mshrTask_bits_dataCheckErr(g_io_mshrTask_bits_dataCheckErr),
    .io_pipeStatusVec_0_valid(io_pipeStatusVec_0_valid),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_toTXREQ_ready(io_toTXREQ_ready),
    .io_toTXREQ_valid(g_io_toTXREQ_valid),
    .io_toTXREQ_bits_qos(g_io_toTXREQ_bits_qos),
    .io_toTXREQ_bits_tgtID(g_io_toTXREQ_bits_tgtID),
    .io_toTXREQ_bits_txnID(g_io_toTXREQ_bits_txnID),
    .io_toTXREQ_bits_opcode(g_io_toTXREQ_bits_opcode),
    .io_toTXREQ_bits_size(g_io_toTXREQ_bits_size),
    .io_toTXREQ_bits_addr(g_io_toTXREQ_bits_addr),
    .io_toTXREQ_bits_likelyshared(g_io_toTXREQ_bits_likelyshared),
    .io_toTXREQ_bits_allowRetry(g_io_toTXREQ_bits_allowRetry),
    .io_toTXREQ_bits_pCrdType(g_io_toTXREQ_bits_pCrdType),
    .io_toTXREQ_bits_memAttr_allocate(g_io_toTXREQ_bits_memAttr_allocate),
    .io_toTXREQ_bits_memAttr_cacheable(g_io_toTXREQ_bits_memAttr_cacheable),
    .io_toTXREQ_bits_memAttr_ewa(g_io_toTXREQ_bits_memAttr_ewa),
    .io_toTXREQ_bits_snpAttr(g_io_toTXREQ_bits_snpAttr),
    .io_toTXREQ_bits_expCompAck(g_io_toTXREQ_bits_expCompAck),
    .io_toTXRSP_ready(io_toTXRSP_ready),
    .io_toTXRSP_valid(g_io_toTXRSP_valid),
    .io_toTXRSP_bits_tgtID(g_io_toTXRSP_bits_tgtID),
    .io_toTXRSP_bits_txnID(g_io_toTXRSP_bits_txnID),
    .io_toTXRSP_bits_opcode(g_io_toTXRSP_bits_opcode),
    .io_toTXRSP_bits_traceTag(g_io_toTXRSP_bits_traceTag),
    .io_toSourceB_ready(io_toSourceB_ready),
    .io_toSourceB_valid(g_io_toSourceB_valid),
    .io_toSourceB_bits_opcode(g_io_toSourceB_bits_opcode),
    .io_toSourceB_bits_param(g_io_toSourceB_bits_param),
    .io_toSourceB_bits_address(g_io_toSourceB_bits_address),
    .io_toSourceB_bits_data(g_io_toSourceB_bits_data),
    .io_grantStatus_0_valid(io_grantStatus_0_valid),
    .io_grantStatus_0_set(io_grantStatus_0_set),
    .io_grantStatus_0_tag(io_grantStatus_0_tag),
    .io_grantStatus_1_valid(io_grantStatus_1_valid),
    .io_grantStatus_1_set(io_grantStatus_1_set),
    .io_grantStatus_1_tag(io_grantStatus_1_tag),
    .io_grantStatus_2_valid(io_grantStatus_2_valid),
    .io_grantStatus_2_set(io_grantStatus_2_set),
    .io_grantStatus_2_tag(io_grantStatus_2_tag),
    .io_grantStatus_3_valid(io_grantStatus_3_valid),
    .io_grantStatus_3_set(io_grantStatus_3_set),
    .io_grantStatus_3_tag(io_grantStatus_3_tag),
    .io_grantStatus_4_valid(io_grantStatus_4_valid),
    .io_grantStatus_4_set(io_grantStatus_4_set),
    .io_grantStatus_4_tag(io_grantStatus_4_tag),
    .io_grantStatus_5_valid(io_grantStatus_5_valid),
    .io_grantStatus_5_set(io_grantStatus_5_set),
    .io_grantStatus_5_tag(io_grantStatus_5_tag),
    .io_grantStatus_6_valid(io_grantStatus_6_valid),
    .io_grantStatus_6_set(io_grantStatus_6_set),
    .io_grantStatus_6_tag(io_grantStatus_6_tag),
    .io_grantStatus_7_valid(io_grantStatus_7_valid),
    .io_grantStatus_7_set(io_grantStatus_7_set),
    .io_grantStatus_7_tag(io_grantStatus_7_tag),
    .io_grantStatus_8_valid(io_grantStatus_8_valid),
    .io_grantStatus_8_set(io_grantStatus_8_set),
    .io_grantStatus_8_tag(io_grantStatus_8_tag),
    .io_grantStatus_9_valid(io_grantStatus_9_valid),
    .io_grantStatus_9_set(io_grantStatus_9_set),
    .io_grantStatus_9_tag(io_grantStatus_9_tag),
    .io_grantStatus_10_valid(io_grantStatus_10_valid),
    .io_grantStatus_10_set(io_grantStatus_10_set),
    .io_grantStatus_10_tag(io_grantStatus_10_tag),
    .io_grantStatus_11_valid(io_grantStatus_11_valid),
    .io_grantStatus_11_set(io_grantStatus_11_set),
    .io_grantStatus_11_tag(io_grantStatus_11_tag),
    .io_grantStatus_12_valid(io_grantStatus_12_valid),
    .io_grantStatus_12_set(io_grantStatus_12_set),
    .io_grantStatus_12_tag(io_grantStatus_12_tag),
    .io_grantStatus_13_valid(io_grantStatus_13_valid),
    .io_grantStatus_13_set(io_grantStatus_13_set),
    .io_grantStatus_13_tag(io_grantStatus_13_tag),
    .io_grantStatus_14_valid(io_grantStatus_14_valid),
    .io_grantStatus_14_set(io_grantStatus_14_set),
    .io_grantStatus_14_tag(io_grantStatus_14_tag),
    .io_grantStatus_15_valid(io_grantStatus_15_valid),
    .io_grantStatus_15_set(io_grantStatus_15_set),
    .io_grantStatus_15_tag(io_grantStatus_15_tag),
    .io_resps_sinkC_valid(io_resps_sinkC_valid),
    .io_resps_sinkC_set(io_resps_sinkC_set),
    .io_resps_sinkC_tag(io_resps_sinkC_tag),
    .io_resps_sinkC_respInfo_opcode(io_resps_sinkC_respInfo_opcode),
    .io_resps_sinkC_respInfo_param(io_resps_sinkC_respInfo_param),
    .io_resps_sinkC_respInfo_last(io_resps_sinkC_respInfo_last),
    .io_resps_sinkC_respInfo_denied(io_resps_sinkC_respInfo_denied),
    .io_resps_sinkC_respInfo_corrupt(io_resps_sinkC_respInfo_corrupt),
    .io_resps_rxrsp_valid(io_resps_rxrsp_valid),
    .io_resps_rxrsp_mshrId(io_resps_rxrsp_mshrId),
    .io_resps_rxrsp_respInfo_chiOpcode(io_resps_rxrsp_respInfo_chiOpcode),
    .io_resps_rxrsp_respInfo_srcID(io_resps_rxrsp_respInfo_srcID),
    .io_resps_rxrsp_respInfo_dbID(io_resps_rxrsp_respInfo_dbID),
    .io_resps_rxrsp_respInfo_resp(io_resps_rxrsp_respInfo_resp),
    .io_resps_rxrsp_respInfo_pCrdType(io_resps_rxrsp_respInfo_pCrdType),
    .io_resps_rxrsp_respInfo_respErr(io_resps_rxrsp_respInfo_respErr),
    .io_resps_rxrsp_respInfo_traceTag(io_resps_rxrsp_respInfo_traceTag),
    .io_resps_rxdat_valid(io_resps_rxdat_valid),
    .io_resps_rxdat_mshrId(io_resps_rxdat_mshrId),
    .io_resps_rxdat_respInfo_last(io_resps_rxdat_respInfo_last),
    .io_resps_rxdat_respInfo_corrupt(io_resps_rxdat_respInfo_corrupt),
    .io_resps_rxdat_respInfo_chiOpcode(io_resps_rxdat_respInfo_chiOpcode),
    .io_resps_rxdat_respInfo_homeNID(io_resps_rxdat_respInfo_homeNID),
    .io_resps_rxdat_respInfo_dbID(io_resps_rxdat_respInfo_dbID),
    .io_resps_rxdat_respInfo_resp(io_resps_rxdat_respInfo_resp),
    .io_resps_rxdat_respInfo_respErr(io_resps_rxdat_respInfo_respErr),
    .io_resps_rxdat_respInfo_traceTag(io_resps_rxdat_respInfo_traceTag),
    .io_resps_rxdat_respInfo_dataCheckErr(io_resps_rxdat_respInfo_dataCheckErr),
    .io_releaseBufWriteId(g_io_releaseBufWriteId),
    .io_nestedwb_set(io_nestedwb_set),
    .io_nestedwb_tag(io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(io_nestedwb_b_toB),
    .io_nestedwb_b_toN(io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
    .io_nestedwbDataId_valid(g_io_nestedwbDataId_valid),
    .io_nestedwbDataId_bits(g_io_nestedwbDataId_bits),
    .io_msInfo_0_valid(g_io_msInfo_0_valid),
    .io_msInfo_0_bits_channel(g_io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set(g_io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way(g_io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag(g_io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree(g_io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask(g_io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease(g_io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill(g_io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty(g_io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state(g_io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients(g_io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias(g_io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch(g_io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc(g_io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed(g_io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr(g_io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr(g_io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag(g_io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit(g_io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch(g_io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch(g_io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param(g_io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA(g_io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst(g_io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release(g_io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill(g_io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp(g_io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw(g_io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack(g_io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp(g_io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast(g_io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData(g_io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean(g_io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid(g_io_msInfo_1_valid),
    .io_msInfo_1_bits_channel(g_io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set(g_io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way(g_io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag(g_io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree(g_io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask(g_io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease(g_io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill(g_io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty(g_io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state(g_io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients(g_io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias(g_io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch(g_io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc(g_io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed(g_io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr(g_io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr(g_io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag(g_io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit(g_io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch(g_io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch(g_io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param(g_io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA(g_io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst(g_io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release(g_io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill(g_io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp(g_io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw(g_io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack(g_io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp(g_io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast(g_io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData(g_io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean(g_io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid(g_io_msInfo_2_valid),
    .io_msInfo_2_bits_channel(g_io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set(g_io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way(g_io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag(g_io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree(g_io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask(g_io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease(g_io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill(g_io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty(g_io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state(g_io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients(g_io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias(g_io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch(g_io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc(g_io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed(g_io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr(g_io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr(g_io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag(g_io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit(g_io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch(g_io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch(g_io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param(g_io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA(g_io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst(g_io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release(g_io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill(g_io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp(g_io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw(g_io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack(g_io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp(g_io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast(g_io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData(g_io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean(g_io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid(g_io_msInfo_3_valid),
    .io_msInfo_3_bits_channel(g_io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set(g_io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way(g_io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag(g_io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree(g_io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask(g_io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease(g_io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill(g_io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty(g_io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state(g_io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients(g_io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias(g_io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch(g_io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc(g_io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed(g_io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr(g_io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr(g_io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag(g_io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit(g_io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch(g_io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch(g_io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param(g_io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA(g_io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst(g_io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release(g_io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill(g_io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp(g_io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw(g_io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack(g_io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp(g_io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast(g_io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData(g_io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean(g_io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid(g_io_msInfo_4_valid),
    .io_msInfo_4_bits_channel(g_io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set(g_io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way(g_io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag(g_io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree(g_io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask(g_io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease(g_io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill(g_io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty(g_io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state(g_io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients(g_io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias(g_io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch(g_io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc(g_io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed(g_io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr(g_io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr(g_io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag(g_io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit(g_io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch(g_io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch(g_io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param(g_io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA(g_io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst(g_io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release(g_io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill(g_io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp(g_io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw(g_io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack(g_io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp(g_io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast(g_io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData(g_io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean(g_io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid(g_io_msInfo_5_valid),
    .io_msInfo_5_bits_channel(g_io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set(g_io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way(g_io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag(g_io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree(g_io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask(g_io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease(g_io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill(g_io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty(g_io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state(g_io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients(g_io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias(g_io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch(g_io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc(g_io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed(g_io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr(g_io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr(g_io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag(g_io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit(g_io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch(g_io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch(g_io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param(g_io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA(g_io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst(g_io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release(g_io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill(g_io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp(g_io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw(g_io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack(g_io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp(g_io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast(g_io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData(g_io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean(g_io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid(g_io_msInfo_6_valid),
    .io_msInfo_6_bits_channel(g_io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set(g_io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way(g_io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag(g_io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree(g_io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask(g_io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease(g_io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill(g_io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty(g_io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state(g_io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients(g_io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias(g_io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch(g_io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc(g_io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed(g_io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr(g_io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr(g_io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag(g_io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit(g_io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch(g_io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch(g_io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param(g_io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA(g_io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst(g_io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release(g_io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill(g_io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp(g_io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw(g_io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack(g_io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp(g_io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast(g_io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData(g_io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean(g_io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid(g_io_msInfo_7_valid),
    .io_msInfo_7_bits_channel(g_io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set(g_io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way(g_io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag(g_io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree(g_io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask(g_io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease(g_io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill(g_io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty(g_io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state(g_io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients(g_io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias(g_io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch(g_io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc(g_io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed(g_io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr(g_io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr(g_io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag(g_io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit(g_io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch(g_io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch(g_io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param(g_io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA(g_io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst(g_io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release(g_io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill(g_io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp(g_io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw(g_io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack(g_io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp(g_io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast(g_io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData(g_io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean(g_io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid(g_io_msInfo_8_valid),
    .io_msInfo_8_bits_channel(g_io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set(g_io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way(g_io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag(g_io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree(g_io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask(g_io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease(g_io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill(g_io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty(g_io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state(g_io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients(g_io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias(g_io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch(g_io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc(g_io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed(g_io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr(g_io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr(g_io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag(g_io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit(g_io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch(g_io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch(g_io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param(g_io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA(g_io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst(g_io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release(g_io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill(g_io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp(g_io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw(g_io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack(g_io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp(g_io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast(g_io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData(g_io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean(g_io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid(g_io_msInfo_9_valid),
    .io_msInfo_9_bits_channel(g_io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set(g_io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way(g_io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag(g_io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree(g_io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask(g_io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease(g_io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill(g_io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty(g_io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state(g_io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients(g_io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias(g_io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch(g_io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc(g_io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed(g_io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr(g_io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr(g_io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag(g_io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit(g_io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch(g_io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch(g_io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param(g_io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA(g_io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst(g_io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release(g_io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill(g_io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp(g_io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw(g_io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack(g_io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp(g_io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast(g_io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData(g_io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean(g_io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid(g_io_msInfo_10_valid),
    .io_msInfo_10_bits_channel(g_io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set(g_io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way(g_io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag(g_io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree(g_io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask(g_io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease(g_io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill(g_io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty(g_io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state(g_io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients(g_io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias(g_io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch(g_io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc(g_io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed(g_io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr(g_io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr(g_io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag(g_io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit(g_io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch(g_io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch(g_io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param(g_io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA(g_io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst(g_io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release(g_io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill(g_io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp(g_io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw(g_io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack(g_io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp(g_io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast(g_io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData(g_io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean(g_io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid(g_io_msInfo_11_valid),
    .io_msInfo_11_bits_channel(g_io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set(g_io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way(g_io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag(g_io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree(g_io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask(g_io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease(g_io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill(g_io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty(g_io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state(g_io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients(g_io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias(g_io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch(g_io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc(g_io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed(g_io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr(g_io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr(g_io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag(g_io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit(g_io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch(g_io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch(g_io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param(g_io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA(g_io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst(g_io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release(g_io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill(g_io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp(g_io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw(g_io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack(g_io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp(g_io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast(g_io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData(g_io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean(g_io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid(g_io_msInfo_12_valid),
    .io_msInfo_12_bits_channel(g_io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set(g_io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way(g_io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag(g_io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree(g_io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask(g_io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease(g_io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill(g_io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty(g_io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state(g_io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients(g_io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias(g_io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch(g_io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc(g_io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed(g_io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr(g_io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr(g_io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag(g_io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit(g_io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch(g_io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch(g_io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param(g_io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA(g_io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst(g_io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release(g_io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill(g_io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp(g_io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw(g_io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack(g_io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp(g_io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast(g_io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData(g_io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean(g_io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid(g_io_msInfo_13_valid),
    .io_msInfo_13_bits_channel(g_io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set(g_io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way(g_io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag(g_io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree(g_io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask(g_io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease(g_io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill(g_io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty(g_io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state(g_io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients(g_io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias(g_io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch(g_io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc(g_io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed(g_io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr(g_io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr(g_io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag(g_io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit(g_io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch(g_io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch(g_io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param(g_io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA(g_io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst(g_io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release(g_io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill(g_io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp(g_io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw(g_io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack(g_io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp(g_io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast(g_io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData(g_io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean(g_io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid(g_io_msInfo_14_valid),
    .io_msInfo_14_bits_channel(g_io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set(g_io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way(g_io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag(g_io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree(g_io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask(g_io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease(g_io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill(g_io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty(g_io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state(g_io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients(g_io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias(g_io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch(g_io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc(g_io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed(g_io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr(g_io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr(g_io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag(g_io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit(g_io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch(g_io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch(g_io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param(g_io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA(g_io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst(g_io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release(g_io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill(g_io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp(g_io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw(g_io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack(g_io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp(g_io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast(g_io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData(g_io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean(g_io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid(g_io_msInfo_15_valid),
    .io_msInfo_15_bits_channel(g_io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set(g_io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way(g_io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag(g_io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree(g_io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask(g_io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease(g_io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill(g_io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty(g_io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state(g_io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients(g_io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias(g_io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch(g_io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc(g_io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed(g_io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr(g_io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr(g_io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag(g_io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit(g_io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch(g_io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch(g_io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param(g_io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA(g_io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst(g_io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release(g_io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill(g_io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp(g_io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw(g_io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack(g_io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp(g_io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast(g_io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData(g_io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean(g_io_msInfo_15_bits_releaseToClean),
    .io_aMergeTask_valid(io_aMergeTask_valid),
    .io_aMergeTask_bits_id(io_aMergeTask_bits_id),
    .io_aMergeTask_bits_task_off(io_aMergeTask_bits_task_off),
    .io_aMergeTask_bits_task_alias(io_aMergeTask_bits_task_alias),
    .io_aMergeTask_bits_task_vaddr(io_aMergeTask_bits_task_vaddr),
    .io_aMergeTask_bits_task_isKeyword(io_aMergeTask_bits_task_isKeyword),
    .io_aMergeTask_bits_task_opcode(io_aMergeTask_bits_task_opcode),
    .io_aMergeTask_bits_task_param(io_aMergeTask_bits_task_param),
    .io_aMergeTask_bits_task_sourceId(io_aMergeTask_bits_task_sourceId),
    .io_replResp_valid(io_replResp_valid),
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
    .io_replResp_bits_mshrId(io_replResp_bits_mshrId),
    .io_replResp_bits_retry(io_replResp_bits_retry),
    .io_msStatus_0_valid(g_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(g_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(g_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(g_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(g_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(g_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(g_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(g_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(g_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(g_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(g_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(g_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(g_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(g_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(g_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(g_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(g_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(g_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(g_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(g_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(g_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(g_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(g_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(g_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(g_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(g_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(g_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(g_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(g_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(g_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(g_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(g_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(g_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(g_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(g_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(g_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(g_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(g_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(g_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(g_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(g_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(g_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(g_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(g_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(g_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(g_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(g_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(g_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(g_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(g_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(g_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(g_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(g_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(g_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(g_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(g_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(g_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(g_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(g_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(g_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(g_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(g_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(g_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(g_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(g_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(g_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(g_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(g_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(g_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(g_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(g_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(g_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(g_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(g_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(g_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(g_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(g_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(g_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(g_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(g_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(g_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(g_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(g_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(g_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(g_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(g_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(g_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(g_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(g_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(g_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(g_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(g_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(g_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(g_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(g_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(g_io_msStatus_15_bits_is_prefetch),
    .io_pCrd_0_query_valid(g_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(g_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(g_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(g_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(g_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(g_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(g_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(g_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(g_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(g_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(g_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(g_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(g_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(g_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(g_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(g_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(g_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(g_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(g_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(g_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(g_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(g_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(g_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(g_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(g_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(g_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(g_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(g_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(g_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(g_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(g_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(g_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(g_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(g_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(g_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(g_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(g_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(g_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(g_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(g_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(g_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(g_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(g_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(g_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(g_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(g_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(g_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(g_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_l2Miss(g_io_l2Miss),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_3_value(g_io_perf_3_value)
  );
  MSHRCtl_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_toReqArb_blockA_s1(i_io_toReqArb_blockA_s1),
    .io_toReqArb_blockB_s1(i_io_toReqArb_blockB_s1),
    .io_fromMainPipe_mshr_alloc_s3_valid(io_fromMainPipe_mshr_alloc_s3_valid),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire(io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe(io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe(io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_release(io_fromMainPipe_mshr_alloc_s3_bits_state_s_release),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack(io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill(io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp(io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack(io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp(io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack(io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack),
    .io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct(io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_channel(io_fromMainPipe_mshr_alloc_s3_bits_task_channel),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_set(io_fromMainPipe_mshr_alloc_s3_bits_task_set),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_tag(io_fromMainPipe_mshr_alloc_s3_bits_task_tag),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_off(io_fromMainPipe_mshr_alloc_s3_bits_task_off),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_alias(io_fromMainPipe_mshr_alloc_s3_bits_task_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword(io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_opcode(io_fromMainPipe_mshr_alloc_s3_bits_task_opcode),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_param(io_fromMainPipe_mshr_alloc_s3_bits_task_param),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId(io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask(io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft(io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource(io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_srcID(io_fromMainPipe_mshr_alloc_s3_bits_task_srcID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_txnID(io_fromMainPipe_mshr_alloc_s3_bits_task_txnID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID(io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID(io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode(io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc(io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag(io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag),
    .io_toMainPipe_mshr_alloc_ptr(i_io_toMainPipe_mshr_alloc_ptr),
    .io_mshrTask_ready(io_mshrTask_ready),
    .io_mshrTask_valid(i_io_mshrTask_valid),
    .io_mshrTask_bits_channel(i_io_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel(i_io_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set(i_io_mshrTask_bits_set),
    .io_mshrTask_bits_tag(i_io_mshrTask_bits_tag),
    .io_mshrTask_bits_off(i_io_mshrTask_bits_off),
    .io_mshrTask_bits_alias(i_io_mshrTask_bits_alias),
    .io_mshrTask_bits_isKeyword(i_io_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode(i_io_mshrTask_bits_opcode),
    .io_mshrTask_bits_param(i_io_mshrTask_bits_param),
    .io_mshrTask_bits_size(i_io_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId(i_io_mshrTask_bits_sourceId),
    .io_mshrTask_bits_denied(i_io_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt(i_io_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask(i_io_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId(i_io_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask(i_io_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData(i_io_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry(i_io_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown(i_io_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft(i_io_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_dirty(i_io_mshrTask_bits_dirty),
    .io_mshrTask_bits_way(i_io_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty(i_io_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state(i_io_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients(i_io_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias(i_io_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch(i_io_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc(i_io_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed(i_io_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr(i_io_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr(i_io_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen(i_io_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen(i_io_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen(i_io_mshrTask_bits_dsWen),
    .io_mshrTask_bits_replTask(i_io_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask(i_io_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_reqSource(i_io_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA(i_io_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off(i_io_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias(i_io_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr(i_io_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword(i_io_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode(i_io_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param(i_io_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId(i_io_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty(i_io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state(i_io_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients(i_io_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias(i_io_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_accessed(i_io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_snpHitRelease(i_io_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval(i_io_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean(i_io_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData(i_io_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx(i_io_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty(i_io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state(i_io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients(i_io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias(i_io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch(i_io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc(i_io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed(i_io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr(i_io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr(i_io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID(i_io_mshrTask_bits_tgtID),
    .io_mshrTask_bits_txnID(i_io_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID(i_io_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID(i_io_mshrTask_bits_dbID),
    .io_mshrTask_bits_chiOpcode(i_io_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp(i_io_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState(i_io_mshrTask_bits_fwdState),
    .io_mshrTask_bits_retToSrc(i_io_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared(i_io_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck(i_io_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry(i_io_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate(i_io_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable(i_io_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_ewa(i_io_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag(i_io_mshrTask_bits_traceTag),
    .io_mshrTask_bits_dataCheckErr(i_io_mshrTask_bits_dataCheckErr),
    .io_pipeStatusVec_0_valid(io_pipeStatusVec_0_valid),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_toTXREQ_ready(io_toTXREQ_ready),
    .io_toTXREQ_valid(i_io_toTXREQ_valid),
    .io_toTXREQ_bits_qos(i_io_toTXREQ_bits_qos),
    .io_toTXREQ_bits_tgtID(i_io_toTXREQ_bits_tgtID),
    .io_toTXREQ_bits_txnID(i_io_toTXREQ_bits_txnID),
    .io_toTXREQ_bits_opcode(i_io_toTXREQ_bits_opcode),
    .io_toTXREQ_bits_size(i_io_toTXREQ_bits_size),
    .io_toTXREQ_bits_addr(i_io_toTXREQ_bits_addr),
    .io_toTXREQ_bits_likelyshared(i_io_toTXREQ_bits_likelyshared),
    .io_toTXREQ_bits_allowRetry(i_io_toTXREQ_bits_allowRetry),
    .io_toTXREQ_bits_pCrdType(i_io_toTXREQ_bits_pCrdType),
    .io_toTXREQ_bits_memAttr_allocate(i_io_toTXREQ_bits_memAttr_allocate),
    .io_toTXREQ_bits_memAttr_cacheable(i_io_toTXREQ_bits_memAttr_cacheable),
    .io_toTXREQ_bits_memAttr_ewa(i_io_toTXREQ_bits_memAttr_ewa),
    .io_toTXREQ_bits_snpAttr(i_io_toTXREQ_bits_snpAttr),
    .io_toTXREQ_bits_expCompAck(i_io_toTXREQ_bits_expCompAck),
    .io_toTXRSP_ready(io_toTXRSP_ready),
    .io_toTXRSP_valid(i_io_toTXRSP_valid),
    .io_toTXRSP_bits_tgtID(i_io_toTXRSP_bits_tgtID),
    .io_toTXRSP_bits_txnID(i_io_toTXRSP_bits_txnID),
    .io_toTXRSP_bits_opcode(i_io_toTXRSP_bits_opcode),
    .io_toTXRSP_bits_traceTag(i_io_toTXRSP_bits_traceTag),
    .io_toSourceB_ready(io_toSourceB_ready),
    .io_toSourceB_valid(i_io_toSourceB_valid),
    .io_toSourceB_bits_opcode(i_io_toSourceB_bits_opcode),
    .io_toSourceB_bits_param(i_io_toSourceB_bits_param),
    .io_toSourceB_bits_address(i_io_toSourceB_bits_address),
    .io_toSourceB_bits_data(i_io_toSourceB_bits_data),
    .io_grantStatus_0_valid(io_grantStatus_0_valid),
    .io_grantStatus_0_set(io_grantStatus_0_set),
    .io_grantStatus_0_tag(io_grantStatus_0_tag),
    .io_grantStatus_1_valid(io_grantStatus_1_valid),
    .io_grantStatus_1_set(io_grantStatus_1_set),
    .io_grantStatus_1_tag(io_grantStatus_1_tag),
    .io_grantStatus_2_valid(io_grantStatus_2_valid),
    .io_grantStatus_2_set(io_grantStatus_2_set),
    .io_grantStatus_2_tag(io_grantStatus_2_tag),
    .io_grantStatus_3_valid(io_grantStatus_3_valid),
    .io_grantStatus_3_set(io_grantStatus_3_set),
    .io_grantStatus_3_tag(io_grantStatus_3_tag),
    .io_grantStatus_4_valid(io_grantStatus_4_valid),
    .io_grantStatus_4_set(io_grantStatus_4_set),
    .io_grantStatus_4_tag(io_grantStatus_4_tag),
    .io_grantStatus_5_valid(io_grantStatus_5_valid),
    .io_grantStatus_5_set(io_grantStatus_5_set),
    .io_grantStatus_5_tag(io_grantStatus_5_tag),
    .io_grantStatus_6_valid(io_grantStatus_6_valid),
    .io_grantStatus_6_set(io_grantStatus_6_set),
    .io_grantStatus_6_tag(io_grantStatus_6_tag),
    .io_grantStatus_7_valid(io_grantStatus_7_valid),
    .io_grantStatus_7_set(io_grantStatus_7_set),
    .io_grantStatus_7_tag(io_grantStatus_7_tag),
    .io_grantStatus_8_valid(io_grantStatus_8_valid),
    .io_grantStatus_8_set(io_grantStatus_8_set),
    .io_grantStatus_8_tag(io_grantStatus_8_tag),
    .io_grantStatus_9_valid(io_grantStatus_9_valid),
    .io_grantStatus_9_set(io_grantStatus_9_set),
    .io_grantStatus_9_tag(io_grantStatus_9_tag),
    .io_grantStatus_10_valid(io_grantStatus_10_valid),
    .io_grantStatus_10_set(io_grantStatus_10_set),
    .io_grantStatus_10_tag(io_grantStatus_10_tag),
    .io_grantStatus_11_valid(io_grantStatus_11_valid),
    .io_grantStatus_11_set(io_grantStatus_11_set),
    .io_grantStatus_11_tag(io_grantStatus_11_tag),
    .io_grantStatus_12_valid(io_grantStatus_12_valid),
    .io_grantStatus_12_set(io_grantStatus_12_set),
    .io_grantStatus_12_tag(io_grantStatus_12_tag),
    .io_grantStatus_13_valid(io_grantStatus_13_valid),
    .io_grantStatus_13_set(io_grantStatus_13_set),
    .io_grantStatus_13_tag(io_grantStatus_13_tag),
    .io_grantStatus_14_valid(io_grantStatus_14_valid),
    .io_grantStatus_14_set(io_grantStatus_14_set),
    .io_grantStatus_14_tag(io_grantStatus_14_tag),
    .io_grantStatus_15_valid(io_grantStatus_15_valid),
    .io_grantStatus_15_set(io_grantStatus_15_set),
    .io_grantStatus_15_tag(io_grantStatus_15_tag),
    .io_resps_sinkC_valid(io_resps_sinkC_valid),
    .io_resps_sinkC_set(io_resps_sinkC_set),
    .io_resps_sinkC_tag(io_resps_sinkC_tag),
    .io_resps_sinkC_respInfo_opcode(io_resps_sinkC_respInfo_opcode),
    .io_resps_sinkC_respInfo_param(io_resps_sinkC_respInfo_param),
    .io_resps_sinkC_respInfo_last(io_resps_sinkC_respInfo_last),
    .io_resps_sinkC_respInfo_denied(io_resps_sinkC_respInfo_denied),
    .io_resps_sinkC_respInfo_corrupt(io_resps_sinkC_respInfo_corrupt),
    .io_resps_rxrsp_valid(io_resps_rxrsp_valid),
    .io_resps_rxrsp_mshrId(io_resps_rxrsp_mshrId),
    .io_resps_rxrsp_respInfo_chiOpcode(io_resps_rxrsp_respInfo_chiOpcode),
    .io_resps_rxrsp_respInfo_srcID(io_resps_rxrsp_respInfo_srcID),
    .io_resps_rxrsp_respInfo_dbID(io_resps_rxrsp_respInfo_dbID),
    .io_resps_rxrsp_respInfo_resp(io_resps_rxrsp_respInfo_resp),
    .io_resps_rxrsp_respInfo_pCrdType(io_resps_rxrsp_respInfo_pCrdType),
    .io_resps_rxrsp_respInfo_respErr(io_resps_rxrsp_respInfo_respErr),
    .io_resps_rxrsp_respInfo_traceTag(io_resps_rxrsp_respInfo_traceTag),
    .io_resps_rxdat_valid(io_resps_rxdat_valid),
    .io_resps_rxdat_mshrId(io_resps_rxdat_mshrId),
    .io_resps_rxdat_respInfo_last(io_resps_rxdat_respInfo_last),
    .io_resps_rxdat_respInfo_corrupt(io_resps_rxdat_respInfo_corrupt),
    .io_resps_rxdat_respInfo_chiOpcode(io_resps_rxdat_respInfo_chiOpcode),
    .io_resps_rxdat_respInfo_homeNID(io_resps_rxdat_respInfo_homeNID),
    .io_resps_rxdat_respInfo_dbID(io_resps_rxdat_respInfo_dbID),
    .io_resps_rxdat_respInfo_resp(io_resps_rxdat_respInfo_resp),
    .io_resps_rxdat_respInfo_respErr(io_resps_rxdat_respInfo_respErr),
    .io_resps_rxdat_respInfo_traceTag(io_resps_rxdat_respInfo_traceTag),
    .io_resps_rxdat_respInfo_dataCheckErr(io_resps_rxdat_respInfo_dataCheckErr),
    .io_releaseBufWriteId(i_io_releaseBufWriteId),
    .io_nestedwb_set(io_nestedwb_set),
    .io_nestedwb_tag(io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(io_nestedwb_b_toB),
    .io_nestedwb_b_toN(io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
    .io_nestedwbDataId_valid(i_io_nestedwbDataId_valid),
    .io_nestedwbDataId_bits(i_io_nestedwbDataId_bits),
    .io_msInfo_0_valid(i_io_msInfo_0_valid),
    .io_msInfo_0_bits_channel(i_io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set(i_io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way(i_io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag(i_io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree(i_io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask(i_io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease(i_io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill(i_io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty(i_io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state(i_io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients(i_io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias(i_io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch(i_io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc(i_io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed(i_io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr(i_io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr(i_io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag(i_io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit(i_io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch(i_io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch(i_io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param(i_io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA(i_io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst(i_io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release(i_io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill(i_io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp(i_io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw(i_io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack(i_io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp(i_io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast(i_io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData(i_io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean(i_io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid(i_io_msInfo_1_valid),
    .io_msInfo_1_bits_channel(i_io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set(i_io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way(i_io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag(i_io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree(i_io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask(i_io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease(i_io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill(i_io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty(i_io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state(i_io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients(i_io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias(i_io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch(i_io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc(i_io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed(i_io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr(i_io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr(i_io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag(i_io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit(i_io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch(i_io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch(i_io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param(i_io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA(i_io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst(i_io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release(i_io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill(i_io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp(i_io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw(i_io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack(i_io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp(i_io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast(i_io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData(i_io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean(i_io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid(i_io_msInfo_2_valid),
    .io_msInfo_2_bits_channel(i_io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set(i_io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way(i_io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag(i_io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree(i_io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask(i_io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease(i_io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill(i_io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty(i_io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state(i_io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients(i_io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias(i_io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch(i_io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc(i_io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed(i_io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr(i_io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr(i_io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag(i_io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit(i_io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch(i_io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch(i_io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param(i_io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA(i_io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst(i_io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release(i_io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill(i_io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp(i_io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw(i_io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack(i_io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp(i_io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast(i_io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData(i_io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean(i_io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid(i_io_msInfo_3_valid),
    .io_msInfo_3_bits_channel(i_io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set(i_io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way(i_io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag(i_io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree(i_io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask(i_io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease(i_io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill(i_io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty(i_io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state(i_io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients(i_io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias(i_io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch(i_io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc(i_io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed(i_io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr(i_io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr(i_io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag(i_io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit(i_io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch(i_io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch(i_io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param(i_io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA(i_io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst(i_io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release(i_io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill(i_io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp(i_io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw(i_io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack(i_io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp(i_io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast(i_io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData(i_io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean(i_io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid(i_io_msInfo_4_valid),
    .io_msInfo_4_bits_channel(i_io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set(i_io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way(i_io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag(i_io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree(i_io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask(i_io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease(i_io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill(i_io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty(i_io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state(i_io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients(i_io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias(i_io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch(i_io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc(i_io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed(i_io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr(i_io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr(i_io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag(i_io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit(i_io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch(i_io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch(i_io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param(i_io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA(i_io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst(i_io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release(i_io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill(i_io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp(i_io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw(i_io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack(i_io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp(i_io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast(i_io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData(i_io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean(i_io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid(i_io_msInfo_5_valid),
    .io_msInfo_5_bits_channel(i_io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set(i_io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way(i_io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag(i_io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree(i_io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask(i_io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease(i_io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill(i_io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty(i_io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state(i_io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients(i_io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias(i_io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch(i_io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc(i_io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed(i_io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr(i_io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr(i_io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag(i_io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit(i_io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch(i_io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch(i_io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param(i_io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA(i_io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst(i_io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release(i_io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill(i_io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp(i_io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw(i_io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack(i_io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp(i_io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast(i_io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData(i_io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean(i_io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid(i_io_msInfo_6_valid),
    .io_msInfo_6_bits_channel(i_io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set(i_io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way(i_io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag(i_io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree(i_io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask(i_io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease(i_io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill(i_io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty(i_io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state(i_io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients(i_io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias(i_io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch(i_io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc(i_io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed(i_io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr(i_io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr(i_io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag(i_io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit(i_io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch(i_io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch(i_io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param(i_io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA(i_io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst(i_io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release(i_io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill(i_io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp(i_io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw(i_io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack(i_io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp(i_io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast(i_io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData(i_io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean(i_io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid(i_io_msInfo_7_valid),
    .io_msInfo_7_bits_channel(i_io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set(i_io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way(i_io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag(i_io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree(i_io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask(i_io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease(i_io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill(i_io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty(i_io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state(i_io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients(i_io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias(i_io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch(i_io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc(i_io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed(i_io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr(i_io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr(i_io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag(i_io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit(i_io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch(i_io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch(i_io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param(i_io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA(i_io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst(i_io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release(i_io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill(i_io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp(i_io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw(i_io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack(i_io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp(i_io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast(i_io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData(i_io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean(i_io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid(i_io_msInfo_8_valid),
    .io_msInfo_8_bits_channel(i_io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set(i_io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way(i_io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag(i_io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree(i_io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask(i_io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease(i_io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill(i_io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty(i_io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state(i_io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients(i_io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias(i_io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch(i_io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc(i_io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed(i_io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr(i_io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr(i_io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag(i_io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit(i_io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch(i_io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch(i_io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param(i_io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA(i_io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst(i_io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release(i_io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill(i_io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp(i_io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw(i_io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack(i_io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp(i_io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast(i_io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData(i_io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean(i_io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid(i_io_msInfo_9_valid),
    .io_msInfo_9_bits_channel(i_io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set(i_io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way(i_io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag(i_io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree(i_io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask(i_io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease(i_io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill(i_io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty(i_io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state(i_io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients(i_io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias(i_io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch(i_io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc(i_io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed(i_io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr(i_io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr(i_io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag(i_io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit(i_io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch(i_io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch(i_io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param(i_io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA(i_io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst(i_io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release(i_io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill(i_io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp(i_io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw(i_io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack(i_io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp(i_io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast(i_io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData(i_io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean(i_io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid(i_io_msInfo_10_valid),
    .io_msInfo_10_bits_channel(i_io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set(i_io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way(i_io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag(i_io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree(i_io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask(i_io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease(i_io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill(i_io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty(i_io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state(i_io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients(i_io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias(i_io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch(i_io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc(i_io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed(i_io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr(i_io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr(i_io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag(i_io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit(i_io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch(i_io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch(i_io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param(i_io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA(i_io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst(i_io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release(i_io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill(i_io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp(i_io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw(i_io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack(i_io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp(i_io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast(i_io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData(i_io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean(i_io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid(i_io_msInfo_11_valid),
    .io_msInfo_11_bits_channel(i_io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set(i_io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way(i_io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag(i_io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree(i_io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask(i_io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease(i_io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill(i_io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty(i_io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state(i_io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients(i_io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias(i_io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch(i_io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc(i_io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed(i_io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr(i_io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr(i_io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag(i_io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit(i_io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch(i_io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch(i_io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param(i_io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA(i_io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst(i_io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release(i_io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill(i_io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp(i_io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw(i_io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack(i_io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp(i_io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast(i_io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData(i_io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean(i_io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid(i_io_msInfo_12_valid),
    .io_msInfo_12_bits_channel(i_io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set(i_io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way(i_io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag(i_io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree(i_io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask(i_io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease(i_io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill(i_io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty(i_io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state(i_io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients(i_io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias(i_io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch(i_io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc(i_io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed(i_io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr(i_io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr(i_io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag(i_io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit(i_io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch(i_io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch(i_io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param(i_io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA(i_io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst(i_io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release(i_io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill(i_io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp(i_io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw(i_io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack(i_io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp(i_io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast(i_io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData(i_io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean(i_io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid(i_io_msInfo_13_valid),
    .io_msInfo_13_bits_channel(i_io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set(i_io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way(i_io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag(i_io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree(i_io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask(i_io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease(i_io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill(i_io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty(i_io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state(i_io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients(i_io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias(i_io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch(i_io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc(i_io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed(i_io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr(i_io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr(i_io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag(i_io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit(i_io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch(i_io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch(i_io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param(i_io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA(i_io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst(i_io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release(i_io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill(i_io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp(i_io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw(i_io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack(i_io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp(i_io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast(i_io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData(i_io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean(i_io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid(i_io_msInfo_14_valid),
    .io_msInfo_14_bits_channel(i_io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set(i_io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way(i_io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag(i_io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree(i_io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask(i_io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease(i_io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill(i_io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty(i_io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state(i_io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients(i_io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias(i_io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch(i_io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc(i_io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed(i_io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr(i_io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr(i_io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag(i_io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit(i_io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch(i_io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch(i_io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param(i_io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA(i_io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst(i_io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release(i_io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill(i_io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp(i_io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw(i_io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack(i_io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp(i_io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast(i_io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData(i_io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean(i_io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid(i_io_msInfo_15_valid),
    .io_msInfo_15_bits_channel(i_io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set(i_io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way(i_io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag(i_io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree(i_io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask(i_io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease(i_io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill(i_io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty(i_io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state(i_io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients(i_io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias(i_io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch(i_io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc(i_io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed(i_io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr(i_io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr(i_io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag(i_io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit(i_io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch(i_io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch(i_io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param(i_io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA(i_io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst(i_io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release(i_io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill(i_io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp(i_io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw(i_io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack(i_io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp(i_io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast(i_io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData(i_io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean(i_io_msInfo_15_bits_releaseToClean),
    .io_aMergeTask_valid(io_aMergeTask_valid),
    .io_aMergeTask_bits_id(io_aMergeTask_bits_id),
    .io_aMergeTask_bits_task_off(io_aMergeTask_bits_task_off),
    .io_aMergeTask_bits_task_alias(io_aMergeTask_bits_task_alias),
    .io_aMergeTask_bits_task_vaddr(io_aMergeTask_bits_task_vaddr),
    .io_aMergeTask_bits_task_isKeyword(io_aMergeTask_bits_task_isKeyword),
    .io_aMergeTask_bits_task_opcode(io_aMergeTask_bits_task_opcode),
    .io_aMergeTask_bits_task_param(io_aMergeTask_bits_task_param),
    .io_aMergeTask_bits_task_sourceId(io_aMergeTask_bits_task_sourceId),
    .io_replResp_valid(io_replResp_valid),
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
    .io_replResp_bits_mshrId(io_replResp_bits_mshrId),
    .io_replResp_bits_retry(io_replResp_bits_retry),
    .io_msStatus_0_valid(i_io_msStatus_0_valid),
    .io_msStatus_0_bits_channel(i_io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set(i_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag(i_io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss(i_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch(i_io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid(i_io_msStatus_1_valid),
    .io_msStatus_1_bits_channel(i_io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set(i_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag(i_io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss(i_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch(i_io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid(i_io_msStatus_2_valid),
    .io_msStatus_2_bits_channel(i_io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set(i_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag(i_io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss(i_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch(i_io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid(i_io_msStatus_3_valid),
    .io_msStatus_3_bits_channel(i_io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set(i_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag(i_io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss(i_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch(i_io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid(i_io_msStatus_4_valid),
    .io_msStatus_4_bits_channel(i_io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set(i_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag(i_io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss(i_io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch(i_io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid(i_io_msStatus_5_valid),
    .io_msStatus_5_bits_channel(i_io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set(i_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag(i_io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss(i_io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch(i_io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid(i_io_msStatus_6_valid),
    .io_msStatus_6_bits_channel(i_io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set(i_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag(i_io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss(i_io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch(i_io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid(i_io_msStatus_7_valid),
    .io_msStatus_7_bits_channel(i_io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set(i_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag(i_io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss(i_io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch(i_io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid(i_io_msStatus_8_valid),
    .io_msStatus_8_bits_channel(i_io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set(i_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag(i_io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss(i_io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch(i_io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid(i_io_msStatus_9_valid),
    .io_msStatus_9_bits_channel(i_io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set(i_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag(i_io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss(i_io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch(i_io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid(i_io_msStatus_10_valid),
    .io_msStatus_10_bits_channel(i_io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set(i_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag(i_io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss(i_io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch(i_io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid(i_io_msStatus_11_valid),
    .io_msStatus_11_bits_channel(i_io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set(i_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag(i_io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss(i_io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch(i_io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid(i_io_msStatus_12_valid),
    .io_msStatus_12_bits_channel(i_io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set(i_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag(i_io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss(i_io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch(i_io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid(i_io_msStatus_13_valid),
    .io_msStatus_13_bits_channel(i_io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set(i_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag(i_io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss(i_io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch(i_io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid(i_io_msStatus_14_valid),
    .io_msStatus_14_bits_channel(i_io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set(i_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag(i_io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss(i_io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch(i_io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid(i_io_msStatus_15_valid),
    .io_msStatus_15_bits_channel(i_io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set(i_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag(i_io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss(i_io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch(i_io_msStatus_15_bits_is_prefetch),
    .io_pCrd_0_query_valid(i_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(i_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(i_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_query_valid(i_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(i_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(i_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_query_valid(i_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(i_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(i_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_query_valid(i_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(i_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(i_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_query_valid(i_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(i_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(i_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_query_valid(i_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(i_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(i_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_query_valid(i_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(i_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(i_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_query_valid(i_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(i_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(i_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .io_pCrd_8_query_valid(i_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(i_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(i_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(io_pCrd_8_grant),
    .io_pCrd_9_query_valid(i_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(i_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(i_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(io_pCrd_9_grant),
    .io_pCrd_10_query_valid(i_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(i_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(i_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(io_pCrd_10_grant),
    .io_pCrd_11_query_valid(i_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(i_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(i_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(io_pCrd_11_grant),
    .io_pCrd_12_query_valid(i_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(i_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(i_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(io_pCrd_12_grant),
    .io_pCrd_13_query_valid(i_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(i_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(i_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(io_pCrd_13_grant),
    .io_pCrd_14_query_valid(i_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(i_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(i_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(io_pCrd_14_grant),
    .io_pCrd_15_query_valid(i_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(i_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(i_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(io_pCrd_15_grant),
    .io_l2Miss(i_io_l2Miss),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_3_value(i_io_perf_3_value)
  );

  task automatic drive_random();
    io_fromMainPipe_mshr_alloc_s3_valid = ($urandom_range(0,3) == 0);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_release = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant = ($urandom_range(0,3) == 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_channel = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_set = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_tag = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_off = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_alias = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_opcode = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_param = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_srcID = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_txnID = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc = $urandom;
    io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag = $urandom;
    io_mshrTask_ready = ($urandom_range(0,3) != 0);
    io_pipeStatusVec_0_valid = ($urandom_range(0,3) == 0);
    io_pipeStatusVec_1_valid = ($urandom_range(0,3) == 0);
    io_toTXREQ_ready = ($urandom_range(0,3) != 0);
    io_toTXRSP_ready = ($urandom_range(0,3) != 0);
    io_toSourceB_ready = ($urandom_range(0,3) != 0);
    io_grantStatus_0_valid = $urandom;
    io_grantStatus_0_set = $urandom;
    io_grantStatus_0_tag = $urandom;
    io_grantStatus_1_valid = $urandom;
    io_grantStatus_1_set = $urandom;
    io_grantStatus_1_tag = $urandom;
    io_grantStatus_2_valid = $urandom;
    io_grantStatus_2_set = $urandom;
    io_grantStatus_2_tag = $urandom;
    io_grantStatus_3_valid = $urandom;
    io_grantStatus_3_set = $urandom;
    io_grantStatus_3_tag = $urandom;
    io_grantStatus_4_valid = $urandom;
    io_grantStatus_4_set = $urandom;
    io_grantStatus_4_tag = $urandom;
    io_grantStatus_5_valid = $urandom;
    io_grantStatus_5_set = $urandom;
    io_grantStatus_5_tag = $urandom;
    io_grantStatus_6_valid = $urandom;
    io_grantStatus_6_set = $urandom;
    io_grantStatus_6_tag = $urandom;
    io_grantStatus_7_valid = $urandom;
    io_grantStatus_7_set = $urandom;
    io_grantStatus_7_tag = $urandom;
    io_grantStatus_8_valid = $urandom;
    io_grantStatus_8_set = $urandom;
    io_grantStatus_8_tag = $urandom;
    io_grantStatus_9_valid = $urandom;
    io_grantStatus_9_set = $urandom;
    io_grantStatus_9_tag = $urandom;
    io_grantStatus_10_valid = $urandom;
    io_grantStatus_10_set = $urandom;
    io_grantStatus_10_tag = $urandom;
    io_grantStatus_11_valid = $urandom;
    io_grantStatus_11_set = $urandom;
    io_grantStatus_11_tag = $urandom;
    io_grantStatus_12_valid = $urandom;
    io_grantStatus_12_set = $urandom;
    io_grantStatus_12_tag = $urandom;
    io_grantStatus_13_valid = $urandom;
    io_grantStatus_13_set = $urandom;
    io_grantStatus_13_tag = $urandom;
    io_grantStatus_14_valid = $urandom;
    io_grantStatus_14_set = $urandom;
    io_grantStatus_14_tag = $urandom;
    io_grantStatus_15_valid = $urandom;
    io_grantStatus_15_set = $urandom;
    io_grantStatus_15_tag = $urandom;
    io_resps_sinkC_valid = ($urandom_range(0,3) == 0);
    io_resps_sinkC_set = $urandom;
    io_resps_sinkC_tag = $urandom;
    io_resps_sinkC_respInfo_opcode = $urandom;
    io_resps_sinkC_respInfo_param = $urandom;
    io_resps_sinkC_respInfo_last = $urandom;
    io_resps_sinkC_respInfo_denied = $urandom;
    io_resps_sinkC_respInfo_corrupt = $urandom;
    io_resps_rxrsp_valid = ($urandom_range(0,3) == 0);
    io_resps_rxrsp_mshrId = 8'($urandom_range(0,15));
    io_resps_rxrsp_respInfo_chiOpcode = $urandom;
    io_resps_rxrsp_respInfo_srcID = $urandom;
    io_resps_rxrsp_respInfo_dbID = $urandom;
    io_resps_rxrsp_respInfo_resp = $urandom;
    io_resps_rxrsp_respInfo_pCrdType = $urandom;
    io_resps_rxrsp_respInfo_respErr = $urandom;
    io_resps_rxrsp_respInfo_traceTag = $urandom;
    io_resps_rxdat_valid = ($urandom_range(0,3) == 0);
    io_resps_rxdat_mshrId = 8'($urandom_range(0,15));
    io_resps_rxdat_respInfo_last = $urandom;
    io_resps_rxdat_respInfo_corrupt = $urandom;
    io_resps_rxdat_respInfo_chiOpcode = $urandom;
    io_resps_rxdat_respInfo_homeNID = $urandom;
    io_resps_rxdat_respInfo_dbID = $urandom;
    io_resps_rxdat_respInfo_resp = $urandom;
    io_resps_rxdat_respInfo_respErr = $urandom;
    io_resps_rxdat_respInfo_traceTag = $urandom;
    io_resps_rxdat_respInfo_dataCheckErr = $urandom;
    io_nestedwb_set = $urandom;
    io_nestedwb_tag = $urandom;
    io_nestedwb_c_set_dirty = ($urandom_range(0,3) == 0);
    io_nestedwb_c_set_tip = ($urandom_range(0,3) == 0);
    io_nestedwb_b_inv_dirty = ($urandom_range(0,3) == 0);
    io_nestedwb_b_toB = ($urandom_range(0,3) == 0);
    io_nestedwb_b_toN = ($urandom_range(0,3) == 0);
    io_nestedwb_b_toClean = ($urandom_range(0,3) == 0);
    io_aMergeTask_valid = ($urandom_range(0,3) == 0);
    io_aMergeTask_bits_id = 8'($urandom_range(0,15));
    io_aMergeTask_bits_task_off = $urandom;
    io_aMergeTask_bits_task_alias = $urandom;
    io_aMergeTask_bits_task_vaddr = {$urandom, $urandom};
    io_aMergeTask_bits_task_isKeyword = $urandom;
    io_aMergeTask_bits_task_opcode = $urandom;
    io_aMergeTask_bits_task_param = $urandom;
    io_aMergeTask_bits_task_sourceId = $urandom;
    io_replResp_valid = ($urandom_range(0,3) == 0);
    io_replResp_bits_tag = $urandom;
    io_replResp_bits_way = $urandom;
    io_replResp_bits_meta_dirty = $urandom;
    io_replResp_bits_meta_state = $urandom;
    io_replResp_bits_meta_clients = $urandom;
    io_replResp_bits_meta_alias = $urandom;
    io_replResp_bits_meta_prefetch = $urandom;
    io_replResp_bits_meta_prefetchSrc = $urandom;
    io_replResp_bits_meta_accessed = $urandom;
    io_replResp_bits_meta_tagErr = $urandom;
    io_replResp_bits_meta_dataErr = $urandom;
    io_replResp_bits_mshrId = 8'($urandom_range(0,15));
    io_replResp_bits_retry = $urandom;
    io_pCrd_0_grant = ($urandom_range(0,3) == 0);
    io_pCrd_1_grant = ($urandom_range(0,3) == 0);
    io_pCrd_2_grant = ($urandom_range(0,3) == 0);
    io_pCrd_3_grant = ($urandom_range(0,3) == 0);
    io_pCrd_4_grant = ($urandom_range(0,3) == 0);
    io_pCrd_5_grant = ($urandom_range(0,3) == 0);
    io_pCrd_6_grant = ($urandom_range(0,3) == 0);
    io_pCrd_7_grant = ($urandom_range(0,3) == 0);
    io_pCrd_8_grant = ($urandom_range(0,3) == 0);
    io_pCrd_9_grant = ($urandom_range(0,3) == 0);
    io_pCrd_10_grant = ($urandom_range(0,3) == 0);
    io_pCrd_11_grant = ($urandom_range(0,3) == 0);
    io_pCrd_12_grant = ($urandom_range(0,3) == 0);
    io_pCrd_13_grant = ($urandom_range(0,3) == 0);
    io_pCrd_14_grant = ($urandom_range(0,3) == 0);
    io_pCrd_15_grant = ($urandom_range(0,3) == 0);
  endtask

  task automatic check_outputs();
    `CHK(io_toReqArb_blockA_s1)
    `CHK(io_toReqArb_blockB_s1)
    `CHK(io_toMainPipe_mshr_alloc_ptr)
    `CHK(io_mshrTask_valid)
    `CHK(io_mshrTask_bits_channel)
    `CHK(io_mshrTask_bits_txChannel)
    `CHK(io_mshrTask_bits_set)
    `CHK(io_mshrTask_bits_tag)
    `CHK(io_mshrTask_bits_off)
    `CHK(io_mshrTask_bits_alias)
    `CHK(io_mshrTask_bits_isKeyword)
    `CHK(io_mshrTask_bits_opcode)
    `CHK(io_mshrTask_bits_param)
    `CHK(io_mshrTask_bits_size)
    `CHK(io_mshrTask_bits_sourceId)
    `CHK(io_mshrTask_bits_denied)
    `CHK(io_mshrTask_bits_corrupt)
    `CHK(io_mshrTask_bits_mshrTask)
    `CHK(io_mshrTask_bits_mshrId)
    `CHK(io_mshrTask_bits_aliasTask)
    `CHK(io_mshrTask_bits_useProbeData)
    `CHK(io_mshrTask_bits_mshrRetry)
    `CHK(io_mshrTask_bits_readProbeDataDown)
    `CHK(io_mshrTask_bits_fromL2pft)
    `CHK(io_mshrTask_bits_dirty)
    `CHK(io_mshrTask_bits_way)
    `CHK(io_mshrTask_bits_meta_dirty)
    `CHK(io_mshrTask_bits_meta_state)
    `CHK(io_mshrTask_bits_meta_clients)
    `CHK(io_mshrTask_bits_meta_alias)
    `CHK(io_mshrTask_bits_meta_prefetch)
    `CHK(io_mshrTask_bits_meta_prefetchSrc)
    `CHK(io_mshrTask_bits_meta_accessed)
    `CHK(io_mshrTask_bits_meta_tagErr)
    `CHK(io_mshrTask_bits_meta_dataErr)
    `CHK(io_mshrTask_bits_metaWen)
    `CHK(io_mshrTask_bits_tagWen)
    `CHK(io_mshrTask_bits_dsWen)
    `CHK(io_mshrTask_bits_replTask)
    `CHK(io_mshrTask_bits_cmoTask)
    `CHK(io_mshrTask_bits_reqSource)
    `CHK(io_mshrTask_bits_mergeA)
    `CHK(io_mshrTask_bits_aMergeTask_off)
    `CHK(io_mshrTask_bits_aMergeTask_alias)
    `CHK(io_mshrTask_bits_aMergeTask_vaddr)
    `CHK(io_mshrTask_bits_aMergeTask_isKeyword)
    `CHK(io_mshrTask_bits_aMergeTask_opcode)
    `CHK(io_mshrTask_bits_aMergeTask_param)
    `CHK(io_mshrTask_bits_aMergeTask_sourceId)
    `CHK(io_mshrTask_bits_aMergeTask_meta_dirty)
    `CHK(io_mshrTask_bits_aMergeTask_meta_state)
    `CHK(io_mshrTask_bits_aMergeTask_meta_clients)
    `CHK(io_mshrTask_bits_aMergeTask_meta_alias)
    `CHK(io_mshrTask_bits_aMergeTask_meta_accessed)
    `CHK(io_mshrTask_bits_snpHitRelease)
    `CHK(io_mshrTask_bits_snpHitReleaseToInval)
    `CHK(io_mshrTask_bits_snpHitReleaseToClean)
    `CHK(io_mshrTask_bits_snpHitReleaseWithData)
    `CHK(io_mshrTask_bits_snpHitReleaseIdx)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_dirty)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_state)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_clients)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_alias)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_prefetch)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_accessed)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_tagErr)
    `CHK(io_mshrTask_bits_snpHitReleaseMeta_dataErr)
    `CHK(io_mshrTask_bits_tgtID)
    `CHK(io_mshrTask_bits_txnID)
    `CHK(io_mshrTask_bits_homeNID)
    `CHK(io_mshrTask_bits_dbID)
    `CHK(io_mshrTask_bits_chiOpcode)
    `CHK(io_mshrTask_bits_resp)
    `CHK(io_mshrTask_bits_fwdState)
    `CHK(io_mshrTask_bits_retToSrc)
    `CHK(io_mshrTask_bits_likelyshared)
    `CHK(io_mshrTask_bits_expCompAck)
    `CHK(io_mshrTask_bits_allowRetry)
    `CHK(io_mshrTask_bits_memAttr_allocate)
    `CHK(io_mshrTask_bits_memAttr_cacheable)
    `CHK(io_mshrTask_bits_memAttr_ewa)
    `CHK(io_mshrTask_bits_traceTag)
    `CHK(io_mshrTask_bits_dataCheckErr)
    `CHK(io_toTXREQ_valid)
    `CHK(io_toTXREQ_bits_qos)
    `CHK(io_toTXREQ_bits_tgtID)
    `CHK(io_toTXREQ_bits_txnID)
    `CHK(io_toTXREQ_bits_opcode)
    `CHK(io_toTXREQ_bits_size)
    `CHK(io_toTXREQ_bits_addr)
    `CHK(io_toTXREQ_bits_likelyshared)
    `CHK(io_toTXREQ_bits_allowRetry)
    `CHK(io_toTXREQ_bits_pCrdType)
    `CHK(io_toTXREQ_bits_memAttr_allocate)
    `CHK(io_toTXREQ_bits_memAttr_cacheable)
    `CHK(io_toTXREQ_bits_memAttr_ewa)
    `CHK(io_toTXREQ_bits_snpAttr)
    `CHK(io_toTXREQ_bits_expCompAck)
    `CHK(io_toTXRSP_valid)
    `CHK(io_toTXRSP_bits_tgtID)
    `CHK(io_toTXRSP_bits_txnID)
    `CHK(io_toTXRSP_bits_opcode)
    `CHK(io_toTXRSP_bits_traceTag)
    `CHK(io_toSourceB_valid)
    `CHK(io_toSourceB_bits_opcode)
    `CHK(io_toSourceB_bits_param)
    `CHK(io_toSourceB_bits_address)
    `CHK(io_toSourceB_bits_data)
    `CHK(io_releaseBufWriteId)
    `CHK(io_nestedwbDataId_valid)
    `CHK(io_nestedwbDataId_bits)
    `CHK(io_msInfo_0_valid)
    `CHK(io_msInfo_0_bits_channel)
    `CHK(io_msInfo_0_bits_set)
    `CHK(io_msInfo_0_bits_way)
    `CHK(io_msInfo_0_bits_reqTag)
    `CHK(io_msInfo_0_bits_willFree)
    `CHK(io_msInfo_0_bits_aliasTask)
    `CHK(io_msInfo_0_bits_needRelease)
    `CHK(io_msInfo_0_bits_blockRefill)
    `CHK(io_msInfo_0_bits_meta_dirty)
    `CHK(io_msInfo_0_bits_meta_state)
    `CHK(io_msInfo_0_bits_meta_clients)
    `CHK(io_msInfo_0_bits_meta_alias)
    `CHK(io_msInfo_0_bits_meta_prefetch)
    `CHK(io_msInfo_0_bits_meta_prefetchSrc)
    `CHK(io_msInfo_0_bits_meta_accessed)
    `CHK(io_msInfo_0_bits_meta_tagErr)
    `CHK(io_msInfo_0_bits_meta_dataErr)
    `CHK(io_msInfo_0_bits_metaTag)
    `CHK(io_msInfo_0_bits_dirHit)
    `CHK(io_msInfo_0_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_0_bits_isPrefetch)
    `CHK(io_msInfo_0_bits_param)
    `CHK(io_msInfo_0_bits_mergeA)
    `CHK(io_msInfo_0_bits_w_grantfirst)
    `CHK(io_msInfo_0_bits_s_release)
    `CHK(io_msInfo_0_bits_s_refill)
    `CHK(io_msInfo_0_bits_s_cmoresp)
    `CHK(io_msInfo_0_bits_s_cmometaw)
    `CHK(io_msInfo_0_bits_w_releaseack)
    `CHK(io_msInfo_0_bits_w_replResp)
    `CHK(io_msInfo_0_bits_w_rprobeacklast)
    `CHK(io_msInfo_0_bits_replaceData)
    `CHK(io_msInfo_0_bits_releaseToClean)
    `CHK(io_msInfo_1_valid)
    `CHK(io_msInfo_1_bits_channel)
    `CHK(io_msInfo_1_bits_set)
    `CHK(io_msInfo_1_bits_way)
    `CHK(io_msInfo_1_bits_reqTag)
    `CHK(io_msInfo_1_bits_willFree)
    `CHK(io_msInfo_1_bits_aliasTask)
    `CHK(io_msInfo_1_bits_needRelease)
    `CHK(io_msInfo_1_bits_blockRefill)
    `CHK(io_msInfo_1_bits_meta_dirty)
    `CHK(io_msInfo_1_bits_meta_state)
    `CHK(io_msInfo_1_bits_meta_clients)
    `CHK(io_msInfo_1_bits_meta_alias)
    `CHK(io_msInfo_1_bits_meta_prefetch)
    `CHK(io_msInfo_1_bits_meta_prefetchSrc)
    `CHK(io_msInfo_1_bits_meta_accessed)
    `CHK(io_msInfo_1_bits_meta_tagErr)
    `CHK(io_msInfo_1_bits_meta_dataErr)
    `CHK(io_msInfo_1_bits_metaTag)
    `CHK(io_msInfo_1_bits_dirHit)
    `CHK(io_msInfo_1_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_1_bits_isPrefetch)
    `CHK(io_msInfo_1_bits_param)
    `CHK(io_msInfo_1_bits_mergeA)
    `CHK(io_msInfo_1_bits_w_grantfirst)
    `CHK(io_msInfo_1_bits_s_release)
    `CHK(io_msInfo_1_bits_s_refill)
    `CHK(io_msInfo_1_bits_s_cmoresp)
    `CHK(io_msInfo_1_bits_s_cmometaw)
    `CHK(io_msInfo_1_bits_w_releaseack)
    `CHK(io_msInfo_1_bits_w_replResp)
    `CHK(io_msInfo_1_bits_w_rprobeacklast)
    `CHK(io_msInfo_1_bits_replaceData)
    `CHK(io_msInfo_1_bits_releaseToClean)
    `CHK(io_msInfo_2_valid)
    `CHK(io_msInfo_2_bits_channel)
    `CHK(io_msInfo_2_bits_set)
    `CHK(io_msInfo_2_bits_way)
    `CHK(io_msInfo_2_bits_reqTag)
    `CHK(io_msInfo_2_bits_willFree)
    `CHK(io_msInfo_2_bits_aliasTask)
    `CHK(io_msInfo_2_bits_needRelease)
    `CHK(io_msInfo_2_bits_blockRefill)
    `CHK(io_msInfo_2_bits_meta_dirty)
    `CHK(io_msInfo_2_bits_meta_state)
    `CHK(io_msInfo_2_bits_meta_clients)
    `CHK(io_msInfo_2_bits_meta_alias)
    `CHK(io_msInfo_2_bits_meta_prefetch)
    `CHK(io_msInfo_2_bits_meta_prefetchSrc)
    `CHK(io_msInfo_2_bits_meta_accessed)
    `CHK(io_msInfo_2_bits_meta_tagErr)
    `CHK(io_msInfo_2_bits_meta_dataErr)
    `CHK(io_msInfo_2_bits_metaTag)
    `CHK(io_msInfo_2_bits_dirHit)
    `CHK(io_msInfo_2_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_2_bits_isPrefetch)
    `CHK(io_msInfo_2_bits_param)
    `CHK(io_msInfo_2_bits_mergeA)
    `CHK(io_msInfo_2_bits_w_grantfirst)
    `CHK(io_msInfo_2_bits_s_release)
    `CHK(io_msInfo_2_bits_s_refill)
    `CHK(io_msInfo_2_bits_s_cmoresp)
    `CHK(io_msInfo_2_bits_s_cmometaw)
    `CHK(io_msInfo_2_bits_w_releaseack)
    `CHK(io_msInfo_2_bits_w_replResp)
    `CHK(io_msInfo_2_bits_w_rprobeacklast)
    `CHK(io_msInfo_2_bits_replaceData)
    `CHK(io_msInfo_2_bits_releaseToClean)
    `CHK(io_msInfo_3_valid)
    `CHK(io_msInfo_3_bits_channel)
    `CHK(io_msInfo_3_bits_set)
    `CHK(io_msInfo_3_bits_way)
    `CHK(io_msInfo_3_bits_reqTag)
    `CHK(io_msInfo_3_bits_willFree)
    `CHK(io_msInfo_3_bits_aliasTask)
    `CHK(io_msInfo_3_bits_needRelease)
    `CHK(io_msInfo_3_bits_blockRefill)
    `CHK(io_msInfo_3_bits_meta_dirty)
    `CHK(io_msInfo_3_bits_meta_state)
    `CHK(io_msInfo_3_bits_meta_clients)
    `CHK(io_msInfo_3_bits_meta_alias)
    `CHK(io_msInfo_3_bits_meta_prefetch)
    `CHK(io_msInfo_3_bits_meta_prefetchSrc)
    `CHK(io_msInfo_3_bits_meta_accessed)
    `CHK(io_msInfo_3_bits_meta_tagErr)
    `CHK(io_msInfo_3_bits_meta_dataErr)
    `CHK(io_msInfo_3_bits_metaTag)
    `CHK(io_msInfo_3_bits_dirHit)
    `CHK(io_msInfo_3_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_3_bits_isPrefetch)
    `CHK(io_msInfo_3_bits_param)
    `CHK(io_msInfo_3_bits_mergeA)
    `CHK(io_msInfo_3_bits_w_grantfirst)
    `CHK(io_msInfo_3_bits_s_release)
    `CHK(io_msInfo_3_bits_s_refill)
    `CHK(io_msInfo_3_bits_s_cmoresp)
    `CHK(io_msInfo_3_bits_s_cmometaw)
    `CHK(io_msInfo_3_bits_w_releaseack)
    `CHK(io_msInfo_3_bits_w_replResp)
    `CHK(io_msInfo_3_bits_w_rprobeacklast)
    `CHK(io_msInfo_3_bits_replaceData)
    `CHK(io_msInfo_3_bits_releaseToClean)
    `CHK(io_msInfo_4_valid)
    `CHK(io_msInfo_4_bits_channel)
    `CHK(io_msInfo_4_bits_set)
    `CHK(io_msInfo_4_bits_way)
    `CHK(io_msInfo_4_bits_reqTag)
    `CHK(io_msInfo_4_bits_willFree)
    `CHK(io_msInfo_4_bits_aliasTask)
    `CHK(io_msInfo_4_bits_needRelease)
    `CHK(io_msInfo_4_bits_blockRefill)
    `CHK(io_msInfo_4_bits_meta_dirty)
    `CHK(io_msInfo_4_bits_meta_state)
    `CHK(io_msInfo_4_bits_meta_clients)
    `CHK(io_msInfo_4_bits_meta_alias)
    `CHK(io_msInfo_4_bits_meta_prefetch)
    `CHK(io_msInfo_4_bits_meta_prefetchSrc)
    `CHK(io_msInfo_4_bits_meta_accessed)
    `CHK(io_msInfo_4_bits_meta_tagErr)
    `CHK(io_msInfo_4_bits_meta_dataErr)
    `CHK(io_msInfo_4_bits_metaTag)
    `CHK(io_msInfo_4_bits_dirHit)
    `CHK(io_msInfo_4_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_4_bits_isPrefetch)
    `CHK(io_msInfo_4_bits_param)
    `CHK(io_msInfo_4_bits_mergeA)
    `CHK(io_msInfo_4_bits_w_grantfirst)
    `CHK(io_msInfo_4_bits_s_release)
    `CHK(io_msInfo_4_bits_s_refill)
    `CHK(io_msInfo_4_bits_s_cmoresp)
    `CHK(io_msInfo_4_bits_s_cmometaw)
    `CHK(io_msInfo_4_bits_w_releaseack)
    `CHK(io_msInfo_4_bits_w_replResp)
    `CHK(io_msInfo_4_bits_w_rprobeacklast)
    `CHK(io_msInfo_4_bits_replaceData)
    `CHK(io_msInfo_4_bits_releaseToClean)
    `CHK(io_msInfo_5_valid)
    `CHK(io_msInfo_5_bits_channel)
    `CHK(io_msInfo_5_bits_set)
    `CHK(io_msInfo_5_bits_way)
    `CHK(io_msInfo_5_bits_reqTag)
    `CHK(io_msInfo_5_bits_willFree)
    `CHK(io_msInfo_5_bits_aliasTask)
    `CHK(io_msInfo_5_bits_needRelease)
    `CHK(io_msInfo_5_bits_blockRefill)
    `CHK(io_msInfo_5_bits_meta_dirty)
    `CHK(io_msInfo_5_bits_meta_state)
    `CHK(io_msInfo_5_bits_meta_clients)
    `CHK(io_msInfo_5_bits_meta_alias)
    `CHK(io_msInfo_5_bits_meta_prefetch)
    `CHK(io_msInfo_5_bits_meta_prefetchSrc)
    `CHK(io_msInfo_5_bits_meta_accessed)
    `CHK(io_msInfo_5_bits_meta_tagErr)
    `CHK(io_msInfo_5_bits_meta_dataErr)
    `CHK(io_msInfo_5_bits_metaTag)
    `CHK(io_msInfo_5_bits_dirHit)
    `CHK(io_msInfo_5_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_5_bits_isPrefetch)
    `CHK(io_msInfo_5_bits_param)
    `CHK(io_msInfo_5_bits_mergeA)
    `CHK(io_msInfo_5_bits_w_grantfirst)
    `CHK(io_msInfo_5_bits_s_release)
    `CHK(io_msInfo_5_bits_s_refill)
    `CHK(io_msInfo_5_bits_s_cmoresp)
    `CHK(io_msInfo_5_bits_s_cmometaw)
    `CHK(io_msInfo_5_bits_w_releaseack)
    `CHK(io_msInfo_5_bits_w_replResp)
    `CHK(io_msInfo_5_bits_w_rprobeacklast)
    `CHK(io_msInfo_5_bits_replaceData)
    `CHK(io_msInfo_5_bits_releaseToClean)
    `CHK(io_msInfo_6_valid)
    `CHK(io_msInfo_6_bits_channel)
    `CHK(io_msInfo_6_bits_set)
    `CHK(io_msInfo_6_bits_way)
    `CHK(io_msInfo_6_bits_reqTag)
    `CHK(io_msInfo_6_bits_willFree)
    `CHK(io_msInfo_6_bits_aliasTask)
    `CHK(io_msInfo_6_bits_needRelease)
    `CHK(io_msInfo_6_bits_blockRefill)
    `CHK(io_msInfo_6_bits_meta_dirty)
    `CHK(io_msInfo_6_bits_meta_state)
    `CHK(io_msInfo_6_bits_meta_clients)
    `CHK(io_msInfo_6_bits_meta_alias)
    `CHK(io_msInfo_6_bits_meta_prefetch)
    `CHK(io_msInfo_6_bits_meta_prefetchSrc)
    `CHK(io_msInfo_6_bits_meta_accessed)
    `CHK(io_msInfo_6_bits_meta_tagErr)
    `CHK(io_msInfo_6_bits_meta_dataErr)
    `CHK(io_msInfo_6_bits_metaTag)
    `CHK(io_msInfo_6_bits_dirHit)
    `CHK(io_msInfo_6_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_6_bits_isPrefetch)
    `CHK(io_msInfo_6_bits_param)
    `CHK(io_msInfo_6_bits_mergeA)
    `CHK(io_msInfo_6_bits_w_grantfirst)
    `CHK(io_msInfo_6_bits_s_release)
    `CHK(io_msInfo_6_bits_s_refill)
    `CHK(io_msInfo_6_bits_s_cmoresp)
    `CHK(io_msInfo_6_bits_s_cmometaw)
    `CHK(io_msInfo_6_bits_w_releaseack)
    `CHK(io_msInfo_6_bits_w_replResp)
    `CHK(io_msInfo_6_bits_w_rprobeacklast)
    `CHK(io_msInfo_6_bits_replaceData)
    `CHK(io_msInfo_6_bits_releaseToClean)
    `CHK(io_msInfo_7_valid)
    `CHK(io_msInfo_7_bits_channel)
    `CHK(io_msInfo_7_bits_set)
    `CHK(io_msInfo_7_bits_way)
    `CHK(io_msInfo_7_bits_reqTag)
    `CHK(io_msInfo_7_bits_willFree)
    `CHK(io_msInfo_7_bits_aliasTask)
    `CHK(io_msInfo_7_bits_needRelease)
    `CHK(io_msInfo_7_bits_blockRefill)
    `CHK(io_msInfo_7_bits_meta_dirty)
    `CHK(io_msInfo_7_bits_meta_state)
    `CHK(io_msInfo_7_bits_meta_clients)
    `CHK(io_msInfo_7_bits_meta_alias)
    `CHK(io_msInfo_7_bits_meta_prefetch)
    `CHK(io_msInfo_7_bits_meta_prefetchSrc)
    `CHK(io_msInfo_7_bits_meta_accessed)
    `CHK(io_msInfo_7_bits_meta_tagErr)
    `CHK(io_msInfo_7_bits_meta_dataErr)
    `CHK(io_msInfo_7_bits_metaTag)
    `CHK(io_msInfo_7_bits_dirHit)
    `CHK(io_msInfo_7_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_7_bits_isPrefetch)
    `CHK(io_msInfo_7_bits_param)
    `CHK(io_msInfo_7_bits_mergeA)
    `CHK(io_msInfo_7_bits_w_grantfirst)
    `CHK(io_msInfo_7_bits_s_release)
    `CHK(io_msInfo_7_bits_s_refill)
    `CHK(io_msInfo_7_bits_s_cmoresp)
    `CHK(io_msInfo_7_bits_s_cmometaw)
    `CHK(io_msInfo_7_bits_w_releaseack)
    `CHK(io_msInfo_7_bits_w_replResp)
    `CHK(io_msInfo_7_bits_w_rprobeacklast)
    `CHK(io_msInfo_7_bits_replaceData)
    `CHK(io_msInfo_7_bits_releaseToClean)
    `CHK(io_msInfo_8_valid)
    `CHK(io_msInfo_8_bits_channel)
    `CHK(io_msInfo_8_bits_set)
    `CHK(io_msInfo_8_bits_way)
    `CHK(io_msInfo_8_bits_reqTag)
    `CHK(io_msInfo_8_bits_willFree)
    `CHK(io_msInfo_8_bits_aliasTask)
    `CHK(io_msInfo_8_bits_needRelease)
    `CHK(io_msInfo_8_bits_blockRefill)
    `CHK(io_msInfo_8_bits_meta_dirty)
    `CHK(io_msInfo_8_bits_meta_state)
    `CHK(io_msInfo_8_bits_meta_clients)
    `CHK(io_msInfo_8_bits_meta_alias)
    `CHK(io_msInfo_8_bits_meta_prefetch)
    `CHK(io_msInfo_8_bits_meta_prefetchSrc)
    `CHK(io_msInfo_8_bits_meta_accessed)
    `CHK(io_msInfo_8_bits_meta_tagErr)
    `CHK(io_msInfo_8_bits_meta_dataErr)
    `CHK(io_msInfo_8_bits_metaTag)
    `CHK(io_msInfo_8_bits_dirHit)
    `CHK(io_msInfo_8_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_8_bits_isPrefetch)
    `CHK(io_msInfo_8_bits_param)
    `CHK(io_msInfo_8_bits_mergeA)
    `CHK(io_msInfo_8_bits_w_grantfirst)
    `CHK(io_msInfo_8_bits_s_release)
    `CHK(io_msInfo_8_bits_s_refill)
    `CHK(io_msInfo_8_bits_s_cmoresp)
    `CHK(io_msInfo_8_bits_s_cmometaw)
    `CHK(io_msInfo_8_bits_w_releaseack)
    `CHK(io_msInfo_8_bits_w_replResp)
    `CHK(io_msInfo_8_bits_w_rprobeacklast)
    `CHK(io_msInfo_8_bits_replaceData)
    `CHK(io_msInfo_8_bits_releaseToClean)
    `CHK(io_msInfo_9_valid)
    `CHK(io_msInfo_9_bits_channel)
    `CHK(io_msInfo_9_bits_set)
    `CHK(io_msInfo_9_bits_way)
    `CHK(io_msInfo_9_bits_reqTag)
    `CHK(io_msInfo_9_bits_willFree)
    `CHK(io_msInfo_9_bits_aliasTask)
    `CHK(io_msInfo_9_bits_needRelease)
    `CHK(io_msInfo_9_bits_blockRefill)
    `CHK(io_msInfo_9_bits_meta_dirty)
    `CHK(io_msInfo_9_bits_meta_state)
    `CHK(io_msInfo_9_bits_meta_clients)
    `CHK(io_msInfo_9_bits_meta_alias)
    `CHK(io_msInfo_9_bits_meta_prefetch)
    `CHK(io_msInfo_9_bits_meta_prefetchSrc)
    `CHK(io_msInfo_9_bits_meta_accessed)
    `CHK(io_msInfo_9_bits_meta_tagErr)
    `CHK(io_msInfo_9_bits_meta_dataErr)
    `CHK(io_msInfo_9_bits_metaTag)
    `CHK(io_msInfo_9_bits_dirHit)
    `CHK(io_msInfo_9_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_9_bits_isPrefetch)
    `CHK(io_msInfo_9_bits_param)
    `CHK(io_msInfo_9_bits_mergeA)
    `CHK(io_msInfo_9_bits_w_grantfirst)
    `CHK(io_msInfo_9_bits_s_release)
    `CHK(io_msInfo_9_bits_s_refill)
    `CHK(io_msInfo_9_bits_s_cmoresp)
    `CHK(io_msInfo_9_bits_s_cmometaw)
    `CHK(io_msInfo_9_bits_w_releaseack)
    `CHK(io_msInfo_9_bits_w_replResp)
    `CHK(io_msInfo_9_bits_w_rprobeacklast)
    `CHK(io_msInfo_9_bits_replaceData)
    `CHK(io_msInfo_9_bits_releaseToClean)
    `CHK(io_msInfo_10_valid)
    `CHK(io_msInfo_10_bits_channel)
    `CHK(io_msInfo_10_bits_set)
    `CHK(io_msInfo_10_bits_way)
    `CHK(io_msInfo_10_bits_reqTag)
    `CHK(io_msInfo_10_bits_willFree)
    `CHK(io_msInfo_10_bits_aliasTask)
    `CHK(io_msInfo_10_bits_needRelease)
    `CHK(io_msInfo_10_bits_blockRefill)
    `CHK(io_msInfo_10_bits_meta_dirty)
    `CHK(io_msInfo_10_bits_meta_state)
    `CHK(io_msInfo_10_bits_meta_clients)
    `CHK(io_msInfo_10_bits_meta_alias)
    `CHK(io_msInfo_10_bits_meta_prefetch)
    `CHK(io_msInfo_10_bits_meta_prefetchSrc)
    `CHK(io_msInfo_10_bits_meta_accessed)
    `CHK(io_msInfo_10_bits_meta_tagErr)
    `CHK(io_msInfo_10_bits_meta_dataErr)
    `CHK(io_msInfo_10_bits_metaTag)
    `CHK(io_msInfo_10_bits_dirHit)
    `CHK(io_msInfo_10_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_10_bits_isPrefetch)
    `CHK(io_msInfo_10_bits_param)
    `CHK(io_msInfo_10_bits_mergeA)
    `CHK(io_msInfo_10_bits_w_grantfirst)
    `CHK(io_msInfo_10_bits_s_release)
    `CHK(io_msInfo_10_bits_s_refill)
    `CHK(io_msInfo_10_bits_s_cmoresp)
    `CHK(io_msInfo_10_bits_s_cmometaw)
    `CHK(io_msInfo_10_bits_w_releaseack)
    `CHK(io_msInfo_10_bits_w_replResp)
    `CHK(io_msInfo_10_bits_w_rprobeacklast)
    `CHK(io_msInfo_10_bits_replaceData)
    `CHK(io_msInfo_10_bits_releaseToClean)
    `CHK(io_msInfo_11_valid)
    `CHK(io_msInfo_11_bits_channel)
    `CHK(io_msInfo_11_bits_set)
    `CHK(io_msInfo_11_bits_way)
    `CHK(io_msInfo_11_bits_reqTag)
    `CHK(io_msInfo_11_bits_willFree)
    `CHK(io_msInfo_11_bits_aliasTask)
    `CHK(io_msInfo_11_bits_needRelease)
    `CHK(io_msInfo_11_bits_blockRefill)
    `CHK(io_msInfo_11_bits_meta_dirty)
    `CHK(io_msInfo_11_bits_meta_state)
    `CHK(io_msInfo_11_bits_meta_clients)
    `CHK(io_msInfo_11_bits_meta_alias)
    `CHK(io_msInfo_11_bits_meta_prefetch)
    `CHK(io_msInfo_11_bits_meta_prefetchSrc)
    `CHK(io_msInfo_11_bits_meta_accessed)
    `CHK(io_msInfo_11_bits_meta_tagErr)
    `CHK(io_msInfo_11_bits_meta_dataErr)
    `CHK(io_msInfo_11_bits_metaTag)
    `CHK(io_msInfo_11_bits_dirHit)
    `CHK(io_msInfo_11_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_11_bits_isPrefetch)
    `CHK(io_msInfo_11_bits_param)
    `CHK(io_msInfo_11_bits_mergeA)
    `CHK(io_msInfo_11_bits_w_grantfirst)
    `CHK(io_msInfo_11_bits_s_release)
    `CHK(io_msInfo_11_bits_s_refill)
    `CHK(io_msInfo_11_bits_s_cmoresp)
    `CHK(io_msInfo_11_bits_s_cmometaw)
    `CHK(io_msInfo_11_bits_w_releaseack)
    `CHK(io_msInfo_11_bits_w_replResp)
    `CHK(io_msInfo_11_bits_w_rprobeacklast)
    `CHK(io_msInfo_11_bits_replaceData)
    `CHK(io_msInfo_11_bits_releaseToClean)
    `CHK(io_msInfo_12_valid)
    `CHK(io_msInfo_12_bits_channel)
    `CHK(io_msInfo_12_bits_set)
    `CHK(io_msInfo_12_bits_way)
    `CHK(io_msInfo_12_bits_reqTag)
    `CHK(io_msInfo_12_bits_willFree)
    `CHK(io_msInfo_12_bits_aliasTask)
    `CHK(io_msInfo_12_bits_needRelease)
    `CHK(io_msInfo_12_bits_blockRefill)
    `CHK(io_msInfo_12_bits_meta_dirty)
    `CHK(io_msInfo_12_bits_meta_state)
    `CHK(io_msInfo_12_bits_meta_clients)
    `CHK(io_msInfo_12_bits_meta_alias)
    `CHK(io_msInfo_12_bits_meta_prefetch)
    `CHK(io_msInfo_12_bits_meta_prefetchSrc)
    `CHK(io_msInfo_12_bits_meta_accessed)
    `CHK(io_msInfo_12_bits_meta_tagErr)
    `CHK(io_msInfo_12_bits_meta_dataErr)
    `CHK(io_msInfo_12_bits_metaTag)
    `CHK(io_msInfo_12_bits_dirHit)
    `CHK(io_msInfo_12_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_12_bits_isPrefetch)
    `CHK(io_msInfo_12_bits_param)
    `CHK(io_msInfo_12_bits_mergeA)
    `CHK(io_msInfo_12_bits_w_grantfirst)
    `CHK(io_msInfo_12_bits_s_release)
    `CHK(io_msInfo_12_bits_s_refill)
    `CHK(io_msInfo_12_bits_s_cmoresp)
    `CHK(io_msInfo_12_bits_s_cmometaw)
    `CHK(io_msInfo_12_bits_w_releaseack)
    `CHK(io_msInfo_12_bits_w_replResp)
    `CHK(io_msInfo_12_bits_w_rprobeacklast)
    `CHK(io_msInfo_12_bits_replaceData)
    `CHK(io_msInfo_12_bits_releaseToClean)
    `CHK(io_msInfo_13_valid)
    `CHK(io_msInfo_13_bits_channel)
    `CHK(io_msInfo_13_bits_set)
    `CHK(io_msInfo_13_bits_way)
    `CHK(io_msInfo_13_bits_reqTag)
    `CHK(io_msInfo_13_bits_willFree)
    `CHK(io_msInfo_13_bits_aliasTask)
    `CHK(io_msInfo_13_bits_needRelease)
    `CHK(io_msInfo_13_bits_blockRefill)
    `CHK(io_msInfo_13_bits_meta_dirty)
    `CHK(io_msInfo_13_bits_meta_state)
    `CHK(io_msInfo_13_bits_meta_clients)
    `CHK(io_msInfo_13_bits_meta_alias)
    `CHK(io_msInfo_13_bits_meta_prefetch)
    `CHK(io_msInfo_13_bits_meta_prefetchSrc)
    `CHK(io_msInfo_13_bits_meta_accessed)
    `CHK(io_msInfo_13_bits_meta_tagErr)
    `CHK(io_msInfo_13_bits_meta_dataErr)
    `CHK(io_msInfo_13_bits_metaTag)
    `CHK(io_msInfo_13_bits_dirHit)
    `CHK(io_msInfo_13_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_13_bits_isPrefetch)
    `CHK(io_msInfo_13_bits_param)
    `CHK(io_msInfo_13_bits_mergeA)
    `CHK(io_msInfo_13_bits_w_grantfirst)
    `CHK(io_msInfo_13_bits_s_release)
    `CHK(io_msInfo_13_bits_s_refill)
    `CHK(io_msInfo_13_bits_s_cmoresp)
    `CHK(io_msInfo_13_bits_s_cmometaw)
    `CHK(io_msInfo_13_bits_w_releaseack)
    `CHK(io_msInfo_13_bits_w_replResp)
    `CHK(io_msInfo_13_bits_w_rprobeacklast)
    `CHK(io_msInfo_13_bits_replaceData)
    `CHK(io_msInfo_13_bits_releaseToClean)
    `CHK(io_msInfo_14_valid)
    `CHK(io_msInfo_14_bits_channel)
    `CHK(io_msInfo_14_bits_set)
    `CHK(io_msInfo_14_bits_way)
    `CHK(io_msInfo_14_bits_reqTag)
    `CHK(io_msInfo_14_bits_willFree)
    `CHK(io_msInfo_14_bits_aliasTask)
    `CHK(io_msInfo_14_bits_needRelease)
    `CHK(io_msInfo_14_bits_blockRefill)
    `CHK(io_msInfo_14_bits_meta_dirty)
    `CHK(io_msInfo_14_bits_meta_state)
    `CHK(io_msInfo_14_bits_meta_clients)
    `CHK(io_msInfo_14_bits_meta_alias)
    `CHK(io_msInfo_14_bits_meta_prefetch)
    `CHK(io_msInfo_14_bits_meta_prefetchSrc)
    `CHK(io_msInfo_14_bits_meta_accessed)
    `CHK(io_msInfo_14_bits_meta_tagErr)
    `CHK(io_msInfo_14_bits_meta_dataErr)
    `CHK(io_msInfo_14_bits_metaTag)
    `CHK(io_msInfo_14_bits_dirHit)
    `CHK(io_msInfo_14_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_14_bits_isPrefetch)
    `CHK(io_msInfo_14_bits_param)
    `CHK(io_msInfo_14_bits_mergeA)
    `CHK(io_msInfo_14_bits_w_grantfirst)
    `CHK(io_msInfo_14_bits_s_release)
    `CHK(io_msInfo_14_bits_s_refill)
    `CHK(io_msInfo_14_bits_s_cmoresp)
    `CHK(io_msInfo_14_bits_s_cmometaw)
    `CHK(io_msInfo_14_bits_w_releaseack)
    `CHK(io_msInfo_14_bits_w_replResp)
    `CHK(io_msInfo_14_bits_w_rprobeacklast)
    `CHK(io_msInfo_14_bits_replaceData)
    `CHK(io_msInfo_14_bits_releaseToClean)
    `CHK(io_msInfo_15_valid)
    `CHK(io_msInfo_15_bits_channel)
    `CHK(io_msInfo_15_bits_set)
    `CHK(io_msInfo_15_bits_way)
    `CHK(io_msInfo_15_bits_reqTag)
    `CHK(io_msInfo_15_bits_willFree)
    `CHK(io_msInfo_15_bits_aliasTask)
    `CHK(io_msInfo_15_bits_needRelease)
    `CHK(io_msInfo_15_bits_blockRefill)
    `CHK(io_msInfo_15_bits_meta_dirty)
    `CHK(io_msInfo_15_bits_meta_state)
    `CHK(io_msInfo_15_bits_meta_clients)
    `CHK(io_msInfo_15_bits_meta_alias)
    `CHK(io_msInfo_15_bits_meta_prefetch)
    `CHK(io_msInfo_15_bits_meta_prefetchSrc)
    `CHK(io_msInfo_15_bits_meta_accessed)
    `CHK(io_msInfo_15_bits_meta_tagErr)
    `CHK(io_msInfo_15_bits_meta_dataErr)
    `CHK(io_msInfo_15_bits_metaTag)
    `CHK(io_msInfo_15_bits_dirHit)
    `CHK(io_msInfo_15_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_15_bits_isPrefetch)
    `CHK(io_msInfo_15_bits_param)
    `CHK(io_msInfo_15_bits_mergeA)
    `CHK(io_msInfo_15_bits_w_grantfirst)
    `CHK(io_msInfo_15_bits_s_release)
    `CHK(io_msInfo_15_bits_s_refill)
    `CHK(io_msInfo_15_bits_s_cmoresp)
    `CHK(io_msInfo_15_bits_s_cmometaw)
    `CHK(io_msInfo_15_bits_w_releaseack)
    `CHK(io_msInfo_15_bits_w_replResp)
    `CHK(io_msInfo_15_bits_w_rprobeacklast)
    `CHK(io_msInfo_15_bits_replaceData)
    `CHK(io_msInfo_15_bits_releaseToClean)
    `CHK(io_msStatus_0_valid)
    `CHK(io_msStatus_0_bits_channel)
    `CHK(io_msStatus_0_bits_set)
    `CHK(io_msStatus_0_bits_reqTag)
    `CHK(io_msStatus_0_bits_is_miss)
    `CHK(io_msStatus_0_bits_is_prefetch)
    `CHK(io_msStatus_1_valid)
    `CHK(io_msStatus_1_bits_channel)
    `CHK(io_msStatus_1_bits_set)
    `CHK(io_msStatus_1_bits_reqTag)
    `CHK(io_msStatus_1_bits_is_miss)
    `CHK(io_msStatus_1_bits_is_prefetch)
    `CHK(io_msStatus_2_valid)
    `CHK(io_msStatus_2_bits_channel)
    `CHK(io_msStatus_2_bits_set)
    `CHK(io_msStatus_2_bits_reqTag)
    `CHK(io_msStatus_2_bits_is_miss)
    `CHK(io_msStatus_2_bits_is_prefetch)
    `CHK(io_msStatus_3_valid)
    `CHK(io_msStatus_3_bits_channel)
    `CHK(io_msStatus_3_bits_set)
    `CHK(io_msStatus_3_bits_reqTag)
    `CHK(io_msStatus_3_bits_is_miss)
    `CHK(io_msStatus_3_bits_is_prefetch)
    `CHK(io_msStatus_4_valid)
    `CHK(io_msStatus_4_bits_channel)
    `CHK(io_msStatus_4_bits_set)
    `CHK(io_msStatus_4_bits_reqTag)
    `CHK(io_msStatus_4_bits_is_miss)
    `CHK(io_msStatus_4_bits_is_prefetch)
    `CHK(io_msStatus_5_valid)
    `CHK(io_msStatus_5_bits_channel)
    `CHK(io_msStatus_5_bits_set)
    `CHK(io_msStatus_5_bits_reqTag)
    `CHK(io_msStatus_5_bits_is_miss)
    `CHK(io_msStatus_5_bits_is_prefetch)
    `CHK(io_msStatus_6_valid)
    `CHK(io_msStatus_6_bits_channel)
    `CHK(io_msStatus_6_bits_set)
    `CHK(io_msStatus_6_bits_reqTag)
    `CHK(io_msStatus_6_bits_is_miss)
    `CHK(io_msStatus_6_bits_is_prefetch)
    `CHK(io_msStatus_7_valid)
    `CHK(io_msStatus_7_bits_channel)
    `CHK(io_msStatus_7_bits_set)
    `CHK(io_msStatus_7_bits_reqTag)
    `CHK(io_msStatus_7_bits_is_miss)
    `CHK(io_msStatus_7_bits_is_prefetch)
    `CHK(io_msStatus_8_valid)
    `CHK(io_msStatus_8_bits_channel)
    `CHK(io_msStatus_8_bits_set)
    `CHK(io_msStatus_8_bits_reqTag)
    `CHK(io_msStatus_8_bits_is_miss)
    `CHK(io_msStatus_8_bits_is_prefetch)
    `CHK(io_msStatus_9_valid)
    `CHK(io_msStatus_9_bits_channel)
    `CHK(io_msStatus_9_bits_set)
    `CHK(io_msStatus_9_bits_reqTag)
    `CHK(io_msStatus_9_bits_is_miss)
    `CHK(io_msStatus_9_bits_is_prefetch)
    `CHK(io_msStatus_10_valid)
    `CHK(io_msStatus_10_bits_channel)
    `CHK(io_msStatus_10_bits_set)
    `CHK(io_msStatus_10_bits_reqTag)
    `CHK(io_msStatus_10_bits_is_miss)
    `CHK(io_msStatus_10_bits_is_prefetch)
    `CHK(io_msStatus_11_valid)
    `CHK(io_msStatus_11_bits_channel)
    `CHK(io_msStatus_11_bits_set)
    `CHK(io_msStatus_11_bits_reqTag)
    `CHK(io_msStatus_11_bits_is_miss)
    `CHK(io_msStatus_11_bits_is_prefetch)
    `CHK(io_msStatus_12_valid)
    `CHK(io_msStatus_12_bits_channel)
    `CHK(io_msStatus_12_bits_set)
    `CHK(io_msStatus_12_bits_reqTag)
    `CHK(io_msStatus_12_bits_is_miss)
    `CHK(io_msStatus_12_bits_is_prefetch)
    `CHK(io_msStatus_13_valid)
    `CHK(io_msStatus_13_bits_channel)
    `CHK(io_msStatus_13_bits_set)
    `CHK(io_msStatus_13_bits_reqTag)
    `CHK(io_msStatus_13_bits_is_miss)
    `CHK(io_msStatus_13_bits_is_prefetch)
    `CHK(io_msStatus_14_valid)
    `CHK(io_msStatus_14_bits_channel)
    `CHK(io_msStatus_14_bits_set)
    `CHK(io_msStatus_14_bits_reqTag)
    `CHK(io_msStatus_14_bits_is_miss)
    `CHK(io_msStatus_14_bits_is_prefetch)
    `CHK(io_msStatus_15_valid)
    `CHK(io_msStatus_15_bits_channel)
    `CHK(io_msStatus_15_bits_set)
    `CHK(io_msStatus_15_bits_reqTag)
    `CHK(io_msStatus_15_bits_is_miss)
    `CHK(io_msStatus_15_bits_is_prefetch)
    `CHK(io_pCrd_0_query_valid)
    `CHK(io_pCrd_0_query_bits_pCrdType)
    `CHK(io_pCrd_0_query_bits_srcID)
    `CHK(io_pCrd_1_query_valid)
    `CHK(io_pCrd_1_query_bits_pCrdType)
    `CHK(io_pCrd_1_query_bits_srcID)
    `CHK(io_pCrd_2_query_valid)
    `CHK(io_pCrd_2_query_bits_pCrdType)
    `CHK(io_pCrd_2_query_bits_srcID)
    `CHK(io_pCrd_3_query_valid)
    `CHK(io_pCrd_3_query_bits_pCrdType)
    `CHK(io_pCrd_3_query_bits_srcID)
    `CHK(io_pCrd_4_query_valid)
    `CHK(io_pCrd_4_query_bits_pCrdType)
    `CHK(io_pCrd_4_query_bits_srcID)
    `CHK(io_pCrd_5_query_valid)
    `CHK(io_pCrd_5_query_bits_pCrdType)
    `CHK(io_pCrd_5_query_bits_srcID)
    `CHK(io_pCrd_6_query_valid)
    `CHK(io_pCrd_6_query_bits_pCrdType)
    `CHK(io_pCrd_6_query_bits_srcID)
    `CHK(io_pCrd_7_query_valid)
    `CHK(io_pCrd_7_query_bits_pCrdType)
    `CHK(io_pCrd_7_query_bits_srcID)
    `CHK(io_pCrd_8_query_valid)
    `CHK(io_pCrd_8_query_bits_pCrdType)
    `CHK(io_pCrd_8_query_bits_srcID)
    `CHK(io_pCrd_9_query_valid)
    `CHK(io_pCrd_9_query_bits_pCrdType)
    `CHK(io_pCrd_9_query_bits_srcID)
    `CHK(io_pCrd_10_query_valid)
    `CHK(io_pCrd_10_query_bits_pCrdType)
    `CHK(io_pCrd_10_query_bits_srcID)
    `CHK(io_pCrd_11_query_valid)
    `CHK(io_pCrd_11_query_bits_pCrdType)
    `CHK(io_pCrd_11_query_bits_srcID)
    `CHK(io_pCrd_12_query_valid)
    `CHK(io_pCrd_12_query_bits_pCrdType)
    `CHK(io_pCrd_12_query_bits_srcID)
    `CHK(io_pCrd_13_query_valid)
    `CHK(io_pCrd_13_query_bits_pCrdType)
    `CHK(io_pCrd_13_query_bits_srcID)
    `CHK(io_pCrd_14_query_valid)
    `CHK(io_pCrd_14_query_bits_pCrdType)
    `CHK(io_pCrd_14_query_bits_srcID)
    `CHK(io_pCrd_15_query_valid)
    `CHK(io_pCrd_15_query_bits_pCrdType)
    `CHK(io_pCrd_15_query_bits_srcID)
    `CHK(io_l2Miss)
    `CHK(io_perf_0_value)
    `CHK(io_perf_1_value)
    `CHK(io_perf_3_value)
  endtask

  // 内部探针: golden 控制 glue vs 可读核(名字不同, 显式映射)
  int ierr = 0;
  task automatic check_internal();
    if (!$isunknown(u_g.mshrFull_probe) &&
        u_g.mshrFull_probe !== u_i.u_core.mshrFull) begin
      ierr++; if (ierr<=20) $display("[%0t] IPROBE mshrFull g=%0h i=%0h", $time, u_g.mshrFull_probe, u_i.u_core.mshrFull); end
    if (!$isunknown(u_g.a_mshrFull_probe) &&
        u_g.a_mshrFull_probe !== u_i.u_core.a_mshrFull) begin
      ierr++; if (ierr<=20) $display("[%0t] IPROBE a_mshrFull g=%0h i=%0h", $time, u_g.a_mshrFull_probe, u_i.u_core.a_mshrFull); end
    if (!$isunknown(u_g._mshrSelector_io_out_bits) &&
        u_g._mshrSelector_io_out_bits !== u_i.u_core.mshrSelector_out_bits) begin
      ierr++; if (ierr<=20) $display("[%0t] IPROBE selOH g=%0h i=%0h", $time, u_g._mshrSelector_io_out_bits, u_i.u_core.mshrSelector_out_bits); end
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_fromMainPipe_mshr_alloc_s3_valid = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_release = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_channel = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_set = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_tag = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_off = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_alias = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_opcode = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_param = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_srcID = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_txnID = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc = '0;
    io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag = '0;
    io_mshrTask_ready = '0;
    io_pipeStatusVec_0_valid = '0;
    io_pipeStatusVec_1_valid = '0;
    io_toTXREQ_ready = '0;
    io_toTXRSP_ready = '0;
    io_toSourceB_ready = '0;
    io_grantStatus_0_valid = '0;
    io_grantStatus_0_set = '0;
    io_grantStatus_0_tag = '0;
    io_grantStatus_1_valid = '0;
    io_grantStatus_1_set = '0;
    io_grantStatus_1_tag = '0;
    io_grantStatus_2_valid = '0;
    io_grantStatus_2_set = '0;
    io_grantStatus_2_tag = '0;
    io_grantStatus_3_valid = '0;
    io_grantStatus_3_set = '0;
    io_grantStatus_3_tag = '0;
    io_grantStatus_4_valid = '0;
    io_grantStatus_4_set = '0;
    io_grantStatus_4_tag = '0;
    io_grantStatus_5_valid = '0;
    io_grantStatus_5_set = '0;
    io_grantStatus_5_tag = '0;
    io_grantStatus_6_valid = '0;
    io_grantStatus_6_set = '0;
    io_grantStatus_6_tag = '0;
    io_grantStatus_7_valid = '0;
    io_grantStatus_7_set = '0;
    io_grantStatus_7_tag = '0;
    io_grantStatus_8_valid = '0;
    io_grantStatus_8_set = '0;
    io_grantStatus_8_tag = '0;
    io_grantStatus_9_valid = '0;
    io_grantStatus_9_set = '0;
    io_grantStatus_9_tag = '0;
    io_grantStatus_10_valid = '0;
    io_grantStatus_10_set = '0;
    io_grantStatus_10_tag = '0;
    io_grantStatus_11_valid = '0;
    io_grantStatus_11_set = '0;
    io_grantStatus_11_tag = '0;
    io_grantStatus_12_valid = '0;
    io_grantStatus_12_set = '0;
    io_grantStatus_12_tag = '0;
    io_grantStatus_13_valid = '0;
    io_grantStatus_13_set = '0;
    io_grantStatus_13_tag = '0;
    io_grantStatus_14_valid = '0;
    io_grantStatus_14_set = '0;
    io_grantStatus_14_tag = '0;
    io_grantStatus_15_valid = '0;
    io_grantStatus_15_set = '0;
    io_grantStatus_15_tag = '0;
    io_resps_sinkC_valid = '0;
    io_resps_sinkC_set = '0;
    io_resps_sinkC_tag = '0;
    io_resps_sinkC_respInfo_opcode = '0;
    io_resps_sinkC_respInfo_param = '0;
    io_resps_sinkC_respInfo_last = '0;
    io_resps_sinkC_respInfo_denied = '0;
    io_resps_sinkC_respInfo_corrupt = '0;
    io_resps_rxrsp_valid = '0;
    io_resps_rxrsp_mshrId = '0;
    io_resps_rxrsp_respInfo_chiOpcode = '0;
    io_resps_rxrsp_respInfo_srcID = '0;
    io_resps_rxrsp_respInfo_dbID = '0;
    io_resps_rxrsp_respInfo_resp = '0;
    io_resps_rxrsp_respInfo_pCrdType = '0;
    io_resps_rxrsp_respInfo_respErr = '0;
    io_resps_rxrsp_respInfo_traceTag = '0;
    io_resps_rxdat_valid = '0;
    io_resps_rxdat_mshrId = '0;
    io_resps_rxdat_respInfo_last = '0;
    io_resps_rxdat_respInfo_corrupt = '0;
    io_resps_rxdat_respInfo_chiOpcode = '0;
    io_resps_rxdat_respInfo_homeNID = '0;
    io_resps_rxdat_respInfo_dbID = '0;
    io_resps_rxdat_respInfo_resp = '0;
    io_resps_rxdat_respInfo_respErr = '0;
    io_resps_rxdat_respInfo_traceTag = '0;
    io_resps_rxdat_respInfo_dataCheckErr = '0;
    io_nestedwb_set = '0;
    io_nestedwb_tag = '0;
    io_nestedwb_c_set_dirty = '0;
    io_nestedwb_c_set_tip = '0;
    io_nestedwb_b_inv_dirty = '0;
    io_nestedwb_b_toB = '0;
    io_nestedwb_b_toN = '0;
    io_nestedwb_b_toClean = '0;
    io_aMergeTask_valid = '0;
    io_aMergeTask_bits_id = '0;
    io_aMergeTask_bits_task_off = '0;
    io_aMergeTask_bits_task_alias = '0;
    io_aMergeTask_bits_task_vaddr = '0;
    io_aMergeTask_bits_task_isKeyword = '0;
    io_aMergeTask_bits_task_opcode = '0;
    io_aMergeTask_bits_task_param = '0;
    io_aMergeTask_bits_task_sourceId = '0;
    io_replResp_valid = '0;
    io_replResp_bits_tag = '0;
    io_replResp_bits_way = '0;
    io_replResp_bits_meta_dirty = '0;
    io_replResp_bits_meta_state = '0;
    io_replResp_bits_meta_clients = '0;
    io_replResp_bits_meta_alias = '0;
    io_replResp_bits_meta_prefetch = '0;
    io_replResp_bits_meta_prefetchSrc = '0;
    io_replResp_bits_meta_accessed = '0;
    io_replResp_bits_meta_tagErr = '0;
    io_replResp_bits_meta_dataErr = '0;
    io_replResp_bits_mshrId = '0;
    io_replResp_bits_retry = '0;
    io_pCrd_0_grant = '0;
    io_pCrd_1_grant = '0;
    io_pCrd_2_grant = '0;
    io_pCrd_3_grant = '0;
    io_pCrd_4_grant = '0;
    io_pCrd_5_grant = '0;
    io_pCrd_6_grant = '0;
    io_pCrd_7_grant = '0;
    io_pCrd_8_grant = '0;
    io_pCrd_9_grant = '0;
    io_pCrd_10_grant = '0;
    io_pCrd_11_grant = '0;
    io_pCrd_12_grant = '0;
    io_pCrd_13_grant = '0;
    io_pCrd_14_grant = '0;
    io_pCrd_15_grant = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("MSHRCtl checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
