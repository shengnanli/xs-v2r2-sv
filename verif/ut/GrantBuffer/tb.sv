// 自动生成 scripts/gen_grantbuffer.py —— 勿手改
// GrantBuffer 双例化逐拍比对: golden GrantBuffer vs 可读重写 GrantBuffer_xs。
// 偏置 opcode∈{Grant=4,GrantData=5,Hint=2}, 小 set/tag/sink, 覆盖 inflight 冲突/反压/出队两拍。
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
  logic io_d_task_valid;
  logic [2:0] io_d_task_bits_task_channel;
  logic [2:0] io_d_task_bits_task_txChannel;
  logic [8:0] io_d_task_bits_task_set;
  logic [30:0] io_d_task_bits_task_tag;
  logic [5:0] io_d_task_bits_task_off;
  logic [1:0] io_d_task_bits_task_alias;
  logic [43:0] io_d_task_bits_task_vaddr;
  logic io_d_task_bits_task_isKeyword;
  logic [3:0] io_d_task_bits_task_opcode;
  logic [2:0] io_d_task_bits_task_param;
  logic [2:0] io_d_task_bits_task_size;
  logic [6:0] io_d_task_bits_task_sourceId;
  logic [1:0] io_d_task_bits_task_bufIdx;
  logic io_d_task_bits_task_needProbeAckData;
  logic io_d_task_bits_task_denied;
  logic io_d_task_bits_task_corrupt;
  logic io_d_task_bits_task_mshrTask;
  logic [7:0] io_d_task_bits_task_mshrId;
  logic io_d_task_bits_task_aliasTask;
  logic io_d_task_bits_task_useProbeData;
  logic io_d_task_bits_task_mshrRetry;
  logic io_d_task_bits_task_readProbeDataDown;
  logic io_d_task_bits_task_fromL2pft;
  logic io_d_task_bits_task_needHint;
  logic io_d_task_bits_task_dirty;
  logic [2:0] io_d_task_bits_task_way;
  logic io_d_task_bits_task_meta_dirty;
  logic [1:0] io_d_task_bits_task_meta_state;
  logic io_d_task_bits_task_meta_clients;
  logic [1:0] io_d_task_bits_task_meta_alias;
  logic io_d_task_bits_task_meta_prefetch;
  logic [2:0] io_d_task_bits_task_meta_prefetchSrc;
  logic io_d_task_bits_task_meta_accessed;
  logic io_d_task_bits_task_meta_tagErr;
  logic io_d_task_bits_task_meta_dataErr;
  logic io_d_task_bits_task_metaWen;
  logic io_d_task_bits_task_tagWen;
  logic io_d_task_bits_task_dsWen;
  logic [7:0] io_d_task_bits_task_wayMask;
  logic io_d_task_bits_task_replTask;
  logic io_d_task_bits_task_cmoTask;
  logic io_d_task_bits_task_cmoAll;
  logic [4:0] io_d_task_bits_task_reqSource;
  logic io_d_task_bits_task_mergeA;
  logic [5:0] io_d_task_bits_task_aMergeTask_off;
  logic [1:0] io_d_task_bits_task_aMergeTask_alias;
  logic [43:0] io_d_task_bits_task_aMergeTask_vaddr;
  logic io_d_task_bits_task_aMergeTask_isKeyword;
  logic [2:0] io_d_task_bits_task_aMergeTask_opcode;
  logic [2:0] io_d_task_bits_task_aMergeTask_param;
  logic [6:0] io_d_task_bits_task_aMergeTask_sourceId;
  logic io_d_task_bits_task_aMergeTask_meta_dirty;
  logic [1:0] io_d_task_bits_task_aMergeTask_meta_state;
  logic io_d_task_bits_task_aMergeTask_meta_clients;
  logic [1:0] io_d_task_bits_task_aMergeTask_meta_alias;
  logic io_d_task_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] io_d_task_bits_task_aMergeTask_meta_prefetchSrc;
  logic io_d_task_bits_task_aMergeTask_meta_accessed;
  logic io_d_task_bits_task_aMergeTask_meta_tagErr;
  logic io_d_task_bits_task_aMergeTask_meta_dataErr;
  logic io_d_task_bits_task_snpHitRelease;
  logic io_d_task_bits_task_snpHitReleaseToInval;
  logic io_d_task_bits_task_snpHitReleaseToClean;
  logic io_d_task_bits_task_snpHitReleaseWithData;
  logic [7:0] io_d_task_bits_task_snpHitReleaseIdx;
  logic io_d_task_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] io_d_task_bits_task_snpHitReleaseMeta_state;
  logic io_d_task_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] io_d_task_bits_task_snpHitReleaseMeta_alias;
  logic io_d_task_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic io_d_task_bits_task_snpHitReleaseMeta_accessed;
  logic io_d_task_bits_task_snpHitReleaseMeta_tagErr;
  logic io_d_task_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] io_d_task_bits_task_tgtID;
  logic [10:0] io_d_task_bits_task_srcID;
  logic [11:0] io_d_task_bits_task_txnID;
  logic [10:0] io_d_task_bits_task_homeNID;
  logic [11:0] io_d_task_bits_task_dbID;
  logic [10:0] io_d_task_bits_task_fwdNID;
  logic [11:0] io_d_task_bits_task_fwdTxnID;
  logic [6:0] io_d_task_bits_task_chiOpcode;
  logic [2:0] io_d_task_bits_task_resp;
  logic [2:0] io_d_task_bits_task_fwdState;
  logic [3:0] io_d_task_bits_task_pCrdType;
  logic io_d_task_bits_task_retToSrc;
  logic io_d_task_bits_task_likelyshared;
  logic io_d_task_bits_task_expCompAck;
  logic io_d_task_bits_task_allowRetry;
  logic io_d_task_bits_task_memAttr_allocate;
  logic io_d_task_bits_task_memAttr_cacheable;
  logic io_d_task_bits_task_memAttr_device;
  logic io_d_task_bits_task_memAttr_ewa;
  logic io_d_task_bits_task_traceTag;
  logic io_d_task_bits_task_dataCheckErr;
  logic [511:0] io_d_task_bits_data_data;
  logic io_d_ready;
  logic io_e_valid;
  logic [7:0] io_e_bits_sink;
  logic [30:0] io_fromReqArb_status_s1_tags_1;
  logic [8:0] io_fromReqArb_status_s1_sets_1;
  logic io_pipeStatusVec_1_valid;
  logic [2:0] io_pipeStatusVec_1_bits_channel;
  logic io_pipeStatusVec_2_valid;
  logic [2:0] io_pipeStatusVec_2_bits_channel;
  logic io_pipeStatusVec_3_valid;
  logic [2:0] io_pipeStatusVec_3_bits_channel;
  logic io_pipeStatusVec_4_valid;
  logic [2:0] io_pipeStatusVec_4_bits_channel;
  logic io_prefetchResp_ready;
  wire g_io_d_valid;
  wire i_io_d_valid;
  wire [3:0] g_io_d_bits_opcode;
  wire [3:0] i_io_d_bits_opcode;
  wire [1:0] g_io_d_bits_param;
  wire [1:0] i_io_d_bits_param;
  wire [6:0] g_io_d_bits_source;
  wire [6:0] i_io_d_bits_source;
  wire [7:0] g_io_d_bits_sink;
  wire [7:0] i_io_d_bits_sink;
  wire g_io_d_bits_denied;
  wire i_io_d_bits_denied;
  wire g_io_d_bits_echo_isKeyword;
  wire i_io_d_bits_echo_isKeyword;
  wire [255:0] g_io_d_bits_data;
  wire [255:0] i_io_d_bits_data;
  wire g_io_d_bits_corrupt;
  wire i_io_d_bits_corrupt;
  wire g_io_toReqArb_blockSinkReqEntrance_blockA_s1;
  wire i_io_toReqArb_blockSinkReqEntrance_blockA_s1;
  wire g_io_toReqArb_blockSinkReqEntrance_blockB_s1;
  wire i_io_toReqArb_blockSinkReqEntrance_blockB_s1;
  wire g_io_toReqArb_blockSinkReqEntrance_blockC_s1;
  wire i_io_toReqArb_blockSinkReqEntrance_blockC_s1;
  wire g_io_toReqArb_blockMSHRReqEntrance;
  wire i_io_toReqArb_blockMSHRReqEntrance;
  wire g_io_prefetchResp_valid;
  wire i_io_prefetchResp_valid;
  wire [32:0] g_io_prefetchResp_bits_tag;
  wire [32:0] i_io_prefetchResp_bits_tag;
  wire [8:0] g_io_prefetchResp_bits_set;
  wire [8:0] i_io_prefetchResp_bits_set;
  wire [43:0] g_io_prefetchResp_bits_vaddr;
  wire [43:0] i_io_prefetchResp_bits_vaddr;
  wire [4:0] g_io_prefetchResp_bits_pfSource;
  wire [4:0] i_io_prefetchResp_bits_pfSource;
  wire g_io_grantStatus_0_valid;
  wire i_io_grantStatus_0_valid;
  wire [8:0] g_io_grantStatus_0_set;
  wire [8:0] i_io_grantStatus_0_set;
  wire [30:0] g_io_grantStatus_0_tag;
  wire [30:0] i_io_grantStatus_0_tag;
  wire g_io_grantStatus_1_valid;
  wire i_io_grantStatus_1_valid;
  wire [8:0] g_io_grantStatus_1_set;
  wire [8:0] i_io_grantStatus_1_set;
  wire [30:0] g_io_grantStatus_1_tag;
  wire [30:0] i_io_grantStatus_1_tag;
  wire g_io_grantStatus_2_valid;
  wire i_io_grantStatus_2_valid;
  wire [8:0] g_io_grantStatus_2_set;
  wire [8:0] i_io_grantStatus_2_set;
  wire [30:0] g_io_grantStatus_2_tag;
  wire [30:0] i_io_grantStatus_2_tag;
  wire g_io_grantStatus_3_valid;
  wire i_io_grantStatus_3_valid;
  wire [8:0] g_io_grantStatus_3_set;
  wire [8:0] i_io_grantStatus_3_set;
  wire [30:0] g_io_grantStatus_3_tag;
  wire [30:0] i_io_grantStatus_3_tag;
  wire g_io_grantStatus_4_valid;
  wire i_io_grantStatus_4_valid;
  wire [8:0] g_io_grantStatus_4_set;
  wire [8:0] i_io_grantStatus_4_set;
  wire [30:0] g_io_grantStatus_4_tag;
  wire [30:0] i_io_grantStatus_4_tag;
  wire g_io_grantStatus_5_valid;
  wire i_io_grantStatus_5_valid;
  wire [8:0] g_io_grantStatus_5_set;
  wire [8:0] i_io_grantStatus_5_set;
  wire [30:0] g_io_grantStatus_5_tag;
  wire [30:0] i_io_grantStatus_5_tag;
  wire g_io_grantStatus_6_valid;
  wire i_io_grantStatus_6_valid;
  wire [8:0] g_io_grantStatus_6_set;
  wire [8:0] i_io_grantStatus_6_set;
  wire [30:0] g_io_grantStatus_6_tag;
  wire [30:0] i_io_grantStatus_6_tag;
  wire g_io_grantStatus_7_valid;
  wire i_io_grantStatus_7_valid;
  wire [8:0] g_io_grantStatus_7_set;
  wire [8:0] i_io_grantStatus_7_set;
  wire [30:0] g_io_grantStatus_7_tag;
  wire [30:0] i_io_grantStatus_7_tag;
  wire g_io_grantStatus_8_valid;
  wire i_io_grantStatus_8_valid;
  wire [8:0] g_io_grantStatus_8_set;
  wire [8:0] i_io_grantStatus_8_set;
  wire [30:0] g_io_grantStatus_8_tag;
  wire [30:0] i_io_grantStatus_8_tag;
  wire g_io_grantStatus_9_valid;
  wire i_io_grantStatus_9_valid;
  wire [8:0] g_io_grantStatus_9_set;
  wire [8:0] i_io_grantStatus_9_set;
  wire [30:0] g_io_grantStatus_9_tag;
  wire [30:0] i_io_grantStatus_9_tag;
  wire g_io_grantStatus_10_valid;
  wire i_io_grantStatus_10_valid;
  wire [8:0] g_io_grantStatus_10_set;
  wire [8:0] i_io_grantStatus_10_set;
  wire [30:0] g_io_grantStatus_10_tag;
  wire [30:0] i_io_grantStatus_10_tag;
  wire g_io_grantStatus_11_valid;
  wire i_io_grantStatus_11_valid;
  wire [8:0] g_io_grantStatus_11_set;
  wire [8:0] i_io_grantStatus_11_set;
  wire [30:0] g_io_grantStatus_11_tag;
  wire [30:0] i_io_grantStatus_11_tag;
  wire g_io_grantStatus_12_valid;
  wire i_io_grantStatus_12_valid;
  wire [8:0] g_io_grantStatus_12_set;
  wire [8:0] i_io_grantStatus_12_set;
  wire [30:0] g_io_grantStatus_12_tag;
  wire [30:0] i_io_grantStatus_12_tag;
  wire g_io_grantStatus_13_valid;
  wire i_io_grantStatus_13_valid;
  wire [8:0] g_io_grantStatus_13_set;
  wire [8:0] i_io_grantStatus_13_set;
  wire [30:0] g_io_grantStatus_13_tag;
  wire [30:0] i_io_grantStatus_13_tag;
  wire g_io_grantStatus_14_valid;
  wire i_io_grantStatus_14_valid;
  wire [8:0] g_io_grantStatus_14_set;
  wire [8:0] i_io_grantStatus_14_set;
  wire [30:0] g_io_grantStatus_14_tag;
  wire [30:0] i_io_grantStatus_14_tag;
  wire g_io_grantStatus_15_valid;
  wire i_io_grantStatus_15_valid;
  wire [8:0] g_io_grantStatus_15_set;
  wire [8:0] i_io_grantStatus_15_set;
  wire [30:0] g_io_grantStatus_15_tag;
  wire [30:0] i_io_grantStatus_15_tag;

  GrantBuffer u_g (
    .clock(clock),
    .reset(reset),
    .io_d_task_valid(io_d_task_valid),
    .io_d_task_bits_task_channel(io_d_task_bits_task_channel),
    .io_d_task_bits_task_txChannel(io_d_task_bits_task_txChannel),
    .io_d_task_bits_task_set(io_d_task_bits_task_set),
    .io_d_task_bits_task_tag(io_d_task_bits_task_tag),
    .io_d_task_bits_task_off(io_d_task_bits_task_off),
    .io_d_task_bits_task_alias(io_d_task_bits_task_alias),
    .io_d_task_bits_task_vaddr(io_d_task_bits_task_vaddr),
    .io_d_task_bits_task_isKeyword(io_d_task_bits_task_isKeyword),
    .io_d_task_bits_task_opcode(io_d_task_bits_task_opcode),
    .io_d_task_bits_task_param(io_d_task_bits_task_param),
    .io_d_task_bits_task_size(io_d_task_bits_task_size),
    .io_d_task_bits_task_sourceId(io_d_task_bits_task_sourceId),
    .io_d_task_bits_task_bufIdx(io_d_task_bits_task_bufIdx),
    .io_d_task_bits_task_needProbeAckData(io_d_task_bits_task_needProbeAckData),
    .io_d_task_bits_task_denied(io_d_task_bits_task_denied),
    .io_d_task_bits_task_corrupt(io_d_task_bits_task_corrupt),
    .io_d_task_bits_task_mshrTask(io_d_task_bits_task_mshrTask),
    .io_d_task_bits_task_mshrId(io_d_task_bits_task_mshrId),
    .io_d_task_bits_task_aliasTask(io_d_task_bits_task_aliasTask),
    .io_d_task_bits_task_useProbeData(io_d_task_bits_task_useProbeData),
    .io_d_task_bits_task_mshrRetry(io_d_task_bits_task_mshrRetry),
    .io_d_task_bits_task_readProbeDataDown(io_d_task_bits_task_readProbeDataDown),
    .io_d_task_bits_task_fromL2pft(io_d_task_bits_task_fromL2pft),
    .io_d_task_bits_task_needHint(io_d_task_bits_task_needHint),
    .io_d_task_bits_task_dirty(io_d_task_bits_task_dirty),
    .io_d_task_bits_task_way(io_d_task_bits_task_way),
    .io_d_task_bits_task_meta_dirty(io_d_task_bits_task_meta_dirty),
    .io_d_task_bits_task_meta_state(io_d_task_bits_task_meta_state),
    .io_d_task_bits_task_meta_clients(io_d_task_bits_task_meta_clients),
    .io_d_task_bits_task_meta_alias(io_d_task_bits_task_meta_alias),
    .io_d_task_bits_task_meta_prefetch(io_d_task_bits_task_meta_prefetch),
    .io_d_task_bits_task_meta_prefetchSrc(io_d_task_bits_task_meta_prefetchSrc),
    .io_d_task_bits_task_meta_accessed(io_d_task_bits_task_meta_accessed),
    .io_d_task_bits_task_meta_tagErr(io_d_task_bits_task_meta_tagErr),
    .io_d_task_bits_task_meta_dataErr(io_d_task_bits_task_meta_dataErr),
    .io_d_task_bits_task_metaWen(io_d_task_bits_task_metaWen),
    .io_d_task_bits_task_tagWen(io_d_task_bits_task_tagWen),
    .io_d_task_bits_task_dsWen(io_d_task_bits_task_dsWen),
    .io_d_task_bits_task_wayMask(io_d_task_bits_task_wayMask),
    .io_d_task_bits_task_replTask(io_d_task_bits_task_replTask),
    .io_d_task_bits_task_cmoTask(io_d_task_bits_task_cmoTask),
    .io_d_task_bits_task_cmoAll(io_d_task_bits_task_cmoAll),
    .io_d_task_bits_task_reqSource(io_d_task_bits_task_reqSource),
    .io_d_task_bits_task_mergeA(io_d_task_bits_task_mergeA),
    .io_d_task_bits_task_aMergeTask_off(io_d_task_bits_task_aMergeTask_off),
    .io_d_task_bits_task_aMergeTask_alias(io_d_task_bits_task_aMergeTask_alias),
    .io_d_task_bits_task_aMergeTask_vaddr(io_d_task_bits_task_aMergeTask_vaddr),
    .io_d_task_bits_task_aMergeTask_isKeyword(io_d_task_bits_task_aMergeTask_isKeyword),
    .io_d_task_bits_task_aMergeTask_opcode(io_d_task_bits_task_aMergeTask_opcode),
    .io_d_task_bits_task_aMergeTask_param(io_d_task_bits_task_aMergeTask_param),
    .io_d_task_bits_task_aMergeTask_sourceId(io_d_task_bits_task_aMergeTask_sourceId),
    .io_d_task_bits_task_aMergeTask_meta_dirty(io_d_task_bits_task_aMergeTask_meta_dirty),
    .io_d_task_bits_task_aMergeTask_meta_state(io_d_task_bits_task_aMergeTask_meta_state),
    .io_d_task_bits_task_aMergeTask_meta_clients(io_d_task_bits_task_aMergeTask_meta_clients),
    .io_d_task_bits_task_aMergeTask_meta_alias(io_d_task_bits_task_aMergeTask_meta_alias),
    .io_d_task_bits_task_aMergeTask_meta_prefetch(io_d_task_bits_task_aMergeTask_meta_prefetch),
    .io_d_task_bits_task_aMergeTask_meta_prefetchSrc(io_d_task_bits_task_aMergeTask_meta_prefetchSrc),
    .io_d_task_bits_task_aMergeTask_meta_accessed(io_d_task_bits_task_aMergeTask_meta_accessed),
    .io_d_task_bits_task_aMergeTask_meta_tagErr(io_d_task_bits_task_aMergeTask_meta_tagErr),
    .io_d_task_bits_task_aMergeTask_meta_dataErr(io_d_task_bits_task_aMergeTask_meta_dataErr),
    .io_d_task_bits_task_snpHitRelease(io_d_task_bits_task_snpHitRelease),
    .io_d_task_bits_task_snpHitReleaseToInval(io_d_task_bits_task_snpHitReleaseToInval),
    .io_d_task_bits_task_snpHitReleaseToClean(io_d_task_bits_task_snpHitReleaseToClean),
    .io_d_task_bits_task_snpHitReleaseWithData(io_d_task_bits_task_snpHitReleaseWithData),
    .io_d_task_bits_task_snpHitReleaseIdx(io_d_task_bits_task_snpHitReleaseIdx),
    .io_d_task_bits_task_snpHitReleaseMeta_dirty(io_d_task_bits_task_snpHitReleaseMeta_dirty),
    .io_d_task_bits_task_snpHitReleaseMeta_state(io_d_task_bits_task_snpHitReleaseMeta_state),
    .io_d_task_bits_task_snpHitReleaseMeta_clients(io_d_task_bits_task_snpHitReleaseMeta_clients),
    .io_d_task_bits_task_snpHitReleaseMeta_alias(io_d_task_bits_task_snpHitReleaseMeta_alias),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetch(io_d_task_bits_task_snpHitReleaseMeta_prefetch),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc(io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_d_task_bits_task_snpHitReleaseMeta_accessed(io_d_task_bits_task_snpHitReleaseMeta_accessed),
    .io_d_task_bits_task_snpHitReleaseMeta_tagErr(io_d_task_bits_task_snpHitReleaseMeta_tagErr),
    .io_d_task_bits_task_snpHitReleaseMeta_dataErr(io_d_task_bits_task_snpHitReleaseMeta_dataErr),
    .io_d_task_bits_task_tgtID(io_d_task_bits_task_tgtID),
    .io_d_task_bits_task_srcID(io_d_task_bits_task_srcID),
    .io_d_task_bits_task_txnID(io_d_task_bits_task_txnID),
    .io_d_task_bits_task_homeNID(io_d_task_bits_task_homeNID),
    .io_d_task_bits_task_dbID(io_d_task_bits_task_dbID),
    .io_d_task_bits_task_fwdNID(io_d_task_bits_task_fwdNID),
    .io_d_task_bits_task_fwdTxnID(io_d_task_bits_task_fwdTxnID),
    .io_d_task_bits_task_chiOpcode(io_d_task_bits_task_chiOpcode),
    .io_d_task_bits_task_resp(io_d_task_bits_task_resp),
    .io_d_task_bits_task_fwdState(io_d_task_bits_task_fwdState),
    .io_d_task_bits_task_pCrdType(io_d_task_bits_task_pCrdType),
    .io_d_task_bits_task_retToSrc(io_d_task_bits_task_retToSrc),
    .io_d_task_bits_task_likelyshared(io_d_task_bits_task_likelyshared),
    .io_d_task_bits_task_expCompAck(io_d_task_bits_task_expCompAck),
    .io_d_task_bits_task_allowRetry(io_d_task_bits_task_allowRetry),
    .io_d_task_bits_task_memAttr_allocate(io_d_task_bits_task_memAttr_allocate),
    .io_d_task_bits_task_memAttr_cacheable(io_d_task_bits_task_memAttr_cacheable),
    .io_d_task_bits_task_memAttr_device(io_d_task_bits_task_memAttr_device),
    .io_d_task_bits_task_memAttr_ewa(io_d_task_bits_task_memAttr_ewa),
    .io_d_task_bits_task_traceTag(io_d_task_bits_task_traceTag),
    .io_d_task_bits_task_dataCheckErr(io_d_task_bits_task_dataCheckErr),
    .io_d_task_bits_data_data(io_d_task_bits_data_data),
    .io_d_ready(io_d_ready),
    .io_d_valid(g_io_d_valid),
    .io_d_bits_opcode(g_io_d_bits_opcode),
    .io_d_bits_param(g_io_d_bits_param),
    .io_d_bits_source(g_io_d_bits_source),
    .io_d_bits_sink(g_io_d_bits_sink),
    .io_d_bits_denied(g_io_d_bits_denied),
    .io_d_bits_echo_isKeyword(g_io_d_bits_echo_isKeyword),
    .io_d_bits_data(g_io_d_bits_data),
    .io_d_bits_corrupt(g_io_d_bits_corrupt),
    .io_e_valid(io_e_valid),
    .io_e_bits_sink(io_e_bits_sink),
    .io_fromReqArb_status_s1_tags_1(io_fromReqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_1(io_fromReqArb_status_s1_sets_1),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel(io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel(io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel(io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel(io_pipeStatusVec_4_bits_channel),
    .io_toReqArb_blockSinkReqEntrance_blockA_s1(g_io_toReqArb_blockSinkReqEntrance_blockA_s1),
    .io_toReqArb_blockSinkReqEntrance_blockB_s1(g_io_toReqArb_blockSinkReqEntrance_blockB_s1),
    .io_toReqArb_blockSinkReqEntrance_blockC_s1(g_io_toReqArb_blockSinkReqEntrance_blockC_s1),
    .io_toReqArb_blockMSHRReqEntrance(g_io_toReqArb_blockMSHRReqEntrance),
    .io_prefetchResp_ready(io_prefetchResp_ready),
    .io_prefetchResp_valid(g_io_prefetchResp_valid),
    .io_prefetchResp_bits_tag(g_io_prefetchResp_bits_tag),
    .io_prefetchResp_bits_set(g_io_prefetchResp_bits_set),
    .io_prefetchResp_bits_vaddr(g_io_prefetchResp_bits_vaddr),
    .io_prefetchResp_bits_pfSource(g_io_prefetchResp_bits_pfSource),
    .io_grantStatus_0_valid(g_io_grantStatus_0_valid),
    .io_grantStatus_0_set(g_io_grantStatus_0_set),
    .io_grantStatus_0_tag(g_io_grantStatus_0_tag),
    .io_grantStatus_1_valid(g_io_grantStatus_1_valid),
    .io_grantStatus_1_set(g_io_grantStatus_1_set),
    .io_grantStatus_1_tag(g_io_grantStatus_1_tag),
    .io_grantStatus_2_valid(g_io_grantStatus_2_valid),
    .io_grantStatus_2_set(g_io_grantStatus_2_set),
    .io_grantStatus_2_tag(g_io_grantStatus_2_tag),
    .io_grantStatus_3_valid(g_io_grantStatus_3_valid),
    .io_grantStatus_3_set(g_io_grantStatus_3_set),
    .io_grantStatus_3_tag(g_io_grantStatus_3_tag),
    .io_grantStatus_4_valid(g_io_grantStatus_4_valid),
    .io_grantStatus_4_set(g_io_grantStatus_4_set),
    .io_grantStatus_4_tag(g_io_grantStatus_4_tag),
    .io_grantStatus_5_valid(g_io_grantStatus_5_valid),
    .io_grantStatus_5_set(g_io_grantStatus_5_set),
    .io_grantStatus_5_tag(g_io_grantStatus_5_tag),
    .io_grantStatus_6_valid(g_io_grantStatus_6_valid),
    .io_grantStatus_6_set(g_io_grantStatus_6_set),
    .io_grantStatus_6_tag(g_io_grantStatus_6_tag),
    .io_grantStatus_7_valid(g_io_grantStatus_7_valid),
    .io_grantStatus_7_set(g_io_grantStatus_7_set),
    .io_grantStatus_7_tag(g_io_grantStatus_7_tag),
    .io_grantStatus_8_valid(g_io_grantStatus_8_valid),
    .io_grantStatus_8_set(g_io_grantStatus_8_set),
    .io_grantStatus_8_tag(g_io_grantStatus_8_tag),
    .io_grantStatus_9_valid(g_io_grantStatus_9_valid),
    .io_grantStatus_9_set(g_io_grantStatus_9_set),
    .io_grantStatus_9_tag(g_io_grantStatus_9_tag),
    .io_grantStatus_10_valid(g_io_grantStatus_10_valid),
    .io_grantStatus_10_set(g_io_grantStatus_10_set),
    .io_grantStatus_10_tag(g_io_grantStatus_10_tag),
    .io_grantStatus_11_valid(g_io_grantStatus_11_valid),
    .io_grantStatus_11_set(g_io_grantStatus_11_set),
    .io_grantStatus_11_tag(g_io_grantStatus_11_tag),
    .io_grantStatus_12_valid(g_io_grantStatus_12_valid),
    .io_grantStatus_12_set(g_io_grantStatus_12_set),
    .io_grantStatus_12_tag(g_io_grantStatus_12_tag),
    .io_grantStatus_13_valid(g_io_grantStatus_13_valid),
    .io_grantStatus_13_set(g_io_grantStatus_13_set),
    .io_grantStatus_13_tag(g_io_grantStatus_13_tag),
    .io_grantStatus_14_valid(g_io_grantStatus_14_valid),
    .io_grantStatus_14_set(g_io_grantStatus_14_set),
    .io_grantStatus_14_tag(g_io_grantStatus_14_tag),
    .io_grantStatus_15_valid(g_io_grantStatus_15_valid),
    .io_grantStatus_15_set(g_io_grantStatus_15_set),
    .io_grantStatus_15_tag(g_io_grantStatus_15_tag)
  );
  GrantBuffer_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_d_task_valid(io_d_task_valid),
    .io_d_task_bits_task_channel(io_d_task_bits_task_channel),
    .io_d_task_bits_task_txChannel(io_d_task_bits_task_txChannel),
    .io_d_task_bits_task_set(io_d_task_bits_task_set),
    .io_d_task_bits_task_tag(io_d_task_bits_task_tag),
    .io_d_task_bits_task_off(io_d_task_bits_task_off),
    .io_d_task_bits_task_alias(io_d_task_bits_task_alias),
    .io_d_task_bits_task_vaddr(io_d_task_bits_task_vaddr),
    .io_d_task_bits_task_isKeyword(io_d_task_bits_task_isKeyword),
    .io_d_task_bits_task_opcode(io_d_task_bits_task_opcode),
    .io_d_task_bits_task_param(io_d_task_bits_task_param),
    .io_d_task_bits_task_size(io_d_task_bits_task_size),
    .io_d_task_bits_task_sourceId(io_d_task_bits_task_sourceId),
    .io_d_task_bits_task_bufIdx(io_d_task_bits_task_bufIdx),
    .io_d_task_bits_task_needProbeAckData(io_d_task_bits_task_needProbeAckData),
    .io_d_task_bits_task_denied(io_d_task_bits_task_denied),
    .io_d_task_bits_task_corrupt(io_d_task_bits_task_corrupt),
    .io_d_task_bits_task_mshrTask(io_d_task_bits_task_mshrTask),
    .io_d_task_bits_task_mshrId(io_d_task_bits_task_mshrId),
    .io_d_task_bits_task_aliasTask(io_d_task_bits_task_aliasTask),
    .io_d_task_bits_task_useProbeData(io_d_task_bits_task_useProbeData),
    .io_d_task_bits_task_mshrRetry(io_d_task_bits_task_mshrRetry),
    .io_d_task_bits_task_readProbeDataDown(io_d_task_bits_task_readProbeDataDown),
    .io_d_task_bits_task_fromL2pft(io_d_task_bits_task_fromL2pft),
    .io_d_task_bits_task_needHint(io_d_task_bits_task_needHint),
    .io_d_task_bits_task_dirty(io_d_task_bits_task_dirty),
    .io_d_task_bits_task_way(io_d_task_bits_task_way),
    .io_d_task_bits_task_meta_dirty(io_d_task_bits_task_meta_dirty),
    .io_d_task_bits_task_meta_state(io_d_task_bits_task_meta_state),
    .io_d_task_bits_task_meta_clients(io_d_task_bits_task_meta_clients),
    .io_d_task_bits_task_meta_alias(io_d_task_bits_task_meta_alias),
    .io_d_task_bits_task_meta_prefetch(io_d_task_bits_task_meta_prefetch),
    .io_d_task_bits_task_meta_prefetchSrc(io_d_task_bits_task_meta_prefetchSrc),
    .io_d_task_bits_task_meta_accessed(io_d_task_bits_task_meta_accessed),
    .io_d_task_bits_task_meta_tagErr(io_d_task_bits_task_meta_tagErr),
    .io_d_task_bits_task_meta_dataErr(io_d_task_bits_task_meta_dataErr),
    .io_d_task_bits_task_metaWen(io_d_task_bits_task_metaWen),
    .io_d_task_bits_task_tagWen(io_d_task_bits_task_tagWen),
    .io_d_task_bits_task_dsWen(io_d_task_bits_task_dsWen),
    .io_d_task_bits_task_wayMask(io_d_task_bits_task_wayMask),
    .io_d_task_bits_task_replTask(io_d_task_bits_task_replTask),
    .io_d_task_bits_task_cmoTask(io_d_task_bits_task_cmoTask),
    .io_d_task_bits_task_cmoAll(io_d_task_bits_task_cmoAll),
    .io_d_task_bits_task_reqSource(io_d_task_bits_task_reqSource),
    .io_d_task_bits_task_mergeA(io_d_task_bits_task_mergeA),
    .io_d_task_bits_task_aMergeTask_off(io_d_task_bits_task_aMergeTask_off),
    .io_d_task_bits_task_aMergeTask_alias(io_d_task_bits_task_aMergeTask_alias),
    .io_d_task_bits_task_aMergeTask_vaddr(io_d_task_bits_task_aMergeTask_vaddr),
    .io_d_task_bits_task_aMergeTask_isKeyword(io_d_task_bits_task_aMergeTask_isKeyword),
    .io_d_task_bits_task_aMergeTask_opcode(io_d_task_bits_task_aMergeTask_opcode),
    .io_d_task_bits_task_aMergeTask_param(io_d_task_bits_task_aMergeTask_param),
    .io_d_task_bits_task_aMergeTask_sourceId(io_d_task_bits_task_aMergeTask_sourceId),
    .io_d_task_bits_task_aMergeTask_meta_dirty(io_d_task_bits_task_aMergeTask_meta_dirty),
    .io_d_task_bits_task_aMergeTask_meta_state(io_d_task_bits_task_aMergeTask_meta_state),
    .io_d_task_bits_task_aMergeTask_meta_clients(io_d_task_bits_task_aMergeTask_meta_clients),
    .io_d_task_bits_task_aMergeTask_meta_alias(io_d_task_bits_task_aMergeTask_meta_alias),
    .io_d_task_bits_task_aMergeTask_meta_prefetch(io_d_task_bits_task_aMergeTask_meta_prefetch),
    .io_d_task_bits_task_aMergeTask_meta_prefetchSrc(io_d_task_bits_task_aMergeTask_meta_prefetchSrc),
    .io_d_task_bits_task_aMergeTask_meta_accessed(io_d_task_bits_task_aMergeTask_meta_accessed),
    .io_d_task_bits_task_aMergeTask_meta_tagErr(io_d_task_bits_task_aMergeTask_meta_tagErr),
    .io_d_task_bits_task_aMergeTask_meta_dataErr(io_d_task_bits_task_aMergeTask_meta_dataErr),
    .io_d_task_bits_task_snpHitRelease(io_d_task_bits_task_snpHitRelease),
    .io_d_task_bits_task_snpHitReleaseToInval(io_d_task_bits_task_snpHitReleaseToInval),
    .io_d_task_bits_task_snpHitReleaseToClean(io_d_task_bits_task_snpHitReleaseToClean),
    .io_d_task_bits_task_snpHitReleaseWithData(io_d_task_bits_task_snpHitReleaseWithData),
    .io_d_task_bits_task_snpHitReleaseIdx(io_d_task_bits_task_snpHitReleaseIdx),
    .io_d_task_bits_task_snpHitReleaseMeta_dirty(io_d_task_bits_task_snpHitReleaseMeta_dirty),
    .io_d_task_bits_task_snpHitReleaseMeta_state(io_d_task_bits_task_snpHitReleaseMeta_state),
    .io_d_task_bits_task_snpHitReleaseMeta_clients(io_d_task_bits_task_snpHitReleaseMeta_clients),
    .io_d_task_bits_task_snpHitReleaseMeta_alias(io_d_task_bits_task_snpHitReleaseMeta_alias),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetch(io_d_task_bits_task_snpHitReleaseMeta_prefetch),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc(io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_d_task_bits_task_snpHitReleaseMeta_accessed(io_d_task_bits_task_snpHitReleaseMeta_accessed),
    .io_d_task_bits_task_snpHitReleaseMeta_tagErr(io_d_task_bits_task_snpHitReleaseMeta_tagErr),
    .io_d_task_bits_task_snpHitReleaseMeta_dataErr(io_d_task_bits_task_snpHitReleaseMeta_dataErr),
    .io_d_task_bits_task_tgtID(io_d_task_bits_task_tgtID),
    .io_d_task_bits_task_srcID(io_d_task_bits_task_srcID),
    .io_d_task_bits_task_txnID(io_d_task_bits_task_txnID),
    .io_d_task_bits_task_homeNID(io_d_task_bits_task_homeNID),
    .io_d_task_bits_task_dbID(io_d_task_bits_task_dbID),
    .io_d_task_bits_task_fwdNID(io_d_task_bits_task_fwdNID),
    .io_d_task_bits_task_fwdTxnID(io_d_task_bits_task_fwdTxnID),
    .io_d_task_bits_task_chiOpcode(io_d_task_bits_task_chiOpcode),
    .io_d_task_bits_task_resp(io_d_task_bits_task_resp),
    .io_d_task_bits_task_fwdState(io_d_task_bits_task_fwdState),
    .io_d_task_bits_task_pCrdType(io_d_task_bits_task_pCrdType),
    .io_d_task_bits_task_retToSrc(io_d_task_bits_task_retToSrc),
    .io_d_task_bits_task_likelyshared(io_d_task_bits_task_likelyshared),
    .io_d_task_bits_task_expCompAck(io_d_task_bits_task_expCompAck),
    .io_d_task_bits_task_allowRetry(io_d_task_bits_task_allowRetry),
    .io_d_task_bits_task_memAttr_allocate(io_d_task_bits_task_memAttr_allocate),
    .io_d_task_bits_task_memAttr_cacheable(io_d_task_bits_task_memAttr_cacheable),
    .io_d_task_bits_task_memAttr_device(io_d_task_bits_task_memAttr_device),
    .io_d_task_bits_task_memAttr_ewa(io_d_task_bits_task_memAttr_ewa),
    .io_d_task_bits_task_traceTag(io_d_task_bits_task_traceTag),
    .io_d_task_bits_task_dataCheckErr(io_d_task_bits_task_dataCheckErr),
    .io_d_task_bits_data_data(io_d_task_bits_data_data),
    .io_d_ready(io_d_ready),
    .io_d_valid(i_io_d_valid),
    .io_d_bits_opcode(i_io_d_bits_opcode),
    .io_d_bits_param(i_io_d_bits_param),
    .io_d_bits_source(i_io_d_bits_source),
    .io_d_bits_sink(i_io_d_bits_sink),
    .io_d_bits_denied(i_io_d_bits_denied),
    .io_d_bits_echo_isKeyword(i_io_d_bits_echo_isKeyword),
    .io_d_bits_data(i_io_d_bits_data),
    .io_d_bits_corrupt(i_io_d_bits_corrupt),
    .io_e_valid(io_e_valid),
    .io_e_bits_sink(io_e_bits_sink),
    .io_fromReqArb_status_s1_tags_1(io_fromReqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_1(io_fromReqArb_status_s1_sets_1),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel(io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel(io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel(io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel(io_pipeStatusVec_4_bits_channel),
    .io_toReqArb_blockSinkReqEntrance_blockA_s1(i_io_toReqArb_blockSinkReqEntrance_blockA_s1),
    .io_toReqArb_blockSinkReqEntrance_blockB_s1(i_io_toReqArb_blockSinkReqEntrance_blockB_s1),
    .io_toReqArb_blockSinkReqEntrance_blockC_s1(i_io_toReqArb_blockSinkReqEntrance_blockC_s1),
    .io_toReqArb_blockMSHRReqEntrance(i_io_toReqArb_blockMSHRReqEntrance),
    .io_prefetchResp_ready(io_prefetchResp_ready),
    .io_prefetchResp_valid(i_io_prefetchResp_valid),
    .io_prefetchResp_bits_tag(i_io_prefetchResp_bits_tag),
    .io_prefetchResp_bits_set(i_io_prefetchResp_bits_set),
    .io_prefetchResp_bits_vaddr(i_io_prefetchResp_bits_vaddr),
    .io_prefetchResp_bits_pfSource(i_io_prefetchResp_bits_pfSource),
    .io_grantStatus_0_valid(i_io_grantStatus_0_valid),
    .io_grantStatus_0_set(i_io_grantStatus_0_set),
    .io_grantStatus_0_tag(i_io_grantStatus_0_tag),
    .io_grantStatus_1_valid(i_io_grantStatus_1_valid),
    .io_grantStatus_1_set(i_io_grantStatus_1_set),
    .io_grantStatus_1_tag(i_io_grantStatus_1_tag),
    .io_grantStatus_2_valid(i_io_grantStatus_2_valid),
    .io_grantStatus_2_set(i_io_grantStatus_2_set),
    .io_grantStatus_2_tag(i_io_grantStatus_2_tag),
    .io_grantStatus_3_valid(i_io_grantStatus_3_valid),
    .io_grantStatus_3_set(i_io_grantStatus_3_set),
    .io_grantStatus_3_tag(i_io_grantStatus_3_tag),
    .io_grantStatus_4_valid(i_io_grantStatus_4_valid),
    .io_grantStatus_4_set(i_io_grantStatus_4_set),
    .io_grantStatus_4_tag(i_io_grantStatus_4_tag),
    .io_grantStatus_5_valid(i_io_grantStatus_5_valid),
    .io_grantStatus_5_set(i_io_grantStatus_5_set),
    .io_grantStatus_5_tag(i_io_grantStatus_5_tag),
    .io_grantStatus_6_valid(i_io_grantStatus_6_valid),
    .io_grantStatus_6_set(i_io_grantStatus_6_set),
    .io_grantStatus_6_tag(i_io_grantStatus_6_tag),
    .io_grantStatus_7_valid(i_io_grantStatus_7_valid),
    .io_grantStatus_7_set(i_io_grantStatus_7_set),
    .io_grantStatus_7_tag(i_io_grantStatus_7_tag),
    .io_grantStatus_8_valid(i_io_grantStatus_8_valid),
    .io_grantStatus_8_set(i_io_grantStatus_8_set),
    .io_grantStatus_8_tag(i_io_grantStatus_8_tag),
    .io_grantStatus_9_valid(i_io_grantStatus_9_valid),
    .io_grantStatus_9_set(i_io_grantStatus_9_set),
    .io_grantStatus_9_tag(i_io_grantStatus_9_tag),
    .io_grantStatus_10_valid(i_io_grantStatus_10_valid),
    .io_grantStatus_10_set(i_io_grantStatus_10_set),
    .io_grantStatus_10_tag(i_io_grantStatus_10_tag),
    .io_grantStatus_11_valid(i_io_grantStatus_11_valid),
    .io_grantStatus_11_set(i_io_grantStatus_11_set),
    .io_grantStatus_11_tag(i_io_grantStatus_11_tag),
    .io_grantStatus_12_valid(i_io_grantStatus_12_valid),
    .io_grantStatus_12_set(i_io_grantStatus_12_set),
    .io_grantStatus_12_tag(i_io_grantStatus_12_tag),
    .io_grantStatus_13_valid(i_io_grantStatus_13_valid),
    .io_grantStatus_13_set(i_io_grantStatus_13_set),
    .io_grantStatus_13_tag(i_io_grantStatus_13_tag),
    .io_grantStatus_14_valid(i_io_grantStatus_14_valid),
    .io_grantStatus_14_set(i_io_grantStatus_14_set),
    .io_grantStatus_14_tag(i_io_grantStatus_14_tag),
    .io_grantStatus_15_valid(i_io_grantStatus_15_valid),
    .io_grantStatus_15_set(i_io_grantStatus_15_set),
    .io_grantStatus_15_tag(i_io_grantStatus_15_tag)
  );

  task automatic drive_random();
    io_d_task_valid = ($urandom_range(0,1) == 0);
    io_d_task_bits_task_channel = $urandom;
    io_d_task_bits_task_txChannel = $urandom;
    io_d_task_bits_task_set = $urandom_range(0,7);
    io_d_task_bits_task_tag = $urandom_range(0,7);
    io_d_task_bits_task_off = $urandom;
    io_d_task_bits_task_alias = $urandom;
    io_d_task_bits_task_vaddr = {$urandom, $urandom};
    io_d_task_bits_task_isKeyword = $urandom;
    io_d_task_bits_task_opcode = $urandom_range(0,5);
    io_d_task_bits_task_param = $urandom;
    io_d_task_bits_task_size = $urandom;
    io_d_task_bits_task_sourceId = $urandom;
    io_d_task_bits_task_bufIdx = $urandom;
    io_d_task_bits_task_needProbeAckData = $urandom;
    io_d_task_bits_task_denied = $urandom;
    io_d_task_bits_task_corrupt = $urandom;
    io_d_task_bits_task_mshrTask = $urandom;
    io_d_task_bits_task_mshrId = $urandom;
    io_d_task_bits_task_aliasTask = $urandom;
    io_d_task_bits_task_useProbeData = $urandom;
    io_d_task_bits_task_mshrRetry = $urandom;
    io_d_task_bits_task_readProbeDataDown = $urandom;
    io_d_task_bits_task_fromL2pft = ($urandom_range(0,1) == 0);
    io_d_task_bits_task_needHint = $urandom;
    io_d_task_bits_task_dirty = $urandom;
    io_d_task_bits_task_way = $urandom;
    io_d_task_bits_task_meta_dirty = $urandom;
    io_d_task_bits_task_meta_state = $urandom;
    io_d_task_bits_task_meta_clients = $urandom;
    io_d_task_bits_task_meta_alias = $urandom;
    io_d_task_bits_task_meta_prefetch = $urandom;
    io_d_task_bits_task_meta_prefetchSrc = $urandom;
    io_d_task_bits_task_meta_accessed = $urandom;
    io_d_task_bits_task_meta_tagErr = $urandom;
    io_d_task_bits_task_meta_dataErr = $urandom;
    io_d_task_bits_task_metaWen = $urandom;
    io_d_task_bits_task_tagWen = $urandom;
    io_d_task_bits_task_dsWen = $urandom;
    io_d_task_bits_task_wayMask = $urandom;
    io_d_task_bits_task_replTask = $urandom;
    io_d_task_bits_task_cmoTask = $urandom;
    io_d_task_bits_task_cmoAll = $urandom;
    io_d_task_bits_task_reqSource = $urandom;
    io_d_task_bits_task_mergeA = ($urandom_range(0,3) == 0);
    io_d_task_bits_task_aMergeTask_off = $urandom;
    io_d_task_bits_task_aMergeTask_alias = $urandom;
    io_d_task_bits_task_aMergeTask_vaddr = {$urandom, $urandom};
    io_d_task_bits_task_aMergeTask_isKeyword = $urandom;
    io_d_task_bits_task_aMergeTask_opcode = $urandom;
    io_d_task_bits_task_aMergeTask_param = $urandom;
    io_d_task_bits_task_aMergeTask_sourceId = $urandom;
    io_d_task_bits_task_aMergeTask_meta_dirty = $urandom;
    io_d_task_bits_task_aMergeTask_meta_state = $urandom;
    io_d_task_bits_task_aMergeTask_meta_clients = $urandom;
    io_d_task_bits_task_aMergeTask_meta_alias = $urandom;
    io_d_task_bits_task_aMergeTask_meta_prefetch = $urandom;
    io_d_task_bits_task_aMergeTask_meta_prefetchSrc = $urandom;
    io_d_task_bits_task_aMergeTask_meta_accessed = $urandom;
    io_d_task_bits_task_aMergeTask_meta_tagErr = $urandom;
    io_d_task_bits_task_aMergeTask_meta_dataErr = $urandom;
    io_d_task_bits_task_snpHitRelease = $urandom;
    io_d_task_bits_task_snpHitReleaseToInval = $urandom;
    io_d_task_bits_task_snpHitReleaseToClean = $urandom;
    io_d_task_bits_task_snpHitReleaseWithData = $urandom;
    io_d_task_bits_task_snpHitReleaseIdx = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_dirty = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_state = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_clients = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_alias = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_prefetch = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_accessed = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_tagErr = $urandom;
    io_d_task_bits_task_snpHitReleaseMeta_dataErr = $urandom;
    io_d_task_bits_task_tgtID = $urandom;
    io_d_task_bits_task_srcID = $urandom;
    io_d_task_bits_task_txnID = $urandom;
    io_d_task_bits_task_homeNID = $urandom;
    io_d_task_bits_task_dbID = $urandom;
    io_d_task_bits_task_fwdNID = $urandom;
    io_d_task_bits_task_fwdTxnID = $urandom;
    io_d_task_bits_task_chiOpcode = $urandom;
    io_d_task_bits_task_resp = $urandom;
    io_d_task_bits_task_fwdState = $urandom;
    io_d_task_bits_task_pCrdType = $urandom;
    io_d_task_bits_task_retToSrc = $urandom;
    io_d_task_bits_task_likelyshared = $urandom;
    io_d_task_bits_task_expCompAck = $urandom;
    io_d_task_bits_task_allowRetry = $urandom;
    io_d_task_bits_task_memAttr_allocate = $urandom;
    io_d_task_bits_task_memAttr_cacheable = $urandom;
    io_d_task_bits_task_memAttr_device = $urandom;
    io_d_task_bits_task_memAttr_ewa = $urandom;
    io_d_task_bits_task_traceTag = $urandom;
    io_d_task_bits_task_dataCheckErr = $urandom;
    io_d_task_bits_data_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_d_ready = ($urandom_range(0,2) != 0);
    io_e_valid = ($urandom_range(0,2) == 0);
    io_e_bits_sink = $urandom_range(0,15);
    io_fromReqArb_status_s1_tags_1 = $urandom_range(0,7);
    io_fromReqArb_status_s1_sets_1 = $urandom_range(0,7);
    io_pipeStatusVec_1_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_1_bits_channel = $urandom_range(0,7);
    io_pipeStatusVec_2_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_2_bits_channel = $urandom_range(0,7);
    io_pipeStatusVec_3_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_3_bits_channel = $urandom_range(0,7);
    io_pipeStatusVec_4_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_4_bits_channel = $urandom_range(0,7);
    io_prefetchResp_ready = ($urandom_range(0,1) == 0);
  endtask

  task automatic check_outputs();
    `CHK(io_d_valid)
    `CHK(io_d_bits_opcode)
    `CHK(io_d_bits_param)
    `CHK(io_d_bits_source)
    `CHK(io_d_bits_sink)
    `CHK(io_d_bits_denied)
    `CHK(io_d_bits_echo_isKeyword)
    `CHK(io_d_bits_data)
    `CHK(io_d_bits_corrupt)
    `CHK(io_toReqArb_blockSinkReqEntrance_blockA_s1)
    `CHK(io_toReqArb_blockSinkReqEntrance_blockB_s1)
    `CHK(io_toReqArb_blockSinkReqEntrance_blockC_s1)
    `CHK(io_toReqArb_blockMSHRReqEntrance)
    `CHK(io_prefetchResp_valid)
    `CHK(io_prefetchResp_bits_tag)
    `CHK(io_prefetchResp_bits_set)
    `CHK(io_prefetchResp_bits_vaddr)
    `CHK(io_prefetchResp_bits_pfSource)
    `CHK(io_grantStatus_0_valid)
    `CHK(io_grantStatus_0_set)
    `CHK(io_grantStatus_0_tag)
    `CHK(io_grantStatus_1_valid)
    `CHK(io_grantStatus_1_set)
    `CHK(io_grantStatus_1_tag)
    `CHK(io_grantStatus_2_valid)
    `CHK(io_grantStatus_2_set)
    `CHK(io_grantStatus_2_tag)
    `CHK(io_grantStatus_3_valid)
    `CHK(io_grantStatus_3_set)
    `CHK(io_grantStatus_3_tag)
    `CHK(io_grantStatus_4_valid)
    `CHK(io_grantStatus_4_set)
    `CHK(io_grantStatus_4_tag)
    `CHK(io_grantStatus_5_valid)
    `CHK(io_grantStatus_5_set)
    `CHK(io_grantStatus_5_tag)
    `CHK(io_grantStatus_6_valid)
    `CHK(io_grantStatus_6_set)
    `CHK(io_grantStatus_6_tag)
    `CHK(io_grantStatus_7_valid)
    `CHK(io_grantStatus_7_set)
    `CHK(io_grantStatus_7_tag)
    `CHK(io_grantStatus_8_valid)
    `CHK(io_grantStatus_8_set)
    `CHK(io_grantStatus_8_tag)
    `CHK(io_grantStatus_9_valid)
    `CHK(io_grantStatus_9_set)
    `CHK(io_grantStatus_9_tag)
    `CHK(io_grantStatus_10_valid)
    `CHK(io_grantStatus_10_set)
    `CHK(io_grantStatus_10_tag)
    `CHK(io_grantStatus_11_valid)
    `CHK(io_grantStatus_11_set)
    `CHK(io_grantStatus_11_tag)
    `CHK(io_grantStatus_12_valid)
    `CHK(io_grantStatus_12_set)
    `CHK(io_grantStatus_12_tag)
    `CHK(io_grantStatus_13_valid)
    `CHK(io_grantStatus_13_set)
    `CHK(io_grantStatus_13_tag)
    `CHK(io_grantStatus_14_valid)
    `CHK(io_grantStatus_14_set)
    `CHK(io_grantStatus_14_tag)
    `CHK(io_grantStatus_15_valid)
    `CHK(io_grantStatus_15_set)
    `CHK(io_grantStatus_15_tag)
  endtask

  int ierr = 0;
  `define IP(GP, IP) begin \
    if (!$isunknown(u_g.GP)) begin \
      if (u_g.GP !== u_i.u_core.IP) begin \
        ierr++; \
        if (ierr <= 40) $display("[%0t] IPROBE-DIFF %s g=%0h i=%0h", $time, `"GP`", u_g.GP, u_i.u_core.IP); \
      end \
    end \
  end
  task automatic check_internal();
    `IP(inflightGrant_0_valid,    inflightGrant_valid[0])
    `IP(inflightGrant_0_bits_set, inflightGrant_set[0])
    `IP(inflightGrant_0_bits_tag, inflightGrant_tag[0])
    `IP(inflightGrant_1_valid,    inflightGrant_valid[1])
    `IP(inflightGrant_1_bits_set, inflightGrant_set[1])
    `IP(inflightGrant_1_bits_tag, inflightGrant_tag[1])
    `IP(inflightGrant_2_valid,    inflightGrant_valid[2])
    `IP(inflightGrant_2_bits_set, inflightGrant_set[2])
    `IP(inflightGrant_2_bits_tag, inflightGrant_tag[2])
    `IP(inflightGrant_3_valid,    inflightGrant_valid[3])
    `IP(inflightGrant_3_bits_set, inflightGrant_set[3])
    `IP(inflightGrant_3_bits_tag, inflightGrant_tag[3])
    `IP(inflightGrant_4_valid,    inflightGrant_valid[4])
    `IP(inflightGrant_4_bits_set, inflightGrant_set[4])
    `IP(inflightGrant_4_bits_tag, inflightGrant_tag[4])
    `IP(inflightGrant_5_valid,    inflightGrant_valid[5])
    `IP(inflightGrant_5_bits_set, inflightGrant_set[5])
    `IP(inflightGrant_5_bits_tag, inflightGrant_tag[5])
    `IP(inflightGrant_6_valid,    inflightGrant_valid[6])
    `IP(inflightGrant_6_bits_set, inflightGrant_set[6])
    `IP(inflightGrant_6_bits_tag, inflightGrant_tag[6])
    `IP(inflightGrant_7_valid,    inflightGrant_valid[7])
    `IP(inflightGrant_7_bits_set, inflightGrant_set[7])
    `IP(inflightGrant_7_bits_tag, inflightGrant_tag[7])
    `IP(inflightGrant_8_valid,    inflightGrant_valid[8])
    `IP(inflightGrant_8_bits_set, inflightGrant_set[8])
    `IP(inflightGrant_8_bits_tag, inflightGrant_tag[8])
    `IP(inflightGrant_9_valid,    inflightGrant_valid[9])
    `IP(inflightGrant_9_bits_set, inflightGrant_set[9])
    `IP(inflightGrant_9_bits_tag, inflightGrant_tag[9])
    `IP(inflightGrant_10_valid,    inflightGrant_valid[10])
    `IP(inflightGrant_10_bits_set, inflightGrant_set[10])
    `IP(inflightGrant_10_bits_tag, inflightGrant_tag[10])
    `IP(inflightGrant_11_valid,    inflightGrant_valid[11])
    `IP(inflightGrant_11_bits_set, inflightGrant_set[11])
    `IP(inflightGrant_11_bits_tag, inflightGrant_tag[11])
    `IP(inflightGrant_12_valid,    inflightGrant_valid[12])
    `IP(inflightGrant_12_bits_set, inflightGrant_set[12])
    `IP(inflightGrant_12_bits_tag, inflightGrant_tag[12])
    `IP(inflightGrant_13_valid,    inflightGrant_valid[13])
    `IP(inflightGrant_13_bits_set, inflightGrant_set[13])
    `IP(inflightGrant_13_bits_tag, inflightGrant_tag[13])
    `IP(inflightGrant_14_valid,    inflightGrant_valid[14])
    `IP(inflightGrant_14_bits_set, inflightGrant_set[14])
    `IP(inflightGrant_14_bits_tag, inflightGrant_tag[14])
    `IP(inflightGrant_15_valid,    inflightGrant_valid[15])
    `IP(inflightGrant_15_bits_set, inflightGrant_set[15])
    `IP(inflightGrant_15_bits_tag, inflightGrant_tag[15])
    `IP(grantBufValid,           grantBufValid)
    `IP(grantBuf_task_opcode,    grantBuf_task_opcode)
    `IP(grantBuf_task_param,     grantBuf_task_param)
    `IP(grantBuf_task_sourceId,  grantBuf_task_sourceId)
    `IP(grantBuf_task_isKeyword, grantBuf_task_isKeyword)
    `IP(grantBuf_task_denied,    grantBuf_task_denied)
    `IP(grantBuf_task_corrupt,   grantBuf_task_corrupt)
    `IP(grantBuf_grantid,        grantBuf_grantid)
    `IP(grantBuf_data_data,      grantBuf_data_data)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_d_task_valid = '0;
    io_d_task_bits_task_channel = '0;
    io_d_task_bits_task_txChannel = '0;
    io_d_task_bits_task_set = '0;
    io_d_task_bits_task_tag = '0;
    io_d_task_bits_task_off = '0;
    io_d_task_bits_task_alias = '0;
    io_d_task_bits_task_vaddr = '0;
    io_d_task_bits_task_isKeyword = '0;
    io_d_task_bits_task_opcode = '0;
    io_d_task_bits_task_param = '0;
    io_d_task_bits_task_size = '0;
    io_d_task_bits_task_sourceId = '0;
    io_d_task_bits_task_bufIdx = '0;
    io_d_task_bits_task_needProbeAckData = '0;
    io_d_task_bits_task_denied = '0;
    io_d_task_bits_task_corrupt = '0;
    io_d_task_bits_task_mshrTask = '0;
    io_d_task_bits_task_mshrId = '0;
    io_d_task_bits_task_aliasTask = '0;
    io_d_task_bits_task_useProbeData = '0;
    io_d_task_bits_task_mshrRetry = '0;
    io_d_task_bits_task_readProbeDataDown = '0;
    io_d_task_bits_task_fromL2pft = '0;
    io_d_task_bits_task_needHint = '0;
    io_d_task_bits_task_dirty = '0;
    io_d_task_bits_task_way = '0;
    io_d_task_bits_task_meta_dirty = '0;
    io_d_task_bits_task_meta_state = '0;
    io_d_task_bits_task_meta_clients = '0;
    io_d_task_bits_task_meta_alias = '0;
    io_d_task_bits_task_meta_prefetch = '0;
    io_d_task_bits_task_meta_prefetchSrc = '0;
    io_d_task_bits_task_meta_accessed = '0;
    io_d_task_bits_task_meta_tagErr = '0;
    io_d_task_bits_task_meta_dataErr = '0;
    io_d_task_bits_task_metaWen = '0;
    io_d_task_bits_task_tagWen = '0;
    io_d_task_bits_task_dsWen = '0;
    io_d_task_bits_task_wayMask = '0;
    io_d_task_bits_task_replTask = '0;
    io_d_task_bits_task_cmoTask = '0;
    io_d_task_bits_task_cmoAll = '0;
    io_d_task_bits_task_reqSource = '0;
    io_d_task_bits_task_mergeA = '0;
    io_d_task_bits_task_aMergeTask_off = '0;
    io_d_task_bits_task_aMergeTask_alias = '0;
    io_d_task_bits_task_aMergeTask_vaddr = '0;
    io_d_task_bits_task_aMergeTask_isKeyword = '0;
    io_d_task_bits_task_aMergeTask_opcode = '0;
    io_d_task_bits_task_aMergeTask_param = '0;
    io_d_task_bits_task_aMergeTask_sourceId = '0;
    io_d_task_bits_task_aMergeTask_meta_dirty = '0;
    io_d_task_bits_task_aMergeTask_meta_state = '0;
    io_d_task_bits_task_aMergeTask_meta_clients = '0;
    io_d_task_bits_task_aMergeTask_meta_alias = '0;
    io_d_task_bits_task_aMergeTask_meta_prefetch = '0;
    io_d_task_bits_task_aMergeTask_meta_prefetchSrc = '0;
    io_d_task_bits_task_aMergeTask_meta_accessed = '0;
    io_d_task_bits_task_aMergeTask_meta_tagErr = '0;
    io_d_task_bits_task_aMergeTask_meta_dataErr = '0;
    io_d_task_bits_task_snpHitRelease = '0;
    io_d_task_bits_task_snpHitReleaseToInval = '0;
    io_d_task_bits_task_snpHitReleaseToClean = '0;
    io_d_task_bits_task_snpHitReleaseWithData = '0;
    io_d_task_bits_task_snpHitReleaseIdx = '0;
    io_d_task_bits_task_snpHitReleaseMeta_dirty = '0;
    io_d_task_bits_task_snpHitReleaseMeta_state = '0;
    io_d_task_bits_task_snpHitReleaseMeta_clients = '0;
    io_d_task_bits_task_snpHitReleaseMeta_alias = '0;
    io_d_task_bits_task_snpHitReleaseMeta_prefetch = '0;
    io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
    io_d_task_bits_task_snpHitReleaseMeta_accessed = '0;
    io_d_task_bits_task_snpHitReleaseMeta_tagErr = '0;
    io_d_task_bits_task_snpHitReleaseMeta_dataErr = '0;
    io_d_task_bits_task_tgtID = '0;
    io_d_task_bits_task_srcID = '0;
    io_d_task_bits_task_txnID = '0;
    io_d_task_bits_task_homeNID = '0;
    io_d_task_bits_task_dbID = '0;
    io_d_task_bits_task_fwdNID = '0;
    io_d_task_bits_task_fwdTxnID = '0;
    io_d_task_bits_task_chiOpcode = '0;
    io_d_task_bits_task_resp = '0;
    io_d_task_bits_task_fwdState = '0;
    io_d_task_bits_task_pCrdType = '0;
    io_d_task_bits_task_retToSrc = '0;
    io_d_task_bits_task_likelyshared = '0;
    io_d_task_bits_task_expCompAck = '0;
    io_d_task_bits_task_allowRetry = '0;
    io_d_task_bits_task_memAttr_allocate = '0;
    io_d_task_bits_task_memAttr_cacheable = '0;
    io_d_task_bits_task_memAttr_device = '0;
    io_d_task_bits_task_memAttr_ewa = '0;
    io_d_task_bits_task_traceTag = '0;
    io_d_task_bits_task_dataCheckErr = '0;
    io_d_task_bits_data_data = '0;
    io_d_ready = '0;
    io_e_valid = '0;
    io_e_bits_sink = '0;
    io_fromReqArb_status_s1_tags_1 = '0;
    io_fromReqArb_status_s1_sets_1 = '0;
    io_pipeStatusVec_1_valid = '0;
    io_pipeStatusVec_1_bits_channel = '0;
    io_pipeStatusVec_2_valid = '0;
    io_pipeStatusVec_2_bits_channel = '0;
    io_pipeStatusVec_3_valid = '0;
    io_pipeStatusVec_3_bits_channel = '0;
    io_pipeStatusVec_4_valid = '0;
    io_pipeStatusVec_4_bits_channel = '0;
    io_prefetchResp_ready = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("GrantBuffer checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
`undef IP
