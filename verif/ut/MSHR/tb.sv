// =============================================================================
// tb —— MSHR UT：golden MSHR 与重写 MSHR_xs 双例化，同激励逐拍比对全部 155 个输出。
//
// 激励（每拍全部输入重摇，偏置见 gen_tb.py 的 drive_expr）：
//   · 空闲时 1/4 概率分配、占用时 1/300 概率重分配；分配的 state 标志 2/3 为 1；
//   · TL opcode 偏向 Get/Hint/Acquire*/CBO*，snoop opcode 覆盖 0..23 全部；
//   · set/tag 取值域压到 0..3，nestedwb 的 set/tag 一半直接取 golden 当前 dirResult，
//     让嵌套写回匹配真正发生；RXDAT/RXRSP/SinkC 的 opcode 偏向本模块识别的那几个；
//   · 约 1/5000 拍一次单拍异步复位。
// 未复位寄存器：+vcs+initreg+random 下两侧初值不同，tb 在首个时钟沿前把 golden 侧
//   初值 force 到重写侧（见 NORESET_REGS），两侧同初态；有复位的寄存器不做任何同步。
// 覆盖：一组 golden 内部判断（release/grant/probeack/dct/cbwrdata/CompAck/嵌套写回/
//   事务结束 …）各自为真的拍数，任何一项为 0 即判 TEST FAILED。
//
// 本文件由 verif/ut/MSHR/gen_tb.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; always #5 clock = ~clock;
  logic reset;
  longint errors = 0, checks = 0;

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
  logic io_alloc_bits_task_denied;
  logic io_alloc_bits_task_corrupt;
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
  logic [8:0] io_nestedwb_set;
  logic [30:0] io_nestedwb_tag;
  logic io_nestedwb_c_set_dirty;
  logic io_nestedwb_c_set_tip;
  logic io_nestedwb_b_inv_dirty;
  logic io_nestedwb_b_toB;
  logic io_nestedwb_b_toN;
  logic io_nestedwb_b_toClean;
  logic io_nestedwb_denied;
  logic io_nestedwb_corrupt;
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
  logic io_replResp_bits_error;
  logic io_pCrd_grant;
  logic io_dsResp_valid;
  logic io_dsResp_bits_dataError;
  logic g_io_status_valid, i_io_status_valid;
  logic [2:0] g_io_status_bits_channel, i_io_status_bits_channel;
  logic [8:0] g_io_status_bits_set, i_io_status_bits_set;
  logic [30:0] g_io_status_bits_reqTag, i_io_status_bits_reqTag;
  logic [30:0] g_io_status_bits_metaTag, i_io_status_bits_metaTag;
  logic g_io_status_bits_needsRepl, i_io_status_bits_needsRepl;
  logic g_io_status_bits_w_c_resp, i_io_status_bits_w_c_resp;
  logic g_io_status_bits_will_free, i_io_status_bits_will_free;
  logic [4:0] g_io_status_bits_reqSource, i_io_status_bits_reqSource;
  logic g_io_status_bits_is_miss, i_io_status_bits_is_miss;
  logic g_io_status_bits_is_prefetch, i_io_status_bits_is_prefetch;
  logic g_io_statAlloc_valid, i_io_statAlloc_valid;
  logic [2:0] g_io_statAlloc_bits_channel, i_io_statAlloc_bits_channel;
  logic g_io_statAlloc_bits_is_miss, i_io_statAlloc_bits_is_miss;
  logic g_io_statAlloc_bits_is_prefetch, i_io_statAlloc_bits_is_prefetch;
  logic g_io_msInfo_valid, i_io_msInfo_valid;
  logic [2:0] g_io_msInfo_bits_channel, i_io_msInfo_bits_channel;
  logic [8:0] g_io_msInfo_bits_set, i_io_msInfo_bits_set;
  logic [2:0] g_io_msInfo_bits_way, i_io_msInfo_bits_way;
  logic [30:0] g_io_msInfo_bits_reqTag, i_io_msInfo_bits_reqTag;
  logic g_io_msInfo_bits_willFree, i_io_msInfo_bits_willFree;
  logic g_io_msInfo_bits_aliasTask, i_io_msInfo_bits_aliasTask;
  logic g_io_msInfo_bits_needRelease, i_io_msInfo_bits_needRelease;
  logic g_io_msInfo_bits_blockRefill, i_io_msInfo_bits_blockRefill;
  logic g_io_msInfo_bits_meta_dirty, i_io_msInfo_bits_meta_dirty;
  logic [1:0] g_io_msInfo_bits_meta_state, i_io_msInfo_bits_meta_state;
  logic g_io_msInfo_bits_meta_clients, i_io_msInfo_bits_meta_clients;
  logic [1:0] g_io_msInfo_bits_meta_alias, i_io_msInfo_bits_meta_alias;
  logic g_io_msInfo_bits_meta_prefetch, i_io_msInfo_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_bits_meta_prefetchSrc, i_io_msInfo_bits_meta_prefetchSrc;
  logic g_io_msInfo_bits_meta_accessed, i_io_msInfo_bits_meta_accessed;
  logic g_io_msInfo_bits_meta_tagErr, i_io_msInfo_bits_meta_tagErr;
  logic g_io_msInfo_bits_meta_dataErr, i_io_msInfo_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_bits_metaTag, i_io_msInfo_bits_metaTag;
  logic g_io_msInfo_bits_dirHit, i_io_msInfo_bits_dirHit;
  logic g_io_msInfo_bits_isAcqOrPrefetch, i_io_msInfo_bits_isAcqOrPrefetch;
  logic g_io_msInfo_bits_isPrefetch, i_io_msInfo_bits_isPrefetch;
  logic [2:0] g_io_msInfo_bits_param, i_io_msInfo_bits_param;
  logic g_io_msInfo_bits_mergeA, i_io_msInfo_bits_mergeA;
  logic g_io_msInfo_bits_w_grantfirst, i_io_msInfo_bits_w_grantfirst;
  logic g_io_msInfo_bits_s_release, i_io_msInfo_bits_s_release;
  logic g_io_msInfo_bits_s_refill, i_io_msInfo_bits_s_refill;
  logic g_io_msInfo_bits_s_cmoresp, i_io_msInfo_bits_s_cmoresp;
  logic g_io_msInfo_bits_s_cmometaw, i_io_msInfo_bits_s_cmometaw;
  logic g_io_msInfo_bits_w_releaseack, i_io_msInfo_bits_w_releaseack;
  logic g_io_msInfo_bits_w_replResp, i_io_msInfo_bits_w_replResp;
  logic g_io_msInfo_bits_w_rprobeacklast, i_io_msInfo_bits_w_rprobeacklast;
  logic g_io_msInfo_bits_replaceData, i_io_msInfo_bits_replaceData;
  logic g_io_msInfo_bits_releaseToClean, i_io_msInfo_bits_releaseToClean;
  logic g_io_tasks_txreq_valid, i_io_tasks_txreq_valid;
  logic [10:0] g_io_tasks_txreq_bits_tgtID, i_io_tasks_txreq_bits_tgtID;
  logic [11:0] g_io_tasks_txreq_bits_txnID, i_io_tasks_txreq_bits_txnID;
  logic [6:0] g_io_tasks_txreq_bits_opcode, i_io_tasks_txreq_bits_opcode;
  logic [47:0] g_io_tasks_txreq_bits_addr, i_io_tasks_txreq_bits_addr;
  logic g_io_tasks_txreq_bits_likelyshared, i_io_tasks_txreq_bits_likelyshared;
  logic g_io_tasks_txreq_bits_allowRetry, i_io_tasks_txreq_bits_allowRetry;
  logic [3:0] g_io_tasks_txreq_bits_pCrdType, i_io_tasks_txreq_bits_pCrdType;
  logic g_io_tasks_txreq_bits_memAttr_allocate, i_io_tasks_txreq_bits_memAttr_allocate;
  logic g_io_tasks_txreq_bits_expCompAck, i_io_tasks_txreq_bits_expCompAck;
  logic g_io_tasks_txrsp_valid, i_io_tasks_txrsp_valid;
  logic [10:0] g_io_tasks_txrsp_bits_tgtID, i_io_tasks_txrsp_bits_tgtID;
  logic [11:0] g_io_tasks_txrsp_bits_txnID, i_io_tasks_txrsp_bits_txnID;
  logic g_io_tasks_txrsp_bits_traceTag, i_io_tasks_txrsp_bits_traceTag;
  logic g_io_tasks_source_b_valid, i_io_tasks_source_b_valid;
  logic [30:0] g_io_tasks_source_b_bits_tag, i_io_tasks_source_b_bits_tag;
  logic [8:0] g_io_tasks_source_b_bits_set, i_io_tasks_source_b_bits_set;
  logic [1:0] g_io_tasks_source_b_bits_param, i_io_tasks_source_b_bits_param;
  logic [1:0] g_io_tasks_source_b_bits_alias, i_io_tasks_source_b_bits_alias;
  logic g_io_tasks_mainpipe_valid, i_io_tasks_mainpipe_valid;
  logic [2:0] g_io_tasks_mainpipe_bits_channel, i_io_tasks_mainpipe_bits_channel;
  logic [2:0] g_io_tasks_mainpipe_bits_txChannel, i_io_tasks_mainpipe_bits_txChannel;
  logic [8:0] g_io_tasks_mainpipe_bits_set, i_io_tasks_mainpipe_bits_set;
  logic [30:0] g_io_tasks_mainpipe_bits_tag, i_io_tasks_mainpipe_bits_tag;
  logic [5:0] g_io_tasks_mainpipe_bits_off, i_io_tasks_mainpipe_bits_off;
  logic [1:0] g_io_tasks_mainpipe_bits_alias, i_io_tasks_mainpipe_bits_alias;
  logic g_io_tasks_mainpipe_bits_isKeyword, i_io_tasks_mainpipe_bits_isKeyword;
  logic [3:0] g_io_tasks_mainpipe_bits_opcode, i_io_tasks_mainpipe_bits_opcode;
  logic [2:0] g_io_tasks_mainpipe_bits_param, i_io_tasks_mainpipe_bits_param;
  logic [2:0] g_io_tasks_mainpipe_bits_size, i_io_tasks_mainpipe_bits_size;
  logic [6:0] g_io_tasks_mainpipe_bits_sourceId, i_io_tasks_mainpipe_bits_sourceId;
  logic g_io_tasks_mainpipe_bits_denied, i_io_tasks_mainpipe_bits_denied;
  logic g_io_tasks_mainpipe_bits_corrupt, i_io_tasks_mainpipe_bits_corrupt;
  logic [7:0] g_io_tasks_mainpipe_bits_mshrId, i_io_tasks_mainpipe_bits_mshrId;
  logic g_io_tasks_mainpipe_bits_aliasTask, i_io_tasks_mainpipe_bits_aliasTask;
  logic g_io_tasks_mainpipe_bits_useProbeData, i_io_tasks_mainpipe_bits_useProbeData;
  logic g_io_tasks_mainpipe_bits_mshrRetry, i_io_tasks_mainpipe_bits_mshrRetry;
  logic g_io_tasks_mainpipe_bits_readProbeDataDown, i_io_tasks_mainpipe_bits_readProbeDataDown;
  logic g_io_tasks_mainpipe_bits_fromL2pft, i_io_tasks_mainpipe_bits_fromL2pft;
  logic g_io_tasks_mainpipe_bits_dirty, i_io_tasks_mainpipe_bits_dirty;
  logic [2:0] g_io_tasks_mainpipe_bits_way, i_io_tasks_mainpipe_bits_way;
  logic g_io_tasks_mainpipe_bits_meta_dirty, i_io_tasks_mainpipe_bits_meta_dirty;
  logic [1:0] g_io_tasks_mainpipe_bits_meta_state, i_io_tasks_mainpipe_bits_meta_state;
  logic g_io_tasks_mainpipe_bits_meta_clients, i_io_tasks_mainpipe_bits_meta_clients;
  logic [1:0] g_io_tasks_mainpipe_bits_meta_alias, i_io_tasks_mainpipe_bits_meta_alias;
  logic g_io_tasks_mainpipe_bits_meta_prefetch, i_io_tasks_mainpipe_bits_meta_prefetch;
  logic [2:0] g_io_tasks_mainpipe_bits_meta_prefetchSrc, i_io_tasks_mainpipe_bits_meta_prefetchSrc;
  logic g_io_tasks_mainpipe_bits_meta_accessed, i_io_tasks_mainpipe_bits_meta_accessed;
  logic g_io_tasks_mainpipe_bits_meta_tagErr, i_io_tasks_mainpipe_bits_meta_tagErr;
  logic g_io_tasks_mainpipe_bits_meta_dataErr, i_io_tasks_mainpipe_bits_meta_dataErr;
  logic g_io_tasks_mainpipe_bits_metaWen, i_io_tasks_mainpipe_bits_metaWen;
  logic g_io_tasks_mainpipe_bits_tagWen, i_io_tasks_mainpipe_bits_tagWen;
  logic g_io_tasks_mainpipe_bits_dsWen, i_io_tasks_mainpipe_bits_dsWen;
  logic g_io_tasks_mainpipe_bits_replTask, i_io_tasks_mainpipe_bits_replTask;
  logic g_io_tasks_mainpipe_bits_cmoTask, i_io_tasks_mainpipe_bits_cmoTask;
  logic [4:0] g_io_tasks_mainpipe_bits_reqSource, i_io_tasks_mainpipe_bits_reqSource;
  logic g_io_tasks_mainpipe_bits_mergeA, i_io_tasks_mainpipe_bits_mergeA;
  logic [5:0] g_io_tasks_mainpipe_bits_aMergeTask_off, i_io_tasks_mainpipe_bits_aMergeTask_off;
  logic [1:0] g_io_tasks_mainpipe_bits_aMergeTask_alias, i_io_tasks_mainpipe_bits_aMergeTask_alias;
  logic [43:0] g_io_tasks_mainpipe_bits_aMergeTask_vaddr, i_io_tasks_mainpipe_bits_aMergeTask_vaddr;
  logic g_io_tasks_mainpipe_bits_aMergeTask_isKeyword, i_io_tasks_mainpipe_bits_aMergeTask_isKeyword;
  logic [2:0] g_io_tasks_mainpipe_bits_aMergeTask_opcode, i_io_tasks_mainpipe_bits_aMergeTask_opcode;
  logic [2:0] g_io_tasks_mainpipe_bits_aMergeTask_param, i_io_tasks_mainpipe_bits_aMergeTask_param;
  logic [6:0] g_io_tasks_mainpipe_bits_aMergeTask_sourceId, i_io_tasks_mainpipe_bits_aMergeTask_sourceId;
  logic g_io_tasks_mainpipe_bits_aMergeTask_meta_dirty, i_io_tasks_mainpipe_bits_aMergeTask_meta_dirty;
  logic [1:0] g_io_tasks_mainpipe_bits_aMergeTask_meta_state, i_io_tasks_mainpipe_bits_aMergeTask_meta_state;
  logic g_io_tasks_mainpipe_bits_aMergeTask_meta_clients, i_io_tasks_mainpipe_bits_aMergeTask_meta_clients;
  logic [1:0] g_io_tasks_mainpipe_bits_aMergeTask_meta_alias, i_io_tasks_mainpipe_bits_aMergeTask_meta_alias;
  logic g_io_tasks_mainpipe_bits_aMergeTask_meta_accessed, i_io_tasks_mainpipe_bits_aMergeTask_meta_accessed;
  logic g_io_tasks_mainpipe_bits_snpHitRelease, i_io_tasks_mainpipe_bits_snpHitRelease;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseToInval, i_io_tasks_mainpipe_bits_snpHitReleaseToInval;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseToClean, i_io_tasks_mainpipe_bits_snpHitReleaseToClean;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseWithData, i_io_tasks_mainpipe_bits_snpHitReleaseWithData;
  logic [7:0] g_io_tasks_mainpipe_bits_snpHitReleaseIdx, i_io_tasks_mainpipe_bits_snpHitReleaseIdx;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty;
  logic [1:0] g_io_tasks_mainpipe_bits_snpHitReleaseMeta_state, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_state;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients;
  logic [1:0] g_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] g_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr;
  logic g_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr, i_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] g_io_tasks_mainpipe_bits_tgtID, i_io_tasks_mainpipe_bits_tgtID;
  logic [11:0] g_io_tasks_mainpipe_bits_txnID, i_io_tasks_mainpipe_bits_txnID;
  logic [10:0] g_io_tasks_mainpipe_bits_homeNID, i_io_tasks_mainpipe_bits_homeNID;
  logic [11:0] g_io_tasks_mainpipe_bits_dbID, i_io_tasks_mainpipe_bits_dbID;
  logic [6:0] g_io_tasks_mainpipe_bits_chiOpcode, i_io_tasks_mainpipe_bits_chiOpcode;
  logic [2:0] g_io_tasks_mainpipe_bits_resp, i_io_tasks_mainpipe_bits_resp;
  logic [2:0] g_io_tasks_mainpipe_bits_fwdState, i_io_tasks_mainpipe_bits_fwdState;
  logic g_io_tasks_mainpipe_bits_retToSrc, i_io_tasks_mainpipe_bits_retToSrc;
  logic g_io_tasks_mainpipe_bits_likelyshared, i_io_tasks_mainpipe_bits_likelyshared;
  logic g_io_tasks_mainpipe_bits_expCompAck, i_io_tasks_mainpipe_bits_expCompAck;
  logic g_io_tasks_mainpipe_bits_allowRetry, i_io_tasks_mainpipe_bits_allowRetry;
  logic g_io_tasks_mainpipe_bits_memAttr_allocate, i_io_tasks_mainpipe_bits_memAttr_allocate;
  logic g_io_tasks_mainpipe_bits_memAttr_cacheable, i_io_tasks_mainpipe_bits_memAttr_cacheable;
  logic g_io_tasks_mainpipe_bits_memAttr_ewa, i_io_tasks_mainpipe_bits_memAttr_ewa;
  logic g_io_tasks_mainpipe_bits_traceTag, i_io_tasks_mainpipe_bits_traceTag;
  logic g_io_nestedwbData, i_io_nestedwbData;
  logic g_io_pCrd_query_valid, i_io_pCrd_query_valid;
  logic [3:0] g_io_pCrd_query_bits_pCrdType, i_io_pCrd_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_query_bits_srcID, i_io_pCrd_query_bits_srcID;
  logic g_acquire_period_valid, i_acquire_period_valid;
  logic [63:0] g_acquire_period_bits, i_acquire_period_bits;
  logic g_release_period_valid, i_release_period_valid;
  logic [63:0] g_release_period_bits, i_release_period_bits;

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
    .io_statAlloc_valid(g_io_statAlloc_valid),
    .io_statAlloc_bits_channel(g_io_statAlloc_bits_channel),
    .io_statAlloc_bits_is_miss(g_io_statAlloc_bits_is_miss),
    .io_statAlloc_bits_is_prefetch(g_io_statAlloc_bits_is_prefetch),
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
    .io_alloc_bits_task_denied(io_alloc_bits_task_denied),
    .io_alloc_bits_task_corrupt(io_alloc_bits_task_corrupt),
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
    .io_nestedwb_set(io_nestedwb_set),
    .io_nestedwb_tag(io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(io_nestedwb_b_toB),
    .io_nestedwb_b_toN(io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
    .io_nestedwb_denied(io_nestedwb_denied),
    .io_nestedwb_corrupt(io_nestedwb_corrupt),
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
    .io_replResp_bits_error(io_replResp_bits_error),
    .io_pCrd_query_valid(g_io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType(g_io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID(g_io_pCrd_query_bits_srcID),
    .io_pCrd_grant(io_pCrd_grant),
    .io_dsResp_valid(io_dsResp_valid),
    .io_dsResp_bits_dataError(io_dsResp_bits_dataError),
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
    .io_statAlloc_valid(i_io_statAlloc_valid),
    .io_statAlloc_bits_channel(i_io_statAlloc_bits_channel),
    .io_statAlloc_bits_is_miss(i_io_statAlloc_bits_is_miss),
    .io_statAlloc_bits_is_prefetch(i_io_statAlloc_bits_is_prefetch),
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
    .io_alloc_bits_task_denied(io_alloc_bits_task_denied),
    .io_alloc_bits_task_corrupt(io_alloc_bits_task_corrupt),
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
    .io_nestedwb_set(io_nestedwb_set),
    .io_nestedwb_tag(io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(io_nestedwb_b_toB),
    .io_nestedwb_b_toN(io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
    .io_nestedwb_denied(io_nestedwb_denied),
    .io_nestedwb_corrupt(io_nestedwb_corrupt),
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
    .io_replResp_bits_error(io_replResp_bits_error),
    .io_pCrd_query_valid(i_io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType(i_io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID(i_io_pCrd_query_bits_srcID),
    .io_pCrd_grant(io_pCrd_grant),
    .io_dsResp_valid(io_dsResp_valid),
    .io_dsResp_bits_dataError(io_dsResp_bits_dataError),
    .acquire_period_valid(i_acquire_period_valid),
    .acquire_period_bits(i_acquire_period_bits),
    .release_period_valid(i_release_period_valid),
    .release_period_bits(i_release_period_bits)
  );

  function automatic logic [3:0] pick_a_opcode();
    case ($urandom_range(0, 9))
      0: return 4'h4;  1: return 4'h5;  2, 3: return 4'h6;  4: return 4'h7;
      5: return 4'hC;  6: return 4'hD;  7: return 4'hE;
      default: return 4'($urandom);
    endcase
  endfunction
  function automatic logic [6:0] pick(input logic [6:0] a, input logic [6:0] b, input logic [6:0] c);
    case ($urandom_range(0, 2)) 0: return a; 1: return b; default: return c; endcase
  endfunction
  function automatic logic [6:0] pick5(input logic [6:0] a, input logic [6:0] b, input logic [6:0] c,
                                      input logic [6:0] d, input logic [6:0] e);
    case ($urandom_range(0, 4)) 0: return a; 1: return b; 2: return c; 3: return d;
      default: return e; endcase
  endfunction

  task automatic drive();
    io_id = 8'($urandom);
    io_alloc_valid = u_g.req_valid ? ($urandom_range(0, 299) == 0) : ($urandom_range(0, 3) == 0);
    io_alloc_bits_dirResult_hit = 1'($urandom);
    io_alloc_bits_dirResult_tag = 31'($urandom_range(0, 3));
    io_alloc_bits_dirResult_set = 9'($urandom_range(0, 3));
    io_alloc_bits_dirResult_way = 3'($urandom);
    io_alloc_bits_dirResult_meta_dirty = 1'($urandom);
    io_alloc_bits_dirResult_meta_state = 2'($urandom);
    io_alloc_bits_dirResult_meta_clients = 1'($urandom);
    io_alloc_bits_dirResult_meta_alias = 2'($urandom);
    io_alloc_bits_dirResult_meta_prefetch = 1'($urandom);
    io_alloc_bits_dirResult_meta_prefetchSrc = 3'($urandom);
    io_alloc_bits_dirResult_meta_accessed = 1'($urandom);
    io_alloc_bits_dirResult_meta_tagErr = 1'($urandom);
    io_alloc_bits_dirResult_meta_dataErr = 1'($urandom);
    io_alloc_bits_dirResult_error = 1'($urandom);
    io_alloc_bits_state_s_acquire = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_rprobe = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_pprobe = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_release = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_probeack = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_refill = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_cmoresp = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_rprobeackfirst = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_rprobeacklast = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_pprobeackfirst = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_pprobeacklast = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_grantfirst = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_grantlast = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_grant = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_releaseack = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_w_replResp = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_rcompack = ($urandom_range(0, 2) != 0);
    io_alloc_bits_state_s_dct = ($urandom_range(0, 2) != 0);
    io_alloc_bits_task_channel = 3'b1 << $urandom_range(0, 2);
    io_alloc_bits_task_set = 9'($urandom);
    io_alloc_bits_task_tag = 31'($urandom);
    io_alloc_bits_task_off = 6'($urandom);
    io_alloc_bits_task_alias = 2'($urandom);
    io_alloc_bits_task_isKeyword = 1'($urandom);
    io_alloc_bits_task_opcode = pick_a_opcode();
    io_alloc_bits_task_param = 3'($urandom);
    io_alloc_bits_task_sourceId = 7'($urandom);
    io_alloc_bits_task_denied = 1'($urandom);
    io_alloc_bits_task_corrupt = 1'($urandom);
    io_alloc_bits_task_aliasTask = 1'($urandom);
    io_alloc_bits_task_fromL2pft = 1'($urandom);
    io_alloc_bits_task_reqSource = 5'($urandom);
    io_alloc_bits_task_snpHitRelease = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseToInval = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseToClean = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseWithData = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseIdx = 8'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_dirty = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_state = 2'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_clients = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_alias = 2'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_prefetch = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc = 3'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_accessed = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_tagErr = 1'($urandom);
    io_alloc_bits_task_snpHitReleaseMeta_dataErr = 1'($urandom);
    io_alloc_bits_task_srcID = 11'($urandom);
    io_alloc_bits_task_txnID = 12'($urandom);
    io_alloc_bits_task_fwdNID = 11'($urandom);
    io_alloc_bits_task_fwdTxnID = 12'($urandom);
    io_alloc_bits_task_chiOpcode = $urandom_range(0, 23);
    io_alloc_bits_task_retToSrc = 1'($urandom);
    io_alloc_bits_task_traceTag = 1'($urandom);
    io_tasks_txreq_ready = ($urandom_range(0, 9) < 7);
    io_tasks_txrsp_ready = ($urandom_range(0, 9) < 7);
    io_tasks_source_b_ready = ($urandom_range(0, 9) < 7);
    io_tasks_mainpipe_ready = ($urandom_range(0, 9) < 7);
    io_resps_sinkC_valid = ($urandom_range(0, 5) == 0);
    io_resps_sinkC_bits_opcode = pick(3'h4, 3'h5, 3'($urandom));
    io_resps_sinkC_bits_param = 3'($urandom);
    io_resps_sinkC_bits_last = 1'($urandom);
    io_resps_sinkC_bits_denied = 1'($urandom);
    io_resps_sinkC_bits_corrupt = 1'($urandom);
    io_resps_rxrsp_valid = ($urandom_range(0, 5) == 0);
    io_resps_rxrsp_bits_chiOpcode = pick5(7'hB, 7'h4, 7'h5, 7'h3, 7'($urandom));
    io_resps_rxrsp_bits_srcID = 11'($urandom);
    io_resps_rxrsp_bits_dbID = 12'($urandom);
    io_resps_rxrsp_bits_resp = 3'($urandom);
    io_resps_rxrsp_bits_pCrdType = 4'($urandom);
    io_resps_rxrsp_bits_respErr = 2'($urandom);
    io_resps_rxrsp_bits_traceTag = 1'($urandom);
    io_resps_rxdat_valid = ($urandom_range(0, 5) == 0);
    io_resps_rxdat_bits_corrupt = 1'($urandom);
    io_resps_rxdat_bits_chiOpcode = pick(7'h4, 7'hB, 7'($urandom));
    io_resps_rxdat_bits_homeNID = 11'($urandom);
    io_resps_rxdat_bits_dbID = 12'($urandom);
    io_resps_rxdat_bits_resp = 3'($urandom);
    io_resps_rxdat_bits_respErr = 2'($urandom);
    io_resps_rxdat_bits_traceTag = 1'($urandom);
    io_nestedwb_set = ($urandom_range(0, 1) == 0) ? u_g.dirResult_set : 9'($urandom_range(0, 3));
    io_nestedwb_tag = ($urandom_range(0, 1) == 0) ? u_g.dirResult_tag : 31'($urandom_range(0, 3));
    io_nestedwb_c_set_dirty = ($urandom_range(0, 7) == 0);
    io_nestedwb_c_set_tip = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_inv_dirty = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_toB = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_toN = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_toClean = ($urandom_range(0, 7) == 0);
    io_nestedwb_denied = ($urandom_range(0, 7) == 0);
    io_nestedwb_corrupt = ($urandom_range(0, 7) == 0);
    io_aMergeTask_valid = ($urandom_range(0, 19) == 0);
    io_aMergeTask_bits_off = 6'($urandom);
    io_aMergeTask_bits_alias = 2'($urandom);
    io_aMergeTask_bits_vaddr = {$urandom, $urandom};
    io_aMergeTask_bits_isKeyword = 1'($urandom);
    io_aMergeTask_bits_opcode = 4'($urandom);
    io_aMergeTask_bits_param = 3'($urandom);
    io_aMergeTask_bits_sourceId = 7'($urandom);
    io_replResp_valid = ($urandom_range(0, 9) == 0);
    io_replResp_bits_tag = 31'($urandom_range(0, 3));
    io_replResp_bits_way = 3'($urandom);
    io_replResp_bits_meta_dirty = 1'($urandom);
    io_replResp_bits_meta_state = 2'($urandom);
    io_replResp_bits_meta_clients = 1'($urandom);
    io_replResp_bits_meta_alias = 2'($urandom);
    io_replResp_bits_meta_prefetch = 1'($urandom);
    io_replResp_bits_meta_prefetchSrc = 3'($urandom);
    io_replResp_bits_meta_accessed = 1'($urandom);
    io_replResp_bits_meta_tagErr = 1'($urandom);
    io_replResp_bits_meta_dataErr = 1'($urandom);
    io_replResp_bits_retry = 1'($urandom);
    io_replResp_bits_error = 1'($urandom);
    io_pCrd_grant = ($urandom_range(0, 9) == 0);
    io_dsResp_valid = ($urandom_range(0, 9) == 0);
    io_dsResp_bits_dataError = 1'($urandom);
    reset = ($urandom_range(0, 4999) == 0);
  endtask

  `define CK(nm) begin checks++; if (g_``nm !== i_``nm) begin errors++; \
    if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, `"nm`", g_``nm, i_``nm); \
    end end
  task automatic check();
    `CK(io_status_valid)
    `CK(io_status_bits_channel)
    `CK(io_status_bits_set)
    `CK(io_status_bits_reqTag)
    `CK(io_status_bits_metaTag)
    `CK(io_status_bits_needsRepl)
    `CK(io_status_bits_w_c_resp)
    `CK(io_status_bits_will_free)
    `CK(io_status_bits_reqSource)
    `CK(io_status_bits_is_miss)
    `CK(io_status_bits_is_prefetch)
    `CK(io_statAlloc_valid)
    `CK(io_statAlloc_bits_channel)
    `CK(io_statAlloc_bits_is_miss)
    `CK(io_statAlloc_bits_is_prefetch)
    `CK(io_msInfo_valid)
    `CK(io_msInfo_bits_channel)
    `CK(io_msInfo_bits_set)
    `CK(io_msInfo_bits_way)
    `CK(io_msInfo_bits_reqTag)
    `CK(io_msInfo_bits_willFree)
    `CK(io_msInfo_bits_aliasTask)
    `CK(io_msInfo_bits_needRelease)
    `CK(io_msInfo_bits_blockRefill)
    `CK(io_msInfo_bits_meta_dirty)
    `CK(io_msInfo_bits_meta_state)
    `CK(io_msInfo_bits_meta_clients)
    `CK(io_msInfo_bits_meta_alias)
    `CK(io_msInfo_bits_meta_prefetch)
    `CK(io_msInfo_bits_meta_prefetchSrc)
    `CK(io_msInfo_bits_meta_accessed)
    `CK(io_msInfo_bits_meta_tagErr)
    `CK(io_msInfo_bits_meta_dataErr)
    `CK(io_msInfo_bits_metaTag)
    `CK(io_msInfo_bits_dirHit)
    `CK(io_msInfo_bits_isAcqOrPrefetch)
    `CK(io_msInfo_bits_isPrefetch)
    `CK(io_msInfo_bits_param)
    `CK(io_msInfo_bits_mergeA)
    `CK(io_msInfo_bits_w_grantfirst)
    `CK(io_msInfo_bits_s_release)
    `CK(io_msInfo_bits_s_refill)
    `CK(io_msInfo_bits_s_cmoresp)
    `CK(io_msInfo_bits_s_cmometaw)
    `CK(io_msInfo_bits_w_releaseack)
    `CK(io_msInfo_bits_w_replResp)
    `CK(io_msInfo_bits_w_rprobeacklast)
    `CK(io_msInfo_bits_replaceData)
    `CK(io_msInfo_bits_releaseToClean)
    `CK(io_tasks_txreq_valid)
    `CK(io_tasks_txreq_bits_tgtID)
    `CK(io_tasks_txreq_bits_txnID)
    `CK(io_tasks_txreq_bits_opcode)
    `CK(io_tasks_txreq_bits_addr)
    `CK(io_tasks_txreq_bits_likelyshared)
    `CK(io_tasks_txreq_bits_allowRetry)
    `CK(io_tasks_txreq_bits_pCrdType)
    `CK(io_tasks_txreq_bits_memAttr_allocate)
    `CK(io_tasks_txreq_bits_expCompAck)
    `CK(io_tasks_txrsp_valid)
    `CK(io_tasks_txrsp_bits_tgtID)
    `CK(io_tasks_txrsp_bits_txnID)
    `CK(io_tasks_txrsp_bits_traceTag)
    `CK(io_tasks_source_b_valid)
    `CK(io_tasks_source_b_bits_tag)
    `CK(io_tasks_source_b_bits_set)
    `CK(io_tasks_source_b_bits_param)
    `CK(io_tasks_source_b_bits_alias)
    `CK(io_tasks_mainpipe_valid)
    `CK(io_tasks_mainpipe_bits_channel)
    `CK(io_tasks_mainpipe_bits_txChannel)
    `CK(io_tasks_mainpipe_bits_set)
    `CK(io_tasks_mainpipe_bits_tag)
    `CK(io_tasks_mainpipe_bits_off)
    `CK(io_tasks_mainpipe_bits_alias)
    `CK(io_tasks_mainpipe_bits_isKeyword)
    `CK(io_tasks_mainpipe_bits_opcode)
    `CK(io_tasks_mainpipe_bits_param)
    `CK(io_tasks_mainpipe_bits_size)
    `CK(io_tasks_mainpipe_bits_sourceId)
    `CK(io_tasks_mainpipe_bits_denied)
    `CK(io_tasks_mainpipe_bits_corrupt)
    `CK(io_tasks_mainpipe_bits_mshrId)
    `CK(io_tasks_mainpipe_bits_aliasTask)
    `CK(io_tasks_mainpipe_bits_useProbeData)
    `CK(io_tasks_mainpipe_bits_mshrRetry)
    `CK(io_tasks_mainpipe_bits_readProbeDataDown)
    `CK(io_tasks_mainpipe_bits_fromL2pft)
    `CK(io_tasks_mainpipe_bits_dirty)
    `CK(io_tasks_mainpipe_bits_way)
    `CK(io_tasks_mainpipe_bits_meta_dirty)
    `CK(io_tasks_mainpipe_bits_meta_state)
    `CK(io_tasks_mainpipe_bits_meta_clients)
    `CK(io_tasks_mainpipe_bits_meta_alias)
    `CK(io_tasks_mainpipe_bits_meta_prefetch)
    `CK(io_tasks_mainpipe_bits_meta_prefetchSrc)
    `CK(io_tasks_mainpipe_bits_meta_accessed)
    `CK(io_tasks_mainpipe_bits_meta_tagErr)
    `CK(io_tasks_mainpipe_bits_meta_dataErr)
    `CK(io_tasks_mainpipe_bits_metaWen)
    `CK(io_tasks_mainpipe_bits_tagWen)
    `CK(io_tasks_mainpipe_bits_dsWen)
    `CK(io_tasks_mainpipe_bits_replTask)
    `CK(io_tasks_mainpipe_bits_cmoTask)
    `CK(io_tasks_mainpipe_bits_reqSource)
    `CK(io_tasks_mainpipe_bits_mergeA)
    `CK(io_tasks_mainpipe_bits_aMergeTask_off)
    `CK(io_tasks_mainpipe_bits_aMergeTask_alias)
    `CK(io_tasks_mainpipe_bits_aMergeTask_vaddr)
    `CK(io_tasks_mainpipe_bits_aMergeTask_isKeyword)
    `CK(io_tasks_mainpipe_bits_aMergeTask_opcode)
    `CK(io_tasks_mainpipe_bits_aMergeTask_param)
    `CK(io_tasks_mainpipe_bits_aMergeTask_sourceId)
    `CK(io_tasks_mainpipe_bits_aMergeTask_meta_dirty)
    `CK(io_tasks_mainpipe_bits_aMergeTask_meta_state)
    `CK(io_tasks_mainpipe_bits_aMergeTask_meta_clients)
    `CK(io_tasks_mainpipe_bits_aMergeTask_meta_alias)
    `CK(io_tasks_mainpipe_bits_aMergeTask_meta_accessed)
    `CK(io_tasks_mainpipe_bits_snpHitRelease)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseToInval)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseToClean)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseWithData)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseIdx)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_state)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_clients)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_alias)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr)
    `CK(io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr)
    `CK(io_tasks_mainpipe_bits_tgtID)
    `CK(io_tasks_mainpipe_bits_txnID)
    `CK(io_tasks_mainpipe_bits_homeNID)
    `CK(io_tasks_mainpipe_bits_dbID)
    `CK(io_tasks_mainpipe_bits_chiOpcode)
    `CK(io_tasks_mainpipe_bits_resp)
    `CK(io_tasks_mainpipe_bits_fwdState)
    `CK(io_tasks_mainpipe_bits_retToSrc)
    `CK(io_tasks_mainpipe_bits_likelyshared)
    `CK(io_tasks_mainpipe_bits_expCompAck)
    `CK(io_tasks_mainpipe_bits_allowRetry)
    `CK(io_tasks_mainpipe_bits_memAttr_allocate)
    `CK(io_tasks_mainpipe_bits_memAttr_cacheable)
    `CK(io_tasks_mainpipe_bits_memAttr_ewa)
    `CK(io_tasks_mainpipe_bits_traceTag)
    `CK(io_nestedwbData)
    `CK(io_pCrd_query_valid)
    `CK(io_pCrd_query_bits_pCrdType)
    `CK(io_pCrd_query_bits_srcID)
    `CK(acquire_period_valid)
    `CK(acquire_period_bits)
    `CK(release_period_valid)
    `CK(release_period_bits)
  endtask

  longint cov [21];
  localparam string COV_NAME [21] = '{"release_valid1", "release_valid2", "mp_grant_valid", "mp_cbwrdata_valid", "mp_probeack_valid", "mp_dct_valid", "rcompack_valid", "wcompack_valid", "nestedwb_match", "nestedwb_hit_match", "doRespData", "req_promoteT", "isWriteBackFull", "isWriteEvictOrEvict", "isEvict", "cmo_cbo", "_GEN_80", "acquire_period_valid", "release_period_valid", "io_nestedwbData", "io_pCrd_query_valid"};
  task automatic sample();
    if (u_g.release_valid1) cov[0]++;
    if (u_g.release_valid2) cov[1]++;
    if (u_g.mp_grant_valid) cov[2]++;
    if (u_g.mp_cbwrdata_valid) cov[3]++;
    if (u_g.mp_probeack_valid) cov[4]++;
    if (u_g.mp_dct_valid) cov[5]++;
    if (u_g.rcompack_valid) cov[6]++;
    if (u_g.wcompack_valid) cov[7]++;
    if (u_g.nestedwb_match) cov[8]++;
    if (u_g.nestedwb_hit_match) cov[9]++;
    if (u_g.doRespData) cov[10]++;
    if (u_g.req_promoteT) cov[11]++;
    if (u_g.isWriteBackFull) cov[12]++;
    if (u_g.isWriteEvictOrEvict) cov[13]++;
    if (u_g.isEvict) cov[14]++;
    if (u_g.cmo_cbo) cov[15]++;
    if (u_g._GEN_80) cov[16]++;
    if (u_g.acquire_period_valid) cov[17]++;
    if (u_g.release_period_valid) cov[18]++;
    if (u_g.io_nestedwbData) cov[19]++;
    if (u_g.io_pCrd_query_valid) cov[20]++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[k]) cov[k] = 0;
    reset = 1'b1;
    drive(); reset = 1'b1;
    #1;
    // 未复位寄存器两侧同初值（见文件头）
    force u_i.u_core.tgtid_rcompack = u_g.tgtid_rcompack;
    force u_i.u_core.txnid_rcompack = u_g.txnid_rcompack;
    force u_i.u_core.tgtid_wcompack = u_g.tgtid_wcompack;
    force u_i.u_core.txnid_wcompack = u_g.txnid_wcompack;
    force u_i.u_core.srcid_retryack = u_g.srcid_retryack;
    force u_i.u_core.acquire_ts = u_g.acquire_ts;
    force u_i.u_core.release_ts = u_g.release_ts;
    force u_i.u_core.acquire_period_valid_REG = u_g.acquire_period_valid_REG;
    force u_i.u_core.release_period_valid_REG = u_g.release_period_valid_REG;
    force u_i.u_core.REG = u_g.REG;
    force u_i.u_core.REG_1 = u_g.REG_1;
    force u_i.u_core.REG_2 = u_g.REG_2;
    force u_i.u_core.REG_3 = u_g.REG_3;
    #1;
    release u_i.u_core.tgtid_rcompack;
    release u_i.u_core.txnid_rcompack;
    release u_i.u_core.tgtid_wcompack;
    release u_i.u_core.txnid_wcompack;
    release u_i.u_core.srcid_retryack;
    release u_i.u_core.acquire_ts;
    release u_i.u_core.release_ts;
    release u_i.u_core.acquire_period_valid_REG;
    release u_i.u_core.release_period_valid_REG;
    release u_i.u_core.REG;
    release u_i.u_core.REG_1;
    release u_i.u_core.REG_2;
    release u_i.u_core.REG_3;
    repeat (4) @(posedge clock);
    #1; drive(); reset = 1'b0;
    repeat (NCYCLES) begin
      @(posedge clock); #1;
      check(); sample(); drive();
    end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage（golden 内部判断为真的拍数）---");
    foreach (cov[k]) begin
      $display("  %-24s %0d", COV_NAME[k], cov[k]);
      if (cov[k] == 0) bad++;
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
