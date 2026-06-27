// 自动生成 scripts/gen_mshr.py —— 勿手改
// MSHR 双例化逐拍比对: golden MSHR vs 可读重写 MSHR_xs。
// 时序一致性状态机: 每拍随机驱动所有输入, 偏向开 alloc/resp 推进 FSM, 逐拍比全部输出。
`timescale 1ns/1ps
`define CHK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic [7:0] io_id;
  logic io_alloc_valid;
  logic io_alloc_bits_dirResult_hit;
  logic [30:0] io_alloc_bits_dirResult_tag;
  logic [8:0] io_alloc_bits_dirResult_set;
  logic [2:0] io_alloc_bits_dirResult_way;
  logic io_alloc_bits_dirResult_meta_dirty;
  logic [1:0] io_alloc_bits_dirResult_meta_state;
  logic io_alloc_bits_dirResult_meta_clients;
  logic [1:0] io_alloc_bits_dirResult_meta_alias;
  logic io_alloc_bits_dirResult_meta_prefetch;
  logic [2:0] io_alloc_bits_dirResult_meta_prefetchSrc;
  logic io_alloc_bits_dirResult_meta_accessed;
  logic io_alloc_bits_dirResult_meta_tagErr;
  logic io_alloc_bits_dirResult_meta_dataErr;
  logic io_alloc_bits_dirResult_error;
  logic io_alloc_bits_state_s_acquire;
  logic io_alloc_bits_state_s_rprobe;
  logic io_alloc_bits_state_s_pprobe;
  logic io_alloc_bits_state_s_release;
  logic io_alloc_bits_state_s_probeack;
  logic io_alloc_bits_state_s_refill;
  logic io_alloc_bits_state_s_cmoresp;
  logic io_alloc_bits_state_w_rprobeackfirst;
  logic io_alloc_bits_state_w_rprobeacklast;
  logic io_alloc_bits_state_w_pprobeackfirst;
  logic io_alloc_bits_state_w_pprobeacklast;
  logic io_alloc_bits_state_w_grantfirst;
  logic io_alloc_bits_state_w_grantlast;
  logic io_alloc_bits_state_w_grant;
  logic io_alloc_bits_state_w_releaseack;
  logic io_alloc_bits_state_w_replResp;
  logic io_alloc_bits_state_s_rcompack;
  logic io_alloc_bits_state_s_dct;
  logic [2:0] io_alloc_bits_task_channel;
  logic [8:0] io_alloc_bits_task_set;
  logic [30:0] io_alloc_bits_task_tag;
  logic [5:0] io_alloc_bits_task_off;
  logic [1:0] io_alloc_bits_task_alias;
  logic io_alloc_bits_task_isKeyword;
  logic [3:0] io_alloc_bits_task_opcode;
  logic [2:0] io_alloc_bits_task_param;
  logic [6:0] io_alloc_bits_task_sourceId;
  logic io_alloc_bits_task_aliasTask;
  logic io_alloc_bits_task_fromL2pft;
  logic [4:0] io_alloc_bits_task_reqSource;
  logic io_alloc_bits_task_snpHitRelease;
  logic io_alloc_bits_task_snpHitReleaseToInval;
  logic io_alloc_bits_task_snpHitReleaseToClean;
  logic io_alloc_bits_task_snpHitReleaseWithData;
  logic [7:0] io_alloc_bits_task_snpHitReleaseIdx;
  logic io_alloc_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] io_alloc_bits_task_snpHitReleaseMeta_state;
  logic io_alloc_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] io_alloc_bits_task_snpHitReleaseMeta_alias;
  logic io_alloc_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic io_alloc_bits_task_snpHitReleaseMeta_accessed;
  logic io_alloc_bits_task_snpHitReleaseMeta_tagErr;
  logic io_alloc_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] io_alloc_bits_task_srcID;
  logic [11:0] io_alloc_bits_task_txnID;
  logic [10:0] io_alloc_bits_task_fwdNID;
  logic [11:0] io_alloc_bits_task_fwdTxnID;
  logic [6:0] io_alloc_bits_task_chiOpcode;
  logic io_alloc_bits_task_retToSrc;
  logic io_alloc_bits_task_traceTag;
  logic io_tasks_txreq_ready;
  logic io_tasks_txrsp_ready;
  logic io_tasks_source_b_ready;
  logic io_tasks_mainpipe_ready;
  logic io_resps_sinkC_valid;
  logic [2:0] io_resps_sinkC_bits_opcode;
  logic [2:0] io_resps_sinkC_bits_param;
  logic io_resps_sinkC_bits_last;
  logic io_resps_sinkC_bits_denied;
  logic io_resps_sinkC_bits_corrupt;
  logic io_resps_rxrsp_valid;
  logic [6:0] io_resps_rxrsp_bits_chiOpcode;
  logic [10:0] io_resps_rxrsp_bits_srcID;
  logic [11:0] io_resps_rxrsp_bits_dbID;
  logic [2:0] io_resps_rxrsp_bits_resp;
  logic [3:0] io_resps_rxrsp_bits_pCrdType;
  logic [1:0] io_resps_rxrsp_bits_respErr;
  logic io_resps_rxrsp_bits_traceTag;
  logic io_resps_rxdat_valid;
  logic io_resps_rxdat_bits_corrupt;
  logic [6:0] io_resps_rxdat_bits_chiOpcode;
  logic [10:0] io_resps_rxdat_bits_homeNID;
  logic [11:0] io_resps_rxdat_bits_dbID;
  logic [2:0] io_resps_rxdat_bits_resp;
  logic [1:0] io_resps_rxdat_bits_respErr;
  logic io_resps_rxdat_bits_traceTag;
  logic io_resps_rxdat_bits_dataCheckErr;
  logic [8:0] io_nestedwb_set;
  logic [30:0] io_nestedwb_tag;
  logic io_nestedwb_c_set_dirty;
  logic io_nestedwb_c_set_tip;
  logic io_nestedwb_b_inv_dirty;
  logic io_nestedwb_b_toB;
  logic io_nestedwb_b_toN;
  logic io_nestedwb_b_toClean;
  logic io_aMergeTask_valid;
  logic [5:0] io_aMergeTask_bits_off;
  logic [1:0] io_aMergeTask_bits_alias;
  logic [43:0] io_aMergeTask_bits_vaddr;
  logic io_aMergeTask_bits_isKeyword;
  logic [3:0] io_aMergeTask_bits_opcode;
  logic [2:0] io_aMergeTask_bits_param;
  logic [6:0] io_aMergeTask_bits_sourceId;
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
  logic io_replResp_bits_retry;
  logic io_pCrd_grant;
  wire g_io_status_valid;
  wire i_io_status_valid;
  wire [2:0] g_io_status_bits_channel;
  wire [2:0] i_io_status_bits_channel;
  wire [8:0] g_io_status_bits_set;
  wire [8:0] i_io_status_bits_set;
  wire [30:0] g_io_status_bits_reqTag;
  wire [30:0] i_io_status_bits_reqTag;
  wire [30:0] g_io_status_bits_metaTag;
  wire [30:0] i_io_status_bits_metaTag;
  wire g_io_status_bits_needsRepl;
  wire i_io_status_bits_needsRepl;
  wire g_io_status_bits_w_c_resp;
  wire i_io_status_bits_w_c_resp;
  wire g_io_status_bits_will_free;
  wire i_io_status_bits_will_free;
  wire [4:0] g_io_status_bits_reqSource;
  wire [4:0] i_io_status_bits_reqSource;
  wire g_io_status_bits_is_miss;
  wire i_io_status_bits_is_miss;
  wire g_io_status_bits_is_prefetch;
  wire i_io_status_bits_is_prefetch;
  wire g_io_msInfo_valid;
  wire i_io_msInfo_valid;
  wire [2:0] g_io_msInfo_bits_channel;
  wire [2:0] i_io_msInfo_bits_channel;
  wire [8:0] g_io_msInfo_bits_set;
  wire [8:0] i_io_msInfo_bits_set;
  wire [2:0] g_io_msInfo_bits_way;
  wire [2:0] i_io_msInfo_bits_way;
  wire [30:0] g_io_msInfo_bits_reqTag;
  wire [30:0] i_io_msInfo_bits_reqTag;
  wire g_io_msInfo_bits_willFree;
  wire i_io_msInfo_bits_willFree;
  wire g_io_msInfo_bits_aliasTask;
  wire i_io_msInfo_bits_aliasTask;
  wire g_io_msInfo_bits_needRelease;
  wire i_io_msInfo_bits_needRelease;
  wire g_io_msInfo_bits_blockRefill;
  wire i_io_msInfo_bits_blockRefill;
  wire g_io_msInfo_bits_meta_dirty;
  wire i_io_msInfo_bits_meta_dirty;
  wire [1:0] g_io_msInfo_bits_meta_state;
  wire [1:0] i_io_msInfo_bits_meta_state;
  wire g_io_msInfo_bits_meta_clients;
  wire i_io_msInfo_bits_meta_clients;
  wire [1:0] g_io_msInfo_bits_meta_alias;
  wire [1:0] i_io_msInfo_bits_meta_alias;
  wire g_io_msInfo_bits_meta_prefetch;
  wire i_io_msInfo_bits_meta_prefetch;
  wire [2:0] g_io_msInfo_bits_meta_prefetchSrc;
  wire [2:0] i_io_msInfo_bits_meta_prefetchSrc;
  wire g_io_msInfo_bits_meta_accessed;
  wire i_io_msInfo_bits_meta_accessed;
  wire g_io_msInfo_bits_meta_tagErr;
  wire i_io_msInfo_bits_meta_tagErr;
  wire g_io_msInfo_bits_meta_dataErr;
  wire i_io_msInfo_bits_meta_dataErr;
  wire [30:0] g_io_msInfo_bits_metaTag;
  wire [30:0] i_io_msInfo_bits_metaTag;
  wire g_io_msInfo_bits_dirHit;
  wire i_io_msInfo_bits_dirHit;
  wire g_io_msInfo_bits_isAcqOrPrefetch;
  wire i_io_msInfo_bits_isAcqOrPrefetch;
  wire g_io_msInfo_bits_isPrefetch;
  wire i_io_msInfo_bits_isPrefetch;
  wire [2:0] g_io_msInfo_bits_param;
  wire [2:0] i_io_msInfo_bits_param;
  wire g_io_msInfo_bits_mergeA;
  wire i_io_msInfo_bits_mergeA;
  wire g_io_msInfo_bits_w_grantfirst;
  wire i_io_msInfo_bits_w_grantfirst;
  wire g_io_msInfo_bits_s_release;
  wire i_io_msInfo_bits_s_release;
  wire g_io_msInfo_bits_s_refill;
  wire i_io_msInfo_bits_s_refill;
  wire g_io_msInfo_bits_s_cmoresp;
  wire i_io_msInfo_bits_s_cmoresp;
  wire g_io_msInfo_bits_s_cmometaw;
  wire i_io_msInfo_bits_s_cmometaw;
  wire g_io_msInfo_bits_w_releaseack;
  wire i_io_msInfo_bits_w_releaseack;
  wire g_io_msInfo_bits_w_replResp;
  wire i_io_msInfo_bits_w_replResp;
  wire g_io_msInfo_bits_w_rprobeacklast;
  wire i_io_msInfo_bits_w_rprobeacklast;
  wire g_io_msInfo_bits_replaceData;
  wire i_io_msInfo_bits_replaceData;
  wire g_io_msInfo_bits_releaseToClean;
  wire i_io_msInfo_bits_releaseToClean;
  wire g_io_tasks_txreq_valid;
  wire i_io_tasks_txreq_valid;
  wire [10:0] g_io_tasks_txreq_bits_tgtID;
  wire [10:0] i_io_tasks_txreq_bits_tgtID;
  wire [11:0] g_io_tasks_txreq_bits_txnID;
  wire [11:0] i_io_tasks_txreq_bits_txnID;
  wire [6:0] g_io_tasks_txreq_bits_opcode;
  wire [6:0] i_io_tasks_txreq_bits_opcode;
  wire [47:0] g_io_tasks_txreq_bits_addr;
  wire [47:0] i_io_tasks_txreq_bits_addr;
  wire g_io_tasks_txreq_bits_likelyshared;
  wire i_io_tasks_txreq_bits_likelyshared;
  wire g_io_tasks_txreq_bits_allowRetry;
  wire i_io_tasks_txreq_bits_allowRetry;
  wire [3:0] g_io_tasks_txreq_bits_pCrdType;
  wire [3:0] i_io_tasks_txreq_bits_pCrdType;
  wire g_io_tasks_txreq_bits_memAttr_allocate;
  wire i_io_tasks_txreq_bits_memAttr_allocate;
  wire g_io_tasks_txreq_bits_memAttr_ewa;
  wire i_io_tasks_txreq_bits_memAttr_ewa;
  wire g_io_tasks_txreq_bits_expCompAck;
  wire i_io_tasks_txreq_bits_expCompAck;
  wire g_io_tasks_txrsp_valid;
  wire i_io_tasks_txrsp_valid;
  wire [10:0] g_io_tasks_txrsp_bits_tgtID;
  wire [10:0] i_io_tasks_txrsp_bits_tgtID;
  wire [11:0] g_io_tasks_txrsp_bits_txnID;
  wire [11:0] i_io_tasks_txrsp_bits_txnID;
  wire g_io_tasks_txrsp_bits_traceTag;
  wire i_io_tasks_txrsp_bits_traceTag;
  wire g_io_tasks_source_b_valid;
  wire i_io_tasks_source_b_valid;
  wire [30:0] g_io_tasks_source_b_bits_tag;
  wire [30:0] i_io_tasks_source_b_bits_tag;
  wire [8:0] g_io_tasks_source_b_bits_set;
  wire [8:0] i_io_tasks_source_b_bits_set;
  wire [1:0] g_io_tasks_source_b_bits_param;
  wire [1:0] i_io_tasks_source_b_bits_param;
  wire [1:0] g_io_tasks_source_b_bits_alias;
  wire [1:0] i_io_tasks_source_b_bits_alias;
  wire g_io_tasks_mainpipe_valid;
  wire i_io_tasks_mainpipe_valid;
  wire [2:0] g_io_tasks_mainpipe_bits_channel;
  wire [2:0] i_io_tasks_mainpipe_bits_channel;
  wire [2:0] g_io_tasks_mainpipe_bits_txChannel;
  wire [2:0] i_io_tasks_mainpipe_bits_txChannel;
  wire [8:0] g_io_tasks_mainpipe_bits_set;
  wire [8:0] i_io_tasks_mainpipe_bits_set;
  wire [30:0] g_io_tasks_mainpipe_bits_tag;
  wire [30:0] i_io_tasks_mainpipe_bits_tag;
  wire [5:0] g_io_tasks_mainpipe_bits_off;
  wire [5:0] i_io_tasks_mainpipe_bits_off;
  wire [1:0] g_io_tasks_mainpipe_bits_alias;
  wire [1:0] i_io_tasks_mainpipe_bits_alias;
  wire g_io_tasks_mainpipe_bits_isKeyword;
  wire i_io_tasks_mainpipe_bits_isKeyword;
  wire [3:0] g_io_tasks_mainpipe_bits_opcode;
  wire [3:0] i_io_tasks_mainpipe_bits_opcode;
  wire [2:0] g_io_tasks_mainpipe_bits_param;
  wire [2:0] i_io_tasks_mainpipe_bits_param;
  wire [2:0] g_io_tasks_mainpipe_bits_size;
  wire [2:0] i_io_tasks_mainpipe_bits_size;
  wire [6:0] g_io_tasks_mainpipe_bits_sourceId;
  wire [6:0] i_io_tasks_mainpipe_bits_sourceId;
  wire g_io_tasks_mainpipe_bits_denied;
  wire i_io_tasks_mainpipe_bits_denied;
  wire g_io_tasks_mainpipe_bits_corrupt;
  wire i_io_tasks_mainpipe_bits_corrupt;
  wire [7:0] g_io_tasks_mainpipe_bits_mshrId;
  wire [7:0] i_io_tasks_mainpipe_bits_mshrId;
  wire g_io_tasks_mainpipe_bits_aliasTask;
  wire i_io_tasks_mainpipe_bits_aliasTask;
  wire g_io_tasks_mainpipe_bits_useProbeData;
  wire i_io_tasks_mainpipe_bits_useProbeData;
  wire g_io_tasks_mainpipe_bits_mshrRetry;
  wire i_io_tasks_mainpipe_bits_mshrRetry;
  wire g_io_tasks_mainpipe_bits_readProbeDataDown;
  wire i_io_tasks_mainpipe_bits_readProbeDataDown;
  wire g_io_tasks_mainpipe_bits_fromL2pft;
  wire i_io_tasks_mainpipe_bits_fromL2pft;
  wire g_io_tasks_mainpipe_bits_dirty;
  wire i_io_tasks_mainpipe_bits_dirty;
  wire [2:0] g_io_tasks_mainpipe_bits_way;
  wire [2:0] i_io_tasks_mainpipe_bits_way;
  wire g_io_tasks_mainpipe_bits_meta_dirty;
  wire i_io_tasks_mainpipe_bits_meta_dirty;
  wire [1:0] g_io_tasks_mainpipe_bits_meta_state;
  wire [1:0] i_io_tasks_mainpipe_bits_meta_state;
  wire g_io_tasks_mainpipe_bits_meta_clients;
  wire i_io_tasks_mainpipe_bits_meta_clients;
  wire [1:0] g_io_tasks_mainpipe_bits_meta_alias;
  wire [1:0] i_io_tasks_mainpipe_bits_meta_alias;
  wire g_io_tasks_mainpipe_bits_meta_prefetch;
  wire i_io_tasks_mainpipe_bits_meta_prefetch;
  wire [2:0] g_io_tasks_mainpipe_bits_meta_prefetchSrc;
  wire [2:0] i_io_tasks_mainpipe_bits_meta_prefetchSrc;
  wire g_io_tasks_mainpipe_bits_meta_accessed;
  wire i_io_tasks_mainpipe_bits_meta_accessed;
  wire g_io_tasks_mainpipe_bits_meta_tagErr;
  wire i_io_tasks_mainpipe_bits_meta_tagErr;
  wire g_io_tasks_mainpipe_bits_meta_dataErr;
  wire i_io_tasks_mainpipe_bits_meta_dataErr;
  wire g_io_tasks_mainpipe_bits_metaWen;
  wire i_io_tasks_mainpipe_bits_metaWen;
  wire g_io_tasks_mainpipe_bits_tagWen;
  wire i_io_tasks_mainpipe_bits_tagWen;
  wire g_io_tasks_mainpipe_bits_dsWen;
  wire i_io_tasks_mainpipe_bits_dsWen;
  wire g_io_tasks_mainpipe_bits_replTask;
  wire i_io_tasks_mainpipe_bits_replTask;
  wire g_io_tasks_mainpipe_bits_cmoTask;
  wire i_io_tasks_mainpipe_bits_cmoTask;
  wire [4:0] g_io_tasks_mainpipe_bits_reqSource;
  wire [4:0] i_io_tasks_mainpipe_bits_reqSource;
  wire g_io_tasks_mainpipe_bits_mergeA;
  wire i_io_tasks_mainpipe_bits_mergeA;
  wire [5:0] g_io_tasks_mainpipe_bits_aMergeTask_off;
  wire [5:0] i_io_tasks_mainpipe_bits_aMergeTask_off;
  wire [1:0] g_io_tasks_mainpipe_bits_aMergeTask_alias;
  wire [1:0] i_io_tasks_mainpipe_bits_aMergeTask_alias;
  wire [43:0] g_io_tasks_mainpipe_bits_aMergeTask_vaddr;
  wire [43:0] i_io_tasks_mainpipe_bits_aMergeTask_vaddr;
  wire g_io_tasks_mainpipe_bits_aMergeTask_isKeyword;
  wire i_io_tasks_mainpipe_bits_aMergeTask_isKeyword;
  wire [2:0] g_io_tasks_mainpipe_bits_aMergeTask_opcode;
  wire [2:0] i_io_tasks_mainpipe_bits_aMergeTask_opcode;
  wire [2:0] g_io_tasks_mainpipe_bits_aMergeTask_param;
  wire [2:0] i_io_tasks_mainpipe_bits_aMergeTask_param;
  wire [6:0] g_io_tasks_mainpipe_bits_aMergeTask_sourceId;
  wire [6:0] i_io_tasks_mainpipe_bits_aMergeTask_sourceId;
  wire g_io_tasks_mainpipe_bits_aMergeTask_meta_dirty;
  wire i_io_tasks_mainpipe_bits_aMergeTask_meta_dirty;
  wire [1:0] g_io_tasks_mainpipe_bits_aMergeTask_meta_state;
  wire [1:0] i_io_tasks_mainpipe_bits_aMergeTask_meta_state;
  wire g_io_tasks_mainpipe_bits_aMergeTask_meta_clients;
  wire i_io_tasks_mainpipe_bits_aMergeTask_meta_clients;
  wire [1:0] g_io_tasks_mainpipe_bits_aMergeTask_meta_alias;
  wire [1:0] i_io_tasks_mainpipe_bits_aMergeTask_meta_alias;
  wire g_io_tasks_mainpipe_bits_aMergeTask_meta_accessed;
  wire i_io_tasks_mainpipe_bits_aMergeTask_meta_accessed;
  wire g_io_tasks_mainpipe_bits_snpHitRelease;
  wire i_io_tasks_mainpipe_bits_snpHitRelease;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseToInval;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseToInval;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseToClean;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseToClean;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseWithData;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseWithData;
  wire [7:0] g_io_tasks_mainpipe_bits_snpHitReleaseIdx;
  wire [7:0] i_io_tasks_mainpipe_bits_snpHitReleaseIdx;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_tasks_mainpipe_bits_snpHitReleaseMeta_state;
  wire [1:0] i_io_tasks_mainpipe_bits_snpHitReleaseMeta_state;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients;
  wire [1:0] g_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias;
  wire [1:0] i_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr;
  wire g_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr;
  wire i_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_tasks_mainpipe_bits_tgtID;
  wire [10:0] i_io_tasks_mainpipe_bits_tgtID;
  wire [11:0] g_io_tasks_mainpipe_bits_txnID;
  wire [11:0] i_io_tasks_mainpipe_bits_txnID;
  wire [10:0] g_io_tasks_mainpipe_bits_homeNID;
  wire [10:0] i_io_tasks_mainpipe_bits_homeNID;
  wire [11:0] g_io_tasks_mainpipe_bits_dbID;
  wire [11:0] i_io_tasks_mainpipe_bits_dbID;
  wire [6:0] g_io_tasks_mainpipe_bits_chiOpcode;
  wire [6:0] i_io_tasks_mainpipe_bits_chiOpcode;
  wire [2:0] g_io_tasks_mainpipe_bits_resp;
  wire [2:0] i_io_tasks_mainpipe_bits_resp;
  wire [2:0] g_io_tasks_mainpipe_bits_fwdState;
  wire [2:0] i_io_tasks_mainpipe_bits_fwdState;
  wire g_io_tasks_mainpipe_bits_retToSrc;
  wire i_io_tasks_mainpipe_bits_retToSrc;
  wire g_io_tasks_mainpipe_bits_likelyshared;
  wire i_io_tasks_mainpipe_bits_likelyshared;
  wire g_io_tasks_mainpipe_bits_expCompAck;
  wire i_io_tasks_mainpipe_bits_expCompAck;
  wire g_io_tasks_mainpipe_bits_allowRetry;
  wire i_io_tasks_mainpipe_bits_allowRetry;
  wire g_io_tasks_mainpipe_bits_memAttr_allocate;
  wire i_io_tasks_mainpipe_bits_memAttr_allocate;
  wire g_io_tasks_mainpipe_bits_memAttr_cacheable;
  wire i_io_tasks_mainpipe_bits_memAttr_cacheable;
  wire g_io_tasks_mainpipe_bits_memAttr_ewa;
  wire i_io_tasks_mainpipe_bits_memAttr_ewa;
  wire g_io_tasks_mainpipe_bits_traceTag;
  wire i_io_tasks_mainpipe_bits_traceTag;
  wire g_io_tasks_mainpipe_bits_dataCheckErr;
  wire i_io_tasks_mainpipe_bits_dataCheckErr;
  wire g_io_nestedwbData;
  wire i_io_nestedwbData;
  wire g_io_pCrd_query_valid;
  wire i_io_pCrd_query_valid;
  wire [3:0] g_io_pCrd_query_bits_pCrdType;
  wire [3:0] i_io_pCrd_query_bits_pCrdType;
  wire [10:0] g_io_pCrd_query_bits_srcID;
  wire [10:0] i_io_pCrd_query_bits_srcID;
  wire g_acquire_period_valid;
  wire i_acquire_period_valid;
  wire [63:0] g_acquire_period_bits;
  wire [63:0] i_acquire_period_bits;
  wire g_release_period_valid;
  wire i_release_period_valid;
  wire [63:0] g_release_period_bits;
  wire [63:0] i_release_period_bits;

  MSHR u_g (
    .clock(clock),
    .reset(reset),
    .io_id(io_id),
    .io_status_valid(g_io_status_valid),
    .io_status_bits_channel(g_io_status_bits_channel),
    .io_status_bits_set(g_io_status_bits_set),
    .io_status_bits_reqTag(g_io_status_bits_reqTag),
    .io_status_bits_metaTag(g_io_status_bits_metaTag),
    .io_status_bits_needsRepl(g_io_status_bits_needsRepl),
    .io_status_bits_w_c_resp(g_io_status_bits_w_c_resp),
    .io_status_bits_will_free(g_io_status_bits_will_free),
    .io_status_bits_reqSource(g_io_status_bits_reqSource),
    .io_status_bits_is_miss(g_io_status_bits_is_miss),
    .io_status_bits_is_prefetch(g_io_status_bits_is_prefetch),
    .io_msInfo_valid(g_io_msInfo_valid),
    .io_msInfo_bits_channel(g_io_msInfo_bits_channel),
    .io_msInfo_bits_set(g_io_msInfo_bits_set),
    .io_msInfo_bits_way(g_io_msInfo_bits_way),
    .io_msInfo_bits_reqTag(g_io_msInfo_bits_reqTag),
    .io_msInfo_bits_willFree(g_io_msInfo_bits_willFree),
    .io_msInfo_bits_aliasTask(g_io_msInfo_bits_aliasTask),
    .io_msInfo_bits_needRelease(g_io_msInfo_bits_needRelease),
    .io_msInfo_bits_blockRefill(g_io_msInfo_bits_blockRefill),
    .io_msInfo_bits_meta_dirty(g_io_msInfo_bits_meta_dirty),
    .io_msInfo_bits_meta_state(g_io_msInfo_bits_meta_state),
    .io_msInfo_bits_meta_clients(g_io_msInfo_bits_meta_clients),
    .io_msInfo_bits_meta_alias(g_io_msInfo_bits_meta_alias),
    .io_msInfo_bits_meta_prefetch(g_io_msInfo_bits_meta_prefetch),
    .io_msInfo_bits_meta_prefetchSrc(g_io_msInfo_bits_meta_prefetchSrc),
    .io_msInfo_bits_meta_accessed(g_io_msInfo_bits_meta_accessed),
    .io_msInfo_bits_meta_tagErr(g_io_msInfo_bits_meta_tagErr),
    .io_msInfo_bits_meta_dataErr(g_io_msInfo_bits_meta_dataErr),
    .io_msInfo_bits_metaTag(g_io_msInfo_bits_metaTag),
    .io_msInfo_bits_dirHit(g_io_msInfo_bits_dirHit),
    .io_msInfo_bits_isAcqOrPrefetch(g_io_msInfo_bits_isAcqOrPrefetch),
    .io_msInfo_bits_isPrefetch(g_io_msInfo_bits_isPrefetch),
    .io_msInfo_bits_param(g_io_msInfo_bits_param),
    .io_msInfo_bits_mergeA(g_io_msInfo_bits_mergeA),
    .io_msInfo_bits_w_grantfirst(g_io_msInfo_bits_w_grantfirst),
    .io_msInfo_bits_s_release(g_io_msInfo_bits_s_release),
    .io_msInfo_bits_s_refill(g_io_msInfo_bits_s_refill),
    .io_msInfo_bits_s_cmoresp(g_io_msInfo_bits_s_cmoresp),
    .io_msInfo_bits_s_cmometaw(g_io_msInfo_bits_s_cmometaw),
    .io_msInfo_bits_w_releaseack(g_io_msInfo_bits_w_releaseack),
    .io_msInfo_bits_w_replResp(g_io_msInfo_bits_w_replResp),
    .io_msInfo_bits_w_rprobeacklast(g_io_msInfo_bits_w_rprobeacklast),
    .io_msInfo_bits_replaceData(g_io_msInfo_bits_replaceData),
    .io_msInfo_bits_releaseToClean(g_io_msInfo_bits_releaseToClean),
    .io_alloc_valid(io_alloc_valid),
    .io_alloc_bits_dirResult_hit(io_alloc_bits_dirResult_hit),
    .io_alloc_bits_dirResult_tag(io_alloc_bits_dirResult_tag),
    .io_alloc_bits_dirResult_set(io_alloc_bits_dirResult_set),
    .io_alloc_bits_dirResult_way(io_alloc_bits_dirResult_way),
    .io_alloc_bits_dirResult_meta_dirty(io_alloc_bits_dirResult_meta_dirty),
    .io_alloc_bits_dirResult_meta_state(io_alloc_bits_dirResult_meta_state),
    .io_alloc_bits_dirResult_meta_clients(io_alloc_bits_dirResult_meta_clients),
    .io_alloc_bits_dirResult_meta_alias(io_alloc_bits_dirResult_meta_alias),
    .io_alloc_bits_dirResult_meta_prefetch(io_alloc_bits_dirResult_meta_prefetch),
    .io_alloc_bits_dirResult_meta_prefetchSrc(io_alloc_bits_dirResult_meta_prefetchSrc),
    .io_alloc_bits_dirResult_meta_accessed(io_alloc_bits_dirResult_meta_accessed),
    .io_alloc_bits_dirResult_meta_tagErr(io_alloc_bits_dirResult_meta_tagErr),
    .io_alloc_bits_dirResult_meta_dataErr(io_alloc_bits_dirResult_meta_dataErr),
    .io_alloc_bits_dirResult_error(io_alloc_bits_dirResult_error),
    .io_alloc_bits_state_s_acquire(io_alloc_bits_state_s_acquire),
    .io_alloc_bits_state_s_rprobe(io_alloc_bits_state_s_rprobe),
    .io_alloc_bits_state_s_pprobe(io_alloc_bits_state_s_pprobe),
    .io_alloc_bits_state_s_release(io_alloc_bits_state_s_release),
    .io_alloc_bits_state_s_probeack(io_alloc_bits_state_s_probeack),
    .io_alloc_bits_state_s_refill(io_alloc_bits_state_s_refill),
    .io_alloc_bits_state_s_cmoresp(io_alloc_bits_state_s_cmoresp),
    .io_alloc_bits_state_w_rprobeackfirst(io_alloc_bits_state_w_rprobeackfirst),
    .io_alloc_bits_state_w_rprobeacklast(io_alloc_bits_state_w_rprobeacklast),
    .io_alloc_bits_state_w_pprobeackfirst(io_alloc_bits_state_w_pprobeackfirst),
    .io_alloc_bits_state_w_pprobeacklast(io_alloc_bits_state_w_pprobeacklast),
    .io_alloc_bits_state_w_grantfirst(io_alloc_bits_state_w_grantfirst),
    .io_alloc_bits_state_w_grantlast(io_alloc_bits_state_w_grantlast),
    .io_alloc_bits_state_w_grant(io_alloc_bits_state_w_grant),
    .io_alloc_bits_state_w_releaseack(io_alloc_bits_state_w_releaseack),
    .io_alloc_bits_state_w_replResp(io_alloc_bits_state_w_replResp),
    .io_alloc_bits_state_s_rcompack(io_alloc_bits_state_s_rcompack),
    .io_alloc_bits_state_s_dct(io_alloc_bits_state_s_dct),
    .io_alloc_bits_task_channel(io_alloc_bits_task_channel),
    .io_alloc_bits_task_set(io_alloc_bits_task_set),
    .io_alloc_bits_task_tag(io_alloc_bits_task_tag),
    .io_alloc_bits_task_off(io_alloc_bits_task_off),
    .io_alloc_bits_task_alias(io_alloc_bits_task_alias),
    .io_alloc_bits_task_isKeyword(io_alloc_bits_task_isKeyword),
    .io_alloc_bits_task_opcode(io_alloc_bits_task_opcode),
    .io_alloc_bits_task_param(io_alloc_bits_task_param),
    .io_alloc_bits_task_sourceId(io_alloc_bits_task_sourceId),
    .io_alloc_bits_task_aliasTask(io_alloc_bits_task_aliasTask),
    .io_alloc_bits_task_fromL2pft(io_alloc_bits_task_fromL2pft),
    .io_alloc_bits_task_reqSource(io_alloc_bits_task_reqSource),
    .io_alloc_bits_task_snpHitRelease(io_alloc_bits_task_snpHitRelease),
    .io_alloc_bits_task_snpHitReleaseToInval(io_alloc_bits_task_snpHitReleaseToInval),
    .io_alloc_bits_task_snpHitReleaseToClean(io_alloc_bits_task_snpHitReleaseToClean),
    .io_alloc_bits_task_snpHitReleaseWithData(io_alloc_bits_task_snpHitReleaseWithData),
    .io_alloc_bits_task_snpHitReleaseIdx(io_alloc_bits_task_snpHitReleaseIdx),
    .io_alloc_bits_task_snpHitReleaseMeta_dirty(io_alloc_bits_task_snpHitReleaseMeta_dirty),
    .io_alloc_bits_task_snpHitReleaseMeta_state(io_alloc_bits_task_snpHitReleaseMeta_state),
    .io_alloc_bits_task_snpHitReleaseMeta_clients(io_alloc_bits_task_snpHitReleaseMeta_clients),
    .io_alloc_bits_task_snpHitReleaseMeta_alias(io_alloc_bits_task_snpHitReleaseMeta_alias),
    .io_alloc_bits_task_snpHitReleaseMeta_prefetch(io_alloc_bits_task_snpHitReleaseMeta_prefetch),
    .io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc(io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_alloc_bits_task_snpHitReleaseMeta_accessed(io_alloc_bits_task_snpHitReleaseMeta_accessed),
    .io_alloc_bits_task_snpHitReleaseMeta_tagErr(io_alloc_bits_task_snpHitReleaseMeta_tagErr),
    .io_alloc_bits_task_snpHitReleaseMeta_dataErr(io_alloc_bits_task_snpHitReleaseMeta_dataErr),
    .io_alloc_bits_task_srcID(io_alloc_bits_task_srcID),
    .io_alloc_bits_task_txnID(io_alloc_bits_task_txnID),
    .io_alloc_bits_task_fwdNID(io_alloc_bits_task_fwdNID),
    .io_alloc_bits_task_fwdTxnID(io_alloc_bits_task_fwdTxnID),
    .io_alloc_bits_task_chiOpcode(io_alloc_bits_task_chiOpcode),
    .io_alloc_bits_task_retToSrc(io_alloc_bits_task_retToSrc),
    .io_alloc_bits_task_traceTag(io_alloc_bits_task_traceTag),
    .io_tasks_txreq_ready(io_tasks_txreq_ready),
    .io_tasks_txreq_valid(g_io_tasks_txreq_valid),
    .io_tasks_txreq_bits_tgtID(g_io_tasks_txreq_bits_tgtID),
    .io_tasks_txreq_bits_txnID(g_io_tasks_txreq_bits_txnID),
    .io_tasks_txreq_bits_opcode(g_io_tasks_txreq_bits_opcode),
    .io_tasks_txreq_bits_addr(g_io_tasks_txreq_bits_addr),
    .io_tasks_txreq_bits_likelyshared(g_io_tasks_txreq_bits_likelyshared),
    .io_tasks_txreq_bits_allowRetry(g_io_tasks_txreq_bits_allowRetry),
    .io_tasks_txreq_bits_pCrdType(g_io_tasks_txreq_bits_pCrdType),
    .io_tasks_txreq_bits_memAttr_allocate(g_io_tasks_txreq_bits_memAttr_allocate),
    .io_tasks_txreq_bits_memAttr_ewa(g_io_tasks_txreq_bits_memAttr_ewa),
    .io_tasks_txreq_bits_expCompAck(g_io_tasks_txreq_bits_expCompAck),
    .io_tasks_txrsp_ready(io_tasks_txrsp_ready),
    .io_tasks_txrsp_valid(g_io_tasks_txrsp_valid),
    .io_tasks_txrsp_bits_tgtID(g_io_tasks_txrsp_bits_tgtID),
    .io_tasks_txrsp_bits_txnID(g_io_tasks_txrsp_bits_txnID),
    .io_tasks_txrsp_bits_traceTag(g_io_tasks_txrsp_bits_traceTag),
    .io_tasks_source_b_ready(io_tasks_source_b_ready),
    .io_tasks_source_b_valid(g_io_tasks_source_b_valid),
    .io_tasks_source_b_bits_tag(g_io_tasks_source_b_bits_tag),
    .io_tasks_source_b_bits_set(g_io_tasks_source_b_bits_set),
    .io_tasks_source_b_bits_param(g_io_tasks_source_b_bits_param),
    .io_tasks_source_b_bits_alias(g_io_tasks_source_b_bits_alias),
    .io_tasks_mainpipe_ready(io_tasks_mainpipe_ready),
    .io_tasks_mainpipe_valid(g_io_tasks_mainpipe_valid),
    .io_tasks_mainpipe_bits_channel(g_io_tasks_mainpipe_bits_channel),
    .io_tasks_mainpipe_bits_txChannel(g_io_tasks_mainpipe_bits_txChannel),
    .io_tasks_mainpipe_bits_set(g_io_tasks_mainpipe_bits_set),
    .io_tasks_mainpipe_bits_tag(g_io_tasks_mainpipe_bits_tag),
    .io_tasks_mainpipe_bits_off(g_io_tasks_mainpipe_bits_off),
    .io_tasks_mainpipe_bits_alias(g_io_tasks_mainpipe_bits_alias),
    .io_tasks_mainpipe_bits_isKeyword(g_io_tasks_mainpipe_bits_isKeyword),
    .io_tasks_mainpipe_bits_opcode(g_io_tasks_mainpipe_bits_opcode),
    .io_tasks_mainpipe_bits_param(g_io_tasks_mainpipe_bits_param),
    .io_tasks_mainpipe_bits_size(g_io_tasks_mainpipe_bits_size),
    .io_tasks_mainpipe_bits_sourceId(g_io_tasks_mainpipe_bits_sourceId),
    .io_tasks_mainpipe_bits_denied(g_io_tasks_mainpipe_bits_denied),
    .io_tasks_mainpipe_bits_corrupt(g_io_tasks_mainpipe_bits_corrupt),
    .io_tasks_mainpipe_bits_mshrId(g_io_tasks_mainpipe_bits_mshrId),
    .io_tasks_mainpipe_bits_aliasTask(g_io_tasks_mainpipe_bits_aliasTask),
    .io_tasks_mainpipe_bits_useProbeData(g_io_tasks_mainpipe_bits_useProbeData),
    .io_tasks_mainpipe_bits_mshrRetry(g_io_tasks_mainpipe_bits_mshrRetry),
    .io_tasks_mainpipe_bits_readProbeDataDown(g_io_tasks_mainpipe_bits_readProbeDataDown),
    .io_tasks_mainpipe_bits_fromL2pft(g_io_tasks_mainpipe_bits_fromL2pft),
    .io_tasks_mainpipe_bits_dirty(g_io_tasks_mainpipe_bits_dirty),
    .io_tasks_mainpipe_bits_way(g_io_tasks_mainpipe_bits_way),
    .io_tasks_mainpipe_bits_meta_dirty(g_io_tasks_mainpipe_bits_meta_dirty),
    .io_tasks_mainpipe_bits_meta_state(g_io_tasks_mainpipe_bits_meta_state),
    .io_tasks_mainpipe_bits_meta_clients(g_io_tasks_mainpipe_bits_meta_clients),
    .io_tasks_mainpipe_bits_meta_alias(g_io_tasks_mainpipe_bits_meta_alias),
    .io_tasks_mainpipe_bits_meta_prefetch(g_io_tasks_mainpipe_bits_meta_prefetch),
    .io_tasks_mainpipe_bits_meta_prefetchSrc(g_io_tasks_mainpipe_bits_meta_prefetchSrc),
    .io_tasks_mainpipe_bits_meta_accessed(g_io_tasks_mainpipe_bits_meta_accessed),
    .io_tasks_mainpipe_bits_meta_tagErr(g_io_tasks_mainpipe_bits_meta_tagErr),
    .io_tasks_mainpipe_bits_meta_dataErr(g_io_tasks_mainpipe_bits_meta_dataErr),
    .io_tasks_mainpipe_bits_metaWen(g_io_tasks_mainpipe_bits_metaWen),
    .io_tasks_mainpipe_bits_tagWen(g_io_tasks_mainpipe_bits_tagWen),
    .io_tasks_mainpipe_bits_dsWen(g_io_tasks_mainpipe_bits_dsWen),
    .io_tasks_mainpipe_bits_replTask(g_io_tasks_mainpipe_bits_replTask),
    .io_tasks_mainpipe_bits_cmoTask(g_io_tasks_mainpipe_bits_cmoTask),
    .io_tasks_mainpipe_bits_reqSource(g_io_tasks_mainpipe_bits_reqSource),
    .io_tasks_mainpipe_bits_mergeA(g_io_tasks_mainpipe_bits_mergeA),
    .io_tasks_mainpipe_bits_aMergeTask_off(g_io_tasks_mainpipe_bits_aMergeTask_off),
    .io_tasks_mainpipe_bits_aMergeTask_alias(g_io_tasks_mainpipe_bits_aMergeTask_alias),
    .io_tasks_mainpipe_bits_aMergeTask_vaddr(g_io_tasks_mainpipe_bits_aMergeTask_vaddr),
    .io_tasks_mainpipe_bits_aMergeTask_isKeyword(g_io_tasks_mainpipe_bits_aMergeTask_isKeyword),
    .io_tasks_mainpipe_bits_aMergeTask_opcode(g_io_tasks_mainpipe_bits_aMergeTask_opcode),
    .io_tasks_mainpipe_bits_aMergeTask_param(g_io_tasks_mainpipe_bits_aMergeTask_param),
    .io_tasks_mainpipe_bits_aMergeTask_sourceId(g_io_tasks_mainpipe_bits_aMergeTask_sourceId),
    .io_tasks_mainpipe_bits_aMergeTask_meta_dirty(g_io_tasks_mainpipe_bits_aMergeTask_meta_dirty),
    .io_tasks_mainpipe_bits_aMergeTask_meta_state(g_io_tasks_mainpipe_bits_aMergeTask_meta_state),
    .io_tasks_mainpipe_bits_aMergeTask_meta_clients(g_io_tasks_mainpipe_bits_aMergeTask_meta_clients),
    .io_tasks_mainpipe_bits_aMergeTask_meta_alias(g_io_tasks_mainpipe_bits_aMergeTask_meta_alias),
    .io_tasks_mainpipe_bits_aMergeTask_meta_accessed(g_io_tasks_mainpipe_bits_aMergeTask_meta_accessed),
    .io_tasks_mainpipe_bits_snpHitRelease(g_io_tasks_mainpipe_bits_snpHitRelease),
    .io_tasks_mainpipe_bits_snpHitReleaseToInval(g_io_tasks_mainpipe_bits_snpHitReleaseToInval),
    .io_tasks_mainpipe_bits_snpHitReleaseToClean(g_io_tasks_mainpipe_bits_snpHitReleaseToClean),
    .io_tasks_mainpipe_bits_snpHitReleaseWithData(g_io_tasks_mainpipe_bits_snpHitReleaseWithData),
    .io_tasks_mainpipe_bits_snpHitReleaseIdx(g_io_tasks_mainpipe_bits_snpHitReleaseIdx),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_state(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_state),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_clients(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_alias(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr(g_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr),
    .io_tasks_mainpipe_bits_tgtID(g_io_tasks_mainpipe_bits_tgtID),
    .io_tasks_mainpipe_bits_txnID(g_io_tasks_mainpipe_bits_txnID),
    .io_tasks_mainpipe_bits_homeNID(g_io_tasks_mainpipe_bits_homeNID),
    .io_tasks_mainpipe_bits_dbID(g_io_tasks_mainpipe_bits_dbID),
    .io_tasks_mainpipe_bits_chiOpcode(g_io_tasks_mainpipe_bits_chiOpcode),
    .io_tasks_mainpipe_bits_resp(g_io_tasks_mainpipe_bits_resp),
    .io_tasks_mainpipe_bits_fwdState(g_io_tasks_mainpipe_bits_fwdState),
    .io_tasks_mainpipe_bits_retToSrc(g_io_tasks_mainpipe_bits_retToSrc),
    .io_tasks_mainpipe_bits_likelyshared(g_io_tasks_mainpipe_bits_likelyshared),
    .io_tasks_mainpipe_bits_expCompAck(g_io_tasks_mainpipe_bits_expCompAck),
    .io_tasks_mainpipe_bits_allowRetry(g_io_tasks_mainpipe_bits_allowRetry),
    .io_tasks_mainpipe_bits_memAttr_allocate(g_io_tasks_mainpipe_bits_memAttr_allocate),
    .io_tasks_mainpipe_bits_memAttr_cacheable(g_io_tasks_mainpipe_bits_memAttr_cacheable),
    .io_tasks_mainpipe_bits_memAttr_ewa(g_io_tasks_mainpipe_bits_memAttr_ewa),
    .io_tasks_mainpipe_bits_traceTag(g_io_tasks_mainpipe_bits_traceTag),
    .io_tasks_mainpipe_bits_dataCheckErr(g_io_tasks_mainpipe_bits_dataCheckErr),
    .io_resps_sinkC_valid(io_resps_sinkC_valid),
    .io_resps_sinkC_bits_opcode(io_resps_sinkC_bits_opcode),
    .io_resps_sinkC_bits_param(io_resps_sinkC_bits_param),
    .io_resps_sinkC_bits_last(io_resps_sinkC_bits_last),
    .io_resps_sinkC_bits_denied(io_resps_sinkC_bits_denied),
    .io_resps_sinkC_bits_corrupt(io_resps_sinkC_bits_corrupt),
    .io_resps_rxrsp_valid(io_resps_rxrsp_valid),
    .io_resps_rxrsp_bits_chiOpcode(io_resps_rxrsp_bits_chiOpcode),
    .io_resps_rxrsp_bits_srcID(io_resps_rxrsp_bits_srcID),
    .io_resps_rxrsp_bits_dbID(io_resps_rxrsp_bits_dbID),
    .io_resps_rxrsp_bits_resp(io_resps_rxrsp_bits_resp),
    .io_resps_rxrsp_bits_pCrdType(io_resps_rxrsp_bits_pCrdType),
    .io_resps_rxrsp_bits_respErr(io_resps_rxrsp_bits_respErr),
    .io_resps_rxrsp_bits_traceTag(io_resps_rxrsp_bits_traceTag),
    .io_resps_rxdat_valid(io_resps_rxdat_valid),
    .io_resps_rxdat_bits_corrupt(io_resps_rxdat_bits_corrupt),
    .io_resps_rxdat_bits_chiOpcode(io_resps_rxdat_bits_chiOpcode),
    .io_resps_rxdat_bits_homeNID(io_resps_rxdat_bits_homeNID),
    .io_resps_rxdat_bits_dbID(io_resps_rxdat_bits_dbID),
    .io_resps_rxdat_bits_resp(io_resps_rxdat_bits_resp),
    .io_resps_rxdat_bits_respErr(io_resps_rxdat_bits_respErr),
    .io_resps_rxdat_bits_traceTag(io_resps_rxdat_bits_traceTag),
    .io_resps_rxdat_bits_dataCheckErr(io_resps_rxdat_bits_dataCheckErr),
    .io_nestedwb_set(io_nestedwb_set),
    .io_nestedwb_tag(io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(io_nestedwb_b_toB),
    .io_nestedwb_b_toN(io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
    .io_nestedwbData(g_io_nestedwbData),
    .io_aMergeTask_valid(io_aMergeTask_valid),
    .io_aMergeTask_bits_off(io_aMergeTask_bits_off),
    .io_aMergeTask_bits_alias(io_aMergeTask_bits_alias),
    .io_aMergeTask_bits_vaddr(io_aMergeTask_bits_vaddr),
    .io_aMergeTask_bits_isKeyword(io_aMergeTask_bits_isKeyword),
    .io_aMergeTask_bits_opcode(io_aMergeTask_bits_opcode),
    .io_aMergeTask_bits_param(io_aMergeTask_bits_param),
    .io_aMergeTask_bits_sourceId(io_aMergeTask_bits_sourceId),
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
    .io_replResp_bits_retry(io_replResp_bits_retry),
    .io_pCrd_query_valid(g_io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType(g_io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID(g_io_pCrd_query_bits_srcID),
    .io_pCrd_grant(io_pCrd_grant),
    .acquire_period_valid(g_acquire_period_valid),
    .acquire_period_bits(g_acquire_period_bits),
    .release_period_valid(g_release_period_valid),
    .release_period_bits(g_release_period_bits)
  );
  MSHR_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_id(io_id),
    .io_status_valid(i_io_status_valid),
    .io_status_bits_channel(i_io_status_bits_channel),
    .io_status_bits_set(i_io_status_bits_set),
    .io_status_bits_reqTag(i_io_status_bits_reqTag),
    .io_status_bits_metaTag(i_io_status_bits_metaTag),
    .io_status_bits_needsRepl(i_io_status_bits_needsRepl),
    .io_status_bits_w_c_resp(i_io_status_bits_w_c_resp),
    .io_status_bits_will_free(i_io_status_bits_will_free),
    .io_status_bits_reqSource(i_io_status_bits_reqSource),
    .io_status_bits_is_miss(i_io_status_bits_is_miss),
    .io_status_bits_is_prefetch(i_io_status_bits_is_prefetch),
    .io_msInfo_valid(i_io_msInfo_valid),
    .io_msInfo_bits_channel(i_io_msInfo_bits_channel),
    .io_msInfo_bits_set(i_io_msInfo_bits_set),
    .io_msInfo_bits_way(i_io_msInfo_bits_way),
    .io_msInfo_bits_reqTag(i_io_msInfo_bits_reqTag),
    .io_msInfo_bits_willFree(i_io_msInfo_bits_willFree),
    .io_msInfo_bits_aliasTask(i_io_msInfo_bits_aliasTask),
    .io_msInfo_bits_needRelease(i_io_msInfo_bits_needRelease),
    .io_msInfo_bits_blockRefill(i_io_msInfo_bits_blockRefill),
    .io_msInfo_bits_meta_dirty(i_io_msInfo_bits_meta_dirty),
    .io_msInfo_bits_meta_state(i_io_msInfo_bits_meta_state),
    .io_msInfo_bits_meta_clients(i_io_msInfo_bits_meta_clients),
    .io_msInfo_bits_meta_alias(i_io_msInfo_bits_meta_alias),
    .io_msInfo_bits_meta_prefetch(i_io_msInfo_bits_meta_prefetch),
    .io_msInfo_bits_meta_prefetchSrc(i_io_msInfo_bits_meta_prefetchSrc),
    .io_msInfo_bits_meta_accessed(i_io_msInfo_bits_meta_accessed),
    .io_msInfo_bits_meta_tagErr(i_io_msInfo_bits_meta_tagErr),
    .io_msInfo_bits_meta_dataErr(i_io_msInfo_bits_meta_dataErr),
    .io_msInfo_bits_metaTag(i_io_msInfo_bits_metaTag),
    .io_msInfo_bits_dirHit(i_io_msInfo_bits_dirHit),
    .io_msInfo_bits_isAcqOrPrefetch(i_io_msInfo_bits_isAcqOrPrefetch),
    .io_msInfo_bits_isPrefetch(i_io_msInfo_bits_isPrefetch),
    .io_msInfo_bits_param(i_io_msInfo_bits_param),
    .io_msInfo_bits_mergeA(i_io_msInfo_bits_mergeA),
    .io_msInfo_bits_w_grantfirst(i_io_msInfo_bits_w_grantfirst),
    .io_msInfo_bits_s_release(i_io_msInfo_bits_s_release),
    .io_msInfo_bits_s_refill(i_io_msInfo_bits_s_refill),
    .io_msInfo_bits_s_cmoresp(i_io_msInfo_bits_s_cmoresp),
    .io_msInfo_bits_s_cmometaw(i_io_msInfo_bits_s_cmometaw),
    .io_msInfo_bits_w_releaseack(i_io_msInfo_bits_w_releaseack),
    .io_msInfo_bits_w_replResp(i_io_msInfo_bits_w_replResp),
    .io_msInfo_bits_w_rprobeacklast(i_io_msInfo_bits_w_rprobeacklast),
    .io_msInfo_bits_replaceData(i_io_msInfo_bits_replaceData),
    .io_msInfo_bits_releaseToClean(i_io_msInfo_bits_releaseToClean),
    .io_alloc_valid(io_alloc_valid),
    .io_alloc_bits_dirResult_hit(io_alloc_bits_dirResult_hit),
    .io_alloc_bits_dirResult_tag(io_alloc_bits_dirResult_tag),
    .io_alloc_bits_dirResult_set(io_alloc_bits_dirResult_set),
    .io_alloc_bits_dirResult_way(io_alloc_bits_dirResult_way),
    .io_alloc_bits_dirResult_meta_dirty(io_alloc_bits_dirResult_meta_dirty),
    .io_alloc_bits_dirResult_meta_state(io_alloc_bits_dirResult_meta_state),
    .io_alloc_bits_dirResult_meta_clients(io_alloc_bits_dirResult_meta_clients),
    .io_alloc_bits_dirResult_meta_alias(io_alloc_bits_dirResult_meta_alias),
    .io_alloc_bits_dirResult_meta_prefetch(io_alloc_bits_dirResult_meta_prefetch),
    .io_alloc_bits_dirResult_meta_prefetchSrc(io_alloc_bits_dirResult_meta_prefetchSrc),
    .io_alloc_bits_dirResult_meta_accessed(io_alloc_bits_dirResult_meta_accessed),
    .io_alloc_bits_dirResult_meta_tagErr(io_alloc_bits_dirResult_meta_tagErr),
    .io_alloc_bits_dirResult_meta_dataErr(io_alloc_bits_dirResult_meta_dataErr),
    .io_alloc_bits_dirResult_error(io_alloc_bits_dirResult_error),
    .io_alloc_bits_state_s_acquire(io_alloc_bits_state_s_acquire),
    .io_alloc_bits_state_s_rprobe(io_alloc_bits_state_s_rprobe),
    .io_alloc_bits_state_s_pprobe(io_alloc_bits_state_s_pprobe),
    .io_alloc_bits_state_s_release(io_alloc_bits_state_s_release),
    .io_alloc_bits_state_s_probeack(io_alloc_bits_state_s_probeack),
    .io_alloc_bits_state_s_refill(io_alloc_bits_state_s_refill),
    .io_alloc_bits_state_s_cmoresp(io_alloc_bits_state_s_cmoresp),
    .io_alloc_bits_state_w_rprobeackfirst(io_alloc_bits_state_w_rprobeackfirst),
    .io_alloc_bits_state_w_rprobeacklast(io_alloc_bits_state_w_rprobeacklast),
    .io_alloc_bits_state_w_pprobeackfirst(io_alloc_bits_state_w_pprobeackfirst),
    .io_alloc_bits_state_w_pprobeacklast(io_alloc_bits_state_w_pprobeacklast),
    .io_alloc_bits_state_w_grantfirst(io_alloc_bits_state_w_grantfirst),
    .io_alloc_bits_state_w_grantlast(io_alloc_bits_state_w_grantlast),
    .io_alloc_bits_state_w_grant(io_alloc_bits_state_w_grant),
    .io_alloc_bits_state_w_releaseack(io_alloc_bits_state_w_releaseack),
    .io_alloc_bits_state_w_replResp(io_alloc_bits_state_w_replResp),
    .io_alloc_bits_state_s_rcompack(io_alloc_bits_state_s_rcompack),
    .io_alloc_bits_state_s_dct(io_alloc_bits_state_s_dct),
    .io_alloc_bits_task_channel(io_alloc_bits_task_channel),
    .io_alloc_bits_task_set(io_alloc_bits_task_set),
    .io_alloc_bits_task_tag(io_alloc_bits_task_tag),
    .io_alloc_bits_task_off(io_alloc_bits_task_off),
    .io_alloc_bits_task_alias(io_alloc_bits_task_alias),
    .io_alloc_bits_task_isKeyword(io_alloc_bits_task_isKeyword),
    .io_alloc_bits_task_opcode(io_alloc_bits_task_opcode),
    .io_alloc_bits_task_param(io_alloc_bits_task_param),
    .io_alloc_bits_task_sourceId(io_alloc_bits_task_sourceId),
    .io_alloc_bits_task_aliasTask(io_alloc_bits_task_aliasTask),
    .io_alloc_bits_task_fromL2pft(io_alloc_bits_task_fromL2pft),
    .io_alloc_bits_task_reqSource(io_alloc_bits_task_reqSource),
    .io_alloc_bits_task_snpHitRelease(io_alloc_bits_task_snpHitRelease),
    .io_alloc_bits_task_snpHitReleaseToInval(io_alloc_bits_task_snpHitReleaseToInval),
    .io_alloc_bits_task_snpHitReleaseToClean(io_alloc_bits_task_snpHitReleaseToClean),
    .io_alloc_bits_task_snpHitReleaseWithData(io_alloc_bits_task_snpHitReleaseWithData),
    .io_alloc_bits_task_snpHitReleaseIdx(io_alloc_bits_task_snpHitReleaseIdx),
    .io_alloc_bits_task_snpHitReleaseMeta_dirty(io_alloc_bits_task_snpHitReleaseMeta_dirty),
    .io_alloc_bits_task_snpHitReleaseMeta_state(io_alloc_bits_task_snpHitReleaseMeta_state),
    .io_alloc_bits_task_snpHitReleaseMeta_clients(io_alloc_bits_task_snpHitReleaseMeta_clients),
    .io_alloc_bits_task_snpHitReleaseMeta_alias(io_alloc_bits_task_snpHitReleaseMeta_alias),
    .io_alloc_bits_task_snpHitReleaseMeta_prefetch(io_alloc_bits_task_snpHitReleaseMeta_prefetch),
    .io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc(io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_alloc_bits_task_snpHitReleaseMeta_accessed(io_alloc_bits_task_snpHitReleaseMeta_accessed),
    .io_alloc_bits_task_snpHitReleaseMeta_tagErr(io_alloc_bits_task_snpHitReleaseMeta_tagErr),
    .io_alloc_bits_task_snpHitReleaseMeta_dataErr(io_alloc_bits_task_snpHitReleaseMeta_dataErr),
    .io_alloc_bits_task_srcID(io_alloc_bits_task_srcID),
    .io_alloc_bits_task_txnID(io_alloc_bits_task_txnID),
    .io_alloc_bits_task_fwdNID(io_alloc_bits_task_fwdNID),
    .io_alloc_bits_task_fwdTxnID(io_alloc_bits_task_fwdTxnID),
    .io_alloc_bits_task_chiOpcode(io_alloc_bits_task_chiOpcode),
    .io_alloc_bits_task_retToSrc(io_alloc_bits_task_retToSrc),
    .io_alloc_bits_task_traceTag(io_alloc_bits_task_traceTag),
    .io_tasks_txreq_ready(io_tasks_txreq_ready),
    .io_tasks_txreq_valid(i_io_tasks_txreq_valid),
    .io_tasks_txreq_bits_tgtID(i_io_tasks_txreq_bits_tgtID),
    .io_tasks_txreq_bits_txnID(i_io_tasks_txreq_bits_txnID),
    .io_tasks_txreq_bits_opcode(i_io_tasks_txreq_bits_opcode),
    .io_tasks_txreq_bits_addr(i_io_tasks_txreq_bits_addr),
    .io_tasks_txreq_bits_likelyshared(i_io_tasks_txreq_bits_likelyshared),
    .io_tasks_txreq_bits_allowRetry(i_io_tasks_txreq_bits_allowRetry),
    .io_tasks_txreq_bits_pCrdType(i_io_tasks_txreq_bits_pCrdType),
    .io_tasks_txreq_bits_memAttr_allocate(i_io_tasks_txreq_bits_memAttr_allocate),
    .io_tasks_txreq_bits_memAttr_ewa(i_io_tasks_txreq_bits_memAttr_ewa),
    .io_tasks_txreq_bits_expCompAck(i_io_tasks_txreq_bits_expCompAck),
    .io_tasks_txrsp_ready(io_tasks_txrsp_ready),
    .io_tasks_txrsp_valid(i_io_tasks_txrsp_valid),
    .io_tasks_txrsp_bits_tgtID(i_io_tasks_txrsp_bits_tgtID),
    .io_tasks_txrsp_bits_txnID(i_io_tasks_txrsp_bits_txnID),
    .io_tasks_txrsp_bits_traceTag(i_io_tasks_txrsp_bits_traceTag),
    .io_tasks_source_b_ready(io_tasks_source_b_ready),
    .io_tasks_source_b_valid(i_io_tasks_source_b_valid),
    .io_tasks_source_b_bits_tag(i_io_tasks_source_b_bits_tag),
    .io_tasks_source_b_bits_set(i_io_tasks_source_b_bits_set),
    .io_tasks_source_b_bits_param(i_io_tasks_source_b_bits_param),
    .io_tasks_source_b_bits_alias(i_io_tasks_source_b_bits_alias),
    .io_tasks_mainpipe_ready(io_tasks_mainpipe_ready),
    .io_tasks_mainpipe_valid(i_io_tasks_mainpipe_valid),
    .io_tasks_mainpipe_bits_channel(i_io_tasks_mainpipe_bits_channel),
    .io_tasks_mainpipe_bits_txChannel(i_io_tasks_mainpipe_bits_txChannel),
    .io_tasks_mainpipe_bits_set(i_io_tasks_mainpipe_bits_set),
    .io_tasks_mainpipe_bits_tag(i_io_tasks_mainpipe_bits_tag),
    .io_tasks_mainpipe_bits_off(i_io_tasks_mainpipe_bits_off),
    .io_tasks_mainpipe_bits_alias(i_io_tasks_mainpipe_bits_alias),
    .io_tasks_mainpipe_bits_isKeyword(i_io_tasks_mainpipe_bits_isKeyword),
    .io_tasks_mainpipe_bits_opcode(i_io_tasks_mainpipe_bits_opcode),
    .io_tasks_mainpipe_bits_param(i_io_tasks_mainpipe_bits_param),
    .io_tasks_mainpipe_bits_size(i_io_tasks_mainpipe_bits_size),
    .io_tasks_mainpipe_bits_sourceId(i_io_tasks_mainpipe_bits_sourceId),
    .io_tasks_mainpipe_bits_denied(i_io_tasks_mainpipe_bits_denied),
    .io_tasks_mainpipe_bits_corrupt(i_io_tasks_mainpipe_bits_corrupt),
    .io_tasks_mainpipe_bits_mshrId(i_io_tasks_mainpipe_bits_mshrId),
    .io_tasks_mainpipe_bits_aliasTask(i_io_tasks_mainpipe_bits_aliasTask),
    .io_tasks_mainpipe_bits_useProbeData(i_io_tasks_mainpipe_bits_useProbeData),
    .io_tasks_mainpipe_bits_mshrRetry(i_io_tasks_mainpipe_bits_mshrRetry),
    .io_tasks_mainpipe_bits_readProbeDataDown(i_io_tasks_mainpipe_bits_readProbeDataDown),
    .io_tasks_mainpipe_bits_fromL2pft(i_io_tasks_mainpipe_bits_fromL2pft),
    .io_tasks_mainpipe_bits_dirty(i_io_tasks_mainpipe_bits_dirty),
    .io_tasks_mainpipe_bits_way(i_io_tasks_mainpipe_bits_way),
    .io_tasks_mainpipe_bits_meta_dirty(i_io_tasks_mainpipe_bits_meta_dirty),
    .io_tasks_mainpipe_bits_meta_state(i_io_tasks_mainpipe_bits_meta_state),
    .io_tasks_mainpipe_bits_meta_clients(i_io_tasks_mainpipe_bits_meta_clients),
    .io_tasks_mainpipe_bits_meta_alias(i_io_tasks_mainpipe_bits_meta_alias),
    .io_tasks_mainpipe_bits_meta_prefetch(i_io_tasks_mainpipe_bits_meta_prefetch),
    .io_tasks_mainpipe_bits_meta_prefetchSrc(i_io_tasks_mainpipe_bits_meta_prefetchSrc),
    .io_tasks_mainpipe_bits_meta_accessed(i_io_tasks_mainpipe_bits_meta_accessed),
    .io_tasks_mainpipe_bits_meta_tagErr(i_io_tasks_mainpipe_bits_meta_tagErr),
    .io_tasks_mainpipe_bits_meta_dataErr(i_io_tasks_mainpipe_bits_meta_dataErr),
    .io_tasks_mainpipe_bits_metaWen(i_io_tasks_mainpipe_bits_metaWen),
    .io_tasks_mainpipe_bits_tagWen(i_io_tasks_mainpipe_bits_tagWen),
    .io_tasks_mainpipe_bits_dsWen(i_io_tasks_mainpipe_bits_dsWen),
    .io_tasks_mainpipe_bits_replTask(i_io_tasks_mainpipe_bits_replTask),
    .io_tasks_mainpipe_bits_cmoTask(i_io_tasks_mainpipe_bits_cmoTask),
    .io_tasks_mainpipe_bits_reqSource(i_io_tasks_mainpipe_bits_reqSource),
    .io_tasks_mainpipe_bits_mergeA(i_io_tasks_mainpipe_bits_mergeA),
    .io_tasks_mainpipe_bits_aMergeTask_off(i_io_tasks_mainpipe_bits_aMergeTask_off),
    .io_tasks_mainpipe_bits_aMergeTask_alias(i_io_tasks_mainpipe_bits_aMergeTask_alias),
    .io_tasks_mainpipe_bits_aMergeTask_vaddr(i_io_tasks_mainpipe_bits_aMergeTask_vaddr),
    .io_tasks_mainpipe_bits_aMergeTask_isKeyword(i_io_tasks_mainpipe_bits_aMergeTask_isKeyword),
    .io_tasks_mainpipe_bits_aMergeTask_opcode(i_io_tasks_mainpipe_bits_aMergeTask_opcode),
    .io_tasks_mainpipe_bits_aMergeTask_param(i_io_tasks_mainpipe_bits_aMergeTask_param),
    .io_tasks_mainpipe_bits_aMergeTask_sourceId(i_io_tasks_mainpipe_bits_aMergeTask_sourceId),
    .io_tasks_mainpipe_bits_aMergeTask_meta_dirty(i_io_tasks_mainpipe_bits_aMergeTask_meta_dirty),
    .io_tasks_mainpipe_bits_aMergeTask_meta_state(i_io_tasks_mainpipe_bits_aMergeTask_meta_state),
    .io_tasks_mainpipe_bits_aMergeTask_meta_clients(i_io_tasks_mainpipe_bits_aMergeTask_meta_clients),
    .io_tasks_mainpipe_bits_aMergeTask_meta_alias(i_io_tasks_mainpipe_bits_aMergeTask_meta_alias),
    .io_tasks_mainpipe_bits_aMergeTask_meta_accessed(i_io_tasks_mainpipe_bits_aMergeTask_meta_accessed),
    .io_tasks_mainpipe_bits_snpHitRelease(i_io_tasks_mainpipe_bits_snpHitRelease),
    .io_tasks_mainpipe_bits_snpHitReleaseToInval(i_io_tasks_mainpipe_bits_snpHitReleaseToInval),
    .io_tasks_mainpipe_bits_snpHitReleaseToClean(i_io_tasks_mainpipe_bits_snpHitReleaseToClean),
    .io_tasks_mainpipe_bits_snpHitReleaseWithData(i_io_tasks_mainpipe_bits_snpHitReleaseWithData),
    .io_tasks_mainpipe_bits_snpHitReleaseIdx(i_io_tasks_mainpipe_bits_snpHitReleaseIdx),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_state(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_state),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_clients(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_alias(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr(i_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr),
    .io_tasks_mainpipe_bits_tgtID(i_io_tasks_mainpipe_bits_tgtID),
    .io_tasks_mainpipe_bits_txnID(i_io_tasks_mainpipe_bits_txnID),
    .io_tasks_mainpipe_bits_homeNID(i_io_tasks_mainpipe_bits_homeNID),
    .io_tasks_mainpipe_bits_dbID(i_io_tasks_mainpipe_bits_dbID),
    .io_tasks_mainpipe_bits_chiOpcode(i_io_tasks_mainpipe_bits_chiOpcode),
    .io_tasks_mainpipe_bits_resp(i_io_tasks_mainpipe_bits_resp),
    .io_tasks_mainpipe_bits_fwdState(i_io_tasks_mainpipe_bits_fwdState),
    .io_tasks_mainpipe_bits_retToSrc(i_io_tasks_mainpipe_bits_retToSrc),
    .io_tasks_mainpipe_bits_likelyshared(i_io_tasks_mainpipe_bits_likelyshared),
    .io_tasks_mainpipe_bits_expCompAck(i_io_tasks_mainpipe_bits_expCompAck),
    .io_tasks_mainpipe_bits_allowRetry(i_io_tasks_mainpipe_bits_allowRetry),
    .io_tasks_mainpipe_bits_memAttr_allocate(i_io_tasks_mainpipe_bits_memAttr_allocate),
    .io_tasks_mainpipe_bits_memAttr_cacheable(i_io_tasks_mainpipe_bits_memAttr_cacheable),
    .io_tasks_mainpipe_bits_memAttr_ewa(i_io_tasks_mainpipe_bits_memAttr_ewa),
    .io_tasks_mainpipe_bits_traceTag(i_io_tasks_mainpipe_bits_traceTag),
    .io_tasks_mainpipe_bits_dataCheckErr(i_io_tasks_mainpipe_bits_dataCheckErr),
    .io_resps_sinkC_valid(io_resps_sinkC_valid),
    .io_resps_sinkC_bits_opcode(io_resps_sinkC_bits_opcode),
    .io_resps_sinkC_bits_param(io_resps_sinkC_bits_param),
    .io_resps_sinkC_bits_last(io_resps_sinkC_bits_last),
    .io_resps_sinkC_bits_denied(io_resps_sinkC_bits_denied),
    .io_resps_sinkC_bits_corrupt(io_resps_sinkC_bits_corrupt),
    .io_resps_rxrsp_valid(io_resps_rxrsp_valid),
    .io_resps_rxrsp_bits_chiOpcode(io_resps_rxrsp_bits_chiOpcode),
    .io_resps_rxrsp_bits_srcID(io_resps_rxrsp_bits_srcID),
    .io_resps_rxrsp_bits_dbID(io_resps_rxrsp_bits_dbID),
    .io_resps_rxrsp_bits_resp(io_resps_rxrsp_bits_resp),
    .io_resps_rxrsp_bits_pCrdType(io_resps_rxrsp_bits_pCrdType),
    .io_resps_rxrsp_bits_respErr(io_resps_rxrsp_bits_respErr),
    .io_resps_rxrsp_bits_traceTag(io_resps_rxrsp_bits_traceTag),
    .io_resps_rxdat_valid(io_resps_rxdat_valid),
    .io_resps_rxdat_bits_corrupt(io_resps_rxdat_bits_corrupt),
    .io_resps_rxdat_bits_chiOpcode(io_resps_rxdat_bits_chiOpcode),
    .io_resps_rxdat_bits_homeNID(io_resps_rxdat_bits_homeNID),
    .io_resps_rxdat_bits_dbID(io_resps_rxdat_bits_dbID),
    .io_resps_rxdat_bits_resp(io_resps_rxdat_bits_resp),
    .io_resps_rxdat_bits_respErr(io_resps_rxdat_bits_respErr),
    .io_resps_rxdat_bits_traceTag(io_resps_rxdat_bits_traceTag),
    .io_resps_rxdat_bits_dataCheckErr(io_resps_rxdat_bits_dataCheckErr),
    .io_nestedwb_set(io_nestedwb_set),
    .io_nestedwb_tag(io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(io_nestedwb_b_toB),
    .io_nestedwb_b_toN(io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
    .io_nestedwbData(i_io_nestedwbData),
    .io_aMergeTask_valid(io_aMergeTask_valid),
    .io_aMergeTask_bits_off(io_aMergeTask_bits_off),
    .io_aMergeTask_bits_alias(io_aMergeTask_bits_alias),
    .io_aMergeTask_bits_vaddr(io_aMergeTask_bits_vaddr),
    .io_aMergeTask_bits_isKeyword(io_aMergeTask_bits_isKeyword),
    .io_aMergeTask_bits_opcode(io_aMergeTask_bits_opcode),
    .io_aMergeTask_bits_param(io_aMergeTask_bits_param),
    .io_aMergeTask_bits_sourceId(io_aMergeTask_bits_sourceId),
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
    .io_replResp_bits_retry(io_replResp_bits_retry),
    .io_pCrd_query_valid(i_io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType(i_io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID(i_io_pCrd_query_bits_srcID),
    .io_pCrd_grant(io_pCrd_grant),
    .acquire_period_valid(i_acquire_period_valid),
    .acquire_period_bits(i_acquire_period_bits),
    .release_period_valid(i_release_period_valid),
    .release_period_bits(i_release_period_bits)
  );

  task automatic drive_random();
    io_alloc_valid = ($urandom_range(0,7) == 0);
    io_alloc_bits_dirResult_hit = $urandom;
    io_alloc_bits_dirResult_tag = $urandom;
    io_alloc_bits_dirResult_set = $urandom;
    io_alloc_bits_dirResult_way = $urandom;
    io_alloc_bits_dirResult_meta_dirty = $urandom;
    io_alloc_bits_dirResult_meta_state = $urandom;
    io_alloc_bits_dirResult_meta_clients = $urandom;
    io_alloc_bits_dirResult_meta_alias = $urandom;
    io_alloc_bits_dirResult_meta_prefetch = $urandom;
    io_alloc_bits_dirResult_meta_prefetchSrc = $urandom;
    io_alloc_bits_dirResult_meta_accessed = $urandom;
    io_alloc_bits_dirResult_meta_tagErr = $urandom;
    io_alloc_bits_dirResult_meta_dataErr = $urandom;
    io_alloc_bits_dirResult_error = $urandom;
    io_alloc_bits_state_s_acquire = $urandom;
    io_alloc_bits_state_s_rprobe = $urandom;
    io_alloc_bits_state_s_pprobe = $urandom;
    io_alloc_bits_state_s_release = $urandom;
    io_alloc_bits_state_s_probeack = $urandom;
    io_alloc_bits_state_s_refill = $urandom;
    io_alloc_bits_state_s_cmoresp = $urandom;
    io_alloc_bits_state_w_rprobeackfirst = $urandom;
    io_alloc_bits_state_w_rprobeacklast = $urandom;
    io_alloc_bits_state_w_pprobeackfirst = $urandom;
    io_alloc_bits_state_w_pprobeacklast = $urandom;
    io_alloc_bits_state_w_grantfirst = $urandom;
    io_alloc_bits_state_w_grantlast = $urandom;
    io_alloc_bits_state_w_grant = $urandom;
    io_alloc_bits_state_w_releaseack = $urandom;
    io_alloc_bits_state_w_replResp = $urandom;
    io_alloc_bits_state_s_rcompack = $urandom;
    io_alloc_bits_state_s_dct = $urandom;
    io_alloc_bits_task_channel = $urandom;
    io_alloc_bits_task_set = $urandom;
    io_alloc_bits_task_tag = $urandom;
    io_alloc_bits_task_off = $urandom;
    io_alloc_bits_task_alias = $urandom;
    io_alloc_bits_task_isKeyword = $urandom;
    io_alloc_bits_task_opcode = $urandom;
    io_alloc_bits_task_param = $urandom;
    io_alloc_bits_task_sourceId = $urandom;
    io_alloc_bits_task_aliasTask = $urandom;
    io_alloc_bits_task_fromL2pft = $urandom;
    io_alloc_bits_task_reqSource = $urandom;
    io_alloc_bits_task_snpHitRelease = $urandom;
    io_alloc_bits_task_snpHitReleaseToInval = $urandom;
    io_alloc_bits_task_snpHitReleaseToClean = $urandom;
    io_alloc_bits_task_snpHitReleaseWithData = $urandom;
    io_alloc_bits_task_snpHitReleaseIdx = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_dirty = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_state = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_clients = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_alias = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_prefetch = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_accessed = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_tagErr = $urandom;
    io_alloc_bits_task_snpHitReleaseMeta_dataErr = $urandom;
    io_alloc_bits_task_srcID = $urandom;
    io_alloc_bits_task_txnID = $urandom;
    io_alloc_bits_task_fwdNID = $urandom;
    io_alloc_bits_task_fwdTxnID = $urandom;
    io_alloc_bits_task_chiOpcode = $urandom;
    io_alloc_bits_task_retToSrc = $urandom;
    io_alloc_bits_task_traceTag = $urandom;
    io_tasks_txreq_ready = ($urandom_range(0,3) != 0);
    io_tasks_txrsp_ready = ($urandom_range(0,3) != 0);
    io_tasks_source_b_ready = ($urandom_range(0,3) != 0);
    io_tasks_mainpipe_ready = ($urandom_range(0,3) != 0);
    io_resps_sinkC_valid = ($urandom_range(0,3) == 0);
    io_resps_sinkC_bits_opcode = $urandom;
    io_resps_sinkC_bits_param = $urandom;
    io_resps_sinkC_bits_last = $urandom;
    io_resps_sinkC_bits_denied = $urandom;
    io_resps_sinkC_bits_corrupt = $urandom;
    io_resps_rxrsp_valid = ($urandom_range(0,3) == 0);
    io_resps_rxrsp_bits_chiOpcode = $urandom;
    io_resps_rxrsp_bits_srcID = $urandom;
    io_resps_rxrsp_bits_dbID = $urandom;
    io_resps_rxrsp_bits_resp = $urandom;
    io_resps_rxrsp_bits_pCrdType = $urandom;
    io_resps_rxrsp_bits_respErr = $urandom;
    io_resps_rxrsp_bits_traceTag = $urandom;
    io_resps_rxdat_valid = ($urandom_range(0,3) == 0);
    io_resps_rxdat_bits_corrupt = $urandom;
    io_resps_rxdat_bits_chiOpcode = $urandom;
    io_resps_rxdat_bits_homeNID = $urandom;
    io_resps_rxdat_bits_dbID = $urandom;
    io_resps_rxdat_bits_resp = $urandom;
    io_resps_rxdat_bits_respErr = $urandom;
    io_resps_rxdat_bits_traceTag = $urandom;
    io_resps_rxdat_bits_dataCheckErr = $urandom;
    io_nestedwb_set = $urandom;
    io_nestedwb_tag = $urandom;
    io_nestedwb_c_set_dirty = ($urandom_range(0,3) == 0);
    io_nestedwb_c_set_tip = ($urandom_range(0,3) == 0);
    io_nestedwb_b_inv_dirty = ($urandom_range(0,3) == 0);
    io_nestedwb_b_toB = ($urandom_range(0,3) == 0);
    io_nestedwb_b_toN = ($urandom_range(0,3) == 0);
    io_nestedwb_b_toClean = ($urandom_range(0,3) == 0);
    io_aMergeTask_valid = ($urandom_range(0,3) == 0);
    io_aMergeTask_bits_off = $urandom;
    io_aMergeTask_bits_alias = $urandom;
    io_aMergeTask_bits_vaddr = {$urandom, $urandom};
    io_aMergeTask_bits_isKeyword = $urandom;
    io_aMergeTask_bits_opcode = $urandom;
    io_aMergeTask_bits_param = $urandom;
    io_aMergeTask_bits_sourceId = $urandom;
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
    io_replResp_bits_retry = $urandom;
    io_pCrd_grant = ($urandom_range(0,3) == 0);
  endtask

  task automatic check_outputs();
    `CHK(io_status_valid)
    `CHK(io_status_bits_channel)
    `CHK(io_status_bits_set)
    `CHK(io_status_bits_reqTag)
    `CHK(io_status_bits_metaTag)
    `CHK(io_status_bits_needsRepl)
    `CHK(io_status_bits_w_c_resp)
    `CHK(io_status_bits_will_free)
    `CHK(io_status_bits_reqSource)
    `CHK(io_status_bits_is_miss)
    `CHK(io_status_bits_is_prefetch)
    `CHK(io_msInfo_valid)
    `CHK(io_msInfo_bits_channel)
    `CHK(io_msInfo_bits_set)
    `CHK(io_msInfo_bits_way)
    `CHK(io_msInfo_bits_reqTag)
    `CHK(io_msInfo_bits_willFree)
    `CHK(io_msInfo_bits_aliasTask)
    `CHK(io_msInfo_bits_needRelease)
    `CHK(io_msInfo_bits_blockRefill)
    `CHK(io_msInfo_bits_meta_dirty)
    `CHK(io_msInfo_bits_meta_state)
    `CHK(io_msInfo_bits_meta_clients)
    `CHK(io_msInfo_bits_meta_alias)
    `CHK(io_msInfo_bits_meta_prefetch)
    `CHK(io_msInfo_bits_meta_prefetchSrc)
    `CHK(io_msInfo_bits_meta_accessed)
    `CHK(io_msInfo_bits_meta_tagErr)
    `CHK(io_msInfo_bits_meta_dataErr)
    `CHK(io_msInfo_bits_metaTag)
    `CHK(io_msInfo_bits_dirHit)
    `CHK(io_msInfo_bits_isAcqOrPrefetch)
    `CHK(io_msInfo_bits_isPrefetch)
    `CHK(io_msInfo_bits_param)
    `CHK(io_msInfo_bits_mergeA)
    `CHK(io_msInfo_bits_w_grantfirst)
    `CHK(io_msInfo_bits_s_release)
    `CHK(io_msInfo_bits_s_refill)
    `CHK(io_msInfo_bits_s_cmoresp)
    `CHK(io_msInfo_bits_s_cmometaw)
    `CHK(io_msInfo_bits_w_releaseack)
    `CHK(io_msInfo_bits_w_replResp)
    `CHK(io_msInfo_bits_w_rprobeacklast)
    `CHK(io_msInfo_bits_replaceData)
    `CHK(io_msInfo_bits_releaseToClean)
    `CHK(io_tasks_txreq_valid)
    `CHK(io_tasks_txreq_bits_tgtID)
    `CHK(io_tasks_txreq_bits_txnID)
    `CHK(io_tasks_txreq_bits_opcode)
    `CHK(io_tasks_txreq_bits_addr)
    `CHK(io_tasks_txreq_bits_likelyshared)
    `CHK(io_tasks_txreq_bits_allowRetry)
    `CHK(io_tasks_txreq_bits_pCrdType)
    `CHK(io_tasks_txreq_bits_memAttr_allocate)
    `CHK(io_tasks_txreq_bits_memAttr_ewa)
    `CHK(io_tasks_txreq_bits_expCompAck)
    `CHK(io_tasks_txrsp_valid)
    `CHK(io_tasks_txrsp_bits_tgtID)
    `CHK(io_tasks_txrsp_bits_txnID)
    `CHK(io_tasks_txrsp_bits_traceTag)
    `CHK(io_tasks_source_b_valid)
    `CHK(io_tasks_source_b_bits_tag)
    `CHK(io_tasks_source_b_bits_set)
    `CHK(io_tasks_source_b_bits_param)
    `CHK(io_tasks_source_b_bits_alias)
    `CHK(io_tasks_mainpipe_valid)
    `CHK(io_tasks_mainpipe_bits_channel)
    `CHK(io_tasks_mainpipe_bits_txChannel)
    `CHK(io_tasks_mainpipe_bits_set)
    `CHK(io_tasks_mainpipe_bits_tag)
    `CHK(io_tasks_mainpipe_bits_off)
    `CHK(io_tasks_mainpipe_bits_alias)
    `CHK(io_tasks_mainpipe_bits_isKeyword)
    `CHK(io_tasks_mainpipe_bits_opcode)
    `CHK(io_tasks_mainpipe_bits_param)
    `CHK(io_tasks_mainpipe_bits_size)
    `CHK(io_tasks_mainpipe_bits_sourceId)
    `CHK(io_tasks_mainpipe_bits_denied)
    `CHK(io_tasks_mainpipe_bits_corrupt)
    `CHK(io_tasks_mainpipe_bits_mshrId)
    `CHK(io_tasks_mainpipe_bits_aliasTask)
    `CHK(io_tasks_mainpipe_bits_useProbeData)
    `CHK(io_tasks_mainpipe_bits_mshrRetry)
    `CHK(io_tasks_mainpipe_bits_readProbeDataDown)
    `CHK(io_tasks_mainpipe_bits_fromL2pft)
    `CHK(io_tasks_mainpipe_bits_dirty)
    `CHK(io_tasks_mainpipe_bits_way)
    `CHK(io_tasks_mainpipe_bits_meta_dirty)
    `CHK(io_tasks_mainpipe_bits_meta_state)
    `CHK(io_tasks_mainpipe_bits_meta_clients)
    `CHK(io_tasks_mainpipe_bits_meta_alias)
    `CHK(io_tasks_mainpipe_bits_meta_prefetch)
    `CHK(io_tasks_mainpipe_bits_meta_prefetchSrc)
    `CHK(io_tasks_mainpipe_bits_meta_accessed)
    `CHK(io_tasks_mainpipe_bits_meta_tagErr)
    `CHK(io_tasks_mainpipe_bits_meta_dataErr)
    `CHK(io_tasks_mainpipe_bits_metaWen)
    `CHK(io_tasks_mainpipe_bits_tagWen)
    `CHK(io_tasks_mainpipe_bits_dsWen)
    `CHK(io_tasks_mainpipe_bits_replTask)
    `CHK(io_tasks_mainpipe_bits_cmoTask)
    `CHK(io_tasks_mainpipe_bits_reqSource)
    `CHK(io_tasks_mainpipe_bits_mergeA)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_off)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_alias)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_vaddr)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_isKeyword)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_opcode)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_param)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_sourceId)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_meta_dirty)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_meta_state)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_meta_clients)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_meta_alias)
    `CHK(io_tasks_mainpipe_bits_aMergeTask_meta_accessed)
    `CHK(io_tasks_mainpipe_bits_snpHitRelease)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseToInval)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseToClean)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseWithData)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseIdx)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_state)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_clients)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_alias)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr)
    `CHK(io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr)
    `CHK(io_tasks_mainpipe_bits_tgtID)
    `CHK(io_tasks_mainpipe_bits_txnID)
    `CHK(io_tasks_mainpipe_bits_homeNID)
    `CHK(io_tasks_mainpipe_bits_dbID)
    `CHK(io_tasks_mainpipe_bits_chiOpcode)
    `CHK(io_tasks_mainpipe_bits_resp)
    `CHK(io_tasks_mainpipe_bits_fwdState)
    `CHK(io_tasks_mainpipe_bits_retToSrc)
    `CHK(io_tasks_mainpipe_bits_likelyshared)
    `CHK(io_tasks_mainpipe_bits_expCompAck)
    `CHK(io_tasks_mainpipe_bits_allowRetry)
    `CHK(io_tasks_mainpipe_bits_memAttr_allocate)
    `CHK(io_tasks_mainpipe_bits_memAttr_cacheable)
    `CHK(io_tasks_mainpipe_bits_memAttr_ewa)
    `CHK(io_tasks_mainpipe_bits_traceTag)
    `CHK(io_tasks_mainpipe_bits_dataCheckErr)
    `CHK(io_nestedwbData)
    `CHK(io_pCrd_query_valid)
    `CHK(io_pCrd_query_bits_pCrdType)
    `CHK(io_pCrd_query_bits_srcID)
    `CHK(acquire_period_valid)
    `CHK(acquire_period_bits)
    `CHK(release_period_valid)
    `CHK(release_period_bits)
  endtask

  // 内部状态层次探针: 逐拍比 golden(u_g) vs 可读核(u_i.u_core) 的 FSM 寄存器,
  // 防止仅比端口漏掉内部状态分叉(s_*/w_* 标志、dirResult.meta、错误标志等)。
  int ierr = 0;
  `define IPROBE(PATH) begin \
    if (!$isunknown(u_g.``PATH)) begin \
      if (u_g.``PATH !== u_i.u_core.``PATH) begin \
        ierr++; \
        if (ierr <= 30) $display("[%0t] IPROBE-DIFF %s g=%0h i=%0h", $time, `"PATH`", u_g.``PATH, u_i.u_core.``PATH); \
      end \
    end \
  end
  task automatic check_internal();
    `IPROBE(state_s_acquire)
    `IPROBE(state_s_rprobe)
    `IPROBE(state_s_pprobe)
    `IPROBE(state_s_release)
    `IPROBE(state_s_probeack)
    `IPROBE(state_s_refill)
    `IPROBE(state_s_retry)
    `IPROBE(state_s_cmoresp)
    `IPROBE(state_s_cmometaw)
    `IPROBE(state_w_rprobeackfirst)
    `IPROBE(state_w_rprobeacklast)
    `IPROBE(state_w_pprobeackfirst)
    `IPROBE(state_w_pprobeacklast)
    `IPROBE(state_w_grantfirst)
    `IPROBE(state_w_grantlast)
    `IPROBE(state_w_grant)
    `IPROBE(state_w_releaseack)
    `IPROBE(state_w_replResp)
    `IPROBE(state_s_rcompack)
    `IPROBE(state_s_wcompack)
    `IPROBE(state_s_cbwrdata)
    `IPROBE(state_s_reissue)
    `IPROBE(state_s_dct)
    `IPROBE(req_valid)
    `IPROBE(dirResult_hit)
    `IPROBE(dirResult_tag)
    `IPROBE(dirResult_way)
    `IPROBE(dirResult_meta_dirty)
    `IPROBE(dirResult_meta_state)
    `IPROBE(dirResult_meta_clients)
    `IPROBE(gotT)
    `IPROBE(gotDirty)
    `IPROBE(gotGrantData)
    `IPROBE(probeDirty)
    `IPROBE(releaseDirty)
    `IPROBE(tagErr)
    `IPROBE(denied)
    `IPROBE(corrupt)
    `IPROBE(dataCheckErr)
    `IPROBE(gotRetryAck)
    `IPROBE(gotPCrdGrant)
    `IPROBE(pcrdtype)
    `IPROBE(retryTimes)
    `IPROBE(backoffTimer)
    `IPROBE(req_released_chiOpcode)
    `IPROBE(tgtid_rcompack)
    `IPROBE(txnid_rcompack)
    `IPROBE(tgtid_wcompack)
    `IPROBE(txnid_wcompack)
    `IPROBE(srcid_retryack)
    `IPROBE(mergeA)
    `IPROBE(req_traceTag)
    `IPROBE(req_aliasTask)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_id = '0;
    io_alloc_valid = '0;
    io_alloc_bits_dirResult_hit = '0;
    io_alloc_bits_dirResult_tag = '0;
    io_alloc_bits_dirResult_set = '0;
    io_alloc_bits_dirResult_way = '0;
    io_alloc_bits_dirResult_meta_dirty = '0;
    io_alloc_bits_dirResult_meta_state = '0;
    io_alloc_bits_dirResult_meta_clients = '0;
    io_alloc_bits_dirResult_meta_alias = '0;
    io_alloc_bits_dirResult_meta_prefetch = '0;
    io_alloc_bits_dirResult_meta_prefetchSrc = '0;
    io_alloc_bits_dirResult_meta_accessed = '0;
    io_alloc_bits_dirResult_meta_tagErr = '0;
    io_alloc_bits_dirResult_meta_dataErr = '0;
    io_alloc_bits_dirResult_error = '0;
    io_alloc_bits_state_s_acquire = '0;
    io_alloc_bits_state_s_rprobe = '0;
    io_alloc_bits_state_s_pprobe = '0;
    io_alloc_bits_state_s_release = '0;
    io_alloc_bits_state_s_probeack = '0;
    io_alloc_bits_state_s_refill = '0;
    io_alloc_bits_state_s_cmoresp = '0;
    io_alloc_bits_state_w_rprobeackfirst = '0;
    io_alloc_bits_state_w_rprobeacklast = '0;
    io_alloc_bits_state_w_pprobeackfirst = '0;
    io_alloc_bits_state_w_pprobeacklast = '0;
    io_alloc_bits_state_w_grantfirst = '0;
    io_alloc_bits_state_w_grantlast = '0;
    io_alloc_bits_state_w_grant = '0;
    io_alloc_bits_state_w_releaseack = '0;
    io_alloc_bits_state_w_replResp = '0;
    io_alloc_bits_state_s_rcompack = '0;
    io_alloc_bits_state_s_dct = '0;
    io_alloc_bits_task_channel = '0;
    io_alloc_bits_task_set = '0;
    io_alloc_bits_task_tag = '0;
    io_alloc_bits_task_off = '0;
    io_alloc_bits_task_alias = '0;
    io_alloc_bits_task_isKeyword = '0;
    io_alloc_bits_task_opcode = '0;
    io_alloc_bits_task_param = '0;
    io_alloc_bits_task_sourceId = '0;
    io_alloc_bits_task_aliasTask = '0;
    io_alloc_bits_task_fromL2pft = '0;
    io_alloc_bits_task_reqSource = '0;
    io_alloc_bits_task_snpHitRelease = '0;
    io_alloc_bits_task_snpHitReleaseToInval = '0;
    io_alloc_bits_task_snpHitReleaseToClean = '0;
    io_alloc_bits_task_snpHitReleaseWithData = '0;
    io_alloc_bits_task_snpHitReleaseIdx = '0;
    io_alloc_bits_task_snpHitReleaseMeta_dirty = '0;
    io_alloc_bits_task_snpHitReleaseMeta_state = '0;
    io_alloc_bits_task_snpHitReleaseMeta_clients = '0;
    io_alloc_bits_task_snpHitReleaseMeta_alias = '0;
    io_alloc_bits_task_snpHitReleaseMeta_prefetch = '0;
    io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
    io_alloc_bits_task_snpHitReleaseMeta_accessed = '0;
    io_alloc_bits_task_snpHitReleaseMeta_tagErr = '0;
    io_alloc_bits_task_snpHitReleaseMeta_dataErr = '0;
    io_alloc_bits_task_srcID = '0;
    io_alloc_bits_task_txnID = '0;
    io_alloc_bits_task_fwdNID = '0;
    io_alloc_bits_task_fwdTxnID = '0;
    io_alloc_bits_task_chiOpcode = '0;
    io_alloc_bits_task_retToSrc = '0;
    io_alloc_bits_task_traceTag = '0;
    io_tasks_txreq_ready = '0;
    io_tasks_txrsp_ready = '0;
    io_tasks_source_b_ready = '0;
    io_tasks_mainpipe_ready = '0;
    io_resps_sinkC_valid = '0;
    io_resps_sinkC_bits_opcode = '0;
    io_resps_sinkC_bits_param = '0;
    io_resps_sinkC_bits_last = '0;
    io_resps_sinkC_bits_denied = '0;
    io_resps_sinkC_bits_corrupt = '0;
    io_resps_rxrsp_valid = '0;
    io_resps_rxrsp_bits_chiOpcode = '0;
    io_resps_rxrsp_bits_srcID = '0;
    io_resps_rxrsp_bits_dbID = '0;
    io_resps_rxrsp_bits_resp = '0;
    io_resps_rxrsp_bits_pCrdType = '0;
    io_resps_rxrsp_bits_respErr = '0;
    io_resps_rxrsp_bits_traceTag = '0;
    io_resps_rxdat_valid = '0;
    io_resps_rxdat_bits_corrupt = '0;
    io_resps_rxdat_bits_chiOpcode = '0;
    io_resps_rxdat_bits_homeNID = '0;
    io_resps_rxdat_bits_dbID = '0;
    io_resps_rxdat_bits_resp = '0;
    io_resps_rxdat_bits_respErr = '0;
    io_resps_rxdat_bits_traceTag = '0;
    io_resps_rxdat_bits_dataCheckErr = '0;
    io_nestedwb_set = '0;
    io_nestedwb_tag = '0;
    io_nestedwb_c_set_dirty = '0;
    io_nestedwb_c_set_tip = '0;
    io_nestedwb_b_inv_dirty = '0;
    io_nestedwb_b_toB = '0;
    io_nestedwb_b_toN = '0;
    io_nestedwb_b_toClean = '0;
    io_aMergeTask_valid = '0;
    io_aMergeTask_bits_off = '0;
    io_aMergeTask_bits_alias = '0;
    io_aMergeTask_bits_vaddr = '0;
    io_aMergeTask_bits_isKeyword = '0;
    io_aMergeTask_bits_opcode = '0;
    io_aMergeTask_bits_param = '0;
    io_aMergeTask_bits_sourceId = '0;
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
    io_replResp_bits_retry = '0;
    io_pCrd_grant = '0;
    io_id = $urandom;  // io_id 固定: 当作常量 MSHR id
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("MSHR checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
