// =============================================================================
// tb —— MSHRCtl UT：golden MSHRCtl 与重写 MSHRCtl_xs 双例化，同激励逐拍比对全部 867 个输出。
//
// 激励（每拍全部输入重摇，偏置见 gen_tb.py 的 drive_expr）：
//   · MainPipe 1/8 概率分配，分配的 state 标志 7/8 为 1（让事务能走完、MSHR 能周转）；
//   · TL opcode 偏向 Get/Hint/Acquire*/CBO*，snoop opcode 覆盖 0..23 全部；
//   · set/tag 取值域压到 0..3，mshrId/id 取 0..16（含一个越界值），让按地址 / 按编号的
//     分发真正命中；RXDAT/RXRSP/SinkC 的 opcode 偏向 MSHR 识别的那几个；
//   · 约 1/5000 拍一次单拍异步复位。
// 未复位寄存器：+vcs+initreg+random 下两侧初值不同，tb 在首个时钟沿前把 golden 侧
//   初值 force 到重写侧（16 个 MSHR 各 13 个 + 本层 7 个）；有复位的寄存器不做任何同步。
// 覆盖：一组 golden 内部判断 / 握手各自为真的拍数，任何一项为 0 即判 TEST FAILED。
//
// 本文件由 verif/ut/MSHRCtl/gen_tb.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; always #5 clock = ~clock;
  logic reset;
  longint errors = 0, checks = 0;

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
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_denied;
  logic io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt;
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
  logic io_dsResp_valid;
  logic [7:0] io_dsResp_bits_mshrId;
  logic io_dsResp_bits_dataError;
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
  logic io_replResp_bits_error;
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
  logic g_io_toReqArb_blockA_s1, i_io_toReqArb_blockA_s1;
  logic g_io_toReqArb_blockB_s1, i_io_toReqArb_blockB_s1;
  logic [7:0] g_io_toMainPipe_mshr_alloc_ptr, i_io_toMainPipe_mshr_alloc_ptr;
  logic g_io_mshrTask_valid, i_io_mshrTask_valid;
  logic [2:0] g_io_mshrTask_bits_channel, i_io_mshrTask_bits_channel;
  logic [2:0] g_io_mshrTask_bits_txChannel, i_io_mshrTask_bits_txChannel;
  logic [8:0] g_io_mshrTask_bits_set, i_io_mshrTask_bits_set;
  logic [30:0] g_io_mshrTask_bits_tag, i_io_mshrTask_bits_tag;
  logic [5:0] g_io_mshrTask_bits_off, i_io_mshrTask_bits_off;
  logic [1:0] g_io_mshrTask_bits_alias, i_io_mshrTask_bits_alias;
  logic g_io_mshrTask_bits_isKeyword, i_io_mshrTask_bits_isKeyword;
  logic [3:0] g_io_mshrTask_bits_opcode, i_io_mshrTask_bits_opcode;
  logic [2:0] g_io_mshrTask_bits_param, i_io_mshrTask_bits_param;
  logic [2:0] g_io_mshrTask_bits_size, i_io_mshrTask_bits_size;
  logic [6:0] g_io_mshrTask_bits_sourceId, i_io_mshrTask_bits_sourceId;
  logic g_io_mshrTask_bits_denied, i_io_mshrTask_bits_denied;
  logic g_io_mshrTask_bits_corrupt, i_io_mshrTask_bits_corrupt;
  logic g_io_mshrTask_bits_mshrTask, i_io_mshrTask_bits_mshrTask;
  logic [7:0] g_io_mshrTask_bits_mshrId, i_io_mshrTask_bits_mshrId;
  logic g_io_mshrTask_bits_aliasTask, i_io_mshrTask_bits_aliasTask;
  logic g_io_mshrTask_bits_useProbeData, i_io_mshrTask_bits_useProbeData;
  logic g_io_mshrTask_bits_mshrRetry, i_io_mshrTask_bits_mshrRetry;
  logic g_io_mshrTask_bits_readProbeDataDown, i_io_mshrTask_bits_readProbeDataDown;
  logic g_io_mshrTask_bits_fromL2pft, i_io_mshrTask_bits_fromL2pft;
  logic g_io_mshrTask_bits_dirty, i_io_mshrTask_bits_dirty;
  logic [2:0] g_io_mshrTask_bits_way, i_io_mshrTask_bits_way;
  logic g_io_mshrTask_bits_meta_dirty, i_io_mshrTask_bits_meta_dirty;
  logic [1:0] g_io_mshrTask_bits_meta_state, i_io_mshrTask_bits_meta_state;
  logic g_io_mshrTask_bits_meta_clients, i_io_mshrTask_bits_meta_clients;
  logic [1:0] g_io_mshrTask_bits_meta_alias, i_io_mshrTask_bits_meta_alias;
  logic g_io_mshrTask_bits_meta_prefetch, i_io_mshrTask_bits_meta_prefetch;
  logic [2:0] g_io_mshrTask_bits_meta_prefetchSrc, i_io_mshrTask_bits_meta_prefetchSrc;
  logic g_io_mshrTask_bits_meta_accessed, i_io_mshrTask_bits_meta_accessed;
  logic g_io_mshrTask_bits_meta_tagErr, i_io_mshrTask_bits_meta_tagErr;
  logic g_io_mshrTask_bits_meta_dataErr, i_io_mshrTask_bits_meta_dataErr;
  logic g_io_mshrTask_bits_metaWen, i_io_mshrTask_bits_metaWen;
  logic g_io_mshrTask_bits_tagWen, i_io_mshrTask_bits_tagWen;
  logic g_io_mshrTask_bits_dsWen, i_io_mshrTask_bits_dsWen;
  logic g_io_mshrTask_bits_replTask, i_io_mshrTask_bits_replTask;
  logic g_io_mshrTask_bits_cmoTask, i_io_mshrTask_bits_cmoTask;
  logic [4:0] g_io_mshrTask_bits_reqSource, i_io_mshrTask_bits_reqSource;
  logic g_io_mshrTask_bits_mergeA, i_io_mshrTask_bits_mergeA;
  logic [5:0] g_io_mshrTask_bits_aMergeTask_off, i_io_mshrTask_bits_aMergeTask_off;
  logic [1:0] g_io_mshrTask_bits_aMergeTask_alias, i_io_mshrTask_bits_aMergeTask_alias;
  logic [43:0] g_io_mshrTask_bits_aMergeTask_vaddr, i_io_mshrTask_bits_aMergeTask_vaddr;
  logic g_io_mshrTask_bits_aMergeTask_isKeyword, i_io_mshrTask_bits_aMergeTask_isKeyword;
  logic [2:0] g_io_mshrTask_bits_aMergeTask_opcode, i_io_mshrTask_bits_aMergeTask_opcode;
  logic [2:0] g_io_mshrTask_bits_aMergeTask_param, i_io_mshrTask_bits_aMergeTask_param;
  logic [6:0] g_io_mshrTask_bits_aMergeTask_sourceId, i_io_mshrTask_bits_aMergeTask_sourceId;
  logic g_io_mshrTask_bits_aMergeTask_meta_dirty, i_io_mshrTask_bits_aMergeTask_meta_dirty;
  logic [1:0] g_io_mshrTask_bits_aMergeTask_meta_state, i_io_mshrTask_bits_aMergeTask_meta_state;
  logic g_io_mshrTask_bits_aMergeTask_meta_clients, i_io_mshrTask_bits_aMergeTask_meta_clients;
  logic [1:0] g_io_mshrTask_bits_aMergeTask_meta_alias, i_io_mshrTask_bits_aMergeTask_meta_alias;
  logic g_io_mshrTask_bits_aMergeTask_meta_accessed, i_io_mshrTask_bits_aMergeTask_meta_accessed;
  logic g_io_mshrTask_bits_snpHitRelease, i_io_mshrTask_bits_snpHitRelease;
  logic g_io_mshrTask_bits_snpHitReleaseToInval, i_io_mshrTask_bits_snpHitReleaseToInval;
  logic g_io_mshrTask_bits_snpHitReleaseToClean, i_io_mshrTask_bits_snpHitReleaseToClean;
  logic g_io_mshrTask_bits_snpHitReleaseWithData, i_io_mshrTask_bits_snpHitReleaseWithData;
  logic [7:0] g_io_mshrTask_bits_snpHitReleaseIdx, i_io_mshrTask_bits_snpHitReleaseIdx;
  logic g_io_mshrTask_bits_snpHitReleaseMeta_dirty, i_io_mshrTask_bits_snpHitReleaseMeta_dirty;
  logic [1:0] g_io_mshrTask_bits_snpHitReleaseMeta_state, i_io_mshrTask_bits_snpHitReleaseMeta_state;
  logic g_io_mshrTask_bits_snpHitReleaseMeta_clients, i_io_mshrTask_bits_snpHitReleaseMeta_clients;
  logic [1:0] g_io_mshrTask_bits_snpHitReleaseMeta_alias, i_io_mshrTask_bits_snpHitReleaseMeta_alias;
  logic g_io_mshrTask_bits_snpHitReleaseMeta_prefetch, i_io_mshrTask_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] g_io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc, i_io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
  logic g_io_mshrTask_bits_snpHitReleaseMeta_accessed, i_io_mshrTask_bits_snpHitReleaseMeta_accessed;
  logic g_io_mshrTask_bits_snpHitReleaseMeta_tagErr, i_io_mshrTask_bits_snpHitReleaseMeta_tagErr;
  logic g_io_mshrTask_bits_snpHitReleaseMeta_dataErr, i_io_mshrTask_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] g_io_mshrTask_bits_tgtID, i_io_mshrTask_bits_tgtID;
  logic [11:0] g_io_mshrTask_bits_txnID, i_io_mshrTask_bits_txnID;
  logic [10:0] g_io_mshrTask_bits_homeNID, i_io_mshrTask_bits_homeNID;
  logic [11:0] g_io_mshrTask_bits_dbID, i_io_mshrTask_bits_dbID;
  logic [6:0] g_io_mshrTask_bits_chiOpcode, i_io_mshrTask_bits_chiOpcode;
  logic [2:0] g_io_mshrTask_bits_resp, i_io_mshrTask_bits_resp;
  logic [2:0] g_io_mshrTask_bits_fwdState, i_io_mshrTask_bits_fwdState;
  logic g_io_mshrTask_bits_retToSrc, i_io_mshrTask_bits_retToSrc;
  logic g_io_mshrTask_bits_likelyshared, i_io_mshrTask_bits_likelyshared;
  logic g_io_mshrTask_bits_expCompAck, i_io_mshrTask_bits_expCompAck;
  logic g_io_mshrTask_bits_allowRetry, i_io_mshrTask_bits_allowRetry;
  logic g_io_mshrTask_bits_memAttr_allocate, i_io_mshrTask_bits_memAttr_allocate;
  logic g_io_mshrTask_bits_memAttr_cacheable, i_io_mshrTask_bits_memAttr_cacheable;
  logic g_io_mshrTask_bits_memAttr_ewa, i_io_mshrTask_bits_memAttr_ewa;
  logic g_io_mshrTask_bits_traceTag, i_io_mshrTask_bits_traceTag;
  logic g_io_toTXREQ_valid, i_io_toTXREQ_valid;
  logic [3:0] g_io_toTXREQ_bits_qos, i_io_toTXREQ_bits_qos;
  logic [10:0] g_io_toTXREQ_bits_tgtID, i_io_toTXREQ_bits_tgtID;
  logic [11:0] g_io_toTXREQ_bits_txnID, i_io_toTXREQ_bits_txnID;
  logic [6:0] g_io_toTXREQ_bits_opcode, i_io_toTXREQ_bits_opcode;
  logic [2:0] g_io_toTXREQ_bits_size, i_io_toTXREQ_bits_size;
  logic [47:0] g_io_toTXREQ_bits_addr, i_io_toTXREQ_bits_addr;
  logic g_io_toTXREQ_bits_likelyshared, i_io_toTXREQ_bits_likelyshared;
  logic g_io_toTXREQ_bits_allowRetry, i_io_toTXREQ_bits_allowRetry;
  logic [3:0] g_io_toTXREQ_bits_pCrdType, i_io_toTXREQ_bits_pCrdType;
  logic g_io_toTXREQ_bits_memAttr_allocate, i_io_toTXREQ_bits_memAttr_allocate;
  logic g_io_toTXREQ_bits_memAttr_cacheable, i_io_toTXREQ_bits_memAttr_cacheable;
  logic g_io_toTXREQ_bits_memAttr_ewa, i_io_toTXREQ_bits_memAttr_ewa;
  logic g_io_toTXREQ_bits_snpAttr, i_io_toTXREQ_bits_snpAttr;
  logic g_io_toTXREQ_bits_expCompAck, i_io_toTXREQ_bits_expCompAck;
  logic g_io_toTXRSP_valid, i_io_toTXRSP_valid;
  logic [10:0] g_io_toTXRSP_bits_tgtID, i_io_toTXRSP_bits_tgtID;
  logic [11:0] g_io_toTXRSP_bits_txnID, i_io_toTXRSP_bits_txnID;
  logic [4:0] g_io_toTXRSP_bits_opcode, i_io_toTXRSP_bits_opcode;
  logic g_io_toTXRSP_bits_traceTag, i_io_toTXRSP_bits_traceTag;
  logic g_io_toSourceB_valid, i_io_toSourceB_valid;
  logic [2:0] g_io_toSourceB_bits_opcode, i_io_toSourceB_bits_opcode;
  logic [1:0] g_io_toSourceB_bits_param, i_io_toSourceB_bits_param;
  logic [47:0] g_io_toSourceB_bits_address, i_io_toSourceB_bits_address;
  logic [255:0] g_io_toSourceB_bits_data, i_io_toSourceB_bits_data;
  logic [7:0] g_io_releaseBufWriteId, i_io_releaseBufWriteId;
  logic g_io_nestedwbDataId_valid, i_io_nestedwbDataId_valid;
  logic [7:0] g_io_nestedwbDataId_bits, i_io_nestedwbDataId_bits;
  logic g_io_msInfo_0_valid, i_io_msInfo_0_valid;
  logic [2:0] g_io_msInfo_0_bits_channel, i_io_msInfo_0_bits_channel;
  logic [8:0] g_io_msInfo_0_bits_set, i_io_msInfo_0_bits_set;
  logic [2:0] g_io_msInfo_0_bits_way, i_io_msInfo_0_bits_way;
  logic [30:0] g_io_msInfo_0_bits_reqTag, i_io_msInfo_0_bits_reqTag;
  logic g_io_msInfo_0_bits_willFree, i_io_msInfo_0_bits_willFree;
  logic g_io_msInfo_0_bits_aliasTask, i_io_msInfo_0_bits_aliasTask;
  logic g_io_msInfo_0_bits_needRelease, i_io_msInfo_0_bits_needRelease;
  logic g_io_msInfo_0_bits_blockRefill, i_io_msInfo_0_bits_blockRefill;
  logic g_io_msInfo_0_bits_meta_dirty, i_io_msInfo_0_bits_meta_dirty;
  logic [1:0] g_io_msInfo_0_bits_meta_state, i_io_msInfo_0_bits_meta_state;
  logic g_io_msInfo_0_bits_meta_clients, i_io_msInfo_0_bits_meta_clients;
  logic [1:0] g_io_msInfo_0_bits_meta_alias, i_io_msInfo_0_bits_meta_alias;
  logic g_io_msInfo_0_bits_meta_prefetch, i_io_msInfo_0_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_0_bits_meta_prefetchSrc, i_io_msInfo_0_bits_meta_prefetchSrc;
  logic g_io_msInfo_0_bits_meta_accessed, i_io_msInfo_0_bits_meta_accessed;
  logic g_io_msInfo_0_bits_meta_tagErr, i_io_msInfo_0_bits_meta_tagErr;
  logic g_io_msInfo_0_bits_meta_dataErr, i_io_msInfo_0_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_0_bits_metaTag, i_io_msInfo_0_bits_metaTag;
  logic g_io_msInfo_0_bits_dirHit, i_io_msInfo_0_bits_dirHit;
  logic g_io_msInfo_0_bits_isAcqOrPrefetch, i_io_msInfo_0_bits_isAcqOrPrefetch;
  logic g_io_msInfo_0_bits_isPrefetch, i_io_msInfo_0_bits_isPrefetch;
  logic [2:0] g_io_msInfo_0_bits_param, i_io_msInfo_0_bits_param;
  logic g_io_msInfo_0_bits_mergeA, i_io_msInfo_0_bits_mergeA;
  logic g_io_msInfo_0_bits_w_grantfirst, i_io_msInfo_0_bits_w_grantfirst;
  logic g_io_msInfo_0_bits_s_release, i_io_msInfo_0_bits_s_release;
  logic g_io_msInfo_0_bits_s_refill, i_io_msInfo_0_bits_s_refill;
  logic g_io_msInfo_0_bits_s_cmoresp, i_io_msInfo_0_bits_s_cmoresp;
  logic g_io_msInfo_0_bits_s_cmometaw, i_io_msInfo_0_bits_s_cmometaw;
  logic g_io_msInfo_0_bits_w_releaseack, i_io_msInfo_0_bits_w_releaseack;
  logic g_io_msInfo_0_bits_w_replResp, i_io_msInfo_0_bits_w_replResp;
  logic g_io_msInfo_0_bits_w_rprobeacklast, i_io_msInfo_0_bits_w_rprobeacklast;
  logic g_io_msInfo_0_bits_replaceData, i_io_msInfo_0_bits_replaceData;
  logic g_io_msInfo_0_bits_releaseToClean, i_io_msInfo_0_bits_releaseToClean;
  logic g_io_msInfo_1_valid, i_io_msInfo_1_valid;
  logic [2:0] g_io_msInfo_1_bits_channel, i_io_msInfo_1_bits_channel;
  logic [8:0] g_io_msInfo_1_bits_set, i_io_msInfo_1_bits_set;
  logic [2:0] g_io_msInfo_1_bits_way, i_io_msInfo_1_bits_way;
  logic [30:0] g_io_msInfo_1_bits_reqTag, i_io_msInfo_1_bits_reqTag;
  logic g_io_msInfo_1_bits_willFree, i_io_msInfo_1_bits_willFree;
  logic g_io_msInfo_1_bits_aliasTask, i_io_msInfo_1_bits_aliasTask;
  logic g_io_msInfo_1_bits_needRelease, i_io_msInfo_1_bits_needRelease;
  logic g_io_msInfo_1_bits_blockRefill, i_io_msInfo_1_bits_blockRefill;
  logic g_io_msInfo_1_bits_meta_dirty, i_io_msInfo_1_bits_meta_dirty;
  logic [1:0] g_io_msInfo_1_bits_meta_state, i_io_msInfo_1_bits_meta_state;
  logic g_io_msInfo_1_bits_meta_clients, i_io_msInfo_1_bits_meta_clients;
  logic [1:0] g_io_msInfo_1_bits_meta_alias, i_io_msInfo_1_bits_meta_alias;
  logic g_io_msInfo_1_bits_meta_prefetch, i_io_msInfo_1_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_1_bits_meta_prefetchSrc, i_io_msInfo_1_bits_meta_prefetchSrc;
  logic g_io_msInfo_1_bits_meta_accessed, i_io_msInfo_1_bits_meta_accessed;
  logic g_io_msInfo_1_bits_meta_tagErr, i_io_msInfo_1_bits_meta_tagErr;
  logic g_io_msInfo_1_bits_meta_dataErr, i_io_msInfo_1_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_1_bits_metaTag, i_io_msInfo_1_bits_metaTag;
  logic g_io_msInfo_1_bits_dirHit, i_io_msInfo_1_bits_dirHit;
  logic g_io_msInfo_1_bits_isAcqOrPrefetch, i_io_msInfo_1_bits_isAcqOrPrefetch;
  logic g_io_msInfo_1_bits_isPrefetch, i_io_msInfo_1_bits_isPrefetch;
  logic [2:0] g_io_msInfo_1_bits_param, i_io_msInfo_1_bits_param;
  logic g_io_msInfo_1_bits_mergeA, i_io_msInfo_1_bits_mergeA;
  logic g_io_msInfo_1_bits_w_grantfirst, i_io_msInfo_1_bits_w_grantfirst;
  logic g_io_msInfo_1_bits_s_release, i_io_msInfo_1_bits_s_release;
  logic g_io_msInfo_1_bits_s_refill, i_io_msInfo_1_bits_s_refill;
  logic g_io_msInfo_1_bits_s_cmoresp, i_io_msInfo_1_bits_s_cmoresp;
  logic g_io_msInfo_1_bits_s_cmometaw, i_io_msInfo_1_bits_s_cmometaw;
  logic g_io_msInfo_1_bits_w_releaseack, i_io_msInfo_1_bits_w_releaseack;
  logic g_io_msInfo_1_bits_w_replResp, i_io_msInfo_1_bits_w_replResp;
  logic g_io_msInfo_1_bits_w_rprobeacklast, i_io_msInfo_1_bits_w_rprobeacklast;
  logic g_io_msInfo_1_bits_replaceData, i_io_msInfo_1_bits_replaceData;
  logic g_io_msInfo_1_bits_releaseToClean, i_io_msInfo_1_bits_releaseToClean;
  logic g_io_msInfo_2_valid, i_io_msInfo_2_valid;
  logic [2:0] g_io_msInfo_2_bits_channel, i_io_msInfo_2_bits_channel;
  logic [8:0] g_io_msInfo_2_bits_set, i_io_msInfo_2_bits_set;
  logic [2:0] g_io_msInfo_2_bits_way, i_io_msInfo_2_bits_way;
  logic [30:0] g_io_msInfo_2_bits_reqTag, i_io_msInfo_2_bits_reqTag;
  logic g_io_msInfo_2_bits_willFree, i_io_msInfo_2_bits_willFree;
  logic g_io_msInfo_2_bits_aliasTask, i_io_msInfo_2_bits_aliasTask;
  logic g_io_msInfo_2_bits_needRelease, i_io_msInfo_2_bits_needRelease;
  logic g_io_msInfo_2_bits_blockRefill, i_io_msInfo_2_bits_blockRefill;
  logic g_io_msInfo_2_bits_meta_dirty, i_io_msInfo_2_bits_meta_dirty;
  logic [1:0] g_io_msInfo_2_bits_meta_state, i_io_msInfo_2_bits_meta_state;
  logic g_io_msInfo_2_bits_meta_clients, i_io_msInfo_2_bits_meta_clients;
  logic [1:0] g_io_msInfo_2_bits_meta_alias, i_io_msInfo_2_bits_meta_alias;
  logic g_io_msInfo_2_bits_meta_prefetch, i_io_msInfo_2_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_2_bits_meta_prefetchSrc, i_io_msInfo_2_bits_meta_prefetchSrc;
  logic g_io_msInfo_2_bits_meta_accessed, i_io_msInfo_2_bits_meta_accessed;
  logic g_io_msInfo_2_bits_meta_tagErr, i_io_msInfo_2_bits_meta_tagErr;
  logic g_io_msInfo_2_bits_meta_dataErr, i_io_msInfo_2_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_2_bits_metaTag, i_io_msInfo_2_bits_metaTag;
  logic g_io_msInfo_2_bits_dirHit, i_io_msInfo_2_bits_dirHit;
  logic g_io_msInfo_2_bits_isAcqOrPrefetch, i_io_msInfo_2_bits_isAcqOrPrefetch;
  logic g_io_msInfo_2_bits_isPrefetch, i_io_msInfo_2_bits_isPrefetch;
  logic [2:0] g_io_msInfo_2_bits_param, i_io_msInfo_2_bits_param;
  logic g_io_msInfo_2_bits_mergeA, i_io_msInfo_2_bits_mergeA;
  logic g_io_msInfo_2_bits_w_grantfirst, i_io_msInfo_2_bits_w_grantfirst;
  logic g_io_msInfo_2_bits_s_release, i_io_msInfo_2_bits_s_release;
  logic g_io_msInfo_2_bits_s_refill, i_io_msInfo_2_bits_s_refill;
  logic g_io_msInfo_2_bits_s_cmoresp, i_io_msInfo_2_bits_s_cmoresp;
  logic g_io_msInfo_2_bits_s_cmometaw, i_io_msInfo_2_bits_s_cmometaw;
  logic g_io_msInfo_2_bits_w_releaseack, i_io_msInfo_2_bits_w_releaseack;
  logic g_io_msInfo_2_bits_w_replResp, i_io_msInfo_2_bits_w_replResp;
  logic g_io_msInfo_2_bits_w_rprobeacklast, i_io_msInfo_2_bits_w_rprobeacklast;
  logic g_io_msInfo_2_bits_replaceData, i_io_msInfo_2_bits_replaceData;
  logic g_io_msInfo_2_bits_releaseToClean, i_io_msInfo_2_bits_releaseToClean;
  logic g_io_msInfo_3_valid, i_io_msInfo_3_valid;
  logic [2:0] g_io_msInfo_3_bits_channel, i_io_msInfo_3_bits_channel;
  logic [8:0] g_io_msInfo_3_bits_set, i_io_msInfo_3_bits_set;
  logic [2:0] g_io_msInfo_3_bits_way, i_io_msInfo_3_bits_way;
  logic [30:0] g_io_msInfo_3_bits_reqTag, i_io_msInfo_3_bits_reqTag;
  logic g_io_msInfo_3_bits_willFree, i_io_msInfo_3_bits_willFree;
  logic g_io_msInfo_3_bits_aliasTask, i_io_msInfo_3_bits_aliasTask;
  logic g_io_msInfo_3_bits_needRelease, i_io_msInfo_3_bits_needRelease;
  logic g_io_msInfo_3_bits_blockRefill, i_io_msInfo_3_bits_blockRefill;
  logic g_io_msInfo_3_bits_meta_dirty, i_io_msInfo_3_bits_meta_dirty;
  logic [1:0] g_io_msInfo_3_bits_meta_state, i_io_msInfo_3_bits_meta_state;
  logic g_io_msInfo_3_bits_meta_clients, i_io_msInfo_3_bits_meta_clients;
  logic [1:0] g_io_msInfo_3_bits_meta_alias, i_io_msInfo_3_bits_meta_alias;
  logic g_io_msInfo_3_bits_meta_prefetch, i_io_msInfo_3_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_3_bits_meta_prefetchSrc, i_io_msInfo_3_bits_meta_prefetchSrc;
  logic g_io_msInfo_3_bits_meta_accessed, i_io_msInfo_3_bits_meta_accessed;
  logic g_io_msInfo_3_bits_meta_tagErr, i_io_msInfo_3_bits_meta_tagErr;
  logic g_io_msInfo_3_bits_meta_dataErr, i_io_msInfo_3_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_3_bits_metaTag, i_io_msInfo_3_bits_metaTag;
  logic g_io_msInfo_3_bits_dirHit, i_io_msInfo_3_bits_dirHit;
  logic g_io_msInfo_3_bits_isAcqOrPrefetch, i_io_msInfo_3_bits_isAcqOrPrefetch;
  logic g_io_msInfo_3_bits_isPrefetch, i_io_msInfo_3_bits_isPrefetch;
  logic [2:0] g_io_msInfo_3_bits_param, i_io_msInfo_3_bits_param;
  logic g_io_msInfo_3_bits_mergeA, i_io_msInfo_3_bits_mergeA;
  logic g_io_msInfo_3_bits_w_grantfirst, i_io_msInfo_3_bits_w_grantfirst;
  logic g_io_msInfo_3_bits_s_release, i_io_msInfo_3_bits_s_release;
  logic g_io_msInfo_3_bits_s_refill, i_io_msInfo_3_bits_s_refill;
  logic g_io_msInfo_3_bits_s_cmoresp, i_io_msInfo_3_bits_s_cmoresp;
  logic g_io_msInfo_3_bits_s_cmometaw, i_io_msInfo_3_bits_s_cmometaw;
  logic g_io_msInfo_3_bits_w_releaseack, i_io_msInfo_3_bits_w_releaseack;
  logic g_io_msInfo_3_bits_w_replResp, i_io_msInfo_3_bits_w_replResp;
  logic g_io_msInfo_3_bits_w_rprobeacklast, i_io_msInfo_3_bits_w_rprobeacklast;
  logic g_io_msInfo_3_bits_replaceData, i_io_msInfo_3_bits_replaceData;
  logic g_io_msInfo_3_bits_releaseToClean, i_io_msInfo_3_bits_releaseToClean;
  logic g_io_msInfo_4_valid, i_io_msInfo_4_valid;
  logic [2:0] g_io_msInfo_4_bits_channel, i_io_msInfo_4_bits_channel;
  logic [8:0] g_io_msInfo_4_bits_set, i_io_msInfo_4_bits_set;
  logic [2:0] g_io_msInfo_4_bits_way, i_io_msInfo_4_bits_way;
  logic [30:0] g_io_msInfo_4_bits_reqTag, i_io_msInfo_4_bits_reqTag;
  logic g_io_msInfo_4_bits_willFree, i_io_msInfo_4_bits_willFree;
  logic g_io_msInfo_4_bits_aliasTask, i_io_msInfo_4_bits_aliasTask;
  logic g_io_msInfo_4_bits_needRelease, i_io_msInfo_4_bits_needRelease;
  logic g_io_msInfo_4_bits_blockRefill, i_io_msInfo_4_bits_blockRefill;
  logic g_io_msInfo_4_bits_meta_dirty, i_io_msInfo_4_bits_meta_dirty;
  logic [1:0] g_io_msInfo_4_bits_meta_state, i_io_msInfo_4_bits_meta_state;
  logic g_io_msInfo_4_bits_meta_clients, i_io_msInfo_4_bits_meta_clients;
  logic [1:0] g_io_msInfo_4_bits_meta_alias, i_io_msInfo_4_bits_meta_alias;
  logic g_io_msInfo_4_bits_meta_prefetch, i_io_msInfo_4_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_4_bits_meta_prefetchSrc, i_io_msInfo_4_bits_meta_prefetchSrc;
  logic g_io_msInfo_4_bits_meta_accessed, i_io_msInfo_4_bits_meta_accessed;
  logic g_io_msInfo_4_bits_meta_tagErr, i_io_msInfo_4_bits_meta_tagErr;
  logic g_io_msInfo_4_bits_meta_dataErr, i_io_msInfo_4_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_4_bits_metaTag, i_io_msInfo_4_bits_metaTag;
  logic g_io_msInfo_4_bits_dirHit, i_io_msInfo_4_bits_dirHit;
  logic g_io_msInfo_4_bits_isAcqOrPrefetch, i_io_msInfo_4_bits_isAcqOrPrefetch;
  logic g_io_msInfo_4_bits_isPrefetch, i_io_msInfo_4_bits_isPrefetch;
  logic [2:0] g_io_msInfo_4_bits_param, i_io_msInfo_4_bits_param;
  logic g_io_msInfo_4_bits_mergeA, i_io_msInfo_4_bits_mergeA;
  logic g_io_msInfo_4_bits_w_grantfirst, i_io_msInfo_4_bits_w_grantfirst;
  logic g_io_msInfo_4_bits_s_release, i_io_msInfo_4_bits_s_release;
  logic g_io_msInfo_4_bits_s_refill, i_io_msInfo_4_bits_s_refill;
  logic g_io_msInfo_4_bits_s_cmoresp, i_io_msInfo_4_bits_s_cmoresp;
  logic g_io_msInfo_4_bits_s_cmometaw, i_io_msInfo_4_bits_s_cmometaw;
  logic g_io_msInfo_4_bits_w_releaseack, i_io_msInfo_4_bits_w_releaseack;
  logic g_io_msInfo_4_bits_w_replResp, i_io_msInfo_4_bits_w_replResp;
  logic g_io_msInfo_4_bits_w_rprobeacklast, i_io_msInfo_4_bits_w_rprobeacklast;
  logic g_io_msInfo_4_bits_replaceData, i_io_msInfo_4_bits_replaceData;
  logic g_io_msInfo_4_bits_releaseToClean, i_io_msInfo_4_bits_releaseToClean;
  logic g_io_msInfo_5_valid, i_io_msInfo_5_valid;
  logic [2:0] g_io_msInfo_5_bits_channel, i_io_msInfo_5_bits_channel;
  logic [8:0] g_io_msInfo_5_bits_set, i_io_msInfo_5_bits_set;
  logic [2:0] g_io_msInfo_5_bits_way, i_io_msInfo_5_bits_way;
  logic [30:0] g_io_msInfo_5_bits_reqTag, i_io_msInfo_5_bits_reqTag;
  logic g_io_msInfo_5_bits_willFree, i_io_msInfo_5_bits_willFree;
  logic g_io_msInfo_5_bits_aliasTask, i_io_msInfo_5_bits_aliasTask;
  logic g_io_msInfo_5_bits_needRelease, i_io_msInfo_5_bits_needRelease;
  logic g_io_msInfo_5_bits_blockRefill, i_io_msInfo_5_bits_blockRefill;
  logic g_io_msInfo_5_bits_meta_dirty, i_io_msInfo_5_bits_meta_dirty;
  logic [1:0] g_io_msInfo_5_bits_meta_state, i_io_msInfo_5_bits_meta_state;
  logic g_io_msInfo_5_bits_meta_clients, i_io_msInfo_5_bits_meta_clients;
  logic [1:0] g_io_msInfo_5_bits_meta_alias, i_io_msInfo_5_bits_meta_alias;
  logic g_io_msInfo_5_bits_meta_prefetch, i_io_msInfo_5_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_5_bits_meta_prefetchSrc, i_io_msInfo_5_bits_meta_prefetchSrc;
  logic g_io_msInfo_5_bits_meta_accessed, i_io_msInfo_5_bits_meta_accessed;
  logic g_io_msInfo_5_bits_meta_tagErr, i_io_msInfo_5_bits_meta_tagErr;
  logic g_io_msInfo_5_bits_meta_dataErr, i_io_msInfo_5_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_5_bits_metaTag, i_io_msInfo_5_bits_metaTag;
  logic g_io_msInfo_5_bits_dirHit, i_io_msInfo_5_bits_dirHit;
  logic g_io_msInfo_5_bits_isAcqOrPrefetch, i_io_msInfo_5_bits_isAcqOrPrefetch;
  logic g_io_msInfo_5_bits_isPrefetch, i_io_msInfo_5_bits_isPrefetch;
  logic [2:0] g_io_msInfo_5_bits_param, i_io_msInfo_5_bits_param;
  logic g_io_msInfo_5_bits_mergeA, i_io_msInfo_5_bits_mergeA;
  logic g_io_msInfo_5_bits_w_grantfirst, i_io_msInfo_5_bits_w_grantfirst;
  logic g_io_msInfo_5_bits_s_release, i_io_msInfo_5_bits_s_release;
  logic g_io_msInfo_5_bits_s_refill, i_io_msInfo_5_bits_s_refill;
  logic g_io_msInfo_5_bits_s_cmoresp, i_io_msInfo_5_bits_s_cmoresp;
  logic g_io_msInfo_5_bits_s_cmometaw, i_io_msInfo_5_bits_s_cmometaw;
  logic g_io_msInfo_5_bits_w_releaseack, i_io_msInfo_5_bits_w_releaseack;
  logic g_io_msInfo_5_bits_w_replResp, i_io_msInfo_5_bits_w_replResp;
  logic g_io_msInfo_5_bits_w_rprobeacklast, i_io_msInfo_5_bits_w_rprobeacklast;
  logic g_io_msInfo_5_bits_replaceData, i_io_msInfo_5_bits_replaceData;
  logic g_io_msInfo_5_bits_releaseToClean, i_io_msInfo_5_bits_releaseToClean;
  logic g_io_msInfo_6_valid, i_io_msInfo_6_valid;
  logic [2:0] g_io_msInfo_6_bits_channel, i_io_msInfo_6_bits_channel;
  logic [8:0] g_io_msInfo_6_bits_set, i_io_msInfo_6_bits_set;
  logic [2:0] g_io_msInfo_6_bits_way, i_io_msInfo_6_bits_way;
  logic [30:0] g_io_msInfo_6_bits_reqTag, i_io_msInfo_6_bits_reqTag;
  logic g_io_msInfo_6_bits_willFree, i_io_msInfo_6_bits_willFree;
  logic g_io_msInfo_6_bits_aliasTask, i_io_msInfo_6_bits_aliasTask;
  logic g_io_msInfo_6_bits_needRelease, i_io_msInfo_6_bits_needRelease;
  logic g_io_msInfo_6_bits_blockRefill, i_io_msInfo_6_bits_blockRefill;
  logic g_io_msInfo_6_bits_meta_dirty, i_io_msInfo_6_bits_meta_dirty;
  logic [1:0] g_io_msInfo_6_bits_meta_state, i_io_msInfo_6_bits_meta_state;
  logic g_io_msInfo_6_bits_meta_clients, i_io_msInfo_6_bits_meta_clients;
  logic [1:0] g_io_msInfo_6_bits_meta_alias, i_io_msInfo_6_bits_meta_alias;
  logic g_io_msInfo_6_bits_meta_prefetch, i_io_msInfo_6_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_6_bits_meta_prefetchSrc, i_io_msInfo_6_bits_meta_prefetchSrc;
  logic g_io_msInfo_6_bits_meta_accessed, i_io_msInfo_6_bits_meta_accessed;
  logic g_io_msInfo_6_bits_meta_tagErr, i_io_msInfo_6_bits_meta_tagErr;
  logic g_io_msInfo_6_bits_meta_dataErr, i_io_msInfo_6_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_6_bits_metaTag, i_io_msInfo_6_bits_metaTag;
  logic g_io_msInfo_6_bits_dirHit, i_io_msInfo_6_bits_dirHit;
  logic g_io_msInfo_6_bits_isAcqOrPrefetch, i_io_msInfo_6_bits_isAcqOrPrefetch;
  logic g_io_msInfo_6_bits_isPrefetch, i_io_msInfo_6_bits_isPrefetch;
  logic [2:0] g_io_msInfo_6_bits_param, i_io_msInfo_6_bits_param;
  logic g_io_msInfo_6_bits_mergeA, i_io_msInfo_6_bits_mergeA;
  logic g_io_msInfo_6_bits_w_grantfirst, i_io_msInfo_6_bits_w_grantfirst;
  logic g_io_msInfo_6_bits_s_release, i_io_msInfo_6_bits_s_release;
  logic g_io_msInfo_6_bits_s_refill, i_io_msInfo_6_bits_s_refill;
  logic g_io_msInfo_6_bits_s_cmoresp, i_io_msInfo_6_bits_s_cmoresp;
  logic g_io_msInfo_6_bits_s_cmometaw, i_io_msInfo_6_bits_s_cmometaw;
  logic g_io_msInfo_6_bits_w_releaseack, i_io_msInfo_6_bits_w_releaseack;
  logic g_io_msInfo_6_bits_w_replResp, i_io_msInfo_6_bits_w_replResp;
  logic g_io_msInfo_6_bits_w_rprobeacklast, i_io_msInfo_6_bits_w_rprobeacklast;
  logic g_io_msInfo_6_bits_replaceData, i_io_msInfo_6_bits_replaceData;
  logic g_io_msInfo_6_bits_releaseToClean, i_io_msInfo_6_bits_releaseToClean;
  logic g_io_msInfo_7_valid, i_io_msInfo_7_valid;
  logic [2:0] g_io_msInfo_7_bits_channel, i_io_msInfo_7_bits_channel;
  logic [8:0] g_io_msInfo_7_bits_set, i_io_msInfo_7_bits_set;
  logic [2:0] g_io_msInfo_7_bits_way, i_io_msInfo_7_bits_way;
  logic [30:0] g_io_msInfo_7_bits_reqTag, i_io_msInfo_7_bits_reqTag;
  logic g_io_msInfo_7_bits_willFree, i_io_msInfo_7_bits_willFree;
  logic g_io_msInfo_7_bits_aliasTask, i_io_msInfo_7_bits_aliasTask;
  logic g_io_msInfo_7_bits_needRelease, i_io_msInfo_7_bits_needRelease;
  logic g_io_msInfo_7_bits_blockRefill, i_io_msInfo_7_bits_blockRefill;
  logic g_io_msInfo_7_bits_meta_dirty, i_io_msInfo_7_bits_meta_dirty;
  logic [1:0] g_io_msInfo_7_bits_meta_state, i_io_msInfo_7_bits_meta_state;
  logic g_io_msInfo_7_bits_meta_clients, i_io_msInfo_7_bits_meta_clients;
  logic [1:0] g_io_msInfo_7_bits_meta_alias, i_io_msInfo_7_bits_meta_alias;
  logic g_io_msInfo_7_bits_meta_prefetch, i_io_msInfo_7_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_7_bits_meta_prefetchSrc, i_io_msInfo_7_bits_meta_prefetchSrc;
  logic g_io_msInfo_7_bits_meta_accessed, i_io_msInfo_7_bits_meta_accessed;
  logic g_io_msInfo_7_bits_meta_tagErr, i_io_msInfo_7_bits_meta_tagErr;
  logic g_io_msInfo_7_bits_meta_dataErr, i_io_msInfo_7_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_7_bits_metaTag, i_io_msInfo_7_bits_metaTag;
  logic g_io_msInfo_7_bits_dirHit, i_io_msInfo_7_bits_dirHit;
  logic g_io_msInfo_7_bits_isAcqOrPrefetch, i_io_msInfo_7_bits_isAcqOrPrefetch;
  logic g_io_msInfo_7_bits_isPrefetch, i_io_msInfo_7_bits_isPrefetch;
  logic [2:0] g_io_msInfo_7_bits_param, i_io_msInfo_7_bits_param;
  logic g_io_msInfo_7_bits_mergeA, i_io_msInfo_7_bits_mergeA;
  logic g_io_msInfo_7_bits_w_grantfirst, i_io_msInfo_7_bits_w_grantfirst;
  logic g_io_msInfo_7_bits_s_release, i_io_msInfo_7_bits_s_release;
  logic g_io_msInfo_7_bits_s_refill, i_io_msInfo_7_bits_s_refill;
  logic g_io_msInfo_7_bits_s_cmoresp, i_io_msInfo_7_bits_s_cmoresp;
  logic g_io_msInfo_7_bits_s_cmometaw, i_io_msInfo_7_bits_s_cmometaw;
  logic g_io_msInfo_7_bits_w_releaseack, i_io_msInfo_7_bits_w_releaseack;
  logic g_io_msInfo_7_bits_w_replResp, i_io_msInfo_7_bits_w_replResp;
  logic g_io_msInfo_7_bits_w_rprobeacklast, i_io_msInfo_7_bits_w_rprobeacklast;
  logic g_io_msInfo_7_bits_replaceData, i_io_msInfo_7_bits_replaceData;
  logic g_io_msInfo_7_bits_releaseToClean, i_io_msInfo_7_bits_releaseToClean;
  logic g_io_msInfo_8_valid, i_io_msInfo_8_valid;
  logic [2:0] g_io_msInfo_8_bits_channel, i_io_msInfo_8_bits_channel;
  logic [8:0] g_io_msInfo_8_bits_set, i_io_msInfo_8_bits_set;
  logic [2:0] g_io_msInfo_8_bits_way, i_io_msInfo_8_bits_way;
  logic [30:0] g_io_msInfo_8_bits_reqTag, i_io_msInfo_8_bits_reqTag;
  logic g_io_msInfo_8_bits_willFree, i_io_msInfo_8_bits_willFree;
  logic g_io_msInfo_8_bits_aliasTask, i_io_msInfo_8_bits_aliasTask;
  logic g_io_msInfo_8_bits_needRelease, i_io_msInfo_8_bits_needRelease;
  logic g_io_msInfo_8_bits_blockRefill, i_io_msInfo_8_bits_blockRefill;
  logic g_io_msInfo_8_bits_meta_dirty, i_io_msInfo_8_bits_meta_dirty;
  logic [1:0] g_io_msInfo_8_bits_meta_state, i_io_msInfo_8_bits_meta_state;
  logic g_io_msInfo_8_bits_meta_clients, i_io_msInfo_8_bits_meta_clients;
  logic [1:0] g_io_msInfo_8_bits_meta_alias, i_io_msInfo_8_bits_meta_alias;
  logic g_io_msInfo_8_bits_meta_prefetch, i_io_msInfo_8_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_8_bits_meta_prefetchSrc, i_io_msInfo_8_bits_meta_prefetchSrc;
  logic g_io_msInfo_8_bits_meta_accessed, i_io_msInfo_8_bits_meta_accessed;
  logic g_io_msInfo_8_bits_meta_tagErr, i_io_msInfo_8_bits_meta_tagErr;
  logic g_io_msInfo_8_bits_meta_dataErr, i_io_msInfo_8_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_8_bits_metaTag, i_io_msInfo_8_bits_metaTag;
  logic g_io_msInfo_8_bits_dirHit, i_io_msInfo_8_bits_dirHit;
  logic g_io_msInfo_8_bits_isAcqOrPrefetch, i_io_msInfo_8_bits_isAcqOrPrefetch;
  logic g_io_msInfo_8_bits_isPrefetch, i_io_msInfo_8_bits_isPrefetch;
  logic [2:0] g_io_msInfo_8_bits_param, i_io_msInfo_8_bits_param;
  logic g_io_msInfo_8_bits_mergeA, i_io_msInfo_8_bits_mergeA;
  logic g_io_msInfo_8_bits_w_grantfirst, i_io_msInfo_8_bits_w_grantfirst;
  logic g_io_msInfo_8_bits_s_release, i_io_msInfo_8_bits_s_release;
  logic g_io_msInfo_8_bits_s_refill, i_io_msInfo_8_bits_s_refill;
  logic g_io_msInfo_8_bits_s_cmoresp, i_io_msInfo_8_bits_s_cmoresp;
  logic g_io_msInfo_8_bits_s_cmometaw, i_io_msInfo_8_bits_s_cmometaw;
  logic g_io_msInfo_8_bits_w_releaseack, i_io_msInfo_8_bits_w_releaseack;
  logic g_io_msInfo_8_bits_w_replResp, i_io_msInfo_8_bits_w_replResp;
  logic g_io_msInfo_8_bits_w_rprobeacklast, i_io_msInfo_8_bits_w_rprobeacklast;
  logic g_io_msInfo_8_bits_replaceData, i_io_msInfo_8_bits_replaceData;
  logic g_io_msInfo_8_bits_releaseToClean, i_io_msInfo_8_bits_releaseToClean;
  logic g_io_msInfo_9_valid, i_io_msInfo_9_valid;
  logic [2:0] g_io_msInfo_9_bits_channel, i_io_msInfo_9_bits_channel;
  logic [8:0] g_io_msInfo_9_bits_set, i_io_msInfo_9_bits_set;
  logic [2:0] g_io_msInfo_9_bits_way, i_io_msInfo_9_bits_way;
  logic [30:0] g_io_msInfo_9_bits_reqTag, i_io_msInfo_9_bits_reqTag;
  logic g_io_msInfo_9_bits_willFree, i_io_msInfo_9_bits_willFree;
  logic g_io_msInfo_9_bits_aliasTask, i_io_msInfo_9_bits_aliasTask;
  logic g_io_msInfo_9_bits_needRelease, i_io_msInfo_9_bits_needRelease;
  logic g_io_msInfo_9_bits_blockRefill, i_io_msInfo_9_bits_blockRefill;
  logic g_io_msInfo_9_bits_meta_dirty, i_io_msInfo_9_bits_meta_dirty;
  logic [1:0] g_io_msInfo_9_bits_meta_state, i_io_msInfo_9_bits_meta_state;
  logic g_io_msInfo_9_bits_meta_clients, i_io_msInfo_9_bits_meta_clients;
  logic [1:0] g_io_msInfo_9_bits_meta_alias, i_io_msInfo_9_bits_meta_alias;
  logic g_io_msInfo_9_bits_meta_prefetch, i_io_msInfo_9_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_9_bits_meta_prefetchSrc, i_io_msInfo_9_bits_meta_prefetchSrc;
  logic g_io_msInfo_9_bits_meta_accessed, i_io_msInfo_9_bits_meta_accessed;
  logic g_io_msInfo_9_bits_meta_tagErr, i_io_msInfo_9_bits_meta_tagErr;
  logic g_io_msInfo_9_bits_meta_dataErr, i_io_msInfo_9_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_9_bits_metaTag, i_io_msInfo_9_bits_metaTag;
  logic g_io_msInfo_9_bits_dirHit, i_io_msInfo_9_bits_dirHit;
  logic g_io_msInfo_9_bits_isAcqOrPrefetch, i_io_msInfo_9_bits_isAcqOrPrefetch;
  logic g_io_msInfo_9_bits_isPrefetch, i_io_msInfo_9_bits_isPrefetch;
  logic [2:0] g_io_msInfo_9_bits_param, i_io_msInfo_9_bits_param;
  logic g_io_msInfo_9_bits_mergeA, i_io_msInfo_9_bits_mergeA;
  logic g_io_msInfo_9_bits_w_grantfirst, i_io_msInfo_9_bits_w_grantfirst;
  logic g_io_msInfo_9_bits_s_release, i_io_msInfo_9_bits_s_release;
  logic g_io_msInfo_9_bits_s_refill, i_io_msInfo_9_bits_s_refill;
  logic g_io_msInfo_9_bits_s_cmoresp, i_io_msInfo_9_bits_s_cmoresp;
  logic g_io_msInfo_9_bits_s_cmometaw, i_io_msInfo_9_bits_s_cmometaw;
  logic g_io_msInfo_9_bits_w_releaseack, i_io_msInfo_9_bits_w_releaseack;
  logic g_io_msInfo_9_bits_w_replResp, i_io_msInfo_9_bits_w_replResp;
  logic g_io_msInfo_9_bits_w_rprobeacklast, i_io_msInfo_9_bits_w_rprobeacklast;
  logic g_io_msInfo_9_bits_replaceData, i_io_msInfo_9_bits_replaceData;
  logic g_io_msInfo_9_bits_releaseToClean, i_io_msInfo_9_bits_releaseToClean;
  logic g_io_msInfo_10_valid, i_io_msInfo_10_valid;
  logic [2:0] g_io_msInfo_10_bits_channel, i_io_msInfo_10_bits_channel;
  logic [8:0] g_io_msInfo_10_bits_set, i_io_msInfo_10_bits_set;
  logic [2:0] g_io_msInfo_10_bits_way, i_io_msInfo_10_bits_way;
  logic [30:0] g_io_msInfo_10_bits_reqTag, i_io_msInfo_10_bits_reqTag;
  logic g_io_msInfo_10_bits_willFree, i_io_msInfo_10_bits_willFree;
  logic g_io_msInfo_10_bits_aliasTask, i_io_msInfo_10_bits_aliasTask;
  logic g_io_msInfo_10_bits_needRelease, i_io_msInfo_10_bits_needRelease;
  logic g_io_msInfo_10_bits_blockRefill, i_io_msInfo_10_bits_blockRefill;
  logic g_io_msInfo_10_bits_meta_dirty, i_io_msInfo_10_bits_meta_dirty;
  logic [1:0] g_io_msInfo_10_bits_meta_state, i_io_msInfo_10_bits_meta_state;
  logic g_io_msInfo_10_bits_meta_clients, i_io_msInfo_10_bits_meta_clients;
  logic [1:0] g_io_msInfo_10_bits_meta_alias, i_io_msInfo_10_bits_meta_alias;
  logic g_io_msInfo_10_bits_meta_prefetch, i_io_msInfo_10_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_10_bits_meta_prefetchSrc, i_io_msInfo_10_bits_meta_prefetchSrc;
  logic g_io_msInfo_10_bits_meta_accessed, i_io_msInfo_10_bits_meta_accessed;
  logic g_io_msInfo_10_bits_meta_tagErr, i_io_msInfo_10_bits_meta_tagErr;
  logic g_io_msInfo_10_bits_meta_dataErr, i_io_msInfo_10_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_10_bits_metaTag, i_io_msInfo_10_bits_metaTag;
  logic g_io_msInfo_10_bits_dirHit, i_io_msInfo_10_bits_dirHit;
  logic g_io_msInfo_10_bits_isAcqOrPrefetch, i_io_msInfo_10_bits_isAcqOrPrefetch;
  logic g_io_msInfo_10_bits_isPrefetch, i_io_msInfo_10_bits_isPrefetch;
  logic [2:0] g_io_msInfo_10_bits_param, i_io_msInfo_10_bits_param;
  logic g_io_msInfo_10_bits_mergeA, i_io_msInfo_10_bits_mergeA;
  logic g_io_msInfo_10_bits_w_grantfirst, i_io_msInfo_10_bits_w_grantfirst;
  logic g_io_msInfo_10_bits_s_release, i_io_msInfo_10_bits_s_release;
  logic g_io_msInfo_10_bits_s_refill, i_io_msInfo_10_bits_s_refill;
  logic g_io_msInfo_10_bits_s_cmoresp, i_io_msInfo_10_bits_s_cmoresp;
  logic g_io_msInfo_10_bits_s_cmometaw, i_io_msInfo_10_bits_s_cmometaw;
  logic g_io_msInfo_10_bits_w_releaseack, i_io_msInfo_10_bits_w_releaseack;
  logic g_io_msInfo_10_bits_w_replResp, i_io_msInfo_10_bits_w_replResp;
  logic g_io_msInfo_10_bits_w_rprobeacklast, i_io_msInfo_10_bits_w_rprobeacklast;
  logic g_io_msInfo_10_bits_replaceData, i_io_msInfo_10_bits_replaceData;
  logic g_io_msInfo_10_bits_releaseToClean, i_io_msInfo_10_bits_releaseToClean;
  logic g_io_msInfo_11_valid, i_io_msInfo_11_valid;
  logic [2:0] g_io_msInfo_11_bits_channel, i_io_msInfo_11_bits_channel;
  logic [8:0] g_io_msInfo_11_bits_set, i_io_msInfo_11_bits_set;
  logic [2:0] g_io_msInfo_11_bits_way, i_io_msInfo_11_bits_way;
  logic [30:0] g_io_msInfo_11_bits_reqTag, i_io_msInfo_11_bits_reqTag;
  logic g_io_msInfo_11_bits_willFree, i_io_msInfo_11_bits_willFree;
  logic g_io_msInfo_11_bits_aliasTask, i_io_msInfo_11_bits_aliasTask;
  logic g_io_msInfo_11_bits_needRelease, i_io_msInfo_11_bits_needRelease;
  logic g_io_msInfo_11_bits_blockRefill, i_io_msInfo_11_bits_blockRefill;
  logic g_io_msInfo_11_bits_meta_dirty, i_io_msInfo_11_bits_meta_dirty;
  logic [1:0] g_io_msInfo_11_bits_meta_state, i_io_msInfo_11_bits_meta_state;
  logic g_io_msInfo_11_bits_meta_clients, i_io_msInfo_11_bits_meta_clients;
  logic [1:0] g_io_msInfo_11_bits_meta_alias, i_io_msInfo_11_bits_meta_alias;
  logic g_io_msInfo_11_bits_meta_prefetch, i_io_msInfo_11_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_11_bits_meta_prefetchSrc, i_io_msInfo_11_bits_meta_prefetchSrc;
  logic g_io_msInfo_11_bits_meta_accessed, i_io_msInfo_11_bits_meta_accessed;
  logic g_io_msInfo_11_bits_meta_tagErr, i_io_msInfo_11_bits_meta_tagErr;
  logic g_io_msInfo_11_bits_meta_dataErr, i_io_msInfo_11_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_11_bits_metaTag, i_io_msInfo_11_bits_metaTag;
  logic g_io_msInfo_11_bits_dirHit, i_io_msInfo_11_bits_dirHit;
  logic g_io_msInfo_11_bits_isAcqOrPrefetch, i_io_msInfo_11_bits_isAcqOrPrefetch;
  logic g_io_msInfo_11_bits_isPrefetch, i_io_msInfo_11_bits_isPrefetch;
  logic [2:0] g_io_msInfo_11_bits_param, i_io_msInfo_11_bits_param;
  logic g_io_msInfo_11_bits_mergeA, i_io_msInfo_11_bits_mergeA;
  logic g_io_msInfo_11_bits_w_grantfirst, i_io_msInfo_11_bits_w_grantfirst;
  logic g_io_msInfo_11_bits_s_release, i_io_msInfo_11_bits_s_release;
  logic g_io_msInfo_11_bits_s_refill, i_io_msInfo_11_bits_s_refill;
  logic g_io_msInfo_11_bits_s_cmoresp, i_io_msInfo_11_bits_s_cmoresp;
  logic g_io_msInfo_11_bits_s_cmometaw, i_io_msInfo_11_bits_s_cmometaw;
  logic g_io_msInfo_11_bits_w_releaseack, i_io_msInfo_11_bits_w_releaseack;
  logic g_io_msInfo_11_bits_w_replResp, i_io_msInfo_11_bits_w_replResp;
  logic g_io_msInfo_11_bits_w_rprobeacklast, i_io_msInfo_11_bits_w_rprobeacklast;
  logic g_io_msInfo_11_bits_replaceData, i_io_msInfo_11_bits_replaceData;
  logic g_io_msInfo_11_bits_releaseToClean, i_io_msInfo_11_bits_releaseToClean;
  logic g_io_msInfo_12_valid, i_io_msInfo_12_valid;
  logic [2:0] g_io_msInfo_12_bits_channel, i_io_msInfo_12_bits_channel;
  logic [8:0] g_io_msInfo_12_bits_set, i_io_msInfo_12_bits_set;
  logic [2:0] g_io_msInfo_12_bits_way, i_io_msInfo_12_bits_way;
  logic [30:0] g_io_msInfo_12_bits_reqTag, i_io_msInfo_12_bits_reqTag;
  logic g_io_msInfo_12_bits_willFree, i_io_msInfo_12_bits_willFree;
  logic g_io_msInfo_12_bits_aliasTask, i_io_msInfo_12_bits_aliasTask;
  logic g_io_msInfo_12_bits_needRelease, i_io_msInfo_12_bits_needRelease;
  logic g_io_msInfo_12_bits_blockRefill, i_io_msInfo_12_bits_blockRefill;
  logic g_io_msInfo_12_bits_meta_dirty, i_io_msInfo_12_bits_meta_dirty;
  logic [1:0] g_io_msInfo_12_bits_meta_state, i_io_msInfo_12_bits_meta_state;
  logic g_io_msInfo_12_bits_meta_clients, i_io_msInfo_12_bits_meta_clients;
  logic [1:0] g_io_msInfo_12_bits_meta_alias, i_io_msInfo_12_bits_meta_alias;
  logic g_io_msInfo_12_bits_meta_prefetch, i_io_msInfo_12_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_12_bits_meta_prefetchSrc, i_io_msInfo_12_bits_meta_prefetchSrc;
  logic g_io_msInfo_12_bits_meta_accessed, i_io_msInfo_12_bits_meta_accessed;
  logic g_io_msInfo_12_bits_meta_tagErr, i_io_msInfo_12_bits_meta_tagErr;
  logic g_io_msInfo_12_bits_meta_dataErr, i_io_msInfo_12_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_12_bits_metaTag, i_io_msInfo_12_bits_metaTag;
  logic g_io_msInfo_12_bits_dirHit, i_io_msInfo_12_bits_dirHit;
  logic g_io_msInfo_12_bits_isAcqOrPrefetch, i_io_msInfo_12_bits_isAcqOrPrefetch;
  logic g_io_msInfo_12_bits_isPrefetch, i_io_msInfo_12_bits_isPrefetch;
  logic [2:0] g_io_msInfo_12_bits_param, i_io_msInfo_12_bits_param;
  logic g_io_msInfo_12_bits_mergeA, i_io_msInfo_12_bits_mergeA;
  logic g_io_msInfo_12_bits_w_grantfirst, i_io_msInfo_12_bits_w_grantfirst;
  logic g_io_msInfo_12_bits_s_release, i_io_msInfo_12_bits_s_release;
  logic g_io_msInfo_12_bits_s_refill, i_io_msInfo_12_bits_s_refill;
  logic g_io_msInfo_12_bits_s_cmoresp, i_io_msInfo_12_bits_s_cmoresp;
  logic g_io_msInfo_12_bits_s_cmometaw, i_io_msInfo_12_bits_s_cmometaw;
  logic g_io_msInfo_12_bits_w_releaseack, i_io_msInfo_12_bits_w_releaseack;
  logic g_io_msInfo_12_bits_w_replResp, i_io_msInfo_12_bits_w_replResp;
  logic g_io_msInfo_12_bits_w_rprobeacklast, i_io_msInfo_12_bits_w_rprobeacklast;
  logic g_io_msInfo_12_bits_replaceData, i_io_msInfo_12_bits_replaceData;
  logic g_io_msInfo_12_bits_releaseToClean, i_io_msInfo_12_bits_releaseToClean;
  logic g_io_msInfo_13_valid, i_io_msInfo_13_valid;
  logic [2:0] g_io_msInfo_13_bits_channel, i_io_msInfo_13_bits_channel;
  logic [8:0] g_io_msInfo_13_bits_set, i_io_msInfo_13_bits_set;
  logic [2:0] g_io_msInfo_13_bits_way, i_io_msInfo_13_bits_way;
  logic [30:0] g_io_msInfo_13_bits_reqTag, i_io_msInfo_13_bits_reqTag;
  logic g_io_msInfo_13_bits_willFree, i_io_msInfo_13_bits_willFree;
  logic g_io_msInfo_13_bits_aliasTask, i_io_msInfo_13_bits_aliasTask;
  logic g_io_msInfo_13_bits_needRelease, i_io_msInfo_13_bits_needRelease;
  logic g_io_msInfo_13_bits_blockRefill, i_io_msInfo_13_bits_blockRefill;
  logic g_io_msInfo_13_bits_meta_dirty, i_io_msInfo_13_bits_meta_dirty;
  logic [1:0] g_io_msInfo_13_bits_meta_state, i_io_msInfo_13_bits_meta_state;
  logic g_io_msInfo_13_bits_meta_clients, i_io_msInfo_13_bits_meta_clients;
  logic [1:0] g_io_msInfo_13_bits_meta_alias, i_io_msInfo_13_bits_meta_alias;
  logic g_io_msInfo_13_bits_meta_prefetch, i_io_msInfo_13_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_13_bits_meta_prefetchSrc, i_io_msInfo_13_bits_meta_prefetchSrc;
  logic g_io_msInfo_13_bits_meta_accessed, i_io_msInfo_13_bits_meta_accessed;
  logic g_io_msInfo_13_bits_meta_tagErr, i_io_msInfo_13_bits_meta_tagErr;
  logic g_io_msInfo_13_bits_meta_dataErr, i_io_msInfo_13_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_13_bits_metaTag, i_io_msInfo_13_bits_metaTag;
  logic g_io_msInfo_13_bits_dirHit, i_io_msInfo_13_bits_dirHit;
  logic g_io_msInfo_13_bits_isAcqOrPrefetch, i_io_msInfo_13_bits_isAcqOrPrefetch;
  logic g_io_msInfo_13_bits_isPrefetch, i_io_msInfo_13_bits_isPrefetch;
  logic [2:0] g_io_msInfo_13_bits_param, i_io_msInfo_13_bits_param;
  logic g_io_msInfo_13_bits_mergeA, i_io_msInfo_13_bits_mergeA;
  logic g_io_msInfo_13_bits_w_grantfirst, i_io_msInfo_13_bits_w_grantfirst;
  logic g_io_msInfo_13_bits_s_release, i_io_msInfo_13_bits_s_release;
  logic g_io_msInfo_13_bits_s_refill, i_io_msInfo_13_bits_s_refill;
  logic g_io_msInfo_13_bits_s_cmoresp, i_io_msInfo_13_bits_s_cmoresp;
  logic g_io_msInfo_13_bits_s_cmometaw, i_io_msInfo_13_bits_s_cmometaw;
  logic g_io_msInfo_13_bits_w_releaseack, i_io_msInfo_13_bits_w_releaseack;
  logic g_io_msInfo_13_bits_w_replResp, i_io_msInfo_13_bits_w_replResp;
  logic g_io_msInfo_13_bits_w_rprobeacklast, i_io_msInfo_13_bits_w_rprobeacklast;
  logic g_io_msInfo_13_bits_replaceData, i_io_msInfo_13_bits_replaceData;
  logic g_io_msInfo_13_bits_releaseToClean, i_io_msInfo_13_bits_releaseToClean;
  logic g_io_msInfo_14_valid, i_io_msInfo_14_valid;
  logic [2:0] g_io_msInfo_14_bits_channel, i_io_msInfo_14_bits_channel;
  logic [8:0] g_io_msInfo_14_bits_set, i_io_msInfo_14_bits_set;
  logic [2:0] g_io_msInfo_14_bits_way, i_io_msInfo_14_bits_way;
  logic [30:0] g_io_msInfo_14_bits_reqTag, i_io_msInfo_14_bits_reqTag;
  logic g_io_msInfo_14_bits_willFree, i_io_msInfo_14_bits_willFree;
  logic g_io_msInfo_14_bits_aliasTask, i_io_msInfo_14_bits_aliasTask;
  logic g_io_msInfo_14_bits_needRelease, i_io_msInfo_14_bits_needRelease;
  logic g_io_msInfo_14_bits_blockRefill, i_io_msInfo_14_bits_blockRefill;
  logic g_io_msInfo_14_bits_meta_dirty, i_io_msInfo_14_bits_meta_dirty;
  logic [1:0] g_io_msInfo_14_bits_meta_state, i_io_msInfo_14_bits_meta_state;
  logic g_io_msInfo_14_bits_meta_clients, i_io_msInfo_14_bits_meta_clients;
  logic [1:0] g_io_msInfo_14_bits_meta_alias, i_io_msInfo_14_bits_meta_alias;
  logic g_io_msInfo_14_bits_meta_prefetch, i_io_msInfo_14_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_14_bits_meta_prefetchSrc, i_io_msInfo_14_bits_meta_prefetchSrc;
  logic g_io_msInfo_14_bits_meta_accessed, i_io_msInfo_14_bits_meta_accessed;
  logic g_io_msInfo_14_bits_meta_tagErr, i_io_msInfo_14_bits_meta_tagErr;
  logic g_io_msInfo_14_bits_meta_dataErr, i_io_msInfo_14_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_14_bits_metaTag, i_io_msInfo_14_bits_metaTag;
  logic g_io_msInfo_14_bits_dirHit, i_io_msInfo_14_bits_dirHit;
  logic g_io_msInfo_14_bits_isAcqOrPrefetch, i_io_msInfo_14_bits_isAcqOrPrefetch;
  logic g_io_msInfo_14_bits_isPrefetch, i_io_msInfo_14_bits_isPrefetch;
  logic [2:0] g_io_msInfo_14_bits_param, i_io_msInfo_14_bits_param;
  logic g_io_msInfo_14_bits_mergeA, i_io_msInfo_14_bits_mergeA;
  logic g_io_msInfo_14_bits_w_grantfirst, i_io_msInfo_14_bits_w_grantfirst;
  logic g_io_msInfo_14_bits_s_release, i_io_msInfo_14_bits_s_release;
  logic g_io_msInfo_14_bits_s_refill, i_io_msInfo_14_bits_s_refill;
  logic g_io_msInfo_14_bits_s_cmoresp, i_io_msInfo_14_bits_s_cmoresp;
  logic g_io_msInfo_14_bits_s_cmometaw, i_io_msInfo_14_bits_s_cmometaw;
  logic g_io_msInfo_14_bits_w_releaseack, i_io_msInfo_14_bits_w_releaseack;
  logic g_io_msInfo_14_bits_w_replResp, i_io_msInfo_14_bits_w_replResp;
  logic g_io_msInfo_14_bits_w_rprobeacklast, i_io_msInfo_14_bits_w_rprobeacklast;
  logic g_io_msInfo_14_bits_replaceData, i_io_msInfo_14_bits_replaceData;
  logic g_io_msInfo_14_bits_releaseToClean, i_io_msInfo_14_bits_releaseToClean;
  logic g_io_msInfo_15_valid, i_io_msInfo_15_valid;
  logic [2:0] g_io_msInfo_15_bits_channel, i_io_msInfo_15_bits_channel;
  logic [8:0] g_io_msInfo_15_bits_set, i_io_msInfo_15_bits_set;
  logic [2:0] g_io_msInfo_15_bits_way, i_io_msInfo_15_bits_way;
  logic [30:0] g_io_msInfo_15_bits_reqTag, i_io_msInfo_15_bits_reqTag;
  logic g_io_msInfo_15_bits_willFree, i_io_msInfo_15_bits_willFree;
  logic g_io_msInfo_15_bits_aliasTask, i_io_msInfo_15_bits_aliasTask;
  logic g_io_msInfo_15_bits_needRelease, i_io_msInfo_15_bits_needRelease;
  logic g_io_msInfo_15_bits_blockRefill, i_io_msInfo_15_bits_blockRefill;
  logic g_io_msInfo_15_bits_meta_dirty, i_io_msInfo_15_bits_meta_dirty;
  logic [1:0] g_io_msInfo_15_bits_meta_state, i_io_msInfo_15_bits_meta_state;
  logic g_io_msInfo_15_bits_meta_clients, i_io_msInfo_15_bits_meta_clients;
  logic [1:0] g_io_msInfo_15_bits_meta_alias, i_io_msInfo_15_bits_meta_alias;
  logic g_io_msInfo_15_bits_meta_prefetch, i_io_msInfo_15_bits_meta_prefetch;
  logic [2:0] g_io_msInfo_15_bits_meta_prefetchSrc, i_io_msInfo_15_bits_meta_prefetchSrc;
  logic g_io_msInfo_15_bits_meta_accessed, i_io_msInfo_15_bits_meta_accessed;
  logic g_io_msInfo_15_bits_meta_tagErr, i_io_msInfo_15_bits_meta_tagErr;
  logic g_io_msInfo_15_bits_meta_dataErr, i_io_msInfo_15_bits_meta_dataErr;
  logic [30:0] g_io_msInfo_15_bits_metaTag, i_io_msInfo_15_bits_metaTag;
  logic g_io_msInfo_15_bits_dirHit, i_io_msInfo_15_bits_dirHit;
  logic g_io_msInfo_15_bits_isAcqOrPrefetch, i_io_msInfo_15_bits_isAcqOrPrefetch;
  logic g_io_msInfo_15_bits_isPrefetch, i_io_msInfo_15_bits_isPrefetch;
  logic [2:0] g_io_msInfo_15_bits_param, i_io_msInfo_15_bits_param;
  logic g_io_msInfo_15_bits_mergeA, i_io_msInfo_15_bits_mergeA;
  logic g_io_msInfo_15_bits_w_grantfirst, i_io_msInfo_15_bits_w_grantfirst;
  logic g_io_msInfo_15_bits_s_release, i_io_msInfo_15_bits_s_release;
  logic g_io_msInfo_15_bits_s_refill, i_io_msInfo_15_bits_s_refill;
  logic g_io_msInfo_15_bits_s_cmoresp, i_io_msInfo_15_bits_s_cmoresp;
  logic g_io_msInfo_15_bits_s_cmometaw, i_io_msInfo_15_bits_s_cmometaw;
  logic g_io_msInfo_15_bits_w_releaseack, i_io_msInfo_15_bits_w_releaseack;
  logic g_io_msInfo_15_bits_w_replResp, i_io_msInfo_15_bits_w_replResp;
  logic g_io_msInfo_15_bits_w_rprobeacklast, i_io_msInfo_15_bits_w_rprobeacklast;
  logic g_io_msInfo_15_bits_replaceData, i_io_msInfo_15_bits_replaceData;
  logic g_io_msInfo_15_bits_releaseToClean, i_io_msInfo_15_bits_releaseToClean;
  logic g_io_msStatus_0_valid, i_io_msStatus_0_valid;
  logic [2:0] g_io_msStatus_0_bits_channel, i_io_msStatus_0_bits_channel;
  logic [8:0] g_io_msStatus_0_bits_set, i_io_msStatus_0_bits_set;
  logic [30:0] g_io_msStatus_0_bits_reqTag, i_io_msStatus_0_bits_reqTag;
  logic g_io_msStatus_0_bits_is_miss, i_io_msStatus_0_bits_is_miss;
  logic g_io_msStatus_0_bits_is_prefetch, i_io_msStatus_0_bits_is_prefetch;
  logic g_io_msStatus_1_valid, i_io_msStatus_1_valid;
  logic [2:0] g_io_msStatus_1_bits_channel, i_io_msStatus_1_bits_channel;
  logic [8:0] g_io_msStatus_1_bits_set, i_io_msStatus_1_bits_set;
  logic [30:0] g_io_msStatus_1_bits_reqTag, i_io_msStatus_1_bits_reqTag;
  logic g_io_msStatus_1_bits_is_miss, i_io_msStatus_1_bits_is_miss;
  logic g_io_msStatus_1_bits_is_prefetch, i_io_msStatus_1_bits_is_prefetch;
  logic g_io_msStatus_2_valid, i_io_msStatus_2_valid;
  logic [2:0] g_io_msStatus_2_bits_channel, i_io_msStatus_2_bits_channel;
  logic [8:0] g_io_msStatus_2_bits_set, i_io_msStatus_2_bits_set;
  logic [30:0] g_io_msStatus_2_bits_reqTag, i_io_msStatus_2_bits_reqTag;
  logic g_io_msStatus_2_bits_is_miss, i_io_msStatus_2_bits_is_miss;
  logic g_io_msStatus_2_bits_is_prefetch, i_io_msStatus_2_bits_is_prefetch;
  logic g_io_msStatus_3_valid, i_io_msStatus_3_valid;
  logic [2:0] g_io_msStatus_3_bits_channel, i_io_msStatus_3_bits_channel;
  logic [8:0] g_io_msStatus_3_bits_set, i_io_msStatus_3_bits_set;
  logic [30:0] g_io_msStatus_3_bits_reqTag, i_io_msStatus_3_bits_reqTag;
  logic g_io_msStatus_3_bits_is_miss, i_io_msStatus_3_bits_is_miss;
  logic g_io_msStatus_3_bits_is_prefetch, i_io_msStatus_3_bits_is_prefetch;
  logic g_io_msStatus_4_valid, i_io_msStatus_4_valid;
  logic [2:0] g_io_msStatus_4_bits_channel, i_io_msStatus_4_bits_channel;
  logic [8:0] g_io_msStatus_4_bits_set, i_io_msStatus_4_bits_set;
  logic [30:0] g_io_msStatus_4_bits_reqTag, i_io_msStatus_4_bits_reqTag;
  logic g_io_msStatus_4_bits_is_miss, i_io_msStatus_4_bits_is_miss;
  logic g_io_msStatus_4_bits_is_prefetch, i_io_msStatus_4_bits_is_prefetch;
  logic g_io_msStatus_5_valid, i_io_msStatus_5_valid;
  logic [2:0] g_io_msStatus_5_bits_channel, i_io_msStatus_5_bits_channel;
  logic [8:0] g_io_msStatus_5_bits_set, i_io_msStatus_5_bits_set;
  logic [30:0] g_io_msStatus_5_bits_reqTag, i_io_msStatus_5_bits_reqTag;
  logic g_io_msStatus_5_bits_is_miss, i_io_msStatus_5_bits_is_miss;
  logic g_io_msStatus_5_bits_is_prefetch, i_io_msStatus_5_bits_is_prefetch;
  logic g_io_msStatus_6_valid, i_io_msStatus_6_valid;
  logic [2:0] g_io_msStatus_6_bits_channel, i_io_msStatus_6_bits_channel;
  logic [8:0] g_io_msStatus_6_bits_set, i_io_msStatus_6_bits_set;
  logic [30:0] g_io_msStatus_6_bits_reqTag, i_io_msStatus_6_bits_reqTag;
  logic g_io_msStatus_6_bits_is_miss, i_io_msStatus_6_bits_is_miss;
  logic g_io_msStatus_6_bits_is_prefetch, i_io_msStatus_6_bits_is_prefetch;
  logic g_io_msStatus_7_valid, i_io_msStatus_7_valid;
  logic [2:0] g_io_msStatus_7_bits_channel, i_io_msStatus_7_bits_channel;
  logic [8:0] g_io_msStatus_7_bits_set, i_io_msStatus_7_bits_set;
  logic [30:0] g_io_msStatus_7_bits_reqTag, i_io_msStatus_7_bits_reqTag;
  logic g_io_msStatus_7_bits_is_miss, i_io_msStatus_7_bits_is_miss;
  logic g_io_msStatus_7_bits_is_prefetch, i_io_msStatus_7_bits_is_prefetch;
  logic g_io_msStatus_8_valid, i_io_msStatus_8_valid;
  logic [2:0] g_io_msStatus_8_bits_channel, i_io_msStatus_8_bits_channel;
  logic [8:0] g_io_msStatus_8_bits_set, i_io_msStatus_8_bits_set;
  logic [30:0] g_io_msStatus_8_bits_reqTag, i_io_msStatus_8_bits_reqTag;
  logic g_io_msStatus_8_bits_is_miss, i_io_msStatus_8_bits_is_miss;
  logic g_io_msStatus_8_bits_is_prefetch, i_io_msStatus_8_bits_is_prefetch;
  logic g_io_msStatus_9_valid, i_io_msStatus_9_valid;
  logic [2:0] g_io_msStatus_9_bits_channel, i_io_msStatus_9_bits_channel;
  logic [8:0] g_io_msStatus_9_bits_set, i_io_msStatus_9_bits_set;
  logic [30:0] g_io_msStatus_9_bits_reqTag, i_io_msStatus_9_bits_reqTag;
  logic g_io_msStatus_9_bits_is_miss, i_io_msStatus_9_bits_is_miss;
  logic g_io_msStatus_9_bits_is_prefetch, i_io_msStatus_9_bits_is_prefetch;
  logic g_io_msStatus_10_valid, i_io_msStatus_10_valid;
  logic [2:0] g_io_msStatus_10_bits_channel, i_io_msStatus_10_bits_channel;
  logic [8:0] g_io_msStatus_10_bits_set, i_io_msStatus_10_bits_set;
  logic [30:0] g_io_msStatus_10_bits_reqTag, i_io_msStatus_10_bits_reqTag;
  logic g_io_msStatus_10_bits_is_miss, i_io_msStatus_10_bits_is_miss;
  logic g_io_msStatus_10_bits_is_prefetch, i_io_msStatus_10_bits_is_prefetch;
  logic g_io_msStatus_11_valid, i_io_msStatus_11_valid;
  logic [2:0] g_io_msStatus_11_bits_channel, i_io_msStatus_11_bits_channel;
  logic [8:0] g_io_msStatus_11_bits_set, i_io_msStatus_11_bits_set;
  logic [30:0] g_io_msStatus_11_bits_reqTag, i_io_msStatus_11_bits_reqTag;
  logic g_io_msStatus_11_bits_is_miss, i_io_msStatus_11_bits_is_miss;
  logic g_io_msStatus_11_bits_is_prefetch, i_io_msStatus_11_bits_is_prefetch;
  logic g_io_msStatus_12_valid, i_io_msStatus_12_valid;
  logic [2:0] g_io_msStatus_12_bits_channel, i_io_msStatus_12_bits_channel;
  logic [8:0] g_io_msStatus_12_bits_set, i_io_msStatus_12_bits_set;
  logic [30:0] g_io_msStatus_12_bits_reqTag, i_io_msStatus_12_bits_reqTag;
  logic g_io_msStatus_12_bits_is_miss, i_io_msStatus_12_bits_is_miss;
  logic g_io_msStatus_12_bits_is_prefetch, i_io_msStatus_12_bits_is_prefetch;
  logic g_io_msStatus_13_valid, i_io_msStatus_13_valid;
  logic [2:0] g_io_msStatus_13_bits_channel, i_io_msStatus_13_bits_channel;
  logic [8:0] g_io_msStatus_13_bits_set, i_io_msStatus_13_bits_set;
  logic [30:0] g_io_msStatus_13_bits_reqTag, i_io_msStatus_13_bits_reqTag;
  logic g_io_msStatus_13_bits_is_miss, i_io_msStatus_13_bits_is_miss;
  logic g_io_msStatus_13_bits_is_prefetch, i_io_msStatus_13_bits_is_prefetch;
  logic g_io_msStatus_14_valid, i_io_msStatus_14_valid;
  logic [2:0] g_io_msStatus_14_bits_channel, i_io_msStatus_14_bits_channel;
  logic [8:0] g_io_msStatus_14_bits_set, i_io_msStatus_14_bits_set;
  logic [30:0] g_io_msStatus_14_bits_reqTag, i_io_msStatus_14_bits_reqTag;
  logic g_io_msStatus_14_bits_is_miss, i_io_msStatus_14_bits_is_miss;
  logic g_io_msStatus_14_bits_is_prefetch, i_io_msStatus_14_bits_is_prefetch;
  logic g_io_msStatus_15_valid, i_io_msStatus_15_valid;
  logic [2:0] g_io_msStatus_15_bits_channel, i_io_msStatus_15_bits_channel;
  logic [8:0] g_io_msStatus_15_bits_set, i_io_msStatus_15_bits_set;
  logic [30:0] g_io_msStatus_15_bits_reqTag, i_io_msStatus_15_bits_reqTag;
  logic g_io_msStatus_15_bits_is_miss, i_io_msStatus_15_bits_is_miss;
  logic g_io_msStatus_15_bits_is_prefetch, i_io_msStatus_15_bits_is_prefetch;
  logic g_io_msAlloc_0_valid, i_io_msAlloc_0_valid;
  logic [2:0] g_io_msAlloc_0_bits_channel, i_io_msAlloc_0_bits_channel;
  logic g_io_msAlloc_0_bits_is_miss, i_io_msAlloc_0_bits_is_miss;
  logic g_io_msAlloc_0_bits_is_prefetch, i_io_msAlloc_0_bits_is_prefetch;
  logic g_io_msAlloc_1_valid, i_io_msAlloc_1_valid;
  logic [2:0] g_io_msAlloc_1_bits_channel, i_io_msAlloc_1_bits_channel;
  logic g_io_msAlloc_1_bits_is_miss, i_io_msAlloc_1_bits_is_miss;
  logic g_io_msAlloc_1_bits_is_prefetch, i_io_msAlloc_1_bits_is_prefetch;
  logic g_io_msAlloc_2_valid, i_io_msAlloc_2_valid;
  logic [2:0] g_io_msAlloc_2_bits_channel, i_io_msAlloc_2_bits_channel;
  logic g_io_msAlloc_2_bits_is_miss, i_io_msAlloc_2_bits_is_miss;
  logic g_io_msAlloc_2_bits_is_prefetch, i_io_msAlloc_2_bits_is_prefetch;
  logic g_io_msAlloc_3_valid, i_io_msAlloc_3_valid;
  logic [2:0] g_io_msAlloc_3_bits_channel, i_io_msAlloc_3_bits_channel;
  logic g_io_msAlloc_3_bits_is_miss, i_io_msAlloc_3_bits_is_miss;
  logic g_io_msAlloc_3_bits_is_prefetch, i_io_msAlloc_3_bits_is_prefetch;
  logic g_io_msAlloc_4_valid, i_io_msAlloc_4_valid;
  logic [2:0] g_io_msAlloc_4_bits_channel, i_io_msAlloc_4_bits_channel;
  logic g_io_msAlloc_4_bits_is_miss, i_io_msAlloc_4_bits_is_miss;
  logic g_io_msAlloc_4_bits_is_prefetch, i_io_msAlloc_4_bits_is_prefetch;
  logic g_io_msAlloc_5_valid, i_io_msAlloc_5_valid;
  logic [2:0] g_io_msAlloc_5_bits_channel, i_io_msAlloc_5_bits_channel;
  logic g_io_msAlloc_5_bits_is_miss, i_io_msAlloc_5_bits_is_miss;
  logic g_io_msAlloc_5_bits_is_prefetch, i_io_msAlloc_5_bits_is_prefetch;
  logic g_io_msAlloc_6_valid, i_io_msAlloc_6_valid;
  logic [2:0] g_io_msAlloc_6_bits_channel, i_io_msAlloc_6_bits_channel;
  logic g_io_msAlloc_6_bits_is_miss, i_io_msAlloc_6_bits_is_miss;
  logic g_io_msAlloc_6_bits_is_prefetch, i_io_msAlloc_6_bits_is_prefetch;
  logic g_io_msAlloc_7_valid, i_io_msAlloc_7_valid;
  logic [2:0] g_io_msAlloc_7_bits_channel, i_io_msAlloc_7_bits_channel;
  logic g_io_msAlloc_7_bits_is_miss, i_io_msAlloc_7_bits_is_miss;
  logic g_io_msAlloc_7_bits_is_prefetch, i_io_msAlloc_7_bits_is_prefetch;
  logic g_io_msAlloc_8_valid, i_io_msAlloc_8_valid;
  logic [2:0] g_io_msAlloc_8_bits_channel, i_io_msAlloc_8_bits_channel;
  logic g_io_msAlloc_8_bits_is_miss, i_io_msAlloc_8_bits_is_miss;
  logic g_io_msAlloc_8_bits_is_prefetch, i_io_msAlloc_8_bits_is_prefetch;
  logic g_io_msAlloc_9_valid, i_io_msAlloc_9_valid;
  logic [2:0] g_io_msAlloc_9_bits_channel, i_io_msAlloc_9_bits_channel;
  logic g_io_msAlloc_9_bits_is_miss, i_io_msAlloc_9_bits_is_miss;
  logic g_io_msAlloc_9_bits_is_prefetch, i_io_msAlloc_9_bits_is_prefetch;
  logic g_io_msAlloc_10_valid, i_io_msAlloc_10_valid;
  logic [2:0] g_io_msAlloc_10_bits_channel, i_io_msAlloc_10_bits_channel;
  logic g_io_msAlloc_10_bits_is_miss, i_io_msAlloc_10_bits_is_miss;
  logic g_io_msAlloc_10_bits_is_prefetch, i_io_msAlloc_10_bits_is_prefetch;
  logic g_io_msAlloc_11_valid, i_io_msAlloc_11_valid;
  logic [2:0] g_io_msAlloc_11_bits_channel, i_io_msAlloc_11_bits_channel;
  logic g_io_msAlloc_11_bits_is_miss, i_io_msAlloc_11_bits_is_miss;
  logic g_io_msAlloc_11_bits_is_prefetch, i_io_msAlloc_11_bits_is_prefetch;
  logic g_io_msAlloc_12_valid, i_io_msAlloc_12_valid;
  logic [2:0] g_io_msAlloc_12_bits_channel, i_io_msAlloc_12_bits_channel;
  logic g_io_msAlloc_12_bits_is_miss, i_io_msAlloc_12_bits_is_miss;
  logic g_io_msAlloc_12_bits_is_prefetch, i_io_msAlloc_12_bits_is_prefetch;
  logic g_io_msAlloc_13_valid, i_io_msAlloc_13_valid;
  logic [2:0] g_io_msAlloc_13_bits_channel, i_io_msAlloc_13_bits_channel;
  logic g_io_msAlloc_13_bits_is_miss, i_io_msAlloc_13_bits_is_miss;
  logic g_io_msAlloc_13_bits_is_prefetch, i_io_msAlloc_13_bits_is_prefetch;
  logic g_io_msAlloc_14_valid, i_io_msAlloc_14_valid;
  logic [2:0] g_io_msAlloc_14_bits_channel, i_io_msAlloc_14_bits_channel;
  logic g_io_msAlloc_14_bits_is_miss, i_io_msAlloc_14_bits_is_miss;
  logic g_io_msAlloc_14_bits_is_prefetch, i_io_msAlloc_14_bits_is_prefetch;
  logic g_io_msAlloc_15_valid, i_io_msAlloc_15_valid;
  logic [2:0] g_io_msAlloc_15_bits_channel, i_io_msAlloc_15_bits_channel;
  logic g_io_msAlloc_15_bits_is_miss, i_io_msAlloc_15_bits_is_miss;
  logic g_io_msAlloc_15_bits_is_prefetch, i_io_msAlloc_15_bits_is_prefetch;
  logic g_io_pCrd_0_query_valid, i_io_pCrd_0_query_valid;
  logic [3:0] g_io_pCrd_0_query_bits_pCrdType, i_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_0_query_bits_srcID, i_io_pCrd_0_query_bits_srcID;
  logic g_io_pCrd_1_query_valid, i_io_pCrd_1_query_valid;
  logic [3:0] g_io_pCrd_1_query_bits_pCrdType, i_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_1_query_bits_srcID, i_io_pCrd_1_query_bits_srcID;
  logic g_io_pCrd_2_query_valid, i_io_pCrd_2_query_valid;
  logic [3:0] g_io_pCrd_2_query_bits_pCrdType, i_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_2_query_bits_srcID, i_io_pCrd_2_query_bits_srcID;
  logic g_io_pCrd_3_query_valid, i_io_pCrd_3_query_valid;
  logic [3:0] g_io_pCrd_3_query_bits_pCrdType, i_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_3_query_bits_srcID, i_io_pCrd_3_query_bits_srcID;
  logic g_io_pCrd_4_query_valid, i_io_pCrd_4_query_valid;
  logic [3:0] g_io_pCrd_4_query_bits_pCrdType, i_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_4_query_bits_srcID, i_io_pCrd_4_query_bits_srcID;
  logic g_io_pCrd_5_query_valid, i_io_pCrd_5_query_valid;
  logic [3:0] g_io_pCrd_5_query_bits_pCrdType, i_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_5_query_bits_srcID, i_io_pCrd_5_query_bits_srcID;
  logic g_io_pCrd_6_query_valid, i_io_pCrd_6_query_valid;
  logic [3:0] g_io_pCrd_6_query_bits_pCrdType, i_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_6_query_bits_srcID, i_io_pCrd_6_query_bits_srcID;
  logic g_io_pCrd_7_query_valid, i_io_pCrd_7_query_valid;
  logic [3:0] g_io_pCrd_7_query_bits_pCrdType, i_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_7_query_bits_srcID, i_io_pCrd_7_query_bits_srcID;
  logic g_io_pCrd_8_query_valid, i_io_pCrd_8_query_valid;
  logic [3:0] g_io_pCrd_8_query_bits_pCrdType, i_io_pCrd_8_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_8_query_bits_srcID, i_io_pCrd_8_query_bits_srcID;
  logic g_io_pCrd_9_query_valid, i_io_pCrd_9_query_valid;
  logic [3:0] g_io_pCrd_9_query_bits_pCrdType, i_io_pCrd_9_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_9_query_bits_srcID, i_io_pCrd_9_query_bits_srcID;
  logic g_io_pCrd_10_query_valid, i_io_pCrd_10_query_valid;
  logic [3:0] g_io_pCrd_10_query_bits_pCrdType, i_io_pCrd_10_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_10_query_bits_srcID, i_io_pCrd_10_query_bits_srcID;
  logic g_io_pCrd_11_query_valid, i_io_pCrd_11_query_valid;
  logic [3:0] g_io_pCrd_11_query_bits_pCrdType, i_io_pCrd_11_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_11_query_bits_srcID, i_io_pCrd_11_query_bits_srcID;
  logic g_io_pCrd_12_query_valid, i_io_pCrd_12_query_valid;
  logic [3:0] g_io_pCrd_12_query_bits_pCrdType, i_io_pCrd_12_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_12_query_bits_srcID, i_io_pCrd_12_query_bits_srcID;
  logic g_io_pCrd_13_query_valid, i_io_pCrd_13_query_valid;
  logic [3:0] g_io_pCrd_13_query_bits_pCrdType, i_io_pCrd_13_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_13_query_bits_srcID, i_io_pCrd_13_query_bits_srcID;
  logic g_io_pCrd_14_query_valid, i_io_pCrd_14_query_valid;
  logic [3:0] g_io_pCrd_14_query_bits_pCrdType, i_io_pCrd_14_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_14_query_bits_srcID, i_io_pCrd_14_query_bits_srcID;
  logic g_io_pCrd_15_query_valid, i_io_pCrd_15_query_valid;
  logic [3:0] g_io_pCrd_15_query_bits_pCrdType, i_io_pCrd_15_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_15_query_bits_srcID, i_io_pCrd_15_query_bits_srcID;
  logic g_io_l2Miss, i_io_l2Miss;
  logic [5:0] g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0] g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0] g_io_perf_3_value, i_io_perf_3_value;

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
    .io_fromMainPipe_mshr_alloc_s3_bits_task_denied(io_fromMainPipe_mshr_alloc_s3_bits_task_denied),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt(io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt),
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
    .io_releaseBufWriteId(g_io_releaseBufWriteId),
    .io_dsResp_valid(io_dsResp_valid),
    .io_dsResp_bits_mshrId(io_dsResp_bits_mshrId),
    .io_dsResp_bits_dataError(io_dsResp_bits_dataError),
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
    .io_replResp_bits_error(io_replResp_bits_error),
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
    .io_msAlloc_0_valid(g_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(g_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(g_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(g_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(g_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(g_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(g_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(g_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(g_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(g_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(g_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(g_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(g_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(g_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(g_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(g_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(g_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(g_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(g_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(g_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(g_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(g_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(g_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(g_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(g_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(g_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(g_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(g_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(g_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(g_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(g_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(g_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(g_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(g_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(g_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(g_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(g_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(g_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(g_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(g_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(g_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(g_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(g_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(g_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(g_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(g_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(g_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(g_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(g_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(g_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(g_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(g_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(g_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(g_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(g_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(g_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(g_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(g_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(g_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(g_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(g_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(g_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(g_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(g_io_msAlloc_15_bits_is_prefetch),
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
    .io_fromMainPipe_mshr_alloc_s3_bits_task_denied(io_fromMainPipe_mshr_alloc_s3_bits_task_denied),
    .io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt(io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt),
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
    .io_releaseBufWriteId(i_io_releaseBufWriteId),
    .io_dsResp_valid(io_dsResp_valid),
    .io_dsResp_bits_mshrId(io_dsResp_bits_mshrId),
    .io_dsResp_bits_dataError(io_dsResp_bits_dataError),
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
    .io_replResp_bits_error(io_replResp_bits_error),
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
    .io_msAlloc_0_valid(i_io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel(i_io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss(i_io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch(i_io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid(i_io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel(i_io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss(i_io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch(i_io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid(i_io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel(i_io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss(i_io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch(i_io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid(i_io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel(i_io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss(i_io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch(i_io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid(i_io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel(i_io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss(i_io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch(i_io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid(i_io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel(i_io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss(i_io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch(i_io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid(i_io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel(i_io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss(i_io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch(i_io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid(i_io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel(i_io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss(i_io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch(i_io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid(i_io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel(i_io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss(i_io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch(i_io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid(i_io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel(i_io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss(i_io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch(i_io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid(i_io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel(i_io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss(i_io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch(i_io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid(i_io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel(i_io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss(i_io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch(i_io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid(i_io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel(i_io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss(i_io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch(i_io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid(i_io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel(i_io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss(i_io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch(i_io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid(i_io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel(i_io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss(i_io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch(i_io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid(i_io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel(i_io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss(i_io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch(i_io_msAlloc_15_bits_is_prefetch),
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
    io_fromMainPipe_mshr_alloc_s3_valid = ($urandom_range(0, 7) == 0);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag = 31'($urandom_range(0, 3));
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set = 9'($urandom_range(0, 3));
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way = 3'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state = 2'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias = 2'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc = 3'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_release = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct = ($urandom_range(0, 7) != 0);
    io_fromMainPipe_mshr_alloc_s3_bits_task_channel = 3'b1 << $urandom_range(0, 2);
    io_fromMainPipe_mshr_alloc_s3_bits_task_set = 9'($urandom_range(0, 3));
    io_fromMainPipe_mshr_alloc_s3_bits_task_tag = 31'($urandom_range(0, 3));
    io_fromMainPipe_mshr_alloc_s3_bits_task_off = 6'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_alias = 2'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_opcode = pick_a_opcode();
    io_fromMainPipe_mshr_alloc_s3_bits_task_param = 3'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId = 7'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_denied = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_corrupt = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource = 5'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx = 8'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state = 2'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias = 2'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc = 3'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_srcID = 11'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_txnID = 12'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID = 11'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID = 12'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode = $urandom_range(0, 23);
    io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc = 1'($urandom);
    io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag = 1'($urandom);
    io_mshrTask_ready = ($urandom_range(0, 9) < 7);
    io_pipeStatusVec_0_valid = ($urandom_range(0, 3) == 0);
    io_pipeStatusVec_1_valid = ($urandom_range(0, 3) == 0);
    io_toTXREQ_ready = ($urandom_range(0, 9) < 7);
    io_toTXRSP_ready = ($urandom_range(0, 9) < 7);
    io_toSourceB_ready = ($urandom_range(0, 9) < 7);
    io_grantStatus_0_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_0_set = 9'($urandom_range(0, 3));
    io_grantStatus_0_tag = 31'($urandom_range(0, 3));
    io_grantStatus_1_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_1_set = 9'($urandom_range(0, 3));
    io_grantStatus_1_tag = 31'($urandom_range(0, 3));
    io_grantStatus_2_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_2_set = 9'($urandom_range(0, 3));
    io_grantStatus_2_tag = 31'($urandom_range(0, 3));
    io_grantStatus_3_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_3_set = 9'($urandom_range(0, 3));
    io_grantStatus_3_tag = 31'($urandom_range(0, 3));
    io_grantStatus_4_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_4_set = 9'($urandom_range(0, 3));
    io_grantStatus_4_tag = 31'($urandom_range(0, 3));
    io_grantStatus_5_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_5_set = 9'($urandom_range(0, 3));
    io_grantStatus_5_tag = 31'($urandom_range(0, 3));
    io_grantStatus_6_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_6_set = 9'($urandom_range(0, 3));
    io_grantStatus_6_tag = 31'($urandom_range(0, 3));
    io_grantStatus_7_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_7_set = 9'($urandom_range(0, 3));
    io_grantStatus_7_tag = 31'($urandom_range(0, 3));
    io_grantStatus_8_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_8_set = 9'($urandom_range(0, 3));
    io_grantStatus_8_tag = 31'($urandom_range(0, 3));
    io_grantStatus_9_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_9_set = 9'($urandom_range(0, 3));
    io_grantStatus_9_tag = 31'($urandom_range(0, 3));
    io_grantStatus_10_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_10_set = 9'($urandom_range(0, 3));
    io_grantStatus_10_tag = 31'($urandom_range(0, 3));
    io_grantStatus_11_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_11_set = 9'($urandom_range(0, 3));
    io_grantStatus_11_tag = 31'($urandom_range(0, 3));
    io_grantStatus_12_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_12_set = 9'($urandom_range(0, 3));
    io_grantStatus_12_tag = 31'($urandom_range(0, 3));
    io_grantStatus_13_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_13_set = 9'($urandom_range(0, 3));
    io_grantStatus_13_tag = 31'($urandom_range(0, 3));
    io_grantStatus_14_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_14_set = 9'($urandom_range(0, 3));
    io_grantStatus_14_tag = 31'($urandom_range(0, 3));
    io_grantStatus_15_valid = ($urandom_range(0, 3) == 0);
    io_grantStatus_15_set = 9'($urandom_range(0, 3));
    io_grantStatus_15_tag = 31'($urandom_range(0, 3));
    io_resps_sinkC_valid = ($urandom_range(0, 2) == 0);
    io_resps_sinkC_set = 9'($urandom_range(0, 3));
    io_resps_sinkC_tag = 31'($urandom_range(0, 3));
    io_resps_sinkC_respInfo_opcode = pick(3'h4, 3'h5, 3'($urandom));
    io_resps_sinkC_respInfo_param = 3'($urandom);
    io_resps_sinkC_respInfo_last = 1'($urandom);
    io_resps_sinkC_respInfo_denied = 1'($urandom);
    io_resps_sinkC_respInfo_corrupt = 1'($urandom);
    io_resps_rxrsp_valid = ($urandom_range(0, 2) == 0);
    io_resps_rxrsp_mshrId = 8'($urandom_range(0, 16));
    io_resps_rxrsp_respInfo_chiOpcode = pick5(7'hB, 7'h4, 7'h5, 7'h3, 7'($urandom));
    io_resps_rxrsp_respInfo_srcID = 11'($urandom);
    io_resps_rxrsp_respInfo_dbID = 12'($urandom);
    io_resps_rxrsp_respInfo_resp = 3'($urandom);
    io_resps_rxrsp_respInfo_pCrdType = 4'($urandom);
    io_resps_rxrsp_respInfo_respErr = 2'($urandom);
    io_resps_rxrsp_respInfo_traceTag = 1'($urandom);
    io_resps_rxdat_valid = ($urandom_range(0, 2) == 0);
    io_resps_rxdat_mshrId = 8'($urandom_range(0, 16));
    io_resps_rxdat_respInfo_last = 1'($urandom);
    io_resps_rxdat_respInfo_corrupt = 1'($urandom);
    io_resps_rxdat_respInfo_chiOpcode = pick(7'h4, 7'hB, 7'($urandom));
    io_resps_rxdat_respInfo_homeNID = 11'($urandom);
    io_resps_rxdat_respInfo_dbID = 12'($urandom);
    io_resps_rxdat_respInfo_resp = 3'($urandom);
    io_resps_rxdat_respInfo_respErr = 2'($urandom);
    io_resps_rxdat_respInfo_traceTag = 1'($urandom);
    io_dsResp_valid = ($urandom_range(0, 9) == 0);
    io_dsResp_bits_mshrId = 8'($urandom_range(0, 16));
    io_dsResp_bits_dataError = 1'($urandom);
    io_nestedwb_set = 9'($urandom_range(0, 3));
    io_nestedwb_tag = 31'($urandom_range(0, 3));
    io_nestedwb_c_set_dirty = ($urandom_range(0, 7) == 0);
    io_nestedwb_c_set_tip = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_inv_dirty = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_toB = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_toN = ($urandom_range(0, 7) == 0);
    io_nestedwb_b_toClean = ($urandom_range(0, 7) == 0);
    io_nestedwb_denied = ($urandom_range(0, 7) == 0);
    io_nestedwb_corrupt = ($urandom_range(0, 7) == 0);
    io_aMergeTask_valid = ($urandom_range(0, 19) == 0);
    io_aMergeTask_bits_id = 8'($urandom_range(0, 16));
    io_aMergeTask_bits_task_off = 6'($urandom);
    io_aMergeTask_bits_task_alias = 2'($urandom);
    io_aMergeTask_bits_task_vaddr = {$urandom, $urandom};
    io_aMergeTask_bits_task_isKeyword = 1'($urandom);
    io_aMergeTask_bits_task_opcode = 4'($urandom);
    io_aMergeTask_bits_task_param = 3'($urandom);
    io_aMergeTask_bits_task_sourceId = 7'($urandom);
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
    io_replResp_bits_mshrId = 8'($urandom_range(0, 16));
    io_replResp_bits_retry = 1'($urandom);
    io_replResp_bits_error = 1'($urandom);
    io_pCrd_0_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_1_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_2_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_3_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_4_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_5_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_6_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_7_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_8_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_9_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_10_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_11_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_12_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_13_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_14_grant = ($urandom_range(0, 19) == 0);
    io_pCrd_15_grant = ($urandom_range(0, 19) == 0);
    reset = ($urandom_range(0, 4999) == 0);
  endtask

  `define CK(nm) begin checks++; if (g_``nm !== i_``nm) begin errors++; \
    if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, `"nm`", g_``nm, i_``nm); \
    end end
  task automatic check();
    `CK(io_toReqArb_blockA_s1)
    `CK(io_toReqArb_blockB_s1)
    `CK(io_toMainPipe_mshr_alloc_ptr)
    `CK(io_mshrTask_valid)
    `CK(io_mshrTask_bits_channel)
    `CK(io_mshrTask_bits_txChannel)
    `CK(io_mshrTask_bits_set)
    `CK(io_mshrTask_bits_tag)
    `CK(io_mshrTask_bits_off)
    `CK(io_mshrTask_bits_alias)
    `CK(io_mshrTask_bits_isKeyword)
    `CK(io_mshrTask_bits_opcode)
    `CK(io_mshrTask_bits_param)
    `CK(io_mshrTask_bits_size)
    `CK(io_mshrTask_bits_sourceId)
    `CK(io_mshrTask_bits_denied)
    `CK(io_mshrTask_bits_corrupt)
    `CK(io_mshrTask_bits_mshrTask)
    `CK(io_mshrTask_bits_mshrId)
    `CK(io_mshrTask_bits_aliasTask)
    `CK(io_mshrTask_bits_useProbeData)
    `CK(io_mshrTask_bits_mshrRetry)
    `CK(io_mshrTask_bits_readProbeDataDown)
    `CK(io_mshrTask_bits_fromL2pft)
    `CK(io_mshrTask_bits_dirty)
    `CK(io_mshrTask_bits_way)
    `CK(io_mshrTask_bits_meta_dirty)
    `CK(io_mshrTask_bits_meta_state)
    `CK(io_mshrTask_bits_meta_clients)
    `CK(io_mshrTask_bits_meta_alias)
    `CK(io_mshrTask_bits_meta_prefetch)
    `CK(io_mshrTask_bits_meta_prefetchSrc)
    `CK(io_mshrTask_bits_meta_accessed)
    `CK(io_mshrTask_bits_meta_tagErr)
    `CK(io_mshrTask_bits_meta_dataErr)
    `CK(io_mshrTask_bits_metaWen)
    `CK(io_mshrTask_bits_tagWen)
    `CK(io_mshrTask_bits_dsWen)
    `CK(io_mshrTask_bits_replTask)
    `CK(io_mshrTask_bits_cmoTask)
    `CK(io_mshrTask_bits_reqSource)
    `CK(io_mshrTask_bits_mergeA)
    `CK(io_mshrTask_bits_aMergeTask_off)
    `CK(io_mshrTask_bits_aMergeTask_alias)
    `CK(io_mshrTask_bits_aMergeTask_vaddr)
    `CK(io_mshrTask_bits_aMergeTask_isKeyword)
    `CK(io_mshrTask_bits_aMergeTask_opcode)
    `CK(io_mshrTask_bits_aMergeTask_param)
    `CK(io_mshrTask_bits_aMergeTask_sourceId)
    `CK(io_mshrTask_bits_aMergeTask_meta_dirty)
    `CK(io_mshrTask_bits_aMergeTask_meta_state)
    `CK(io_mshrTask_bits_aMergeTask_meta_clients)
    `CK(io_mshrTask_bits_aMergeTask_meta_alias)
    `CK(io_mshrTask_bits_aMergeTask_meta_accessed)
    `CK(io_mshrTask_bits_snpHitRelease)
    `CK(io_mshrTask_bits_snpHitReleaseToInval)
    `CK(io_mshrTask_bits_snpHitReleaseToClean)
    `CK(io_mshrTask_bits_snpHitReleaseWithData)
    `CK(io_mshrTask_bits_snpHitReleaseIdx)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_dirty)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_state)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_clients)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_alias)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_prefetch)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_accessed)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_tagErr)
    `CK(io_mshrTask_bits_snpHitReleaseMeta_dataErr)
    `CK(io_mshrTask_bits_tgtID)
    `CK(io_mshrTask_bits_txnID)
    `CK(io_mshrTask_bits_homeNID)
    `CK(io_mshrTask_bits_dbID)
    `CK(io_mshrTask_bits_chiOpcode)
    `CK(io_mshrTask_bits_resp)
    `CK(io_mshrTask_bits_fwdState)
    `CK(io_mshrTask_bits_retToSrc)
    `CK(io_mshrTask_bits_likelyshared)
    `CK(io_mshrTask_bits_expCompAck)
    `CK(io_mshrTask_bits_allowRetry)
    `CK(io_mshrTask_bits_memAttr_allocate)
    `CK(io_mshrTask_bits_memAttr_cacheable)
    `CK(io_mshrTask_bits_memAttr_ewa)
    `CK(io_mshrTask_bits_traceTag)
    `CK(io_toTXREQ_valid)
    `CK(io_toTXREQ_bits_qos)
    `CK(io_toTXREQ_bits_tgtID)
    `CK(io_toTXREQ_bits_txnID)
    `CK(io_toTXREQ_bits_opcode)
    `CK(io_toTXREQ_bits_size)
    `CK(io_toTXREQ_bits_addr)
    `CK(io_toTXREQ_bits_likelyshared)
    `CK(io_toTXREQ_bits_allowRetry)
    `CK(io_toTXREQ_bits_pCrdType)
    `CK(io_toTXREQ_bits_memAttr_allocate)
    `CK(io_toTXREQ_bits_memAttr_cacheable)
    `CK(io_toTXREQ_bits_memAttr_ewa)
    `CK(io_toTXREQ_bits_snpAttr)
    `CK(io_toTXREQ_bits_expCompAck)
    `CK(io_toTXRSP_valid)
    `CK(io_toTXRSP_bits_tgtID)
    `CK(io_toTXRSP_bits_txnID)
    `CK(io_toTXRSP_bits_opcode)
    `CK(io_toTXRSP_bits_traceTag)
    `CK(io_toSourceB_valid)
    `CK(io_toSourceB_bits_opcode)
    `CK(io_toSourceB_bits_param)
    `CK(io_toSourceB_bits_address)
    `CK(io_toSourceB_bits_data)
    `CK(io_releaseBufWriteId)
    `CK(io_nestedwbDataId_valid)
    `CK(io_nestedwbDataId_bits)
    `CK(io_msInfo_0_valid)
    `CK(io_msInfo_0_bits_channel)
    `CK(io_msInfo_0_bits_set)
    `CK(io_msInfo_0_bits_way)
    `CK(io_msInfo_0_bits_reqTag)
    `CK(io_msInfo_0_bits_willFree)
    `CK(io_msInfo_0_bits_aliasTask)
    `CK(io_msInfo_0_bits_needRelease)
    `CK(io_msInfo_0_bits_blockRefill)
    `CK(io_msInfo_0_bits_meta_dirty)
    `CK(io_msInfo_0_bits_meta_state)
    `CK(io_msInfo_0_bits_meta_clients)
    `CK(io_msInfo_0_bits_meta_alias)
    `CK(io_msInfo_0_bits_meta_prefetch)
    `CK(io_msInfo_0_bits_meta_prefetchSrc)
    `CK(io_msInfo_0_bits_meta_accessed)
    `CK(io_msInfo_0_bits_meta_tagErr)
    `CK(io_msInfo_0_bits_meta_dataErr)
    `CK(io_msInfo_0_bits_metaTag)
    `CK(io_msInfo_0_bits_dirHit)
    `CK(io_msInfo_0_bits_isAcqOrPrefetch)
    `CK(io_msInfo_0_bits_isPrefetch)
    `CK(io_msInfo_0_bits_param)
    `CK(io_msInfo_0_bits_mergeA)
    `CK(io_msInfo_0_bits_w_grantfirst)
    `CK(io_msInfo_0_bits_s_release)
    `CK(io_msInfo_0_bits_s_refill)
    `CK(io_msInfo_0_bits_s_cmoresp)
    `CK(io_msInfo_0_bits_s_cmometaw)
    `CK(io_msInfo_0_bits_w_releaseack)
    `CK(io_msInfo_0_bits_w_replResp)
    `CK(io_msInfo_0_bits_w_rprobeacklast)
    `CK(io_msInfo_0_bits_replaceData)
    `CK(io_msInfo_0_bits_releaseToClean)
    `CK(io_msInfo_1_valid)
    `CK(io_msInfo_1_bits_channel)
    `CK(io_msInfo_1_bits_set)
    `CK(io_msInfo_1_bits_way)
    `CK(io_msInfo_1_bits_reqTag)
    `CK(io_msInfo_1_bits_willFree)
    `CK(io_msInfo_1_bits_aliasTask)
    `CK(io_msInfo_1_bits_needRelease)
    `CK(io_msInfo_1_bits_blockRefill)
    `CK(io_msInfo_1_bits_meta_dirty)
    `CK(io_msInfo_1_bits_meta_state)
    `CK(io_msInfo_1_bits_meta_clients)
    `CK(io_msInfo_1_bits_meta_alias)
    `CK(io_msInfo_1_bits_meta_prefetch)
    `CK(io_msInfo_1_bits_meta_prefetchSrc)
    `CK(io_msInfo_1_bits_meta_accessed)
    `CK(io_msInfo_1_bits_meta_tagErr)
    `CK(io_msInfo_1_bits_meta_dataErr)
    `CK(io_msInfo_1_bits_metaTag)
    `CK(io_msInfo_1_bits_dirHit)
    `CK(io_msInfo_1_bits_isAcqOrPrefetch)
    `CK(io_msInfo_1_bits_isPrefetch)
    `CK(io_msInfo_1_bits_param)
    `CK(io_msInfo_1_bits_mergeA)
    `CK(io_msInfo_1_bits_w_grantfirst)
    `CK(io_msInfo_1_bits_s_release)
    `CK(io_msInfo_1_bits_s_refill)
    `CK(io_msInfo_1_bits_s_cmoresp)
    `CK(io_msInfo_1_bits_s_cmometaw)
    `CK(io_msInfo_1_bits_w_releaseack)
    `CK(io_msInfo_1_bits_w_replResp)
    `CK(io_msInfo_1_bits_w_rprobeacklast)
    `CK(io_msInfo_1_bits_replaceData)
    `CK(io_msInfo_1_bits_releaseToClean)
    `CK(io_msInfo_2_valid)
    `CK(io_msInfo_2_bits_channel)
    `CK(io_msInfo_2_bits_set)
    `CK(io_msInfo_2_bits_way)
    `CK(io_msInfo_2_bits_reqTag)
    `CK(io_msInfo_2_bits_willFree)
    `CK(io_msInfo_2_bits_aliasTask)
    `CK(io_msInfo_2_bits_needRelease)
    `CK(io_msInfo_2_bits_blockRefill)
    `CK(io_msInfo_2_bits_meta_dirty)
    `CK(io_msInfo_2_bits_meta_state)
    `CK(io_msInfo_2_bits_meta_clients)
    `CK(io_msInfo_2_bits_meta_alias)
    `CK(io_msInfo_2_bits_meta_prefetch)
    `CK(io_msInfo_2_bits_meta_prefetchSrc)
    `CK(io_msInfo_2_bits_meta_accessed)
    `CK(io_msInfo_2_bits_meta_tagErr)
    `CK(io_msInfo_2_bits_meta_dataErr)
    `CK(io_msInfo_2_bits_metaTag)
    `CK(io_msInfo_2_bits_dirHit)
    `CK(io_msInfo_2_bits_isAcqOrPrefetch)
    `CK(io_msInfo_2_bits_isPrefetch)
    `CK(io_msInfo_2_bits_param)
    `CK(io_msInfo_2_bits_mergeA)
    `CK(io_msInfo_2_bits_w_grantfirst)
    `CK(io_msInfo_2_bits_s_release)
    `CK(io_msInfo_2_bits_s_refill)
    `CK(io_msInfo_2_bits_s_cmoresp)
    `CK(io_msInfo_2_bits_s_cmometaw)
    `CK(io_msInfo_2_bits_w_releaseack)
    `CK(io_msInfo_2_bits_w_replResp)
    `CK(io_msInfo_2_bits_w_rprobeacklast)
    `CK(io_msInfo_2_bits_replaceData)
    `CK(io_msInfo_2_bits_releaseToClean)
    `CK(io_msInfo_3_valid)
    `CK(io_msInfo_3_bits_channel)
    `CK(io_msInfo_3_bits_set)
    `CK(io_msInfo_3_bits_way)
    `CK(io_msInfo_3_bits_reqTag)
    `CK(io_msInfo_3_bits_willFree)
    `CK(io_msInfo_3_bits_aliasTask)
    `CK(io_msInfo_3_bits_needRelease)
    `CK(io_msInfo_3_bits_blockRefill)
    `CK(io_msInfo_3_bits_meta_dirty)
    `CK(io_msInfo_3_bits_meta_state)
    `CK(io_msInfo_3_bits_meta_clients)
    `CK(io_msInfo_3_bits_meta_alias)
    `CK(io_msInfo_3_bits_meta_prefetch)
    `CK(io_msInfo_3_bits_meta_prefetchSrc)
    `CK(io_msInfo_3_bits_meta_accessed)
    `CK(io_msInfo_3_bits_meta_tagErr)
    `CK(io_msInfo_3_bits_meta_dataErr)
    `CK(io_msInfo_3_bits_metaTag)
    `CK(io_msInfo_3_bits_dirHit)
    `CK(io_msInfo_3_bits_isAcqOrPrefetch)
    `CK(io_msInfo_3_bits_isPrefetch)
    `CK(io_msInfo_3_bits_param)
    `CK(io_msInfo_3_bits_mergeA)
    `CK(io_msInfo_3_bits_w_grantfirst)
    `CK(io_msInfo_3_bits_s_release)
    `CK(io_msInfo_3_bits_s_refill)
    `CK(io_msInfo_3_bits_s_cmoresp)
    `CK(io_msInfo_3_bits_s_cmometaw)
    `CK(io_msInfo_3_bits_w_releaseack)
    `CK(io_msInfo_3_bits_w_replResp)
    `CK(io_msInfo_3_bits_w_rprobeacklast)
    `CK(io_msInfo_3_bits_replaceData)
    `CK(io_msInfo_3_bits_releaseToClean)
    `CK(io_msInfo_4_valid)
    `CK(io_msInfo_4_bits_channel)
    `CK(io_msInfo_4_bits_set)
    `CK(io_msInfo_4_bits_way)
    `CK(io_msInfo_4_bits_reqTag)
    `CK(io_msInfo_4_bits_willFree)
    `CK(io_msInfo_4_bits_aliasTask)
    `CK(io_msInfo_4_bits_needRelease)
    `CK(io_msInfo_4_bits_blockRefill)
    `CK(io_msInfo_4_bits_meta_dirty)
    `CK(io_msInfo_4_bits_meta_state)
    `CK(io_msInfo_4_bits_meta_clients)
    `CK(io_msInfo_4_bits_meta_alias)
    `CK(io_msInfo_4_bits_meta_prefetch)
    `CK(io_msInfo_4_bits_meta_prefetchSrc)
    `CK(io_msInfo_4_bits_meta_accessed)
    `CK(io_msInfo_4_bits_meta_tagErr)
    `CK(io_msInfo_4_bits_meta_dataErr)
    `CK(io_msInfo_4_bits_metaTag)
    `CK(io_msInfo_4_bits_dirHit)
    `CK(io_msInfo_4_bits_isAcqOrPrefetch)
    `CK(io_msInfo_4_bits_isPrefetch)
    `CK(io_msInfo_4_bits_param)
    `CK(io_msInfo_4_bits_mergeA)
    `CK(io_msInfo_4_bits_w_grantfirst)
    `CK(io_msInfo_4_bits_s_release)
    `CK(io_msInfo_4_bits_s_refill)
    `CK(io_msInfo_4_bits_s_cmoresp)
    `CK(io_msInfo_4_bits_s_cmometaw)
    `CK(io_msInfo_4_bits_w_releaseack)
    `CK(io_msInfo_4_bits_w_replResp)
    `CK(io_msInfo_4_bits_w_rprobeacklast)
    `CK(io_msInfo_4_bits_replaceData)
    `CK(io_msInfo_4_bits_releaseToClean)
    `CK(io_msInfo_5_valid)
    `CK(io_msInfo_5_bits_channel)
    `CK(io_msInfo_5_bits_set)
    `CK(io_msInfo_5_bits_way)
    `CK(io_msInfo_5_bits_reqTag)
    `CK(io_msInfo_5_bits_willFree)
    `CK(io_msInfo_5_bits_aliasTask)
    `CK(io_msInfo_5_bits_needRelease)
    `CK(io_msInfo_5_bits_blockRefill)
    `CK(io_msInfo_5_bits_meta_dirty)
    `CK(io_msInfo_5_bits_meta_state)
    `CK(io_msInfo_5_bits_meta_clients)
    `CK(io_msInfo_5_bits_meta_alias)
    `CK(io_msInfo_5_bits_meta_prefetch)
    `CK(io_msInfo_5_bits_meta_prefetchSrc)
    `CK(io_msInfo_5_bits_meta_accessed)
    `CK(io_msInfo_5_bits_meta_tagErr)
    `CK(io_msInfo_5_bits_meta_dataErr)
    `CK(io_msInfo_5_bits_metaTag)
    `CK(io_msInfo_5_bits_dirHit)
    `CK(io_msInfo_5_bits_isAcqOrPrefetch)
    `CK(io_msInfo_5_bits_isPrefetch)
    `CK(io_msInfo_5_bits_param)
    `CK(io_msInfo_5_bits_mergeA)
    `CK(io_msInfo_5_bits_w_grantfirst)
    `CK(io_msInfo_5_bits_s_release)
    `CK(io_msInfo_5_bits_s_refill)
    `CK(io_msInfo_5_bits_s_cmoresp)
    `CK(io_msInfo_5_bits_s_cmometaw)
    `CK(io_msInfo_5_bits_w_releaseack)
    `CK(io_msInfo_5_bits_w_replResp)
    `CK(io_msInfo_5_bits_w_rprobeacklast)
    `CK(io_msInfo_5_bits_replaceData)
    `CK(io_msInfo_5_bits_releaseToClean)
    `CK(io_msInfo_6_valid)
    `CK(io_msInfo_6_bits_channel)
    `CK(io_msInfo_6_bits_set)
    `CK(io_msInfo_6_bits_way)
    `CK(io_msInfo_6_bits_reqTag)
    `CK(io_msInfo_6_bits_willFree)
    `CK(io_msInfo_6_bits_aliasTask)
    `CK(io_msInfo_6_bits_needRelease)
    `CK(io_msInfo_6_bits_blockRefill)
    `CK(io_msInfo_6_bits_meta_dirty)
    `CK(io_msInfo_6_bits_meta_state)
    `CK(io_msInfo_6_bits_meta_clients)
    `CK(io_msInfo_6_bits_meta_alias)
    `CK(io_msInfo_6_bits_meta_prefetch)
    `CK(io_msInfo_6_bits_meta_prefetchSrc)
    `CK(io_msInfo_6_bits_meta_accessed)
    `CK(io_msInfo_6_bits_meta_tagErr)
    `CK(io_msInfo_6_bits_meta_dataErr)
    `CK(io_msInfo_6_bits_metaTag)
    `CK(io_msInfo_6_bits_dirHit)
    `CK(io_msInfo_6_bits_isAcqOrPrefetch)
    `CK(io_msInfo_6_bits_isPrefetch)
    `CK(io_msInfo_6_bits_param)
    `CK(io_msInfo_6_bits_mergeA)
    `CK(io_msInfo_6_bits_w_grantfirst)
    `CK(io_msInfo_6_bits_s_release)
    `CK(io_msInfo_6_bits_s_refill)
    `CK(io_msInfo_6_bits_s_cmoresp)
    `CK(io_msInfo_6_bits_s_cmometaw)
    `CK(io_msInfo_6_bits_w_releaseack)
    `CK(io_msInfo_6_bits_w_replResp)
    `CK(io_msInfo_6_bits_w_rprobeacklast)
    `CK(io_msInfo_6_bits_replaceData)
    `CK(io_msInfo_6_bits_releaseToClean)
    `CK(io_msInfo_7_valid)
    `CK(io_msInfo_7_bits_channel)
    `CK(io_msInfo_7_bits_set)
    `CK(io_msInfo_7_bits_way)
    `CK(io_msInfo_7_bits_reqTag)
    `CK(io_msInfo_7_bits_willFree)
    `CK(io_msInfo_7_bits_aliasTask)
    `CK(io_msInfo_7_bits_needRelease)
    `CK(io_msInfo_7_bits_blockRefill)
    `CK(io_msInfo_7_bits_meta_dirty)
    `CK(io_msInfo_7_bits_meta_state)
    `CK(io_msInfo_7_bits_meta_clients)
    `CK(io_msInfo_7_bits_meta_alias)
    `CK(io_msInfo_7_bits_meta_prefetch)
    `CK(io_msInfo_7_bits_meta_prefetchSrc)
    `CK(io_msInfo_7_bits_meta_accessed)
    `CK(io_msInfo_7_bits_meta_tagErr)
    `CK(io_msInfo_7_bits_meta_dataErr)
    `CK(io_msInfo_7_bits_metaTag)
    `CK(io_msInfo_7_bits_dirHit)
    `CK(io_msInfo_7_bits_isAcqOrPrefetch)
    `CK(io_msInfo_7_bits_isPrefetch)
    `CK(io_msInfo_7_bits_param)
    `CK(io_msInfo_7_bits_mergeA)
    `CK(io_msInfo_7_bits_w_grantfirst)
    `CK(io_msInfo_7_bits_s_release)
    `CK(io_msInfo_7_bits_s_refill)
    `CK(io_msInfo_7_bits_s_cmoresp)
    `CK(io_msInfo_7_bits_s_cmometaw)
    `CK(io_msInfo_7_bits_w_releaseack)
    `CK(io_msInfo_7_bits_w_replResp)
    `CK(io_msInfo_7_bits_w_rprobeacklast)
    `CK(io_msInfo_7_bits_replaceData)
    `CK(io_msInfo_7_bits_releaseToClean)
    `CK(io_msInfo_8_valid)
    `CK(io_msInfo_8_bits_channel)
    `CK(io_msInfo_8_bits_set)
    `CK(io_msInfo_8_bits_way)
    `CK(io_msInfo_8_bits_reqTag)
    `CK(io_msInfo_8_bits_willFree)
    `CK(io_msInfo_8_bits_aliasTask)
    `CK(io_msInfo_8_bits_needRelease)
    `CK(io_msInfo_8_bits_blockRefill)
    `CK(io_msInfo_8_bits_meta_dirty)
    `CK(io_msInfo_8_bits_meta_state)
    `CK(io_msInfo_8_bits_meta_clients)
    `CK(io_msInfo_8_bits_meta_alias)
    `CK(io_msInfo_8_bits_meta_prefetch)
    `CK(io_msInfo_8_bits_meta_prefetchSrc)
    `CK(io_msInfo_8_bits_meta_accessed)
    `CK(io_msInfo_8_bits_meta_tagErr)
    `CK(io_msInfo_8_bits_meta_dataErr)
    `CK(io_msInfo_8_bits_metaTag)
    `CK(io_msInfo_8_bits_dirHit)
    `CK(io_msInfo_8_bits_isAcqOrPrefetch)
    `CK(io_msInfo_8_bits_isPrefetch)
    `CK(io_msInfo_8_bits_param)
    `CK(io_msInfo_8_bits_mergeA)
    `CK(io_msInfo_8_bits_w_grantfirst)
    `CK(io_msInfo_8_bits_s_release)
    `CK(io_msInfo_8_bits_s_refill)
    `CK(io_msInfo_8_bits_s_cmoresp)
    `CK(io_msInfo_8_bits_s_cmometaw)
    `CK(io_msInfo_8_bits_w_releaseack)
    `CK(io_msInfo_8_bits_w_replResp)
    `CK(io_msInfo_8_bits_w_rprobeacklast)
    `CK(io_msInfo_8_bits_replaceData)
    `CK(io_msInfo_8_bits_releaseToClean)
    `CK(io_msInfo_9_valid)
    `CK(io_msInfo_9_bits_channel)
    `CK(io_msInfo_9_bits_set)
    `CK(io_msInfo_9_bits_way)
    `CK(io_msInfo_9_bits_reqTag)
    `CK(io_msInfo_9_bits_willFree)
    `CK(io_msInfo_9_bits_aliasTask)
    `CK(io_msInfo_9_bits_needRelease)
    `CK(io_msInfo_9_bits_blockRefill)
    `CK(io_msInfo_9_bits_meta_dirty)
    `CK(io_msInfo_9_bits_meta_state)
    `CK(io_msInfo_9_bits_meta_clients)
    `CK(io_msInfo_9_bits_meta_alias)
    `CK(io_msInfo_9_bits_meta_prefetch)
    `CK(io_msInfo_9_bits_meta_prefetchSrc)
    `CK(io_msInfo_9_bits_meta_accessed)
    `CK(io_msInfo_9_bits_meta_tagErr)
    `CK(io_msInfo_9_bits_meta_dataErr)
    `CK(io_msInfo_9_bits_metaTag)
    `CK(io_msInfo_9_bits_dirHit)
    `CK(io_msInfo_9_bits_isAcqOrPrefetch)
    `CK(io_msInfo_9_bits_isPrefetch)
    `CK(io_msInfo_9_bits_param)
    `CK(io_msInfo_9_bits_mergeA)
    `CK(io_msInfo_9_bits_w_grantfirst)
    `CK(io_msInfo_9_bits_s_release)
    `CK(io_msInfo_9_bits_s_refill)
    `CK(io_msInfo_9_bits_s_cmoresp)
    `CK(io_msInfo_9_bits_s_cmometaw)
    `CK(io_msInfo_9_bits_w_releaseack)
    `CK(io_msInfo_9_bits_w_replResp)
    `CK(io_msInfo_9_bits_w_rprobeacklast)
    `CK(io_msInfo_9_bits_replaceData)
    `CK(io_msInfo_9_bits_releaseToClean)
    `CK(io_msInfo_10_valid)
    `CK(io_msInfo_10_bits_channel)
    `CK(io_msInfo_10_bits_set)
    `CK(io_msInfo_10_bits_way)
    `CK(io_msInfo_10_bits_reqTag)
    `CK(io_msInfo_10_bits_willFree)
    `CK(io_msInfo_10_bits_aliasTask)
    `CK(io_msInfo_10_bits_needRelease)
    `CK(io_msInfo_10_bits_blockRefill)
    `CK(io_msInfo_10_bits_meta_dirty)
    `CK(io_msInfo_10_bits_meta_state)
    `CK(io_msInfo_10_bits_meta_clients)
    `CK(io_msInfo_10_bits_meta_alias)
    `CK(io_msInfo_10_bits_meta_prefetch)
    `CK(io_msInfo_10_bits_meta_prefetchSrc)
    `CK(io_msInfo_10_bits_meta_accessed)
    `CK(io_msInfo_10_bits_meta_tagErr)
    `CK(io_msInfo_10_bits_meta_dataErr)
    `CK(io_msInfo_10_bits_metaTag)
    `CK(io_msInfo_10_bits_dirHit)
    `CK(io_msInfo_10_bits_isAcqOrPrefetch)
    `CK(io_msInfo_10_bits_isPrefetch)
    `CK(io_msInfo_10_bits_param)
    `CK(io_msInfo_10_bits_mergeA)
    `CK(io_msInfo_10_bits_w_grantfirst)
    `CK(io_msInfo_10_bits_s_release)
    `CK(io_msInfo_10_bits_s_refill)
    `CK(io_msInfo_10_bits_s_cmoresp)
    `CK(io_msInfo_10_bits_s_cmometaw)
    `CK(io_msInfo_10_bits_w_releaseack)
    `CK(io_msInfo_10_bits_w_replResp)
    `CK(io_msInfo_10_bits_w_rprobeacklast)
    `CK(io_msInfo_10_bits_replaceData)
    `CK(io_msInfo_10_bits_releaseToClean)
    `CK(io_msInfo_11_valid)
    `CK(io_msInfo_11_bits_channel)
    `CK(io_msInfo_11_bits_set)
    `CK(io_msInfo_11_bits_way)
    `CK(io_msInfo_11_bits_reqTag)
    `CK(io_msInfo_11_bits_willFree)
    `CK(io_msInfo_11_bits_aliasTask)
    `CK(io_msInfo_11_bits_needRelease)
    `CK(io_msInfo_11_bits_blockRefill)
    `CK(io_msInfo_11_bits_meta_dirty)
    `CK(io_msInfo_11_bits_meta_state)
    `CK(io_msInfo_11_bits_meta_clients)
    `CK(io_msInfo_11_bits_meta_alias)
    `CK(io_msInfo_11_bits_meta_prefetch)
    `CK(io_msInfo_11_bits_meta_prefetchSrc)
    `CK(io_msInfo_11_bits_meta_accessed)
    `CK(io_msInfo_11_bits_meta_tagErr)
    `CK(io_msInfo_11_bits_meta_dataErr)
    `CK(io_msInfo_11_bits_metaTag)
    `CK(io_msInfo_11_bits_dirHit)
    `CK(io_msInfo_11_bits_isAcqOrPrefetch)
    `CK(io_msInfo_11_bits_isPrefetch)
    `CK(io_msInfo_11_bits_param)
    `CK(io_msInfo_11_bits_mergeA)
    `CK(io_msInfo_11_bits_w_grantfirst)
    `CK(io_msInfo_11_bits_s_release)
    `CK(io_msInfo_11_bits_s_refill)
    `CK(io_msInfo_11_bits_s_cmoresp)
    `CK(io_msInfo_11_bits_s_cmometaw)
    `CK(io_msInfo_11_bits_w_releaseack)
    `CK(io_msInfo_11_bits_w_replResp)
    `CK(io_msInfo_11_bits_w_rprobeacklast)
    `CK(io_msInfo_11_bits_replaceData)
    `CK(io_msInfo_11_bits_releaseToClean)
    `CK(io_msInfo_12_valid)
    `CK(io_msInfo_12_bits_channel)
    `CK(io_msInfo_12_bits_set)
    `CK(io_msInfo_12_bits_way)
    `CK(io_msInfo_12_bits_reqTag)
    `CK(io_msInfo_12_bits_willFree)
    `CK(io_msInfo_12_bits_aliasTask)
    `CK(io_msInfo_12_bits_needRelease)
    `CK(io_msInfo_12_bits_blockRefill)
    `CK(io_msInfo_12_bits_meta_dirty)
    `CK(io_msInfo_12_bits_meta_state)
    `CK(io_msInfo_12_bits_meta_clients)
    `CK(io_msInfo_12_bits_meta_alias)
    `CK(io_msInfo_12_bits_meta_prefetch)
    `CK(io_msInfo_12_bits_meta_prefetchSrc)
    `CK(io_msInfo_12_bits_meta_accessed)
    `CK(io_msInfo_12_bits_meta_tagErr)
    `CK(io_msInfo_12_bits_meta_dataErr)
    `CK(io_msInfo_12_bits_metaTag)
    `CK(io_msInfo_12_bits_dirHit)
    `CK(io_msInfo_12_bits_isAcqOrPrefetch)
    `CK(io_msInfo_12_bits_isPrefetch)
    `CK(io_msInfo_12_bits_param)
    `CK(io_msInfo_12_bits_mergeA)
    `CK(io_msInfo_12_bits_w_grantfirst)
    `CK(io_msInfo_12_bits_s_release)
    `CK(io_msInfo_12_bits_s_refill)
    `CK(io_msInfo_12_bits_s_cmoresp)
    `CK(io_msInfo_12_bits_s_cmometaw)
    `CK(io_msInfo_12_bits_w_releaseack)
    `CK(io_msInfo_12_bits_w_replResp)
    `CK(io_msInfo_12_bits_w_rprobeacklast)
    `CK(io_msInfo_12_bits_replaceData)
    `CK(io_msInfo_12_bits_releaseToClean)
    `CK(io_msInfo_13_valid)
    `CK(io_msInfo_13_bits_channel)
    `CK(io_msInfo_13_bits_set)
    `CK(io_msInfo_13_bits_way)
    `CK(io_msInfo_13_bits_reqTag)
    `CK(io_msInfo_13_bits_willFree)
    `CK(io_msInfo_13_bits_aliasTask)
    `CK(io_msInfo_13_bits_needRelease)
    `CK(io_msInfo_13_bits_blockRefill)
    `CK(io_msInfo_13_bits_meta_dirty)
    `CK(io_msInfo_13_bits_meta_state)
    `CK(io_msInfo_13_bits_meta_clients)
    `CK(io_msInfo_13_bits_meta_alias)
    `CK(io_msInfo_13_bits_meta_prefetch)
    `CK(io_msInfo_13_bits_meta_prefetchSrc)
    `CK(io_msInfo_13_bits_meta_accessed)
    `CK(io_msInfo_13_bits_meta_tagErr)
    `CK(io_msInfo_13_bits_meta_dataErr)
    `CK(io_msInfo_13_bits_metaTag)
    `CK(io_msInfo_13_bits_dirHit)
    `CK(io_msInfo_13_bits_isAcqOrPrefetch)
    `CK(io_msInfo_13_bits_isPrefetch)
    `CK(io_msInfo_13_bits_param)
    `CK(io_msInfo_13_bits_mergeA)
    `CK(io_msInfo_13_bits_w_grantfirst)
    `CK(io_msInfo_13_bits_s_release)
    `CK(io_msInfo_13_bits_s_refill)
    `CK(io_msInfo_13_bits_s_cmoresp)
    `CK(io_msInfo_13_bits_s_cmometaw)
    `CK(io_msInfo_13_bits_w_releaseack)
    `CK(io_msInfo_13_bits_w_replResp)
    `CK(io_msInfo_13_bits_w_rprobeacklast)
    `CK(io_msInfo_13_bits_replaceData)
    `CK(io_msInfo_13_bits_releaseToClean)
    `CK(io_msInfo_14_valid)
    `CK(io_msInfo_14_bits_channel)
    `CK(io_msInfo_14_bits_set)
    `CK(io_msInfo_14_bits_way)
    `CK(io_msInfo_14_bits_reqTag)
    `CK(io_msInfo_14_bits_willFree)
    `CK(io_msInfo_14_bits_aliasTask)
    `CK(io_msInfo_14_bits_needRelease)
    `CK(io_msInfo_14_bits_blockRefill)
    `CK(io_msInfo_14_bits_meta_dirty)
    `CK(io_msInfo_14_bits_meta_state)
    `CK(io_msInfo_14_bits_meta_clients)
    `CK(io_msInfo_14_bits_meta_alias)
    `CK(io_msInfo_14_bits_meta_prefetch)
    `CK(io_msInfo_14_bits_meta_prefetchSrc)
    `CK(io_msInfo_14_bits_meta_accessed)
    `CK(io_msInfo_14_bits_meta_tagErr)
    `CK(io_msInfo_14_bits_meta_dataErr)
    `CK(io_msInfo_14_bits_metaTag)
    `CK(io_msInfo_14_bits_dirHit)
    `CK(io_msInfo_14_bits_isAcqOrPrefetch)
    `CK(io_msInfo_14_bits_isPrefetch)
    `CK(io_msInfo_14_bits_param)
    `CK(io_msInfo_14_bits_mergeA)
    `CK(io_msInfo_14_bits_w_grantfirst)
    `CK(io_msInfo_14_bits_s_release)
    `CK(io_msInfo_14_bits_s_refill)
    `CK(io_msInfo_14_bits_s_cmoresp)
    `CK(io_msInfo_14_bits_s_cmometaw)
    `CK(io_msInfo_14_bits_w_releaseack)
    `CK(io_msInfo_14_bits_w_replResp)
    `CK(io_msInfo_14_bits_w_rprobeacklast)
    `CK(io_msInfo_14_bits_replaceData)
    `CK(io_msInfo_14_bits_releaseToClean)
    `CK(io_msInfo_15_valid)
    `CK(io_msInfo_15_bits_channel)
    `CK(io_msInfo_15_bits_set)
    `CK(io_msInfo_15_bits_way)
    `CK(io_msInfo_15_bits_reqTag)
    `CK(io_msInfo_15_bits_willFree)
    `CK(io_msInfo_15_bits_aliasTask)
    `CK(io_msInfo_15_bits_needRelease)
    `CK(io_msInfo_15_bits_blockRefill)
    `CK(io_msInfo_15_bits_meta_dirty)
    `CK(io_msInfo_15_bits_meta_state)
    `CK(io_msInfo_15_bits_meta_clients)
    `CK(io_msInfo_15_bits_meta_alias)
    `CK(io_msInfo_15_bits_meta_prefetch)
    `CK(io_msInfo_15_bits_meta_prefetchSrc)
    `CK(io_msInfo_15_bits_meta_accessed)
    `CK(io_msInfo_15_bits_meta_tagErr)
    `CK(io_msInfo_15_bits_meta_dataErr)
    `CK(io_msInfo_15_bits_metaTag)
    `CK(io_msInfo_15_bits_dirHit)
    `CK(io_msInfo_15_bits_isAcqOrPrefetch)
    `CK(io_msInfo_15_bits_isPrefetch)
    `CK(io_msInfo_15_bits_param)
    `CK(io_msInfo_15_bits_mergeA)
    `CK(io_msInfo_15_bits_w_grantfirst)
    `CK(io_msInfo_15_bits_s_release)
    `CK(io_msInfo_15_bits_s_refill)
    `CK(io_msInfo_15_bits_s_cmoresp)
    `CK(io_msInfo_15_bits_s_cmometaw)
    `CK(io_msInfo_15_bits_w_releaseack)
    `CK(io_msInfo_15_bits_w_replResp)
    `CK(io_msInfo_15_bits_w_rprobeacklast)
    `CK(io_msInfo_15_bits_replaceData)
    `CK(io_msInfo_15_bits_releaseToClean)
    `CK(io_msStatus_0_valid)
    `CK(io_msStatus_0_bits_channel)
    `CK(io_msStatus_0_bits_set)
    `CK(io_msStatus_0_bits_reqTag)
    `CK(io_msStatus_0_bits_is_miss)
    `CK(io_msStatus_0_bits_is_prefetch)
    `CK(io_msStatus_1_valid)
    `CK(io_msStatus_1_bits_channel)
    `CK(io_msStatus_1_bits_set)
    `CK(io_msStatus_1_bits_reqTag)
    `CK(io_msStatus_1_bits_is_miss)
    `CK(io_msStatus_1_bits_is_prefetch)
    `CK(io_msStatus_2_valid)
    `CK(io_msStatus_2_bits_channel)
    `CK(io_msStatus_2_bits_set)
    `CK(io_msStatus_2_bits_reqTag)
    `CK(io_msStatus_2_bits_is_miss)
    `CK(io_msStatus_2_bits_is_prefetch)
    `CK(io_msStatus_3_valid)
    `CK(io_msStatus_3_bits_channel)
    `CK(io_msStatus_3_bits_set)
    `CK(io_msStatus_3_bits_reqTag)
    `CK(io_msStatus_3_bits_is_miss)
    `CK(io_msStatus_3_bits_is_prefetch)
    `CK(io_msStatus_4_valid)
    `CK(io_msStatus_4_bits_channel)
    `CK(io_msStatus_4_bits_set)
    `CK(io_msStatus_4_bits_reqTag)
    `CK(io_msStatus_4_bits_is_miss)
    `CK(io_msStatus_4_bits_is_prefetch)
    `CK(io_msStatus_5_valid)
    `CK(io_msStatus_5_bits_channel)
    `CK(io_msStatus_5_bits_set)
    `CK(io_msStatus_5_bits_reqTag)
    `CK(io_msStatus_5_bits_is_miss)
    `CK(io_msStatus_5_bits_is_prefetch)
    `CK(io_msStatus_6_valid)
    `CK(io_msStatus_6_bits_channel)
    `CK(io_msStatus_6_bits_set)
    `CK(io_msStatus_6_bits_reqTag)
    `CK(io_msStatus_6_bits_is_miss)
    `CK(io_msStatus_6_bits_is_prefetch)
    `CK(io_msStatus_7_valid)
    `CK(io_msStatus_7_bits_channel)
    `CK(io_msStatus_7_bits_set)
    `CK(io_msStatus_7_bits_reqTag)
    `CK(io_msStatus_7_bits_is_miss)
    `CK(io_msStatus_7_bits_is_prefetch)
    `CK(io_msStatus_8_valid)
    `CK(io_msStatus_8_bits_channel)
    `CK(io_msStatus_8_bits_set)
    `CK(io_msStatus_8_bits_reqTag)
    `CK(io_msStatus_8_bits_is_miss)
    `CK(io_msStatus_8_bits_is_prefetch)
    `CK(io_msStatus_9_valid)
    `CK(io_msStatus_9_bits_channel)
    `CK(io_msStatus_9_bits_set)
    `CK(io_msStatus_9_bits_reqTag)
    `CK(io_msStatus_9_bits_is_miss)
    `CK(io_msStatus_9_bits_is_prefetch)
    `CK(io_msStatus_10_valid)
    `CK(io_msStatus_10_bits_channel)
    `CK(io_msStatus_10_bits_set)
    `CK(io_msStatus_10_bits_reqTag)
    `CK(io_msStatus_10_bits_is_miss)
    `CK(io_msStatus_10_bits_is_prefetch)
    `CK(io_msStatus_11_valid)
    `CK(io_msStatus_11_bits_channel)
    `CK(io_msStatus_11_bits_set)
    `CK(io_msStatus_11_bits_reqTag)
    `CK(io_msStatus_11_bits_is_miss)
    `CK(io_msStatus_11_bits_is_prefetch)
    `CK(io_msStatus_12_valid)
    `CK(io_msStatus_12_bits_channel)
    `CK(io_msStatus_12_bits_set)
    `CK(io_msStatus_12_bits_reqTag)
    `CK(io_msStatus_12_bits_is_miss)
    `CK(io_msStatus_12_bits_is_prefetch)
    `CK(io_msStatus_13_valid)
    `CK(io_msStatus_13_bits_channel)
    `CK(io_msStatus_13_bits_set)
    `CK(io_msStatus_13_bits_reqTag)
    `CK(io_msStatus_13_bits_is_miss)
    `CK(io_msStatus_13_bits_is_prefetch)
    `CK(io_msStatus_14_valid)
    `CK(io_msStatus_14_bits_channel)
    `CK(io_msStatus_14_bits_set)
    `CK(io_msStatus_14_bits_reqTag)
    `CK(io_msStatus_14_bits_is_miss)
    `CK(io_msStatus_14_bits_is_prefetch)
    `CK(io_msStatus_15_valid)
    `CK(io_msStatus_15_bits_channel)
    `CK(io_msStatus_15_bits_set)
    `CK(io_msStatus_15_bits_reqTag)
    `CK(io_msStatus_15_bits_is_miss)
    `CK(io_msStatus_15_bits_is_prefetch)
    `CK(io_msAlloc_0_valid)
    `CK(io_msAlloc_0_bits_channel)
    `CK(io_msAlloc_0_bits_is_miss)
    `CK(io_msAlloc_0_bits_is_prefetch)
    `CK(io_msAlloc_1_valid)
    `CK(io_msAlloc_1_bits_channel)
    `CK(io_msAlloc_1_bits_is_miss)
    `CK(io_msAlloc_1_bits_is_prefetch)
    `CK(io_msAlloc_2_valid)
    `CK(io_msAlloc_2_bits_channel)
    `CK(io_msAlloc_2_bits_is_miss)
    `CK(io_msAlloc_2_bits_is_prefetch)
    `CK(io_msAlloc_3_valid)
    `CK(io_msAlloc_3_bits_channel)
    `CK(io_msAlloc_3_bits_is_miss)
    `CK(io_msAlloc_3_bits_is_prefetch)
    `CK(io_msAlloc_4_valid)
    `CK(io_msAlloc_4_bits_channel)
    `CK(io_msAlloc_4_bits_is_miss)
    `CK(io_msAlloc_4_bits_is_prefetch)
    `CK(io_msAlloc_5_valid)
    `CK(io_msAlloc_5_bits_channel)
    `CK(io_msAlloc_5_bits_is_miss)
    `CK(io_msAlloc_5_bits_is_prefetch)
    `CK(io_msAlloc_6_valid)
    `CK(io_msAlloc_6_bits_channel)
    `CK(io_msAlloc_6_bits_is_miss)
    `CK(io_msAlloc_6_bits_is_prefetch)
    `CK(io_msAlloc_7_valid)
    `CK(io_msAlloc_7_bits_channel)
    `CK(io_msAlloc_7_bits_is_miss)
    `CK(io_msAlloc_7_bits_is_prefetch)
    `CK(io_msAlloc_8_valid)
    `CK(io_msAlloc_8_bits_channel)
    `CK(io_msAlloc_8_bits_is_miss)
    `CK(io_msAlloc_8_bits_is_prefetch)
    `CK(io_msAlloc_9_valid)
    `CK(io_msAlloc_9_bits_channel)
    `CK(io_msAlloc_9_bits_is_miss)
    `CK(io_msAlloc_9_bits_is_prefetch)
    `CK(io_msAlloc_10_valid)
    `CK(io_msAlloc_10_bits_channel)
    `CK(io_msAlloc_10_bits_is_miss)
    `CK(io_msAlloc_10_bits_is_prefetch)
    `CK(io_msAlloc_11_valid)
    `CK(io_msAlloc_11_bits_channel)
    `CK(io_msAlloc_11_bits_is_miss)
    `CK(io_msAlloc_11_bits_is_prefetch)
    `CK(io_msAlloc_12_valid)
    `CK(io_msAlloc_12_bits_channel)
    `CK(io_msAlloc_12_bits_is_miss)
    `CK(io_msAlloc_12_bits_is_prefetch)
    `CK(io_msAlloc_13_valid)
    `CK(io_msAlloc_13_bits_channel)
    `CK(io_msAlloc_13_bits_is_miss)
    `CK(io_msAlloc_13_bits_is_prefetch)
    `CK(io_msAlloc_14_valid)
    `CK(io_msAlloc_14_bits_channel)
    `CK(io_msAlloc_14_bits_is_miss)
    `CK(io_msAlloc_14_bits_is_prefetch)
    `CK(io_msAlloc_15_valid)
    `CK(io_msAlloc_15_bits_channel)
    `CK(io_msAlloc_15_bits_is_miss)
    `CK(io_msAlloc_15_bits_is_prefetch)
    `CK(io_pCrd_0_query_valid)
    `CK(io_pCrd_0_query_bits_pCrdType)
    `CK(io_pCrd_0_query_bits_srcID)
    `CK(io_pCrd_1_query_valid)
    `CK(io_pCrd_1_query_bits_pCrdType)
    `CK(io_pCrd_1_query_bits_srcID)
    `CK(io_pCrd_2_query_valid)
    `CK(io_pCrd_2_query_bits_pCrdType)
    `CK(io_pCrd_2_query_bits_srcID)
    `CK(io_pCrd_3_query_valid)
    `CK(io_pCrd_3_query_bits_pCrdType)
    `CK(io_pCrd_3_query_bits_srcID)
    `CK(io_pCrd_4_query_valid)
    `CK(io_pCrd_4_query_bits_pCrdType)
    `CK(io_pCrd_4_query_bits_srcID)
    `CK(io_pCrd_5_query_valid)
    `CK(io_pCrd_5_query_bits_pCrdType)
    `CK(io_pCrd_5_query_bits_srcID)
    `CK(io_pCrd_6_query_valid)
    `CK(io_pCrd_6_query_bits_pCrdType)
    `CK(io_pCrd_6_query_bits_srcID)
    `CK(io_pCrd_7_query_valid)
    `CK(io_pCrd_7_query_bits_pCrdType)
    `CK(io_pCrd_7_query_bits_srcID)
    `CK(io_pCrd_8_query_valid)
    `CK(io_pCrd_8_query_bits_pCrdType)
    `CK(io_pCrd_8_query_bits_srcID)
    `CK(io_pCrd_9_query_valid)
    `CK(io_pCrd_9_query_bits_pCrdType)
    `CK(io_pCrd_9_query_bits_srcID)
    `CK(io_pCrd_10_query_valid)
    `CK(io_pCrd_10_query_bits_pCrdType)
    `CK(io_pCrd_10_query_bits_srcID)
    `CK(io_pCrd_11_query_valid)
    `CK(io_pCrd_11_query_bits_pCrdType)
    `CK(io_pCrd_11_query_bits_srcID)
    `CK(io_pCrd_12_query_valid)
    `CK(io_pCrd_12_query_bits_pCrdType)
    `CK(io_pCrd_12_query_bits_srcID)
    `CK(io_pCrd_13_query_valid)
    `CK(io_pCrd_13_query_bits_pCrdType)
    `CK(io_pCrd_13_query_bits_srcID)
    `CK(io_pCrd_14_query_valid)
    `CK(io_pCrd_14_query_bits_pCrdType)
    `CK(io_pCrd_14_query_bits_srcID)
    `CK(io_pCrd_15_query_valid)
    `CK(io_pCrd_15_query_bits_pCrdType)
    `CK(io_pCrd_15_query_bits_srcID)
    `CK(io_l2Miss)
    `CK(io_perf_0_value)
    `CK(io_perf_1_value)
    `CK(io_perf_3_value)
  endtask

  longint cov [17];
  localparam string COV_NAME [17] = '{"mshrFull_probe", "a_mshrFull_probe", "io_nestedwbDataId_valid", "io_l2Miss", "resp_sinkC_match_vec_3", "resp_sinkC_match_vec_14", "_mshrs_15_io_status_valid", "io_toTXREQ_valid & io_toTXREQ_ready", "io_toTXRSP_valid & io_toTXRSP_ready", "io_toSourceB_valid & io_toSourceB_ready", "io_mshrTask_valid & io_mshrTask_ready", "mshrs_7.release_valid1", "mshrs_7.mp_probeack_valid", "mshrs_7.mp_dct_valid", "mshrs_7._GEN_80", "mshrs_0.nestedwb_match", "|io_perf_3_value"};
  task automatic sample();
    if (u_g.mshrFull_probe) cov[0]++;
    if (u_g.a_mshrFull_probe) cov[1]++;
    if (u_g.io_nestedwbDataId_valid) cov[2]++;
    if (u_g.io_l2Miss) cov[3]++;
    if (u_g.resp_sinkC_match_vec_3) cov[4]++;
    if (u_g.resp_sinkC_match_vec_14) cov[5]++;
    if (u_g._mshrs_15_io_status_valid) cov[6]++;
    if (u_g.io_toTXREQ_valid & u_g.io_toTXREQ_ready) cov[7]++;
    if (u_g.io_toTXRSP_valid & u_g.io_toTXRSP_ready) cov[8]++;
    if (u_g.io_toSourceB_valid & u_g.io_toSourceB_ready) cov[9]++;
    if (u_g.io_mshrTask_valid & u_g.io_mshrTask_ready) cov[10]++;
    if (u_g.mshrs_7.release_valid1) cov[11]++;
    if (u_g.mshrs_7.mp_probeack_valid) cov[12]++;
    if (u_g.mshrs_7.mp_dct_valid) cov[13]++;
    if (u_g.mshrs_7._GEN_80) cov[14]++;
    if (u_g.mshrs_0.nestedwb_match) cov[15]++;
    if (|u_g.io_perf_3_value) cov[16]++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[k]) cov[k] = 0;
    reset = 1'b1;
    drive(); reset = 1'b1;
    #1;
    // 未复位寄存器两侧同初值（见文件头）
    force u_i.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g.mshrs_0.tgtid_rcompack;
    force u_i.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g.mshrs_0.txnid_rcompack;
    force u_i.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g.mshrs_0.tgtid_wcompack;
    force u_i.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g.mshrs_0.txnid_wcompack;
    force u_i.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g.mshrs_0.srcid_retryack;
    force u_i.u_core.mshrs[0].entry.u_core.acquire_ts = u_g.mshrs_0.acquire_ts;
    force u_i.u_core.mshrs[0].entry.u_core.release_ts = u_g.mshrs_0.release_ts;
    force u_i.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g.mshrs_0.acquire_period_valid_REG;
    force u_i.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g.mshrs_0.release_period_valid_REG;
    force u_i.u_core.mshrs[0].entry.u_core.REG = u_g.mshrs_0.REG;
    force u_i.u_core.mshrs[0].entry.u_core.REG_1 = u_g.mshrs_0.REG_1;
    force u_i.u_core.mshrs[0].entry.u_core.REG_2 = u_g.mshrs_0.REG_2;
    force u_i.u_core.mshrs[0].entry.u_core.REG_3 = u_g.mshrs_0.REG_3;
    force u_i.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g.mshrs_1.tgtid_rcompack;
    force u_i.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g.mshrs_1.txnid_rcompack;
    force u_i.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g.mshrs_1.tgtid_wcompack;
    force u_i.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g.mshrs_1.txnid_wcompack;
    force u_i.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g.mshrs_1.srcid_retryack;
    force u_i.u_core.mshrs[1].entry.u_core.acquire_ts = u_g.mshrs_1.acquire_ts;
    force u_i.u_core.mshrs[1].entry.u_core.release_ts = u_g.mshrs_1.release_ts;
    force u_i.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g.mshrs_1.acquire_period_valid_REG;
    force u_i.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g.mshrs_1.release_period_valid_REG;
    force u_i.u_core.mshrs[1].entry.u_core.REG = u_g.mshrs_1.REG;
    force u_i.u_core.mshrs[1].entry.u_core.REG_1 = u_g.mshrs_1.REG_1;
    force u_i.u_core.mshrs[1].entry.u_core.REG_2 = u_g.mshrs_1.REG_2;
    force u_i.u_core.mshrs[1].entry.u_core.REG_3 = u_g.mshrs_1.REG_3;
    force u_i.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g.mshrs_2.tgtid_rcompack;
    force u_i.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g.mshrs_2.txnid_rcompack;
    force u_i.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g.mshrs_2.tgtid_wcompack;
    force u_i.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g.mshrs_2.txnid_wcompack;
    force u_i.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g.mshrs_2.srcid_retryack;
    force u_i.u_core.mshrs[2].entry.u_core.acquire_ts = u_g.mshrs_2.acquire_ts;
    force u_i.u_core.mshrs[2].entry.u_core.release_ts = u_g.mshrs_2.release_ts;
    force u_i.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g.mshrs_2.acquire_period_valid_REG;
    force u_i.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g.mshrs_2.release_period_valid_REG;
    force u_i.u_core.mshrs[2].entry.u_core.REG = u_g.mshrs_2.REG;
    force u_i.u_core.mshrs[2].entry.u_core.REG_1 = u_g.mshrs_2.REG_1;
    force u_i.u_core.mshrs[2].entry.u_core.REG_2 = u_g.mshrs_2.REG_2;
    force u_i.u_core.mshrs[2].entry.u_core.REG_3 = u_g.mshrs_2.REG_3;
    force u_i.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g.mshrs_3.tgtid_rcompack;
    force u_i.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g.mshrs_3.txnid_rcompack;
    force u_i.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g.mshrs_3.tgtid_wcompack;
    force u_i.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g.mshrs_3.txnid_wcompack;
    force u_i.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g.mshrs_3.srcid_retryack;
    force u_i.u_core.mshrs[3].entry.u_core.acquire_ts = u_g.mshrs_3.acquire_ts;
    force u_i.u_core.mshrs[3].entry.u_core.release_ts = u_g.mshrs_3.release_ts;
    force u_i.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g.mshrs_3.acquire_period_valid_REG;
    force u_i.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g.mshrs_3.release_period_valid_REG;
    force u_i.u_core.mshrs[3].entry.u_core.REG = u_g.mshrs_3.REG;
    force u_i.u_core.mshrs[3].entry.u_core.REG_1 = u_g.mshrs_3.REG_1;
    force u_i.u_core.mshrs[3].entry.u_core.REG_2 = u_g.mshrs_3.REG_2;
    force u_i.u_core.mshrs[3].entry.u_core.REG_3 = u_g.mshrs_3.REG_3;
    force u_i.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g.mshrs_4.tgtid_rcompack;
    force u_i.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g.mshrs_4.txnid_rcompack;
    force u_i.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g.mshrs_4.tgtid_wcompack;
    force u_i.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g.mshrs_4.txnid_wcompack;
    force u_i.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g.mshrs_4.srcid_retryack;
    force u_i.u_core.mshrs[4].entry.u_core.acquire_ts = u_g.mshrs_4.acquire_ts;
    force u_i.u_core.mshrs[4].entry.u_core.release_ts = u_g.mshrs_4.release_ts;
    force u_i.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g.mshrs_4.acquire_period_valid_REG;
    force u_i.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g.mshrs_4.release_period_valid_REG;
    force u_i.u_core.mshrs[4].entry.u_core.REG = u_g.mshrs_4.REG;
    force u_i.u_core.mshrs[4].entry.u_core.REG_1 = u_g.mshrs_4.REG_1;
    force u_i.u_core.mshrs[4].entry.u_core.REG_2 = u_g.mshrs_4.REG_2;
    force u_i.u_core.mshrs[4].entry.u_core.REG_3 = u_g.mshrs_4.REG_3;
    force u_i.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g.mshrs_5.tgtid_rcompack;
    force u_i.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g.mshrs_5.txnid_rcompack;
    force u_i.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g.mshrs_5.tgtid_wcompack;
    force u_i.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g.mshrs_5.txnid_wcompack;
    force u_i.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g.mshrs_5.srcid_retryack;
    force u_i.u_core.mshrs[5].entry.u_core.acquire_ts = u_g.mshrs_5.acquire_ts;
    force u_i.u_core.mshrs[5].entry.u_core.release_ts = u_g.mshrs_5.release_ts;
    force u_i.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g.mshrs_5.acquire_period_valid_REG;
    force u_i.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g.mshrs_5.release_period_valid_REG;
    force u_i.u_core.mshrs[5].entry.u_core.REG = u_g.mshrs_5.REG;
    force u_i.u_core.mshrs[5].entry.u_core.REG_1 = u_g.mshrs_5.REG_1;
    force u_i.u_core.mshrs[5].entry.u_core.REG_2 = u_g.mshrs_5.REG_2;
    force u_i.u_core.mshrs[5].entry.u_core.REG_3 = u_g.mshrs_5.REG_3;
    force u_i.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g.mshrs_6.tgtid_rcompack;
    force u_i.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g.mshrs_6.txnid_rcompack;
    force u_i.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g.mshrs_6.tgtid_wcompack;
    force u_i.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g.mshrs_6.txnid_wcompack;
    force u_i.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g.mshrs_6.srcid_retryack;
    force u_i.u_core.mshrs[6].entry.u_core.acquire_ts = u_g.mshrs_6.acquire_ts;
    force u_i.u_core.mshrs[6].entry.u_core.release_ts = u_g.mshrs_6.release_ts;
    force u_i.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g.mshrs_6.acquire_period_valid_REG;
    force u_i.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g.mshrs_6.release_period_valid_REG;
    force u_i.u_core.mshrs[6].entry.u_core.REG = u_g.mshrs_6.REG;
    force u_i.u_core.mshrs[6].entry.u_core.REG_1 = u_g.mshrs_6.REG_1;
    force u_i.u_core.mshrs[6].entry.u_core.REG_2 = u_g.mshrs_6.REG_2;
    force u_i.u_core.mshrs[6].entry.u_core.REG_3 = u_g.mshrs_6.REG_3;
    force u_i.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g.mshrs_7.tgtid_rcompack;
    force u_i.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g.mshrs_7.txnid_rcompack;
    force u_i.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g.mshrs_7.tgtid_wcompack;
    force u_i.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g.mshrs_7.txnid_wcompack;
    force u_i.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g.mshrs_7.srcid_retryack;
    force u_i.u_core.mshrs[7].entry.u_core.acquire_ts = u_g.mshrs_7.acquire_ts;
    force u_i.u_core.mshrs[7].entry.u_core.release_ts = u_g.mshrs_7.release_ts;
    force u_i.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g.mshrs_7.acquire_period_valid_REG;
    force u_i.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g.mshrs_7.release_period_valid_REG;
    force u_i.u_core.mshrs[7].entry.u_core.REG = u_g.mshrs_7.REG;
    force u_i.u_core.mshrs[7].entry.u_core.REG_1 = u_g.mshrs_7.REG_1;
    force u_i.u_core.mshrs[7].entry.u_core.REG_2 = u_g.mshrs_7.REG_2;
    force u_i.u_core.mshrs[7].entry.u_core.REG_3 = u_g.mshrs_7.REG_3;
    force u_i.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g.mshrs_8.tgtid_rcompack;
    force u_i.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g.mshrs_8.txnid_rcompack;
    force u_i.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g.mshrs_8.tgtid_wcompack;
    force u_i.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g.mshrs_8.txnid_wcompack;
    force u_i.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g.mshrs_8.srcid_retryack;
    force u_i.u_core.mshrs[8].entry.u_core.acquire_ts = u_g.mshrs_8.acquire_ts;
    force u_i.u_core.mshrs[8].entry.u_core.release_ts = u_g.mshrs_8.release_ts;
    force u_i.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g.mshrs_8.acquire_period_valid_REG;
    force u_i.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g.mshrs_8.release_period_valid_REG;
    force u_i.u_core.mshrs[8].entry.u_core.REG = u_g.mshrs_8.REG;
    force u_i.u_core.mshrs[8].entry.u_core.REG_1 = u_g.mshrs_8.REG_1;
    force u_i.u_core.mshrs[8].entry.u_core.REG_2 = u_g.mshrs_8.REG_2;
    force u_i.u_core.mshrs[8].entry.u_core.REG_3 = u_g.mshrs_8.REG_3;
    force u_i.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g.mshrs_9.tgtid_rcompack;
    force u_i.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g.mshrs_9.txnid_rcompack;
    force u_i.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g.mshrs_9.tgtid_wcompack;
    force u_i.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g.mshrs_9.txnid_wcompack;
    force u_i.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g.mshrs_9.srcid_retryack;
    force u_i.u_core.mshrs[9].entry.u_core.acquire_ts = u_g.mshrs_9.acquire_ts;
    force u_i.u_core.mshrs[9].entry.u_core.release_ts = u_g.mshrs_9.release_ts;
    force u_i.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g.mshrs_9.acquire_period_valid_REG;
    force u_i.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g.mshrs_9.release_period_valid_REG;
    force u_i.u_core.mshrs[9].entry.u_core.REG = u_g.mshrs_9.REG;
    force u_i.u_core.mshrs[9].entry.u_core.REG_1 = u_g.mshrs_9.REG_1;
    force u_i.u_core.mshrs[9].entry.u_core.REG_2 = u_g.mshrs_9.REG_2;
    force u_i.u_core.mshrs[9].entry.u_core.REG_3 = u_g.mshrs_9.REG_3;
    force u_i.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g.mshrs_10.tgtid_rcompack;
    force u_i.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g.mshrs_10.txnid_rcompack;
    force u_i.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g.mshrs_10.tgtid_wcompack;
    force u_i.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g.mshrs_10.txnid_wcompack;
    force u_i.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g.mshrs_10.srcid_retryack;
    force u_i.u_core.mshrs[10].entry.u_core.acquire_ts = u_g.mshrs_10.acquire_ts;
    force u_i.u_core.mshrs[10].entry.u_core.release_ts = u_g.mshrs_10.release_ts;
    force u_i.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g.mshrs_10.acquire_period_valid_REG;
    force u_i.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g.mshrs_10.release_period_valid_REG;
    force u_i.u_core.mshrs[10].entry.u_core.REG = u_g.mshrs_10.REG;
    force u_i.u_core.mshrs[10].entry.u_core.REG_1 = u_g.mshrs_10.REG_1;
    force u_i.u_core.mshrs[10].entry.u_core.REG_2 = u_g.mshrs_10.REG_2;
    force u_i.u_core.mshrs[10].entry.u_core.REG_3 = u_g.mshrs_10.REG_3;
    force u_i.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g.mshrs_11.tgtid_rcompack;
    force u_i.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g.mshrs_11.txnid_rcompack;
    force u_i.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g.mshrs_11.tgtid_wcompack;
    force u_i.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g.mshrs_11.txnid_wcompack;
    force u_i.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g.mshrs_11.srcid_retryack;
    force u_i.u_core.mshrs[11].entry.u_core.acquire_ts = u_g.mshrs_11.acquire_ts;
    force u_i.u_core.mshrs[11].entry.u_core.release_ts = u_g.mshrs_11.release_ts;
    force u_i.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g.mshrs_11.acquire_period_valid_REG;
    force u_i.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g.mshrs_11.release_period_valid_REG;
    force u_i.u_core.mshrs[11].entry.u_core.REG = u_g.mshrs_11.REG;
    force u_i.u_core.mshrs[11].entry.u_core.REG_1 = u_g.mshrs_11.REG_1;
    force u_i.u_core.mshrs[11].entry.u_core.REG_2 = u_g.mshrs_11.REG_2;
    force u_i.u_core.mshrs[11].entry.u_core.REG_3 = u_g.mshrs_11.REG_3;
    force u_i.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g.mshrs_12.tgtid_rcompack;
    force u_i.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g.mshrs_12.txnid_rcompack;
    force u_i.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g.mshrs_12.tgtid_wcompack;
    force u_i.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g.mshrs_12.txnid_wcompack;
    force u_i.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g.mshrs_12.srcid_retryack;
    force u_i.u_core.mshrs[12].entry.u_core.acquire_ts = u_g.mshrs_12.acquire_ts;
    force u_i.u_core.mshrs[12].entry.u_core.release_ts = u_g.mshrs_12.release_ts;
    force u_i.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g.mshrs_12.acquire_period_valid_REG;
    force u_i.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g.mshrs_12.release_period_valid_REG;
    force u_i.u_core.mshrs[12].entry.u_core.REG = u_g.mshrs_12.REG;
    force u_i.u_core.mshrs[12].entry.u_core.REG_1 = u_g.mshrs_12.REG_1;
    force u_i.u_core.mshrs[12].entry.u_core.REG_2 = u_g.mshrs_12.REG_2;
    force u_i.u_core.mshrs[12].entry.u_core.REG_3 = u_g.mshrs_12.REG_3;
    force u_i.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g.mshrs_13.tgtid_rcompack;
    force u_i.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g.mshrs_13.txnid_rcompack;
    force u_i.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g.mshrs_13.tgtid_wcompack;
    force u_i.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g.mshrs_13.txnid_wcompack;
    force u_i.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g.mshrs_13.srcid_retryack;
    force u_i.u_core.mshrs[13].entry.u_core.acquire_ts = u_g.mshrs_13.acquire_ts;
    force u_i.u_core.mshrs[13].entry.u_core.release_ts = u_g.mshrs_13.release_ts;
    force u_i.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g.mshrs_13.acquire_period_valid_REG;
    force u_i.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g.mshrs_13.release_period_valid_REG;
    force u_i.u_core.mshrs[13].entry.u_core.REG = u_g.mshrs_13.REG;
    force u_i.u_core.mshrs[13].entry.u_core.REG_1 = u_g.mshrs_13.REG_1;
    force u_i.u_core.mshrs[13].entry.u_core.REG_2 = u_g.mshrs_13.REG_2;
    force u_i.u_core.mshrs[13].entry.u_core.REG_3 = u_g.mshrs_13.REG_3;
    force u_i.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g.mshrs_14.tgtid_rcompack;
    force u_i.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g.mshrs_14.txnid_rcompack;
    force u_i.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g.mshrs_14.tgtid_wcompack;
    force u_i.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g.mshrs_14.txnid_wcompack;
    force u_i.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g.mshrs_14.srcid_retryack;
    force u_i.u_core.mshrs[14].entry.u_core.acquire_ts = u_g.mshrs_14.acquire_ts;
    force u_i.u_core.mshrs[14].entry.u_core.release_ts = u_g.mshrs_14.release_ts;
    force u_i.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g.mshrs_14.acquire_period_valid_REG;
    force u_i.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g.mshrs_14.release_period_valid_REG;
    force u_i.u_core.mshrs[14].entry.u_core.REG = u_g.mshrs_14.REG;
    force u_i.u_core.mshrs[14].entry.u_core.REG_1 = u_g.mshrs_14.REG_1;
    force u_i.u_core.mshrs[14].entry.u_core.REG_2 = u_g.mshrs_14.REG_2;
    force u_i.u_core.mshrs[14].entry.u_core.REG_3 = u_g.mshrs_14.REG_3;
    force u_i.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g.mshrs_15.tgtid_rcompack;
    force u_i.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g.mshrs_15.txnid_rcompack;
    force u_i.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g.mshrs_15.tgtid_wcompack;
    force u_i.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g.mshrs_15.txnid_wcompack;
    force u_i.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g.mshrs_15.srcid_retryack;
    force u_i.u_core.mshrs[15].entry.u_core.acquire_ts = u_g.mshrs_15.acquire_ts;
    force u_i.u_core.mshrs[15].entry.u_core.release_ts = u_g.mshrs_15.release_ts;
    force u_i.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g.mshrs_15.acquire_period_valid_REG;
    force u_i.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g.mshrs_15.release_period_valid_REG;
    force u_i.u_core.mshrs[15].entry.u_core.REG = u_g.mshrs_15.REG;
    force u_i.u_core.mshrs[15].entry.u_core.REG_1 = u_g.mshrs_15.REG_1;
    force u_i.u_core.mshrs[15].entry.u_core.REG_2 = u_g.mshrs_15.REG_2;
    force u_i.u_core.mshrs[15].entry.u_core.REG_3 = u_g.mshrs_15.REG_3;
    force u_i.u_core.io_perf_0_value_REG = u_g.io_perf_0_value_REG;
    force u_i.u_core.io_perf_0_value_REG_1 = u_g.io_perf_0_value_REG_1;
    force u_i.u_core.io_perf_1_value_REG = u_g.io_perf_1_value_REG;
    force u_i.u_core.io_perf_1_value_REG_1 = u_g.io_perf_1_value_REG_1;
    force u_i.u_core.io_perf_3_value_REG = u_g.io_perf_3_value_REG;
    force u_i.u_core.io_perf_3_value_REG_1 = u_g.io_perf_3_value_REG_1;
    force u_i.u_core.REG = u_g.REG;
    #1;
    release u_i.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[0].entry.u_core.REG;
    release u_i.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[1].entry.u_core.REG;
    release u_i.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[2].entry.u_core.REG;
    release u_i.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[3].entry.u_core.REG;
    release u_i.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[4].entry.u_core.REG;
    release u_i.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[5].entry.u_core.REG;
    release u_i.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[6].entry.u_core.REG;
    release u_i.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[7].entry.u_core.REG;
    release u_i.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[8].entry.u_core.REG;
    release u_i.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[9].entry.u_core.REG;
    release u_i.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[10].entry.u_core.REG;
    release u_i.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[11].entry.u_core.REG;
    release u_i.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[12].entry.u_core.REG;
    release u_i.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[13].entry.u_core.REG;
    release u_i.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[14].entry.u_core.REG;
    release u_i.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i.u_core.mshrs[15].entry.u_core.REG;
    release u_i.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i.u_core.io_perf_0_value_REG;
    release u_i.u_core.io_perf_0_value_REG_1;
    release u_i.u_core.io_perf_1_value_REG;
    release u_i.u_core.io_perf_1_value_REG_1;
    release u_i.u_core.io_perf_3_value_REG;
    release u_i.u_core.io_perf_3_value_REG_1;
    release u_i.u_core.REG;
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
