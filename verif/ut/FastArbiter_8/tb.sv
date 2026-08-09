// 自动生成：scripts/gen_fastarbiter4.py —— 勿手改
// FastArbiter_8 双例化逐拍比对: golden FastArbiter_8 vs 可读 FastArbiter_8_xs。
// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
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
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_in_0_valid;
  logic [2:0] io_in_0_bits_channel;
  logic [2:0] io_in_0_bits_txChannel;
  logic [8:0] io_in_0_bits_set;
  logic [30:0] io_in_0_bits_tag;
  logic [5:0] io_in_0_bits_off;
  logic [1:0] io_in_0_bits_alias;
  logic io_in_0_bits_isKeyword;
  logic [3:0] io_in_0_bits_opcode;
  logic [2:0] io_in_0_bits_param;
  logic [2:0] io_in_0_bits_size;
  logic [6:0] io_in_0_bits_sourceId;
  logic io_in_0_bits_denied;
  logic io_in_0_bits_corrupt;
  logic [7:0] io_in_0_bits_mshrId;
  logic io_in_0_bits_aliasTask;
  logic io_in_0_bits_useProbeData;
  logic io_in_0_bits_mshrRetry;
  logic io_in_0_bits_readProbeDataDown;
  logic io_in_0_bits_fromL2pft;
  logic io_in_0_bits_dirty;
  logic [2:0] io_in_0_bits_way;
  logic io_in_0_bits_meta_dirty;
  logic [1:0] io_in_0_bits_meta_state;
  logic io_in_0_bits_meta_clients;
  logic [1:0] io_in_0_bits_meta_alias;
  logic io_in_0_bits_meta_prefetch;
  logic [2:0] io_in_0_bits_meta_prefetchSrc;
  logic io_in_0_bits_meta_accessed;
  logic io_in_0_bits_meta_tagErr;
  logic io_in_0_bits_meta_dataErr;
  logic io_in_0_bits_metaWen;
  logic io_in_0_bits_tagWen;
  logic io_in_0_bits_dsWen;
  logic io_in_0_bits_replTask;
  logic io_in_0_bits_cmoTask;
  logic [4:0] io_in_0_bits_reqSource;
  logic io_in_0_bits_mergeA;
  logic [5:0] io_in_0_bits_aMergeTask_off;
  logic [1:0] io_in_0_bits_aMergeTask_alias;
  logic [43:0] io_in_0_bits_aMergeTask_vaddr;
  logic io_in_0_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_0_bits_aMergeTask_opcode;
  logic [2:0] io_in_0_bits_aMergeTask_param;
  logic [6:0] io_in_0_bits_aMergeTask_sourceId;
  logic io_in_0_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_0_bits_aMergeTask_meta_state;
  logic io_in_0_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_0_bits_aMergeTask_meta_alias;
  logic io_in_0_bits_aMergeTask_meta_accessed;
  logic io_in_0_bits_snpHitRelease;
  logic io_in_0_bits_snpHitReleaseToInval;
  logic io_in_0_bits_snpHitReleaseToClean;
  logic io_in_0_bits_snpHitReleaseWithData;
  logic [7:0] io_in_0_bits_snpHitReleaseIdx;
  logic io_in_0_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_0_bits_snpHitReleaseMeta_state;
  logic io_in_0_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_0_bits_snpHitReleaseMeta_alias;
  logic io_in_0_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_0_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_0_bits_snpHitReleaseMeta_accessed;
  logic io_in_0_bits_snpHitReleaseMeta_tagErr;
  logic io_in_0_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_0_bits_tgtID;
  logic [11:0] io_in_0_bits_txnID;
  logic [10:0] io_in_0_bits_homeNID;
  logic [11:0] io_in_0_bits_dbID;
  logic [6:0] io_in_0_bits_chiOpcode;
  logic [2:0] io_in_0_bits_resp;
  logic [2:0] io_in_0_bits_fwdState;
  logic io_in_0_bits_retToSrc;
  logic io_in_0_bits_likelyshared;
  logic io_in_0_bits_expCompAck;
  logic io_in_0_bits_allowRetry;
  logic io_in_0_bits_memAttr_allocate;
  logic io_in_0_bits_memAttr_cacheable;
  logic io_in_0_bits_memAttr_ewa;
  logic io_in_0_bits_traceTag;
  logic io_in_0_bits_dataCheckErr;
  logic io_in_1_valid;
  logic [2:0] io_in_1_bits_channel;
  logic [2:0] io_in_1_bits_txChannel;
  logic [8:0] io_in_1_bits_set;
  logic [30:0] io_in_1_bits_tag;
  logic [5:0] io_in_1_bits_off;
  logic [1:0] io_in_1_bits_alias;
  logic io_in_1_bits_isKeyword;
  logic [3:0] io_in_1_bits_opcode;
  logic [2:0] io_in_1_bits_param;
  logic [2:0] io_in_1_bits_size;
  logic [6:0] io_in_1_bits_sourceId;
  logic io_in_1_bits_denied;
  logic io_in_1_bits_corrupt;
  logic [7:0] io_in_1_bits_mshrId;
  logic io_in_1_bits_aliasTask;
  logic io_in_1_bits_useProbeData;
  logic io_in_1_bits_mshrRetry;
  logic io_in_1_bits_readProbeDataDown;
  logic io_in_1_bits_fromL2pft;
  logic io_in_1_bits_dirty;
  logic [2:0] io_in_1_bits_way;
  logic io_in_1_bits_meta_dirty;
  logic [1:0] io_in_1_bits_meta_state;
  logic io_in_1_bits_meta_clients;
  logic [1:0] io_in_1_bits_meta_alias;
  logic io_in_1_bits_meta_prefetch;
  logic [2:0] io_in_1_bits_meta_prefetchSrc;
  logic io_in_1_bits_meta_accessed;
  logic io_in_1_bits_meta_tagErr;
  logic io_in_1_bits_meta_dataErr;
  logic io_in_1_bits_metaWen;
  logic io_in_1_bits_tagWen;
  logic io_in_1_bits_dsWen;
  logic io_in_1_bits_replTask;
  logic io_in_1_bits_cmoTask;
  logic [4:0] io_in_1_bits_reqSource;
  logic io_in_1_bits_mergeA;
  logic [5:0] io_in_1_bits_aMergeTask_off;
  logic [1:0] io_in_1_bits_aMergeTask_alias;
  logic [43:0] io_in_1_bits_aMergeTask_vaddr;
  logic io_in_1_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_1_bits_aMergeTask_opcode;
  logic [2:0] io_in_1_bits_aMergeTask_param;
  logic [6:0] io_in_1_bits_aMergeTask_sourceId;
  logic io_in_1_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_1_bits_aMergeTask_meta_state;
  logic io_in_1_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_1_bits_aMergeTask_meta_alias;
  logic io_in_1_bits_aMergeTask_meta_accessed;
  logic io_in_1_bits_snpHitRelease;
  logic io_in_1_bits_snpHitReleaseToInval;
  logic io_in_1_bits_snpHitReleaseToClean;
  logic io_in_1_bits_snpHitReleaseWithData;
  logic [7:0] io_in_1_bits_snpHitReleaseIdx;
  logic io_in_1_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_1_bits_snpHitReleaseMeta_state;
  logic io_in_1_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_1_bits_snpHitReleaseMeta_alias;
  logic io_in_1_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_1_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_1_bits_snpHitReleaseMeta_accessed;
  logic io_in_1_bits_snpHitReleaseMeta_tagErr;
  logic io_in_1_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_1_bits_tgtID;
  logic [11:0] io_in_1_bits_txnID;
  logic [10:0] io_in_1_bits_homeNID;
  logic [11:0] io_in_1_bits_dbID;
  logic [6:0] io_in_1_bits_chiOpcode;
  logic [2:0] io_in_1_bits_resp;
  logic [2:0] io_in_1_bits_fwdState;
  logic io_in_1_bits_retToSrc;
  logic io_in_1_bits_likelyshared;
  logic io_in_1_bits_expCompAck;
  logic io_in_1_bits_allowRetry;
  logic io_in_1_bits_memAttr_allocate;
  logic io_in_1_bits_memAttr_cacheable;
  logic io_in_1_bits_memAttr_ewa;
  logic io_in_1_bits_traceTag;
  logic io_in_1_bits_dataCheckErr;
  logic io_in_2_valid;
  logic [2:0] io_in_2_bits_channel;
  logic [2:0] io_in_2_bits_txChannel;
  logic [8:0] io_in_2_bits_set;
  logic [30:0] io_in_2_bits_tag;
  logic [5:0] io_in_2_bits_off;
  logic [1:0] io_in_2_bits_alias;
  logic io_in_2_bits_isKeyword;
  logic [3:0] io_in_2_bits_opcode;
  logic [2:0] io_in_2_bits_param;
  logic [2:0] io_in_2_bits_size;
  logic [6:0] io_in_2_bits_sourceId;
  logic io_in_2_bits_denied;
  logic io_in_2_bits_corrupt;
  logic [7:0] io_in_2_bits_mshrId;
  logic io_in_2_bits_aliasTask;
  logic io_in_2_bits_useProbeData;
  logic io_in_2_bits_mshrRetry;
  logic io_in_2_bits_readProbeDataDown;
  logic io_in_2_bits_fromL2pft;
  logic io_in_2_bits_dirty;
  logic [2:0] io_in_2_bits_way;
  logic io_in_2_bits_meta_dirty;
  logic [1:0] io_in_2_bits_meta_state;
  logic io_in_2_bits_meta_clients;
  logic [1:0] io_in_2_bits_meta_alias;
  logic io_in_2_bits_meta_prefetch;
  logic [2:0] io_in_2_bits_meta_prefetchSrc;
  logic io_in_2_bits_meta_accessed;
  logic io_in_2_bits_meta_tagErr;
  logic io_in_2_bits_meta_dataErr;
  logic io_in_2_bits_metaWen;
  logic io_in_2_bits_tagWen;
  logic io_in_2_bits_dsWen;
  logic io_in_2_bits_replTask;
  logic io_in_2_bits_cmoTask;
  logic [4:0] io_in_2_bits_reqSource;
  logic io_in_2_bits_mergeA;
  logic [5:0] io_in_2_bits_aMergeTask_off;
  logic [1:0] io_in_2_bits_aMergeTask_alias;
  logic [43:0] io_in_2_bits_aMergeTask_vaddr;
  logic io_in_2_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_2_bits_aMergeTask_opcode;
  logic [2:0] io_in_2_bits_aMergeTask_param;
  logic [6:0] io_in_2_bits_aMergeTask_sourceId;
  logic io_in_2_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_2_bits_aMergeTask_meta_state;
  logic io_in_2_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_2_bits_aMergeTask_meta_alias;
  logic io_in_2_bits_aMergeTask_meta_accessed;
  logic io_in_2_bits_snpHitRelease;
  logic io_in_2_bits_snpHitReleaseToInval;
  logic io_in_2_bits_snpHitReleaseToClean;
  logic io_in_2_bits_snpHitReleaseWithData;
  logic [7:0] io_in_2_bits_snpHitReleaseIdx;
  logic io_in_2_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_2_bits_snpHitReleaseMeta_state;
  logic io_in_2_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_2_bits_snpHitReleaseMeta_alias;
  logic io_in_2_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_2_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_2_bits_snpHitReleaseMeta_accessed;
  logic io_in_2_bits_snpHitReleaseMeta_tagErr;
  logic io_in_2_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_2_bits_tgtID;
  logic [11:0] io_in_2_bits_txnID;
  logic [10:0] io_in_2_bits_homeNID;
  logic [11:0] io_in_2_bits_dbID;
  logic [6:0] io_in_2_bits_chiOpcode;
  logic [2:0] io_in_2_bits_resp;
  logic [2:0] io_in_2_bits_fwdState;
  logic io_in_2_bits_retToSrc;
  logic io_in_2_bits_likelyshared;
  logic io_in_2_bits_expCompAck;
  logic io_in_2_bits_allowRetry;
  logic io_in_2_bits_memAttr_allocate;
  logic io_in_2_bits_memAttr_cacheable;
  logic io_in_2_bits_memAttr_ewa;
  logic io_in_2_bits_traceTag;
  logic io_in_2_bits_dataCheckErr;
  logic io_in_3_valid;
  logic [2:0] io_in_3_bits_channel;
  logic [2:0] io_in_3_bits_txChannel;
  logic [8:0] io_in_3_bits_set;
  logic [30:0] io_in_3_bits_tag;
  logic [5:0] io_in_3_bits_off;
  logic [1:0] io_in_3_bits_alias;
  logic io_in_3_bits_isKeyword;
  logic [3:0] io_in_3_bits_opcode;
  logic [2:0] io_in_3_bits_param;
  logic [2:0] io_in_3_bits_size;
  logic [6:0] io_in_3_bits_sourceId;
  logic io_in_3_bits_denied;
  logic io_in_3_bits_corrupt;
  logic [7:0] io_in_3_bits_mshrId;
  logic io_in_3_bits_aliasTask;
  logic io_in_3_bits_useProbeData;
  logic io_in_3_bits_mshrRetry;
  logic io_in_3_bits_readProbeDataDown;
  logic io_in_3_bits_fromL2pft;
  logic io_in_3_bits_dirty;
  logic [2:0] io_in_3_bits_way;
  logic io_in_3_bits_meta_dirty;
  logic [1:0] io_in_3_bits_meta_state;
  logic io_in_3_bits_meta_clients;
  logic [1:0] io_in_3_bits_meta_alias;
  logic io_in_3_bits_meta_prefetch;
  logic [2:0] io_in_3_bits_meta_prefetchSrc;
  logic io_in_3_bits_meta_accessed;
  logic io_in_3_bits_meta_tagErr;
  logic io_in_3_bits_meta_dataErr;
  logic io_in_3_bits_metaWen;
  logic io_in_3_bits_tagWen;
  logic io_in_3_bits_dsWen;
  logic io_in_3_bits_replTask;
  logic io_in_3_bits_cmoTask;
  logic [4:0] io_in_3_bits_reqSource;
  logic io_in_3_bits_mergeA;
  logic [5:0] io_in_3_bits_aMergeTask_off;
  logic [1:0] io_in_3_bits_aMergeTask_alias;
  logic [43:0] io_in_3_bits_aMergeTask_vaddr;
  logic io_in_3_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_3_bits_aMergeTask_opcode;
  logic [2:0] io_in_3_bits_aMergeTask_param;
  logic [6:0] io_in_3_bits_aMergeTask_sourceId;
  logic io_in_3_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_3_bits_aMergeTask_meta_state;
  logic io_in_3_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_3_bits_aMergeTask_meta_alias;
  logic io_in_3_bits_aMergeTask_meta_accessed;
  logic io_in_3_bits_snpHitRelease;
  logic io_in_3_bits_snpHitReleaseToInval;
  logic io_in_3_bits_snpHitReleaseToClean;
  logic io_in_3_bits_snpHitReleaseWithData;
  logic [7:0] io_in_3_bits_snpHitReleaseIdx;
  logic io_in_3_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_3_bits_snpHitReleaseMeta_state;
  logic io_in_3_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_3_bits_snpHitReleaseMeta_alias;
  logic io_in_3_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_3_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_3_bits_snpHitReleaseMeta_accessed;
  logic io_in_3_bits_snpHitReleaseMeta_tagErr;
  logic io_in_3_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_3_bits_tgtID;
  logic [11:0] io_in_3_bits_txnID;
  logic [10:0] io_in_3_bits_homeNID;
  logic [11:0] io_in_3_bits_dbID;
  logic [6:0] io_in_3_bits_chiOpcode;
  logic [2:0] io_in_3_bits_resp;
  logic [2:0] io_in_3_bits_fwdState;
  logic io_in_3_bits_retToSrc;
  logic io_in_3_bits_likelyshared;
  logic io_in_3_bits_expCompAck;
  logic io_in_3_bits_allowRetry;
  logic io_in_3_bits_memAttr_allocate;
  logic io_in_3_bits_memAttr_cacheable;
  logic io_in_3_bits_memAttr_ewa;
  logic io_in_3_bits_traceTag;
  logic io_in_3_bits_dataCheckErr;
  logic io_in_4_valid;
  logic [2:0] io_in_4_bits_channel;
  logic [2:0] io_in_4_bits_txChannel;
  logic [8:0] io_in_4_bits_set;
  logic [30:0] io_in_4_bits_tag;
  logic [5:0] io_in_4_bits_off;
  logic [1:0] io_in_4_bits_alias;
  logic io_in_4_bits_isKeyword;
  logic [3:0] io_in_4_bits_opcode;
  logic [2:0] io_in_4_bits_param;
  logic [2:0] io_in_4_bits_size;
  logic [6:0] io_in_4_bits_sourceId;
  logic io_in_4_bits_denied;
  logic io_in_4_bits_corrupt;
  logic [7:0] io_in_4_bits_mshrId;
  logic io_in_4_bits_aliasTask;
  logic io_in_4_bits_useProbeData;
  logic io_in_4_bits_mshrRetry;
  logic io_in_4_bits_readProbeDataDown;
  logic io_in_4_bits_fromL2pft;
  logic io_in_4_bits_dirty;
  logic [2:0] io_in_4_bits_way;
  logic io_in_4_bits_meta_dirty;
  logic [1:0] io_in_4_bits_meta_state;
  logic io_in_4_bits_meta_clients;
  logic [1:0] io_in_4_bits_meta_alias;
  logic io_in_4_bits_meta_prefetch;
  logic [2:0] io_in_4_bits_meta_prefetchSrc;
  logic io_in_4_bits_meta_accessed;
  logic io_in_4_bits_meta_tagErr;
  logic io_in_4_bits_meta_dataErr;
  logic io_in_4_bits_metaWen;
  logic io_in_4_bits_tagWen;
  logic io_in_4_bits_dsWen;
  logic io_in_4_bits_replTask;
  logic io_in_4_bits_cmoTask;
  logic [4:0] io_in_4_bits_reqSource;
  logic io_in_4_bits_mergeA;
  logic [5:0] io_in_4_bits_aMergeTask_off;
  logic [1:0] io_in_4_bits_aMergeTask_alias;
  logic [43:0] io_in_4_bits_aMergeTask_vaddr;
  logic io_in_4_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_4_bits_aMergeTask_opcode;
  logic [2:0] io_in_4_bits_aMergeTask_param;
  logic [6:0] io_in_4_bits_aMergeTask_sourceId;
  logic io_in_4_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_4_bits_aMergeTask_meta_state;
  logic io_in_4_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_4_bits_aMergeTask_meta_alias;
  logic io_in_4_bits_aMergeTask_meta_accessed;
  logic io_in_4_bits_snpHitRelease;
  logic io_in_4_bits_snpHitReleaseToInval;
  logic io_in_4_bits_snpHitReleaseToClean;
  logic io_in_4_bits_snpHitReleaseWithData;
  logic [7:0] io_in_4_bits_snpHitReleaseIdx;
  logic io_in_4_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_4_bits_snpHitReleaseMeta_state;
  logic io_in_4_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_4_bits_snpHitReleaseMeta_alias;
  logic io_in_4_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_4_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_4_bits_snpHitReleaseMeta_accessed;
  logic io_in_4_bits_snpHitReleaseMeta_tagErr;
  logic io_in_4_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_4_bits_tgtID;
  logic [11:0] io_in_4_bits_txnID;
  logic [10:0] io_in_4_bits_homeNID;
  logic [11:0] io_in_4_bits_dbID;
  logic [6:0] io_in_4_bits_chiOpcode;
  logic [2:0] io_in_4_bits_resp;
  logic [2:0] io_in_4_bits_fwdState;
  logic io_in_4_bits_retToSrc;
  logic io_in_4_bits_likelyshared;
  logic io_in_4_bits_expCompAck;
  logic io_in_4_bits_allowRetry;
  logic io_in_4_bits_memAttr_allocate;
  logic io_in_4_bits_memAttr_cacheable;
  logic io_in_4_bits_memAttr_ewa;
  logic io_in_4_bits_traceTag;
  logic io_in_4_bits_dataCheckErr;
  logic io_in_5_valid;
  logic [2:0] io_in_5_bits_channel;
  logic [2:0] io_in_5_bits_txChannel;
  logic [8:0] io_in_5_bits_set;
  logic [30:0] io_in_5_bits_tag;
  logic [5:0] io_in_5_bits_off;
  logic [1:0] io_in_5_bits_alias;
  logic io_in_5_bits_isKeyword;
  logic [3:0] io_in_5_bits_opcode;
  logic [2:0] io_in_5_bits_param;
  logic [2:0] io_in_5_bits_size;
  logic [6:0] io_in_5_bits_sourceId;
  logic io_in_5_bits_denied;
  logic io_in_5_bits_corrupt;
  logic [7:0] io_in_5_bits_mshrId;
  logic io_in_5_bits_aliasTask;
  logic io_in_5_bits_useProbeData;
  logic io_in_5_bits_mshrRetry;
  logic io_in_5_bits_readProbeDataDown;
  logic io_in_5_bits_fromL2pft;
  logic io_in_5_bits_dirty;
  logic [2:0] io_in_5_bits_way;
  logic io_in_5_bits_meta_dirty;
  logic [1:0] io_in_5_bits_meta_state;
  logic io_in_5_bits_meta_clients;
  logic [1:0] io_in_5_bits_meta_alias;
  logic io_in_5_bits_meta_prefetch;
  logic [2:0] io_in_5_bits_meta_prefetchSrc;
  logic io_in_5_bits_meta_accessed;
  logic io_in_5_bits_meta_tagErr;
  logic io_in_5_bits_meta_dataErr;
  logic io_in_5_bits_metaWen;
  logic io_in_5_bits_tagWen;
  logic io_in_5_bits_dsWen;
  logic io_in_5_bits_replTask;
  logic io_in_5_bits_cmoTask;
  logic [4:0] io_in_5_bits_reqSource;
  logic io_in_5_bits_mergeA;
  logic [5:0] io_in_5_bits_aMergeTask_off;
  logic [1:0] io_in_5_bits_aMergeTask_alias;
  logic [43:0] io_in_5_bits_aMergeTask_vaddr;
  logic io_in_5_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_5_bits_aMergeTask_opcode;
  logic [2:0] io_in_5_bits_aMergeTask_param;
  logic [6:0] io_in_5_bits_aMergeTask_sourceId;
  logic io_in_5_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_5_bits_aMergeTask_meta_state;
  logic io_in_5_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_5_bits_aMergeTask_meta_alias;
  logic io_in_5_bits_aMergeTask_meta_accessed;
  logic io_in_5_bits_snpHitRelease;
  logic io_in_5_bits_snpHitReleaseToInval;
  logic io_in_5_bits_snpHitReleaseToClean;
  logic io_in_5_bits_snpHitReleaseWithData;
  logic [7:0] io_in_5_bits_snpHitReleaseIdx;
  logic io_in_5_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_5_bits_snpHitReleaseMeta_state;
  logic io_in_5_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_5_bits_snpHitReleaseMeta_alias;
  logic io_in_5_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_5_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_5_bits_snpHitReleaseMeta_accessed;
  logic io_in_5_bits_snpHitReleaseMeta_tagErr;
  logic io_in_5_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_5_bits_tgtID;
  logic [11:0] io_in_5_bits_txnID;
  logic [10:0] io_in_5_bits_homeNID;
  logic [11:0] io_in_5_bits_dbID;
  logic [6:0] io_in_5_bits_chiOpcode;
  logic [2:0] io_in_5_bits_resp;
  logic [2:0] io_in_5_bits_fwdState;
  logic io_in_5_bits_retToSrc;
  logic io_in_5_bits_likelyshared;
  logic io_in_5_bits_expCompAck;
  logic io_in_5_bits_allowRetry;
  logic io_in_5_bits_memAttr_allocate;
  logic io_in_5_bits_memAttr_cacheable;
  logic io_in_5_bits_memAttr_ewa;
  logic io_in_5_bits_traceTag;
  logic io_in_5_bits_dataCheckErr;
  logic io_in_6_valid;
  logic [2:0] io_in_6_bits_channel;
  logic [2:0] io_in_6_bits_txChannel;
  logic [8:0] io_in_6_bits_set;
  logic [30:0] io_in_6_bits_tag;
  logic [5:0] io_in_6_bits_off;
  logic [1:0] io_in_6_bits_alias;
  logic io_in_6_bits_isKeyword;
  logic [3:0] io_in_6_bits_opcode;
  logic [2:0] io_in_6_bits_param;
  logic [2:0] io_in_6_bits_size;
  logic [6:0] io_in_6_bits_sourceId;
  logic io_in_6_bits_denied;
  logic io_in_6_bits_corrupt;
  logic [7:0] io_in_6_bits_mshrId;
  logic io_in_6_bits_aliasTask;
  logic io_in_6_bits_useProbeData;
  logic io_in_6_bits_mshrRetry;
  logic io_in_6_bits_readProbeDataDown;
  logic io_in_6_bits_fromL2pft;
  logic io_in_6_bits_dirty;
  logic [2:0] io_in_6_bits_way;
  logic io_in_6_bits_meta_dirty;
  logic [1:0] io_in_6_bits_meta_state;
  logic io_in_6_bits_meta_clients;
  logic [1:0] io_in_6_bits_meta_alias;
  logic io_in_6_bits_meta_prefetch;
  logic [2:0] io_in_6_bits_meta_prefetchSrc;
  logic io_in_6_bits_meta_accessed;
  logic io_in_6_bits_meta_tagErr;
  logic io_in_6_bits_meta_dataErr;
  logic io_in_6_bits_metaWen;
  logic io_in_6_bits_tagWen;
  logic io_in_6_bits_dsWen;
  logic io_in_6_bits_replTask;
  logic io_in_6_bits_cmoTask;
  logic [4:0] io_in_6_bits_reqSource;
  logic io_in_6_bits_mergeA;
  logic [5:0] io_in_6_bits_aMergeTask_off;
  logic [1:0] io_in_6_bits_aMergeTask_alias;
  logic [43:0] io_in_6_bits_aMergeTask_vaddr;
  logic io_in_6_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_6_bits_aMergeTask_opcode;
  logic [2:0] io_in_6_bits_aMergeTask_param;
  logic [6:0] io_in_6_bits_aMergeTask_sourceId;
  logic io_in_6_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_6_bits_aMergeTask_meta_state;
  logic io_in_6_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_6_bits_aMergeTask_meta_alias;
  logic io_in_6_bits_aMergeTask_meta_accessed;
  logic io_in_6_bits_snpHitRelease;
  logic io_in_6_bits_snpHitReleaseToInval;
  logic io_in_6_bits_snpHitReleaseToClean;
  logic io_in_6_bits_snpHitReleaseWithData;
  logic [7:0] io_in_6_bits_snpHitReleaseIdx;
  logic io_in_6_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_6_bits_snpHitReleaseMeta_state;
  logic io_in_6_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_6_bits_snpHitReleaseMeta_alias;
  logic io_in_6_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_6_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_6_bits_snpHitReleaseMeta_accessed;
  logic io_in_6_bits_snpHitReleaseMeta_tagErr;
  logic io_in_6_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_6_bits_tgtID;
  logic [11:0] io_in_6_bits_txnID;
  logic [10:0] io_in_6_bits_homeNID;
  logic [11:0] io_in_6_bits_dbID;
  logic [6:0] io_in_6_bits_chiOpcode;
  logic [2:0] io_in_6_bits_resp;
  logic [2:0] io_in_6_bits_fwdState;
  logic io_in_6_bits_retToSrc;
  logic io_in_6_bits_likelyshared;
  logic io_in_6_bits_expCompAck;
  logic io_in_6_bits_allowRetry;
  logic io_in_6_bits_memAttr_allocate;
  logic io_in_6_bits_memAttr_cacheable;
  logic io_in_6_bits_memAttr_ewa;
  logic io_in_6_bits_traceTag;
  logic io_in_6_bits_dataCheckErr;
  logic io_in_7_valid;
  logic [2:0] io_in_7_bits_channel;
  logic [2:0] io_in_7_bits_txChannel;
  logic [8:0] io_in_7_bits_set;
  logic [30:0] io_in_7_bits_tag;
  logic [5:0] io_in_7_bits_off;
  logic [1:0] io_in_7_bits_alias;
  logic io_in_7_bits_isKeyword;
  logic [3:0] io_in_7_bits_opcode;
  logic [2:0] io_in_7_bits_param;
  logic [2:0] io_in_7_bits_size;
  logic [6:0] io_in_7_bits_sourceId;
  logic io_in_7_bits_denied;
  logic io_in_7_bits_corrupt;
  logic [7:0] io_in_7_bits_mshrId;
  logic io_in_7_bits_aliasTask;
  logic io_in_7_bits_useProbeData;
  logic io_in_7_bits_mshrRetry;
  logic io_in_7_bits_readProbeDataDown;
  logic io_in_7_bits_fromL2pft;
  logic io_in_7_bits_dirty;
  logic [2:0] io_in_7_bits_way;
  logic io_in_7_bits_meta_dirty;
  logic [1:0] io_in_7_bits_meta_state;
  logic io_in_7_bits_meta_clients;
  logic [1:0] io_in_7_bits_meta_alias;
  logic io_in_7_bits_meta_prefetch;
  logic [2:0] io_in_7_bits_meta_prefetchSrc;
  logic io_in_7_bits_meta_accessed;
  logic io_in_7_bits_meta_tagErr;
  logic io_in_7_bits_meta_dataErr;
  logic io_in_7_bits_metaWen;
  logic io_in_7_bits_tagWen;
  logic io_in_7_bits_dsWen;
  logic io_in_7_bits_replTask;
  logic io_in_7_bits_cmoTask;
  logic [4:0] io_in_7_bits_reqSource;
  logic io_in_7_bits_mergeA;
  logic [5:0] io_in_7_bits_aMergeTask_off;
  logic [1:0] io_in_7_bits_aMergeTask_alias;
  logic [43:0] io_in_7_bits_aMergeTask_vaddr;
  logic io_in_7_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_7_bits_aMergeTask_opcode;
  logic [2:0] io_in_7_bits_aMergeTask_param;
  logic [6:0] io_in_7_bits_aMergeTask_sourceId;
  logic io_in_7_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_7_bits_aMergeTask_meta_state;
  logic io_in_7_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_7_bits_aMergeTask_meta_alias;
  logic io_in_7_bits_aMergeTask_meta_accessed;
  logic io_in_7_bits_snpHitRelease;
  logic io_in_7_bits_snpHitReleaseToInval;
  logic io_in_7_bits_snpHitReleaseToClean;
  logic io_in_7_bits_snpHitReleaseWithData;
  logic [7:0] io_in_7_bits_snpHitReleaseIdx;
  logic io_in_7_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_7_bits_snpHitReleaseMeta_state;
  logic io_in_7_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_7_bits_snpHitReleaseMeta_alias;
  logic io_in_7_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_7_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_7_bits_snpHitReleaseMeta_accessed;
  logic io_in_7_bits_snpHitReleaseMeta_tagErr;
  logic io_in_7_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_7_bits_tgtID;
  logic [11:0] io_in_7_bits_txnID;
  logic [10:0] io_in_7_bits_homeNID;
  logic [11:0] io_in_7_bits_dbID;
  logic [6:0] io_in_7_bits_chiOpcode;
  logic [2:0] io_in_7_bits_resp;
  logic [2:0] io_in_7_bits_fwdState;
  logic io_in_7_bits_retToSrc;
  logic io_in_7_bits_likelyshared;
  logic io_in_7_bits_expCompAck;
  logic io_in_7_bits_allowRetry;
  logic io_in_7_bits_memAttr_allocate;
  logic io_in_7_bits_memAttr_cacheable;
  logic io_in_7_bits_memAttr_ewa;
  logic io_in_7_bits_traceTag;
  logic io_in_7_bits_dataCheckErr;
  logic io_in_8_valid;
  logic [2:0] io_in_8_bits_channel;
  logic [2:0] io_in_8_bits_txChannel;
  logic [8:0] io_in_8_bits_set;
  logic [30:0] io_in_8_bits_tag;
  logic [5:0] io_in_8_bits_off;
  logic [1:0] io_in_8_bits_alias;
  logic io_in_8_bits_isKeyword;
  logic [3:0] io_in_8_bits_opcode;
  logic [2:0] io_in_8_bits_param;
  logic [2:0] io_in_8_bits_size;
  logic [6:0] io_in_8_bits_sourceId;
  logic io_in_8_bits_denied;
  logic io_in_8_bits_corrupt;
  logic [7:0] io_in_8_bits_mshrId;
  logic io_in_8_bits_aliasTask;
  logic io_in_8_bits_useProbeData;
  logic io_in_8_bits_mshrRetry;
  logic io_in_8_bits_readProbeDataDown;
  logic io_in_8_bits_fromL2pft;
  logic io_in_8_bits_dirty;
  logic [2:0] io_in_8_bits_way;
  logic io_in_8_bits_meta_dirty;
  logic [1:0] io_in_8_bits_meta_state;
  logic io_in_8_bits_meta_clients;
  logic [1:0] io_in_8_bits_meta_alias;
  logic io_in_8_bits_meta_prefetch;
  logic [2:0] io_in_8_bits_meta_prefetchSrc;
  logic io_in_8_bits_meta_accessed;
  logic io_in_8_bits_meta_tagErr;
  logic io_in_8_bits_meta_dataErr;
  logic io_in_8_bits_metaWen;
  logic io_in_8_bits_tagWen;
  logic io_in_8_bits_dsWen;
  logic io_in_8_bits_replTask;
  logic io_in_8_bits_cmoTask;
  logic [4:0] io_in_8_bits_reqSource;
  logic io_in_8_bits_mergeA;
  logic [5:0] io_in_8_bits_aMergeTask_off;
  logic [1:0] io_in_8_bits_aMergeTask_alias;
  logic [43:0] io_in_8_bits_aMergeTask_vaddr;
  logic io_in_8_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_8_bits_aMergeTask_opcode;
  logic [2:0] io_in_8_bits_aMergeTask_param;
  logic [6:0] io_in_8_bits_aMergeTask_sourceId;
  logic io_in_8_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_8_bits_aMergeTask_meta_state;
  logic io_in_8_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_8_bits_aMergeTask_meta_alias;
  logic io_in_8_bits_aMergeTask_meta_accessed;
  logic io_in_8_bits_snpHitRelease;
  logic io_in_8_bits_snpHitReleaseToInval;
  logic io_in_8_bits_snpHitReleaseToClean;
  logic io_in_8_bits_snpHitReleaseWithData;
  logic [7:0] io_in_8_bits_snpHitReleaseIdx;
  logic io_in_8_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_8_bits_snpHitReleaseMeta_state;
  logic io_in_8_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_8_bits_snpHitReleaseMeta_alias;
  logic io_in_8_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_8_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_8_bits_snpHitReleaseMeta_accessed;
  logic io_in_8_bits_snpHitReleaseMeta_tagErr;
  logic io_in_8_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_8_bits_tgtID;
  logic [11:0] io_in_8_bits_txnID;
  logic [10:0] io_in_8_bits_homeNID;
  logic [11:0] io_in_8_bits_dbID;
  logic [6:0] io_in_8_bits_chiOpcode;
  logic [2:0] io_in_8_bits_resp;
  logic [2:0] io_in_8_bits_fwdState;
  logic io_in_8_bits_retToSrc;
  logic io_in_8_bits_likelyshared;
  logic io_in_8_bits_expCompAck;
  logic io_in_8_bits_allowRetry;
  logic io_in_8_bits_memAttr_allocate;
  logic io_in_8_bits_memAttr_cacheable;
  logic io_in_8_bits_memAttr_ewa;
  logic io_in_8_bits_traceTag;
  logic io_in_8_bits_dataCheckErr;
  logic io_in_9_valid;
  logic [2:0] io_in_9_bits_channel;
  logic [2:0] io_in_9_bits_txChannel;
  logic [8:0] io_in_9_bits_set;
  logic [30:0] io_in_9_bits_tag;
  logic [5:0] io_in_9_bits_off;
  logic [1:0] io_in_9_bits_alias;
  logic io_in_9_bits_isKeyword;
  logic [3:0] io_in_9_bits_opcode;
  logic [2:0] io_in_9_bits_param;
  logic [2:0] io_in_9_bits_size;
  logic [6:0] io_in_9_bits_sourceId;
  logic io_in_9_bits_denied;
  logic io_in_9_bits_corrupt;
  logic [7:0] io_in_9_bits_mshrId;
  logic io_in_9_bits_aliasTask;
  logic io_in_9_bits_useProbeData;
  logic io_in_9_bits_mshrRetry;
  logic io_in_9_bits_readProbeDataDown;
  logic io_in_9_bits_fromL2pft;
  logic io_in_9_bits_dirty;
  logic [2:0] io_in_9_bits_way;
  logic io_in_9_bits_meta_dirty;
  logic [1:0] io_in_9_bits_meta_state;
  logic io_in_9_bits_meta_clients;
  logic [1:0] io_in_9_bits_meta_alias;
  logic io_in_9_bits_meta_prefetch;
  logic [2:0] io_in_9_bits_meta_prefetchSrc;
  logic io_in_9_bits_meta_accessed;
  logic io_in_9_bits_meta_tagErr;
  logic io_in_9_bits_meta_dataErr;
  logic io_in_9_bits_metaWen;
  logic io_in_9_bits_tagWen;
  logic io_in_9_bits_dsWen;
  logic io_in_9_bits_replTask;
  logic io_in_9_bits_cmoTask;
  logic [4:0] io_in_9_bits_reqSource;
  logic io_in_9_bits_mergeA;
  logic [5:0] io_in_9_bits_aMergeTask_off;
  logic [1:0] io_in_9_bits_aMergeTask_alias;
  logic [43:0] io_in_9_bits_aMergeTask_vaddr;
  logic io_in_9_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_9_bits_aMergeTask_opcode;
  logic [2:0] io_in_9_bits_aMergeTask_param;
  logic [6:0] io_in_9_bits_aMergeTask_sourceId;
  logic io_in_9_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_9_bits_aMergeTask_meta_state;
  logic io_in_9_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_9_bits_aMergeTask_meta_alias;
  logic io_in_9_bits_aMergeTask_meta_accessed;
  logic io_in_9_bits_snpHitRelease;
  logic io_in_9_bits_snpHitReleaseToInval;
  logic io_in_9_bits_snpHitReleaseToClean;
  logic io_in_9_bits_snpHitReleaseWithData;
  logic [7:0] io_in_9_bits_snpHitReleaseIdx;
  logic io_in_9_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_9_bits_snpHitReleaseMeta_state;
  logic io_in_9_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_9_bits_snpHitReleaseMeta_alias;
  logic io_in_9_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_9_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_9_bits_snpHitReleaseMeta_accessed;
  logic io_in_9_bits_snpHitReleaseMeta_tagErr;
  logic io_in_9_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_9_bits_tgtID;
  logic [11:0] io_in_9_bits_txnID;
  logic [10:0] io_in_9_bits_homeNID;
  logic [11:0] io_in_9_bits_dbID;
  logic [6:0] io_in_9_bits_chiOpcode;
  logic [2:0] io_in_9_bits_resp;
  logic [2:0] io_in_9_bits_fwdState;
  logic io_in_9_bits_retToSrc;
  logic io_in_9_bits_likelyshared;
  logic io_in_9_bits_expCompAck;
  logic io_in_9_bits_allowRetry;
  logic io_in_9_bits_memAttr_allocate;
  logic io_in_9_bits_memAttr_cacheable;
  logic io_in_9_bits_memAttr_ewa;
  logic io_in_9_bits_traceTag;
  logic io_in_9_bits_dataCheckErr;
  logic io_in_10_valid;
  logic [2:0] io_in_10_bits_channel;
  logic [2:0] io_in_10_bits_txChannel;
  logic [8:0] io_in_10_bits_set;
  logic [30:0] io_in_10_bits_tag;
  logic [5:0] io_in_10_bits_off;
  logic [1:0] io_in_10_bits_alias;
  logic io_in_10_bits_isKeyword;
  logic [3:0] io_in_10_bits_opcode;
  logic [2:0] io_in_10_bits_param;
  logic [2:0] io_in_10_bits_size;
  logic [6:0] io_in_10_bits_sourceId;
  logic io_in_10_bits_denied;
  logic io_in_10_bits_corrupt;
  logic [7:0] io_in_10_bits_mshrId;
  logic io_in_10_bits_aliasTask;
  logic io_in_10_bits_useProbeData;
  logic io_in_10_bits_mshrRetry;
  logic io_in_10_bits_readProbeDataDown;
  logic io_in_10_bits_fromL2pft;
  logic io_in_10_bits_dirty;
  logic [2:0] io_in_10_bits_way;
  logic io_in_10_bits_meta_dirty;
  logic [1:0] io_in_10_bits_meta_state;
  logic io_in_10_bits_meta_clients;
  logic [1:0] io_in_10_bits_meta_alias;
  logic io_in_10_bits_meta_prefetch;
  logic [2:0] io_in_10_bits_meta_prefetchSrc;
  logic io_in_10_bits_meta_accessed;
  logic io_in_10_bits_meta_tagErr;
  logic io_in_10_bits_meta_dataErr;
  logic io_in_10_bits_metaWen;
  logic io_in_10_bits_tagWen;
  logic io_in_10_bits_dsWen;
  logic io_in_10_bits_replTask;
  logic io_in_10_bits_cmoTask;
  logic [4:0] io_in_10_bits_reqSource;
  logic io_in_10_bits_mergeA;
  logic [5:0] io_in_10_bits_aMergeTask_off;
  logic [1:0] io_in_10_bits_aMergeTask_alias;
  logic [43:0] io_in_10_bits_aMergeTask_vaddr;
  logic io_in_10_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_10_bits_aMergeTask_opcode;
  logic [2:0] io_in_10_bits_aMergeTask_param;
  logic [6:0] io_in_10_bits_aMergeTask_sourceId;
  logic io_in_10_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_10_bits_aMergeTask_meta_state;
  logic io_in_10_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_10_bits_aMergeTask_meta_alias;
  logic io_in_10_bits_aMergeTask_meta_accessed;
  logic io_in_10_bits_snpHitRelease;
  logic io_in_10_bits_snpHitReleaseToInval;
  logic io_in_10_bits_snpHitReleaseToClean;
  logic io_in_10_bits_snpHitReleaseWithData;
  logic [7:0] io_in_10_bits_snpHitReleaseIdx;
  logic io_in_10_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_10_bits_snpHitReleaseMeta_state;
  logic io_in_10_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_10_bits_snpHitReleaseMeta_alias;
  logic io_in_10_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_10_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_10_bits_snpHitReleaseMeta_accessed;
  logic io_in_10_bits_snpHitReleaseMeta_tagErr;
  logic io_in_10_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_10_bits_tgtID;
  logic [11:0] io_in_10_bits_txnID;
  logic [10:0] io_in_10_bits_homeNID;
  logic [11:0] io_in_10_bits_dbID;
  logic [6:0] io_in_10_bits_chiOpcode;
  logic [2:0] io_in_10_bits_resp;
  logic [2:0] io_in_10_bits_fwdState;
  logic io_in_10_bits_retToSrc;
  logic io_in_10_bits_likelyshared;
  logic io_in_10_bits_expCompAck;
  logic io_in_10_bits_allowRetry;
  logic io_in_10_bits_memAttr_allocate;
  logic io_in_10_bits_memAttr_cacheable;
  logic io_in_10_bits_memAttr_ewa;
  logic io_in_10_bits_traceTag;
  logic io_in_10_bits_dataCheckErr;
  logic io_in_11_valid;
  logic [2:0] io_in_11_bits_channel;
  logic [2:0] io_in_11_bits_txChannel;
  logic [8:0] io_in_11_bits_set;
  logic [30:0] io_in_11_bits_tag;
  logic [5:0] io_in_11_bits_off;
  logic [1:0] io_in_11_bits_alias;
  logic io_in_11_bits_isKeyword;
  logic [3:0] io_in_11_bits_opcode;
  logic [2:0] io_in_11_bits_param;
  logic [2:0] io_in_11_bits_size;
  logic [6:0] io_in_11_bits_sourceId;
  logic io_in_11_bits_denied;
  logic io_in_11_bits_corrupt;
  logic [7:0] io_in_11_bits_mshrId;
  logic io_in_11_bits_aliasTask;
  logic io_in_11_bits_useProbeData;
  logic io_in_11_bits_mshrRetry;
  logic io_in_11_bits_readProbeDataDown;
  logic io_in_11_bits_fromL2pft;
  logic io_in_11_bits_dirty;
  logic [2:0] io_in_11_bits_way;
  logic io_in_11_bits_meta_dirty;
  logic [1:0] io_in_11_bits_meta_state;
  logic io_in_11_bits_meta_clients;
  logic [1:0] io_in_11_bits_meta_alias;
  logic io_in_11_bits_meta_prefetch;
  logic [2:0] io_in_11_bits_meta_prefetchSrc;
  logic io_in_11_bits_meta_accessed;
  logic io_in_11_bits_meta_tagErr;
  logic io_in_11_bits_meta_dataErr;
  logic io_in_11_bits_metaWen;
  logic io_in_11_bits_tagWen;
  logic io_in_11_bits_dsWen;
  logic io_in_11_bits_replTask;
  logic io_in_11_bits_cmoTask;
  logic [4:0] io_in_11_bits_reqSource;
  logic io_in_11_bits_mergeA;
  logic [5:0] io_in_11_bits_aMergeTask_off;
  logic [1:0] io_in_11_bits_aMergeTask_alias;
  logic [43:0] io_in_11_bits_aMergeTask_vaddr;
  logic io_in_11_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_11_bits_aMergeTask_opcode;
  logic [2:0] io_in_11_bits_aMergeTask_param;
  logic [6:0] io_in_11_bits_aMergeTask_sourceId;
  logic io_in_11_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_11_bits_aMergeTask_meta_state;
  logic io_in_11_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_11_bits_aMergeTask_meta_alias;
  logic io_in_11_bits_aMergeTask_meta_accessed;
  logic io_in_11_bits_snpHitRelease;
  logic io_in_11_bits_snpHitReleaseToInval;
  logic io_in_11_bits_snpHitReleaseToClean;
  logic io_in_11_bits_snpHitReleaseWithData;
  logic [7:0] io_in_11_bits_snpHitReleaseIdx;
  logic io_in_11_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_11_bits_snpHitReleaseMeta_state;
  logic io_in_11_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_11_bits_snpHitReleaseMeta_alias;
  logic io_in_11_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_11_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_11_bits_snpHitReleaseMeta_accessed;
  logic io_in_11_bits_snpHitReleaseMeta_tagErr;
  logic io_in_11_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_11_bits_tgtID;
  logic [11:0] io_in_11_bits_txnID;
  logic [10:0] io_in_11_bits_homeNID;
  logic [11:0] io_in_11_bits_dbID;
  logic [6:0] io_in_11_bits_chiOpcode;
  logic [2:0] io_in_11_bits_resp;
  logic [2:0] io_in_11_bits_fwdState;
  logic io_in_11_bits_retToSrc;
  logic io_in_11_bits_likelyshared;
  logic io_in_11_bits_expCompAck;
  logic io_in_11_bits_allowRetry;
  logic io_in_11_bits_memAttr_allocate;
  logic io_in_11_bits_memAttr_cacheable;
  logic io_in_11_bits_memAttr_ewa;
  logic io_in_11_bits_traceTag;
  logic io_in_11_bits_dataCheckErr;
  logic io_in_12_valid;
  logic [2:0] io_in_12_bits_channel;
  logic [2:0] io_in_12_bits_txChannel;
  logic [8:0] io_in_12_bits_set;
  logic [30:0] io_in_12_bits_tag;
  logic [5:0] io_in_12_bits_off;
  logic [1:0] io_in_12_bits_alias;
  logic io_in_12_bits_isKeyword;
  logic [3:0] io_in_12_bits_opcode;
  logic [2:0] io_in_12_bits_param;
  logic [2:0] io_in_12_bits_size;
  logic [6:0] io_in_12_bits_sourceId;
  logic io_in_12_bits_denied;
  logic io_in_12_bits_corrupt;
  logic [7:0] io_in_12_bits_mshrId;
  logic io_in_12_bits_aliasTask;
  logic io_in_12_bits_useProbeData;
  logic io_in_12_bits_mshrRetry;
  logic io_in_12_bits_readProbeDataDown;
  logic io_in_12_bits_fromL2pft;
  logic io_in_12_bits_dirty;
  logic [2:0] io_in_12_bits_way;
  logic io_in_12_bits_meta_dirty;
  logic [1:0] io_in_12_bits_meta_state;
  logic io_in_12_bits_meta_clients;
  logic [1:0] io_in_12_bits_meta_alias;
  logic io_in_12_bits_meta_prefetch;
  logic [2:0] io_in_12_bits_meta_prefetchSrc;
  logic io_in_12_bits_meta_accessed;
  logic io_in_12_bits_meta_tagErr;
  logic io_in_12_bits_meta_dataErr;
  logic io_in_12_bits_metaWen;
  logic io_in_12_bits_tagWen;
  logic io_in_12_bits_dsWen;
  logic io_in_12_bits_replTask;
  logic io_in_12_bits_cmoTask;
  logic [4:0] io_in_12_bits_reqSource;
  logic io_in_12_bits_mergeA;
  logic [5:0] io_in_12_bits_aMergeTask_off;
  logic [1:0] io_in_12_bits_aMergeTask_alias;
  logic [43:0] io_in_12_bits_aMergeTask_vaddr;
  logic io_in_12_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_12_bits_aMergeTask_opcode;
  logic [2:0] io_in_12_bits_aMergeTask_param;
  logic [6:0] io_in_12_bits_aMergeTask_sourceId;
  logic io_in_12_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_12_bits_aMergeTask_meta_state;
  logic io_in_12_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_12_bits_aMergeTask_meta_alias;
  logic io_in_12_bits_aMergeTask_meta_accessed;
  logic io_in_12_bits_snpHitRelease;
  logic io_in_12_bits_snpHitReleaseToInval;
  logic io_in_12_bits_snpHitReleaseToClean;
  logic io_in_12_bits_snpHitReleaseWithData;
  logic [7:0] io_in_12_bits_snpHitReleaseIdx;
  logic io_in_12_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_12_bits_snpHitReleaseMeta_state;
  logic io_in_12_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_12_bits_snpHitReleaseMeta_alias;
  logic io_in_12_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_12_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_12_bits_snpHitReleaseMeta_accessed;
  logic io_in_12_bits_snpHitReleaseMeta_tagErr;
  logic io_in_12_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_12_bits_tgtID;
  logic [11:0] io_in_12_bits_txnID;
  logic [10:0] io_in_12_bits_homeNID;
  logic [11:0] io_in_12_bits_dbID;
  logic [6:0] io_in_12_bits_chiOpcode;
  logic [2:0] io_in_12_bits_resp;
  logic [2:0] io_in_12_bits_fwdState;
  logic io_in_12_bits_retToSrc;
  logic io_in_12_bits_likelyshared;
  logic io_in_12_bits_expCompAck;
  logic io_in_12_bits_allowRetry;
  logic io_in_12_bits_memAttr_allocate;
  logic io_in_12_bits_memAttr_cacheable;
  logic io_in_12_bits_memAttr_ewa;
  logic io_in_12_bits_traceTag;
  logic io_in_12_bits_dataCheckErr;
  logic io_in_13_valid;
  logic [2:0] io_in_13_bits_channel;
  logic [2:0] io_in_13_bits_txChannel;
  logic [8:0] io_in_13_bits_set;
  logic [30:0] io_in_13_bits_tag;
  logic [5:0] io_in_13_bits_off;
  logic [1:0] io_in_13_bits_alias;
  logic io_in_13_bits_isKeyword;
  logic [3:0] io_in_13_bits_opcode;
  logic [2:0] io_in_13_bits_param;
  logic [2:0] io_in_13_bits_size;
  logic [6:0] io_in_13_bits_sourceId;
  logic io_in_13_bits_denied;
  logic io_in_13_bits_corrupt;
  logic [7:0] io_in_13_bits_mshrId;
  logic io_in_13_bits_aliasTask;
  logic io_in_13_bits_useProbeData;
  logic io_in_13_bits_mshrRetry;
  logic io_in_13_bits_readProbeDataDown;
  logic io_in_13_bits_fromL2pft;
  logic io_in_13_bits_dirty;
  logic [2:0] io_in_13_bits_way;
  logic io_in_13_bits_meta_dirty;
  logic [1:0] io_in_13_bits_meta_state;
  logic io_in_13_bits_meta_clients;
  logic [1:0] io_in_13_bits_meta_alias;
  logic io_in_13_bits_meta_prefetch;
  logic [2:0] io_in_13_bits_meta_prefetchSrc;
  logic io_in_13_bits_meta_accessed;
  logic io_in_13_bits_meta_tagErr;
  logic io_in_13_bits_meta_dataErr;
  logic io_in_13_bits_metaWen;
  logic io_in_13_bits_tagWen;
  logic io_in_13_bits_dsWen;
  logic io_in_13_bits_replTask;
  logic io_in_13_bits_cmoTask;
  logic [4:0] io_in_13_bits_reqSource;
  logic io_in_13_bits_mergeA;
  logic [5:0] io_in_13_bits_aMergeTask_off;
  logic [1:0] io_in_13_bits_aMergeTask_alias;
  logic [43:0] io_in_13_bits_aMergeTask_vaddr;
  logic io_in_13_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_13_bits_aMergeTask_opcode;
  logic [2:0] io_in_13_bits_aMergeTask_param;
  logic [6:0] io_in_13_bits_aMergeTask_sourceId;
  logic io_in_13_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_13_bits_aMergeTask_meta_state;
  logic io_in_13_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_13_bits_aMergeTask_meta_alias;
  logic io_in_13_bits_aMergeTask_meta_accessed;
  logic io_in_13_bits_snpHitRelease;
  logic io_in_13_bits_snpHitReleaseToInval;
  logic io_in_13_bits_snpHitReleaseToClean;
  logic io_in_13_bits_snpHitReleaseWithData;
  logic [7:0] io_in_13_bits_snpHitReleaseIdx;
  logic io_in_13_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_13_bits_snpHitReleaseMeta_state;
  logic io_in_13_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_13_bits_snpHitReleaseMeta_alias;
  logic io_in_13_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_13_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_13_bits_snpHitReleaseMeta_accessed;
  logic io_in_13_bits_snpHitReleaseMeta_tagErr;
  logic io_in_13_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_13_bits_tgtID;
  logic [11:0] io_in_13_bits_txnID;
  logic [10:0] io_in_13_bits_homeNID;
  logic [11:0] io_in_13_bits_dbID;
  logic [6:0] io_in_13_bits_chiOpcode;
  logic [2:0] io_in_13_bits_resp;
  logic [2:0] io_in_13_bits_fwdState;
  logic io_in_13_bits_retToSrc;
  logic io_in_13_bits_likelyshared;
  logic io_in_13_bits_expCompAck;
  logic io_in_13_bits_allowRetry;
  logic io_in_13_bits_memAttr_allocate;
  logic io_in_13_bits_memAttr_cacheable;
  logic io_in_13_bits_memAttr_ewa;
  logic io_in_13_bits_traceTag;
  logic io_in_13_bits_dataCheckErr;
  logic io_in_14_valid;
  logic [2:0] io_in_14_bits_channel;
  logic [2:0] io_in_14_bits_txChannel;
  logic [8:0] io_in_14_bits_set;
  logic [30:0] io_in_14_bits_tag;
  logic [5:0] io_in_14_bits_off;
  logic [1:0] io_in_14_bits_alias;
  logic io_in_14_bits_isKeyword;
  logic [3:0] io_in_14_bits_opcode;
  logic [2:0] io_in_14_bits_param;
  logic [2:0] io_in_14_bits_size;
  logic [6:0] io_in_14_bits_sourceId;
  logic io_in_14_bits_denied;
  logic io_in_14_bits_corrupt;
  logic [7:0] io_in_14_bits_mshrId;
  logic io_in_14_bits_aliasTask;
  logic io_in_14_bits_useProbeData;
  logic io_in_14_bits_mshrRetry;
  logic io_in_14_bits_readProbeDataDown;
  logic io_in_14_bits_fromL2pft;
  logic io_in_14_bits_dirty;
  logic [2:0] io_in_14_bits_way;
  logic io_in_14_bits_meta_dirty;
  logic [1:0] io_in_14_bits_meta_state;
  logic io_in_14_bits_meta_clients;
  logic [1:0] io_in_14_bits_meta_alias;
  logic io_in_14_bits_meta_prefetch;
  logic [2:0] io_in_14_bits_meta_prefetchSrc;
  logic io_in_14_bits_meta_accessed;
  logic io_in_14_bits_meta_tagErr;
  logic io_in_14_bits_meta_dataErr;
  logic io_in_14_bits_metaWen;
  logic io_in_14_bits_tagWen;
  logic io_in_14_bits_dsWen;
  logic io_in_14_bits_replTask;
  logic io_in_14_bits_cmoTask;
  logic [4:0] io_in_14_bits_reqSource;
  logic io_in_14_bits_mergeA;
  logic [5:0] io_in_14_bits_aMergeTask_off;
  logic [1:0] io_in_14_bits_aMergeTask_alias;
  logic [43:0] io_in_14_bits_aMergeTask_vaddr;
  logic io_in_14_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_14_bits_aMergeTask_opcode;
  logic [2:0] io_in_14_bits_aMergeTask_param;
  logic [6:0] io_in_14_bits_aMergeTask_sourceId;
  logic io_in_14_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_14_bits_aMergeTask_meta_state;
  logic io_in_14_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_14_bits_aMergeTask_meta_alias;
  logic io_in_14_bits_aMergeTask_meta_accessed;
  logic io_in_14_bits_snpHitRelease;
  logic io_in_14_bits_snpHitReleaseToInval;
  logic io_in_14_bits_snpHitReleaseToClean;
  logic io_in_14_bits_snpHitReleaseWithData;
  logic [7:0] io_in_14_bits_snpHitReleaseIdx;
  logic io_in_14_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_14_bits_snpHitReleaseMeta_state;
  logic io_in_14_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_14_bits_snpHitReleaseMeta_alias;
  logic io_in_14_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_14_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_14_bits_snpHitReleaseMeta_accessed;
  logic io_in_14_bits_snpHitReleaseMeta_tagErr;
  logic io_in_14_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_14_bits_tgtID;
  logic [11:0] io_in_14_bits_txnID;
  logic [10:0] io_in_14_bits_homeNID;
  logic [11:0] io_in_14_bits_dbID;
  logic [6:0] io_in_14_bits_chiOpcode;
  logic [2:0] io_in_14_bits_resp;
  logic [2:0] io_in_14_bits_fwdState;
  logic io_in_14_bits_retToSrc;
  logic io_in_14_bits_likelyshared;
  logic io_in_14_bits_expCompAck;
  logic io_in_14_bits_allowRetry;
  logic io_in_14_bits_memAttr_allocate;
  logic io_in_14_bits_memAttr_cacheable;
  logic io_in_14_bits_memAttr_ewa;
  logic io_in_14_bits_traceTag;
  logic io_in_14_bits_dataCheckErr;
  logic io_in_15_valid;
  logic [2:0] io_in_15_bits_channel;
  logic [2:0] io_in_15_bits_txChannel;
  logic [8:0] io_in_15_bits_set;
  logic [30:0] io_in_15_bits_tag;
  logic [5:0] io_in_15_bits_off;
  logic [1:0] io_in_15_bits_alias;
  logic io_in_15_bits_isKeyword;
  logic [3:0] io_in_15_bits_opcode;
  logic [2:0] io_in_15_bits_param;
  logic [2:0] io_in_15_bits_size;
  logic [6:0] io_in_15_bits_sourceId;
  logic io_in_15_bits_denied;
  logic io_in_15_bits_corrupt;
  logic [7:0] io_in_15_bits_mshrId;
  logic io_in_15_bits_aliasTask;
  logic io_in_15_bits_useProbeData;
  logic io_in_15_bits_mshrRetry;
  logic io_in_15_bits_readProbeDataDown;
  logic io_in_15_bits_fromL2pft;
  logic io_in_15_bits_dirty;
  logic [2:0] io_in_15_bits_way;
  logic io_in_15_bits_meta_dirty;
  logic [1:0] io_in_15_bits_meta_state;
  logic io_in_15_bits_meta_clients;
  logic [1:0] io_in_15_bits_meta_alias;
  logic io_in_15_bits_meta_prefetch;
  logic [2:0] io_in_15_bits_meta_prefetchSrc;
  logic io_in_15_bits_meta_accessed;
  logic io_in_15_bits_meta_tagErr;
  logic io_in_15_bits_meta_dataErr;
  logic io_in_15_bits_metaWen;
  logic io_in_15_bits_tagWen;
  logic io_in_15_bits_dsWen;
  logic io_in_15_bits_replTask;
  logic io_in_15_bits_cmoTask;
  logic [4:0] io_in_15_bits_reqSource;
  logic io_in_15_bits_mergeA;
  logic [5:0] io_in_15_bits_aMergeTask_off;
  logic [1:0] io_in_15_bits_aMergeTask_alias;
  logic [43:0] io_in_15_bits_aMergeTask_vaddr;
  logic io_in_15_bits_aMergeTask_isKeyword;
  logic [2:0] io_in_15_bits_aMergeTask_opcode;
  logic [2:0] io_in_15_bits_aMergeTask_param;
  logic [6:0] io_in_15_bits_aMergeTask_sourceId;
  logic io_in_15_bits_aMergeTask_meta_dirty;
  logic [1:0] io_in_15_bits_aMergeTask_meta_state;
  logic io_in_15_bits_aMergeTask_meta_clients;
  logic [1:0] io_in_15_bits_aMergeTask_meta_alias;
  logic io_in_15_bits_aMergeTask_meta_accessed;
  logic io_in_15_bits_snpHitRelease;
  logic io_in_15_bits_snpHitReleaseToInval;
  logic io_in_15_bits_snpHitReleaseToClean;
  logic io_in_15_bits_snpHitReleaseWithData;
  logic [7:0] io_in_15_bits_snpHitReleaseIdx;
  logic io_in_15_bits_snpHitReleaseMeta_dirty;
  logic [1:0] io_in_15_bits_snpHitReleaseMeta_state;
  logic io_in_15_bits_snpHitReleaseMeta_clients;
  logic [1:0] io_in_15_bits_snpHitReleaseMeta_alias;
  logic io_in_15_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] io_in_15_bits_snpHitReleaseMeta_prefetchSrc;
  logic io_in_15_bits_snpHitReleaseMeta_accessed;
  logic io_in_15_bits_snpHitReleaseMeta_tagErr;
  logic io_in_15_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] io_in_15_bits_tgtID;
  logic [11:0] io_in_15_bits_txnID;
  logic [10:0] io_in_15_bits_homeNID;
  logic [11:0] io_in_15_bits_dbID;
  logic [6:0] io_in_15_bits_chiOpcode;
  logic [2:0] io_in_15_bits_resp;
  logic [2:0] io_in_15_bits_fwdState;
  logic io_in_15_bits_retToSrc;
  logic io_in_15_bits_likelyshared;
  logic io_in_15_bits_expCompAck;
  logic io_in_15_bits_allowRetry;
  logic io_in_15_bits_memAttr_allocate;
  logic io_in_15_bits_memAttr_cacheable;
  logic io_in_15_bits_memAttr_ewa;
  logic io_in_15_bits_traceTag;
  logic io_in_15_bits_dataCheckErr;
  logic io_out_ready;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_in_4_ready;
  wire i_io_in_4_ready;
  wire g_io_in_5_ready;
  wire i_io_in_5_ready;
  wire g_io_in_6_ready;
  wire i_io_in_6_ready;
  wire g_io_in_7_ready;
  wire i_io_in_7_ready;
  wire g_io_in_8_ready;
  wire i_io_in_8_ready;
  wire g_io_in_9_ready;
  wire i_io_in_9_ready;
  wire g_io_in_10_ready;
  wire i_io_in_10_ready;
  wire g_io_in_11_ready;
  wire i_io_in_11_ready;
  wire g_io_in_12_ready;
  wire i_io_in_12_ready;
  wire g_io_in_13_ready;
  wire i_io_in_13_ready;
  wire g_io_in_14_ready;
  wire i_io_in_14_ready;
  wire g_io_in_15_ready;
  wire i_io_in_15_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [2:0] g_io_out_bits_channel;
  wire [2:0] i_io_out_bits_channel;
  wire [2:0] g_io_out_bits_txChannel;
  wire [2:0] i_io_out_bits_txChannel;
  wire [8:0] g_io_out_bits_set;
  wire [8:0] i_io_out_bits_set;
  wire [30:0] g_io_out_bits_tag;
  wire [30:0] i_io_out_bits_tag;
  wire [5:0] g_io_out_bits_off;
  wire [5:0] i_io_out_bits_off;
  wire [1:0] g_io_out_bits_alias;
  wire [1:0] i_io_out_bits_alias;
  wire g_io_out_bits_isKeyword;
  wire i_io_out_bits_isKeyword;
  wire [3:0] g_io_out_bits_opcode;
  wire [3:0] i_io_out_bits_opcode;
  wire [2:0] g_io_out_bits_param;
  wire [2:0] i_io_out_bits_param;
  wire [2:0] g_io_out_bits_size;
  wire [2:0] i_io_out_bits_size;
  wire [6:0] g_io_out_bits_sourceId;
  wire [6:0] i_io_out_bits_sourceId;
  wire g_io_out_bits_denied;
  wire i_io_out_bits_denied;
  wire g_io_out_bits_corrupt;
  wire i_io_out_bits_corrupt;
  wire g_io_out_bits_mshrTask;
  wire i_io_out_bits_mshrTask;
  wire [7:0] g_io_out_bits_mshrId;
  wire [7:0] i_io_out_bits_mshrId;
  wire g_io_out_bits_aliasTask;
  wire i_io_out_bits_aliasTask;
  wire g_io_out_bits_useProbeData;
  wire i_io_out_bits_useProbeData;
  wire g_io_out_bits_mshrRetry;
  wire i_io_out_bits_mshrRetry;
  wire g_io_out_bits_readProbeDataDown;
  wire i_io_out_bits_readProbeDataDown;
  wire g_io_out_bits_fromL2pft;
  wire i_io_out_bits_fromL2pft;
  wire g_io_out_bits_dirty;
  wire i_io_out_bits_dirty;
  wire [2:0] g_io_out_bits_way;
  wire [2:0] i_io_out_bits_way;
  wire g_io_out_bits_meta_dirty;
  wire i_io_out_bits_meta_dirty;
  wire [1:0] g_io_out_bits_meta_state;
  wire [1:0] i_io_out_bits_meta_state;
  wire g_io_out_bits_meta_clients;
  wire i_io_out_bits_meta_clients;
  wire [1:0] g_io_out_bits_meta_alias;
  wire [1:0] i_io_out_bits_meta_alias;
  wire g_io_out_bits_meta_prefetch;
  wire i_io_out_bits_meta_prefetch;
  wire [2:0] g_io_out_bits_meta_prefetchSrc;
  wire [2:0] i_io_out_bits_meta_prefetchSrc;
  wire g_io_out_bits_meta_accessed;
  wire i_io_out_bits_meta_accessed;
  wire g_io_out_bits_meta_tagErr;
  wire i_io_out_bits_meta_tagErr;
  wire g_io_out_bits_meta_dataErr;
  wire i_io_out_bits_meta_dataErr;
  wire g_io_out_bits_metaWen;
  wire i_io_out_bits_metaWen;
  wire g_io_out_bits_tagWen;
  wire i_io_out_bits_tagWen;
  wire g_io_out_bits_dsWen;
  wire i_io_out_bits_dsWen;
  wire g_io_out_bits_replTask;
  wire i_io_out_bits_replTask;
  wire g_io_out_bits_cmoTask;
  wire i_io_out_bits_cmoTask;
  wire [4:0] g_io_out_bits_reqSource;
  wire [4:0] i_io_out_bits_reqSource;
  wire g_io_out_bits_mergeA;
  wire i_io_out_bits_mergeA;
  wire [5:0] g_io_out_bits_aMergeTask_off;
  wire [5:0] i_io_out_bits_aMergeTask_off;
  wire [1:0] g_io_out_bits_aMergeTask_alias;
  wire [1:0] i_io_out_bits_aMergeTask_alias;
  wire [43:0] g_io_out_bits_aMergeTask_vaddr;
  wire [43:0] i_io_out_bits_aMergeTask_vaddr;
  wire g_io_out_bits_aMergeTask_isKeyword;
  wire i_io_out_bits_aMergeTask_isKeyword;
  wire [2:0] g_io_out_bits_aMergeTask_opcode;
  wire [2:0] i_io_out_bits_aMergeTask_opcode;
  wire [2:0] g_io_out_bits_aMergeTask_param;
  wire [2:0] i_io_out_bits_aMergeTask_param;
  wire [6:0] g_io_out_bits_aMergeTask_sourceId;
  wire [6:0] i_io_out_bits_aMergeTask_sourceId;
  wire g_io_out_bits_aMergeTask_meta_dirty;
  wire i_io_out_bits_aMergeTask_meta_dirty;
  wire [1:0] g_io_out_bits_aMergeTask_meta_state;
  wire [1:0] i_io_out_bits_aMergeTask_meta_state;
  wire g_io_out_bits_aMergeTask_meta_clients;
  wire i_io_out_bits_aMergeTask_meta_clients;
  wire [1:0] g_io_out_bits_aMergeTask_meta_alias;
  wire [1:0] i_io_out_bits_aMergeTask_meta_alias;
  wire g_io_out_bits_aMergeTask_meta_accessed;
  wire i_io_out_bits_aMergeTask_meta_accessed;
  wire g_io_out_bits_snpHitRelease;
  wire i_io_out_bits_snpHitRelease;
  wire g_io_out_bits_snpHitReleaseToInval;
  wire i_io_out_bits_snpHitReleaseToInval;
  wire g_io_out_bits_snpHitReleaseToClean;
  wire i_io_out_bits_snpHitReleaseToClean;
  wire g_io_out_bits_snpHitReleaseWithData;
  wire i_io_out_bits_snpHitReleaseWithData;
  wire [7:0] g_io_out_bits_snpHitReleaseIdx;
  wire [7:0] i_io_out_bits_snpHitReleaseIdx;
  wire g_io_out_bits_snpHitReleaseMeta_dirty;
  wire i_io_out_bits_snpHitReleaseMeta_dirty;
  wire [1:0] g_io_out_bits_snpHitReleaseMeta_state;
  wire [1:0] i_io_out_bits_snpHitReleaseMeta_state;
  wire g_io_out_bits_snpHitReleaseMeta_clients;
  wire i_io_out_bits_snpHitReleaseMeta_clients;
  wire [1:0] g_io_out_bits_snpHitReleaseMeta_alias;
  wire [1:0] i_io_out_bits_snpHitReleaseMeta_alias;
  wire g_io_out_bits_snpHitReleaseMeta_prefetch;
  wire i_io_out_bits_snpHitReleaseMeta_prefetch;
  wire [2:0] g_io_out_bits_snpHitReleaseMeta_prefetchSrc;
  wire [2:0] i_io_out_bits_snpHitReleaseMeta_prefetchSrc;
  wire g_io_out_bits_snpHitReleaseMeta_accessed;
  wire i_io_out_bits_snpHitReleaseMeta_accessed;
  wire g_io_out_bits_snpHitReleaseMeta_tagErr;
  wire i_io_out_bits_snpHitReleaseMeta_tagErr;
  wire g_io_out_bits_snpHitReleaseMeta_dataErr;
  wire i_io_out_bits_snpHitReleaseMeta_dataErr;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [10:0] g_io_out_bits_homeNID;
  wire [10:0] i_io_out_bits_homeNID;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [6:0] g_io_out_bits_chiOpcode;
  wire [6:0] i_io_out_bits_chiOpcode;
  wire [2:0] g_io_out_bits_resp;
  wire [2:0] i_io_out_bits_resp;
  wire [2:0] g_io_out_bits_fwdState;
  wire [2:0] i_io_out_bits_fwdState;
  wire g_io_out_bits_retToSrc;
  wire i_io_out_bits_retToSrc;
  wire g_io_out_bits_likelyshared;
  wire i_io_out_bits_likelyshared;
  wire g_io_out_bits_expCompAck;
  wire i_io_out_bits_expCompAck;
  wire g_io_out_bits_allowRetry;
  wire i_io_out_bits_allowRetry;
  wire g_io_out_bits_memAttr_allocate;
  wire i_io_out_bits_memAttr_allocate;
  wire g_io_out_bits_memAttr_cacheable;
  wire i_io_out_bits_memAttr_cacheable;
  wire g_io_out_bits_memAttr_ewa;
  wire i_io_out_bits_memAttr_ewa;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire g_io_out_bits_dataCheckErr;
  wire i_io_out_bits_dataCheckErr;

  FastArbiter_8 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_channel(io_in_0_bits_channel),
    .io_in_0_bits_txChannel(io_in_0_bits_txChannel),
    .io_in_0_bits_set(io_in_0_bits_set),
    .io_in_0_bits_tag(io_in_0_bits_tag),
    .io_in_0_bits_off(io_in_0_bits_off),
    .io_in_0_bits_alias(io_in_0_bits_alias),
    .io_in_0_bits_isKeyword(io_in_0_bits_isKeyword),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_param(io_in_0_bits_param),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_sourceId(io_in_0_bits_sourceId),
    .io_in_0_bits_denied(io_in_0_bits_denied),
    .io_in_0_bits_corrupt(io_in_0_bits_corrupt),
    .io_in_0_bits_mshrId(io_in_0_bits_mshrId),
    .io_in_0_bits_aliasTask(io_in_0_bits_aliasTask),
    .io_in_0_bits_useProbeData(io_in_0_bits_useProbeData),
    .io_in_0_bits_mshrRetry(io_in_0_bits_mshrRetry),
    .io_in_0_bits_readProbeDataDown(io_in_0_bits_readProbeDataDown),
    .io_in_0_bits_fromL2pft(io_in_0_bits_fromL2pft),
    .io_in_0_bits_dirty(io_in_0_bits_dirty),
    .io_in_0_bits_way(io_in_0_bits_way),
    .io_in_0_bits_meta_dirty(io_in_0_bits_meta_dirty),
    .io_in_0_bits_meta_state(io_in_0_bits_meta_state),
    .io_in_0_bits_meta_clients(io_in_0_bits_meta_clients),
    .io_in_0_bits_meta_alias(io_in_0_bits_meta_alias),
    .io_in_0_bits_meta_prefetch(io_in_0_bits_meta_prefetch),
    .io_in_0_bits_meta_prefetchSrc(io_in_0_bits_meta_prefetchSrc),
    .io_in_0_bits_meta_accessed(io_in_0_bits_meta_accessed),
    .io_in_0_bits_meta_tagErr(io_in_0_bits_meta_tagErr),
    .io_in_0_bits_meta_dataErr(io_in_0_bits_meta_dataErr),
    .io_in_0_bits_metaWen(io_in_0_bits_metaWen),
    .io_in_0_bits_tagWen(io_in_0_bits_tagWen),
    .io_in_0_bits_dsWen(io_in_0_bits_dsWen),
    .io_in_0_bits_replTask(io_in_0_bits_replTask),
    .io_in_0_bits_cmoTask(io_in_0_bits_cmoTask),
    .io_in_0_bits_reqSource(io_in_0_bits_reqSource),
    .io_in_0_bits_mergeA(io_in_0_bits_mergeA),
    .io_in_0_bits_aMergeTask_off(io_in_0_bits_aMergeTask_off),
    .io_in_0_bits_aMergeTask_alias(io_in_0_bits_aMergeTask_alias),
    .io_in_0_bits_aMergeTask_vaddr(io_in_0_bits_aMergeTask_vaddr),
    .io_in_0_bits_aMergeTask_isKeyword(io_in_0_bits_aMergeTask_isKeyword),
    .io_in_0_bits_aMergeTask_opcode(io_in_0_bits_aMergeTask_opcode),
    .io_in_0_bits_aMergeTask_param(io_in_0_bits_aMergeTask_param),
    .io_in_0_bits_aMergeTask_sourceId(io_in_0_bits_aMergeTask_sourceId),
    .io_in_0_bits_aMergeTask_meta_dirty(io_in_0_bits_aMergeTask_meta_dirty),
    .io_in_0_bits_aMergeTask_meta_state(io_in_0_bits_aMergeTask_meta_state),
    .io_in_0_bits_aMergeTask_meta_clients(io_in_0_bits_aMergeTask_meta_clients),
    .io_in_0_bits_aMergeTask_meta_alias(io_in_0_bits_aMergeTask_meta_alias),
    .io_in_0_bits_aMergeTask_meta_accessed(io_in_0_bits_aMergeTask_meta_accessed),
    .io_in_0_bits_snpHitRelease(io_in_0_bits_snpHitRelease),
    .io_in_0_bits_snpHitReleaseToInval(io_in_0_bits_snpHitReleaseToInval),
    .io_in_0_bits_snpHitReleaseToClean(io_in_0_bits_snpHitReleaseToClean),
    .io_in_0_bits_snpHitReleaseWithData(io_in_0_bits_snpHitReleaseWithData),
    .io_in_0_bits_snpHitReleaseIdx(io_in_0_bits_snpHitReleaseIdx),
    .io_in_0_bits_snpHitReleaseMeta_dirty(io_in_0_bits_snpHitReleaseMeta_dirty),
    .io_in_0_bits_snpHitReleaseMeta_state(io_in_0_bits_snpHitReleaseMeta_state),
    .io_in_0_bits_snpHitReleaseMeta_clients(io_in_0_bits_snpHitReleaseMeta_clients),
    .io_in_0_bits_snpHitReleaseMeta_alias(io_in_0_bits_snpHitReleaseMeta_alias),
    .io_in_0_bits_snpHitReleaseMeta_prefetch(io_in_0_bits_snpHitReleaseMeta_prefetch),
    .io_in_0_bits_snpHitReleaseMeta_prefetchSrc(io_in_0_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_snpHitReleaseMeta_accessed(io_in_0_bits_snpHitReleaseMeta_accessed),
    .io_in_0_bits_snpHitReleaseMeta_tagErr(io_in_0_bits_snpHitReleaseMeta_tagErr),
    .io_in_0_bits_snpHitReleaseMeta_dataErr(io_in_0_bits_snpHitReleaseMeta_dataErr),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(io_in_0_bits_homeNID),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_chiOpcode(io_in_0_bits_chiOpcode),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_fwdState(io_in_0_bits_fwdState),
    .io_in_0_bits_retToSrc(io_in_0_bits_retToSrc),
    .io_in_0_bits_likelyshared(io_in_0_bits_likelyshared),
    .io_in_0_bits_expCompAck(io_in_0_bits_expCompAck),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_memAttr_allocate(io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable(io_in_0_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_dataCheckErr(io_in_0_bits_dataCheckErr),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_channel(io_in_1_bits_channel),
    .io_in_1_bits_txChannel(io_in_1_bits_txChannel),
    .io_in_1_bits_set(io_in_1_bits_set),
    .io_in_1_bits_tag(io_in_1_bits_tag),
    .io_in_1_bits_off(io_in_1_bits_off),
    .io_in_1_bits_alias(io_in_1_bits_alias),
    .io_in_1_bits_isKeyword(io_in_1_bits_isKeyword),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_param(io_in_1_bits_param),
    .io_in_1_bits_size(io_in_1_bits_size),
    .io_in_1_bits_sourceId(io_in_1_bits_sourceId),
    .io_in_1_bits_denied(io_in_1_bits_denied),
    .io_in_1_bits_corrupt(io_in_1_bits_corrupt),
    .io_in_1_bits_mshrId(io_in_1_bits_mshrId),
    .io_in_1_bits_aliasTask(io_in_1_bits_aliasTask),
    .io_in_1_bits_useProbeData(io_in_1_bits_useProbeData),
    .io_in_1_bits_mshrRetry(io_in_1_bits_mshrRetry),
    .io_in_1_bits_readProbeDataDown(io_in_1_bits_readProbeDataDown),
    .io_in_1_bits_fromL2pft(io_in_1_bits_fromL2pft),
    .io_in_1_bits_dirty(io_in_1_bits_dirty),
    .io_in_1_bits_way(io_in_1_bits_way),
    .io_in_1_bits_meta_dirty(io_in_1_bits_meta_dirty),
    .io_in_1_bits_meta_state(io_in_1_bits_meta_state),
    .io_in_1_bits_meta_clients(io_in_1_bits_meta_clients),
    .io_in_1_bits_meta_alias(io_in_1_bits_meta_alias),
    .io_in_1_bits_meta_prefetch(io_in_1_bits_meta_prefetch),
    .io_in_1_bits_meta_prefetchSrc(io_in_1_bits_meta_prefetchSrc),
    .io_in_1_bits_meta_accessed(io_in_1_bits_meta_accessed),
    .io_in_1_bits_meta_tagErr(io_in_1_bits_meta_tagErr),
    .io_in_1_bits_meta_dataErr(io_in_1_bits_meta_dataErr),
    .io_in_1_bits_metaWen(io_in_1_bits_metaWen),
    .io_in_1_bits_tagWen(io_in_1_bits_tagWen),
    .io_in_1_bits_dsWen(io_in_1_bits_dsWen),
    .io_in_1_bits_replTask(io_in_1_bits_replTask),
    .io_in_1_bits_cmoTask(io_in_1_bits_cmoTask),
    .io_in_1_bits_reqSource(io_in_1_bits_reqSource),
    .io_in_1_bits_mergeA(io_in_1_bits_mergeA),
    .io_in_1_bits_aMergeTask_off(io_in_1_bits_aMergeTask_off),
    .io_in_1_bits_aMergeTask_alias(io_in_1_bits_aMergeTask_alias),
    .io_in_1_bits_aMergeTask_vaddr(io_in_1_bits_aMergeTask_vaddr),
    .io_in_1_bits_aMergeTask_isKeyword(io_in_1_bits_aMergeTask_isKeyword),
    .io_in_1_bits_aMergeTask_opcode(io_in_1_bits_aMergeTask_opcode),
    .io_in_1_bits_aMergeTask_param(io_in_1_bits_aMergeTask_param),
    .io_in_1_bits_aMergeTask_sourceId(io_in_1_bits_aMergeTask_sourceId),
    .io_in_1_bits_aMergeTask_meta_dirty(io_in_1_bits_aMergeTask_meta_dirty),
    .io_in_1_bits_aMergeTask_meta_state(io_in_1_bits_aMergeTask_meta_state),
    .io_in_1_bits_aMergeTask_meta_clients(io_in_1_bits_aMergeTask_meta_clients),
    .io_in_1_bits_aMergeTask_meta_alias(io_in_1_bits_aMergeTask_meta_alias),
    .io_in_1_bits_aMergeTask_meta_accessed(io_in_1_bits_aMergeTask_meta_accessed),
    .io_in_1_bits_snpHitRelease(io_in_1_bits_snpHitRelease),
    .io_in_1_bits_snpHitReleaseToInval(io_in_1_bits_snpHitReleaseToInval),
    .io_in_1_bits_snpHitReleaseToClean(io_in_1_bits_snpHitReleaseToClean),
    .io_in_1_bits_snpHitReleaseWithData(io_in_1_bits_snpHitReleaseWithData),
    .io_in_1_bits_snpHitReleaseIdx(io_in_1_bits_snpHitReleaseIdx),
    .io_in_1_bits_snpHitReleaseMeta_dirty(io_in_1_bits_snpHitReleaseMeta_dirty),
    .io_in_1_bits_snpHitReleaseMeta_state(io_in_1_bits_snpHitReleaseMeta_state),
    .io_in_1_bits_snpHitReleaseMeta_clients(io_in_1_bits_snpHitReleaseMeta_clients),
    .io_in_1_bits_snpHitReleaseMeta_alias(io_in_1_bits_snpHitReleaseMeta_alias),
    .io_in_1_bits_snpHitReleaseMeta_prefetch(io_in_1_bits_snpHitReleaseMeta_prefetch),
    .io_in_1_bits_snpHitReleaseMeta_prefetchSrc(io_in_1_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_snpHitReleaseMeta_accessed(io_in_1_bits_snpHitReleaseMeta_accessed),
    .io_in_1_bits_snpHitReleaseMeta_tagErr(io_in_1_bits_snpHitReleaseMeta_tagErr),
    .io_in_1_bits_snpHitReleaseMeta_dataErr(io_in_1_bits_snpHitReleaseMeta_dataErr),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_homeNID(io_in_1_bits_homeNID),
    .io_in_1_bits_dbID(io_in_1_bits_dbID),
    .io_in_1_bits_chiOpcode(io_in_1_bits_chiOpcode),
    .io_in_1_bits_resp(io_in_1_bits_resp),
    .io_in_1_bits_fwdState(io_in_1_bits_fwdState),
    .io_in_1_bits_retToSrc(io_in_1_bits_retToSrc),
    .io_in_1_bits_likelyshared(io_in_1_bits_likelyshared),
    .io_in_1_bits_expCompAck(io_in_1_bits_expCompAck),
    .io_in_1_bits_allowRetry(io_in_1_bits_allowRetry),
    .io_in_1_bits_memAttr_allocate(io_in_1_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable(io_in_1_bits_memAttr_cacheable),
    .io_in_1_bits_memAttr_ewa(io_in_1_bits_memAttr_ewa),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_in_1_bits_dataCheckErr(io_in_1_bits_dataCheckErr),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_channel(io_in_2_bits_channel),
    .io_in_2_bits_txChannel(io_in_2_bits_txChannel),
    .io_in_2_bits_set(io_in_2_bits_set),
    .io_in_2_bits_tag(io_in_2_bits_tag),
    .io_in_2_bits_off(io_in_2_bits_off),
    .io_in_2_bits_alias(io_in_2_bits_alias),
    .io_in_2_bits_isKeyword(io_in_2_bits_isKeyword),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_param(io_in_2_bits_param),
    .io_in_2_bits_size(io_in_2_bits_size),
    .io_in_2_bits_sourceId(io_in_2_bits_sourceId),
    .io_in_2_bits_denied(io_in_2_bits_denied),
    .io_in_2_bits_corrupt(io_in_2_bits_corrupt),
    .io_in_2_bits_mshrId(io_in_2_bits_mshrId),
    .io_in_2_bits_aliasTask(io_in_2_bits_aliasTask),
    .io_in_2_bits_useProbeData(io_in_2_bits_useProbeData),
    .io_in_2_bits_mshrRetry(io_in_2_bits_mshrRetry),
    .io_in_2_bits_readProbeDataDown(io_in_2_bits_readProbeDataDown),
    .io_in_2_bits_fromL2pft(io_in_2_bits_fromL2pft),
    .io_in_2_bits_dirty(io_in_2_bits_dirty),
    .io_in_2_bits_way(io_in_2_bits_way),
    .io_in_2_bits_meta_dirty(io_in_2_bits_meta_dirty),
    .io_in_2_bits_meta_state(io_in_2_bits_meta_state),
    .io_in_2_bits_meta_clients(io_in_2_bits_meta_clients),
    .io_in_2_bits_meta_alias(io_in_2_bits_meta_alias),
    .io_in_2_bits_meta_prefetch(io_in_2_bits_meta_prefetch),
    .io_in_2_bits_meta_prefetchSrc(io_in_2_bits_meta_prefetchSrc),
    .io_in_2_bits_meta_accessed(io_in_2_bits_meta_accessed),
    .io_in_2_bits_meta_tagErr(io_in_2_bits_meta_tagErr),
    .io_in_2_bits_meta_dataErr(io_in_2_bits_meta_dataErr),
    .io_in_2_bits_metaWen(io_in_2_bits_metaWen),
    .io_in_2_bits_tagWen(io_in_2_bits_tagWen),
    .io_in_2_bits_dsWen(io_in_2_bits_dsWen),
    .io_in_2_bits_replTask(io_in_2_bits_replTask),
    .io_in_2_bits_cmoTask(io_in_2_bits_cmoTask),
    .io_in_2_bits_reqSource(io_in_2_bits_reqSource),
    .io_in_2_bits_mergeA(io_in_2_bits_mergeA),
    .io_in_2_bits_aMergeTask_off(io_in_2_bits_aMergeTask_off),
    .io_in_2_bits_aMergeTask_alias(io_in_2_bits_aMergeTask_alias),
    .io_in_2_bits_aMergeTask_vaddr(io_in_2_bits_aMergeTask_vaddr),
    .io_in_2_bits_aMergeTask_isKeyword(io_in_2_bits_aMergeTask_isKeyword),
    .io_in_2_bits_aMergeTask_opcode(io_in_2_bits_aMergeTask_opcode),
    .io_in_2_bits_aMergeTask_param(io_in_2_bits_aMergeTask_param),
    .io_in_2_bits_aMergeTask_sourceId(io_in_2_bits_aMergeTask_sourceId),
    .io_in_2_bits_aMergeTask_meta_dirty(io_in_2_bits_aMergeTask_meta_dirty),
    .io_in_2_bits_aMergeTask_meta_state(io_in_2_bits_aMergeTask_meta_state),
    .io_in_2_bits_aMergeTask_meta_clients(io_in_2_bits_aMergeTask_meta_clients),
    .io_in_2_bits_aMergeTask_meta_alias(io_in_2_bits_aMergeTask_meta_alias),
    .io_in_2_bits_aMergeTask_meta_accessed(io_in_2_bits_aMergeTask_meta_accessed),
    .io_in_2_bits_snpHitRelease(io_in_2_bits_snpHitRelease),
    .io_in_2_bits_snpHitReleaseToInval(io_in_2_bits_snpHitReleaseToInval),
    .io_in_2_bits_snpHitReleaseToClean(io_in_2_bits_snpHitReleaseToClean),
    .io_in_2_bits_snpHitReleaseWithData(io_in_2_bits_snpHitReleaseWithData),
    .io_in_2_bits_snpHitReleaseIdx(io_in_2_bits_snpHitReleaseIdx),
    .io_in_2_bits_snpHitReleaseMeta_dirty(io_in_2_bits_snpHitReleaseMeta_dirty),
    .io_in_2_bits_snpHitReleaseMeta_state(io_in_2_bits_snpHitReleaseMeta_state),
    .io_in_2_bits_snpHitReleaseMeta_clients(io_in_2_bits_snpHitReleaseMeta_clients),
    .io_in_2_bits_snpHitReleaseMeta_alias(io_in_2_bits_snpHitReleaseMeta_alias),
    .io_in_2_bits_snpHitReleaseMeta_prefetch(io_in_2_bits_snpHitReleaseMeta_prefetch),
    .io_in_2_bits_snpHitReleaseMeta_prefetchSrc(io_in_2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_snpHitReleaseMeta_accessed(io_in_2_bits_snpHitReleaseMeta_accessed),
    .io_in_2_bits_snpHitReleaseMeta_tagErr(io_in_2_bits_snpHitReleaseMeta_tagErr),
    .io_in_2_bits_snpHitReleaseMeta_dataErr(io_in_2_bits_snpHitReleaseMeta_dataErr),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_homeNID(io_in_2_bits_homeNID),
    .io_in_2_bits_dbID(io_in_2_bits_dbID),
    .io_in_2_bits_chiOpcode(io_in_2_bits_chiOpcode),
    .io_in_2_bits_resp(io_in_2_bits_resp),
    .io_in_2_bits_fwdState(io_in_2_bits_fwdState),
    .io_in_2_bits_retToSrc(io_in_2_bits_retToSrc),
    .io_in_2_bits_likelyshared(io_in_2_bits_likelyshared),
    .io_in_2_bits_expCompAck(io_in_2_bits_expCompAck),
    .io_in_2_bits_allowRetry(io_in_2_bits_allowRetry),
    .io_in_2_bits_memAttr_allocate(io_in_2_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable(io_in_2_bits_memAttr_cacheable),
    .io_in_2_bits_memAttr_ewa(io_in_2_bits_memAttr_ewa),
    .io_in_2_bits_traceTag(io_in_2_bits_traceTag),
    .io_in_2_bits_dataCheckErr(io_in_2_bits_dataCheckErr),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_channel(io_in_3_bits_channel),
    .io_in_3_bits_txChannel(io_in_3_bits_txChannel),
    .io_in_3_bits_set(io_in_3_bits_set),
    .io_in_3_bits_tag(io_in_3_bits_tag),
    .io_in_3_bits_off(io_in_3_bits_off),
    .io_in_3_bits_alias(io_in_3_bits_alias),
    .io_in_3_bits_isKeyword(io_in_3_bits_isKeyword),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_param(io_in_3_bits_param),
    .io_in_3_bits_size(io_in_3_bits_size),
    .io_in_3_bits_sourceId(io_in_3_bits_sourceId),
    .io_in_3_bits_denied(io_in_3_bits_denied),
    .io_in_3_bits_corrupt(io_in_3_bits_corrupt),
    .io_in_3_bits_mshrId(io_in_3_bits_mshrId),
    .io_in_3_bits_aliasTask(io_in_3_bits_aliasTask),
    .io_in_3_bits_useProbeData(io_in_3_bits_useProbeData),
    .io_in_3_bits_mshrRetry(io_in_3_bits_mshrRetry),
    .io_in_3_bits_readProbeDataDown(io_in_3_bits_readProbeDataDown),
    .io_in_3_bits_fromL2pft(io_in_3_bits_fromL2pft),
    .io_in_3_bits_dirty(io_in_3_bits_dirty),
    .io_in_3_bits_way(io_in_3_bits_way),
    .io_in_3_bits_meta_dirty(io_in_3_bits_meta_dirty),
    .io_in_3_bits_meta_state(io_in_3_bits_meta_state),
    .io_in_3_bits_meta_clients(io_in_3_bits_meta_clients),
    .io_in_3_bits_meta_alias(io_in_3_bits_meta_alias),
    .io_in_3_bits_meta_prefetch(io_in_3_bits_meta_prefetch),
    .io_in_3_bits_meta_prefetchSrc(io_in_3_bits_meta_prefetchSrc),
    .io_in_3_bits_meta_accessed(io_in_3_bits_meta_accessed),
    .io_in_3_bits_meta_tagErr(io_in_3_bits_meta_tagErr),
    .io_in_3_bits_meta_dataErr(io_in_3_bits_meta_dataErr),
    .io_in_3_bits_metaWen(io_in_3_bits_metaWen),
    .io_in_3_bits_tagWen(io_in_3_bits_tagWen),
    .io_in_3_bits_dsWen(io_in_3_bits_dsWen),
    .io_in_3_bits_replTask(io_in_3_bits_replTask),
    .io_in_3_bits_cmoTask(io_in_3_bits_cmoTask),
    .io_in_3_bits_reqSource(io_in_3_bits_reqSource),
    .io_in_3_bits_mergeA(io_in_3_bits_mergeA),
    .io_in_3_bits_aMergeTask_off(io_in_3_bits_aMergeTask_off),
    .io_in_3_bits_aMergeTask_alias(io_in_3_bits_aMergeTask_alias),
    .io_in_3_bits_aMergeTask_vaddr(io_in_3_bits_aMergeTask_vaddr),
    .io_in_3_bits_aMergeTask_isKeyword(io_in_3_bits_aMergeTask_isKeyword),
    .io_in_3_bits_aMergeTask_opcode(io_in_3_bits_aMergeTask_opcode),
    .io_in_3_bits_aMergeTask_param(io_in_3_bits_aMergeTask_param),
    .io_in_3_bits_aMergeTask_sourceId(io_in_3_bits_aMergeTask_sourceId),
    .io_in_3_bits_aMergeTask_meta_dirty(io_in_3_bits_aMergeTask_meta_dirty),
    .io_in_3_bits_aMergeTask_meta_state(io_in_3_bits_aMergeTask_meta_state),
    .io_in_3_bits_aMergeTask_meta_clients(io_in_3_bits_aMergeTask_meta_clients),
    .io_in_3_bits_aMergeTask_meta_alias(io_in_3_bits_aMergeTask_meta_alias),
    .io_in_3_bits_aMergeTask_meta_accessed(io_in_3_bits_aMergeTask_meta_accessed),
    .io_in_3_bits_snpHitRelease(io_in_3_bits_snpHitRelease),
    .io_in_3_bits_snpHitReleaseToInval(io_in_3_bits_snpHitReleaseToInval),
    .io_in_3_bits_snpHitReleaseToClean(io_in_3_bits_snpHitReleaseToClean),
    .io_in_3_bits_snpHitReleaseWithData(io_in_3_bits_snpHitReleaseWithData),
    .io_in_3_bits_snpHitReleaseIdx(io_in_3_bits_snpHitReleaseIdx),
    .io_in_3_bits_snpHitReleaseMeta_dirty(io_in_3_bits_snpHitReleaseMeta_dirty),
    .io_in_3_bits_snpHitReleaseMeta_state(io_in_3_bits_snpHitReleaseMeta_state),
    .io_in_3_bits_snpHitReleaseMeta_clients(io_in_3_bits_snpHitReleaseMeta_clients),
    .io_in_3_bits_snpHitReleaseMeta_alias(io_in_3_bits_snpHitReleaseMeta_alias),
    .io_in_3_bits_snpHitReleaseMeta_prefetch(io_in_3_bits_snpHitReleaseMeta_prefetch),
    .io_in_3_bits_snpHitReleaseMeta_prefetchSrc(io_in_3_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_3_bits_snpHitReleaseMeta_accessed(io_in_3_bits_snpHitReleaseMeta_accessed),
    .io_in_3_bits_snpHitReleaseMeta_tagErr(io_in_3_bits_snpHitReleaseMeta_tagErr),
    .io_in_3_bits_snpHitReleaseMeta_dataErr(io_in_3_bits_snpHitReleaseMeta_dataErr),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_homeNID(io_in_3_bits_homeNID),
    .io_in_3_bits_dbID(io_in_3_bits_dbID),
    .io_in_3_bits_chiOpcode(io_in_3_bits_chiOpcode),
    .io_in_3_bits_resp(io_in_3_bits_resp),
    .io_in_3_bits_fwdState(io_in_3_bits_fwdState),
    .io_in_3_bits_retToSrc(io_in_3_bits_retToSrc),
    .io_in_3_bits_likelyshared(io_in_3_bits_likelyshared),
    .io_in_3_bits_expCompAck(io_in_3_bits_expCompAck),
    .io_in_3_bits_allowRetry(io_in_3_bits_allowRetry),
    .io_in_3_bits_memAttr_allocate(io_in_3_bits_memAttr_allocate),
    .io_in_3_bits_memAttr_cacheable(io_in_3_bits_memAttr_cacheable),
    .io_in_3_bits_memAttr_ewa(io_in_3_bits_memAttr_ewa),
    .io_in_3_bits_traceTag(io_in_3_bits_traceTag),
    .io_in_3_bits_dataCheckErr(io_in_3_bits_dataCheckErr),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_channel(io_in_4_bits_channel),
    .io_in_4_bits_txChannel(io_in_4_bits_txChannel),
    .io_in_4_bits_set(io_in_4_bits_set),
    .io_in_4_bits_tag(io_in_4_bits_tag),
    .io_in_4_bits_off(io_in_4_bits_off),
    .io_in_4_bits_alias(io_in_4_bits_alias),
    .io_in_4_bits_isKeyword(io_in_4_bits_isKeyword),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_param(io_in_4_bits_param),
    .io_in_4_bits_size(io_in_4_bits_size),
    .io_in_4_bits_sourceId(io_in_4_bits_sourceId),
    .io_in_4_bits_denied(io_in_4_bits_denied),
    .io_in_4_bits_corrupt(io_in_4_bits_corrupt),
    .io_in_4_bits_mshrId(io_in_4_bits_mshrId),
    .io_in_4_bits_aliasTask(io_in_4_bits_aliasTask),
    .io_in_4_bits_useProbeData(io_in_4_bits_useProbeData),
    .io_in_4_bits_mshrRetry(io_in_4_bits_mshrRetry),
    .io_in_4_bits_readProbeDataDown(io_in_4_bits_readProbeDataDown),
    .io_in_4_bits_fromL2pft(io_in_4_bits_fromL2pft),
    .io_in_4_bits_dirty(io_in_4_bits_dirty),
    .io_in_4_bits_way(io_in_4_bits_way),
    .io_in_4_bits_meta_dirty(io_in_4_bits_meta_dirty),
    .io_in_4_bits_meta_state(io_in_4_bits_meta_state),
    .io_in_4_bits_meta_clients(io_in_4_bits_meta_clients),
    .io_in_4_bits_meta_alias(io_in_4_bits_meta_alias),
    .io_in_4_bits_meta_prefetch(io_in_4_bits_meta_prefetch),
    .io_in_4_bits_meta_prefetchSrc(io_in_4_bits_meta_prefetchSrc),
    .io_in_4_bits_meta_accessed(io_in_4_bits_meta_accessed),
    .io_in_4_bits_meta_tagErr(io_in_4_bits_meta_tagErr),
    .io_in_4_bits_meta_dataErr(io_in_4_bits_meta_dataErr),
    .io_in_4_bits_metaWen(io_in_4_bits_metaWen),
    .io_in_4_bits_tagWen(io_in_4_bits_tagWen),
    .io_in_4_bits_dsWen(io_in_4_bits_dsWen),
    .io_in_4_bits_replTask(io_in_4_bits_replTask),
    .io_in_4_bits_cmoTask(io_in_4_bits_cmoTask),
    .io_in_4_bits_reqSource(io_in_4_bits_reqSource),
    .io_in_4_bits_mergeA(io_in_4_bits_mergeA),
    .io_in_4_bits_aMergeTask_off(io_in_4_bits_aMergeTask_off),
    .io_in_4_bits_aMergeTask_alias(io_in_4_bits_aMergeTask_alias),
    .io_in_4_bits_aMergeTask_vaddr(io_in_4_bits_aMergeTask_vaddr),
    .io_in_4_bits_aMergeTask_isKeyword(io_in_4_bits_aMergeTask_isKeyword),
    .io_in_4_bits_aMergeTask_opcode(io_in_4_bits_aMergeTask_opcode),
    .io_in_4_bits_aMergeTask_param(io_in_4_bits_aMergeTask_param),
    .io_in_4_bits_aMergeTask_sourceId(io_in_4_bits_aMergeTask_sourceId),
    .io_in_4_bits_aMergeTask_meta_dirty(io_in_4_bits_aMergeTask_meta_dirty),
    .io_in_4_bits_aMergeTask_meta_state(io_in_4_bits_aMergeTask_meta_state),
    .io_in_4_bits_aMergeTask_meta_clients(io_in_4_bits_aMergeTask_meta_clients),
    .io_in_4_bits_aMergeTask_meta_alias(io_in_4_bits_aMergeTask_meta_alias),
    .io_in_4_bits_aMergeTask_meta_accessed(io_in_4_bits_aMergeTask_meta_accessed),
    .io_in_4_bits_snpHitRelease(io_in_4_bits_snpHitRelease),
    .io_in_4_bits_snpHitReleaseToInval(io_in_4_bits_snpHitReleaseToInval),
    .io_in_4_bits_snpHitReleaseToClean(io_in_4_bits_snpHitReleaseToClean),
    .io_in_4_bits_snpHitReleaseWithData(io_in_4_bits_snpHitReleaseWithData),
    .io_in_4_bits_snpHitReleaseIdx(io_in_4_bits_snpHitReleaseIdx),
    .io_in_4_bits_snpHitReleaseMeta_dirty(io_in_4_bits_snpHitReleaseMeta_dirty),
    .io_in_4_bits_snpHitReleaseMeta_state(io_in_4_bits_snpHitReleaseMeta_state),
    .io_in_4_bits_snpHitReleaseMeta_clients(io_in_4_bits_snpHitReleaseMeta_clients),
    .io_in_4_bits_snpHitReleaseMeta_alias(io_in_4_bits_snpHitReleaseMeta_alias),
    .io_in_4_bits_snpHitReleaseMeta_prefetch(io_in_4_bits_snpHitReleaseMeta_prefetch),
    .io_in_4_bits_snpHitReleaseMeta_prefetchSrc(io_in_4_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_4_bits_snpHitReleaseMeta_accessed(io_in_4_bits_snpHitReleaseMeta_accessed),
    .io_in_4_bits_snpHitReleaseMeta_tagErr(io_in_4_bits_snpHitReleaseMeta_tagErr),
    .io_in_4_bits_snpHitReleaseMeta_dataErr(io_in_4_bits_snpHitReleaseMeta_dataErr),
    .io_in_4_bits_tgtID(io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_homeNID(io_in_4_bits_homeNID),
    .io_in_4_bits_dbID(io_in_4_bits_dbID),
    .io_in_4_bits_chiOpcode(io_in_4_bits_chiOpcode),
    .io_in_4_bits_resp(io_in_4_bits_resp),
    .io_in_4_bits_fwdState(io_in_4_bits_fwdState),
    .io_in_4_bits_retToSrc(io_in_4_bits_retToSrc),
    .io_in_4_bits_likelyshared(io_in_4_bits_likelyshared),
    .io_in_4_bits_expCompAck(io_in_4_bits_expCompAck),
    .io_in_4_bits_allowRetry(io_in_4_bits_allowRetry),
    .io_in_4_bits_memAttr_allocate(io_in_4_bits_memAttr_allocate),
    .io_in_4_bits_memAttr_cacheable(io_in_4_bits_memAttr_cacheable),
    .io_in_4_bits_memAttr_ewa(io_in_4_bits_memAttr_ewa),
    .io_in_4_bits_traceTag(io_in_4_bits_traceTag),
    .io_in_4_bits_dataCheckErr(io_in_4_bits_dataCheckErr),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_channel(io_in_5_bits_channel),
    .io_in_5_bits_txChannel(io_in_5_bits_txChannel),
    .io_in_5_bits_set(io_in_5_bits_set),
    .io_in_5_bits_tag(io_in_5_bits_tag),
    .io_in_5_bits_off(io_in_5_bits_off),
    .io_in_5_bits_alias(io_in_5_bits_alias),
    .io_in_5_bits_isKeyword(io_in_5_bits_isKeyword),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_param(io_in_5_bits_param),
    .io_in_5_bits_size(io_in_5_bits_size),
    .io_in_5_bits_sourceId(io_in_5_bits_sourceId),
    .io_in_5_bits_denied(io_in_5_bits_denied),
    .io_in_5_bits_corrupt(io_in_5_bits_corrupt),
    .io_in_5_bits_mshrId(io_in_5_bits_mshrId),
    .io_in_5_bits_aliasTask(io_in_5_bits_aliasTask),
    .io_in_5_bits_useProbeData(io_in_5_bits_useProbeData),
    .io_in_5_bits_mshrRetry(io_in_5_bits_mshrRetry),
    .io_in_5_bits_readProbeDataDown(io_in_5_bits_readProbeDataDown),
    .io_in_5_bits_fromL2pft(io_in_5_bits_fromL2pft),
    .io_in_5_bits_dirty(io_in_5_bits_dirty),
    .io_in_5_bits_way(io_in_5_bits_way),
    .io_in_5_bits_meta_dirty(io_in_5_bits_meta_dirty),
    .io_in_5_bits_meta_state(io_in_5_bits_meta_state),
    .io_in_5_bits_meta_clients(io_in_5_bits_meta_clients),
    .io_in_5_bits_meta_alias(io_in_5_bits_meta_alias),
    .io_in_5_bits_meta_prefetch(io_in_5_bits_meta_prefetch),
    .io_in_5_bits_meta_prefetchSrc(io_in_5_bits_meta_prefetchSrc),
    .io_in_5_bits_meta_accessed(io_in_5_bits_meta_accessed),
    .io_in_5_bits_meta_tagErr(io_in_5_bits_meta_tagErr),
    .io_in_5_bits_meta_dataErr(io_in_5_bits_meta_dataErr),
    .io_in_5_bits_metaWen(io_in_5_bits_metaWen),
    .io_in_5_bits_tagWen(io_in_5_bits_tagWen),
    .io_in_5_bits_dsWen(io_in_5_bits_dsWen),
    .io_in_5_bits_replTask(io_in_5_bits_replTask),
    .io_in_5_bits_cmoTask(io_in_5_bits_cmoTask),
    .io_in_5_bits_reqSource(io_in_5_bits_reqSource),
    .io_in_5_bits_mergeA(io_in_5_bits_mergeA),
    .io_in_5_bits_aMergeTask_off(io_in_5_bits_aMergeTask_off),
    .io_in_5_bits_aMergeTask_alias(io_in_5_bits_aMergeTask_alias),
    .io_in_5_bits_aMergeTask_vaddr(io_in_5_bits_aMergeTask_vaddr),
    .io_in_5_bits_aMergeTask_isKeyword(io_in_5_bits_aMergeTask_isKeyword),
    .io_in_5_bits_aMergeTask_opcode(io_in_5_bits_aMergeTask_opcode),
    .io_in_5_bits_aMergeTask_param(io_in_5_bits_aMergeTask_param),
    .io_in_5_bits_aMergeTask_sourceId(io_in_5_bits_aMergeTask_sourceId),
    .io_in_5_bits_aMergeTask_meta_dirty(io_in_5_bits_aMergeTask_meta_dirty),
    .io_in_5_bits_aMergeTask_meta_state(io_in_5_bits_aMergeTask_meta_state),
    .io_in_5_bits_aMergeTask_meta_clients(io_in_5_bits_aMergeTask_meta_clients),
    .io_in_5_bits_aMergeTask_meta_alias(io_in_5_bits_aMergeTask_meta_alias),
    .io_in_5_bits_aMergeTask_meta_accessed(io_in_5_bits_aMergeTask_meta_accessed),
    .io_in_5_bits_snpHitRelease(io_in_5_bits_snpHitRelease),
    .io_in_5_bits_snpHitReleaseToInval(io_in_5_bits_snpHitReleaseToInval),
    .io_in_5_bits_snpHitReleaseToClean(io_in_5_bits_snpHitReleaseToClean),
    .io_in_5_bits_snpHitReleaseWithData(io_in_5_bits_snpHitReleaseWithData),
    .io_in_5_bits_snpHitReleaseIdx(io_in_5_bits_snpHitReleaseIdx),
    .io_in_5_bits_snpHitReleaseMeta_dirty(io_in_5_bits_snpHitReleaseMeta_dirty),
    .io_in_5_bits_snpHitReleaseMeta_state(io_in_5_bits_snpHitReleaseMeta_state),
    .io_in_5_bits_snpHitReleaseMeta_clients(io_in_5_bits_snpHitReleaseMeta_clients),
    .io_in_5_bits_snpHitReleaseMeta_alias(io_in_5_bits_snpHitReleaseMeta_alias),
    .io_in_5_bits_snpHitReleaseMeta_prefetch(io_in_5_bits_snpHitReleaseMeta_prefetch),
    .io_in_5_bits_snpHitReleaseMeta_prefetchSrc(io_in_5_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_5_bits_snpHitReleaseMeta_accessed(io_in_5_bits_snpHitReleaseMeta_accessed),
    .io_in_5_bits_snpHitReleaseMeta_tagErr(io_in_5_bits_snpHitReleaseMeta_tagErr),
    .io_in_5_bits_snpHitReleaseMeta_dataErr(io_in_5_bits_snpHitReleaseMeta_dataErr),
    .io_in_5_bits_tgtID(io_in_5_bits_tgtID),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_homeNID(io_in_5_bits_homeNID),
    .io_in_5_bits_dbID(io_in_5_bits_dbID),
    .io_in_5_bits_chiOpcode(io_in_5_bits_chiOpcode),
    .io_in_5_bits_resp(io_in_5_bits_resp),
    .io_in_5_bits_fwdState(io_in_5_bits_fwdState),
    .io_in_5_bits_retToSrc(io_in_5_bits_retToSrc),
    .io_in_5_bits_likelyshared(io_in_5_bits_likelyshared),
    .io_in_5_bits_expCompAck(io_in_5_bits_expCompAck),
    .io_in_5_bits_allowRetry(io_in_5_bits_allowRetry),
    .io_in_5_bits_memAttr_allocate(io_in_5_bits_memAttr_allocate),
    .io_in_5_bits_memAttr_cacheable(io_in_5_bits_memAttr_cacheable),
    .io_in_5_bits_memAttr_ewa(io_in_5_bits_memAttr_ewa),
    .io_in_5_bits_traceTag(io_in_5_bits_traceTag),
    .io_in_5_bits_dataCheckErr(io_in_5_bits_dataCheckErr),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_channel(io_in_6_bits_channel),
    .io_in_6_bits_txChannel(io_in_6_bits_txChannel),
    .io_in_6_bits_set(io_in_6_bits_set),
    .io_in_6_bits_tag(io_in_6_bits_tag),
    .io_in_6_bits_off(io_in_6_bits_off),
    .io_in_6_bits_alias(io_in_6_bits_alias),
    .io_in_6_bits_isKeyword(io_in_6_bits_isKeyword),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_param(io_in_6_bits_param),
    .io_in_6_bits_size(io_in_6_bits_size),
    .io_in_6_bits_sourceId(io_in_6_bits_sourceId),
    .io_in_6_bits_denied(io_in_6_bits_denied),
    .io_in_6_bits_corrupt(io_in_6_bits_corrupt),
    .io_in_6_bits_mshrId(io_in_6_bits_mshrId),
    .io_in_6_bits_aliasTask(io_in_6_bits_aliasTask),
    .io_in_6_bits_useProbeData(io_in_6_bits_useProbeData),
    .io_in_6_bits_mshrRetry(io_in_6_bits_mshrRetry),
    .io_in_6_bits_readProbeDataDown(io_in_6_bits_readProbeDataDown),
    .io_in_6_bits_fromL2pft(io_in_6_bits_fromL2pft),
    .io_in_6_bits_dirty(io_in_6_bits_dirty),
    .io_in_6_bits_way(io_in_6_bits_way),
    .io_in_6_bits_meta_dirty(io_in_6_bits_meta_dirty),
    .io_in_6_bits_meta_state(io_in_6_bits_meta_state),
    .io_in_6_bits_meta_clients(io_in_6_bits_meta_clients),
    .io_in_6_bits_meta_alias(io_in_6_bits_meta_alias),
    .io_in_6_bits_meta_prefetch(io_in_6_bits_meta_prefetch),
    .io_in_6_bits_meta_prefetchSrc(io_in_6_bits_meta_prefetchSrc),
    .io_in_6_bits_meta_accessed(io_in_6_bits_meta_accessed),
    .io_in_6_bits_meta_tagErr(io_in_6_bits_meta_tagErr),
    .io_in_6_bits_meta_dataErr(io_in_6_bits_meta_dataErr),
    .io_in_6_bits_metaWen(io_in_6_bits_metaWen),
    .io_in_6_bits_tagWen(io_in_6_bits_tagWen),
    .io_in_6_bits_dsWen(io_in_6_bits_dsWen),
    .io_in_6_bits_replTask(io_in_6_bits_replTask),
    .io_in_6_bits_cmoTask(io_in_6_bits_cmoTask),
    .io_in_6_bits_reqSource(io_in_6_bits_reqSource),
    .io_in_6_bits_mergeA(io_in_6_bits_mergeA),
    .io_in_6_bits_aMergeTask_off(io_in_6_bits_aMergeTask_off),
    .io_in_6_bits_aMergeTask_alias(io_in_6_bits_aMergeTask_alias),
    .io_in_6_bits_aMergeTask_vaddr(io_in_6_bits_aMergeTask_vaddr),
    .io_in_6_bits_aMergeTask_isKeyword(io_in_6_bits_aMergeTask_isKeyword),
    .io_in_6_bits_aMergeTask_opcode(io_in_6_bits_aMergeTask_opcode),
    .io_in_6_bits_aMergeTask_param(io_in_6_bits_aMergeTask_param),
    .io_in_6_bits_aMergeTask_sourceId(io_in_6_bits_aMergeTask_sourceId),
    .io_in_6_bits_aMergeTask_meta_dirty(io_in_6_bits_aMergeTask_meta_dirty),
    .io_in_6_bits_aMergeTask_meta_state(io_in_6_bits_aMergeTask_meta_state),
    .io_in_6_bits_aMergeTask_meta_clients(io_in_6_bits_aMergeTask_meta_clients),
    .io_in_6_bits_aMergeTask_meta_alias(io_in_6_bits_aMergeTask_meta_alias),
    .io_in_6_bits_aMergeTask_meta_accessed(io_in_6_bits_aMergeTask_meta_accessed),
    .io_in_6_bits_snpHitRelease(io_in_6_bits_snpHitRelease),
    .io_in_6_bits_snpHitReleaseToInval(io_in_6_bits_snpHitReleaseToInval),
    .io_in_6_bits_snpHitReleaseToClean(io_in_6_bits_snpHitReleaseToClean),
    .io_in_6_bits_snpHitReleaseWithData(io_in_6_bits_snpHitReleaseWithData),
    .io_in_6_bits_snpHitReleaseIdx(io_in_6_bits_snpHitReleaseIdx),
    .io_in_6_bits_snpHitReleaseMeta_dirty(io_in_6_bits_snpHitReleaseMeta_dirty),
    .io_in_6_bits_snpHitReleaseMeta_state(io_in_6_bits_snpHitReleaseMeta_state),
    .io_in_6_bits_snpHitReleaseMeta_clients(io_in_6_bits_snpHitReleaseMeta_clients),
    .io_in_6_bits_snpHitReleaseMeta_alias(io_in_6_bits_snpHitReleaseMeta_alias),
    .io_in_6_bits_snpHitReleaseMeta_prefetch(io_in_6_bits_snpHitReleaseMeta_prefetch),
    .io_in_6_bits_snpHitReleaseMeta_prefetchSrc(io_in_6_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_6_bits_snpHitReleaseMeta_accessed(io_in_6_bits_snpHitReleaseMeta_accessed),
    .io_in_6_bits_snpHitReleaseMeta_tagErr(io_in_6_bits_snpHitReleaseMeta_tagErr),
    .io_in_6_bits_snpHitReleaseMeta_dataErr(io_in_6_bits_snpHitReleaseMeta_dataErr),
    .io_in_6_bits_tgtID(io_in_6_bits_tgtID),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_homeNID(io_in_6_bits_homeNID),
    .io_in_6_bits_dbID(io_in_6_bits_dbID),
    .io_in_6_bits_chiOpcode(io_in_6_bits_chiOpcode),
    .io_in_6_bits_resp(io_in_6_bits_resp),
    .io_in_6_bits_fwdState(io_in_6_bits_fwdState),
    .io_in_6_bits_retToSrc(io_in_6_bits_retToSrc),
    .io_in_6_bits_likelyshared(io_in_6_bits_likelyshared),
    .io_in_6_bits_expCompAck(io_in_6_bits_expCompAck),
    .io_in_6_bits_allowRetry(io_in_6_bits_allowRetry),
    .io_in_6_bits_memAttr_allocate(io_in_6_bits_memAttr_allocate),
    .io_in_6_bits_memAttr_cacheable(io_in_6_bits_memAttr_cacheable),
    .io_in_6_bits_memAttr_ewa(io_in_6_bits_memAttr_ewa),
    .io_in_6_bits_traceTag(io_in_6_bits_traceTag),
    .io_in_6_bits_dataCheckErr(io_in_6_bits_dataCheckErr),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_channel(io_in_7_bits_channel),
    .io_in_7_bits_txChannel(io_in_7_bits_txChannel),
    .io_in_7_bits_set(io_in_7_bits_set),
    .io_in_7_bits_tag(io_in_7_bits_tag),
    .io_in_7_bits_off(io_in_7_bits_off),
    .io_in_7_bits_alias(io_in_7_bits_alias),
    .io_in_7_bits_isKeyword(io_in_7_bits_isKeyword),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_param(io_in_7_bits_param),
    .io_in_7_bits_size(io_in_7_bits_size),
    .io_in_7_bits_sourceId(io_in_7_bits_sourceId),
    .io_in_7_bits_denied(io_in_7_bits_denied),
    .io_in_7_bits_corrupt(io_in_7_bits_corrupt),
    .io_in_7_bits_mshrId(io_in_7_bits_mshrId),
    .io_in_7_bits_aliasTask(io_in_7_bits_aliasTask),
    .io_in_7_bits_useProbeData(io_in_7_bits_useProbeData),
    .io_in_7_bits_mshrRetry(io_in_7_bits_mshrRetry),
    .io_in_7_bits_readProbeDataDown(io_in_7_bits_readProbeDataDown),
    .io_in_7_bits_fromL2pft(io_in_7_bits_fromL2pft),
    .io_in_7_bits_dirty(io_in_7_bits_dirty),
    .io_in_7_bits_way(io_in_7_bits_way),
    .io_in_7_bits_meta_dirty(io_in_7_bits_meta_dirty),
    .io_in_7_bits_meta_state(io_in_7_bits_meta_state),
    .io_in_7_bits_meta_clients(io_in_7_bits_meta_clients),
    .io_in_7_bits_meta_alias(io_in_7_bits_meta_alias),
    .io_in_7_bits_meta_prefetch(io_in_7_bits_meta_prefetch),
    .io_in_7_bits_meta_prefetchSrc(io_in_7_bits_meta_prefetchSrc),
    .io_in_7_bits_meta_accessed(io_in_7_bits_meta_accessed),
    .io_in_7_bits_meta_tagErr(io_in_7_bits_meta_tagErr),
    .io_in_7_bits_meta_dataErr(io_in_7_bits_meta_dataErr),
    .io_in_7_bits_metaWen(io_in_7_bits_metaWen),
    .io_in_7_bits_tagWen(io_in_7_bits_tagWen),
    .io_in_7_bits_dsWen(io_in_7_bits_dsWen),
    .io_in_7_bits_replTask(io_in_7_bits_replTask),
    .io_in_7_bits_cmoTask(io_in_7_bits_cmoTask),
    .io_in_7_bits_reqSource(io_in_7_bits_reqSource),
    .io_in_7_bits_mergeA(io_in_7_bits_mergeA),
    .io_in_7_bits_aMergeTask_off(io_in_7_bits_aMergeTask_off),
    .io_in_7_bits_aMergeTask_alias(io_in_7_bits_aMergeTask_alias),
    .io_in_7_bits_aMergeTask_vaddr(io_in_7_bits_aMergeTask_vaddr),
    .io_in_7_bits_aMergeTask_isKeyword(io_in_7_bits_aMergeTask_isKeyword),
    .io_in_7_bits_aMergeTask_opcode(io_in_7_bits_aMergeTask_opcode),
    .io_in_7_bits_aMergeTask_param(io_in_7_bits_aMergeTask_param),
    .io_in_7_bits_aMergeTask_sourceId(io_in_7_bits_aMergeTask_sourceId),
    .io_in_7_bits_aMergeTask_meta_dirty(io_in_7_bits_aMergeTask_meta_dirty),
    .io_in_7_bits_aMergeTask_meta_state(io_in_7_bits_aMergeTask_meta_state),
    .io_in_7_bits_aMergeTask_meta_clients(io_in_7_bits_aMergeTask_meta_clients),
    .io_in_7_bits_aMergeTask_meta_alias(io_in_7_bits_aMergeTask_meta_alias),
    .io_in_7_bits_aMergeTask_meta_accessed(io_in_7_bits_aMergeTask_meta_accessed),
    .io_in_7_bits_snpHitRelease(io_in_7_bits_snpHitRelease),
    .io_in_7_bits_snpHitReleaseToInval(io_in_7_bits_snpHitReleaseToInval),
    .io_in_7_bits_snpHitReleaseToClean(io_in_7_bits_snpHitReleaseToClean),
    .io_in_7_bits_snpHitReleaseWithData(io_in_7_bits_snpHitReleaseWithData),
    .io_in_7_bits_snpHitReleaseIdx(io_in_7_bits_snpHitReleaseIdx),
    .io_in_7_bits_snpHitReleaseMeta_dirty(io_in_7_bits_snpHitReleaseMeta_dirty),
    .io_in_7_bits_snpHitReleaseMeta_state(io_in_7_bits_snpHitReleaseMeta_state),
    .io_in_7_bits_snpHitReleaseMeta_clients(io_in_7_bits_snpHitReleaseMeta_clients),
    .io_in_7_bits_snpHitReleaseMeta_alias(io_in_7_bits_snpHitReleaseMeta_alias),
    .io_in_7_bits_snpHitReleaseMeta_prefetch(io_in_7_bits_snpHitReleaseMeta_prefetch),
    .io_in_7_bits_snpHitReleaseMeta_prefetchSrc(io_in_7_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_7_bits_snpHitReleaseMeta_accessed(io_in_7_bits_snpHitReleaseMeta_accessed),
    .io_in_7_bits_snpHitReleaseMeta_tagErr(io_in_7_bits_snpHitReleaseMeta_tagErr),
    .io_in_7_bits_snpHitReleaseMeta_dataErr(io_in_7_bits_snpHitReleaseMeta_dataErr),
    .io_in_7_bits_tgtID(io_in_7_bits_tgtID),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_homeNID(io_in_7_bits_homeNID),
    .io_in_7_bits_dbID(io_in_7_bits_dbID),
    .io_in_7_bits_chiOpcode(io_in_7_bits_chiOpcode),
    .io_in_7_bits_resp(io_in_7_bits_resp),
    .io_in_7_bits_fwdState(io_in_7_bits_fwdState),
    .io_in_7_bits_retToSrc(io_in_7_bits_retToSrc),
    .io_in_7_bits_likelyshared(io_in_7_bits_likelyshared),
    .io_in_7_bits_expCompAck(io_in_7_bits_expCompAck),
    .io_in_7_bits_allowRetry(io_in_7_bits_allowRetry),
    .io_in_7_bits_memAttr_allocate(io_in_7_bits_memAttr_allocate),
    .io_in_7_bits_memAttr_cacheable(io_in_7_bits_memAttr_cacheable),
    .io_in_7_bits_memAttr_ewa(io_in_7_bits_memAttr_ewa),
    .io_in_7_bits_traceTag(io_in_7_bits_traceTag),
    .io_in_7_bits_dataCheckErr(io_in_7_bits_dataCheckErr),
    .io_in_8_ready(g_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_channel(io_in_8_bits_channel),
    .io_in_8_bits_txChannel(io_in_8_bits_txChannel),
    .io_in_8_bits_set(io_in_8_bits_set),
    .io_in_8_bits_tag(io_in_8_bits_tag),
    .io_in_8_bits_off(io_in_8_bits_off),
    .io_in_8_bits_alias(io_in_8_bits_alias),
    .io_in_8_bits_isKeyword(io_in_8_bits_isKeyword),
    .io_in_8_bits_opcode(io_in_8_bits_opcode),
    .io_in_8_bits_param(io_in_8_bits_param),
    .io_in_8_bits_size(io_in_8_bits_size),
    .io_in_8_bits_sourceId(io_in_8_bits_sourceId),
    .io_in_8_bits_denied(io_in_8_bits_denied),
    .io_in_8_bits_corrupt(io_in_8_bits_corrupt),
    .io_in_8_bits_mshrId(io_in_8_bits_mshrId),
    .io_in_8_bits_aliasTask(io_in_8_bits_aliasTask),
    .io_in_8_bits_useProbeData(io_in_8_bits_useProbeData),
    .io_in_8_bits_mshrRetry(io_in_8_bits_mshrRetry),
    .io_in_8_bits_readProbeDataDown(io_in_8_bits_readProbeDataDown),
    .io_in_8_bits_fromL2pft(io_in_8_bits_fromL2pft),
    .io_in_8_bits_dirty(io_in_8_bits_dirty),
    .io_in_8_bits_way(io_in_8_bits_way),
    .io_in_8_bits_meta_dirty(io_in_8_bits_meta_dirty),
    .io_in_8_bits_meta_state(io_in_8_bits_meta_state),
    .io_in_8_bits_meta_clients(io_in_8_bits_meta_clients),
    .io_in_8_bits_meta_alias(io_in_8_bits_meta_alias),
    .io_in_8_bits_meta_prefetch(io_in_8_bits_meta_prefetch),
    .io_in_8_bits_meta_prefetchSrc(io_in_8_bits_meta_prefetchSrc),
    .io_in_8_bits_meta_accessed(io_in_8_bits_meta_accessed),
    .io_in_8_bits_meta_tagErr(io_in_8_bits_meta_tagErr),
    .io_in_8_bits_meta_dataErr(io_in_8_bits_meta_dataErr),
    .io_in_8_bits_metaWen(io_in_8_bits_metaWen),
    .io_in_8_bits_tagWen(io_in_8_bits_tagWen),
    .io_in_8_bits_dsWen(io_in_8_bits_dsWen),
    .io_in_8_bits_replTask(io_in_8_bits_replTask),
    .io_in_8_bits_cmoTask(io_in_8_bits_cmoTask),
    .io_in_8_bits_reqSource(io_in_8_bits_reqSource),
    .io_in_8_bits_mergeA(io_in_8_bits_mergeA),
    .io_in_8_bits_aMergeTask_off(io_in_8_bits_aMergeTask_off),
    .io_in_8_bits_aMergeTask_alias(io_in_8_bits_aMergeTask_alias),
    .io_in_8_bits_aMergeTask_vaddr(io_in_8_bits_aMergeTask_vaddr),
    .io_in_8_bits_aMergeTask_isKeyword(io_in_8_bits_aMergeTask_isKeyword),
    .io_in_8_bits_aMergeTask_opcode(io_in_8_bits_aMergeTask_opcode),
    .io_in_8_bits_aMergeTask_param(io_in_8_bits_aMergeTask_param),
    .io_in_8_bits_aMergeTask_sourceId(io_in_8_bits_aMergeTask_sourceId),
    .io_in_8_bits_aMergeTask_meta_dirty(io_in_8_bits_aMergeTask_meta_dirty),
    .io_in_8_bits_aMergeTask_meta_state(io_in_8_bits_aMergeTask_meta_state),
    .io_in_8_bits_aMergeTask_meta_clients(io_in_8_bits_aMergeTask_meta_clients),
    .io_in_8_bits_aMergeTask_meta_alias(io_in_8_bits_aMergeTask_meta_alias),
    .io_in_8_bits_aMergeTask_meta_accessed(io_in_8_bits_aMergeTask_meta_accessed),
    .io_in_8_bits_snpHitRelease(io_in_8_bits_snpHitRelease),
    .io_in_8_bits_snpHitReleaseToInval(io_in_8_bits_snpHitReleaseToInval),
    .io_in_8_bits_snpHitReleaseToClean(io_in_8_bits_snpHitReleaseToClean),
    .io_in_8_bits_snpHitReleaseWithData(io_in_8_bits_snpHitReleaseWithData),
    .io_in_8_bits_snpHitReleaseIdx(io_in_8_bits_snpHitReleaseIdx),
    .io_in_8_bits_snpHitReleaseMeta_dirty(io_in_8_bits_snpHitReleaseMeta_dirty),
    .io_in_8_bits_snpHitReleaseMeta_state(io_in_8_bits_snpHitReleaseMeta_state),
    .io_in_8_bits_snpHitReleaseMeta_clients(io_in_8_bits_snpHitReleaseMeta_clients),
    .io_in_8_bits_snpHitReleaseMeta_alias(io_in_8_bits_snpHitReleaseMeta_alias),
    .io_in_8_bits_snpHitReleaseMeta_prefetch(io_in_8_bits_snpHitReleaseMeta_prefetch),
    .io_in_8_bits_snpHitReleaseMeta_prefetchSrc(io_in_8_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_8_bits_snpHitReleaseMeta_accessed(io_in_8_bits_snpHitReleaseMeta_accessed),
    .io_in_8_bits_snpHitReleaseMeta_tagErr(io_in_8_bits_snpHitReleaseMeta_tagErr),
    .io_in_8_bits_snpHitReleaseMeta_dataErr(io_in_8_bits_snpHitReleaseMeta_dataErr),
    .io_in_8_bits_tgtID(io_in_8_bits_tgtID),
    .io_in_8_bits_txnID(io_in_8_bits_txnID),
    .io_in_8_bits_homeNID(io_in_8_bits_homeNID),
    .io_in_8_bits_dbID(io_in_8_bits_dbID),
    .io_in_8_bits_chiOpcode(io_in_8_bits_chiOpcode),
    .io_in_8_bits_resp(io_in_8_bits_resp),
    .io_in_8_bits_fwdState(io_in_8_bits_fwdState),
    .io_in_8_bits_retToSrc(io_in_8_bits_retToSrc),
    .io_in_8_bits_likelyshared(io_in_8_bits_likelyshared),
    .io_in_8_bits_expCompAck(io_in_8_bits_expCompAck),
    .io_in_8_bits_allowRetry(io_in_8_bits_allowRetry),
    .io_in_8_bits_memAttr_allocate(io_in_8_bits_memAttr_allocate),
    .io_in_8_bits_memAttr_cacheable(io_in_8_bits_memAttr_cacheable),
    .io_in_8_bits_memAttr_ewa(io_in_8_bits_memAttr_ewa),
    .io_in_8_bits_traceTag(io_in_8_bits_traceTag),
    .io_in_8_bits_dataCheckErr(io_in_8_bits_dataCheckErr),
    .io_in_9_ready(g_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_channel(io_in_9_bits_channel),
    .io_in_9_bits_txChannel(io_in_9_bits_txChannel),
    .io_in_9_bits_set(io_in_9_bits_set),
    .io_in_9_bits_tag(io_in_9_bits_tag),
    .io_in_9_bits_off(io_in_9_bits_off),
    .io_in_9_bits_alias(io_in_9_bits_alias),
    .io_in_9_bits_isKeyword(io_in_9_bits_isKeyword),
    .io_in_9_bits_opcode(io_in_9_bits_opcode),
    .io_in_9_bits_param(io_in_9_bits_param),
    .io_in_9_bits_size(io_in_9_bits_size),
    .io_in_9_bits_sourceId(io_in_9_bits_sourceId),
    .io_in_9_bits_denied(io_in_9_bits_denied),
    .io_in_9_bits_corrupt(io_in_9_bits_corrupt),
    .io_in_9_bits_mshrId(io_in_9_bits_mshrId),
    .io_in_9_bits_aliasTask(io_in_9_bits_aliasTask),
    .io_in_9_bits_useProbeData(io_in_9_bits_useProbeData),
    .io_in_9_bits_mshrRetry(io_in_9_bits_mshrRetry),
    .io_in_9_bits_readProbeDataDown(io_in_9_bits_readProbeDataDown),
    .io_in_9_bits_fromL2pft(io_in_9_bits_fromL2pft),
    .io_in_9_bits_dirty(io_in_9_bits_dirty),
    .io_in_9_bits_way(io_in_9_bits_way),
    .io_in_9_bits_meta_dirty(io_in_9_bits_meta_dirty),
    .io_in_9_bits_meta_state(io_in_9_bits_meta_state),
    .io_in_9_bits_meta_clients(io_in_9_bits_meta_clients),
    .io_in_9_bits_meta_alias(io_in_9_bits_meta_alias),
    .io_in_9_bits_meta_prefetch(io_in_9_bits_meta_prefetch),
    .io_in_9_bits_meta_prefetchSrc(io_in_9_bits_meta_prefetchSrc),
    .io_in_9_bits_meta_accessed(io_in_9_bits_meta_accessed),
    .io_in_9_bits_meta_tagErr(io_in_9_bits_meta_tagErr),
    .io_in_9_bits_meta_dataErr(io_in_9_bits_meta_dataErr),
    .io_in_9_bits_metaWen(io_in_9_bits_metaWen),
    .io_in_9_bits_tagWen(io_in_9_bits_tagWen),
    .io_in_9_bits_dsWen(io_in_9_bits_dsWen),
    .io_in_9_bits_replTask(io_in_9_bits_replTask),
    .io_in_9_bits_cmoTask(io_in_9_bits_cmoTask),
    .io_in_9_bits_reqSource(io_in_9_bits_reqSource),
    .io_in_9_bits_mergeA(io_in_9_bits_mergeA),
    .io_in_9_bits_aMergeTask_off(io_in_9_bits_aMergeTask_off),
    .io_in_9_bits_aMergeTask_alias(io_in_9_bits_aMergeTask_alias),
    .io_in_9_bits_aMergeTask_vaddr(io_in_9_bits_aMergeTask_vaddr),
    .io_in_9_bits_aMergeTask_isKeyword(io_in_9_bits_aMergeTask_isKeyword),
    .io_in_9_bits_aMergeTask_opcode(io_in_9_bits_aMergeTask_opcode),
    .io_in_9_bits_aMergeTask_param(io_in_9_bits_aMergeTask_param),
    .io_in_9_bits_aMergeTask_sourceId(io_in_9_bits_aMergeTask_sourceId),
    .io_in_9_bits_aMergeTask_meta_dirty(io_in_9_bits_aMergeTask_meta_dirty),
    .io_in_9_bits_aMergeTask_meta_state(io_in_9_bits_aMergeTask_meta_state),
    .io_in_9_bits_aMergeTask_meta_clients(io_in_9_bits_aMergeTask_meta_clients),
    .io_in_9_bits_aMergeTask_meta_alias(io_in_9_bits_aMergeTask_meta_alias),
    .io_in_9_bits_aMergeTask_meta_accessed(io_in_9_bits_aMergeTask_meta_accessed),
    .io_in_9_bits_snpHitRelease(io_in_9_bits_snpHitRelease),
    .io_in_9_bits_snpHitReleaseToInval(io_in_9_bits_snpHitReleaseToInval),
    .io_in_9_bits_snpHitReleaseToClean(io_in_9_bits_snpHitReleaseToClean),
    .io_in_9_bits_snpHitReleaseWithData(io_in_9_bits_snpHitReleaseWithData),
    .io_in_9_bits_snpHitReleaseIdx(io_in_9_bits_snpHitReleaseIdx),
    .io_in_9_bits_snpHitReleaseMeta_dirty(io_in_9_bits_snpHitReleaseMeta_dirty),
    .io_in_9_bits_snpHitReleaseMeta_state(io_in_9_bits_snpHitReleaseMeta_state),
    .io_in_9_bits_snpHitReleaseMeta_clients(io_in_9_bits_snpHitReleaseMeta_clients),
    .io_in_9_bits_snpHitReleaseMeta_alias(io_in_9_bits_snpHitReleaseMeta_alias),
    .io_in_9_bits_snpHitReleaseMeta_prefetch(io_in_9_bits_snpHitReleaseMeta_prefetch),
    .io_in_9_bits_snpHitReleaseMeta_prefetchSrc(io_in_9_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_9_bits_snpHitReleaseMeta_accessed(io_in_9_bits_snpHitReleaseMeta_accessed),
    .io_in_9_bits_snpHitReleaseMeta_tagErr(io_in_9_bits_snpHitReleaseMeta_tagErr),
    .io_in_9_bits_snpHitReleaseMeta_dataErr(io_in_9_bits_snpHitReleaseMeta_dataErr),
    .io_in_9_bits_tgtID(io_in_9_bits_tgtID),
    .io_in_9_bits_txnID(io_in_9_bits_txnID),
    .io_in_9_bits_homeNID(io_in_9_bits_homeNID),
    .io_in_9_bits_dbID(io_in_9_bits_dbID),
    .io_in_9_bits_chiOpcode(io_in_9_bits_chiOpcode),
    .io_in_9_bits_resp(io_in_9_bits_resp),
    .io_in_9_bits_fwdState(io_in_9_bits_fwdState),
    .io_in_9_bits_retToSrc(io_in_9_bits_retToSrc),
    .io_in_9_bits_likelyshared(io_in_9_bits_likelyshared),
    .io_in_9_bits_expCompAck(io_in_9_bits_expCompAck),
    .io_in_9_bits_allowRetry(io_in_9_bits_allowRetry),
    .io_in_9_bits_memAttr_allocate(io_in_9_bits_memAttr_allocate),
    .io_in_9_bits_memAttr_cacheable(io_in_9_bits_memAttr_cacheable),
    .io_in_9_bits_memAttr_ewa(io_in_9_bits_memAttr_ewa),
    .io_in_9_bits_traceTag(io_in_9_bits_traceTag),
    .io_in_9_bits_dataCheckErr(io_in_9_bits_dataCheckErr),
    .io_in_10_ready(g_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_channel(io_in_10_bits_channel),
    .io_in_10_bits_txChannel(io_in_10_bits_txChannel),
    .io_in_10_bits_set(io_in_10_bits_set),
    .io_in_10_bits_tag(io_in_10_bits_tag),
    .io_in_10_bits_off(io_in_10_bits_off),
    .io_in_10_bits_alias(io_in_10_bits_alias),
    .io_in_10_bits_isKeyword(io_in_10_bits_isKeyword),
    .io_in_10_bits_opcode(io_in_10_bits_opcode),
    .io_in_10_bits_param(io_in_10_bits_param),
    .io_in_10_bits_size(io_in_10_bits_size),
    .io_in_10_bits_sourceId(io_in_10_bits_sourceId),
    .io_in_10_bits_denied(io_in_10_bits_denied),
    .io_in_10_bits_corrupt(io_in_10_bits_corrupt),
    .io_in_10_bits_mshrId(io_in_10_bits_mshrId),
    .io_in_10_bits_aliasTask(io_in_10_bits_aliasTask),
    .io_in_10_bits_useProbeData(io_in_10_bits_useProbeData),
    .io_in_10_bits_mshrRetry(io_in_10_bits_mshrRetry),
    .io_in_10_bits_readProbeDataDown(io_in_10_bits_readProbeDataDown),
    .io_in_10_bits_fromL2pft(io_in_10_bits_fromL2pft),
    .io_in_10_bits_dirty(io_in_10_bits_dirty),
    .io_in_10_bits_way(io_in_10_bits_way),
    .io_in_10_bits_meta_dirty(io_in_10_bits_meta_dirty),
    .io_in_10_bits_meta_state(io_in_10_bits_meta_state),
    .io_in_10_bits_meta_clients(io_in_10_bits_meta_clients),
    .io_in_10_bits_meta_alias(io_in_10_bits_meta_alias),
    .io_in_10_bits_meta_prefetch(io_in_10_bits_meta_prefetch),
    .io_in_10_bits_meta_prefetchSrc(io_in_10_bits_meta_prefetchSrc),
    .io_in_10_bits_meta_accessed(io_in_10_bits_meta_accessed),
    .io_in_10_bits_meta_tagErr(io_in_10_bits_meta_tagErr),
    .io_in_10_bits_meta_dataErr(io_in_10_bits_meta_dataErr),
    .io_in_10_bits_metaWen(io_in_10_bits_metaWen),
    .io_in_10_bits_tagWen(io_in_10_bits_tagWen),
    .io_in_10_bits_dsWen(io_in_10_bits_dsWen),
    .io_in_10_bits_replTask(io_in_10_bits_replTask),
    .io_in_10_bits_cmoTask(io_in_10_bits_cmoTask),
    .io_in_10_bits_reqSource(io_in_10_bits_reqSource),
    .io_in_10_bits_mergeA(io_in_10_bits_mergeA),
    .io_in_10_bits_aMergeTask_off(io_in_10_bits_aMergeTask_off),
    .io_in_10_bits_aMergeTask_alias(io_in_10_bits_aMergeTask_alias),
    .io_in_10_bits_aMergeTask_vaddr(io_in_10_bits_aMergeTask_vaddr),
    .io_in_10_bits_aMergeTask_isKeyword(io_in_10_bits_aMergeTask_isKeyword),
    .io_in_10_bits_aMergeTask_opcode(io_in_10_bits_aMergeTask_opcode),
    .io_in_10_bits_aMergeTask_param(io_in_10_bits_aMergeTask_param),
    .io_in_10_bits_aMergeTask_sourceId(io_in_10_bits_aMergeTask_sourceId),
    .io_in_10_bits_aMergeTask_meta_dirty(io_in_10_bits_aMergeTask_meta_dirty),
    .io_in_10_bits_aMergeTask_meta_state(io_in_10_bits_aMergeTask_meta_state),
    .io_in_10_bits_aMergeTask_meta_clients(io_in_10_bits_aMergeTask_meta_clients),
    .io_in_10_bits_aMergeTask_meta_alias(io_in_10_bits_aMergeTask_meta_alias),
    .io_in_10_bits_aMergeTask_meta_accessed(io_in_10_bits_aMergeTask_meta_accessed),
    .io_in_10_bits_snpHitRelease(io_in_10_bits_snpHitRelease),
    .io_in_10_bits_snpHitReleaseToInval(io_in_10_bits_snpHitReleaseToInval),
    .io_in_10_bits_snpHitReleaseToClean(io_in_10_bits_snpHitReleaseToClean),
    .io_in_10_bits_snpHitReleaseWithData(io_in_10_bits_snpHitReleaseWithData),
    .io_in_10_bits_snpHitReleaseIdx(io_in_10_bits_snpHitReleaseIdx),
    .io_in_10_bits_snpHitReleaseMeta_dirty(io_in_10_bits_snpHitReleaseMeta_dirty),
    .io_in_10_bits_snpHitReleaseMeta_state(io_in_10_bits_snpHitReleaseMeta_state),
    .io_in_10_bits_snpHitReleaseMeta_clients(io_in_10_bits_snpHitReleaseMeta_clients),
    .io_in_10_bits_snpHitReleaseMeta_alias(io_in_10_bits_snpHitReleaseMeta_alias),
    .io_in_10_bits_snpHitReleaseMeta_prefetch(io_in_10_bits_snpHitReleaseMeta_prefetch),
    .io_in_10_bits_snpHitReleaseMeta_prefetchSrc(io_in_10_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_10_bits_snpHitReleaseMeta_accessed(io_in_10_bits_snpHitReleaseMeta_accessed),
    .io_in_10_bits_snpHitReleaseMeta_tagErr(io_in_10_bits_snpHitReleaseMeta_tagErr),
    .io_in_10_bits_snpHitReleaseMeta_dataErr(io_in_10_bits_snpHitReleaseMeta_dataErr),
    .io_in_10_bits_tgtID(io_in_10_bits_tgtID),
    .io_in_10_bits_txnID(io_in_10_bits_txnID),
    .io_in_10_bits_homeNID(io_in_10_bits_homeNID),
    .io_in_10_bits_dbID(io_in_10_bits_dbID),
    .io_in_10_bits_chiOpcode(io_in_10_bits_chiOpcode),
    .io_in_10_bits_resp(io_in_10_bits_resp),
    .io_in_10_bits_fwdState(io_in_10_bits_fwdState),
    .io_in_10_bits_retToSrc(io_in_10_bits_retToSrc),
    .io_in_10_bits_likelyshared(io_in_10_bits_likelyshared),
    .io_in_10_bits_expCompAck(io_in_10_bits_expCompAck),
    .io_in_10_bits_allowRetry(io_in_10_bits_allowRetry),
    .io_in_10_bits_memAttr_allocate(io_in_10_bits_memAttr_allocate),
    .io_in_10_bits_memAttr_cacheable(io_in_10_bits_memAttr_cacheable),
    .io_in_10_bits_memAttr_ewa(io_in_10_bits_memAttr_ewa),
    .io_in_10_bits_traceTag(io_in_10_bits_traceTag),
    .io_in_10_bits_dataCheckErr(io_in_10_bits_dataCheckErr),
    .io_in_11_ready(g_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_channel(io_in_11_bits_channel),
    .io_in_11_bits_txChannel(io_in_11_bits_txChannel),
    .io_in_11_bits_set(io_in_11_bits_set),
    .io_in_11_bits_tag(io_in_11_bits_tag),
    .io_in_11_bits_off(io_in_11_bits_off),
    .io_in_11_bits_alias(io_in_11_bits_alias),
    .io_in_11_bits_isKeyword(io_in_11_bits_isKeyword),
    .io_in_11_bits_opcode(io_in_11_bits_opcode),
    .io_in_11_bits_param(io_in_11_bits_param),
    .io_in_11_bits_size(io_in_11_bits_size),
    .io_in_11_bits_sourceId(io_in_11_bits_sourceId),
    .io_in_11_bits_denied(io_in_11_bits_denied),
    .io_in_11_bits_corrupt(io_in_11_bits_corrupt),
    .io_in_11_bits_mshrId(io_in_11_bits_mshrId),
    .io_in_11_bits_aliasTask(io_in_11_bits_aliasTask),
    .io_in_11_bits_useProbeData(io_in_11_bits_useProbeData),
    .io_in_11_bits_mshrRetry(io_in_11_bits_mshrRetry),
    .io_in_11_bits_readProbeDataDown(io_in_11_bits_readProbeDataDown),
    .io_in_11_bits_fromL2pft(io_in_11_bits_fromL2pft),
    .io_in_11_bits_dirty(io_in_11_bits_dirty),
    .io_in_11_bits_way(io_in_11_bits_way),
    .io_in_11_bits_meta_dirty(io_in_11_bits_meta_dirty),
    .io_in_11_bits_meta_state(io_in_11_bits_meta_state),
    .io_in_11_bits_meta_clients(io_in_11_bits_meta_clients),
    .io_in_11_bits_meta_alias(io_in_11_bits_meta_alias),
    .io_in_11_bits_meta_prefetch(io_in_11_bits_meta_prefetch),
    .io_in_11_bits_meta_prefetchSrc(io_in_11_bits_meta_prefetchSrc),
    .io_in_11_bits_meta_accessed(io_in_11_bits_meta_accessed),
    .io_in_11_bits_meta_tagErr(io_in_11_bits_meta_tagErr),
    .io_in_11_bits_meta_dataErr(io_in_11_bits_meta_dataErr),
    .io_in_11_bits_metaWen(io_in_11_bits_metaWen),
    .io_in_11_bits_tagWen(io_in_11_bits_tagWen),
    .io_in_11_bits_dsWen(io_in_11_bits_dsWen),
    .io_in_11_bits_replTask(io_in_11_bits_replTask),
    .io_in_11_bits_cmoTask(io_in_11_bits_cmoTask),
    .io_in_11_bits_reqSource(io_in_11_bits_reqSource),
    .io_in_11_bits_mergeA(io_in_11_bits_mergeA),
    .io_in_11_bits_aMergeTask_off(io_in_11_bits_aMergeTask_off),
    .io_in_11_bits_aMergeTask_alias(io_in_11_bits_aMergeTask_alias),
    .io_in_11_bits_aMergeTask_vaddr(io_in_11_bits_aMergeTask_vaddr),
    .io_in_11_bits_aMergeTask_isKeyword(io_in_11_bits_aMergeTask_isKeyword),
    .io_in_11_bits_aMergeTask_opcode(io_in_11_bits_aMergeTask_opcode),
    .io_in_11_bits_aMergeTask_param(io_in_11_bits_aMergeTask_param),
    .io_in_11_bits_aMergeTask_sourceId(io_in_11_bits_aMergeTask_sourceId),
    .io_in_11_bits_aMergeTask_meta_dirty(io_in_11_bits_aMergeTask_meta_dirty),
    .io_in_11_bits_aMergeTask_meta_state(io_in_11_bits_aMergeTask_meta_state),
    .io_in_11_bits_aMergeTask_meta_clients(io_in_11_bits_aMergeTask_meta_clients),
    .io_in_11_bits_aMergeTask_meta_alias(io_in_11_bits_aMergeTask_meta_alias),
    .io_in_11_bits_aMergeTask_meta_accessed(io_in_11_bits_aMergeTask_meta_accessed),
    .io_in_11_bits_snpHitRelease(io_in_11_bits_snpHitRelease),
    .io_in_11_bits_snpHitReleaseToInval(io_in_11_bits_snpHitReleaseToInval),
    .io_in_11_bits_snpHitReleaseToClean(io_in_11_bits_snpHitReleaseToClean),
    .io_in_11_bits_snpHitReleaseWithData(io_in_11_bits_snpHitReleaseWithData),
    .io_in_11_bits_snpHitReleaseIdx(io_in_11_bits_snpHitReleaseIdx),
    .io_in_11_bits_snpHitReleaseMeta_dirty(io_in_11_bits_snpHitReleaseMeta_dirty),
    .io_in_11_bits_snpHitReleaseMeta_state(io_in_11_bits_snpHitReleaseMeta_state),
    .io_in_11_bits_snpHitReleaseMeta_clients(io_in_11_bits_snpHitReleaseMeta_clients),
    .io_in_11_bits_snpHitReleaseMeta_alias(io_in_11_bits_snpHitReleaseMeta_alias),
    .io_in_11_bits_snpHitReleaseMeta_prefetch(io_in_11_bits_snpHitReleaseMeta_prefetch),
    .io_in_11_bits_snpHitReleaseMeta_prefetchSrc(io_in_11_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_11_bits_snpHitReleaseMeta_accessed(io_in_11_bits_snpHitReleaseMeta_accessed),
    .io_in_11_bits_snpHitReleaseMeta_tagErr(io_in_11_bits_snpHitReleaseMeta_tagErr),
    .io_in_11_bits_snpHitReleaseMeta_dataErr(io_in_11_bits_snpHitReleaseMeta_dataErr),
    .io_in_11_bits_tgtID(io_in_11_bits_tgtID),
    .io_in_11_bits_txnID(io_in_11_bits_txnID),
    .io_in_11_bits_homeNID(io_in_11_bits_homeNID),
    .io_in_11_bits_dbID(io_in_11_bits_dbID),
    .io_in_11_bits_chiOpcode(io_in_11_bits_chiOpcode),
    .io_in_11_bits_resp(io_in_11_bits_resp),
    .io_in_11_bits_fwdState(io_in_11_bits_fwdState),
    .io_in_11_bits_retToSrc(io_in_11_bits_retToSrc),
    .io_in_11_bits_likelyshared(io_in_11_bits_likelyshared),
    .io_in_11_bits_expCompAck(io_in_11_bits_expCompAck),
    .io_in_11_bits_allowRetry(io_in_11_bits_allowRetry),
    .io_in_11_bits_memAttr_allocate(io_in_11_bits_memAttr_allocate),
    .io_in_11_bits_memAttr_cacheable(io_in_11_bits_memAttr_cacheable),
    .io_in_11_bits_memAttr_ewa(io_in_11_bits_memAttr_ewa),
    .io_in_11_bits_traceTag(io_in_11_bits_traceTag),
    .io_in_11_bits_dataCheckErr(io_in_11_bits_dataCheckErr),
    .io_in_12_ready(g_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_channel(io_in_12_bits_channel),
    .io_in_12_bits_txChannel(io_in_12_bits_txChannel),
    .io_in_12_bits_set(io_in_12_bits_set),
    .io_in_12_bits_tag(io_in_12_bits_tag),
    .io_in_12_bits_off(io_in_12_bits_off),
    .io_in_12_bits_alias(io_in_12_bits_alias),
    .io_in_12_bits_isKeyword(io_in_12_bits_isKeyword),
    .io_in_12_bits_opcode(io_in_12_bits_opcode),
    .io_in_12_bits_param(io_in_12_bits_param),
    .io_in_12_bits_size(io_in_12_bits_size),
    .io_in_12_bits_sourceId(io_in_12_bits_sourceId),
    .io_in_12_bits_denied(io_in_12_bits_denied),
    .io_in_12_bits_corrupt(io_in_12_bits_corrupt),
    .io_in_12_bits_mshrId(io_in_12_bits_mshrId),
    .io_in_12_bits_aliasTask(io_in_12_bits_aliasTask),
    .io_in_12_bits_useProbeData(io_in_12_bits_useProbeData),
    .io_in_12_bits_mshrRetry(io_in_12_bits_mshrRetry),
    .io_in_12_bits_readProbeDataDown(io_in_12_bits_readProbeDataDown),
    .io_in_12_bits_fromL2pft(io_in_12_bits_fromL2pft),
    .io_in_12_bits_dirty(io_in_12_bits_dirty),
    .io_in_12_bits_way(io_in_12_bits_way),
    .io_in_12_bits_meta_dirty(io_in_12_bits_meta_dirty),
    .io_in_12_bits_meta_state(io_in_12_bits_meta_state),
    .io_in_12_bits_meta_clients(io_in_12_bits_meta_clients),
    .io_in_12_bits_meta_alias(io_in_12_bits_meta_alias),
    .io_in_12_bits_meta_prefetch(io_in_12_bits_meta_prefetch),
    .io_in_12_bits_meta_prefetchSrc(io_in_12_bits_meta_prefetchSrc),
    .io_in_12_bits_meta_accessed(io_in_12_bits_meta_accessed),
    .io_in_12_bits_meta_tagErr(io_in_12_bits_meta_tagErr),
    .io_in_12_bits_meta_dataErr(io_in_12_bits_meta_dataErr),
    .io_in_12_bits_metaWen(io_in_12_bits_metaWen),
    .io_in_12_bits_tagWen(io_in_12_bits_tagWen),
    .io_in_12_bits_dsWen(io_in_12_bits_dsWen),
    .io_in_12_bits_replTask(io_in_12_bits_replTask),
    .io_in_12_bits_cmoTask(io_in_12_bits_cmoTask),
    .io_in_12_bits_reqSource(io_in_12_bits_reqSource),
    .io_in_12_bits_mergeA(io_in_12_bits_mergeA),
    .io_in_12_bits_aMergeTask_off(io_in_12_bits_aMergeTask_off),
    .io_in_12_bits_aMergeTask_alias(io_in_12_bits_aMergeTask_alias),
    .io_in_12_bits_aMergeTask_vaddr(io_in_12_bits_aMergeTask_vaddr),
    .io_in_12_bits_aMergeTask_isKeyword(io_in_12_bits_aMergeTask_isKeyword),
    .io_in_12_bits_aMergeTask_opcode(io_in_12_bits_aMergeTask_opcode),
    .io_in_12_bits_aMergeTask_param(io_in_12_bits_aMergeTask_param),
    .io_in_12_bits_aMergeTask_sourceId(io_in_12_bits_aMergeTask_sourceId),
    .io_in_12_bits_aMergeTask_meta_dirty(io_in_12_bits_aMergeTask_meta_dirty),
    .io_in_12_bits_aMergeTask_meta_state(io_in_12_bits_aMergeTask_meta_state),
    .io_in_12_bits_aMergeTask_meta_clients(io_in_12_bits_aMergeTask_meta_clients),
    .io_in_12_bits_aMergeTask_meta_alias(io_in_12_bits_aMergeTask_meta_alias),
    .io_in_12_bits_aMergeTask_meta_accessed(io_in_12_bits_aMergeTask_meta_accessed),
    .io_in_12_bits_snpHitRelease(io_in_12_bits_snpHitRelease),
    .io_in_12_bits_snpHitReleaseToInval(io_in_12_bits_snpHitReleaseToInval),
    .io_in_12_bits_snpHitReleaseToClean(io_in_12_bits_snpHitReleaseToClean),
    .io_in_12_bits_snpHitReleaseWithData(io_in_12_bits_snpHitReleaseWithData),
    .io_in_12_bits_snpHitReleaseIdx(io_in_12_bits_snpHitReleaseIdx),
    .io_in_12_bits_snpHitReleaseMeta_dirty(io_in_12_bits_snpHitReleaseMeta_dirty),
    .io_in_12_bits_snpHitReleaseMeta_state(io_in_12_bits_snpHitReleaseMeta_state),
    .io_in_12_bits_snpHitReleaseMeta_clients(io_in_12_bits_snpHitReleaseMeta_clients),
    .io_in_12_bits_snpHitReleaseMeta_alias(io_in_12_bits_snpHitReleaseMeta_alias),
    .io_in_12_bits_snpHitReleaseMeta_prefetch(io_in_12_bits_snpHitReleaseMeta_prefetch),
    .io_in_12_bits_snpHitReleaseMeta_prefetchSrc(io_in_12_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_12_bits_snpHitReleaseMeta_accessed(io_in_12_bits_snpHitReleaseMeta_accessed),
    .io_in_12_bits_snpHitReleaseMeta_tagErr(io_in_12_bits_snpHitReleaseMeta_tagErr),
    .io_in_12_bits_snpHitReleaseMeta_dataErr(io_in_12_bits_snpHitReleaseMeta_dataErr),
    .io_in_12_bits_tgtID(io_in_12_bits_tgtID),
    .io_in_12_bits_txnID(io_in_12_bits_txnID),
    .io_in_12_bits_homeNID(io_in_12_bits_homeNID),
    .io_in_12_bits_dbID(io_in_12_bits_dbID),
    .io_in_12_bits_chiOpcode(io_in_12_bits_chiOpcode),
    .io_in_12_bits_resp(io_in_12_bits_resp),
    .io_in_12_bits_fwdState(io_in_12_bits_fwdState),
    .io_in_12_bits_retToSrc(io_in_12_bits_retToSrc),
    .io_in_12_bits_likelyshared(io_in_12_bits_likelyshared),
    .io_in_12_bits_expCompAck(io_in_12_bits_expCompAck),
    .io_in_12_bits_allowRetry(io_in_12_bits_allowRetry),
    .io_in_12_bits_memAttr_allocate(io_in_12_bits_memAttr_allocate),
    .io_in_12_bits_memAttr_cacheable(io_in_12_bits_memAttr_cacheable),
    .io_in_12_bits_memAttr_ewa(io_in_12_bits_memAttr_ewa),
    .io_in_12_bits_traceTag(io_in_12_bits_traceTag),
    .io_in_12_bits_dataCheckErr(io_in_12_bits_dataCheckErr),
    .io_in_13_ready(g_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_channel(io_in_13_bits_channel),
    .io_in_13_bits_txChannel(io_in_13_bits_txChannel),
    .io_in_13_bits_set(io_in_13_bits_set),
    .io_in_13_bits_tag(io_in_13_bits_tag),
    .io_in_13_bits_off(io_in_13_bits_off),
    .io_in_13_bits_alias(io_in_13_bits_alias),
    .io_in_13_bits_isKeyword(io_in_13_bits_isKeyword),
    .io_in_13_bits_opcode(io_in_13_bits_opcode),
    .io_in_13_bits_param(io_in_13_bits_param),
    .io_in_13_bits_size(io_in_13_bits_size),
    .io_in_13_bits_sourceId(io_in_13_bits_sourceId),
    .io_in_13_bits_denied(io_in_13_bits_denied),
    .io_in_13_bits_corrupt(io_in_13_bits_corrupt),
    .io_in_13_bits_mshrId(io_in_13_bits_mshrId),
    .io_in_13_bits_aliasTask(io_in_13_bits_aliasTask),
    .io_in_13_bits_useProbeData(io_in_13_bits_useProbeData),
    .io_in_13_bits_mshrRetry(io_in_13_bits_mshrRetry),
    .io_in_13_bits_readProbeDataDown(io_in_13_bits_readProbeDataDown),
    .io_in_13_bits_fromL2pft(io_in_13_bits_fromL2pft),
    .io_in_13_bits_dirty(io_in_13_bits_dirty),
    .io_in_13_bits_way(io_in_13_bits_way),
    .io_in_13_bits_meta_dirty(io_in_13_bits_meta_dirty),
    .io_in_13_bits_meta_state(io_in_13_bits_meta_state),
    .io_in_13_bits_meta_clients(io_in_13_bits_meta_clients),
    .io_in_13_bits_meta_alias(io_in_13_bits_meta_alias),
    .io_in_13_bits_meta_prefetch(io_in_13_bits_meta_prefetch),
    .io_in_13_bits_meta_prefetchSrc(io_in_13_bits_meta_prefetchSrc),
    .io_in_13_bits_meta_accessed(io_in_13_bits_meta_accessed),
    .io_in_13_bits_meta_tagErr(io_in_13_bits_meta_tagErr),
    .io_in_13_bits_meta_dataErr(io_in_13_bits_meta_dataErr),
    .io_in_13_bits_metaWen(io_in_13_bits_metaWen),
    .io_in_13_bits_tagWen(io_in_13_bits_tagWen),
    .io_in_13_bits_dsWen(io_in_13_bits_dsWen),
    .io_in_13_bits_replTask(io_in_13_bits_replTask),
    .io_in_13_bits_cmoTask(io_in_13_bits_cmoTask),
    .io_in_13_bits_reqSource(io_in_13_bits_reqSource),
    .io_in_13_bits_mergeA(io_in_13_bits_mergeA),
    .io_in_13_bits_aMergeTask_off(io_in_13_bits_aMergeTask_off),
    .io_in_13_bits_aMergeTask_alias(io_in_13_bits_aMergeTask_alias),
    .io_in_13_bits_aMergeTask_vaddr(io_in_13_bits_aMergeTask_vaddr),
    .io_in_13_bits_aMergeTask_isKeyword(io_in_13_bits_aMergeTask_isKeyword),
    .io_in_13_bits_aMergeTask_opcode(io_in_13_bits_aMergeTask_opcode),
    .io_in_13_bits_aMergeTask_param(io_in_13_bits_aMergeTask_param),
    .io_in_13_bits_aMergeTask_sourceId(io_in_13_bits_aMergeTask_sourceId),
    .io_in_13_bits_aMergeTask_meta_dirty(io_in_13_bits_aMergeTask_meta_dirty),
    .io_in_13_bits_aMergeTask_meta_state(io_in_13_bits_aMergeTask_meta_state),
    .io_in_13_bits_aMergeTask_meta_clients(io_in_13_bits_aMergeTask_meta_clients),
    .io_in_13_bits_aMergeTask_meta_alias(io_in_13_bits_aMergeTask_meta_alias),
    .io_in_13_bits_aMergeTask_meta_accessed(io_in_13_bits_aMergeTask_meta_accessed),
    .io_in_13_bits_snpHitRelease(io_in_13_bits_snpHitRelease),
    .io_in_13_bits_snpHitReleaseToInval(io_in_13_bits_snpHitReleaseToInval),
    .io_in_13_bits_snpHitReleaseToClean(io_in_13_bits_snpHitReleaseToClean),
    .io_in_13_bits_snpHitReleaseWithData(io_in_13_bits_snpHitReleaseWithData),
    .io_in_13_bits_snpHitReleaseIdx(io_in_13_bits_snpHitReleaseIdx),
    .io_in_13_bits_snpHitReleaseMeta_dirty(io_in_13_bits_snpHitReleaseMeta_dirty),
    .io_in_13_bits_snpHitReleaseMeta_state(io_in_13_bits_snpHitReleaseMeta_state),
    .io_in_13_bits_snpHitReleaseMeta_clients(io_in_13_bits_snpHitReleaseMeta_clients),
    .io_in_13_bits_snpHitReleaseMeta_alias(io_in_13_bits_snpHitReleaseMeta_alias),
    .io_in_13_bits_snpHitReleaseMeta_prefetch(io_in_13_bits_snpHitReleaseMeta_prefetch),
    .io_in_13_bits_snpHitReleaseMeta_prefetchSrc(io_in_13_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_13_bits_snpHitReleaseMeta_accessed(io_in_13_bits_snpHitReleaseMeta_accessed),
    .io_in_13_bits_snpHitReleaseMeta_tagErr(io_in_13_bits_snpHitReleaseMeta_tagErr),
    .io_in_13_bits_snpHitReleaseMeta_dataErr(io_in_13_bits_snpHitReleaseMeta_dataErr),
    .io_in_13_bits_tgtID(io_in_13_bits_tgtID),
    .io_in_13_bits_txnID(io_in_13_bits_txnID),
    .io_in_13_bits_homeNID(io_in_13_bits_homeNID),
    .io_in_13_bits_dbID(io_in_13_bits_dbID),
    .io_in_13_bits_chiOpcode(io_in_13_bits_chiOpcode),
    .io_in_13_bits_resp(io_in_13_bits_resp),
    .io_in_13_bits_fwdState(io_in_13_bits_fwdState),
    .io_in_13_bits_retToSrc(io_in_13_bits_retToSrc),
    .io_in_13_bits_likelyshared(io_in_13_bits_likelyshared),
    .io_in_13_bits_expCompAck(io_in_13_bits_expCompAck),
    .io_in_13_bits_allowRetry(io_in_13_bits_allowRetry),
    .io_in_13_bits_memAttr_allocate(io_in_13_bits_memAttr_allocate),
    .io_in_13_bits_memAttr_cacheable(io_in_13_bits_memAttr_cacheable),
    .io_in_13_bits_memAttr_ewa(io_in_13_bits_memAttr_ewa),
    .io_in_13_bits_traceTag(io_in_13_bits_traceTag),
    .io_in_13_bits_dataCheckErr(io_in_13_bits_dataCheckErr),
    .io_in_14_ready(g_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_channel(io_in_14_bits_channel),
    .io_in_14_bits_txChannel(io_in_14_bits_txChannel),
    .io_in_14_bits_set(io_in_14_bits_set),
    .io_in_14_bits_tag(io_in_14_bits_tag),
    .io_in_14_bits_off(io_in_14_bits_off),
    .io_in_14_bits_alias(io_in_14_bits_alias),
    .io_in_14_bits_isKeyword(io_in_14_bits_isKeyword),
    .io_in_14_bits_opcode(io_in_14_bits_opcode),
    .io_in_14_bits_param(io_in_14_bits_param),
    .io_in_14_bits_size(io_in_14_bits_size),
    .io_in_14_bits_sourceId(io_in_14_bits_sourceId),
    .io_in_14_bits_denied(io_in_14_bits_denied),
    .io_in_14_bits_corrupt(io_in_14_bits_corrupt),
    .io_in_14_bits_mshrId(io_in_14_bits_mshrId),
    .io_in_14_bits_aliasTask(io_in_14_bits_aliasTask),
    .io_in_14_bits_useProbeData(io_in_14_bits_useProbeData),
    .io_in_14_bits_mshrRetry(io_in_14_bits_mshrRetry),
    .io_in_14_bits_readProbeDataDown(io_in_14_bits_readProbeDataDown),
    .io_in_14_bits_fromL2pft(io_in_14_bits_fromL2pft),
    .io_in_14_bits_dirty(io_in_14_bits_dirty),
    .io_in_14_bits_way(io_in_14_bits_way),
    .io_in_14_bits_meta_dirty(io_in_14_bits_meta_dirty),
    .io_in_14_bits_meta_state(io_in_14_bits_meta_state),
    .io_in_14_bits_meta_clients(io_in_14_bits_meta_clients),
    .io_in_14_bits_meta_alias(io_in_14_bits_meta_alias),
    .io_in_14_bits_meta_prefetch(io_in_14_bits_meta_prefetch),
    .io_in_14_bits_meta_prefetchSrc(io_in_14_bits_meta_prefetchSrc),
    .io_in_14_bits_meta_accessed(io_in_14_bits_meta_accessed),
    .io_in_14_bits_meta_tagErr(io_in_14_bits_meta_tagErr),
    .io_in_14_bits_meta_dataErr(io_in_14_bits_meta_dataErr),
    .io_in_14_bits_metaWen(io_in_14_bits_metaWen),
    .io_in_14_bits_tagWen(io_in_14_bits_tagWen),
    .io_in_14_bits_dsWen(io_in_14_bits_dsWen),
    .io_in_14_bits_replTask(io_in_14_bits_replTask),
    .io_in_14_bits_cmoTask(io_in_14_bits_cmoTask),
    .io_in_14_bits_reqSource(io_in_14_bits_reqSource),
    .io_in_14_bits_mergeA(io_in_14_bits_mergeA),
    .io_in_14_bits_aMergeTask_off(io_in_14_bits_aMergeTask_off),
    .io_in_14_bits_aMergeTask_alias(io_in_14_bits_aMergeTask_alias),
    .io_in_14_bits_aMergeTask_vaddr(io_in_14_bits_aMergeTask_vaddr),
    .io_in_14_bits_aMergeTask_isKeyword(io_in_14_bits_aMergeTask_isKeyword),
    .io_in_14_bits_aMergeTask_opcode(io_in_14_bits_aMergeTask_opcode),
    .io_in_14_bits_aMergeTask_param(io_in_14_bits_aMergeTask_param),
    .io_in_14_bits_aMergeTask_sourceId(io_in_14_bits_aMergeTask_sourceId),
    .io_in_14_bits_aMergeTask_meta_dirty(io_in_14_bits_aMergeTask_meta_dirty),
    .io_in_14_bits_aMergeTask_meta_state(io_in_14_bits_aMergeTask_meta_state),
    .io_in_14_bits_aMergeTask_meta_clients(io_in_14_bits_aMergeTask_meta_clients),
    .io_in_14_bits_aMergeTask_meta_alias(io_in_14_bits_aMergeTask_meta_alias),
    .io_in_14_bits_aMergeTask_meta_accessed(io_in_14_bits_aMergeTask_meta_accessed),
    .io_in_14_bits_snpHitRelease(io_in_14_bits_snpHitRelease),
    .io_in_14_bits_snpHitReleaseToInval(io_in_14_bits_snpHitReleaseToInval),
    .io_in_14_bits_snpHitReleaseToClean(io_in_14_bits_snpHitReleaseToClean),
    .io_in_14_bits_snpHitReleaseWithData(io_in_14_bits_snpHitReleaseWithData),
    .io_in_14_bits_snpHitReleaseIdx(io_in_14_bits_snpHitReleaseIdx),
    .io_in_14_bits_snpHitReleaseMeta_dirty(io_in_14_bits_snpHitReleaseMeta_dirty),
    .io_in_14_bits_snpHitReleaseMeta_state(io_in_14_bits_snpHitReleaseMeta_state),
    .io_in_14_bits_snpHitReleaseMeta_clients(io_in_14_bits_snpHitReleaseMeta_clients),
    .io_in_14_bits_snpHitReleaseMeta_alias(io_in_14_bits_snpHitReleaseMeta_alias),
    .io_in_14_bits_snpHitReleaseMeta_prefetch(io_in_14_bits_snpHitReleaseMeta_prefetch),
    .io_in_14_bits_snpHitReleaseMeta_prefetchSrc(io_in_14_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_14_bits_snpHitReleaseMeta_accessed(io_in_14_bits_snpHitReleaseMeta_accessed),
    .io_in_14_bits_snpHitReleaseMeta_tagErr(io_in_14_bits_snpHitReleaseMeta_tagErr),
    .io_in_14_bits_snpHitReleaseMeta_dataErr(io_in_14_bits_snpHitReleaseMeta_dataErr),
    .io_in_14_bits_tgtID(io_in_14_bits_tgtID),
    .io_in_14_bits_txnID(io_in_14_bits_txnID),
    .io_in_14_bits_homeNID(io_in_14_bits_homeNID),
    .io_in_14_bits_dbID(io_in_14_bits_dbID),
    .io_in_14_bits_chiOpcode(io_in_14_bits_chiOpcode),
    .io_in_14_bits_resp(io_in_14_bits_resp),
    .io_in_14_bits_fwdState(io_in_14_bits_fwdState),
    .io_in_14_bits_retToSrc(io_in_14_bits_retToSrc),
    .io_in_14_bits_likelyshared(io_in_14_bits_likelyshared),
    .io_in_14_bits_expCompAck(io_in_14_bits_expCompAck),
    .io_in_14_bits_allowRetry(io_in_14_bits_allowRetry),
    .io_in_14_bits_memAttr_allocate(io_in_14_bits_memAttr_allocate),
    .io_in_14_bits_memAttr_cacheable(io_in_14_bits_memAttr_cacheable),
    .io_in_14_bits_memAttr_ewa(io_in_14_bits_memAttr_ewa),
    .io_in_14_bits_traceTag(io_in_14_bits_traceTag),
    .io_in_14_bits_dataCheckErr(io_in_14_bits_dataCheckErr),
    .io_in_15_ready(g_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_channel(io_in_15_bits_channel),
    .io_in_15_bits_txChannel(io_in_15_bits_txChannel),
    .io_in_15_bits_set(io_in_15_bits_set),
    .io_in_15_bits_tag(io_in_15_bits_tag),
    .io_in_15_bits_off(io_in_15_bits_off),
    .io_in_15_bits_alias(io_in_15_bits_alias),
    .io_in_15_bits_isKeyword(io_in_15_bits_isKeyword),
    .io_in_15_bits_opcode(io_in_15_bits_opcode),
    .io_in_15_bits_param(io_in_15_bits_param),
    .io_in_15_bits_size(io_in_15_bits_size),
    .io_in_15_bits_sourceId(io_in_15_bits_sourceId),
    .io_in_15_bits_denied(io_in_15_bits_denied),
    .io_in_15_bits_corrupt(io_in_15_bits_corrupt),
    .io_in_15_bits_mshrId(io_in_15_bits_mshrId),
    .io_in_15_bits_aliasTask(io_in_15_bits_aliasTask),
    .io_in_15_bits_useProbeData(io_in_15_bits_useProbeData),
    .io_in_15_bits_mshrRetry(io_in_15_bits_mshrRetry),
    .io_in_15_bits_readProbeDataDown(io_in_15_bits_readProbeDataDown),
    .io_in_15_bits_fromL2pft(io_in_15_bits_fromL2pft),
    .io_in_15_bits_dirty(io_in_15_bits_dirty),
    .io_in_15_bits_way(io_in_15_bits_way),
    .io_in_15_bits_meta_dirty(io_in_15_bits_meta_dirty),
    .io_in_15_bits_meta_state(io_in_15_bits_meta_state),
    .io_in_15_bits_meta_clients(io_in_15_bits_meta_clients),
    .io_in_15_bits_meta_alias(io_in_15_bits_meta_alias),
    .io_in_15_bits_meta_prefetch(io_in_15_bits_meta_prefetch),
    .io_in_15_bits_meta_prefetchSrc(io_in_15_bits_meta_prefetchSrc),
    .io_in_15_bits_meta_accessed(io_in_15_bits_meta_accessed),
    .io_in_15_bits_meta_tagErr(io_in_15_bits_meta_tagErr),
    .io_in_15_bits_meta_dataErr(io_in_15_bits_meta_dataErr),
    .io_in_15_bits_metaWen(io_in_15_bits_metaWen),
    .io_in_15_bits_tagWen(io_in_15_bits_tagWen),
    .io_in_15_bits_dsWen(io_in_15_bits_dsWen),
    .io_in_15_bits_replTask(io_in_15_bits_replTask),
    .io_in_15_bits_cmoTask(io_in_15_bits_cmoTask),
    .io_in_15_bits_reqSource(io_in_15_bits_reqSource),
    .io_in_15_bits_mergeA(io_in_15_bits_mergeA),
    .io_in_15_bits_aMergeTask_off(io_in_15_bits_aMergeTask_off),
    .io_in_15_bits_aMergeTask_alias(io_in_15_bits_aMergeTask_alias),
    .io_in_15_bits_aMergeTask_vaddr(io_in_15_bits_aMergeTask_vaddr),
    .io_in_15_bits_aMergeTask_isKeyword(io_in_15_bits_aMergeTask_isKeyword),
    .io_in_15_bits_aMergeTask_opcode(io_in_15_bits_aMergeTask_opcode),
    .io_in_15_bits_aMergeTask_param(io_in_15_bits_aMergeTask_param),
    .io_in_15_bits_aMergeTask_sourceId(io_in_15_bits_aMergeTask_sourceId),
    .io_in_15_bits_aMergeTask_meta_dirty(io_in_15_bits_aMergeTask_meta_dirty),
    .io_in_15_bits_aMergeTask_meta_state(io_in_15_bits_aMergeTask_meta_state),
    .io_in_15_bits_aMergeTask_meta_clients(io_in_15_bits_aMergeTask_meta_clients),
    .io_in_15_bits_aMergeTask_meta_alias(io_in_15_bits_aMergeTask_meta_alias),
    .io_in_15_bits_aMergeTask_meta_accessed(io_in_15_bits_aMergeTask_meta_accessed),
    .io_in_15_bits_snpHitRelease(io_in_15_bits_snpHitRelease),
    .io_in_15_bits_snpHitReleaseToInval(io_in_15_bits_snpHitReleaseToInval),
    .io_in_15_bits_snpHitReleaseToClean(io_in_15_bits_snpHitReleaseToClean),
    .io_in_15_bits_snpHitReleaseWithData(io_in_15_bits_snpHitReleaseWithData),
    .io_in_15_bits_snpHitReleaseIdx(io_in_15_bits_snpHitReleaseIdx),
    .io_in_15_bits_snpHitReleaseMeta_dirty(io_in_15_bits_snpHitReleaseMeta_dirty),
    .io_in_15_bits_snpHitReleaseMeta_state(io_in_15_bits_snpHitReleaseMeta_state),
    .io_in_15_bits_snpHitReleaseMeta_clients(io_in_15_bits_snpHitReleaseMeta_clients),
    .io_in_15_bits_snpHitReleaseMeta_alias(io_in_15_bits_snpHitReleaseMeta_alias),
    .io_in_15_bits_snpHitReleaseMeta_prefetch(io_in_15_bits_snpHitReleaseMeta_prefetch),
    .io_in_15_bits_snpHitReleaseMeta_prefetchSrc(io_in_15_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_15_bits_snpHitReleaseMeta_accessed(io_in_15_bits_snpHitReleaseMeta_accessed),
    .io_in_15_bits_snpHitReleaseMeta_tagErr(io_in_15_bits_snpHitReleaseMeta_tagErr),
    .io_in_15_bits_snpHitReleaseMeta_dataErr(io_in_15_bits_snpHitReleaseMeta_dataErr),
    .io_in_15_bits_tgtID(io_in_15_bits_tgtID),
    .io_in_15_bits_txnID(io_in_15_bits_txnID),
    .io_in_15_bits_homeNID(io_in_15_bits_homeNID),
    .io_in_15_bits_dbID(io_in_15_bits_dbID),
    .io_in_15_bits_chiOpcode(io_in_15_bits_chiOpcode),
    .io_in_15_bits_resp(io_in_15_bits_resp),
    .io_in_15_bits_fwdState(io_in_15_bits_fwdState),
    .io_in_15_bits_retToSrc(io_in_15_bits_retToSrc),
    .io_in_15_bits_likelyshared(io_in_15_bits_likelyshared),
    .io_in_15_bits_expCompAck(io_in_15_bits_expCompAck),
    .io_in_15_bits_allowRetry(io_in_15_bits_allowRetry),
    .io_in_15_bits_memAttr_allocate(io_in_15_bits_memAttr_allocate),
    .io_in_15_bits_memAttr_cacheable(io_in_15_bits_memAttr_cacheable),
    .io_in_15_bits_memAttr_ewa(io_in_15_bits_memAttr_ewa),
    .io_in_15_bits_traceTag(io_in_15_bits_traceTag),
    .io_in_15_bits_dataCheckErr(io_in_15_bits_dataCheckErr),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_channel(g_io_out_bits_channel),
    .io_out_bits_txChannel(g_io_out_bits_txChannel),
    .io_out_bits_set(g_io_out_bits_set),
    .io_out_bits_tag(g_io_out_bits_tag),
    .io_out_bits_off(g_io_out_bits_off),
    .io_out_bits_alias(g_io_out_bits_alias),
    .io_out_bits_isKeyword(g_io_out_bits_isKeyword),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_param(g_io_out_bits_param),
    .io_out_bits_size(g_io_out_bits_size),
    .io_out_bits_sourceId(g_io_out_bits_sourceId),
    .io_out_bits_denied(g_io_out_bits_denied),
    .io_out_bits_corrupt(g_io_out_bits_corrupt),
    .io_out_bits_mshrTask(g_io_out_bits_mshrTask),
    .io_out_bits_mshrId(g_io_out_bits_mshrId),
    .io_out_bits_aliasTask(g_io_out_bits_aliasTask),
    .io_out_bits_useProbeData(g_io_out_bits_useProbeData),
    .io_out_bits_mshrRetry(g_io_out_bits_mshrRetry),
    .io_out_bits_readProbeDataDown(g_io_out_bits_readProbeDataDown),
    .io_out_bits_fromL2pft(g_io_out_bits_fromL2pft),
    .io_out_bits_dirty(g_io_out_bits_dirty),
    .io_out_bits_way(g_io_out_bits_way),
    .io_out_bits_meta_dirty(g_io_out_bits_meta_dirty),
    .io_out_bits_meta_state(g_io_out_bits_meta_state),
    .io_out_bits_meta_clients(g_io_out_bits_meta_clients),
    .io_out_bits_meta_alias(g_io_out_bits_meta_alias),
    .io_out_bits_meta_prefetch(g_io_out_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc(g_io_out_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed(g_io_out_bits_meta_accessed),
    .io_out_bits_meta_tagErr(g_io_out_bits_meta_tagErr),
    .io_out_bits_meta_dataErr(g_io_out_bits_meta_dataErr),
    .io_out_bits_metaWen(g_io_out_bits_metaWen),
    .io_out_bits_tagWen(g_io_out_bits_tagWen),
    .io_out_bits_dsWen(g_io_out_bits_dsWen),
    .io_out_bits_replTask(g_io_out_bits_replTask),
    .io_out_bits_cmoTask(g_io_out_bits_cmoTask),
    .io_out_bits_reqSource(g_io_out_bits_reqSource),
    .io_out_bits_mergeA(g_io_out_bits_mergeA),
    .io_out_bits_aMergeTask_off(g_io_out_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias(g_io_out_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr(g_io_out_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword(g_io_out_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode(g_io_out_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param(g_io_out_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId(g_io_out_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty(g_io_out_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state(g_io_out_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients(g_io_out_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias(g_io_out_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_accessed(g_io_out_bits_aMergeTask_meta_accessed),
    .io_out_bits_snpHitRelease(g_io_out_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval(g_io_out_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean(g_io_out_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData(g_io_out_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx(g_io_out_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty(g_io_out_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state(g_io_out_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients(g_io_out_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias(g_io_out_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch(g_io_out_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc(g_io_out_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed(g_io_out_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr(g_io_out_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr(g_io_out_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_homeNID(g_io_out_bits_homeNID),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_chiOpcode(g_io_out_bits_chiOpcode),
    .io_out_bits_resp(g_io_out_bits_resp),
    .io_out_bits_fwdState(g_io_out_bits_fwdState),
    .io_out_bits_retToSrc(g_io_out_bits_retToSrc),
    .io_out_bits_likelyshared(g_io_out_bits_likelyshared),
    .io_out_bits_expCompAck(g_io_out_bits_expCompAck),
    .io_out_bits_allowRetry(g_io_out_bits_allowRetry),
    .io_out_bits_memAttr_allocate(g_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(g_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_ewa(g_io_out_bits_memAttr_ewa),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_out_bits_dataCheckErr(g_io_out_bits_dataCheckErr)
  );

  FastArbiter_8_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_channel(io_in_0_bits_channel),
    .io_in_0_bits_txChannel(io_in_0_bits_txChannel),
    .io_in_0_bits_set(io_in_0_bits_set),
    .io_in_0_bits_tag(io_in_0_bits_tag),
    .io_in_0_bits_off(io_in_0_bits_off),
    .io_in_0_bits_alias(io_in_0_bits_alias),
    .io_in_0_bits_isKeyword(io_in_0_bits_isKeyword),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_param(io_in_0_bits_param),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_sourceId(io_in_0_bits_sourceId),
    .io_in_0_bits_denied(io_in_0_bits_denied),
    .io_in_0_bits_corrupt(io_in_0_bits_corrupt),
    .io_in_0_bits_mshrId(io_in_0_bits_mshrId),
    .io_in_0_bits_aliasTask(io_in_0_bits_aliasTask),
    .io_in_0_bits_useProbeData(io_in_0_bits_useProbeData),
    .io_in_0_bits_mshrRetry(io_in_0_bits_mshrRetry),
    .io_in_0_bits_readProbeDataDown(io_in_0_bits_readProbeDataDown),
    .io_in_0_bits_fromL2pft(io_in_0_bits_fromL2pft),
    .io_in_0_bits_dirty(io_in_0_bits_dirty),
    .io_in_0_bits_way(io_in_0_bits_way),
    .io_in_0_bits_meta_dirty(io_in_0_bits_meta_dirty),
    .io_in_0_bits_meta_state(io_in_0_bits_meta_state),
    .io_in_0_bits_meta_clients(io_in_0_bits_meta_clients),
    .io_in_0_bits_meta_alias(io_in_0_bits_meta_alias),
    .io_in_0_bits_meta_prefetch(io_in_0_bits_meta_prefetch),
    .io_in_0_bits_meta_prefetchSrc(io_in_0_bits_meta_prefetchSrc),
    .io_in_0_bits_meta_accessed(io_in_0_bits_meta_accessed),
    .io_in_0_bits_meta_tagErr(io_in_0_bits_meta_tagErr),
    .io_in_0_bits_meta_dataErr(io_in_0_bits_meta_dataErr),
    .io_in_0_bits_metaWen(io_in_0_bits_metaWen),
    .io_in_0_bits_tagWen(io_in_0_bits_tagWen),
    .io_in_0_bits_dsWen(io_in_0_bits_dsWen),
    .io_in_0_bits_replTask(io_in_0_bits_replTask),
    .io_in_0_bits_cmoTask(io_in_0_bits_cmoTask),
    .io_in_0_bits_reqSource(io_in_0_bits_reqSource),
    .io_in_0_bits_mergeA(io_in_0_bits_mergeA),
    .io_in_0_bits_aMergeTask_off(io_in_0_bits_aMergeTask_off),
    .io_in_0_bits_aMergeTask_alias(io_in_0_bits_aMergeTask_alias),
    .io_in_0_bits_aMergeTask_vaddr(io_in_0_bits_aMergeTask_vaddr),
    .io_in_0_bits_aMergeTask_isKeyword(io_in_0_bits_aMergeTask_isKeyword),
    .io_in_0_bits_aMergeTask_opcode(io_in_0_bits_aMergeTask_opcode),
    .io_in_0_bits_aMergeTask_param(io_in_0_bits_aMergeTask_param),
    .io_in_0_bits_aMergeTask_sourceId(io_in_0_bits_aMergeTask_sourceId),
    .io_in_0_bits_aMergeTask_meta_dirty(io_in_0_bits_aMergeTask_meta_dirty),
    .io_in_0_bits_aMergeTask_meta_state(io_in_0_bits_aMergeTask_meta_state),
    .io_in_0_bits_aMergeTask_meta_clients(io_in_0_bits_aMergeTask_meta_clients),
    .io_in_0_bits_aMergeTask_meta_alias(io_in_0_bits_aMergeTask_meta_alias),
    .io_in_0_bits_aMergeTask_meta_accessed(io_in_0_bits_aMergeTask_meta_accessed),
    .io_in_0_bits_snpHitRelease(io_in_0_bits_snpHitRelease),
    .io_in_0_bits_snpHitReleaseToInval(io_in_0_bits_snpHitReleaseToInval),
    .io_in_0_bits_snpHitReleaseToClean(io_in_0_bits_snpHitReleaseToClean),
    .io_in_0_bits_snpHitReleaseWithData(io_in_0_bits_snpHitReleaseWithData),
    .io_in_0_bits_snpHitReleaseIdx(io_in_0_bits_snpHitReleaseIdx),
    .io_in_0_bits_snpHitReleaseMeta_dirty(io_in_0_bits_snpHitReleaseMeta_dirty),
    .io_in_0_bits_snpHitReleaseMeta_state(io_in_0_bits_snpHitReleaseMeta_state),
    .io_in_0_bits_snpHitReleaseMeta_clients(io_in_0_bits_snpHitReleaseMeta_clients),
    .io_in_0_bits_snpHitReleaseMeta_alias(io_in_0_bits_snpHitReleaseMeta_alias),
    .io_in_0_bits_snpHitReleaseMeta_prefetch(io_in_0_bits_snpHitReleaseMeta_prefetch),
    .io_in_0_bits_snpHitReleaseMeta_prefetchSrc(io_in_0_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_snpHitReleaseMeta_accessed(io_in_0_bits_snpHitReleaseMeta_accessed),
    .io_in_0_bits_snpHitReleaseMeta_tagErr(io_in_0_bits_snpHitReleaseMeta_tagErr),
    .io_in_0_bits_snpHitReleaseMeta_dataErr(io_in_0_bits_snpHitReleaseMeta_dataErr),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(io_in_0_bits_homeNID),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_chiOpcode(io_in_0_bits_chiOpcode),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_fwdState(io_in_0_bits_fwdState),
    .io_in_0_bits_retToSrc(io_in_0_bits_retToSrc),
    .io_in_0_bits_likelyshared(io_in_0_bits_likelyshared),
    .io_in_0_bits_expCompAck(io_in_0_bits_expCompAck),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_memAttr_allocate(io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable(io_in_0_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_dataCheckErr(io_in_0_bits_dataCheckErr),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_channel(io_in_1_bits_channel),
    .io_in_1_bits_txChannel(io_in_1_bits_txChannel),
    .io_in_1_bits_set(io_in_1_bits_set),
    .io_in_1_bits_tag(io_in_1_bits_tag),
    .io_in_1_bits_off(io_in_1_bits_off),
    .io_in_1_bits_alias(io_in_1_bits_alias),
    .io_in_1_bits_isKeyword(io_in_1_bits_isKeyword),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_param(io_in_1_bits_param),
    .io_in_1_bits_size(io_in_1_bits_size),
    .io_in_1_bits_sourceId(io_in_1_bits_sourceId),
    .io_in_1_bits_denied(io_in_1_bits_denied),
    .io_in_1_bits_corrupt(io_in_1_bits_corrupt),
    .io_in_1_bits_mshrId(io_in_1_bits_mshrId),
    .io_in_1_bits_aliasTask(io_in_1_bits_aliasTask),
    .io_in_1_bits_useProbeData(io_in_1_bits_useProbeData),
    .io_in_1_bits_mshrRetry(io_in_1_bits_mshrRetry),
    .io_in_1_bits_readProbeDataDown(io_in_1_bits_readProbeDataDown),
    .io_in_1_bits_fromL2pft(io_in_1_bits_fromL2pft),
    .io_in_1_bits_dirty(io_in_1_bits_dirty),
    .io_in_1_bits_way(io_in_1_bits_way),
    .io_in_1_bits_meta_dirty(io_in_1_bits_meta_dirty),
    .io_in_1_bits_meta_state(io_in_1_bits_meta_state),
    .io_in_1_bits_meta_clients(io_in_1_bits_meta_clients),
    .io_in_1_bits_meta_alias(io_in_1_bits_meta_alias),
    .io_in_1_bits_meta_prefetch(io_in_1_bits_meta_prefetch),
    .io_in_1_bits_meta_prefetchSrc(io_in_1_bits_meta_prefetchSrc),
    .io_in_1_bits_meta_accessed(io_in_1_bits_meta_accessed),
    .io_in_1_bits_meta_tagErr(io_in_1_bits_meta_tagErr),
    .io_in_1_bits_meta_dataErr(io_in_1_bits_meta_dataErr),
    .io_in_1_bits_metaWen(io_in_1_bits_metaWen),
    .io_in_1_bits_tagWen(io_in_1_bits_tagWen),
    .io_in_1_bits_dsWen(io_in_1_bits_dsWen),
    .io_in_1_bits_replTask(io_in_1_bits_replTask),
    .io_in_1_bits_cmoTask(io_in_1_bits_cmoTask),
    .io_in_1_bits_reqSource(io_in_1_bits_reqSource),
    .io_in_1_bits_mergeA(io_in_1_bits_mergeA),
    .io_in_1_bits_aMergeTask_off(io_in_1_bits_aMergeTask_off),
    .io_in_1_bits_aMergeTask_alias(io_in_1_bits_aMergeTask_alias),
    .io_in_1_bits_aMergeTask_vaddr(io_in_1_bits_aMergeTask_vaddr),
    .io_in_1_bits_aMergeTask_isKeyword(io_in_1_bits_aMergeTask_isKeyword),
    .io_in_1_bits_aMergeTask_opcode(io_in_1_bits_aMergeTask_opcode),
    .io_in_1_bits_aMergeTask_param(io_in_1_bits_aMergeTask_param),
    .io_in_1_bits_aMergeTask_sourceId(io_in_1_bits_aMergeTask_sourceId),
    .io_in_1_bits_aMergeTask_meta_dirty(io_in_1_bits_aMergeTask_meta_dirty),
    .io_in_1_bits_aMergeTask_meta_state(io_in_1_bits_aMergeTask_meta_state),
    .io_in_1_bits_aMergeTask_meta_clients(io_in_1_bits_aMergeTask_meta_clients),
    .io_in_1_bits_aMergeTask_meta_alias(io_in_1_bits_aMergeTask_meta_alias),
    .io_in_1_bits_aMergeTask_meta_accessed(io_in_1_bits_aMergeTask_meta_accessed),
    .io_in_1_bits_snpHitRelease(io_in_1_bits_snpHitRelease),
    .io_in_1_bits_snpHitReleaseToInval(io_in_1_bits_snpHitReleaseToInval),
    .io_in_1_bits_snpHitReleaseToClean(io_in_1_bits_snpHitReleaseToClean),
    .io_in_1_bits_snpHitReleaseWithData(io_in_1_bits_snpHitReleaseWithData),
    .io_in_1_bits_snpHitReleaseIdx(io_in_1_bits_snpHitReleaseIdx),
    .io_in_1_bits_snpHitReleaseMeta_dirty(io_in_1_bits_snpHitReleaseMeta_dirty),
    .io_in_1_bits_snpHitReleaseMeta_state(io_in_1_bits_snpHitReleaseMeta_state),
    .io_in_1_bits_snpHitReleaseMeta_clients(io_in_1_bits_snpHitReleaseMeta_clients),
    .io_in_1_bits_snpHitReleaseMeta_alias(io_in_1_bits_snpHitReleaseMeta_alias),
    .io_in_1_bits_snpHitReleaseMeta_prefetch(io_in_1_bits_snpHitReleaseMeta_prefetch),
    .io_in_1_bits_snpHitReleaseMeta_prefetchSrc(io_in_1_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_snpHitReleaseMeta_accessed(io_in_1_bits_snpHitReleaseMeta_accessed),
    .io_in_1_bits_snpHitReleaseMeta_tagErr(io_in_1_bits_snpHitReleaseMeta_tagErr),
    .io_in_1_bits_snpHitReleaseMeta_dataErr(io_in_1_bits_snpHitReleaseMeta_dataErr),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_homeNID(io_in_1_bits_homeNID),
    .io_in_1_bits_dbID(io_in_1_bits_dbID),
    .io_in_1_bits_chiOpcode(io_in_1_bits_chiOpcode),
    .io_in_1_bits_resp(io_in_1_bits_resp),
    .io_in_1_bits_fwdState(io_in_1_bits_fwdState),
    .io_in_1_bits_retToSrc(io_in_1_bits_retToSrc),
    .io_in_1_bits_likelyshared(io_in_1_bits_likelyshared),
    .io_in_1_bits_expCompAck(io_in_1_bits_expCompAck),
    .io_in_1_bits_allowRetry(io_in_1_bits_allowRetry),
    .io_in_1_bits_memAttr_allocate(io_in_1_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable(io_in_1_bits_memAttr_cacheable),
    .io_in_1_bits_memAttr_ewa(io_in_1_bits_memAttr_ewa),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_in_1_bits_dataCheckErr(io_in_1_bits_dataCheckErr),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_channel(io_in_2_bits_channel),
    .io_in_2_bits_txChannel(io_in_2_bits_txChannel),
    .io_in_2_bits_set(io_in_2_bits_set),
    .io_in_2_bits_tag(io_in_2_bits_tag),
    .io_in_2_bits_off(io_in_2_bits_off),
    .io_in_2_bits_alias(io_in_2_bits_alias),
    .io_in_2_bits_isKeyword(io_in_2_bits_isKeyword),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_param(io_in_2_bits_param),
    .io_in_2_bits_size(io_in_2_bits_size),
    .io_in_2_bits_sourceId(io_in_2_bits_sourceId),
    .io_in_2_bits_denied(io_in_2_bits_denied),
    .io_in_2_bits_corrupt(io_in_2_bits_corrupt),
    .io_in_2_bits_mshrId(io_in_2_bits_mshrId),
    .io_in_2_bits_aliasTask(io_in_2_bits_aliasTask),
    .io_in_2_bits_useProbeData(io_in_2_bits_useProbeData),
    .io_in_2_bits_mshrRetry(io_in_2_bits_mshrRetry),
    .io_in_2_bits_readProbeDataDown(io_in_2_bits_readProbeDataDown),
    .io_in_2_bits_fromL2pft(io_in_2_bits_fromL2pft),
    .io_in_2_bits_dirty(io_in_2_bits_dirty),
    .io_in_2_bits_way(io_in_2_bits_way),
    .io_in_2_bits_meta_dirty(io_in_2_bits_meta_dirty),
    .io_in_2_bits_meta_state(io_in_2_bits_meta_state),
    .io_in_2_bits_meta_clients(io_in_2_bits_meta_clients),
    .io_in_2_bits_meta_alias(io_in_2_bits_meta_alias),
    .io_in_2_bits_meta_prefetch(io_in_2_bits_meta_prefetch),
    .io_in_2_bits_meta_prefetchSrc(io_in_2_bits_meta_prefetchSrc),
    .io_in_2_bits_meta_accessed(io_in_2_bits_meta_accessed),
    .io_in_2_bits_meta_tagErr(io_in_2_bits_meta_tagErr),
    .io_in_2_bits_meta_dataErr(io_in_2_bits_meta_dataErr),
    .io_in_2_bits_metaWen(io_in_2_bits_metaWen),
    .io_in_2_bits_tagWen(io_in_2_bits_tagWen),
    .io_in_2_bits_dsWen(io_in_2_bits_dsWen),
    .io_in_2_bits_replTask(io_in_2_bits_replTask),
    .io_in_2_bits_cmoTask(io_in_2_bits_cmoTask),
    .io_in_2_bits_reqSource(io_in_2_bits_reqSource),
    .io_in_2_bits_mergeA(io_in_2_bits_mergeA),
    .io_in_2_bits_aMergeTask_off(io_in_2_bits_aMergeTask_off),
    .io_in_2_bits_aMergeTask_alias(io_in_2_bits_aMergeTask_alias),
    .io_in_2_bits_aMergeTask_vaddr(io_in_2_bits_aMergeTask_vaddr),
    .io_in_2_bits_aMergeTask_isKeyword(io_in_2_bits_aMergeTask_isKeyword),
    .io_in_2_bits_aMergeTask_opcode(io_in_2_bits_aMergeTask_opcode),
    .io_in_2_bits_aMergeTask_param(io_in_2_bits_aMergeTask_param),
    .io_in_2_bits_aMergeTask_sourceId(io_in_2_bits_aMergeTask_sourceId),
    .io_in_2_bits_aMergeTask_meta_dirty(io_in_2_bits_aMergeTask_meta_dirty),
    .io_in_2_bits_aMergeTask_meta_state(io_in_2_bits_aMergeTask_meta_state),
    .io_in_2_bits_aMergeTask_meta_clients(io_in_2_bits_aMergeTask_meta_clients),
    .io_in_2_bits_aMergeTask_meta_alias(io_in_2_bits_aMergeTask_meta_alias),
    .io_in_2_bits_aMergeTask_meta_accessed(io_in_2_bits_aMergeTask_meta_accessed),
    .io_in_2_bits_snpHitRelease(io_in_2_bits_snpHitRelease),
    .io_in_2_bits_snpHitReleaseToInval(io_in_2_bits_snpHitReleaseToInval),
    .io_in_2_bits_snpHitReleaseToClean(io_in_2_bits_snpHitReleaseToClean),
    .io_in_2_bits_snpHitReleaseWithData(io_in_2_bits_snpHitReleaseWithData),
    .io_in_2_bits_snpHitReleaseIdx(io_in_2_bits_snpHitReleaseIdx),
    .io_in_2_bits_snpHitReleaseMeta_dirty(io_in_2_bits_snpHitReleaseMeta_dirty),
    .io_in_2_bits_snpHitReleaseMeta_state(io_in_2_bits_snpHitReleaseMeta_state),
    .io_in_2_bits_snpHitReleaseMeta_clients(io_in_2_bits_snpHitReleaseMeta_clients),
    .io_in_2_bits_snpHitReleaseMeta_alias(io_in_2_bits_snpHitReleaseMeta_alias),
    .io_in_2_bits_snpHitReleaseMeta_prefetch(io_in_2_bits_snpHitReleaseMeta_prefetch),
    .io_in_2_bits_snpHitReleaseMeta_prefetchSrc(io_in_2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_snpHitReleaseMeta_accessed(io_in_2_bits_snpHitReleaseMeta_accessed),
    .io_in_2_bits_snpHitReleaseMeta_tagErr(io_in_2_bits_snpHitReleaseMeta_tagErr),
    .io_in_2_bits_snpHitReleaseMeta_dataErr(io_in_2_bits_snpHitReleaseMeta_dataErr),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_homeNID(io_in_2_bits_homeNID),
    .io_in_2_bits_dbID(io_in_2_bits_dbID),
    .io_in_2_bits_chiOpcode(io_in_2_bits_chiOpcode),
    .io_in_2_bits_resp(io_in_2_bits_resp),
    .io_in_2_bits_fwdState(io_in_2_bits_fwdState),
    .io_in_2_bits_retToSrc(io_in_2_bits_retToSrc),
    .io_in_2_bits_likelyshared(io_in_2_bits_likelyshared),
    .io_in_2_bits_expCompAck(io_in_2_bits_expCompAck),
    .io_in_2_bits_allowRetry(io_in_2_bits_allowRetry),
    .io_in_2_bits_memAttr_allocate(io_in_2_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable(io_in_2_bits_memAttr_cacheable),
    .io_in_2_bits_memAttr_ewa(io_in_2_bits_memAttr_ewa),
    .io_in_2_bits_traceTag(io_in_2_bits_traceTag),
    .io_in_2_bits_dataCheckErr(io_in_2_bits_dataCheckErr),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_channel(io_in_3_bits_channel),
    .io_in_3_bits_txChannel(io_in_3_bits_txChannel),
    .io_in_3_bits_set(io_in_3_bits_set),
    .io_in_3_bits_tag(io_in_3_bits_tag),
    .io_in_3_bits_off(io_in_3_bits_off),
    .io_in_3_bits_alias(io_in_3_bits_alias),
    .io_in_3_bits_isKeyword(io_in_3_bits_isKeyword),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_param(io_in_3_bits_param),
    .io_in_3_bits_size(io_in_3_bits_size),
    .io_in_3_bits_sourceId(io_in_3_bits_sourceId),
    .io_in_3_bits_denied(io_in_3_bits_denied),
    .io_in_3_bits_corrupt(io_in_3_bits_corrupt),
    .io_in_3_bits_mshrId(io_in_3_bits_mshrId),
    .io_in_3_bits_aliasTask(io_in_3_bits_aliasTask),
    .io_in_3_bits_useProbeData(io_in_3_bits_useProbeData),
    .io_in_3_bits_mshrRetry(io_in_3_bits_mshrRetry),
    .io_in_3_bits_readProbeDataDown(io_in_3_bits_readProbeDataDown),
    .io_in_3_bits_fromL2pft(io_in_3_bits_fromL2pft),
    .io_in_3_bits_dirty(io_in_3_bits_dirty),
    .io_in_3_bits_way(io_in_3_bits_way),
    .io_in_3_bits_meta_dirty(io_in_3_bits_meta_dirty),
    .io_in_3_bits_meta_state(io_in_3_bits_meta_state),
    .io_in_3_bits_meta_clients(io_in_3_bits_meta_clients),
    .io_in_3_bits_meta_alias(io_in_3_bits_meta_alias),
    .io_in_3_bits_meta_prefetch(io_in_3_bits_meta_prefetch),
    .io_in_3_bits_meta_prefetchSrc(io_in_3_bits_meta_prefetchSrc),
    .io_in_3_bits_meta_accessed(io_in_3_bits_meta_accessed),
    .io_in_3_bits_meta_tagErr(io_in_3_bits_meta_tagErr),
    .io_in_3_bits_meta_dataErr(io_in_3_bits_meta_dataErr),
    .io_in_3_bits_metaWen(io_in_3_bits_metaWen),
    .io_in_3_bits_tagWen(io_in_3_bits_tagWen),
    .io_in_3_bits_dsWen(io_in_3_bits_dsWen),
    .io_in_3_bits_replTask(io_in_3_bits_replTask),
    .io_in_3_bits_cmoTask(io_in_3_bits_cmoTask),
    .io_in_3_bits_reqSource(io_in_3_bits_reqSource),
    .io_in_3_bits_mergeA(io_in_3_bits_mergeA),
    .io_in_3_bits_aMergeTask_off(io_in_3_bits_aMergeTask_off),
    .io_in_3_bits_aMergeTask_alias(io_in_3_bits_aMergeTask_alias),
    .io_in_3_bits_aMergeTask_vaddr(io_in_3_bits_aMergeTask_vaddr),
    .io_in_3_bits_aMergeTask_isKeyword(io_in_3_bits_aMergeTask_isKeyword),
    .io_in_3_bits_aMergeTask_opcode(io_in_3_bits_aMergeTask_opcode),
    .io_in_3_bits_aMergeTask_param(io_in_3_bits_aMergeTask_param),
    .io_in_3_bits_aMergeTask_sourceId(io_in_3_bits_aMergeTask_sourceId),
    .io_in_3_bits_aMergeTask_meta_dirty(io_in_3_bits_aMergeTask_meta_dirty),
    .io_in_3_bits_aMergeTask_meta_state(io_in_3_bits_aMergeTask_meta_state),
    .io_in_3_bits_aMergeTask_meta_clients(io_in_3_bits_aMergeTask_meta_clients),
    .io_in_3_bits_aMergeTask_meta_alias(io_in_3_bits_aMergeTask_meta_alias),
    .io_in_3_bits_aMergeTask_meta_accessed(io_in_3_bits_aMergeTask_meta_accessed),
    .io_in_3_bits_snpHitRelease(io_in_3_bits_snpHitRelease),
    .io_in_3_bits_snpHitReleaseToInval(io_in_3_bits_snpHitReleaseToInval),
    .io_in_3_bits_snpHitReleaseToClean(io_in_3_bits_snpHitReleaseToClean),
    .io_in_3_bits_snpHitReleaseWithData(io_in_3_bits_snpHitReleaseWithData),
    .io_in_3_bits_snpHitReleaseIdx(io_in_3_bits_snpHitReleaseIdx),
    .io_in_3_bits_snpHitReleaseMeta_dirty(io_in_3_bits_snpHitReleaseMeta_dirty),
    .io_in_3_bits_snpHitReleaseMeta_state(io_in_3_bits_snpHitReleaseMeta_state),
    .io_in_3_bits_snpHitReleaseMeta_clients(io_in_3_bits_snpHitReleaseMeta_clients),
    .io_in_3_bits_snpHitReleaseMeta_alias(io_in_3_bits_snpHitReleaseMeta_alias),
    .io_in_3_bits_snpHitReleaseMeta_prefetch(io_in_3_bits_snpHitReleaseMeta_prefetch),
    .io_in_3_bits_snpHitReleaseMeta_prefetchSrc(io_in_3_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_3_bits_snpHitReleaseMeta_accessed(io_in_3_bits_snpHitReleaseMeta_accessed),
    .io_in_3_bits_snpHitReleaseMeta_tagErr(io_in_3_bits_snpHitReleaseMeta_tagErr),
    .io_in_3_bits_snpHitReleaseMeta_dataErr(io_in_3_bits_snpHitReleaseMeta_dataErr),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_homeNID(io_in_3_bits_homeNID),
    .io_in_3_bits_dbID(io_in_3_bits_dbID),
    .io_in_3_bits_chiOpcode(io_in_3_bits_chiOpcode),
    .io_in_3_bits_resp(io_in_3_bits_resp),
    .io_in_3_bits_fwdState(io_in_3_bits_fwdState),
    .io_in_3_bits_retToSrc(io_in_3_bits_retToSrc),
    .io_in_3_bits_likelyshared(io_in_3_bits_likelyshared),
    .io_in_3_bits_expCompAck(io_in_3_bits_expCompAck),
    .io_in_3_bits_allowRetry(io_in_3_bits_allowRetry),
    .io_in_3_bits_memAttr_allocate(io_in_3_bits_memAttr_allocate),
    .io_in_3_bits_memAttr_cacheable(io_in_3_bits_memAttr_cacheable),
    .io_in_3_bits_memAttr_ewa(io_in_3_bits_memAttr_ewa),
    .io_in_3_bits_traceTag(io_in_3_bits_traceTag),
    .io_in_3_bits_dataCheckErr(io_in_3_bits_dataCheckErr),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_channel(io_in_4_bits_channel),
    .io_in_4_bits_txChannel(io_in_4_bits_txChannel),
    .io_in_4_bits_set(io_in_4_bits_set),
    .io_in_4_bits_tag(io_in_4_bits_tag),
    .io_in_4_bits_off(io_in_4_bits_off),
    .io_in_4_bits_alias(io_in_4_bits_alias),
    .io_in_4_bits_isKeyword(io_in_4_bits_isKeyword),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_param(io_in_4_bits_param),
    .io_in_4_bits_size(io_in_4_bits_size),
    .io_in_4_bits_sourceId(io_in_4_bits_sourceId),
    .io_in_4_bits_denied(io_in_4_bits_denied),
    .io_in_4_bits_corrupt(io_in_4_bits_corrupt),
    .io_in_4_bits_mshrId(io_in_4_bits_mshrId),
    .io_in_4_bits_aliasTask(io_in_4_bits_aliasTask),
    .io_in_4_bits_useProbeData(io_in_4_bits_useProbeData),
    .io_in_4_bits_mshrRetry(io_in_4_bits_mshrRetry),
    .io_in_4_bits_readProbeDataDown(io_in_4_bits_readProbeDataDown),
    .io_in_4_bits_fromL2pft(io_in_4_bits_fromL2pft),
    .io_in_4_bits_dirty(io_in_4_bits_dirty),
    .io_in_4_bits_way(io_in_4_bits_way),
    .io_in_4_bits_meta_dirty(io_in_4_bits_meta_dirty),
    .io_in_4_bits_meta_state(io_in_4_bits_meta_state),
    .io_in_4_bits_meta_clients(io_in_4_bits_meta_clients),
    .io_in_4_bits_meta_alias(io_in_4_bits_meta_alias),
    .io_in_4_bits_meta_prefetch(io_in_4_bits_meta_prefetch),
    .io_in_4_bits_meta_prefetchSrc(io_in_4_bits_meta_prefetchSrc),
    .io_in_4_bits_meta_accessed(io_in_4_bits_meta_accessed),
    .io_in_4_bits_meta_tagErr(io_in_4_bits_meta_tagErr),
    .io_in_4_bits_meta_dataErr(io_in_4_bits_meta_dataErr),
    .io_in_4_bits_metaWen(io_in_4_bits_metaWen),
    .io_in_4_bits_tagWen(io_in_4_bits_tagWen),
    .io_in_4_bits_dsWen(io_in_4_bits_dsWen),
    .io_in_4_bits_replTask(io_in_4_bits_replTask),
    .io_in_4_bits_cmoTask(io_in_4_bits_cmoTask),
    .io_in_4_bits_reqSource(io_in_4_bits_reqSource),
    .io_in_4_bits_mergeA(io_in_4_bits_mergeA),
    .io_in_4_bits_aMergeTask_off(io_in_4_bits_aMergeTask_off),
    .io_in_4_bits_aMergeTask_alias(io_in_4_bits_aMergeTask_alias),
    .io_in_4_bits_aMergeTask_vaddr(io_in_4_bits_aMergeTask_vaddr),
    .io_in_4_bits_aMergeTask_isKeyword(io_in_4_bits_aMergeTask_isKeyword),
    .io_in_4_bits_aMergeTask_opcode(io_in_4_bits_aMergeTask_opcode),
    .io_in_4_bits_aMergeTask_param(io_in_4_bits_aMergeTask_param),
    .io_in_4_bits_aMergeTask_sourceId(io_in_4_bits_aMergeTask_sourceId),
    .io_in_4_bits_aMergeTask_meta_dirty(io_in_4_bits_aMergeTask_meta_dirty),
    .io_in_4_bits_aMergeTask_meta_state(io_in_4_bits_aMergeTask_meta_state),
    .io_in_4_bits_aMergeTask_meta_clients(io_in_4_bits_aMergeTask_meta_clients),
    .io_in_4_bits_aMergeTask_meta_alias(io_in_4_bits_aMergeTask_meta_alias),
    .io_in_4_bits_aMergeTask_meta_accessed(io_in_4_bits_aMergeTask_meta_accessed),
    .io_in_4_bits_snpHitRelease(io_in_4_bits_snpHitRelease),
    .io_in_4_bits_snpHitReleaseToInval(io_in_4_bits_snpHitReleaseToInval),
    .io_in_4_bits_snpHitReleaseToClean(io_in_4_bits_snpHitReleaseToClean),
    .io_in_4_bits_snpHitReleaseWithData(io_in_4_bits_snpHitReleaseWithData),
    .io_in_4_bits_snpHitReleaseIdx(io_in_4_bits_snpHitReleaseIdx),
    .io_in_4_bits_snpHitReleaseMeta_dirty(io_in_4_bits_snpHitReleaseMeta_dirty),
    .io_in_4_bits_snpHitReleaseMeta_state(io_in_4_bits_snpHitReleaseMeta_state),
    .io_in_4_bits_snpHitReleaseMeta_clients(io_in_4_bits_snpHitReleaseMeta_clients),
    .io_in_4_bits_snpHitReleaseMeta_alias(io_in_4_bits_snpHitReleaseMeta_alias),
    .io_in_4_bits_snpHitReleaseMeta_prefetch(io_in_4_bits_snpHitReleaseMeta_prefetch),
    .io_in_4_bits_snpHitReleaseMeta_prefetchSrc(io_in_4_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_4_bits_snpHitReleaseMeta_accessed(io_in_4_bits_snpHitReleaseMeta_accessed),
    .io_in_4_bits_snpHitReleaseMeta_tagErr(io_in_4_bits_snpHitReleaseMeta_tagErr),
    .io_in_4_bits_snpHitReleaseMeta_dataErr(io_in_4_bits_snpHitReleaseMeta_dataErr),
    .io_in_4_bits_tgtID(io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_homeNID(io_in_4_bits_homeNID),
    .io_in_4_bits_dbID(io_in_4_bits_dbID),
    .io_in_4_bits_chiOpcode(io_in_4_bits_chiOpcode),
    .io_in_4_bits_resp(io_in_4_bits_resp),
    .io_in_4_bits_fwdState(io_in_4_bits_fwdState),
    .io_in_4_bits_retToSrc(io_in_4_bits_retToSrc),
    .io_in_4_bits_likelyshared(io_in_4_bits_likelyshared),
    .io_in_4_bits_expCompAck(io_in_4_bits_expCompAck),
    .io_in_4_bits_allowRetry(io_in_4_bits_allowRetry),
    .io_in_4_bits_memAttr_allocate(io_in_4_bits_memAttr_allocate),
    .io_in_4_bits_memAttr_cacheable(io_in_4_bits_memAttr_cacheable),
    .io_in_4_bits_memAttr_ewa(io_in_4_bits_memAttr_ewa),
    .io_in_4_bits_traceTag(io_in_4_bits_traceTag),
    .io_in_4_bits_dataCheckErr(io_in_4_bits_dataCheckErr),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_channel(io_in_5_bits_channel),
    .io_in_5_bits_txChannel(io_in_5_bits_txChannel),
    .io_in_5_bits_set(io_in_5_bits_set),
    .io_in_5_bits_tag(io_in_5_bits_tag),
    .io_in_5_bits_off(io_in_5_bits_off),
    .io_in_5_bits_alias(io_in_5_bits_alias),
    .io_in_5_bits_isKeyword(io_in_5_bits_isKeyword),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_param(io_in_5_bits_param),
    .io_in_5_bits_size(io_in_5_bits_size),
    .io_in_5_bits_sourceId(io_in_5_bits_sourceId),
    .io_in_5_bits_denied(io_in_5_bits_denied),
    .io_in_5_bits_corrupt(io_in_5_bits_corrupt),
    .io_in_5_bits_mshrId(io_in_5_bits_mshrId),
    .io_in_5_bits_aliasTask(io_in_5_bits_aliasTask),
    .io_in_5_bits_useProbeData(io_in_5_bits_useProbeData),
    .io_in_5_bits_mshrRetry(io_in_5_bits_mshrRetry),
    .io_in_5_bits_readProbeDataDown(io_in_5_bits_readProbeDataDown),
    .io_in_5_bits_fromL2pft(io_in_5_bits_fromL2pft),
    .io_in_5_bits_dirty(io_in_5_bits_dirty),
    .io_in_5_bits_way(io_in_5_bits_way),
    .io_in_5_bits_meta_dirty(io_in_5_bits_meta_dirty),
    .io_in_5_bits_meta_state(io_in_5_bits_meta_state),
    .io_in_5_bits_meta_clients(io_in_5_bits_meta_clients),
    .io_in_5_bits_meta_alias(io_in_5_bits_meta_alias),
    .io_in_5_bits_meta_prefetch(io_in_5_bits_meta_prefetch),
    .io_in_5_bits_meta_prefetchSrc(io_in_5_bits_meta_prefetchSrc),
    .io_in_5_bits_meta_accessed(io_in_5_bits_meta_accessed),
    .io_in_5_bits_meta_tagErr(io_in_5_bits_meta_tagErr),
    .io_in_5_bits_meta_dataErr(io_in_5_bits_meta_dataErr),
    .io_in_5_bits_metaWen(io_in_5_bits_metaWen),
    .io_in_5_bits_tagWen(io_in_5_bits_tagWen),
    .io_in_5_bits_dsWen(io_in_5_bits_dsWen),
    .io_in_5_bits_replTask(io_in_5_bits_replTask),
    .io_in_5_bits_cmoTask(io_in_5_bits_cmoTask),
    .io_in_5_bits_reqSource(io_in_5_bits_reqSource),
    .io_in_5_bits_mergeA(io_in_5_bits_mergeA),
    .io_in_5_bits_aMergeTask_off(io_in_5_bits_aMergeTask_off),
    .io_in_5_bits_aMergeTask_alias(io_in_5_bits_aMergeTask_alias),
    .io_in_5_bits_aMergeTask_vaddr(io_in_5_bits_aMergeTask_vaddr),
    .io_in_5_bits_aMergeTask_isKeyword(io_in_5_bits_aMergeTask_isKeyword),
    .io_in_5_bits_aMergeTask_opcode(io_in_5_bits_aMergeTask_opcode),
    .io_in_5_bits_aMergeTask_param(io_in_5_bits_aMergeTask_param),
    .io_in_5_bits_aMergeTask_sourceId(io_in_5_bits_aMergeTask_sourceId),
    .io_in_5_bits_aMergeTask_meta_dirty(io_in_5_bits_aMergeTask_meta_dirty),
    .io_in_5_bits_aMergeTask_meta_state(io_in_5_bits_aMergeTask_meta_state),
    .io_in_5_bits_aMergeTask_meta_clients(io_in_5_bits_aMergeTask_meta_clients),
    .io_in_5_bits_aMergeTask_meta_alias(io_in_5_bits_aMergeTask_meta_alias),
    .io_in_5_bits_aMergeTask_meta_accessed(io_in_5_bits_aMergeTask_meta_accessed),
    .io_in_5_bits_snpHitRelease(io_in_5_bits_snpHitRelease),
    .io_in_5_bits_snpHitReleaseToInval(io_in_5_bits_snpHitReleaseToInval),
    .io_in_5_bits_snpHitReleaseToClean(io_in_5_bits_snpHitReleaseToClean),
    .io_in_5_bits_snpHitReleaseWithData(io_in_5_bits_snpHitReleaseWithData),
    .io_in_5_bits_snpHitReleaseIdx(io_in_5_bits_snpHitReleaseIdx),
    .io_in_5_bits_snpHitReleaseMeta_dirty(io_in_5_bits_snpHitReleaseMeta_dirty),
    .io_in_5_bits_snpHitReleaseMeta_state(io_in_5_bits_snpHitReleaseMeta_state),
    .io_in_5_bits_snpHitReleaseMeta_clients(io_in_5_bits_snpHitReleaseMeta_clients),
    .io_in_5_bits_snpHitReleaseMeta_alias(io_in_5_bits_snpHitReleaseMeta_alias),
    .io_in_5_bits_snpHitReleaseMeta_prefetch(io_in_5_bits_snpHitReleaseMeta_prefetch),
    .io_in_5_bits_snpHitReleaseMeta_prefetchSrc(io_in_5_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_5_bits_snpHitReleaseMeta_accessed(io_in_5_bits_snpHitReleaseMeta_accessed),
    .io_in_5_bits_snpHitReleaseMeta_tagErr(io_in_5_bits_snpHitReleaseMeta_tagErr),
    .io_in_5_bits_snpHitReleaseMeta_dataErr(io_in_5_bits_snpHitReleaseMeta_dataErr),
    .io_in_5_bits_tgtID(io_in_5_bits_tgtID),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_homeNID(io_in_5_bits_homeNID),
    .io_in_5_bits_dbID(io_in_5_bits_dbID),
    .io_in_5_bits_chiOpcode(io_in_5_bits_chiOpcode),
    .io_in_5_bits_resp(io_in_5_bits_resp),
    .io_in_5_bits_fwdState(io_in_5_bits_fwdState),
    .io_in_5_bits_retToSrc(io_in_5_bits_retToSrc),
    .io_in_5_bits_likelyshared(io_in_5_bits_likelyshared),
    .io_in_5_bits_expCompAck(io_in_5_bits_expCompAck),
    .io_in_5_bits_allowRetry(io_in_5_bits_allowRetry),
    .io_in_5_bits_memAttr_allocate(io_in_5_bits_memAttr_allocate),
    .io_in_5_bits_memAttr_cacheable(io_in_5_bits_memAttr_cacheable),
    .io_in_5_bits_memAttr_ewa(io_in_5_bits_memAttr_ewa),
    .io_in_5_bits_traceTag(io_in_5_bits_traceTag),
    .io_in_5_bits_dataCheckErr(io_in_5_bits_dataCheckErr),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_channel(io_in_6_bits_channel),
    .io_in_6_bits_txChannel(io_in_6_bits_txChannel),
    .io_in_6_bits_set(io_in_6_bits_set),
    .io_in_6_bits_tag(io_in_6_bits_tag),
    .io_in_6_bits_off(io_in_6_bits_off),
    .io_in_6_bits_alias(io_in_6_bits_alias),
    .io_in_6_bits_isKeyword(io_in_6_bits_isKeyword),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_param(io_in_6_bits_param),
    .io_in_6_bits_size(io_in_6_bits_size),
    .io_in_6_bits_sourceId(io_in_6_bits_sourceId),
    .io_in_6_bits_denied(io_in_6_bits_denied),
    .io_in_6_bits_corrupt(io_in_6_bits_corrupt),
    .io_in_6_bits_mshrId(io_in_6_bits_mshrId),
    .io_in_6_bits_aliasTask(io_in_6_bits_aliasTask),
    .io_in_6_bits_useProbeData(io_in_6_bits_useProbeData),
    .io_in_6_bits_mshrRetry(io_in_6_bits_mshrRetry),
    .io_in_6_bits_readProbeDataDown(io_in_6_bits_readProbeDataDown),
    .io_in_6_bits_fromL2pft(io_in_6_bits_fromL2pft),
    .io_in_6_bits_dirty(io_in_6_bits_dirty),
    .io_in_6_bits_way(io_in_6_bits_way),
    .io_in_6_bits_meta_dirty(io_in_6_bits_meta_dirty),
    .io_in_6_bits_meta_state(io_in_6_bits_meta_state),
    .io_in_6_bits_meta_clients(io_in_6_bits_meta_clients),
    .io_in_6_bits_meta_alias(io_in_6_bits_meta_alias),
    .io_in_6_bits_meta_prefetch(io_in_6_bits_meta_prefetch),
    .io_in_6_bits_meta_prefetchSrc(io_in_6_bits_meta_prefetchSrc),
    .io_in_6_bits_meta_accessed(io_in_6_bits_meta_accessed),
    .io_in_6_bits_meta_tagErr(io_in_6_bits_meta_tagErr),
    .io_in_6_bits_meta_dataErr(io_in_6_bits_meta_dataErr),
    .io_in_6_bits_metaWen(io_in_6_bits_metaWen),
    .io_in_6_bits_tagWen(io_in_6_bits_tagWen),
    .io_in_6_bits_dsWen(io_in_6_bits_dsWen),
    .io_in_6_bits_replTask(io_in_6_bits_replTask),
    .io_in_6_bits_cmoTask(io_in_6_bits_cmoTask),
    .io_in_6_bits_reqSource(io_in_6_bits_reqSource),
    .io_in_6_bits_mergeA(io_in_6_bits_mergeA),
    .io_in_6_bits_aMergeTask_off(io_in_6_bits_aMergeTask_off),
    .io_in_6_bits_aMergeTask_alias(io_in_6_bits_aMergeTask_alias),
    .io_in_6_bits_aMergeTask_vaddr(io_in_6_bits_aMergeTask_vaddr),
    .io_in_6_bits_aMergeTask_isKeyword(io_in_6_bits_aMergeTask_isKeyword),
    .io_in_6_bits_aMergeTask_opcode(io_in_6_bits_aMergeTask_opcode),
    .io_in_6_bits_aMergeTask_param(io_in_6_bits_aMergeTask_param),
    .io_in_6_bits_aMergeTask_sourceId(io_in_6_bits_aMergeTask_sourceId),
    .io_in_6_bits_aMergeTask_meta_dirty(io_in_6_bits_aMergeTask_meta_dirty),
    .io_in_6_bits_aMergeTask_meta_state(io_in_6_bits_aMergeTask_meta_state),
    .io_in_6_bits_aMergeTask_meta_clients(io_in_6_bits_aMergeTask_meta_clients),
    .io_in_6_bits_aMergeTask_meta_alias(io_in_6_bits_aMergeTask_meta_alias),
    .io_in_6_bits_aMergeTask_meta_accessed(io_in_6_bits_aMergeTask_meta_accessed),
    .io_in_6_bits_snpHitRelease(io_in_6_bits_snpHitRelease),
    .io_in_6_bits_snpHitReleaseToInval(io_in_6_bits_snpHitReleaseToInval),
    .io_in_6_bits_snpHitReleaseToClean(io_in_6_bits_snpHitReleaseToClean),
    .io_in_6_bits_snpHitReleaseWithData(io_in_6_bits_snpHitReleaseWithData),
    .io_in_6_bits_snpHitReleaseIdx(io_in_6_bits_snpHitReleaseIdx),
    .io_in_6_bits_snpHitReleaseMeta_dirty(io_in_6_bits_snpHitReleaseMeta_dirty),
    .io_in_6_bits_snpHitReleaseMeta_state(io_in_6_bits_snpHitReleaseMeta_state),
    .io_in_6_bits_snpHitReleaseMeta_clients(io_in_6_bits_snpHitReleaseMeta_clients),
    .io_in_6_bits_snpHitReleaseMeta_alias(io_in_6_bits_snpHitReleaseMeta_alias),
    .io_in_6_bits_snpHitReleaseMeta_prefetch(io_in_6_bits_snpHitReleaseMeta_prefetch),
    .io_in_6_bits_snpHitReleaseMeta_prefetchSrc(io_in_6_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_6_bits_snpHitReleaseMeta_accessed(io_in_6_bits_snpHitReleaseMeta_accessed),
    .io_in_6_bits_snpHitReleaseMeta_tagErr(io_in_6_bits_snpHitReleaseMeta_tagErr),
    .io_in_6_bits_snpHitReleaseMeta_dataErr(io_in_6_bits_snpHitReleaseMeta_dataErr),
    .io_in_6_bits_tgtID(io_in_6_bits_tgtID),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_homeNID(io_in_6_bits_homeNID),
    .io_in_6_bits_dbID(io_in_6_bits_dbID),
    .io_in_6_bits_chiOpcode(io_in_6_bits_chiOpcode),
    .io_in_6_bits_resp(io_in_6_bits_resp),
    .io_in_6_bits_fwdState(io_in_6_bits_fwdState),
    .io_in_6_bits_retToSrc(io_in_6_bits_retToSrc),
    .io_in_6_bits_likelyshared(io_in_6_bits_likelyshared),
    .io_in_6_bits_expCompAck(io_in_6_bits_expCompAck),
    .io_in_6_bits_allowRetry(io_in_6_bits_allowRetry),
    .io_in_6_bits_memAttr_allocate(io_in_6_bits_memAttr_allocate),
    .io_in_6_bits_memAttr_cacheable(io_in_6_bits_memAttr_cacheable),
    .io_in_6_bits_memAttr_ewa(io_in_6_bits_memAttr_ewa),
    .io_in_6_bits_traceTag(io_in_6_bits_traceTag),
    .io_in_6_bits_dataCheckErr(io_in_6_bits_dataCheckErr),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_channel(io_in_7_bits_channel),
    .io_in_7_bits_txChannel(io_in_7_bits_txChannel),
    .io_in_7_bits_set(io_in_7_bits_set),
    .io_in_7_bits_tag(io_in_7_bits_tag),
    .io_in_7_bits_off(io_in_7_bits_off),
    .io_in_7_bits_alias(io_in_7_bits_alias),
    .io_in_7_bits_isKeyword(io_in_7_bits_isKeyword),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_param(io_in_7_bits_param),
    .io_in_7_bits_size(io_in_7_bits_size),
    .io_in_7_bits_sourceId(io_in_7_bits_sourceId),
    .io_in_7_bits_denied(io_in_7_bits_denied),
    .io_in_7_bits_corrupt(io_in_7_bits_corrupt),
    .io_in_7_bits_mshrId(io_in_7_bits_mshrId),
    .io_in_7_bits_aliasTask(io_in_7_bits_aliasTask),
    .io_in_7_bits_useProbeData(io_in_7_bits_useProbeData),
    .io_in_7_bits_mshrRetry(io_in_7_bits_mshrRetry),
    .io_in_7_bits_readProbeDataDown(io_in_7_bits_readProbeDataDown),
    .io_in_7_bits_fromL2pft(io_in_7_bits_fromL2pft),
    .io_in_7_bits_dirty(io_in_7_bits_dirty),
    .io_in_7_bits_way(io_in_7_bits_way),
    .io_in_7_bits_meta_dirty(io_in_7_bits_meta_dirty),
    .io_in_7_bits_meta_state(io_in_7_bits_meta_state),
    .io_in_7_bits_meta_clients(io_in_7_bits_meta_clients),
    .io_in_7_bits_meta_alias(io_in_7_bits_meta_alias),
    .io_in_7_bits_meta_prefetch(io_in_7_bits_meta_prefetch),
    .io_in_7_bits_meta_prefetchSrc(io_in_7_bits_meta_prefetchSrc),
    .io_in_7_bits_meta_accessed(io_in_7_bits_meta_accessed),
    .io_in_7_bits_meta_tagErr(io_in_7_bits_meta_tagErr),
    .io_in_7_bits_meta_dataErr(io_in_7_bits_meta_dataErr),
    .io_in_7_bits_metaWen(io_in_7_bits_metaWen),
    .io_in_7_bits_tagWen(io_in_7_bits_tagWen),
    .io_in_7_bits_dsWen(io_in_7_bits_dsWen),
    .io_in_7_bits_replTask(io_in_7_bits_replTask),
    .io_in_7_bits_cmoTask(io_in_7_bits_cmoTask),
    .io_in_7_bits_reqSource(io_in_7_bits_reqSource),
    .io_in_7_bits_mergeA(io_in_7_bits_mergeA),
    .io_in_7_bits_aMergeTask_off(io_in_7_bits_aMergeTask_off),
    .io_in_7_bits_aMergeTask_alias(io_in_7_bits_aMergeTask_alias),
    .io_in_7_bits_aMergeTask_vaddr(io_in_7_bits_aMergeTask_vaddr),
    .io_in_7_bits_aMergeTask_isKeyword(io_in_7_bits_aMergeTask_isKeyword),
    .io_in_7_bits_aMergeTask_opcode(io_in_7_bits_aMergeTask_opcode),
    .io_in_7_bits_aMergeTask_param(io_in_7_bits_aMergeTask_param),
    .io_in_7_bits_aMergeTask_sourceId(io_in_7_bits_aMergeTask_sourceId),
    .io_in_7_bits_aMergeTask_meta_dirty(io_in_7_bits_aMergeTask_meta_dirty),
    .io_in_7_bits_aMergeTask_meta_state(io_in_7_bits_aMergeTask_meta_state),
    .io_in_7_bits_aMergeTask_meta_clients(io_in_7_bits_aMergeTask_meta_clients),
    .io_in_7_bits_aMergeTask_meta_alias(io_in_7_bits_aMergeTask_meta_alias),
    .io_in_7_bits_aMergeTask_meta_accessed(io_in_7_bits_aMergeTask_meta_accessed),
    .io_in_7_bits_snpHitRelease(io_in_7_bits_snpHitRelease),
    .io_in_7_bits_snpHitReleaseToInval(io_in_7_bits_snpHitReleaseToInval),
    .io_in_7_bits_snpHitReleaseToClean(io_in_7_bits_snpHitReleaseToClean),
    .io_in_7_bits_snpHitReleaseWithData(io_in_7_bits_snpHitReleaseWithData),
    .io_in_7_bits_snpHitReleaseIdx(io_in_7_bits_snpHitReleaseIdx),
    .io_in_7_bits_snpHitReleaseMeta_dirty(io_in_7_bits_snpHitReleaseMeta_dirty),
    .io_in_7_bits_snpHitReleaseMeta_state(io_in_7_bits_snpHitReleaseMeta_state),
    .io_in_7_bits_snpHitReleaseMeta_clients(io_in_7_bits_snpHitReleaseMeta_clients),
    .io_in_7_bits_snpHitReleaseMeta_alias(io_in_7_bits_snpHitReleaseMeta_alias),
    .io_in_7_bits_snpHitReleaseMeta_prefetch(io_in_7_bits_snpHitReleaseMeta_prefetch),
    .io_in_7_bits_snpHitReleaseMeta_prefetchSrc(io_in_7_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_7_bits_snpHitReleaseMeta_accessed(io_in_7_bits_snpHitReleaseMeta_accessed),
    .io_in_7_bits_snpHitReleaseMeta_tagErr(io_in_7_bits_snpHitReleaseMeta_tagErr),
    .io_in_7_bits_snpHitReleaseMeta_dataErr(io_in_7_bits_snpHitReleaseMeta_dataErr),
    .io_in_7_bits_tgtID(io_in_7_bits_tgtID),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_homeNID(io_in_7_bits_homeNID),
    .io_in_7_bits_dbID(io_in_7_bits_dbID),
    .io_in_7_bits_chiOpcode(io_in_7_bits_chiOpcode),
    .io_in_7_bits_resp(io_in_7_bits_resp),
    .io_in_7_bits_fwdState(io_in_7_bits_fwdState),
    .io_in_7_bits_retToSrc(io_in_7_bits_retToSrc),
    .io_in_7_bits_likelyshared(io_in_7_bits_likelyshared),
    .io_in_7_bits_expCompAck(io_in_7_bits_expCompAck),
    .io_in_7_bits_allowRetry(io_in_7_bits_allowRetry),
    .io_in_7_bits_memAttr_allocate(io_in_7_bits_memAttr_allocate),
    .io_in_7_bits_memAttr_cacheable(io_in_7_bits_memAttr_cacheable),
    .io_in_7_bits_memAttr_ewa(io_in_7_bits_memAttr_ewa),
    .io_in_7_bits_traceTag(io_in_7_bits_traceTag),
    .io_in_7_bits_dataCheckErr(io_in_7_bits_dataCheckErr),
    .io_in_8_ready(i_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_channel(io_in_8_bits_channel),
    .io_in_8_bits_txChannel(io_in_8_bits_txChannel),
    .io_in_8_bits_set(io_in_8_bits_set),
    .io_in_8_bits_tag(io_in_8_bits_tag),
    .io_in_8_bits_off(io_in_8_bits_off),
    .io_in_8_bits_alias(io_in_8_bits_alias),
    .io_in_8_bits_isKeyword(io_in_8_bits_isKeyword),
    .io_in_8_bits_opcode(io_in_8_bits_opcode),
    .io_in_8_bits_param(io_in_8_bits_param),
    .io_in_8_bits_size(io_in_8_bits_size),
    .io_in_8_bits_sourceId(io_in_8_bits_sourceId),
    .io_in_8_bits_denied(io_in_8_bits_denied),
    .io_in_8_bits_corrupt(io_in_8_bits_corrupt),
    .io_in_8_bits_mshrId(io_in_8_bits_mshrId),
    .io_in_8_bits_aliasTask(io_in_8_bits_aliasTask),
    .io_in_8_bits_useProbeData(io_in_8_bits_useProbeData),
    .io_in_8_bits_mshrRetry(io_in_8_bits_mshrRetry),
    .io_in_8_bits_readProbeDataDown(io_in_8_bits_readProbeDataDown),
    .io_in_8_bits_fromL2pft(io_in_8_bits_fromL2pft),
    .io_in_8_bits_dirty(io_in_8_bits_dirty),
    .io_in_8_bits_way(io_in_8_bits_way),
    .io_in_8_bits_meta_dirty(io_in_8_bits_meta_dirty),
    .io_in_8_bits_meta_state(io_in_8_bits_meta_state),
    .io_in_8_bits_meta_clients(io_in_8_bits_meta_clients),
    .io_in_8_bits_meta_alias(io_in_8_bits_meta_alias),
    .io_in_8_bits_meta_prefetch(io_in_8_bits_meta_prefetch),
    .io_in_8_bits_meta_prefetchSrc(io_in_8_bits_meta_prefetchSrc),
    .io_in_8_bits_meta_accessed(io_in_8_bits_meta_accessed),
    .io_in_8_bits_meta_tagErr(io_in_8_bits_meta_tagErr),
    .io_in_8_bits_meta_dataErr(io_in_8_bits_meta_dataErr),
    .io_in_8_bits_metaWen(io_in_8_bits_metaWen),
    .io_in_8_bits_tagWen(io_in_8_bits_tagWen),
    .io_in_8_bits_dsWen(io_in_8_bits_dsWen),
    .io_in_8_bits_replTask(io_in_8_bits_replTask),
    .io_in_8_bits_cmoTask(io_in_8_bits_cmoTask),
    .io_in_8_bits_reqSource(io_in_8_bits_reqSource),
    .io_in_8_bits_mergeA(io_in_8_bits_mergeA),
    .io_in_8_bits_aMergeTask_off(io_in_8_bits_aMergeTask_off),
    .io_in_8_bits_aMergeTask_alias(io_in_8_bits_aMergeTask_alias),
    .io_in_8_bits_aMergeTask_vaddr(io_in_8_bits_aMergeTask_vaddr),
    .io_in_8_bits_aMergeTask_isKeyword(io_in_8_bits_aMergeTask_isKeyword),
    .io_in_8_bits_aMergeTask_opcode(io_in_8_bits_aMergeTask_opcode),
    .io_in_8_bits_aMergeTask_param(io_in_8_bits_aMergeTask_param),
    .io_in_8_bits_aMergeTask_sourceId(io_in_8_bits_aMergeTask_sourceId),
    .io_in_8_bits_aMergeTask_meta_dirty(io_in_8_bits_aMergeTask_meta_dirty),
    .io_in_8_bits_aMergeTask_meta_state(io_in_8_bits_aMergeTask_meta_state),
    .io_in_8_bits_aMergeTask_meta_clients(io_in_8_bits_aMergeTask_meta_clients),
    .io_in_8_bits_aMergeTask_meta_alias(io_in_8_bits_aMergeTask_meta_alias),
    .io_in_8_bits_aMergeTask_meta_accessed(io_in_8_bits_aMergeTask_meta_accessed),
    .io_in_8_bits_snpHitRelease(io_in_8_bits_snpHitRelease),
    .io_in_8_bits_snpHitReleaseToInval(io_in_8_bits_snpHitReleaseToInval),
    .io_in_8_bits_snpHitReleaseToClean(io_in_8_bits_snpHitReleaseToClean),
    .io_in_8_bits_snpHitReleaseWithData(io_in_8_bits_snpHitReleaseWithData),
    .io_in_8_bits_snpHitReleaseIdx(io_in_8_bits_snpHitReleaseIdx),
    .io_in_8_bits_snpHitReleaseMeta_dirty(io_in_8_bits_snpHitReleaseMeta_dirty),
    .io_in_8_bits_snpHitReleaseMeta_state(io_in_8_bits_snpHitReleaseMeta_state),
    .io_in_8_bits_snpHitReleaseMeta_clients(io_in_8_bits_snpHitReleaseMeta_clients),
    .io_in_8_bits_snpHitReleaseMeta_alias(io_in_8_bits_snpHitReleaseMeta_alias),
    .io_in_8_bits_snpHitReleaseMeta_prefetch(io_in_8_bits_snpHitReleaseMeta_prefetch),
    .io_in_8_bits_snpHitReleaseMeta_prefetchSrc(io_in_8_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_8_bits_snpHitReleaseMeta_accessed(io_in_8_bits_snpHitReleaseMeta_accessed),
    .io_in_8_bits_snpHitReleaseMeta_tagErr(io_in_8_bits_snpHitReleaseMeta_tagErr),
    .io_in_8_bits_snpHitReleaseMeta_dataErr(io_in_8_bits_snpHitReleaseMeta_dataErr),
    .io_in_8_bits_tgtID(io_in_8_bits_tgtID),
    .io_in_8_bits_txnID(io_in_8_bits_txnID),
    .io_in_8_bits_homeNID(io_in_8_bits_homeNID),
    .io_in_8_bits_dbID(io_in_8_bits_dbID),
    .io_in_8_bits_chiOpcode(io_in_8_bits_chiOpcode),
    .io_in_8_bits_resp(io_in_8_bits_resp),
    .io_in_8_bits_fwdState(io_in_8_bits_fwdState),
    .io_in_8_bits_retToSrc(io_in_8_bits_retToSrc),
    .io_in_8_bits_likelyshared(io_in_8_bits_likelyshared),
    .io_in_8_bits_expCompAck(io_in_8_bits_expCompAck),
    .io_in_8_bits_allowRetry(io_in_8_bits_allowRetry),
    .io_in_8_bits_memAttr_allocate(io_in_8_bits_memAttr_allocate),
    .io_in_8_bits_memAttr_cacheable(io_in_8_bits_memAttr_cacheable),
    .io_in_8_bits_memAttr_ewa(io_in_8_bits_memAttr_ewa),
    .io_in_8_bits_traceTag(io_in_8_bits_traceTag),
    .io_in_8_bits_dataCheckErr(io_in_8_bits_dataCheckErr),
    .io_in_9_ready(i_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_channel(io_in_9_bits_channel),
    .io_in_9_bits_txChannel(io_in_9_bits_txChannel),
    .io_in_9_bits_set(io_in_9_bits_set),
    .io_in_9_bits_tag(io_in_9_bits_tag),
    .io_in_9_bits_off(io_in_9_bits_off),
    .io_in_9_bits_alias(io_in_9_bits_alias),
    .io_in_9_bits_isKeyword(io_in_9_bits_isKeyword),
    .io_in_9_bits_opcode(io_in_9_bits_opcode),
    .io_in_9_bits_param(io_in_9_bits_param),
    .io_in_9_bits_size(io_in_9_bits_size),
    .io_in_9_bits_sourceId(io_in_9_bits_sourceId),
    .io_in_9_bits_denied(io_in_9_bits_denied),
    .io_in_9_bits_corrupt(io_in_9_bits_corrupt),
    .io_in_9_bits_mshrId(io_in_9_bits_mshrId),
    .io_in_9_bits_aliasTask(io_in_9_bits_aliasTask),
    .io_in_9_bits_useProbeData(io_in_9_bits_useProbeData),
    .io_in_9_bits_mshrRetry(io_in_9_bits_mshrRetry),
    .io_in_9_bits_readProbeDataDown(io_in_9_bits_readProbeDataDown),
    .io_in_9_bits_fromL2pft(io_in_9_bits_fromL2pft),
    .io_in_9_bits_dirty(io_in_9_bits_dirty),
    .io_in_9_bits_way(io_in_9_bits_way),
    .io_in_9_bits_meta_dirty(io_in_9_bits_meta_dirty),
    .io_in_9_bits_meta_state(io_in_9_bits_meta_state),
    .io_in_9_bits_meta_clients(io_in_9_bits_meta_clients),
    .io_in_9_bits_meta_alias(io_in_9_bits_meta_alias),
    .io_in_9_bits_meta_prefetch(io_in_9_bits_meta_prefetch),
    .io_in_9_bits_meta_prefetchSrc(io_in_9_bits_meta_prefetchSrc),
    .io_in_9_bits_meta_accessed(io_in_9_bits_meta_accessed),
    .io_in_9_bits_meta_tagErr(io_in_9_bits_meta_tagErr),
    .io_in_9_bits_meta_dataErr(io_in_9_bits_meta_dataErr),
    .io_in_9_bits_metaWen(io_in_9_bits_metaWen),
    .io_in_9_bits_tagWen(io_in_9_bits_tagWen),
    .io_in_9_bits_dsWen(io_in_9_bits_dsWen),
    .io_in_9_bits_replTask(io_in_9_bits_replTask),
    .io_in_9_bits_cmoTask(io_in_9_bits_cmoTask),
    .io_in_9_bits_reqSource(io_in_9_bits_reqSource),
    .io_in_9_bits_mergeA(io_in_9_bits_mergeA),
    .io_in_9_bits_aMergeTask_off(io_in_9_bits_aMergeTask_off),
    .io_in_9_bits_aMergeTask_alias(io_in_9_bits_aMergeTask_alias),
    .io_in_9_bits_aMergeTask_vaddr(io_in_9_bits_aMergeTask_vaddr),
    .io_in_9_bits_aMergeTask_isKeyword(io_in_9_bits_aMergeTask_isKeyword),
    .io_in_9_bits_aMergeTask_opcode(io_in_9_bits_aMergeTask_opcode),
    .io_in_9_bits_aMergeTask_param(io_in_9_bits_aMergeTask_param),
    .io_in_9_bits_aMergeTask_sourceId(io_in_9_bits_aMergeTask_sourceId),
    .io_in_9_bits_aMergeTask_meta_dirty(io_in_9_bits_aMergeTask_meta_dirty),
    .io_in_9_bits_aMergeTask_meta_state(io_in_9_bits_aMergeTask_meta_state),
    .io_in_9_bits_aMergeTask_meta_clients(io_in_9_bits_aMergeTask_meta_clients),
    .io_in_9_bits_aMergeTask_meta_alias(io_in_9_bits_aMergeTask_meta_alias),
    .io_in_9_bits_aMergeTask_meta_accessed(io_in_9_bits_aMergeTask_meta_accessed),
    .io_in_9_bits_snpHitRelease(io_in_9_bits_snpHitRelease),
    .io_in_9_bits_snpHitReleaseToInval(io_in_9_bits_snpHitReleaseToInval),
    .io_in_9_bits_snpHitReleaseToClean(io_in_9_bits_snpHitReleaseToClean),
    .io_in_9_bits_snpHitReleaseWithData(io_in_9_bits_snpHitReleaseWithData),
    .io_in_9_bits_snpHitReleaseIdx(io_in_9_bits_snpHitReleaseIdx),
    .io_in_9_bits_snpHitReleaseMeta_dirty(io_in_9_bits_snpHitReleaseMeta_dirty),
    .io_in_9_bits_snpHitReleaseMeta_state(io_in_9_bits_snpHitReleaseMeta_state),
    .io_in_9_bits_snpHitReleaseMeta_clients(io_in_9_bits_snpHitReleaseMeta_clients),
    .io_in_9_bits_snpHitReleaseMeta_alias(io_in_9_bits_snpHitReleaseMeta_alias),
    .io_in_9_bits_snpHitReleaseMeta_prefetch(io_in_9_bits_snpHitReleaseMeta_prefetch),
    .io_in_9_bits_snpHitReleaseMeta_prefetchSrc(io_in_9_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_9_bits_snpHitReleaseMeta_accessed(io_in_9_bits_snpHitReleaseMeta_accessed),
    .io_in_9_bits_snpHitReleaseMeta_tagErr(io_in_9_bits_snpHitReleaseMeta_tagErr),
    .io_in_9_bits_snpHitReleaseMeta_dataErr(io_in_9_bits_snpHitReleaseMeta_dataErr),
    .io_in_9_bits_tgtID(io_in_9_bits_tgtID),
    .io_in_9_bits_txnID(io_in_9_bits_txnID),
    .io_in_9_bits_homeNID(io_in_9_bits_homeNID),
    .io_in_9_bits_dbID(io_in_9_bits_dbID),
    .io_in_9_bits_chiOpcode(io_in_9_bits_chiOpcode),
    .io_in_9_bits_resp(io_in_9_bits_resp),
    .io_in_9_bits_fwdState(io_in_9_bits_fwdState),
    .io_in_9_bits_retToSrc(io_in_9_bits_retToSrc),
    .io_in_9_bits_likelyshared(io_in_9_bits_likelyshared),
    .io_in_9_bits_expCompAck(io_in_9_bits_expCompAck),
    .io_in_9_bits_allowRetry(io_in_9_bits_allowRetry),
    .io_in_9_bits_memAttr_allocate(io_in_9_bits_memAttr_allocate),
    .io_in_9_bits_memAttr_cacheable(io_in_9_bits_memAttr_cacheable),
    .io_in_9_bits_memAttr_ewa(io_in_9_bits_memAttr_ewa),
    .io_in_9_bits_traceTag(io_in_9_bits_traceTag),
    .io_in_9_bits_dataCheckErr(io_in_9_bits_dataCheckErr),
    .io_in_10_ready(i_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_channel(io_in_10_bits_channel),
    .io_in_10_bits_txChannel(io_in_10_bits_txChannel),
    .io_in_10_bits_set(io_in_10_bits_set),
    .io_in_10_bits_tag(io_in_10_bits_tag),
    .io_in_10_bits_off(io_in_10_bits_off),
    .io_in_10_bits_alias(io_in_10_bits_alias),
    .io_in_10_bits_isKeyword(io_in_10_bits_isKeyword),
    .io_in_10_bits_opcode(io_in_10_bits_opcode),
    .io_in_10_bits_param(io_in_10_bits_param),
    .io_in_10_bits_size(io_in_10_bits_size),
    .io_in_10_bits_sourceId(io_in_10_bits_sourceId),
    .io_in_10_bits_denied(io_in_10_bits_denied),
    .io_in_10_bits_corrupt(io_in_10_bits_corrupt),
    .io_in_10_bits_mshrId(io_in_10_bits_mshrId),
    .io_in_10_bits_aliasTask(io_in_10_bits_aliasTask),
    .io_in_10_bits_useProbeData(io_in_10_bits_useProbeData),
    .io_in_10_bits_mshrRetry(io_in_10_bits_mshrRetry),
    .io_in_10_bits_readProbeDataDown(io_in_10_bits_readProbeDataDown),
    .io_in_10_bits_fromL2pft(io_in_10_bits_fromL2pft),
    .io_in_10_bits_dirty(io_in_10_bits_dirty),
    .io_in_10_bits_way(io_in_10_bits_way),
    .io_in_10_bits_meta_dirty(io_in_10_bits_meta_dirty),
    .io_in_10_bits_meta_state(io_in_10_bits_meta_state),
    .io_in_10_bits_meta_clients(io_in_10_bits_meta_clients),
    .io_in_10_bits_meta_alias(io_in_10_bits_meta_alias),
    .io_in_10_bits_meta_prefetch(io_in_10_bits_meta_prefetch),
    .io_in_10_bits_meta_prefetchSrc(io_in_10_bits_meta_prefetchSrc),
    .io_in_10_bits_meta_accessed(io_in_10_bits_meta_accessed),
    .io_in_10_bits_meta_tagErr(io_in_10_bits_meta_tagErr),
    .io_in_10_bits_meta_dataErr(io_in_10_bits_meta_dataErr),
    .io_in_10_bits_metaWen(io_in_10_bits_metaWen),
    .io_in_10_bits_tagWen(io_in_10_bits_tagWen),
    .io_in_10_bits_dsWen(io_in_10_bits_dsWen),
    .io_in_10_bits_replTask(io_in_10_bits_replTask),
    .io_in_10_bits_cmoTask(io_in_10_bits_cmoTask),
    .io_in_10_bits_reqSource(io_in_10_bits_reqSource),
    .io_in_10_bits_mergeA(io_in_10_bits_mergeA),
    .io_in_10_bits_aMergeTask_off(io_in_10_bits_aMergeTask_off),
    .io_in_10_bits_aMergeTask_alias(io_in_10_bits_aMergeTask_alias),
    .io_in_10_bits_aMergeTask_vaddr(io_in_10_bits_aMergeTask_vaddr),
    .io_in_10_bits_aMergeTask_isKeyword(io_in_10_bits_aMergeTask_isKeyword),
    .io_in_10_bits_aMergeTask_opcode(io_in_10_bits_aMergeTask_opcode),
    .io_in_10_bits_aMergeTask_param(io_in_10_bits_aMergeTask_param),
    .io_in_10_bits_aMergeTask_sourceId(io_in_10_bits_aMergeTask_sourceId),
    .io_in_10_bits_aMergeTask_meta_dirty(io_in_10_bits_aMergeTask_meta_dirty),
    .io_in_10_bits_aMergeTask_meta_state(io_in_10_bits_aMergeTask_meta_state),
    .io_in_10_bits_aMergeTask_meta_clients(io_in_10_bits_aMergeTask_meta_clients),
    .io_in_10_bits_aMergeTask_meta_alias(io_in_10_bits_aMergeTask_meta_alias),
    .io_in_10_bits_aMergeTask_meta_accessed(io_in_10_bits_aMergeTask_meta_accessed),
    .io_in_10_bits_snpHitRelease(io_in_10_bits_snpHitRelease),
    .io_in_10_bits_snpHitReleaseToInval(io_in_10_bits_snpHitReleaseToInval),
    .io_in_10_bits_snpHitReleaseToClean(io_in_10_bits_snpHitReleaseToClean),
    .io_in_10_bits_snpHitReleaseWithData(io_in_10_bits_snpHitReleaseWithData),
    .io_in_10_bits_snpHitReleaseIdx(io_in_10_bits_snpHitReleaseIdx),
    .io_in_10_bits_snpHitReleaseMeta_dirty(io_in_10_bits_snpHitReleaseMeta_dirty),
    .io_in_10_bits_snpHitReleaseMeta_state(io_in_10_bits_snpHitReleaseMeta_state),
    .io_in_10_bits_snpHitReleaseMeta_clients(io_in_10_bits_snpHitReleaseMeta_clients),
    .io_in_10_bits_snpHitReleaseMeta_alias(io_in_10_bits_snpHitReleaseMeta_alias),
    .io_in_10_bits_snpHitReleaseMeta_prefetch(io_in_10_bits_snpHitReleaseMeta_prefetch),
    .io_in_10_bits_snpHitReleaseMeta_prefetchSrc(io_in_10_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_10_bits_snpHitReleaseMeta_accessed(io_in_10_bits_snpHitReleaseMeta_accessed),
    .io_in_10_bits_snpHitReleaseMeta_tagErr(io_in_10_bits_snpHitReleaseMeta_tagErr),
    .io_in_10_bits_snpHitReleaseMeta_dataErr(io_in_10_bits_snpHitReleaseMeta_dataErr),
    .io_in_10_bits_tgtID(io_in_10_bits_tgtID),
    .io_in_10_bits_txnID(io_in_10_bits_txnID),
    .io_in_10_bits_homeNID(io_in_10_bits_homeNID),
    .io_in_10_bits_dbID(io_in_10_bits_dbID),
    .io_in_10_bits_chiOpcode(io_in_10_bits_chiOpcode),
    .io_in_10_bits_resp(io_in_10_bits_resp),
    .io_in_10_bits_fwdState(io_in_10_bits_fwdState),
    .io_in_10_bits_retToSrc(io_in_10_bits_retToSrc),
    .io_in_10_bits_likelyshared(io_in_10_bits_likelyshared),
    .io_in_10_bits_expCompAck(io_in_10_bits_expCompAck),
    .io_in_10_bits_allowRetry(io_in_10_bits_allowRetry),
    .io_in_10_bits_memAttr_allocate(io_in_10_bits_memAttr_allocate),
    .io_in_10_bits_memAttr_cacheable(io_in_10_bits_memAttr_cacheable),
    .io_in_10_bits_memAttr_ewa(io_in_10_bits_memAttr_ewa),
    .io_in_10_bits_traceTag(io_in_10_bits_traceTag),
    .io_in_10_bits_dataCheckErr(io_in_10_bits_dataCheckErr),
    .io_in_11_ready(i_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_channel(io_in_11_bits_channel),
    .io_in_11_bits_txChannel(io_in_11_bits_txChannel),
    .io_in_11_bits_set(io_in_11_bits_set),
    .io_in_11_bits_tag(io_in_11_bits_tag),
    .io_in_11_bits_off(io_in_11_bits_off),
    .io_in_11_bits_alias(io_in_11_bits_alias),
    .io_in_11_bits_isKeyword(io_in_11_bits_isKeyword),
    .io_in_11_bits_opcode(io_in_11_bits_opcode),
    .io_in_11_bits_param(io_in_11_bits_param),
    .io_in_11_bits_size(io_in_11_bits_size),
    .io_in_11_bits_sourceId(io_in_11_bits_sourceId),
    .io_in_11_bits_denied(io_in_11_bits_denied),
    .io_in_11_bits_corrupt(io_in_11_bits_corrupt),
    .io_in_11_bits_mshrId(io_in_11_bits_mshrId),
    .io_in_11_bits_aliasTask(io_in_11_bits_aliasTask),
    .io_in_11_bits_useProbeData(io_in_11_bits_useProbeData),
    .io_in_11_bits_mshrRetry(io_in_11_bits_mshrRetry),
    .io_in_11_bits_readProbeDataDown(io_in_11_bits_readProbeDataDown),
    .io_in_11_bits_fromL2pft(io_in_11_bits_fromL2pft),
    .io_in_11_bits_dirty(io_in_11_bits_dirty),
    .io_in_11_bits_way(io_in_11_bits_way),
    .io_in_11_bits_meta_dirty(io_in_11_bits_meta_dirty),
    .io_in_11_bits_meta_state(io_in_11_bits_meta_state),
    .io_in_11_bits_meta_clients(io_in_11_bits_meta_clients),
    .io_in_11_bits_meta_alias(io_in_11_bits_meta_alias),
    .io_in_11_bits_meta_prefetch(io_in_11_bits_meta_prefetch),
    .io_in_11_bits_meta_prefetchSrc(io_in_11_bits_meta_prefetchSrc),
    .io_in_11_bits_meta_accessed(io_in_11_bits_meta_accessed),
    .io_in_11_bits_meta_tagErr(io_in_11_bits_meta_tagErr),
    .io_in_11_bits_meta_dataErr(io_in_11_bits_meta_dataErr),
    .io_in_11_bits_metaWen(io_in_11_bits_metaWen),
    .io_in_11_bits_tagWen(io_in_11_bits_tagWen),
    .io_in_11_bits_dsWen(io_in_11_bits_dsWen),
    .io_in_11_bits_replTask(io_in_11_bits_replTask),
    .io_in_11_bits_cmoTask(io_in_11_bits_cmoTask),
    .io_in_11_bits_reqSource(io_in_11_bits_reqSource),
    .io_in_11_bits_mergeA(io_in_11_bits_mergeA),
    .io_in_11_bits_aMergeTask_off(io_in_11_bits_aMergeTask_off),
    .io_in_11_bits_aMergeTask_alias(io_in_11_bits_aMergeTask_alias),
    .io_in_11_bits_aMergeTask_vaddr(io_in_11_bits_aMergeTask_vaddr),
    .io_in_11_bits_aMergeTask_isKeyword(io_in_11_bits_aMergeTask_isKeyword),
    .io_in_11_bits_aMergeTask_opcode(io_in_11_bits_aMergeTask_opcode),
    .io_in_11_bits_aMergeTask_param(io_in_11_bits_aMergeTask_param),
    .io_in_11_bits_aMergeTask_sourceId(io_in_11_bits_aMergeTask_sourceId),
    .io_in_11_bits_aMergeTask_meta_dirty(io_in_11_bits_aMergeTask_meta_dirty),
    .io_in_11_bits_aMergeTask_meta_state(io_in_11_bits_aMergeTask_meta_state),
    .io_in_11_bits_aMergeTask_meta_clients(io_in_11_bits_aMergeTask_meta_clients),
    .io_in_11_bits_aMergeTask_meta_alias(io_in_11_bits_aMergeTask_meta_alias),
    .io_in_11_bits_aMergeTask_meta_accessed(io_in_11_bits_aMergeTask_meta_accessed),
    .io_in_11_bits_snpHitRelease(io_in_11_bits_snpHitRelease),
    .io_in_11_bits_snpHitReleaseToInval(io_in_11_bits_snpHitReleaseToInval),
    .io_in_11_bits_snpHitReleaseToClean(io_in_11_bits_snpHitReleaseToClean),
    .io_in_11_bits_snpHitReleaseWithData(io_in_11_bits_snpHitReleaseWithData),
    .io_in_11_bits_snpHitReleaseIdx(io_in_11_bits_snpHitReleaseIdx),
    .io_in_11_bits_snpHitReleaseMeta_dirty(io_in_11_bits_snpHitReleaseMeta_dirty),
    .io_in_11_bits_snpHitReleaseMeta_state(io_in_11_bits_snpHitReleaseMeta_state),
    .io_in_11_bits_snpHitReleaseMeta_clients(io_in_11_bits_snpHitReleaseMeta_clients),
    .io_in_11_bits_snpHitReleaseMeta_alias(io_in_11_bits_snpHitReleaseMeta_alias),
    .io_in_11_bits_snpHitReleaseMeta_prefetch(io_in_11_bits_snpHitReleaseMeta_prefetch),
    .io_in_11_bits_snpHitReleaseMeta_prefetchSrc(io_in_11_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_11_bits_snpHitReleaseMeta_accessed(io_in_11_bits_snpHitReleaseMeta_accessed),
    .io_in_11_bits_snpHitReleaseMeta_tagErr(io_in_11_bits_snpHitReleaseMeta_tagErr),
    .io_in_11_bits_snpHitReleaseMeta_dataErr(io_in_11_bits_snpHitReleaseMeta_dataErr),
    .io_in_11_bits_tgtID(io_in_11_bits_tgtID),
    .io_in_11_bits_txnID(io_in_11_bits_txnID),
    .io_in_11_bits_homeNID(io_in_11_bits_homeNID),
    .io_in_11_bits_dbID(io_in_11_bits_dbID),
    .io_in_11_bits_chiOpcode(io_in_11_bits_chiOpcode),
    .io_in_11_bits_resp(io_in_11_bits_resp),
    .io_in_11_bits_fwdState(io_in_11_bits_fwdState),
    .io_in_11_bits_retToSrc(io_in_11_bits_retToSrc),
    .io_in_11_bits_likelyshared(io_in_11_bits_likelyshared),
    .io_in_11_bits_expCompAck(io_in_11_bits_expCompAck),
    .io_in_11_bits_allowRetry(io_in_11_bits_allowRetry),
    .io_in_11_bits_memAttr_allocate(io_in_11_bits_memAttr_allocate),
    .io_in_11_bits_memAttr_cacheable(io_in_11_bits_memAttr_cacheable),
    .io_in_11_bits_memAttr_ewa(io_in_11_bits_memAttr_ewa),
    .io_in_11_bits_traceTag(io_in_11_bits_traceTag),
    .io_in_11_bits_dataCheckErr(io_in_11_bits_dataCheckErr),
    .io_in_12_ready(i_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_channel(io_in_12_bits_channel),
    .io_in_12_bits_txChannel(io_in_12_bits_txChannel),
    .io_in_12_bits_set(io_in_12_bits_set),
    .io_in_12_bits_tag(io_in_12_bits_tag),
    .io_in_12_bits_off(io_in_12_bits_off),
    .io_in_12_bits_alias(io_in_12_bits_alias),
    .io_in_12_bits_isKeyword(io_in_12_bits_isKeyword),
    .io_in_12_bits_opcode(io_in_12_bits_opcode),
    .io_in_12_bits_param(io_in_12_bits_param),
    .io_in_12_bits_size(io_in_12_bits_size),
    .io_in_12_bits_sourceId(io_in_12_bits_sourceId),
    .io_in_12_bits_denied(io_in_12_bits_denied),
    .io_in_12_bits_corrupt(io_in_12_bits_corrupt),
    .io_in_12_bits_mshrId(io_in_12_bits_mshrId),
    .io_in_12_bits_aliasTask(io_in_12_bits_aliasTask),
    .io_in_12_bits_useProbeData(io_in_12_bits_useProbeData),
    .io_in_12_bits_mshrRetry(io_in_12_bits_mshrRetry),
    .io_in_12_bits_readProbeDataDown(io_in_12_bits_readProbeDataDown),
    .io_in_12_bits_fromL2pft(io_in_12_bits_fromL2pft),
    .io_in_12_bits_dirty(io_in_12_bits_dirty),
    .io_in_12_bits_way(io_in_12_bits_way),
    .io_in_12_bits_meta_dirty(io_in_12_bits_meta_dirty),
    .io_in_12_bits_meta_state(io_in_12_bits_meta_state),
    .io_in_12_bits_meta_clients(io_in_12_bits_meta_clients),
    .io_in_12_bits_meta_alias(io_in_12_bits_meta_alias),
    .io_in_12_bits_meta_prefetch(io_in_12_bits_meta_prefetch),
    .io_in_12_bits_meta_prefetchSrc(io_in_12_bits_meta_prefetchSrc),
    .io_in_12_bits_meta_accessed(io_in_12_bits_meta_accessed),
    .io_in_12_bits_meta_tagErr(io_in_12_bits_meta_tagErr),
    .io_in_12_bits_meta_dataErr(io_in_12_bits_meta_dataErr),
    .io_in_12_bits_metaWen(io_in_12_bits_metaWen),
    .io_in_12_bits_tagWen(io_in_12_bits_tagWen),
    .io_in_12_bits_dsWen(io_in_12_bits_dsWen),
    .io_in_12_bits_replTask(io_in_12_bits_replTask),
    .io_in_12_bits_cmoTask(io_in_12_bits_cmoTask),
    .io_in_12_bits_reqSource(io_in_12_bits_reqSource),
    .io_in_12_bits_mergeA(io_in_12_bits_mergeA),
    .io_in_12_bits_aMergeTask_off(io_in_12_bits_aMergeTask_off),
    .io_in_12_bits_aMergeTask_alias(io_in_12_bits_aMergeTask_alias),
    .io_in_12_bits_aMergeTask_vaddr(io_in_12_bits_aMergeTask_vaddr),
    .io_in_12_bits_aMergeTask_isKeyword(io_in_12_bits_aMergeTask_isKeyword),
    .io_in_12_bits_aMergeTask_opcode(io_in_12_bits_aMergeTask_opcode),
    .io_in_12_bits_aMergeTask_param(io_in_12_bits_aMergeTask_param),
    .io_in_12_bits_aMergeTask_sourceId(io_in_12_bits_aMergeTask_sourceId),
    .io_in_12_bits_aMergeTask_meta_dirty(io_in_12_bits_aMergeTask_meta_dirty),
    .io_in_12_bits_aMergeTask_meta_state(io_in_12_bits_aMergeTask_meta_state),
    .io_in_12_bits_aMergeTask_meta_clients(io_in_12_bits_aMergeTask_meta_clients),
    .io_in_12_bits_aMergeTask_meta_alias(io_in_12_bits_aMergeTask_meta_alias),
    .io_in_12_bits_aMergeTask_meta_accessed(io_in_12_bits_aMergeTask_meta_accessed),
    .io_in_12_bits_snpHitRelease(io_in_12_bits_snpHitRelease),
    .io_in_12_bits_snpHitReleaseToInval(io_in_12_bits_snpHitReleaseToInval),
    .io_in_12_bits_snpHitReleaseToClean(io_in_12_bits_snpHitReleaseToClean),
    .io_in_12_bits_snpHitReleaseWithData(io_in_12_bits_snpHitReleaseWithData),
    .io_in_12_bits_snpHitReleaseIdx(io_in_12_bits_snpHitReleaseIdx),
    .io_in_12_bits_snpHitReleaseMeta_dirty(io_in_12_bits_snpHitReleaseMeta_dirty),
    .io_in_12_bits_snpHitReleaseMeta_state(io_in_12_bits_snpHitReleaseMeta_state),
    .io_in_12_bits_snpHitReleaseMeta_clients(io_in_12_bits_snpHitReleaseMeta_clients),
    .io_in_12_bits_snpHitReleaseMeta_alias(io_in_12_bits_snpHitReleaseMeta_alias),
    .io_in_12_bits_snpHitReleaseMeta_prefetch(io_in_12_bits_snpHitReleaseMeta_prefetch),
    .io_in_12_bits_snpHitReleaseMeta_prefetchSrc(io_in_12_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_12_bits_snpHitReleaseMeta_accessed(io_in_12_bits_snpHitReleaseMeta_accessed),
    .io_in_12_bits_snpHitReleaseMeta_tagErr(io_in_12_bits_snpHitReleaseMeta_tagErr),
    .io_in_12_bits_snpHitReleaseMeta_dataErr(io_in_12_bits_snpHitReleaseMeta_dataErr),
    .io_in_12_bits_tgtID(io_in_12_bits_tgtID),
    .io_in_12_bits_txnID(io_in_12_bits_txnID),
    .io_in_12_bits_homeNID(io_in_12_bits_homeNID),
    .io_in_12_bits_dbID(io_in_12_bits_dbID),
    .io_in_12_bits_chiOpcode(io_in_12_bits_chiOpcode),
    .io_in_12_bits_resp(io_in_12_bits_resp),
    .io_in_12_bits_fwdState(io_in_12_bits_fwdState),
    .io_in_12_bits_retToSrc(io_in_12_bits_retToSrc),
    .io_in_12_bits_likelyshared(io_in_12_bits_likelyshared),
    .io_in_12_bits_expCompAck(io_in_12_bits_expCompAck),
    .io_in_12_bits_allowRetry(io_in_12_bits_allowRetry),
    .io_in_12_bits_memAttr_allocate(io_in_12_bits_memAttr_allocate),
    .io_in_12_bits_memAttr_cacheable(io_in_12_bits_memAttr_cacheable),
    .io_in_12_bits_memAttr_ewa(io_in_12_bits_memAttr_ewa),
    .io_in_12_bits_traceTag(io_in_12_bits_traceTag),
    .io_in_12_bits_dataCheckErr(io_in_12_bits_dataCheckErr),
    .io_in_13_ready(i_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_channel(io_in_13_bits_channel),
    .io_in_13_bits_txChannel(io_in_13_bits_txChannel),
    .io_in_13_bits_set(io_in_13_bits_set),
    .io_in_13_bits_tag(io_in_13_bits_tag),
    .io_in_13_bits_off(io_in_13_bits_off),
    .io_in_13_bits_alias(io_in_13_bits_alias),
    .io_in_13_bits_isKeyword(io_in_13_bits_isKeyword),
    .io_in_13_bits_opcode(io_in_13_bits_opcode),
    .io_in_13_bits_param(io_in_13_bits_param),
    .io_in_13_bits_size(io_in_13_bits_size),
    .io_in_13_bits_sourceId(io_in_13_bits_sourceId),
    .io_in_13_bits_denied(io_in_13_bits_denied),
    .io_in_13_bits_corrupt(io_in_13_bits_corrupt),
    .io_in_13_bits_mshrId(io_in_13_bits_mshrId),
    .io_in_13_bits_aliasTask(io_in_13_bits_aliasTask),
    .io_in_13_bits_useProbeData(io_in_13_bits_useProbeData),
    .io_in_13_bits_mshrRetry(io_in_13_bits_mshrRetry),
    .io_in_13_bits_readProbeDataDown(io_in_13_bits_readProbeDataDown),
    .io_in_13_bits_fromL2pft(io_in_13_bits_fromL2pft),
    .io_in_13_bits_dirty(io_in_13_bits_dirty),
    .io_in_13_bits_way(io_in_13_bits_way),
    .io_in_13_bits_meta_dirty(io_in_13_bits_meta_dirty),
    .io_in_13_bits_meta_state(io_in_13_bits_meta_state),
    .io_in_13_bits_meta_clients(io_in_13_bits_meta_clients),
    .io_in_13_bits_meta_alias(io_in_13_bits_meta_alias),
    .io_in_13_bits_meta_prefetch(io_in_13_bits_meta_prefetch),
    .io_in_13_bits_meta_prefetchSrc(io_in_13_bits_meta_prefetchSrc),
    .io_in_13_bits_meta_accessed(io_in_13_bits_meta_accessed),
    .io_in_13_bits_meta_tagErr(io_in_13_bits_meta_tagErr),
    .io_in_13_bits_meta_dataErr(io_in_13_bits_meta_dataErr),
    .io_in_13_bits_metaWen(io_in_13_bits_metaWen),
    .io_in_13_bits_tagWen(io_in_13_bits_tagWen),
    .io_in_13_bits_dsWen(io_in_13_bits_dsWen),
    .io_in_13_bits_replTask(io_in_13_bits_replTask),
    .io_in_13_bits_cmoTask(io_in_13_bits_cmoTask),
    .io_in_13_bits_reqSource(io_in_13_bits_reqSource),
    .io_in_13_bits_mergeA(io_in_13_bits_mergeA),
    .io_in_13_bits_aMergeTask_off(io_in_13_bits_aMergeTask_off),
    .io_in_13_bits_aMergeTask_alias(io_in_13_bits_aMergeTask_alias),
    .io_in_13_bits_aMergeTask_vaddr(io_in_13_bits_aMergeTask_vaddr),
    .io_in_13_bits_aMergeTask_isKeyword(io_in_13_bits_aMergeTask_isKeyword),
    .io_in_13_bits_aMergeTask_opcode(io_in_13_bits_aMergeTask_opcode),
    .io_in_13_bits_aMergeTask_param(io_in_13_bits_aMergeTask_param),
    .io_in_13_bits_aMergeTask_sourceId(io_in_13_bits_aMergeTask_sourceId),
    .io_in_13_bits_aMergeTask_meta_dirty(io_in_13_bits_aMergeTask_meta_dirty),
    .io_in_13_bits_aMergeTask_meta_state(io_in_13_bits_aMergeTask_meta_state),
    .io_in_13_bits_aMergeTask_meta_clients(io_in_13_bits_aMergeTask_meta_clients),
    .io_in_13_bits_aMergeTask_meta_alias(io_in_13_bits_aMergeTask_meta_alias),
    .io_in_13_bits_aMergeTask_meta_accessed(io_in_13_bits_aMergeTask_meta_accessed),
    .io_in_13_bits_snpHitRelease(io_in_13_bits_snpHitRelease),
    .io_in_13_bits_snpHitReleaseToInval(io_in_13_bits_snpHitReleaseToInval),
    .io_in_13_bits_snpHitReleaseToClean(io_in_13_bits_snpHitReleaseToClean),
    .io_in_13_bits_snpHitReleaseWithData(io_in_13_bits_snpHitReleaseWithData),
    .io_in_13_bits_snpHitReleaseIdx(io_in_13_bits_snpHitReleaseIdx),
    .io_in_13_bits_snpHitReleaseMeta_dirty(io_in_13_bits_snpHitReleaseMeta_dirty),
    .io_in_13_bits_snpHitReleaseMeta_state(io_in_13_bits_snpHitReleaseMeta_state),
    .io_in_13_bits_snpHitReleaseMeta_clients(io_in_13_bits_snpHitReleaseMeta_clients),
    .io_in_13_bits_snpHitReleaseMeta_alias(io_in_13_bits_snpHitReleaseMeta_alias),
    .io_in_13_bits_snpHitReleaseMeta_prefetch(io_in_13_bits_snpHitReleaseMeta_prefetch),
    .io_in_13_bits_snpHitReleaseMeta_prefetchSrc(io_in_13_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_13_bits_snpHitReleaseMeta_accessed(io_in_13_bits_snpHitReleaseMeta_accessed),
    .io_in_13_bits_snpHitReleaseMeta_tagErr(io_in_13_bits_snpHitReleaseMeta_tagErr),
    .io_in_13_bits_snpHitReleaseMeta_dataErr(io_in_13_bits_snpHitReleaseMeta_dataErr),
    .io_in_13_bits_tgtID(io_in_13_bits_tgtID),
    .io_in_13_bits_txnID(io_in_13_bits_txnID),
    .io_in_13_bits_homeNID(io_in_13_bits_homeNID),
    .io_in_13_bits_dbID(io_in_13_bits_dbID),
    .io_in_13_bits_chiOpcode(io_in_13_bits_chiOpcode),
    .io_in_13_bits_resp(io_in_13_bits_resp),
    .io_in_13_bits_fwdState(io_in_13_bits_fwdState),
    .io_in_13_bits_retToSrc(io_in_13_bits_retToSrc),
    .io_in_13_bits_likelyshared(io_in_13_bits_likelyshared),
    .io_in_13_bits_expCompAck(io_in_13_bits_expCompAck),
    .io_in_13_bits_allowRetry(io_in_13_bits_allowRetry),
    .io_in_13_bits_memAttr_allocate(io_in_13_bits_memAttr_allocate),
    .io_in_13_bits_memAttr_cacheable(io_in_13_bits_memAttr_cacheable),
    .io_in_13_bits_memAttr_ewa(io_in_13_bits_memAttr_ewa),
    .io_in_13_bits_traceTag(io_in_13_bits_traceTag),
    .io_in_13_bits_dataCheckErr(io_in_13_bits_dataCheckErr),
    .io_in_14_ready(i_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_channel(io_in_14_bits_channel),
    .io_in_14_bits_txChannel(io_in_14_bits_txChannel),
    .io_in_14_bits_set(io_in_14_bits_set),
    .io_in_14_bits_tag(io_in_14_bits_tag),
    .io_in_14_bits_off(io_in_14_bits_off),
    .io_in_14_bits_alias(io_in_14_bits_alias),
    .io_in_14_bits_isKeyword(io_in_14_bits_isKeyword),
    .io_in_14_bits_opcode(io_in_14_bits_opcode),
    .io_in_14_bits_param(io_in_14_bits_param),
    .io_in_14_bits_size(io_in_14_bits_size),
    .io_in_14_bits_sourceId(io_in_14_bits_sourceId),
    .io_in_14_bits_denied(io_in_14_bits_denied),
    .io_in_14_bits_corrupt(io_in_14_bits_corrupt),
    .io_in_14_bits_mshrId(io_in_14_bits_mshrId),
    .io_in_14_bits_aliasTask(io_in_14_bits_aliasTask),
    .io_in_14_bits_useProbeData(io_in_14_bits_useProbeData),
    .io_in_14_bits_mshrRetry(io_in_14_bits_mshrRetry),
    .io_in_14_bits_readProbeDataDown(io_in_14_bits_readProbeDataDown),
    .io_in_14_bits_fromL2pft(io_in_14_bits_fromL2pft),
    .io_in_14_bits_dirty(io_in_14_bits_dirty),
    .io_in_14_bits_way(io_in_14_bits_way),
    .io_in_14_bits_meta_dirty(io_in_14_bits_meta_dirty),
    .io_in_14_bits_meta_state(io_in_14_bits_meta_state),
    .io_in_14_bits_meta_clients(io_in_14_bits_meta_clients),
    .io_in_14_bits_meta_alias(io_in_14_bits_meta_alias),
    .io_in_14_bits_meta_prefetch(io_in_14_bits_meta_prefetch),
    .io_in_14_bits_meta_prefetchSrc(io_in_14_bits_meta_prefetchSrc),
    .io_in_14_bits_meta_accessed(io_in_14_bits_meta_accessed),
    .io_in_14_bits_meta_tagErr(io_in_14_bits_meta_tagErr),
    .io_in_14_bits_meta_dataErr(io_in_14_bits_meta_dataErr),
    .io_in_14_bits_metaWen(io_in_14_bits_metaWen),
    .io_in_14_bits_tagWen(io_in_14_bits_tagWen),
    .io_in_14_bits_dsWen(io_in_14_bits_dsWen),
    .io_in_14_bits_replTask(io_in_14_bits_replTask),
    .io_in_14_bits_cmoTask(io_in_14_bits_cmoTask),
    .io_in_14_bits_reqSource(io_in_14_bits_reqSource),
    .io_in_14_bits_mergeA(io_in_14_bits_mergeA),
    .io_in_14_bits_aMergeTask_off(io_in_14_bits_aMergeTask_off),
    .io_in_14_bits_aMergeTask_alias(io_in_14_bits_aMergeTask_alias),
    .io_in_14_bits_aMergeTask_vaddr(io_in_14_bits_aMergeTask_vaddr),
    .io_in_14_bits_aMergeTask_isKeyword(io_in_14_bits_aMergeTask_isKeyword),
    .io_in_14_bits_aMergeTask_opcode(io_in_14_bits_aMergeTask_opcode),
    .io_in_14_bits_aMergeTask_param(io_in_14_bits_aMergeTask_param),
    .io_in_14_bits_aMergeTask_sourceId(io_in_14_bits_aMergeTask_sourceId),
    .io_in_14_bits_aMergeTask_meta_dirty(io_in_14_bits_aMergeTask_meta_dirty),
    .io_in_14_bits_aMergeTask_meta_state(io_in_14_bits_aMergeTask_meta_state),
    .io_in_14_bits_aMergeTask_meta_clients(io_in_14_bits_aMergeTask_meta_clients),
    .io_in_14_bits_aMergeTask_meta_alias(io_in_14_bits_aMergeTask_meta_alias),
    .io_in_14_bits_aMergeTask_meta_accessed(io_in_14_bits_aMergeTask_meta_accessed),
    .io_in_14_bits_snpHitRelease(io_in_14_bits_snpHitRelease),
    .io_in_14_bits_snpHitReleaseToInval(io_in_14_bits_snpHitReleaseToInval),
    .io_in_14_bits_snpHitReleaseToClean(io_in_14_bits_snpHitReleaseToClean),
    .io_in_14_bits_snpHitReleaseWithData(io_in_14_bits_snpHitReleaseWithData),
    .io_in_14_bits_snpHitReleaseIdx(io_in_14_bits_snpHitReleaseIdx),
    .io_in_14_bits_snpHitReleaseMeta_dirty(io_in_14_bits_snpHitReleaseMeta_dirty),
    .io_in_14_bits_snpHitReleaseMeta_state(io_in_14_bits_snpHitReleaseMeta_state),
    .io_in_14_bits_snpHitReleaseMeta_clients(io_in_14_bits_snpHitReleaseMeta_clients),
    .io_in_14_bits_snpHitReleaseMeta_alias(io_in_14_bits_snpHitReleaseMeta_alias),
    .io_in_14_bits_snpHitReleaseMeta_prefetch(io_in_14_bits_snpHitReleaseMeta_prefetch),
    .io_in_14_bits_snpHitReleaseMeta_prefetchSrc(io_in_14_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_14_bits_snpHitReleaseMeta_accessed(io_in_14_bits_snpHitReleaseMeta_accessed),
    .io_in_14_bits_snpHitReleaseMeta_tagErr(io_in_14_bits_snpHitReleaseMeta_tagErr),
    .io_in_14_bits_snpHitReleaseMeta_dataErr(io_in_14_bits_snpHitReleaseMeta_dataErr),
    .io_in_14_bits_tgtID(io_in_14_bits_tgtID),
    .io_in_14_bits_txnID(io_in_14_bits_txnID),
    .io_in_14_bits_homeNID(io_in_14_bits_homeNID),
    .io_in_14_bits_dbID(io_in_14_bits_dbID),
    .io_in_14_bits_chiOpcode(io_in_14_bits_chiOpcode),
    .io_in_14_bits_resp(io_in_14_bits_resp),
    .io_in_14_bits_fwdState(io_in_14_bits_fwdState),
    .io_in_14_bits_retToSrc(io_in_14_bits_retToSrc),
    .io_in_14_bits_likelyshared(io_in_14_bits_likelyshared),
    .io_in_14_bits_expCompAck(io_in_14_bits_expCompAck),
    .io_in_14_bits_allowRetry(io_in_14_bits_allowRetry),
    .io_in_14_bits_memAttr_allocate(io_in_14_bits_memAttr_allocate),
    .io_in_14_bits_memAttr_cacheable(io_in_14_bits_memAttr_cacheable),
    .io_in_14_bits_memAttr_ewa(io_in_14_bits_memAttr_ewa),
    .io_in_14_bits_traceTag(io_in_14_bits_traceTag),
    .io_in_14_bits_dataCheckErr(io_in_14_bits_dataCheckErr),
    .io_in_15_ready(i_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_channel(io_in_15_bits_channel),
    .io_in_15_bits_txChannel(io_in_15_bits_txChannel),
    .io_in_15_bits_set(io_in_15_bits_set),
    .io_in_15_bits_tag(io_in_15_bits_tag),
    .io_in_15_bits_off(io_in_15_bits_off),
    .io_in_15_bits_alias(io_in_15_bits_alias),
    .io_in_15_bits_isKeyword(io_in_15_bits_isKeyword),
    .io_in_15_bits_opcode(io_in_15_bits_opcode),
    .io_in_15_bits_param(io_in_15_bits_param),
    .io_in_15_bits_size(io_in_15_bits_size),
    .io_in_15_bits_sourceId(io_in_15_bits_sourceId),
    .io_in_15_bits_denied(io_in_15_bits_denied),
    .io_in_15_bits_corrupt(io_in_15_bits_corrupt),
    .io_in_15_bits_mshrId(io_in_15_bits_mshrId),
    .io_in_15_bits_aliasTask(io_in_15_bits_aliasTask),
    .io_in_15_bits_useProbeData(io_in_15_bits_useProbeData),
    .io_in_15_bits_mshrRetry(io_in_15_bits_mshrRetry),
    .io_in_15_bits_readProbeDataDown(io_in_15_bits_readProbeDataDown),
    .io_in_15_bits_fromL2pft(io_in_15_bits_fromL2pft),
    .io_in_15_bits_dirty(io_in_15_bits_dirty),
    .io_in_15_bits_way(io_in_15_bits_way),
    .io_in_15_bits_meta_dirty(io_in_15_bits_meta_dirty),
    .io_in_15_bits_meta_state(io_in_15_bits_meta_state),
    .io_in_15_bits_meta_clients(io_in_15_bits_meta_clients),
    .io_in_15_bits_meta_alias(io_in_15_bits_meta_alias),
    .io_in_15_bits_meta_prefetch(io_in_15_bits_meta_prefetch),
    .io_in_15_bits_meta_prefetchSrc(io_in_15_bits_meta_prefetchSrc),
    .io_in_15_bits_meta_accessed(io_in_15_bits_meta_accessed),
    .io_in_15_bits_meta_tagErr(io_in_15_bits_meta_tagErr),
    .io_in_15_bits_meta_dataErr(io_in_15_bits_meta_dataErr),
    .io_in_15_bits_metaWen(io_in_15_bits_metaWen),
    .io_in_15_bits_tagWen(io_in_15_bits_tagWen),
    .io_in_15_bits_dsWen(io_in_15_bits_dsWen),
    .io_in_15_bits_replTask(io_in_15_bits_replTask),
    .io_in_15_bits_cmoTask(io_in_15_bits_cmoTask),
    .io_in_15_bits_reqSource(io_in_15_bits_reqSource),
    .io_in_15_bits_mergeA(io_in_15_bits_mergeA),
    .io_in_15_bits_aMergeTask_off(io_in_15_bits_aMergeTask_off),
    .io_in_15_bits_aMergeTask_alias(io_in_15_bits_aMergeTask_alias),
    .io_in_15_bits_aMergeTask_vaddr(io_in_15_bits_aMergeTask_vaddr),
    .io_in_15_bits_aMergeTask_isKeyword(io_in_15_bits_aMergeTask_isKeyword),
    .io_in_15_bits_aMergeTask_opcode(io_in_15_bits_aMergeTask_opcode),
    .io_in_15_bits_aMergeTask_param(io_in_15_bits_aMergeTask_param),
    .io_in_15_bits_aMergeTask_sourceId(io_in_15_bits_aMergeTask_sourceId),
    .io_in_15_bits_aMergeTask_meta_dirty(io_in_15_bits_aMergeTask_meta_dirty),
    .io_in_15_bits_aMergeTask_meta_state(io_in_15_bits_aMergeTask_meta_state),
    .io_in_15_bits_aMergeTask_meta_clients(io_in_15_bits_aMergeTask_meta_clients),
    .io_in_15_bits_aMergeTask_meta_alias(io_in_15_bits_aMergeTask_meta_alias),
    .io_in_15_bits_aMergeTask_meta_accessed(io_in_15_bits_aMergeTask_meta_accessed),
    .io_in_15_bits_snpHitRelease(io_in_15_bits_snpHitRelease),
    .io_in_15_bits_snpHitReleaseToInval(io_in_15_bits_snpHitReleaseToInval),
    .io_in_15_bits_snpHitReleaseToClean(io_in_15_bits_snpHitReleaseToClean),
    .io_in_15_bits_snpHitReleaseWithData(io_in_15_bits_snpHitReleaseWithData),
    .io_in_15_bits_snpHitReleaseIdx(io_in_15_bits_snpHitReleaseIdx),
    .io_in_15_bits_snpHitReleaseMeta_dirty(io_in_15_bits_snpHitReleaseMeta_dirty),
    .io_in_15_bits_snpHitReleaseMeta_state(io_in_15_bits_snpHitReleaseMeta_state),
    .io_in_15_bits_snpHitReleaseMeta_clients(io_in_15_bits_snpHitReleaseMeta_clients),
    .io_in_15_bits_snpHitReleaseMeta_alias(io_in_15_bits_snpHitReleaseMeta_alias),
    .io_in_15_bits_snpHitReleaseMeta_prefetch(io_in_15_bits_snpHitReleaseMeta_prefetch),
    .io_in_15_bits_snpHitReleaseMeta_prefetchSrc(io_in_15_bits_snpHitReleaseMeta_prefetchSrc),
    .io_in_15_bits_snpHitReleaseMeta_accessed(io_in_15_bits_snpHitReleaseMeta_accessed),
    .io_in_15_bits_snpHitReleaseMeta_tagErr(io_in_15_bits_snpHitReleaseMeta_tagErr),
    .io_in_15_bits_snpHitReleaseMeta_dataErr(io_in_15_bits_snpHitReleaseMeta_dataErr),
    .io_in_15_bits_tgtID(io_in_15_bits_tgtID),
    .io_in_15_bits_txnID(io_in_15_bits_txnID),
    .io_in_15_bits_homeNID(io_in_15_bits_homeNID),
    .io_in_15_bits_dbID(io_in_15_bits_dbID),
    .io_in_15_bits_chiOpcode(io_in_15_bits_chiOpcode),
    .io_in_15_bits_resp(io_in_15_bits_resp),
    .io_in_15_bits_fwdState(io_in_15_bits_fwdState),
    .io_in_15_bits_retToSrc(io_in_15_bits_retToSrc),
    .io_in_15_bits_likelyshared(io_in_15_bits_likelyshared),
    .io_in_15_bits_expCompAck(io_in_15_bits_expCompAck),
    .io_in_15_bits_allowRetry(io_in_15_bits_allowRetry),
    .io_in_15_bits_memAttr_allocate(io_in_15_bits_memAttr_allocate),
    .io_in_15_bits_memAttr_cacheable(io_in_15_bits_memAttr_cacheable),
    .io_in_15_bits_memAttr_ewa(io_in_15_bits_memAttr_ewa),
    .io_in_15_bits_traceTag(io_in_15_bits_traceTag),
    .io_in_15_bits_dataCheckErr(io_in_15_bits_dataCheckErr),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_channel(i_io_out_bits_channel),
    .io_out_bits_txChannel(i_io_out_bits_txChannel),
    .io_out_bits_set(i_io_out_bits_set),
    .io_out_bits_tag(i_io_out_bits_tag),
    .io_out_bits_off(i_io_out_bits_off),
    .io_out_bits_alias(i_io_out_bits_alias),
    .io_out_bits_isKeyword(i_io_out_bits_isKeyword),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_param(i_io_out_bits_param),
    .io_out_bits_size(i_io_out_bits_size),
    .io_out_bits_sourceId(i_io_out_bits_sourceId),
    .io_out_bits_denied(i_io_out_bits_denied),
    .io_out_bits_corrupt(i_io_out_bits_corrupt),
    .io_out_bits_mshrTask(i_io_out_bits_mshrTask),
    .io_out_bits_mshrId(i_io_out_bits_mshrId),
    .io_out_bits_aliasTask(i_io_out_bits_aliasTask),
    .io_out_bits_useProbeData(i_io_out_bits_useProbeData),
    .io_out_bits_mshrRetry(i_io_out_bits_mshrRetry),
    .io_out_bits_readProbeDataDown(i_io_out_bits_readProbeDataDown),
    .io_out_bits_fromL2pft(i_io_out_bits_fromL2pft),
    .io_out_bits_dirty(i_io_out_bits_dirty),
    .io_out_bits_way(i_io_out_bits_way),
    .io_out_bits_meta_dirty(i_io_out_bits_meta_dirty),
    .io_out_bits_meta_state(i_io_out_bits_meta_state),
    .io_out_bits_meta_clients(i_io_out_bits_meta_clients),
    .io_out_bits_meta_alias(i_io_out_bits_meta_alias),
    .io_out_bits_meta_prefetch(i_io_out_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc(i_io_out_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed(i_io_out_bits_meta_accessed),
    .io_out_bits_meta_tagErr(i_io_out_bits_meta_tagErr),
    .io_out_bits_meta_dataErr(i_io_out_bits_meta_dataErr),
    .io_out_bits_metaWen(i_io_out_bits_metaWen),
    .io_out_bits_tagWen(i_io_out_bits_tagWen),
    .io_out_bits_dsWen(i_io_out_bits_dsWen),
    .io_out_bits_replTask(i_io_out_bits_replTask),
    .io_out_bits_cmoTask(i_io_out_bits_cmoTask),
    .io_out_bits_reqSource(i_io_out_bits_reqSource),
    .io_out_bits_mergeA(i_io_out_bits_mergeA),
    .io_out_bits_aMergeTask_off(i_io_out_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias(i_io_out_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr(i_io_out_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword(i_io_out_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode(i_io_out_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param(i_io_out_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId(i_io_out_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty(i_io_out_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state(i_io_out_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients(i_io_out_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias(i_io_out_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_accessed(i_io_out_bits_aMergeTask_meta_accessed),
    .io_out_bits_snpHitRelease(i_io_out_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval(i_io_out_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean(i_io_out_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData(i_io_out_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx(i_io_out_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty(i_io_out_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state(i_io_out_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients(i_io_out_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias(i_io_out_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch(i_io_out_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc(i_io_out_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed(i_io_out_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr(i_io_out_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr(i_io_out_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_homeNID(i_io_out_bits_homeNID),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_chiOpcode(i_io_out_bits_chiOpcode),
    .io_out_bits_resp(i_io_out_bits_resp),
    .io_out_bits_fwdState(i_io_out_bits_fwdState),
    .io_out_bits_retToSrc(i_io_out_bits_retToSrc),
    .io_out_bits_likelyshared(i_io_out_bits_likelyshared),
    .io_out_bits_expCompAck(i_io_out_bits_expCompAck),
    .io_out_bits_allowRetry(i_io_out_bits_allowRetry),
    .io_out_bits_memAttr_allocate(i_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(i_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_ewa(i_io_out_bits_memAttr_ewa),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_out_bits_dataCheckErr(i_io_out_bits_dataCheckErr)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_channel <= 3'({$urandom});
    io_in_0_bits_txChannel <= 3'({$urandom});
    io_in_0_bits_set <= 9'({$urandom});
    io_in_0_bits_tag <= 31'({$urandom});
    io_in_0_bits_off <= 6'({$urandom});
    io_in_0_bits_alias <= 2'({$urandom});
    io_in_0_bits_isKeyword <= $urandom_range(0, 1);
    io_in_0_bits_opcode <= 4'({$urandom});
    io_in_0_bits_param <= 3'({$urandom});
    io_in_0_bits_size <= 3'({$urandom});
    io_in_0_bits_sourceId <= 7'({$urandom});
    io_in_0_bits_denied <= $urandom_range(0, 1);
    io_in_0_bits_corrupt <= $urandom_range(0, 1);
    io_in_0_bits_mshrId <= 8'({$urandom});
    io_in_0_bits_aliasTask <= $urandom_range(0, 1);
    io_in_0_bits_useProbeData <= $urandom_range(0, 1);
    io_in_0_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_0_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_0_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_0_bits_dirty <= $urandom_range(0, 1);
    io_in_0_bits_way <= 3'({$urandom});
    io_in_0_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_0_bits_meta_state <= 2'({$urandom});
    io_in_0_bits_meta_clients <= $urandom_range(0, 1);
    io_in_0_bits_meta_alias <= 2'({$urandom});
    io_in_0_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_0_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_0_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_0_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_0_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_0_bits_metaWen <= $urandom_range(0, 1);
    io_in_0_bits_tagWen <= $urandom_range(0, 1);
    io_in_0_bits_dsWen <= $urandom_range(0, 1);
    io_in_0_bits_replTask <= $urandom_range(0, 1);
    io_in_0_bits_cmoTask <= $urandom_range(0, 1);
    io_in_0_bits_reqSource <= 5'({$urandom});
    io_in_0_bits_mergeA <= $urandom_range(0, 1);
    io_in_0_bits_aMergeTask_off <= 6'({$urandom});
    io_in_0_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_0_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_0_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_0_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_0_bits_aMergeTask_param <= 3'({$urandom});
    io_in_0_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_0_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_0_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_0_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_0_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_0_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_0_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_0_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_0_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_0_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_0_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_0_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_0_bits_tgtID <= 11'({$urandom});
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_homeNID <= 11'({$urandom});
    io_in_0_bits_dbID <= 12'({$urandom});
    io_in_0_bits_chiOpcode <= 7'({$urandom});
    io_in_0_bits_resp <= 3'({$urandom});
    io_in_0_bits_fwdState <= 3'({$urandom});
    io_in_0_bits_retToSrc <= $urandom_range(0, 1);
    io_in_0_bits_likelyshared <= $urandom_range(0, 1);
    io_in_0_bits_expCompAck <= $urandom_range(0, 1);
    io_in_0_bits_allowRetry <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_0_bits_traceTag <= $urandom_range(0, 1);
    io_in_0_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_channel <= 3'({$urandom});
    io_in_1_bits_txChannel <= 3'({$urandom});
    io_in_1_bits_set <= 9'({$urandom});
    io_in_1_bits_tag <= 31'({$urandom});
    io_in_1_bits_off <= 6'({$urandom});
    io_in_1_bits_alias <= 2'({$urandom});
    io_in_1_bits_isKeyword <= $urandom_range(0, 1);
    io_in_1_bits_opcode <= 4'({$urandom});
    io_in_1_bits_param <= 3'({$urandom});
    io_in_1_bits_size <= 3'({$urandom});
    io_in_1_bits_sourceId <= 7'({$urandom});
    io_in_1_bits_denied <= $urandom_range(0, 1);
    io_in_1_bits_corrupt <= $urandom_range(0, 1);
    io_in_1_bits_mshrId <= 8'({$urandom});
    io_in_1_bits_aliasTask <= $urandom_range(0, 1);
    io_in_1_bits_useProbeData <= $urandom_range(0, 1);
    io_in_1_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_1_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_1_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_1_bits_dirty <= $urandom_range(0, 1);
    io_in_1_bits_way <= 3'({$urandom});
    io_in_1_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_1_bits_meta_state <= 2'({$urandom});
    io_in_1_bits_meta_clients <= $urandom_range(0, 1);
    io_in_1_bits_meta_alias <= 2'({$urandom});
    io_in_1_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_1_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_1_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_1_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_1_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_1_bits_metaWen <= $urandom_range(0, 1);
    io_in_1_bits_tagWen <= $urandom_range(0, 1);
    io_in_1_bits_dsWen <= $urandom_range(0, 1);
    io_in_1_bits_replTask <= $urandom_range(0, 1);
    io_in_1_bits_cmoTask <= $urandom_range(0, 1);
    io_in_1_bits_reqSource <= 5'({$urandom});
    io_in_1_bits_mergeA <= $urandom_range(0, 1);
    io_in_1_bits_aMergeTask_off <= 6'({$urandom});
    io_in_1_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_1_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_1_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_1_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_1_bits_aMergeTask_param <= 3'({$urandom});
    io_in_1_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_1_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_1_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_1_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_1_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_1_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_1_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_1_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_1_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_1_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_1_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_1_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_1_bits_tgtID <= 11'({$urandom});
    io_in_1_bits_txnID <= 12'({$urandom});
    io_in_1_bits_homeNID <= 11'({$urandom});
    io_in_1_bits_dbID <= 12'({$urandom});
    io_in_1_bits_chiOpcode <= 7'({$urandom});
    io_in_1_bits_resp <= 3'({$urandom});
    io_in_1_bits_fwdState <= 3'({$urandom});
    io_in_1_bits_retToSrc <= $urandom_range(0, 1);
    io_in_1_bits_likelyshared <= $urandom_range(0, 1);
    io_in_1_bits_expCompAck <= $urandom_range(0, 1);
    io_in_1_bits_allowRetry <= $urandom_range(0, 1);
    io_in_1_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_1_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_1_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_1_bits_traceTag <= $urandom_range(0, 1);
    io_in_1_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_channel <= 3'({$urandom});
    io_in_2_bits_txChannel <= 3'({$urandom});
    io_in_2_bits_set <= 9'({$urandom});
    io_in_2_bits_tag <= 31'({$urandom});
    io_in_2_bits_off <= 6'({$urandom});
    io_in_2_bits_alias <= 2'({$urandom});
    io_in_2_bits_isKeyword <= $urandom_range(0, 1);
    io_in_2_bits_opcode <= 4'({$urandom});
    io_in_2_bits_param <= 3'({$urandom});
    io_in_2_bits_size <= 3'({$urandom});
    io_in_2_bits_sourceId <= 7'({$urandom});
    io_in_2_bits_denied <= $urandom_range(0, 1);
    io_in_2_bits_corrupt <= $urandom_range(0, 1);
    io_in_2_bits_mshrId <= 8'({$urandom});
    io_in_2_bits_aliasTask <= $urandom_range(0, 1);
    io_in_2_bits_useProbeData <= $urandom_range(0, 1);
    io_in_2_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_2_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_2_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_2_bits_dirty <= $urandom_range(0, 1);
    io_in_2_bits_way <= 3'({$urandom});
    io_in_2_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_2_bits_meta_state <= 2'({$urandom});
    io_in_2_bits_meta_clients <= $urandom_range(0, 1);
    io_in_2_bits_meta_alias <= 2'({$urandom});
    io_in_2_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_2_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_2_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_2_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_2_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_2_bits_metaWen <= $urandom_range(0, 1);
    io_in_2_bits_tagWen <= $urandom_range(0, 1);
    io_in_2_bits_dsWen <= $urandom_range(0, 1);
    io_in_2_bits_replTask <= $urandom_range(0, 1);
    io_in_2_bits_cmoTask <= $urandom_range(0, 1);
    io_in_2_bits_reqSource <= 5'({$urandom});
    io_in_2_bits_mergeA <= $urandom_range(0, 1);
    io_in_2_bits_aMergeTask_off <= 6'({$urandom});
    io_in_2_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_2_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_2_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_2_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_2_bits_aMergeTask_param <= 3'({$urandom});
    io_in_2_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_2_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_2_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_2_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_2_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_2_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_2_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_2_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_2_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_2_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_2_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_2_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_2_bits_tgtID <= 11'({$urandom});
    io_in_2_bits_txnID <= 12'({$urandom});
    io_in_2_bits_homeNID <= 11'({$urandom});
    io_in_2_bits_dbID <= 12'({$urandom});
    io_in_2_bits_chiOpcode <= 7'({$urandom});
    io_in_2_bits_resp <= 3'({$urandom});
    io_in_2_bits_fwdState <= 3'({$urandom});
    io_in_2_bits_retToSrc <= $urandom_range(0, 1);
    io_in_2_bits_likelyshared <= $urandom_range(0, 1);
    io_in_2_bits_expCompAck <= $urandom_range(0, 1);
    io_in_2_bits_allowRetry <= $urandom_range(0, 1);
    io_in_2_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_2_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_2_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_2_bits_traceTag <= $urandom_range(0, 1);
    io_in_2_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_channel <= 3'({$urandom});
    io_in_3_bits_txChannel <= 3'({$urandom});
    io_in_3_bits_set <= 9'({$urandom});
    io_in_3_bits_tag <= 31'({$urandom});
    io_in_3_bits_off <= 6'({$urandom});
    io_in_3_bits_alias <= 2'({$urandom});
    io_in_3_bits_isKeyword <= $urandom_range(0, 1);
    io_in_3_bits_opcode <= 4'({$urandom});
    io_in_3_bits_param <= 3'({$urandom});
    io_in_3_bits_size <= 3'({$urandom});
    io_in_3_bits_sourceId <= 7'({$urandom});
    io_in_3_bits_denied <= $urandom_range(0, 1);
    io_in_3_bits_corrupt <= $urandom_range(0, 1);
    io_in_3_bits_mshrId <= 8'({$urandom});
    io_in_3_bits_aliasTask <= $urandom_range(0, 1);
    io_in_3_bits_useProbeData <= $urandom_range(0, 1);
    io_in_3_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_3_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_3_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_3_bits_dirty <= $urandom_range(0, 1);
    io_in_3_bits_way <= 3'({$urandom});
    io_in_3_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_3_bits_meta_state <= 2'({$urandom});
    io_in_3_bits_meta_clients <= $urandom_range(0, 1);
    io_in_3_bits_meta_alias <= 2'({$urandom});
    io_in_3_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_3_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_3_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_3_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_3_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_3_bits_metaWen <= $urandom_range(0, 1);
    io_in_3_bits_tagWen <= $urandom_range(0, 1);
    io_in_3_bits_dsWen <= $urandom_range(0, 1);
    io_in_3_bits_replTask <= $urandom_range(0, 1);
    io_in_3_bits_cmoTask <= $urandom_range(0, 1);
    io_in_3_bits_reqSource <= 5'({$urandom});
    io_in_3_bits_mergeA <= $urandom_range(0, 1);
    io_in_3_bits_aMergeTask_off <= 6'({$urandom});
    io_in_3_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_3_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_3_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_3_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_3_bits_aMergeTask_param <= 3'({$urandom});
    io_in_3_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_3_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_3_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_3_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_3_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_3_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_3_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_3_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_3_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_3_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_3_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_3_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_3_bits_tgtID <= 11'({$urandom});
    io_in_3_bits_txnID <= 12'({$urandom});
    io_in_3_bits_homeNID <= 11'({$urandom});
    io_in_3_bits_dbID <= 12'({$urandom});
    io_in_3_bits_chiOpcode <= 7'({$urandom});
    io_in_3_bits_resp <= 3'({$urandom});
    io_in_3_bits_fwdState <= 3'({$urandom});
    io_in_3_bits_retToSrc <= $urandom_range(0, 1);
    io_in_3_bits_likelyshared <= $urandom_range(0, 1);
    io_in_3_bits_expCompAck <= $urandom_range(0, 1);
    io_in_3_bits_allowRetry <= $urandom_range(0, 1);
    io_in_3_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_3_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_3_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_3_bits_traceTag <= $urandom_range(0, 1);
    io_in_3_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_4_valid <= $urandom_range(0, 1);
    io_in_4_bits_channel <= 3'({$urandom});
    io_in_4_bits_txChannel <= 3'({$urandom});
    io_in_4_bits_set <= 9'({$urandom});
    io_in_4_bits_tag <= 31'({$urandom});
    io_in_4_bits_off <= 6'({$urandom});
    io_in_4_bits_alias <= 2'({$urandom});
    io_in_4_bits_isKeyword <= $urandom_range(0, 1);
    io_in_4_bits_opcode <= 4'({$urandom});
    io_in_4_bits_param <= 3'({$urandom});
    io_in_4_bits_size <= 3'({$urandom});
    io_in_4_bits_sourceId <= 7'({$urandom});
    io_in_4_bits_denied <= $urandom_range(0, 1);
    io_in_4_bits_corrupt <= $urandom_range(0, 1);
    io_in_4_bits_mshrId <= 8'({$urandom});
    io_in_4_bits_aliasTask <= $urandom_range(0, 1);
    io_in_4_bits_useProbeData <= $urandom_range(0, 1);
    io_in_4_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_4_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_4_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_4_bits_dirty <= $urandom_range(0, 1);
    io_in_4_bits_way <= 3'({$urandom});
    io_in_4_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_4_bits_meta_state <= 2'({$urandom});
    io_in_4_bits_meta_clients <= $urandom_range(0, 1);
    io_in_4_bits_meta_alias <= 2'({$urandom});
    io_in_4_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_4_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_4_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_4_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_4_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_4_bits_metaWen <= $urandom_range(0, 1);
    io_in_4_bits_tagWen <= $urandom_range(0, 1);
    io_in_4_bits_dsWen <= $urandom_range(0, 1);
    io_in_4_bits_replTask <= $urandom_range(0, 1);
    io_in_4_bits_cmoTask <= $urandom_range(0, 1);
    io_in_4_bits_reqSource <= 5'({$urandom});
    io_in_4_bits_mergeA <= $urandom_range(0, 1);
    io_in_4_bits_aMergeTask_off <= 6'({$urandom});
    io_in_4_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_4_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_4_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_4_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_4_bits_aMergeTask_param <= 3'({$urandom});
    io_in_4_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_4_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_4_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_4_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_4_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_4_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_4_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_4_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_4_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_4_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_4_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_4_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_4_bits_tgtID <= 11'({$urandom});
    io_in_4_bits_txnID <= 12'({$urandom});
    io_in_4_bits_homeNID <= 11'({$urandom});
    io_in_4_bits_dbID <= 12'({$urandom});
    io_in_4_bits_chiOpcode <= 7'({$urandom});
    io_in_4_bits_resp <= 3'({$urandom});
    io_in_4_bits_fwdState <= 3'({$urandom});
    io_in_4_bits_retToSrc <= $urandom_range(0, 1);
    io_in_4_bits_likelyshared <= $urandom_range(0, 1);
    io_in_4_bits_expCompAck <= $urandom_range(0, 1);
    io_in_4_bits_allowRetry <= $urandom_range(0, 1);
    io_in_4_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_4_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_4_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_4_bits_traceTag <= $urandom_range(0, 1);
    io_in_4_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_5_valid <= $urandom_range(0, 1);
    io_in_5_bits_channel <= 3'({$urandom});
    io_in_5_bits_txChannel <= 3'({$urandom});
    io_in_5_bits_set <= 9'({$urandom});
    io_in_5_bits_tag <= 31'({$urandom});
    io_in_5_bits_off <= 6'({$urandom});
    io_in_5_bits_alias <= 2'({$urandom});
    io_in_5_bits_isKeyword <= $urandom_range(0, 1);
    io_in_5_bits_opcode <= 4'({$urandom});
    io_in_5_bits_param <= 3'({$urandom});
    io_in_5_bits_size <= 3'({$urandom});
    io_in_5_bits_sourceId <= 7'({$urandom});
    io_in_5_bits_denied <= $urandom_range(0, 1);
    io_in_5_bits_corrupt <= $urandom_range(0, 1);
    io_in_5_bits_mshrId <= 8'({$urandom});
    io_in_5_bits_aliasTask <= $urandom_range(0, 1);
    io_in_5_bits_useProbeData <= $urandom_range(0, 1);
    io_in_5_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_5_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_5_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_5_bits_dirty <= $urandom_range(0, 1);
    io_in_5_bits_way <= 3'({$urandom});
    io_in_5_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_5_bits_meta_state <= 2'({$urandom});
    io_in_5_bits_meta_clients <= $urandom_range(0, 1);
    io_in_5_bits_meta_alias <= 2'({$urandom});
    io_in_5_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_5_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_5_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_5_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_5_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_5_bits_metaWen <= $urandom_range(0, 1);
    io_in_5_bits_tagWen <= $urandom_range(0, 1);
    io_in_5_bits_dsWen <= $urandom_range(0, 1);
    io_in_5_bits_replTask <= $urandom_range(0, 1);
    io_in_5_bits_cmoTask <= $urandom_range(0, 1);
    io_in_5_bits_reqSource <= 5'({$urandom});
    io_in_5_bits_mergeA <= $urandom_range(0, 1);
    io_in_5_bits_aMergeTask_off <= 6'({$urandom});
    io_in_5_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_5_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_5_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_5_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_5_bits_aMergeTask_param <= 3'({$urandom});
    io_in_5_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_5_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_5_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_5_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_5_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_5_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_5_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_5_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_5_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_5_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_5_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_5_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_5_bits_tgtID <= 11'({$urandom});
    io_in_5_bits_txnID <= 12'({$urandom});
    io_in_5_bits_homeNID <= 11'({$urandom});
    io_in_5_bits_dbID <= 12'({$urandom});
    io_in_5_bits_chiOpcode <= 7'({$urandom});
    io_in_5_bits_resp <= 3'({$urandom});
    io_in_5_bits_fwdState <= 3'({$urandom});
    io_in_5_bits_retToSrc <= $urandom_range(0, 1);
    io_in_5_bits_likelyshared <= $urandom_range(0, 1);
    io_in_5_bits_expCompAck <= $urandom_range(0, 1);
    io_in_5_bits_allowRetry <= $urandom_range(0, 1);
    io_in_5_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_5_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_5_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_5_bits_traceTag <= $urandom_range(0, 1);
    io_in_5_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_6_valid <= $urandom_range(0, 1);
    io_in_6_bits_channel <= 3'({$urandom});
    io_in_6_bits_txChannel <= 3'({$urandom});
    io_in_6_bits_set <= 9'({$urandom});
    io_in_6_bits_tag <= 31'({$urandom});
    io_in_6_bits_off <= 6'({$urandom});
    io_in_6_bits_alias <= 2'({$urandom});
    io_in_6_bits_isKeyword <= $urandom_range(0, 1);
    io_in_6_bits_opcode <= 4'({$urandom});
    io_in_6_bits_param <= 3'({$urandom});
    io_in_6_bits_size <= 3'({$urandom});
    io_in_6_bits_sourceId <= 7'({$urandom});
    io_in_6_bits_denied <= $urandom_range(0, 1);
    io_in_6_bits_corrupt <= $urandom_range(0, 1);
    io_in_6_bits_mshrId <= 8'({$urandom});
    io_in_6_bits_aliasTask <= $urandom_range(0, 1);
    io_in_6_bits_useProbeData <= $urandom_range(0, 1);
    io_in_6_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_6_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_6_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_6_bits_dirty <= $urandom_range(0, 1);
    io_in_6_bits_way <= 3'({$urandom});
    io_in_6_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_6_bits_meta_state <= 2'({$urandom});
    io_in_6_bits_meta_clients <= $urandom_range(0, 1);
    io_in_6_bits_meta_alias <= 2'({$urandom});
    io_in_6_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_6_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_6_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_6_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_6_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_6_bits_metaWen <= $urandom_range(0, 1);
    io_in_6_bits_tagWen <= $urandom_range(0, 1);
    io_in_6_bits_dsWen <= $urandom_range(0, 1);
    io_in_6_bits_replTask <= $urandom_range(0, 1);
    io_in_6_bits_cmoTask <= $urandom_range(0, 1);
    io_in_6_bits_reqSource <= 5'({$urandom});
    io_in_6_bits_mergeA <= $urandom_range(0, 1);
    io_in_6_bits_aMergeTask_off <= 6'({$urandom});
    io_in_6_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_6_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_6_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_6_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_6_bits_aMergeTask_param <= 3'({$urandom});
    io_in_6_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_6_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_6_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_6_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_6_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_6_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_6_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_6_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_6_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_6_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_6_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_6_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_6_bits_tgtID <= 11'({$urandom});
    io_in_6_bits_txnID <= 12'({$urandom});
    io_in_6_bits_homeNID <= 11'({$urandom});
    io_in_6_bits_dbID <= 12'({$urandom});
    io_in_6_bits_chiOpcode <= 7'({$urandom});
    io_in_6_bits_resp <= 3'({$urandom});
    io_in_6_bits_fwdState <= 3'({$urandom});
    io_in_6_bits_retToSrc <= $urandom_range(0, 1);
    io_in_6_bits_likelyshared <= $urandom_range(0, 1);
    io_in_6_bits_expCompAck <= $urandom_range(0, 1);
    io_in_6_bits_allowRetry <= $urandom_range(0, 1);
    io_in_6_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_6_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_6_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_6_bits_traceTag <= $urandom_range(0, 1);
    io_in_6_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_7_valid <= $urandom_range(0, 1);
    io_in_7_bits_channel <= 3'({$urandom});
    io_in_7_bits_txChannel <= 3'({$urandom});
    io_in_7_bits_set <= 9'({$urandom});
    io_in_7_bits_tag <= 31'({$urandom});
    io_in_7_bits_off <= 6'({$urandom});
    io_in_7_bits_alias <= 2'({$urandom});
    io_in_7_bits_isKeyword <= $urandom_range(0, 1);
    io_in_7_bits_opcode <= 4'({$urandom});
    io_in_7_bits_param <= 3'({$urandom});
    io_in_7_bits_size <= 3'({$urandom});
    io_in_7_bits_sourceId <= 7'({$urandom});
    io_in_7_bits_denied <= $urandom_range(0, 1);
    io_in_7_bits_corrupt <= $urandom_range(0, 1);
    io_in_7_bits_mshrId <= 8'({$urandom});
    io_in_7_bits_aliasTask <= $urandom_range(0, 1);
    io_in_7_bits_useProbeData <= $urandom_range(0, 1);
    io_in_7_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_7_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_7_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_7_bits_dirty <= $urandom_range(0, 1);
    io_in_7_bits_way <= 3'({$urandom});
    io_in_7_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_7_bits_meta_state <= 2'({$urandom});
    io_in_7_bits_meta_clients <= $urandom_range(0, 1);
    io_in_7_bits_meta_alias <= 2'({$urandom});
    io_in_7_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_7_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_7_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_7_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_7_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_7_bits_metaWen <= $urandom_range(0, 1);
    io_in_7_bits_tagWen <= $urandom_range(0, 1);
    io_in_7_bits_dsWen <= $urandom_range(0, 1);
    io_in_7_bits_replTask <= $urandom_range(0, 1);
    io_in_7_bits_cmoTask <= $urandom_range(0, 1);
    io_in_7_bits_reqSource <= 5'({$urandom});
    io_in_7_bits_mergeA <= $urandom_range(0, 1);
    io_in_7_bits_aMergeTask_off <= 6'({$urandom});
    io_in_7_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_7_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_7_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_7_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_7_bits_aMergeTask_param <= 3'({$urandom});
    io_in_7_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_7_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_7_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_7_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_7_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_7_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_7_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_7_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_7_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_7_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_7_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_7_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_7_bits_tgtID <= 11'({$urandom});
    io_in_7_bits_txnID <= 12'({$urandom});
    io_in_7_bits_homeNID <= 11'({$urandom});
    io_in_7_bits_dbID <= 12'({$urandom});
    io_in_7_bits_chiOpcode <= 7'({$urandom});
    io_in_7_bits_resp <= 3'({$urandom});
    io_in_7_bits_fwdState <= 3'({$urandom});
    io_in_7_bits_retToSrc <= $urandom_range(0, 1);
    io_in_7_bits_likelyshared <= $urandom_range(0, 1);
    io_in_7_bits_expCompAck <= $urandom_range(0, 1);
    io_in_7_bits_allowRetry <= $urandom_range(0, 1);
    io_in_7_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_7_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_7_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_7_bits_traceTag <= $urandom_range(0, 1);
    io_in_7_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_8_valid <= $urandom_range(0, 1);
    io_in_8_bits_channel <= 3'({$urandom});
    io_in_8_bits_txChannel <= 3'({$urandom});
    io_in_8_bits_set <= 9'({$urandom});
    io_in_8_bits_tag <= 31'({$urandom});
    io_in_8_bits_off <= 6'({$urandom});
    io_in_8_bits_alias <= 2'({$urandom});
    io_in_8_bits_isKeyword <= $urandom_range(0, 1);
    io_in_8_bits_opcode <= 4'({$urandom});
    io_in_8_bits_param <= 3'({$urandom});
    io_in_8_bits_size <= 3'({$urandom});
    io_in_8_bits_sourceId <= 7'({$urandom});
    io_in_8_bits_denied <= $urandom_range(0, 1);
    io_in_8_bits_corrupt <= $urandom_range(0, 1);
    io_in_8_bits_mshrId <= 8'({$urandom});
    io_in_8_bits_aliasTask <= $urandom_range(0, 1);
    io_in_8_bits_useProbeData <= $urandom_range(0, 1);
    io_in_8_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_8_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_8_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_8_bits_dirty <= $urandom_range(0, 1);
    io_in_8_bits_way <= 3'({$urandom});
    io_in_8_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_8_bits_meta_state <= 2'({$urandom});
    io_in_8_bits_meta_clients <= $urandom_range(0, 1);
    io_in_8_bits_meta_alias <= 2'({$urandom});
    io_in_8_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_8_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_8_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_8_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_8_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_8_bits_metaWen <= $urandom_range(0, 1);
    io_in_8_bits_tagWen <= $urandom_range(0, 1);
    io_in_8_bits_dsWen <= $urandom_range(0, 1);
    io_in_8_bits_replTask <= $urandom_range(0, 1);
    io_in_8_bits_cmoTask <= $urandom_range(0, 1);
    io_in_8_bits_reqSource <= 5'({$urandom});
    io_in_8_bits_mergeA <= $urandom_range(0, 1);
    io_in_8_bits_aMergeTask_off <= 6'({$urandom});
    io_in_8_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_8_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_8_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_8_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_8_bits_aMergeTask_param <= 3'({$urandom});
    io_in_8_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_8_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_8_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_8_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_8_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_8_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_8_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_8_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_8_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_8_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_8_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_8_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_8_bits_tgtID <= 11'({$urandom});
    io_in_8_bits_txnID <= 12'({$urandom});
    io_in_8_bits_homeNID <= 11'({$urandom});
    io_in_8_bits_dbID <= 12'({$urandom});
    io_in_8_bits_chiOpcode <= 7'({$urandom});
    io_in_8_bits_resp <= 3'({$urandom});
    io_in_8_bits_fwdState <= 3'({$urandom});
    io_in_8_bits_retToSrc <= $urandom_range(0, 1);
    io_in_8_bits_likelyshared <= $urandom_range(0, 1);
    io_in_8_bits_expCompAck <= $urandom_range(0, 1);
    io_in_8_bits_allowRetry <= $urandom_range(0, 1);
    io_in_8_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_8_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_8_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_8_bits_traceTag <= $urandom_range(0, 1);
    io_in_8_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_9_valid <= $urandom_range(0, 1);
    io_in_9_bits_channel <= 3'({$urandom});
    io_in_9_bits_txChannel <= 3'({$urandom});
    io_in_9_bits_set <= 9'({$urandom});
    io_in_9_bits_tag <= 31'({$urandom});
    io_in_9_bits_off <= 6'({$urandom});
    io_in_9_bits_alias <= 2'({$urandom});
    io_in_9_bits_isKeyword <= $urandom_range(0, 1);
    io_in_9_bits_opcode <= 4'({$urandom});
    io_in_9_bits_param <= 3'({$urandom});
    io_in_9_bits_size <= 3'({$urandom});
    io_in_9_bits_sourceId <= 7'({$urandom});
    io_in_9_bits_denied <= $urandom_range(0, 1);
    io_in_9_bits_corrupt <= $urandom_range(0, 1);
    io_in_9_bits_mshrId <= 8'({$urandom});
    io_in_9_bits_aliasTask <= $urandom_range(0, 1);
    io_in_9_bits_useProbeData <= $urandom_range(0, 1);
    io_in_9_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_9_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_9_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_9_bits_dirty <= $urandom_range(0, 1);
    io_in_9_bits_way <= 3'({$urandom});
    io_in_9_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_9_bits_meta_state <= 2'({$urandom});
    io_in_9_bits_meta_clients <= $urandom_range(0, 1);
    io_in_9_bits_meta_alias <= 2'({$urandom});
    io_in_9_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_9_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_9_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_9_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_9_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_9_bits_metaWen <= $urandom_range(0, 1);
    io_in_9_bits_tagWen <= $urandom_range(0, 1);
    io_in_9_bits_dsWen <= $urandom_range(0, 1);
    io_in_9_bits_replTask <= $urandom_range(0, 1);
    io_in_9_bits_cmoTask <= $urandom_range(0, 1);
    io_in_9_bits_reqSource <= 5'({$urandom});
    io_in_9_bits_mergeA <= $urandom_range(0, 1);
    io_in_9_bits_aMergeTask_off <= 6'({$urandom});
    io_in_9_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_9_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_9_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_9_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_9_bits_aMergeTask_param <= 3'({$urandom});
    io_in_9_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_9_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_9_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_9_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_9_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_9_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_9_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_9_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_9_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_9_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_9_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_9_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_9_bits_tgtID <= 11'({$urandom});
    io_in_9_bits_txnID <= 12'({$urandom});
    io_in_9_bits_homeNID <= 11'({$urandom});
    io_in_9_bits_dbID <= 12'({$urandom});
    io_in_9_bits_chiOpcode <= 7'({$urandom});
    io_in_9_bits_resp <= 3'({$urandom});
    io_in_9_bits_fwdState <= 3'({$urandom});
    io_in_9_bits_retToSrc <= $urandom_range(0, 1);
    io_in_9_bits_likelyshared <= $urandom_range(0, 1);
    io_in_9_bits_expCompAck <= $urandom_range(0, 1);
    io_in_9_bits_allowRetry <= $urandom_range(0, 1);
    io_in_9_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_9_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_9_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_9_bits_traceTag <= $urandom_range(0, 1);
    io_in_9_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_10_valid <= $urandom_range(0, 1);
    io_in_10_bits_channel <= 3'({$urandom});
    io_in_10_bits_txChannel <= 3'({$urandom});
    io_in_10_bits_set <= 9'({$urandom});
    io_in_10_bits_tag <= 31'({$urandom});
    io_in_10_bits_off <= 6'({$urandom});
    io_in_10_bits_alias <= 2'({$urandom});
    io_in_10_bits_isKeyword <= $urandom_range(0, 1);
    io_in_10_bits_opcode <= 4'({$urandom});
    io_in_10_bits_param <= 3'({$urandom});
    io_in_10_bits_size <= 3'({$urandom});
    io_in_10_bits_sourceId <= 7'({$urandom});
    io_in_10_bits_denied <= $urandom_range(0, 1);
    io_in_10_bits_corrupt <= $urandom_range(0, 1);
    io_in_10_bits_mshrId <= 8'({$urandom});
    io_in_10_bits_aliasTask <= $urandom_range(0, 1);
    io_in_10_bits_useProbeData <= $urandom_range(0, 1);
    io_in_10_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_10_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_10_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_10_bits_dirty <= $urandom_range(0, 1);
    io_in_10_bits_way <= 3'({$urandom});
    io_in_10_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_10_bits_meta_state <= 2'({$urandom});
    io_in_10_bits_meta_clients <= $urandom_range(0, 1);
    io_in_10_bits_meta_alias <= 2'({$urandom});
    io_in_10_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_10_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_10_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_10_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_10_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_10_bits_metaWen <= $urandom_range(0, 1);
    io_in_10_bits_tagWen <= $urandom_range(0, 1);
    io_in_10_bits_dsWen <= $urandom_range(0, 1);
    io_in_10_bits_replTask <= $urandom_range(0, 1);
    io_in_10_bits_cmoTask <= $urandom_range(0, 1);
    io_in_10_bits_reqSource <= 5'({$urandom});
    io_in_10_bits_mergeA <= $urandom_range(0, 1);
    io_in_10_bits_aMergeTask_off <= 6'({$urandom});
    io_in_10_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_10_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_10_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_10_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_10_bits_aMergeTask_param <= 3'({$urandom});
    io_in_10_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_10_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_10_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_10_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_10_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_10_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_10_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_10_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_10_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_10_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_10_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_10_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_10_bits_tgtID <= 11'({$urandom});
    io_in_10_bits_txnID <= 12'({$urandom});
    io_in_10_bits_homeNID <= 11'({$urandom});
    io_in_10_bits_dbID <= 12'({$urandom});
    io_in_10_bits_chiOpcode <= 7'({$urandom});
    io_in_10_bits_resp <= 3'({$urandom});
    io_in_10_bits_fwdState <= 3'({$urandom});
    io_in_10_bits_retToSrc <= $urandom_range(0, 1);
    io_in_10_bits_likelyshared <= $urandom_range(0, 1);
    io_in_10_bits_expCompAck <= $urandom_range(0, 1);
    io_in_10_bits_allowRetry <= $urandom_range(0, 1);
    io_in_10_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_10_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_10_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_10_bits_traceTag <= $urandom_range(0, 1);
    io_in_10_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_11_valid <= $urandom_range(0, 1);
    io_in_11_bits_channel <= 3'({$urandom});
    io_in_11_bits_txChannel <= 3'({$urandom});
    io_in_11_bits_set <= 9'({$urandom});
    io_in_11_bits_tag <= 31'({$urandom});
    io_in_11_bits_off <= 6'({$urandom});
    io_in_11_bits_alias <= 2'({$urandom});
    io_in_11_bits_isKeyword <= $urandom_range(0, 1);
    io_in_11_bits_opcode <= 4'({$urandom});
    io_in_11_bits_param <= 3'({$urandom});
    io_in_11_bits_size <= 3'({$urandom});
    io_in_11_bits_sourceId <= 7'({$urandom});
    io_in_11_bits_denied <= $urandom_range(0, 1);
    io_in_11_bits_corrupt <= $urandom_range(0, 1);
    io_in_11_bits_mshrId <= 8'({$urandom});
    io_in_11_bits_aliasTask <= $urandom_range(0, 1);
    io_in_11_bits_useProbeData <= $urandom_range(0, 1);
    io_in_11_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_11_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_11_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_11_bits_dirty <= $urandom_range(0, 1);
    io_in_11_bits_way <= 3'({$urandom});
    io_in_11_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_11_bits_meta_state <= 2'({$urandom});
    io_in_11_bits_meta_clients <= $urandom_range(0, 1);
    io_in_11_bits_meta_alias <= 2'({$urandom});
    io_in_11_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_11_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_11_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_11_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_11_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_11_bits_metaWen <= $urandom_range(0, 1);
    io_in_11_bits_tagWen <= $urandom_range(0, 1);
    io_in_11_bits_dsWen <= $urandom_range(0, 1);
    io_in_11_bits_replTask <= $urandom_range(0, 1);
    io_in_11_bits_cmoTask <= $urandom_range(0, 1);
    io_in_11_bits_reqSource <= 5'({$urandom});
    io_in_11_bits_mergeA <= $urandom_range(0, 1);
    io_in_11_bits_aMergeTask_off <= 6'({$urandom});
    io_in_11_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_11_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_11_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_11_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_11_bits_aMergeTask_param <= 3'({$urandom});
    io_in_11_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_11_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_11_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_11_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_11_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_11_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_11_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_11_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_11_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_11_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_11_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_11_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_11_bits_tgtID <= 11'({$urandom});
    io_in_11_bits_txnID <= 12'({$urandom});
    io_in_11_bits_homeNID <= 11'({$urandom});
    io_in_11_bits_dbID <= 12'({$urandom});
    io_in_11_bits_chiOpcode <= 7'({$urandom});
    io_in_11_bits_resp <= 3'({$urandom});
    io_in_11_bits_fwdState <= 3'({$urandom});
    io_in_11_bits_retToSrc <= $urandom_range(0, 1);
    io_in_11_bits_likelyshared <= $urandom_range(0, 1);
    io_in_11_bits_expCompAck <= $urandom_range(0, 1);
    io_in_11_bits_allowRetry <= $urandom_range(0, 1);
    io_in_11_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_11_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_11_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_11_bits_traceTag <= $urandom_range(0, 1);
    io_in_11_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_12_valid <= $urandom_range(0, 1);
    io_in_12_bits_channel <= 3'({$urandom});
    io_in_12_bits_txChannel <= 3'({$urandom});
    io_in_12_bits_set <= 9'({$urandom});
    io_in_12_bits_tag <= 31'({$urandom});
    io_in_12_bits_off <= 6'({$urandom});
    io_in_12_bits_alias <= 2'({$urandom});
    io_in_12_bits_isKeyword <= $urandom_range(0, 1);
    io_in_12_bits_opcode <= 4'({$urandom});
    io_in_12_bits_param <= 3'({$urandom});
    io_in_12_bits_size <= 3'({$urandom});
    io_in_12_bits_sourceId <= 7'({$urandom});
    io_in_12_bits_denied <= $urandom_range(0, 1);
    io_in_12_bits_corrupt <= $urandom_range(0, 1);
    io_in_12_bits_mshrId <= 8'({$urandom});
    io_in_12_bits_aliasTask <= $urandom_range(0, 1);
    io_in_12_bits_useProbeData <= $urandom_range(0, 1);
    io_in_12_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_12_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_12_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_12_bits_dirty <= $urandom_range(0, 1);
    io_in_12_bits_way <= 3'({$urandom});
    io_in_12_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_12_bits_meta_state <= 2'({$urandom});
    io_in_12_bits_meta_clients <= $urandom_range(0, 1);
    io_in_12_bits_meta_alias <= 2'({$urandom});
    io_in_12_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_12_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_12_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_12_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_12_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_12_bits_metaWen <= $urandom_range(0, 1);
    io_in_12_bits_tagWen <= $urandom_range(0, 1);
    io_in_12_bits_dsWen <= $urandom_range(0, 1);
    io_in_12_bits_replTask <= $urandom_range(0, 1);
    io_in_12_bits_cmoTask <= $urandom_range(0, 1);
    io_in_12_bits_reqSource <= 5'({$urandom});
    io_in_12_bits_mergeA <= $urandom_range(0, 1);
    io_in_12_bits_aMergeTask_off <= 6'({$urandom});
    io_in_12_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_12_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_12_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_12_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_12_bits_aMergeTask_param <= 3'({$urandom});
    io_in_12_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_12_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_12_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_12_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_12_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_12_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_12_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_12_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_12_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_12_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_12_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_12_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_12_bits_tgtID <= 11'({$urandom});
    io_in_12_bits_txnID <= 12'({$urandom});
    io_in_12_bits_homeNID <= 11'({$urandom});
    io_in_12_bits_dbID <= 12'({$urandom});
    io_in_12_bits_chiOpcode <= 7'({$urandom});
    io_in_12_bits_resp <= 3'({$urandom});
    io_in_12_bits_fwdState <= 3'({$urandom});
    io_in_12_bits_retToSrc <= $urandom_range(0, 1);
    io_in_12_bits_likelyshared <= $urandom_range(0, 1);
    io_in_12_bits_expCompAck <= $urandom_range(0, 1);
    io_in_12_bits_allowRetry <= $urandom_range(0, 1);
    io_in_12_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_12_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_12_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_12_bits_traceTag <= $urandom_range(0, 1);
    io_in_12_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_13_valid <= $urandom_range(0, 1);
    io_in_13_bits_channel <= 3'({$urandom});
    io_in_13_bits_txChannel <= 3'({$urandom});
    io_in_13_bits_set <= 9'({$urandom});
    io_in_13_bits_tag <= 31'({$urandom});
    io_in_13_bits_off <= 6'({$urandom});
    io_in_13_bits_alias <= 2'({$urandom});
    io_in_13_bits_isKeyword <= $urandom_range(0, 1);
    io_in_13_bits_opcode <= 4'({$urandom});
    io_in_13_bits_param <= 3'({$urandom});
    io_in_13_bits_size <= 3'({$urandom});
    io_in_13_bits_sourceId <= 7'({$urandom});
    io_in_13_bits_denied <= $urandom_range(0, 1);
    io_in_13_bits_corrupt <= $urandom_range(0, 1);
    io_in_13_bits_mshrId <= 8'({$urandom});
    io_in_13_bits_aliasTask <= $urandom_range(0, 1);
    io_in_13_bits_useProbeData <= $urandom_range(0, 1);
    io_in_13_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_13_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_13_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_13_bits_dirty <= $urandom_range(0, 1);
    io_in_13_bits_way <= 3'({$urandom});
    io_in_13_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_13_bits_meta_state <= 2'({$urandom});
    io_in_13_bits_meta_clients <= $urandom_range(0, 1);
    io_in_13_bits_meta_alias <= 2'({$urandom});
    io_in_13_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_13_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_13_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_13_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_13_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_13_bits_metaWen <= $urandom_range(0, 1);
    io_in_13_bits_tagWen <= $urandom_range(0, 1);
    io_in_13_bits_dsWen <= $urandom_range(0, 1);
    io_in_13_bits_replTask <= $urandom_range(0, 1);
    io_in_13_bits_cmoTask <= $urandom_range(0, 1);
    io_in_13_bits_reqSource <= 5'({$urandom});
    io_in_13_bits_mergeA <= $urandom_range(0, 1);
    io_in_13_bits_aMergeTask_off <= 6'({$urandom});
    io_in_13_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_13_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_13_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_13_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_13_bits_aMergeTask_param <= 3'({$urandom});
    io_in_13_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_13_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_13_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_13_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_13_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_13_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_13_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_13_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_13_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_13_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_13_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_13_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_13_bits_tgtID <= 11'({$urandom});
    io_in_13_bits_txnID <= 12'({$urandom});
    io_in_13_bits_homeNID <= 11'({$urandom});
    io_in_13_bits_dbID <= 12'({$urandom});
    io_in_13_bits_chiOpcode <= 7'({$urandom});
    io_in_13_bits_resp <= 3'({$urandom});
    io_in_13_bits_fwdState <= 3'({$urandom});
    io_in_13_bits_retToSrc <= $urandom_range(0, 1);
    io_in_13_bits_likelyshared <= $urandom_range(0, 1);
    io_in_13_bits_expCompAck <= $urandom_range(0, 1);
    io_in_13_bits_allowRetry <= $urandom_range(0, 1);
    io_in_13_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_13_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_13_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_13_bits_traceTag <= $urandom_range(0, 1);
    io_in_13_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_14_valid <= $urandom_range(0, 1);
    io_in_14_bits_channel <= 3'({$urandom});
    io_in_14_bits_txChannel <= 3'({$urandom});
    io_in_14_bits_set <= 9'({$urandom});
    io_in_14_bits_tag <= 31'({$urandom});
    io_in_14_bits_off <= 6'({$urandom});
    io_in_14_bits_alias <= 2'({$urandom});
    io_in_14_bits_isKeyword <= $urandom_range(0, 1);
    io_in_14_bits_opcode <= 4'({$urandom});
    io_in_14_bits_param <= 3'({$urandom});
    io_in_14_bits_size <= 3'({$urandom});
    io_in_14_bits_sourceId <= 7'({$urandom});
    io_in_14_bits_denied <= $urandom_range(0, 1);
    io_in_14_bits_corrupt <= $urandom_range(0, 1);
    io_in_14_bits_mshrId <= 8'({$urandom});
    io_in_14_bits_aliasTask <= $urandom_range(0, 1);
    io_in_14_bits_useProbeData <= $urandom_range(0, 1);
    io_in_14_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_14_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_14_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_14_bits_dirty <= $urandom_range(0, 1);
    io_in_14_bits_way <= 3'({$urandom});
    io_in_14_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_14_bits_meta_state <= 2'({$urandom});
    io_in_14_bits_meta_clients <= $urandom_range(0, 1);
    io_in_14_bits_meta_alias <= 2'({$urandom});
    io_in_14_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_14_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_14_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_14_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_14_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_14_bits_metaWen <= $urandom_range(0, 1);
    io_in_14_bits_tagWen <= $urandom_range(0, 1);
    io_in_14_bits_dsWen <= $urandom_range(0, 1);
    io_in_14_bits_replTask <= $urandom_range(0, 1);
    io_in_14_bits_cmoTask <= $urandom_range(0, 1);
    io_in_14_bits_reqSource <= 5'({$urandom});
    io_in_14_bits_mergeA <= $urandom_range(0, 1);
    io_in_14_bits_aMergeTask_off <= 6'({$urandom});
    io_in_14_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_14_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_14_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_14_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_14_bits_aMergeTask_param <= 3'({$urandom});
    io_in_14_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_14_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_14_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_14_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_14_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_14_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_14_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_14_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_14_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_14_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_14_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_14_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_14_bits_tgtID <= 11'({$urandom});
    io_in_14_bits_txnID <= 12'({$urandom});
    io_in_14_bits_homeNID <= 11'({$urandom});
    io_in_14_bits_dbID <= 12'({$urandom});
    io_in_14_bits_chiOpcode <= 7'({$urandom});
    io_in_14_bits_resp <= 3'({$urandom});
    io_in_14_bits_fwdState <= 3'({$urandom});
    io_in_14_bits_retToSrc <= $urandom_range(0, 1);
    io_in_14_bits_likelyshared <= $urandom_range(0, 1);
    io_in_14_bits_expCompAck <= $urandom_range(0, 1);
    io_in_14_bits_allowRetry <= $urandom_range(0, 1);
    io_in_14_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_14_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_14_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_14_bits_traceTag <= $urandom_range(0, 1);
    io_in_14_bits_dataCheckErr <= $urandom_range(0, 1);
    io_in_15_valid <= $urandom_range(0, 1);
    io_in_15_bits_channel <= 3'({$urandom});
    io_in_15_bits_txChannel <= 3'({$urandom});
    io_in_15_bits_set <= 9'({$urandom});
    io_in_15_bits_tag <= 31'({$urandom});
    io_in_15_bits_off <= 6'({$urandom});
    io_in_15_bits_alias <= 2'({$urandom});
    io_in_15_bits_isKeyword <= $urandom_range(0, 1);
    io_in_15_bits_opcode <= 4'({$urandom});
    io_in_15_bits_param <= 3'({$urandom});
    io_in_15_bits_size <= 3'({$urandom});
    io_in_15_bits_sourceId <= 7'({$urandom});
    io_in_15_bits_denied <= $urandom_range(0, 1);
    io_in_15_bits_corrupt <= $urandom_range(0, 1);
    io_in_15_bits_mshrId <= 8'({$urandom});
    io_in_15_bits_aliasTask <= $urandom_range(0, 1);
    io_in_15_bits_useProbeData <= $urandom_range(0, 1);
    io_in_15_bits_mshrRetry <= $urandom_range(0, 1);
    io_in_15_bits_readProbeDataDown <= $urandom_range(0, 1);
    io_in_15_bits_fromL2pft <= $urandom_range(0, 1);
    io_in_15_bits_dirty <= $urandom_range(0, 1);
    io_in_15_bits_way <= 3'({$urandom});
    io_in_15_bits_meta_dirty <= $urandom_range(0, 1);
    io_in_15_bits_meta_state <= 2'({$urandom});
    io_in_15_bits_meta_clients <= $urandom_range(0, 1);
    io_in_15_bits_meta_alias <= 2'({$urandom});
    io_in_15_bits_meta_prefetch <= $urandom_range(0, 1);
    io_in_15_bits_meta_prefetchSrc <= 3'({$urandom});
    io_in_15_bits_meta_accessed <= $urandom_range(0, 1);
    io_in_15_bits_meta_tagErr <= $urandom_range(0, 1);
    io_in_15_bits_meta_dataErr <= $urandom_range(0, 1);
    io_in_15_bits_metaWen <= $urandom_range(0, 1);
    io_in_15_bits_tagWen <= $urandom_range(0, 1);
    io_in_15_bits_dsWen <= $urandom_range(0, 1);
    io_in_15_bits_replTask <= $urandom_range(0, 1);
    io_in_15_bits_cmoTask <= $urandom_range(0, 1);
    io_in_15_bits_reqSource <= 5'({$urandom});
    io_in_15_bits_mergeA <= $urandom_range(0, 1);
    io_in_15_bits_aMergeTask_off <= 6'({$urandom});
    io_in_15_bits_aMergeTask_alias <= 2'({$urandom});
    io_in_15_bits_aMergeTask_vaddr <= 44'({$urandom, $urandom});
    io_in_15_bits_aMergeTask_isKeyword <= $urandom_range(0, 1);
    io_in_15_bits_aMergeTask_opcode <= 3'({$urandom});
    io_in_15_bits_aMergeTask_param <= 3'({$urandom});
    io_in_15_bits_aMergeTask_sourceId <= 7'({$urandom});
    io_in_15_bits_aMergeTask_meta_dirty <= $urandom_range(0, 1);
    io_in_15_bits_aMergeTask_meta_state <= 2'({$urandom});
    io_in_15_bits_aMergeTask_meta_clients <= $urandom_range(0, 1);
    io_in_15_bits_aMergeTask_meta_alias <= 2'({$urandom});
    io_in_15_bits_aMergeTask_meta_accessed <= $urandom_range(0, 1);
    io_in_15_bits_snpHitRelease <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseToInval <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseToClean <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseWithData <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseIdx <= 8'({$urandom});
    io_in_15_bits_snpHitReleaseMeta_dirty <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseMeta_state <= 2'({$urandom});
    io_in_15_bits_snpHitReleaseMeta_clients <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseMeta_alias <= 2'({$urandom});
    io_in_15_bits_snpHitReleaseMeta_prefetch <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseMeta_prefetchSrc <= 3'({$urandom});
    io_in_15_bits_snpHitReleaseMeta_accessed <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseMeta_tagErr <= $urandom_range(0, 1);
    io_in_15_bits_snpHitReleaseMeta_dataErr <= $urandom_range(0, 1);
    io_in_15_bits_tgtID <= 11'({$urandom});
    io_in_15_bits_txnID <= 12'({$urandom});
    io_in_15_bits_homeNID <= 11'({$urandom});
    io_in_15_bits_dbID <= 12'({$urandom});
    io_in_15_bits_chiOpcode <= 7'({$urandom});
    io_in_15_bits_resp <= 3'({$urandom});
    io_in_15_bits_fwdState <= 3'({$urandom});
    io_in_15_bits_retToSrc <= $urandom_range(0, 1);
    io_in_15_bits_likelyshared <= $urandom_range(0, 1);
    io_in_15_bits_expCompAck <= $urandom_range(0, 1);
    io_in_15_bits_allowRetry <= $urandom_range(0, 1);
    io_in_15_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_15_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_15_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_15_bits_traceTag <= $urandom_range(0, 1);
    io_in_15_bits_dataCheckErr <= $urandom_range(0, 1);
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_in_4_ready)
    `CHECK(io_in_5_ready)
    `CHECK(io_in_6_ready)
    `CHECK(io_in_7_ready)
    `CHECK(io_in_8_ready)
    `CHECK(io_in_9_ready)
    `CHECK(io_in_10_ready)
    `CHECK(io_in_11_ready)
    `CHECK(io_in_12_ready)
    `CHECK(io_in_13_ready)
    `CHECK(io_in_14_ready)
    `CHECK(io_in_15_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_channel)
    `CHECK(io_out_bits_txChannel)
    `CHECK(io_out_bits_set)
    `CHECK(io_out_bits_tag)
    `CHECK(io_out_bits_off)
    `CHECK(io_out_bits_alias)
    `CHECK(io_out_bits_isKeyword)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_param)
    `CHECK(io_out_bits_size)
    `CHECK(io_out_bits_sourceId)
    `CHECK(io_out_bits_denied)
    `CHECK(io_out_bits_corrupt)
    `CHECK(io_out_bits_mshrTask)
    `CHECK(io_out_bits_mshrId)
    `CHECK(io_out_bits_aliasTask)
    `CHECK(io_out_bits_useProbeData)
    `CHECK(io_out_bits_mshrRetry)
    `CHECK(io_out_bits_readProbeDataDown)
    `CHECK(io_out_bits_fromL2pft)
    `CHECK(io_out_bits_dirty)
    `CHECK(io_out_bits_way)
    `CHECK(io_out_bits_meta_dirty)
    `CHECK(io_out_bits_meta_state)
    `CHECK(io_out_bits_meta_clients)
    `CHECK(io_out_bits_meta_alias)
    `CHECK(io_out_bits_meta_prefetch)
    `CHECK(io_out_bits_meta_prefetchSrc)
    `CHECK(io_out_bits_meta_accessed)
    `CHECK(io_out_bits_meta_tagErr)
    `CHECK(io_out_bits_meta_dataErr)
    `CHECK(io_out_bits_metaWen)
    `CHECK(io_out_bits_tagWen)
    `CHECK(io_out_bits_dsWen)
    `CHECK(io_out_bits_replTask)
    `CHECK(io_out_bits_cmoTask)
    `CHECK(io_out_bits_reqSource)
    `CHECK(io_out_bits_mergeA)
    `CHECK(io_out_bits_aMergeTask_off)
    `CHECK(io_out_bits_aMergeTask_alias)
    `CHECK(io_out_bits_aMergeTask_vaddr)
    `CHECK(io_out_bits_aMergeTask_isKeyword)
    `CHECK(io_out_bits_aMergeTask_opcode)
    `CHECK(io_out_bits_aMergeTask_param)
    `CHECK(io_out_bits_aMergeTask_sourceId)
    `CHECK(io_out_bits_aMergeTask_meta_dirty)
    `CHECK(io_out_bits_aMergeTask_meta_state)
    `CHECK(io_out_bits_aMergeTask_meta_clients)
    `CHECK(io_out_bits_aMergeTask_meta_alias)
    `CHECK(io_out_bits_aMergeTask_meta_accessed)
    `CHECK(io_out_bits_snpHitRelease)
    `CHECK(io_out_bits_snpHitReleaseToInval)
    `CHECK(io_out_bits_snpHitReleaseToClean)
    `CHECK(io_out_bits_snpHitReleaseWithData)
    `CHECK(io_out_bits_snpHitReleaseIdx)
    `CHECK(io_out_bits_snpHitReleaseMeta_dirty)
    `CHECK(io_out_bits_snpHitReleaseMeta_state)
    `CHECK(io_out_bits_snpHitReleaseMeta_clients)
    `CHECK(io_out_bits_snpHitReleaseMeta_alias)
    `CHECK(io_out_bits_snpHitReleaseMeta_prefetch)
    `CHECK(io_out_bits_snpHitReleaseMeta_prefetchSrc)
    `CHECK(io_out_bits_snpHitReleaseMeta_accessed)
    `CHECK(io_out_bits_snpHitReleaseMeta_tagErr)
    `CHECK(io_out_bits_snpHitReleaseMeta_dataErr)
    `CHECK(io_out_bits_tgtID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_homeNID)
    `CHECK(io_out_bits_dbID)
    `CHECK(io_out_bits_chiOpcode)
    `CHECK(io_out_bits_resp)
    `CHECK(io_out_bits_fwdState)
    `CHECK(io_out_bits_retToSrc)
    `CHECK(io_out_bits_likelyshared)
    `CHECK(io_out_bits_expCompAck)
    `CHECK(io_out_bits_allowRetry)
    `CHECK(io_out_bits_memAttr_allocate)
    `CHECK(io_out_bits_memAttr_cacheable)
    `CHECK(io_out_bits_memAttr_ewa)
    `CHECK(io_out_bits_traceTag)
    `CHECK(io_out_bits_dataCheckErr)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_channel = '0;
    io_in_0_bits_txChannel = '0;
    io_in_0_bits_set = '0;
    io_in_0_bits_tag = '0;
    io_in_0_bits_off = '0;
    io_in_0_bits_alias = '0;
    io_in_0_bits_isKeyword = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_param = '0;
    io_in_0_bits_size = '0;
    io_in_0_bits_sourceId = '0;
    io_in_0_bits_denied = '0;
    io_in_0_bits_corrupt = '0;
    io_in_0_bits_mshrId = '0;
    io_in_0_bits_aliasTask = '0;
    io_in_0_bits_useProbeData = '0;
    io_in_0_bits_mshrRetry = '0;
    io_in_0_bits_readProbeDataDown = '0;
    io_in_0_bits_fromL2pft = '0;
    io_in_0_bits_dirty = '0;
    io_in_0_bits_way = '0;
    io_in_0_bits_meta_dirty = '0;
    io_in_0_bits_meta_state = '0;
    io_in_0_bits_meta_clients = '0;
    io_in_0_bits_meta_alias = '0;
    io_in_0_bits_meta_prefetch = '0;
    io_in_0_bits_meta_prefetchSrc = '0;
    io_in_0_bits_meta_accessed = '0;
    io_in_0_bits_meta_tagErr = '0;
    io_in_0_bits_meta_dataErr = '0;
    io_in_0_bits_metaWen = '0;
    io_in_0_bits_tagWen = '0;
    io_in_0_bits_dsWen = '0;
    io_in_0_bits_replTask = '0;
    io_in_0_bits_cmoTask = '0;
    io_in_0_bits_reqSource = '0;
    io_in_0_bits_mergeA = '0;
    io_in_0_bits_aMergeTask_off = '0;
    io_in_0_bits_aMergeTask_alias = '0;
    io_in_0_bits_aMergeTask_vaddr = '0;
    io_in_0_bits_aMergeTask_isKeyword = '0;
    io_in_0_bits_aMergeTask_opcode = '0;
    io_in_0_bits_aMergeTask_param = '0;
    io_in_0_bits_aMergeTask_sourceId = '0;
    io_in_0_bits_aMergeTask_meta_dirty = '0;
    io_in_0_bits_aMergeTask_meta_state = '0;
    io_in_0_bits_aMergeTask_meta_clients = '0;
    io_in_0_bits_aMergeTask_meta_alias = '0;
    io_in_0_bits_aMergeTask_meta_accessed = '0;
    io_in_0_bits_snpHitRelease = '0;
    io_in_0_bits_snpHitReleaseToInval = '0;
    io_in_0_bits_snpHitReleaseToClean = '0;
    io_in_0_bits_snpHitReleaseWithData = '0;
    io_in_0_bits_snpHitReleaseIdx = '0;
    io_in_0_bits_snpHitReleaseMeta_dirty = '0;
    io_in_0_bits_snpHitReleaseMeta_state = '0;
    io_in_0_bits_snpHitReleaseMeta_clients = '0;
    io_in_0_bits_snpHitReleaseMeta_alias = '0;
    io_in_0_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_0_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_0_bits_snpHitReleaseMeta_accessed = '0;
    io_in_0_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_0_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_homeNID = '0;
    io_in_0_bits_dbID = '0;
    io_in_0_bits_chiOpcode = '0;
    io_in_0_bits_resp = '0;
    io_in_0_bits_fwdState = '0;
    io_in_0_bits_retToSrc = '0;
    io_in_0_bits_likelyshared = '0;
    io_in_0_bits_expCompAck = '0;
    io_in_0_bits_allowRetry = '0;
    io_in_0_bits_memAttr_allocate = '0;
    io_in_0_bits_memAttr_cacheable = '0;
    io_in_0_bits_memAttr_ewa = '0;
    io_in_0_bits_traceTag = '0;
    io_in_0_bits_dataCheckErr = '0;
    io_in_1_valid = '0;
    io_in_1_bits_channel = '0;
    io_in_1_bits_txChannel = '0;
    io_in_1_bits_set = '0;
    io_in_1_bits_tag = '0;
    io_in_1_bits_off = '0;
    io_in_1_bits_alias = '0;
    io_in_1_bits_isKeyword = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_param = '0;
    io_in_1_bits_size = '0;
    io_in_1_bits_sourceId = '0;
    io_in_1_bits_denied = '0;
    io_in_1_bits_corrupt = '0;
    io_in_1_bits_mshrId = '0;
    io_in_1_bits_aliasTask = '0;
    io_in_1_bits_useProbeData = '0;
    io_in_1_bits_mshrRetry = '0;
    io_in_1_bits_readProbeDataDown = '0;
    io_in_1_bits_fromL2pft = '0;
    io_in_1_bits_dirty = '0;
    io_in_1_bits_way = '0;
    io_in_1_bits_meta_dirty = '0;
    io_in_1_bits_meta_state = '0;
    io_in_1_bits_meta_clients = '0;
    io_in_1_bits_meta_alias = '0;
    io_in_1_bits_meta_prefetch = '0;
    io_in_1_bits_meta_prefetchSrc = '0;
    io_in_1_bits_meta_accessed = '0;
    io_in_1_bits_meta_tagErr = '0;
    io_in_1_bits_meta_dataErr = '0;
    io_in_1_bits_metaWen = '0;
    io_in_1_bits_tagWen = '0;
    io_in_1_bits_dsWen = '0;
    io_in_1_bits_replTask = '0;
    io_in_1_bits_cmoTask = '0;
    io_in_1_bits_reqSource = '0;
    io_in_1_bits_mergeA = '0;
    io_in_1_bits_aMergeTask_off = '0;
    io_in_1_bits_aMergeTask_alias = '0;
    io_in_1_bits_aMergeTask_vaddr = '0;
    io_in_1_bits_aMergeTask_isKeyword = '0;
    io_in_1_bits_aMergeTask_opcode = '0;
    io_in_1_bits_aMergeTask_param = '0;
    io_in_1_bits_aMergeTask_sourceId = '0;
    io_in_1_bits_aMergeTask_meta_dirty = '0;
    io_in_1_bits_aMergeTask_meta_state = '0;
    io_in_1_bits_aMergeTask_meta_clients = '0;
    io_in_1_bits_aMergeTask_meta_alias = '0;
    io_in_1_bits_aMergeTask_meta_accessed = '0;
    io_in_1_bits_snpHitRelease = '0;
    io_in_1_bits_snpHitReleaseToInval = '0;
    io_in_1_bits_snpHitReleaseToClean = '0;
    io_in_1_bits_snpHitReleaseWithData = '0;
    io_in_1_bits_snpHitReleaseIdx = '0;
    io_in_1_bits_snpHitReleaseMeta_dirty = '0;
    io_in_1_bits_snpHitReleaseMeta_state = '0;
    io_in_1_bits_snpHitReleaseMeta_clients = '0;
    io_in_1_bits_snpHitReleaseMeta_alias = '0;
    io_in_1_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_1_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_1_bits_snpHitReleaseMeta_accessed = '0;
    io_in_1_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_1_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_1_bits_tgtID = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_homeNID = '0;
    io_in_1_bits_dbID = '0;
    io_in_1_bits_chiOpcode = '0;
    io_in_1_bits_resp = '0;
    io_in_1_bits_fwdState = '0;
    io_in_1_bits_retToSrc = '0;
    io_in_1_bits_likelyshared = '0;
    io_in_1_bits_expCompAck = '0;
    io_in_1_bits_allowRetry = '0;
    io_in_1_bits_memAttr_allocate = '0;
    io_in_1_bits_memAttr_cacheable = '0;
    io_in_1_bits_memAttr_ewa = '0;
    io_in_1_bits_traceTag = '0;
    io_in_1_bits_dataCheckErr = '0;
    io_in_2_valid = '0;
    io_in_2_bits_channel = '0;
    io_in_2_bits_txChannel = '0;
    io_in_2_bits_set = '0;
    io_in_2_bits_tag = '0;
    io_in_2_bits_off = '0;
    io_in_2_bits_alias = '0;
    io_in_2_bits_isKeyword = '0;
    io_in_2_bits_opcode = '0;
    io_in_2_bits_param = '0;
    io_in_2_bits_size = '0;
    io_in_2_bits_sourceId = '0;
    io_in_2_bits_denied = '0;
    io_in_2_bits_corrupt = '0;
    io_in_2_bits_mshrId = '0;
    io_in_2_bits_aliasTask = '0;
    io_in_2_bits_useProbeData = '0;
    io_in_2_bits_mshrRetry = '0;
    io_in_2_bits_readProbeDataDown = '0;
    io_in_2_bits_fromL2pft = '0;
    io_in_2_bits_dirty = '0;
    io_in_2_bits_way = '0;
    io_in_2_bits_meta_dirty = '0;
    io_in_2_bits_meta_state = '0;
    io_in_2_bits_meta_clients = '0;
    io_in_2_bits_meta_alias = '0;
    io_in_2_bits_meta_prefetch = '0;
    io_in_2_bits_meta_prefetchSrc = '0;
    io_in_2_bits_meta_accessed = '0;
    io_in_2_bits_meta_tagErr = '0;
    io_in_2_bits_meta_dataErr = '0;
    io_in_2_bits_metaWen = '0;
    io_in_2_bits_tagWen = '0;
    io_in_2_bits_dsWen = '0;
    io_in_2_bits_replTask = '0;
    io_in_2_bits_cmoTask = '0;
    io_in_2_bits_reqSource = '0;
    io_in_2_bits_mergeA = '0;
    io_in_2_bits_aMergeTask_off = '0;
    io_in_2_bits_aMergeTask_alias = '0;
    io_in_2_bits_aMergeTask_vaddr = '0;
    io_in_2_bits_aMergeTask_isKeyword = '0;
    io_in_2_bits_aMergeTask_opcode = '0;
    io_in_2_bits_aMergeTask_param = '0;
    io_in_2_bits_aMergeTask_sourceId = '0;
    io_in_2_bits_aMergeTask_meta_dirty = '0;
    io_in_2_bits_aMergeTask_meta_state = '0;
    io_in_2_bits_aMergeTask_meta_clients = '0;
    io_in_2_bits_aMergeTask_meta_alias = '0;
    io_in_2_bits_aMergeTask_meta_accessed = '0;
    io_in_2_bits_snpHitRelease = '0;
    io_in_2_bits_snpHitReleaseToInval = '0;
    io_in_2_bits_snpHitReleaseToClean = '0;
    io_in_2_bits_snpHitReleaseWithData = '0;
    io_in_2_bits_snpHitReleaseIdx = '0;
    io_in_2_bits_snpHitReleaseMeta_dirty = '0;
    io_in_2_bits_snpHitReleaseMeta_state = '0;
    io_in_2_bits_snpHitReleaseMeta_clients = '0;
    io_in_2_bits_snpHitReleaseMeta_alias = '0;
    io_in_2_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_2_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_2_bits_snpHitReleaseMeta_accessed = '0;
    io_in_2_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_2_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_2_bits_tgtID = '0;
    io_in_2_bits_txnID = '0;
    io_in_2_bits_homeNID = '0;
    io_in_2_bits_dbID = '0;
    io_in_2_bits_chiOpcode = '0;
    io_in_2_bits_resp = '0;
    io_in_2_bits_fwdState = '0;
    io_in_2_bits_retToSrc = '0;
    io_in_2_bits_likelyshared = '0;
    io_in_2_bits_expCompAck = '0;
    io_in_2_bits_allowRetry = '0;
    io_in_2_bits_memAttr_allocate = '0;
    io_in_2_bits_memAttr_cacheable = '0;
    io_in_2_bits_memAttr_ewa = '0;
    io_in_2_bits_traceTag = '0;
    io_in_2_bits_dataCheckErr = '0;
    io_in_3_valid = '0;
    io_in_3_bits_channel = '0;
    io_in_3_bits_txChannel = '0;
    io_in_3_bits_set = '0;
    io_in_3_bits_tag = '0;
    io_in_3_bits_off = '0;
    io_in_3_bits_alias = '0;
    io_in_3_bits_isKeyword = '0;
    io_in_3_bits_opcode = '0;
    io_in_3_bits_param = '0;
    io_in_3_bits_size = '0;
    io_in_3_bits_sourceId = '0;
    io_in_3_bits_denied = '0;
    io_in_3_bits_corrupt = '0;
    io_in_3_bits_mshrId = '0;
    io_in_3_bits_aliasTask = '0;
    io_in_3_bits_useProbeData = '0;
    io_in_3_bits_mshrRetry = '0;
    io_in_3_bits_readProbeDataDown = '0;
    io_in_3_bits_fromL2pft = '0;
    io_in_3_bits_dirty = '0;
    io_in_3_bits_way = '0;
    io_in_3_bits_meta_dirty = '0;
    io_in_3_bits_meta_state = '0;
    io_in_3_bits_meta_clients = '0;
    io_in_3_bits_meta_alias = '0;
    io_in_3_bits_meta_prefetch = '0;
    io_in_3_bits_meta_prefetchSrc = '0;
    io_in_3_bits_meta_accessed = '0;
    io_in_3_bits_meta_tagErr = '0;
    io_in_3_bits_meta_dataErr = '0;
    io_in_3_bits_metaWen = '0;
    io_in_3_bits_tagWen = '0;
    io_in_3_bits_dsWen = '0;
    io_in_3_bits_replTask = '0;
    io_in_3_bits_cmoTask = '0;
    io_in_3_bits_reqSource = '0;
    io_in_3_bits_mergeA = '0;
    io_in_3_bits_aMergeTask_off = '0;
    io_in_3_bits_aMergeTask_alias = '0;
    io_in_3_bits_aMergeTask_vaddr = '0;
    io_in_3_bits_aMergeTask_isKeyword = '0;
    io_in_3_bits_aMergeTask_opcode = '0;
    io_in_3_bits_aMergeTask_param = '0;
    io_in_3_bits_aMergeTask_sourceId = '0;
    io_in_3_bits_aMergeTask_meta_dirty = '0;
    io_in_3_bits_aMergeTask_meta_state = '0;
    io_in_3_bits_aMergeTask_meta_clients = '0;
    io_in_3_bits_aMergeTask_meta_alias = '0;
    io_in_3_bits_aMergeTask_meta_accessed = '0;
    io_in_3_bits_snpHitRelease = '0;
    io_in_3_bits_snpHitReleaseToInval = '0;
    io_in_3_bits_snpHitReleaseToClean = '0;
    io_in_3_bits_snpHitReleaseWithData = '0;
    io_in_3_bits_snpHitReleaseIdx = '0;
    io_in_3_bits_snpHitReleaseMeta_dirty = '0;
    io_in_3_bits_snpHitReleaseMeta_state = '0;
    io_in_3_bits_snpHitReleaseMeta_clients = '0;
    io_in_3_bits_snpHitReleaseMeta_alias = '0;
    io_in_3_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_3_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_3_bits_snpHitReleaseMeta_accessed = '0;
    io_in_3_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_3_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_3_bits_tgtID = '0;
    io_in_3_bits_txnID = '0;
    io_in_3_bits_homeNID = '0;
    io_in_3_bits_dbID = '0;
    io_in_3_bits_chiOpcode = '0;
    io_in_3_bits_resp = '0;
    io_in_3_bits_fwdState = '0;
    io_in_3_bits_retToSrc = '0;
    io_in_3_bits_likelyshared = '0;
    io_in_3_bits_expCompAck = '0;
    io_in_3_bits_allowRetry = '0;
    io_in_3_bits_memAttr_allocate = '0;
    io_in_3_bits_memAttr_cacheable = '0;
    io_in_3_bits_memAttr_ewa = '0;
    io_in_3_bits_traceTag = '0;
    io_in_3_bits_dataCheckErr = '0;
    io_in_4_valid = '0;
    io_in_4_bits_channel = '0;
    io_in_4_bits_txChannel = '0;
    io_in_4_bits_set = '0;
    io_in_4_bits_tag = '0;
    io_in_4_bits_off = '0;
    io_in_4_bits_alias = '0;
    io_in_4_bits_isKeyword = '0;
    io_in_4_bits_opcode = '0;
    io_in_4_bits_param = '0;
    io_in_4_bits_size = '0;
    io_in_4_bits_sourceId = '0;
    io_in_4_bits_denied = '0;
    io_in_4_bits_corrupt = '0;
    io_in_4_bits_mshrId = '0;
    io_in_4_bits_aliasTask = '0;
    io_in_4_bits_useProbeData = '0;
    io_in_4_bits_mshrRetry = '0;
    io_in_4_bits_readProbeDataDown = '0;
    io_in_4_bits_fromL2pft = '0;
    io_in_4_bits_dirty = '0;
    io_in_4_bits_way = '0;
    io_in_4_bits_meta_dirty = '0;
    io_in_4_bits_meta_state = '0;
    io_in_4_bits_meta_clients = '0;
    io_in_4_bits_meta_alias = '0;
    io_in_4_bits_meta_prefetch = '0;
    io_in_4_bits_meta_prefetchSrc = '0;
    io_in_4_bits_meta_accessed = '0;
    io_in_4_bits_meta_tagErr = '0;
    io_in_4_bits_meta_dataErr = '0;
    io_in_4_bits_metaWen = '0;
    io_in_4_bits_tagWen = '0;
    io_in_4_bits_dsWen = '0;
    io_in_4_bits_replTask = '0;
    io_in_4_bits_cmoTask = '0;
    io_in_4_bits_reqSource = '0;
    io_in_4_bits_mergeA = '0;
    io_in_4_bits_aMergeTask_off = '0;
    io_in_4_bits_aMergeTask_alias = '0;
    io_in_4_bits_aMergeTask_vaddr = '0;
    io_in_4_bits_aMergeTask_isKeyword = '0;
    io_in_4_bits_aMergeTask_opcode = '0;
    io_in_4_bits_aMergeTask_param = '0;
    io_in_4_bits_aMergeTask_sourceId = '0;
    io_in_4_bits_aMergeTask_meta_dirty = '0;
    io_in_4_bits_aMergeTask_meta_state = '0;
    io_in_4_bits_aMergeTask_meta_clients = '0;
    io_in_4_bits_aMergeTask_meta_alias = '0;
    io_in_4_bits_aMergeTask_meta_accessed = '0;
    io_in_4_bits_snpHitRelease = '0;
    io_in_4_bits_snpHitReleaseToInval = '0;
    io_in_4_bits_snpHitReleaseToClean = '0;
    io_in_4_bits_snpHitReleaseWithData = '0;
    io_in_4_bits_snpHitReleaseIdx = '0;
    io_in_4_bits_snpHitReleaseMeta_dirty = '0;
    io_in_4_bits_snpHitReleaseMeta_state = '0;
    io_in_4_bits_snpHitReleaseMeta_clients = '0;
    io_in_4_bits_snpHitReleaseMeta_alias = '0;
    io_in_4_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_4_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_4_bits_snpHitReleaseMeta_accessed = '0;
    io_in_4_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_4_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_4_bits_tgtID = '0;
    io_in_4_bits_txnID = '0;
    io_in_4_bits_homeNID = '0;
    io_in_4_bits_dbID = '0;
    io_in_4_bits_chiOpcode = '0;
    io_in_4_bits_resp = '0;
    io_in_4_bits_fwdState = '0;
    io_in_4_bits_retToSrc = '0;
    io_in_4_bits_likelyshared = '0;
    io_in_4_bits_expCompAck = '0;
    io_in_4_bits_allowRetry = '0;
    io_in_4_bits_memAttr_allocate = '0;
    io_in_4_bits_memAttr_cacheable = '0;
    io_in_4_bits_memAttr_ewa = '0;
    io_in_4_bits_traceTag = '0;
    io_in_4_bits_dataCheckErr = '0;
    io_in_5_valid = '0;
    io_in_5_bits_channel = '0;
    io_in_5_bits_txChannel = '0;
    io_in_5_bits_set = '0;
    io_in_5_bits_tag = '0;
    io_in_5_bits_off = '0;
    io_in_5_bits_alias = '0;
    io_in_5_bits_isKeyword = '0;
    io_in_5_bits_opcode = '0;
    io_in_5_bits_param = '0;
    io_in_5_bits_size = '0;
    io_in_5_bits_sourceId = '0;
    io_in_5_bits_denied = '0;
    io_in_5_bits_corrupt = '0;
    io_in_5_bits_mshrId = '0;
    io_in_5_bits_aliasTask = '0;
    io_in_5_bits_useProbeData = '0;
    io_in_5_bits_mshrRetry = '0;
    io_in_5_bits_readProbeDataDown = '0;
    io_in_5_bits_fromL2pft = '0;
    io_in_5_bits_dirty = '0;
    io_in_5_bits_way = '0;
    io_in_5_bits_meta_dirty = '0;
    io_in_5_bits_meta_state = '0;
    io_in_5_bits_meta_clients = '0;
    io_in_5_bits_meta_alias = '0;
    io_in_5_bits_meta_prefetch = '0;
    io_in_5_bits_meta_prefetchSrc = '0;
    io_in_5_bits_meta_accessed = '0;
    io_in_5_bits_meta_tagErr = '0;
    io_in_5_bits_meta_dataErr = '0;
    io_in_5_bits_metaWen = '0;
    io_in_5_bits_tagWen = '0;
    io_in_5_bits_dsWen = '0;
    io_in_5_bits_replTask = '0;
    io_in_5_bits_cmoTask = '0;
    io_in_5_bits_reqSource = '0;
    io_in_5_bits_mergeA = '0;
    io_in_5_bits_aMergeTask_off = '0;
    io_in_5_bits_aMergeTask_alias = '0;
    io_in_5_bits_aMergeTask_vaddr = '0;
    io_in_5_bits_aMergeTask_isKeyword = '0;
    io_in_5_bits_aMergeTask_opcode = '0;
    io_in_5_bits_aMergeTask_param = '0;
    io_in_5_bits_aMergeTask_sourceId = '0;
    io_in_5_bits_aMergeTask_meta_dirty = '0;
    io_in_5_bits_aMergeTask_meta_state = '0;
    io_in_5_bits_aMergeTask_meta_clients = '0;
    io_in_5_bits_aMergeTask_meta_alias = '0;
    io_in_5_bits_aMergeTask_meta_accessed = '0;
    io_in_5_bits_snpHitRelease = '0;
    io_in_5_bits_snpHitReleaseToInval = '0;
    io_in_5_bits_snpHitReleaseToClean = '0;
    io_in_5_bits_snpHitReleaseWithData = '0;
    io_in_5_bits_snpHitReleaseIdx = '0;
    io_in_5_bits_snpHitReleaseMeta_dirty = '0;
    io_in_5_bits_snpHitReleaseMeta_state = '0;
    io_in_5_bits_snpHitReleaseMeta_clients = '0;
    io_in_5_bits_snpHitReleaseMeta_alias = '0;
    io_in_5_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_5_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_5_bits_snpHitReleaseMeta_accessed = '0;
    io_in_5_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_5_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_5_bits_tgtID = '0;
    io_in_5_bits_txnID = '0;
    io_in_5_bits_homeNID = '0;
    io_in_5_bits_dbID = '0;
    io_in_5_bits_chiOpcode = '0;
    io_in_5_bits_resp = '0;
    io_in_5_bits_fwdState = '0;
    io_in_5_bits_retToSrc = '0;
    io_in_5_bits_likelyshared = '0;
    io_in_5_bits_expCompAck = '0;
    io_in_5_bits_allowRetry = '0;
    io_in_5_bits_memAttr_allocate = '0;
    io_in_5_bits_memAttr_cacheable = '0;
    io_in_5_bits_memAttr_ewa = '0;
    io_in_5_bits_traceTag = '0;
    io_in_5_bits_dataCheckErr = '0;
    io_in_6_valid = '0;
    io_in_6_bits_channel = '0;
    io_in_6_bits_txChannel = '0;
    io_in_6_bits_set = '0;
    io_in_6_bits_tag = '0;
    io_in_6_bits_off = '0;
    io_in_6_bits_alias = '0;
    io_in_6_bits_isKeyword = '0;
    io_in_6_bits_opcode = '0;
    io_in_6_bits_param = '0;
    io_in_6_bits_size = '0;
    io_in_6_bits_sourceId = '0;
    io_in_6_bits_denied = '0;
    io_in_6_bits_corrupt = '0;
    io_in_6_bits_mshrId = '0;
    io_in_6_bits_aliasTask = '0;
    io_in_6_bits_useProbeData = '0;
    io_in_6_bits_mshrRetry = '0;
    io_in_6_bits_readProbeDataDown = '0;
    io_in_6_bits_fromL2pft = '0;
    io_in_6_bits_dirty = '0;
    io_in_6_bits_way = '0;
    io_in_6_bits_meta_dirty = '0;
    io_in_6_bits_meta_state = '0;
    io_in_6_bits_meta_clients = '0;
    io_in_6_bits_meta_alias = '0;
    io_in_6_bits_meta_prefetch = '0;
    io_in_6_bits_meta_prefetchSrc = '0;
    io_in_6_bits_meta_accessed = '0;
    io_in_6_bits_meta_tagErr = '0;
    io_in_6_bits_meta_dataErr = '0;
    io_in_6_bits_metaWen = '0;
    io_in_6_bits_tagWen = '0;
    io_in_6_bits_dsWen = '0;
    io_in_6_bits_replTask = '0;
    io_in_6_bits_cmoTask = '0;
    io_in_6_bits_reqSource = '0;
    io_in_6_bits_mergeA = '0;
    io_in_6_bits_aMergeTask_off = '0;
    io_in_6_bits_aMergeTask_alias = '0;
    io_in_6_bits_aMergeTask_vaddr = '0;
    io_in_6_bits_aMergeTask_isKeyword = '0;
    io_in_6_bits_aMergeTask_opcode = '0;
    io_in_6_bits_aMergeTask_param = '0;
    io_in_6_bits_aMergeTask_sourceId = '0;
    io_in_6_bits_aMergeTask_meta_dirty = '0;
    io_in_6_bits_aMergeTask_meta_state = '0;
    io_in_6_bits_aMergeTask_meta_clients = '0;
    io_in_6_bits_aMergeTask_meta_alias = '0;
    io_in_6_bits_aMergeTask_meta_accessed = '0;
    io_in_6_bits_snpHitRelease = '0;
    io_in_6_bits_snpHitReleaseToInval = '0;
    io_in_6_bits_snpHitReleaseToClean = '0;
    io_in_6_bits_snpHitReleaseWithData = '0;
    io_in_6_bits_snpHitReleaseIdx = '0;
    io_in_6_bits_snpHitReleaseMeta_dirty = '0;
    io_in_6_bits_snpHitReleaseMeta_state = '0;
    io_in_6_bits_snpHitReleaseMeta_clients = '0;
    io_in_6_bits_snpHitReleaseMeta_alias = '0;
    io_in_6_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_6_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_6_bits_snpHitReleaseMeta_accessed = '0;
    io_in_6_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_6_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_6_bits_tgtID = '0;
    io_in_6_bits_txnID = '0;
    io_in_6_bits_homeNID = '0;
    io_in_6_bits_dbID = '0;
    io_in_6_bits_chiOpcode = '0;
    io_in_6_bits_resp = '0;
    io_in_6_bits_fwdState = '0;
    io_in_6_bits_retToSrc = '0;
    io_in_6_bits_likelyshared = '0;
    io_in_6_bits_expCompAck = '0;
    io_in_6_bits_allowRetry = '0;
    io_in_6_bits_memAttr_allocate = '0;
    io_in_6_bits_memAttr_cacheable = '0;
    io_in_6_bits_memAttr_ewa = '0;
    io_in_6_bits_traceTag = '0;
    io_in_6_bits_dataCheckErr = '0;
    io_in_7_valid = '0;
    io_in_7_bits_channel = '0;
    io_in_7_bits_txChannel = '0;
    io_in_7_bits_set = '0;
    io_in_7_bits_tag = '0;
    io_in_7_bits_off = '0;
    io_in_7_bits_alias = '0;
    io_in_7_bits_isKeyword = '0;
    io_in_7_bits_opcode = '0;
    io_in_7_bits_param = '0;
    io_in_7_bits_size = '0;
    io_in_7_bits_sourceId = '0;
    io_in_7_bits_denied = '0;
    io_in_7_bits_corrupt = '0;
    io_in_7_bits_mshrId = '0;
    io_in_7_bits_aliasTask = '0;
    io_in_7_bits_useProbeData = '0;
    io_in_7_bits_mshrRetry = '0;
    io_in_7_bits_readProbeDataDown = '0;
    io_in_7_bits_fromL2pft = '0;
    io_in_7_bits_dirty = '0;
    io_in_7_bits_way = '0;
    io_in_7_bits_meta_dirty = '0;
    io_in_7_bits_meta_state = '0;
    io_in_7_bits_meta_clients = '0;
    io_in_7_bits_meta_alias = '0;
    io_in_7_bits_meta_prefetch = '0;
    io_in_7_bits_meta_prefetchSrc = '0;
    io_in_7_bits_meta_accessed = '0;
    io_in_7_bits_meta_tagErr = '0;
    io_in_7_bits_meta_dataErr = '0;
    io_in_7_bits_metaWen = '0;
    io_in_7_bits_tagWen = '0;
    io_in_7_bits_dsWen = '0;
    io_in_7_bits_replTask = '0;
    io_in_7_bits_cmoTask = '0;
    io_in_7_bits_reqSource = '0;
    io_in_7_bits_mergeA = '0;
    io_in_7_bits_aMergeTask_off = '0;
    io_in_7_bits_aMergeTask_alias = '0;
    io_in_7_bits_aMergeTask_vaddr = '0;
    io_in_7_bits_aMergeTask_isKeyword = '0;
    io_in_7_bits_aMergeTask_opcode = '0;
    io_in_7_bits_aMergeTask_param = '0;
    io_in_7_bits_aMergeTask_sourceId = '0;
    io_in_7_bits_aMergeTask_meta_dirty = '0;
    io_in_7_bits_aMergeTask_meta_state = '0;
    io_in_7_bits_aMergeTask_meta_clients = '0;
    io_in_7_bits_aMergeTask_meta_alias = '0;
    io_in_7_bits_aMergeTask_meta_accessed = '0;
    io_in_7_bits_snpHitRelease = '0;
    io_in_7_bits_snpHitReleaseToInval = '0;
    io_in_7_bits_snpHitReleaseToClean = '0;
    io_in_7_bits_snpHitReleaseWithData = '0;
    io_in_7_bits_snpHitReleaseIdx = '0;
    io_in_7_bits_snpHitReleaseMeta_dirty = '0;
    io_in_7_bits_snpHitReleaseMeta_state = '0;
    io_in_7_bits_snpHitReleaseMeta_clients = '0;
    io_in_7_bits_snpHitReleaseMeta_alias = '0;
    io_in_7_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_7_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_7_bits_snpHitReleaseMeta_accessed = '0;
    io_in_7_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_7_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_7_bits_tgtID = '0;
    io_in_7_bits_txnID = '0;
    io_in_7_bits_homeNID = '0;
    io_in_7_bits_dbID = '0;
    io_in_7_bits_chiOpcode = '0;
    io_in_7_bits_resp = '0;
    io_in_7_bits_fwdState = '0;
    io_in_7_bits_retToSrc = '0;
    io_in_7_bits_likelyshared = '0;
    io_in_7_bits_expCompAck = '0;
    io_in_7_bits_allowRetry = '0;
    io_in_7_bits_memAttr_allocate = '0;
    io_in_7_bits_memAttr_cacheable = '0;
    io_in_7_bits_memAttr_ewa = '0;
    io_in_7_bits_traceTag = '0;
    io_in_7_bits_dataCheckErr = '0;
    io_in_8_valid = '0;
    io_in_8_bits_channel = '0;
    io_in_8_bits_txChannel = '0;
    io_in_8_bits_set = '0;
    io_in_8_bits_tag = '0;
    io_in_8_bits_off = '0;
    io_in_8_bits_alias = '0;
    io_in_8_bits_isKeyword = '0;
    io_in_8_bits_opcode = '0;
    io_in_8_bits_param = '0;
    io_in_8_bits_size = '0;
    io_in_8_bits_sourceId = '0;
    io_in_8_bits_denied = '0;
    io_in_8_bits_corrupt = '0;
    io_in_8_bits_mshrId = '0;
    io_in_8_bits_aliasTask = '0;
    io_in_8_bits_useProbeData = '0;
    io_in_8_bits_mshrRetry = '0;
    io_in_8_bits_readProbeDataDown = '0;
    io_in_8_bits_fromL2pft = '0;
    io_in_8_bits_dirty = '0;
    io_in_8_bits_way = '0;
    io_in_8_bits_meta_dirty = '0;
    io_in_8_bits_meta_state = '0;
    io_in_8_bits_meta_clients = '0;
    io_in_8_bits_meta_alias = '0;
    io_in_8_bits_meta_prefetch = '0;
    io_in_8_bits_meta_prefetchSrc = '0;
    io_in_8_bits_meta_accessed = '0;
    io_in_8_bits_meta_tagErr = '0;
    io_in_8_bits_meta_dataErr = '0;
    io_in_8_bits_metaWen = '0;
    io_in_8_bits_tagWen = '0;
    io_in_8_bits_dsWen = '0;
    io_in_8_bits_replTask = '0;
    io_in_8_bits_cmoTask = '0;
    io_in_8_bits_reqSource = '0;
    io_in_8_bits_mergeA = '0;
    io_in_8_bits_aMergeTask_off = '0;
    io_in_8_bits_aMergeTask_alias = '0;
    io_in_8_bits_aMergeTask_vaddr = '0;
    io_in_8_bits_aMergeTask_isKeyword = '0;
    io_in_8_bits_aMergeTask_opcode = '0;
    io_in_8_bits_aMergeTask_param = '0;
    io_in_8_bits_aMergeTask_sourceId = '0;
    io_in_8_bits_aMergeTask_meta_dirty = '0;
    io_in_8_bits_aMergeTask_meta_state = '0;
    io_in_8_bits_aMergeTask_meta_clients = '0;
    io_in_8_bits_aMergeTask_meta_alias = '0;
    io_in_8_bits_aMergeTask_meta_accessed = '0;
    io_in_8_bits_snpHitRelease = '0;
    io_in_8_bits_snpHitReleaseToInval = '0;
    io_in_8_bits_snpHitReleaseToClean = '0;
    io_in_8_bits_snpHitReleaseWithData = '0;
    io_in_8_bits_snpHitReleaseIdx = '0;
    io_in_8_bits_snpHitReleaseMeta_dirty = '0;
    io_in_8_bits_snpHitReleaseMeta_state = '0;
    io_in_8_bits_snpHitReleaseMeta_clients = '0;
    io_in_8_bits_snpHitReleaseMeta_alias = '0;
    io_in_8_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_8_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_8_bits_snpHitReleaseMeta_accessed = '0;
    io_in_8_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_8_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_8_bits_tgtID = '0;
    io_in_8_bits_txnID = '0;
    io_in_8_bits_homeNID = '0;
    io_in_8_bits_dbID = '0;
    io_in_8_bits_chiOpcode = '0;
    io_in_8_bits_resp = '0;
    io_in_8_bits_fwdState = '0;
    io_in_8_bits_retToSrc = '0;
    io_in_8_bits_likelyshared = '0;
    io_in_8_bits_expCompAck = '0;
    io_in_8_bits_allowRetry = '0;
    io_in_8_bits_memAttr_allocate = '0;
    io_in_8_bits_memAttr_cacheable = '0;
    io_in_8_bits_memAttr_ewa = '0;
    io_in_8_bits_traceTag = '0;
    io_in_8_bits_dataCheckErr = '0;
    io_in_9_valid = '0;
    io_in_9_bits_channel = '0;
    io_in_9_bits_txChannel = '0;
    io_in_9_bits_set = '0;
    io_in_9_bits_tag = '0;
    io_in_9_bits_off = '0;
    io_in_9_bits_alias = '0;
    io_in_9_bits_isKeyword = '0;
    io_in_9_bits_opcode = '0;
    io_in_9_bits_param = '0;
    io_in_9_bits_size = '0;
    io_in_9_bits_sourceId = '0;
    io_in_9_bits_denied = '0;
    io_in_9_bits_corrupt = '0;
    io_in_9_bits_mshrId = '0;
    io_in_9_bits_aliasTask = '0;
    io_in_9_bits_useProbeData = '0;
    io_in_9_bits_mshrRetry = '0;
    io_in_9_bits_readProbeDataDown = '0;
    io_in_9_bits_fromL2pft = '0;
    io_in_9_bits_dirty = '0;
    io_in_9_bits_way = '0;
    io_in_9_bits_meta_dirty = '0;
    io_in_9_bits_meta_state = '0;
    io_in_9_bits_meta_clients = '0;
    io_in_9_bits_meta_alias = '0;
    io_in_9_bits_meta_prefetch = '0;
    io_in_9_bits_meta_prefetchSrc = '0;
    io_in_9_bits_meta_accessed = '0;
    io_in_9_bits_meta_tagErr = '0;
    io_in_9_bits_meta_dataErr = '0;
    io_in_9_bits_metaWen = '0;
    io_in_9_bits_tagWen = '0;
    io_in_9_bits_dsWen = '0;
    io_in_9_bits_replTask = '0;
    io_in_9_bits_cmoTask = '0;
    io_in_9_bits_reqSource = '0;
    io_in_9_bits_mergeA = '0;
    io_in_9_bits_aMergeTask_off = '0;
    io_in_9_bits_aMergeTask_alias = '0;
    io_in_9_bits_aMergeTask_vaddr = '0;
    io_in_9_bits_aMergeTask_isKeyword = '0;
    io_in_9_bits_aMergeTask_opcode = '0;
    io_in_9_bits_aMergeTask_param = '0;
    io_in_9_bits_aMergeTask_sourceId = '0;
    io_in_9_bits_aMergeTask_meta_dirty = '0;
    io_in_9_bits_aMergeTask_meta_state = '0;
    io_in_9_bits_aMergeTask_meta_clients = '0;
    io_in_9_bits_aMergeTask_meta_alias = '0;
    io_in_9_bits_aMergeTask_meta_accessed = '0;
    io_in_9_bits_snpHitRelease = '0;
    io_in_9_bits_snpHitReleaseToInval = '0;
    io_in_9_bits_snpHitReleaseToClean = '0;
    io_in_9_bits_snpHitReleaseWithData = '0;
    io_in_9_bits_snpHitReleaseIdx = '0;
    io_in_9_bits_snpHitReleaseMeta_dirty = '0;
    io_in_9_bits_snpHitReleaseMeta_state = '0;
    io_in_9_bits_snpHitReleaseMeta_clients = '0;
    io_in_9_bits_snpHitReleaseMeta_alias = '0;
    io_in_9_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_9_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_9_bits_snpHitReleaseMeta_accessed = '0;
    io_in_9_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_9_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_9_bits_tgtID = '0;
    io_in_9_bits_txnID = '0;
    io_in_9_bits_homeNID = '0;
    io_in_9_bits_dbID = '0;
    io_in_9_bits_chiOpcode = '0;
    io_in_9_bits_resp = '0;
    io_in_9_bits_fwdState = '0;
    io_in_9_bits_retToSrc = '0;
    io_in_9_bits_likelyshared = '0;
    io_in_9_bits_expCompAck = '0;
    io_in_9_bits_allowRetry = '0;
    io_in_9_bits_memAttr_allocate = '0;
    io_in_9_bits_memAttr_cacheable = '0;
    io_in_9_bits_memAttr_ewa = '0;
    io_in_9_bits_traceTag = '0;
    io_in_9_bits_dataCheckErr = '0;
    io_in_10_valid = '0;
    io_in_10_bits_channel = '0;
    io_in_10_bits_txChannel = '0;
    io_in_10_bits_set = '0;
    io_in_10_bits_tag = '0;
    io_in_10_bits_off = '0;
    io_in_10_bits_alias = '0;
    io_in_10_bits_isKeyword = '0;
    io_in_10_bits_opcode = '0;
    io_in_10_bits_param = '0;
    io_in_10_bits_size = '0;
    io_in_10_bits_sourceId = '0;
    io_in_10_bits_denied = '0;
    io_in_10_bits_corrupt = '0;
    io_in_10_bits_mshrId = '0;
    io_in_10_bits_aliasTask = '0;
    io_in_10_bits_useProbeData = '0;
    io_in_10_bits_mshrRetry = '0;
    io_in_10_bits_readProbeDataDown = '0;
    io_in_10_bits_fromL2pft = '0;
    io_in_10_bits_dirty = '0;
    io_in_10_bits_way = '0;
    io_in_10_bits_meta_dirty = '0;
    io_in_10_bits_meta_state = '0;
    io_in_10_bits_meta_clients = '0;
    io_in_10_bits_meta_alias = '0;
    io_in_10_bits_meta_prefetch = '0;
    io_in_10_bits_meta_prefetchSrc = '0;
    io_in_10_bits_meta_accessed = '0;
    io_in_10_bits_meta_tagErr = '0;
    io_in_10_bits_meta_dataErr = '0;
    io_in_10_bits_metaWen = '0;
    io_in_10_bits_tagWen = '0;
    io_in_10_bits_dsWen = '0;
    io_in_10_bits_replTask = '0;
    io_in_10_bits_cmoTask = '0;
    io_in_10_bits_reqSource = '0;
    io_in_10_bits_mergeA = '0;
    io_in_10_bits_aMergeTask_off = '0;
    io_in_10_bits_aMergeTask_alias = '0;
    io_in_10_bits_aMergeTask_vaddr = '0;
    io_in_10_bits_aMergeTask_isKeyword = '0;
    io_in_10_bits_aMergeTask_opcode = '0;
    io_in_10_bits_aMergeTask_param = '0;
    io_in_10_bits_aMergeTask_sourceId = '0;
    io_in_10_bits_aMergeTask_meta_dirty = '0;
    io_in_10_bits_aMergeTask_meta_state = '0;
    io_in_10_bits_aMergeTask_meta_clients = '0;
    io_in_10_bits_aMergeTask_meta_alias = '0;
    io_in_10_bits_aMergeTask_meta_accessed = '0;
    io_in_10_bits_snpHitRelease = '0;
    io_in_10_bits_snpHitReleaseToInval = '0;
    io_in_10_bits_snpHitReleaseToClean = '0;
    io_in_10_bits_snpHitReleaseWithData = '0;
    io_in_10_bits_snpHitReleaseIdx = '0;
    io_in_10_bits_snpHitReleaseMeta_dirty = '0;
    io_in_10_bits_snpHitReleaseMeta_state = '0;
    io_in_10_bits_snpHitReleaseMeta_clients = '0;
    io_in_10_bits_snpHitReleaseMeta_alias = '0;
    io_in_10_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_10_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_10_bits_snpHitReleaseMeta_accessed = '0;
    io_in_10_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_10_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_10_bits_tgtID = '0;
    io_in_10_bits_txnID = '0;
    io_in_10_bits_homeNID = '0;
    io_in_10_bits_dbID = '0;
    io_in_10_bits_chiOpcode = '0;
    io_in_10_bits_resp = '0;
    io_in_10_bits_fwdState = '0;
    io_in_10_bits_retToSrc = '0;
    io_in_10_bits_likelyshared = '0;
    io_in_10_bits_expCompAck = '0;
    io_in_10_bits_allowRetry = '0;
    io_in_10_bits_memAttr_allocate = '0;
    io_in_10_bits_memAttr_cacheable = '0;
    io_in_10_bits_memAttr_ewa = '0;
    io_in_10_bits_traceTag = '0;
    io_in_10_bits_dataCheckErr = '0;
    io_in_11_valid = '0;
    io_in_11_bits_channel = '0;
    io_in_11_bits_txChannel = '0;
    io_in_11_bits_set = '0;
    io_in_11_bits_tag = '0;
    io_in_11_bits_off = '0;
    io_in_11_bits_alias = '0;
    io_in_11_bits_isKeyword = '0;
    io_in_11_bits_opcode = '0;
    io_in_11_bits_param = '0;
    io_in_11_bits_size = '0;
    io_in_11_bits_sourceId = '0;
    io_in_11_bits_denied = '0;
    io_in_11_bits_corrupt = '0;
    io_in_11_bits_mshrId = '0;
    io_in_11_bits_aliasTask = '0;
    io_in_11_bits_useProbeData = '0;
    io_in_11_bits_mshrRetry = '0;
    io_in_11_bits_readProbeDataDown = '0;
    io_in_11_bits_fromL2pft = '0;
    io_in_11_bits_dirty = '0;
    io_in_11_bits_way = '0;
    io_in_11_bits_meta_dirty = '0;
    io_in_11_bits_meta_state = '0;
    io_in_11_bits_meta_clients = '0;
    io_in_11_bits_meta_alias = '0;
    io_in_11_bits_meta_prefetch = '0;
    io_in_11_bits_meta_prefetchSrc = '0;
    io_in_11_bits_meta_accessed = '0;
    io_in_11_bits_meta_tagErr = '0;
    io_in_11_bits_meta_dataErr = '0;
    io_in_11_bits_metaWen = '0;
    io_in_11_bits_tagWen = '0;
    io_in_11_bits_dsWen = '0;
    io_in_11_bits_replTask = '0;
    io_in_11_bits_cmoTask = '0;
    io_in_11_bits_reqSource = '0;
    io_in_11_bits_mergeA = '0;
    io_in_11_bits_aMergeTask_off = '0;
    io_in_11_bits_aMergeTask_alias = '0;
    io_in_11_bits_aMergeTask_vaddr = '0;
    io_in_11_bits_aMergeTask_isKeyword = '0;
    io_in_11_bits_aMergeTask_opcode = '0;
    io_in_11_bits_aMergeTask_param = '0;
    io_in_11_bits_aMergeTask_sourceId = '0;
    io_in_11_bits_aMergeTask_meta_dirty = '0;
    io_in_11_bits_aMergeTask_meta_state = '0;
    io_in_11_bits_aMergeTask_meta_clients = '0;
    io_in_11_bits_aMergeTask_meta_alias = '0;
    io_in_11_bits_aMergeTask_meta_accessed = '0;
    io_in_11_bits_snpHitRelease = '0;
    io_in_11_bits_snpHitReleaseToInval = '0;
    io_in_11_bits_snpHitReleaseToClean = '0;
    io_in_11_bits_snpHitReleaseWithData = '0;
    io_in_11_bits_snpHitReleaseIdx = '0;
    io_in_11_bits_snpHitReleaseMeta_dirty = '0;
    io_in_11_bits_snpHitReleaseMeta_state = '0;
    io_in_11_bits_snpHitReleaseMeta_clients = '0;
    io_in_11_bits_snpHitReleaseMeta_alias = '0;
    io_in_11_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_11_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_11_bits_snpHitReleaseMeta_accessed = '0;
    io_in_11_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_11_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_11_bits_tgtID = '0;
    io_in_11_bits_txnID = '0;
    io_in_11_bits_homeNID = '0;
    io_in_11_bits_dbID = '0;
    io_in_11_bits_chiOpcode = '0;
    io_in_11_bits_resp = '0;
    io_in_11_bits_fwdState = '0;
    io_in_11_bits_retToSrc = '0;
    io_in_11_bits_likelyshared = '0;
    io_in_11_bits_expCompAck = '0;
    io_in_11_bits_allowRetry = '0;
    io_in_11_bits_memAttr_allocate = '0;
    io_in_11_bits_memAttr_cacheable = '0;
    io_in_11_bits_memAttr_ewa = '0;
    io_in_11_bits_traceTag = '0;
    io_in_11_bits_dataCheckErr = '0;
    io_in_12_valid = '0;
    io_in_12_bits_channel = '0;
    io_in_12_bits_txChannel = '0;
    io_in_12_bits_set = '0;
    io_in_12_bits_tag = '0;
    io_in_12_bits_off = '0;
    io_in_12_bits_alias = '0;
    io_in_12_bits_isKeyword = '0;
    io_in_12_bits_opcode = '0;
    io_in_12_bits_param = '0;
    io_in_12_bits_size = '0;
    io_in_12_bits_sourceId = '0;
    io_in_12_bits_denied = '0;
    io_in_12_bits_corrupt = '0;
    io_in_12_bits_mshrId = '0;
    io_in_12_bits_aliasTask = '0;
    io_in_12_bits_useProbeData = '0;
    io_in_12_bits_mshrRetry = '0;
    io_in_12_bits_readProbeDataDown = '0;
    io_in_12_bits_fromL2pft = '0;
    io_in_12_bits_dirty = '0;
    io_in_12_bits_way = '0;
    io_in_12_bits_meta_dirty = '0;
    io_in_12_bits_meta_state = '0;
    io_in_12_bits_meta_clients = '0;
    io_in_12_bits_meta_alias = '0;
    io_in_12_bits_meta_prefetch = '0;
    io_in_12_bits_meta_prefetchSrc = '0;
    io_in_12_bits_meta_accessed = '0;
    io_in_12_bits_meta_tagErr = '0;
    io_in_12_bits_meta_dataErr = '0;
    io_in_12_bits_metaWen = '0;
    io_in_12_bits_tagWen = '0;
    io_in_12_bits_dsWen = '0;
    io_in_12_bits_replTask = '0;
    io_in_12_bits_cmoTask = '0;
    io_in_12_bits_reqSource = '0;
    io_in_12_bits_mergeA = '0;
    io_in_12_bits_aMergeTask_off = '0;
    io_in_12_bits_aMergeTask_alias = '0;
    io_in_12_bits_aMergeTask_vaddr = '0;
    io_in_12_bits_aMergeTask_isKeyword = '0;
    io_in_12_bits_aMergeTask_opcode = '0;
    io_in_12_bits_aMergeTask_param = '0;
    io_in_12_bits_aMergeTask_sourceId = '0;
    io_in_12_bits_aMergeTask_meta_dirty = '0;
    io_in_12_bits_aMergeTask_meta_state = '0;
    io_in_12_bits_aMergeTask_meta_clients = '0;
    io_in_12_bits_aMergeTask_meta_alias = '0;
    io_in_12_bits_aMergeTask_meta_accessed = '0;
    io_in_12_bits_snpHitRelease = '0;
    io_in_12_bits_snpHitReleaseToInval = '0;
    io_in_12_bits_snpHitReleaseToClean = '0;
    io_in_12_bits_snpHitReleaseWithData = '0;
    io_in_12_bits_snpHitReleaseIdx = '0;
    io_in_12_bits_snpHitReleaseMeta_dirty = '0;
    io_in_12_bits_snpHitReleaseMeta_state = '0;
    io_in_12_bits_snpHitReleaseMeta_clients = '0;
    io_in_12_bits_snpHitReleaseMeta_alias = '0;
    io_in_12_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_12_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_12_bits_snpHitReleaseMeta_accessed = '0;
    io_in_12_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_12_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_12_bits_tgtID = '0;
    io_in_12_bits_txnID = '0;
    io_in_12_bits_homeNID = '0;
    io_in_12_bits_dbID = '0;
    io_in_12_bits_chiOpcode = '0;
    io_in_12_bits_resp = '0;
    io_in_12_bits_fwdState = '0;
    io_in_12_bits_retToSrc = '0;
    io_in_12_bits_likelyshared = '0;
    io_in_12_bits_expCompAck = '0;
    io_in_12_bits_allowRetry = '0;
    io_in_12_bits_memAttr_allocate = '0;
    io_in_12_bits_memAttr_cacheable = '0;
    io_in_12_bits_memAttr_ewa = '0;
    io_in_12_bits_traceTag = '0;
    io_in_12_bits_dataCheckErr = '0;
    io_in_13_valid = '0;
    io_in_13_bits_channel = '0;
    io_in_13_bits_txChannel = '0;
    io_in_13_bits_set = '0;
    io_in_13_bits_tag = '0;
    io_in_13_bits_off = '0;
    io_in_13_bits_alias = '0;
    io_in_13_bits_isKeyword = '0;
    io_in_13_bits_opcode = '0;
    io_in_13_bits_param = '0;
    io_in_13_bits_size = '0;
    io_in_13_bits_sourceId = '0;
    io_in_13_bits_denied = '0;
    io_in_13_bits_corrupt = '0;
    io_in_13_bits_mshrId = '0;
    io_in_13_bits_aliasTask = '0;
    io_in_13_bits_useProbeData = '0;
    io_in_13_bits_mshrRetry = '0;
    io_in_13_bits_readProbeDataDown = '0;
    io_in_13_bits_fromL2pft = '0;
    io_in_13_bits_dirty = '0;
    io_in_13_bits_way = '0;
    io_in_13_bits_meta_dirty = '0;
    io_in_13_bits_meta_state = '0;
    io_in_13_bits_meta_clients = '0;
    io_in_13_bits_meta_alias = '0;
    io_in_13_bits_meta_prefetch = '0;
    io_in_13_bits_meta_prefetchSrc = '0;
    io_in_13_bits_meta_accessed = '0;
    io_in_13_bits_meta_tagErr = '0;
    io_in_13_bits_meta_dataErr = '0;
    io_in_13_bits_metaWen = '0;
    io_in_13_bits_tagWen = '0;
    io_in_13_bits_dsWen = '0;
    io_in_13_bits_replTask = '0;
    io_in_13_bits_cmoTask = '0;
    io_in_13_bits_reqSource = '0;
    io_in_13_bits_mergeA = '0;
    io_in_13_bits_aMergeTask_off = '0;
    io_in_13_bits_aMergeTask_alias = '0;
    io_in_13_bits_aMergeTask_vaddr = '0;
    io_in_13_bits_aMergeTask_isKeyword = '0;
    io_in_13_bits_aMergeTask_opcode = '0;
    io_in_13_bits_aMergeTask_param = '0;
    io_in_13_bits_aMergeTask_sourceId = '0;
    io_in_13_bits_aMergeTask_meta_dirty = '0;
    io_in_13_bits_aMergeTask_meta_state = '0;
    io_in_13_bits_aMergeTask_meta_clients = '0;
    io_in_13_bits_aMergeTask_meta_alias = '0;
    io_in_13_bits_aMergeTask_meta_accessed = '0;
    io_in_13_bits_snpHitRelease = '0;
    io_in_13_bits_snpHitReleaseToInval = '0;
    io_in_13_bits_snpHitReleaseToClean = '0;
    io_in_13_bits_snpHitReleaseWithData = '0;
    io_in_13_bits_snpHitReleaseIdx = '0;
    io_in_13_bits_snpHitReleaseMeta_dirty = '0;
    io_in_13_bits_snpHitReleaseMeta_state = '0;
    io_in_13_bits_snpHitReleaseMeta_clients = '0;
    io_in_13_bits_snpHitReleaseMeta_alias = '0;
    io_in_13_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_13_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_13_bits_snpHitReleaseMeta_accessed = '0;
    io_in_13_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_13_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_13_bits_tgtID = '0;
    io_in_13_bits_txnID = '0;
    io_in_13_bits_homeNID = '0;
    io_in_13_bits_dbID = '0;
    io_in_13_bits_chiOpcode = '0;
    io_in_13_bits_resp = '0;
    io_in_13_bits_fwdState = '0;
    io_in_13_bits_retToSrc = '0;
    io_in_13_bits_likelyshared = '0;
    io_in_13_bits_expCompAck = '0;
    io_in_13_bits_allowRetry = '0;
    io_in_13_bits_memAttr_allocate = '0;
    io_in_13_bits_memAttr_cacheable = '0;
    io_in_13_bits_memAttr_ewa = '0;
    io_in_13_bits_traceTag = '0;
    io_in_13_bits_dataCheckErr = '0;
    io_in_14_valid = '0;
    io_in_14_bits_channel = '0;
    io_in_14_bits_txChannel = '0;
    io_in_14_bits_set = '0;
    io_in_14_bits_tag = '0;
    io_in_14_bits_off = '0;
    io_in_14_bits_alias = '0;
    io_in_14_bits_isKeyword = '0;
    io_in_14_bits_opcode = '0;
    io_in_14_bits_param = '0;
    io_in_14_bits_size = '0;
    io_in_14_bits_sourceId = '0;
    io_in_14_bits_denied = '0;
    io_in_14_bits_corrupt = '0;
    io_in_14_bits_mshrId = '0;
    io_in_14_bits_aliasTask = '0;
    io_in_14_bits_useProbeData = '0;
    io_in_14_bits_mshrRetry = '0;
    io_in_14_bits_readProbeDataDown = '0;
    io_in_14_bits_fromL2pft = '0;
    io_in_14_bits_dirty = '0;
    io_in_14_bits_way = '0;
    io_in_14_bits_meta_dirty = '0;
    io_in_14_bits_meta_state = '0;
    io_in_14_bits_meta_clients = '0;
    io_in_14_bits_meta_alias = '0;
    io_in_14_bits_meta_prefetch = '0;
    io_in_14_bits_meta_prefetchSrc = '0;
    io_in_14_bits_meta_accessed = '0;
    io_in_14_bits_meta_tagErr = '0;
    io_in_14_bits_meta_dataErr = '0;
    io_in_14_bits_metaWen = '0;
    io_in_14_bits_tagWen = '0;
    io_in_14_bits_dsWen = '0;
    io_in_14_bits_replTask = '0;
    io_in_14_bits_cmoTask = '0;
    io_in_14_bits_reqSource = '0;
    io_in_14_bits_mergeA = '0;
    io_in_14_bits_aMergeTask_off = '0;
    io_in_14_bits_aMergeTask_alias = '0;
    io_in_14_bits_aMergeTask_vaddr = '0;
    io_in_14_bits_aMergeTask_isKeyword = '0;
    io_in_14_bits_aMergeTask_opcode = '0;
    io_in_14_bits_aMergeTask_param = '0;
    io_in_14_bits_aMergeTask_sourceId = '0;
    io_in_14_bits_aMergeTask_meta_dirty = '0;
    io_in_14_bits_aMergeTask_meta_state = '0;
    io_in_14_bits_aMergeTask_meta_clients = '0;
    io_in_14_bits_aMergeTask_meta_alias = '0;
    io_in_14_bits_aMergeTask_meta_accessed = '0;
    io_in_14_bits_snpHitRelease = '0;
    io_in_14_bits_snpHitReleaseToInval = '0;
    io_in_14_bits_snpHitReleaseToClean = '0;
    io_in_14_bits_snpHitReleaseWithData = '0;
    io_in_14_bits_snpHitReleaseIdx = '0;
    io_in_14_bits_snpHitReleaseMeta_dirty = '0;
    io_in_14_bits_snpHitReleaseMeta_state = '0;
    io_in_14_bits_snpHitReleaseMeta_clients = '0;
    io_in_14_bits_snpHitReleaseMeta_alias = '0;
    io_in_14_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_14_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_14_bits_snpHitReleaseMeta_accessed = '0;
    io_in_14_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_14_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_14_bits_tgtID = '0;
    io_in_14_bits_txnID = '0;
    io_in_14_bits_homeNID = '0;
    io_in_14_bits_dbID = '0;
    io_in_14_bits_chiOpcode = '0;
    io_in_14_bits_resp = '0;
    io_in_14_bits_fwdState = '0;
    io_in_14_bits_retToSrc = '0;
    io_in_14_bits_likelyshared = '0;
    io_in_14_bits_expCompAck = '0;
    io_in_14_bits_allowRetry = '0;
    io_in_14_bits_memAttr_allocate = '0;
    io_in_14_bits_memAttr_cacheable = '0;
    io_in_14_bits_memAttr_ewa = '0;
    io_in_14_bits_traceTag = '0;
    io_in_14_bits_dataCheckErr = '0;
    io_in_15_valid = '0;
    io_in_15_bits_channel = '0;
    io_in_15_bits_txChannel = '0;
    io_in_15_bits_set = '0;
    io_in_15_bits_tag = '0;
    io_in_15_bits_off = '0;
    io_in_15_bits_alias = '0;
    io_in_15_bits_isKeyword = '0;
    io_in_15_bits_opcode = '0;
    io_in_15_bits_param = '0;
    io_in_15_bits_size = '0;
    io_in_15_bits_sourceId = '0;
    io_in_15_bits_denied = '0;
    io_in_15_bits_corrupt = '0;
    io_in_15_bits_mshrId = '0;
    io_in_15_bits_aliasTask = '0;
    io_in_15_bits_useProbeData = '0;
    io_in_15_bits_mshrRetry = '0;
    io_in_15_bits_readProbeDataDown = '0;
    io_in_15_bits_fromL2pft = '0;
    io_in_15_bits_dirty = '0;
    io_in_15_bits_way = '0;
    io_in_15_bits_meta_dirty = '0;
    io_in_15_bits_meta_state = '0;
    io_in_15_bits_meta_clients = '0;
    io_in_15_bits_meta_alias = '0;
    io_in_15_bits_meta_prefetch = '0;
    io_in_15_bits_meta_prefetchSrc = '0;
    io_in_15_bits_meta_accessed = '0;
    io_in_15_bits_meta_tagErr = '0;
    io_in_15_bits_meta_dataErr = '0;
    io_in_15_bits_metaWen = '0;
    io_in_15_bits_tagWen = '0;
    io_in_15_bits_dsWen = '0;
    io_in_15_bits_replTask = '0;
    io_in_15_bits_cmoTask = '0;
    io_in_15_bits_reqSource = '0;
    io_in_15_bits_mergeA = '0;
    io_in_15_bits_aMergeTask_off = '0;
    io_in_15_bits_aMergeTask_alias = '0;
    io_in_15_bits_aMergeTask_vaddr = '0;
    io_in_15_bits_aMergeTask_isKeyword = '0;
    io_in_15_bits_aMergeTask_opcode = '0;
    io_in_15_bits_aMergeTask_param = '0;
    io_in_15_bits_aMergeTask_sourceId = '0;
    io_in_15_bits_aMergeTask_meta_dirty = '0;
    io_in_15_bits_aMergeTask_meta_state = '0;
    io_in_15_bits_aMergeTask_meta_clients = '0;
    io_in_15_bits_aMergeTask_meta_alias = '0;
    io_in_15_bits_aMergeTask_meta_accessed = '0;
    io_in_15_bits_snpHitRelease = '0;
    io_in_15_bits_snpHitReleaseToInval = '0;
    io_in_15_bits_snpHitReleaseToClean = '0;
    io_in_15_bits_snpHitReleaseWithData = '0;
    io_in_15_bits_snpHitReleaseIdx = '0;
    io_in_15_bits_snpHitReleaseMeta_dirty = '0;
    io_in_15_bits_snpHitReleaseMeta_state = '0;
    io_in_15_bits_snpHitReleaseMeta_clients = '0;
    io_in_15_bits_snpHitReleaseMeta_alias = '0;
    io_in_15_bits_snpHitReleaseMeta_prefetch = '0;
    io_in_15_bits_snpHitReleaseMeta_prefetchSrc = '0;
    io_in_15_bits_snpHitReleaseMeta_accessed = '0;
    io_in_15_bits_snpHitReleaseMeta_tagErr = '0;
    io_in_15_bits_snpHitReleaseMeta_dataErr = '0;
    io_in_15_bits_tgtID = '0;
    io_in_15_bits_txnID = '0;
    io_in_15_bits_homeNID = '0;
    io_in_15_bits_dbID = '0;
    io_in_15_bits_chiOpcode = '0;
    io_in_15_bits_resp = '0;
    io_in_15_bits_fwdState = '0;
    io_in_15_bits_retToSrc = '0;
    io_in_15_bits_likelyshared = '0;
    io_in_15_bits_expCompAck = '0;
    io_in_15_bits_allowRetry = '0;
    io_in_15_bits_memAttr_allocate = '0;
    io_in_15_bits_memAttr_cacheable = '0;
    io_in_15_bits_memAttr_ewa = '0;
    io_in_15_bits_traceTag = '0;
    io_in_15_bits_dataCheckErr = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_8 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
