// 自动生成 scripts/gen_l2mainpipe.py —— 勿手改
// MainPipe 双例化逐拍比对: golden MainPipe_1 vs 可读重写 MainPipe_1_xs。
// 偏置 channel/txChannel one-hot, opcode/chiOpcode/param/set/tag 偏小。两侧共用 golden CustomL1Hint。
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
  logic io_taskFromArb_s2_valid;
  logic [2:0] io_taskFromArb_s2_bits_channel;
  logic [2:0] io_taskFromArb_s2_bits_txChannel;
  logic [8:0] io_taskFromArb_s2_bits_set;
  logic [30:0] io_taskFromArb_s2_bits_tag;
  logic [5:0] io_taskFromArb_s2_bits_off;
  logic [1:0] io_taskFromArb_s2_bits_alias;
  logic [43:0] io_taskFromArb_s2_bits_vaddr;
  logic io_taskFromArb_s2_bits_isKeyword;
  logic [3:0] io_taskFromArb_s2_bits_opcode;
  logic [2:0] io_taskFromArb_s2_bits_param;
  logic [2:0] io_taskFromArb_s2_bits_size;
  logic [6:0] io_taskFromArb_s2_bits_sourceId;
  logic [1:0] io_taskFromArb_s2_bits_bufIdx;
  logic io_taskFromArb_s2_bits_needProbeAckData;
  logic io_taskFromArb_s2_bits_denied;
  logic io_taskFromArb_s2_bits_corrupt;
  logic io_taskFromArb_s2_bits_mshrTask;
  logic [7:0] io_taskFromArb_s2_bits_mshrId;
  logic io_taskFromArb_s2_bits_aliasTask;
  logic io_taskFromArb_s2_bits_useProbeData;
  logic io_taskFromArb_s2_bits_mshrRetry;
  logic io_taskFromArb_s2_bits_readProbeDataDown;
  logic io_taskFromArb_s2_bits_fromL2pft;
  logic io_taskFromArb_s2_bits_needHint;
  logic io_taskFromArb_s2_bits_dirty;
  logic [2:0] io_taskFromArb_s2_bits_way;
  logic io_taskFromArb_s2_bits_meta_dirty;
  logic [1:0] io_taskFromArb_s2_bits_meta_state;
  logic io_taskFromArb_s2_bits_meta_clients;
  logic [1:0] io_taskFromArb_s2_bits_meta_alias;
  logic io_taskFromArb_s2_bits_meta_prefetch;
  logic [2:0] io_taskFromArb_s2_bits_meta_prefetchSrc;
  logic io_taskFromArb_s2_bits_meta_accessed;
  logic io_taskFromArb_s2_bits_meta_tagErr;
  logic io_taskFromArb_s2_bits_meta_dataErr;
  logic io_taskFromArb_s2_bits_metaWen;
  logic io_taskFromArb_s2_bits_tagWen;
  logic io_taskFromArb_s2_bits_dsWen;
  logic [7:0] io_taskFromArb_s2_bits_wayMask;
  logic io_taskFromArb_s2_bits_replTask;
  logic io_taskFromArb_s2_bits_cmoTask;
  logic io_taskFromArb_s2_bits_cmoAll;
  logic [4:0] io_taskFromArb_s2_bits_reqSource;
  logic io_taskFromArb_s2_bits_mergeA;
  logic [5:0] io_taskFromArb_s2_bits_aMergeTask_off;
  logic [1:0] io_taskFromArb_s2_bits_aMergeTask_alias;
  logic [43:0] io_taskFromArb_s2_bits_aMergeTask_vaddr;
  logic io_taskFromArb_s2_bits_aMergeTask_isKeyword;
  logic [2:0] io_taskFromArb_s2_bits_aMergeTask_opcode;
  logic [2:0] io_taskFromArb_s2_bits_aMergeTask_param;
  logic [6:0] io_taskFromArb_s2_bits_aMergeTask_sourceId;
  logic io_taskFromArb_s2_bits_aMergeTask_meta_dirty;
  logic [1:0] io_taskFromArb_s2_bits_aMergeTask_meta_state;
  logic io_taskFromArb_s2_bits_aMergeTask_meta_clients;
  logic [1:0] io_taskFromArb_s2_bits_aMergeTask_meta_alias;
  logic io_taskFromArb_s2_bits_aMergeTask_meta_prefetch;
  logic [2:0] io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc;
  logic io_taskFromArb_s2_bits_aMergeTask_meta_accessed;
  logic io_taskFromArb_s2_bits_aMergeTask_meta_tagErr;
  logic io_taskFromArb_s2_bits_aMergeTask_meta_dataErr;
  logic io_taskFromArb_s2_bits_snpHitRelease;
  logic io_taskFromArb_s2_bits_snpHitReleaseToInval;
  logic io_taskFromArb_s2_bits_snpHitReleaseToClean;
  logic io_taskFromArb_s2_bits_snpHitReleaseWithData;
  logic [7:0] io_taskFromArb_s2_bits_snpHitReleaseIdx;
  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_state;
  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_alias;
  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed;
  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr;
  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_taskFromArb_s2_bits_tgtID;
  logic [10:0] io_taskFromArb_s2_bits_srcID;
  logic [11:0] io_taskFromArb_s2_bits_txnID;
  logic [10:0] io_taskFromArb_s2_bits_homeNID;
  logic [11:0] io_taskFromArb_s2_bits_dbID;
  logic [10:0] io_taskFromArb_s2_bits_fwdNID;
  logic [11:0] io_taskFromArb_s2_bits_fwdTxnID;
  logic [6:0] io_taskFromArb_s2_bits_chiOpcode;
  logic [2:0] io_taskFromArb_s2_bits_resp;
  logic [2:0] io_taskFromArb_s2_bits_fwdState;
  logic [3:0] io_taskFromArb_s2_bits_pCrdType;
  logic io_taskFromArb_s2_bits_retToSrc;
  logic io_taskFromArb_s2_bits_likelyshared;
  logic io_taskFromArb_s2_bits_expCompAck;
  logic io_taskFromArb_s2_bits_allowRetry;
  logic io_taskFromArb_s2_bits_memAttr_allocate;
  logic io_taskFromArb_s2_bits_memAttr_cacheable;
  logic io_taskFromArb_s2_bits_memAttr_device;
  logic io_taskFromArb_s2_bits_memAttr_ewa;
  logic io_taskFromArb_s2_bits_traceTag;
  logic io_taskFromArb_s2_bits_dataCheckErr;
  logic io_taskInfo_s1_valid;
  logic [2:0] io_taskInfo_s1_bits_channel;
  logic io_taskInfo_s1_bits_isKeyword;
  logic [3:0] io_taskInfo_s1_bits_opcode;
  logic [6:0] io_taskInfo_s1_bits_sourceId;
  logic io_taskInfo_s1_bits_mshrTask;
  logic io_taskInfo_s1_bits_mergeA;
  logic io_taskInfo_s1_bits_aMergeTask_isKeyword;
  logic [2:0] io_taskInfo_s1_bits_aMergeTask_opcode;
  logic [6:0] io_taskInfo_s1_bits_aMergeTask_sourceId;
  logic [30:0] io_fromReqArb_status_s1_tags_1;
  logic [8:0] io_fromReqArb_status_s1_sets_0;
  logic [8:0] io_fromReqArb_status_s1_sets_1;
  logic [8:0] io_fromReqArb_status_s1_sets_2;
  logic [8:0] io_fromReqArb_status_s1_sets_3;
  logic io_dirResp_s3_hit;
  logic [30:0] io_dirResp_s3_tag;
  logic [8:0] io_dirResp_s3_set;
  logic [2:0] io_dirResp_s3_way;
  logic io_dirResp_s3_meta_dirty;
  logic [1:0] io_dirResp_s3_meta_state;
  logic io_dirResp_s3_meta_clients;
  logic [1:0] io_dirResp_s3_meta_alias;
  logic io_dirResp_s3_meta_prefetch;
  logic [2:0] io_dirResp_s3_meta_prefetchSrc;
  logic io_dirResp_s3_meta_accessed;
  logic io_dirResp_s3_meta_tagErr;
  logic io_dirResp_s3_meta_dataErr;
  logic io_dirResp_s3_error;
  logic io_replResp_valid;
  logic [2:0] io_replResp_bits_way;
  logic [1:0] io_replResp_bits_meta_state;
  logic io_replResp_bits_retry;
  logic [7:0] io_fromMSHRCtl_mshr_alloc_ptr;
  logic [255:0] io_bufResp_data_0;
  logic [255:0] io_bufResp_data_1;
  logic [511:0] io_refillBufResp_s3_bits_data;
  logic io_releaseBufResp_s3_valid;
  logic [511:0] io_releaseBufResp_s3_bits_data;
  logic [511:0] io_toDS_rdata_s5_data;
  logic io_toDS_error_s5;
  logic io_toTXDAT_ready;
  logic io_l1Hint_ready;
  logic io_prefetchTrain_ready;
  wire g_io_toReqArb_blockG_s1;
  wire i_io_toReqArb_blockG_s1;
  wire g_io_toReqArb_blockB_s1;
  wire i_io_toReqArb_blockB_s1;
  wire g_io_toReqArb_blockC_s1;
  wire i_io_toReqArb_blockC_s1;
  wire g_io_toReqBuf_0;
  wire i_io_toReqBuf_0;
  wire g_io_toReqBuf_1;
  wire i_io_toReqBuf_1;
  wire g_io_status_vec_toD_0_valid;
  wire i_io_status_vec_toD_0_valid;
  wire [2:0] g_io_status_vec_toD_0_bits_channel;
  wire [2:0] i_io_status_vec_toD_0_bits_channel;
  wire g_io_status_vec_toD_1_valid;
  wire i_io_status_vec_toD_1_valid;
  wire [2:0] g_io_status_vec_toD_1_bits_channel;
  wire [2:0] i_io_status_vec_toD_1_bits_channel;
  wire g_io_status_vec_toD_2_valid;
  wire i_io_status_vec_toD_2_valid;
  wire [2:0] g_io_status_vec_toD_2_bits_channel;
  wire [2:0] i_io_status_vec_toD_2_bits_channel;
  wire g_io_status_vec_toTX_0_valid;
  wire i_io_status_vec_toTX_0_valid;
  wire [2:0] g_io_status_vec_toTX_0_bits_channel;
  wire [2:0] i_io_status_vec_toTX_0_bits_channel;
  wire [2:0] g_io_status_vec_toTX_0_bits_txChannel;
  wire [2:0] i_io_status_vec_toTX_0_bits_txChannel;
  wire g_io_status_vec_toTX_0_bits_mshrTask;
  wire i_io_status_vec_toTX_0_bits_mshrTask;
  wire g_io_status_vec_toTX_1_valid;
  wire i_io_status_vec_toTX_1_valid;
  wire [2:0] g_io_status_vec_toTX_1_bits_channel;
  wire [2:0] i_io_status_vec_toTX_1_bits_channel;
  wire [2:0] g_io_status_vec_toTX_1_bits_txChannel;
  wire [2:0] i_io_status_vec_toTX_1_bits_txChannel;
  wire g_io_status_vec_toTX_1_bits_mshrTask;
  wire i_io_status_vec_toTX_1_bits_mshrTask;
  wire g_io_status_vec_toTX_2_valid;
  wire i_io_status_vec_toTX_2_valid;
  wire [2:0] g_io_status_vec_toTX_2_bits_channel;
  wire [2:0] i_io_status_vec_toTX_2_bits_channel;
  wire [2:0] g_io_status_vec_toTX_2_bits_txChannel;
  wire [2:0] i_io_status_vec_toTX_2_bits_txChannel;
  wire g_io_status_vec_toTX_2_bits_mshrTask;
  wire i_io_status_vec_toTX_2_bits_mshrTask;
  wire g_io_toMSHRCtl_mshr_alloc_s3_valid;
  wire i_io_toMSHRCtl_mshr_alloc_s3_valid;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit;
  wire [30:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag;
  wire [30:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag;
  wire [8:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set;
  wire [8:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set;
  wire [2:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way;
  wire [2:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty;
  wire [1:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state;
  wire [1:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients;
  wire [1:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias;
  wire [1:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch;
  wire [2:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc;
  wire [2:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct;
  wire [2:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_channel;
  wire [2:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_channel;
  wire [8:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_set;
  wire [8:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_set;
  wire [30:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_tag;
  wire [30:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_tag;
  wire [5:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_off;
  wire [5:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_off;
  wire [1:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_alias;
  wire [1:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_alias;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword;
  wire [3:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode;
  wire [3:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode;
  wire [2:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_param;
  wire [2:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_param;
  wire [6:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId;
  wire [6:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft;
  wire [4:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource;
  wire [4:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData;
  wire [7:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx;
  wire [7:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state;
  wire [1:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients;
  wire [1:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias;
  wire [1:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID;
  wire [10:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID;
  wire [11:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID;
  wire [11:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID;
  wire [10:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID;
  wire [10:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID;
  wire [11:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID;
  wire [11:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID;
  wire [6:0] g_io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode;
  wire [6:0] i_io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc;
  wire g_io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag;
  wire i_io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag;
  wire g_io_toDS_en_s3;
  wire i_io_toDS_en_s3;
  wire g_io_toDS_req_s3_valid;
  wire i_io_toDS_req_s3_valid;
  wire [2:0] g_io_toDS_req_s3_bits_way;
  wire [2:0] i_io_toDS_req_s3_bits_way;
  wire [8:0] g_io_toDS_req_s3_bits_set;
  wire [8:0] i_io_toDS_req_s3_bits_set;
  wire g_io_toDS_req_s3_bits_wen;
  wire i_io_toDS_req_s3_bits_wen;
  wire [511:0] g_io_toDS_wdata_s3_data;
  wire [511:0] i_io_toDS_wdata_s3_data;
  wire g_io_toSourceD_valid;
  wire i_io_toSourceD_valid;
  wire [2:0] g_io_toSourceD_bits_task_channel;
  wire [2:0] i_io_toSourceD_bits_task_channel;
  wire [2:0] g_io_toSourceD_bits_task_txChannel;
  wire [2:0] i_io_toSourceD_bits_task_txChannel;
  wire [8:0] g_io_toSourceD_bits_task_set;
  wire [8:0] i_io_toSourceD_bits_task_set;
  wire [30:0] g_io_toSourceD_bits_task_tag;
  wire [30:0] i_io_toSourceD_bits_task_tag;
  wire [5:0] g_io_toSourceD_bits_task_off;
  wire [5:0] i_io_toSourceD_bits_task_off;
  wire [1:0] g_io_toSourceD_bits_task_alias;
  wire [1:0] i_io_toSourceD_bits_task_alias;
  wire [43:0] g_io_toSourceD_bits_task_vaddr;
  wire [43:0] i_io_toSourceD_bits_task_vaddr;
  wire g_io_toSourceD_bits_task_isKeyword;
  wire i_io_toSourceD_bits_task_isKeyword;
  wire [3:0] g_io_toSourceD_bits_task_opcode;
  wire [3:0] i_io_toSourceD_bits_task_opcode;
  wire [2:0] g_io_toSourceD_bits_task_param;
  wire [2:0] i_io_toSourceD_bits_task_param;
  wire [2:0] g_io_toSourceD_bits_task_size;
  wire [2:0] i_io_toSourceD_bits_task_size;
  wire [6:0] g_io_toSourceD_bits_task_sourceId;
  wire [6:0] i_io_toSourceD_bits_task_sourceId;
  wire [1:0] g_io_toSourceD_bits_task_bufIdx;
  wire [1:0] i_io_toSourceD_bits_task_bufIdx;
  wire g_io_toSourceD_bits_task_needProbeAckData;
  wire i_io_toSourceD_bits_task_needProbeAckData;
  wire g_io_toSourceD_bits_task_denied;
  wire i_io_toSourceD_bits_task_denied;
  wire g_io_toSourceD_bits_task_corrupt;
  wire i_io_toSourceD_bits_task_corrupt;
  wire g_io_toSourceD_bits_task_mshrTask;
  wire i_io_toSourceD_bits_task_mshrTask;
  wire [7:0] g_io_toSourceD_bits_task_mshrId;
  wire [7:0] i_io_toSourceD_bits_task_mshrId;
  wire g_io_toSourceD_bits_task_aliasTask;
  wire i_io_toSourceD_bits_task_aliasTask;
  wire g_io_toSourceD_bits_task_useProbeData;
  wire i_io_toSourceD_bits_task_useProbeData;
  wire g_io_toSourceD_bits_task_mshrRetry;
  wire i_io_toSourceD_bits_task_mshrRetry;
  wire g_io_toSourceD_bits_task_readProbeDataDown;
  wire i_io_toSourceD_bits_task_readProbeDataDown;
  wire g_io_toSourceD_bits_task_fromL2pft;
  wire i_io_toSourceD_bits_task_fromL2pft;
  wire g_io_toSourceD_bits_task_needHint;
  wire i_io_toSourceD_bits_task_needHint;
  wire g_io_toSourceD_bits_task_dirty;
  wire i_io_toSourceD_bits_task_dirty;
  wire [2:0] g_io_toSourceD_bits_task_way;
  wire [2:0] i_io_toSourceD_bits_task_way;
  wire g_io_toSourceD_bits_task_meta_dirty;
  wire i_io_toSourceD_bits_task_meta_dirty;
  wire [1:0] g_io_toSourceD_bits_task_meta_state;
  wire [1:0] i_io_toSourceD_bits_task_meta_state;
  wire g_io_toSourceD_bits_task_meta_clients;
  wire i_io_toSourceD_bits_task_meta_clients;
  wire [1:0] g_io_toSourceD_bits_task_meta_alias;
  wire [1:0] i_io_toSourceD_bits_task_meta_alias;
  wire g_io_toSourceD_bits_task_meta_prefetch;
  wire i_io_toSourceD_bits_task_meta_prefetch;
  wire [2:0] g_io_toSourceD_bits_task_meta_prefetchSrc;
  wire [2:0] i_io_toSourceD_bits_task_meta_prefetchSrc;
  wire g_io_toSourceD_bits_task_meta_accessed;
  wire i_io_toSourceD_bits_task_meta_accessed;
  wire g_io_toSourceD_bits_task_meta_tagErr;
  wire i_io_toSourceD_bits_task_meta_tagErr;
  wire g_io_toSourceD_bits_task_meta_dataErr;
  wire i_io_toSourceD_bits_task_meta_dataErr;
  wire g_io_toSourceD_bits_task_metaWen;
  wire i_io_toSourceD_bits_task_metaWen;
  wire g_io_toSourceD_bits_task_tagWen;
  wire i_io_toSourceD_bits_task_tagWen;
  wire g_io_toSourceD_bits_task_dsWen;
  wire i_io_toSourceD_bits_task_dsWen;
  wire [7:0] g_io_toSourceD_bits_task_wayMask;
  wire [7:0] i_io_toSourceD_bits_task_wayMask;
  wire g_io_toSourceD_bits_task_replTask;
  wire i_io_toSourceD_bits_task_replTask;
  wire g_io_toSourceD_bits_task_cmoTask;
  wire i_io_toSourceD_bits_task_cmoTask;
  wire g_io_toSourceD_bits_task_cmoAll;
  wire i_io_toSourceD_bits_task_cmoAll;
  wire [4:0] g_io_toSourceD_bits_task_reqSource;
  wire [4:0] i_io_toSourceD_bits_task_reqSource;
  wire g_io_toSourceD_bits_task_mergeA;
  wire i_io_toSourceD_bits_task_mergeA;
  wire [5:0] g_io_toSourceD_bits_task_aMergeTask_off;
  wire [5:0] i_io_toSourceD_bits_task_aMergeTask_off;
  wire [1:0] g_io_toSourceD_bits_task_aMergeTask_alias;
  wire [1:0] i_io_toSourceD_bits_task_aMergeTask_alias;
  wire [43:0] g_io_toSourceD_bits_task_aMergeTask_vaddr;
  wire [43:0] i_io_toSourceD_bits_task_aMergeTask_vaddr;
  wire g_io_toSourceD_bits_task_aMergeTask_isKeyword;
  wire i_io_toSourceD_bits_task_aMergeTask_isKeyword;
  wire [2:0] g_io_toSourceD_bits_task_aMergeTask_opcode;
  wire [2:0] i_io_toSourceD_bits_task_aMergeTask_opcode;
  wire [2:0] g_io_toSourceD_bits_task_aMergeTask_param;
  wire [2:0] i_io_toSourceD_bits_task_aMergeTask_param;
  wire [6:0] g_io_toSourceD_bits_task_aMergeTask_sourceId;
  wire [6:0] i_io_toSourceD_bits_task_aMergeTask_sourceId;
  wire g_io_toSourceD_bits_task_aMergeTask_meta_dirty;
  wire i_io_toSourceD_bits_task_aMergeTask_meta_dirty;
  wire [1:0] g_io_toSourceD_bits_task_aMergeTask_meta_state;
  wire [1:0] i_io_toSourceD_bits_task_aMergeTask_meta_state;
  wire g_io_toSourceD_bits_task_aMergeTask_meta_clients;
  wire i_io_toSourceD_bits_task_aMergeTask_meta_clients;
  wire [1:0] g_io_toSourceD_bits_task_aMergeTask_meta_alias;
  wire [1:0] i_io_toSourceD_bits_task_aMergeTask_meta_alias;
  wire g_io_toSourceD_bits_task_aMergeTask_meta_prefetch;
  wire i_io_toSourceD_bits_task_aMergeTask_meta_prefetch;
  wire [2:0] g_io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc;
  wire [2:0] i_io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc;
  wire g_io_toSourceD_bits_task_aMergeTask_meta_accessed;
  wire i_io_toSourceD_bits_task_aMergeTask_meta_accessed;
  wire g_io_toSourceD_bits_task_aMergeTask_meta_tagErr;
  wire i_io_toSourceD_bits_task_aMergeTask_meta_tagErr;
  wire g_io_toSourceD_bits_task_aMergeTask_meta_dataErr;
  wire i_io_toSourceD_bits_task_aMergeTask_meta_dataErr;
  wire g_io_toSourceD_bits_task_snpHitRelease;
  wire i_io_toSourceD_bits_task_snpHitRelease;
  wire g_io_toSourceD_bits_task_snpHitReleaseToInval;
  wire i_io_toSourceD_bits_task_snpHitReleaseToInval;
  wire g_io_toSourceD_bits_task_snpHitReleaseToClean;
  wire i_io_toSourceD_bits_task_snpHitReleaseToClean;
  wire g_io_toSourceD_bits_task_snpHitReleaseWithData;
  wire i_io_toSourceD_bits_task_snpHitReleaseWithData;
  wire [7:0] g_io_toSourceD_bits_task_snpHitReleaseIdx;
  wire [7:0] i_io_toSourceD_bits_task_snpHitReleaseIdx;
  wire g_io_toSourceD_bits_task_snpHitReleaseMeta_dirty;
  wire i_io_toSourceD_bits_task_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_toSourceD_bits_task_snpHitReleaseMeta_state;
  wire [1:0] i_io_toSourceD_bits_task_snpHitReleaseMeta_state;
  wire g_io_toSourceD_bits_task_snpHitReleaseMeta_clients;
  wire i_io_toSourceD_bits_task_snpHitReleaseMeta_clients;
  wire [1:0] g_io_toSourceD_bits_task_snpHitReleaseMeta_alias;
  wire [1:0] i_io_toSourceD_bits_task_snpHitReleaseMeta_alias;
  wire g_io_toSourceD_bits_task_snpHitReleaseMeta_prefetch;
  wire i_io_toSourceD_bits_task_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire g_io_toSourceD_bits_task_snpHitReleaseMeta_accessed;
  wire i_io_toSourceD_bits_task_snpHitReleaseMeta_accessed;
  wire g_io_toSourceD_bits_task_snpHitReleaseMeta_tagErr;
  wire i_io_toSourceD_bits_task_snpHitReleaseMeta_tagErr;
  wire g_io_toSourceD_bits_task_snpHitReleaseMeta_dataErr;
  wire i_io_toSourceD_bits_task_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_toSourceD_bits_task_tgtID;
  wire [10:0] i_io_toSourceD_bits_task_tgtID;
  wire [10:0] g_io_toSourceD_bits_task_srcID;
  wire [10:0] i_io_toSourceD_bits_task_srcID;
  wire [11:0] g_io_toSourceD_bits_task_txnID;
  wire [11:0] i_io_toSourceD_bits_task_txnID;
  wire [10:0] g_io_toSourceD_bits_task_homeNID;
  wire [10:0] i_io_toSourceD_bits_task_homeNID;
  wire [11:0] g_io_toSourceD_bits_task_dbID;
  wire [11:0] i_io_toSourceD_bits_task_dbID;
  wire [10:0] g_io_toSourceD_bits_task_fwdNID;
  wire [10:0] i_io_toSourceD_bits_task_fwdNID;
  wire [11:0] g_io_toSourceD_bits_task_fwdTxnID;
  wire [11:0] i_io_toSourceD_bits_task_fwdTxnID;
  wire [6:0] g_io_toSourceD_bits_task_chiOpcode;
  wire [6:0] i_io_toSourceD_bits_task_chiOpcode;
  wire [2:0] g_io_toSourceD_bits_task_resp;
  wire [2:0] i_io_toSourceD_bits_task_resp;
  wire [2:0] g_io_toSourceD_bits_task_fwdState;
  wire [2:0] i_io_toSourceD_bits_task_fwdState;
  wire [3:0] g_io_toSourceD_bits_task_pCrdType;
  wire [3:0] i_io_toSourceD_bits_task_pCrdType;
  wire g_io_toSourceD_bits_task_retToSrc;
  wire i_io_toSourceD_bits_task_retToSrc;
  wire g_io_toSourceD_bits_task_likelyshared;
  wire i_io_toSourceD_bits_task_likelyshared;
  wire g_io_toSourceD_bits_task_expCompAck;
  wire i_io_toSourceD_bits_task_expCompAck;
  wire g_io_toSourceD_bits_task_allowRetry;
  wire i_io_toSourceD_bits_task_allowRetry;
  wire g_io_toSourceD_bits_task_memAttr_allocate;
  wire i_io_toSourceD_bits_task_memAttr_allocate;
  wire g_io_toSourceD_bits_task_memAttr_cacheable;
  wire i_io_toSourceD_bits_task_memAttr_cacheable;
  wire g_io_toSourceD_bits_task_memAttr_device;
  wire i_io_toSourceD_bits_task_memAttr_device;
  wire g_io_toSourceD_bits_task_memAttr_ewa;
  wire i_io_toSourceD_bits_task_memAttr_ewa;
  wire g_io_toSourceD_bits_task_traceTag;
  wire i_io_toSourceD_bits_task_traceTag;
  wire g_io_toSourceD_bits_task_dataCheckErr;
  wire i_io_toSourceD_bits_task_dataCheckErr;
  wire [511:0] g_io_toSourceD_bits_data_data;
  wire [511:0] i_io_toSourceD_bits_data_data;
  wire g_io_toTXREQ_valid;
  wire i_io_toTXREQ_valid;
  wire [10:0] g_io_toTXREQ_bits_tgtID;
  wire [10:0] i_io_toTXREQ_bits_tgtID;
  wire [10:0] g_io_toTXREQ_bits_srcID;
  wire [10:0] i_io_toTXREQ_bits_srcID;
  wire [11:0] g_io_toTXREQ_bits_txnID;
  wire [11:0] i_io_toTXREQ_bits_txnID;
  wire [6:0] g_io_toTXREQ_bits_opcode;
  wire [6:0] i_io_toTXREQ_bits_opcode;
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
  wire g_io_toTXREQ_bits_memAttr_device;
  wire i_io_toTXREQ_bits_memAttr_device;
  wire g_io_toTXREQ_bits_memAttr_ewa;
  wire i_io_toTXREQ_bits_memAttr_ewa;
  wire g_io_toTXREQ_bits_expCompAck;
  wire i_io_toTXREQ_bits_expCompAck;
  wire g_io_toTXRSP_valid;
  wire i_io_toTXRSP_valid;
  wire [2:0] g_io_toTXRSP_bits_txChannel;
  wire [2:0] i_io_toTXRSP_bits_txChannel;
  wire g_io_toTXRSP_bits_denied;
  wire i_io_toTXRSP_bits_denied;
  wire [10:0] g_io_toTXRSP_bits_tgtID;
  wire [10:0] i_io_toTXRSP_bits_tgtID;
  wire [10:0] g_io_toTXRSP_bits_srcID;
  wire [10:0] i_io_toTXRSP_bits_srcID;
  wire [11:0] g_io_toTXRSP_bits_txnID;
  wire [11:0] i_io_toTXRSP_bits_txnID;
  wire [11:0] g_io_toTXRSP_bits_dbID;
  wire [11:0] i_io_toTXRSP_bits_dbID;
  wire [6:0] g_io_toTXRSP_bits_chiOpcode;
  wire [6:0] i_io_toTXRSP_bits_chiOpcode;
  wire [2:0] g_io_toTXRSP_bits_resp;
  wire [2:0] i_io_toTXRSP_bits_resp;
  wire [2:0] g_io_toTXRSP_bits_fwdState;
  wire [2:0] i_io_toTXRSP_bits_fwdState;
  wire [3:0] g_io_toTXRSP_bits_pCrdType;
  wire [3:0] i_io_toTXRSP_bits_pCrdType;
  wire g_io_toTXRSP_bits_traceTag;
  wire i_io_toTXRSP_bits_traceTag;
  wire g_io_toTXDAT_valid;
  wire i_io_toTXDAT_valid;
  wire [2:0] g_io_toTXDAT_bits_task_channel;
  wire [2:0] i_io_toTXDAT_bits_task_channel;
  wire [2:0] g_io_toTXDAT_bits_task_txChannel;
  wire [2:0] i_io_toTXDAT_bits_task_txChannel;
  wire [8:0] g_io_toTXDAT_bits_task_set;
  wire [8:0] i_io_toTXDAT_bits_task_set;
  wire [30:0] g_io_toTXDAT_bits_task_tag;
  wire [30:0] i_io_toTXDAT_bits_task_tag;
  wire [5:0] g_io_toTXDAT_bits_task_off;
  wire [5:0] i_io_toTXDAT_bits_task_off;
  wire [1:0] g_io_toTXDAT_bits_task_alias;
  wire [1:0] i_io_toTXDAT_bits_task_alias;
  wire [43:0] g_io_toTXDAT_bits_task_vaddr;
  wire [43:0] i_io_toTXDAT_bits_task_vaddr;
  wire g_io_toTXDAT_bits_task_isKeyword;
  wire i_io_toTXDAT_bits_task_isKeyword;
  wire [3:0] g_io_toTXDAT_bits_task_opcode;
  wire [3:0] i_io_toTXDAT_bits_task_opcode;
  wire [2:0] g_io_toTXDAT_bits_task_param;
  wire [2:0] i_io_toTXDAT_bits_task_param;
  wire [2:0] g_io_toTXDAT_bits_task_size;
  wire [2:0] i_io_toTXDAT_bits_task_size;
  wire [6:0] g_io_toTXDAT_bits_task_sourceId;
  wire [6:0] i_io_toTXDAT_bits_task_sourceId;
  wire [1:0] g_io_toTXDAT_bits_task_bufIdx;
  wire [1:0] i_io_toTXDAT_bits_task_bufIdx;
  wire g_io_toTXDAT_bits_task_needProbeAckData;
  wire i_io_toTXDAT_bits_task_needProbeAckData;
  wire g_io_toTXDAT_bits_task_denied;
  wire i_io_toTXDAT_bits_task_denied;
  wire g_io_toTXDAT_bits_task_corrupt;
  wire i_io_toTXDAT_bits_task_corrupt;
  wire g_io_toTXDAT_bits_task_mshrTask;
  wire i_io_toTXDAT_bits_task_mshrTask;
  wire [7:0] g_io_toTXDAT_bits_task_mshrId;
  wire [7:0] i_io_toTXDAT_bits_task_mshrId;
  wire g_io_toTXDAT_bits_task_aliasTask;
  wire i_io_toTXDAT_bits_task_aliasTask;
  wire g_io_toTXDAT_bits_task_useProbeData;
  wire i_io_toTXDAT_bits_task_useProbeData;
  wire g_io_toTXDAT_bits_task_mshrRetry;
  wire i_io_toTXDAT_bits_task_mshrRetry;
  wire g_io_toTXDAT_bits_task_readProbeDataDown;
  wire i_io_toTXDAT_bits_task_readProbeDataDown;
  wire g_io_toTXDAT_bits_task_fromL2pft;
  wire i_io_toTXDAT_bits_task_fromL2pft;
  wire g_io_toTXDAT_bits_task_needHint;
  wire i_io_toTXDAT_bits_task_needHint;
  wire g_io_toTXDAT_bits_task_dirty;
  wire i_io_toTXDAT_bits_task_dirty;
  wire [2:0] g_io_toTXDAT_bits_task_way;
  wire [2:0] i_io_toTXDAT_bits_task_way;
  wire g_io_toTXDAT_bits_task_meta_dirty;
  wire i_io_toTXDAT_bits_task_meta_dirty;
  wire [1:0] g_io_toTXDAT_bits_task_meta_state;
  wire [1:0] i_io_toTXDAT_bits_task_meta_state;
  wire g_io_toTXDAT_bits_task_meta_clients;
  wire i_io_toTXDAT_bits_task_meta_clients;
  wire [1:0] g_io_toTXDAT_bits_task_meta_alias;
  wire [1:0] i_io_toTXDAT_bits_task_meta_alias;
  wire g_io_toTXDAT_bits_task_meta_prefetch;
  wire i_io_toTXDAT_bits_task_meta_prefetch;
  wire [2:0] g_io_toTXDAT_bits_task_meta_prefetchSrc;
  wire [2:0] i_io_toTXDAT_bits_task_meta_prefetchSrc;
  wire g_io_toTXDAT_bits_task_meta_accessed;
  wire i_io_toTXDAT_bits_task_meta_accessed;
  wire g_io_toTXDAT_bits_task_meta_tagErr;
  wire i_io_toTXDAT_bits_task_meta_tagErr;
  wire g_io_toTXDAT_bits_task_meta_dataErr;
  wire i_io_toTXDAT_bits_task_meta_dataErr;
  wire g_io_toTXDAT_bits_task_metaWen;
  wire i_io_toTXDAT_bits_task_metaWen;
  wire g_io_toTXDAT_bits_task_tagWen;
  wire i_io_toTXDAT_bits_task_tagWen;
  wire g_io_toTXDAT_bits_task_dsWen;
  wire i_io_toTXDAT_bits_task_dsWen;
  wire [7:0] g_io_toTXDAT_bits_task_wayMask;
  wire [7:0] i_io_toTXDAT_bits_task_wayMask;
  wire g_io_toTXDAT_bits_task_replTask;
  wire i_io_toTXDAT_bits_task_replTask;
  wire g_io_toTXDAT_bits_task_cmoTask;
  wire i_io_toTXDAT_bits_task_cmoTask;
  wire g_io_toTXDAT_bits_task_cmoAll;
  wire i_io_toTXDAT_bits_task_cmoAll;
  wire [4:0] g_io_toTXDAT_bits_task_reqSource;
  wire [4:0] i_io_toTXDAT_bits_task_reqSource;
  wire g_io_toTXDAT_bits_task_mergeA;
  wire i_io_toTXDAT_bits_task_mergeA;
  wire [5:0] g_io_toTXDAT_bits_task_aMergeTask_off;
  wire [5:0] i_io_toTXDAT_bits_task_aMergeTask_off;
  wire [1:0] g_io_toTXDAT_bits_task_aMergeTask_alias;
  wire [1:0] i_io_toTXDAT_bits_task_aMergeTask_alias;
  wire [43:0] g_io_toTXDAT_bits_task_aMergeTask_vaddr;
  wire [43:0] i_io_toTXDAT_bits_task_aMergeTask_vaddr;
  wire g_io_toTXDAT_bits_task_aMergeTask_isKeyword;
  wire i_io_toTXDAT_bits_task_aMergeTask_isKeyword;
  wire [2:0] g_io_toTXDAT_bits_task_aMergeTask_opcode;
  wire [2:0] i_io_toTXDAT_bits_task_aMergeTask_opcode;
  wire [2:0] g_io_toTXDAT_bits_task_aMergeTask_param;
  wire [2:0] i_io_toTXDAT_bits_task_aMergeTask_param;
  wire [6:0] g_io_toTXDAT_bits_task_aMergeTask_sourceId;
  wire [6:0] i_io_toTXDAT_bits_task_aMergeTask_sourceId;
  wire g_io_toTXDAT_bits_task_aMergeTask_meta_dirty;
  wire i_io_toTXDAT_bits_task_aMergeTask_meta_dirty;
  wire [1:0] g_io_toTXDAT_bits_task_aMergeTask_meta_state;
  wire [1:0] i_io_toTXDAT_bits_task_aMergeTask_meta_state;
  wire g_io_toTXDAT_bits_task_aMergeTask_meta_clients;
  wire i_io_toTXDAT_bits_task_aMergeTask_meta_clients;
  wire [1:0] g_io_toTXDAT_bits_task_aMergeTask_meta_alias;
  wire [1:0] i_io_toTXDAT_bits_task_aMergeTask_meta_alias;
  wire g_io_toTXDAT_bits_task_aMergeTask_meta_prefetch;
  wire i_io_toTXDAT_bits_task_aMergeTask_meta_prefetch;
  wire [2:0] g_io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc;
  wire [2:0] i_io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc;
  wire g_io_toTXDAT_bits_task_aMergeTask_meta_accessed;
  wire i_io_toTXDAT_bits_task_aMergeTask_meta_accessed;
  wire g_io_toTXDAT_bits_task_aMergeTask_meta_tagErr;
  wire i_io_toTXDAT_bits_task_aMergeTask_meta_tagErr;
  wire g_io_toTXDAT_bits_task_aMergeTask_meta_dataErr;
  wire i_io_toTXDAT_bits_task_aMergeTask_meta_dataErr;
  wire g_io_toTXDAT_bits_task_snpHitRelease;
  wire i_io_toTXDAT_bits_task_snpHitRelease;
  wire g_io_toTXDAT_bits_task_snpHitReleaseToInval;
  wire i_io_toTXDAT_bits_task_snpHitReleaseToInval;
  wire g_io_toTXDAT_bits_task_snpHitReleaseToClean;
  wire i_io_toTXDAT_bits_task_snpHitReleaseToClean;
  wire g_io_toTXDAT_bits_task_snpHitReleaseWithData;
  wire i_io_toTXDAT_bits_task_snpHitReleaseWithData;
  wire [7:0] g_io_toTXDAT_bits_task_snpHitReleaseIdx;
  wire [7:0] i_io_toTXDAT_bits_task_snpHitReleaseIdx;
  wire g_io_toTXDAT_bits_task_snpHitReleaseMeta_dirty;
  wire i_io_toTXDAT_bits_task_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_toTXDAT_bits_task_snpHitReleaseMeta_state;
  wire [1:0] i_io_toTXDAT_bits_task_snpHitReleaseMeta_state;
  wire g_io_toTXDAT_bits_task_snpHitReleaseMeta_clients;
  wire i_io_toTXDAT_bits_task_snpHitReleaseMeta_clients;
  wire [1:0] g_io_toTXDAT_bits_task_snpHitReleaseMeta_alias;
  wire [1:0] i_io_toTXDAT_bits_task_snpHitReleaseMeta_alias;
  wire g_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch;
  wire i_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire g_io_toTXDAT_bits_task_snpHitReleaseMeta_accessed;
  wire i_io_toTXDAT_bits_task_snpHitReleaseMeta_accessed;
  wire g_io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr;
  wire i_io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr;
  wire g_io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr;
  wire i_io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_toTXDAT_bits_task_tgtID;
  wire [10:0] i_io_toTXDAT_bits_task_tgtID;
  wire [10:0] g_io_toTXDAT_bits_task_srcID;
  wire [10:0] i_io_toTXDAT_bits_task_srcID;
  wire [11:0] g_io_toTXDAT_bits_task_txnID;
  wire [11:0] i_io_toTXDAT_bits_task_txnID;
  wire [10:0] g_io_toTXDAT_bits_task_homeNID;
  wire [10:0] i_io_toTXDAT_bits_task_homeNID;
  wire [11:0] g_io_toTXDAT_bits_task_dbID;
  wire [11:0] i_io_toTXDAT_bits_task_dbID;
  wire [10:0] g_io_toTXDAT_bits_task_fwdNID;
  wire [10:0] i_io_toTXDAT_bits_task_fwdNID;
  wire [11:0] g_io_toTXDAT_bits_task_fwdTxnID;
  wire [11:0] i_io_toTXDAT_bits_task_fwdTxnID;
  wire [6:0] g_io_toTXDAT_bits_task_chiOpcode;
  wire [6:0] i_io_toTXDAT_bits_task_chiOpcode;
  wire [2:0] g_io_toTXDAT_bits_task_resp;
  wire [2:0] i_io_toTXDAT_bits_task_resp;
  wire [2:0] g_io_toTXDAT_bits_task_fwdState;
  wire [2:0] i_io_toTXDAT_bits_task_fwdState;
  wire [3:0] g_io_toTXDAT_bits_task_pCrdType;
  wire [3:0] i_io_toTXDAT_bits_task_pCrdType;
  wire g_io_toTXDAT_bits_task_retToSrc;
  wire i_io_toTXDAT_bits_task_retToSrc;
  wire g_io_toTXDAT_bits_task_likelyshared;
  wire i_io_toTXDAT_bits_task_likelyshared;
  wire g_io_toTXDAT_bits_task_expCompAck;
  wire i_io_toTXDAT_bits_task_expCompAck;
  wire g_io_toTXDAT_bits_task_allowRetry;
  wire i_io_toTXDAT_bits_task_allowRetry;
  wire g_io_toTXDAT_bits_task_memAttr_allocate;
  wire i_io_toTXDAT_bits_task_memAttr_allocate;
  wire g_io_toTXDAT_bits_task_memAttr_cacheable;
  wire i_io_toTXDAT_bits_task_memAttr_cacheable;
  wire g_io_toTXDAT_bits_task_memAttr_device;
  wire i_io_toTXDAT_bits_task_memAttr_device;
  wire g_io_toTXDAT_bits_task_memAttr_ewa;
  wire i_io_toTXDAT_bits_task_memAttr_ewa;
  wire g_io_toTXDAT_bits_task_traceTag;
  wire i_io_toTXDAT_bits_task_traceTag;
  wire g_io_toTXDAT_bits_task_dataCheckErr;
  wire i_io_toTXDAT_bits_task_dataCheckErr;
  wire [511:0] g_io_toTXDAT_bits_data_data;
  wire [511:0] i_io_toTXDAT_bits_data_data;
  wire g_io_metaWReq_valid;
  wire i_io_metaWReq_valid;
  wire [8:0] g_io_metaWReq_bits_set;
  wire [8:0] i_io_metaWReq_bits_set;
  wire [7:0] g_io_metaWReq_bits_wayOH;
  wire [7:0] i_io_metaWReq_bits_wayOH;
  wire g_io_metaWReq_bits_wmeta_dirty;
  wire i_io_metaWReq_bits_wmeta_dirty;
  wire [1:0] g_io_metaWReq_bits_wmeta_state;
  wire [1:0] i_io_metaWReq_bits_wmeta_state;
  wire g_io_metaWReq_bits_wmeta_clients;
  wire i_io_metaWReq_bits_wmeta_clients;
  wire [1:0] g_io_metaWReq_bits_wmeta_alias;
  wire [1:0] i_io_metaWReq_bits_wmeta_alias;
  wire g_io_metaWReq_bits_wmeta_prefetch;
  wire i_io_metaWReq_bits_wmeta_prefetch;
  wire [2:0] g_io_metaWReq_bits_wmeta_prefetchSrc;
  wire [2:0] i_io_metaWReq_bits_wmeta_prefetchSrc;
  wire g_io_metaWReq_bits_wmeta_accessed;
  wire i_io_metaWReq_bits_wmeta_accessed;
  wire g_io_metaWReq_bits_wmeta_tagErr;
  wire i_io_metaWReq_bits_wmeta_tagErr;
  wire g_io_metaWReq_bits_wmeta_dataErr;
  wire i_io_metaWReq_bits_wmeta_dataErr;
  wire g_io_tagWReq_valid;
  wire i_io_tagWReq_valid;
  wire [8:0] g_io_tagWReq_bits_set;
  wire [8:0] i_io_tagWReq_bits_set;
  wire [2:0] g_io_tagWReq_bits_way;
  wire [2:0] i_io_tagWReq_bits_way;
  wire [30:0] g_io_tagWReq_bits_wtag;
  wire [30:0] i_io_tagWReq_bits_wtag;
  wire g_io_releaseBufWrite_valid;
  wire i_io_releaseBufWrite_valid;
  wire [7:0] g_io_releaseBufWrite_bits_id;
  wire [7:0] i_io_releaseBufWrite_bits_id;
  wire [511:0] g_io_releaseBufWrite_bits_data_data;
  wire [511:0] i_io_releaseBufWrite_bits_data_data;
  wire [8:0] g_io_nestedwb_set;
  wire [8:0] i_io_nestedwb_set;
  wire [30:0] g_io_nestedwb_tag;
  wire [30:0] i_io_nestedwb_tag;
  wire g_io_nestedwb_c_set_dirty;
  wire i_io_nestedwb_c_set_dirty;
  wire g_io_nestedwb_c_set_tip;
  wire i_io_nestedwb_c_set_tip;
  wire g_io_nestedwb_b_inv_dirty;
  wire i_io_nestedwb_b_inv_dirty;
  wire g_io_nestedwb_b_toB;
  wire i_io_nestedwb_b_toB;
  wire g_io_nestedwb_b_toN;
  wire i_io_nestedwb_b_toN;
  wire g_io_nestedwb_b_toClean;
  wire i_io_nestedwb_b_toClean;
  wire [511:0] g_io_nestedwbData_data;
  wire [511:0] i_io_nestedwbData_data;
  wire g_io_l1Hint_valid;
  wire i_io_l1Hint_valid;
  wire [31:0] g_io_l1Hint_bits_sourceId;
  wire [31:0] i_io_l1Hint_bits_sourceId;
  wire g_io_l1Hint_bits_isKeyword;
  wire i_io_l1Hint_bits_isKeyword;
  wire g_io_prefetchTrain_valid;
  wire i_io_prefetchTrain_valid;
  wire [32:0] g_io_prefetchTrain_bits_tag;
  wire [32:0] i_io_prefetchTrain_bits_tag;
  wire [8:0] g_io_prefetchTrain_bits_set;
  wire [8:0] i_io_prefetchTrain_bits_set;
  wire g_io_prefetchTrain_bits_needT;
  wire i_io_prefetchTrain_bits_needT;
  wire [6:0] g_io_prefetchTrain_bits_source;
  wire [6:0] i_io_prefetchTrain_bits_source;
  wire [43:0] g_io_prefetchTrain_bits_vaddr;
  wire [43:0] i_io_prefetchTrain_bits_vaddr;
  wire g_io_prefetchTrain_bits_hit;
  wire i_io_prefetchTrain_bits_hit;
  wire g_io_prefetchTrain_bits_prefetched;
  wire i_io_prefetchTrain_bits_prefetched;
  wire [2:0] g_io_prefetchTrain_bits_pfsource;
  wire [2:0] i_io_prefetchTrain_bits_pfsource;
  wire [4:0] g_io_prefetchTrain_bits_reqsource;
  wire [4:0] i_io_prefetchTrain_bits_reqsource;
  wire g_io_error_valid;
  wire i_io_error_valid;
  wire g_io_error_bits_valid;
  wire i_io_error_bits_valid;
  wire [45:0] g_io_error_bits_address;
  wire [45:0] i_io_error_bits_address;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value;
  wire [5:0] i_io_perf_7_value;

  MainPipe_1 u_g (
    .clock(clock),
    .reset(reset),
    .io_taskFromArb_s2_valid(io_taskFromArb_s2_valid),
    .io_taskFromArb_s2_bits_channel(io_taskFromArb_s2_bits_channel),
    .io_taskFromArb_s2_bits_txChannel(io_taskFromArb_s2_bits_txChannel),
    .io_taskFromArb_s2_bits_set(io_taskFromArb_s2_bits_set),
    .io_taskFromArb_s2_bits_tag(io_taskFromArb_s2_bits_tag),
    .io_taskFromArb_s2_bits_off(io_taskFromArb_s2_bits_off),
    .io_taskFromArb_s2_bits_alias(io_taskFromArb_s2_bits_alias),
    .io_taskFromArb_s2_bits_vaddr(io_taskFromArb_s2_bits_vaddr),
    .io_taskFromArb_s2_bits_isKeyword(io_taskFromArb_s2_bits_isKeyword),
    .io_taskFromArb_s2_bits_opcode(io_taskFromArb_s2_bits_opcode),
    .io_taskFromArb_s2_bits_param(io_taskFromArb_s2_bits_param),
    .io_taskFromArb_s2_bits_size(io_taskFromArb_s2_bits_size),
    .io_taskFromArb_s2_bits_sourceId(io_taskFromArb_s2_bits_sourceId),
    .io_taskFromArb_s2_bits_bufIdx(io_taskFromArb_s2_bits_bufIdx),
    .io_taskFromArb_s2_bits_needProbeAckData(io_taskFromArb_s2_bits_needProbeAckData),
    .io_taskFromArb_s2_bits_denied(io_taskFromArb_s2_bits_denied),
    .io_taskFromArb_s2_bits_corrupt(io_taskFromArb_s2_bits_corrupt),
    .io_taskFromArb_s2_bits_mshrTask(io_taskFromArb_s2_bits_mshrTask),
    .io_taskFromArb_s2_bits_mshrId(io_taskFromArb_s2_bits_mshrId),
    .io_taskFromArb_s2_bits_aliasTask(io_taskFromArb_s2_bits_aliasTask),
    .io_taskFromArb_s2_bits_useProbeData(io_taskFromArb_s2_bits_useProbeData),
    .io_taskFromArb_s2_bits_mshrRetry(io_taskFromArb_s2_bits_mshrRetry),
    .io_taskFromArb_s2_bits_readProbeDataDown(io_taskFromArb_s2_bits_readProbeDataDown),
    .io_taskFromArb_s2_bits_fromL2pft(io_taskFromArb_s2_bits_fromL2pft),
    .io_taskFromArb_s2_bits_needHint(io_taskFromArb_s2_bits_needHint),
    .io_taskFromArb_s2_bits_dirty(io_taskFromArb_s2_bits_dirty),
    .io_taskFromArb_s2_bits_way(io_taskFromArb_s2_bits_way),
    .io_taskFromArb_s2_bits_meta_dirty(io_taskFromArb_s2_bits_meta_dirty),
    .io_taskFromArb_s2_bits_meta_state(io_taskFromArb_s2_bits_meta_state),
    .io_taskFromArb_s2_bits_meta_clients(io_taskFromArb_s2_bits_meta_clients),
    .io_taskFromArb_s2_bits_meta_alias(io_taskFromArb_s2_bits_meta_alias),
    .io_taskFromArb_s2_bits_meta_prefetch(io_taskFromArb_s2_bits_meta_prefetch),
    .io_taskFromArb_s2_bits_meta_prefetchSrc(io_taskFromArb_s2_bits_meta_prefetchSrc),
    .io_taskFromArb_s2_bits_meta_accessed(io_taskFromArb_s2_bits_meta_accessed),
    .io_taskFromArb_s2_bits_meta_tagErr(io_taskFromArb_s2_bits_meta_tagErr),
    .io_taskFromArb_s2_bits_meta_dataErr(io_taskFromArb_s2_bits_meta_dataErr),
    .io_taskFromArb_s2_bits_metaWen(io_taskFromArb_s2_bits_metaWen),
    .io_taskFromArb_s2_bits_tagWen(io_taskFromArb_s2_bits_tagWen),
    .io_taskFromArb_s2_bits_dsWen(io_taskFromArb_s2_bits_dsWen),
    .io_taskFromArb_s2_bits_wayMask(io_taskFromArb_s2_bits_wayMask),
    .io_taskFromArb_s2_bits_replTask(io_taskFromArb_s2_bits_replTask),
    .io_taskFromArb_s2_bits_cmoTask(io_taskFromArb_s2_bits_cmoTask),
    .io_taskFromArb_s2_bits_cmoAll(io_taskFromArb_s2_bits_cmoAll),
    .io_taskFromArb_s2_bits_reqSource(io_taskFromArb_s2_bits_reqSource),
    .io_taskFromArb_s2_bits_mergeA(io_taskFromArb_s2_bits_mergeA),
    .io_taskFromArb_s2_bits_aMergeTask_off(io_taskFromArb_s2_bits_aMergeTask_off),
    .io_taskFromArb_s2_bits_aMergeTask_alias(io_taskFromArb_s2_bits_aMergeTask_alias),
    .io_taskFromArb_s2_bits_aMergeTask_vaddr(io_taskFromArb_s2_bits_aMergeTask_vaddr),
    .io_taskFromArb_s2_bits_aMergeTask_isKeyword(io_taskFromArb_s2_bits_aMergeTask_isKeyword),
    .io_taskFromArb_s2_bits_aMergeTask_opcode(io_taskFromArb_s2_bits_aMergeTask_opcode),
    .io_taskFromArb_s2_bits_aMergeTask_param(io_taskFromArb_s2_bits_aMergeTask_param),
    .io_taskFromArb_s2_bits_aMergeTask_sourceId(io_taskFromArb_s2_bits_aMergeTask_sourceId),
    .io_taskFromArb_s2_bits_aMergeTask_meta_dirty(io_taskFromArb_s2_bits_aMergeTask_meta_dirty),
    .io_taskFromArb_s2_bits_aMergeTask_meta_state(io_taskFromArb_s2_bits_aMergeTask_meta_state),
    .io_taskFromArb_s2_bits_aMergeTask_meta_clients(io_taskFromArb_s2_bits_aMergeTask_meta_clients),
    .io_taskFromArb_s2_bits_aMergeTask_meta_alias(io_taskFromArb_s2_bits_aMergeTask_meta_alias),
    .io_taskFromArb_s2_bits_aMergeTask_meta_prefetch(io_taskFromArb_s2_bits_aMergeTask_meta_prefetch),
    .io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc(io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskFromArb_s2_bits_aMergeTask_meta_accessed(io_taskFromArb_s2_bits_aMergeTask_meta_accessed),
    .io_taskFromArb_s2_bits_aMergeTask_meta_tagErr(io_taskFromArb_s2_bits_aMergeTask_meta_tagErr),
    .io_taskFromArb_s2_bits_aMergeTask_meta_dataErr(io_taskFromArb_s2_bits_aMergeTask_meta_dataErr),
    .io_taskFromArb_s2_bits_snpHitRelease(io_taskFromArb_s2_bits_snpHitRelease),
    .io_taskFromArb_s2_bits_snpHitReleaseToInval(io_taskFromArb_s2_bits_snpHitReleaseToInval),
    .io_taskFromArb_s2_bits_snpHitReleaseToClean(io_taskFromArb_s2_bits_snpHitReleaseToClean),
    .io_taskFromArb_s2_bits_snpHitReleaseWithData(io_taskFromArb_s2_bits_snpHitReleaseWithData),
    .io_taskFromArb_s2_bits_snpHitReleaseIdx(io_taskFromArb_s2_bits_snpHitReleaseIdx),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty(io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_state(io_taskFromArb_s2_bits_snpHitReleaseMeta_state),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_clients(io_taskFromArb_s2_bits_snpHitReleaseMeta_clients),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_alias(io_taskFromArb_s2_bits_snpHitReleaseMeta_alias),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch(io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc(io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed(io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr(io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr(io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskFromArb_s2_bits_tgtID(io_taskFromArb_s2_bits_tgtID),
    .io_taskFromArb_s2_bits_srcID(io_taskFromArb_s2_bits_srcID),
    .io_taskFromArb_s2_bits_txnID(io_taskFromArb_s2_bits_txnID),
    .io_taskFromArb_s2_bits_homeNID(io_taskFromArb_s2_bits_homeNID),
    .io_taskFromArb_s2_bits_dbID(io_taskFromArb_s2_bits_dbID),
    .io_taskFromArb_s2_bits_fwdNID(io_taskFromArb_s2_bits_fwdNID),
    .io_taskFromArb_s2_bits_fwdTxnID(io_taskFromArb_s2_bits_fwdTxnID),
    .io_taskFromArb_s2_bits_chiOpcode(io_taskFromArb_s2_bits_chiOpcode),
    .io_taskFromArb_s2_bits_resp(io_taskFromArb_s2_bits_resp),
    .io_taskFromArb_s2_bits_fwdState(io_taskFromArb_s2_bits_fwdState),
    .io_taskFromArb_s2_bits_pCrdType(io_taskFromArb_s2_bits_pCrdType),
    .io_taskFromArb_s2_bits_retToSrc(io_taskFromArb_s2_bits_retToSrc),
    .io_taskFromArb_s2_bits_likelyshared(io_taskFromArb_s2_bits_likelyshared),
    .io_taskFromArb_s2_bits_expCompAck(io_taskFromArb_s2_bits_expCompAck),
    .io_taskFromArb_s2_bits_allowRetry(io_taskFromArb_s2_bits_allowRetry),
    .io_taskFromArb_s2_bits_memAttr_allocate(io_taskFromArb_s2_bits_memAttr_allocate),
    .io_taskFromArb_s2_bits_memAttr_cacheable(io_taskFromArb_s2_bits_memAttr_cacheable),
    .io_taskFromArb_s2_bits_memAttr_device(io_taskFromArb_s2_bits_memAttr_device),
    .io_taskFromArb_s2_bits_memAttr_ewa(io_taskFromArb_s2_bits_memAttr_ewa),
    .io_taskFromArb_s2_bits_traceTag(io_taskFromArb_s2_bits_traceTag),
    .io_taskFromArb_s2_bits_dataCheckErr(io_taskFromArb_s2_bits_dataCheckErr),
    .io_taskInfo_s1_valid(io_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel(io_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_isKeyword(io_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode(io_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_sourceId(io_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_mshrTask(io_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mergeA(io_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword(io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode(io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_sourceId(io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_fromReqArb_status_s1_tags_1(io_fromReqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_0(io_fromReqArb_status_s1_sets_0),
    .io_fromReqArb_status_s1_sets_1(io_fromReqArb_status_s1_sets_1),
    .io_fromReqArb_status_s1_sets_2(io_fromReqArb_status_s1_sets_2),
    .io_fromReqArb_status_s1_sets_3(io_fromReqArb_status_s1_sets_3),
    .io_toReqArb_blockG_s1(g_io_toReqArb_blockG_s1),
    .io_toReqArb_blockB_s1(g_io_toReqArb_blockB_s1),
    .io_toReqArb_blockC_s1(g_io_toReqArb_blockC_s1),
    .io_toReqBuf_0(g_io_toReqBuf_0),
    .io_toReqBuf_1(g_io_toReqBuf_1),
    .io_status_vec_toD_0_valid(g_io_status_vec_toD_0_valid),
    .io_status_vec_toD_0_bits_channel(g_io_status_vec_toD_0_bits_channel),
    .io_status_vec_toD_1_valid(g_io_status_vec_toD_1_valid),
    .io_status_vec_toD_1_bits_channel(g_io_status_vec_toD_1_bits_channel),
    .io_status_vec_toD_2_valid(g_io_status_vec_toD_2_valid),
    .io_status_vec_toD_2_bits_channel(g_io_status_vec_toD_2_bits_channel),
    .io_status_vec_toTX_0_valid(g_io_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel(g_io_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel(g_io_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask(g_io_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid(g_io_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel(g_io_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel(g_io_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask(g_io_status_vec_toTX_1_bits_mshrTask),
    .io_status_vec_toTX_2_valid(g_io_status_vec_toTX_2_valid),
    .io_status_vec_toTX_2_bits_channel(g_io_status_vec_toTX_2_bits_channel),
    .io_status_vec_toTX_2_bits_txChannel(g_io_status_vec_toTX_2_bits_txChannel),
    .io_status_vec_toTX_2_bits_mshrTask(g_io_status_vec_toTX_2_bits_mshrTask),
    .io_dirResp_s3_hit(io_dirResp_s3_hit),
    .io_dirResp_s3_tag(io_dirResp_s3_tag),
    .io_dirResp_s3_set(io_dirResp_s3_set),
    .io_dirResp_s3_way(io_dirResp_s3_way),
    .io_dirResp_s3_meta_dirty(io_dirResp_s3_meta_dirty),
    .io_dirResp_s3_meta_state(io_dirResp_s3_meta_state),
    .io_dirResp_s3_meta_clients(io_dirResp_s3_meta_clients),
    .io_dirResp_s3_meta_alias(io_dirResp_s3_meta_alias),
    .io_dirResp_s3_meta_prefetch(io_dirResp_s3_meta_prefetch),
    .io_dirResp_s3_meta_prefetchSrc(io_dirResp_s3_meta_prefetchSrc),
    .io_dirResp_s3_meta_accessed(io_dirResp_s3_meta_accessed),
    .io_dirResp_s3_meta_tagErr(io_dirResp_s3_meta_tagErr),
    .io_dirResp_s3_meta_dataErr(io_dirResp_s3_meta_dataErr),
    .io_dirResp_s3_error(io_dirResp_s3_error),
    .io_replResp_valid(io_replResp_valid),
    .io_replResp_bits_way(io_replResp_bits_way),
    .io_replResp_bits_meta_state(io_replResp_bits_meta_state),
    .io_replResp_bits_retry(io_replResp_bits_retry),
    .io_toMSHRCtl_mshr_alloc_s3_valid(g_io_toMSHRCtl_mshr_alloc_s3_valid),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error(g_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct(g_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_channel(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_channel),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_set(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_set),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_tag(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_tag),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_off(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_off),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_alias(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_param(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_param),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag(g_io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag),
    .io_fromMSHRCtl_mshr_alloc_ptr(io_fromMSHRCtl_mshr_alloc_ptr),
    .io_bufResp_data_0(io_bufResp_data_0),
    .io_bufResp_data_1(io_bufResp_data_1),
    .io_refillBufResp_s3_bits_data(io_refillBufResp_s3_bits_data),
    .io_releaseBufResp_s3_valid(io_releaseBufResp_s3_valid),
    .io_releaseBufResp_s3_bits_data(io_releaseBufResp_s3_bits_data),
    .io_toDS_en_s3(g_io_toDS_en_s3),
    .io_toDS_req_s3_valid(g_io_toDS_req_s3_valid),
    .io_toDS_req_s3_bits_way(g_io_toDS_req_s3_bits_way),
    .io_toDS_req_s3_bits_set(g_io_toDS_req_s3_bits_set),
    .io_toDS_req_s3_bits_wen(g_io_toDS_req_s3_bits_wen),
    .io_toDS_rdata_s5_data(io_toDS_rdata_s5_data),
    .io_toDS_wdata_s3_data(g_io_toDS_wdata_s3_data),
    .io_toDS_error_s5(io_toDS_error_s5),
    .io_toSourceD_valid(g_io_toSourceD_valid),
    .io_toSourceD_bits_task_channel(g_io_toSourceD_bits_task_channel),
    .io_toSourceD_bits_task_txChannel(g_io_toSourceD_bits_task_txChannel),
    .io_toSourceD_bits_task_set(g_io_toSourceD_bits_task_set),
    .io_toSourceD_bits_task_tag(g_io_toSourceD_bits_task_tag),
    .io_toSourceD_bits_task_off(g_io_toSourceD_bits_task_off),
    .io_toSourceD_bits_task_alias(g_io_toSourceD_bits_task_alias),
    .io_toSourceD_bits_task_vaddr(g_io_toSourceD_bits_task_vaddr),
    .io_toSourceD_bits_task_isKeyword(g_io_toSourceD_bits_task_isKeyword),
    .io_toSourceD_bits_task_opcode(g_io_toSourceD_bits_task_opcode),
    .io_toSourceD_bits_task_param(g_io_toSourceD_bits_task_param),
    .io_toSourceD_bits_task_size(g_io_toSourceD_bits_task_size),
    .io_toSourceD_bits_task_sourceId(g_io_toSourceD_bits_task_sourceId),
    .io_toSourceD_bits_task_bufIdx(g_io_toSourceD_bits_task_bufIdx),
    .io_toSourceD_bits_task_needProbeAckData(g_io_toSourceD_bits_task_needProbeAckData),
    .io_toSourceD_bits_task_denied(g_io_toSourceD_bits_task_denied),
    .io_toSourceD_bits_task_corrupt(g_io_toSourceD_bits_task_corrupt),
    .io_toSourceD_bits_task_mshrTask(g_io_toSourceD_bits_task_mshrTask),
    .io_toSourceD_bits_task_mshrId(g_io_toSourceD_bits_task_mshrId),
    .io_toSourceD_bits_task_aliasTask(g_io_toSourceD_bits_task_aliasTask),
    .io_toSourceD_bits_task_useProbeData(g_io_toSourceD_bits_task_useProbeData),
    .io_toSourceD_bits_task_mshrRetry(g_io_toSourceD_bits_task_mshrRetry),
    .io_toSourceD_bits_task_readProbeDataDown(g_io_toSourceD_bits_task_readProbeDataDown),
    .io_toSourceD_bits_task_fromL2pft(g_io_toSourceD_bits_task_fromL2pft),
    .io_toSourceD_bits_task_needHint(g_io_toSourceD_bits_task_needHint),
    .io_toSourceD_bits_task_dirty(g_io_toSourceD_bits_task_dirty),
    .io_toSourceD_bits_task_way(g_io_toSourceD_bits_task_way),
    .io_toSourceD_bits_task_meta_dirty(g_io_toSourceD_bits_task_meta_dirty),
    .io_toSourceD_bits_task_meta_state(g_io_toSourceD_bits_task_meta_state),
    .io_toSourceD_bits_task_meta_clients(g_io_toSourceD_bits_task_meta_clients),
    .io_toSourceD_bits_task_meta_alias(g_io_toSourceD_bits_task_meta_alias),
    .io_toSourceD_bits_task_meta_prefetch(g_io_toSourceD_bits_task_meta_prefetch),
    .io_toSourceD_bits_task_meta_prefetchSrc(g_io_toSourceD_bits_task_meta_prefetchSrc),
    .io_toSourceD_bits_task_meta_accessed(g_io_toSourceD_bits_task_meta_accessed),
    .io_toSourceD_bits_task_meta_tagErr(g_io_toSourceD_bits_task_meta_tagErr),
    .io_toSourceD_bits_task_meta_dataErr(g_io_toSourceD_bits_task_meta_dataErr),
    .io_toSourceD_bits_task_metaWen(g_io_toSourceD_bits_task_metaWen),
    .io_toSourceD_bits_task_tagWen(g_io_toSourceD_bits_task_tagWen),
    .io_toSourceD_bits_task_dsWen(g_io_toSourceD_bits_task_dsWen),
    .io_toSourceD_bits_task_wayMask(g_io_toSourceD_bits_task_wayMask),
    .io_toSourceD_bits_task_replTask(g_io_toSourceD_bits_task_replTask),
    .io_toSourceD_bits_task_cmoTask(g_io_toSourceD_bits_task_cmoTask),
    .io_toSourceD_bits_task_cmoAll(g_io_toSourceD_bits_task_cmoAll),
    .io_toSourceD_bits_task_reqSource(g_io_toSourceD_bits_task_reqSource),
    .io_toSourceD_bits_task_mergeA(g_io_toSourceD_bits_task_mergeA),
    .io_toSourceD_bits_task_aMergeTask_off(g_io_toSourceD_bits_task_aMergeTask_off),
    .io_toSourceD_bits_task_aMergeTask_alias(g_io_toSourceD_bits_task_aMergeTask_alias),
    .io_toSourceD_bits_task_aMergeTask_vaddr(g_io_toSourceD_bits_task_aMergeTask_vaddr),
    .io_toSourceD_bits_task_aMergeTask_isKeyword(g_io_toSourceD_bits_task_aMergeTask_isKeyword),
    .io_toSourceD_bits_task_aMergeTask_opcode(g_io_toSourceD_bits_task_aMergeTask_opcode),
    .io_toSourceD_bits_task_aMergeTask_param(g_io_toSourceD_bits_task_aMergeTask_param),
    .io_toSourceD_bits_task_aMergeTask_sourceId(g_io_toSourceD_bits_task_aMergeTask_sourceId),
    .io_toSourceD_bits_task_aMergeTask_meta_dirty(g_io_toSourceD_bits_task_aMergeTask_meta_dirty),
    .io_toSourceD_bits_task_aMergeTask_meta_state(g_io_toSourceD_bits_task_aMergeTask_meta_state),
    .io_toSourceD_bits_task_aMergeTask_meta_clients(g_io_toSourceD_bits_task_aMergeTask_meta_clients),
    .io_toSourceD_bits_task_aMergeTask_meta_alias(g_io_toSourceD_bits_task_aMergeTask_meta_alias),
    .io_toSourceD_bits_task_aMergeTask_meta_prefetch(g_io_toSourceD_bits_task_aMergeTask_meta_prefetch),
    .io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc(g_io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc),
    .io_toSourceD_bits_task_aMergeTask_meta_accessed(g_io_toSourceD_bits_task_aMergeTask_meta_accessed),
    .io_toSourceD_bits_task_aMergeTask_meta_tagErr(g_io_toSourceD_bits_task_aMergeTask_meta_tagErr),
    .io_toSourceD_bits_task_aMergeTask_meta_dataErr(g_io_toSourceD_bits_task_aMergeTask_meta_dataErr),
    .io_toSourceD_bits_task_snpHitRelease(g_io_toSourceD_bits_task_snpHitRelease),
    .io_toSourceD_bits_task_snpHitReleaseToInval(g_io_toSourceD_bits_task_snpHitReleaseToInval),
    .io_toSourceD_bits_task_snpHitReleaseToClean(g_io_toSourceD_bits_task_snpHitReleaseToClean),
    .io_toSourceD_bits_task_snpHitReleaseWithData(g_io_toSourceD_bits_task_snpHitReleaseWithData),
    .io_toSourceD_bits_task_snpHitReleaseIdx(g_io_toSourceD_bits_task_snpHitReleaseIdx),
    .io_toSourceD_bits_task_snpHitReleaseMeta_dirty(g_io_toSourceD_bits_task_snpHitReleaseMeta_dirty),
    .io_toSourceD_bits_task_snpHitReleaseMeta_state(g_io_toSourceD_bits_task_snpHitReleaseMeta_state),
    .io_toSourceD_bits_task_snpHitReleaseMeta_clients(g_io_toSourceD_bits_task_snpHitReleaseMeta_clients),
    .io_toSourceD_bits_task_snpHitReleaseMeta_alias(g_io_toSourceD_bits_task_snpHitReleaseMeta_alias),
    .io_toSourceD_bits_task_snpHitReleaseMeta_prefetch(g_io_toSourceD_bits_task_snpHitReleaseMeta_prefetch),
    .io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc(g_io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toSourceD_bits_task_snpHitReleaseMeta_accessed(g_io_toSourceD_bits_task_snpHitReleaseMeta_accessed),
    .io_toSourceD_bits_task_snpHitReleaseMeta_tagErr(g_io_toSourceD_bits_task_snpHitReleaseMeta_tagErr),
    .io_toSourceD_bits_task_snpHitReleaseMeta_dataErr(g_io_toSourceD_bits_task_snpHitReleaseMeta_dataErr),
    .io_toSourceD_bits_task_tgtID(g_io_toSourceD_bits_task_tgtID),
    .io_toSourceD_bits_task_srcID(g_io_toSourceD_bits_task_srcID),
    .io_toSourceD_bits_task_txnID(g_io_toSourceD_bits_task_txnID),
    .io_toSourceD_bits_task_homeNID(g_io_toSourceD_bits_task_homeNID),
    .io_toSourceD_bits_task_dbID(g_io_toSourceD_bits_task_dbID),
    .io_toSourceD_bits_task_fwdNID(g_io_toSourceD_bits_task_fwdNID),
    .io_toSourceD_bits_task_fwdTxnID(g_io_toSourceD_bits_task_fwdTxnID),
    .io_toSourceD_bits_task_chiOpcode(g_io_toSourceD_bits_task_chiOpcode),
    .io_toSourceD_bits_task_resp(g_io_toSourceD_bits_task_resp),
    .io_toSourceD_bits_task_fwdState(g_io_toSourceD_bits_task_fwdState),
    .io_toSourceD_bits_task_pCrdType(g_io_toSourceD_bits_task_pCrdType),
    .io_toSourceD_bits_task_retToSrc(g_io_toSourceD_bits_task_retToSrc),
    .io_toSourceD_bits_task_likelyshared(g_io_toSourceD_bits_task_likelyshared),
    .io_toSourceD_bits_task_expCompAck(g_io_toSourceD_bits_task_expCompAck),
    .io_toSourceD_bits_task_allowRetry(g_io_toSourceD_bits_task_allowRetry),
    .io_toSourceD_bits_task_memAttr_allocate(g_io_toSourceD_bits_task_memAttr_allocate),
    .io_toSourceD_bits_task_memAttr_cacheable(g_io_toSourceD_bits_task_memAttr_cacheable),
    .io_toSourceD_bits_task_memAttr_device(g_io_toSourceD_bits_task_memAttr_device),
    .io_toSourceD_bits_task_memAttr_ewa(g_io_toSourceD_bits_task_memAttr_ewa),
    .io_toSourceD_bits_task_traceTag(g_io_toSourceD_bits_task_traceTag),
    .io_toSourceD_bits_task_dataCheckErr(g_io_toSourceD_bits_task_dataCheckErr),
    .io_toSourceD_bits_data_data(g_io_toSourceD_bits_data_data),
    .io_toTXREQ_valid(g_io_toTXREQ_valid),
    .io_toTXREQ_bits_tgtID(g_io_toTXREQ_bits_tgtID),
    .io_toTXREQ_bits_srcID(g_io_toTXREQ_bits_srcID),
    .io_toTXREQ_bits_txnID(g_io_toTXREQ_bits_txnID),
    .io_toTXREQ_bits_opcode(g_io_toTXREQ_bits_opcode),
    .io_toTXREQ_bits_addr(g_io_toTXREQ_bits_addr),
    .io_toTXREQ_bits_likelyshared(g_io_toTXREQ_bits_likelyshared),
    .io_toTXREQ_bits_allowRetry(g_io_toTXREQ_bits_allowRetry),
    .io_toTXREQ_bits_pCrdType(g_io_toTXREQ_bits_pCrdType),
    .io_toTXREQ_bits_memAttr_allocate(g_io_toTXREQ_bits_memAttr_allocate),
    .io_toTXREQ_bits_memAttr_cacheable(g_io_toTXREQ_bits_memAttr_cacheable),
    .io_toTXREQ_bits_memAttr_device(g_io_toTXREQ_bits_memAttr_device),
    .io_toTXREQ_bits_memAttr_ewa(g_io_toTXREQ_bits_memAttr_ewa),
    .io_toTXREQ_bits_expCompAck(g_io_toTXREQ_bits_expCompAck),
    .io_toTXRSP_valid(g_io_toTXRSP_valid),
    .io_toTXRSP_bits_txChannel(g_io_toTXRSP_bits_txChannel),
    .io_toTXRSP_bits_denied(g_io_toTXRSP_bits_denied),
    .io_toTXRSP_bits_tgtID(g_io_toTXRSP_bits_tgtID),
    .io_toTXRSP_bits_srcID(g_io_toTXRSP_bits_srcID),
    .io_toTXRSP_bits_txnID(g_io_toTXRSP_bits_txnID),
    .io_toTXRSP_bits_dbID(g_io_toTXRSP_bits_dbID),
    .io_toTXRSP_bits_chiOpcode(g_io_toTXRSP_bits_chiOpcode),
    .io_toTXRSP_bits_resp(g_io_toTXRSP_bits_resp),
    .io_toTXRSP_bits_fwdState(g_io_toTXRSP_bits_fwdState),
    .io_toTXRSP_bits_pCrdType(g_io_toTXRSP_bits_pCrdType),
    .io_toTXRSP_bits_traceTag(g_io_toTXRSP_bits_traceTag),
    .io_toTXDAT_ready(io_toTXDAT_ready),
    .io_toTXDAT_valid(g_io_toTXDAT_valid),
    .io_toTXDAT_bits_task_channel(g_io_toTXDAT_bits_task_channel),
    .io_toTXDAT_bits_task_txChannel(g_io_toTXDAT_bits_task_txChannel),
    .io_toTXDAT_bits_task_set(g_io_toTXDAT_bits_task_set),
    .io_toTXDAT_bits_task_tag(g_io_toTXDAT_bits_task_tag),
    .io_toTXDAT_bits_task_off(g_io_toTXDAT_bits_task_off),
    .io_toTXDAT_bits_task_alias(g_io_toTXDAT_bits_task_alias),
    .io_toTXDAT_bits_task_vaddr(g_io_toTXDAT_bits_task_vaddr),
    .io_toTXDAT_bits_task_isKeyword(g_io_toTXDAT_bits_task_isKeyword),
    .io_toTXDAT_bits_task_opcode(g_io_toTXDAT_bits_task_opcode),
    .io_toTXDAT_bits_task_param(g_io_toTXDAT_bits_task_param),
    .io_toTXDAT_bits_task_size(g_io_toTXDAT_bits_task_size),
    .io_toTXDAT_bits_task_sourceId(g_io_toTXDAT_bits_task_sourceId),
    .io_toTXDAT_bits_task_bufIdx(g_io_toTXDAT_bits_task_bufIdx),
    .io_toTXDAT_bits_task_needProbeAckData(g_io_toTXDAT_bits_task_needProbeAckData),
    .io_toTXDAT_bits_task_denied(g_io_toTXDAT_bits_task_denied),
    .io_toTXDAT_bits_task_corrupt(g_io_toTXDAT_bits_task_corrupt),
    .io_toTXDAT_bits_task_mshrTask(g_io_toTXDAT_bits_task_mshrTask),
    .io_toTXDAT_bits_task_mshrId(g_io_toTXDAT_bits_task_mshrId),
    .io_toTXDAT_bits_task_aliasTask(g_io_toTXDAT_bits_task_aliasTask),
    .io_toTXDAT_bits_task_useProbeData(g_io_toTXDAT_bits_task_useProbeData),
    .io_toTXDAT_bits_task_mshrRetry(g_io_toTXDAT_bits_task_mshrRetry),
    .io_toTXDAT_bits_task_readProbeDataDown(g_io_toTXDAT_bits_task_readProbeDataDown),
    .io_toTXDAT_bits_task_fromL2pft(g_io_toTXDAT_bits_task_fromL2pft),
    .io_toTXDAT_bits_task_needHint(g_io_toTXDAT_bits_task_needHint),
    .io_toTXDAT_bits_task_dirty(g_io_toTXDAT_bits_task_dirty),
    .io_toTXDAT_bits_task_way(g_io_toTXDAT_bits_task_way),
    .io_toTXDAT_bits_task_meta_dirty(g_io_toTXDAT_bits_task_meta_dirty),
    .io_toTXDAT_bits_task_meta_state(g_io_toTXDAT_bits_task_meta_state),
    .io_toTXDAT_bits_task_meta_clients(g_io_toTXDAT_bits_task_meta_clients),
    .io_toTXDAT_bits_task_meta_alias(g_io_toTXDAT_bits_task_meta_alias),
    .io_toTXDAT_bits_task_meta_prefetch(g_io_toTXDAT_bits_task_meta_prefetch),
    .io_toTXDAT_bits_task_meta_prefetchSrc(g_io_toTXDAT_bits_task_meta_prefetchSrc),
    .io_toTXDAT_bits_task_meta_accessed(g_io_toTXDAT_bits_task_meta_accessed),
    .io_toTXDAT_bits_task_meta_tagErr(g_io_toTXDAT_bits_task_meta_tagErr),
    .io_toTXDAT_bits_task_meta_dataErr(g_io_toTXDAT_bits_task_meta_dataErr),
    .io_toTXDAT_bits_task_metaWen(g_io_toTXDAT_bits_task_metaWen),
    .io_toTXDAT_bits_task_tagWen(g_io_toTXDAT_bits_task_tagWen),
    .io_toTXDAT_bits_task_dsWen(g_io_toTXDAT_bits_task_dsWen),
    .io_toTXDAT_bits_task_wayMask(g_io_toTXDAT_bits_task_wayMask),
    .io_toTXDAT_bits_task_replTask(g_io_toTXDAT_bits_task_replTask),
    .io_toTXDAT_bits_task_cmoTask(g_io_toTXDAT_bits_task_cmoTask),
    .io_toTXDAT_bits_task_cmoAll(g_io_toTXDAT_bits_task_cmoAll),
    .io_toTXDAT_bits_task_reqSource(g_io_toTXDAT_bits_task_reqSource),
    .io_toTXDAT_bits_task_mergeA(g_io_toTXDAT_bits_task_mergeA),
    .io_toTXDAT_bits_task_aMergeTask_off(g_io_toTXDAT_bits_task_aMergeTask_off),
    .io_toTXDAT_bits_task_aMergeTask_alias(g_io_toTXDAT_bits_task_aMergeTask_alias),
    .io_toTXDAT_bits_task_aMergeTask_vaddr(g_io_toTXDAT_bits_task_aMergeTask_vaddr),
    .io_toTXDAT_bits_task_aMergeTask_isKeyword(g_io_toTXDAT_bits_task_aMergeTask_isKeyword),
    .io_toTXDAT_bits_task_aMergeTask_opcode(g_io_toTXDAT_bits_task_aMergeTask_opcode),
    .io_toTXDAT_bits_task_aMergeTask_param(g_io_toTXDAT_bits_task_aMergeTask_param),
    .io_toTXDAT_bits_task_aMergeTask_sourceId(g_io_toTXDAT_bits_task_aMergeTask_sourceId),
    .io_toTXDAT_bits_task_aMergeTask_meta_dirty(g_io_toTXDAT_bits_task_aMergeTask_meta_dirty),
    .io_toTXDAT_bits_task_aMergeTask_meta_state(g_io_toTXDAT_bits_task_aMergeTask_meta_state),
    .io_toTXDAT_bits_task_aMergeTask_meta_clients(g_io_toTXDAT_bits_task_aMergeTask_meta_clients),
    .io_toTXDAT_bits_task_aMergeTask_meta_alias(g_io_toTXDAT_bits_task_aMergeTask_meta_alias),
    .io_toTXDAT_bits_task_aMergeTask_meta_prefetch(g_io_toTXDAT_bits_task_aMergeTask_meta_prefetch),
    .io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc(g_io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc),
    .io_toTXDAT_bits_task_aMergeTask_meta_accessed(g_io_toTXDAT_bits_task_aMergeTask_meta_accessed),
    .io_toTXDAT_bits_task_aMergeTask_meta_tagErr(g_io_toTXDAT_bits_task_aMergeTask_meta_tagErr),
    .io_toTXDAT_bits_task_aMergeTask_meta_dataErr(g_io_toTXDAT_bits_task_aMergeTask_meta_dataErr),
    .io_toTXDAT_bits_task_snpHitRelease(g_io_toTXDAT_bits_task_snpHitRelease),
    .io_toTXDAT_bits_task_snpHitReleaseToInval(g_io_toTXDAT_bits_task_snpHitReleaseToInval),
    .io_toTXDAT_bits_task_snpHitReleaseToClean(g_io_toTXDAT_bits_task_snpHitReleaseToClean),
    .io_toTXDAT_bits_task_snpHitReleaseWithData(g_io_toTXDAT_bits_task_snpHitReleaseWithData),
    .io_toTXDAT_bits_task_snpHitReleaseIdx(g_io_toTXDAT_bits_task_snpHitReleaseIdx),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_dirty(g_io_toTXDAT_bits_task_snpHitReleaseMeta_dirty),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_state(g_io_toTXDAT_bits_task_snpHitReleaseMeta_state),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_clients(g_io_toTXDAT_bits_task_snpHitReleaseMeta_clients),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_alias(g_io_toTXDAT_bits_task_snpHitReleaseMeta_alias),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch(g_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc(g_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_accessed(g_io_toTXDAT_bits_task_snpHitReleaseMeta_accessed),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr(g_io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr(g_io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr),
    .io_toTXDAT_bits_task_tgtID(g_io_toTXDAT_bits_task_tgtID),
    .io_toTXDAT_bits_task_srcID(g_io_toTXDAT_bits_task_srcID),
    .io_toTXDAT_bits_task_txnID(g_io_toTXDAT_bits_task_txnID),
    .io_toTXDAT_bits_task_homeNID(g_io_toTXDAT_bits_task_homeNID),
    .io_toTXDAT_bits_task_dbID(g_io_toTXDAT_bits_task_dbID),
    .io_toTXDAT_bits_task_fwdNID(g_io_toTXDAT_bits_task_fwdNID),
    .io_toTXDAT_bits_task_fwdTxnID(g_io_toTXDAT_bits_task_fwdTxnID),
    .io_toTXDAT_bits_task_chiOpcode(g_io_toTXDAT_bits_task_chiOpcode),
    .io_toTXDAT_bits_task_resp(g_io_toTXDAT_bits_task_resp),
    .io_toTXDAT_bits_task_fwdState(g_io_toTXDAT_bits_task_fwdState),
    .io_toTXDAT_bits_task_pCrdType(g_io_toTXDAT_bits_task_pCrdType),
    .io_toTXDAT_bits_task_retToSrc(g_io_toTXDAT_bits_task_retToSrc),
    .io_toTXDAT_bits_task_likelyshared(g_io_toTXDAT_bits_task_likelyshared),
    .io_toTXDAT_bits_task_expCompAck(g_io_toTXDAT_bits_task_expCompAck),
    .io_toTXDAT_bits_task_allowRetry(g_io_toTXDAT_bits_task_allowRetry),
    .io_toTXDAT_bits_task_memAttr_allocate(g_io_toTXDAT_bits_task_memAttr_allocate),
    .io_toTXDAT_bits_task_memAttr_cacheable(g_io_toTXDAT_bits_task_memAttr_cacheable),
    .io_toTXDAT_bits_task_memAttr_device(g_io_toTXDAT_bits_task_memAttr_device),
    .io_toTXDAT_bits_task_memAttr_ewa(g_io_toTXDAT_bits_task_memAttr_ewa),
    .io_toTXDAT_bits_task_traceTag(g_io_toTXDAT_bits_task_traceTag),
    .io_toTXDAT_bits_task_dataCheckErr(g_io_toTXDAT_bits_task_dataCheckErr),
    .io_toTXDAT_bits_data_data(g_io_toTXDAT_bits_data_data),
    .io_metaWReq_valid(g_io_metaWReq_valid),
    .io_metaWReq_bits_set(g_io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(g_io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty(g_io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state(g_io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients(g_io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias(g_io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch(g_io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc(g_io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed(g_io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr(g_io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr(g_io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid(g_io_tagWReq_valid),
    .io_tagWReq_bits_set(g_io_tagWReq_bits_set),
    .io_tagWReq_bits_way(g_io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(g_io_tagWReq_bits_wtag),
    .io_releaseBufWrite_valid(g_io_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_id(g_io_releaseBufWrite_bits_id),
    .io_releaseBufWrite_bits_data_data(g_io_releaseBufWrite_bits_data_data),
    .io_nestedwb_set(g_io_nestedwb_set),
    .io_nestedwb_tag(g_io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(g_io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(g_io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(g_io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(g_io_nestedwb_b_toB),
    .io_nestedwb_b_toN(g_io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(g_io_nestedwb_b_toClean),
    .io_nestedwbData_data(g_io_nestedwbData_data),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(g_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(g_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(g_io_l1Hint_bits_isKeyword),
    .io_prefetchTrain_ready(io_prefetchTrain_ready),
    .io_prefetchTrain_valid(g_io_prefetchTrain_valid),
    .io_prefetchTrain_bits_tag(g_io_prefetchTrain_bits_tag),
    .io_prefetchTrain_bits_set(g_io_prefetchTrain_bits_set),
    .io_prefetchTrain_bits_needT(g_io_prefetchTrain_bits_needT),
    .io_prefetchTrain_bits_source(g_io_prefetchTrain_bits_source),
    .io_prefetchTrain_bits_vaddr(g_io_prefetchTrain_bits_vaddr),
    .io_prefetchTrain_bits_hit(g_io_prefetchTrain_bits_hit),
    .io_prefetchTrain_bits_prefetched(g_io_prefetchTrain_bits_prefetched),
    .io_prefetchTrain_bits_pfsource(g_io_prefetchTrain_bits_pfsource),
    .io_prefetchTrain_bits_reqsource(g_io_prefetchTrain_bits_reqsource),
    .io_error_valid(g_io_error_valid),
    .io_error_bits_valid(g_io_error_bits_valid),
    .io_error_bits_address(g_io_error_bits_address),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value)
  );
  MainPipe_1_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_taskFromArb_s2_valid(io_taskFromArb_s2_valid),
    .io_taskFromArb_s2_bits_channel(io_taskFromArb_s2_bits_channel),
    .io_taskFromArb_s2_bits_txChannel(io_taskFromArb_s2_bits_txChannel),
    .io_taskFromArb_s2_bits_set(io_taskFromArb_s2_bits_set),
    .io_taskFromArb_s2_bits_tag(io_taskFromArb_s2_bits_tag),
    .io_taskFromArb_s2_bits_off(io_taskFromArb_s2_bits_off),
    .io_taskFromArb_s2_bits_alias(io_taskFromArb_s2_bits_alias),
    .io_taskFromArb_s2_bits_vaddr(io_taskFromArb_s2_bits_vaddr),
    .io_taskFromArb_s2_bits_isKeyword(io_taskFromArb_s2_bits_isKeyword),
    .io_taskFromArb_s2_bits_opcode(io_taskFromArb_s2_bits_opcode),
    .io_taskFromArb_s2_bits_param(io_taskFromArb_s2_bits_param),
    .io_taskFromArb_s2_bits_size(io_taskFromArb_s2_bits_size),
    .io_taskFromArb_s2_bits_sourceId(io_taskFromArb_s2_bits_sourceId),
    .io_taskFromArb_s2_bits_bufIdx(io_taskFromArb_s2_bits_bufIdx),
    .io_taskFromArb_s2_bits_needProbeAckData(io_taskFromArb_s2_bits_needProbeAckData),
    .io_taskFromArb_s2_bits_denied(io_taskFromArb_s2_bits_denied),
    .io_taskFromArb_s2_bits_corrupt(io_taskFromArb_s2_bits_corrupt),
    .io_taskFromArb_s2_bits_mshrTask(io_taskFromArb_s2_bits_mshrTask),
    .io_taskFromArb_s2_bits_mshrId(io_taskFromArb_s2_bits_mshrId),
    .io_taskFromArb_s2_bits_aliasTask(io_taskFromArb_s2_bits_aliasTask),
    .io_taskFromArb_s2_bits_useProbeData(io_taskFromArb_s2_bits_useProbeData),
    .io_taskFromArb_s2_bits_mshrRetry(io_taskFromArb_s2_bits_mshrRetry),
    .io_taskFromArb_s2_bits_readProbeDataDown(io_taskFromArb_s2_bits_readProbeDataDown),
    .io_taskFromArb_s2_bits_fromL2pft(io_taskFromArb_s2_bits_fromL2pft),
    .io_taskFromArb_s2_bits_needHint(io_taskFromArb_s2_bits_needHint),
    .io_taskFromArb_s2_bits_dirty(io_taskFromArb_s2_bits_dirty),
    .io_taskFromArb_s2_bits_way(io_taskFromArb_s2_bits_way),
    .io_taskFromArb_s2_bits_meta_dirty(io_taskFromArb_s2_bits_meta_dirty),
    .io_taskFromArb_s2_bits_meta_state(io_taskFromArb_s2_bits_meta_state),
    .io_taskFromArb_s2_bits_meta_clients(io_taskFromArb_s2_bits_meta_clients),
    .io_taskFromArb_s2_bits_meta_alias(io_taskFromArb_s2_bits_meta_alias),
    .io_taskFromArb_s2_bits_meta_prefetch(io_taskFromArb_s2_bits_meta_prefetch),
    .io_taskFromArb_s2_bits_meta_prefetchSrc(io_taskFromArb_s2_bits_meta_prefetchSrc),
    .io_taskFromArb_s2_bits_meta_accessed(io_taskFromArb_s2_bits_meta_accessed),
    .io_taskFromArb_s2_bits_meta_tagErr(io_taskFromArb_s2_bits_meta_tagErr),
    .io_taskFromArb_s2_bits_meta_dataErr(io_taskFromArb_s2_bits_meta_dataErr),
    .io_taskFromArb_s2_bits_metaWen(io_taskFromArb_s2_bits_metaWen),
    .io_taskFromArb_s2_bits_tagWen(io_taskFromArb_s2_bits_tagWen),
    .io_taskFromArb_s2_bits_dsWen(io_taskFromArb_s2_bits_dsWen),
    .io_taskFromArb_s2_bits_wayMask(io_taskFromArb_s2_bits_wayMask),
    .io_taskFromArb_s2_bits_replTask(io_taskFromArb_s2_bits_replTask),
    .io_taskFromArb_s2_bits_cmoTask(io_taskFromArb_s2_bits_cmoTask),
    .io_taskFromArb_s2_bits_cmoAll(io_taskFromArb_s2_bits_cmoAll),
    .io_taskFromArb_s2_bits_reqSource(io_taskFromArb_s2_bits_reqSource),
    .io_taskFromArb_s2_bits_mergeA(io_taskFromArb_s2_bits_mergeA),
    .io_taskFromArb_s2_bits_aMergeTask_off(io_taskFromArb_s2_bits_aMergeTask_off),
    .io_taskFromArb_s2_bits_aMergeTask_alias(io_taskFromArb_s2_bits_aMergeTask_alias),
    .io_taskFromArb_s2_bits_aMergeTask_vaddr(io_taskFromArb_s2_bits_aMergeTask_vaddr),
    .io_taskFromArb_s2_bits_aMergeTask_isKeyword(io_taskFromArb_s2_bits_aMergeTask_isKeyword),
    .io_taskFromArb_s2_bits_aMergeTask_opcode(io_taskFromArb_s2_bits_aMergeTask_opcode),
    .io_taskFromArb_s2_bits_aMergeTask_param(io_taskFromArb_s2_bits_aMergeTask_param),
    .io_taskFromArb_s2_bits_aMergeTask_sourceId(io_taskFromArb_s2_bits_aMergeTask_sourceId),
    .io_taskFromArb_s2_bits_aMergeTask_meta_dirty(io_taskFromArb_s2_bits_aMergeTask_meta_dirty),
    .io_taskFromArb_s2_bits_aMergeTask_meta_state(io_taskFromArb_s2_bits_aMergeTask_meta_state),
    .io_taskFromArb_s2_bits_aMergeTask_meta_clients(io_taskFromArb_s2_bits_aMergeTask_meta_clients),
    .io_taskFromArb_s2_bits_aMergeTask_meta_alias(io_taskFromArb_s2_bits_aMergeTask_meta_alias),
    .io_taskFromArb_s2_bits_aMergeTask_meta_prefetch(io_taskFromArb_s2_bits_aMergeTask_meta_prefetch),
    .io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc(io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskFromArb_s2_bits_aMergeTask_meta_accessed(io_taskFromArb_s2_bits_aMergeTask_meta_accessed),
    .io_taskFromArb_s2_bits_aMergeTask_meta_tagErr(io_taskFromArb_s2_bits_aMergeTask_meta_tagErr),
    .io_taskFromArb_s2_bits_aMergeTask_meta_dataErr(io_taskFromArb_s2_bits_aMergeTask_meta_dataErr),
    .io_taskFromArb_s2_bits_snpHitRelease(io_taskFromArb_s2_bits_snpHitRelease),
    .io_taskFromArb_s2_bits_snpHitReleaseToInval(io_taskFromArb_s2_bits_snpHitReleaseToInval),
    .io_taskFromArb_s2_bits_snpHitReleaseToClean(io_taskFromArb_s2_bits_snpHitReleaseToClean),
    .io_taskFromArb_s2_bits_snpHitReleaseWithData(io_taskFromArb_s2_bits_snpHitReleaseWithData),
    .io_taskFromArb_s2_bits_snpHitReleaseIdx(io_taskFromArb_s2_bits_snpHitReleaseIdx),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty(io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_state(io_taskFromArb_s2_bits_snpHitReleaseMeta_state),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_clients(io_taskFromArb_s2_bits_snpHitReleaseMeta_clients),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_alias(io_taskFromArb_s2_bits_snpHitReleaseMeta_alias),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch(io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc(io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed(io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr(io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr(io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskFromArb_s2_bits_tgtID(io_taskFromArb_s2_bits_tgtID),
    .io_taskFromArb_s2_bits_srcID(io_taskFromArb_s2_bits_srcID),
    .io_taskFromArb_s2_bits_txnID(io_taskFromArb_s2_bits_txnID),
    .io_taskFromArb_s2_bits_homeNID(io_taskFromArb_s2_bits_homeNID),
    .io_taskFromArb_s2_bits_dbID(io_taskFromArb_s2_bits_dbID),
    .io_taskFromArb_s2_bits_fwdNID(io_taskFromArb_s2_bits_fwdNID),
    .io_taskFromArb_s2_bits_fwdTxnID(io_taskFromArb_s2_bits_fwdTxnID),
    .io_taskFromArb_s2_bits_chiOpcode(io_taskFromArb_s2_bits_chiOpcode),
    .io_taskFromArb_s2_bits_resp(io_taskFromArb_s2_bits_resp),
    .io_taskFromArb_s2_bits_fwdState(io_taskFromArb_s2_bits_fwdState),
    .io_taskFromArb_s2_bits_pCrdType(io_taskFromArb_s2_bits_pCrdType),
    .io_taskFromArb_s2_bits_retToSrc(io_taskFromArb_s2_bits_retToSrc),
    .io_taskFromArb_s2_bits_likelyshared(io_taskFromArb_s2_bits_likelyshared),
    .io_taskFromArb_s2_bits_expCompAck(io_taskFromArb_s2_bits_expCompAck),
    .io_taskFromArb_s2_bits_allowRetry(io_taskFromArb_s2_bits_allowRetry),
    .io_taskFromArb_s2_bits_memAttr_allocate(io_taskFromArb_s2_bits_memAttr_allocate),
    .io_taskFromArb_s2_bits_memAttr_cacheable(io_taskFromArb_s2_bits_memAttr_cacheable),
    .io_taskFromArb_s2_bits_memAttr_device(io_taskFromArb_s2_bits_memAttr_device),
    .io_taskFromArb_s2_bits_memAttr_ewa(io_taskFromArb_s2_bits_memAttr_ewa),
    .io_taskFromArb_s2_bits_traceTag(io_taskFromArb_s2_bits_traceTag),
    .io_taskFromArb_s2_bits_dataCheckErr(io_taskFromArb_s2_bits_dataCheckErr),
    .io_taskInfo_s1_valid(io_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel(io_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_isKeyword(io_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode(io_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_sourceId(io_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_mshrTask(io_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mergeA(io_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword(io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode(io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_sourceId(io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_fromReqArb_status_s1_tags_1(io_fromReqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_0(io_fromReqArb_status_s1_sets_0),
    .io_fromReqArb_status_s1_sets_1(io_fromReqArb_status_s1_sets_1),
    .io_fromReqArb_status_s1_sets_2(io_fromReqArb_status_s1_sets_2),
    .io_fromReqArb_status_s1_sets_3(io_fromReqArb_status_s1_sets_3),
    .io_toReqArb_blockG_s1(i_io_toReqArb_blockG_s1),
    .io_toReqArb_blockB_s1(i_io_toReqArb_blockB_s1),
    .io_toReqArb_blockC_s1(i_io_toReqArb_blockC_s1),
    .io_toReqBuf_0(i_io_toReqBuf_0),
    .io_toReqBuf_1(i_io_toReqBuf_1),
    .io_status_vec_toD_0_valid(i_io_status_vec_toD_0_valid),
    .io_status_vec_toD_0_bits_channel(i_io_status_vec_toD_0_bits_channel),
    .io_status_vec_toD_1_valid(i_io_status_vec_toD_1_valid),
    .io_status_vec_toD_1_bits_channel(i_io_status_vec_toD_1_bits_channel),
    .io_status_vec_toD_2_valid(i_io_status_vec_toD_2_valid),
    .io_status_vec_toD_2_bits_channel(i_io_status_vec_toD_2_bits_channel),
    .io_status_vec_toTX_0_valid(i_io_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel(i_io_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel(i_io_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask(i_io_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid(i_io_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel(i_io_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel(i_io_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask(i_io_status_vec_toTX_1_bits_mshrTask),
    .io_status_vec_toTX_2_valid(i_io_status_vec_toTX_2_valid),
    .io_status_vec_toTX_2_bits_channel(i_io_status_vec_toTX_2_bits_channel),
    .io_status_vec_toTX_2_bits_txChannel(i_io_status_vec_toTX_2_bits_txChannel),
    .io_status_vec_toTX_2_bits_mshrTask(i_io_status_vec_toTX_2_bits_mshrTask),
    .io_dirResp_s3_hit(io_dirResp_s3_hit),
    .io_dirResp_s3_tag(io_dirResp_s3_tag),
    .io_dirResp_s3_set(io_dirResp_s3_set),
    .io_dirResp_s3_way(io_dirResp_s3_way),
    .io_dirResp_s3_meta_dirty(io_dirResp_s3_meta_dirty),
    .io_dirResp_s3_meta_state(io_dirResp_s3_meta_state),
    .io_dirResp_s3_meta_clients(io_dirResp_s3_meta_clients),
    .io_dirResp_s3_meta_alias(io_dirResp_s3_meta_alias),
    .io_dirResp_s3_meta_prefetch(io_dirResp_s3_meta_prefetch),
    .io_dirResp_s3_meta_prefetchSrc(io_dirResp_s3_meta_prefetchSrc),
    .io_dirResp_s3_meta_accessed(io_dirResp_s3_meta_accessed),
    .io_dirResp_s3_meta_tagErr(io_dirResp_s3_meta_tagErr),
    .io_dirResp_s3_meta_dataErr(io_dirResp_s3_meta_dataErr),
    .io_dirResp_s3_error(io_dirResp_s3_error),
    .io_replResp_valid(io_replResp_valid),
    .io_replResp_bits_way(io_replResp_bits_way),
    .io_replResp_bits_meta_state(io_replResp_bits_meta_state),
    .io_replResp_bits_retry(io_replResp_bits_retry),
    .io_toMSHRCtl_mshr_alloc_s3_valid(i_io_toMSHRCtl_mshr_alloc_s3_valid),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error(i_io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack),
    .io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct(i_io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_channel(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_channel),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_set(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_set),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_tag(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_tag),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_off(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_off),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_alias(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_param(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_param),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc),
    .io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag(i_io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag),
    .io_fromMSHRCtl_mshr_alloc_ptr(io_fromMSHRCtl_mshr_alloc_ptr),
    .io_bufResp_data_0(io_bufResp_data_0),
    .io_bufResp_data_1(io_bufResp_data_1),
    .io_refillBufResp_s3_bits_data(io_refillBufResp_s3_bits_data),
    .io_releaseBufResp_s3_valid(io_releaseBufResp_s3_valid),
    .io_releaseBufResp_s3_bits_data(io_releaseBufResp_s3_bits_data),
    .io_toDS_en_s3(i_io_toDS_en_s3),
    .io_toDS_req_s3_valid(i_io_toDS_req_s3_valid),
    .io_toDS_req_s3_bits_way(i_io_toDS_req_s3_bits_way),
    .io_toDS_req_s3_bits_set(i_io_toDS_req_s3_bits_set),
    .io_toDS_req_s3_bits_wen(i_io_toDS_req_s3_bits_wen),
    .io_toDS_rdata_s5_data(io_toDS_rdata_s5_data),
    .io_toDS_wdata_s3_data(i_io_toDS_wdata_s3_data),
    .io_toDS_error_s5(io_toDS_error_s5),
    .io_toSourceD_valid(i_io_toSourceD_valid),
    .io_toSourceD_bits_task_channel(i_io_toSourceD_bits_task_channel),
    .io_toSourceD_bits_task_txChannel(i_io_toSourceD_bits_task_txChannel),
    .io_toSourceD_bits_task_set(i_io_toSourceD_bits_task_set),
    .io_toSourceD_bits_task_tag(i_io_toSourceD_bits_task_tag),
    .io_toSourceD_bits_task_off(i_io_toSourceD_bits_task_off),
    .io_toSourceD_bits_task_alias(i_io_toSourceD_bits_task_alias),
    .io_toSourceD_bits_task_vaddr(i_io_toSourceD_bits_task_vaddr),
    .io_toSourceD_bits_task_isKeyword(i_io_toSourceD_bits_task_isKeyword),
    .io_toSourceD_bits_task_opcode(i_io_toSourceD_bits_task_opcode),
    .io_toSourceD_bits_task_param(i_io_toSourceD_bits_task_param),
    .io_toSourceD_bits_task_size(i_io_toSourceD_bits_task_size),
    .io_toSourceD_bits_task_sourceId(i_io_toSourceD_bits_task_sourceId),
    .io_toSourceD_bits_task_bufIdx(i_io_toSourceD_bits_task_bufIdx),
    .io_toSourceD_bits_task_needProbeAckData(i_io_toSourceD_bits_task_needProbeAckData),
    .io_toSourceD_bits_task_denied(i_io_toSourceD_bits_task_denied),
    .io_toSourceD_bits_task_corrupt(i_io_toSourceD_bits_task_corrupt),
    .io_toSourceD_bits_task_mshrTask(i_io_toSourceD_bits_task_mshrTask),
    .io_toSourceD_bits_task_mshrId(i_io_toSourceD_bits_task_mshrId),
    .io_toSourceD_bits_task_aliasTask(i_io_toSourceD_bits_task_aliasTask),
    .io_toSourceD_bits_task_useProbeData(i_io_toSourceD_bits_task_useProbeData),
    .io_toSourceD_bits_task_mshrRetry(i_io_toSourceD_bits_task_mshrRetry),
    .io_toSourceD_bits_task_readProbeDataDown(i_io_toSourceD_bits_task_readProbeDataDown),
    .io_toSourceD_bits_task_fromL2pft(i_io_toSourceD_bits_task_fromL2pft),
    .io_toSourceD_bits_task_needHint(i_io_toSourceD_bits_task_needHint),
    .io_toSourceD_bits_task_dirty(i_io_toSourceD_bits_task_dirty),
    .io_toSourceD_bits_task_way(i_io_toSourceD_bits_task_way),
    .io_toSourceD_bits_task_meta_dirty(i_io_toSourceD_bits_task_meta_dirty),
    .io_toSourceD_bits_task_meta_state(i_io_toSourceD_bits_task_meta_state),
    .io_toSourceD_bits_task_meta_clients(i_io_toSourceD_bits_task_meta_clients),
    .io_toSourceD_bits_task_meta_alias(i_io_toSourceD_bits_task_meta_alias),
    .io_toSourceD_bits_task_meta_prefetch(i_io_toSourceD_bits_task_meta_prefetch),
    .io_toSourceD_bits_task_meta_prefetchSrc(i_io_toSourceD_bits_task_meta_prefetchSrc),
    .io_toSourceD_bits_task_meta_accessed(i_io_toSourceD_bits_task_meta_accessed),
    .io_toSourceD_bits_task_meta_tagErr(i_io_toSourceD_bits_task_meta_tagErr),
    .io_toSourceD_bits_task_meta_dataErr(i_io_toSourceD_bits_task_meta_dataErr),
    .io_toSourceD_bits_task_metaWen(i_io_toSourceD_bits_task_metaWen),
    .io_toSourceD_bits_task_tagWen(i_io_toSourceD_bits_task_tagWen),
    .io_toSourceD_bits_task_dsWen(i_io_toSourceD_bits_task_dsWen),
    .io_toSourceD_bits_task_wayMask(i_io_toSourceD_bits_task_wayMask),
    .io_toSourceD_bits_task_replTask(i_io_toSourceD_bits_task_replTask),
    .io_toSourceD_bits_task_cmoTask(i_io_toSourceD_bits_task_cmoTask),
    .io_toSourceD_bits_task_cmoAll(i_io_toSourceD_bits_task_cmoAll),
    .io_toSourceD_bits_task_reqSource(i_io_toSourceD_bits_task_reqSource),
    .io_toSourceD_bits_task_mergeA(i_io_toSourceD_bits_task_mergeA),
    .io_toSourceD_bits_task_aMergeTask_off(i_io_toSourceD_bits_task_aMergeTask_off),
    .io_toSourceD_bits_task_aMergeTask_alias(i_io_toSourceD_bits_task_aMergeTask_alias),
    .io_toSourceD_bits_task_aMergeTask_vaddr(i_io_toSourceD_bits_task_aMergeTask_vaddr),
    .io_toSourceD_bits_task_aMergeTask_isKeyword(i_io_toSourceD_bits_task_aMergeTask_isKeyword),
    .io_toSourceD_bits_task_aMergeTask_opcode(i_io_toSourceD_bits_task_aMergeTask_opcode),
    .io_toSourceD_bits_task_aMergeTask_param(i_io_toSourceD_bits_task_aMergeTask_param),
    .io_toSourceD_bits_task_aMergeTask_sourceId(i_io_toSourceD_bits_task_aMergeTask_sourceId),
    .io_toSourceD_bits_task_aMergeTask_meta_dirty(i_io_toSourceD_bits_task_aMergeTask_meta_dirty),
    .io_toSourceD_bits_task_aMergeTask_meta_state(i_io_toSourceD_bits_task_aMergeTask_meta_state),
    .io_toSourceD_bits_task_aMergeTask_meta_clients(i_io_toSourceD_bits_task_aMergeTask_meta_clients),
    .io_toSourceD_bits_task_aMergeTask_meta_alias(i_io_toSourceD_bits_task_aMergeTask_meta_alias),
    .io_toSourceD_bits_task_aMergeTask_meta_prefetch(i_io_toSourceD_bits_task_aMergeTask_meta_prefetch),
    .io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc(i_io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc),
    .io_toSourceD_bits_task_aMergeTask_meta_accessed(i_io_toSourceD_bits_task_aMergeTask_meta_accessed),
    .io_toSourceD_bits_task_aMergeTask_meta_tagErr(i_io_toSourceD_bits_task_aMergeTask_meta_tagErr),
    .io_toSourceD_bits_task_aMergeTask_meta_dataErr(i_io_toSourceD_bits_task_aMergeTask_meta_dataErr),
    .io_toSourceD_bits_task_snpHitRelease(i_io_toSourceD_bits_task_snpHitRelease),
    .io_toSourceD_bits_task_snpHitReleaseToInval(i_io_toSourceD_bits_task_snpHitReleaseToInval),
    .io_toSourceD_bits_task_snpHitReleaseToClean(i_io_toSourceD_bits_task_snpHitReleaseToClean),
    .io_toSourceD_bits_task_snpHitReleaseWithData(i_io_toSourceD_bits_task_snpHitReleaseWithData),
    .io_toSourceD_bits_task_snpHitReleaseIdx(i_io_toSourceD_bits_task_snpHitReleaseIdx),
    .io_toSourceD_bits_task_snpHitReleaseMeta_dirty(i_io_toSourceD_bits_task_snpHitReleaseMeta_dirty),
    .io_toSourceD_bits_task_snpHitReleaseMeta_state(i_io_toSourceD_bits_task_snpHitReleaseMeta_state),
    .io_toSourceD_bits_task_snpHitReleaseMeta_clients(i_io_toSourceD_bits_task_snpHitReleaseMeta_clients),
    .io_toSourceD_bits_task_snpHitReleaseMeta_alias(i_io_toSourceD_bits_task_snpHitReleaseMeta_alias),
    .io_toSourceD_bits_task_snpHitReleaseMeta_prefetch(i_io_toSourceD_bits_task_snpHitReleaseMeta_prefetch),
    .io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc(i_io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toSourceD_bits_task_snpHitReleaseMeta_accessed(i_io_toSourceD_bits_task_snpHitReleaseMeta_accessed),
    .io_toSourceD_bits_task_snpHitReleaseMeta_tagErr(i_io_toSourceD_bits_task_snpHitReleaseMeta_tagErr),
    .io_toSourceD_bits_task_snpHitReleaseMeta_dataErr(i_io_toSourceD_bits_task_snpHitReleaseMeta_dataErr),
    .io_toSourceD_bits_task_tgtID(i_io_toSourceD_bits_task_tgtID),
    .io_toSourceD_bits_task_srcID(i_io_toSourceD_bits_task_srcID),
    .io_toSourceD_bits_task_txnID(i_io_toSourceD_bits_task_txnID),
    .io_toSourceD_bits_task_homeNID(i_io_toSourceD_bits_task_homeNID),
    .io_toSourceD_bits_task_dbID(i_io_toSourceD_bits_task_dbID),
    .io_toSourceD_bits_task_fwdNID(i_io_toSourceD_bits_task_fwdNID),
    .io_toSourceD_bits_task_fwdTxnID(i_io_toSourceD_bits_task_fwdTxnID),
    .io_toSourceD_bits_task_chiOpcode(i_io_toSourceD_bits_task_chiOpcode),
    .io_toSourceD_bits_task_resp(i_io_toSourceD_bits_task_resp),
    .io_toSourceD_bits_task_fwdState(i_io_toSourceD_bits_task_fwdState),
    .io_toSourceD_bits_task_pCrdType(i_io_toSourceD_bits_task_pCrdType),
    .io_toSourceD_bits_task_retToSrc(i_io_toSourceD_bits_task_retToSrc),
    .io_toSourceD_bits_task_likelyshared(i_io_toSourceD_bits_task_likelyshared),
    .io_toSourceD_bits_task_expCompAck(i_io_toSourceD_bits_task_expCompAck),
    .io_toSourceD_bits_task_allowRetry(i_io_toSourceD_bits_task_allowRetry),
    .io_toSourceD_bits_task_memAttr_allocate(i_io_toSourceD_bits_task_memAttr_allocate),
    .io_toSourceD_bits_task_memAttr_cacheable(i_io_toSourceD_bits_task_memAttr_cacheable),
    .io_toSourceD_bits_task_memAttr_device(i_io_toSourceD_bits_task_memAttr_device),
    .io_toSourceD_bits_task_memAttr_ewa(i_io_toSourceD_bits_task_memAttr_ewa),
    .io_toSourceD_bits_task_traceTag(i_io_toSourceD_bits_task_traceTag),
    .io_toSourceD_bits_task_dataCheckErr(i_io_toSourceD_bits_task_dataCheckErr),
    .io_toSourceD_bits_data_data(i_io_toSourceD_bits_data_data),
    .io_toTXREQ_valid(i_io_toTXREQ_valid),
    .io_toTXREQ_bits_tgtID(i_io_toTXREQ_bits_tgtID),
    .io_toTXREQ_bits_srcID(i_io_toTXREQ_bits_srcID),
    .io_toTXREQ_bits_txnID(i_io_toTXREQ_bits_txnID),
    .io_toTXREQ_bits_opcode(i_io_toTXREQ_bits_opcode),
    .io_toTXREQ_bits_addr(i_io_toTXREQ_bits_addr),
    .io_toTXREQ_bits_likelyshared(i_io_toTXREQ_bits_likelyshared),
    .io_toTXREQ_bits_allowRetry(i_io_toTXREQ_bits_allowRetry),
    .io_toTXREQ_bits_pCrdType(i_io_toTXREQ_bits_pCrdType),
    .io_toTXREQ_bits_memAttr_allocate(i_io_toTXREQ_bits_memAttr_allocate),
    .io_toTXREQ_bits_memAttr_cacheable(i_io_toTXREQ_bits_memAttr_cacheable),
    .io_toTXREQ_bits_memAttr_device(i_io_toTXREQ_bits_memAttr_device),
    .io_toTXREQ_bits_memAttr_ewa(i_io_toTXREQ_bits_memAttr_ewa),
    .io_toTXREQ_bits_expCompAck(i_io_toTXREQ_bits_expCompAck),
    .io_toTXRSP_valid(i_io_toTXRSP_valid),
    .io_toTXRSP_bits_txChannel(i_io_toTXRSP_bits_txChannel),
    .io_toTXRSP_bits_denied(i_io_toTXRSP_bits_denied),
    .io_toTXRSP_bits_tgtID(i_io_toTXRSP_bits_tgtID),
    .io_toTXRSP_bits_srcID(i_io_toTXRSP_bits_srcID),
    .io_toTXRSP_bits_txnID(i_io_toTXRSP_bits_txnID),
    .io_toTXRSP_bits_dbID(i_io_toTXRSP_bits_dbID),
    .io_toTXRSP_bits_chiOpcode(i_io_toTXRSP_bits_chiOpcode),
    .io_toTXRSP_bits_resp(i_io_toTXRSP_bits_resp),
    .io_toTXRSP_bits_fwdState(i_io_toTXRSP_bits_fwdState),
    .io_toTXRSP_bits_pCrdType(i_io_toTXRSP_bits_pCrdType),
    .io_toTXRSP_bits_traceTag(i_io_toTXRSP_bits_traceTag),
    .io_toTXDAT_ready(io_toTXDAT_ready),
    .io_toTXDAT_valid(i_io_toTXDAT_valid),
    .io_toTXDAT_bits_task_channel(i_io_toTXDAT_bits_task_channel),
    .io_toTXDAT_bits_task_txChannel(i_io_toTXDAT_bits_task_txChannel),
    .io_toTXDAT_bits_task_set(i_io_toTXDAT_bits_task_set),
    .io_toTXDAT_bits_task_tag(i_io_toTXDAT_bits_task_tag),
    .io_toTXDAT_bits_task_off(i_io_toTXDAT_bits_task_off),
    .io_toTXDAT_bits_task_alias(i_io_toTXDAT_bits_task_alias),
    .io_toTXDAT_bits_task_vaddr(i_io_toTXDAT_bits_task_vaddr),
    .io_toTXDAT_bits_task_isKeyword(i_io_toTXDAT_bits_task_isKeyword),
    .io_toTXDAT_bits_task_opcode(i_io_toTXDAT_bits_task_opcode),
    .io_toTXDAT_bits_task_param(i_io_toTXDAT_bits_task_param),
    .io_toTXDAT_bits_task_size(i_io_toTXDAT_bits_task_size),
    .io_toTXDAT_bits_task_sourceId(i_io_toTXDAT_bits_task_sourceId),
    .io_toTXDAT_bits_task_bufIdx(i_io_toTXDAT_bits_task_bufIdx),
    .io_toTXDAT_bits_task_needProbeAckData(i_io_toTXDAT_bits_task_needProbeAckData),
    .io_toTXDAT_bits_task_denied(i_io_toTXDAT_bits_task_denied),
    .io_toTXDAT_bits_task_corrupt(i_io_toTXDAT_bits_task_corrupt),
    .io_toTXDAT_bits_task_mshrTask(i_io_toTXDAT_bits_task_mshrTask),
    .io_toTXDAT_bits_task_mshrId(i_io_toTXDAT_bits_task_mshrId),
    .io_toTXDAT_bits_task_aliasTask(i_io_toTXDAT_bits_task_aliasTask),
    .io_toTXDAT_bits_task_useProbeData(i_io_toTXDAT_bits_task_useProbeData),
    .io_toTXDAT_bits_task_mshrRetry(i_io_toTXDAT_bits_task_mshrRetry),
    .io_toTXDAT_bits_task_readProbeDataDown(i_io_toTXDAT_bits_task_readProbeDataDown),
    .io_toTXDAT_bits_task_fromL2pft(i_io_toTXDAT_bits_task_fromL2pft),
    .io_toTXDAT_bits_task_needHint(i_io_toTXDAT_bits_task_needHint),
    .io_toTXDAT_bits_task_dirty(i_io_toTXDAT_bits_task_dirty),
    .io_toTXDAT_bits_task_way(i_io_toTXDAT_bits_task_way),
    .io_toTXDAT_bits_task_meta_dirty(i_io_toTXDAT_bits_task_meta_dirty),
    .io_toTXDAT_bits_task_meta_state(i_io_toTXDAT_bits_task_meta_state),
    .io_toTXDAT_bits_task_meta_clients(i_io_toTXDAT_bits_task_meta_clients),
    .io_toTXDAT_bits_task_meta_alias(i_io_toTXDAT_bits_task_meta_alias),
    .io_toTXDAT_bits_task_meta_prefetch(i_io_toTXDAT_bits_task_meta_prefetch),
    .io_toTXDAT_bits_task_meta_prefetchSrc(i_io_toTXDAT_bits_task_meta_prefetchSrc),
    .io_toTXDAT_bits_task_meta_accessed(i_io_toTXDAT_bits_task_meta_accessed),
    .io_toTXDAT_bits_task_meta_tagErr(i_io_toTXDAT_bits_task_meta_tagErr),
    .io_toTXDAT_bits_task_meta_dataErr(i_io_toTXDAT_bits_task_meta_dataErr),
    .io_toTXDAT_bits_task_metaWen(i_io_toTXDAT_bits_task_metaWen),
    .io_toTXDAT_bits_task_tagWen(i_io_toTXDAT_bits_task_tagWen),
    .io_toTXDAT_bits_task_dsWen(i_io_toTXDAT_bits_task_dsWen),
    .io_toTXDAT_bits_task_wayMask(i_io_toTXDAT_bits_task_wayMask),
    .io_toTXDAT_bits_task_replTask(i_io_toTXDAT_bits_task_replTask),
    .io_toTXDAT_bits_task_cmoTask(i_io_toTXDAT_bits_task_cmoTask),
    .io_toTXDAT_bits_task_cmoAll(i_io_toTXDAT_bits_task_cmoAll),
    .io_toTXDAT_bits_task_reqSource(i_io_toTXDAT_bits_task_reqSource),
    .io_toTXDAT_bits_task_mergeA(i_io_toTXDAT_bits_task_mergeA),
    .io_toTXDAT_bits_task_aMergeTask_off(i_io_toTXDAT_bits_task_aMergeTask_off),
    .io_toTXDAT_bits_task_aMergeTask_alias(i_io_toTXDAT_bits_task_aMergeTask_alias),
    .io_toTXDAT_bits_task_aMergeTask_vaddr(i_io_toTXDAT_bits_task_aMergeTask_vaddr),
    .io_toTXDAT_bits_task_aMergeTask_isKeyword(i_io_toTXDAT_bits_task_aMergeTask_isKeyword),
    .io_toTXDAT_bits_task_aMergeTask_opcode(i_io_toTXDAT_bits_task_aMergeTask_opcode),
    .io_toTXDAT_bits_task_aMergeTask_param(i_io_toTXDAT_bits_task_aMergeTask_param),
    .io_toTXDAT_bits_task_aMergeTask_sourceId(i_io_toTXDAT_bits_task_aMergeTask_sourceId),
    .io_toTXDAT_bits_task_aMergeTask_meta_dirty(i_io_toTXDAT_bits_task_aMergeTask_meta_dirty),
    .io_toTXDAT_bits_task_aMergeTask_meta_state(i_io_toTXDAT_bits_task_aMergeTask_meta_state),
    .io_toTXDAT_bits_task_aMergeTask_meta_clients(i_io_toTXDAT_bits_task_aMergeTask_meta_clients),
    .io_toTXDAT_bits_task_aMergeTask_meta_alias(i_io_toTXDAT_bits_task_aMergeTask_meta_alias),
    .io_toTXDAT_bits_task_aMergeTask_meta_prefetch(i_io_toTXDAT_bits_task_aMergeTask_meta_prefetch),
    .io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc(i_io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc),
    .io_toTXDAT_bits_task_aMergeTask_meta_accessed(i_io_toTXDAT_bits_task_aMergeTask_meta_accessed),
    .io_toTXDAT_bits_task_aMergeTask_meta_tagErr(i_io_toTXDAT_bits_task_aMergeTask_meta_tagErr),
    .io_toTXDAT_bits_task_aMergeTask_meta_dataErr(i_io_toTXDAT_bits_task_aMergeTask_meta_dataErr),
    .io_toTXDAT_bits_task_snpHitRelease(i_io_toTXDAT_bits_task_snpHitRelease),
    .io_toTXDAT_bits_task_snpHitReleaseToInval(i_io_toTXDAT_bits_task_snpHitReleaseToInval),
    .io_toTXDAT_bits_task_snpHitReleaseToClean(i_io_toTXDAT_bits_task_snpHitReleaseToClean),
    .io_toTXDAT_bits_task_snpHitReleaseWithData(i_io_toTXDAT_bits_task_snpHitReleaseWithData),
    .io_toTXDAT_bits_task_snpHitReleaseIdx(i_io_toTXDAT_bits_task_snpHitReleaseIdx),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_dirty(i_io_toTXDAT_bits_task_snpHitReleaseMeta_dirty),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_state(i_io_toTXDAT_bits_task_snpHitReleaseMeta_state),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_clients(i_io_toTXDAT_bits_task_snpHitReleaseMeta_clients),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_alias(i_io_toTXDAT_bits_task_snpHitReleaseMeta_alias),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch(i_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc(i_io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_accessed(i_io_toTXDAT_bits_task_snpHitReleaseMeta_accessed),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr(i_io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr),
    .io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr(i_io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr),
    .io_toTXDAT_bits_task_tgtID(i_io_toTXDAT_bits_task_tgtID),
    .io_toTXDAT_bits_task_srcID(i_io_toTXDAT_bits_task_srcID),
    .io_toTXDAT_bits_task_txnID(i_io_toTXDAT_bits_task_txnID),
    .io_toTXDAT_bits_task_homeNID(i_io_toTXDAT_bits_task_homeNID),
    .io_toTXDAT_bits_task_dbID(i_io_toTXDAT_bits_task_dbID),
    .io_toTXDAT_bits_task_fwdNID(i_io_toTXDAT_bits_task_fwdNID),
    .io_toTXDAT_bits_task_fwdTxnID(i_io_toTXDAT_bits_task_fwdTxnID),
    .io_toTXDAT_bits_task_chiOpcode(i_io_toTXDAT_bits_task_chiOpcode),
    .io_toTXDAT_bits_task_resp(i_io_toTXDAT_bits_task_resp),
    .io_toTXDAT_bits_task_fwdState(i_io_toTXDAT_bits_task_fwdState),
    .io_toTXDAT_bits_task_pCrdType(i_io_toTXDAT_bits_task_pCrdType),
    .io_toTXDAT_bits_task_retToSrc(i_io_toTXDAT_bits_task_retToSrc),
    .io_toTXDAT_bits_task_likelyshared(i_io_toTXDAT_bits_task_likelyshared),
    .io_toTXDAT_bits_task_expCompAck(i_io_toTXDAT_bits_task_expCompAck),
    .io_toTXDAT_bits_task_allowRetry(i_io_toTXDAT_bits_task_allowRetry),
    .io_toTXDAT_bits_task_memAttr_allocate(i_io_toTXDAT_bits_task_memAttr_allocate),
    .io_toTXDAT_bits_task_memAttr_cacheable(i_io_toTXDAT_bits_task_memAttr_cacheable),
    .io_toTXDAT_bits_task_memAttr_device(i_io_toTXDAT_bits_task_memAttr_device),
    .io_toTXDAT_bits_task_memAttr_ewa(i_io_toTXDAT_bits_task_memAttr_ewa),
    .io_toTXDAT_bits_task_traceTag(i_io_toTXDAT_bits_task_traceTag),
    .io_toTXDAT_bits_task_dataCheckErr(i_io_toTXDAT_bits_task_dataCheckErr),
    .io_toTXDAT_bits_data_data(i_io_toTXDAT_bits_data_data),
    .io_metaWReq_valid(i_io_metaWReq_valid),
    .io_metaWReq_bits_set(i_io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(i_io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty(i_io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state(i_io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients(i_io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias(i_io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch(i_io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc(i_io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed(i_io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr(i_io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr(i_io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid(i_io_tagWReq_valid),
    .io_tagWReq_bits_set(i_io_tagWReq_bits_set),
    .io_tagWReq_bits_way(i_io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(i_io_tagWReq_bits_wtag),
    .io_releaseBufWrite_valid(i_io_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_id(i_io_releaseBufWrite_bits_id),
    .io_releaseBufWrite_bits_data_data(i_io_releaseBufWrite_bits_data_data),
    .io_nestedwb_set(i_io_nestedwb_set),
    .io_nestedwb_tag(i_io_nestedwb_tag),
    .io_nestedwb_c_set_dirty(i_io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip(i_io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty(i_io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB(i_io_nestedwb_b_toB),
    .io_nestedwb_b_toN(i_io_nestedwb_b_toN),
    .io_nestedwb_b_toClean(i_io_nestedwb_b_toClean),
    .io_nestedwbData_data(i_io_nestedwbData_data),
    .io_l1Hint_ready(io_l1Hint_ready),
    .io_l1Hint_valid(i_io_l1Hint_valid),
    .io_l1Hint_bits_sourceId(i_io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword(i_io_l1Hint_bits_isKeyword),
    .io_prefetchTrain_ready(io_prefetchTrain_ready),
    .io_prefetchTrain_valid(i_io_prefetchTrain_valid),
    .io_prefetchTrain_bits_tag(i_io_prefetchTrain_bits_tag),
    .io_prefetchTrain_bits_set(i_io_prefetchTrain_bits_set),
    .io_prefetchTrain_bits_needT(i_io_prefetchTrain_bits_needT),
    .io_prefetchTrain_bits_source(i_io_prefetchTrain_bits_source),
    .io_prefetchTrain_bits_vaddr(i_io_prefetchTrain_bits_vaddr),
    .io_prefetchTrain_bits_hit(i_io_prefetchTrain_bits_hit),
    .io_prefetchTrain_bits_prefetched(i_io_prefetchTrain_bits_prefetched),
    .io_prefetchTrain_bits_pfsource(i_io_prefetchTrain_bits_pfsource),
    .io_prefetchTrain_bits_reqsource(i_io_prefetchTrain_bits_reqsource),
    .io_error_valid(i_io_error_valid),
    .io_error_bits_valid(i_io_error_bits_valid),
    .io_error_bits_address(i_io_error_bits_address),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value)
  );

  function automatic logic [2:0] oh3(); int k; k = $urandom_range(0,2); return (3'h1 << k); endfunction

  task automatic drive_random();
    io_taskFromArb_s2_valid = ($urandom_range(0,1) == 0);
    io_taskFromArb_s2_bits_channel = oh3();
    io_taskFromArb_s2_bits_txChannel = oh3();
    io_taskFromArb_s2_bits_set = $urandom_range(0,7);
    io_taskFromArb_s2_bits_tag = $urandom_range(0,7);
    io_taskFromArb_s2_bits_off = $urandom;
    io_taskFromArb_s2_bits_alias = $urandom;
    io_taskFromArb_s2_bits_vaddr = {$urandom, $urandom};
    io_taskFromArb_s2_bits_isKeyword = $urandom;
    io_taskFromArb_s2_bits_opcode = $urandom_range(0,14);
    io_taskFromArb_s2_bits_param = $urandom_range(0,5);
    io_taskFromArb_s2_bits_size = $urandom;
    io_taskFromArb_s2_bits_sourceId = $urandom;
    io_taskFromArb_s2_bits_bufIdx = $urandom;
    io_taskFromArb_s2_bits_needProbeAckData = $urandom;
    io_taskFromArb_s2_bits_denied = $urandom;
    io_taskFromArb_s2_bits_corrupt = $urandom;
    io_taskFromArb_s2_bits_mshrTask = $urandom;
    io_taskFromArb_s2_bits_mshrId = $urandom;
    io_taskFromArb_s2_bits_aliasTask = $urandom;
    io_taskFromArb_s2_bits_useProbeData = $urandom;
    io_taskFromArb_s2_bits_mshrRetry = $urandom;
    io_taskFromArb_s2_bits_readProbeDataDown = $urandom;
    io_taskFromArb_s2_bits_fromL2pft = $urandom;
    io_taskFromArb_s2_bits_needHint = $urandom;
    io_taskFromArb_s2_bits_dirty = $urandom;
    io_taskFromArb_s2_bits_way = $urandom_range(0,7);
    io_taskFromArb_s2_bits_meta_dirty = $urandom;
    io_taskFromArb_s2_bits_meta_state = $urandom_range(0,3);
    io_taskFromArb_s2_bits_meta_clients = $urandom;
    io_taskFromArb_s2_bits_meta_alias = $urandom;
    io_taskFromArb_s2_bits_meta_prefetch = $urandom;
    io_taskFromArb_s2_bits_meta_prefetchSrc = $urandom;
    io_taskFromArb_s2_bits_meta_accessed = $urandom;
    io_taskFromArb_s2_bits_meta_tagErr = $urandom;
    io_taskFromArb_s2_bits_meta_dataErr = $urandom;
    io_taskFromArb_s2_bits_metaWen = $urandom;
    io_taskFromArb_s2_bits_tagWen = $urandom;
    io_taskFromArb_s2_bits_dsWen = $urandom;
    io_taskFromArb_s2_bits_wayMask = $urandom;
    io_taskFromArb_s2_bits_replTask = $urandom;
    io_taskFromArb_s2_bits_cmoTask = $urandom;
    io_taskFromArb_s2_bits_cmoAll = $urandom;
    io_taskFromArb_s2_bits_reqSource = $urandom;
    io_taskFromArb_s2_bits_mergeA = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_off = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_alias = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_vaddr = {$urandom, $urandom};
    io_taskFromArb_s2_bits_aMergeTask_isKeyword = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_opcode = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_param = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_sourceId = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_dirty = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_state = $urandom_range(0,3);
    io_taskFromArb_s2_bits_aMergeTask_meta_clients = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_alias = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_prefetch = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_accessed = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_tagErr = $urandom;
    io_taskFromArb_s2_bits_aMergeTask_meta_dataErr = $urandom;
    io_taskFromArb_s2_bits_snpHitRelease = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseToInval = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseToClean = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseWithData = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseIdx = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_state = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_clients = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_alias = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr = $urandom;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr = $urandom;
    io_taskFromArb_s2_bits_tgtID = $urandom;
    io_taskFromArb_s2_bits_srcID = $urandom;
    io_taskFromArb_s2_bits_txnID = $urandom;
    io_taskFromArb_s2_bits_homeNID = $urandom;
    io_taskFromArb_s2_bits_dbID = $urandom;
    io_taskFromArb_s2_bits_fwdNID = $urandom;
    io_taskFromArb_s2_bits_fwdTxnID = $urandom;
    io_taskFromArb_s2_bits_chiOpcode = $urandom_range(0,32);
    io_taskFromArb_s2_bits_resp = $urandom;
    io_taskFromArb_s2_bits_fwdState = $urandom;
    io_taskFromArb_s2_bits_pCrdType = $urandom;
    io_taskFromArb_s2_bits_retToSrc = $urandom;
    io_taskFromArb_s2_bits_likelyshared = $urandom;
    io_taskFromArb_s2_bits_expCompAck = $urandom;
    io_taskFromArb_s2_bits_allowRetry = $urandom;
    io_taskFromArb_s2_bits_memAttr_allocate = $urandom;
    io_taskFromArb_s2_bits_memAttr_cacheable = $urandom;
    io_taskFromArb_s2_bits_memAttr_device = $urandom;
    io_taskFromArb_s2_bits_memAttr_ewa = $urandom;
    io_taskFromArb_s2_bits_traceTag = $urandom;
    io_taskFromArb_s2_bits_dataCheckErr = $urandom;
    io_taskInfo_s1_valid = ($urandom_range(0,1) == 0);
    io_taskInfo_s1_bits_channel = $urandom;
    io_taskInfo_s1_bits_isKeyword = $urandom;
    io_taskInfo_s1_bits_opcode = $urandom_range(0,14);
    io_taskInfo_s1_bits_sourceId = $urandom;
    io_taskInfo_s1_bits_mshrTask = $urandom;
    io_taskInfo_s1_bits_mergeA = $urandom;
    io_taskInfo_s1_bits_aMergeTask_isKeyword = $urandom;
    io_taskInfo_s1_bits_aMergeTask_opcode = $urandom;
    io_taskInfo_s1_bits_aMergeTask_sourceId = $urandom;
    io_fromReqArb_status_s1_tags_1 = $urandom_range(0,7);
    io_fromReqArb_status_s1_sets_0 = $urandom_range(0,7);
    io_fromReqArb_status_s1_sets_1 = $urandom_range(0,7);
    io_fromReqArb_status_s1_sets_2 = $urandom_range(0,7);
    io_fromReqArb_status_s1_sets_3 = $urandom_range(0,7);
    io_dirResp_s3_hit = $urandom;
    io_dirResp_s3_tag = $urandom;
    io_dirResp_s3_set = $urandom;
    io_dirResp_s3_way = $urandom;
    io_dirResp_s3_meta_dirty = $urandom;
    io_dirResp_s3_meta_state = $urandom_range(0,3);
    io_dirResp_s3_meta_clients = $urandom;
    io_dirResp_s3_meta_alias = $urandom;
    io_dirResp_s3_meta_prefetch = $urandom;
    io_dirResp_s3_meta_prefetchSrc = $urandom;
    io_dirResp_s3_meta_accessed = $urandom;
    io_dirResp_s3_meta_tagErr = $urandom;
    io_dirResp_s3_meta_dataErr = $urandom;
    io_dirResp_s3_error = $urandom;
    io_replResp_valid = ($urandom_range(0,1) == 0);
    io_replResp_bits_way = $urandom_range(0,7);
    io_replResp_bits_meta_state = $urandom_range(0,3);
    io_replResp_bits_retry = $urandom;
    io_fromMSHRCtl_mshr_alloc_ptr = $urandom;
    io_bufResp_data_0 = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_bufResp_data_1 = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_refillBufResp_s3_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_releaseBufResp_s3_valid = ($urandom_range(0,1) == 0);
    io_releaseBufResp_s3_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_toDS_rdata_s5_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_toDS_error_s5 = $urandom;
    io_toTXDAT_ready = ($urandom_range(0,2) != 0);
    io_l1Hint_ready = ($urandom_range(0,2) != 0);
    io_prefetchTrain_ready = ($urandom_range(0,2) != 0);
  endtask

  task automatic check_outputs();
    `CHK(io_toReqArb_blockG_s1)
    `CHK(io_toReqArb_blockB_s1)
    `CHK(io_toReqArb_blockC_s1)
    `CHK(io_toReqBuf_0)
    `CHK(io_toReqBuf_1)
    `CHK(io_status_vec_toD_0_valid)
    `CHK(io_status_vec_toD_0_bits_channel)
    `CHK(io_status_vec_toD_1_valid)
    `CHK(io_status_vec_toD_1_bits_channel)
    `CHK(io_status_vec_toD_2_valid)
    `CHK(io_status_vec_toD_2_bits_channel)
    `CHK(io_status_vec_toTX_0_valid)
    `CHK(io_status_vec_toTX_0_bits_channel)
    `CHK(io_status_vec_toTX_0_bits_txChannel)
    `CHK(io_status_vec_toTX_0_bits_mshrTask)
    `CHK(io_status_vec_toTX_1_valid)
    `CHK(io_status_vec_toTX_1_bits_channel)
    `CHK(io_status_vec_toTX_1_bits_txChannel)
    `CHK(io_status_vec_toTX_1_bits_mshrTask)
    `CHK(io_status_vec_toTX_2_valid)
    `CHK(io_status_vec_toTX_2_bits_channel)
    `CHK(io_status_vec_toTX_2_bits_txChannel)
    `CHK(io_status_vec_toTX_2_bits_mshrTask)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_valid)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_channel)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_set)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_tag)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_off)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_alias)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_param)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc)
    `CHK(io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag)
    `CHK(io_toDS_en_s3)
    `CHK(io_toDS_req_s3_valid)
    `CHK(io_toDS_req_s3_bits_way)
    `CHK(io_toDS_req_s3_bits_set)
    `CHK(io_toDS_req_s3_bits_wen)
    `CHK(io_toDS_wdata_s3_data)
    `CHK(io_toSourceD_valid)
    `CHK(io_toSourceD_bits_task_channel)
    `CHK(io_toSourceD_bits_task_txChannel)
    `CHK(io_toSourceD_bits_task_set)
    `CHK(io_toSourceD_bits_task_tag)
    `CHK(io_toSourceD_bits_task_off)
    `CHK(io_toSourceD_bits_task_alias)
    `CHK(io_toSourceD_bits_task_vaddr)
    `CHK(io_toSourceD_bits_task_isKeyword)
    `CHK(io_toSourceD_bits_task_opcode)
    `CHK(io_toSourceD_bits_task_param)
    `CHK(io_toSourceD_bits_task_size)
    `CHK(io_toSourceD_bits_task_sourceId)
    `CHK(io_toSourceD_bits_task_bufIdx)
    `CHK(io_toSourceD_bits_task_needProbeAckData)
    `CHK(io_toSourceD_bits_task_denied)
    `CHK(io_toSourceD_bits_task_corrupt)
    `CHK(io_toSourceD_bits_task_mshrTask)
    `CHK(io_toSourceD_bits_task_mshrId)
    `CHK(io_toSourceD_bits_task_aliasTask)
    `CHK(io_toSourceD_bits_task_useProbeData)
    `CHK(io_toSourceD_bits_task_mshrRetry)
    `CHK(io_toSourceD_bits_task_readProbeDataDown)
    `CHK(io_toSourceD_bits_task_fromL2pft)
    `CHK(io_toSourceD_bits_task_needHint)
    `CHK(io_toSourceD_bits_task_dirty)
    `CHK(io_toSourceD_bits_task_way)
    `CHK(io_toSourceD_bits_task_meta_dirty)
    `CHK(io_toSourceD_bits_task_meta_state)
    `CHK(io_toSourceD_bits_task_meta_clients)
    `CHK(io_toSourceD_bits_task_meta_alias)
    `CHK(io_toSourceD_bits_task_meta_prefetch)
    `CHK(io_toSourceD_bits_task_meta_prefetchSrc)
    `CHK(io_toSourceD_bits_task_meta_accessed)
    `CHK(io_toSourceD_bits_task_meta_tagErr)
    `CHK(io_toSourceD_bits_task_meta_dataErr)
    `CHK(io_toSourceD_bits_task_metaWen)
    `CHK(io_toSourceD_bits_task_tagWen)
    `CHK(io_toSourceD_bits_task_dsWen)
    `CHK(io_toSourceD_bits_task_wayMask)
    `CHK(io_toSourceD_bits_task_replTask)
    `CHK(io_toSourceD_bits_task_cmoTask)
    `CHK(io_toSourceD_bits_task_cmoAll)
    `CHK(io_toSourceD_bits_task_reqSource)
    `CHK(io_toSourceD_bits_task_mergeA)
    `CHK(io_toSourceD_bits_task_aMergeTask_off)
    `CHK(io_toSourceD_bits_task_aMergeTask_alias)
    `CHK(io_toSourceD_bits_task_aMergeTask_vaddr)
    `CHK(io_toSourceD_bits_task_aMergeTask_isKeyword)
    `CHK(io_toSourceD_bits_task_aMergeTask_opcode)
    `CHK(io_toSourceD_bits_task_aMergeTask_param)
    `CHK(io_toSourceD_bits_task_aMergeTask_sourceId)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_dirty)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_state)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_clients)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_alias)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_prefetch)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_accessed)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_tagErr)
    `CHK(io_toSourceD_bits_task_aMergeTask_meta_dataErr)
    `CHK(io_toSourceD_bits_task_snpHitRelease)
    `CHK(io_toSourceD_bits_task_snpHitReleaseToInval)
    `CHK(io_toSourceD_bits_task_snpHitReleaseToClean)
    `CHK(io_toSourceD_bits_task_snpHitReleaseWithData)
    `CHK(io_toSourceD_bits_task_snpHitReleaseIdx)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_dirty)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_state)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_clients)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_alias)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_prefetch)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_accessed)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_tagErr)
    `CHK(io_toSourceD_bits_task_snpHitReleaseMeta_dataErr)
    `CHK(io_toSourceD_bits_task_tgtID)
    `CHK(io_toSourceD_bits_task_srcID)
    `CHK(io_toSourceD_bits_task_txnID)
    `CHK(io_toSourceD_bits_task_homeNID)
    `CHK(io_toSourceD_bits_task_dbID)
    `CHK(io_toSourceD_bits_task_fwdNID)
    `CHK(io_toSourceD_bits_task_fwdTxnID)
    `CHK(io_toSourceD_bits_task_chiOpcode)
    `CHK(io_toSourceD_bits_task_resp)
    `CHK(io_toSourceD_bits_task_fwdState)
    `CHK(io_toSourceD_bits_task_pCrdType)
    `CHK(io_toSourceD_bits_task_retToSrc)
    `CHK(io_toSourceD_bits_task_likelyshared)
    `CHK(io_toSourceD_bits_task_expCompAck)
    `CHK(io_toSourceD_bits_task_allowRetry)
    `CHK(io_toSourceD_bits_task_memAttr_allocate)
    `CHK(io_toSourceD_bits_task_memAttr_cacheable)
    `CHK(io_toSourceD_bits_task_memAttr_device)
    `CHK(io_toSourceD_bits_task_memAttr_ewa)
    `CHK(io_toSourceD_bits_task_traceTag)
    `CHK(io_toSourceD_bits_task_dataCheckErr)
    `CHK(io_toSourceD_bits_data_data)
    `CHK(io_toTXREQ_valid)
    `CHK(io_toTXREQ_bits_tgtID)
    `CHK(io_toTXREQ_bits_srcID)
    `CHK(io_toTXREQ_bits_txnID)
    `CHK(io_toTXREQ_bits_opcode)
    `CHK(io_toTXREQ_bits_addr)
    `CHK(io_toTXREQ_bits_likelyshared)
    `CHK(io_toTXREQ_bits_allowRetry)
    `CHK(io_toTXREQ_bits_pCrdType)
    `CHK(io_toTXREQ_bits_memAttr_allocate)
    `CHK(io_toTXREQ_bits_memAttr_cacheable)
    `CHK(io_toTXREQ_bits_memAttr_device)
    `CHK(io_toTXREQ_bits_memAttr_ewa)
    `CHK(io_toTXREQ_bits_expCompAck)
    `CHK(io_toTXRSP_valid)
    `CHK(io_toTXRSP_bits_txChannel)
    `CHK(io_toTXRSP_bits_denied)
    `CHK(io_toTXRSP_bits_tgtID)
    `CHK(io_toTXRSP_bits_srcID)
    `CHK(io_toTXRSP_bits_txnID)
    `CHK(io_toTXRSP_bits_dbID)
    `CHK(io_toTXRSP_bits_chiOpcode)
    `CHK(io_toTXRSP_bits_resp)
    `CHK(io_toTXRSP_bits_fwdState)
    `CHK(io_toTXRSP_bits_pCrdType)
    `CHK(io_toTXRSP_bits_traceTag)
    `CHK(io_toTXDAT_valid)
    `CHK(io_toTXDAT_bits_task_channel)
    `CHK(io_toTXDAT_bits_task_txChannel)
    `CHK(io_toTXDAT_bits_task_set)
    `CHK(io_toTXDAT_bits_task_tag)
    `CHK(io_toTXDAT_bits_task_off)
    `CHK(io_toTXDAT_bits_task_alias)
    `CHK(io_toTXDAT_bits_task_vaddr)
    `CHK(io_toTXDAT_bits_task_isKeyword)
    `CHK(io_toTXDAT_bits_task_opcode)
    `CHK(io_toTXDAT_bits_task_param)
    `CHK(io_toTXDAT_bits_task_size)
    `CHK(io_toTXDAT_bits_task_sourceId)
    `CHK(io_toTXDAT_bits_task_bufIdx)
    `CHK(io_toTXDAT_bits_task_needProbeAckData)
    `CHK(io_toTXDAT_bits_task_denied)
    `CHK(io_toTXDAT_bits_task_corrupt)
    `CHK(io_toTXDAT_bits_task_mshrTask)
    `CHK(io_toTXDAT_bits_task_mshrId)
    `CHK(io_toTXDAT_bits_task_aliasTask)
    `CHK(io_toTXDAT_bits_task_useProbeData)
    `CHK(io_toTXDAT_bits_task_mshrRetry)
    `CHK(io_toTXDAT_bits_task_readProbeDataDown)
    `CHK(io_toTXDAT_bits_task_fromL2pft)
    `CHK(io_toTXDAT_bits_task_needHint)
    `CHK(io_toTXDAT_bits_task_dirty)
    `CHK(io_toTXDAT_bits_task_way)
    `CHK(io_toTXDAT_bits_task_meta_dirty)
    `CHK(io_toTXDAT_bits_task_meta_state)
    `CHK(io_toTXDAT_bits_task_meta_clients)
    `CHK(io_toTXDAT_bits_task_meta_alias)
    `CHK(io_toTXDAT_bits_task_meta_prefetch)
    `CHK(io_toTXDAT_bits_task_meta_prefetchSrc)
    `CHK(io_toTXDAT_bits_task_meta_accessed)
    `CHK(io_toTXDAT_bits_task_meta_tagErr)
    `CHK(io_toTXDAT_bits_task_meta_dataErr)
    `CHK(io_toTXDAT_bits_task_metaWen)
    `CHK(io_toTXDAT_bits_task_tagWen)
    `CHK(io_toTXDAT_bits_task_dsWen)
    `CHK(io_toTXDAT_bits_task_wayMask)
    `CHK(io_toTXDAT_bits_task_replTask)
    `CHK(io_toTXDAT_bits_task_cmoTask)
    `CHK(io_toTXDAT_bits_task_cmoAll)
    `CHK(io_toTXDAT_bits_task_reqSource)
    `CHK(io_toTXDAT_bits_task_mergeA)
    `CHK(io_toTXDAT_bits_task_aMergeTask_off)
    `CHK(io_toTXDAT_bits_task_aMergeTask_alias)
    `CHK(io_toTXDAT_bits_task_aMergeTask_vaddr)
    `CHK(io_toTXDAT_bits_task_aMergeTask_isKeyword)
    `CHK(io_toTXDAT_bits_task_aMergeTask_opcode)
    `CHK(io_toTXDAT_bits_task_aMergeTask_param)
    `CHK(io_toTXDAT_bits_task_aMergeTask_sourceId)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_dirty)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_state)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_clients)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_alias)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_prefetch)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_accessed)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_tagErr)
    `CHK(io_toTXDAT_bits_task_aMergeTask_meta_dataErr)
    `CHK(io_toTXDAT_bits_task_snpHitRelease)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseToInval)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseToClean)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseWithData)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseIdx)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_dirty)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_state)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_clients)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_alias)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_accessed)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr)
    `CHK(io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr)
    `CHK(io_toTXDAT_bits_task_tgtID)
    `CHK(io_toTXDAT_bits_task_srcID)
    `CHK(io_toTXDAT_bits_task_txnID)
    `CHK(io_toTXDAT_bits_task_homeNID)
    `CHK(io_toTXDAT_bits_task_dbID)
    `CHK(io_toTXDAT_bits_task_fwdNID)
    `CHK(io_toTXDAT_bits_task_fwdTxnID)
    `CHK(io_toTXDAT_bits_task_chiOpcode)
    `CHK(io_toTXDAT_bits_task_resp)
    `CHK(io_toTXDAT_bits_task_fwdState)
    `CHK(io_toTXDAT_bits_task_pCrdType)
    `CHK(io_toTXDAT_bits_task_retToSrc)
    `CHK(io_toTXDAT_bits_task_likelyshared)
    `CHK(io_toTXDAT_bits_task_expCompAck)
    `CHK(io_toTXDAT_bits_task_allowRetry)
    `CHK(io_toTXDAT_bits_task_memAttr_allocate)
    `CHK(io_toTXDAT_bits_task_memAttr_cacheable)
    `CHK(io_toTXDAT_bits_task_memAttr_device)
    `CHK(io_toTXDAT_bits_task_memAttr_ewa)
    `CHK(io_toTXDAT_bits_task_traceTag)
    `CHK(io_toTXDAT_bits_task_dataCheckErr)
    `CHK(io_toTXDAT_bits_data_data)
    `CHK(io_metaWReq_valid)
    `CHK(io_metaWReq_bits_set)
    `CHK(io_metaWReq_bits_wayOH)
    `CHK(io_metaWReq_bits_wmeta_dirty)
    `CHK(io_metaWReq_bits_wmeta_state)
    `CHK(io_metaWReq_bits_wmeta_clients)
    `CHK(io_metaWReq_bits_wmeta_alias)
    `CHK(io_metaWReq_bits_wmeta_prefetch)
    `CHK(io_metaWReq_bits_wmeta_prefetchSrc)
    `CHK(io_metaWReq_bits_wmeta_accessed)
    `CHK(io_metaWReq_bits_wmeta_tagErr)
    `CHK(io_metaWReq_bits_wmeta_dataErr)
    `CHK(io_tagWReq_valid)
    `CHK(io_tagWReq_bits_set)
    `CHK(io_tagWReq_bits_way)
    `CHK(io_tagWReq_bits_wtag)
    `CHK(io_releaseBufWrite_valid)
    `CHK(io_releaseBufWrite_bits_id)
    `CHK(io_releaseBufWrite_bits_data_data)
    `CHK(io_nestedwb_set)
    `CHK(io_nestedwb_tag)
    `CHK(io_nestedwb_c_set_dirty)
    `CHK(io_nestedwb_c_set_tip)
    `CHK(io_nestedwb_b_inv_dirty)
    `CHK(io_nestedwb_b_toB)
    `CHK(io_nestedwb_b_toN)
    `CHK(io_nestedwb_b_toClean)
    `CHK(io_nestedwbData_data)
    `CHK(io_l1Hint_valid)
    `CHK(io_l1Hint_bits_sourceId)
    `CHK(io_l1Hint_bits_isKeyword)
    `CHK(io_prefetchTrain_valid)
    `CHK(io_prefetchTrain_bits_tag)
    `CHK(io_prefetchTrain_bits_set)
    `CHK(io_prefetchTrain_bits_needT)
    `CHK(io_prefetchTrain_bits_source)
    `CHK(io_prefetchTrain_bits_vaddr)
    `CHK(io_prefetchTrain_bits_hit)
    `CHK(io_prefetchTrain_bits_prefetched)
    `CHK(io_prefetchTrain_bits_pfsource)
    `CHK(io_prefetchTrain_bits_reqsource)
    `CHK(io_error_valid)
    `CHK(io_error_bits_valid)
    `CHK(io_error_bits_address)
    `CHK(io_perf_0_value)
    `CHK(io_perf_1_value)
    `CHK(io_perf_2_value)
    `CHK(io_perf_3_value)
    `CHK(io_perf_4_value)
    `CHK(io_perf_5_value)
    `CHK(io_perf_6_value)
    `CHK(io_perf_7_value)
  endtask

  int ierr = 0;
  `define IP(SIG) begin \
    if (!$isunknown(u_g.SIG)) begin \
      if (u_g.SIG !== u_i.u_core.SIG) begin \
        ierr++; \
        if (ierr <= 60) $display("[%0t] IPROBE-DIFF %s g=%0h i=%0h", $time, `"SIG`", u_g.SIG, u_i.u_core.SIG); \
      end \
    end \
  end
  task automatic check_internal();
    `IP(resetFinish)
    `IP(resetIdx)
    `IP(task_s3_valid)
    `IP(task_s4_valid)
    `IP(task_s5_valid)
    `IP(replResp_valid_s4)
    `IP(task_s3_valid_hold2)
    `IP(isD_s4)
    `IP(isTXREQ_s4)
    `IP(isTXRSP_s4)
    `IP(isTXDAT_s4)
    `IP(isD_s5)
    `IP(isTXREQ_s5)
    `IP(isTXRSP_s5)
    `IP(isTXDAT_s5)
    `IP(tagError_s4)
    `IP(dataError_s4)
    `IP(l2Error_s4)
    `IP(tagError_s5)
    `IP(dataMetaError_s5)
    `IP(l2TagError_s5)
    `IP(need_write_releaseBuf_s4)
    `IP(need_write_releaseBuf_s5)
    `IP(chnl_valid_s4_REG)
    `IP(chnl_valid_s5_REG)
    `IP(task_s3_bits_channel)
    `IP(task_s4_bits_channel)
    `IP(task_s5_bits_channel)
    `IP(task_s3_bits_txChannel)
    `IP(task_s4_bits_txChannel)
    `IP(task_s5_bits_txChannel)
    `IP(task_s3_bits_set)
    `IP(task_s4_bits_set)
    `IP(task_s5_bits_set)
    `IP(task_s3_bits_tag)
    `IP(task_s4_bits_tag)
    `IP(task_s5_bits_tag)
    `IP(task_s3_bits_off)
    `IP(task_s4_bits_off)
    `IP(task_s5_bits_off)
    `IP(task_s3_bits_alias)
    `IP(task_s4_bits_alias)
    `IP(task_s5_bits_alias)
    `IP(task_s3_bits_vaddr)
    `IP(task_s4_bits_vaddr)
    `IP(task_s5_bits_vaddr)
    `IP(task_s3_bits_isKeyword)
    `IP(task_s4_bits_isKeyword)
    `IP(task_s5_bits_isKeyword)
    `IP(task_s3_bits_opcode)
    `IP(task_s4_bits_opcode)
    `IP(task_s5_bits_opcode)
    `IP(task_s3_bits_param)
    `IP(task_s4_bits_param)
    `IP(task_s5_bits_param)
    `IP(task_s3_bits_size)
    `IP(task_s4_bits_size)
    `IP(task_s5_bits_size)
    `IP(task_s3_bits_sourceId)
    `IP(task_s4_bits_sourceId)
    `IP(task_s5_bits_sourceId)
    `IP(task_s3_bits_bufIdx)
    `IP(task_s4_bits_bufIdx)
    `IP(task_s5_bits_bufIdx)
    `IP(task_s3_bits_needProbeAckData)
    `IP(task_s4_bits_needProbeAckData)
    `IP(task_s5_bits_needProbeAckData)
    `IP(task_s3_bits_denied)
    `IP(task_s4_bits_denied)
    `IP(task_s5_bits_denied)
    `IP(task_s3_bits_corrupt)
    `IP(task_s4_bits_corrupt)
    `IP(task_s5_bits_corrupt)
    `IP(task_s3_bits_mshrTask)
    `IP(task_s4_bits_mshrTask)
    `IP(task_s5_bits_mshrTask)
    `IP(task_s3_bits_mshrId)
    `IP(task_s4_bits_mshrId)
    `IP(task_s5_bits_mshrId)
    `IP(task_s3_bits_aliasTask)
    `IP(task_s4_bits_aliasTask)
    `IP(task_s5_bits_aliasTask)
    `IP(task_s3_bits_useProbeData)
    `IP(task_s4_bits_useProbeData)
    `IP(task_s5_bits_useProbeData)
    `IP(task_s3_bits_mshrRetry)
    `IP(task_s4_bits_mshrRetry)
    `IP(task_s5_bits_mshrRetry)
    `IP(task_s3_bits_readProbeDataDown)
    `IP(task_s4_bits_readProbeDataDown)
    `IP(task_s5_bits_readProbeDataDown)
    `IP(task_s3_bits_fromL2pft)
    `IP(task_s4_bits_fromL2pft)
    `IP(task_s5_bits_fromL2pft)
    `IP(task_s3_bits_needHint)
    `IP(task_s4_bits_needHint)
    `IP(task_s5_bits_needHint)
    `IP(task_s3_bits_dirty)
    `IP(task_s4_bits_dirty)
    `IP(task_s5_bits_dirty)
    `IP(task_s3_bits_way)
    `IP(task_s4_bits_way)
    `IP(task_s5_bits_way)
    `IP(task_s3_bits_meta_dirty)
    `IP(task_s4_bits_meta_dirty)
    `IP(task_s5_bits_meta_dirty)
    `IP(task_s3_bits_meta_state)
    `IP(task_s4_bits_meta_state)
    `IP(task_s5_bits_meta_state)
    `IP(task_s3_bits_meta_clients)
    `IP(task_s4_bits_meta_clients)
    `IP(task_s5_bits_meta_clients)
    `IP(task_s3_bits_meta_alias)
    `IP(task_s4_bits_meta_alias)
    `IP(task_s5_bits_meta_alias)
    `IP(task_s3_bits_meta_prefetch)
    `IP(task_s4_bits_meta_prefetch)
    `IP(task_s5_bits_meta_prefetch)
    `IP(task_s3_bits_meta_prefetchSrc)
    `IP(task_s4_bits_meta_prefetchSrc)
    `IP(task_s5_bits_meta_prefetchSrc)
    `IP(task_s3_bits_meta_accessed)
    `IP(task_s4_bits_meta_accessed)
    `IP(task_s5_bits_meta_accessed)
    `IP(task_s3_bits_meta_tagErr)
    `IP(task_s4_bits_meta_tagErr)
    `IP(task_s5_bits_meta_tagErr)
    `IP(task_s3_bits_meta_dataErr)
    `IP(task_s4_bits_meta_dataErr)
    `IP(task_s5_bits_meta_dataErr)
    `IP(task_s3_bits_metaWen)
    `IP(task_s4_bits_metaWen)
    `IP(task_s5_bits_metaWen)
    `IP(task_s3_bits_tagWen)
    `IP(task_s4_bits_tagWen)
    `IP(task_s5_bits_tagWen)
    `IP(task_s3_bits_dsWen)
    `IP(task_s4_bits_dsWen)
    `IP(task_s5_bits_dsWen)
    `IP(task_s3_bits_wayMask)
    `IP(task_s4_bits_wayMask)
    `IP(task_s5_bits_wayMask)
    `IP(task_s3_bits_replTask)
    `IP(task_s4_bits_replTask)
    `IP(task_s5_bits_replTask)
    `IP(task_s3_bits_cmoTask)
    `IP(task_s4_bits_cmoTask)
    `IP(task_s5_bits_cmoTask)
    `IP(task_s3_bits_cmoAll)
    `IP(task_s4_bits_cmoAll)
    `IP(task_s5_bits_cmoAll)
    `IP(task_s3_bits_reqSource)
    `IP(task_s4_bits_reqSource)
    `IP(task_s5_bits_reqSource)
    `IP(task_s3_bits_mergeA)
    `IP(task_s4_bits_mergeA)
    `IP(task_s5_bits_mergeA)
    `IP(task_s3_bits_aMergeTask_off)
    `IP(task_s4_bits_aMergeTask_off)
    `IP(task_s5_bits_aMergeTask_off)
    `IP(task_s3_bits_aMergeTask_alias)
    `IP(task_s4_bits_aMergeTask_alias)
    `IP(task_s5_bits_aMergeTask_alias)
    `IP(task_s3_bits_aMergeTask_vaddr)
    `IP(task_s4_bits_aMergeTask_vaddr)
    `IP(task_s5_bits_aMergeTask_vaddr)
    `IP(task_s3_bits_aMergeTask_isKeyword)
    `IP(task_s4_bits_aMergeTask_isKeyword)
    `IP(task_s5_bits_aMergeTask_isKeyword)
    `IP(task_s3_bits_aMergeTask_opcode)
    `IP(task_s4_bits_aMergeTask_opcode)
    `IP(task_s5_bits_aMergeTask_opcode)
    `IP(task_s3_bits_aMergeTask_param)
    `IP(task_s4_bits_aMergeTask_param)
    `IP(task_s5_bits_aMergeTask_param)
    `IP(task_s3_bits_aMergeTask_sourceId)
    `IP(task_s4_bits_aMergeTask_sourceId)
    `IP(task_s5_bits_aMergeTask_sourceId)
    `IP(task_s3_bits_aMergeTask_meta_dirty)
    `IP(task_s4_bits_aMergeTask_meta_dirty)
    `IP(task_s5_bits_aMergeTask_meta_dirty)
    `IP(task_s3_bits_aMergeTask_meta_state)
    `IP(task_s4_bits_aMergeTask_meta_state)
    `IP(task_s5_bits_aMergeTask_meta_state)
    `IP(task_s3_bits_aMergeTask_meta_clients)
    `IP(task_s4_bits_aMergeTask_meta_clients)
    `IP(task_s5_bits_aMergeTask_meta_clients)
    `IP(task_s3_bits_aMergeTask_meta_alias)
    `IP(task_s4_bits_aMergeTask_meta_alias)
    `IP(task_s5_bits_aMergeTask_meta_alias)
    `IP(task_s3_bits_aMergeTask_meta_prefetch)
    `IP(task_s4_bits_aMergeTask_meta_prefetch)
    `IP(task_s5_bits_aMergeTask_meta_prefetch)
    `IP(task_s3_bits_aMergeTask_meta_prefetchSrc)
    `IP(task_s4_bits_aMergeTask_meta_prefetchSrc)
    `IP(task_s5_bits_aMergeTask_meta_prefetchSrc)
    `IP(task_s3_bits_aMergeTask_meta_accessed)
    `IP(task_s4_bits_aMergeTask_meta_accessed)
    `IP(task_s5_bits_aMergeTask_meta_accessed)
    `IP(task_s3_bits_aMergeTask_meta_tagErr)
    `IP(task_s4_bits_aMergeTask_meta_tagErr)
    `IP(task_s5_bits_aMergeTask_meta_tagErr)
    `IP(task_s3_bits_aMergeTask_meta_dataErr)
    `IP(task_s4_bits_aMergeTask_meta_dataErr)
    `IP(task_s5_bits_aMergeTask_meta_dataErr)
    `IP(task_s3_bits_snpHitRelease)
    `IP(task_s4_bits_snpHitRelease)
    `IP(task_s5_bits_snpHitRelease)
    `IP(task_s3_bits_snpHitReleaseToInval)
    `IP(task_s4_bits_snpHitReleaseToInval)
    `IP(task_s5_bits_snpHitReleaseToInval)
    `IP(task_s3_bits_snpHitReleaseToClean)
    `IP(task_s4_bits_snpHitReleaseToClean)
    `IP(task_s5_bits_snpHitReleaseToClean)
    `IP(task_s3_bits_snpHitReleaseWithData)
    `IP(task_s4_bits_snpHitReleaseWithData)
    `IP(task_s5_bits_snpHitReleaseWithData)
    `IP(task_s3_bits_snpHitReleaseIdx)
    `IP(task_s4_bits_snpHitReleaseIdx)
    `IP(task_s5_bits_snpHitReleaseIdx)
    `IP(task_s3_bits_snpHitReleaseMeta_dirty)
    `IP(task_s4_bits_snpHitReleaseMeta_dirty)
    `IP(task_s5_bits_snpHitReleaseMeta_dirty)
    `IP(task_s3_bits_snpHitReleaseMeta_state)
    `IP(task_s4_bits_snpHitReleaseMeta_state)
    `IP(task_s5_bits_snpHitReleaseMeta_state)
    `IP(task_s3_bits_snpHitReleaseMeta_clients)
    `IP(task_s4_bits_snpHitReleaseMeta_clients)
    `IP(task_s5_bits_snpHitReleaseMeta_clients)
    `IP(task_s3_bits_snpHitReleaseMeta_alias)
    `IP(task_s4_bits_snpHitReleaseMeta_alias)
    `IP(task_s5_bits_snpHitReleaseMeta_alias)
    `IP(task_s3_bits_snpHitReleaseMeta_prefetch)
    `IP(task_s4_bits_snpHitReleaseMeta_prefetch)
    `IP(task_s5_bits_snpHitReleaseMeta_prefetch)
    `IP(task_s3_bits_snpHitReleaseMeta_prefetchSrc)
    `IP(task_s4_bits_snpHitReleaseMeta_prefetchSrc)
    `IP(task_s5_bits_snpHitReleaseMeta_prefetchSrc)
    `IP(task_s3_bits_snpHitReleaseMeta_accessed)
    `IP(task_s4_bits_snpHitReleaseMeta_accessed)
    `IP(task_s5_bits_snpHitReleaseMeta_accessed)
    `IP(task_s3_bits_snpHitReleaseMeta_tagErr)
    `IP(task_s4_bits_snpHitReleaseMeta_tagErr)
    `IP(task_s5_bits_snpHitReleaseMeta_tagErr)
    `IP(task_s3_bits_snpHitReleaseMeta_dataErr)
    `IP(task_s4_bits_snpHitReleaseMeta_dataErr)
    `IP(task_s5_bits_snpHitReleaseMeta_dataErr)
    `IP(task_s3_bits_tgtID)
    `IP(task_s4_bits_tgtID)
    `IP(task_s5_bits_tgtID)
    `IP(task_s3_bits_srcID)
    `IP(task_s4_bits_srcID)
    `IP(task_s5_bits_srcID)
    `IP(task_s3_bits_txnID)
    `IP(task_s4_bits_txnID)
    `IP(task_s5_bits_txnID)
    `IP(task_s3_bits_homeNID)
    `IP(task_s4_bits_homeNID)
    `IP(task_s5_bits_homeNID)
    `IP(task_s3_bits_dbID)
    `IP(task_s4_bits_dbID)
    `IP(task_s5_bits_dbID)
    `IP(task_s3_bits_fwdNID)
    `IP(task_s4_bits_fwdNID)
    `IP(task_s5_bits_fwdNID)
    `IP(task_s3_bits_fwdTxnID)
    `IP(task_s4_bits_fwdTxnID)
    `IP(task_s5_bits_fwdTxnID)
    `IP(task_s3_bits_chiOpcode)
    `IP(task_s4_bits_chiOpcode)
    `IP(task_s5_bits_chiOpcode)
    `IP(task_s3_bits_resp)
    `IP(task_s4_bits_resp)
    `IP(task_s5_bits_resp)
    `IP(task_s3_bits_fwdState)
    `IP(task_s4_bits_fwdState)
    `IP(task_s5_bits_fwdState)
    `IP(task_s3_bits_pCrdType)
    `IP(task_s4_bits_pCrdType)
    `IP(task_s5_bits_pCrdType)
    `IP(task_s3_bits_retToSrc)
    `IP(task_s4_bits_retToSrc)
    `IP(task_s5_bits_retToSrc)
    `IP(task_s3_bits_likelyshared)
    `IP(task_s4_bits_likelyshared)
    `IP(task_s5_bits_likelyshared)
    `IP(task_s3_bits_expCompAck)
    `IP(task_s4_bits_expCompAck)
    `IP(task_s5_bits_expCompAck)
    `IP(task_s3_bits_allowRetry)
    `IP(task_s4_bits_allowRetry)
    `IP(task_s5_bits_allowRetry)
    `IP(task_s3_bits_memAttr_allocate)
    `IP(task_s4_bits_memAttr_allocate)
    `IP(task_s5_bits_memAttr_allocate)
    `IP(task_s3_bits_memAttr_cacheable)
    `IP(task_s4_bits_memAttr_cacheable)
    `IP(task_s5_bits_memAttr_cacheable)
    `IP(task_s3_bits_memAttr_device)
    `IP(task_s4_bits_memAttr_device)
    `IP(task_s5_bits_memAttr_device)
    `IP(task_s3_bits_memAttr_ewa)
    `IP(task_s4_bits_memAttr_ewa)
    `IP(task_s5_bits_memAttr_ewa)
    `IP(task_s3_bits_traceTag)
    `IP(task_s4_bits_traceTag)
    `IP(task_s5_bits_traceTag)
    `IP(task_s3_bits_dataCheckErr)
    `IP(task_s4_bits_dataCheckErr)
    `IP(task_s5_bits_dataCheckErr)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_taskFromArb_s2_valid = '0;
    io_taskFromArb_s2_bits_channel = '0;
    io_taskFromArb_s2_bits_txChannel = '0;
    io_taskFromArb_s2_bits_set = '0;
    io_taskFromArb_s2_bits_tag = '0;
    io_taskFromArb_s2_bits_off = '0;
    io_taskFromArb_s2_bits_alias = '0;
    io_taskFromArb_s2_bits_vaddr = '0;
    io_taskFromArb_s2_bits_isKeyword = '0;
    io_taskFromArb_s2_bits_opcode = '0;
    io_taskFromArb_s2_bits_param = '0;
    io_taskFromArb_s2_bits_size = '0;
    io_taskFromArb_s2_bits_sourceId = '0;
    io_taskFromArb_s2_bits_bufIdx = '0;
    io_taskFromArb_s2_bits_needProbeAckData = '0;
    io_taskFromArb_s2_bits_denied = '0;
    io_taskFromArb_s2_bits_corrupt = '0;
    io_taskFromArb_s2_bits_mshrTask = '0;
    io_taskFromArb_s2_bits_mshrId = '0;
    io_taskFromArb_s2_bits_aliasTask = '0;
    io_taskFromArb_s2_bits_useProbeData = '0;
    io_taskFromArb_s2_bits_mshrRetry = '0;
    io_taskFromArb_s2_bits_readProbeDataDown = '0;
    io_taskFromArb_s2_bits_fromL2pft = '0;
    io_taskFromArb_s2_bits_needHint = '0;
    io_taskFromArb_s2_bits_dirty = '0;
    io_taskFromArb_s2_bits_way = '0;
    io_taskFromArb_s2_bits_meta_dirty = '0;
    io_taskFromArb_s2_bits_meta_state = '0;
    io_taskFromArb_s2_bits_meta_clients = '0;
    io_taskFromArb_s2_bits_meta_alias = '0;
    io_taskFromArb_s2_bits_meta_prefetch = '0;
    io_taskFromArb_s2_bits_meta_prefetchSrc = '0;
    io_taskFromArb_s2_bits_meta_accessed = '0;
    io_taskFromArb_s2_bits_meta_tagErr = '0;
    io_taskFromArb_s2_bits_meta_dataErr = '0;
    io_taskFromArb_s2_bits_metaWen = '0;
    io_taskFromArb_s2_bits_tagWen = '0;
    io_taskFromArb_s2_bits_dsWen = '0;
    io_taskFromArb_s2_bits_wayMask = '0;
    io_taskFromArb_s2_bits_replTask = '0;
    io_taskFromArb_s2_bits_cmoTask = '0;
    io_taskFromArb_s2_bits_cmoAll = '0;
    io_taskFromArb_s2_bits_reqSource = '0;
    io_taskFromArb_s2_bits_mergeA = '0;
    io_taskFromArb_s2_bits_aMergeTask_off = '0;
    io_taskFromArb_s2_bits_aMergeTask_alias = '0;
    io_taskFromArb_s2_bits_aMergeTask_vaddr = '0;
    io_taskFromArb_s2_bits_aMergeTask_isKeyword = '0;
    io_taskFromArb_s2_bits_aMergeTask_opcode = '0;
    io_taskFromArb_s2_bits_aMergeTask_param = '0;
    io_taskFromArb_s2_bits_aMergeTask_sourceId = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_dirty = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_state = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_clients = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_alias = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_prefetch = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_accessed = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_tagErr = '0;
    io_taskFromArb_s2_bits_aMergeTask_meta_dataErr = '0;
    io_taskFromArb_s2_bits_snpHitRelease = '0;
    io_taskFromArb_s2_bits_snpHitReleaseToInval = '0;
    io_taskFromArb_s2_bits_snpHitReleaseToClean = '0;
    io_taskFromArb_s2_bits_snpHitReleaseWithData = '0;
    io_taskFromArb_s2_bits_snpHitReleaseIdx = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_state = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_clients = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_alias = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr = '0;
    io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr = '0;
    io_taskFromArb_s2_bits_tgtID = '0;
    io_taskFromArb_s2_bits_srcID = '0;
    io_taskFromArb_s2_bits_txnID = '0;
    io_taskFromArb_s2_bits_homeNID = '0;
    io_taskFromArb_s2_bits_dbID = '0;
    io_taskFromArb_s2_bits_fwdNID = '0;
    io_taskFromArb_s2_bits_fwdTxnID = '0;
    io_taskFromArb_s2_bits_chiOpcode = '0;
    io_taskFromArb_s2_bits_resp = '0;
    io_taskFromArb_s2_bits_fwdState = '0;
    io_taskFromArb_s2_bits_pCrdType = '0;
    io_taskFromArb_s2_bits_retToSrc = '0;
    io_taskFromArb_s2_bits_likelyshared = '0;
    io_taskFromArb_s2_bits_expCompAck = '0;
    io_taskFromArb_s2_bits_allowRetry = '0;
    io_taskFromArb_s2_bits_memAttr_allocate = '0;
    io_taskFromArb_s2_bits_memAttr_cacheable = '0;
    io_taskFromArb_s2_bits_memAttr_device = '0;
    io_taskFromArb_s2_bits_memAttr_ewa = '0;
    io_taskFromArb_s2_bits_traceTag = '0;
    io_taskFromArb_s2_bits_dataCheckErr = '0;
    io_taskInfo_s1_valid = '0;
    io_taskInfo_s1_bits_channel = '0;
    io_taskInfo_s1_bits_isKeyword = '0;
    io_taskInfo_s1_bits_opcode = '0;
    io_taskInfo_s1_bits_sourceId = '0;
    io_taskInfo_s1_bits_mshrTask = '0;
    io_taskInfo_s1_bits_mergeA = '0;
    io_taskInfo_s1_bits_aMergeTask_isKeyword = '0;
    io_taskInfo_s1_bits_aMergeTask_opcode = '0;
    io_taskInfo_s1_bits_aMergeTask_sourceId = '0;
    io_fromReqArb_status_s1_tags_1 = '0;
    io_fromReqArb_status_s1_sets_0 = '0;
    io_fromReqArb_status_s1_sets_1 = '0;
    io_fromReqArb_status_s1_sets_2 = '0;
    io_fromReqArb_status_s1_sets_3 = '0;
    io_dirResp_s3_hit = '0;
    io_dirResp_s3_tag = '0;
    io_dirResp_s3_set = '0;
    io_dirResp_s3_way = '0;
    io_dirResp_s3_meta_dirty = '0;
    io_dirResp_s3_meta_state = '0;
    io_dirResp_s3_meta_clients = '0;
    io_dirResp_s3_meta_alias = '0;
    io_dirResp_s3_meta_prefetch = '0;
    io_dirResp_s3_meta_prefetchSrc = '0;
    io_dirResp_s3_meta_accessed = '0;
    io_dirResp_s3_meta_tagErr = '0;
    io_dirResp_s3_meta_dataErr = '0;
    io_dirResp_s3_error = '0;
    io_replResp_valid = '0;
    io_replResp_bits_way = '0;
    io_replResp_bits_meta_state = '0;
    io_replResp_bits_retry = '0;
    io_fromMSHRCtl_mshr_alloc_ptr = '0;
    io_bufResp_data_0 = '0;
    io_bufResp_data_1 = '0;
    io_refillBufResp_s3_bits_data = '0;
    io_releaseBufResp_s3_valid = '0;
    io_releaseBufResp_s3_bits_data = '0;
    io_toDS_rdata_s5_data = '0;
    io_toDS_error_s5 = '0;
    io_toTXDAT_ready = '0;
    io_l1Hint_ready = '0;
    io_prefetchTrain_ready = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("MainPipe checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
`undef IP
