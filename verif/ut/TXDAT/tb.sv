// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// TXDAT 双例化逐拍比对: golden TXDAT vs 可读重写 TXDAT_xs。
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
  logic io_in_valid;
  logic [2:0] io_in_bits_task_channel;
  logic [2:0] io_in_bits_task_txChannel;
  logic [8:0] io_in_bits_task_set;
  logic [30:0] io_in_bits_task_tag;
  logic [5:0] io_in_bits_task_off;
  logic [1:0] io_in_bits_task_alias;
  logic [43:0] io_in_bits_task_vaddr;
  logic io_in_bits_task_isKeyword;
  logic [3:0] io_in_bits_task_opcode;
  logic [2:0] io_in_bits_task_param;
  logic [2:0] io_in_bits_task_size;
  logic [6:0] io_in_bits_task_sourceId;
  logic [1:0] io_in_bits_task_bufIdx;
  logic io_in_bits_task_needProbeAckData;
  logic io_in_bits_task_denied;
  logic io_in_bits_task_corrupt;
  logic io_in_bits_task_mshrTask;
  logic [7:0] io_in_bits_task_mshrId;
  logic io_in_bits_task_aliasTask;
  logic io_in_bits_task_useProbeData;
  logic io_in_bits_task_mshrRetry;
  logic io_in_bits_task_readProbeDataDown;
  logic io_in_bits_task_fromL2pft;
  logic io_in_bits_task_needHint;
  logic io_in_bits_task_dirty;
  logic [2:0] io_in_bits_task_way;
  logic io_in_bits_task_meta_dirty;
  logic [1:0] io_in_bits_task_meta_state;
  logic io_in_bits_task_meta_clients;
  logic [1:0] io_in_bits_task_meta_alias;
  logic io_in_bits_task_meta_prefetch;
  logic [2:0] io_in_bits_task_meta_prefetchSrc;
  logic io_in_bits_task_meta_accessed;
  logic io_in_bits_task_meta_tagErr;
  logic io_in_bits_task_meta_dataErr;
  logic io_in_bits_task_metaWen;
  logic io_in_bits_task_tagWen;
  logic io_in_bits_task_dsWen;
  logic [7:0] io_in_bits_task_wayMask;
  logic io_in_bits_task_replTask;
  logic io_in_bits_task_cmoTask;
  logic io_in_bits_task_cmoAll;
  logic [4:0] io_in_bits_task_reqSource;
  logic io_in_bits_task_mergeA;
  logic [5:0] io_in_bits_task_aMergeTask_off;
  logic [1:0] io_in_bits_task_aMergeTask_alias;
  logic [43:0] io_in_bits_task_aMergeTask_vaddr;
  logic io_in_bits_task_aMergeTask_isKeyword;
  logic [2:0] io_in_bits_task_aMergeTask_opcode;
  logic [2:0] io_in_bits_task_aMergeTask_param;
  logic [6:0] io_in_bits_task_aMergeTask_sourceId;
  logic io_in_bits_task_aMergeTask_meta_dirty;
  logic [1:0] io_in_bits_task_aMergeTask_meta_state;
  logic io_in_bits_task_aMergeTask_meta_clients;
  logic [1:0] io_in_bits_task_aMergeTask_meta_alias;
  logic io_in_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] io_in_bits_task_aMergeTask_meta_prefetchSrc;
  logic io_in_bits_task_aMergeTask_meta_accessed;
  logic io_in_bits_task_aMergeTask_meta_tagErr;
  logic io_in_bits_task_aMergeTask_meta_dataErr;
  logic io_in_bits_task_snpHitRelease;
  logic io_in_bits_task_snpHitReleaseToInval;
  logic io_in_bits_task_snpHitReleaseToClean;
  logic io_in_bits_task_snpHitReleaseWithData;
  logic [7:0] io_in_bits_task_snpHitReleaseIdx;
  logic io_in_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_bits_task_snpHitReleaseMeta_state;
  logic io_in_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] io_in_bits_task_snpHitReleaseMeta_alias;
  logic io_in_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic io_in_bits_task_snpHitReleaseMeta_accessed;
  logic io_in_bits_task_snpHitReleaseMeta_tagErr;
  logic io_in_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_bits_task_tgtID;
  logic [10:0] io_in_bits_task_srcID;
  logic [11:0] io_in_bits_task_txnID;
  logic [10:0] io_in_bits_task_homeNID;
  logic [11:0] io_in_bits_task_dbID;
  logic [10:0] io_in_bits_task_fwdNID;
  logic [11:0] io_in_bits_task_fwdTxnID;
  logic [6:0] io_in_bits_task_chiOpcode;
  logic [2:0] io_in_bits_task_resp;
  logic [2:0] io_in_bits_task_fwdState;
  logic [3:0] io_in_bits_task_pCrdType;
  logic io_in_bits_task_retToSrc;
  logic io_in_bits_task_likelyshared;
  logic io_in_bits_task_expCompAck;
  logic io_in_bits_task_allowRetry;
  logic io_in_bits_task_memAttr_allocate;
  logic io_in_bits_task_memAttr_cacheable;
  logic io_in_bits_task_memAttr_device;
  logic io_in_bits_task_memAttr_ewa;
  logic io_in_bits_task_traceTag;
  logic io_in_bits_task_dataCheckErr;
  logic [511:0] io_in_bits_data_data;
  logic io_out_ready;
  logic io_pipeStatusVec_1_valid;
  logic [2:0] io_pipeStatusVec_1_bits_channel;
  logic [2:0] io_pipeStatusVec_1_bits_txChannel;
  logic io_pipeStatusVec_1_bits_mshrTask;
  logic io_pipeStatusVec_2_valid;
  logic [2:0] io_pipeStatusVec_2_bits_channel;
  logic [2:0] io_pipeStatusVec_2_bits_txChannel;
  logic io_pipeStatusVec_2_bits_mshrTask;
  logic io_pipeStatusVec_3_valid;
  logic [2:0] io_pipeStatusVec_3_bits_channel;
  logic [2:0] io_pipeStatusVec_3_bits_txChannel;
  logic io_pipeStatusVec_3_bits_mshrTask;
  logic io_pipeStatusVec_4_valid;
  logic [2:0] io_pipeStatusVec_4_bits_channel;
  logic [2:0] io_pipeStatusVec_4_bits_txChannel;
  logic io_pipeStatusVec_4_bits_mshrTask;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [10:0] g_io_out_bits_homeNID;
  wire [10:0] i_io_out_bits_homeNID;
  wire [3:0] g_io_out_bits_opcode;
  wire [3:0] i_io_out_bits_opcode;
  wire [1:0] g_io_out_bits_respErr;
  wire [1:0] i_io_out_bits_respErr;
  wire [2:0] g_io_out_bits_resp;
  wire [2:0] i_io_out_bits_resp;
  wire [3:0] g_io_out_bits_dataSource;
  wire [3:0] i_io_out_bits_dataSource;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [1:0] g_io_out_bits_ccID;
  wire [1:0] i_io_out_bits_ccID;
  wire [1:0] g_io_out_bits_dataID;
  wire [1:0] i_io_out_bits_dataID;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire [31:0] g_io_out_bits_be;
  wire [31:0] i_io_out_bits_be;
  wire [255:0] g_io_out_bits_data;
  wire [255:0] i_io_out_bits_data;
  wire [31:0] g_io_out_bits_dataCheck;
  wire [31:0] i_io_out_bits_dataCheck;
  wire [3:0] g_io_out_bits_poison;
  wire [3:0] i_io_out_bits_poison;
  wire g_io_toReqArb_blockMSHRReqEntrance;
  wire i_io_toReqArb_blockMSHRReqEntrance;
  wire g_io_toReqArb_blockSinkBReqEntrance;
  wire i_io_toReqArb_blockSinkBReqEntrance;

  TXDAT u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_task_channel(io_in_bits_task_channel),
    .io_in_bits_task_txChannel(io_in_bits_task_txChannel),
    .io_in_bits_task_set(io_in_bits_task_set),
    .io_in_bits_task_tag(io_in_bits_task_tag),
    .io_in_bits_task_off(io_in_bits_task_off),
    .io_in_bits_task_alias(io_in_bits_task_alias),
    .io_in_bits_task_vaddr(io_in_bits_task_vaddr),
    .io_in_bits_task_isKeyword(io_in_bits_task_isKeyword),
    .io_in_bits_task_opcode(io_in_bits_task_opcode),
    .io_in_bits_task_param(io_in_bits_task_param),
    .io_in_bits_task_size(io_in_bits_task_size),
    .io_in_bits_task_sourceId(io_in_bits_task_sourceId),
    .io_in_bits_task_bufIdx(io_in_bits_task_bufIdx),
    .io_in_bits_task_needProbeAckData(io_in_bits_task_needProbeAckData),
    .io_in_bits_task_denied(io_in_bits_task_denied),
    .io_in_bits_task_corrupt(io_in_bits_task_corrupt),
    .io_in_bits_task_mshrTask(io_in_bits_task_mshrTask),
    .io_in_bits_task_mshrId(io_in_bits_task_mshrId),
    .io_in_bits_task_aliasTask(io_in_bits_task_aliasTask),
    .io_in_bits_task_useProbeData(io_in_bits_task_useProbeData),
    .io_in_bits_task_mshrRetry(io_in_bits_task_mshrRetry),
    .io_in_bits_task_readProbeDataDown(io_in_bits_task_readProbeDataDown),
    .io_in_bits_task_fromL2pft(io_in_bits_task_fromL2pft),
    .io_in_bits_task_needHint(io_in_bits_task_needHint),
    .io_in_bits_task_dirty(io_in_bits_task_dirty),
    .io_in_bits_task_way(io_in_bits_task_way),
    .io_in_bits_task_meta_dirty(io_in_bits_task_meta_dirty),
    .io_in_bits_task_meta_state(io_in_bits_task_meta_state),
    .io_in_bits_task_meta_clients(io_in_bits_task_meta_clients),
    .io_in_bits_task_meta_alias(io_in_bits_task_meta_alias),
    .io_in_bits_task_meta_prefetch(io_in_bits_task_meta_prefetch),
    .io_in_bits_task_meta_prefetchSrc(io_in_bits_task_meta_prefetchSrc),
    .io_in_bits_task_meta_accessed(io_in_bits_task_meta_accessed),
    .io_in_bits_task_meta_tagErr(io_in_bits_task_meta_tagErr),
    .io_in_bits_task_meta_dataErr(io_in_bits_task_meta_dataErr),
    .io_in_bits_task_metaWen(io_in_bits_task_metaWen),
    .io_in_bits_task_tagWen(io_in_bits_task_tagWen),
    .io_in_bits_task_dsWen(io_in_bits_task_dsWen),
    .io_in_bits_task_wayMask(io_in_bits_task_wayMask),
    .io_in_bits_task_replTask(io_in_bits_task_replTask),
    .io_in_bits_task_cmoTask(io_in_bits_task_cmoTask),
    .io_in_bits_task_cmoAll(io_in_bits_task_cmoAll),
    .io_in_bits_task_reqSource(io_in_bits_task_reqSource),
    .io_in_bits_task_mergeA(io_in_bits_task_mergeA),
    .io_in_bits_task_aMergeTask_off(io_in_bits_task_aMergeTask_off),
    .io_in_bits_task_aMergeTask_alias(io_in_bits_task_aMergeTask_alias),
    .io_in_bits_task_aMergeTask_vaddr(io_in_bits_task_aMergeTask_vaddr),
    .io_in_bits_task_aMergeTask_isKeyword(io_in_bits_task_aMergeTask_isKeyword),
    .io_in_bits_task_aMergeTask_opcode(io_in_bits_task_aMergeTask_opcode),
    .io_in_bits_task_aMergeTask_param(io_in_bits_task_aMergeTask_param),
    .io_in_bits_task_aMergeTask_sourceId(io_in_bits_task_aMergeTask_sourceId),
    .io_in_bits_task_aMergeTask_meta_dirty(io_in_bits_task_aMergeTask_meta_dirty),
    .io_in_bits_task_aMergeTask_meta_state(io_in_bits_task_aMergeTask_meta_state),
    .io_in_bits_task_aMergeTask_meta_clients(io_in_bits_task_aMergeTask_meta_clients),
    .io_in_bits_task_aMergeTask_meta_alias(io_in_bits_task_aMergeTask_meta_alias),
    .io_in_bits_task_aMergeTask_meta_prefetch(io_in_bits_task_aMergeTask_meta_prefetch),
    .io_in_bits_task_aMergeTask_meta_prefetchSrc(io_in_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_bits_task_aMergeTask_meta_accessed(io_in_bits_task_aMergeTask_meta_accessed),
    .io_in_bits_task_aMergeTask_meta_tagErr(io_in_bits_task_aMergeTask_meta_tagErr),
    .io_in_bits_task_aMergeTask_meta_dataErr(io_in_bits_task_aMergeTask_meta_dataErr),
    .io_in_bits_task_snpHitRelease(io_in_bits_task_snpHitRelease),
    .io_in_bits_task_snpHitReleaseToInval(io_in_bits_task_snpHitReleaseToInval),
    .io_in_bits_task_snpHitReleaseToClean(io_in_bits_task_snpHitReleaseToClean),
    .io_in_bits_task_snpHitReleaseWithData(io_in_bits_task_snpHitReleaseWithData),
    .io_in_bits_task_snpHitReleaseIdx(io_in_bits_task_snpHitReleaseIdx),
    .io_in_bits_task_snpHitReleaseMeta_dirty(io_in_bits_task_snpHitReleaseMeta_dirty),
    .io_in_bits_task_snpHitReleaseMeta_state(io_in_bits_task_snpHitReleaseMeta_state),
    .io_in_bits_task_snpHitReleaseMeta_clients(io_in_bits_task_snpHitReleaseMeta_clients),
    .io_in_bits_task_snpHitReleaseMeta_alias(io_in_bits_task_snpHitReleaseMeta_alias),
    .io_in_bits_task_snpHitReleaseMeta_prefetch(io_in_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_bits_task_snpHitReleaseMeta_prefetchSrc(io_in_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_bits_task_snpHitReleaseMeta_accessed(io_in_bits_task_snpHitReleaseMeta_accessed),
    .io_in_bits_task_snpHitReleaseMeta_tagErr(io_in_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_bits_task_snpHitReleaseMeta_dataErr(io_in_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_bits_task_tgtID(io_in_bits_task_tgtID),
    .io_in_bits_task_srcID(io_in_bits_task_srcID),
    .io_in_bits_task_txnID(io_in_bits_task_txnID),
    .io_in_bits_task_homeNID(io_in_bits_task_homeNID),
    .io_in_bits_task_dbID(io_in_bits_task_dbID),
    .io_in_bits_task_fwdNID(io_in_bits_task_fwdNID),
    .io_in_bits_task_fwdTxnID(io_in_bits_task_fwdTxnID),
    .io_in_bits_task_chiOpcode(io_in_bits_task_chiOpcode),
    .io_in_bits_task_resp(io_in_bits_task_resp),
    .io_in_bits_task_fwdState(io_in_bits_task_fwdState),
    .io_in_bits_task_pCrdType(io_in_bits_task_pCrdType),
    .io_in_bits_task_retToSrc(io_in_bits_task_retToSrc),
    .io_in_bits_task_likelyshared(io_in_bits_task_likelyshared),
    .io_in_bits_task_expCompAck(io_in_bits_task_expCompAck),
    .io_in_bits_task_allowRetry(io_in_bits_task_allowRetry),
    .io_in_bits_task_memAttr_allocate(io_in_bits_task_memAttr_allocate),
    .io_in_bits_task_memAttr_cacheable(io_in_bits_task_memAttr_cacheable),
    .io_in_bits_task_memAttr_device(io_in_bits_task_memAttr_device),
    .io_in_bits_task_memAttr_ewa(io_in_bits_task_memAttr_ewa),
    .io_in_bits_task_traceTag(io_in_bits_task_traceTag),
    .io_in_bits_task_dataCheckErr(io_in_bits_task_dataCheckErr),
    .io_in_bits_data_data(io_in_bits_data_data),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_homeNID(g_io_out_bits_homeNID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_respErr(g_io_out_bits_respErr),
    .io_out_bits_resp(g_io_out_bits_resp),
    .io_out_bits_dataSource(g_io_out_bits_dataSource),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_ccID(g_io_out_bits_ccID),
    .io_out_bits_dataID(g_io_out_bits_dataID),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_out_bits_be(g_io_out_bits_be),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_dataCheck(g_io_out_bits_dataCheck),
    .io_out_bits_poison(g_io_out_bits_poison),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel(io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel(io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask(io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel(io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel(io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask(io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel(io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel(io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask(io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel(io_pipeStatusVec_4_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel(io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask(io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance(g_io_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance(g_io_toReqArb_blockSinkBReqEntrance)
  );
  TXDAT_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_task_channel(io_in_bits_task_channel),
    .io_in_bits_task_txChannel(io_in_bits_task_txChannel),
    .io_in_bits_task_set(io_in_bits_task_set),
    .io_in_bits_task_tag(io_in_bits_task_tag),
    .io_in_bits_task_off(io_in_bits_task_off),
    .io_in_bits_task_alias(io_in_bits_task_alias),
    .io_in_bits_task_vaddr(io_in_bits_task_vaddr),
    .io_in_bits_task_isKeyword(io_in_bits_task_isKeyword),
    .io_in_bits_task_opcode(io_in_bits_task_opcode),
    .io_in_bits_task_param(io_in_bits_task_param),
    .io_in_bits_task_size(io_in_bits_task_size),
    .io_in_bits_task_sourceId(io_in_bits_task_sourceId),
    .io_in_bits_task_bufIdx(io_in_bits_task_bufIdx),
    .io_in_bits_task_needProbeAckData(io_in_bits_task_needProbeAckData),
    .io_in_bits_task_denied(io_in_bits_task_denied),
    .io_in_bits_task_corrupt(io_in_bits_task_corrupt),
    .io_in_bits_task_mshrTask(io_in_bits_task_mshrTask),
    .io_in_bits_task_mshrId(io_in_bits_task_mshrId),
    .io_in_bits_task_aliasTask(io_in_bits_task_aliasTask),
    .io_in_bits_task_useProbeData(io_in_bits_task_useProbeData),
    .io_in_bits_task_mshrRetry(io_in_bits_task_mshrRetry),
    .io_in_bits_task_readProbeDataDown(io_in_bits_task_readProbeDataDown),
    .io_in_bits_task_fromL2pft(io_in_bits_task_fromL2pft),
    .io_in_bits_task_needHint(io_in_bits_task_needHint),
    .io_in_bits_task_dirty(io_in_bits_task_dirty),
    .io_in_bits_task_way(io_in_bits_task_way),
    .io_in_bits_task_meta_dirty(io_in_bits_task_meta_dirty),
    .io_in_bits_task_meta_state(io_in_bits_task_meta_state),
    .io_in_bits_task_meta_clients(io_in_bits_task_meta_clients),
    .io_in_bits_task_meta_alias(io_in_bits_task_meta_alias),
    .io_in_bits_task_meta_prefetch(io_in_bits_task_meta_prefetch),
    .io_in_bits_task_meta_prefetchSrc(io_in_bits_task_meta_prefetchSrc),
    .io_in_bits_task_meta_accessed(io_in_bits_task_meta_accessed),
    .io_in_bits_task_meta_tagErr(io_in_bits_task_meta_tagErr),
    .io_in_bits_task_meta_dataErr(io_in_bits_task_meta_dataErr),
    .io_in_bits_task_metaWen(io_in_bits_task_metaWen),
    .io_in_bits_task_tagWen(io_in_bits_task_tagWen),
    .io_in_bits_task_dsWen(io_in_bits_task_dsWen),
    .io_in_bits_task_wayMask(io_in_bits_task_wayMask),
    .io_in_bits_task_replTask(io_in_bits_task_replTask),
    .io_in_bits_task_cmoTask(io_in_bits_task_cmoTask),
    .io_in_bits_task_cmoAll(io_in_bits_task_cmoAll),
    .io_in_bits_task_reqSource(io_in_bits_task_reqSource),
    .io_in_bits_task_mergeA(io_in_bits_task_mergeA),
    .io_in_bits_task_aMergeTask_off(io_in_bits_task_aMergeTask_off),
    .io_in_bits_task_aMergeTask_alias(io_in_bits_task_aMergeTask_alias),
    .io_in_bits_task_aMergeTask_vaddr(io_in_bits_task_aMergeTask_vaddr),
    .io_in_bits_task_aMergeTask_isKeyword(io_in_bits_task_aMergeTask_isKeyword),
    .io_in_bits_task_aMergeTask_opcode(io_in_bits_task_aMergeTask_opcode),
    .io_in_bits_task_aMergeTask_param(io_in_bits_task_aMergeTask_param),
    .io_in_bits_task_aMergeTask_sourceId(io_in_bits_task_aMergeTask_sourceId),
    .io_in_bits_task_aMergeTask_meta_dirty(io_in_bits_task_aMergeTask_meta_dirty),
    .io_in_bits_task_aMergeTask_meta_state(io_in_bits_task_aMergeTask_meta_state),
    .io_in_bits_task_aMergeTask_meta_clients(io_in_bits_task_aMergeTask_meta_clients),
    .io_in_bits_task_aMergeTask_meta_alias(io_in_bits_task_aMergeTask_meta_alias),
    .io_in_bits_task_aMergeTask_meta_prefetch(io_in_bits_task_aMergeTask_meta_prefetch),
    .io_in_bits_task_aMergeTask_meta_prefetchSrc(io_in_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_bits_task_aMergeTask_meta_accessed(io_in_bits_task_aMergeTask_meta_accessed),
    .io_in_bits_task_aMergeTask_meta_tagErr(io_in_bits_task_aMergeTask_meta_tagErr),
    .io_in_bits_task_aMergeTask_meta_dataErr(io_in_bits_task_aMergeTask_meta_dataErr),
    .io_in_bits_task_snpHitRelease(io_in_bits_task_snpHitRelease),
    .io_in_bits_task_snpHitReleaseToInval(io_in_bits_task_snpHitReleaseToInval),
    .io_in_bits_task_snpHitReleaseToClean(io_in_bits_task_snpHitReleaseToClean),
    .io_in_bits_task_snpHitReleaseWithData(io_in_bits_task_snpHitReleaseWithData),
    .io_in_bits_task_snpHitReleaseIdx(io_in_bits_task_snpHitReleaseIdx),
    .io_in_bits_task_snpHitReleaseMeta_dirty(io_in_bits_task_snpHitReleaseMeta_dirty),
    .io_in_bits_task_snpHitReleaseMeta_state(io_in_bits_task_snpHitReleaseMeta_state),
    .io_in_bits_task_snpHitReleaseMeta_clients(io_in_bits_task_snpHitReleaseMeta_clients),
    .io_in_bits_task_snpHitReleaseMeta_alias(io_in_bits_task_snpHitReleaseMeta_alias),
    .io_in_bits_task_snpHitReleaseMeta_prefetch(io_in_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_bits_task_snpHitReleaseMeta_prefetchSrc(io_in_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_bits_task_snpHitReleaseMeta_accessed(io_in_bits_task_snpHitReleaseMeta_accessed),
    .io_in_bits_task_snpHitReleaseMeta_tagErr(io_in_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_bits_task_snpHitReleaseMeta_dataErr(io_in_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_bits_task_tgtID(io_in_bits_task_tgtID),
    .io_in_bits_task_srcID(io_in_bits_task_srcID),
    .io_in_bits_task_txnID(io_in_bits_task_txnID),
    .io_in_bits_task_homeNID(io_in_bits_task_homeNID),
    .io_in_bits_task_dbID(io_in_bits_task_dbID),
    .io_in_bits_task_fwdNID(io_in_bits_task_fwdNID),
    .io_in_bits_task_fwdTxnID(io_in_bits_task_fwdTxnID),
    .io_in_bits_task_chiOpcode(io_in_bits_task_chiOpcode),
    .io_in_bits_task_resp(io_in_bits_task_resp),
    .io_in_bits_task_fwdState(io_in_bits_task_fwdState),
    .io_in_bits_task_pCrdType(io_in_bits_task_pCrdType),
    .io_in_bits_task_retToSrc(io_in_bits_task_retToSrc),
    .io_in_bits_task_likelyshared(io_in_bits_task_likelyshared),
    .io_in_bits_task_expCompAck(io_in_bits_task_expCompAck),
    .io_in_bits_task_allowRetry(io_in_bits_task_allowRetry),
    .io_in_bits_task_memAttr_allocate(io_in_bits_task_memAttr_allocate),
    .io_in_bits_task_memAttr_cacheable(io_in_bits_task_memAttr_cacheable),
    .io_in_bits_task_memAttr_device(io_in_bits_task_memAttr_device),
    .io_in_bits_task_memAttr_ewa(io_in_bits_task_memAttr_ewa),
    .io_in_bits_task_traceTag(io_in_bits_task_traceTag),
    .io_in_bits_task_dataCheckErr(io_in_bits_task_dataCheckErr),
    .io_in_bits_data_data(io_in_bits_data_data),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_homeNID(i_io_out_bits_homeNID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_respErr(i_io_out_bits_respErr),
    .io_out_bits_resp(i_io_out_bits_resp),
    .io_out_bits_dataSource(i_io_out_bits_dataSource),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_ccID(i_io_out_bits_ccID),
    .io_out_bits_dataID(i_io_out_bits_dataID),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_out_bits_be(i_io_out_bits_be),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_dataCheck(i_io_out_bits_dataCheck),
    .io_out_bits_poison(i_io_out_bits_poison),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel(io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel(io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask(io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel(io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel(io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask(io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel(io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel(io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask(io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel(io_pipeStatusVec_4_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel(io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask(io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance(i_io_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance(i_io_toReqArb_blockSinkBReqEntrance)
  );

  task automatic drive_random();
    io_in_valid = ($urandom_range(0,1) == 0);
    io_in_bits_task_channel = $urandom;
    io_in_bits_task_txChannel = $urandom;
    io_in_bits_task_set = $urandom;
    io_in_bits_task_tag = $urandom;
    io_in_bits_task_off = $urandom;
    io_in_bits_task_alias = $urandom;
    io_in_bits_task_vaddr = {$urandom, $urandom};
    io_in_bits_task_isKeyword = $urandom;
    io_in_bits_task_opcode = $urandom;
    io_in_bits_task_param = $urandom;
    io_in_bits_task_size = $urandom;
    io_in_bits_task_sourceId = $urandom;
    io_in_bits_task_bufIdx = $urandom;
    io_in_bits_task_needProbeAckData = $urandom;
    io_in_bits_task_denied = $urandom;
    io_in_bits_task_corrupt = $urandom;
    io_in_bits_task_mshrTask = $urandom;
    io_in_bits_task_mshrId = $urandom;
    io_in_bits_task_aliasTask = $urandom;
    io_in_bits_task_useProbeData = $urandom;
    io_in_bits_task_mshrRetry = $urandom;
    io_in_bits_task_readProbeDataDown = $urandom;
    io_in_bits_task_fromL2pft = $urandom;
    io_in_bits_task_needHint = $urandom;
    io_in_bits_task_dirty = $urandom;
    io_in_bits_task_way = $urandom;
    io_in_bits_task_meta_dirty = $urandom;
    io_in_bits_task_meta_state = $urandom;
    io_in_bits_task_meta_clients = $urandom;
    io_in_bits_task_meta_alias = $urandom;
    io_in_bits_task_meta_prefetch = $urandom;
    io_in_bits_task_meta_prefetchSrc = $urandom;
    io_in_bits_task_meta_accessed = $urandom;
    io_in_bits_task_meta_tagErr = $urandom;
    io_in_bits_task_meta_dataErr = $urandom;
    io_in_bits_task_metaWen = $urandom;
    io_in_bits_task_tagWen = $urandom;
    io_in_bits_task_dsWen = $urandom;
    io_in_bits_task_wayMask = $urandom;
    io_in_bits_task_replTask = $urandom;
    io_in_bits_task_cmoTask = $urandom;
    io_in_bits_task_cmoAll = $urandom;
    io_in_bits_task_reqSource = $urandom;
    io_in_bits_task_mergeA = $urandom;
    io_in_bits_task_aMergeTask_off = $urandom;
    io_in_bits_task_aMergeTask_alias = $urandom;
    io_in_bits_task_aMergeTask_vaddr = {$urandom, $urandom};
    io_in_bits_task_aMergeTask_isKeyword = $urandom;
    io_in_bits_task_aMergeTask_opcode = $urandom;
    io_in_bits_task_aMergeTask_param = $urandom;
    io_in_bits_task_aMergeTask_sourceId = $urandom;
    io_in_bits_task_aMergeTask_meta_dirty = $urandom;
    io_in_bits_task_aMergeTask_meta_state = $urandom;
    io_in_bits_task_aMergeTask_meta_clients = $urandom;
    io_in_bits_task_aMergeTask_meta_alias = $urandom;
    io_in_bits_task_aMergeTask_meta_prefetch = $urandom;
    io_in_bits_task_aMergeTask_meta_prefetchSrc = $urandom;
    io_in_bits_task_aMergeTask_meta_accessed = $urandom;
    io_in_bits_task_aMergeTask_meta_tagErr = $urandom;
    io_in_bits_task_aMergeTask_meta_dataErr = $urandom;
    io_in_bits_task_snpHitRelease = $urandom;
    io_in_bits_task_snpHitReleaseToInval = $urandom;
    io_in_bits_task_snpHitReleaseToClean = $urandom;
    io_in_bits_task_snpHitReleaseWithData = $urandom;
    io_in_bits_task_snpHitReleaseIdx = $urandom;
    io_in_bits_task_snpHitReleaseMeta_dirty = $urandom;
    io_in_bits_task_snpHitReleaseMeta_state = $urandom;
    io_in_bits_task_snpHitReleaseMeta_clients = $urandom;
    io_in_bits_task_snpHitReleaseMeta_alias = $urandom;
    io_in_bits_task_snpHitReleaseMeta_prefetch = $urandom;
    io_in_bits_task_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_in_bits_task_snpHitReleaseMeta_accessed = $urandom;
    io_in_bits_task_snpHitReleaseMeta_tagErr = $urandom;
    io_in_bits_task_snpHitReleaseMeta_dataErr = $urandom;
    io_in_bits_task_tgtID = $urandom;
    io_in_bits_task_srcID = $urandom;
    io_in_bits_task_txnID = $urandom;
    io_in_bits_task_homeNID = $urandom;
    io_in_bits_task_dbID = $urandom;
    io_in_bits_task_fwdNID = $urandom;
    io_in_bits_task_fwdTxnID = $urandom;
    io_in_bits_task_chiOpcode = $urandom;
    io_in_bits_task_resp = $urandom;
    io_in_bits_task_fwdState = $urandom;
    io_in_bits_task_pCrdType = $urandom;
    io_in_bits_task_retToSrc = $urandom;
    io_in_bits_task_likelyshared = $urandom;
    io_in_bits_task_expCompAck = $urandom;
    io_in_bits_task_allowRetry = $urandom;
    io_in_bits_task_memAttr_allocate = $urandom;
    io_in_bits_task_memAttr_cacheable = $urandom;
    io_in_bits_task_memAttr_device = $urandom;
    io_in_bits_task_memAttr_ewa = $urandom;
    io_in_bits_task_traceTag = $urandom;
    io_in_bits_task_dataCheckErr = $urandom;
    io_in_bits_data_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_out_ready = ($urandom_range(0,3) != 0);
    io_pipeStatusVec_1_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_1_bits_channel = $urandom;
    io_pipeStatusVec_1_bits_txChannel = $urandom;
    io_pipeStatusVec_1_bits_mshrTask = $urandom;
    io_pipeStatusVec_2_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_2_bits_channel = $urandom;
    io_pipeStatusVec_2_bits_txChannel = $urandom;
    io_pipeStatusVec_2_bits_mshrTask = $urandom;
    io_pipeStatusVec_3_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_3_bits_channel = $urandom;
    io_pipeStatusVec_3_bits_txChannel = $urandom;
    io_pipeStatusVec_3_bits_mshrTask = $urandom;
    io_pipeStatusVec_4_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_4_bits_channel = $urandom;
    io_pipeStatusVec_4_bits_txChannel = $urandom;
    io_pipeStatusVec_4_bits_mshrTask = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_in_ready)
    `CHK(io_out_valid)
    `CHK(io_out_bits_tgtID)
    `CHK(io_out_bits_txnID)
    `CHK(io_out_bits_homeNID)
    `CHK(io_out_bits_opcode)
    `CHK(io_out_bits_respErr)
    `CHK(io_out_bits_resp)
    `CHK(io_out_bits_dataSource)
    `CHK(io_out_bits_dbID)
    `CHK(io_out_bits_ccID)
    `CHK(io_out_bits_dataID)
    `CHK(io_out_bits_traceTag)
    `CHK(io_out_bits_be)
    `CHK(io_out_bits_data)
    `CHK(io_out_bits_dataCheck)
    `CHK(io_out_bits_poison)
    `CHK(io_toReqArb_blockMSHRReqEntrance)
    `CHK(io_toReqArb_blockSinkBReqEntrance)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_valid = '0;
    io_in_bits_task_channel = '0;
    io_in_bits_task_txChannel = '0;
    io_in_bits_task_set = '0;
    io_in_bits_task_tag = '0;
    io_in_bits_task_off = '0;
    io_in_bits_task_alias = '0;
    io_in_bits_task_vaddr = '0;
    io_in_bits_task_isKeyword = '0;
    io_in_bits_task_opcode = '0;
    io_in_bits_task_param = '0;
    io_in_bits_task_size = '0;
    io_in_bits_task_sourceId = '0;
    io_in_bits_task_bufIdx = '0;
    io_in_bits_task_needProbeAckData = '0;
    io_in_bits_task_denied = '0;
    io_in_bits_task_corrupt = '0;
    io_in_bits_task_mshrTask = '0;
    io_in_bits_task_mshrId = '0;
    io_in_bits_task_aliasTask = '0;
    io_in_bits_task_useProbeData = '0;
    io_in_bits_task_mshrRetry = '0;
    io_in_bits_task_readProbeDataDown = '0;
    io_in_bits_task_fromL2pft = '0;
    io_in_bits_task_needHint = '0;
    io_in_bits_task_dirty = '0;
    io_in_bits_task_way = '0;
    io_in_bits_task_meta_dirty = '0;
    io_in_bits_task_meta_state = '0;
    io_in_bits_task_meta_clients = '0;
    io_in_bits_task_meta_alias = '0;
    io_in_bits_task_meta_prefetch = '0;
    io_in_bits_task_meta_prefetchSrc = '0;
    io_in_bits_task_meta_accessed = '0;
    io_in_bits_task_meta_tagErr = '0;
    io_in_bits_task_meta_dataErr = '0;
    io_in_bits_task_metaWen = '0;
    io_in_bits_task_tagWen = '0;
    io_in_bits_task_dsWen = '0;
    io_in_bits_task_wayMask = '0;
    io_in_bits_task_replTask = '0;
    io_in_bits_task_cmoTask = '0;
    io_in_bits_task_cmoAll = '0;
    io_in_bits_task_reqSource = '0;
    io_in_bits_task_mergeA = '0;
    io_in_bits_task_aMergeTask_off = '0;
    io_in_bits_task_aMergeTask_alias = '0;
    io_in_bits_task_aMergeTask_vaddr = '0;
    io_in_bits_task_aMergeTask_isKeyword = '0;
    io_in_bits_task_aMergeTask_opcode = '0;
    io_in_bits_task_aMergeTask_param = '0;
    io_in_bits_task_aMergeTask_sourceId = '0;
    io_in_bits_task_aMergeTask_meta_dirty = '0;
    io_in_bits_task_aMergeTask_meta_state = '0;
    io_in_bits_task_aMergeTask_meta_clients = '0;
    io_in_bits_task_aMergeTask_meta_alias = '0;
    io_in_bits_task_aMergeTask_meta_prefetch = '0;
    io_in_bits_task_aMergeTask_meta_prefetchSrc = '0;
    io_in_bits_task_aMergeTask_meta_accessed = '0;
    io_in_bits_task_aMergeTask_meta_tagErr = '0;
    io_in_bits_task_aMergeTask_meta_dataErr = '0;
    io_in_bits_task_snpHitRelease = '0;
    io_in_bits_task_snpHitReleaseToInval = '0;
    io_in_bits_task_snpHitReleaseToClean = '0;
    io_in_bits_task_snpHitReleaseWithData = '0;
    io_in_bits_task_snpHitReleaseIdx = '0;
    io_in_bits_task_snpHitReleaseMeta_dirty = '0;
    io_in_bits_task_snpHitReleaseMeta_state = '0;
    io_in_bits_task_snpHitReleaseMeta_clients = '0;
    io_in_bits_task_snpHitReleaseMeta_alias = '0;
    io_in_bits_task_snpHitReleaseMeta_prefetch = '0;
    io_in_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_bits_task_snpHitReleaseMeta_accessed = '0;
    io_in_bits_task_snpHitReleaseMeta_tagErr = '0;
    io_in_bits_task_snpHitReleaseMeta_dataErr = '0;
    io_in_bits_task_tgtID = '0;
    io_in_bits_task_srcID = '0;
    io_in_bits_task_txnID = '0;
    io_in_bits_task_homeNID = '0;
    io_in_bits_task_dbID = '0;
    io_in_bits_task_fwdNID = '0;
    io_in_bits_task_fwdTxnID = '0;
    io_in_bits_task_chiOpcode = '0;
    io_in_bits_task_resp = '0;
    io_in_bits_task_fwdState = '0;
    io_in_bits_task_pCrdType = '0;
    io_in_bits_task_retToSrc = '0;
    io_in_bits_task_likelyshared = '0;
    io_in_bits_task_expCompAck = '0;
    io_in_bits_task_allowRetry = '0;
    io_in_bits_task_memAttr_allocate = '0;
    io_in_bits_task_memAttr_cacheable = '0;
    io_in_bits_task_memAttr_device = '0;
    io_in_bits_task_memAttr_ewa = '0;
    io_in_bits_task_traceTag = '0;
    io_in_bits_task_dataCheckErr = '0;
    io_in_bits_data_data = '0;
    io_out_ready = '0;
    io_pipeStatusVec_1_valid = '0;
    io_pipeStatusVec_1_bits_channel = '0;
    io_pipeStatusVec_1_bits_txChannel = '0;
    io_pipeStatusVec_1_bits_mshrTask = '0;
    io_pipeStatusVec_2_valid = '0;
    io_pipeStatusVec_2_bits_channel = '0;
    io_pipeStatusVec_2_bits_txChannel = '0;
    io_pipeStatusVec_2_bits_mshrTask = '0;
    io_pipeStatusVec_3_valid = '0;
    io_pipeStatusVec_3_bits_channel = '0;
    io_pipeStatusVec_3_bits_txChannel = '0;
    io_pipeStatusVec_3_bits_mshrTask = '0;
    io_pipeStatusVec_4_valid = '0;
    io_pipeStatusVec_4_bits_channel = '0;
    io_pipeStatusVec_4_bits_txChannel = '0;
    io_pipeStatusVec_4_bits_mshrTask = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("TXDAT checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
