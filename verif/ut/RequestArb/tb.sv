// 自动生成 scripts/gen_requestarb.py —— 勿手改
// RequestArb 双例化逐拍比对: golden RequestArb vs 可读重写 RequestArb_xs。
// 偏置 opcode/set/tag 偏小, 通道/MSHR/block 随机, 覆盖优先级仲裁/replRead stall/mcp2。
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
  logic io_sinkA_valid;
  logic [2:0] io_sinkA_bits_channel;
  logic [2:0] io_sinkA_bits_txChannel;
  logic [8:0] io_sinkA_bits_set;
  logic [30:0] io_sinkA_bits_tag;
  logic [5:0] io_sinkA_bits_off;
  logic [1:0] io_sinkA_bits_alias;
  logic [43:0] io_sinkA_bits_vaddr;
  logic io_sinkA_bits_isKeyword;
  logic [3:0] io_sinkA_bits_opcode;
  logic [2:0] io_sinkA_bits_param;
  logic [2:0] io_sinkA_bits_size;
  logic [6:0] io_sinkA_bits_sourceId;
  logic [1:0] io_sinkA_bits_bufIdx;
  logic io_sinkA_bits_needProbeAckData;
  logic io_sinkA_bits_denied;
  logic io_sinkA_bits_corrupt;
  logic io_sinkA_bits_mshrTask;
  logic [7:0] io_sinkA_bits_mshrId;
  logic io_sinkA_bits_aliasTask;
  logic io_sinkA_bits_useProbeData;
  logic io_sinkA_bits_mshrRetry;
  logic io_sinkA_bits_readProbeDataDown;
  logic io_sinkA_bits_fromL2pft;
  logic io_sinkA_bits_needHint;
  logic io_sinkA_bits_dirty;
  logic [2:0] io_sinkA_bits_way;
  logic io_sinkA_bits_meta_dirty;
  logic [1:0] io_sinkA_bits_meta_state;
  logic io_sinkA_bits_meta_clients;
  logic [1:0] io_sinkA_bits_meta_alias;
  logic io_sinkA_bits_meta_prefetch;
  logic [2:0] io_sinkA_bits_meta_prefetchSrc;
  logic io_sinkA_bits_meta_accessed;
  logic io_sinkA_bits_meta_tagErr;
  logic io_sinkA_bits_meta_dataErr;
  logic io_sinkA_bits_metaWen;
  logic io_sinkA_bits_tagWen;
  logic io_sinkA_bits_dsWen;
  logic [7:0] io_sinkA_bits_wayMask;
  logic io_sinkA_bits_replTask;
  logic io_sinkA_bits_cmoTask;
  logic io_sinkA_bits_cmoAll;
  logic [4:0] io_sinkA_bits_reqSource;
  logic io_sinkA_bits_mergeA;
  logic [5:0] io_sinkA_bits_aMergeTask_off;
  logic [1:0] io_sinkA_bits_aMergeTask_alias;
  logic [43:0] io_sinkA_bits_aMergeTask_vaddr;
  logic io_sinkA_bits_aMergeTask_isKeyword;
  logic [2:0] io_sinkA_bits_aMergeTask_opcode;
  logic [2:0] io_sinkA_bits_aMergeTask_param;
  logic [6:0] io_sinkA_bits_aMergeTask_sourceId;
  logic io_sinkA_bits_aMergeTask_meta_dirty;
  logic [1:0] io_sinkA_bits_aMergeTask_meta_state;
  logic io_sinkA_bits_aMergeTask_meta_clients;
  logic [1:0] io_sinkA_bits_aMergeTask_meta_alias;
  logic io_sinkA_bits_aMergeTask_meta_prefetch;
  logic [2:0] io_sinkA_bits_aMergeTask_meta_prefetchSrc;
  logic io_sinkA_bits_aMergeTask_meta_accessed;
  logic io_sinkA_bits_aMergeTask_meta_tagErr;
  logic io_sinkA_bits_aMergeTask_meta_dataErr;
  logic io_sinkA_bits_snpHitRelease;
  logic io_sinkA_bits_snpHitReleaseToInval;
  logic io_sinkA_bits_snpHitReleaseToClean;
  logic io_sinkA_bits_snpHitReleaseWithData;
  logic [7:0] io_sinkA_bits_snpHitReleaseIdx;
  logic io_sinkA_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_sinkA_bits_snpHitReleaseMeta_state;
  logic io_sinkA_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_sinkA_bits_snpHitReleaseMeta_alias;
  logic io_sinkA_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_sinkA_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_sinkA_bits_snpHitReleaseMeta_accessed;
  logic io_sinkA_bits_snpHitReleaseMeta_tagErr;
  logic io_sinkA_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_sinkA_bits_tgtID;
  logic [10:0] io_sinkA_bits_srcID;
  logic [11:0] io_sinkA_bits_txnID;
  logic [10:0] io_sinkA_bits_homeNID;
  logic [11:0] io_sinkA_bits_dbID;
  logic [10:0] io_sinkA_bits_fwdNID;
  logic [11:0] io_sinkA_bits_fwdTxnID;
  logic [6:0] io_sinkA_bits_chiOpcode;
  logic [2:0] io_sinkA_bits_resp;
  logic [2:0] io_sinkA_bits_fwdState;
  logic [3:0] io_sinkA_bits_pCrdType;
  logic io_sinkA_bits_retToSrc;
  logic io_sinkA_bits_likelyshared;
  logic io_sinkA_bits_expCompAck;
  logic io_sinkA_bits_allowRetry;
  logic io_sinkA_bits_memAttr_allocate;
  logic io_sinkA_bits_memAttr_cacheable;
  logic io_sinkA_bits_memAttr_device;
  logic io_sinkA_bits_memAttr_ewa;
  logic io_sinkA_bits_traceTag;
  logic io_sinkA_bits_dataCheckErr;
  logic [30:0] io_ATag;
  logic [8:0] io_ASet;
  logic io_sinkB_valid;
  logic [2:0] io_sinkB_bits_channel;
  logic [2:0] io_sinkB_bits_txChannel;
  logic [8:0] io_sinkB_bits_set;
  logic [30:0] io_sinkB_bits_tag;
  logic [5:0] io_sinkB_bits_off;
  logic [1:0] io_sinkB_bits_alias;
  logic [43:0] io_sinkB_bits_vaddr;
  logic io_sinkB_bits_isKeyword;
  logic [3:0] io_sinkB_bits_opcode;
  logic [2:0] io_sinkB_bits_param;
  logic [2:0] io_sinkB_bits_size;
  logic [6:0] io_sinkB_bits_sourceId;
  logic [1:0] io_sinkB_bits_bufIdx;
  logic io_sinkB_bits_needProbeAckData;
  logic io_sinkB_bits_denied;
  logic io_sinkB_bits_corrupt;
  logic io_sinkB_bits_mshrTask;
  logic [7:0] io_sinkB_bits_mshrId;
  logic io_sinkB_bits_aliasTask;
  logic io_sinkB_bits_useProbeData;
  logic io_sinkB_bits_mshrRetry;
  logic io_sinkB_bits_readProbeDataDown;
  logic io_sinkB_bits_fromL2pft;
  logic io_sinkB_bits_needHint;
  logic io_sinkB_bits_dirty;
  logic [2:0] io_sinkB_bits_way;
  logic io_sinkB_bits_meta_dirty;
  logic [1:0] io_sinkB_bits_meta_state;
  logic io_sinkB_bits_meta_clients;
  logic [1:0] io_sinkB_bits_meta_alias;
  logic io_sinkB_bits_meta_prefetch;
  logic [2:0] io_sinkB_bits_meta_prefetchSrc;
  logic io_sinkB_bits_meta_accessed;
  logic io_sinkB_bits_meta_tagErr;
  logic io_sinkB_bits_meta_dataErr;
  logic io_sinkB_bits_metaWen;
  logic io_sinkB_bits_tagWen;
  logic io_sinkB_bits_dsWen;
  logic [7:0] io_sinkB_bits_wayMask;
  logic io_sinkB_bits_replTask;
  logic io_sinkB_bits_cmoTask;
  logic io_sinkB_bits_cmoAll;
  logic [4:0] io_sinkB_bits_reqSource;
  logic io_sinkB_bits_mergeA;
  logic [5:0] io_sinkB_bits_aMergeTask_off;
  logic [1:0] io_sinkB_bits_aMergeTask_alias;
  logic [43:0] io_sinkB_bits_aMergeTask_vaddr;
  logic io_sinkB_bits_aMergeTask_isKeyword;
  logic [2:0] io_sinkB_bits_aMergeTask_opcode;
  logic [2:0] io_sinkB_bits_aMergeTask_param;
  logic [6:0] io_sinkB_bits_aMergeTask_sourceId;
  logic io_sinkB_bits_aMergeTask_meta_dirty;
  logic [1:0] io_sinkB_bits_aMergeTask_meta_state;
  logic io_sinkB_bits_aMergeTask_meta_clients;
  logic [1:0] io_sinkB_bits_aMergeTask_meta_alias;
  logic io_sinkB_bits_aMergeTask_meta_prefetch;
  logic [2:0] io_sinkB_bits_aMergeTask_meta_prefetchSrc;
  logic io_sinkB_bits_aMergeTask_meta_accessed;
  logic io_sinkB_bits_aMergeTask_meta_tagErr;
  logic io_sinkB_bits_aMergeTask_meta_dataErr;
  logic io_sinkB_bits_snpHitRelease;
  logic io_sinkB_bits_snpHitReleaseToInval;
  logic io_sinkB_bits_snpHitReleaseToClean;
  logic io_sinkB_bits_snpHitReleaseWithData;
  logic [7:0] io_sinkB_bits_snpHitReleaseIdx;
  logic io_sinkB_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_sinkB_bits_snpHitReleaseMeta_state;
  logic io_sinkB_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_sinkB_bits_snpHitReleaseMeta_alias;
  logic io_sinkB_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_sinkB_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_sinkB_bits_snpHitReleaseMeta_accessed;
  logic io_sinkB_bits_snpHitReleaseMeta_tagErr;
  logic io_sinkB_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_sinkB_bits_tgtID;
  logic [10:0] io_sinkB_bits_srcID;
  logic [11:0] io_sinkB_bits_txnID;
  logic [10:0] io_sinkB_bits_homeNID;
  logic [11:0] io_sinkB_bits_dbID;
  logic [10:0] io_sinkB_bits_fwdNID;
  logic [11:0] io_sinkB_bits_fwdTxnID;
  logic [6:0] io_sinkB_bits_chiOpcode;
  logic [2:0] io_sinkB_bits_resp;
  logic [2:0] io_sinkB_bits_fwdState;
  logic [3:0] io_sinkB_bits_pCrdType;
  logic io_sinkB_bits_retToSrc;
  logic io_sinkB_bits_likelyshared;
  logic io_sinkB_bits_expCompAck;
  logic io_sinkB_bits_allowRetry;
  logic io_sinkB_bits_memAttr_allocate;
  logic io_sinkB_bits_memAttr_cacheable;
  logic io_sinkB_bits_memAttr_device;
  logic io_sinkB_bits_memAttr_ewa;
  logic io_sinkB_bits_traceTag;
  logic io_sinkB_bits_dataCheckErr;
  logic io_sinkC_valid;
  logic [2:0] io_sinkC_bits_channel;
  logic [2:0] io_sinkC_bits_txChannel;
  logic [8:0] io_sinkC_bits_set;
  logic [30:0] io_sinkC_bits_tag;
  logic [5:0] io_sinkC_bits_off;
  logic [1:0] io_sinkC_bits_alias;
  logic [43:0] io_sinkC_bits_vaddr;
  logic io_sinkC_bits_isKeyword;
  logic [3:0] io_sinkC_bits_opcode;
  logic [2:0] io_sinkC_bits_param;
  logic [2:0] io_sinkC_bits_size;
  logic [6:0] io_sinkC_bits_sourceId;
  logic [1:0] io_sinkC_bits_bufIdx;
  logic io_sinkC_bits_needProbeAckData;
  logic io_sinkC_bits_denied;
  logic io_sinkC_bits_corrupt;
  logic io_sinkC_bits_mshrTask;
  logic [7:0] io_sinkC_bits_mshrId;
  logic io_sinkC_bits_aliasTask;
  logic io_sinkC_bits_useProbeData;
  logic io_sinkC_bits_mshrRetry;
  logic io_sinkC_bits_readProbeDataDown;
  logic io_sinkC_bits_fromL2pft;
  logic io_sinkC_bits_needHint;
  logic io_sinkC_bits_dirty;
  logic [2:0] io_sinkC_bits_way;
  logic io_sinkC_bits_meta_dirty;
  logic [1:0] io_sinkC_bits_meta_state;
  logic io_sinkC_bits_meta_clients;
  logic [1:0] io_sinkC_bits_meta_alias;
  logic io_sinkC_bits_meta_prefetch;
  logic [2:0] io_sinkC_bits_meta_prefetchSrc;
  logic io_sinkC_bits_meta_accessed;
  logic io_sinkC_bits_meta_tagErr;
  logic io_sinkC_bits_meta_dataErr;
  logic io_sinkC_bits_metaWen;
  logic io_sinkC_bits_tagWen;
  logic io_sinkC_bits_dsWen;
  logic [7:0] io_sinkC_bits_wayMask;
  logic io_sinkC_bits_replTask;
  logic io_sinkC_bits_cmoTask;
  logic io_sinkC_bits_cmoAll;
  logic [4:0] io_sinkC_bits_reqSource;
  logic io_sinkC_bits_mergeA;
  logic [5:0] io_sinkC_bits_aMergeTask_off;
  logic [1:0] io_sinkC_bits_aMergeTask_alias;
  logic [43:0] io_sinkC_bits_aMergeTask_vaddr;
  logic io_sinkC_bits_aMergeTask_isKeyword;
  logic [2:0] io_sinkC_bits_aMergeTask_opcode;
  logic [2:0] io_sinkC_bits_aMergeTask_param;
  logic [6:0] io_sinkC_bits_aMergeTask_sourceId;
  logic io_sinkC_bits_aMergeTask_meta_dirty;
  logic [1:0] io_sinkC_bits_aMergeTask_meta_state;
  logic io_sinkC_bits_aMergeTask_meta_clients;
  logic [1:0] io_sinkC_bits_aMergeTask_meta_alias;
  logic io_sinkC_bits_aMergeTask_meta_prefetch;
  logic [2:0] io_sinkC_bits_aMergeTask_meta_prefetchSrc;
  logic io_sinkC_bits_aMergeTask_meta_accessed;
  logic io_sinkC_bits_aMergeTask_meta_tagErr;
  logic io_sinkC_bits_aMergeTask_meta_dataErr;
  logic io_sinkC_bits_snpHitRelease;
  logic io_sinkC_bits_snpHitReleaseToInval;
  logic io_sinkC_bits_snpHitReleaseToClean;
  logic io_sinkC_bits_snpHitReleaseWithData;
  logic [7:0] io_sinkC_bits_snpHitReleaseIdx;
  logic io_sinkC_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_sinkC_bits_snpHitReleaseMeta_state;
  logic io_sinkC_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_sinkC_bits_snpHitReleaseMeta_alias;
  logic io_sinkC_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_sinkC_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_sinkC_bits_snpHitReleaseMeta_accessed;
  logic io_sinkC_bits_snpHitReleaseMeta_tagErr;
  logic io_sinkC_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_sinkC_bits_tgtID;
  logic [10:0] io_sinkC_bits_srcID;
  logic [11:0] io_sinkC_bits_txnID;
  logic [10:0] io_sinkC_bits_homeNID;
  logic [11:0] io_sinkC_bits_dbID;
  logic [10:0] io_sinkC_bits_fwdNID;
  logic [11:0] io_sinkC_bits_fwdTxnID;
  logic [6:0] io_sinkC_bits_chiOpcode;
  logic [2:0] io_sinkC_bits_resp;
  logic [2:0] io_sinkC_bits_fwdState;
  logic [3:0] io_sinkC_bits_pCrdType;
  logic io_sinkC_bits_retToSrc;
  logic io_sinkC_bits_likelyshared;
  logic io_sinkC_bits_expCompAck;
  logic io_sinkC_bits_allowRetry;
  logic io_sinkC_bits_memAttr_allocate;
  logic io_sinkC_bits_memAttr_cacheable;
  logic io_sinkC_bits_memAttr_device;
  logic io_sinkC_bits_memAttr_ewa;
  logic io_sinkC_bits_traceTag;
  logic io_sinkC_bits_dataCheckErr;
  logic io_mshrTask_valid;
  logic [2:0] io_mshrTask_bits_channel;
  logic [2:0] io_mshrTask_bits_txChannel;
  logic [8:0] io_mshrTask_bits_set;
  logic [30:0] io_mshrTask_bits_tag;
  logic [5:0] io_mshrTask_bits_off;
  logic [1:0] io_mshrTask_bits_alias;
  logic [43:0] io_mshrTask_bits_vaddr;
  logic io_mshrTask_bits_isKeyword;
  logic [3:0] io_mshrTask_bits_opcode;
  logic [2:0] io_mshrTask_bits_param;
  logic [2:0] io_mshrTask_bits_size;
  logic [6:0] io_mshrTask_bits_sourceId;
  logic [1:0] io_mshrTask_bits_bufIdx;
  logic io_mshrTask_bits_needProbeAckData;
  logic io_mshrTask_bits_denied;
  logic io_mshrTask_bits_corrupt;
  logic io_mshrTask_bits_mshrTask;
  logic [7:0] io_mshrTask_bits_mshrId;
  logic io_mshrTask_bits_aliasTask;
  logic io_mshrTask_bits_useProbeData;
  logic io_mshrTask_bits_mshrRetry;
  logic io_mshrTask_bits_readProbeDataDown;
  logic io_mshrTask_bits_fromL2pft;
  logic io_mshrTask_bits_needHint;
  logic io_mshrTask_bits_dirty;
  logic [2:0] io_mshrTask_bits_way;
  logic io_mshrTask_bits_meta_dirty;
  logic [1:0] io_mshrTask_bits_meta_state;
  logic io_mshrTask_bits_meta_clients;
  logic [1:0] io_mshrTask_bits_meta_alias;
  logic io_mshrTask_bits_meta_prefetch;
  logic [2:0] io_mshrTask_bits_meta_prefetchSrc;
  logic io_mshrTask_bits_meta_accessed;
  logic io_mshrTask_bits_meta_tagErr;
  logic io_mshrTask_bits_meta_dataErr;
  logic io_mshrTask_bits_metaWen;
  logic io_mshrTask_bits_tagWen;
  logic io_mshrTask_bits_dsWen;
  logic [7:0] io_mshrTask_bits_wayMask;
  logic io_mshrTask_bits_replTask;
  logic io_mshrTask_bits_cmoTask;
  logic io_mshrTask_bits_cmoAll;
  logic [4:0] io_mshrTask_bits_reqSource;
  logic io_mshrTask_bits_mergeA;
  logic [5:0] io_mshrTask_bits_aMergeTask_off;
  logic [1:0] io_mshrTask_bits_aMergeTask_alias;
  logic [43:0] io_mshrTask_bits_aMergeTask_vaddr;
  logic io_mshrTask_bits_aMergeTask_isKeyword;
  logic [2:0] io_mshrTask_bits_aMergeTask_opcode;
  logic [2:0] io_mshrTask_bits_aMergeTask_param;
  logic [6:0] io_mshrTask_bits_aMergeTask_sourceId;
  logic io_mshrTask_bits_aMergeTask_meta_dirty;
  logic [1:0] io_mshrTask_bits_aMergeTask_meta_state;
  logic io_mshrTask_bits_aMergeTask_meta_clients;
  logic [1:0] io_mshrTask_bits_aMergeTask_meta_alias;
  logic io_mshrTask_bits_aMergeTask_meta_prefetch;
  logic [2:0] io_mshrTask_bits_aMergeTask_meta_prefetchSrc;
  logic io_mshrTask_bits_aMergeTask_meta_accessed;
  logic io_mshrTask_bits_aMergeTask_meta_tagErr;
  logic io_mshrTask_bits_aMergeTask_meta_dataErr;
  logic io_mshrTask_bits_snpHitRelease;
  logic io_mshrTask_bits_snpHitReleaseToInval;
  logic io_mshrTask_bits_snpHitReleaseToClean;
  logic io_mshrTask_bits_snpHitReleaseWithData;
  logic [7:0] io_mshrTask_bits_snpHitReleaseIdx;
  logic io_mshrTask_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_mshrTask_bits_snpHitReleaseMeta_state;
  logic io_mshrTask_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_mshrTask_bits_snpHitReleaseMeta_alias;
  logic io_mshrTask_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_mshrTask_bits_snpHitReleaseMeta_accessed;
  logic io_mshrTask_bits_snpHitReleaseMeta_tagErr;
  logic io_mshrTask_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_mshrTask_bits_tgtID;
  logic [10:0] io_mshrTask_bits_srcID;
  logic [11:0] io_mshrTask_bits_txnID;
  logic [10:0] io_mshrTask_bits_homeNID;
  logic [11:0] io_mshrTask_bits_dbID;
  logic [10:0] io_mshrTask_bits_fwdNID;
  logic [11:0] io_mshrTask_bits_fwdTxnID;
  logic [6:0] io_mshrTask_bits_chiOpcode;
  logic [2:0] io_mshrTask_bits_resp;
  logic [2:0] io_mshrTask_bits_fwdState;
  logic [3:0] io_mshrTask_bits_pCrdType;
  logic io_mshrTask_bits_retToSrc;
  logic io_mshrTask_bits_likelyshared;
  logic io_mshrTask_bits_expCompAck;
  logic io_mshrTask_bits_allowRetry;
  logic io_mshrTask_bits_memAttr_allocate;
  logic io_mshrTask_bits_memAttr_cacheable;
  logic io_mshrTask_bits_memAttr_device;
  logic io_mshrTask_bits_memAttr_ewa;
  logic io_mshrTask_bits_traceTag;
  logic io_mshrTask_bits_dataCheckErr;
  logic io_dirRead_s1_ready;
  logic io_fromMSHRCtl_blockG_s1;
  logic io_fromMSHRCtl_blockA_s1;
  logic io_fromMSHRCtl_blockB_s1;
  logic io_fromMSHRCtl_blockC_s1;
  logic io_fromMainPipe_blockG_s1;
  logic io_fromMainPipe_blockA_s1;
  logic io_fromMainPipe_blockB_s1;
  logic io_fromMainPipe_blockC_s1;
  logic io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1;
  logic io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1;
  logic io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1;
  logic io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1;
  logic io_fromGrantBuffer_blockMSHRReqEntrance;
  logic io_fromTXDAT_blockMSHRReqEntrance;
  logic io_fromTXDAT_blockSinkBReqEntrance;
  logic io_fromTXRSP_blockMSHRReqEntrance;
  logic io_fromTXRSP_blockSinkBReqEntrance;
  logic io_fromTXREQ_blockMSHRReqEntrance;
  logic io_msInfo_0_valid;
  logic [2:0] io_msInfo_0_bits_channel;
  logic [8:0] io_msInfo_0_bits_set;
  logic [2:0] io_msInfo_0_bits_way;
  logic [30:0] io_msInfo_0_bits_reqTag;
  logic io_msInfo_0_bits_willFree;
  logic io_msInfo_0_bits_aliasTask;
  logic io_msInfo_0_bits_needRelease;
  logic io_msInfo_0_bits_blockRefill;
  logic io_msInfo_0_bits_meta_dirty;
  logic [1:0] io_msInfo_0_bits_meta_state;
  logic io_msInfo_0_bits_meta_clients;
  logic [1:0] io_msInfo_0_bits_meta_alias;
  logic io_msInfo_0_bits_meta_prefetch;
  logic [2:0] io_msInfo_0_bits_meta_prefetchSrc;
  logic io_msInfo_0_bits_meta_accessed;
  logic io_msInfo_0_bits_meta_tagErr;
  logic io_msInfo_0_bits_meta_dataErr;
  logic [30:0] io_msInfo_0_bits_metaTag;
  logic io_msInfo_0_bits_dirHit;
  logic io_msInfo_0_bits_isAcqOrPrefetch;
  logic io_msInfo_0_bits_isPrefetch;
  logic [2:0] io_msInfo_0_bits_param;
  logic io_msInfo_0_bits_mergeA;
  logic io_msInfo_0_bits_w_grantfirst;
  logic io_msInfo_0_bits_s_release;
  logic io_msInfo_0_bits_s_refill;
  logic io_msInfo_0_bits_s_cmoresp;
  logic io_msInfo_0_bits_s_cmometaw;
  logic io_msInfo_0_bits_w_releaseack;
  logic io_msInfo_0_bits_w_replResp;
  logic io_msInfo_0_bits_w_rprobeacklast;
  logic io_msInfo_0_bits_replaceData;
  logic io_msInfo_0_bits_releaseToClean;
  logic io_msInfo_1_valid;
  logic [2:0] io_msInfo_1_bits_channel;
  logic [8:0] io_msInfo_1_bits_set;
  logic [2:0] io_msInfo_1_bits_way;
  logic [30:0] io_msInfo_1_bits_reqTag;
  logic io_msInfo_1_bits_willFree;
  logic io_msInfo_1_bits_aliasTask;
  logic io_msInfo_1_bits_needRelease;
  logic io_msInfo_1_bits_blockRefill;
  logic io_msInfo_1_bits_meta_dirty;
  logic [1:0] io_msInfo_1_bits_meta_state;
  logic io_msInfo_1_bits_meta_clients;
  logic [1:0] io_msInfo_1_bits_meta_alias;
  logic io_msInfo_1_bits_meta_prefetch;
  logic [2:0] io_msInfo_1_bits_meta_prefetchSrc;
  logic io_msInfo_1_bits_meta_accessed;
  logic io_msInfo_1_bits_meta_tagErr;
  logic io_msInfo_1_bits_meta_dataErr;
  logic [30:0] io_msInfo_1_bits_metaTag;
  logic io_msInfo_1_bits_dirHit;
  logic io_msInfo_1_bits_isAcqOrPrefetch;
  logic io_msInfo_1_bits_isPrefetch;
  logic [2:0] io_msInfo_1_bits_param;
  logic io_msInfo_1_bits_mergeA;
  logic io_msInfo_1_bits_w_grantfirst;
  logic io_msInfo_1_bits_s_release;
  logic io_msInfo_1_bits_s_refill;
  logic io_msInfo_1_bits_s_cmoresp;
  logic io_msInfo_1_bits_s_cmometaw;
  logic io_msInfo_1_bits_w_releaseack;
  logic io_msInfo_1_bits_w_replResp;
  logic io_msInfo_1_bits_w_rprobeacklast;
  logic io_msInfo_1_bits_replaceData;
  logic io_msInfo_1_bits_releaseToClean;
  logic io_msInfo_2_valid;
  logic [2:0] io_msInfo_2_bits_channel;
  logic [8:0] io_msInfo_2_bits_set;
  logic [2:0] io_msInfo_2_bits_way;
  logic [30:0] io_msInfo_2_bits_reqTag;
  logic io_msInfo_2_bits_willFree;
  logic io_msInfo_2_bits_aliasTask;
  logic io_msInfo_2_bits_needRelease;
  logic io_msInfo_2_bits_blockRefill;
  logic io_msInfo_2_bits_meta_dirty;
  logic [1:0] io_msInfo_2_bits_meta_state;
  logic io_msInfo_2_bits_meta_clients;
  logic [1:0] io_msInfo_2_bits_meta_alias;
  logic io_msInfo_2_bits_meta_prefetch;
  logic [2:0] io_msInfo_2_bits_meta_prefetchSrc;
  logic io_msInfo_2_bits_meta_accessed;
  logic io_msInfo_2_bits_meta_tagErr;
  logic io_msInfo_2_bits_meta_dataErr;
  logic [30:0] io_msInfo_2_bits_metaTag;
  logic io_msInfo_2_bits_dirHit;
  logic io_msInfo_2_bits_isAcqOrPrefetch;
  logic io_msInfo_2_bits_isPrefetch;
  logic [2:0] io_msInfo_2_bits_param;
  logic io_msInfo_2_bits_mergeA;
  logic io_msInfo_2_bits_w_grantfirst;
  logic io_msInfo_2_bits_s_release;
  logic io_msInfo_2_bits_s_refill;
  logic io_msInfo_2_bits_s_cmoresp;
  logic io_msInfo_2_bits_s_cmometaw;
  logic io_msInfo_2_bits_w_releaseack;
  logic io_msInfo_2_bits_w_replResp;
  logic io_msInfo_2_bits_w_rprobeacklast;
  logic io_msInfo_2_bits_replaceData;
  logic io_msInfo_2_bits_releaseToClean;
  logic io_msInfo_3_valid;
  logic [2:0] io_msInfo_3_bits_channel;
  logic [8:0] io_msInfo_3_bits_set;
  logic [2:0] io_msInfo_3_bits_way;
  logic [30:0] io_msInfo_3_bits_reqTag;
  logic io_msInfo_3_bits_willFree;
  logic io_msInfo_3_bits_aliasTask;
  logic io_msInfo_3_bits_needRelease;
  logic io_msInfo_3_bits_blockRefill;
  logic io_msInfo_3_bits_meta_dirty;
  logic [1:0] io_msInfo_3_bits_meta_state;
  logic io_msInfo_3_bits_meta_clients;
  logic [1:0] io_msInfo_3_bits_meta_alias;
  logic io_msInfo_3_bits_meta_prefetch;
  logic [2:0] io_msInfo_3_bits_meta_prefetchSrc;
  logic io_msInfo_3_bits_meta_accessed;
  logic io_msInfo_3_bits_meta_tagErr;
  logic io_msInfo_3_bits_meta_dataErr;
  logic [30:0] io_msInfo_3_bits_metaTag;
  logic io_msInfo_3_bits_dirHit;
  logic io_msInfo_3_bits_isAcqOrPrefetch;
  logic io_msInfo_3_bits_isPrefetch;
  logic [2:0] io_msInfo_3_bits_param;
  logic io_msInfo_3_bits_mergeA;
  logic io_msInfo_3_bits_w_grantfirst;
  logic io_msInfo_3_bits_s_release;
  logic io_msInfo_3_bits_s_refill;
  logic io_msInfo_3_bits_s_cmoresp;
  logic io_msInfo_3_bits_s_cmometaw;
  logic io_msInfo_3_bits_w_releaseack;
  logic io_msInfo_3_bits_w_replResp;
  logic io_msInfo_3_bits_w_rprobeacklast;
  logic io_msInfo_3_bits_replaceData;
  logic io_msInfo_3_bits_releaseToClean;
  logic io_msInfo_4_valid;
  logic [2:0] io_msInfo_4_bits_channel;
  logic [8:0] io_msInfo_4_bits_set;
  logic [2:0] io_msInfo_4_bits_way;
  logic [30:0] io_msInfo_4_bits_reqTag;
  logic io_msInfo_4_bits_willFree;
  logic io_msInfo_4_bits_aliasTask;
  logic io_msInfo_4_bits_needRelease;
  logic io_msInfo_4_bits_blockRefill;
  logic io_msInfo_4_bits_meta_dirty;
  logic [1:0] io_msInfo_4_bits_meta_state;
  logic io_msInfo_4_bits_meta_clients;
  logic [1:0] io_msInfo_4_bits_meta_alias;
  logic io_msInfo_4_bits_meta_prefetch;
  logic [2:0] io_msInfo_4_bits_meta_prefetchSrc;
  logic io_msInfo_4_bits_meta_accessed;
  logic io_msInfo_4_bits_meta_tagErr;
  logic io_msInfo_4_bits_meta_dataErr;
  logic [30:0] io_msInfo_4_bits_metaTag;
  logic io_msInfo_4_bits_dirHit;
  logic io_msInfo_4_bits_isAcqOrPrefetch;
  logic io_msInfo_4_bits_isPrefetch;
  logic [2:0] io_msInfo_4_bits_param;
  logic io_msInfo_4_bits_mergeA;
  logic io_msInfo_4_bits_w_grantfirst;
  logic io_msInfo_4_bits_s_release;
  logic io_msInfo_4_bits_s_refill;
  logic io_msInfo_4_bits_s_cmoresp;
  logic io_msInfo_4_bits_s_cmometaw;
  logic io_msInfo_4_bits_w_releaseack;
  logic io_msInfo_4_bits_w_replResp;
  logic io_msInfo_4_bits_w_rprobeacklast;
  logic io_msInfo_4_bits_replaceData;
  logic io_msInfo_4_bits_releaseToClean;
  logic io_msInfo_5_valid;
  logic [2:0] io_msInfo_5_bits_channel;
  logic [8:0] io_msInfo_5_bits_set;
  logic [2:0] io_msInfo_5_bits_way;
  logic [30:0] io_msInfo_5_bits_reqTag;
  logic io_msInfo_5_bits_willFree;
  logic io_msInfo_5_bits_aliasTask;
  logic io_msInfo_5_bits_needRelease;
  logic io_msInfo_5_bits_blockRefill;
  logic io_msInfo_5_bits_meta_dirty;
  logic [1:0] io_msInfo_5_bits_meta_state;
  logic io_msInfo_5_bits_meta_clients;
  logic [1:0] io_msInfo_5_bits_meta_alias;
  logic io_msInfo_5_bits_meta_prefetch;
  logic [2:0] io_msInfo_5_bits_meta_prefetchSrc;
  logic io_msInfo_5_bits_meta_accessed;
  logic io_msInfo_5_bits_meta_tagErr;
  logic io_msInfo_5_bits_meta_dataErr;
  logic [30:0] io_msInfo_5_bits_metaTag;
  logic io_msInfo_5_bits_dirHit;
  logic io_msInfo_5_bits_isAcqOrPrefetch;
  logic io_msInfo_5_bits_isPrefetch;
  logic [2:0] io_msInfo_5_bits_param;
  logic io_msInfo_5_bits_mergeA;
  logic io_msInfo_5_bits_w_grantfirst;
  logic io_msInfo_5_bits_s_release;
  logic io_msInfo_5_bits_s_refill;
  logic io_msInfo_5_bits_s_cmoresp;
  logic io_msInfo_5_bits_s_cmometaw;
  logic io_msInfo_5_bits_w_releaseack;
  logic io_msInfo_5_bits_w_replResp;
  logic io_msInfo_5_bits_w_rprobeacklast;
  logic io_msInfo_5_bits_replaceData;
  logic io_msInfo_5_bits_releaseToClean;
  logic io_msInfo_6_valid;
  logic [2:0] io_msInfo_6_bits_channel;
  logic [8:0] io_msInfo_6_bits_set;
  logic [2:0] io_msInfo_6_bits_way;
  logic [30:0] io_msInfo_6_bits_reqTag;
  logic io_msInfo_6_bits_willFree;
  logic io_msInfo_6_bits_aliasTask;
  logic io_msInfo_6_bits_needRelease;
  logic io_msInfo_6_bits_blockRefill;
  logic io_msInfo_6_bits_meta_dirty;
  logic [1:0] io_msInfo_6_bits_meta_state;
  logic io_msInfo_6_bits_meta_clients;
  logic [1:0] io_msInfo_6_bits_meta_alias;
  logic io_msInfo_6_bits_meta_prefetch;
  logic [2:0] io_msInfo_6_bits_meta_prefetchSrc;
  logic io_msInfo_6_bits_meta_accessed;
  logic io_msInfo_6_bits_meta_tagErr;
  logic io_msInfo_6_bits_meta_dataErr;
  logic [30:0] io_msInfo_6_bits_metaTag;
  logic io_msInfo_6_bits_dirHit;
  logic io_msInfo_6_bits_isAcqOrPrefetch;
  logic io_msInfo_6_bits_isPrefetch;
  logic [2:0] io_msInfo_6_bits_param;
  logic io_msInfo_6_bits_mergeA;
  logic io_msInfo_6_bits_w_grantfirst;
  logic io_msInfo_6_bits_s_release;
  logic io_msInfo_6_bits_s_refill;
  logic io_msInfo_6_bits_s_cmoresp;
  logic io_msInfo_6_bits_s_cmometaw;
  logic io_msInfo_6_bits_w_releaseack;
  logic io_msInfo_6_bits_w_replResp;
  logic io_msInfo_6_bits_w_rprobeacklast;
  logic io_msInfo_6_bits_replaceData;
  logic io_msInfo_6_bits_releaseToClean;
  logic io_msInfo_7_valid;
  logic [2:0] io_msInfo_7_bits_channel;
  logic [8:0] io_msInfo_7_bits_set;
  logic [2:0] io_msInfo_7_bits_way;
  logic [30:0] io_msInfo_7_bits_reqTag;
  logic io_msInfo_7_bits_willFree;
  logic io_msInfo_7_bits_aliasTask;
  logic io_msInfo_7_bits_needRelease;
  logic io_msInfo_7_bits_blockRefill;
  logic io_msInfo_7_bits_meta_dirty;
  logic [1:0] io_msInfo_7_bits_meta_state;
  logic io_msInfo_7_bits_meta_clients;
  logic [1:0] io_msInfo_7_bits_meta_alias;
  logic io_msInfo_7_bits_meta_prefetch;
  logic [2:0] io_msInfo_7_bits_meta_prefetchSrc;
  logic io_msInfo_7_bits_meta_accessed;
  logic io_msInfo_7_bits_meta_tagErr;
  logic io_msInfo_7_bits_meta_dataErr;
  logic [30:0] io_msInfo_7_bits_metaTag;
  logic io_msInfo_7_bits_dirHit;
  logic io_msInfo_7_bits_isAcqOrPrefetch;
  logic io_msInfo_7_bits_isPrefetch;
  logic [2:0] io_msInfo_7_bits_param;
  logic io_msInfo_7_bits_mergeA;
  logic io_msInfo_7_bits_w_grantfirst;
  logic io_msInfo_7_bits_s_release;
  logic io_msInfo_7_bits_s_refill;
  logic io_msInfo_7_bits_s_cmoresp;
  logic io_msInfo_7_bits_s_cmometaw;
  logic io_msInfo_7_bits_w_releaseack;
  logic io_msInfo_7_bits_w_replResp;
  logic io_msInfo_7_bits_w_rprobeacklast;
  logic io_msInfo_7_bits_replaceData;
  logic io_msInfo_7_bits_releaseToClean;
  logic io_msInfo_8_valid;
  logic [2:0] io_msInfo_8_bits_channel;
  logic [8:0] io_msInfo_8_bits_set;
  logic [2:0] io_msInfo_8_bits_way;
  logic [30:0] io_msInfo_8_bits_reqTag;
  logic io_msInfo_8_bits_willFree;
  logic io_msInfo_8_bits_aliasTask;
  logic io_msInfo_8_bits_needRelease;
  logic io_msInfo_8_bits_blockRefill;
  logic io_msInfo_8_bits_meta_dirty;
  logic [1:0] io_msInfo_8_bits_meta_state;
  logic io_msInfo_8_bits_meta_clients;
  logic [1:0] io_msInfo_8_bits_meta_alias;
  logic io_msInfo_8_bits_meta_prefetch;
  logic [2:0] io_msInfo_8_bits_meta_prefetchSrc;
  logic io_msInfo_8_bits_meta_accessed;
  logic io_msInfo_8_bits_meta_tagErr;
  logic io_msInfo_8_bits_meta_dataErr;
  logic [30:0] io_msInfo_8_bits_metaTag;
  logic io_msInfo_8_bits_dirHit;
  logic io_msInfo_8_bits_isAcqOrPrefetch;
  logic io_msInfo_8_bits_isPrefetch;
  logic [2:0] io_msInfo_8_bits_param;
  logic io_msInfo_8_bits_mergeA;
  logic io_msInfo_8_bits_w_grantfirst;
  logic io_msInfo_8_bits_s_release;
  logic io_msInfo_8_bits_s_refill;
  logic io_msInfo_8_bits_s_cmoresp;
  logic io_msInfo_8_bits_s_cmometaw;
  logic io_msInfo_8_bits_w_releaseack;
  logic io_msInfo_8_bits_w_replResp;
  logic io_msInfo_8_bits_w_rprobeacklast;
  logic io_msInfo_8_bits_replaceData;
  logic io_msInfo_8_bits_releaseToClean;
  logic io_msInfo_9_valid;
  logic [2:0] io_msInfo_9_bits_channel;
  logic [8:0] io_msInfo_9_bits_set;
  logic [2:0] io_msInfo_9_bits_way;
  logic [30:0] io_msInfo_9_bits_reqTag;
  logic io_msInfo_9_bits_willFree;
  logic io_msInfo_9_bits_aliasTask;
  logic io_msInfo_9_bits_needRelease;
  logic io_msInfo_9_bits_blockRefill;
  logic io_msInfo_9_bits_meta_dirty;
  logic [1:0] io_msInfo_9_bits_meta_state;
  logic io_msInfo_9_bits_meta_clients;
  logic [1:0] io_msInfo_9_bits_meta_alias;
  logic io_msInfo_9_bits_meta_prefetch;
  logic [2:0] io_msInfo_9_bits_meta_prefetchSrc;
  logic io_msInfo_9_bits_meta_accessed;
  logic io_msInfo_9_bits_meta_tagErr;
  logic io_msInfo_9_bits_meta_dataErr;
  logic [30:0] io_msInfo_9_bits_metaTag;
  logic io_msInfo_9_bits_dirHit;
  logic io_msInfo_9_bits_isAcqOrPrefetch;
  logic io_msInfo_9_bits_isPrefetch;
  logic [2:0] io_msInfo_9_bits_param;
  logic io_msInfo_9_bits_mergeA;
  logic io_msInfo_9_bits_w_grantfirst;
  logic io_msInfo_9_bits_s_release;
  logic io_msInfo_9_bits_s_refill;
  logic io_msInfo_9_bits_s_cmoresp;
  logic io_msInfo_9_bits_s_cmometaw;
  logic io_msInfo_9_bits_w_releaseack;
  logic io_msInfo_9_bits_w_replResp;
  logic io_msInfo_9_bits_w_rprobeacklast;
  logic io_msInfo_9_bits_replaceData;
  logic io_msInfo_9_bits_releaseToClean;
  logic io_msInfo_10_valid;
  logic [2:0] io_msInfo_10_bits_channel;
  logic [8:0] io_msInfo_10_bits_set;
  logic [2:0] io_msInfo_10_bits_way;
  logic [30:0] io_msInfo_10_bits_reqTag;
  logic io_msInfo_10_bits_willFree;
  logic io_msInfo_10_bits_aliasTask;
  logic io_msInfo_10_bits_needRelease;
  logic io_msInfo_10_bits_blockRefill;
  logic io_msInfo_10_bits_meta_dirty;
  logic [1:0] io_msInfo_10_bits_meta_state;
  logic io_msInfo_10_bits_meta_clients;
  logic [1:0] io_msInfo_10_bits_meta_alias;
  logic io_msInfo_10_bits_meta_prefetch;
  logic [2:0] io_msInfo_10_bits_meta_prefetchSrc;
  logic io_msInfo_10_bits_meta_accessed;
  logic io_msInfo_10_bits_meta_tagErr;
  logic io_msInfo_10_bits_meta_dataErr;
  logic [30:0] io_msInfo_10_bits_metaTag;
  logic io_msInfo_10_bits_dirHit;
  logic io_msInfo_10_bits_isAcqOrPrefetch;
  logic io_msInfo_10_bits_isPrefetch;
  logic [2:0] io_msInfo_10_bits_param;
  logic io_msInfo_10_bits_mergeA;
  logic io_msInfo_10_bits_w_grantfirst;
  logic io_msInfo_10_bits_s_release;
  logic io_msInfo_10_bits_s_refill;
  logic io_msInfo_10_bits_s_cmoresp;
  logic io_msInfo_10_bits_s_cmometaw;
  logic io_msInfo_10_bits_w_releaseack;
  logic io_msInfo_10_bits_w_replResp;
  logic io_msInfo_10_bits_w_rprobeacklast;
  logic io_msInfo_10_bits_replaceData;
  logic io_msInfo_10_bits_releaseToClean;
  logic io_msInfo_11_valid;
  logic [2:0] io_msInfo_11_bits_channel;
  logic [8:0] io_msInfo_11_bits_set;
  logic [2:0] io_msInfo_11_bits_way;
  logic [30:0] io_msInfo_11_bits_reqTag;
  logic io_msInfo_11_bits_willFree;
  logic io_msInfo_11_bits_aliasTask;
  logic io_msInfo_11_bits_needRelease;
  logic io_msInfo_11_bits_blockRefill;
  logic io_msInfo_11_bits_meta_dirty;
  logic [1:0] io_msInfo_11_bits_meta_state;
  logic io_msInfo_11_bits_meta_clients;
  logic [1:0] io_msInfo_11_bits_meta_alias;
  logic io_msInfo_11_bits_meta_prefetch;
  logic [2:0] io_msInfo_11_bits_meta_prefetchSrc;
  logic io_msInfo_11_bits_meta_accessed;
  logic io_msInfo_11_bits_meta_tagErr;
  logic io_msInfo_11_bits_meta_dataErr;
  logic [30:0] io_msInfo_11_bits_metaTag;
  logic io_msInfo_11_bits_dirHit;
  logic io_msInfo_11_bits_isAcqOrPrefetch;
  logic io_msInfo_11_bits_isPrefetch;
  logic [2:0] io_msInfo_11_bits_param;
  logic io_msInfo_11_bits_mergeA;
  logic io_msInfo_11_bits_w_grantfirst;
  logic io_msInfo_11_bits_s_release;
  logic io_msInfo_11_bits_s_refill;
  logic io_msInfo_11_bits_s_cmoresp;
  logic io_msInfo_11_bits_s_cmometaw;
  logic io_msInfo_11_bits_w_releaseack;
  logic io_msInfo_11_bits_w_replResp;
  logic io_msInfo_11_bits_w_rprobeacklast;
  logic io_msInfo_11_bits_replaceData;
  logic io_msInfo_11_bits_releaseToClean;
  logic io_msInfo_12_valid;
  logic [2:0] io_msInfo_12_bits_channel;
  logic [8:0] io_msInfo_12_bits_set;
  logic [2:0] io_msInfo_12_bits_way;
  logic [30:0] io_msInfo_12_bits_reqTag;
  logic io_msInfo_12_bits_willFree;
  logic io_msInfo_12_bits_aliasTask;
  logic io_msInfo_12_bits_needRelease;
  logic io_msInfo_12_bits_blockRefill;
  logic io_msInfo_12_bits_meta_dirty;
  logic [1:0] io_msInfo_12_bits_meta_state;
  logic io_msInfo_12_bits_meta_clients;
  logic [1:0] io_msInfo_12_bits_meta_alias;
  logic io_msInfo_12_bits_meta_prefetch;
  logic [2:0] io_msInfo_12_bits_meta_prefetchSrc;
  logic io_msInfo_12_bits_meta_accessed;
  logic io_msInfo_12_bits_meta_tagErr;
  logic io_msInfo_12_bits_meta_dataErr;
  logic [30:0] io_msInfo_12_bits_metaTag;
  logic io_msInfo_12_bits_dirHit;
  logic io_msInfo_12_bits_isAcqOrPrefetch;
  logic io_msInfo_12_bits_isPrefetch;
  logic [2:0] io_msInfo_12_bits_param;
  logic io_msInfo_12_bits_mergeA;
  logic io_msInfo_12_bits_w_grantfirst;
  logic io_msInfo_12_bits_s_release;
  logic io_msInfo_12_bits_s_refill;
  logic io_msInfo_12_bits_s_cmoresp;
  logic io_msInfo_12_bits_s_cmometaw;
  logic io_msInfo_12_bits_w_releaseack;
  logic io_msInfo_12_bits_w_replResp;
  logic io_msInfo_12_bits_w_rprobeacklast;
  logic io_msInfo_12_bits_replaceData;
  logic io_msInfo_12_bits_releaseToClean;
  logic io_msInfo_13_valid;
  logic [2:0] io_msInfo_13_bits_channel;
  logic [8:0] io_msInfo_13_bits_set;
  logic [2:0] io_msInfo_13_bits_way;
  logic [30:0] io_msInfo_13_bits_reqTag;
  logic io_msInfo_13_bits_willFree;
  logic io_msInfo_13_bits_aliasTask;
  logic io_msInfo_13_bits_needRelease;
  logic io_msInfo_13_bits_blockRefill;
  logic io_msInfo_13_bits_meta_dirty;
  logic [1:0] io_msInfo_13_bits_meta_state;
  logic io_msInfo_13_bits_meta_clients;
  logic [1:0] io_msInfo_13_bits_meta_alias;
  logic io_msInfo_13_bits_meta_prefetch;
  logic [2:0] io_msInfo_13_bits_meta_prefetchSrc;
  logic io_msInfo_13_bits_meta_accessed;
  logic io_msInfo_13_bits_meta_tagErr;
  logic io_msInfo_13_bits_meta_dataErr;
  logic [30:0] io_msInfo_13_bits_metaTag;
  logic io_msInfo_13_bits_dirHit;
  logic io_msInfo_13_bits_isAcqOrPrefetch;
  logic io_msInfo_13_bits_isPrefetch;
  logic [2:0] io_msInfo_13_bits_param;
  logic io_msInfo_13_bits_mergeA;
  logic io_msInfo_13_bits_w_grantfirst;
  logic io_msInfo_13_bits_s_release;
  logic io_msInfo_13_bits_s_refill;
  logic io_msInfo_13_bits_s_cmoresp;
  logic io_msInfo_13_bits_s_cmometaw;
  logic io_msInfo_13_bits_w_releaseack;
  logic io_msInfo_13_bits_w_replResp;
  logic io_msInfo_13_bits_w_rprobeacklast;
  logic io_msInfo_13_bits_replaceData;
  logic io_msInfo_13_bits_releaseToClean;
  logic io_msInfo_14_valid;
  logic [2:0] io_msInfo_14_bits_channel;
  logic [8:0] io_msInfo_14_bits_set;
  logic [2:0] io_msInfo_14_bits_way;
  logic [30:0] io_msInfo_14_bits_reqTag;
  logic io_msInfo_14_bits_willFree;
  logic io_msInfo_14_bits_aliasTask;
  logic io_msInfo_14_bits_needRelease;
  logic io_msInfo_14_bits_blockRefill;
  logic io_msInfo_14_bits_meta_dirty;
  logic [1:0] io_msInfo_14_bits_meta_state;
  logic io_msInfo_14_bits_meta_clients;
  logic [1:0] io_msInfo_14_bits_meta_alias;
  logic io_msInfo_14_bits_meta_prefetch;
  logic [2:0] io_msInfo_14_bits_meta_prefetchSrc;
  logic io_msInfo_14_bits_meta_accessed;
  logic io_msInfo_14_bits_meta_tagErr;
  logic io_msInfo_14_bits_meta_dataErr;
  logic [30:0] io_msInfo_14_bits_metaTag;
  logic io_msInfo_14_bits_dirHit;
  logic io_msInfo_14_bits_isAcqOrPrefetch;
  logic io_msInfo_14_bits_isPrefetch;
  logic [2:0] io_msInfo_14_bits_param;
  logic io_msInfo_14_bits_mergeA;
  logic io_msInfo_14_bits_w_grantfirst;
  logic io_msInfo_14_bits_s_release;
  logic io_msInfo_14_bits_s_refill;
  logic io_msInfo_14_bits_s_cmoresp;
  logic io_msInfo_14_bits_s_cmometaw;
  logic io_msInfo_14_bits_w_releaseack;
  logic io_msInfo_14_bits_w_replResp;
  logic io_msInfo_14_bits_w_rprobeacklast;
  logic io_msInfo_14_bits_replaceData;
  logic io_msInfo_14_bits_releaseToClean;
  logic io_msInfo_15_valid;
  logic [2:0] io_msInfo_15_bits_channel;
  logic [8:0] io_msInfo_15_bits_set;
  logic [2:0] io_msInfo_15_bits_way;
  logic [30:0] io_msInfo_15_bits_reqTag;
  logic io_msInfo_15_bits_willFree;
  logic io_msInfo_15_bits_aliasTask;
  logic io_msInfo_15_bits_needRelease;
  logic io_msInfo_15_bits_blockRefill;
  logic io_msInfo_15_bits_meta_dirty;
  logic [1:0] io_msInfo_15_bits_meta_state;
  logic io_msInfo_15_bits_meta_clients;
  logic [1:0] io_msInfo_15_bits_meta_alias;
  logic io_msInfo_15_bits_meta_prefetch;
  logic [2:0] io_msInfo_15_bits_meta_prefetchSrc;
  logic io_msInfo_15_bits_meta_accessed;
  logic io_msInfo_15_bits_meta_tagErr;
  logic io_msInfo_15_bits_meta_dataErr;
  logic [30:0] io_msInfo_15_bits_metaTag;
  logic io_msInfo_15_bits_dirHit;
  logic io_msInfo_15_bits_isAcqOrPrefetch;
  logic io_msInfo_15_bits_isPrefetch;
  logic [2:0] io_msInfo_15_bits_param;
  logic io_msInfo_15_bits_mergeA;
  logic io_msInfo_15_bits_w_grantfirst;
  logic io_msInfo_15_bits_s_release;
  logic io_msInfo_15_bits_s_refill;
  logic io_msInfo_15_bits_s_cmoresp;
  logic io_msInfo_15_bits_s_cmometaw;
  logic io_msInfo_15_bits_w_releaseack;
  logic io_msInfo_15_bits_w_replResp;
  logic io_msInfo_15_bits_w_rprobeacklast;
  logic io_msInfo_15_bits_replaceData;
  logic io_msInfo_15_bits_releaseToClean;
  wire g_io_sinkA_ready;
  wire i_io_sinkA_ready;
  wire g_io_s1Entrance_valid;
  wire i_io_s1Entrance_valid;
  wire [8:0] g_io_s1Entrance_bits_set;
  wire [8:0] i_io_s1Entrance_bits_set;
  wire g_io_sinkB_ready;
  wire i_io_sinkB_ready;
  wire g_io_sinkC_ready;
  wire i_io_sinkC_ready;
  wire g_io_mshrTask_ready;
  wire i_io_mshrTask_ready;
  wire g_io_dirRead_s1_valid;
  wire i_io_dirRead_s1_valid;
  wire [30:0] g_io_dirRead_s1_bits_tag;
  wire [30:0] i_io_dirRead_s1_bits_tag;
  wire [8:0] g_io_dirRead_s1_bits_set;
  wire [8:0] i_io_dirRead_s1_bits_set;
  wire [7:0] g_io_dirRead_s1_bits_wayMask;
  wire [7:0] i_io_dirRead_s1_bits_wayMask;
  wire [2:0] g_io_dirRead_s1_bits_replacerInfo_channel;
  wire [2:0] i_io_dirRead_s1_bits_replacerInfo_channel;
  wire [2:0] g_io_dirRead_s1_bits_replacerInfo_opcode;
  wire [2:0] i_io_dirRead_s1_bits_replacerInfo_opcode;
  wire [4:0] g_io_dirRead_s1_bits_replacerInfo_reqSource;
  wire [4:0] i_io_dirRead_s1_bits_replacerInfo_reqSource;
  wire g_io_dirRead_s1_bits_replacerInfo_refill_prefetch;
  wire i_io_dirRead_s1_bits_replacerInfo_refill_prefetch;
  wire g_io_dirRead_s1_bits_refill;
  wire i_io_dirRead_s1_bits_refill;
  wire [7:0] g_io_dirRead_s1_bits_mshrId;
  wire [7:0] i_io_dirRead_s1_bits_mshrId;
  wire g_io_dirRead_s1_bits_cmoAll;
  wire i_io_dirRead_s1_bits_cmoAll;
  wire [2:0] g_io_dirRead_s1_bits_cmoWay;
  wire [2:0] i_io_dirRead_s1_bits_cmoWay;
  wire g_io_taskToPipe_s2_valid;
  wire i_io_taskToPipe_s2_valid;
  wire [2:0] g_io_taskToPipe_s2_bits_channel;
  wire [2:0] i_io_taskToPipe_s2_bits_channel;
  wire [2:0] g_io_taskToPipe_s2_bits_txChannel;
  wire [2:0] i_io_taskToPipe_s2_bits_txChannel;
  wire [8:0] g_io_taskToPipe_s2_bits_set;
  wire [8:0] i_io_taskToPipe_s2_bits_set;
  wire [30:0] g_io_taskToPipe_s2_bits_tag;
  wire [30:0] i_io_taskToPipe_s2_bits_tag;
  wire [5:0] g_io_taskToPipe_s2_bits_off;
  wire [5:0] i_io_taskToPipe_s2_bits_off;
  wire [1:0] g_io_taskToPipe_s2_bits_alias;
  wire [1:0] i_io_taskToPipe_s2_bits_alias;
  wire [43:0] g_io_taskToPipe_s2_bits_vaddr;
  wire [43:0] i_io_taskToPipe_s2_bits_vaddr;
  wire g_io_taskToPipe_s2_bits_isKeyword;
  wire i_io_taskToPipe_s2_bits_isKeyword;
  wire [3:0] g_io_taskToPipe_s2_bits_opcode;
  wire [3:0] i_io_taskToPipe_s2_bits_opcode;
  wire [2:0] g_io_taskToPipe_s2_bits_param;
  wire [2:0] i_io_taskToPipe_s2_bits_param;
  wire [2:0] g_io_taskToPipe_s2_bits_size;
  wire [2:0] i_io_taskToPipe_s2_bits_size;
  wire [6:0] g_io_taskToPipe_s2_bits_sourceId;
  wire [6:0] i_io_taskToPipe_s2_bits_sourceId;
  wire [1:0] g_io_taskToPipe_s2_bits_bufIdx;
  wire [1:0] i_io_taskToPipe_s2_bits_bufIdx;
  wire g_io_taskToPipe_s2_bits_needProbeAckData;
  wire i_io_taskToPipe_s2_bits_needProbeAckData;
  wire g_io_taskToPipe_s2_bits_denied;
  wire i_io_taskToPipe_s2_bits_denied;
  wire g_io_taskToPipe_s2_bits_corrupt;
  wire i_io_taskToPipe_s2_bits_corrupt;
  wire g_io_taskToPipe_s2_bits_mshrTask;
  wire i_io_taskToPipe_s2_bits_mshrTask;
  wire [7:0] g_io_taskToPipe_s2_bits_mshrId;
  wire [7:0] i_io_taskToPipe_s2_bits_mshrId;
  wire g_io_taskToPipe_s2_bits_aliasTask;
  wire i_io_taskToPipe_s2_bits_aliasTask;
  wire g_io_taskToPipe_s2_bits_useProbeData;
  wire i_io_taskToPipe_s2_bits_useProbeData;
  wire g_io_taskToPipe_s2_bits_mshrRetry;
  wire i_io_taskToPipe_s2_bits_mshrRetry;
  wire g_io_taskToPipe_s2_bits_readProbeDataDown;
  wire i_io_taskToPipe_s2_bits_readProbeDataDown;
  wire g_io_taskToPipe_s2_bits_fromL2pft;
  wire i_io_taskToPipe_s2_bits_fromL2pft;
  wire g_io_taskToPipe_s2_bits_needHint;
  wire i_io_taskToPipe_s2_bits_needHint;
  wire g_io_taskToPipe_s2_bits_dirty;
  wire i_io_taskToPipe_s2_bits_dirty;
  wire [2:0] g_io_taskToPipe_s2_bits_way;
  wire [2:0] i_io_taskToPipe_s2_bits_way;
  wire g_io_taskToPipe_s2_bits_meta_dirty;
  wire i_io_taskToPipe_s2_bits_meta_dirty;
  wire [1:0] g_io_taskToPipe_s2_bits_meta_state;
  wire [1:0] i_io_taskToPipe_s2_bits_meta_state;
  wire g_io_taskToPipe_s2_bits_meta_clients;
  wire i_io_taskToPipe_s2_bits_meta_clients;
  wire [1:0] g_io_taskToPipe_s2_bits_meta_alias;
  wire [1:0] i_io_taskToPipe_s2_bits_meta_alias;
  wire g_io_taskToPipe_s2_bits_meta_prefetch;
  wire i_io_taskToPipe_s2_bits_meta_prefetch;
  wire [2:0] g_io_taskToPipe_s2_bits_meta_prefetchSrc;
  wire [2:0] i_io_taskToPipe_s2_bits_meta_prefetchSrc;
  wire g_io_taskToPipe_s2_bits_meta_accessed;
  wire i_io_taskToPipe_s2_bits_meta_accessed;
  wire g_io_taskToPipe_s2_bits_meta_tagErr;
  wire i_io_taskToPipe_s2_bits_meta_tagErr;
  wire g_io_taskToPipe_s2_bits_meta_dataErr;
  wire i_io_taskToPipe_s2_bits_meta_dataErr;
  wire g_io_taskToPipe_s2_bits_metaWen;
  wire i_io_taskToPipe_s2_bits_metaWen;
  wire g_io_taskToPipe_s2_bits_tagWen;
  wire i_io_taskToPipe_s2_bits_tagWen;
  wire g_io_taskToPipe_s2_bits_dsWen;
  wire i_io_taskToPipe_s2_bits_dsWen;
  wire [7:0] g_io_taskToPipe_s2_bits_wayMask;
  wire [7:0] i_io_taskToPipe_s2_bits_wayMask;
  wire g_io_taskToPipe_s2_bits_replTask;
  wire i_io_taskToPipe_s2_bits_replTask;
  wire g_io_taskToPipe_s2_bits_cmoTask;
  wire i_io_taskToPipe_s2_bits_cmoTask;
  wire g_io_taskToPipe_s2_bits_cmoAll;
  wire i_io_taskToPipe_s2_bits_cmoAll;
  wire [4:0] g_io_taskToPipe_s2_bits_reqSource;
  wire [4:0] i_io_taskToPipe_s2_bits_reqSource;
  wire g_io_taskToPipe_s2_bits_mergeA;
  wire i_io_taskToPipe_s2_bits_mergeA;
  wire [5:0] g_io_taskToPipe_s2_bits_aMergeTask_off;
  wire [5:0] i_io_taskToPipe_s2_bits_aMergeTask_off;
  wire [1:0] g_io_taskToPipe_s2_bits_aMergeTask_alias;
  wire [1:0] i_io_taskToPipe_s2_bits_aMergeTask_alias;
  wire [43:0] g_io_taskToPipe_s2_bits_aMergeTask_vaddr;
  wire [43:0] i_io_taskToPipe_s2_bits_aMergeTask_vaddr;
  wire g_io_taskToPipe_s2_bits_aMergeTask_isKeyword;
  wire i_io_taskToPipe_s2_bits_aMergeTask_isKeyword;
  wire [2:0] g_io_taskToPipe_s2_bits_aMergeTask_opcode;
  wire [2:0] i_io_taskToPipe_s2_bits_aMergeTask_opcode;
  wire [2:0] g_io_taskToPipe_s2_bits_aMergeTask_param;
  wire [2:0] i_io_taskToPipe_s2_bits_aMergeTask_param;
  wire [6:0] g_io_taskToPipe_s2_bits_aMergeTask_sourceId;
  wire [6:0] i_io_taskToPipe_s2_bits_aMergeTask_sourceId;
  wire g_io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  wire i_io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  wire [1:0] g_io_taskToPipe_s2_bits_aMergeTask_meta_state;
  wire [1:0] i_io_taskToPipe_s2_bits_aMergeTask_meta_state;
  wire g_io_taskToPipe_s2_bits_aMergeTask_meta_clients;
  wire i_io_taskToPipe_s2_bits_aMergeTask_meta_clients;
  wire [1:0] g_io_taskToPipe_s2_bits_aMergeTask_meta_alias;
  wire [1:0] i_io_taskToPipe_s2_bits_aMergeTask_meta_alias;
  wire g_io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  wire i_io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  wire [2:0] g_io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  wire [2:0] i_io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  wire g_io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  wire i_io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  wire g_io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  wire i_io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  wire g_io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  wire i_io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  wire g_io_taskToPipe_s2_bits_snpHitRelease;
  wire i_io_taskToPipe_s2_bits_snpHitRelease;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseToInval;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseToInval;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseToClean;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseToClean;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseWithData;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseWithData;
  wire [7:0] g_io_taskToPipe_s2_bits_snpHitReleaseIdx;
  wire [7:0] i_io_taskToPipe_s2_bits_snpHitReleaseIdx;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  wire [1:0] i_io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  wire [1:0] g_io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  wire [1:0] i_io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  wire g_io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  wire i_io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_taskToPipe_s2_bits_tgtID;
  wire [10:0] i_io_taskToPipe_s2_bits_tgtID;
  wire [10:0] g_io_taskToPipe_s2_bits_srcID;
  wire [10:0] i_io_taskToPipe_s2_bits_srcID;
  wire [11:0] g_io_taskToPipe_s2_bits_txnID;
  wire [11:0] i_io_taskToPipe_s2_bits_txnID;
  wire [10:0] g_io_taskToPipe_s2_bits_homeNID;
  wire [10:0] i_io_taskToPipe_s2_bits_homeNID;
  wire [11:0] g_io_taskToPipe_s2_bits_dbID;
  wire [11:0] i_io_taskToPipe_s2_bits_dbID;
  wire [10:0] g_io_taskToPipe_s2_bits_fwdNID;
  wire [10:0] i_io_taskToPipe_s2_bits_fwdNID;
  wire [11:0] g_io_taskToPipe_s2_bits_fwdTxnID;
  wire [11:0] i_io_taskToPipe_s2_bits_fwdTxnID;
  wire [6:0] g_io_taskToPipe_s2_bits_chiOpcode;
  wire [6:0] i_io_taskToPipe_s2_bits_chiOpcode;
  wire [2:0] g_io_taskToPipe_s2_bits_resp;
  wire [2:0] i_io_taskToPipe_s2_bits_resp;
  wire [2:0] g_io_taskToPipe_s2_bits_fwdState;
  wire [2:0] i_io_taskToPipe_s2_bits_fwdState;
  wire [3:0] g_io_taskToPipe_s2_bits_pCrdType;
  wire [3:0] i_io_taskToPipe_s2_bits_pCrdType;
  wire g_io_taskToPipe_s2_bits_retToSrc;
  wire i_io_taskToPipe_s2_bits_retToSrc;
  wire g_io_taskToPipe_s2_bits_likelyshared;
  wire i_io_taskToPipe_s2_bits_likelyshared;
  wire g_io_taskToPipe_s2_bits_expCompAck;
  wire i_io_taskToPipe_s2_bits_expCompAck;
  wire g_io_taskToPipe_s2_bits_allowRetry;
  wire i_io_taskToPipe_s2_bits_allowRetry;
  wire g_io_taskToPipe_s2_bits_memAttr_allocate;
  wire i_io_taskToPipe_s2_bits_memAttr_allocate;
  wire g_io_taskToPipe_s2_bits_memAttr_cacheable;
  wire i_io_taskToPipe_s2_bits_memAttr_cacheable;
  wire g_io_taskToPipe_s2_bits_memAttr_device;
  wire i_io_taskToPipe_s2_bits_memAttr_device;
  wire g_io_taskToPipe_s2_bits_memAttr_ewa;
  wire i_io_taskToPipe_s2_bits_memAttr_ewa;
  wire g_io_taskToPipe_s2_bits_traceTag;
  wire i_io_taskToPipe_s2_bits_traceTag;
  wire g_io_taskToPipe_s2_bits_dataCheckErr;
  wire i_io_taskToPipe_s2_bits_dataCheckErr;
  wire g_io_taskInfo_s1_valid;
  wire i_io_taskInfo_s1_valid;
  wire [2:0] g_io_taskInfo_s1_bits_channel;
  wire [2:0] i_io_taskInfo_s1_bits_channel;
  wire [2:0] g_io_taskInfo_s1_bits_txChannel;
  wire [2:0] i_io_taskInfo_s1_bits_txChannel;
  wire [8:0] g_io_taskInfo_s1_bits_set;
  wire [8:0] i_io_taskInfo_s1_bits_set;
  wire [30:0] g_io_taskInfo_s1_bits_tag;
  wire [30:0] i_io_taskInfo_s1_bits_tag;
  wire [5:0] g_io_taskInfo_s1_bits_off;
  wire [5:0] i_io_taskInfo_s1_bits_off;
  wire [1:0] g_io_taskInfo_s1_bits_alias;
  wire [1:0] i_io_taskInfo_s1_bits_alias;
  wire [43:0] g_io_taskInfo_s1_bits_vaddr;
  wire [43:0] i_io_taskInfo_s1_bits_vaddr;
  wire g_io_taskInfo_s1_bits_isKeyword;
  wire i_io_taskInfo_s1_bits_isKeyword;
  wire [3:0] g_io_taskInfo_s1_bits_opcode;
  wire [3:0] i_io_taskInfo_s1_bits_opcode;
  wire [2:0] g_io_taskInfo_s1_bits_param;
  wire [2:0] i_io_taskInfo_s1_bits_param;
  wire [2:0] g_io_taskInfo_s1_bits_size;
  wire [2:0] i_io_taskInfo_s1_bits_size;
  wire [6:0] g_io_taskInfo_s1_bits_sourceId;
  wire [6:0] i_io_taskInfo_s1_bits_sourceId;
  wire [1:0] g_io_taskInfo_s1_bits_bufIdx;
  wire [1:0] i_io_taskInfo_s1_bits_bufIdx;
  wire g_io_taskInfo_s1_bits_needProbeAckData;
  wire i_io_taskInfo_s1_bits_needProbeAckData;
  wire g_io_taskInfo_s1_bits_denied;
  wire i_io_taskInfo_s1_bits_denied;
  wire g_io_taskInfo_s1_bits_corrupt;
  wire i_io_taskInfo_s1_bits_corrupt;
  wire g_io_taskInfo_s1_bits_mshrTask;
  wire i_io_taskInfo_s1_bits_mshrTask;
  wire [7:0] g_io_taskInfo_s1_bits_mshrId;
  wire [7:0] i_io_taskInfo_s1_bits_mshrId;
  wire g_io_taskInfo_s1_bits_aliasTask;
  wire i_io_taskInfo_s1_bits_aliasTask;
  wire g_io_taskInfo_s1_bits_useProbeData;
  wire i_io_taskInfo_s1_bits_useProbeData;
  wire g_io_taskInfo_s1_bits_mshrRetry;
  wire i_io_taskInfo_s1_bits_mshrRetry;
  wire g_io_taskInfo_s1_bits_readProbeDataDown;
  wire i_io_taskInfo_s1_bits_readProbeDataDown;
  wire g_io_taskInfo_s1_bits_fromL2pft;
  wire i_io_taskInfo_s1_bits_fromL2pft;
  wire g_io_taskInfo_s1_bits_needHint;
  wire i_io_taskInfo_s1_bits_needHint;
  wire g_io_taskInfo_s1_bits_dirty;
  wire i_io_taskInfo_s1_bits_dirty;
  wire [2:0] g_io_taskInfo_s1_bits_way;
  wire [2:0] i_io_taskInfo_s1_bits_way;
  wire g_io_taskInfo_s1_bits_meta_dirty;
  wire i_io_taskInfo_s1_bits_meta_dirty;
  wire [1:0] g_io_taskInfo_s1_bits_meta_state;
  wire [1:0] i_io_taskInfo_s1_bits_meta_state;
  wire g_io_taskInfo_s1_bits_meta_clients;
  wire i_io_taskInfo_s1_bits_meta_clients;
  wire [1:0] g_io_taskInfo_s1_bits_meta_alias;
  wire [1:0] i_io_taskInfo_s1_bits_meta_alias;
  wire g_io_taskInfo_s1_bits_meta_prefetch;
  wire i_io_taskInfo_s1_bits_meta_prefetch;
  wire [2:0] g_io_taskInfo_s1_bits_meta_prefetchSrc;
  wire [2:0] i_io_taskInfo_s1_bits_meta_prefetchSrc;
  wire g_io_taskInfo_s1_bits_meta_accessed;
  wire i_io_taskInfo_s1_bits_meta_accessed;
  wire g_io_taskInfo_s1_bits_meta_tagErr;
  wire i_io_taskInfo_s1_bits_meta_tagErr;
  wire g_io_taskInfo_s1_bits_meta_dataErr;
  wire i_io_taskInfo_s1_bits_meta_dataErr;
  wire g_io_taskInfo_s1_bits_metaWen;
  wire i_io_taskInfo_s1_bits_metaWen;
  wire g_io_taskInfo_s1_bits_tagWen;
  wire i_io_taskInfo_s1_bits_tagWen;
  wire g_io_taskInfo_s1_bits_dsWen;
  wire i_io_taskInfo_s1_bits_dsWen;
  wire [7:0] g_io_taskInfo_s1_bits_wayMask;
  wire [7:0] i_io_taskInfo_s1_bits_wayMask;
  wire g_io_taskInfo_s1_bits_replTask;
  wire i_io_taskInfo_s1_bits_replTask;
  wire g_io_taskInfo_s1_bits_cmoTask;
  wire i_io_taskInfo_s1_bits_cmoTask;
  wire g_io_taskInfo_s1_bits_cmoAll;
  wire i_io_taskInfo_s1_bits_cmoAll;
  wire [4:0] g_io_taskInfo_s1_bits_reqSource;
  wire [4:0] i_io_taskInfo_s1_bits_reqSource;
  wire g_io_taskInfo_s1_bits_mergeA;
  wire i_io_taskInfo_s1_bits_mergeA;
  wire [5:0] g_io_taskInfo_s1_bits_aMergeTask_off;
  wire [5:0] i_io_taskInfo_s1_bits_aMergeTask_off;
  wire [1:0] g_io_taskInfo_s1_bits_aMergeTask_alias;
  wire [1:0] i_io_taskInfo_s1_bits_aMergeTask_alias;
  wire [43:0] g_io_taskInfo_s1_bits_aMergeTask_vaddr;
  wire [43:0] i_io_taskInfo_s1_bits_aMergeTask_vaddr;
  wire g_io_taskInfo_s1_bits_aMergeTask_isKeyword;
  wire i_io_taskInfo_s1_bits_aMergeTask_isKeyword;
  wire [2:0] g_io_taskInfo_s1_bits_aMergeTask_opcode;
  wire [2:0] i_io_taskInfo_s1_bits_aMergeTask_opcode;
  wire [2:0] g_io_taskInfo_s1_bits_aMergeTask_param;
  wire [2:0] i_io_taskInfo_s1_bits_aMergeTask_param;
  wire [6:0] g_io_taskInfo_s1_bits_aMergeTask_sourceId;
  wire [6:0] i_io_taskInfo_s1_bits_aMergeTask_sourceId;
  wire g_io_taskInfo_s1_bits_aMergeTask_meta_dirty;
  wire i_io_taskInfo_s1_bits_aMergeTask_meta_dirty;
  wire [1:0] g_io_taskInfo_s1_bits_aMergeTask_meta_state;
  wire [1:0] i_io_taskInfo_s1_bits_aMergeTask_meta_state;
  wire g_io_taskInfo_s1_bits_aMergeTask_meta_clients;
  wire i_io_taskInfo_s1_bits_aMergeTask_meta_clients;
  wire [1:0] g_io_taskInfo_s1_bits_aMergeTask_meta_alias;
  wire [1:0] i_io_taskInfo_s1_bits_aMergeTask_meta_alias;
  wire g_io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
  wire i_io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
  wire [2:0] g_io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
  wire [2:0] i_io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
  wire g_io_taskInfo_s1_bits_aMergeTask_meta_accessed;
  wire i_io_taskInfo_s1_bits_aMergeTask_meta_accessed;
  wire g_io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
  wire i_io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
  wire g_io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
  wire i_io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
  wire g_io_taskInfo_s1_bits_snpHitRelease;
  wire i_io_taskInfo_s1_bits_snpHitRelease;
  wire g_io_taskInfo_s1_bits_snpHitReleaseToInval;
  wire i_io_taskInfo_s1_bits_snpHitReleaseToInval;
  wire g_io_taskInfo_s1_bits_snpHitReleaseToClean;
  wire i_io_taskInfo_s1_bits_snpHitReleaseToClean;
  wire g_io_taskInfo_s1_bits_snpHitReleaseWithData;
  wire i_io_taskInfo_s1_bits_snpHitReleaseWithData;
  wire [7:0] g_io_taskInfo_s1_bits_snpHitReleaseIdx;
  wire [7:0] i_io_taskInfo_s1_bits_snpHitReleaseIdx;
  wire g_io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
  wire i_io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_taskInfo_s1_bits_snpHitReleaseMeta_state;
  wire [1:0] i_io_taskInfo_s1_bits_snpHitReleaseMeta_state;
  wire g_io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
  wire i_io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
  wire [1:0] g_io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
  wire [1:0] i_io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
  wire g_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
  wire i_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
  wire g_io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
  wire i_io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
  wire g_io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
  wire i_io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
  wire g_io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
  wire i_io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_taskInfo_s1_bits_tgtID;
  wire [10:0] i_io_taskInfo_s1_bits_tgtID;
  wire [10:0] g_io_taskInfo_s1_bits_srcID;
  wire [10:0] i_io_taskInfo_s1_bits_srcID;
  wire [11:0] g_io_taskInfo_s1_bits_txnID;
  wire [11:0] i_io_taskInfo_s1_bits_txnID;
  wire [10:0] g_io_taskInfo_s1_bits_homeNID;
  wire [10:0] i_io_taskInfo_s1_bits_homeNID;
  wire [11:0] g_io_taskInfo_s1_bits_dbID;
  wire [11:0] i_io_taskInfo_s1_bits_dbID;
  wire [10:0] g_io_taskInfo_s1_bits_fwdNID;
  wire [10:0] i_io_taskInfo_s1_bits_fwdNID;
  wire [11:0] g_io_taskInfo_s1_bits_fwdTxnID;
  wire [11:0] i_io_taskInfo_s1_bits_fwdTxnID;
  wire [6:0] g_io_taskInfo_s1_bits_chiOpcode;
  wire [6:0] i_io_taskInfo_s1_bits_chiOpcode;
  wire [2:0] g_io_taskInfo_s1_bits_resp;
  wire [2:0] i_io_taskInfo_s1_bits_resp;
  wire [2:0] g_io_taskInfo_s1_bits_fwdState;
  wire [2:0] i_io_taskInfo_s1_bits_fwdState;
  wire [3:0] g_io_taskInfo_s1_bits_pCrdType;
  wire [3:0] i_io_taskInfo_s1_bits_pCrdType;
  wire g_io_taskInfo_s1_bits_retToSrc;
  wire i_io_taskInfo_s1_bits_retToSrc;
  wire g_io_taskInfo_s1_bits_likelyshared;
  wire i_io_taskInfo_s1_bits_likelyshared;
  wire g_io_taskInfo_s1_bits_expCompAck;
  wire i_io_taskInfo_s1_bits_expCompAck;
  wire g_io_taskInfo_s1_bits_allowRetry;
  wire i_io_taskInfo_s1_bits_allowRetry;
  wire g_io_taskInfo_s1_bits_memAttr_allocate;
  wire i_io_taskInfo_s1_bits_memAttr_allocate;
  wire g_io_taskInfo_s1_bits_memAttr_cacheable;
  wire i_io_taskInfo_s1_bits_memAttr_cacheable;
  wire g_io_taskInfo_s1_bits_memAttr_device;
  wire i_io_taskInfo_s1_bits_memAttr_device;
  wire g_io_taskInfo_s1_bits_memAttr_ewa;
  wire i_io_taskInfo_s1_bits_memAttr_ewa;
  wire g_io_taskInfo_s1_bits_traceTag;
  wire i_io_taskInfo_s1_bits_traceTag;
  wire g_io_taskInfo_s1_bits_dataCheckErr;
  wire i_io_taskInfo_s1_bits_dataCheckErr;
  wire g_io_refillBufRead_s2_valid;
  wire i_io_refillBufRead_s2_valid;
  wire [7:0] g_io_refillBufRead_s2_bits_id;
  wire [7:0] i_io_refillBufRead_s2_bits_id;
  wire g_io_releaseBufRead_s2_valid;
  wire i_io_releaseBufRead_s2_valid;
  wire [7:0] g_io_releaseBufRead_s2_bits_id;
  wire [7:0] i_io_releaseBufRead_s2_bits_id;
  wire [30:0] g_io_status_s1_tags_0;
  wire [30:0] i_io_status_s1_tags_0;
  wire [30:0] g_io_status_s1_tags_1;
  wire [30:0] i_io_status_s1_tags_1;
  wire [30:0] g_io_status_s1_tags_2;
  wire [30:0] i_io_status_s1_tags_2;
  wire [30:0] g_io_status_s1_tags_3;
  wire [30:0] i_io_status_s1_tags_3;
  wire [8:0] g_io_status_s1_sets_0;
  wire [8:0] i_io_status_s1_sets_0;
  wire [8:0] g_io_status_s1_sets_1;
  wire [8:0] i_io_status_s1_sets_1;
  wire [8:0] g_io_status_s1_sets_2;
  wire [8:0] i_io_status_s1_sets_2;
  wire [8:0] g_io_status_s1_sets_3;
  wire [8:0] i_io_status_s1_sets_3;
  wire g_io_status_vec_0_valid;
  wire i_io_status_vec_0_valid;
  wire [2:0] g_io_status_vec_0_bits_channel;
  wire [2:0] i_io_status_vec_0_bits_channel;
  wire g_io_status_vec_1_valid;
  wire i_io_status_vec_1_valid;
  wire [2:0] g_io_status_vec_1_bits_channel;
  wire [2:0] i_io_status_vec_1_bits_channel;
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

  RequestArb u_g (
    .clock(clock),
    .reset(reset),
    .io_sinkA_ready(g_io_sinkA_ready),
    .io_sinkA_valid(io_sinkA_valid),
    .io_sinkA_bits_channel(io_sinkA_bits_channel),
    .io_sinkA_bits_txChannel(io_sinkA_bits_txChannel),
    .io_sinkA_bits_set(io_sinkA_bits_set),
    .io_sinkA_bits_tag(io_sinkA_bits_tag),
    .io_sinkA_bits_off(io_sinkA_bits_off),
    .io_sinkA_bits_alias(io_sinkA_bits_alias),
    .io_sinkA_bits_vaddr(io_sinkA_bits_vaddr),
    .io_sinkA_bits_isKeyword(io_sinkA_bits_isKeyword),
    .io_sinkA_bits_opcode(io_sinkA_bits_opcode),
    .io_sinkA_bits_param(io_sinkA_bits_param),
    .io_sinkA_bits_size(io_sinkA_bits_size),
    .io_sinkA_bits_sourceId(io_sinkA_bits_sourceId),
    .io_sinkA_bits_bufIdx(io_sinkA_bits_bufIdx),
    .io_sinkA_bits_needProbeAckData(io_sinkA_bits_needProbeAckData),
    .io_sinkA_bits_denied(io_sinkA_bits_denied),
    .io_sinkA_bits_corrupt(io_sinkA_bits_corrupt),
    .io_sinkA_bits_mshrTask(io_sinkA_bits_mshrTask),
    .io_sinkA_bits_mshrId(io_sinkA_bits_mshrId),
    .io_sinkA_bits_aliasTask(io_sinkA_bits_aliasTask),
    .io_sinkA_bits_useProbeData(io_sinkA_bits_useProbeData),
    .io_sinkA_bits_mshrRetry(io_sinkA_bits_mshrRetry),
    .io_sinkA_bits_readProbeDataDown(io_sinkA_bits_readProbeDataDown),
    .io_sinkA_bits_fromL2pft(io_sinkA_bits_fromL2pft),
    .io_sinkA_bits_needHint(io_sinkA_bits_needHint),
    .io_sinkA_bits_dirty(io_sinkA_bits_dirty),
    .io_sinkA_bits_way(io_sinkA_bits_way),
    .io_sinkA_bits_meta_dirty(io_sinkA_bits_meta_dirty),
    .io_sinkA_bits_meta_state(io_sinkA_bits_meta_state),
    .io_sinkA_bits_meta_clients(io_sinkA_bits_meta_clients),
    .io_sinkA_bits_meta_alias(io_sinkA_bits_meta_alias),
    .io_sinkA_bits_meta_prefetch(io_sinkA_bits_meta_prefetch),
    .io_sinkA_bits_meta_prefetchSrc(io_sinkA_bits_meta_prefetchSrc),
    .io_sinkA_bits_meta_accessed(io_sinkA_bits_meta_accessed),
    .io_sinkA_bits_meta_tagErr(io_sinkA_bits_meta_tagErr),
    .io_sinkA_bits_meta_dataErr(io_sinkA_bits_meta_dataErr),
    .io_sinkA_bits_metaWen(io_sinkA_bits_metaWen),
    .io_sinkA_bits_tagWen(io_sinkA_bits_tagWen),
    .io_sinkA_bits_dsWen(io_sinkA_bits_dsWen),
    .io_sinkA_bits_wayMask(io_sinkA_bits_wayMask),
    .io_sinkA_bits_replTask(io_sinkA_bits_replTask),
    .io_sinkA_bits_cmoTask(io_sinkA_bits_cmoTask),
    .io_sinkA_bits_cmoAll(io_sinkA_bits_cmoAll),
    .io_sinkA_bits_reqSource(io_sinkA_bits_reqSource),
    .io_sinkA_bits_mergeA(io_sinkA_bits_mergeA),
    .io_sinkA_bits_aMergeTask_off(io_sinkA_bits_aMergeTask_off),
    .io_sinkA_bits_aMergeTask_alias(io_sinkA_bits_aMergeTask_alias),
    .io_sinkA_bits_aMergeTask_vaddr(io_sinkA_bits_aMergeTask_vaddr),
    .io_sinkA_bits_aMergeTask_isKeyword(io_sinkA_bits_aMergeTask_isKeyword),
    .io_sinkA_bits_aMergeTask_opcode(io_sinkA_bits_aMergeTask_opcode),
    .io_sinkA_bits_aMergeTask_param(io_sinkA_bits_aMergeTask_param),
    .io_sinkA_bits_aMergeTask_sourceId(io_sinkA_bits_aMergeTask_sourceId),
    .io_sinkA_bits_aMergeTask_meta_dirty(io_sinkA_bits_aMergeTask_meta_dirty),
    .io_sinkA_bits_aMergeTask_meta_state(io_sinkA_bits_aMergeTask_meta_state),
    .io_sinkA_bits_aMergeTask_meta_clients(io_sinkA_bits_aMergeTask_meta_clients),
    .io_sinkA_bits_aMergeTask_meta_alias(io_sinkA_bits_aMergeTask_meta_alias),
    .io_sinkA_bits_aMergeTask_meta_prefetch(io_sinkA_bits_aMergeTask_meta_prefetch),
    .io_sinkA_bits_aMergeTask_meta_prefetchSrc(io_sinkA_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkA_bits_aMergeTask_meta_accessed(io_sinkA_bits_aMergeTask_meta_accessed),
    .io_sinkA_bits_aMergeTask_meta_tagErr(io_sinkA_bits_aMergeTask_meta_tagErr),
    .io_sinkA_bits_aMergeTask_meta_dataErr(io_sinkA_bits_aMergeTask_meta_dataErr),
    .io_sinkA_bits_snpHitRelease(io_sinkA_bits_snpHitRelease),
    .io_sinkA_bits_snpHitReleaseToInval(io_sinkA_bits_snpHitReleaseToInval),
    .io_sinkA_bits_snpHitReleaseToClean(io_sinkA_bits_snpHitReleaseToClean),
    .io_sinkA_bits_snpHitReleaseWithData(io_sinkA_bits_snpHitReleaseWithData),
    .io_sinkA_bits_snpHitReleaseIdx(io_sinkA_bits_snpHitReleaseIdx),
    .io_sinkA_bits_snpHitReleaseMeta_dirty(io_sinkA_bits_snpHitReleaseMeta_dirty),
    .io_sinkA_bits_snpHitReleaseMeta_state(io_sinkA_bits_snpHitReleaseMeta_state),
    .io_sinkA_bits_snpHitReleaseMeta_clients(io_sinkA_bits_snpHitReleaseMeta_clients),
    .io_sinkA_bits_snpHitReleaseMeta_alias(io_sinkA_bits_snpHitReleaseMeta_alias),
    .io_sinkA_bits_snpHitReleaseMeta_prefetch(io_sinkA_bits_snpHitReleaseMeta_prefetch),
    .io_sinkA_bits_snpHitReleaseMeta_prefetchSrc(io_sinkA_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkA_bits_snpHitReleaseMeta_accessed(io_sinkA_bits_snpHitReleaseMeta_accessed),
    .io_sinkA_bits_snpHitReleaseMeta_tagErr(io_sinkA_bits_snpHitReleaseMeta_tagErr),
    .io_sinkA_bits_snpHitReleaseMeta_dataErr(io_sinkA_bits_snpHitReleaseMeta_dataErr),
    .io_sinkA_bits_tgtID(io_sinkA_bits_tgtID),
    .io_sinkA_bits_srcID(io_sinkA_bits_srcID),
    .io_sinkA_bits_txnID(io_sinkA_bits_txnID),
    .io_sinkA_bits_homeNID(io_sinkA_bits_homeNID),
    .io_sinkA_bits_dbID(io_sinkA_bits_dbID),
    .io_sinkA_bits_fwdNID(io_sinkA_bits_fwdNID),
    .io_sinkA_bits_fwdTxnID(io_sinkA_bits_fwdTxnID),
    .io_sinkA_bits_chiOpcode(io_sinkA_bits_chiOpcode),
    .io_sinkA_bits_resp(io_sinkA_bits_resp),
    .io_sinkA_bits_fwdState(io_sinkA_bits_fwdState),
    .io_sinkA_bits_pCrdType(io_sinkA_bits_pCrdType),
    .io_sinkA_bits_retToSrc(io_sinkA_bits_retToSrc),
    .io_sinkA_bits_likelyshared(io_sinkA_bits_likelyshared),
    .io_sinkA_bits_expCompAck(io_sinkA_bits_expCompAck),
    .io_sinkA_bits_allowRetry(io_sinkA_bits_allowRetry),
    .io_sinkA_bits_memAttr_allocate(io_sinkA_bits_memAttr_allocate),
    .io_sinkA_bits_memAttr_cacheable(io_sinkA_bits_memAttr_cacheable),
    .io_sinkA_bits_memAttr_device(io_sinkA_bits_memAttr_device),
    .io_sinkA_bits_memAttr_ewa(io_sinkA_bits_memAttr_ewa),
    .io_sinkA_bits_traceTag(io_sinkA_bits_traceTag),
    .io_sinkA_bits_dataCheckErr(io_sinkA_bits_dataCheckErr),
    .io_ATag(io_ATag),
    .io_ASet(io_ASet),
    .io_s1Entrance_valid(g_io_s1Entrance_valid),
    .io_s1Entrance_bits_set(g_io_s1Entrance_bits_set),
    .io_sinkB_ready(g_io_sinkB_ready),
    .io_sinkB_valid(io_sinkB_valid),
    .io_sinkB_bits_channel(io_sinkB_bits_channel),
    .io_sinkB_bits_txChannel(io_sinkB_bits_txChannel),
    .io_sinkB_bits_set(io_sinkB_bits_set),
    .io_sinkB_bits_tag(io_sinkB_bits_tag),
    .io_sinkB_bits_off(io_sinkB_bits_off),
    .io_sinkB_bits_alias(io_sinkB_bits_alias),
    .io_sinkB_bits_vaddr(io_sinkB_bits_vaddr),
    .io_sinkB_bits_isKeyword(io_sinkB_bits_isKeyword),
    .io_sinkB_bits_opcode(io_sinkB_bits_opcode),
    .io_sinkB_bits_param(io_sinkB_bits_param),
    .io_sinkB_bits_size(io_sinkB_bits_size),
    .io_sinkB_bits_sourceId(io_sinkB_bits_sourceId),
    .io_sinkB_bits_bufIdx(io_sinkB_bits_bufIdx),
    .io_sinkB_bits_needProbeAckData(io_sinkB_bits_needProbeAckData),
    .io_sinkB_bits_denied(io_sinkB_bits_denied),
    .io_sinkB_bits_corrupt(io_sinkB_bits_corrupt),
    .io_sinkB_bits_mshrTask(io_sinkB_bits_mshrTask),
    .io_sinkB_bits_mshrId(io_sinkB_bits_mshrId),
    .io_sinkB_bits_aliasTask(io_sinkB_bits_aliasTask),
    .io_sinkB_bits_useProbeData(io_sinkB_bits_useProbeData),
    .io_sinkB_bits_mshrRetry(io_sinkB_bits_mshrRetry),
    .io_sinkB_bits_readProbeDataDown(io_sinkB_bits_readProbeDataDown),
    .io_sinkB_bits_fromL2pft(io_sinkB_bits_fromL2pft),
    .io_sinkB_bits_needHint(io_sinkB_bits_needHint),
    .io_sinkB_bits_dirty(io_sinkB_bits_dirty),
    .io_sinkB_bits_way(io_sinkB_bits_way),
    .io_sinkB_bits_meta_dirty(io_sinkB_bits_meta_dirty),
    .io_sinkB_bits_meta_state(io_sinkB_bits_meta_state),
    .io_sinkB_bits_meta_clients(io_sinkB_bits_meta_clients),
    .io_sinkB_bits_meta_alias(io_sinkB_bits_meta_alias),
    .io_sinkB_bits_meta_prefetch(io_sinkB_bits_meta_prefetch),
    .io_sinkB_bits_meta_prefetchSrc(io_sinkB_bits_meta_prefetchSrc),
    .io_sinkB_bits_meta_accessed(io_sinkB_bits_meta_accessed),
    .io_sinkB_bits_meta_tagErr(io_sinkB_bits_meta_tagErr),
    .io_sinkB_bits_meta_dataErr(io_sinkB_bits_meta_dataErr),
    .io_sinkB_bits_metaWen(io_sinkB_bits_metaWen),
    .io_sinkB_bits_tagWen(io_sinkB_bits_tagWen),
    .io_sinkB_bits_dsWen(io_sinkB_bits_dsWen),
    .io_sinkB_bits_wayMask(io_sinkB_bits_wayMask),
    .io_sinkB_bits_replTask(io_sinkB_bits_replTask),
    .io_sinkB_bits_cmoTask(io_sinkB_bits_cmoTask),
    .io_sinkB_bits_cmoAll(io_sinkB_bits_cmoAll),
    .io_sinkB_bits_reqSource(io_sinkB_bits_reqSource),
    .io_sinkB_bits_mergeA(io_sinkB_bits_mergeA),
    .io_sinkB_bits_aMergeTask_off(io_sinkB_bits_aMergeTask_off),
    .io_sinkB_bits_aMergeTask_alias(io_sinkB_bits_aMergeTask_alias),
    .io_sinkB_bits_aMergeTask_vaddr(io_sinkB_bits_aMergeTask_vaddr),
    .io_sinkB_bits_aMergeTask_isKeyword(io_sinkB_bits_aMergeTask_isKeyword),
    .io_sinkB_bits_aMergeTask_opcode(io_sinkB_bits_aMergeTask_opcode),
    .io_sinkB_bits_aMergeTask_param(io_sinkB_bits_aMergeTask_param),
    .io_sinkB_bits_aMergeTask_sourceId(io_sinkB_bits_aMergeTask_sourceId),
    .io_sinkB_bits_aMergeTask_meta_dirty(io_sinkB_bits_aMergeTask_meta_dirty),
    .io_sinkB_bits_aMergeTask_meta_state(io_sinkB_bits_aMergeTask_meta_state),
    .io_sinkB_bits_aMergeTask_meta_clients(io_sinkB_bits_aMergeTask_meta_clients),
    .io_sinkB_bits_aMergeTask_meta_alias(io_sinkB_bits_aMergeTask_meta_alias),
    .io_sinkB_bits_aMergeTask_meta_prefetch(io_sinkB_bits_aMergeTask_meta_prefetch),
    .io_sinkB_bits_aMergeTask_meta_prefetchSrc(io_sinkB_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkB_bits_aMergeTask_meta_accessed(io_sinkB_bits_aMergeTask_meta_accessed),
    .io_sinkB_bits_aMergeTask_meta_tagErr(io_sinkB_bits_aMergeTask_meta_tagErr),
    .io_sinkB_bits_aMergeTask_meta_dataErr(io_sinkB_bits_aMergeTask_meta_dataErr),
    .io_sinkB_bits_snpHitRelease(io_sinkB_bits_snpHitRelease),
    .io_sinkB_bits_snpHitReleaseToInval(io_sinkB_bits_snpHitReleaseToInval),
    .io_sinkB_bits_snpHitReleaseToClean(io_sinkB_bits_snpHitReleaseToClean),
    .io_sinkB_bits_snpHitReleaseWithData(io_sinkB_bits_snpHitReleaseWithData),
    .io_sinkB_bits_snpHitReleaseIdx(io_sinkB_bits_snpHitReleaseIdx),
    .io_sinkB_bits_snpHitReleaseMeta_dirty(io_sinkB_bits_snpHitReleaseMeta_dirty),
    .io_sinkB_bits_snpHitReleaseMeta_state(io_sinkB_bits_snpHitReleaseMeta_state),
    .io_sinkB_bits_snpHitReleaseMeta_clients(io_sinkB_bits_snpHitReleaseMeta_clients),
    .io_sinkB_bits_snpHitReleaseMeta_alias(io_sinkB_bits_snpHitReleaseMeta_alias),
    .io_sinkB_bits_snpHitReleaseMeta_prefetch(io_sinkB_bits_snpHitReleaseMeta_prefetch),
    .io_sinkB_bits_snpHitReleaseMeta_prefetchSrc(io_sinkB_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkB_bits_snpHitReleaseMeta_accessed(io_sinkB_bits_snpHitReleaseMeta_accessed),
    .io_sinkB_bits_snpHitReleaseMeta_tagErr(io_sinkB_bits_snpHitReleaseMeta_tagErr),
    .io_sinkB_bits_snpHitReleaseMeta_dataErr(io_sinkB_bits_snpHitReleaseMeta_dataErr),
    .io_sinkB_bits_tgtID(io_sinkB_bits_tgtID),
    .io_sinkB_bits_srcID(io_sinkB_bits_srcID),
    .io_sinkB_bits_txnID(io_sinkB_bits_txnID),
    .io_sinkB_bits_homeNID(io_sinkB_bits_homeNID),
    .io_sinkB_bits_dbID(io_sinkB_bits_dbID),
    .io_sinkB_bits_fwdNID(io_sinkB_bits_fwdNID),
    .io_sinkB_bits_fwdTxnID(io_sinkB_bits_fwdTxnID),
    .io_sinkB_bits_chiOpcode(io_sinkB_bits_chiOpcode),
    .io_sinkB_bits_resp(io_sinkB_bits_resp),
    .io_sinkB_bits_fwdState(io_sinkB_bits_fwdState),
    .io_sinkB_bits_pCrdType(io_sinkB_bits_pCrdType),
    .io_sinkB_bits_retToSrc(io_sinkB_bits_retToSrc),
    .io_sinkB_bits_likelyshared(io_sinkB_bits_likelyshared),
    .io_sinkB_bits_expCompAck(io_sinkB_bits_expCompAck),
    .io_sinkB_bits_allowRetry(io_sinkB_bits_allowRetry),
    .io_sinkB_bits_memAttr_allocate(io_sinkB_bits_memAttr_allocate),
    .io_sinkB_bits_memAttr_cacheable(io_sinkB_bits_memAttr_cacheable),
    .io_sinkB_bits_memAttr_device(io_sinkB_bits_memAttr_device),
    .io_sinkB_bits_memAttr_ewa(io_sinkB_bits_memAttr_ewa),
    .io_sinkB_bits_traceTag(io_sinkB_bits_traceTag),
    .io_sinkB_bits_dataCheckErr(io_sinkB_bits_dataCheckErr),
    .io_sinkC_ready(g_io_sinkC_ready),
    .io_sinkC_valid(io_sinkC_valid),
    .io_sinkC_bits_channel(io_sinkC_bits_channel),
    .io_sinkC_bits_txChannel(io_sinkC_bits_txChannel),
    .io_sinkC_bits_set(io_sinkC_bits_set),
    .io_sinkC_bits_tag(io_sinkC_bits_tag),
    .io_sinkC_bits_off(io_sinkC_bits_off),
    .io_sinkC_bits_alias(io_sinkC_bits_alias),
    .io_sinkC_bits_vaddr(io_sinkC_bits_vaddr),
    .io_sinkC_bits_isKeyword(io_sinkC_bits_isKeyword),
    .io_sinkC_bits_opcode(io_sinkC_bits_opcode),
    .io_sinkC_bits_param(io_sinkC_bits_param),
    .io_sinkC_bits_size(io_sinkC_bits_size),
    .io_sinkC_bits_sourceId(io_sinkC_bits_sourceId),
    .io_sinkC_bits_bufIdx(io_sinkC_bits_bufIdx),
    .io_sinkC_bits_needProbeAckData(io_sinkC_bits_needProbeAckData),
    .io_sinkC_bits_denied(io_sinkC_bits_denied),
    .io_sinkC_bits_corrupt(io_sinkC_bits_corrupt),
    .io_sinkC_bits_mshrTask(io_sinkC_bits_mshrTask),
    .io_sinkC_bits_mshrId(io_sinkC_bits_mshrId),
    .io_sinkC_bits_aliasTask(io_sinkC_bits_aliasTask),
    .io_sinkC_bits_useProbeData(io_sinkC_bits_useProbeData),
    .io_sinkC_bits_mshrRetry(io_sinkC_bits_mshrRetry),
    .io_sinkC_bits_readProbeDataDown(io_sinkC_bits_readProbeDataDown),
    .io_sinkC_bits_fromL2pft(io_sinkC_bits_fromL2pft),
    .io_sinkC_bits_needHint(io_sinkC_bits_needHint),
    .io_sinkC_bits_dirty(io_sinkC_bits_dirty),
    .io_sinkC_bits_way(io_sinkC_bits_way),
    .io_sinkC_bits_meta_dirty(io_sinkC_bits_meta_dirty),
    .io_sinkC_bits_meta_state(io_sinkC_bits_meta_state),
    .io_sinkC_bits_meta_clients(io_sinkC_bits_meta_clients),
    .io_sinkC_bits_meta_alias(io_sinkC_bits_meta_alias),
    .io_sinkC_bits_meta_prefetch(io_sinkC_bits_meta_prefetch),
    .io_sinkC_bits_meta_prefetchSrc(io_sinkC_bits_meta_prefetchSrc),
    .io_sinkC_bits_meta_accessed(io_sinkC_bits_meta_accessed),
    .io_sinkC_bits_meta_tagErr(io_sinkC_bits_meta_tagErr),
    .io_sinkC_bits_meta_dataErr(io_sinkC_bits_meta_dataErr),
    .io_sinkC_bits_metaWen(io_sinkC_bits_metaWen),
    .io_sinkC_bits_tagWen(io_sinkC_bits_tagWen),
    .io_sinkC_bits_dsWen(io_sinkC_bits_dsWen),
    .io_sinkC_bits_wayMask(io_sinkC_bits_wayMask),
    .io_sinkC_bits_replTask(io_sinkC_bits_replTask),
    .io_sinkC_bits_cmoTask(io_sinkC_bits_cmoTask),
    .io_sinkC_bits_cmoAll(io_sinkC_bits_cmoAll),
    .io_sinkC_bits_reqSource(io_sinkC_bits_reqSource),
    .io_sinkC_bits_mergeA(io_sinkC_bits_mergeA),
    .io_sinkC_bits_aMergeTask_off(io_sinkC_bits_aMergeTask_off),
    .io_sinkC_bits_aMergeTask_alias(io_sinkC_bits_aMergeTask_alias),
    .io_sinkC_bits_aMergeTask_vaddr(io_sinkC_bits_aMergeTask_vaddr),
    .io_sinkC_bits_aMergeTask_isKeyword(io_sinkC_bits_aMergeTask_isKeyword),
    .io_sinkC_bits_aMergeTask_opcode(io_sinkC_bits_aMergeTask_opcode),
    .io_sinkC_bits_aMergeTask_param(io_sinkC_bits_aMergeTask_param),
    .io_sinkC_bits_aMergeTask_sourceId(io_sinkC_bits_aMergeTask_sourceId),
    .io_sinkC_bits_aMergeTask_meta_dirty(io_sinkC_bits_aMergeTask_meta_dirty),
    .io_sinkC_bits_aMergeTask_meta_state(io_sinkC_bits_aMergeTask_meta_state),
    .io_sinkC_bits_aMergeTask_meta_clients(io_sinkC_bits_aMergeTask_meta_clients),
    .io_sinkC_bits_aMergeTask_meta_alias(io_sinkC_bits_aMergeTask_meta_alias),
    .io_sinkC_bits_aMergeTask_meta_prefetch(io_sinkC_bits_aMergeTask_meta_prefetch),
    .io_sinkC_bits_aMergeTask_meta_prefetchSrc(io_sinkC_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkC_bits_aMergeTask_meta_accessed(io_sinkC_bits_aMergeTask_meta_accessed),
    .io_sinkC_bits_aMergeTask_meta_tagErr(io_sinkC_bits_aMergeTask_meta_tagErr),
    .io_sinkC_bits_aMergeTask_meta_dataErr(io_sinkC_bits_aMergeTask_meta_dataErr),
    .io_sinkC_bits_snpHitRelease(io_sinkC_bits_snpHitRelease),
    .io_sinkC_bits_snpHitReleaseToInval(io_sinkC_bits_snpHitReleaseToInval),
    .io_sinkC_bits_snpHitReleaseToClean(io_sinkC_bits_snpHitReleaseToClean),
    .io_sinkC_bits_snpHitReleaseWithData(io_sinkC_bits_snpHitReleaseWithData),
    .io_sinkC_bits_snpHitReleaseIdx(io_sinkC_bits_snpHitReleaseIdx),
    .io_sinkC_bits_snpHitReleaseMeta_dirty(io_sinkC_bits_snpHitReleaseMeta_dirty),
    .io_sinkC_bits_snpHitReleaseMeta_state(io_sinkC_bits_snpHitReleaseMeta_state),
    .io_sinkC_bits_snpHitReleaseMeta_clients(io_sinkC_bits_snpHitReleaseMeta_clients),
    .io_sinkC_bits_snpHitReleaseMeta_alias(io_sinkC_bits_snpHitReleaseMeta_alias),
    .io_sinkC_bits_snpHitReleaseMeta_prefetch(io_sinkC_bits_snpHitReleaseMeta_prefetch),
    .io_sinkC_bits_snpHitReleaseMeta_prefetchSrc(io_sinkC_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkC_bits_snpHitReleaseMeta_accessed(io_sinkC_bits_snpHitReleaseMeta_accessed),
    .io_sinkC_bits_snpHitReleaseMeta_tagErr(io_sinkC_bits_snpHitReleaseMeta_tagErr),
    .io_sinkC_bits_snpHitReleaseMeta_dataErr(io_sinkC_bits_snpHitReleaseMeta_dataErr),
    .io_sinkC_bits_tgtID(io_sinkC_bits_tgtID),
    .io_sinkC_bits_srcID(io_sinkC_bits_srcID),
    .io_sinkC_bits_txnID(io_sinkC_bits_txnID),
    .io_sinkC_bits_homeNID(io_sinkC_bits_homeNID),
    .io_sinkC_bits_dbID(io_sinkC_bits_dbID),
    .io_sinkC_bits_fwdNID(io_sinkC_bits_fwdNID),
    .io_sinkC_bits_fwdTxnID(io_sinkC_bits_fwdTxnID),
    .io_sinkC_bits_chiOpcode(io_sinkC_bits_chiOpcode),
    .io_sinkC_bits_resp(io_sinkC_bits_resp),
    .io_sinkC_bits_fwdState(io_sinkC_bits_fwdState),
    .io_sinkC_bits_pCrdType(io_sinkC_bits_pCrdType),
    .io_sinkC_bits_retToSrc(io_sinkC_bits_retToSrc),
    .io_sinkC_bits_likelyshared(io_sinkC_bits_likelyshared),
    .io_sinkC_bits_expCompAck(io_sinkC_bits_expCompAck),
    .io_sinkC_bits_allowRetry(io_sinkC_bits_allowRetry),
    .io_sinkC_bits_memAttr_allocate(io_sinkC_bits_memAttr_allocate),
    .io_sinkC_bits_memAttr_cacheable(io_sinkC_bits_memAttr_cacheable),
    .io_sinkC_bits_memAttr_device(io_sinkC_bits_memAttr_device),
    .io_sinkC_bits_memAttr_ewa(io_sinkC_bits_memAttr_ewa),
    .io_sinkC_bits_traceTag(io_sinkC_bits_traceTag),
    .io_sinkC_bits_dataCheckErr(io_sinkC_bits_dataCheckErr),
    .io_mshrTask_ready(g_io_mshrTask_ready),
    .io_mshrTask_valid(io_mshrTask_valid),
    .io_mshrTask_bits_channel(io_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel(io_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set(io_mshrTask_bits_set),
    .io_mshrTask_bits_tag(io_mshrTask_bits_tag),
    .io_mshrTask_bits_off(io_mshrTask_bits_off),
    .io_mshrTask_bits_alias(io_mshrTask_bits_alias),
    .io_mshrTask_bits_vaddr(io_mshrTask_bits_vaddr),
    .io_mshrTask_bits_isKeyword(io_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode(io_mshrTask_bits_opcode),
    .io_mshrTask_bits_param(io_mshrTask_bits_param),
    .io_mshrTask_bits_size(io_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId(io_mshrTask_bits_sourceId),
    .io_mshrTask_bits_bufIdx(io_mshrTask_bits_bufIdx),
    .io_mshrTask_bits_needProbeAckData(io_mshrTask_bits_needProbeAckData),
    .io_mshrTask_bits_denied(io_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt(io_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask(io_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId(io_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask(io_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData(io_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry(io_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown(io_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft(io_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_needHint(io_mshrTask_bits_needHint),
    .io_mshrTask_bits_dirty(io_mshrTask_bits_dirty),
    .io_mshrTask_bits_way(io_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty(io_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state(io_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients(io_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias(io_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch(io_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc(io_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed(io_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr(io_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr(io_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen(io_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen(io_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen(io_mshrTask_bits_dsWen),
    .io_mshrTask_bits_wayMask(io_mshrTask_bits_wayMask),
    .io_mshrTask_bits_replTask(io_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask(io_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_cmoAll(io_mshrTask_bits_cmoAll),
    .io_mshrTask_bits_reqSource(io_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA(io_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off(io_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias(io_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr(io_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword(io_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode(io_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param(io_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId(io_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty(io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state(io_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients(io_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias(io_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_prefetch(io_mshrTask_bits_aMergeTask_meta_prefetch),
    .io_mshrTask_bits_aMergeTask_meta_prefetchSrc(io_mshrTask_bits_aMergeTask_meta_prefetchSrc),
    .io_mshrTask_bits_aMergeTask_meta_accessed(io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_aMergeTask_meta_tagErr(io_mshrTask_bits_aMergeTask_meta_tagErr),
    .io_mshrTask_bits_aMergeTask_meta_dataErr(io_mshrTask_bits_aMergeTask_meta_dataErr),
    .io_mshrTask_bits_snpHitRelease(io_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval(io_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean(io_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData(io_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx(io_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty(io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state(io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients(io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias(io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch(io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc(io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed(io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr(io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr(io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID(io_mshrTask_bits_tgtID),
    .io_mshrTask_bits_srcID(io_mshrTask_bits_srcID),
    .io_mshrTask_bits_txnID(io_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID(io_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID(io_mshrTask_bits_dbID),
    .io_mshrTask_bits_fwdNID(io_mshrTask_bits_fwdNID),
    .io_mshrTask_bits_fwdTxnID(io_mshrTask_bits_fwdTxnID),
    .io_mshrTask_bits_chiOpcode(io_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp(io_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState(io_mshrTask_bits_fwdState),
    .io_mshrTask_bits_pCrdType(io_mshrTask_bits_pCrdType),
    .io_mshrTask_bits_retToSrc(io_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared(io_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck(io_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry(io_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate(io_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable(io_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_device(io_mshrTask_bits_memAttr_device),
    .io_mshrTask_bits_memAttr_ewa(io_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag(io_mshrTask_bits_traceTag),
    .io_mshrTask_bits_dataCheckErr(io_mshrTask_bits_dataCheckErr),
    .io_dirRead_s1_ready(io_dirRead_s1_ready),
    .io_dirRead_s1_valid(g_io_dirRead_s1_valid),
    .io_dirRead_s1_bits_tag(g_io_dirRead_s1_bits_tag),
    .io_dirRead_s1_bits_set(g_io_dirRead_s1_bits_set),
    .io_dirRead_s1_bits_wayMask(g_io_dirRead_s1_bits_wayMask),
    .io_dirRead_s1_bits_replacerInfo_channel(g_io_dirRead_s1_bits_replacerInfo_channel),
    .io_dirRead_s1_bits_replacerInfo_opcode(g_io_dirRead_s1_bits_replacerInfo_opcode),
    .io_dirRead_s1_bits_replacerInfo_reqSource(g_io_dirRead_s1_bits_replacerInfo_reqSource),
    .io_dirRead_s1_bits_replacerInfo_refill_prefetch(g_io_dirRead_s1_bits_replacerInfo_refill_prefetch),
    .io_dirRead_s1_bits_refill(g_io_dirRead_s1_bits_refill),
    .io_dirRead_s1_bits_mshrId(g_io_dirRead_s1_bits_mshrId),
    .io_dirRead_s1_bits_cmoAll(g_io_dirRead_s1_bits_cmoAll),
    .io_dirRead_s1_bits_cmoWay(g_io_dirRead_s1_bits_cmoWay),
    .io_taskToPipe_s2_valid(g_io_taskToPipe_s2_valid),
    .io_taskToPipe_s2_bits_channel(g_io_taskToPipe_s2_bits_channel),
    .io_taskToPipe_s2_bits_txChannel(g_io_taskToPipe_s2_bits_txChannel),
    .io_taskToPipe_s2_bits_set(g_io_taskToPipe_s2_bits_set),
    .io_taskToPipe_s2_bits_tag(g_io_taskToPipe_s2_bits_tag),
    .io_taskToPipe_s2_bits_off(g_io_taskToPipe_s2_bits_off),
    .io_taskToPipe_s2_bits_alias(g_io_taskToPipe_s2_bits_alias),
    .io_taskToPipe_s2_bits_vaddr(g_io_taskToPipe_s2_bits_vaddr),
    .io_taskToPipe_s2_bits_isKeyword(g_io_taskToPipe_s2_bits_isKeyword),
    .io_taskToPipe_s2_bits_opcode(g_io_taskToPipe_s2_bits_opcode),
    .io_taskToPipe_s2_bits_param(g_io_taskToPipe_s2_bits_param),
    .io_taskToPipe_s2_bits_size(g_io_taskToPipe_s2_bits_size),
    .io_taskToPipe_s2_bits_sourceId(g_io_taskToPipe_s2_bits_sourceId),
    .io_taskToPipe_s2_bits_bufIdx(g_io_taskToPipe_s2_bits_bufIdx),
    .io_taskToPipe_s2_bits_needProbeAckData(g_io_taskToPipe_s2_bits_needProbeAckData),
    .io_taskToPipe_s2_bits_denied(g_io_taskToPipe_s2_bits_denied),
    .io_taskToPipe_s2_bits_corrupt(g_io_taskToPipe_s2_bits_corrupt),
    .io_taskToPipe_s2_bits_mshrTask(g_io_taskToPipe_s2_bits_mshrTask),
    .io_taskToPipe_s2_bits_mshrId(g_io_taskToPipe_s2_bits_mshrId),
    .io_taskToPipe_s2_bits_aliasTask(g_io_taskToPipe_s2_bits_aliasTask),
    .io_taskToPipe_s2_bits_useProbeData(g_io_taskToPipe_s2_bits_useProbeData),
    .io_taskToPipe_s2_bits_mshrRetry(g_io_taskToPipe_s2_bits_mshrRetry),
    .io_taskToPipe_s2_bits_readProbeDataDown(g_io_taskToPipe_s2_bits_readProbeDataDown),
    .io_taskToPipe_s2_bits_fromL2pft(g_io_taskToPipe_s2_bits_fromL2pft),
    .io_taskToPipe_s2_bits_needHint(g_io_taskToPipe_s2_bits_needHint),
    .io_taskToPipe_s2_bits_dirty(g_io_taskToPipe_s2_bits_dirty),
    .io_taskToPipe_s2_bits_way(g_io_taskToPipe_s2_bits_way),
    .io_taskToPipe_s2_bits_meta_dirty(g_io_taskToPipe_s2_bits_meta_dirty),
    .io_taskToPipe_s2_bits_meta_state(g_io_taskToPipe_s2_bits_meta_state),
    .io_taskToPipe_s2_bits_meta_clients(g_io_taskToPipe_s2_bits_meta_clients),
    .io_taskToPipe_s2_bits_meta_alias(g_io_taskToPipe_s2_bits_meta_alias),
    .io_taskToPipe_s2_bits_meta_prefetch(g_io_taskToPipe_s2_bits_meta_prefetch),
    .io_taskToPipe_s2_bits_meta_prefetchSrc(g_io_taskToPipe_s2_bits_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_meta_accessed(g_io_taskToPipe_s2_bits_meta_accessed),
    .io_taskToPipe_s2_bits_meta_tagErr(g_io_taskToPipe_s2_bits_meta_tagErr),
    .io_taskToPipe_s2_bits_meta_dataErr(g_io_taskToPipe_s2_bits_meta_dataErr),
    .io_taskToPipe_s2_bits_metaWen(g_io_taskToPipe_s2_bits_metaWen),
    .io_taskToPipe_s2_bits_tagWen(g_io_taskToPipe_s2_bits_tagWen),
    .io_taskToPipe_s2_bits_dsWen(g_io_taskToPipe_s2_bits_dsWen),
    .io_taskToPipe_s2_bits_wayMask(g_io_taskToPipe_s2_bits_wayMask),
    .io_taskToPipe_s2_bits_replTask(g_io_taskToPipe_s2_bits_replTask),
    .io_taskToPipe_s2_bits_cmoTask(g_io_taskToPipe_s2_bits_cmoTask),
    .io_taskToPipe_s2_bits_cmoAll(g_io_taskToPipe_s2_bits_cmoAll),
    .io_taskToPipe_s2_bits_reqSource(g_io_taskToPipe_s2_bits_reqSource),
    .io_taskToPipe_s2_bits_mergeA(g_io_taskToPipe_s2_bits_mergeA),
    .io_taskToPipe_s2_bits_aMergeTask_off(g_io_taskToPipe_s2_bits_aMergeTask_off),
    .io_taskToPipe_s2_bits_aMergeTask_alias(g_io_taskToPipe_s2_bits_aMergeTask_alias),
    .io_taskToPipe_s2_bits_aMergeTask_vaddr(g_io_taskToPipe_s2_bits_aMergeTask_vaddr),
    .io_taskToPipe_s2_bits_aMergeTask_isKeyword(g_io_taskToPipe_s2_bits_aMergeTask_isKeyword),
    .io_taskToPipe_s2_bits_aMergeTask_opcode(g_io_taskToPipe_s2_bits_aMergeTask_opcode),
    .io_taskToPipe_s2_bits_aMergeTask_param(g_io_taskToPipe_s2_bits_aMergeTask_param),
    .io_taskToPipe_s2_bits_aMergeTask_sourceId(g_io_taskToPipe_s2_bits_aMergeTask_sourceId),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dirty(g_io_taskToPipe_s2_bits_aMergeTask_meta_dirty),
    .io_taskToPipe_s2_bits_aMergeTask_meta_state(g_io_taskToPipe_s2_bits_aMergeTask_meta_state),
    .io_taskToPipe_s2_bits_aMergeTask_meta_clients(g_io_taskToPipe_s2_bits_aMergeTask_meta_clients),
    .io_taskToPipe_s2_bits_aMergeTask_meta_alias(g_io_taskToPipe_s2_bits_aMergeTask_meta_alias),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetch(g_io_taskToPipe_s2_bits_aMergeTask_meta_prefetch),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc(g_io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_aMergeTask_meta_accessed(g_io_taskToPipe_s2_bits_aMergeTask_meta_accessed),
    .io_taskToPipe_s2_bits_aMergeTask_meta_tagErr(g_io_taskToPipe_s2_bits_aMergeTask_meta_tagErr),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dataErr(g_io_taskToPipe_s2_bits_aMergeTask_meta_dataErr),
    .io_taskToPipe_s2_bits_snpHitRelease(g_io_taskToPipe_s2_bits_snpHitRelease),
    .io_taskToPipe_s2_bits_snpHitReleaseToInval(g_io_taskToPipe_s2_bits_snpHitReleaseToInval),
    .io_taskToPipe_s2_bits_snpHitReleaseToClean(g_io_taskToPipe_s2_bits_snpHitReleaseToClean),
    .io_taskToPipe_s2_bits_snpHitReleaseWithData(g_io_taskToPipe_s2_bits_snpHitReleaseWithData),
    .io_taskToPipe_s2_bits_snpHitReleaseIdx(g_io_taskToPipe_s2_bits_snpHitReleaseIdx),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_state(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_state),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_clients(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_clients),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_alias(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_alias),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr(g_io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskToPipe_s2_bits_tgtID(g_io_taskToPipe_s2_bits_tgtID),
    .io_taskToPipe_s2_bits_srcID(g_io_taskToPipe_s2_bits_srcID),
    .io_taskToPipe_s2_bits_txnID(g_io_taskToPipe_s2_bits_txnID),
    .io_taskToPipe_s2_bits_homeNID(g_io_taskToPipe_s2_bits_homeNID),
    .io_taskToPipe_s2_bits_dbID(g_io_taskToPipe_s2_bits_dbID),
    .io_taskToPipe_s2_bits_fwdNID(g_io_taskToPipe_s2_bits_fwdNID),
    .io_taskToPipe_s2_bits_fwdTxnID(g_io_taskToPipe_s2_bits_fwdTxnID),
    .io_taskToPipe_s2_bits_chiOpcode(g_io_taskToPipe_s2_bits_chiOpcode),
    .io_taskToPipe_s2_bits_resp(g_io_taskToPipe_s2_bits_resp),
    .io_taskToPipe_s2_bits_fwdState(g_io_taskToPipe_s2_bits_fwdState),
    .io_taskToPipe_s2_bits_pCrdType(g_io_taskToPipe_s2_bits_pCrdType),
    .io_taskToPipe_s2_bits_retToSrc(g_io_taskToPipe_s2_bits_retToSrc),
    .io_taskToPipe_s2_bits_likelyshared(g_io_taskToPipe_s2_bits_likelyshared),
    .io_taskToPipe_s2_bits_expCompAck(g_io_taskToPipe_s2_bits_expCompAck),
    .io_taskToPipe_s2_bits_allowRetry(g_io_taskToPipe_s2_bits_allowRetry),
    .io_taskToPipe_s2_bits_memAttr_allocate(g_io_taskToPipe_s2_bits_memAttr_allocate),
    .io_taskToPipe_s2_bits_memAttr_cacheable(g_io_taskToPipe_s2_bits_memAttr_cacheable),
    .io_taskToPipe_s2_bits_memAttr_device(g_io_taskToPipe_s2_bits_memAttr_device),
    .io_taskToPipe_s2_bits_memAttr_ewa(g_io_taskToPipe_s2_bits_memAttr_ewa),
    .io_taskToPipe_s2_bits_traceTag(g_io_taskToPipe_s2_bits_traceTag),
    .io_taskToPipe_s2_bits_dataCheckErr(g_io_taskToPipe_s2_bits_dataCheckErr),
    .io_taskInfo_s1_valid(g_io_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel(g_io_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_txChannel(g_io_taskInfo_s1_bits_txChannel),
    .io_taskInfo_s1_bits_set(g_io_taskInfo_s1_bits_set),
    .io_taskInfo_s1_bits_tag(g_io_taskInfo_s1_bits_tag),
    .io_taskInfo_s1_bits_off(g_io_taskInfo_s1_bits_off),
    .io_taskInfo_s1_bits_alias(g_io_taskInfo_s1_bits_alias),
    .io_taskInfo_s1_bits_vaddr(g_io_taskInfo_s1_bits_vaddr),
    .io_taskInfo_s1_bits_isKeyword(g_io_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode(g_io_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_param(g_io_taskInfo_s1_bits_param),
    .io_taskInfo_s1_bits_size(g_io_taskInfo_s1_bits_size),
    .io_taskInfo_s1_bits_sourceId(g_io_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_bufIdx(g_io_taskInfo_s1_bits_bufIdx),
    .io_taskInfo_s1_bits_needProbeAckData(g_io_taskInfo_s1_bits_needProbeAckData),
    .io_taskInfo_s1_bits_denied(g_io_taskInfo_s1_bits_denied),
    .io_taskInfo_s1_bits_corrupt(g_io_taskInfo_s1_bits_corrupt),
    .io_taskInfo_s1_bits_mshrTask(g_io_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mshrId(g_io_taskInfo_s1_bits_mshrId),
    .io_taskInfo_s1_bits_aliasTask(g_io_taskInfo_s1_bits_aliasTask),
    .io_taskInfo_s1_bits_useProbeData(g_io_taskInfo_s1_bits_useProbeData),
    .io_taskInfo_s1_bits_mshrRetry(g_io_taskInfo_s1_bits_mshrRetry),
    .io_taskInfo_s1_bits_readProbeDataDown(g_io_taskInfo_s1_bits_readProbeDataDown),
    .io_taskInfo_s1_bits_fromL2pft(g_io_taskInfo_s1_bits_fromL2pft),
    .io_taskInfo_s1_bits_needHint(g_io_taskInfo_s1_bits_needHint),
    .io_taskInfo_s1_bits_dirty(g_io_taskInfo_s1_bits_dirty),
    .io_taskInfo_s1_bits_way(g_io_taskInfo_s1_bits_way),
    .io_taskInfo_s1_bits_meta_dirty(g_io_taskInfo_s1_bits_meta_dirty),
    .io_taskInfo_s1_bits_meta_state(g_io_taskInfo_s1_bits_meta_state),
    .io_taskInfo_s1_bits_meta_clients(g_io_taskInfo_s1_bits_meta_clients),
    .io_taskInfo_s1_bits_meta_alias(g_io_taskInfo_s1_bits_meta_alias),
    .io_taskInfo_s1_bits_meta_prefetch(g_io_taskInfo_s1_bits_meta_prefetch),
    .io_taskInfo_s1_bits_meta_prefetchSrc(g_io_taskInfo_s1_bits_meta_prefetchSrc),
    .io_taskInfo_s1_bits_meta_accessed(g_io_taskInfo_s1_bits_meta_accessed),
    .io_taskInfo_s1_bits_meta_tagErr(g_io_taskInfo_s1_bits_meta_tagErr),
    .io_taskInfo_s1_bits_meta_dataErr(g_io_taskInfo_s1_bits_meta_dataErr),
    .io_taskInfo_s1_bits_metaWen(g_io_taskInfo_s1_bits_metaWen),
    .io_taskInfo_s1_bits_tagWen(g_io_taskInfo_s1_bits_tagWen),
    .io_taskInfo_s1_bits_dsWen(g_io_taskInfo_s1_bits_dsWen),
    .io_taskInfo_s1_bits_wayMask(g_io_taskInfo_s1_bits_wayMask),
    .io_taskInfo_s1_bits_replTask(g_io_taskInfo_s1_bits_replTask),
    .io_taskInfo_s1_bits_cmoTask(g_io_taskInfo_s1_bits_cmoTask),
    .io_taskInfo_s1_bits_cmoAll(g_io_taskInfo_s1_bits_cmoAll),
    .io_taskInfo_s1_bits_reqSource(g_io_taskInfo_s1_bits_reqSource),
    .io_taskInfo_s1_bits_mergeA(g_io_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_off(g_io_taskInfo_s1_bits_aMergeTask_off),
    .io_taskInfo_s1_bits_aMergeTask_alias(g_io_taskInfo_s1_bits_aMergeTask_alias),
    .io_taskInfo_s1_bits_aMergeTask_vaddr(g_io_taskInfo_s1_bits_aMergeTask_vaddr),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword(g_io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode(g_io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_param(g_io_taskInfo_s1_bits_aMergeTask_param),
    .io_taskInfo_s1_bits_aMergeTask_sourceId(g_io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_taskInfo_s1_bits_aMergeTask_meta_dirty(g_io_taskInfo_s1_bits_aMergeTask_meta_dirty),
    .io_taskInfo_s1_bits_aMergeTask_meta_state(g_io_taskInfo_s1_bits_aMergeTask_meta_state),
    .io_taskInfo_s1_bits_aMergeTask_meta_clients(g_io_taskInfo_s1_bits_aMergeTask_meta_clients),
    .io_taskInfo_s1_bits_aMergeTask_meta_alias(g_io_taskInfo_s1_bits_aMergeTask_meta_alias),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetch(g_io_taskInfo_s1_bits_aMergeTask_meta_prefetch),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc(g_io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc),
    .io_taskInfo_s1_bits_aMergeTask_meta_accessed(g_io_taskInfo_s1_bits_aMergeTask_meta_accessed),
    .io_taskInfo_s1_bits_aMergeTask_meta_tagErr(g_io_taskInfo_s1_bits_aMergeTask_meta_tagErr),
    .io_taskInfo_s1_bits_aMergeTask_meta_dataErr(g_io_taskInfo_s1_bits_aMergeTask_meta_dataErr),
    .io_taskInfo_s1_bits_snpHitRelease(g_io_taskInfo_s1_bits_snpHitRelease),
    .io_taskInfo_s1_bits_snpHitReleaseToInval(g_io_taskInfo_s1_bits_snpHitReleaseToInval),
    .io_taskInfo_s1_bits_snpHitReleaseToClean(g_io_taskInfo_s1_bits_snpHitReleaseToClean),
    .io_taskInfo_s1_bits_snpHitReleaseWithData(g_io_taskInfo_s1_bits_snpHitReleaseWithData),
    .io_taskInfo_s1_bits_snpHitReleaseIdx(g_io_taskInfo_s1_bits_snpHitReleaseIdx),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dirty(g_io_taskInfo_s1_bits_snpHitReleaseMeta_dirty),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_state(g_io_taskInfo_s1_bits_snpHitReleaseMeta_state),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_clients(g_io_taskInfo_s1_bits_snpHitReleaseMeta_clients),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_alias(g_io_taskInfo_s1_bits_snpHitReleaseMeta_alias),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch(g_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc(g_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_accessed(g_io_taskInfo_s1_bits_snpHitReleaseMeta_accessed),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr(g_io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr(g_io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr),
    .io_taskInfo_s1_bits_tgtID(g_io_taskInfo_s1_bits_tgtID),
    .io_taskInfo_s1_bits_srcID(g_io_taskInfo_s1_bits_srcID),
    .io_taskInfo_s1_bits_txnID(g_io_taskInfo_s1_bits_txnID),
    .io_taskInfo_s1_bits_homeNID(g_io_taskInfo_s1_bits_homeNID),
    .io_taskInfo_s1_bits_dbID(g_io_taskInfo_s1_bits_dbID),
    .io_taskInfo_s1_bits_fwdNID(g_io_taskInfo_s1_bits_fwdNID),
    .io_taskInfo_s1_bits_fwdTxnID(g_io_taskInfo_s1_bits_fwdTxnID),
    .io_taskInfo_s1_bits_chiOpcode(g_io_taskInfo_s1_bits_chiOpcode),
    .io_taskInfo_s1_bits_resp(g_io_taskInfo_s1_bits_resp),
    .io_taskInfo_s1_bits_fwdState(g_io_taskInfo_s1_bits_fwdState),
    .io_taskInfo_s1_bits_pCrdType(g_io_taskInfo_s1_bits_pCrdType),
    .io_taskInfo_s1_bits_retToSrc(g_io_taskInfo_s1_bits_retToSrc),
    .io_taskInfo_s1_bits_likelyshared(g_io_taskInfo_s1_bits_likelyshared),
    .io_taskInfo_s1_bits_expCompAck(g_io_taskInfo_s1_bits_expCompAck),
    .io_taskInfo_s1_bits_allowRetry(g_io_taskInfo_s1_bits_allowRetry),
    .io_taskInfo_s1_bits_memAttr_allocate(g_io_taskInfo_s1_bits_memAttr_allocate),
    .io_taskInfo_s1_bits_memAttr_cacheable(g_io_taskInfo_s1_bits_memAttr_cacheable),
    .io_taskInfo_s1_bits_memAttr_device(g_io_taskInfo_s1_bits_memAttr_device),
    .io_taskInfo_s1_bits_memAttr_ewa(g_io_taskInfo_s1_bits_memAttr_ewa),
    .io_taskInfo_s1_bits_traceTag(g_io_taskInfo_s1_bits_traceTag),
    .io_taskInfo_s1_bits_dataCheckErr(g_io_taskInfo_s1_bits_dataCheckErr),
    .io_refillBufRead_s2_valid(g_io_refillBufRead_s2_valid),
    .io_refillBufRead_s2_bits_id(g_io_refillBufRead_s2_bits_id),
    .io_releaseBufRead_s2_valid(g_io_releaseBufRead_s2_valid),
    .io_releaseBufRead_s2_bits_id(g_io_releaseBufRead_s2_bits_id),
    .io_status_s1_tags_0(g_io_status_s1_tags_0),
    .io_status_s1_tags_1(g_io_status_s1_tags_1),
    .io_status_s1_tags_2(g_io_status_s1_tags_2),
    .io_status_s1_tags_3(g_io_status_s1_tags_3),
    .io_status_s1_sets_0(g_io_status_s1_sets_0),
    .io_status_s1_sets_1(g_io_status_s1_sets_1),
    .io_status_s1_sets_2(g_io_status_s1_sets_2),
    .io_status_s1_sets_3(g_io_status_s1_sets_3),
    .io_status_vec_0_valid(g_io_status_vec_0_valid),
    .io_status_vec_0_bits_channel(g_io_status_vec_0_bits_channel),
    .io_status_vec_1_valid(g_io_status_vec_1_valid),
    .io_status_vec_1_bits_channel(g_io_status_vec_1_bits_channel),
    .io_status_vec_toTX_0_valid(g_io_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel(g_io_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel(g_io_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask(g_io_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid(g_io_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel(g_io_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel(g_io_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask(g_io_status_vec_toTX_1_bits_mshrTask),
    .io_fromMSHRCtl_blockG_s1(io_fromMSHRCtl_blockG_s1),
    .io_fromMSHRCtl_blockA_s1(io_fromMSHRCtl_blockA_s1),
    .io_fromMSHRCtl_blockB_s1(io_fromMSHRCtl_blockB_s1),
    .io_fromMSHRCtl_blockC_s1(io_fromMSHRCtl_blockC_s1),
    .io_fromMainPipe_blockG_s1(io_fromMainPipe_blockG_s1),
    .io_fromMainPipe_blockA_s1(io_fromMainPipe_blockA_s1),
    .io_fromMainPipe_blockB_s1(io_fromMainPipe_blockB_s1),
    .io_fromMainPipe_blockC_s1(io_fromMainPipe_blockC_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1),
    .io_fromGrantBuffer_blockMSHRReqEntrance(io_fromGrantBuffer_blockMSHRReqEntrance),
    .io_fromTXDAT_blockMSHRReqEntrance(io_fromTXDAT_blockMSHRReqEntrance),
    .io_fromTXDAT_blockSinkBReqEntrance(io_fromTXDAT_blockSinkBReqEntrance),
    .io_fromTXRSP_blockMSHRReqEntrance(io_fromTXRSP_blockMSHRReqEntrance),
    .io_fromTXRSP_blockSinkBReqEntrance(io_fromTXRSP_blockSinkBReqEntrance),
    .io_fromTXREQ_blockMSHRReqEntrance(io_fromTXREQ_blockMSHRReqEntrance),
    .io_msInfo_0_valid(io_msInfo_0_valid),
    .io_msInfo_0_bits_channel(io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set(io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way(io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag(io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree(io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask(io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease(io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill(io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty(io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state(io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients(io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias(io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch(io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc(io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed(io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr(io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr(io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag(io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit(io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch(io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch(io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param(io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA(io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst(io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release(io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill(io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp(io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw(io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack(io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp(io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast(io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData(io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean(io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid(io_msInfo_1_valid),
    .io_msInfo_1_bits_channel(io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set(io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way(io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag(io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree(io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask(io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease(io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill(io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty(io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state(io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients(io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias(io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch(io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc(io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed(io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr(io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr(io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag(io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit(io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch(io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch(io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param(io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA(io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst(io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release(io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill(io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp(io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw(io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack(io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp(io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast(io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData(io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean(io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid(io_msInfo_2_valid),
    .io_msInfo_2_bits_channel(io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set(io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way(io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag(io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree(io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask(io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease(io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill(io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty(io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state(io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients(io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias(io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch(io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc(io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed(io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr(io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr(io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag(io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit(io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch(io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch(io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param(io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA(io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst(io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release(io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill(io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp(io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw(io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack(io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp(io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast(io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData(io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean(io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid(io_msInfo_3_valid),
    .io_msInfo_3_bits_channel(io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set(io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way(io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag(io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree(io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask(io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease(io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill(io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty(io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state(io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients(io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias(io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch(io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc(io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed(io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr(io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr(io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag(io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit(io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch(io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch(io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param(io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA(io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst(io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release(io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill(io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp(io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw(io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack(io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp(io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast(io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData(io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean(io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid(io_msInfo_4_valid),
    .io_msInfo_4_bits_channel(io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set(io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way(io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag(io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree(io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask(io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease(io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill(io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty(io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state(io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients(io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias(io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch(io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc(io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed(io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr(io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr(io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag(io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit(io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch(io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch(io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param(io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA(io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst(io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release(io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill(io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp(io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw(io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack(io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp(io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast(io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData(io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean(io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid(io_msInfo_5_valid),
    .io_msInfo_5_bits_channel(io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set(io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way(io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag(io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree(io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask(io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease(io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill(io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty(io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state(io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients(io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias(io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch(io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc(io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed(io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr(io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr(io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag(io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit(io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch(io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch(io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param(io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA(io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst(io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release(io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill(io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp(io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw(io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack(io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp(io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast(io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData(io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean(io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid(io_msInfo_6_valid),
    .io_msInfo_6_bits_channel(io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set(io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way(io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag(io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree(io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask(io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease(io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill(io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty(io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state(io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients(io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias(io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch(io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc(io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed(io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr(io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr(io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag(io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit(io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch(io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch(io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param(io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA(io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst(io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release(io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill(io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp(io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw(io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack(io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp(io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast(io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData(io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean(io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid(io_msInfo_7_valid),
    .io_msInfo_7_bits_channel(io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set(io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way(io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag(io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree(io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask(io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease(io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill(io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty(io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state(io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients(io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias(io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch(io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc(io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed(io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr(io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr(io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag(io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit(io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch(io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch(io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param(io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA(io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst(io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release(io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill(io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp(io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw(io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack(io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp(io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast(io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData(io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean(io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid(io_msInfo_8_valid),
    .io_msInfo_8_bits_channel(io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set(io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way(io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag(io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree(io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask(io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease(io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill(io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty(io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state(io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients(io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias(io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch(io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc(io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed(io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr(io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr(io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag(io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit(io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch(io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch(io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param(io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA(io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst(io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release(io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill(io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp(io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw(io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack(io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp(io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast(io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData(io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean(io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid(io_msInfo_9_valid),
    .io_msInfo_9_bits_channel(io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set(io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way(io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag(io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree(io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask(io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease(io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill(io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty(io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state(io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients(io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias(io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch(io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc(io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed(io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr(io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr(io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag(io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit(io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch(io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch(io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param(io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA(io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst(io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release(io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill(io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp(io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw(io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack(io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp(io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast(io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData(io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean(io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid(io_msInfo_10_valid),
    .io_msInfo_10_bits_channel(io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set(io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way(io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag(io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree(io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask(io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease(io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill(io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty(io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state(io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients(io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias(io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch(io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc(io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed(io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr(io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr(io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag(io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit(io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch(io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch(io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param(io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA(io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst(io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release(io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill(io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp(io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw(io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack(io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp(io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast(io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData(io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean(io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid(io_msInfo_11_valid),
    .io_msInfo_11_bits_channel(io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set(io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way(io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag(io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree(io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask(io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease(io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill(io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty(io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state(io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients(io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias(io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch(io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc(io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed(io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr(io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr(io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag(io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit(io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch(io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch(io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param(io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA(io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst(io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release(io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill(io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp(io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw(io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack(io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp(io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast(io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData(io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean(io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid(io_msInfo_12_valid),
    .io_msInfo_12_bits_channel(io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set(io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way(io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag(io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree(io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask(io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease(io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill(io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty(io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state(io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients(io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias(io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch(io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc(io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed(io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr(io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr(io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag(io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit(io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch(io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch(io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param(io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA(io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst(io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release(io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill(io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp(io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw(io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack(io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp(io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast(io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData(io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean(io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid(io_msInfo_13_valid),
    .io_msInfo_13_bits_channel(io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set(io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way(io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag(io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree(io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask(io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease(io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill(io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty(io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state(io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients(io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias(io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch(io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc(io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed(io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr(io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr(io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag(io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit(io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch(io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch(io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param(io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA(io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst(io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release(io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill(io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp(io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw(io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack(io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp(io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast(io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData(io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean(io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid(io_msInfo_14_valid),
    .io_msInfo_14_bits_channel(io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set(io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way(io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag(io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree(io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask(io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease(io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill(io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty(io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state(io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients(io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias(io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch(io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc(io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed(io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr(io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr(io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag(io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit(io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch(io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch(io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param(io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA(io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst(io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release(io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill(io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp(io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw(io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack(io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp(io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast(io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData(io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean(io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid(io_msInfo_15_valid),
    .io_msInfo_15_bits_channel(io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set(io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way(io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag(io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree(io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask(io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease(io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill(io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty(io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state(io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients(io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias(io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch(io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc(io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed(io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr(io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr(io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag(io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit(io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch(io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch(io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param(io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA(io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst(io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release(io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill(io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp(io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw(io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack(io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp(io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast(io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData(io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean(io_msInfo_15_bits_releaseToClean)
  );
  RequestArb_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sinkA_ready(i_io_sinkA_ready),
    .io_sinkA_valid(io_sinkA_valid),
    .io_sinkA_bits_channel(io_sinkA_bits_channel),
    .io_sinkA_bits_txChannel(io_sinkA_bits_txChannel),
    .io_sinkA_bits_set(io_sinkA_bits_set),
    .io_sinkA_bits_tag(io_sinkA_bits_tag),
    .io_sinkA_bits_off(io_sinkA_bits_off),
    .io_sinkA_bits_alias(io_sinkA_bits_alias),
    .io_sinkA_bits_vaddr(io_sinkA_bits_vaddr),
    .io_sinkA_bits_isKeyword(io_sinkA_bits_isKeyword),
    .io_sinkA_bits_opcode(io_sinkA_bits_opcode),
    .io_sinkA_bits_param(io_sinkA_bits_param),
    .io_sinkA_bits_size(io_sinkA_bits_size),
    .io_sinkA_bits_sourceId(io_sinkA_bits_sourceId),
    .io_sinkA_bits_bufIdx(io_sinkA_bits_bufIdx),
    .io_sinkA_bits_needProbeAckData(io_sinkA_bits_needProbeAckData),
    .io_sinkA_bits_denied(io_sinkA_bits_denied),
    .io_sinkA_bits_corrupt(io_sinkA_bits_corrupt),
    .io_sinkA_bits_mshrTask(io_sinkA_bits_mshrTask),
    .io_sinkA_bits_mshrId(io_sinkA_bits_mshrId),
    .io_sinkA_bits_aliasTask(io_sinkA_bits_aliasTask),
    .io_sinkA_bits_useProbeData(io_sinkA_bits_useProbeData),
    .io_sinkA_bits_mshrRetry(io_sinkA_bits_mshrRetry),
    .io_sinkA_bits_readProbeDataDown(io_sinkA_bits_readProbeDataDown),
    .io_sinkA_bits_fromL2pft(io_sinkA_bits_fromL2pft),
    .io_sinkA_bits_needHint(io_sinkA_bits_needHint),
    .io_sinkA_bits_dirty(io_sinkA_bits_dirty),
    .io_sinkA_bits_way(io_sinkA_bits_way),
    .io_sinkA_bits_meta_dirty(io_sinkA_bits_meta_dirty),
    .io_sinkA_bits_meta_state(io_sinkA_bits_meta_state),
    .io_sinkA_bits_meta_clients(io_sinkA_bits_meta_clients),
    .io_sinkA_bits_meta_alias(io_sinkA_bits_meta_alias),
    .io_sinkA_bits_meta_prefetch(io_sinkA_bits_meta_prefetch),
    .io_sinkA_bits_meta_prefetchSrc(io_sinkA_bits_meta_prefetchSrc),
    .io_sinkA_bits_meta_accessed(io_sinkA_bits_meta_accessed),
    .io_sinkA_bits_meta_tagErr(io_sinkA_bits_meta_tagErr),
    .io_sinkA_bits_meta_dataErr(io_sinkA_bits_meta_dataErr),
    .io_sinkA_bits_metaWen(io_sinkA_bits_metaWen),
    .io_sinkA_bits_tagWen(io_sinkA_bits_tagWen),
    .io_sinkA_bits_dsWen(io_sinkA_bits_dsWen),
    .io_sinkA_bits_wayMask(io_sinkA_bits_wayMask),
    .io_sinkA_bits_replTask(io_sinkA_bits_replTask),
    .io_sinkA_bits_cmoTask(io_sinkA_bits_cmoTask),
    .io_sinkA_bits_cmoAll(io_sinkA_bits_cmoAll),
    .io_sinkA_bits_reqSource(io_sinkA_bits_reqSource),
    .io_sinkA_bits_mergeA(io_sinkA_bits_mergeA),
    .io_sinkA_bits_aMergeTask_off(io_sinkA_bits_aMergeTask_off),
    .io_sinkA_bits_aMergeTask_alias(io_sinkA_bits_aMergeTask_alias),
    .io_sinkA_bits_aMergeTask_vaddr(io_sinkA_bits_aMergeTask_vaddr),
    .io_sinkA_bits_aMergeTask_isKeyword(io_sinkA_bits_aMergeTask_isKeyword),
    .io_sinkA_bits_aMergeTask_opcode(io_sinkA_bits_aMergeTask_opcode),
    .io_sinkA_bits_aMergeTask_param(io_sinkA_bits_aMergeTask_param),
    .io_sinkA_bits_aMergeTask_sourceId(io_sinkA_bits_aMergeTask_sourceId),
    .io_sinkA_bits_aMergeTask_meta_dirty(io_sinkA_bits_aMergeTask_meta_dirty),
    .io_sinkA_bits_aMergeTask_meta_state(io_sinkA_bits_aMergeTask_meta_state),
    .io_sinkA_bits_aMergeTask_meta_clients(io_sinkA_bits_aMergeTask_meta_clients),
    .io_sinkA_bits_aMergeTask_meta_alias(io_sinkA_bits_aMergeTask_meta_alias),
    .io_sinkA_bits_aMergeTask_meta_prefetch(io_sinkA_bits_aMergeTask_meta_prefetch),
    .io_sinkA_bits_aMergeTask_meta_prefetchSrc(io_sinkA_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkA_bits_aMergeTask_meta_accessed(io_sinkA_bits_aMergeTask_meta_accessed),
    .io_sinkA_bits_aMergeTask_meta_tagErr(io_sinkA_bits_aMergeTask_meta_tagErr),
    .io_sinkA_bits_aMergeTask_meta_dataErr(io_sinkA_bits_aMergeTask_meta_dataErr),
    .io_sinkA_bits_snpHitRelease(io_sinkA_bits_snpHitRelease),
    .io_sinkA_bits_snpHitReleaseToInval(io_sinkA_bits_snpHitReleaseToInval),
    .io_sinkA_bits_snpHitReleaseToClean(io_sinkA_bits_snpHitReleaseToClean),
    .io_sinkA_bits_snpHitReleaseWithData(io_sinkA_bits_snpHitReleaseWithData),
    .io_sinkA_bits_snpHitReleaseIdx(io_sinkA_bits_snpHitReleaseIdx),
    .io_sinkA_bits_snpHitReleaseMeta_dirty(io_sinkA_bits_snpHitReleaseMeta_dirty),
    .io_sinkA_bits_snpHitReleaseMeta_state(io_sinkA_bits_snpHitReleaseMeta_state),
    .io_sinkA_bits_snpHitReleaseMeta_clients(io_sinkA_bits_snpHitReleaseMeta_clients),
    .io_sinkA_bits_snpHitReleaseMeta_alias(io_sinkA_bits_snpHitReleaseMeta_alias),
    .io_sinkA_bits_snpHitReleaseMeta_prefetch(io_sinkA_bits_snpHitReleaseMeta_prefetch),
    .io_sinkA_bits_snpHitReleaseMeta_prefetchSrc(io_sinkA_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkA_bits_snpHitReleaseMeta_accessed(io_sinkA_bits_snpHitReleaseMeta_accessed),
    .io_sinkA_bits_snpHitReleaseMeta_tagErr(io_sinkA_bits_snpHitReleaseMeta_tagErr),
    .io_sinkA_bits_snpHitReleaseMeta_dataErr(io_sinkA_bits_snpHitReleaseMeta_dataErr),
    .io_sinkA_bits_tgtID(io_sinkA_bits_tgtID),
    .io_sinkA_bits_srcID(io_sinkA_bits_srcID),
    .io_sinkA_bits_txnID(io_sinkA_bits_txnID),
    .io_sinkA_bits_homeNID(io_sinkA_bits_homeNID),
    .io_sinkA_bits_dbID(io_sinkA_bits_dbID),
    .io_sinkA_bits_fwdNID(io_sinkA_bits_fwdNID),
    .io_sinkA_bits_fwdTxnID(io_sinkA_bits_fwdTxnID),
    .io_sinkA_bits_chiOpcode(io_sinkA_bits_chiOpcode),
    .io_sinkA_bits_resp(io_sinkA_bits_resp),
    .io_sinkA_bits_fwdState(io_sinkA_bits_fwdState),
    .io_sinkA_bits_pCrdType(io_sinkA_bits_pCrdType),
    .io_sinkA_bits_retToSrc(io_sinkA_bits_retToSrc),
    .io_sinkA_bits_likelyshared(io_sinkA_bits_likelyshared),
    .io_sinkA_bits_expCompAck(io_sinkA_bits_expCompAck),
    .io_sinkA_bits_allowRetry(io_sinkA_bits_allowRetry),
    .io_sinkA_bits_memAttr_allocate(io_sinkA_bits_memAttr_allocate),
    .io_sinkA_bits_memAttr_cacheable(io_sinkA_bits_memAttr_cacheable),
    .io_sinkA_bits_memAttr_device(io_sinkA_bits_memAttr_device),
    .io_sinkA_bits_memAttr_ewa(io_sinkA_bits_memAttr_ewa),
    .io_sinkA_bits_traceTag(io_sinkA_bits_traceTag),
    .io_sinkA_bits_dataCheckErr(io_sinkA_bits_dataCheckErr),
    .io_ATag(io_ATag),
    .io_ASet(io_ASet),
    .io_s1Entrance_valid(i_io_s1Entrance_valid),
    .io_s1Entrance_bits_set(i_io_s1Entrance_bits_set),
    .io_sinkB_ready(i_io_sinkB_ready),
    .io_sinkB_valid(io_sinkB_valid),
    .io_sinkB_bits_channel(io_sinkB_bits_channel),
    .io_sinkB_bits_txChannel(io_sinkB_bits_txChannel),
    .io_sinkB_bits_set(io_sinkB_bits_set),
    .io_sinkB_bits_tag(io_sinkB_bits_tag),
    .io_sinkB_bits_off(io_sinkB_bits_off),
    .io_sinkB_bits_alias(io_sinkB_bits_alias),
    .io_sinkB_bits_vaddr(io_sinkB_bits_vaddr),
    .io_sinkB_bits_isKeyword(io_sinkB_bits_isKeyword),
    .io_sinkB_bits_opcode(io_sinkB_bits_opcode),
    .io_sinkB_bits_param(io_sinkB_bits_param),
    .io_sinkB_bits_size(io_sinkB_bits_size),
    .io_sinkB_bits_sourceId(io_sinkB_bits_sourceId),
    .io_sinkB_bits_bufIdx(io_sinkB_bits_bufIdx),
    .io_sinkB_bits_needProbeAckData(io_sinkB_bits_needProbeAckData),
    .io_sinkB_bits_denied(io_sinkB_bits_denied),
    .io_sinkB_bits_corrupt(io_sinkB_bits_corrupt),
    .io_sinkB_bits_mshrTask(io_sinkB_bits_mshrTask),
    .io_sinkB_bits_mshrId(io_sinkB_bits_mshrId),
    .io_sinkB_bits_aliasTask(io_sinkB_bits_aliasTask),
    .io_sinkB_bits_useProbeData(io_sinkB_bits_useProbeData),
    .io_sinkB_bits_mshrRetry(io_sinkB_bits_mshrRetry),
    .io_sinkB_bits_readProbeDataDown(io_sinkB_bits_readProbeDataDown),
    .io_sinkB_bits_fromL2pft(io_sinkB_bits_fromL2pft),
    .io_sinkB_bits_needHint(io_sinkB_bits_needHint),
    .io_sinkB_bits_dirty(io_sinkB_bits_dirty),
    .io_sinkB_bits_way(io_sinkB_bits_way),
    .io_sinkB_bits_meta_dirty(io_sinkB_bits_meta_dirty),
    .io_sinkB_bits_meta_state(io_sinkB_bits_meta_state),
    .io_sinkB_bits_meta_clients(io_sinkB_bits_meta_clients),
    .io_sinkB_bits_meta_alias(io_sinkB_bits_meta_alias),
    .io_sinkB_bits_meta_prefetch(io_sinkB_bits_meta_prefetch),
    .io_sinkB_bits_meta_prefetchSrc(io_sinkB_bits_meta_prefetchSrc),
    .io_sinkB_bits_meta_accessed(io_sinkB_bits_meta_accessed),
    .io_sinkB_bits_meta_tagErr(io_sinkB_bits_meta_tagErr),
    .io_sinkB_bits_meta_dataErr(io_sinkB_bits_meta_dataErr),
    .io_sinkB_bits_metaWen(io_sinkB_bits_metaWen),
    .io_sinkB_bits_tagWen(io_sinkB_bits_tagWen),
    .io_sinkB_bits_dsWen(io_sinkB_bits_dsWen),
    .io_sinkB_bits_wayMask(io_sinkB_bits_wayMask),
    .io_sinkB_bits_replTask(io_sinkB_bits_replTask),
    .io_sinkB_bits_cmoTask(io_sinkB_bits_cmoTask),
    .io_sinkB_bits_cmoAll(io_sinkB_bits_cmoAll),
    .io_sinkB_bits_reqSource(io_sinkB_bits_reqSource),
    .io_sinkB_bits_mergeA(io_sinkB_bits_mergeA),
    .io_sinkB_bits_aMergeTask_off(io_sinkB_bits_aMergeTask_off),
    .io_sinkB_bits_aMergeTask_alias(io_sinkB_bits_aMergeTask_alias),
    .io_sinkB_bits_aMergeTask_vaddr(io_sinkB_bits_aMergeTask_vaddr),
    .io_sinkB_bits_aMergeTask_isKeyword(io_sinkB_bits_aMergeTask_isKeyword),
    .io_sinkB_bits_aMergeTask_opcode(io_sinkB_bits_aMergeTask_opcode),
    .io_sinkB_bits_aMergeTask_param(io_sinkB_bits_aMergeTask_param),
    .io_sinkB_bits_aMergeTask_sourceId(io_sinkB_bits_aMergeTask_sourceId),
    .io_sinkB_bits_aMergeTask_meta_dirty(io_sinkB_bits_aMergeTask_meta_dirty),
    .io_sinkB_bits_aMergeTask_meta_state(io_sinkB_bits_aMergeTask_meta_state),
    .io_sinkB_bits_aMergeTask_meta_clients(io_sinkB_bits_aMergeTask_meta_clients),
    .io_sinkB_bits_aMergeTask_meta_alias(io_sinkB_bits_aMergeTask_meta_alias),
    .io_sinkB_bits_aMergeTask_meta_prefetch(io_sinkB_bits_aMergeTask_meta_prefetch),
    .io_sinkB_bits_aMergeTask_meta_prefetchSrc(io_sinkB_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkB_bits_aMergeTask_meta_accessed(io_sinkB_bits_aMergeTask_meta_accessed),
    .io_sinkB_bits_aMergeTask_meta_tagErr(io_sinkB_bits_aMergeTask_meta_tagErr),
    .io_sinkB_bits_aMergeTask_meta_dataErr(io_sinkB_bits_aMergeTask_meta_dataErr),
    .io_sinkB_bits_snpHitRelease(io_sinkB_bits_snpHitRelease),
    .io_sinkB_bits_snpHitReleaseToInval(io_sinkB_bits_snpHitReleaseToInval),
    .io_sinkB_bits_snpHitReleaseToClean(io_sinkB_bits_snpHitReleaseToClean),
    .io_sinkB_bits_snpHitReleaseWithData(io_sinkB_bits_snpHitReleaseWithData),
    .io_sinkB_bits_snpHitReleaseIdx(io_sinkB_bits_snpHitReleaseIdx),
    .io_sinkB_bits_snpHitReleaseMeta_dirty(io_sinkB_bits_snpHitReleaseMeta_dirty),
    .io_sinkB_bits_snpHitReleaseMeta_state(io_sinkB_bits_snpHitReleaseMeta_state),
    .io_sinkB_bits_snpHitReleaseMeta_clients(io_sinkB_bits_snpHitReleaseMeta_clients),
    .io_sinkB_bits_snpHitReleaseMeta_alias(io_sinkB_bits_snpHitReleaseMeta_alias),
    .io_sinkB_bits_snpHitReleaseMeta_prefetch(io_sinkB_bits_snpHitReleaseMeta_prefetch),
    .io_sinkB_bits_snpHitReleaseMeta_prefetchSrc(io_sinkB_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkB_bits_snpHitReleaseMeta_accessed(io_sinkB_bits_snpHitReleaseMeta_accessed),
    .io_sinkB_bits_snpHitReleaseMeta_tagErr(io_sinkB_bits_snpHitReleaseMeta_tagErr),
    .io_sinkB_bits_snpHitReleaseMeta_dataErr(io_sinkB_bits_snpHitReleaseMeta_dataErr),
    .io_sinkB_bits_tgtID(io_sinkB_bits_tgtID),
    .io_sinkB_bits_srcID(io_sinkB_bits_srcID),
    .io_sinkB_bits_txnID(io_sinkB_bits_txnID),
    .io_sinkB_bits_homeNID(io_sinkB_bits_homeNID),
    .io_sinkB_bits_dbID(io_sinkB_bits_dbID),
    .io_sinkB_bits_fwdNID(io_sinkB_bits_fwdNID),
    .io_sinkB_bits_fwdTxnID(io_sinkB_bits_fwdTxnID),
    .io_sinkB_bits_chiOpcode(io_sinkB_bits_chiOpcode),
    .io_sinkB_bits_resp(io_sinkB_bits_resp),
    .io_sinkB_bits_fwdState(io_sinkB_bits_fwdState),
    .io_sinkB_bits_pCrdType(io_sinkB_bits_pCrdType),
    .io_sinkB_bits_retToSrc(io_sinkB_bits_retToSrc),
    .io_sinkB_bits_likelyshared(io_sinkB_bits_likelyshared),
    .io_sinkB_bits_expCompAck(io_sinkB_bits_expCompAck),
    .io_sinkB_bits_allowRetry(io_sinkB_bits_allowRetry),
    .io_sinkB_bits_memAttr_allocate(io_sinkB_bits_memAttr_allocate),
    .io_sinkB_bits_memAttr_cacheable(io_sinkB_bits_memAttr_cacheable),
    .io_sinkB_bits_memAttr_device(io_sinkB_bits_memAttr_device),
    .io_sinkB_bits_memAttr_ewa(io_sinkB_bits_memAttr_ewa),
    .io_sinkB_bits_traceTag(io_sinkB_bits_traceTag),
    .io_sinkB_bits_dataCheckErr(io_sinkB_bits_dataCheckErr),
    .io_sinkC_ready(i_io_sinkC_ready),
    .io_sinkC_valid(io_sinkC_valid),
    .io_sinkC_bits_channel(io_sinkC_bits_channel),
    .io_sinkC_bits_txChannel(io_sinkC_bits_txChannel),
    .io_sinkC_bits_set(io_sinkC_bits_set),
    .io_sinkC_bits_tag(io_sinkC_bits_tag),
    .io_sinkC_bits_off(io_sinkC_bits_off),
    .io_sinkC_bits_alias(io_sinkC_bits_alias),
    .io_sinkC_bits_vaddr(io_sinkC_bits_vaddr),
    .io_sinkC_bits_isKeyword(io_sinkC_bits_isKeyword),
    .io_sinkC_bits_opcode(io_sinkC_bits_opcode),
    .io_sinkC_bits_param(io_sinkC_bits_param),
    .io_sinkC_bits_size(io_sinkC_bits_size),
    .io_sinkC_bits_sourceId(io_sinkC_bits_sourceId),
    .io_sinkC_bits_bufIdx(io_sinkC_bits_bufIdx),
    .io_sinkC_bits_needProbeAckData(io_sinkC_bits_needProbeAckData),
    .io_sinkC_bits_denied(io_sinkC_bits_denied),
    .io_sinkC_bits_corrupt(io_sinkC_bits_corrupt),
    .io_sinkC_bits_mshrTask(io_sinkC_bits_mshrTask),
    .io_sinkC_bits_mshrId(io_sinkC_bits_mshrId),
    .io_sinkC_bits_aliasTask(io_sinkC_bits_aliasTask),
    .io_sinkC_bits_useProbeData(io_sinkC_bits_useProbeData),
    .io_sinkC_bits_mshrRetry(io_sinkC_bits_mshrRetry),
    .io_sinkC_bits_readProbeDataDown(io_sinkC_bits_readProbeDataDown),
    .io_sinkC_bits_fromL2pft(io_sinkC_bits_fromL2pft),
    .io_sinkC_bits_needHint(io_sinkC_bits_needHint),
    .io_sinkC_bits_dirty(io_sinkC_bits_dirty),
    .io_sinkC_bits_way(io_sinkC_bits_way),
    .io_sinkC_bits_meta_dirty(io_sinkC_bits_meta_dirty),
    .io_sinkC_bits_meta_state(io_sinkC_bits_meta_state),
    .io_sinkC_bits_meta_clients(io_sinkC_bits_meta_clients),
    .io_sinkC_bits_meta_alias(io_sinkC_bits_meta_alias),
    .io_sinkC_bits_meta_prefetch(io_sinkC_bits_meta_prefetch),
    .io_sinkC_bits_meta_prefetchSrc(io_sinkC_bits_meta_prefetchSrc),
    .io_sinkC_bits_meta_accessed(io_sinkC_bits_meta_accessed),
    .io_sinkC_bits_meta_tagErr(io_sinkC_bits_meta_tagErr),
    .io_sinkC_bits_meta_dataErr(io_sinkC_bits_meta_dataErr),
    .io_sinkC_bits_metaWen(io_sinkC_bits_metaWen),
    .io_sinkC_bits_tagWen(io_sinkC_bits_tagWen),
    .io_sinkC_bits_dsWen(io_sinkC_bits_dsWen),
    .io_sinkC_bits_wayMask(io_sinkC_bits_wayMask),
    .io_sinkC_bits_replTask(io_sinkC_bits_replTask),
    .io_sinkC_bits_cmoTask(io_sinkC_bits_cmoTask),
    .io_sinkC_bits_cmoAll(io_sinkC_bits_cmoAll),
    .io_sinkC_bits_reqSource(io_sinkC_bits_reqSource),
    .io_sinkC_bits_mergeA(io_sinkC_bits_mergeA),
    .io_sinkC_bits_aMergeTask_off(io_sinkC_bits_aMergeTask_off),
    .io_sinkC_bits_aMergeTask_alias(io_sinkC_bits_aMergeTask_alias),
    .io_sinkC_bits_aMergeTask_vaddr(io_sinkC_bits_aMergeTask_vaddr),
    .io_sinkC_bits_aMergeTask_isKeyword(io_sinkC_bits_aMergeTask_isKeyword),
    .io_sinkC_bits_aMergeTask_opcode(io_sinkC_bits_aMergeTask_opcode),
    .io_sinkC_bits_aMergeTask_param(io_sinkC_bits_aMergeTask_param),
    .io_sinkC_bits_aMergeTask_sourceId(io_sinkC_bits_aMergeTask_sourceId),
    .io_sinkC_bits_aMergeTask_meta_dirty(io_sinkC_bits_aMergeTask_meta_dirty),
    .io_sinkC_bits_aMergeTask_meta_state(io_sinkC_bits_aMergeTask_meta_state),
    .io_sinkC_bits_aMergeTask_meta_clients(io_sinkC_bits_aMergeTask_meta_clients),
    .io_sinkC_bits_aMergeTask_meta_alias(io_sinkC_bits_aMergeTask_meta_alias),
    .io_sinkC_bits_aMergeTask_meta_prefetch(io_sinkC_bits_aMergeTask_meta_prefetch),
    .io_sinkC_bits_aMergeTask_meta_prefetchSrc(io_sinkC_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkC_bits_aMergeTask_meta_accessed(io_sinkC_bits_aMergeTask_meta_accessed),
    .io_sinkC_bits_aMergeTask_meta_tagErr(io_sinkC_bits_aMergeTask_meta_tagErr),
    .io_sinkC_bits_aMergeTask_meta_dataErr(io_sinkC_bits_aMergeTask_meta_dataErr),
    .io_sinkC_bits_snpHitRelease(io_sinkC_bits_snpHitRelease),
    .io_sinkC_bits_snpHitReleaseToInval(io_sinkC_bits_snpHitReleaseToInval),
    .io_sinkC_bits_snpHitReleaseToClean(io_sinkC_bits_snpHitReleaseToClean),
    .io_sinkC_bits_snpHitReleaseWithData(io_sinkC_bits_snpHitReleaseWithData),
    .io_sinkC_bits_snpHitReleaseIdx(io_sinkC_bits_snpHitReleaseIdx),
    .io_sinkC_bits_snpHitReleaseMeta_dirty(io_sinkC_bits_snpHitReleaseMeta_dirty),
    .io_sinkC_bits_snpHitReleaseMeta_state(io_sinkC_bits_snpHitReleaseMeta_state),
    .io_sinkC_bits_snpHitReleaseMeta_clients(io_sinkC_bits_snpHitReleaseMeta_clients),
    .io_sinkC_bits_snpHitReleaseMeta_alias(io_sinkC_bits_snpHitReleaseMeta_alias),
    .io_sinkC_bits_snpHitReleaseMeta_prefetch(io_sinkC_bits_snpHitReleaseMeta_prefetch),
    .io_sinkC_bits_snpHitReleaseMeta_prefetchSrc(io_sinkC_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkC_bits_snpHitReleaseMeta_accessed(io_sinkC_bits_snpHitReleaseMeta_accessed),
    .io_sinkC_bits_snpHitReleaseMeta_tagErr(io_sinkC_bits_snpHitReleaseMeta_tagErr),
    .io_sinkC_bits_snpHitReleaseMeta_dataErr(io_sinkC_bits_snpHitReleaseMeta_dataErr),
    .io_sinkC_bits_tgtID(io_sinkC_bits_tgtID),
    .io_sinkC_bits_srcID(io_sinkC_bits_srcID),
    .io_sinkC_bits_txnID(io_sinkC_bits_txnID),
    .io_sinkC_bits_homeNID(io_sinkC_bits_homeNID),
    .io_sinkC_bits_dbID(io_sinkC_bits_dbID),
    .io_sinkC_bits_fwdNID(io_sinkC_bits_fwdNID),
    .io_sinkC_bits_fwdTxnID(io_sinkC_bits_fwdTxnID),
    .io_sinkC_bits_chiOpcode(io_sinkC_bits_chiOpcode),
    .io_sinkC_bits_resp(io_sinkC_bits_resp),
    .io_sinkC_bits_fwdState(io_sinkC_bits_fwdState),
    .io_sinkC_bits_pCrdType(io_sinkC_bits_pCrdType),
    .io_sinkC_bits_retToSrc(io_sinkC_bits_retToSrc),
    .io_sinkC_bits_likelyshared(io_sinkC_bits_likelyshared),
    .io_sinkC_bits_expCompAck(io_sinkC_bits_expCompAck),
    .io_sinkC_bits_allowRetry(io_sinkC_bits_allowRetry),
    .io_sinkC_bits_memAttr_allocate(io_sinkC_bits_memAttr_allocate),
    .io_sinkC_bits_memAttr_cacheable(io_sinkC_bits_memAttr_cacheable),
    .io_sinkC_bits_memAttr_device(io_sinkC_bits_memAttr_device),
    .io_sinkC_bits_memAttr_ewa(io_sinkC_bits_memAttr_ewa),
    .io_sinkC_bits_traceTag(io_sinkC_bits_traceTag),
    .io_sinkC_bits_dataCheckErr(io_sinkC_bits_dataCheckErr),
    .io_mshrTask_ready(i_io_mshrTask_ready),
    .io_mshrTask_valid(io_mshrTask_valid),
    .io_mshrTask_bits_channel(io_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel(io_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set(io_mshrTask_bits_set),
    .io_mshrTask_bits_tag(io_mshrTask_bits_tag),
    .io_mshrTask_bits_off(io_mshrTask_bits_off),
    .io_mshrTask_bits_alias(io_mshrTask_bits_alias),
    .io_mshrTask_bits_vaddr(io_mshrTask_bits_vaddr),
    .io_mshrTask_bits_isKeyword(io_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode(io_mshrTask_bits_opcode),
    .io_mshrTask_bits_param(io_mshrTask_bits_param),
    .io_mshrTask_bits_size(io_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId(io_mshrTask_bits_sourceId),
    .io_mshrTask_bits_bufIdx(io_mshrTask_bits_bufIdx),
    .io_mshrTask_bits_needProbeAckData(io_mshrTask_bits_needProbeAckData),
    .io_mshrTask_bits_denied(io_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt(io_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask(io_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId(io_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask(io_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData(io_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry(io_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown(io_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft(io_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_needHint(io_mshrTask_bits_needHint),
    .io_mshrTask_bits_dirty(io_mshrTask_bits_dirty),
    .io_mshrTask_bits_way(io_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty(io_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state(io_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients(io_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias(io_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch(io_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc(io_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed(io_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr(io_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr(io_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen(io_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen(io_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen(io_mshrTask_bits_dsWen),
    .io_mshrTask_bits_wayMask(io_mshrTask_bits_wayMask),
    .io_mshrTask_bits_replTask(io_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask(io_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_cmoAll(io_mshrTask_bits_cmoAll),
    .io_mshrTask_bits_reqSource(io_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA(io_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off(io_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias(io_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr(io_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword(io_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode(io_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param(io_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId(io_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty(io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state(io_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients(io_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias(io_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_prefetch(io_mshrTask_bits_aMergeTask_meta_prefetch),
    .io_mshrTask_bits_aMergeTask_meta_prefetchSrc(io_mshrTask_bits_aMergeTask_meta_prefetchSrc),
    .io_mshrTask_bits_aMergeTask_meta_accessed(io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_aMergeTask_meta_tagErr(io_mshrTask_bits_aMergeTask_meta_tagErr),
    .io_mshrTask_bits_aMergeTask_meta_dataErr(io_mshrTask_bits_aMergeTask_meta_dataErr),
    .io_mshrTask_bits_snpHitRelease(io_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval(io_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean(io_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData(io_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx(io_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty(io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state(io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients(io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias(io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch(io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc(io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed(io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr(io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr(io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID(io_mshrTask_bits_tgtID),
    .io_mshrTask_bits_srcID(io_mshrTask_bits_srcID),
    .io_mshrTask_bits_txnID(io_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID(io_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID(io_mshrTask_bits_dbID),
    .io_mshrTask_bits_fwdNID(io_mshrTask_bits_fwdNID),
    .io_mshrTask_bits_fwdTxnID(io_mshrTask_bits_fwdTxnID),
    .io_mshrTask_bits_chiOpcode(io_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp(io_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState(io_mshrTask_bits_fwdState),
    .io_mshrTask_bits_pCrdType(io_mshrTask_bits_pCrdType),
    .io_mshrTask_bits_retToSrc(io_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared(io_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck(io_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry(io_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate(io_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable(io_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_device(io_mshrTask_bits_memAttr_device),
    .io_mshrTask_bits_memAttr_ewa(io_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag(io_mshrTask_bits_traceTag),
    .io_mshrTask_bits_dataCheckErr(io_mshrTask_bits_dataCheckErr),
    .io_dirRead_s1_ready(io_dirRead_s1_ready),
    .io_dirRead_s1_valid(i_io_dirRead_s1_valid),
    .io_dirRead_s1_bits_tag(i_io_dirRead_s1_bits_tag),
    .io_dirRead_s1_bits_set(i_io_dirRead_s1_bits_set),
    .io_dirRead_s1_bits_wayMask(i_io_dirRead_s1_bits_wayMask),
    .io_dirRead_s1_bits_replacerInfo_channel(i_io_dirRead_s1_bits_replacerInfo_channel),
    .io_dirRead_s1_bits_replacerInfo_opcode(i_io_dirRead_s1_bits_replacerInfo_opcode),
    .io_dirRead_s1_bits_replacerInfo_reqSource(i_io_dirRead_s1_bits_replacerInfo_reqSource),
    .io_dirRead_s1_bits_replacerInfo_refill_prefetch(i_io_dirRead_s1_bits_replacerInfo_refill_prefetch),
    .io_dirRead_s1_bits_refill(i_io_dirRead_s1_bits_refill),
    .io_dirRead_s1_bits_mshrId(i_io_dirRead_s1_bits_mshrId),
    .io_dirRead_s1_bits_cmoAll(i_io_dirRead_s1_bits_cmoAll),
    .io_dirRead_s1_bits_cmoWay(i_io_dirRead_s1_bits_cmoWay),
    .io_taskToPipe_s2_valid(i_io_taskToPipe_s2_valid),
    .io_taskToPipe_s2_bits_channel(i_io_taskToPipe_s2_bits_channel),
    .io_taskToPipe_s2_bits_txChannel(i_io_taskToPipe_s2_bits_txChannel),
    .io_taskToPipe_s2_bits_set(i_io_taskToPipe_s2_bits_set),
    .io_taskToPipe_s2_bits_tag(i_io_taskToPipe_s2_bits_tag),
    .io_taskToPipe_s2_bits_off(i_io_taskToPipe_s2_bits_off),
    .io_taskToPipe_s2_bits_alias(i_io_taskToPipe_s2_bits_alias),
    .io_taskToPipe_s2_bits_vaddr(i_io_taskToPipe_s2_bits_vaddr),
    .io_taskToPipe_s2_bits_isKeyword(i_io_taskToPipe_s2_bits_isKeyword),
    .io_taskToPipe_s2_bits_opcode(i_io_taskToPipe_s2_bits_opcode),
    .io_taskToPipe_s2_bits_param(i_io_taskToPipe_s2_bits_param),
    .io_taskToPipe_s2_bits_size(i_io_taskToPipe_s2_bits_size),
    .io_taskToPipe_s2_bits_sourceId(i_io_taskToPipe_s2_bits_sourceId),
    .io_taskToPipe_s2_bits_bufIdx(i_io_taskToPipe_s2_bits_bufIdx),
    .io_taskToPipe_s2_bits_needProbeAckData(i_io_taskToPipe_s2_bits_needProbeAckData),
    .io_taskToPipe_s2_bits_denied(i_io_taskToPipe_s2_bits_denied),
    .io_taskToPipe_s2_bits_corrupt(i_io_taskToPipe_s2_bits_corrupt),
    .io_taskToPipe_s2_bits_mshrTask(i_io_taskToPipe_s2_bits_mshrTask),
    .io_taskToPipe_s2_bits_mshrId(i_io_taskToPipe_s2_bits_mshrId),
    .io_taskToPipe_s2_bits_aliasTask(i_io_taskToPipe_s2_bits_aliasTask),
    .io_taskToPipe_s2_bits_useProbeData(i_io_taskToPipe_s2_bits_useProbeData),
    .io_taskToPipe_s2_bits_mshrRetry(i_io_taskToPipe_s2_bits_mshrRetry),
    .io_taskToPipe_s2_bits_readProbeDataDown(i_io_taskToPipe_s2_bits_readProbeDataDown),
    .io_taskToPipe_s2_bits_fromL2pft(i_io_taskToPipe_s2_bits_fromL2pft),
    .io_taskToPipe_s2_bits_needHint(i_io_taskToPipe_s2_bits_needHint),
    .io_taskToPipe_s2_bits_dirty(i_io_taskToPipe_s2_bits_dirty),
    .io_taskToPipe_s2_bits_way(i_io_taskToPipe_s2_bits_way),
    .io_taskToPipe_s2_bits_meta_dirty(i_io_taskToPipe_s2_bits_meta_dirty),
    .io_taskToPipe_s2_bits_meta_state(i_io_taskToPipe_s2_bits_meta_state),
    .io_taskToPipe_s2_bits_meta_clients(i_io_taskToPipe_s2_bits_meta_clients),
    .io_taskToPipe_s2_bits_meta_alias(i_io_taskToPipe_s2_bits_meta_alias),
    .io_taskToPipe_s2_bits_meta_prefetch(i_io_taskToPipe_s2_bits_meta_prefetch),
    .io_taskToPipe_s2_bits_meta_prefetchSrc(i_io_taskToPipe_s2_bits_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_meta_accessed(i_io_taskToPipe_s2_bits_meta_accessed),
    .io_taskToPipe_s2_bits_meta_tagErr(i_io_taskToPipe_s2_bits_meta_tagErr),
    .io_taskToPipe_s2_bits_meta_dataErr(i_io_taskToPipe_s2_bits_meta_dataErr),
    .io_taskToPipe_s2_bits_metaWen(i_io_taskToPipe_s2_bits_metaWen),
    .io_taskToPipe_s2_bits_tagWen(i_io_taskToPipe_s2_bits_tagWen),
    .io_taskToPipe_s2_bits_dsWen(i_io_taskToPipe_s2_bits_dsWen),
    .io_taskToPipe_s2_bits_wayMask(i_io_taskToPipe_s2_bits_wayMask),
    .io_taskToPipe_s2_bits_replTask(i_io_taskToPipe_s2_bits_replTask),
    .io_taskToPipe_s2_bits_cmoTask(i_io_taskToPipe_s2_bits_cmoTask),
    .io_taskToPipe_s2_bits_cmoAll(i_io_taskToPipe_s2_bits_cmoAll),
    .io_taskToPipe_s2_bits_reqSource(i_io_taskToPipe_s2_bits_reqSource),
    .io_taskToPipe_s2_bits_mergeA(i_io_taskToPipe_s2_bits_mergeA),
    .io_taskToPipe_s2_bits_aMergeTask_off(i_io_taskToPipe_s2_bits_aMergeTask_off),
    .io_taskToPipe_s2_bits_aMergeTask_alias(i_io_taskToPipe_s2_bits_aMergeTask_alias),
    .io_taskToPipe_s2_bits_aMergeTask_vaddr(i_io_taskToPipe_s2_bits_aMergeTask_vaddr),
    .io_taskToPipe_s2_bits_aMergeTask_isKeyword(i_io_taskToPipe_s2_bits_aMergeTask_isKeyword),
    .io_taskToPipe_s2_bits_aMergeTask_opcode(i_io_taskToPipe_s2_bits_aMergeTask_opcode),
    .io_taskToPipe_s2_bits_aMergeTask_param(i_io_taskToPipe_s2_bits_aMergeTask_param),
    .io_taskToPipe_s2_bits_aMergeTask_sourceId(i_io_taskToPipe_s2_bits_aMergeTask_sourceId),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dirty(i_io_taskToPipe_s2_bits_aMergeTask_meta_dirty),
    .io_taskToPipe_s2_bits_aMergeTask_meta_state(i_io_taskToPipe_s2_bits_aMergeTask_meta_state),
    .io_taskToPipe_s2_bits_aMergeTask_meta_clients(i_io_taskToPipe_s2_bits_aMergeTask_meta_clients),
    .io_taskToPipe_s2_bits_aMergeTask_meta_alias(i_io_taskToPipe_s2_bits_aMergeTask_meta_alias),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetch(i_io_taskToPipe_s2_bits_aMergeTask_meta_prefetch),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc(i_io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_aMergeTask_meta_accessed(i_io_taskToPipe_s2_bits_aMergeTask_meta_accessed),
    .io_taskToPipe_s2_bits_aMergeTask_meta_tagErr(i_io_taskToPipe_s2_bits_aMergeTask_meta_tagErr),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dataErr(i_io_taskToPipe_s2_bits_aMergeTask_meta_dataErr),
    .io_taskToPipe_s2_bits_snpHitRelease(i_io_taskToPipe_s2_bits_snpHitRelease),
    .io_taskToPipe_s2_bits_snpHitReleaseToInval(i_io_taskToPipe_s2_bits_snpHitReleaseToInval),
    .io_taskToPipe_s2_bits_snpHitReleaseToClean(i_io_taskToPipe_s2_bits_snpHitReleaseToClean),
    .io_taskToPipe_s2_bits_snpHitReleaseWithData(i_io_taskToPipe_s2_bits_snpHitReleaseWithData),
    .io_taskToPipe_s2_bits_snpHitReleaseIdx(i_io_taskToPipe_s2_bits_snpHitReleaseIdx),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_state(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_state),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_clients(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_clients),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_alias(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_alias),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr(i_io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskToPipe_s2_bits_tgtID(i_io_taskToPipe_s2_bits_tgtID),
    .io_taskToPipe_s2_bits_srcID(i_io_taskToPipe_s2_bits_srcID),
    .io_taskToPipe_s2_bits_txnID(i_io_taskToPipe_s2_bits_txnID),
    .io_taskToPipe_s2_bits_homeNID(i_io_taskToPipe_s2_bits_homeNID),
    .io_taskToPipe_s2_bits_dbID(i_io_taskToPipe_s2_bits_dbID),
    .io_taskToPipe_s2_bits_fwdNID(i_io_taskToPipe_s2_bits_fwdNID),
    .io_taskToPipe_s2_bits_fwdTxnID(i_io_taskToPipe_s2_bits_fwdTxnID),
    .io_taskToPipe_s2_bits_chiOpcode(i_io_taskToPipe_s2_bits_chiOpcode),
    .io_taskToPipe_s2_bits_resp(i_io_taskToPipe_s2_bits_resp),
    .io_taskToPipe_s2_bits_fwdState(i_io_taskToPipe_s2_bits_fwdState),
    .io_taskToPipe_s2_bits_pCrdType(i_io_taskToPipe_s2_bits_pCrdType),
    .io_taskToPipe_s2_bits_retToSrc(i_io_taskToPipe_s2_bits_retToSrc),
    .io_taskToPipe_s2_bits_likelyshared(i_io_taskToPipe_s2_bits_likelyshared),
    .io_taskToPipe_s2_bits_expCompAck(i_io_taskToPipe_s2_bits_expCompAck),
    .io_taskToPipe_s2_bits_allowRetry(i_io_taskToPipe_s2_bits_allowRetry),
    .io_taskToPipe_s2_bits_memAttr_allocate(i_io_taskToPipe_s2_bits_memAttr_allocate),
    .io_taskToPipe_s2_bits_memAttr_cacheable(i_io_taskToPipe_s2_bits_memAttr_cacheable),
    .io_taskToPipe_s2_bits_memAttr_device(i_io_taskToPipe_s2_bits_memAttr_device),
    .io_taskToPipe_s2_bits_memAttr_ewa(i_io_taskToPipe_s2_bits_memAttr_ewa),
    .io_taskToPipe_s2_bits_traceTag(i_io_taskToPipe_s2_bits_traceTag),
    .io_taskToPipe_s2_bits_dataCheckErr(i_io_taskToPipe_s2_bits_dataCheckErr),
    .io_taskInfo_s1_valid(i_io_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel(i_io_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_txChannel(i_io_taskInfo_s1_bits_txChannel),
    .io_taskInfo_s1_bits_set(i_io_taskInfo_s1_bits_set),
    .io_taskInfo_s1_bits_tag(i_io_taskInfo_s1_bits_tag),
    .io_taskInfo_s1_bits_off(i_io_taskInfo_s1_bits_off),
    .io_taskInfo_s1_bits_alias(i_io_taskInfo_s1_bits_alias),
    .io_taskInfo_s1_bits_vaddr(i_io_taskInfo_s1_bits_vaddr),
    .io_taskInfo_s1_bits_isKeyword(i_io_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode(i_io_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_param(i_io_taskInfo_s1_bits_param),
    .io_taskInfo_s1_bits_size(i_io_taskInfo_s1_bits_size),
    .io_taskInfo_s1_bits_sourceId(i_io_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_bufIdx(i_io_taskInfo_s1_bits_bufIdx),
    .io_taskInfo_s1_bits_needProbeAckData(i_io_taskInfo_s1_bits_needProbeAckData),
    .io_taskInfo_s1_bits_denied(i_io_taskInfo_s1_bits_denied),
    .io_taskInfo_s1_bits_corrupt(i_io_taskInfo_s1_bits_corrupt),
    .io_taskInfo_s1_bits_mshrTask(i_io_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mshrId(i_io_taskInfo_s1_bits_mshrId),
    .io_taskInfo_s1_bits_aliasTask(i_io_taskInfo_s1_bits_aliasTask),
    .io_taskInfo_s1_bits_useProbeData(i_io_taskInfo_s1_bits_useProbeData),
    .io_taskInfo_s1_bits_mshrRetry(i_io_taskInfo_s1_bits_mshrRetry),
    .io_taskInfo_s1_bits_readProbeDataDown(i_io_taskInfo_s1_bits_readProbeDataDown),
    .io_taskInfo_s1_bits_fromL2pft(i_io_taskInfo_s1_bits_fromL2pft),
    .io_taskInfo_s1_bits_needHint(i_io_taskInfo_s1_bits_needHint),
    .io_taskInfo_s1_bits_dirty(i_io_taskInfo_s1_bits_dirty),
    .io_taskInfo_s1_bits_way(i_io_taskInfo_s1_bits_way),
    .io_taskInfo_s1_bits_meta_dirty(i_io_taskInfo_s1_bits_meta_dirty),
    .io_taskInfo_s1_bits_meta_state(i_io_taskInfo_s1_bits_meta_state),
    .io_taskInfo_s1_bits_meta_clients(i_io_taskInfo_s1_bits_meta_clients),
    .io_taskInfo_s1_bits_meta_alias(i_io_taskInfo_s1_bits_meta_alias),
    .io_taskInfo_s1_bits_meta_prefetch(i_io_taskInfo_s1_bits_meta_prefetch),
    .io_taskInfo_s1_bits_meta_prefetchSrc(i_io_taskInfo_s1_bits_meta_prefetchSrc),
    .io_taskInfo_s1_bits_meta_accessed(i_io_taskInfo_s1_bits_meta_accessed),
    .io_taskInfo_s1_bits_meta_tagErr(i_io_taskInfo_s1_bits_meta_tagErr),
    .io_taskInfo_s1_bits_meta_dataErr(i_io_taskInfo_s1_bits_meta_dataErr),
    .io_taskInfo_s1_bits_metaWen(i_io_taskInfo_s1_bits_metaWen),
    .io_taskInfo_s1_bits_tagWen(i_io_taskInfo_s1_bits_tagWen),
    .io_taskInfo_s1_bits_dsWen(i_io_taskInfo_s1_bits_dsWen),
    .io_taskInfo_s1_bits_wayMask(i_io_taskInfo_s1_bits_wayMask),
    .io_taskInfo_s1_bits_replTask(i_io_taskInfo_s1_bits_replTask),
    .io_taskInfo_s1_bits_cmoTask(i_io_taskInfo_s1_bits_cmoTask),
    .io_taskInfo_s1_bits_cmoAll(i_io_taskInfo_s1_bits_cmoAll),
    .io_taskInfo_s1_bits_reqSource(i_io_taskInfo_s1_bits_reqSource),
    .io_taskInfo_s1_bits_mergeA(i_io_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_off(i_io_taskInfo_s1_bits_aMergeTask_off),
    .io_taskInfo_s1_bits_aMergeTask_alias(i_io_taskInfo_s1_bits_aMergeTask_alias),
    .io_taskInfo_s1_bits_aMergeTask_vaddr(i_io_taskInfo_s1_bits_aMergeTask_vaddr),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword(i_io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode(i_io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_param(i_io_taskInfo_s1_bits_aMergeTask_param),
    .io_taskInfo_s1_bits_aMergeTask_sourceId(i_io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_taskInfo_s1_bits_aMergeTask_meta_dirty(i_io_taskInfo_s1_bits_aMergeTask_meta_dirty),
    .io_taskInfo_s1_bits_aMergeTask_meta_state(i_io_taskInfo_s1_bits_aMergeTask_meta_state),
    .io_taskInfo_s1_bits_aMergeTask_meta_clients(i_io_taskInfo_s1_bits_aMergeTask_meta_clients),
    .io_taskInfo_s1_bits_aMergeTask_meta_alias(i_io_taskInfo_s1_bits_aMergeTask_meta_alias),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetch(i_io_taskInfo_s1_bits_aMergeTask_meta_prefetch),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc(i_io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc),
    .io_taskInfo_s1_bits_aMergeTask_meta_accessed(i_io_taskInfo_s1_bits_aMergeTask_meta_accessed),
    .io_taskInfo_s1_bits_aMergeTask_meta_tagErr(i_io_taskInfo_s1_bits_aMergeTask_meta_tagErr),
    .io_taskInfo_s1_bits_aMergeTask_meta_dataErr(i_io_taskInfo_s1_bits_aMergeTask_meta_dataErr),
    .io_taskInfo_s1_bits_snpHitRelease(i_io_taskInfo_s1_bits_snpHitRelease),
    .io_taskInfo_s1_bits_snpHitReleaseToInval(i_io_taskInfo_s1_bits_snpHitReleaseToInval),
    .io_taskInfo_s1_bits_snpHitReleaseToClean(i_io_taskInfo_s1_bits_snpHitReleaseToClean),
    .io_taskInfo_s1_bits_snpHitReleaseWithData(i_io_taskInfo_s1_bits_snpHitReleaseWithData),
    .io_taskInfo_s1_bits_snpHitReleaseIdx(i_io_taskInfo_s1_bits_snpHitReleaseIdx),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dirty(i_io_taskInfo_s1_bits_snpHitReleaseMeta_dirty),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_state(i_io_taskInfo_s1_bits_snpHitReleaseMeta_state),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_clients(i_io_taskInfo_s1_bits_snpHitReleaseMeta_clients),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_alias(i_io_taskInfo_s1_bits_snpHitReleaseMeta_alias),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch(i_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc(i_io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_accessed(i_io_taskInfo_s1_bits_snpHitReleaseMeta_accessed),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr(i_io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr(i_io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr),
    .io_taskInfo_s1_bits_tgtID(i_io_taskInfo_s1_bits_tgtID),
    .io_taskInfo_s1_bits_srcID(i_io_taskInfo_s1_bits_srcID),
    .io_taskInfo_s1_bits_txnID(i_io_taskInfo_s1_bits_txnID),
    .io_taskInfo_s1_bits_homeNID(i_io_taskInfo_s1_bits_homeNID),
    .io_taskInfo_s1_bits_dbID(i_io_taskInfo_s1_bits_dbID),
    .io_taskInfo_s1_bits_fwdNID(i_io_taskInfo_s1_bits_fwdNID),
    .io_taskInfo_s1_bits_fwdTxnID(i_io_taskInfo_s1_bits_fwdTxnID),
    .io_taskInfo_s1_bits_chiOpcode(i_io_taskInfo_s1_bits_chiOpcode),
    .io_taskInfo_s1_bits_resp(i_io_taskInfo_s1_bits_resp),
    .io_taskInfo_s1_bits_fwdState(i_io_taskInfo_s1_bits_fwdState),
    .io_taskInfo_s1_bits_pCrdType(i_io_taskInfo_s1_bits_pCrdType),
    .io_taskInfo_s1_bits_retToSrc(i_io_taskInfo_s1_bits_retToSrc),
    .io_taskInfo_s1_bits_likelyshared(i_io_taskInfo_s1_bits_likelyshared),
    .io_taskInfo_s1_bits_expCompAck(i_io_taskInfo_s1_bits_expCompAck),
    .io_taskInfo_s1_bits_allowRetry(i_io_taskInfo_s1_bits_allowRetry),
    .io_taskInfo_s1_bits_memAttr_allocate(i_io_taskInfo_s1_bits_memAttr_allocate),
    .io_taskInfo_s1_bits_memAttr_cacheable(i_io_taskInfo_s1_bits_memAttr_cacheable),
    .io_taskInfo_s1_bits_memAttr_device(i_io_taskInfo_s1_bits_memAttr_device),
    .io_taskInfo_s1_bits_memAttr_ewa(i_io_taskInfo_s1_bits_memAttr_ewa),
    .io_taskInfo_s1_bits_traceTag(i_io_taskInfo_s1_bits_traceTag),
    .io_taskInfo_s1_bits_dataCheckErr(i_io_taskInfo_s1_bits_dataCheckErr),
    .io_refillBufRead_s2_valid(i_io_refillBufRead_s2_valid),
    .io_refillBufRead_s2_bits_id(i_io_refillBufRead_s2_bits_id),
    .io_releaseBufRead_s2_valid(i_io_releaseBufRead_s2_valid),
    .io_releaseBufRead_s2_bits_id(i_io_releaseBufRead_s2_bits_id),
    .io_status_s1_tags_0(i_io_status_s1_tags_0),
    .io_status_s1_tags_1(i_io_status_s1_tags_1),
    .io_status_s1_tags_2(i_io_status_s1_tags_2),
    .io_status_s1_tags_3(i_io_status_s1_tags_3),
    .io_status_s1_sets_0(i_io_status_s1_sets_0),
    .io_status_s1_sets_1(i_io_status_s1_sets_1),
    .io_status_s1_sets_2(i_io_status_s1_sets_2),
    .io_status_s1_sets_3(i_io_status_s1_sets_3),
    .io_status_vec_0_valid(i_io_status_vec_0_valid),
    .io_status_vec_0_bits_channel(i_io_status_vec_0_bits_channel),
    .io_status_vec_1_valid(i_io_status_vec_1_valid),
    .io_status_vec_1_bits_channel(i_io_status_vec_1_bits_channel),
    .io_status_vec_toTX_0_valid(i_io_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel(i_io_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel(i_io_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask(i_io_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid(i_io_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel(i_io_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel(i_io_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask(i_io_status_vec_toTX_1_bits_mshrTask),
    .io_fromMSHRCtl_blockG_s1(io_fromMSHRCtl_blockG_s1),
    .io_fromMSHRCtl_blockA_s1(io_fromMSHRCtl_blockA_s1),
    .io_fromMSHRCtl_blockB_s1(io_fromMSHRCtl_blockB_s1),
    .io_fromMSHRCtl_blockC_s1(io_fromMSHRCtl_blockC_s1),
    .io_fromMainPipe_blockG_s1(io_fromMainPipe_blockG_s1),
    .io_fromMainPipe_blockA_s1(io_fromMainPipe_blockA_s1),
    .io_fromMainPipe_blockB_s1(io_fromMainPipe_blockB_s1),
    .io_fromMainPipe_blockC_s1(io_fromMainPipe_blockC_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1(io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1),
    .io_fromGrantBuffer_blockMSHRReqEntrance(io_fromGrantBuffer_blockMSHRReqEntrance),
    .io_fromTXDAT_blockMSHRReqEntrance(io_fromTXDAT_blockMSHRReqEntrance),
    .io_fromTXDAT_blockSinkBReqEntrance(io_fromTXDAT_blockSinkBReqEntrance),
    .io_fromTXRSP_blockMSHRReqEntrance(io_fromTXRSP_blockMSHRReqEntrance),
    .io_fromTXRSP_blockSinkBReqEntrance(io_fromTXRSP_blockSinkBReqEntrance),
    .io_fromTXREQ_blockMSHRReqEntrance(io_fromTXREQ_blockMSHRReqEntrance),
    .io_msInfo_0_valid(io_msInfo_0_valid),
    .io_msInfo_0_bits_channel(io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set(io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way(io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag(io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree(io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask(io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease(io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill(io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty(io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state(io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients(io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias(io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch(io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc(io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed(io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr(io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr(io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag(io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit(io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch(io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch(io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param(io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA(io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst(io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release(io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill(io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp(io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw(io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack(io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp(io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast(io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData(io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean(io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid(io_msInfo_1_valid),
    .io_msInfo_1_bits_channel(io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set(io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way(io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag(io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree(io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask(io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease(io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill(io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty(io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state(io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients(io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias(io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch(io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc(io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed(io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr(io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr(io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag(io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit(io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch(io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch(io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param(io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA(io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst(io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release(io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill(io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp(io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw(io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack(io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp(io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast(io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData(io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean(io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid(io_msInfo_2_valid),
    .io_msInfo_2_bits_channel(io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set(io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way(io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag(io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree(io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask(io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease(io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill(io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty(io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state(io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients(io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias(io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch(io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc(io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed(io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr(io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr(io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag(io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit(io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch(io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch(io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param(io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA(io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst(io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release(io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill(io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp(io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw(io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack(io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp(io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast(io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData(io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean(io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid(io_msInfo_3_valid),
    .io_msInfo_3_bits_channel(io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set(io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way(io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag(io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree(io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask(io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease(io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill(io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty(io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state(io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients(io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias(io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch(io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc(io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed(io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr(io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr(io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag(io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit(io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch(io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch(io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param(io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA(io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst(io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release(io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill(io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp(io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw(io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack(io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp(io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast(io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData(io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean(io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid(io_msInfo_4_valid),
    .io_msInfo_4_bits_channel(io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set(io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way(io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag(io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree(io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask(io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease(io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill(io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty(io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state(io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients(io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias(io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch(io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc(io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed(io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr(io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr(io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag(io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit(io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch(io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch(io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param(io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA(io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst(io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release(io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill(io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp(io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw(io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack(io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp(io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast(io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData(io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean(io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid(io_msInfo_5_valid),
    .io_msInfo_5_bits_channel(io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set(io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way(io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag(io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree(io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask(io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease(io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill(io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty(io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state(io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients(io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias(io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch(io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc(io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed(io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr(io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr(io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag(io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit(io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch(io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch(io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param(io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA(io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst(io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release(io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill(io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp(io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw(io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack(io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp(io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast(io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData(io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean(io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid(io_msInfo_6_valid),
    .io_msInfo_6_bits_channel(io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set(io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way(io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag(io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree(io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask(io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease(io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill(io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty(io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state(io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients(io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias(io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch(io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc(io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed(io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr(io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr(io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag(io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit(io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch(io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch(io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param(io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA(io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst(io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release(io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill(io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp(io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw(io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack(io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp(io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast(io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData(io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean(io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid(io_msInfo_7_valid),
    .io_msInfo_7_bits_channel(io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set(io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way(io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag(io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree(io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask(io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease(io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill(io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty(io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state(io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients(io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias(io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch(io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc(io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed(io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr(io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr(io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag(io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit(io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch(io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch(io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param(io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA(io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst(io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release(io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill(io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp(io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw(io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack(io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp(io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast(io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData(io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean(io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid(io_msInfo_8_valid),
    .io_msInfo_8_bits_channel(io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set(io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way(io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag(io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree(io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask(io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease(io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill(io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty(io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state(io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients(io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias(io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch(io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc(io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed(io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr(io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr(io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag(io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit(io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch(io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch(io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param(io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA(io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst(io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release(io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill(io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp(io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw(io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack(io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp(io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast(io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData(io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean(io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid(io_msInfo_9_valid),
    .io_msInfo_9_bits_channel(io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set(io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way(io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag(io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree(io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask(io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease(io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill(io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty(io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state(io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients(io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias(io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch(io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc(io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed(io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr(io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr(io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag(io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit(io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch(io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch(io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param(io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA(io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst(io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release(io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill(io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp(io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw(io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack(io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp(io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast(io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData(io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean(io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid(io_msInfo_10_valid),
    .io_msInfo_10_bits_channel(io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set(io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way(io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag(io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree(io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask(io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease(io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill(io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty(io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state(io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients(io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias(io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch(io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc(io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed(io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr(io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr(io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag(io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit(io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch(io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch(io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param(io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA(io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst(io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release(io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill(io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp(io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw(io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack(io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp(io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast(io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData(io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean(io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid(io_msInfo_11_valid),
    .io_msInfo_11_bits_channel(io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set(io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way(io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag(io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree(io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask(io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease(io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill(io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty(io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state(io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients(io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias(io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch(io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc(io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed(io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr(io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr(io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag(io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit(io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch(io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch(io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param(io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA(io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst(io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release(io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill(io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp(io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw(io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack(io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp(io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast(io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData(io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean(io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid(io_msInfo_12_valid),
    .io_msInfo_12_bits_channel(io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set(io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way(io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag(io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree(io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask(io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease(io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill(io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty(io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state(io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients(io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias(io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch(io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc(io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed(io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr(io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr(io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag(io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit(io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch(io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch(io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param(io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA(io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst(io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release(io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill(io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp(io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw(io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack(io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp(io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast(io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData(io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean(io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid(io_msInfo_13_valid),
    .io_msInfo_13_bits_channel(io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set(io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way(io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag(io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree(io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask(io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease(io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill(io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty(io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state(io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients(io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias(io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch(io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc(io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed(io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr(io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr(io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag(io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit(io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch(io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch(io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param(io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA(io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst(io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release(io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill(io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp(io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw(io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack(io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp(io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast(io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData(io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean(io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid(io_msInfo_14_valid),
    .io_msInfo_14_bits_channel(io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set(io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way(io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag(io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree(io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask(io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease(io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill(io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty(io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state(io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients(io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias(io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch(io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc(io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed(io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr(io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr(io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag(io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit(io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch(io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch(io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param(io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA(io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst(io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release(io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill(io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp(io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw(io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack(io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp(io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast(io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData(io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean(io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid(io_msInfo_15_valid),
    .io_msInfo_15_bits_channel(io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set(io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way(io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag(io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree(io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask(io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease(io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill(io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty(io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state(io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients(io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias(io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch(io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc(io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed(io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr(io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr(io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag(io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit(io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch(io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch(io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param(io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA(io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst(io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release(io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill(io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp(io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw(io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack(io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp(io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast(io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData(io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean(io_msInfo_15_bits_releaseToClean)
  );

  task automatic drive_random();
    io_sinkA_valid = ($urandom_range(0,1) == 0);
    io_sinkA_bits_channel = $urandom;
    io_sinkA_bits_txChannel = $urandom;
    io_sinkA_bits_set = $urandom_range(0,7);
    io_sinkA_bits_tag = $urandom_range(0,7);
    io_sinkA_bits_off = $urandom;
    io_sinkA_bits_alias = $urandom;
    io_sinkA_bits_vaddr = {$urandom, $urandom};
    io_sinkA_bits_isKeyword = $urandom;
    io_sinkA_bits_opcode = $urandom_range(0,5);
    io_sinkA_bits_param = $urandom;
    io_sinkA_bits_size = $urandom;
    io_sinkA_bits_sourceId = $urandom;
    io_sinkA_bits_bufIdx = $urandom;
    io_sinkA_bits_needProbeAckData = $urandom;
    io_sinkA_bits_denied = $urandom;
    io_sinkA_bits_corrupt = $urandom;
    io_sinkA_bits_mshrTask = $urandom;
    io_sinkA_bits_mshrId = $urandom;
    io_sinkA_bits_aliasTask = $urandom;
    io_sinkA_bits_useProbeData = $urandom;
    io_sinkA_bits_mshrRetry = $urandom;
    io_sinkA_bits_readProbeDataDown = $urandom;
    io_sinkA_bits_fromL2pft = $urandom;
    io_sinkA_bits_needHint = $urandom;
    io_sinkA_bits_dirty = $urandom;
    io_sinkA_bits_way = $urandom_range(0,7);
    io_sinkA_bits_meta_dirty = $urandom;
    io_sinkA_bits_meta_state = $urandom;
    io_sinkA_bits_meta_clients = $urandom;
    io_sinkA_bits_meta_alias = $urandom;
    io_sinkA_bits_meta_prefetch = $urandom;
    io_sinkA_bits_meta_prefetchSrc = $urandom;
    io_sinkA_bits_meta_accessed = $urandom;
    io_sinkA_bits_meta_tagErr = $urandom;
    io_sinkA_bits_meta_dataErr = $urandom;
    io_sinkA_bits_metaWen = $urandom;
    io_sinkA_bits_tagWen = $urandom;
    io_sinkA_bits_dsWen = $urandom;
    io_sinkA_bits_wayMask = $urandom;
    io_sinkA_bits_replTask = $urandom;
    io_sinkA_bits_cmoTask = $urandom;
    io_sinkA_bits_cmoAll = $urandom;
    io_sinkA_bits_reqSource = $urandom;
    io_sinkA_bits_mergeA = $urandom;
    io_sinkA_bits_aMergeTask_off = $urandom;
    io_sinkA_bits_aMergeTask_alias = $urandom;
    io_sinkA_bits_aMergeTask_vaddr = {$urandom, $urandom};
    io_sinkA_bits_aMergeTask_isKeyword = $urandom;
    io_sinkA_bits_aMergeTask_opcode = $urandom;
    io_sinkA_bits_aMergeTask_param = $urandom;
    io_sinkA_bits_aMergeTask_sourceId = $urandom;
    io_sinkA_bits_aMergeTask_meta_dirty = $urandom;
    io_sinkA_bits_aMergeTask_meta_state = $urandom;
    io_sinkA_bits_aMergeTask_meta_clients = $urandom;
    io_sinkA_bits_aMergeTask_meta_alias = $urandom;
    io_sinkA_bits_aMergeTask_meta_prefetch = $urandom;
    io_sinkA_bits_aMergeTask_meta_prefetchSrc = $urandom;
    io_sinkA_bits_aMergeTask_meta_accessed = $urandom;
    io_sinkA_bits_aMergeTask_meta_tagErr = $urandom;
    io_sinkA_bits_aMergeTask_meta_dataErr = $urandom;
    io_sinkA_bits_snpHitRelease = $urandom;
    io_sinkA_bits_snpHitReleaseToInval = $urandom;
    io_sinkA_bits_snpHitReleaseToClean = $urandom;
    io_sinkA_bits_snpHitReleaseWithData = $urandom;
    io_sinkA_bits_snpHitReleaseIdx = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_dirty = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_state = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_clients = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_alias = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_prefetch = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_accessed = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_tagErr = $urandom;
    io_sinkA_bits_snpHitReleaseMeta_dataErr = $urandom;
    io_sinkA_bits_tgtID = $urandom;
    io_sinkA_bits_srcID = $urandom;
    io_sinkA_bits_txnID = $urandom;
    io_sinkA_bits_homeNID = $urandom;
    io_sinkA_bits_dbID = $urandom;
    io_sinkA_bits_fwdNID = $urandom;
    io_sinkA_bits_fwdTxnID = $urandom;
    io_sinkA_bits_chiOpcode = $urandom;
    io_sinkA_bits_resp = $urandom;
    io_sinkA_bits_fwdState = $urandom;
    io_sinkA_bits_pCrdType = $urandom;
    io_sinkA_bits_retToSrc = $urandom;
    io_sinkA_bits_likelyshared = $urandom;
    io_sinkA_bits_expCompAck = $urandom;
    io_sinkA_bits_allowRetry = $urandom;
    io_sinkA_bits_memAttr_allocate = $urandom;
    io_sinkA_bits_memAttr_cacheable = $urandom;
    io_sinkA_bits_memAttr_device = $urandom;
    io_sinkA_bits_memAttr_ewa = $urandom;
    io_sinkA_bits_traceTag = $urandom;
    io_sinkA_bits_dataCheckErr = $urandom;
    io_ATag = $urandom_range(0,7);
    io_ASet = $urandom_range(0,7);
    io_sinkB_valid = ($urandom_range(0,1) == 0);
    io_sinkB_bits_channel = $urandom;
    io_sinkB_bits_txChannel = $urandom;
    io_sinkB_bits_set = $urandom_range(0,7);
    io_sinkB_bits_tag = $urandom_range(0,7);
    io_sinkB_bits_off = $urandom;
    io_sinkB_bits_alias = $urandom;
    io_sinkB_bits_vaddr = {$urandom, $urandom};
    io_sinkB_bits_isKeyword = $urandom;
    io_sinkB_bits_opcode = $urandom_range(0,5);
    io_sinkB_bits_param = $urandom;
    io_sinkB_bits_size = $urandom;
    io_sinkB_bits_sourceId = $urandom;
    io_sinkB_bits_bufIdx = $urandom;
    io_sinkB_bits_needProbeAckData = $urandom;
    io_sinkB_bits_denied = $urandom;
    io_sinkB_bits_corrupt = $urandom;
    io_sinkB_bits_mshrTask = $urandom;
    io_sinkB_bits_mshrId = $urandom;
    io_sinkB_bits_aliasTask = $urandom;
    io_sinkB_bits_useProbeData = $urandom;
    io_sinkB_bits_mshrRetry = $urandom;
    io_sinkB_bits_readProbeDataDown = $urandom;
    io_sinkB_bits_fromL2pft = $urandom;
    io_sinkB_bits_needHint = $urandom;
    io_sinkB_bits_dirty = $urandom;
    io_sinkB_bits_way = $urandom_range(0,7);
    io_sinkB_bits_meta_dirty = $urandom;
    io_sinkB_bits_meta_state = $urandom;
    io_sinkB_bits_meta_clients = $urandom;
    io_sinkB_bits_meta_alias = $urandom;
    io_sinkB_bits_meta_prefetch = $urandom;
    io_sinkB_bits_meta_prefetchSrc = $urandom;
    io_sinkB_bits_meta_accessed = $urandom;
    io_sinkB_bits_meta_tagErr = $urandom;
    io_sinkB_bits_meta_dataErr = $urandom;
    io_sinkB_bits_metaWen = $urandom;
    io_sinkB_bits_tagWen = $urandom;
    io_sinkB_bits_dsWen = $urandom;
    io_sinkB_bits_wayMask = $urandom;
    io_sinkB_bits_replTask = $urandom;
    io_sinkB_bits_cmoTask = $urandom;
    io_sinkB_bits_cmoAll = $urandom;
    io_sinkB_bits_reqSource = $urandom;
    io_sinkB_bits_mergeA = $urandom;
    io_sinkB_bits_aMergeTask_off = $urandom;
    io_sinkB_bits_aMergeTask_alias = $urandom;
    io_sinkB_bits_aMergeTask_vaddr = {$urandom, $urandom};
    io_sinkB_bits_aMergeTask_isKeyword = $urandom;
    io_sinkB_bits_aMergeTask_opcode = $urandom;
    io_sinkB_bits_aMergeTask_param = $urandom;
    io_sinkB_bits_aMergeTask_sourceId = $urandom;
    io_sinkB_bits_aMergeTask_meta_dirty = $urandom;
    io_sinkB_bits_aMergeTask_meta_state = $urandom;
    io_sinkB_bits_aMergeTask_meta_clients = $urandom;
    io_sinkB_bits_aMergeTask_meta_alias = $urandom;
    io_sinkB_bits_aMergeTask_meta_prefetch = $urandom;
    io_sinkB_bits_aMergeTask_meta_prefetchSrc = $urandom;
    io_sinkB_bits_aMergeTask_meta_accessed = $urandom;
    io_sinkB_bits_aMergeTask_meta_tagErr = $urandom;
    io_sinkB_bits_aMergeTask_meta_dataErr = $urandom;
    io_sinkB_bits_snpHitRelease = $urandom;
    io_sinkB_bits_snpHitReleaseToInval = $urandom;
    io_sinkB_bits_snpHitReleaseToClean = $urandom;
    io_sinkB_bits_snpHitReleaseWithData = $urandom;
    io_sinkB_bits_snpHitReleaseIdx = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_dirty = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_state = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_clients = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_alias = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_prefetch = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_accessed = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_tagErr = $urandom;
    io_sinkB_bits_snpHitReleaseMeta_dataErr = $urandom;
    io_sinkB_bits_tgtID = $urandom;
    io_sinkB_bits_srcID = $urandom;
    io_sinkB_bits_txnID = $urandom;
    io_sinkB_bits_homeNID = $urandom;
    io_sinkB_bits_dbID = $urandom;
    io_sinkB_bits_fwdNID = $urandom;
    io_sinkB_bits_fwdTxnID = $urandom;
    io_sinkB_bits_chiOpcode = $urandom;
    io_sinkB_bits_resp = $urandom;
    io_sinkB_bits_fwdState = $urandom;
    io_sinkB_bits_pCrdType = $urandom;
    io_sinkB_bits_retToSrc = $urandom;
    io_sinkB_bits_likelyshared = $urandom;
    io_sinkB_bits_expCompAck = $urandom;
    io_sinkB_bits_allowRetry = $urandom;
    io_sinkB_bits_memAttr_allocate = $urandom;
    io_sinkB_bits_memAttr_cacheable = $urandom;
    io_sinkB_bits_memAttr_device = $urandom;
    io_sinkB_bits_memAttr_ewa = $urandom;
    io_sinkB_bits_traceTag = $urandom;
    io_sinkB_bits_dataCheckErr = $urandom;
    io_sinkC_valid = ($urandom_range(0,1) == 0);
    io_sinkC_bits_channel = $urandom;
    io_sinkC_bits_txChannel = $urandom;
    io_sinkC_bits_set = $urandom_range(0,7);
    io_sinkC_bits_tag = $urandom_range(0,7);
    io_sinkC_bits_off = $urandom;
    io_sinkC_bits_alias = $urandom;
    io_sinkC_bits_vaddr = {$urandom, $urandom};
    io_sinkC_bits_isKeyword = $urandom;
    io_sinkC_bits_opcode = $urandom_range(0,5);
    io_sinkC_bits_param = $urandom;
    io_sinkC_bits_size = $urandom;
    io_sinkC_bits_sourceId = $urandom;
    io_sinkC_bits_bufIdx = $urandom;
    io_sinkC_bits_needProbeAckData = $urandom;
    io_sinkC_bits_denied = $urandom;
    io_sinkC_bits_corrupt = $urandom;
    io_sinkC_bits_mshrTask = $urandom;
    io_sinkC_bits_mshrId = $urandom;
    io_sinkC_bits_aliasTask = $urandom;
    io_sinkC_bits_useProbeData = $urandom;
    io_sinkC_bits_mshrRetry = $urandom;
    io_sinkC_bits_readProbeDataDown = $urandom;
    io_sinkC_bits_fromL2pft = $urandom;
    io_sinkC_bits_needHint = $urandom;
    io_sinkC_bits_dirty = $urandom;
    io_sinkC_bits_way = $urandom_range(0,7);
    io_sinkC_bits_meta_dirty = $urandom;
    io_sinkC_bits_meta_state = $urandom;
    io_sinkC_bits_meta_clients = $urandom;
    io_sinkC_bits_meta_alias = $urandom;
    io_sinkC_bits_meta_prefetch = $urandom;
    io_sinkC_bits_meta_prefetchSrc = $urandom;
    io_sinkC_bits_meta_accessed = $urandom;
    io_sinkC_bits_meta_tagErr = $urandom;
    io_sinkC_bits_meta_dataErr = $urandom;
    io_sinkC_bits_metaWen = $urandom;
    io_sinkC_bits_tagWen = $urandom;
    io_sinkC_bits_dsWen = $urandom;
    io_sinkC_bits_wayMask = $urandom;
    io_sinkC_bits_replTask = $urandom;
    io_sinkC_bits_cmoTask = $urandom;
    io_sinkC_bits_cmoAll = $urandom;
    io_sinkC_bits_reqSource = $urandom;
    io_sinkC_bits_mergeA = $urandom;
    io_sinkC_bits_aMergeTask_off = $urandom;
    io_sinkC_bits_aMergeTask_alias = $urandom;
    io_sinkC_bits_aMergeTask_vaddr = {$urandom, $urandom};
    io_sinkC_bits_aMergeTask_isKeyword = $urandom;
    io_sinkC_bits_aMergeTask_opcode = $urandom;
    io_sinkC_bits_aMergeTask_param = $urandom;
    io_sinkC_bits_aMergeTask_sourceId = $urandom;
    io_sinkC_bits_aMergeTask_meta_dirty = $urandom;
    io_sinkC_bits_aMergeTask_meta_state = $urandom;
    io_sinkC_bits_aMergeTask_meta_clients = $urandom;
    io_sinkC_bits_aMergeTask_meta_alias = $urandom;
    io_sinkC_bits_aMergeTask_meta_prefetch = $urandom;
    io_sinkC_bits_aMergeTask_meta_prefetchSrc = $urandom;
    io_sinkC_bits_aMergeTask_meta_accessed = $urandom;
    io_sinkC_bits_aMergeTask_meta_tagErr = $urandom;
    io_sinkC_bits_aMergeTask_meta_dataErr = $urandom;
    io_sinkC_bits_snpHitRelease = $urandom;
    io_sinkC_bits_snpHitReleaseToInval = $urandom;
    io_sinkC_bits_snpHitReleaseToClean = $urandom;
    io_sinkC_bits_snpHitReleaseWithData = $urandom;
    io_sinkC_bits_snpHitReleaseIdx = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_dirty = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_state = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_clients = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_alias = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_prefetch = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_accessed = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_tagErr = $urandom;
    io_sinkC_bits_snpHitReleaseMeta_dataErr = $urandom;
    io_sinkC_bits_tgtID = $urandom;
    io_sinkC_bits_srcID = $urandom;
    io_sinkC_bits_txnID = $urandom;
    io_sinkC_bits_homeNID = $urandom;
    io_sinkC_bits_dbID = $urandom;
    io_sinkC_bits_fwdNID = $urandom;
    io_sinkC_bits_fwdTxnID = $urandom;
    io_sinkC_bits_chiOpcode = $urandom;
    io_sinkC_bits_resp = $urandom;
    io_sinkC_bits_fwdState = $urandom;
    io_sinkC_bits_pCrdType = $urandom;
    io_sinkC_bits_retToSrc = $urandom;
    io_sinkC_bits_likelyshared = $urandom;
    io_sinkC_bits_expCompAck = $urandom;
    io_sinkC_bits_allowRetry = $urandom;
    io_sinkC_bits_memAttr_allocate = $urandom;
    io_sinkC_bits_memAttr_cacheable = $urandom;
    io_sinkC_bits_memAttr_device = $urandom;
    io_sinkC_bits_memAttr_ewa = $urandom;
    io_sinkC_bits_traceTag = $urandom;
    io_sinkC_bits_dataCheckErr = $urandom;
    io_mshrTask_valid = ($urandom_range(0,1) == 0);
    io_mshrTask_bits_channel = $urandom;
    io_mshrTask_bits_txChannel = $urandom;
    io_mshrTask_bits_set = $urandom_range(0,7);
    io_mshrTask_bits_tag = $urandom_range(0,7);
    io_mshrTask_bits_off = $urandom;
    io_mshrTask_bits_alias = $urandom;
    io_mshrTask_bits_vaddr = {$urandom, $urandom};
    io_mshrTask_bits_isKeyword = $urandom;
    io_mshrTask_bits_opcode = $urandom_range(0,5);
    io_mshrTask_bits_param = $urandom;
    io_mshrTask_bits_size = $urandom;
    io_mshrTask_bits_sourceId = $urandom;
    io_mshrTask_bits_bufIdx = $urandom;
    io_mshrTask_bits_needProbeAckData = $urandom;
    io_mshrTask_bits_denied = $urandom;
    io_mshrTask_bits_corrupt = $urandom;
    io_mshrTask_bits_mshrTask = $urandom;
    io_mshrTask_bits_mshrId = $urandom;
    io_mshrTask_bits_aliasTask = $urandom;
    io_mshrTask_bits_useProbeData = $urandom;
    io_mshrTask_bits_mshrRetry = $urandom;
    io_mshrTask_bits_readProbeDataDown = $urandom;
    io_mshrTask_bits_fromL2pft = $urandom;
    io_mshrTask_bits_needHint = $urandom;
    io_mshrTask_bits_dirty = $urandom;
    io_mshrTask_bits_way = $urandom_range(0,7);
    io_mshrTask_bits_meta_dirty = $urandom;
    io_mshrTask_bits_meta_state = $urandom;
    io_mshrTask_bits_meta_clients = $urandom;
    io_mshrTask_bits_meta_alias = $urandom;
    io_mshrTask_bits_meta_prefetch = $urandom;
    io_mshrTask_bits_meta_prefetchSrc = $urandom;
    io_mshrTask_bits_meta_accessed = $urandom;
    io_mshrTask_bits_meta_tagErr = $urandom;
    io_mshrTask_bits_meta_dataErr = $urandom;
    io_mshrTask_bits_metaWen = $urandom;
    io_mshrTask_bits_tagWen = $urandom;
    io_mshrTask_bits_dsWen = $urandom;
    io_mshrTask_bits_wayMask = $urandom;
    io_mshrTask_bits_replTask = $urandom;
    io_mshrTask_bits_cmoTask = $urandom;
    io_mshrTask_bits_cmoAll = $urandom;
    io_mshrTask_bits_reqSource = $urandom;
    io_mshrTask_bits_mergeA = $urandom;
    io_mshrTask_bits_aMergeTask_off = $urandom;
    io_mshrTask_bits_aMergeTask_alias = $urandom;
    io_mshrTask_bits_aMergeTask_vaddr = {$urandom, $urandom};
    io_mshrTask_bits_aMergeTask_isKeyword = $urandom;
    io_mshrTask_bits_aMergeTask_opcode = $urandom;
    io_mshrTask_bits_aMergeTask_param = $urandom;
    io_mshrTask_bits_aMergeTask_sourceId = $urandom;
    io_mshrTask_bits_aMergeTask_meta_dirty = $urandom;
    io_mshrTask_bits_aMergeTask_meta_state = $urandom;
    io_mshrTask_bits_aMergeTask_meta_clients = $urandom;
    io_mshrTask_bits_aMergeTask_meta_alias = $urandom;
    io_mshrTask_bits_aMergeTask_meta_prefetch = $urandom;
    io_mshrTask_bits_aMergeTask_meta_prefetchSrc = $urandom;
    io_mshrTask_bits_aMergeTask_meta_accessed = $urandom;
    io_mshrTask_bits_aMergeTask_meta_tagErr = $urandom;
    io_mshrTask_bits_aMergeTask_meta_dataErr = $urandom;
    io_mshrTask_bits_snpHitRelease = $urandom;
    io_mshrTask_bits_snpHitReleaseToInval = $urandom;
    io_mshrTask_bits_snpHitReleaseToClean = $urandom;
    io_mshrTask_bits_snpHitReleaseWithData = $urandom;
    io_mshrTask_bits_snpHitReleaseIdx = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_dirty = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_state = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_clients = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_alias = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_prefetch = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_accessed = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_tagErr = $urandom;
    io_mshrTask_bits_snpHitReleaseMeta_dataErr = $urandom;
    io_mshrTask_bits_tgtID = $urandom;
    io_mshrTask_bits_srcID = $urandom;
    io_mshrTask_bits_txnID = $urandom;
    io_mshrTask_bits_homeNID = $urandom;
    io_mshrTask_bits_dbID = $urandom;
    io_mshrTask_bits_fwdNID = $urandom;
    io_mshrTask_bits_fwdTxnID = $urandom;
    io_mshrTask_bits_chiOpcode = $urandom;
    io_mshrTask_bits_resp = $urandom;
    io_mshrTask_bits_fwdState = $urandom;
    io_mshrTask_bits_pCrdType = $urandom;
    io_mshrTask_bits_retToSrc = $urandom;
    io_mshrTask_bits_likelyshared = $urandom;
    io_mshrTask_bits_expCompAck = $urandom;
    io_mshrTask_bits_allowRetry = $urandom;
    io_mshrTask_bits_memAttr_allocate = $urandom;
    io_mshrTask_bits_memAttr_cacheable = $urandom;
    io_mshrTask_bits_memAttr_device = $urandom;
    io_mshrTask_bits_memAttr_ewa = $urandom;
    io_mshrTask_bits_traceTag = $urandom;
    io_mshrTask_bits_dataCheckErr = $urandom;
    io_dirRead_s1_ready = ($urandom_range(0,2) != 0);
    io_fromMSHRCtl_blockG_s1 = ($urandom_range(0,3) == 0);
    io_fromMSHRCtl_blockA_s1 = ($urandom_range(0,3) == 0);
    io_fromMSHRCtl_blockB_s1 = ($urandom_range(0,3) == 0);
    io_fromMSHRCtl_blockC_s1 = ($urandom_range(0,3) == 0);
    io_fromMainPipe_blockG_s1 = ($urandom_range(0,3) == 0);
    io_fromMainPipe_blockA_s1 = ($urandom_range(0,3) == 0);
    io_fromMainPipe_blockB_s1 = ($urandom_range(0,3) == 0);
    io_fromMainPipe_blockC_s1 = ($urandom_range(0,3) == 0);
    io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1 = ($urandom_range(0,3) == 0);
    io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1 = ($urandom_range(0,3) == 0);
    io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 = ($urandom_range(0,3) == 0);
    io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1 = ($urandom_range(0,3) == 0);
    io_fromGrantBuffer_blockMSHRReqEntrance = ($urandom_range(0,3) == 0);
    io_fromTXDAT_blockMSHRReqEntrance = ($urandom_range(0,3) == 0);
    io_fromTXDAT_blockSinkBReqEntrance = ($urandom_range(0,3) == 0);
    io_fromTXRSP_blockMSHRReqEntrance = ($urandom_range(0,3) == 0);
    io_fromTXRSP_blockSinkBReqEntrance = ($urandom_range(0,3) == 0);
    io_fromTXREQ_blockMSHRReqEntrance = ($urandom_range(0,3) == 0);
    io_msInfo_0_valid = ($urandom_range(0,1) == 0);
    io_msInfo_0_bits_channel = $urandom;
    io_msInfo_0_bits_set = $urandom_range(0,7);
    io_msInfo_0_bits_way = $urandom_range(0,7);
    io_msInfo_0_bits_reqTag = $urandom;
    io_msInfo_0_bits_willFree = $urandom;
    io_msInfo_0_bits_aliasTask = $urandom;
    io_msInfo_0_bits_needRelease = $urandom;
    io_msInfo_0_bits_blockRefill = $urandom;
    io_msInfo_0_bits_meta_dirty = $urandom;
    io_msInfo_0_bits_meta_state = $urandom;
    io_msInfo_0_bits_meta_clients = $urandom;
    io_msInfo_0_bits_meta_alias = $urandom;
    io_msInfo_0_bits_meta_prefetch = $urandom;
    io_msInfo_0_bits_meta_prefetchSrc = $urandom;
    io_msInfo_0_bits_meta_accessed = $urandom;
    io_msInfo_0_bits_meta_tagErr = $urandom;
    io_msInfo_0_bits_meta_dataErr = $urandom;
    io_msInfo_0_bits_metaTag = $urandom;
    io_msInfo_0_bits_dirHit = $urandom;
    io_msInfo_0_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_0_bits_isPrefetch = $urandom;
    io_msInfo_0_bits_param = $urandom;
    io_msInfo_0_bits_mergeA = $urandom;
    io_msInfo_0_bits_w_grantfirst = $urandom;
    io_msInfo_0_bits_s_release = $urandom;
    io_msInfo_0_bits_s_refill = $urandom;
    io_msInfo_0_bits_s_cmoresp = $urandom;
    io_msInfo_0_bits_s_cmometaw = $urandom;
    io_msInfo_0_bits_w_releaseack = $urandom;
    io_msInfo_0_bits_w_replResp = $urandom;
    io_msInfo_0_bits_w_rprobeacklast = $urandom;
    io_msInfo_0_bits_replaceData = $urandom;
    io_msInfo_0_bits_releaseToClean = $urandom;
    io_msInfo_1_valid = ($urandom_range(0,1) == 0);
    io_msInfo_1_bits_channel = $urandom;
    io_msInfo_1_bits_set = $urandom_range(0,7);
    io_msInfo_1_bits_way = $urandom_range(0,7);
    io_msInfo_1_bits_reqTag = $urandom;
    io_msInfo_1_bits_willFree = $urandom;
    io_msInfo_1_bits_aliasTask = $urandom;
    io_msInfo_1_bits_needRelease = $urandom;
    io_msInfo_1_bits_blockRefill = $urandom;
    io_msInfo_1_bits_meta_dirty = $urandom;
    io_msInfo_1_bits_meta_state = $urandom;
    io_msInfo_1_bits_meta_clients = $urandom;
    io_msInfo_1_bits_meta_alias = $urandom;
    io_msInfo_1_bits_meta_prefetch = $urandom;
    io_msInfo_1_bits_meta_prefetchSrc = $urandom;
    io_msInfo_1_bits_meta_accessed = $urandom;
    io_msInfo_1_bits_meta_tagErr = $urandom;
    io_msInfo_1_bits_meta_dataErr = $urandom;
    io_msInfo_1_bits_metaTag = $urandom;
    io_msInfo_1_bits_dirHit = $urandom;
    io_msInfo_1_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_1_bits_isPrefetch = $urandom;
    io_msInfo_1_bits_param = $urandom;
    io_msInfo_1_bits_mergeA = $urandom;
    io_msInfo_1_bits_w_grantfirst = $urandom;
    io_msInfo_1_bits_s_release = $urandom;
    io_msInfo_1_bits_s_refill = $urandom;
    io_msInfo_1_bits_s_cmoresp = $urandom;
    io_msInfo_1_bits_s_cmometaw = $urandom;
    io_msInfo_1_bits_w_releaseack = $urandom;
    io_msInfo_1_bits_w_replResp = $urandom;
    io_msInfo_1_bits_w_rprobeacklast = $urandom;
    io_msInfo_1_bits_replaceData = $urandom;
    io_msInfo_1_bits_releaseToClean = $urandom;
    io_msInfo_2_valid = ($urandom_range(0,1) == 0);
    io_msInfo_2_bits_channel = $urandom;
    io_msInfo_2_bits_set = $urandom_range(0,7);
    io_msInfo_2_bits_way = $urandom_range(0,7);
    io_msInfo_2_bits_reqTag = $urandom;
    io_msInfo_2_bits_willFree = $urandom;
    io_msInfo_2_bits_aliasTask = $urandom;
    io_msInfo_2_bits_needRelease = $urandom;
    io_msInfo_2_bits_blockRefill = $urandom;
    io_msInfo_2_bits_meta_dirty = $urandom;
    io_msInfo_2_bits_meta_state = $urandom;
    io_msInfo_2_bits_meta_clients = $urandom;
    io_msInfo_2_bits_meta_alias = $urandom;
    io_msInfo_2_bits_meta_prefetch = $urandom;
    io_msInfo_2_bits_meta_prefetchSrc = $urandom;
    io_msInfo_2_bits_meta_accessed = $urandom;
    io_msInfo_2_bits_meta_tagErr = $urandom;
    io_msInfo_2_bits_meta_dataErr = $urandom;
    io_msInfo_2_bits_metaTag = $urandom;
    io_msInfo_2_bits_dirHit = $urandom;
    io_msInfo_2_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_2_bits_isPrefetch = $urandom;
    io_msInfo_2_bits_param = $urandom;
    io_msInfo_2_bits_mergeA = $urandom;
    io_msInfo_2_bits_w_grantfirst = $urandom;
    io_msInfo_2_bits_s_release = $urandom;
    io_msInfo_2_bits_s_refill = $urandom;
    io_msInfo_2_bits_s_cmoresp = $urandom;
    io_msInfo_2_bits_s_cmometaw = $urandom;
    io_msInfo_2_bits_w_releaseack = $urandom;
    io_msInfo_2_bits_w_replResp = $urandom;
    io_msInfo_2_bits_w_rprobeacklast = $urandom;
    io_msInfo_2_bits_replaceData = $urandom;
    io_msInfo_2_bits_releaseToClean = $urandom;
    io_msInfo_3_valid = ($urandom_range(0,1) == 0);
    io_msInfo_3_bits_channel = $urandom;
    io_msInfo_3_bits_set = $urandom_range(0,7);
    io_msInfo_3_bits_way = $urandom_range(0,7);
    io_msInfo_3_bits_reqTag = $urandom;
    io_msInfo_3_bits_willFree = $urandom;
    io_msInfo_3_bits_aliasTask = $urandom;
    io_msInfo_3_bits_needRelease = $urandom;
    io_msInfo_3_bits_blockRefill = $urandom;
    io_msInfo_3_bits_meta_dirty = $urandom;
    io_msInfo_3_bits_meta_state = $urandom;
    io_msInfo_3_bits_meta_clients = $urandom;
    io_msInfo_3_bits_meta_alias = $urandom;
    io_msInfo_3_bits_meta_prefetch = $urandom;
    io_msInfo_3_bits_meta_prefetchSrc = $urandom;
    io_msInfo_3_bits_meta_accessed = $urandom;
    io_msInfo_3_bits_meta_tagErr = $urandom;
    io_msInfo_3_bits_meta_dataErr = $urandom;
    io_msInfo_3_bits_metaTag = $urandom;
    io_msInfo_3_bits_dirHit = $urandom;
    io_msInfo_3_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_3_bits_isPrefetch = $urandom;
    io_msInfo_3_bits_param = $urandom;
    io_msInfo_3_bits_mergeA = $urandom;
    io_msInfo_3_bits_w_grantfirst = $urandom;
    io_msInfo_3_bits_s_release = $urandom;
    io_msInfo_3_bits_s_refill = $urandom;
    io_msInfo_3_bits_s_cmoresp = $urandom;
    io_msInfo_3_bits_s_cmometaw = $urandom;
    io_msInfo_3_bits_w_releaseack = $urandom;
    io_msInfo_3_bits_w_replResp = $urandom;
    io_msInfo_3_bits_w_rprobeacklast = $urandom;
    io_msInfo_3_bits_replaceData = $urandom;
    io_msInfo_3_bits_releaseToClean = $urandom;
    io_msInfo_4_valid = ($urandom_range(0,1) == 0);
    io_msInfo_4_bits_channel = $urandom;
    io_msInfo_4_bits_set = $urandom_range(0,7);
    io_msInfo_4_bits_way = $urandom_range(0,7);
    io_msInfo_4_bits_reqTag = $urandom;
    io_msInfo_4_bits_willFree = $urandom;
    io_msInfo_4_bits_aliasTask = $urandom;
    io_msInfo_4_bits_needRelease = $urandom;
    io_msInfo_4_bits_blockRefill = $urandom;
    io_msInfo_4_bits_meta_dirty = $urandom;
    io_msInfo_4_bits_meta_state = $urandom;
    io_msInfo_4_bits_meta_clients = $urandom;
    io_msInfo_4_bits_meta_alias = $urandom;
    io_msInfo_4_bits_meta_prefetch = $urandom;
    io_msInfo_4_bits_meta_prefetchSrc = $urandom;
    io_msInfo_4_bits_meta_accessed = $urandom;
    io_msInfo_4_bits_meta_tagErr = $urandom;
    io_msInfo_4_bits_meta_dataErr = $urandom;
    io_msInfo_4_bits_metaTag = $urandom;
    io_msInfo_4_bits_dirHit = $urandom;
    io_msInfo_4_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_4_bits_isPrefetch = $urandom;
    io_msInfo_4_bits_param = $urandom;
    io_msInfo_4_bits_mergeA = $urandom;
    io_msInfo_4_bits_w_grantfirst = $urandom;
    io_msInfo_4_bits_s_release = $urandom;
    io_msInfo_4_bits_s_refill = $urandom;
    io_msInfo_4_bits_s_cmoresp = $urandom;
    io_msInfo_4_bits_s_cmometaw = $urandom;
    io_msInfo_4_bits_w_releaseack = $urandom;
    io_msInfo_4_bits_w_replResp = $urandom;
    io_msInfo_4_bits_w_rprobeacklast = $urandom;
    io_msInfo_4_bits_replaceData = $urandom;
    io_msInfo_4_bits_releaseToClean = $urandom;
    io_msInfo_5_valid = ($urandom_range(0,1) == 0);
    io_msInfo_5_bits_channel = $urandom;
    io_msInfo_5_bits_set = $urandom_range(0,7);
    io_msInfo_5_bits_way = $urandom_range(0,7);
    io_msInfo_5_bits_reqTag = $urandom;
    io_msInfo_5_bits_willFree = $urandom;
    io_msInfo_5_bits_aliasTask = $urandom;
    io_msInfo_5_bits_needRelease = $urandom;
    io_msInfo_5_bits_blockRefill = $urandom;
    io_msInfo_5_bits_meta_dirty = $urandom;
    io_msInfo_5_bits_meta_state = $urandom;
    io_msInfo_5_bits_meta_clients = $urandom;
    io_msInfo_5_bits_meta_alias = $urandom;
    io_msInfo_5_bits_meta_prefetch = $urandom;
    io_msInfo_5_bits_meta_prefetchSrc = $urandom;
    io_msInfo_5_bits_meta_accessed = $urandom;
    io_msInfo_5_bits_meta_tagErr = $urandom;
    io_msInfo_5_bits_meta_dataErr = $urandom;
    io_msInfo_5_bits_metaTag = $urandom;
    io_msInfo_5_bits_dirHit = $urandom;
    io_msInfo_5_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_5_bits_isPrefetch = $urandom;
    io_msInfo_5_bits_param = $urandom;
    io_msInfo_5_bits_mergeA = $urandom;
    io_msInfo_5_bits_w_grantfirst = $urandom;
    io_msInfo_5_bits_s_release = $urandom;
    io_msInfo_5_bits_s_refill = $urandom;
    io_msInfo_5_bits_s_cmoresp = $urandom;
    io_msInfo_5_bits_s_cmometaw = $urandom;
    io_msInfo_5_bits_w_releaseack = $urandom;
    io_msInfo_5_bits_w_replResp = $urandom;
    io_msInfo_5_bits_w_rprobeacklast = $urandom;
    io_msInfo_5_bits_replaceData = $urandom;
    io_msInfo_5_bits_releaseToClean = $urandom;
    io_msInfo_6_valid = ($urandom_range(0,1) == 0);
    io_msInfo_6_bits_channel = $urandom;
    io_msInfo_6_bits_set = $urandom_range(0,7);
    io_msInfo_6_bits_way = $urandom_range(0,7);
    io_msInfo_6_bits_reqTag = $urandom;
    io_msInfo_6_bits_willFree = $urandom;
    io_msInfo_6_bits_aliasTask = $urandom;
    io_msInfo_6_bits_needRelease = $urandom;
    io_msInfo_6_bits_blockRefill = $urandom;
    io_msInfo_6_bits_meta_dirty = $urandom;
    io_msInfo_6_bits_meta_state = $urandom;
    io_msInfo_6_bits_meta_clients = $urandom;
    io_msInfo_6_bits_meta_alias = $urandom;
    io_msInfo_6_bits_meta_prefetch = $urandom;
    io_msInfo_6_bits_meta_prefetchSrc = $urandom;
    io_msInfo_6_bits_meta_accessed = $urandom;
    io_msInfo_6_bits_meta_tagErr = $urandom;
    io_msInfo_6_bits_meta_dataErr = $urandom;
    io_msInfo_6_bits_metaTag = $urandom;
    io_msInfo_6_bits_dirHit = $urandom;
    io_msInfo_6_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_6_bits_isPrefetch = $urandom;
    io_msInfo_6_bits_param = $urandom;
    io_msInfo_6_bits_mergeA = $urandom;
    io_msInfo_6_bits_w_grantfirst = $urandom;
    io_msInfo_6_bits_s_release = $urandom;
    io_msInfo_6_bits_s_refill = $urandom;
    io_msInfo_6_bits_s_cmoresp = $urandom;
    io_msInfo_6_bits_s_cmometaw = $urandom;
    io_msInfo_6_bits_w_releaseack = $urandom;
    io_msInfo_6_bits_w_replResp = $urandom;
    io_msInfo_6_bits_w_rprobeacklast = $urandom;
    io_msInfo_6_bits_replaceData = $urandom;
    io_msInfo_6_bits_releaseToClean = $urandom;
    io_msInfo_7_valid = ($urandom_range(0,1) == 0);
    io_msInfo_7_bits_channel = $urandom;
    io_msInfo_7_bits_set = $urandom_range(0,7);
    io_msInfo_7_bits_way = $urandom_range(0,7);
    io_msInfo_7_bits_reqTag = $urandom;
    io_msInfo_7_bits_willFree = $urandom;
    io_msInfo_7_bits_aliasTask = $urandom;
    io_msInfo_7_bits_needRelease = $urandom;
    io_msInfo_7_bits_blockRefill = $urandom;
    io_msInfo_7_bits_meta_dirty = $urandom;
    io_msInfo_7_bits_meta_state = $urandom;
    io_msInfo_7_bits_meta_clients = $urandom;
    io_msInfo_7_bits_meta_alias = $urandom;
    io_msInfo_7_bits_meta_prefetch = $urandom;
    io_msInfo_7_bits_meta_prefetchSrc = $urandom;
    io_msInfo_7_bits_meta_accessed = $urandom;
    io_msInfo_7_bits_meta_tagErr = $urandom;
    io_msInfo_7_bits_meta_dataErr = $urandom;
    io_msInfo_7_bits_metaTag = $urandom;
    io_msInfo_7_bits_dirHit = $urandom;
    io_msInfo_7_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_7_bits_isPrefetch = $urandom;
    io_msInfo_7_bits_param = $urandom;
    io_msInfo_7_bits_mergeA = $urandom;
    io_msInfo_7_bits_w_grantfirst = $urandom;
    io_msInfo_7_bits_s_release = $urandom;
    io_msInfo_7_bits_s_refill = $urandom;
    io_msInfo_7_bits_s_cmoresp = $urandom;
    io_msInfo_7_bits_s_cmometaw = $urandom;
    io_msInfo_7_bits_w_releaseack = $urandom;
    io_msInfo_7_bits_w_replResp = $urandom;
    io_msInfo_7_bits_w_rprobeacklast = $urandom;
    io_msInfo_7_bits_replaceData = $urandom;
    io_msInfo_7_bits_releaseToClean = $urandom;
    io_msInfo_8_valid = ($urandom_range(0,1) == 0);
    io_msInfo_8_bits_channel = $urandom;
    io_msInfo_8_bits_set = $urandom_range(0,7);
    io_msInfo_8_bits_way = $urandom_range(0,7);
    io_msInfo_8_bits_reqTag = $urandom;
    io_msInfo_8_bits_willFree = $urandom;
    io_msInfo_8_bits_aliasTask = $urandom;
    io_msInfo_8_bits_needRelease = $urandom;
    io_msInfo_8_bits_blockRefill = $urandom;
    io_msInfo_8_bits_meta_dirty = $urandom;
    io_msInfo_8_bits_meta_state = $urandom;
    io_msInfo_8_bits_meta_clients = $urandom;
    io_msInfo_8_bits_meta_alias = $urandom;
    io_msInfo_8_bits_meta_prefetch = $urandom;
    io_msInfo_8_bits_meta_prefetchSrc = $urandom;
    io_msInfo_8_bits_meta_accessed = $urandom;
    io_msInfo_8_bits_meta_tagErr = $urandom;
    io_msInfo_8_bits_meta_dataErr = $urandom;
    io_msInfo_8_bits_metaTag = $urandom;
    io_msInfo_8_bits_dirHit = $urandom;
    io_msInfo_8_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_8_bits_isPrefetch = $urandom;
    io_msInfo_8_bits_param = $urandom;
    io_msInfo_8_bits_mergeA = $urandom;
    io_msInfo_8_bits_w_grantfirst = $urandom;
    io_msInfo_8_bits_s_release = $urandom;
    io_msInfo_8_bits_s_refill = $urandom;
    io_msInfo_8_bits_s_cmoresp = $urandom;
    io_msInfo_8_bits_s_cmometaw = $urandom;
    io_msInfo_8_bits_w_releaseack = $urandom;
    io_msInfo_8_bits_w_replResp = $urandom;
    io_msInfo_8_bits_w_rprobeacklast = $urandom;
    io_msInfo_8_bits_replaceData = $urandom;
    io_msInfo_8_bits_releaseToClean = $urandom;
    io_msInfo_9_valid = ($urandom_range(0,1) == 0);
    io_msInfo_9_bits_channel = $urandom;
    io_msInfo_9_bits_set = $urandom_range(0,7);
    io_msInfo_9_bits_way = $urandom_range(0,7);
    io_msInfo_9_bits_reqTag = $urandom;
    io_msInfo_9_bits_willFree = $urandom;
    io_msInfo_9_bits_aliasTask = $urandom;
    io_msInfo_9_bits_needRelease = $urandom;
    io_msInfo_9_bits_blockRefill = $urandom;
    io_msInfo_9_bits_meta_dirty = $urandom;
    io_msInfo_9_bits_meta_state = $urandom;
    io_msInfo_9_bits_meta_clients = $urandom;
    io_msInfo_9_bits_meta_alias = $urandom;
    io_msInfo_9_bits_meta_prefetch = $urandom;
    io_msInfo_9_bits_meta_prefetchSrc = $urandom;
    io_msInfo_9_bits_meta_accessed = $urandom;
    io_msInfo_9_bits_meta_tagErr = $urandom;
    io_msInfo_9_bits_meta_dataErr = $urandom;
    io_msInfo_9_bits_metaTag = $urandom;
    io_msInfo_9_bits_dirHit = $urandom;
    io_msInfo_9_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_9_bits_isPrefetch = $urandom;
    io_msInfo_9_bits_param = $urandom;
    io_msInfo_9_bits_mergeA = $urandom;
    io_msInfo_9_bits_w_grantfirst = $urandom;
    io_msInfo_9_bits_s_release = $urandom;
    io_msInfo_9_bits_s_refill = $urandom;
    io_msInfo_9_bits_s_cmoresp = $urandom;
    io_msInfo_9_bits_s_cmometaw = $urandom;
    io_msInfo_9_bits_w_releaseack = $urandom;
    io_msInfo_9_bits_w_replResp = $urandom;
    io_msInfo_9_bits_w_rprobeacklast = $urandom;
    io_msInfo_9_bits_replaceData = $urandom;
    io_msInfo_9_bits_releaseToClean = $urandom;
    io_msInfo_10_valid = ($urandom_range(0,1) == 0);
    io_msInfo_10_bits_channel = $urandom;
    io_msInfo_10_bits_set = $urandom_range(0,7);
    io_msInfo_10_bits_way = $urandom_range(0,7);
    io_msInfo_10_bits_reqTag = $urandom;
    io_msInfo_10_bits_willFree = $urandom;
    io_msInfo_10_bits_aliasTask = $urandom;
    io_msInfo_10_bits_needRelease = $urandom;
    io_msInfo_10_bits_blockRefill = $urandom;
    io_msInfo_10_bits_meta_dirty = $urandom;
    io_msInfo_10_bits_meta_state = $urandom;
    io_msInfo_10_bits_meta_clients = $urandom;
    io_msInfo_10_bits_meta_alias = $urandom;
    io_msInfo_10_bits_meta_prefetch = $urandom;
    io_msInfo_10_bits_meta_prefetchSrc = $urandom;
    io_msInfo_10_bits_meta_accessed = $urandom;
    io_msInfo_10_bits_meta_tagErr = $urandom;
    io_msInfo_10_bits_meta_dataErr = $urandom;
    io_msInfo_10_bits_metaTag = $urandom;
    io_msInfo_10_bits_dirHit = $urandom;
    io_msInfo_10_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_10_bits_isPrefetch = $urandom;
    io_msInfo_10_bits_param = $urandom;
    io_msInfo_10_bits_mergeA = $urandom;
    io_msInfo_10_bits_w_grantfirst = $urandom;
    io_msInfo_10_bits_s_release = $urandom;
    io_msInfo_10_bits_s_refill = $urandom;
    io_msInfo_10_bits_s_cmoresp = $urandom;
    io_msInfo_10_bits_s_cmometaw = $urandom;
    io_msInfo_10_bits_w_releaseack = $urandom;
    io_msInfo_10_bits_w_replResp = $urandom;
    io_msInfo_10_bits_w_rprobeacklast = $urandom;
    io_msInfo_10_bits_replaceData = $urandom;
    io_msInfo_10_bits_releaseToClean = $urandom;
    io_msInfo_11_valid = ($urandom_range(0,1) == 0);
    io_msInfo_11_bits_channel = $urandom;
    io_msInfo_11_bits_set = $urandom_range(0,7);
    io_msInfo_11_bits_way = $urandom_range(0,7);
    io_msInfo_11_bits_reqTag = $urandom;
    io_msInfo_11_bits_willFree = $urandom;
    io_msInfo_11_bits_aliasTask = $urandom;
    io_msInfo_11_bits_needRelease = $urandom;
    io_msInfo_11_bits_blockRefill = $urandom;
    io_msInfo_11_bits_meta_dirty = $urandom;
    io_msInfo_11_bits_meta_state = $urandom;
    io_msInfo_11_bits_meta_clients = $urandom;
    io_msInfo_11_bits_meta_alias = $urandom;
    io_msInfo_11_bits_meta_prefetch = $urandom;
    io_msInfo_11_bits_meta_prefetchSrc = $urandom;
    io_msInfo_11_bits_meta_accessed = $urandom;
    io_msInfo_11_bits_meta_tagErr = $urandom;
    io_msInfo_11_bits_meta_dataErr = $urandom;
    io_msInfo_11_bits_metaTag = $urandom;
    io_msInfo_11_bits_dirHit = $urandom;
    io_msInfo_11_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_11_bits_isPrefetch = $urandom;
    io_msInfo_11_bits_param = $urandom;
    io_msInfo_11_bits_mergeA = $urandom;
    io_msInfo_11_bits_w_grantfirst = $urandom;
    io_msInfo_11_bits_s_release = $urandom;
    io_msInfo_11_bits_s_refill = $urandom;
    io_msInfo_11_bits_s_cmoresp = $urandom;
    io_msInfo_11_bits_s_cmometaw = $urandom;
    io_msInfo_11_bits_w_releaseack = $urandom;
    io_msInfo_11_bits_w_replResp = $urandom;
    io_msInfo_11_bits_w_rprobeacklast = $urandom;
    io_msInfo_11_bits_replaceData = $urandom;
    io_msInfo_11_bits_releaseToClean = $urandom;
    io_msInfo_12_valid = ($urandom_range(0,1) == 0);
    io_msInfo_12_bits_channel = $urandom;
    io_msInfo_12_bits_set = $urandom_range(0,7);
    io_msInfo_12_bits_way = $urandom_range(0,7);
    io_msInfo_12_bits_reqTag = $urandom;
    io_msInfo_12_bits_willFree = $urandom;
    io_msInfo_12_bits_aliasTask = $urandom;
    io_msInfo_12_bits_needRelease = $urandom;
    io_msInfo_12_bits_blockRefill = $urandom;
    io_msInfo_12_bits_meta_dirty = $urandom;
    io_msInfo_12_bits_meta_state = $urandom;
    io_msInfo_12_bits_meta_clients = $urandom;
    io_msInfo_12_bits_meta_alias = $urandom;
    io_msInfo_12_bits_meta_prefetch = $urandom;
    io_msInfo_12_bits_meta_prefetchSrc = $urandom;
    io_msInfo_12_bits_meta_accessed = $urandom;
    io_msInfo_12_bits_meta_tagErr = $urandom;
    io_msInfo_12_bits_meta_dataErr = $urandom;
    io_msInfo_12_bits_metaTag = $urandom;
    io_msInfo_12_bits_dirHit = $urandom;
    io_msInfo_12_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_12_bits_isPrefetch = $urandom;
    io_msInfo_12_bits_param = $urandom;
    io_msInfo_12_bits_mergeA = $urandom;
    io_msInfo_12_bits_w_grantfirst = $urandom;
    io_msInfo_12_bits_s_release = $urandom;
    io_msInfo_12_bits_s_refill = $urandom;
    io_msInfo_12_bits_s_cmoresp = $urandom;
    io_msInfo_12_bits_s_cmometaw = $urandom;
    io_msInfo_12_bits_w_releaseack = $urandom;
    io_msInfo_12_bits_w_replResp = $urandom;
    io_msInfo_12_bits_w_rprobeacklast = $urandom;
    io_msInfo_12_bits_replaceData = $urandom;
    io_msInfo_12_bits_releaseToClean = $urandom;
    io_msInfo_13_valid = ($urandom_range(0,1) == 0);
    io_msInfo_13_bits_channel = $urandom;
    io_msInfo_13_bits_set = $urandom_range(0,7);
    io_msInfo_13_bits_way = $urandom_range(0,7);
    io_msInfo_13_bits_reqTag = $urandom;
    io_msInfo_13_bits_willFree = $urandom;
    io_msInfo_13_bits_aliasTask = $urandom;
    io_msInfo_13_bits_needRelease = $urandom;
    io_msInfo_13_bits_blockRefill = $urandom;
    io_msInfo_13_bits_meta_dirty = $urandom;
    io_msInfo_13_bits_meta_state = $urandom;
    io_msInfo_13_bits_meta_clients = $urandom;
    io_msInfo_13_bits_meta_alias = $urandom;
    io_msInfo_13_bits_meta_prefetch = $urandom;
    io_msInfo_13_bits_meta_prefetchSrc = $urandom;
    io_msInfo_13_bits_meta_accessed = $urandom;
    io_msInfo_13_bits_meta_tagErr = $urandom;
    io_msInfo_13_bits_meta_dataErr = $urandom;
    io_msInfo_13_bits_metaTag = $urandom;
    io_msInfo_13_bits_dirHit = $urandom;
    io_msInfo_13_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_13_bits_isPrefetch = $urandom;
    io_msInfo_13_bits_param = $urandom;
    io_msInfo_13_bits_mergeA = $urandom;
    io_msInfo_13_bits_w_grantfirst = $urandom;
    io_msInfo_13_bits_s_release = $urandom;
    io_msInfo_13_bits_s_refill = $urandom;
    io_msInfo_13_bits_s_cmoresp = $urandom;
    io_msInfo_13_bits_s_cmometaw = $urandom;
    io_msInfo_13_bits_w_releaseack = $urandom;
    io_msInfo_13_bits_w_replResp = $urandom;
    io_msInfo_13_bits_w_rprobeacklast = $urandom;
    io_msInfo_13_bits_replaceData = $urandom;
    io_msInfo_13_bits_releaseToClean = $urandom;
    io_msInfo_14_valid = ($urandom_range(0,1) == 0);
    io_msInfo_14_bits_channel = $urandom;
    io_msInfo_14_bits_set = $urandom_range(0,7);
    io_msInfo_14_bits_way = $urandom_range(0,7);
    io_msInfo_14_bits_reqTag = $urandom;
    io_msInfo_14_bits_willFree = $urandom;
    io_msInfo_14_bits_aliasTask = $urandom;
    io_msInfo_14_bits_needRelease = $urandom;
    io_msInfo_14_bits_blockRefill = $urandom;
    io_msInfo_14_bits_meta_dirty = $urandom;
    io_msInfo_14_bits_meta_state = $urandom;
    io_msInfo_14_bits_meta_clients = $urandom;
    io_msInfo_14_bits_meta_alias = $urandom;
    io_msInfo_14_bits_meta_prefetch = $urandom;
    io_msInfo_14_bits_meta_prefetchSrc = $urandom;
    io_msInfo_14_bits_meta_accessed = $urandom;
    io_msInfo_14_bits_meta_tagErr = $urandom;
    io_msInfo_14_bits_meta_dataErr = $urandom;
    io_msInfo_14_bits_metaTag = $urandom;
    io_msInfo_14_bits_dirHit = $urandom;
    io_msInfo_14_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_14_bits_isPrefetch = $urandom;
    io_msInfo_14_bits_param = $urandom;
    io_msInfo_14_bits_mergeA = $urandom;
    io_msInfo_14_bits_w_grantfirst = $urandom;
    io_msInfo_14_bits_s_release = $urandom;
    io_msInfo_14_bits_s_refill = $urandom;
    io_msInfo_14_bits_s_cmoresp = $urandom;
    io_msInfo_14_bits_s_cmometaw = $urandom;
    io_msInfo_14_bits_w_releaseack = $urandom;
    io_msInfo_14_bits_w_replResp = $urandom;
    io_msInfo_14_bits_w_rprobeacklast = $urandom;
    io_msInfo_14_bits_replaceData = $urandom;
    io_msInfo_14_bits_releaseToClean = $urandom;
    io_msInfo_15_valid = ($urandom_range(0,1) == 0);
    io_msInfo_15_bits_channel = $urandom;
    io_msInfo_15_bits_set = $urandom_range(0,7);
    io_msInfo_15_bits_way = $urandom_range(0,7);
    io_msInfo_15_bits_reqTag = $urandom;
    io_msInfo_15_bits_willFree = $urandom;
    io_msInfo_15_bits_aliasTask = $urandom;
    io_msInfo_15_bits_needRelease = $urandom;
    io_msInfo_15_bits_blockRefill = $urandom;
    io_msInfo_15_bits_meta_dirty = $urandom;
    io_msInfo_15_bits_meta_state = $urandom;
    io_msInfo_15_bits_meta_clients = $urandom;
    io_msInfo_15_bits_meta_alias = $urandom;
    io_msInfo_15_bits_meta_prefetch = $urandom;
    io_msInfo_15_bits_meta_prefetchSrc = $urandom;
    io_msInfo_15_bits_meta_accessed = $urandom;
    io_msInfo_15_bits_meta_tagErr = $urandom;
    io_msInfo_15_bits_meta_dataErr = $urandom;
    io_msInfo_15_bits_metaTag = $urandom;
    io_msInfo_15_bits_dirHit = $urandom;
    io_msInfo_15_bits_isAcqOrPrefetch = $urandom;
    io_msInfo_15_bits_isPrefetch = $urandom;
    io_msInfo_15_bits_param = $urandom;
    io_msInfo_15_bits_mergeA = $urandom;
    io_msInfo_15_bits_w_grantfirst = $urandom;
    io_msInfo_15_bits_s_release = $urandom;
    io_msInfo_15_bits_s_refill = $urandom;
    io_msInfo_15_bits_s_cmoresp = $urandom;
    io_msInfo_15_bits_s_cmometaw = $urandom;
    io_msInfo_15_bits_w_releaseack = $urandom;
    io_msInfo_15_bits_w_replResp = $urandom;
    io_msInfo_15_bits_w_rprobeacklast = $urandom;
    io_msInfo_15_bits_replaceData = $urandom;
    io_msInfo_15_bits_releaseToClean = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_sinkA_ready)
    `CHK(io_s1Entrance_valid)
    `CHK(io_s1Entrance_bits_set)
    `CHK(io_sinkB_ready)
    `CHK(io_sinkC_ready)
    `CHK(io_mshrTask_ready)
    `CHK(io_dirRead_s1_valid)
    `CHK(io_dirRead_s1_bits_tag)
    `CHK(io_dirRead_s1_bits_set)
    `CHK(io_dirRead_s1_bits_wayMask)
    `CHK(io_dirRead_s1_bits_replacerInfo_channel)
    `CHK(io_dirRead_s1_bits_replacerInfo_opcode)
    `CHK(io_dirRead_s1_bits_replacerInfo_reqSource)
    `CHK(io_dirRead_s1_bits_replacerInfo_refill_prefetch)
    `CHK(io_dirRead_s1_bits_refill)
    `CHK(io_dirRead_s1_bits_mshrId)
    `CHK(io_dirRead_s1_bits_cmoAll)
    `CHK(io_dirRead_s1_bits_cmoWay)
    `CHK(io_taskToPipe_s2_valid)
    `CHK(io_taskToPipe_s2_bits_channel)
    `CHK(io_taskToPipe_s2_bits_txChannel)
    `CHK(io_taskToPipe_s2_bits_set)
    `CHK(io_taskToPipe_s2_bits_tag)
    `CHK(io_taskToPipe_s2_bits_off)
    `CHK(io_taskToPipe_s2_bits_alias)
    `CHK(io_taskToPipe_s2_bits_vaddr)
    `CHK(io_taskToPipe_s2_bits_isKeyword)
    `CHK(io_taskToPipe_s2_bits_opcode)
    `CHK(io_taskToPipe_s2_bits_param)
    `CHK(io_taskToPipe_s2_bits_size)
    `CHK(io_taskToPipe_s2_bits_sourceId)
    `CHK(io_taskToPipe_s2_bits_bufIdx)
    `CHK(io_taskToPipe_s2_bits_needProbeAckData)
    `CHK(io_taskToPipe_s2_bits_denied)
    `CHK(io_taskToPipe_s2_bits_corrupt)
    `CHK(io_taskToPipe_s2_bits_mshrTask)
    `CHK(io_taskToPipe_s2_bits_mshrId)
    `CHK(io_taskToPipe_s2_bits_aliasTask)
    `CHK(io_taskToPipe_s2_bits_useProbeData)
    `CHK(io_taskToPipe_s2_bits_mshrRetry)
    `CHK(io_taskToPipe_s2_bits_readProbeDataDown)
    `CHK(io_taskToPipe_s2_bits_fromL2pft)
    `CHK(io_taskToPipe_s2_bits_needHint)
    `CHK(io_taskToPipe_s2_bits_dirty)
    `CHK(io_taskToPipe_s2_bits_way)
    `CHK(io_taskToPipe_s2_bits_meta_dirty)
    `CHK(io_taskToPipe_s2_bits_meta_state)
    `CHK(io_taskToPipe_s2_bits_meta_clients)
    `CHK(io_taskToPipe_s2_bits_meta_alias)
    `CHK(io_taskToPipe_s2_bits_meta_prefetch)
    `CHK(io_taskToPipe_s2_bits_meta_prefetchSrc)
    `CHK(io_taskToPipe_s2_bits_meta_accessed)
    `CHK(io_taskToPipe_s2_bits_meta_tagErr)
    `CHK(io_taskToPipe_s2_bits_meta_dataErr)
    `CHK(io_taskToPipe_s2_bits_metaWen)
    `CHK(io_taskToPipe_s2_bits_tagWen)
    `CHK(io_taskToPipe_s2_bits_dsWen)
    `CHK(io_taskToPipe_s2_bits_wayMask)
    `CHK(io_taskToPipe_s2_bits_replTask)
    `CHK(io_taskToPipe_s2_bits_cmoTask)
    `CHK(io_taskToPipe_s2_bits_cmoAll)
    `CHK(io_taskToPipe_s2_bits_reqSource)
    `CHK(io_taskToPipe_s2_bits_mergeA)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_off)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_alias)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_vaddr)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_isKeyword)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_opcode)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_param)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_sourceId)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_dirty)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_state)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_clients)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_alias)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_prefetch)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_accessed)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_tagErr)
    `CHK(io_taskToPipe_s2_bits_aMergeTask_meta_dataErr)
    `CHK(io_taskToPipe_s2_bits_snpHitRelease)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseToInval)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseToClean)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseWithData)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseIdx)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_state)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_clients)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_alias)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr)
    `CHK(io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr)
    `CHK(io_taskToPipe_s2_bits_tgtID)
    `CHK(io_taskToPipe_s2_bits_srcID)
    `CHK(io_taskToPipe_s2_bits_txnID)
    `CHK(io_taskToPipe_s2_bits_homeNID)
    `CHK(io_taskToPipe_s2_bits_dbID)
    `CHK(io_taskToPipe_s2_bits_fwdNID)
    `CHK(io_taskToPipe_s2_bits_fwdTxnID)
    `CHK(io_taskToPipe_s2_bits_chiOpcode)
    `CHK(io_taskToPipe_s2_bits_resp)
    `CHK(io_taskToPipe_s2_bits_fwdState)
    `CHK(io_taskToPipe_s2_bits_pCrdType)
    `CHK(io_taskToPipe_s2_bits_retToSrc)
    `CHK(io_taskToPipe_s2_bits_likelyshared)
    `CHK(io_taskToPipe_s2_bits_expCompAck)
    `CHK(io_taskToPipe_s2_bits_allowRetry)
    `CHK(io_taskToPipe_s2_bits_memAttr_allocate)
    `CHK(io_taskToPipe_s2_bits_memAttr_cacheable)
    `CHK(io_taskToPipe_s2_bits_memAttr_device)
    `CHK(io_taskToPipe_s2_bits_memAttr_ewa)
    `CHK(io_taskToPipe_s2_bits_traceTag)
    `CHK(io_taskToPipe_s2_bits_dataCheckErr)
    `CHK(io_taskInfo_s1_valid)
    `CHK(io_taskInfo_s1_bits_channel)
    `CHK(io_taskInfo_s1_bits_txChannel)
    `CHK(io_taskInfo_s1_bits_set)
    `CHK(io_taskInfo_s1_bits_tag)
    `CHK(io_taskInfo_s1_bits_off)
    `CHK(io_taskInfo_s1_bits_alias)
    `CHK(io_taskInfo_s1_bits_vaddr)
    `CHK(io_taskInfo_s1_bits_isKeyword)
    `CHK(io_taskInfo_s1_bits_opcode)
    `CHK(io_taskInfo_s1_bits_param)
    `CHK(io_taskInfo_s1_bits_size)
    `CHK(io_taskInfo_s1_bits_sourceId)
    `CHK(io_taskInfo_s1_bits_bufIdx)
    `CHK(io_taskInfo_s1_bits_needProbeAckData)
    `CHK(io_taskInfo_s1_bits_denied)
    `CHK(io_taskInfo_s1_bits_corrupt)
    `CHK(io_taskInfo_s1_bits_mshrTask)
    `CHK(io_taskInfo_s1_bits_mshrId)
    `CHK(io_taskInfo_s1_bits_aliasTask)
    `CHK(io_taskInfo_s1_bits_useProbeData)
    `CHK(io_taskInfo_s1_bits_mshrRetry)
    `CHK(io_taskInfo_s1_bits_readProbeDataDown)
    `CHK(io_taskInfo_s1_bits_fromL2pft)
    `CHK(io_taskInfo_s1_bits_needHint)
    `CHK(io_taskInfo_s1_bits_dirty)
    `CHK(io_taskInfo_s1_bits_way)
    `CHK(io_taskInfo_s1_bits_meta_dirty)
    `CHK(io_taskInfo_s1_bits_meta_state)
    `CHK(io_taskInfo_s1_bits_meta_clients)
    `CHK(io_taskInfo_s1_bits_meta_alias)
    `CHK(io_taskInfo_s1_bits_meta_prefetch)
    `CHK(io_taskInfo_s1_bits_meta_prefetchSrc)
    `CHK(io_taskInfo_s1_bits_meta_accessed)
    `CHK(io_taskInfo_s1_bits_meta_tagErr)
    `CHK(io_taskInfo_s1_bits_meta_dataErr)
    `CHK(io_taskInfo_s1_bits_metaWen)
    `CHK(io_taskInfo_s1_bits_tagWen)
    `CHK(io_taskInfo_s1_bits_dsWen)
    `CHK(io_taskInfo_s1_bits_wayMask)
    `CHK(io_taskInfo_s1_bits_replTask)
    `CHK(io_taskInfo_s1_bits_cmoTask)
    `CHK(io_taskInfo_s1_bits_cmoAll)
    `CHK(io_taskInfo_s1_bits_reqSource)
    `CHK(io_taskInfo_s1_bits_mergeA)
    `CHK(io_taskInfo_s1_bits_aMergeTask_off)
    `CHK(io_taskInfo_s1_bits_aMergeTask_alias)
    `CHK(io_taskInfo_s1_bits_aMergeTask_vaddr)
    `CHK(io_taskInfo_s1_bits_aMergeTask_isKeyword)
    `CHK(io_taskInfo_s1_bits_aMergeTask_opcode)
    `CHK(io_taskInfo_s1_bits_aMergeTask_param)
    `CHK(io_taskInfo_s1_bits_aMergeTask_sourceId)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_dirty)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_state)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_clients)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_alias)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_prefetch)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_accessed)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_tagErr)
    `CHK(io_taskInfo_s1_bits_aMergeTask_meta_dataErr)
    `CHK(io_taskInfo_s1_bits_snpHitRelease)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseToInval)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseToClean)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseWithData)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseIdx)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_dirty)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_state)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_clients)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_alias)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_accessed)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr)
    `CHK(io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr)
    `CHK(io_taskInfo_s1_bits_tgtID)
    `CHK(io_taskInfo_s1_bits_srcID)
    `CHK(io_taskInfo_s1_bits_txnID)
    `CHK(io_taskInfo_s1_bits_homeNID)
    `CHK(io_taskInfo_s1_bits_dbID)
    `CHK(io_taskInfo_s1_bits_fwdNID)
    `CHK(io_taskInfo_s1_bits_fwdTxnID)
    `CHK(io_taskInfo_s1_bits_chiOpcode)
    `CHK(io_taskInfo_s1_bits_resp)
    `CHK(io_taskInfo_s1_bits_fwdState)
    `CHK(io_taskInfo_s1_bits_pCrdType)
    `CHK(io_taskInfo_s1_bits_retToSrc)
    `CHK(io_taskInfo_s1_bits_likelyshared)
    `CHK(io_taskInfo_s1_bits_expCompAck)
    `CHK(io_taskInfo_s1_bits_allowRetry)
    `CHK(io_taskInfo_s1_bits_memAttr_allocate)
    `CHK(io_taskInfo_s1_bits_memAttr_cacheable)
    `CHK(io_taskInfo_s1_bits_memAttr_device)
    `CHK(io_taskInfo_s1_bits_memAttr_ewa)
    `CHK(io_taskInfo_s1_bits_traceTag)
    `CHK(io_taskInfo_s1_bits_dataCheckErr)
    `CHK(io_refillBufRead_s2_valid)
    `CHK(io_refillBufRead_s2_bits_id)
    `CHK(io_releaseBufRead_s2_valid)
    `CHK(io_releaseBufRead_s2_bits_id)
    `CHK(io_status_s1_tags_0)
    `CHK(io_status_s1_tags_1)
    `CHK(io_status_s1_tags_2)
    `CHK(io_status_s1_tags_3)
    `CHK(io_status_s1_sets_0)
    `CHK(io_status_s1_sets_1)
    `CHK(io_status_s1_sets_2)
    `CHK(io_status_s1_sets_3)
    `CHK(io_status_vec_0_valid)
    `CHK(io_status_vec_0_bits_channel)
    `CHK(io_status_vec_1_valid)
    `CHK(io_status_vec_1_bits_channel)
    `CHK(io_status_vec_toTX_0_valid)
    `CHK(io_status_vec_toTX_0_bits_channel)
    `CHK(io_status_vec_toTX_0_bits_txChannel)
    `CHK(io_status_vec_toTX_0_bits_mshrTask)
    `CHK(io_status_vec_toTX_1_valid)
    `CHK(io_status_vec_toTX_1_bits_channel)
    `CHK(io_status_vec_toTX_1_bits_txChannel)
    `CHK(io_status_vec_toTX_1_bits_mshrTask)
  endtask

  int ierr = 0;
  `define IP(SIG) begin \
    if (!$isunknown(u_g.SIG)) begin \
      if (u_g.SIG !== u_i.u_core.SIG) begin \
        ierr++; \
        if (ierr <= 40) $display("[%0t] IPROBE-DIFF %s g=%0h i=%0h", $time, `"SIG`", u_g.SIG, u_i.u_core.SIG); \
      end \
    end \
  end
  task automatic check_internal();
    `IP(resetFinish)
    `IP(resetIdx)
    `IP(ds_mcp2_stall)
    `IP(mshr_task_s1_valid)
    `IP(task_s2_valid)
    `IP(mshr_task_s1_bits_channel)
    `IP(task_s2_bits_channel)
    `IP(mshr_task_s1_bits_txChannel)
    `IP(task_s2_bits_txChannel)
    `IP(mshr_task_s1_bits_set)
    `IP(task_s2_bits_set)
    `IP(mshr_task_s1_bits_tag)
    `IP(task_s2_bits_tag)
    `IP(mshr_task_s1_bits_off)
    `IP(task_s2_bits_off)
    `IP(mshr_task_s1_bits_alias)
    `IP(task_s2_bits_alias)
    `IP(mshr_task_s1_bits_vaddr)
    `IP(task_s2_bits_vaddr)
    `IP(mshr_task_s1_bits_isKeyword)
    `IP(task_s2_bits_isKeyword)
    `IP(mshr_task_s1_bits_opcode)
    `IP(task_s2_bits_opcode)
    `IP(mshr_task_s1_bits_param)
    `IP(task_s2_bits_param)
    `IP(mshr_task_s1_bits_size)
    `IP(task_s2_bits_size)
    `IP(mshr_task_s1_bits_sourceId)
    `IP(task_s2_bits_sourceId)
    `IP(mshr_task_s1_bits_bufIdx)
    `IP(task_s2_bits_bufIdx)
    `IP(mshr_task_s1_bits_needProbeAckData)
    `IP(task_s2_bits_needProbeAckData)
    `IP(mshr_task_s1_bits_denied)
    `IP(task_s2_bits_denied)
    `IP(mshr_task_s1_bits_corrupt)
    `IP(task_s2_bits_corrupt)
    `IP(mshr_task_s1_bits_mshrTask)
    `IP(task_s2_bits_mshrTask)
    `IP(mshr_task_s1_bits_mshrId)
    `IP(task_s2_bits_mshrId)
    `IP(mshr_task_s1_bits_aliasTask)
    `IP(task_s2_bits_aliasTask)
    `IP(mshr_task_s1_bits_useProbeData)
    `IP(task_s2_bits_useProbeData)
    `IP(mshr_task_s1_bits_mshrRetry)
    `IP(task_s2_bits_mshrRetry)
    `IP(mshr_task_s1_bits_readProbeDataDown)
    `IP(task_s2_bits_readProbeDataDown)
    `IP(mshr_task_s1_bits_fromL2pft)
    `IP(task_s2_bits_fromL2pft)
    `IP(mshr_task_s1_bits_needHint)
    `IP(task_s2_bits_needHint)
    `IP(mshr_task_s1_bits_dirty)
    `IP(task_s2_bits_dirty)
    `IP(mshr_task_s1_bits_way)
    `IP(task_s2_bits_way)
    `IP(mshr_task_s1_bits_meta_dirty)
    `IP(task_s2_bits_meta_dirty)
    `IP(mshr_task_s1_bits_meta_state)
    `IP(task_s2_bits_meta_state)
    `IP(mshr_task_s1_bits_meta_clients)
    `IP(task_s2_bits_meta_clients)
    `IP(mshr_task_s1_bits_meta_alias)
    `IP(task_s2_bits_meta_alias)
    `IP(mshr_task_s1_bits_meta_prefetch)
    `IP(task_s2_bits_meta_prefetch)
    `IP(mshr_task_s1_bits_meta_prefetchSrc)
    `IP(task_s2_bits_meta_prefetchSrc)
    `IP(mshr_task_s1_bits_meta_accessed)
    `IP(task_s2_bits_meta_accessed)
    `IP(mshr_task_s1_bits_meta_tagErr)
    `IP(task_s2_bits_meta_tagErr)
    `IP(mshr_task_s1_bits_meta_dataErr)
    `IP(task_s2_bits_meta_dataErr)
    `IP(mshr_task_s1_bits_metaWen)
    `IP(task_s2_bits_metaWen)
    `IP(mshr_task_s1_bits_tagWen)
    `IP(task_s2_bits_tagWen)
    `IP(mshr_task_s1_bits_dsWen)
    `IP(task_s2_bits_dsWen)
    `IP(mshr_task_s1_bits_wayMask)
    `IP(task_s2_bits_wayMask)
    `IP(mshr_task_s1_bits_replTask)
    `IP(task_s2_bits_replTask)
    `IP(mshr_task_s1_bits_cmoTask)
    `IP(task_s2_bits_cmoTask)
    `IP(mshr_task_s1_bits_cmoAll)
    `IP(task_s2_bits_cmoAll)
    `IP(mshr_task_s1_bits_reqSource)
    `IP(task_s2_bits_reqSource)
    `IP(mshr_task_s1_bits_mergeA)
    `IP(task_s2_bits_mergeA)
    `IP(mshr_task_s1_bits_aMergeTask_off)
    `IP(task_s2_bits_aMergeTask_off)
    `IP(mshr_task_s1_bits_aMergeTask_alias)
    `IP(task_s2_bits_aMergeTask_alias)
    `IP(mshr_task_s1_bits_aMergeTask_vaddr)
    `IP(task_s2_bits_aMergeTask_vaddr)
    `IP(mshr_task_s1_bits_aMergeTask_isKeyword)
    `IP(task_s2_bits_aMergeTask_isKeyword)
    `IP(mshr_task_s1_bits_aMergeTask_opcode)
    `IP(task_s2_bits_aMergeTask_opcode)
    `IP(mshr_task_s1_bits_aMergeTask_param)
    `IP(task_s2_bits_aMergeTask_param)
    `IP(mshr_task_s1_bits_aMergeTask_sourceId)
    `IP(task_s2_bits_aMergeTask_sourceId)
    `IP(mshr_task_s1_bits_aMergeTask_meta_dirty)
    `IP(task_s2_bits_aMergeTask_meta_dirty)
    `IP(mshr_task_s1_bits_aMergeTask_meta_state)
    `IP(task_s2_bits_aMergeTask_meta_state)
    `IP(mshr_task_s1_bits_aMergeTask_meta_clients)
    `IP(task_s2_bits_aMergeTask_meta_clients)
    `IP(mshr_task_s1_bits_aMergeTask_meta_alias)
    `IP(task_s2_bits_aMergeTask_meta_alias)
    `IP(mshr_task_s1_bits_aMergeTask_meta_prefetch)
    `IP(task_s2_bits_aMergeTask_meta_prefetch)
    `IP(mshr_task_s1_bits_aMergeTask_meta_prefetchSrc)
    `IP(task_s2_bits_aMergeTask_meta_prefetchSrc)
    `IP(mshr_task_s1_bits_aMergeTask_meta_accessed)
    `IP(task_s2_bits_aMergeTask_meta_accessed)
    `IP(mshr_task_s1_bits_aMergeTask_meta_tagErr)
    `IP(task_s2_bits_aMergeTask_meta_tagErr)
    `IP(mshr_task_s1_bits_aMergeTask_meta_dataErr)
    `IP(task_s2_bits_aMergeTask_meta_dataErr)
    `IP(mshr_task_s1_bits_snpHitRelease)
    `IP(task_s2_bits_snpHitRelease)
    `IP(mshr_task_s1_bits_snpHitReleaseToInval)
    `IP(task_s2_bits_snpHitReleaseToInval)
    `IP(mshr_task_s1_bits_snpHitReleaseToClean)
    `IP(task_s2_bits_snpHitReleaseToClean)
    `IP(mshr_task_s1_bits_snpHitReleaseWithData)
    `IP(task_s2_bits_snpHitReleaseWithData)
    `IP(mshr_task_s1_bits_snpHitReleaseIdx)
    `IP(task_s2_bits_snpHitReleaseIdx)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_dirty)
    `IP(task_s2_bits_snpHitReleaseMeta_dirty)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_state)
    `IP(task_s2_bits_snpHitReleaseMeta_state)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_clients)
    `IP(task_s2_bits_snpHitReleaseMeta_clients)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_alias)
    `IP(task_s2_bits_snpHitReleaseMeta_alias)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_prefetch)
    `IP(task_s2_bits_snpHitReleaseMeta_prefetch)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc)
    `IP(task_s2_bits_snpHitReleaseMeta_prefetchSrc)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_accessed)
    `IP(task_s2_bits_snpHitReleaseMeta_accessed)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_tagErr)
    `IP(task_s2_bits_snpHitReleaseMeta_tagErr)
    `IP(mshr_task_s1_bits_snpHitReleaseMeta_dataErr)
    `IP(task_s2_bits_snpHitReleaseMeta_dataErr)
    `IP(mshr_task_s1_bits_tgtID)
    `IP(task_s2_bits_tgtID)
    `IP(mshr_task_s1_bits_srcID)
    `IP(task_s2_bits_srcID)
    `IP(mshr_task_s1_bits_txnID)
    `IP(task_s2_bits_txnID)
    `IP(mshr_task_s1_bits_homeNID)
    `IP(task_s2_bits_homeNID)
    `IP(mshr_task_s1_bits_dbID)
    `IP(task_s2_bits_dbID)
    `IP(mshr_task_s1_bits_fwdNID)
    `IP(task_s2_bits_fwdNID)
    `IP(mshr_task_s1_bits_fwdTxnID)
    `IP(task_s2_bits_fwdTxnID)
    `IP(mshr_task_s1_bits_chiOpcode)
    `IP(task_s2_bits_chiOpcode)
    `IP(mshr_task_s1_bits_resp)
    `IP(task_s2_bits_resp)
    `IP(mshr_task_s1_bits_fwdState)
    `IP(task_s2_bits_fwdState)
    `IP(mshr_task_s1_bits_pCrdType)
    `IP(task_s2_bits_pCrdType)
    `IP(mshr_task_s1_bits_retToSrc)
    `IP(task_s2_bits_retToSrc)
    `IP(mshr_task_s1_bits_likelyshared)
    `IP(task_s2_bits_likelyshared)
    `IP(mshr_task_s1_bits_expCompAck)
    `IP(task_s2_bits_expCompAck)
    `IP(mshr_task_s1_bits_allowRetry)
    `IP(task_s2_bits_allowRetry)
    `IP(mshr_task_s1_bits_memAttr_allocate)
    `IP(task_s2_bits_memAttr_allocate)
    `IP(mshr_task_s1_bits_memAttr_cacheable)
    `IP(task_s2_bits_memAttr_cacheable)
    `IP(mshr_task_s1_bits_memAttr_device)
    `IP(task_s2_bits_memAttr_device)
    `IP(mshr_task_s1_bits_memAttr_ewa)
    `IP(task_s2_bits_memAttr_ewa)
    `IP(mshr_task_s1_bits_traceTag)
    `IP(task_s2_bits_traceTag)
    `IP(mshr_task_s1_bits_dataCheckErr)
    `IP(task_s2_bits_dataCheckErr)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_sinkA_valid = '0;
    io_sinkA_bits_channel = '0;
    io_sinkA_bits_txChannel = '0;
    io_sinkA_bits_set = '0;
    io_sinkA_bits_tag = '0;
    io_sinkA_bits_off = '0;
    io_sinkA_bits_alias = '0;
    io_sinkA_bits_vaddr = '0;
    io_sinkA_bits_isKeyword = '0;
    io_sinkA_bits_opcode = '0;
    io_sinkA_bits_param = '0;
    io_sinkA_bits_size = '0;
    io_sinkA_bits_sourceId = '0;
    io_sinkA_bits_bufIdx = '0;
    io_sinkA_bits_needProbeAckData = '0;
    io_sinkA_bits_denied = '0;
    io_sinkA_bits_corrupt = '0;
    io_sinkA_bits_mshrTask = '0;
    io_sinkA_bits_mshrId = '0;
    io_sinkA_bits_aliasTask = '0;
    io_sinkA_bits_useProbeData = '0;
    io_sinkA_bits_mshrRetry = '0;
    io_sinkA_bits_readProbeDataDown = '0;
    io_sinkA_bits_fromL2pft = '0;
    io_sinkA_bits_needHint = '0;
    io_sinkA_bits_dirty = '0;
    io_sinkA_bits_way = '0;
    io_sinkA_bits_meta_dirty = '0;
    io_sinkA_bits_meta_state = '0;
    io_sinkA_bits_meta_clients = '0;
    io_sinkA_bits_meta_alias = '0;
    io_sinkA_bits_meta_prefetch = '0;
    io_sinkA_bits_meta_prefetchSrc = '0;
    io_sinkA_bits_meta_accessed = '0;
    io_sinkA_bits_meta_tagErr = '0;
    io_sinkA_bits_meta_dataErr = '0;
    io_sinkA_bits_metaWen = '0;
    io_sinkA_bits_tagWen = '0;
    io_sinkA_bits_dsWen = '0;
    io_sinkA_bits_wayMask = '0;
    io_sinkA_bits_replTask = '0;
    io_sinkA_bits_cmoTask = '0;
    io_sinkA_bits_cmoAll = '0;
    io_sinkA_bits_reqSource = '0;
    io_sinkA_bits_mergeA = '0;
    io_sinkA_bits_aMergeTask_off = '0;
    io_sinkA_bits_aMergeTask_alias = '0;
    io_sinkA_bits_aMergeTask_vaddr = '0;
    io_sinkA_bits_aMergeTask_isKeyword = '0;
    io_sinkA_bits_aMergeTask_opcode = '0;
    io_sinkA_bits_aMergeTask_param = '0;
    io_sinkA_bits_aMergeTask_sourceId = '0;
    io_sinkA_bits_aMergeTask_meta_dirty = '0;
    io_sinkA_bits_aMergeTask_meta_state = '0;
    io_sinkA_bits_aMergeTask_meta_clients = '0;
    io_sinkA_bits_aMergeTask_meta_alias = '0;
    io_sinkA_bits_aMergeTask_meta_prefetch = '0;
    io_sinkA_bits_aMergeTask_meta_prefetchSrc = '0;
    io_sinkA_bits_aMergeTask_meta_accessed = '0;
    io_sinkA_bits_aMergeTask_meta_tagErr = '0;
    io_sinkA_bits_aMergeTask_meta_dataErr = '0;
    io_sinkA_bits_snpHitRelease = '0;
    io_sinkA_bits_snpHitReleaseToInval = '0;
    io_sinkA_bits_snpHitReleaseToClean = '0;
    io_sinkA_bits_snpHitReleaseWithData = '0;
    io_sinkA_bits_snpHitReleaseIdx = '0;
    io_sinkA_bits_snpHitReleaseMeta_dirty = '0;
    io_sinkA_bits_snpHitReleaseMeta_state = '0;
    io_sinkA_bits_snpHitReleaseMeta_clients = '0;
    io_sinkA_bits_snpHitReleaseMeta_alias = '0;
    io_sinkA_bits_snpHitReleaseMeta_prefetch = '0;
    io_sinkA_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_sinkA_bits_snpHitReleaseMeta_accessed = '0;
    io_sinkA_bits_snpHitReleaseMeta_tagErr = '0;
    io_sinkA_bits_snpHitReleaseMeta_dataErr = '0;
    io_sinkA_bits_tgtID = '0;
    io_sinkA_bits_srcID = '0;
    io_sinkA_bits_txnID = '0;
    io_sinkA_bits_homeNID = '0;
    io_sinkA_bits_dbID = '0;
    io_sinkA_bits_fwdNID = '0;
    io_sinkA_bits_fwdTxnID = '0;
    io_sinkA_bits_chiOpcode = '0;
    io_sinkA_bits_resp = '0;
    io_sinkA_bits_fwdState = '0;
    io_sinkA_bits_pCrdType = '0;
    io_sinkA_bits_retToSrc = '0;
    io_sinkA_bits_likelyshared = '0;
    io_sinkA_bits_expCompAck = '0;
    io_sinkA_bits_allowRetry = '0;
    io_sinkA_bits_memAttr_allocate = '0;
    io_sinkA_bits_memAttr_cacheable = '0;
    io_sinkA_bits_memAttr_device = '0;
    io_sinkA_bits_memAttr_ewa = '0;
    io_sinkA_bits_traceTag = '0;
    io_sinkA_bits_dataCheckErr = '0;
    io_ATag = '0;
    io_ASet = '0;
    io_sinkB_valid = '0;
    io_sinkB_bits_channel = '0;
    io_sinkB_bits_txChannel = '0;
    io_sinkB_bits_set = '0;
    io_sinkB_bits_tag = '0;
    io_sinkB_bits_off = '0;
    io_sinkB_bits_alias = '0;
    io_sinkB_bits_vaddr = '0;
    io_sinkB_bits_isKeyword = '0;
    io_sinkB_bits_opcode = '0;
    io_sinkB_bits_param = '0;
    io_sinkB_bits_size = '0;
    io_sinkB_bits_sourceId = '0;
    io_sinkB_bits_bufIdx = '0;
    io_sinkB_bits_needProbeAckData = '0;
    io_sinkB_bits_denied = '0;
    io_sinkB_bits_corrupt = '0;
    io_sinkB_bits_mshrTask = '0;
    io_sinkB_bits_mshrId = '0;
    io_sinkB_bits_aliasTask = '0;
    io_sinkB_bits_useProbeData = '0;
    io_sinkB_bits_mshrRetry = '0;
    io_sinkB_bits_readProbeDataDown = '0;
    io_sinkB_bits_fromL2pft = '0;
    io_sinkB_bits_needHint = '0;
    io_sinkB_bits_dirty = '0;
    io_sinkB_bits_way = '0;
    io_sinkB_bits_meta_dirty = '0;
    io_sinkB_bits_meta_state = '0;
    io_sinkB_bits_meta_clients = '0;
    io_sinkB_bits_meta_alias = '0;
    io_sinkB_bits_meta_prefetch = '0;
    io_sinkB_bits_meta_prefetchSrc = '0;
    io_sinkB_bits_meta_accessed = '0;
    io_sinkB_bits_meta_tagErr = '0;
    io_sinkB_bits_meta_dataErr = '0;
    io_sinkB_bits_metaWen = '0;
    io_sinkB_bits_tagWen = '0;
    io_sinkB_bits_dsWen = '0;
    io_sinkB_bits_wayMask = '0;
    io_sinkB_bits_replTask = '0;
    io_sinkB_bits_cmoTask = '0;
    io_sinkB_bits_cmoAll = '0;
    io_sinkB_bits_reqSource = '0;
    io_sinkB_bits_mergeA = '0;
    io_sinkB_bits_aMergeTask_off = '0;
    io_sinkB_bits_aMergeTask_alias = '0;
    io_sinkB_bits_aMergeTask_vaddr = '0;
    io_sinkB_bits_aMergeTask_isKeyword = '0;
    io_sinkB_bits_aMergeTask_opcode = '0;
    io_sinkB_bits_aMergeTask_param = '0;
    io_sinkB_bits_aMergeTask_sourceId = '0;
    io_sinkB_bits_aMergeTask_meta_dirty = '0;
    io_sinkB_bits_aMergeTask_meta_state = '0;
    io_sinkB_bits_aMergeTask_meta_clients = '0;
    io_sinkB_bits_aMergeTask_meta_alias = '0;
    io_sinkB_bits_aMergeTask_meta_prefetch = '0;
    io_sinkB_bits_aMergeTask_meta_prefetchSrc = '0;
    io_sinkB_bits_aMergeTask_meta_accessed = '0;
    io_sinkB_bits_aMergeTask_meta_tagErr = '0;
    io_sinkB_bits_aMergeTask_meta_dataErr = '0;
    io_sinkB_bits_snpHitRelease = '0;
    io_sinkB_bits_snpHitReleaseToInval = '0;
    io_sinkB_bits_snpHitReleaseToClean = '0;
    io_sinkB_bits_snpHitReleaseWithData = '0;
    io_sinkB_bits_snpHitReleaseIdx = '0;
    io_sinkB_bits_snpHitReleaseMeta_dirty = '0;
    io_sinkB_bits_snpHitReleaseMeta_state = '0;
    io_sinkB_bits_snpHitReleaseMeta_clients = '0;
    io_sinkB_bits_snpHitReleaseMeta_alias = '0;
    io_sinkB_bits_snpHitReleaseMeta_prefetch = '0;
    io_sinkB_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_sinkB_bits_snpHitReleaseMeta_accessed = '0;
    io_sinkB_bits_snpHitReleaseMeta_tagErr = '0;
    io_sinkB_bits_snpHitReleaseMeta_dataErr = '0;
    io_sinkB_bits_tgtID = '0;
    io_sinkB_bits_srcID = '0;
    io_sinkB_bits_txnID = '0;
    io_sinkB_bits_homeNID = '0;
    io_sinkB_bits_dbID = '0;
    io_sinkB_bits_fwdNID = '0;
    io_sinkB_bits_fwdTxnID = '0;
    io_sinkB_bits_chiOpcode = '0;
    io_sinkB_bits_resp = '0;
    io_sinkB_bits_fwdState = '0;
    io_sinkB_bits_pCrdType = '0;
    io_sinkB_bits_retToSrc = '0;
    io_sinkB_bits_likelyshared = '0;
    io_sinkB_bits_expCompAck = '0;
    io_sinkB_bits_allowRetry = '0;
    io_sinkB_bits_memAttr_allocate = '0;
    io_sinkB_bits_memAttr_cacheable = '0;
    io_sinkB_bits_memAttr_device = '0;
    io_sinkB_bits_memAttr_ewa = '0;
    io_sinkB_bits_traceTag = '0;
    io_sinkB_bits_dataCheckErr = '0;
    io_sinkC_valid = '0;
    io_sinkC_bits_channel = '0;
    io_sinkC_bits_txChannel = '0;
    io_sinkC_bits_set = '0;
    io_sinkC_bits_tag = '0;
    io_sinkC_bits_off = '0;
    io_sinkC_bits_alias = '0;
    io_sinkC_bits_vaddr = '0;
    io_sinkC_bits_isKeyword = '0;
    io_sinkC_bits_opcode = '0;
    io_sinkC_bits_param = '0;
    io_sinkC_bits_size = '0;
    io_sinkC_bits_sourceId = '0;
    io_sinkC_bits_bufIdx = '0;
    io_sinkC_bits_needProbeAckData = '0;
    io_sinkC_bits_denied = '0;
    io_sinkC_bits_corrupt = '0;
    io_sinkC_bits_mshrTask = '0;
    io_sinkC_bits_mshrId = '0;
    io_sinkC_bits_aliasTask = '0;
    io_sinkC_bits_useProbeData = '0;
    io_sinkC_bits_mshrRetry = '0;
    io_sinkC_bits_readProbeDataDown = '0;
    io_sinkC_bits_fromL2pft = '0;
    io_sinkC_bits_needHint = '0;
    io_sinkC_bits_dirty = '0;
    io_sinkC_bits_way = '0;
    io_sinkC_bits_meta_dirty = '0;
    io_sinkC_bits_meta_state = '0;
    io_sinkC_bits_meta_clients = '0;
    io_sinkC_bits_meta_alias = '0;
    io_sinkC_bits_meta_prefetch = '0;
    io_sinkC_bits_meta_prefetchSrc = '0;
    io_sinkC_bits_meta_accessed = '0;
    io_sinkC_bits_meta_tagErr = '0;
    io_sinkC_bits_meta_dataErr = '0;
    io_sinkC_bits_metaWen = '0;
    io_sinkC_bits_tagWen = '0;
    io_sinkC_bits_dsWen = '0;
    io_sinkC_bits_wayMask = '0;
    io_sinkC_bits_replTask = '0;
    io_sinkC_bits_cmoTask = '0;
    io_sinkC_bits_cmoAll = '0;
    io_sinkC_bits_reqSource = '0;
    io_sinkC_bits_mergeA = '0;
    io_sinkC_bits_aMergeTask_off = '0;
    io_sinkC_bits_aMergeTask_alias = '0;
    io_sinkC_bits_aMergeTask_vaddr = '0;
    io_sinkC_bits_aMergeTask_isKeyword = '0;
    io_sinkC_bits_aMergeTask_opcode = '0;
    io_sinkC_bits_aMergeTask_param = '0;
    io_sinkC_bits_aMergeTask_sourceId = '0;
    io_sinkC_bits_aMergeTask_meta_dirty = '0;
    io_sinkC_bits_aMergeTask_meta_state = '0;
    io_sinkC_bits_aMergeTask_meta_clients = '0;
    io_sinkC_bits_aMergeTask_meta_alias = '0;
    io_sinkC_bits_aMergeTask_meta_prefetch = '0;
    io_sinkC_bits_aMergeTask_meta_prefetchSrc = '0;
    io_sinkC_bits_aMergeTask_meta_accessed = '0;
    io_sinkC_bits_aMergeTask_meta_tagErr = '0;
    io_sinkC_bits_aMergeTask_meta_dataErr = '0;
    io_sinkC_bits_snpHitRelease = '0;
    io_sinkC_bits_snpHitReleaseToInval = '0;
    io_sinkC_bits_snpHitReleaseToClean = '0;
    io_sinkC_bits_snpHitReleaseWithData = '0;
    io_sinkC_bits_snpHitReleaseIdx = '0;
    io_sinkC_bits_snpHitReleaseMeta_dirty = '0;
    io_sinkC_bits_snpHitReleaseMeta_state = '0;
    io_sinkC_bits_snpHitReleaseMeta_clients = '0;
    io_sinkC_bits_snpHitReleaseMeta_alias = '0;
    io_sinkC_bits_snpHitReleaseMeta_prefetch = '0;
    io_sinkC_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_sinkC_bits_snpHitReleaseMeta_accessed = '0;
    io_sinkC_bits_snpHitReleaseMeta_tagErr = '0;
    io_sinkC_bits_snpHitReleaseMeta_dataErr = '0;
    io_sinkC_bits_tgtID = '0;
    io_sinkC_bits_srcID = '0;
    io_sinkC_bits_txnID = '0;
    io_sinkC_bits_homeNID = '0;
    io_sinkC_bits_dbID = '0;
    io_sinkC_bits_fwdNID = '0;
    io_sinkC_bits_fwdTxnID = '0;
    io_sinkC_bits_chiOpcode = '0;
    io_sinkC_bits_resp = '0;
    io_sinkC_bits_fwdState = '0;
    io_sinkC_bits_pCrdType = '0;
    io_sinkC_bits_retToSrc = '0;
    io_sinkC_bits_likelyshared = '0;
    io_sinkC_bits_expCompAck = '0;
    io_sinkC_bits_allowRetry = '0;
    io_sinkC_bits_memAttr_allocate = '0;
    io_sinkC_bits_memAttr_cacheable = '0;
    io_sinkC_bits_memAttr_device = '0;
    io_sinkC_bits_memAttr_ewa = '0;
    io_sinkC_bits_traceTag = '0;
    io_sinkC_bits_dataCheckErr = '0;
    io_mshrTask_valid = '0;
    io_mshrTask_bits_channel = '0;
    io_mshrTask_bits_txChannel = '0;
    io_mshrTask_bits_set = '0;
    io_mshrTask_bits_tag = '0;
    io_mshrTask_bits_off = '0;
    io_mshrTask_bits_alias = '0;
    io_mshrTask_bits_vaddr = '0;
    io_mshrTask_bits_isKeyword = '0;
    io_mshrTask_bits_opcode = '0;
    io_mshrTask_bits_param = '0;
    io_mshrTask_bits_size = '0;
    io_mshrTask_bits_sourceId = '0;
    io_mshrTask_bits_bufIdx = '0;
    io_mshrTask_bits_needProbeAckData = '0;
    io_mshrTask_bits_denied = '0;
    io_mshrTask_bits_corrupt = '0;
    io_mshrTask_bits_mshrTask = '0;
    io_mshrTask_bits_mshrId = '0;
    io_mshrTask_bits_aliasTask = '0;
    io_mshrTask_bits_useProbeData = '0;
    io_mshrTask_bits_mshrRetry = '0;
    io_mshrTask_bits_readProbeDataDown = '0;
    io_mshrTask_bits_fromL2pft = '0;
    io_mshrTask_bits_needHint = '0;
    io_mshrTask_bits_dirty = '0;
    io_mshrTask_bits_way = '0;
    io_mshrTask_bits_meta_dirty = '0;
    io_mshrTask_bits_meta_state = '0;
    io_mshrTask_bits_meta_clients = '0;
    io_mshrTask_bits_meta_alias = '0;
    io_mshrTask_bits_meta_prefetch = '0;
    io_mshrTask_bits_meta_prefetchSrc = '0;
    io_mshrTask_bits_meta_accessed = '0;
    io_mshrTask_bits_meta_tagErr = '0;
    io_mshrTask_bits_meta_dataErr = '0;
    io_mshrTask_bits_metaWen = '0;
    io_mshrTask_bits_tagWen = '0;
    io_mshrTask_bits_dsWen = '0;
    io_mshrTask_bits_wayMask = '0;
    io_mshrTask_bits_replTask = '0;
    io_mshrTask_bits_cmoTask = '0;
    io_mshrTask_bits_cmoAll = '0;
    io_mshrTask_bits_reqSource = '0;
    io_mshrTask_bits_mergeA = '0;
    io_mshrTask_bits_aMergeTask_off = '0;
    io_mshrTask_bits_aMergeTask_alias = '0;
    io_mshrTask_bits_aMergeTask_vaddr = '0;
    io_mshrTask_bits_aMergeTask_isKeyword = '0;
    io_mshrTask_bits_aMergeTask_opcode = '0;
    io_mshrTask_bits_aMergeTask_param = '0;
    io_mshrTask_bits_aMergeTask_sourceId = '0;
    io_mshrTask_bits_aMergeTask_meta_dirty = '0;
    io_mshrTask_bits_aMergeTask_meta_state = '0;
    io_mshrTask_bits_aMergeTask_meta_clients = '0;
    io_mshrTask_bits_aMergeTask_meta_alias = '0;
    io_mshrTask_bits_aMergeTask_meta_prefetch = '0;
    io_mshrTask_bits_aMergeTask_meta_prefetchSrc = '0;
    io_mshrTask_bits_aMergeTask_meta_accessed = '0;
    io_mshrTask_bits_aMergeTask_meta_tagErr = '0;
    io_mshrTask_bits_aMergeTask_meta_dataErr = '0;
    io_mshrTask_bits_snpHitRelease = '0;
    io_mshrTask_bits_snpHitReleaseToInval = '0;
    io_mshrTask_bits_snpHitReleaseToClean = '0;
    io_mshrTask_bits_snpHitReleaseWithData = '0;
    io_mshrTask_bits_snpHitReleaseIdx = '0;
    io_mshrTask_bits_snpHitReleaseMeta_dirty = '0;
    io_mshrTask_bits_snpHitReleaseMeta_state = '0;
    io_mshrTask_bits_snpHitReleaseMeta_clients = '0;
    io_mshrTask_bits_snpHitReleaseMeta_alias = '0;
    io_mshrTask_bits_snpHitReleaseMeta_prefetch = '0;
    io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_mshrTask_bits_snpHitReleaseMeta_accessed = '0;
    io_mshrTask_bits_snpHitReleaseMeta_tagErr = '0;
    io_mshrTask_bits_snpHitReleaseMeta_dataErr = '0;
    io_mshrTask_bits_tgtID = '0;
    io_mshrTask_bits_srcID = '0;
    io_mshrTask_bits_txnID = '0;
    io_mshrTask_bits_homeNID = '0;
    io_mshrTask_bits_dbID = '0;
    io_mshrTask_bits_fwdNID = '0;
    io_mshrTask_bits_fwdTxnID = '0;
    io_mshrTask_bits_chiOpcode = '0;
    io_mshrTask_bits_resp = '0;
    io_mshrTask_bits_fwdState = '0;
    io_mshrTask_bits_pCrdType = '0;
    io_mshrTask_bits_retToSrc = '0;
    io_mshrTask_bits_likelyshared = '0;
    io_mshrTask_bits_expCompAck = '0;
    io_mshrTask_bits_allowRetry = '0;
    io_mshrTask_bits_memAttr_allocate = '0;
    io_mshrTask_bits_memAttr_cacheable = '0;
    io_mshrTask_bits_memAttr_device = '0;
    io_mshrTask_bits_memAttr_ewa = '0;
    io_mshrTask_bits_traceTag = '0;
    io_mshrTask_bits_dataCheckErr = '0;
    io_dirRead_s1_ready = '0;
    io_fromMSHRCtl_blockG_s1 = '0;
    io_fromMSHRCtl_blockA_s1 = '0;
    io_fromMSHRCtl_blockB_s1 = '0;
    io_fromMSHRCtl_blockC_s1 = '0;
    io_fromMainPipe_blockG_s1 = '0;
    io_fromMainPipe_blockA_s1 = '0;
    io_fromMainPipe_blockB_s1 = '0;
    io_fromMainPipe_blockC_s1 = '0;
    io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1 = '0;
    io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1 = '0;
    io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 = '0;
    io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1 = '0;
    io_fromGrantBuffer_blockMSHRReqEntrance = '0;
    io_fromTXDAT_blockMSHRReqEntrance = '0;
    io_fromTXDAT_blockSinkBReqEntrance = '0;
    io_fromTXRSP_blockMSHRReqEntrance = '0;
    io_fromTXRSP_blockSinkBReqEntrance = '0;
    io_fromTXREQ_blockMSHRReqEntrance = '0;
    io_msInfo_0_valid = '0;
    io_msInfo_0_bits_channel = '0;
    io_msInfo_0_bits_set = '0;
    io_msInfo_0_bits_way = '0;
    io_msInfo_0_bits_reqTag = '0;
    io_msInfo_0_bits_willFree = '0;
    io_msInfo_0_bits_aliasTask = '0;
    io_msInfo_0_bits_needRelease = '0;
    io_msInfo_0_bits_blockRefill = '0;
    io_msInfo_0_bits_meta_dirty = '0;
    io_msInfo_0_bits_meta_state = '0;
    io_msInfo_0_bits_meta_clients = '0;
    io_msInfo_0_bits_meta_alias = '0;
    io_msInfo_0_bits_meta_prefetch = '0;
    io_msInfo_0_bits_meta_prefetchSrc = '0;
    io_msInfo_0_bits_meta_accessed = '0;
    io_msInfo_0_bits_meta_tagErr = '0;
    io_msInfo_0_bits_meta_dataErr = '0;
    io_msInfo_0_bits_metaTag = '0;
    io_msInfo_0_bits_dirHit = '0;
    io_msInfo_0_bits_isAcqOrPrefetch = '0;
    io_msInfo_0_bits_isPrefetch = '0;
    io_msInfo_0_bits_param = '0;
    io_msInfo_0_bits_mergeA = '0;
    io_msInfo_0_bits_w_grantfirst = '0;
    io_msInfo_0_bits_s_release = '0;
    io_msInfo_0_bits_s_refill = '0;
    io_msInfo_0_bits_s_cmoresp = '0;
    io_msInfo_0_bits_s_cmometaw = '0;
    io_msInfo_0_bits_w_releaseack = '0;
    io_msInfo_0_bits_w_replResp = '0;
    io_msInfo_0_bits_w_rprobeacklast = '0;
    io_msInfo_0_bits_replaceData = '0;
    io_msInfo_0_bits_releaseToClean = '0;
    io_msInfo_1_valid = '0;
    io_msInfo_1_bits_channel = '0;
    io_msInfo_1_bits_set = '0;
    io_msInfo_1_bits_way = '0;
    io_msInfo_1_bits_reqTag = '0;
    io_msInfo_1_bits_willFree = '0;
    io_msInfo_1_bits_aliasTask = '0;
    io_msInfo_1_bits_needRelease = '0;
    io_msInfo_1_bits_blockRefill = '0;
    io_msInfo_1_bits_meta_dirty = '0;
    io_msInfo_1_bits_meta_state = '0;
    io_msInfo_1_bits_meta_clients = '0;
    io_msInfo_1_bits_meta_alias = '0;
    io_msInfo_1_bits_meta_prefetch = '0;
    io_msInfo_1_bits_meta_prefetchSrc = '0;
    io_msInfo_1_bits_meta_accessed = '0;
    io_msInfo_1_bits_meta_tagErr = '0;
    io_msInfo_1_bits_meta_dataErr = '0;
    io_msInfo_1_bits_metaTag = '0;
    io_msInfo_1_bits_dirHit = '0;
    io_msInfo_1_bits_isAcqOrPrefetch = '0;
    io_msInfo_1_bits_isPrefetch = '0;
    io_msInfo_1_bits_param = '0;
    io_msInfo_1_bits_mergeA = '0;
    io_msInfo_1_bits_w_grantfirst = '0;
    io_msInfo_1_bits_s_release = '0;
    io_msInfo_1_bits_s_refill = '0;
    io_msInfo_1_bits_s_cmoresp = '0;
    io_msInfo_1_bits_s_cmometaw = '0;
    io_msInfo_1_bits_w_releaseack = '0;
    io_msInfo_1_bits_w_replResp = '0;
    io_msInfo_1_bits_w_rprobeacklast = '0;
    io_msInfo_1_bits_replaceData = '0;
    io_msInfo_1_bits_releaseToClean = '0;
    io_msInfo_2_valid = '0;
    io_msInfo_2_bits_channel = '0;
    io_msInfo_2_bits_set = '0;
    io_msInfo_2_bits_way = '0;
    io_msInfo_2_bits_reqTag = '0;
    io_msInfo_2_bits_willFree = '0;
    io_msInfo_2_bits_aliasTask = '0;
    io_msInfo_2_bits_needRelease = '0;
    io_msInfo_2_bits_blockRefill = '0;
    io_msInfo_2_bits_meta_dirty = '0;
    io_msInfo_2_bits_meta_state = '0;
    io_msInfo_2_bits_meta_clients = '0;
    io_msInfo_2_bits_meta_alias = '0;
    io_msInfo_2_bits_meta_prefetch = '0;
    io_msInfo_2_bits_meta_prefetchSrc = '0;
    io_msInfo_2_bits_meta_accessed = '0;
    io_msInfo_2_bits_meta_tagErr = '0;
    io_msInfo_2_bits_meta_dataErr = '0;
    io_msInfo_2_bits_metaTag = '0;
    io_msInfo_2_bits_dirHit = '0;
    io_msInfo_2_bits_isAcqOrPrefetch = '0;
    io_msInfo_2_bits_isPrefetch = '0;
    io_msInfo_2_bits_param = '0;
    io_msInfo_2_bits_mergeA = '0;
    io_msInfo_2_bits_w_grantfirst = '0;
    io_msInfo_2_bits_s_release = '0;
    io_msInfo_2_bits_s_refill = '0;
    io_msInfo_2_bits_s_cmoresp = '0;
    io_msInfo_2_bits_s_cmometaw = '0;
    io_msInfo_2_bits_w_releaseack = '0;
    io_msInfo_2_bits_w_replResp = '0;
    io_msInfo_2_bits_w_rprobeacklast = '0;
    io_msInfo_2_bits_replaceData = '0;
    io_msInfo_2_bits_releaseToClean = '0;
    io_msInfo_3_valid = '0;
    io_msInfo_3_bits_channel = '0;
    io_msInfo_3_bits_set = '0;
    io_msInfo_3_bits_way = '0;
    io_msInfo_3_bits_reqTag = '0;
    io_msInfo_3_bits_willFree = '0;
    io_msInfo_3_bits_aliasTask = '0;
    io_msInfo_3_bits_needRelease = '0;
    io_msInfo_3_bits_blockRefill = '0;
    io_msInfo_3_bits_meta_dirty = '0;
    io_msInfo_3_bits_meta_state = '0;
    io_msInfo_3_bits_meta_clients = '0;
    io_msInfo_3_bits_meta_alias = '0;
    io_msInfo_3_bits_meta_prefetch = '0;
    io_msInfo_3_bits_meta_prefetchSrc = '0;
    io_msInfo_3_bits_meta_accessed = '0;
    io_msInfo_3_bits_meta_tagErr = '0;
    io_msInfo_3_bits_meta_dataErr = '0;
    io_msInfo_3_bits_metaTag = '0;
    io_msInfo_3_bits_dirHit = '0;
    io_msInfo_3_bits_isAcqOrPrefetch = '0;
    io_msInfo_3_bits_isPrefetch = '0;
    io_msInfo_3_bits_param = '0;
    io_msInfo_3_bits_mergeA = '0;
    io_msInfo_3_bits_w_grantfirst = '0;
    io_msInfo_3_bits_s_release = '0;
    io_msInfo_3_bits_s_refill = '0;
    io_msInfo_3_bits_s_cmoresp = '0;
    io_msInfo_3_bits_s_cmometaw = '0;
    io_msInfo_3_bits_w_releaseack = '0;
    io_msInfo_3_bits_w_replResp = '0;
    io_msInfo_3_bits_w_rprobeacklast = '0;
    io_msInfo_3_bits_replaceData = '0;
    io_msInfo_3_bits_releaseToClean = '0;
    io_msInfo_4_valid = '0;
    io_msInfo_4_bits_channel = '0;
    io_msInfo_4_bits_set = '0;
    io_msInfo_4_bits_way = '0;
    io_msInfo_4_bits_reqTag = '0;
    io_msInfo_4_bits_willFree = '0;
    io_msInfo_4_bits_aliasTask = '0;
    io_msInfo_4_bits_needRelease = '0;
    io_msInfo_4_bits_blockRefill = '0;
    io_msInfo_4_bits_meta_dirty = '0;
    io_msInfo_4_bits_meta_state = '0;
    io_msInfo_4_bits_meta_clients = '0;
    io_msInfo_4_bits_meta_alias = '0;
    io_msInfo_4_bits_meta_prefetch = '0;
    io_msInfo_4_bits_meta_prefetchSrc = '0;
    io_msInfo_4_bits_meta_accessed = '0;
    io_msInfo_4_bits_meta_tagErr = '0;
    io_msInfo_4_bits_meta_dataErr = '0;
    io_msInfo_4_bits_metaTag = '0;
    io_msInfo_4_bits_dirHit = '0;
    io_msInfo_4_bits_isAcqOrPrefetch = '0;
    io_msInfo_4_bits_isPrefetch = '0;
    io_msInfo_4_bits_param = '0;
    io_msInfo_4_bits_mergeA = '0;
    io_msInfo_4_bits_w_grantfirst = '0;
    io_msInfo_4_bits_s_release = '0;
    io_msInfo_4_bits_s_refill = '0;
    io_msInfo_4_bits_s_cmoresp = '0;
    io_msInfo_4_bits_s_cmometaw = '0;
    io_msInfo_4_bits_w_releaseack = '0;
    io_msInfo_4_bits_w_replResp = '0;
    io_msInfo_4_bits_w_rprobeacklast = '0;
    io_msInfo_4_bits_replaceData = '0;
    io_msInfo_4_bits_releaseToClean = '0;
    io_msInfo_5_valid = '0;
    io_msInfo_5_bits_channel = '0;
    io_msInfo_5_bits_set = '0;
    io_msInfo_5_bits_way = '0;
    io_msInfo_5_bits_reqTag = '0;
    io_msInfo_5_bits_willFree = '0;
    io_msInfo_5_bits_aliasTask = '0;
    io_msInfo_5_bits_needRelease = '0;
    io_msInfo_5_bits_blockRefill = '0;
    io_msInfo_5_bits_meta_dirty = '0;
    io_msInfo_5_bits_meta_state = '0;
    io_msInfo_5_bits_meta_clients = '0;
    io_msInfo_5_bits_meta_alias = '0;
    io_msInfo_5_bits_meta_prefetch = '0;
    io_msInfo_5_bits_meta_prefetchSrc = '0;
    io_msInfo_5_bits_meta_accessed = '0;
    io_msInfo_5_bits_meta_tagErr = '0;
    io_msInfo_5_bits_meta_dataErr = '0;
    io_msInfo_5_bits_metaTag = '0;
    io_msInfo_5_bits_dirHit = '0;
    io_msInfo_5_bits_isAcqOrPrefetch = '0;
    io_msInfo_5_bits_isPrefetch = '0;
    io_msInfo_5_bits_param = '0;
    io_msInfo_5_bits_mergeA = '0;
    io_msInfo_5_bits_w_grantfirst = '0;
    io_msInfo_5_bits_s_release = '0;
    io_msInfo_5_bits_s_refill = '0;
    io_msInfo_5_bits_s_cmoresp = '0;
    io_msInfo_5_bits_s_cmometaw = '0;
    io_msInfo_5_bits_w_releaseack = '0;
    io_msInfo_5_bits_w_replResp = '0;
    io_msInfo_5_bits_w_rprobeacklast = '0;
    io_msInfo_5_bits_replaceData = '0;
    io_msInfo_5_bits_releaseToClean = '0;
    io_msInfo_6_valid = '0;
    io_msInfo_6_bits_channel = '0;
    io_msInfo_6_bits_set = '0;
    io_msInfo_6_bits_way = '0;
    io_msInfo_6_bits_reqTag = '0;
    io_msInfo_6_bits_willFree = '0;
    io_msInfo_6_bits_aliasTask = '0;
    io_msInfo_6_bits_needRelease = '0;
    io_msInfo_6_bits_blockRefill = '0;
    io_msInfo_6_bits_meta_dirty = '0;
    io_msInfo_6_bits_meta_state = '0;
    io_msInfo_6_bits_meta_clients = '0;
    io_msInfo_6_bits_meta_alias = '0;
    io_msInfo_6_bits_meta_prefetch = '0;
    io_msInfo_6_bits_meta_prefetchSrc = '0;
    io_msInfo_6_bits_meta_accessed = '0;
    io_msInfo_6_bits_meta_tagErr = '0;
    io_msInfo_6_bits_meta_dataErr = '0;
    io_msInfo_6_bits_metaTag = '0;
    io_msInfo_6_bits_dirHit = '0;
    io_msInfo_6_bits_isAcqOrPrefetch = '0;
    io_msInfo_6_bits_isPrefetch = '0;
    io_msInfo_6_bits_param = '0;
    io_msInfo_6_bits_mergeA = '0;
    io_msInfo_6_bits_w_grantfirst = '0;
    io_msInfo_6_bits_s_release = '0;
    io_msInfo_6_bits_s_refill = '0;
    io_msInfo_6_bits_s_cmoresp = '0;
    io_msInfo_6_bits_s_cmometaw = '0;
    io_msInfo_6_bits_w_releaseack = '0;
    io_msInfo_6_bits_w_replResp = '0;
    io_msInfo_6_bits_w_rprobeacklast = '0;
    io_msInfo_6_bits_replaceData = '0;
    io_msInfo_6_bits_releaseToClean = '0;
    io_msInfo_7_valid = '0;
    io_msInfo_7_bits_channel = '0;
    io_msInfo_7_bits_set = '0;
    io_msInfo_7_bits_way = '0;
    io_msInfo_7_bits_reqTag = '0;
    io_msInfo_7_bits_willFree = '0;
    io_msInfo_7_bits_aliasTask = '0;
    io_msInfo_7_bits_needRelease = '0;
    io_msInfo_7_bits_blockRefill = '0;
    io_msInfo_7_bits_meta_dirty = '0;
    io_msInfo_7_bits_meta_state = '0;
    io_msInfo_7_bits_meta_clients = '0;
    io_msInfo_7_bits_meta_alias = '0;
    io_msInfo_7_bits_meta_prefetch = '0;
    io_msInfo_7_bits_meta_prefetchSrc = '0;
    io_msInfo_7_bits_meta_accessed = '0;
    io_msInfo_7_bits_meta_tagErr = '0;
    io_msInfo_7_bits_meta_dataErr = '0;
    io_msInfo_7_bits_metaTag = '0;
    io_msInfo_7_bits_dirHit = '0;
    io_msInfo_7_bits_isAcqOrPrefetch = '0;
    io_msInfo_7_bits_isPrefetch = '0;
    io_msInfo_7_bits_param = '0;
    io_msInfo_7_bits_mergeA = '0;
    io_msInfo_7_bits_w_grantfirst = '0;
    io_msInfo_7_bits_s_release = '0;
    io_msInfo_7_bits_s_refill = '0;
    io_msInfo_7_bits_s_cmoresp = '0;
    io_msInfo_7_bits_s_cmometaw = '0;
    io_msInfo_7_bits_w_releaseack = '0;
    io_msInfo_7_bits_w_replResp = '0;
    io_msInfo_7_bits_w_rprobeacklast = '0;
    io_msInfo_7_bits_replaceData = '0;
    io_msInfo_7_bits_releaseToClean = '0;
    io_msInfo_8_valid = '0;
    io_msInfo_8_bits_channel = '0;
    io_msInfo_8_bits_set = '0;
    io_msInfo_8_bits_way = '0;
    io_msInfo_8_bits_reqTag = '0;
    io_msInfo_8_bits_willFree = '0;
    io_msInfo_8_bits_aliasTask = '0;
    io_msInfo_8_bits_needRelease = '0;
    io_msInfo_8_bits_blockRefill = '0;
    io_msInfo_8_bits_meta_dirty = '0;
    io_msInfo_8_bits_meta_state = '0;
    io_msInfo_8_bits_meta_clients = '0;
    io_msInfo_8_bits_meta_alias = '0;
    io_msInfo_8_bits_meta_prefetch = '0;
    io_msInfo_8_bits_meta_prefetchSrc = '0;
    io_msInfo_8_bits_meta_accessed = '0;
    io_msInfo_8_bits_meta_tagErr = '0;
    io_msInfo_8_bits_meta_dataErr = '0;
    io_msInfo_8_bits_metaTag = '0;
    io_msInfo_8_bits_dirHit = '0;
    io_msInfo_8_bits_isAcqOrPrefetch = '0;
    io_msInfo_8_bits_isPrefetch = '0;
    io_msInfo_8_bits_param = '0;
    io_msInfo_8_bits_mergeA = '0;
    io_msInfo_8_bits_w_grantfirst = '0;
    io_msInfo_8_bits_s_release = '0;
    io_msInfo_8_bits_s_refill = '0;
    io_msInfo_8_bits_s_cmoresp = '0;
    io_msInfo_8_bits_s_cmometaw = '0;
    io_msInfo_8_bits_w_releaseack = '0;
    io_msInfo_8_bits_w_replResp = '0;
    io_msInfo_8_bits_w_rprobeacklast = '0;
    io_msInfo_8_bits_replaceData = '0;
    io_msInfo_8_bits_releaseToClean = '0;
    io_msInfo_9_valid = '0;
    io_msInfo_9_bits_channel = '0;
    io_msInfo_9_bits_set = '0;
    io_msInfo_9_bits_way = '0;
    io_msInfo_9_bits_reqTag = '0;
    io_msInfo_9_bits_willFree = '0;
    io_msInfo_9_bits_aliasTask = '0;
    io_msInfo_9_bits_needRelease = '0;
    io_msInfo_9_bits_blockRefill = '0;
    io_msInfo_9_bits_meta_dirty = '0;
    io_msInfo_9_bits_meta_state = '0;
    io_msInfo_9_bits_meta_clients = '0;
    io_msInfo_9_bits_meta_alias = '0;
    io_msInfo_9_bits_meta_prefetch = '0;
    io_msInfo_9_bits_meta_prefetchSrc = '0;
    io_msInfo_9_bits_meta_accessed = '0;
    io_msInfo_9_bits_meta_tagErr = '0;
    io_msInfo_9_bits_meta_dataErr = '0;
    io_msInfo_9_bits_metaTag = '0;
    io_msInfo_9_bits_dirHit = '0;
    io_msInfo_9_bits_isAcqOrPrefetch = '0;
    io_msInfo_9_bits_isPrefetch = '0;
    io_msInfo_9_bits_param = '0;
    io_msInfo_9_bits_mergeA = '0;
    io_msInfo_9_bits_w_grantfirst = '0;
    io_msInfo_9_bits_s_release = '0;
    io_msInfo_9_bits_s_refill = '0;
    io_msInfo_9_bits_s_cmoresp = '0;
    io_msInfo_9_bits_s_cmometaw = '0;
    io_msInfo_9_bits_w_releaseack = '0;
    io_msInfo_9_bits_w_replResp = '0;
    io_msInfo_9_bits_w_rprobeacklast = '0;
    io_msInfo_9_bits_replaceData = '0;
    io_msInfo_9_bits_releaseToClean = '0;
    io_msInfo_10_valid = '0;
    io_msInfo_10_bits_channel = '0;
    io_msInfo_10_bits_set = '0;
    io_msInfo_10_bits_way = '0;
    io_msInfo_10_bits_reqTag = '0;
    io_msInfo_10_bits_willFree = '0;
    io_msInfo_10_bits_aliasTask = '0;
    io_msInfo_10_bits_needRelease = '0;
    io_msInfo_10_bits_blockRefill = '0;
    io_msInfo_10_bits_meta_dirty = '0;
    io_msInfo_10_bits_meta_state = '0;
    io_msInfo_10_bits_meta_clients = '0;
    io_msInfo_10_bits_meta_alias = '0;
    io_msInfo_10_bits_meta_prefetch = '0;
    io_msInfo_10_bits_meta_prefetchSrc = '0;
    io_msInfo_10_bits_meta_accessed = '0;
    io_msInfo_10_bits_meta_tagErr = '0;
    io_msInfo_10_bits_meta_dataErr = '0;
    io_msInfo_10_bits_metaTag = '0;
    io_msInfo_10_bits_dirHit = '0;
    io_msInfo_10_bits_isAcqOrPrefetch = '0;
    io_msInfo_10_bits_isPrefetch = '0;
    io_msInfo_10_bits_param = '0;
    io_msInfo_10_bits_mergeA = '0;
    io_msInfo_10_bits_w_grantfirst = '0;
    io_msInfo_10_bits_s_release = '0;
    io_msInfo_10_bits_s_refill = '0;
    io_msInfo_10_bits_s_cmoresp = '0;
    io_msInfo_10_bits_s_cmometaw = '0;
    io_msInfo_10_bits_w_releaseack = '0;
    io_msInfo_10_bits_w_replResp = '0;
    io_msInfo_10_bits_w_rprobeacklast = '0;
    io_msInfo_10_bits_replaceData = '0;
    io_msInfo_10_bits_releaseToClean = '0;
    io_msInfo_11_valid = '0;
    io_msInfo_11_bits_channel = '0;
    io_msInfo_11_bits_set = '0;
    io_msInfo_11_bits_way = '0;
    io_msInfo_11_bits_reqTag = '0;
    io_msInfo_11_bits_willFree = '0;
    io_msInfo_11_bits_aliasTask = '0;
    io_msInfo_11_bits_needRelease = '0;
    io_msInfo_11_bits_blockRefill = '0;
    io_msInfo_11_bits_meta_dirty = '0;
    io_msInfo_11_bits_meta_state = '0;
    io_msInfo_11_bits_meta_clients = '0;
    io_msInfo_11_bits_meta_alias = '0;
    io_msInfo_11_bits_meta_prefetch = '0;
    io_msInfo_11_bits_meta_prefetchSrc = '0;
    io_msInfo_11_bits_meta_accessed = '0;
    io_msInfo_11_bits_meta_tagErr = '0;
    io_msInfo_11_bits_meta_dataErr = '0;
    io_msInfo_11_bits_metaTag = '0;
    io_msInfo_11_bits_dirHit = '0;
    io_msInfo_11_bits_isAcqOrPrefetch = '0;
    io_msInfo_11_bits_isPrefetch = '0;
    io_msInfo_11_bits_param = '0;
    io_msInfo_11_bits_mergeA = '0;
    io_msInfo_11_bits_w_grantfirst = '0;
    io_msInfo_11_bits_s_release = '0;
    io_msInfo_11_bits_s_refill = '0;
    io_msInfo_11_bits_s_cmoresp = '0;
    io_msInfo_11_bits_s_cmometaw = '0;
    io_msInfo_11_bits_w_releaseack = '0;
    io_msInfo_11_bits_w_replResp = '0;
    io_msInfo_11_bits_w_rprobeacklast = '0;
    io_msInfo_11_bits_replaceData = '0;
    io_msInfo_11_bits_releaseToClean = '0;
    io_msInfo_12_valid = '0;
    io_msInfo_12_bits_channel = '0;
    io_msInfo_12_bits_set = '0;
    io_msInfo_12_bits_way = '0;
    io_msInfo_12_bits_reqTag = '0;
    io_msInfo_12_bits_willFree = '0;
    io_msInfo_12_bits_aliasTask = '0;
    io_msInfo_12_bits_needRelease = '0;
    io_msInfo_12_bits_blockRefill = '0;
    io_msInfo_12_bits_meta_dirty = '0;
    io_msInfo_12_bits_meta_state = '0;
    io_msInfo_12_bits_meta_clients = '0;
    io_msInfo_12_bits_meta_alias = '0;
    io_msInfo_12_bits_meta_prefetch = '0;
    io_msInfo_12_bits_meta_prefetchSrc = '0;
    io_msInfo_12_bits_meta_accessed = '0;
    io_msInfo_12_bits_meta_tagErr = '0;
    io_msInfo_12_bits_meta_dataErr = '0;
    io_msInfo_12_bits_metaTag = '0;
    io_msInfo_12_bits_dirHit = '0;
    io_msInfo_12_bits_isAcqOrPrefetch = '0;
    io_msInfo_12_bits_isPrefetch = '0;
    io_msInfo_12_bits_param = '0;
    io_msInfo_12_bits_mergeA = '0;
    io_msInfo_12_bits_w_grantfirst = '0;
    io_msInfo_12_bits_s_release = '0;
    io_msInfo_12_bits_s_refill = '0;
    io_msInfo_12_bits_s_cmoresp = '0;
    io_msInfo_12_bits_s_cmometaw = '0;
    io_msInfo_12_bits_w_releaseack = '0;
    io_msInfo_12_bits_w_replResp = '0;
    io_msInfo_12_bits_w_rprobeacklast = '0;
    io_msInfo_12_bits_replaceData = '0;
    io_msInfo_12_bits_releaseToClean = '0;
    io_msInfo_13_valid = '0;
    io_msInfo_13_bits_channel = '0;
    io_msInfo_13_bits_set = '0;
    io_msInfo_13_bits_way = '0;
    io_msInfo_13_bits_reqTag = '0;
    io_msInfo_13_bits_willFree = '0;
    io_msInfo_13_bits_aliasTask = '0;
    io_msInfo_13_bits_needRelease = '0;
    io_msInfo_13_bits_blockRefill = '0;
    io_msInfo_13_bits_meta_dirty = '0;
    io_msInfo_13_bits_meta_state = '0;
    io_msInfo_13_bits_meta_clients = '0;
    io_msInfo_13_bits_meta_alias = '0;
    io_msInfo_13_bits_meta_prefetch = '0;
    io_msInfo_13_bits_meta_prefetchSrc = '0;
    io_msInfo_13_bits_meta_accessed = '0;
    io_msInfo_13_bits_meta_tagErr = '0;
    io_msInfo_13_bits_meta_dataErr = '0;
    io_msInfo_13_bits_metaTag = '0;
    io_msInfo_13_bits_dirHit = '0;
    io_msInfo_13_bits_isAcqOrPrefetch = '0;
    io_msInfo_13_bits_isPrefetch = '0;
    io_msInfo_13_bits_param = '0;
    io_msInfo_13_bits_mergeA = '0;
    io_msInfo_13_bits_w_grantfirst = '0;
    io_msInfo_13_bits_s_release = '0;
    io_msInfo_13_bits_s_refill = '0;
    io_msInfo_13_bits_s_cmoresp = '0;
    io_msInfo_13_bits_s_cmometaw = '0;
    io_msInfo_13_bits_w_releaseack = '0;
    io_msInfo_13_bits_w_replResp = '0;
    io_msInfo_13_bits_w_rprobeacklast = '0;
    io_msInfo_13_bits_replaceData = '0;
    io_msInfo_13_bits_releaseToClean = '0;
    io_msInfo_14_valid = '0;
    io_msInfo_14_bits_channel = '0;
    io_msInfo_14_bits_set = '0;
    io_msInfo_14_bits_way = '0;
    io_msInfo_14_bits_reqTag = '0;
    io_msInfo_14_bits_willFree = '0;
    io_msInfo_14_bits_aliasTask = '0;
    io_msInfo_14_bits_needRelease = '0;
    io_msInfo_14_bits_blockRefill = '0;
    io_msInfo_14_bits_meta_dirty = '0;
    io_msInfo_14_bits_meta_state = '0;
    io_msInfo_14_bits_meta_clients = '0;
    io_msInfo_14_bits_meta_alias = '0;
    io_msInfo_14_bits_meta_prefetch = '0;
    io_msInfo_14_bits_meta_prefetchSrc = '0;
    io_msInfo_14_bits_meta_accessed = '0;
    io_msInfo_14_bits_meta_tagErr = '0;
    io_msInfo_14_bits_meta_dataErr = '0;
    io_msInfo_14_bits_metaTag = '0;
    io_msInfo_14_bits_dirHit = '0;
    io_msInfo_14_bits_isAcqOrPrefetch = '0;
    io_msInfo_14_bits_isPrefetch = '0;
    io_msInfo_14_bits_param = '0;
    io_msInfo_14_bits_mergeA = '0;
    io_msInfo_14_bits_w_grantfirst = '0;
    io_msInfo_14_bits_s_release = '0;
    io_msInfo_14_bits_s_refill = '0;
    io_msInfo_14_bits_s_cmoresp = '0;
    io_msInfo_14_bits_s_cmometaw = '0;
    io_msInfo_14_bits_w_releaseack = '0;
    io_msInfo_14_bits_w_replResp = '0;
    io_msInfo_14_bits_w_rprobeacklast = '0;
    io_msInfo_14_bits_replaceData = '0;
    io_msInfo_14_bits_releaseToClean = '0;
    io_msInfo_15_valid = '0;
    io_msInfo_15_bits_channel = '0;
    io_msInfo_15_bits_set = '0;
    io_msInfo_15_bits_way = '0;
    io_msInfo_15_bits_reqTag = '0;
    io_msInfo_15_bits_willFree = '0;
    io_msInfo_15_bits_aliasTask = '0;
    io_msInfo_15_bits_needRelease = '0;
    io_msInfo_15_bits_blockRefill = '0;
    io_msInfo_15_bits_meta_dirty = '0;
    io_msInfo_15_bits_meta_state = '0;
    io_msInfo_15_bits_meta_clients = '0;
    io_msInfo_15_bits_meta_alias = '0;
    io_msInfo_15_bits_meta_prefetch = '0;
    io_msInfo_15_bits_meta_prefetchSrc = '0;
    io_msInfo_15_bits_meta_accessed = '0;
    io_msInfo_15_bits_meta_tagErr = '0;
    io_msInfo_15_bits_meta_dataErr = '0;
    io_msInfo_15_bits_metaTag = '0;
    io_msInfo_15_bits_dirHit = '0;
    io_msInfo_15_bits_isAcqOrPrefetch = '0;
    io_msInfo_15_bits_isPrefetch = '0;
    io_msInfo_15_bits_param = '0;
    io_msInfo_15_bits_mergeA = '0;
    io_msInfo_15_bits_w_grantfirst = '0;
    io_msInfo_15_bits_s_release = '0;
    io_msInfo_15_bits_s_refill = '0;
    io_msInfo_15_bits_s_cmoresp = '0;
    io_msInfo_15_bits_s_cmometaw = '0;
    io_msInfo_15_bits_w_releaseack = '0;
    io_msInfo_15_bits_w_replResp = '0;
    io_msInfo_15_bits_w_rprobeacklast = '0;
    io_msInfo_15_bits_replaceData = '0;
    io_msInfo_15_bits_releaseToClean = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("RequestArb checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
`undef IP
