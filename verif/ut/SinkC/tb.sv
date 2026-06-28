// 自动生成 scripts/gen_sinkc.py —— 勿手改
// SinkC 双例化逐拍比对: golden SinkC vs 可读重写 SinkC_xs。
// 偏 Release/ProbeAck 与偏小 set/tag 促成缓冲分配与 msInfo 命中。
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
  logic io_c_valid;
  logic [2:0] io_c_bits_opcode;
  logic [2:0] io_c_bits_param;
  logic [2:0] io_c_bits_size;
  logic [6:0] io_c_bits_source;
  logic [47:0] io_c_bits_address;
  logic [255:0] io_c_bits_data;
  logic io_c_bits_corrupt;
  logic io_task_ready;
  logic io_msInfo_0_valid;
  logic [8:0] io_msInfo_0_bits_set;
  logic [30:0] io_msInfo_0_bits_reqTag;
  logic io_msInfo_0_bits_blockRefill;
  logic io_msInfo_1_valid;
  logic [8:0] io_msInfo_1_bits_set;
  logic [30:0] io_msInfo_1_bits_reqTag;
  logic io_msInfo_1_bits_blockRefill;
  logic io_msInfo_2_valid;
  logic [8:0] io_msInfo_2_bits_set;
  logic [30:0] io_msInfo_2_bits_reqTag;
  logic io_msInfo_2_bits_blockRefill;
  logic io_msInfo_3_valid;
  logic [8:0] io_msInfo_3_bits_set;
  logic [30:0] io_msInfo_3_bits_reqTag;
  logic io_msInfo_3_bits_blockRefill;
  logic io_msInfo_4_valid;
  logic [8:0] io_msInfo_4_bits_set;
  logic [30:0] io_msInfo_4_bits_reqTag;
  logic io_msInfo_4_bits_blockRefill;
  logic io_msInfo_5_valid;
  logic [8:0] io_msInfo_5_bits_set;
  logic [30:0] io_msInfo_5_bits_reqTag;
  logic io_msInfo_5_bits_blockRefill;
  logic io_msInfo_6_valid;
  logic [8:0] io_msInfo_6_bits_set;
  logic [30:0] io_msInfo_6_bits_reqTag;
  logic io_msInfo_6_bits_blockRefill;
  logic io_msInfo_7_valid;
  logic [8:0] io_msInfo_7_bits_set;
  logic [30:0] io_msInfo_7_bits_reqTag;
  logic io_msInfo_7_bits_blockRefill;
  logic io_msInfo_8_valid;
  logic [8:0] io_msInfo_8_bits_set;
  logic [30:0] io_msInfo_8_bits_reqTag;
  logic io_msInfo_8_bits_blockRefill;
  logic io_msInfo_9_valid;
  logic [8:0] io_msInfo_9_bits_set;
  logic [30:0] io_msInfo_9_bits_reqTag;
  logic io_msInfo_9_bits_blockRefill;
  logic io_msInfo_10_valid;
  logic [8:0] io_msInfo_10_bits_set;
  logic [30:0] io_msInfo_10_bits_reqTag;
  logic io_msInfo_10_bits_blockRefill;
  logic io_msInfo_11_valid;
  logic [8:0] io_msInfo_11_bits_set;
  logic [30:0] io_msInfo_11_bits_reqTag;
  logic io_msInfo_11_bits_blockRefill;
  logic io_msInfo_12_valid;
  logic [8:0] io_msInfo_12_bits_set;
  logic [30:0] io_msInfo_12_bits_reqTag;
  logic io_msInfo_12_bits_blockRefill;
  logic io_msInfo_13_valid;
  logic [8:0] io_msInfo_13_bits_set;
  logic [30:0] io_msInfo_13_bits_reqTag;
  logic io_msInfo_13_bits_blockRefill;
  logic io_msInfo_14_valid;
  logic [8:0] io_msInfo_14_bits_set;
  logic [30:0] io_msInfo_14_bits_reqTag;
  logic io_msInfo_14_bits_blockRefill;
  logic io_msInfo_15_valid;
  logic [8:0] io_msInfo_15_bits_set;
  logic [30:0] io_msInfo_15_bits_reqTag;
  logic io_msInfo_15_bits_blockRefill;
  wire g_io_c_ready;
  wire i_io_c_ready;
  wire g_io_task_valid;
  wire i_io_task_valid;
  wire [2:0] g_io_task_bits_channel;
  wire [2:0] i_io_task_bits_channel;
  wire [2:0] g_io_task_bits_txChannel;
  wire [2:0] i_io_task_bits_txChannel;
  wire [8:0] g_io_task_bits_set;
  wire [8:0] i_io_task_bits_set;
  wire [30:0] g_io_task_bits_tag;
  wire [30:0] i_io_task_bits_tag;
  wire [5:0] g_io_task_bits_off;
  wire [5:0] i_io_task_bits_off;
  wire [1:0] g_io_task_bits_alias;
  wire [1:0] i_io_task_bits_alias;
  wire [43:0] g_io_task_bits_vaddr;
  wire [43:0] i_io_task_bits_vaddr;
  wire g_io_task_bits_isKeyword;
  wire i_io_task_bits_isKeyword;
  wire [3:0] g_io_task_bits_opcode;
  wire [3:0] i_io_task_bits_opcode;
  wire [2:0] g_io_task_bits_param;
  wire [2:0] i_io_task_bits_param;
  wire [2:0] g_io_task_bits_size;
  wire [2:0] i_io_task_bits_size;
  wire [6:0] g_io_task_bits_sourceId;
  wire [6:0] i_io_task_bits_sourceId;
  wire [1:0] g_io_task_bits_bufIdx;
  wire [1:0] i_io_task_bits_bufIdx;
  wire g_io_task_bits_needProbeAckData;
  wire i_io_task_bits_needProbeAckData;
  wire g_io_task_bits_denied;
  wire i_io_task_bits_denied;
  wire g_io_task_bits_corrupt;
  wire i_io_task_bits_corrupt;
  wire g_io_task_bits_mshrTask;
  wire i_io_task_bits_mshrTask;
  wire [7:0] g_io_task_bits_mshrId;
  wire [7:0] i_io_task_bits_mshrId;
  wire g_io_task_bits_aliasTask;
  wire i_io_task_bits_aliasTask;
  wire g_io_task_bits_useProbeData;
  wire i_io_task_bits_useProbeData;
  wire g_io_task_bits_mshrRetry;
  wire i_io_task_bits_mshrRetry;
  wire g_io_task_bits_readProbeDataDown;
  wire i_io_task_bits_readProbeDataDown;
  wire g_io_task_bits_fromL2pft;
  wire i_io_task_bits_fromL2pft;
  wire g_io_task_bits_needHint;
  wire i_io_task_bits_needHint;
  wire g_io_task_bits_dirty;
  wire i_io_task_bits_dirty;
  wire [2:0] g_io_task_bits_way;
  wire [2:0] i_io_task_bits_way;
  wire g_io_task_bits_meta_dirty;
  wire i_io_task_bits_meta_dirty;
  wire [1:0] g_io_task_bits_meta_state;
  wire [1:0] i_io_task_bits_meta_state;
  wire g_io_task_bits_meta_clients;
  wire i_io_task_bits_meta_clients;
  wire [1:0] g_io_task_bits_meta_alias;
  wire [1:0] i_io_task_bits_meta_alias;
  wire g_io_task_bits_meta_prefetch;
  wire i_io_task_bits_meta_prefetch;
  wire [2:0] g_io_task_bits_meta_prefetchSrc;
  wire [2:0] i_io_task_bits_meta_prefetchSrc;
  wire g_io_task_bits_meta_accessed;
  wire i_io_task_bits_meta_accessed;
  wire g_io_task_bits_meta_tagErr;
  wire i_io_task_bits_meta_tagErr;
  wire g_io_task_bits_meta_dataErr;
  wire i_io_task_bits_meta_dataErr;
  wire g_io_task_bits_metaWen;
  wire i_io_task_bits_metaWen;
  wire g_io_task_bits_tagWen;
  wire i_io_task_bits_tagWen;
  wire g_io_task_bits_dsWen;
  wire i_io_task_bits_dsWen;
  wire [7:0] g_io_task_bits_wayMask;
  wire [7:0] i_io_task_bits_wayMask;
  wire g_io_task_bits_replTask;
  wire i_io_task_bits_replTask;
  wire g_io_task_bits_cmoTask;
  wire i_io_task_bits_cmoTask;
  wire g_io_task_bits_cmoAll;
  wire i_io_task_bits_cmoAll;
  wire [4:0] g_io_task_bits_reqSource;
  wire [4:0] i_io_task_bits_reqSource;
  wire g_io_task_bits_mergeA;
  wire i_io_task_bits_mergeA;
  wire [5:0] g_io_task_bits_aMergeTask_off;
  wire [5:0] i_io_task_bits_aMergeTask_off;
  wire [1:0] g_io_task_bits_aMergeTask_alias;
  wire [1:0] i_io_task_bits_aMergeTask_alias;
  wire [43:0] g_io_task_bits_aMergeTask_vaddr;
  wire [43:0] i_io_task_bits_aMergeTask_vaddr;
  wire g_io_task_bits_aMergeTask_isKeyword;
  wire i_io_task_bits_aMergeTask_isKeyword;
  wire [2:0] g_io_task_bits_aMergeTask_opcode;
  wire [2:0] i_io_task_bits_aMergeTask_opcode;
  wire [2:0] g_io_task_bits_aMergeTask_param;
  wire [2:0] i_io_task_bits_aMergeTask_param;
  wire [6:0] g_io_task_bits_aMergeTask_sourceId;
  wire [6:0] i_io_task_bits_aMergeTask_sourceId;
  wire g_io_task_bits_aMergeTask_meta_dirty;
  wire i_io_task_bits_aMergeTask_meta_dirty;
  wire [1:0] g_io_task_bits_aMergeTask_meta_state;
  wire [1:0] i_io_task_bits_aMergeTask_meta_state;
  wire g_io_task_bits_aMergeTask_meta_clients;
  wire i_io_task_bits_aMergeTask_meta_clients;
  wire [1:0] g_io_task_bits_aMergeTask_meta_alias;
  wire [1:0] i_io_task_bits_aMergeTask_meta_alias;
  wire g_io_task_bits_aMergeTask_meta_prefetch;
  wire i_io_task_bits_aMergeTask_meta_prefetch;
  wire [2:0] g_io_task_bits_aMergeTask_meta_prefetchSrc;
  wire [2:0] i_io_task_bits_aMergeTask_meta_prefetchSrc;
  wire g_io_task_bits_aMergeTask_meta_accessed;
  wire i_io_task_bits_aMergeTask_meta_accessed;
  wire g_io_task_bits_aMergeTask_meta_tagErr;
  wire i_io_task_bits_aMergeTask_meta_tagErr;
  wire g_io_task_bits_aMergeTask_meta_dataErr;
  wire i_io_task_bits_aMergeTask_meta_dataErr;
  wire g_io_task_bits_snpHitRelease;
  wire i_io_task_bits_snpHitRelease;
  wire g_io_task_bits_snpHitReleaseToInval;
  wire i_io_task_bits_snpHitReleaseToInval;
  wire g_io_task_bits_snpHitReleaseToClean;
  wire i_io_task_bits_snpHitReleaseToClean;
  wire g_io_task_bits_snpHitReleaseWithData;
  wire i_io_task_bits_snpHitReleaseWithData;
  wire [7:0] g_io_task_bits_snpHitReleaseIdx;
  wire [7:0] i_io_task_bits_snpHitReleaseIdx;
  wire g_io_task_bits_snpHitReleaseMeta_dirty;
  wire i_io_task_bits_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_task_bits_snpHitReleaseMeta_state;
  wire [1:0] i_io_task_bits_snpHitReleaseMeta_state;
  wire g_io_task_bits_snpHitReleaseMeta_clients;
  wire i_io_task_bits_snpHitReleaseMeta_clients;
  wire [1:0] g_io_task_bits_snpHitReleaseMeta_alias;
  wire [1:0] i_io_task_bits_snpHitReleaseMeta_alias;
  wire g_io_task_bits_snpHitReleaseMeta_prefetch;
  wire i_io_task_bits_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_task_bits_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_task_bits_snpHitReleaseMeta_prefetchSrc;
  wire g_io_task_bits_snpHitReleaseMeta_accessed;
  wire i_io_task_bits_snpHitReleaseMeta_accessed;
  wire g_io_task_bits_snpHitReleaseMeta_tagErr;
  wire i_io_task_bits_snpHitReleaseMeta_tagErr;
  wire g_io_task_bits_snpHitReleaseMeta_dataErr;
  wire i_io_task_bits_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_task_bits_tgtID;
  wire [10:0] i_io_task_bits_tgtID;
  wire [10:0] g_io_task_bits_srcID;
  wire [10:0] i_io_task_bits_srcID;
  wire [11:0] g_io_task_bits_txnID;
  wire [11:0] i_io_task_bits_txnID;
  wire [10:0] g_io_task_bits_homeNID;
  wire [10:0] i_io_task_bits_homeNID;
  wire [11:0] g_io_task_bits_dbID;
  wire [11:0] i_io_task_bits_dbID;
  wire [10:0] g_io_task_bits_fwdNID;
  wire [10:0] i_io_task_bits_fwdNID;
  wire [11:0] g_io_task_bits_fwdTxnID;
  wire [11:0] i_io_task_bits_fwdTxnID;
  wire [6:0] g_io_task_bits_chiOpcode;
  wire [6:0] i_io_task_bits_chiOpcode;
  wire [2:0] g_io_task_bits_resp;
  wire [2:0] i_io_task_bits_resp;
  wire [2:0] g_io_task_bits_fwdState;
  wire [2:0] i_io_task_bits_fwdState;
  wire [3:0] g_io_task_bits_pCrdType;
  wire [3:0] i_io_task_bits_pCrdType;
  wire g_io_task_bits_retToSrc;
  wire i_io_task_bits_retToSrc;
  wire g_io_task_bits_likelyshared;
  wire i_io_task_bits_likelyshared;
  wire g_io_task_bits_expCompAck;
  wire i_io_task_bits_expCompAck;
  wire g_io_task_bits_allowRetry;
  wire i_io_task_bits_allowRetry;
  wire g_io_task_bits_memAttr_allocate;
  wire i_io_task_bits_memAttr_allocate;
  wire g_io_task_bits_memAttr_cacheable;
  wire i_io_task_bits_memAttr_cacheable;
  wire g_io_task_bits_memAttr_device;
  wire i_io_task_bits_memAttr_device;
  wire g_io_task_bits_memAttr_ewa;
  wire i_io_task_bits_memAttr_ewa;
  wire g_io_task_bits_traceTag;
  wire i_io_task_bits_traceTag;
  wire g_io_task_bits_dataCheckErr;
  wire i_io_task_bits_dataCheckErr;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire [8:0] g_io_resp_set;
  wire [8:0] i_io_resp_set;
  wire [30:0] g_io_resp_tag;
  wire [30:0] i_io_resp_tag;
  wire [2:0] g_io_resp_respInfo_opcode;
  wire [2:0] i_io_resp_respInfo_opcode;
  wire [2:0] g_io_resp_respInfo_param;
  wire [2:0] i_io_resp_respInfo_param;
  wire g_io_resp_respInfo_last;
  wire i_io_resp_respInfo_last;
  wire g_io_resp_respInfo_denied;
  wire i_io_resp_respInfo_denied;
  wire g_io_resp_respInfo_corrupt;
  wire i_io_resp_respInfo_corrupt;
  wire g_io_releaseBufWrite_valid;
  wire i_io_releaseBufWrite_valid;
  wire [511:0] g_io_releaseBufWrite_bits_data_data;
  wire [511:0] i_io_releaseBufWrite_bits_data_data;
  wire [255:0] g_io_bufResp_data_0;
  wire [255:0] i_io_bufResp_data_0;
  wire [255:0] g_io_bufResp_data_1;
  wire [255:0] i_io_bufResp_data_1;
  wire g_io_refillBufWrite_valid;
  wire i_io_refillBufWrite_valid;
  wire [7:0] g_io_refillBufWrite_bits_id;
  wire [7:0] i_io_refillBufWrite_bits_id;
  wire [511:0] g_io_refillBufWrite_bits_data_data;
  wire [511:0] i_io_refillBufWrite_bits_data_data;

  SinkC u_g (
    .clock(clock),
    .reset(reset),
    .io_c_ready(g_io_c_ready),
    .io_c_valid(io_c_valid),
    .io_c_bits_opcode(io_c_bits_opcode),
    .io_c_bits_param(io_c_bits_param),
    .io_c_bits_size(io_c_bits_size),
    .io_c_bits_source(io_c_bits_source),
    .io_c_bits_address(io_c_bits_address),
    .io_c_bits_data(io_c_bits_data),
    .io_c_bits_corrupt(io_c_bits_corrupt),
    .io_task_ready(io_task_ready),
    .io_task_valid(g_io_task_valid),
    .io_task_bits_channel(g_io_task_bits_channel),
    .io_task_bits_txChannel(g_io_task_bits_txChannel),
    .io_task_bits_set(g_io_task_bits_set),
    .io_task_bits_tag(g_io_task_bits_tag),
    .io_task_bits_off(g_io_task_bits_off),
    .io_task_bits_alias(g_io_task_bits_alias),
    .io_task_bits_vaddr(g_io_task_bits_vaddr),
    .io_task_bits_isKeyword(g_io_task_bits_isKeyword),
    .io_task_bits_opcode(g_io_task_bits_opcode),
    .io_task_bits_param(g_io_task_bits_param),
    .io_task_bits_size(g_io_task_bits_size),
    .io_task_bits_sourceId(g_io_task_bits_sourceId),
    .io_task_bits_bufIdx(g_io_task_bits_bufIdx),
    .io_task_bits_needProbeAckData(g_io_task_bits_needProbeAckData),
    .io_task_bits_denied(g_io_task_bits_denied),
    .io_task_bits_corrupt(g_io_task_bits_corrupt),
    .io_task_bits_mshrTask(g_io_task_bits_mshrTask),
    .io_task_bits_mshrId(g_io_task_bits_mshrId),
    .io_task_bits_aliasTask(g_io_task_bits_aliasTask),
    .io_task_bits_useProbeData(g_io_task_bits_useProbeData),
    .io_task_bits_mshrRetry(g_io_task_bits_mshrRetry),
    .io_task_bits_readProbeDataDown(g_io_task_bits_readProbeDataDown),
    .io_task_bits_fromL2pft(g_io_task_bits_fromL2pft),
    .io_task_bits_needHint(g_io_task_bits_needHint),
    .io_task_bits_dirty(g_io_task_bits_dirty),
    .io_task_bits_way(g_io_task_bits_way),
    .io_task_bits_meta_dirty(g_io_task_bits_meta_dirty),
    .io_task_bits_meta_state(g_io_task_bits_meta_state),
    .io_task_bits_meta_clients(g_io_task_bits_meta_clients),
    .io_task_bits_meta_alias(g_io_task_bits_meta_alias),
    .io_task_bits_meta_prefetch(g_io_task_bits_meta_prefetch),
    .io_task_bits_meta_prefetchSrc(g_io_task_bits_meta_prefetchSrc),
    .io_task_bits_meta_accessed(g_io_task_bits_meta_accessed),
    .io_task_bits_meta_tagErr(g_io_task_bits_meta_tagErr),
    .io_task_bits_meta_dataErr(g_io_task_bits_meta_dataErr),
    .io_task_bits_metaWen(g_io_task_bits_metaWen),
    .io_task_bits_tagWen(g_io_task_bits_tagWen),
    .io_task_bits_dsWen(g_io_task_bits_dsWen),
    .io_task_bits_wayMask(g_io_task_bits_wayMask),
    .io_task_bits_replTask(g_io_task_bits_replTask),
    .io_task_bits_cmoTask(g_io_task_bits_cmoTask),
    .io_task_bits_cmoAll(g_io_task_bits_cmoAll),
    .io_task_bits_reqSource(g_io_task_bits_reqSource),
    .io_task_bits_mergeA(g_io_task_bits_mergeA),
    .io_task_bits_aMergeTask_off(g_io_task_bits_aMergeTask_off),
    .io_task_bits_aMergeTask_alias(g_io_task_bits_aMergeTask_alias),
    .io_task_bits_aMergeTask_vaddr(g_io_task_bits_aMergeTask_vaddr),
    .io_task_bits_aMergeTask_isKeyword(g_io_task_bits_aMergeTask_isKeyword),
    .io_task_bits_aMergeTask_opcode(g_io_task_bits_aMergeTask_opcode),
    .io_task_bits_aMergeTask_param(g_io_task_bits_aMergeTask_param),
    .io_task_bits_aMergeTask_sourceId(g_io_task_bits_aMergeTask_sourceId),
    .io_task_bits_aMergeTask_meta_dirty(g_io_task_bits_aMergeTask_meta_dirty),
    .io_task_bits_aMergeTask_meta_state(g_io_task_bits_aMergeTask_meta_state),
    .io_task_bits_aMergeTask_meta_clients(g_io_task_bits_aMergeTask_meta_clients),
    .io_task_bits_aMergeTask_meta_alias(g_io_task_bits_aMergeTask_meta_alias),
    .io_task_bits_aMergeTask_meta_prefetch(g_io_task_bits_aMergeTask_meta_prefetch),
    .io_task_bits_aMergeTask_meta_prefetchSrc(g_io_task_bits_aMergeTask_meta_prefetchSrc),
    .io_task_bits_aMergeTask_meta_accessed(g_io_task_bits_aMergeTask_meta_accessed),
    .io_task_bits_aMergeTask_meta_tagErr(g_io_task_bits_aMergeTask_meta_tagErr),
    .io_task_bits_aMergeTask_meta_dataErr(g_io_task_bits_aMergeTask_meta_dataErr),
    .io_task_bits_snpHitRelease(g_io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval(g_io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean(g_io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData(g_io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx(g_io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty(g_io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state(g_io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients(g_io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias(g_io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch(g_io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc(g_io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed(g_io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr(g_io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr(g_io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_tgtID(g_io_task_bits_tgtID),
    .io_task_bits_srcID(g_io_task_bits_srcID),
    .io_task_bits_txnID(g_io_task_bits_txnID),
    .io_task_bits_homeNID(g_io_task_bits_homeNID),
    .io_task_bits_dbID(g_io_task_bits_dbID),
    .io_task_bits_fwdNID(g_io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(g_io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(g_io_task_bits_chiOpcode),
    .io_task_bits_resp(g_io_task_bits_resp),
    .io_task_bits_fwdState(g_io_task_bits_fwdState),
    .io_task_bits_pCrdType(g_io_task_bits_pCrdType),
    .io_task_bits_retToSrc(g_io_task_bits_retToSrc),
    .io_task_bits_likelyshared(g_io_task_bits_likelyshared),
    .io_task_bits_expCompAck(g_io_task_bits_expCompAck),
    .io_task_bits_allowRetry(g_io_task_bits_allowRetry),
    .io_task_bits_memAttr_allocate(g_io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable(g_io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device(g_io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa(g_io_task_bits_memAttr_ewa),
    .io_task_bits_traceTag(g_io_task_bits_traceTag),
    .io_task_bits_dataCheckErr(g_io_task_bits_dataCheckErr),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_set(g_io_resp_set),
    .io_resp_tag(g_io_resp_tag),
    .io_resp_respInfo_opcode(g_io_resp_respInfo_opcode),
    .io_resp_respInfo_param(g_io_resp_respInfo_param),
    .io_resp_respInfo_last(g_io_resp_respInfo_last),
    .io_resp_respInfo_denied(g_io_resp_respInfo_denied),
    .io_resp_respInfo_corrupt(g_io_resp_respInfo_corrupt),
    .io_releaseBufWrite_valid(g_io_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_data_data(g_io_releaseBufWrite_bits_data_data),
    .io_bufResp_data_0(g_io_bufResp_data_0),
    .io_bufResp_data_1(g_io_bufResp_data_1),
    .io_refillBufWrite_valid(g_io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id(g_io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data(g_io_refillBufWrite_bits_data_data),
    .io_msInfo_0_valid(io_msInfo_0_valid),
    .io_msInfo_0_bits_set(io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag(io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_blockRefill(io_msInfo_0_bits_blockRefill),
    .io_msInfo_1_valid(io_msInfo_1_valid),
    .io_msInfo_1_bits_set(io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag(io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_blockRefill(io_msInfo_1_bits_blockRefill),
    .io_msInfo_2_valid(io_msInfo_2_valid),
    .io_msInfo_2_bits_set(io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag(io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_blockRefill(io_msInfo_2_bits_blockRefill),
    .io_msInfo_3_valid(io_msInfo_3_valid),
    .io_msInfo_3_bits_set(io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag(io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_blockRefill(io_msInfo_3_bits_blockRefill),
    .io_msInfo_4_valid(io_msInfo_4_valid),
    .io_msInfo_4_bits_set(io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag(io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_blockRefill(io_msInfo_4_bits_blockRefill),
    .io_msInfo_5_valid(io_msInfo_5_valid),
    .io_msInfo_5_bits_set(io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag(io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_blockRefill(io_msInfo_5_bits_blockRefill),
    .io_msInfo_6_valid(io_msInfo_6_valid),
    .io_msInfo_6_bits_set(io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag(io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_blockRefill(io_msInfo_6_bits_blockRefill),
    .io_msInfo_7_valid(io_msInfo_7_valid),
    .io_msInfo_7_bits_set(io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag(io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_blockRefill(io_msInfo_7_bits_blockRefill),
    .io_msInfo_8_valid(io_msInfo_8_valid),
    .io_msInfo_8_bits_set(io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag(io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_blockRefill(io_msInfo_8_bits_blockRefill),
    .io_msInfo_9_valid(io_msInfo_9_valid),
    .io_msInfo_9_bits_set(io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag(io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_blockRefill(io_msInfo_9_bits_blockRefill),
    .io_msInfo_10_valid(io_msInfo_10_valid),
    .io_msInfo_10_bits_set(io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag(io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_blockRefill(io_msInfo_10_bits_blockRefill),
    .io_msInfo_11_valid(io_msInfo_11_valid),
    .io_msInfo_11_bits_set(io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag(io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_blockRefill(io_msInfo_11_bits_blockRefill),
    .io_msInfo_12_valid(io_msInfo_12_valid),
    .io_msInfo_12_bits_set(io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag(io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_blockRefill(io_msInfo_12_bits_blockRefill),
    .io_msInfo_13_valid(io_msInfo_13_valid),
    .io_msInfo_13_bits_set(io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag(io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_blockRefill(io_msInfo_13_bits_blockRefill),
    .io_msInfo_14_valid(io_msInfo_14_valid),
    .io_msInfo_14_bits_set(io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag(io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_blockRefill(io_msInfo_14_bits_blockRefill),
    .io_msInfo_15_valid(io_msInfo_15_valid),
    .io_msInfo_15_bits_set(io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag(io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_blockRefill(io_msInfo_15_bits_blockRefill)
  );
  SinkC_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_c_ready(i_io_c_ready),
    .io_c_valid(io_c_valid),
    .io_c_bits_opcode(io_c_bits_opcode),
    .io_c_bits_param(io_c_bits_param),
    .io_c_bits_size(io_c_bits_size),
    .io_c_bits_source(io_c_bits_source),
    .io_c_bits_address(io_c_bits_address),
    .io_c_bits_data(io_c_bits_data),
    .io_c_bits_corrupt(io_c_bits_corrupt),
    .io_task_ready(io_task_ready),
    .io_task_valid(i_io_task_valid),
    .io_task_bits_channel(i_io_task_bits_channel),
    .io_task_bits_txChannel(i_io_task_bits_txChannel),
    .io_task_bits_set(i_io_task_bits_set),
    .io_task_bits_tag(i_io_task_bits_tag),
    .io_task_bits_off(i_io_task_bits_off),
    .io_task_bits_alias(i_io_task_bits_alias),
    .io_task_bits_vaddr(i_io_task_bits_vaddr),
    .io_task_bits_isKeyword(i_io_task_bits_isKeyword),
    .io_task_bits_opcode(i_io_task_bits_opcode),
    .io_task_bits_param(i_io_task_bits_param),
    .io_task_bits_size(i_io_task_bits_size),
    .io_task_bits_sourceId(i_io_task_bits_sourceId),
    .io_task_bits_bufIdx(i_io_task_bits_bufIdx),
    .io_task_bits_needProbeAckData(i_io_task_bits_needProbeAckData),
    .io_task_bits_denied(i_io_task_bits_denied),
    .io_task_bits_corrupt(i_io_task_bits_corrupt),
    .io_task_bits_mshrTask(i_io_task_bits_mshrTask),
    .io_task_bits_mshrId(i_io_task_bits_mshrId),
    .io_task_bits_aliasTask(i_io_task_bits_aliasTask),
    .io_task_bits_useProbeData(i_io_task_bits_useProbeData),
    .io_task_bits_mshrRetry(i_io_task_bits_mshrRetry),
    .io_task_bits_readProbeDataDown(i_io_task_bits_readProbeDataDown),
    .io_task_bits_fromL2pft(i_io_task_bits_fromL2pft),
    .io_task_bits_needHint(i_io_task_bits_needHint),
    .io_task_bits_dirty(i_io_task_bits_dirty),
    .io_task_bits_way(i_io_task_bits_way),
    .io_task_bits_meta_dirty(i_io_task_bits_meta_dirty),
    .io_task_bits_meta_state(i_io_task_bits_meta_state),
    .io_task_bits_meta_clients(i_io_task_bits_meta_clients),
    .io_task_bits_meta_alias(i_io_task_bits_meta_alias),
    .io_task_bits_meta_prefetch(i_io_task_bits_meta_prefetch),
    .io_task_bits_meta_prefetchSrc(i_io_task_bits_meta_prefetchSrc),
    .io_task_bits_meta_accessed(i_io_task_bits_meta_accessed),
    .io_task_bits_meta_tagErr(i_io_task_bits_meta_tagErr),
    .io_task_bits_meta_dataErr(i_io_task_bits_meta_dataErr),
    .io_task_bits_metaWen(i_io_task_bits_metaWen),
    .io_task_bits_tagWen(i_io_task_bits_tagWen),
    .io_task_bits_dsWen(i_io_task_bits_dsWen),
    .io_task_bits_wayMask(i_io_task_bits_wayMask),
    .io_task_bits_replTask(i_io_task_bits_replTask),
    .io_task_bits_cmoTask(i_io_task_bits_cmoTask),
    .io_task_bits_cmoAll(i_io_task_bits_cmoAll),
    .io_task_bits_reqSource(i_io_task_bits_reqSource),
    .io_task_bits_mergeA(i_io_task_bits_mergeA),
    .io_task_bits_aMergeTask_off(i_io_task_bits_aMergeTask_off),
    .io_task_bits_aMergeTask_alias(i_io_task_bits_aMergeTask_alias),
    .io_task_bits_aMergeTask_vaddr(i_io_task_bits_aMergeTask_vaddr),
    .io_task_bits_aMergeTask_isKeyword(i_io_task_bits_aMergeTask_isKeyword),
    .io_task_bits_aMergeTask_opcode(i_io_task_bits_aMergeTask_opcode),
    .io_task_bits_aMergeTask_param(i_io_task_bits_aMergeTask_param),
    .io_task_bits_aMergeTask_sourceId(i_io_task_bits_aMergeTask_sourceId),
    .io_task_bits_aMergeTask_meta_dirty(i_io_task_bits_aMergeTask_meta_dirty),
    .io_task_bits_aMergeTask_meta_state(i_io_task_bits_aMergeTask_meta_state),
    .io_task_bits_aMergeTask_meta_clients(i_io_task_bits_aMergeTask_meta_clients),
    .io_task_bits_aMergeTask_meta_alias(i_io_task_bits_aMergeTask_meta_alias),
    .io_task_bits_aMergeTask_meta_prefetch(i_io_task_bits_aMergeTask_meta_prefetch),
    .io_task_bits_aMergeTask_meta_prefetchSrc(i_io_task_bits_aMergeTask_meta_prefetchSrc),
    .io_task_bits_aMergeTask_meta_accessed(i_io_task_bits_aMergeTask_meta_accessed),
    .io_task_bits_aMergeTask_meta_tagErr(i_io_task_bits_aMergeTask_meta_tagErr),
    .io_task_bits_aMergeTask_meta_dataErr(i_io_task_bits_aMergeTask_meta_dataErr),
    .io_task_bits_snpHitRelease(i_io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval(i_io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean(i_io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData(i_io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx(i_io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty(i_io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state(i_io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients(i_io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias(i_io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch(i_io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc(i_io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed(i_io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr(i_io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr(i_io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_tgtID(i_io_task_bits_tgtID),
    .io_task_bits_srcID(i_io_task_bits_srcID),
    .io_task_bits_txnID(i_io_task_bits_txnID),
    .io_task_bits_homeNID(i_io_task_bits_homeNID),
    .io_task_bits_dbID(i_io_task_bits_dbID),
    .io_task_bits_fwdNID(i_io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(i_io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(i_io_task_bits_chiOpcode),
    .io_task_bits_resp(i_io_task_bits_resp),
    .io_task_bits_fwdState(i_io_task_bits_fwdState),
    .io_task_bits_pCrdType(i_io_task_bits_pCrdType),
    .io_task_bits_retToSrc(i_io_task_bits_retToSrc),
    .io_task_bits_likelyshared(i_io_task_bits_likelyshared),
    .io_task_bits_expCompAck(i_io_task_bits_expCompAck),
    .io_task_bits_allowRetry(i_io_task_bits_allowRetry),
    .io_task_bits_memAttr_allocate(i_io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable(i_io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device(i_io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa(i_io_task_bits_memAttr_ewa),
    .io_task_bits_traceTag(i_io_task_bits_traceTag),
    .io_task_bits_dataCheckErr(i_io_task_bits_dataCheckErr),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_set(i_io_resp_set),
    .io_resp_tag(i_io_resp_tag),
    .io_resp_respInfo_opcode(i_io_resp_respInfo_opcode),
    .io_resp_respInfo_param(i_io_resp_respInfo_param),
    .io_resp_respInfo_last(i_io_resp_respInfo_last),
    .io_resp_respInfo_denied(i_io_resp_respInfo_denied),
    .io_resp_respInfo_corrupt(i_io_resp_respInfo_corrupt),
    .io_releaseBufWrite_valid(i_io_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_data_data(i_io_releaseBufWrite_bits_data_data),
    .io_bufResp_data_0(i_io_bufResp_data_0),
    .io_bufResp_data_1(i_io_bufResp_data_1),
    .io_refillBufWrite_valid(i_io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id(i_io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data(i_io_refillBufWrite_bits_data_data),
    .io_msInfo_0_valid(io_msInfo_0_valid),
    .io_msInfo_0_bits_set(io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag(io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_blockRefill(io_msInfo_0_bits_blockRefill),
    .io_msInfo_1_valid(io_msInfo_1_valid),
    .io_msInfo_1_bits_set(io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag(io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_blockRefill(io_msInfo_1_bits_blockRefill),
    .io_msInfo_2_valid(io_msInfo_2_valid),
    .io_msInfo_2_bits_set(io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag(io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_blockRefill(io_msInfo_2_bits_blockRefill),
    .io_msInfo_3_valid(io_msInfo_3_valid),
    .io_msInfo_3_bits_set(io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag(io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_blockRefill(io_msInfo_3_bits_blockRefill),
    .io_msInfo_4_valid(io_msInfo_4_valid),
    .io_msInfo_4_bits_set(io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag(io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_blockRefill(io_msInfo_4_bits_blockRefill),
    .io_msInfo_5_valid(io_msInfo_5_valid),
    .io_msInfo_5_bits_set(io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag(io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_blockRefill(io_msInfo_5_bits_blockRefill),
    .io_msInfo_6_valid(io_msInfo_6_valid),
    .io_msInfo_6_bits_set(io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag(io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_blockRefill(io_msInfo_6_bits_blockRefill),
    .io_msInfo_7_valid(io_msInfo_7_valid),
    .io_msInfo_7_bits_set(io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag(io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_blockRefill(io_msInfo_7_bits_blockRefill),
    .io_msInfo_8_valid(io_msInfo_8_valid),
    .io_msInfo_8_bits_set(io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag(io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_blockRefill(io_msInfo_8_bits_blockRefill),
    .io_msInfo_9_valid(io_msInfo_9_valid),
    .io_msInfo_9_bits_set(io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag(io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_blockRefill(io_msInfo_9_bits_blockRefill),
    .io_msInfo_10_valid(io_msInfo_10_valid),
    .io_msInfo_10_bits_set(io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag(io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_blockRefill(io_msInfo_10_bits_blockRefill),
    .io_msInfo_11_valid(io_msInfo_11_valid),
    .io_msInfo_11_bits_set(io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag(io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_blockRefill(io_msInfo_11_bits_blockRefill),
    .io_msInfo_12_valid(io_msInfo_12_valid),
    .io_msInfo_12_bits_set(io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag(io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_blockRefill(io_msInfo_12_bits_blockRefill),
    .io_msInfo_13_valid(io_msInfo_13_valid),
    .io_msInfo_13_bits_set(io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag(io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_blockRefill(io_msInfo_13_bits_blockRefill),
    .io_msInfo_14_valid(io_msInfo_14_valid),
    .io_msInfo_14_bits_set(io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag(io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_blockRefill(io_msInfo_14_bits_blockRefill),
    .io_msInfo_15_valid(io_msInfo_15_valid),
    .io_msInfo_15_bits_set(io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag(io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_blockRefill(io_msInfo_15_bits_blockRefill)
  );

  task automatic drive_random();
    io_c_valid = ($urandom_range(0,1) == 0);
    io_c_bits_opcode = 3'h4 | $urandom_range(0,3);
    io_c_bits_param = $urandom;
    io_c_bits_size = ($urandom_range(0,1) == 0) ? 3'h6 : $urandom_range(0,6);
    io_c_bits_source = $urandom;
    io_c_bits_address = {31'h0, $urandom_range(0,3), 8'h0, $urandom_range(0,63)};
    io_c_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_c_bits_corrupt = $urandom;
    io_task_ready = ($urandom_range(0,2) != 0);
    io_msInfo_0_valid = ($urandom_range(0,1) == 0);
    io_msInfo_0_bits_set = $urandom_range(0,3);
    io_msInfo_0_bits_reqTag = $urandom_range(0,3);
    io_msInfo_0_bits_blockRefill = $urandom;
    io_msInfo_1_valid = ($urandom_range(0,1) == 0);
    io_msInfo_1_bits_set = $urandom_range(0,3);
    io_msInfo_1_bits_reqTag = $urandom_range(0,3);
    io_msInfo_1_bits_blockRefill = $urandom;
    io_msInfo_2_valid = ($urandom_range(0,1) == 0);
    io_msInfo_2_bits_set = $urandom_range(0,3);
    io_msInfo_2_bits_reqTag = $urandom_range(0,3);
    io_msInfo_2_bits_blockRefill = $urandom;
    io_msInfo_3_valid = ($urandom_range(0,1) == 0);
    io_msInfo_3_bits_set = $urandom_range(0,3);
    io_msInfo_3_bits_reqTag = $urandom_range(0,3);
    io_msInfo_3_bits_blockRefill = $urandom;
    io_msInfo_4_valid = ($urandom_range(0,1) == 0);
    io_msInfo_4_bits_set = $urandom_range(0,3);
    io_msInfo_4_bits_reqTag = $urandom_range(0,3);
    io_msInfo_4_bits_blockRefill = $urandom;
    io_msInfo_5_valid = ($urandom_range(0,1) == 0);
    io_msInfo_5_bits_set = $urandom_range(0,3);
    io_msInfo_5_bits_reqTag = $urandom_range(0,3);
    io_msInfo_5_bits_blockRefill = $urandom;
    io_msInfo_6_valid = ($urandom_range(0,1) == 0);
    io_msInfo_6_bits_set = $urandom_range(0,3);
    io_msInfo_6_bits_reqTag = $urandom_range(0,3);
    io_msInfo_6_bits_blockRefill = $urandom;
    io_msInfo_7_valid = ($urandom_range(0,1) == 0);
    io_msInfo_7_bits_set = $urandom_range(0,3);
    io_msInfo_7_bits_reqTag = $urandom_range(0,3);
    io_msInfo_7_bits_blockRefill = $urandom;
    io_msInfo_8_valid = ($urandom_range(0,1) == 0);
    io_msInfo_8_bits_set = $urandom_range(0,3);
    io_msInfo_8_bits_reqTag = $urandom_range(0,3);
    io_msInfo_8_bits_blockRefill = $urandom;
    io_msInfo_9_valid = ($urandom_range(0,1) == 0);
    io_msInfo_9_bits_set = $urandom_range(0,3);
    io_msInfo_9_bits_reqTag = $urandom_range(0,3);
    io_msInfo_9_bits_blockRefill = $urandom;
    io_msInfo_10_valid = ($urandom_range(0,1) == 0);
    io_msInfo_10_bits_set = $urandom_range(0,3);
    io_msInfo_10_bits_reqTag = $urandom_range(0,3);
    io_msInfo_10_bits_blockRefill = $urandom;
    io_msInfo_11_valid = ($urandom_range(0,1) == 0);
    io_msInfo_11_bits_set = $urandom_range(0,3);
    io_msInfo_11_bits_reqTag = $urandom_range(0,3);
    io_msInfo_11_bits_blockRefill = $urandom;
    io_msInfo_12_valid = ($urandom_range(0,1) == 0);
    io_msInfo_12_bits_set = $urandom_range(0,3);
    io_msInfo_12_bits_reqTag = $urandom_range(0,3);
    io_msInfo_12_bits_blockRefill = $urandom;
    io_msInfo_13_valid = ($urandom_range(0,1) == 0);
    io_msInfo_13_bits_set = $urandom_range(0,3);
    io_msInfo_13_bits_reqTag = $urandom_range(0,3);
    io_msInfo_13_bits_blockRefill = $urandom;
    io_msInfo_14_valid = ($urandom_range(0,1) == 0);
    io_msInfo_14_bits_set = $urandom_range(0,3);
    io_msInfo_14_bits_reqTag = $urandom_range(0,3);
    io_msInfo_14_bits_blockRefill = $urandom;
    io_msInfo_15_valid = ($urandom_range(0,1) == 0);
    io_msInfo_15_bits_set = $urandom_range(0,3);
    io_msInfo_15_bits_reqTag = $urandom_range(0,3);
    io_msInfo_15_bits_blockRefill = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_c_ready)
    `CHK(io_task_valid)
    `CHK(io_task_bits_channel)
    `CHK(io_task_bits_txChannel)
    `CHK(io_task_bits_set)
    `CHK(io_task_bits_tag)
    `CHK(io_task_bits_off)
    `CHK(io_task_bits_alias)
    `CHK(io_task_bits_vaddr)
    `CHK(io_task_bits_isKeyword)
    `CHK(io_task_bits_opcode)
    `CHK(io_task_bits_param)
    `CHK(io_task_bits_size)
    `CHK(io_task_bits_sourceId)
    `CHK(io_task_bits_bufIdx)
    `CHK(io_task_bits_needProbeAckData)
    `CHK(io_task_bits_denied)
    `CHK(io_task_bits_corrupt)
    `CHK(io_task_bits_mshrTask)
    `CHK(io_task_bits_mshrId)
    `CHK(io_task_bits_aliasTask)
    `CHK(io_task_bits_useProbeData)
    `CHK(io_task_bits_mshrRetry)
    `CHK(io_task_bits_readProbeDataDown)
    `CHK(io_task_bits_fromL2pft)
    `CHK(io_task_bits_needHint)
    `CHK(io_task_bits_dirty)
    `CHK(io_task_bits_way)
    `CHK(io_task_bits_meta_dirty)
    `CHK(io_task_bits_meta_state)
    `CHK(io_task_bits_meta_clients)
    `CHK(io_task_bits_meta_alias)
    `CHK(io_task_bits_meta_prefetch)
    `CHK(io_task_bits_meta_prefetchSrc)
    `CHK(io_task_bits_meta_accessed)
    `CHK(io_task_bits_meta_tagErr)
    `CHK(io_task_bits_meta_dataErr)
    `CHK(io_task_bits_metaWen)
    `CHK(io_task_bits_tagWen)
    `CHK(io_task_bits_dsWen)
    `CHK(io_task_bits_wayMask)
    `CHK(io_task_bits_replTask)
    `CHK(io_task_bits_cmoTask)
    `CHK(io_task_bits_cmoAll)
    `CHK(io_task_bits_reqSource)
    `CHK(io_task_bits_mergeA)
    `CHK(io_task_bits_aMergeTask_off)
    `CHK(io_task_bits_aMergeTask_alias)
    `CHK(io_task_bits_aMergeTask_vaddr)
    `CHK(io_task_bits_aMergeTask_isKeyword)
    `CHK(io_task_bits_aMergeTask_opcode)
    `CHK(io_task_bits_aMergeTask_param)
    `CHK(io_task_bits_aMergeTask_sourceId)
    `CHK(io_task_bits_aMergeTask_meta_dirty)
    `CHK(io_task_bits_aMergeTask_meta_state)
    `CHK(io_task_bits_aMergeTask_meta_clients)
    `CHK(io_task_bits_aMergeTask_meta_alias)
    `CHK(io_task_bits_aMergeTask_meta_prefetch)
    `CHK(io_task_bits_aMergeTask_meta_prefetchSrc)
    `CHK(io_task_bits_aMergeTask_meta_accessed)
    `CHK(io_task_bits_aMergeTask_meta_tagErr)
    `CHK(io_task_bits_aMergeTask_meta_dataErr)
    `CHK(io_task_bits_snpHitRelease)
    `CHK(io_task_bits_snpHitReleaseToInval)
    `CHK(io_task_bits_snpHitReleaseToClean)
    `CHK(io_task_bits_snpHitReleaseWithData)
    `CHK(io_task_bits_snpHitReleaseIdx)
    `CHK(io_task_bits_snpHitReleaseMeta_dirty)
    `CHK(io_task_bits_snpHitReleaseMeta_state)
    `CHK(io_task_bits_snpHitReleaseMeta_clients)
    `CHK(io_task_bits_snpHitReleaseMeta_alias)
    `CHK(io_task_bits_snpHitReleaseMeta_prefetch)
    `CHK(io_task_bits_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_task_bits_snpHitReleaseMeta_accessed)
    `CHK(io_task_bits_snpHitReleaseMeta_tagErr)
    `CHK(io_task_bits_snpHitReleaseMeta_dataErr)
    `CHK(io_task_bits_tgtID)
    `CHK(io_task_bits_srcID)
    `CHK(io_task_bits_txnID)
    `CHK(io_task_bits_homeNID)
    `CHK(io_task_bits_dbID)
    `CHK(io_task_bits_fwdNID)
    `CHK(io_task_bits_fwdTxnID)
    `CHK(io_task_bits_chiOpcode)
    `CHK(io_task_bits_resp)
    `CHK(io_task_bits_fwdState)
    `CHK(io_task_bits_pCrdType)
    `CHK(io_task_bits_retToSrc)
    `CHK(io_task_bits_likelyshared)
    `CHK(io_task_bits_expCompAck)
    `CHK(io_task_bits_allowRetry)
    `CHK(io_task_bits_memAttr_allocate)
    `CHK(io_task_bits_memAttr_cacheable)
    `CHK(io_task_bits_memAttr_device)
    `CHK(io_task_bits_memAttr_ewa)
    `CHK(io_task_bits_traceTag)
    `CHK(io_task_bits_dataCheckErr)
    `CHK(io_resp_valid)
    `CHK(io_resp_set)
    `CHK(io_resp_tag)
    `CHK(io_resp_respInfo_opcode)
    `CHK(io_resp_respInfo_param)
    `CHK(io_resp_respInfo_last)
    `CHK(io_resp_respInfo_denied)
    `CHK(io_resp_respInfo_corrupt)
    `CHK(io_releaseBufWrite_valid)
    `CHK(io_releaseBufWrite_bits_data_data)
    `CHK(io_bufResp_data_0)
    `CHK(io_bufResp_data_1)
    `CHK(io_refillBufWrite_valid)
    `CHK(io_refillBufWrite_bits_id)
    `CHK(io_refillBufWrite_bits_data_data)
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
    `IP(dataBuf_0_0, dataBuf[0][0])
    `IP(beatValids_0_0, beatValids[0][0])
    `IP(dataBuf_0_1, dataBuf[0][1])
    `IP(beatValids_0_1, beatValids[0][1])
    `IP(dataBuf_1_0, dataBuf[1][0])
    `IP(beatValids_1_0, beatValids[1][0])
    `IP(dataBuf_1_1, dataBuf[1][1])
    `IP(beatValids_1_1, beatValids[1][1])
    `IP(dataBuf_2_0, dataBuf[2][0])
    `IP(beatValids_2_0, beatValids[2][0])
    `IP(dataBuf_2_1, dataBuf[2][1])
    `IP(beatValids_2_1, beatValids[2][1])
    `IP(dataBuf_3_0, dataBuf[3][0])
    `IP(beatValids_3_0, beatValids[3][0])
    `IP(dataBuf_3_1, dataBuf[3][1])
    `IP(beatValids_3_1, beatValids[3][1])
    `IP(taskBuf_0_channel, taskBuf_0_channel)
    `IP(taskBuf_0_set, taskBuf_0_set)
    `IP(taskBuf_0_tag, taskBuf_0_tag)
    `IP(taskBuf_0_off, taskBuf_0_off)
    `IP(taskBuf_0_opcode, taskBuf_0_opcode)
    `IP(taskBuf_0_param, taskBuf_0_param)
    `IP(taskBuf_0_size, taskBuf_0_size)
    `IP(taskBuf_0_sourceId, taskBuf_0_sourceId)
    `IP(taskBuf_0_bufIdx, taskBuf_0_bufIdx)
    `IP(taskBuf_0_denied, taskBuf_0_denied)
    `IP(taskBuf_0_corrupt, taskBuf_0_corrupt)
    `IP(taskBuf_0_wayMask, taskBuf_0_wayMask)
    `IP(taskValids_0, taskValids[0])
    `IP(taskBuf_1_channel, taskBuf_1_channel)
    `IP(taskBuf_1_set, taskBuf_1_set)
    `IP(taskBuf_1_tag, taskBuf_1_tag)
    `IP(taskBuf_1_off, taskBuf_1_off)
    `IP(taskBuf_1_opcode, taskBuf_1_opcode)
    `IP(taskBuf_1_param, taskBuf_1_param)
    `IP(taskBuf_1_size, taskBuf_1_size)
    `IP(taskBuf_1_sourceId, taskBuf_1_sourceId)
    `IP(taskBuf_1_bufIdx, taskBuf_1_bufIdx)
    `IP(taskBuf_1_denied, taskBuf_1_denied)
    `IP(taskBuf_1_corrupt, taskBuf_1_corrupt)
    `IP(taskBuf_1_wayMask, taskBuf_1_wayMask)
    `IP(taskValids_1, taskValids[1])
    `IP(taskBuf_2_channel, taskBuf_2_channel)
    `IP(taskBuf_2_set, taskBuf_2_set)
    `IP(taskBuf_2_tag, taskBuf_2_tag)
    `IP(taskBuf_2_off, taskBuf_2_off)
    `IP(taskBuf_2_opcode, taskBuf_2_opcode)
    `IP(taskBuf_2_param, taskBuf_2_param)
    `IP(taskBuf_2_size, taskBuf_2_size)
    `IP(taskBuf_2_sourceId, taskBuf_2_sourceId)
    `IP(taskBuf_2_bufIdx, taskBuf_2_bufIdx)
    `IP(taskBuf_2_denied, taskBuf_2_denied)
    `IP(taskBuf_2_corrupt, taskBuf_2_corrupt)
    `IP(taskBuf_2_wayMask, taskBuf_2_wayMask)
    `IP(taskValids_2, taskValids[2])
    `IP(taskBuf_3_channel, taskBuf_3_channel)
    `IP(taskBuf_3_set, taskBuf_3_set)
    `IP(taskBuf_3_tag, taskBuf_3_tag)
    `IP(taskBuf_3_off, taskBuf_3_off)
    `IP(taskBuf_3_opcode, taskBuf_3_opcode)
    `IP(taskBuf_3_param, taskBuf_3_param)
    `IP(taskBuf_3_size, taskBuf_3_size)
    `IP(taskBuf_3_sourceId, taskBuf_3_sourceId)
    `IP(taskBuf_3_bufIdx, taskBuf_3_bufIdx)
    `IP(taskBuf_3_denied, taskBuf_3_denied)
    `IP(taskBuf_3_corrupt, taskBuf_3_corrupt)
    `IP(taskBuf_3_wayMask, taskBuf_3_wayMask)
    `IP(taskValids_3, taskValids[3])
    `IP(r_counter, r_counter)
    `IP(nextPtrReg, nextPtrReg)
    `IP(probeAckDataBuf, probeAckDataBuf)
    `IP(r_0, r_0)
    `IP(r_1, r_1)
    `IP(REG_0, REG_0)
    `IP(REG_1, REG_1)
    `IP(REG_1_0, REG_1_0)
    `IP(REG_2, REG_2)
    `IP(io_refillBufWrite_valid_REG, io_refillBufWrite_valid_REG)
    `IP(io_refillBufWrite_bits_id_REG, io_refillBufWrite_bits_id_REG)
    `IP(io_refillBufWrite_bits_data_data_REG, io_refillBufWrite_bits_data_data_REG)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_c_valid = '0;
    io_c_bits_opcode = '0;
    io_c_bits_param = '0;
    io_c_bits_size = '0;
    io_c_bits_source = '0;
    io_c_bits_address = '0;
    io_c_bits_data = '0;
    io_c_bits_corrupt = '0;
    io_task_ready = '0;
    io_msInfo_0_valid = '0;
    io_msInfo_0_bits_set = '0;
    io_msInfo_0_bits_reqTag = '0;
    io_msInfo_0_bits_blockRefill = '0;
    io_msInfo_1_valid = '0;
    io_msInfo_1_bits_set = '0;
    io_msInfo_1_bits_reqTag = '0;
    io_msInfo_1_bits_blockRefill = '0;
    io_msInfo_2_valid = '0;
    io_msInfo_2_bits_set = '0;
    io_msInfo_2_bits_reqTag = '0;
    io_msInfo_2_bits_blockRefill = '0;
    io_msInfo_3_valid = '0;
    io_msInfo_3_bits_set = '0;
    io_msInfo_3_bits_reqTag = '0;
    io_msInfo_3_bits_blockRefill = '0;
    io_msInfo_4_valid = '0;
    io_msInfo_4_bits_set = '0;
    io_msInfo_4_bits_reqTag = '0;
    io_msInfo_4_bits_blockRefill = '0;
    io_msInfo_5_valid = '0;
    io_msInfo_5_bits_set = '0;
    io_msInfo_5_bits_reqTag = '0;
    io_msInfo_5_bits_blockRefill = '0;
    io_msInfo_6_valid = '0;
    io_msInfo_6_bits_set = '0;
    io_msInfo_6_bits_reqTag = '0;
    io_msInfo_6_bits_blockRefill = '0;
    io_msInfo_7_valid = '0;
    io_msInfo_7_bits_set = '0;
    io_msInfo_7_bits_reqTag = '0;
    io_msInfo_7_bits_blockRefill = '0;
    io_msInfo_8_valid = '0;
    io_msInfo_8_bits_set = '0;
    io_msInfo_8_bits_reqTag = '0;
    io_msInfo_8_bits_blockRefill = '0;
    io_msInfo_9_valid = '0;
    io_msInfo_9_bits_set = '0;
    io_msInfo_9_bits_reqTag = '0;
    io_msInfo_9_bits_blockRefill = '0;
    io_msInfo_10_valid = '0;
    io_msInfo_10_bits_set = '0;
    io_msInfo_10_bits_reqTag = '0;
    io_msInfo_10_bits_blockRefill = '0;
    io_msInfo_11_valid = '0;
    io_msInfo_11_bits_set = '0;
    io_msInfo_11_bits_reqTag = '0;
    io_msInfo_11_bits_blockRefill = '0;
    io_msInfo_12_valid = '0;
    io_msInfo_12_bits_set = '0;
    io_msInfo_12_bits_reqTag = '0;
    io_msInfo_12_bits_blockRefill = '0;
    io_msInfo_13_valid = '0;
    io_msInfo_13_bits_set = '0;
    io_msInfo_13_bits_reqTag = '0;
    io_msInfo_13_bits_blockRefill = '0;
    io_msInfo_14_valid = '0;
    io_msInfo_14_bits_set = '0;
    io_msInfo_14_bits_reqTag = '0;
    io_msInfo_14_bits_blockRefill = '0;
    io_msInfo_15_valid = '0;
    io_msInfo_15_bits_set = '0;
    io_msInfo_15_bits_reqTag = '0;
    io_msInfo_15_bits_blockRefill = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("SinkC checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
`undef IP
