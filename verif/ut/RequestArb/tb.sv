// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：RequestArb
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= RequestArb =======================
  logic RequestArb__io_sinkA_valid;
  logic [2:0] RequestArb__io_sinkA_bits_channel;
  logic [2:0] RequestArb__io_sinkA_bits_txChannel;
  logic [8:0] RequestArb__io_sinkA_bits_set;
  logic [30:0] RequestArb__io_sinkA_bits_tag;
  logic [5:0] RequestArb__io_sinkA_bits_off;
  logic [1:0] RequestArb__io_sinkA_bits_alias;
  logic [43:0] RequestArb__io_sinkA_bits_vaddr;
  logic RequestArb__io_sinkA_bits_isKeyword;
  logic [3:0] RequestArb__io_sinkA_bits_opcode;
  logic [2:0] RequestArb__io_sinkA_bits_param;
  logic [2:0] RequestArb__io_sinkA_bits_size;
  logic [6:0] RequestArb__io_sinkA_bits_sourceId;
  logic [1:0] RequestArb__io_sinkA_bits_bufIdx;
  logic RequestArb__io_sinkA_bits_needProbeAckData;
  logic RequestArb__io_sinkA_bits_denied;
  logic RequestArb__io_sinkA_bits_corrupt;
  logic RequestArb__io_sinkA_bits_mshrTask;
  logic [7:0] RequestArb__io_sinkA_bits_mshrId;
  logic RequestArb__io_sinkA_bits_aliasTask;
  logic RequestArb__io_sinkA_bits_useProbeData;
  logic RequestArb__io_sinkA_bits_mshrRetry;
  logic RequestArb__io_sinkA_bits_readProbeDataDown;
  logic RequestArb__io_sinkA_bits_fromL2pft;
  logic RequestArb__io_sinkA_bits_needHint;
  logic RequestArb__io_sinkA_bits_dirty;
  logic [2:0] RequestArb__io_sinkA_bits_way;
  logic RequestArb__io_sinkA_bits_meta_dirty;
  logic [1:0] RequestArb__io_sinkA_bits_meta_state;
  logic RequestArb__io_sinkA_bits_meta_clients;
  logic [1:0] RequestArb__io_sinkA_bits_meta_alias;
  logic RequestArb__io_sinkA_bits_meta_prefetch;
  logic [2:0] RequestArb__io_sinkA_bits_meta_prefetchSrc;
  logic RequestArb__io_sinkA_bits_meta_accessed;
  logic RequestArb__io_sinkA_bits_meta_tagErr;
  logic RequestArb__io_sinkA_bits_meta_dataErr;
  logic RequestArb__io_sinkA_bits_metaWen;
  logic RequestArb__io_sinkA_bits_tagWen;
  logic RequestArb__io_sinkA_bits_dsWen;
  logic [7:0] RequestArb__io_sinkA_bits_wayMask;
  logic RequestArb__io_sinkA_bits_replTask;
  logic RequestArb__io_sinkA_bits_cmoTask;
  logic RequestArb__io_sinkA_bits_cmoAll;
  logic [4:0] RequestArb__io_sinkA_bits_reqSource;
  logic RequestArb__io_sinkA_bits_mergeA;
  logic [5:0] RequestArb__io_sinkA_bits_aMergeTask_off;
  logic [1:0] RequestArb__io_sinkA_bits_aMergeTask_alias;
  logic [43:0] RequestArb__io_sinkA_bits_aMergeTask_vaddr;
  logic RequestArb__io_sinkA_bits_aMergeTask_isKeyword;
  logic [2:0] RequestArb__io_sinkA_bits_aMergeTask_opcode;
  logic [2:0] RequestArb__io_sinkA_bits_aMergeTask_param;
  logic [6:0] RequestArb__io_sinkA_bits_aMergeTask_sourceId;
  logic RequestArb__io_sinkA_bits_aMergeTask_meta_dirty;
  logic [1:0] RequestArb__io_sinkA_bits_aMergeTask_meta_state;
  logic RequestArb__io_sinkA_bits_aMergeTask_meta_clients;
  logic [1:0] RequestArb__io_sinkA_bits_aMergeTask_meta_alias;
  logic RequestArb__io_sinkA_bits_aMergeTask_meta_prefetch;
  logic [2:0] RequestArb__io_sinkA_bits_aMergeTask_meta_prefetchSrc;
  logic RequestArb__io_sinkA_bits_aMergeTask_meta_accessed;
  logic RequestArb__io_sinkA_bits_aMergeTask_meta_tagErr;
  logic RequestArb__io_sinkA_bits_aMergeTask_meta_dataErr;
  logic RequestArb__io_sinkA_bits_snpHitRelease;
  logic RequestArb__io_sinkA_bits_snpHitReleaseToInval;
  logic RequestArb__io_sinkA_bits_snpHitReleaseToClean;
  logic RequestArb__io_sinkA_bits_snpHitReleaseWithData;
  logic [7:0] RequestArb__io_sinkA_bits_snpHitReleaseIdx;
  logic RequestArb__io_sinkA_bits_snpHitReleaseMeta_dirty;
  logic [1:0] RequestArb__io_sinkA_bits_snpHitReleaseMeta_state;
  logic RequestArb__io_sinkA_bits_snpHitReleaseMeta_clients;
  logic [1:0] RequestArb__io_sinkA_bits_snpHitReleaseMeta_alias;
  logic RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetchSrc;
  logic RequestArb__io_sinkA_bits_snpHitReleaseMeta_accessed;
  logic RequestArb__io_sinkA_bits_snpHitReleaseMeta_tagErr;
  logic RequestArb__io_sinkA_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] RequestArb__io_sinkA_bits_tgtID;
  logic [10:0] RequestArb__io_sinkA_bits_srcID;
  logic [11:0] RequestArb__io_sinkA_bits_txnID;
  logic [10:0] RequestArb__io_sinkA_bits_homeNID;
  logic [11:0] RequestArb__io_sinkA_bits_dbID;
  logic [10:0] RequestArb__io_sinkA_bits_fwdNID;
  logic [11:0] RequestArb__io_sinkA_bits_fwdTxnID;
  logic [6:0] RequestArb__io_sinkA_bits_chiOpcode;
  logic [2:0] RequestArb__io_sinkA_bits_resp;
  logic [2:0] RequestArb__io_sinkA_bits_fwdState;
  logic [3:0] RequestArb__io_sinkA_bits_pCrdType;
  logic RequestArb__io_sinkA_bits_retToSrc;
  logic RequestArb__io_sinkA_bits_likelyshared;
  logic RequestArb__io_sinkA_bits_expCompAck;
  logic RequestArb__io_sinkA_bits_allowRetry;
  logic RequestArb__io_sinkA_bits_memAttr_allocate;
  logic RequestArb__io_sinkA_bits_memAttr_cacheable;
  logic RequestArb__io_sinkA_bits_memAttr_device;
  logic RequestArb__io_sinkA_bits_memAttr_ewa;
  logic RequestArb__io_sinkA_bits_traceTag;
  logic [30:0] RequestArb__io_ATag;
  logic [8:0] RequestArb__io_ASet;
  logic RequestArb__io_sinkB_valid;
  logic [2:0] RequestArb__io_sinkB_bits_channel;
  logic [2:0] RequestArb__io_sinkB_bits_txChannel;
  logic [8:0] RequestArb__io_sinkB_bits_set;
  logic [30:0] RequestArb__io_sinkB_bits_tag;
  logic [5:0] RequestArb__io_sinkB_bits_off;
  logic [1:0] RequestArb__io_sinkB_bits_alias;
  logic [43:0] RequestArb__io_sinkB_bits_vaddr;
  logic RequestArb__io_sinkB_bits_isKeyword;
  logic [3:0] RequestArb__io_sinkB_bits_opcode;
  logic [2:0] RequestArb__io_sinkB_bits_param;
  logic [2:0] RequestArb__io_sinkB_bits_size;
  logic [6:0] RequestArb__io_sinkB_bits_sourceId;
  logic [1:0] RequestArb__io_sinkB_bits_bufIdx;
  logic RequestArb__io_sinkB_bits_needProbeAckData;
  logic RequestArb__io_sinkB_bits_denied;
  logic RequestArb__io_sinkB_bits_corrupt;
  logic RequestArb__io_sinkB_bits_mshrTask;
  logic [7:0] RequestArb__io_sinkB_bits_mshrId;
  logic RequestArb__io_sinkB_bits_aliasTask;
  logic RequestArb__io_sinkB_bits_useProbeData;
  logic RequestArb__io_sinkB_bits_mshrRetry;
  logic RequestArb__io_sinkB_bits_readProbeDataDown;
  logic RequestArb__io_sinkB_bits_fromL2pft;
  logic RequestArb__io_sinkB_bits_needHint;
  logic RequestArb__io_sinkB_bits_dirty;
  logic [2:0] RequestArb__io_sinkB_bits_way;
  logic RequestArb__io_sinkB_bits_meta_dirty;
  logic [1:0] RequestArb__io_sinkB_bits_meta_state;
  logic RequestArb__io_sinkB_bits_meta_clients;
  logic [1:0] RequestArb__io_sinkB_bits_meta_alias;
  logic RequestArb__io_sinkB_bits_meta_prefetch;
  logic [2:0] RequestArb__io_sinkB_bits_meta_prefetchSrc;
  logic RequestArb__io_sinkB_bits_meta_accessed;
  logic RequestArb__io_sinkB_bits_meta_tagErr;
  logic RequestArb__io_sinkB_bits_meta_dataErr;
  logic RequestArb__io_sinkB_bits_metaWen;
  logic RequestArb__io_sinkB_bits_tagWen;
  logic RequestArb__io_sinkB_bits_dsWen;
  logic [7:0] RequestArb__io_sinkB_bits_wayMask;
  logic RequestArb__io_sinkB_bits_replTask;
  logic RequestArb__io_sinkB_bits_cmoTask;
  logic RequestArb__io_sinkB_bits_cmoAll;
  logic [4:0] RequestArb__io_sinkB_bits_reqSource;
  logic RequestArb__io_sinkB_bits_mergeA;
  logic [5:0] RequestArb__io_sinkB_bits_aMergeTask_off;
  logic [1:0] RequestArb__io_sinkB_bits_aMergeTask_alias;
  logic [43:0] RequestArb__io_sinkB_bits_aMergeTask_vaddr;
  logic RequestArb__io_sinkB_bits_aMergeTask_isKeyword;
  logic [2:0] RequestArb__io_sinkB_bits_aMergeTask_opcode;
  logic [2:0] RequestArb__io_sinkB_bits_aMergeTask_param;
  logic [6:0] RequestArb__io_sinkB_bits_aMergeTask_sourceId;
  logic RequestArb__io_sinkB_bits_aMergeTask_meta_dirty;
  logic [1:0] RequestArb__io_sinkB_bits_aMergeTask_meta_state;
  logic RequestArb__io_sinkB_bits_aMergeTask_meta_clients;
  logic [1:0] RequestArb__io_sinkB_bits_aMergeTask_meta_alias;
  logic RequestArb__io_sinkB_bits_aMergeTask_meta_prefetch;
  logic [2:0] RequestArb__io_sinkB_bits_aMergeTask_meta_prefetchSrc;
  logic RequestArb__io_sinkB_bits_aMergeTask_meta_accessed;
  logic RequestArb__io_sinkB_bits_aMergeTask_meta_tagErr;
  logic RequestArb__io_sinkB_bits_aMergeTask_meta_dataErr;
  logic RequestArb__io_sinkB_bits_snpHitRelease;
  logic RequestArb__io_sinkB_bits_snpHitReleaseToInval;
  logic RequestArb__io_sinkB_bits_snpHitReleaseToClean;
  logic RequestArb__io_sinkB_bits_snpHitReleaseWithData;
  logic [7:0] RequestArb__io_sinkB_bits_snpHitReleaseIdx;
  logic RequestArb__io_sinkB_bits_snpHitReleaseMeta_dirty;
  logic [1:0] RequestArb__io_sinkB_bits_snpHitReleaseMeta_state;
  logic RequestArb__io_sinkB_bits_snpHitReleaseMeta_clients;
  logic [1:0] RequestArb__io_sinkB_bits_snpHitReleaseMeta_alias;
  logic RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetchSrc;
  logic RequestArb__io_sinkB_bits_snpHitReleaseMeta_accessed;
  logic RequestArb__io_sinkB_bits_snpHitReleaseMeta_tagErr;
  logic RequestArb__io_sinkB_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] RequestArb__io_sinkB_bits_tgtID;
  logic [10:0] RequestArb__io_sinkB_bits_srcID;
  logic [11:0] RequestArb__io_sinkB_bits_txnID;
  logic [10:0] RequestArb__io_sinkB_bits_homeNID;
  logic [11:0] RequestArb__io_sinkB_bits_dbID;
  logic [10:0] RequestArb__io_sinkB_bits_fwdNID;
  logic [11:0] RequestArb__io_sinkB_bits_fwdTxnID;
  logic [6:0] RequestArb__io_sinkB_bits_chiOpcode;
  logic [2:0] RequestArb__io_sinkB_bits_resp;
  logic [2:0] RequestArb__io_sinkB_bits_fwdState;
  logic [3:0] RequestArb__io_sinkB_bits_pCrdType;
  logic RequestArb__io_sinkB_bits_retToSrc;
  logic RequestArb__io_sinkB_bits_likelyshared;
  logic RequestArb__io_sinkB_bits_expCompAck;
  logic RequestArb__io_sinkB_bits_allowRetry;
  logic RequestArb__io_sinkB_bits_memAttr_allocate;
  logic RequestArb__io_sinkB_bits_memAttr_cacheable;
  logic RequestArb__io_sinkB_bits_memAttr_device;
  logic RequestArb__io_sinkB_bits_memAttr_ewa;
  logic RequestArb__io_sinkB_bits_traceTag;
  logic RequestArb__io_sinkC_valid;
  logic [2:0] RequestArb__io_sinkC_bits_channel;
  logic [2:0] RequestArb__io_sinkC_bits_txChannel;
  logic [8:0] RequestArb__io_sinkC_bits_set;
  logic [30:0] RequestArb__io_sinkC_bits_tag;
  logic [5:0] RequestArb__io_sinkC_bits_off;
  logic [1:0] RequestArb__io_sinkC_bits_alias;
  logic [43:0] RequestArb__io_sinkC_bits_vaddr;
  logic RequestArb__io_sinkC_bits_isKeyword;
  logic [3:0] RequestArb__io_sinkC_bits_opcode;
  logic [2:0] RequestArb__io_sinkC_bits_param;
  logic [2:0] RequestArb__io_sinkC_bits_size;
  logic [6:0] RequestArb__io_sinkC_bits_sourceId;
  logic [1:0] RequestArb__io_sinkC_bits_bufIdx;
  logic RequestArb__io_sinkC_bits_needProbeAckData;
  logic RequestArb__io_sinkC_bits_denied;
  logic RequestArb__io_sinkC_bits_corrupt;
  logic RequestArb__io_sinkC_bits_mshrTask;
  logic [7:0] RequestArb__io_sinkC_bits_mshrId;
  logic RequestArb__io_sinkC_bits_aliasTask;
  logic RequestArb__io_sinkC_bits_useProbeData;
  logic RequestArb__io_sinkC_bits_mshrRetry;
  logic RequestArb__io_sinkC_bits_readProbeDataDown;
  logic RequestArb__io_sinkC_bits_fromL2pft;
  logic RequestArb__io_sinkC_bits_needHint;
  logic RequestArb__io_sinkC_bits_dirty;
  logic [2:0] RequestArb__io_sinkC_bits_way;
  logic RequestArb__io_sinkC_bits_meta_dirty;
  logic [1:0] RequestArb__io_sinkC_bits_meta_state;
  logic RequestArb__io_sinkC_bits_meta_clients;
  logic [1:0] RequestArb__io_sinkC_bits_meta_alias;
  logic RequestArb__io_sinkC_bits_meta_prefetch;
  logic [2:0] RequestArb__io_sinkC_bits_meta_prefetchSrc;
  logic RequestArb__io_sinkC_bits_meta_accessed;
  logic RequestArb__io_sinkC_bits_meta_tagErr;
  logic RequestArb__io_sinkC_bits_meta_dataErr;
  logic RequestArb__io_sinkC_bits_metaWen;
  logic RequestArb__io_sinkC_bits_tagWen;
  logic RequestArb__io_sinkC_bits_dsWen;
  logic [7:0] RequestArb__io_sinkC_bits_wayMask;
  logic RequestArb__io_sinkC_bits_replTask;
  logic RequestArb__io_sinkC_bits_cmoTask;
  logic RequestArb__io_sinkC_bits_cmoAll;
  logic [4:0] RequestArb__io_sinkC_bits_reqSource;
  logic RequestArb__io_sinkC_bits_mergeA;
  logic [5:0] RequestArb__io_sinkC_bits_aMergeTask_off;
  logic [1:0] RequestArb__io_sinkC_bits_aMergeTask_alias;
  logic [43:0] RequestArb__io_sinkC_bits_aMergeTask_vaddr;
  logic RequestArb__io_sinkC_bits_aMergeTask_isKeyword;
  logic [2:0] RequestArb__io_sinkC_bits_aMergeTask_opcode;
  logic [2:0] RequestArb__io_sinkC_bits_aMergeTask_param;
  logic [6:0] RequestArb__io_sinkC_bits_aMergeTask_sourceId;
  logic RequestArb__io_sinkC_bits_aMergeTask_meta_dirty;
  logic [1:0] RequestArb__io_sinkC_bits_aMergeTask_meta_state;
  logic RequestArb__io_sinkC_bits_aMergeTask_meta_clients;
  logic [1:0] RequestArb__io_sinkC_bits_aMergeTask_meta_alias;
  logic RequestArb__io_sinkC_bits_aMergeTask_meta_prefetch;
  logic [2:0] RequestArb__io_sinkC_bits_aMergeTask_meta_prefetchSrc;
  logic RequestArb__io_sinkC_bits_aMergeTask_meta_accessed;
  logic RequestArb__io_sinkC_bits_aMergeTask_meta_tagErr;
  logic RequestArb__io_sinkC_bits_aMergeTask_meta_dataErr;
  logic RequestArb__io_sinkC_bits_snpHitRelease;
  logic RequestArb__io_sinkC_bits_snpHitReleaseToInval;
  logic RequestArb__io_sinkC_bits_snpHitReleaseToClean;
  logic RequestArb__io_sinkC_bits_snpHitReleaseWithData;
  logic [7:0] RequestArb__io_sinkC_bits_snpHitReleaseIdx;
  logic RequestArb__io_sinkC_bits_snpHitReleaseMeta_dirty;
  logic [1:0] RequestArb__io_sinkC_bits_snpHitReleaseMeta_state;
  logic RequestArb__io_sinkC_bits_snpHitReleaseMeta_clients;
  logic [1:0] RequestArb__io_sinkC_bits_snpHitReleaseMeta_alias;
  logic RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetchSrc;
  logic RequestArb__io_sinkC_bits_snpHitReleaseMeta_accessed;
  logic RequestArb__io_sinkC_bits_snpHitReleaseMeta_tagErr;
  logic RequestArb__io_sinkC_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] RequestArb__io_sinkC_bits_tgtID;
  logic [10:0] RequestArb__io_sinkC_bits_srcID;
  logic [11:0] RequestArb__io_sinkC_bits_txnID;
  logic [10:0] RequestArb__io_sinkC_bits_homeNID;
  logic [11:0] RequestArb__io_sinkC_bits_dbID;
  logic [10:0] RequestArb__io_sinkC_bits_fwdNID;
  logic [11:0] RequestArb__io_sinkC_bits_fwdTxnID;
  logic [6:0] RequestArb__io_sinkC_bits_chiOpcode;
  logic [2:0] RequestArb__io_sinkC_bits_resp;
  logic [2:0] RequestArb__io_sinkC_bits_fwdState;
  logic [3:0] RequestArb__io_sinkC_bits_pCrdType;
  logic RequestArb__io_sinkC_bits_retToSrc;
  logic RequestArb__io_sinkC_bits_likelyshared;
  logic RequestArb__io_sinkC_bits_expCompAck;
  logic RequestArb__io_sinkC_bits_allowRetry;
  logic RequestArb__io_sinkC_bits_memAttr_allocate;
  logic RequestArb__io_sinkC_bits_memAttr_cacheable;
  logic RequestArb__io_sinkC_bits_memAttr_device;
  logic RequestArb__io_sinkC_bits_memAttr_ewa;
  logic RequestArb__io_sinkC_bits_traceTag;
  logic RequestArb__io_mshrTask_valid;
  logic [2:0] RequestArb__io_mshrTask_bits_channel;
  logic [2:0] RequestArb__io_mshrTask_bits_txChannel;
  logic [8:0] RequestArb__io_mshrTask_bits_set;
  logic [30:0] RequestArb__io_mshrTask_bits_tag;
  logic [5:0] RequestArb__io_mshrTask_bits_off;
  logic [1:0] RequestArb__io_mshrTask_bits_alias;
  logic [43:0] RequestArb__io_mshrTask_bits_vaddr;
  logic RequestArb__io_mshrTask_bits_isKeyword;
  logic [3:0] RequestArb__io_mshrTask_bits_opcode;
  logic [2:0] RequestArb__io_mshrTask_bits_param;
  logic [2:0] RequestArb__io_mshrTask_bits_size;
  logic [6:0] RequestArb__io_mshrTask_bits_sourceId;
  logic [1:0] RequestArb__io_mshrTask_bits_bufIdx;
  logic RequestArb__io_mshrTask_bits_needProbeAckData;
  logic RequestArb__io_mshrTask_bits_denied;
  logic RequestArb__io_mshrTask_bits_corrupt;
  logic RequestArb__io_mshrTask_bits_mshrTask;
  logic [7:0] RequestArb__io_mshrTask_bits_mshrId;
  logic RequestArb__io_mshrTask_bits_aliasTask;
  logic RequestArb__io_mshrTask_bits_useProbeData;
  logic RequestArb__io_mshrTask_bits_mshrRetry;
  logic RequestArb__io_mshrTask_bits_readProbeDataDown;
  logic RequestArb__io_mshrTask_bits_fromL2pft;
  logic RequestArb__io_mshrTask_bits_needHint;
  logic RequestArb__io_mshrTask_bits_dirty;
  logic [2:0] RequestArb__io_mshrTask_bits_way;
  logic RequestArb__io_mshrTask_bits_meta_dirty;
  logic [1:0] RequestArb__io_mshrTask_bits_meta_state;
  logic RequestArb__io_mshrTask_bits_meta_clients;
  logic [1:0] RequestArb__io_mshrTask_bits_meta_alias;
  logic RequestArb__io_mshrTask_bits_meta_prefetch;
  logic [2:0] RequestArb__io_mshrTask_bits_meta_prefetchSrc;
  logic RequestArb__io_mshrTask_bits_meta_accessed;
  logic RequestArb__io_mshrTask_bits_meta_tagErr;
  logic RequestArb__io_mshrTask_bits_meta_dataErr;
  logic RequestArb__io_mshrTask_bits_metaWen;
  logic RequestArb__io_mshrTask_bits_tagWen;
  logic RequestArb__io_mshrTask_bits_dsWen;
  logic [7:0] RequestArb__io_mshrTask_bits_wayMask;
  logic RequestArb__io_mshrTask_bits_replTask;
  logic RequestArb__io_mshrTask_bits_cmoTask;
  logic RequestArb__io_mshrTask_bits_cmoAll;
  logic [4:0] RequestArb__io_mshrTask_bits_reqSource;
  logic RequestArb__io_mshrTask_bits_mergeA;
  logic [5:0] RequestArb__io_mshrTask_bits_aMergeTask_off;
  logic [1:0] RequestArb__io_mshrTask_bits_aMergeTask_alias;
  logic [43:0] RequestArb__io_mshrTask_bits_aMergeTask_vaddr;
  logic RequestArb__io_mshrTask_bits_aMergeTask_isKeyword;
  logic [2:0] RequestArb__io_mshrTask_bits_aMergeTask_opcode;
  logic [2:0] RequestArb__io_mshrTask_bits_aMergeTask_param;
  logic [6:0] RequestArb__io_mshrTask_bits_aMergeTask_sourceId;
  logic RequestArb__io_mshrTask_bits_aMergeTask_meta_dirty;
  logic [1:0] RequestArb__io_mshrTask_bits_aMergeTask_meta_state;
  logic RequestArb__io_mshrTask_bits_aMergeTask_meta_clients;
  logic [1:0] RequestArb__io_mshrTask_bits_aMergeTask_meta_alias;
  logic RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetch;
  logic [2:0] RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetchSrc;
  logic RequestArb__io_mshrTask_bits_aMergeTask_meta_accessed;
  logic RequestArb__io_mshrTask_bits_aMergeTask_meta_tagErr;
  logic RequestArb__io_mshrTask_bits_aMergeTask_meta_dataErr;
  logic RequestArb__io_mshrTask_bits_snpHitRelease;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseToInval;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseToClean;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseWithData;
  logic [7:0] RequestArb__io_mshrTask_bits_snpHitReleaseIdx;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dirty;
  logic [1:0] RequestArb__io_mshrTask_bits_snpHitReleaseMeta_state;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseMeta_clients;
  logic [1:0] RequestArb__io_mshrTask_bits_snpHitReleaseMeta_alias;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseMeta_accessed;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseMeta_tagErr;
  logic RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] RequestArb__io_mshrTask_bits_tgtID;
  logic [10:0] RequestArb__io_mshrTask_bits_srcID;
  logic [11:0] RequestArb__io_mshrTask_bits_txnID;
  logic [10:0] RequestArb__io_mshrTask_bits_homeNID;
  logic [11:0] RequestArb__io_mshrTask_bits_dbID;
  logic [10:0] RequestArb__io_mshrTask_bits_fwdNID;
  logic [11:0] RequestArb__io_mshrTask_bits_fwdTxnID;
  logic [6:0] RequestArb__io_mshrTask_bits_chiOpcode;
  logic [2:0] RequestArb__io_mshrTask_bits_resp;
  logic [2:0] RequestArb__io_mshrTask_bits_fwdState;
  logic [3:0] RequestArb__io_mshrTask_bits_pCrdType;
  logic RequestArb__io_mshrTask_bits_retToSrc;
  logic RequestArb__io_mshrTask_bits_likelyshared;
  logic RequestArb__io_mshrTask_bits_expCompAck;
  logic RequestArb__io_mshrTask_bits_allowRetry;
  logic RequestArb__io_mshrTask_bits_memAttr_allocate;
  logic RequestArb__io_mshrTask_bits_memAttr_cacheable;
  logic RequestArb__io_mshrTask_bits_memAttr_device;
  logic RequestArb__io_mshrTask_bits_memAttr_ewa;
  logic RequestArb__io_mshrTask_bits_traceTag;
  logic RequestArb__io_dirRead_s1_ready;
  logic RequestArb__io_fromMSHRCtl_blockG_s1;
  logic RequestArb__io_fromMSHRCtl_blockA_s1;
  logic RequestArb__io_fromMSHRCtl_blockB_s1;
  logic RequestArb__io_fromMSHRCtl_blockC_s1;
  logic RequestArb__io_fromMainPipe_blockG_s1;
  logic RequestArb__io_fromMainPipe_blockA_s1;
  logic RequestArb__io_fromMainPipe_blockB_s1;
  logic RequestArb__io_fromMainPipe_blockC_s1;
  logic RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1;
  logic RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1;
  logic RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1;
  logic RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1;
  logic RequestArb__io_fromGrantBuffer_blockMSHRReqEntrance;
  logic RequestArb__io_fromTXDAT_blockMSHRReqEntrance;
  logic RequestArb__io_fromTXDAT_blockSinkBReqEntrance;
  logic RequestArb__io_fromTXRSP_blockMSHRReqEntrance;
  logic RequestArb__io_fromTXRSP_blockSinkBReqEntrance;
  logic RequestArb__io_fromTXREQ_blockMSHRReqEntrance;
  logic RequestArb__io_msInfo_0_valid;
  logic [2:0] RequestArb__io_msInfo_0_bits_channel;
  logic [8:0] RequestArb__io_msInfo_0_bits_set;
  logic [2:0] RequestArb__io_msInfo_0_bits_way;
  logic [30:0] RequestArb__io_msInfo_0_bits_reqTag;
  logic RequestArb__io_msInfo_0_bits_willFree;
  logic RequestArb__io_msInfo_0_bits_aliasTask;
  logic RequestArb__io_msInfo_0_bits_needRelease;
  logic RequestArb__io_msInfo_0_bits_blockRefill;
  logic RequestArb__io_msInfo_0_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_0_bits_meta_state;
  logic RequestArb__io_msInfo_0_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_0_bits_meta_alias;
  logic RequestArb__io_msInfo_0_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_0_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_0_bits_meta_accessed;
  logic RequestArb__io_msInfo_0_bits_meta_tagErr;
  logic RequestArb__io_msInfo_0_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_0_bits_metaTag;
  logic RequestArb__io_msInfo_0_bits_dirHit;
  logic RequestArb__io_msInfo_0_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_0_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_0_bits_param;
  logic RequestArb__io_msInfo_0_bits_mergeA;
  logic RequestArb__io_msInfo_0_bits_w_grantfirst;
  logic RequestArb__io_msInfo_0_bits_s_release;
  logic RequestArb__io_msInfo_0_bits_s_refill;
  logic RequestArb__io_msInfo_0_bits_s_cmoresp;
  logic RequestArb__io_msInfo_0_bits_s_cmometaw;
  logic RequestArb__io_msInfo_0_bits_w_releaseack;
  logic RequestArb__io_msInfo_0_bits_w_replResp;
  logic RequestArb__io_msInfo_0_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_0_bits_replaceData;
  logic RequestArb__io_msInfo_0_bits_releaseToClean;
  logic RequestArb__io_msInfo_1_valid;
  logic [2:0] RequestArb__io_msInfo_1_bits_channel;
  logic [8:0] RequestArb__io_msInfo_1_bits_set;
  logic [2:0] RequestArb__io_msInfo_1_bits_way;
  logic [30:0] RequestArb__io_msInfo_1_bits_reqTag;
  logic RequestArb__io_msInfo_1_bits_willFree;
  logic RequestArb__io_msInfo_1_bits_aliasTask;
  logic RequestArb__io_msInfo_1_bits_needRelease;
  logic RequestArb__io_msInfo_1_bits_blockRefill;
  logic RequestArb__io_msInfo_1_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_1_bits_meta_state;
  logic RequestArb__io_msInfo_1_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_1_bits_meta_alias;
  logic RequestArb__io_msInfo_1_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_1_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_1_bits_meta_accessed;
  logic RequestArb__io_msInfo_1_bits_meta_tagErr;
  logic RequestArb__io_msInfo_1_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_1_bits_metaTag;
  logic RequestArb__io_msInfo_1_bits_dirHit;
  logic RequestArb__io_msInfo_1_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_1_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_1_bits_param;
  logic RequestArb__io_msInfo_1_bits_mergeA;
  logic RequestArb__io_msInfo_1_bits_w_grantfirst;
  logic RequestArb__io_msInfo_1_bits_s_release;
  logic RequestArb__io_msInfo_1_bits_s_refill;
  logic RequestArb__io_msInfo_1_bits_s_cmoresp;
  logic RequestArb__io_msInfo_1_bits_s_cmometaw;
  logic RequestArb__io_msInfo_1_bits_w_releaseack;
  logic RequestArb__io_msInfo_1_bits_w_replResp;
  logic RequestArb__io_msInfo_1_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_1_bits_replaceData;
  logic RequestArb__io_msInfo_1_bits_releaseToClean;
  logic RequestArb__io_msInfo_2_valid;
  logic [2:0] RequestArb__io_msInfo_2_bits_channel;
  logic [8:0] RequestArb__io_msInfo_2_bits_set;
  logic [2:0] RequestArb__io_msInfo_2_bits_way;
  logic [30:0] RequestArb__io_msInfo_2_bits_reqTag;
  logic RequestArb__io_msInfo_2_bits_willFree;
  logic RequestArb__io_msInfo_2_bits_aliasTask;
  logic RequestArb__io_msInfo_2_bits_needRelease;
  logic RequestArb__io_msInfo_2_bits_blockRefill;
  logic RequestArb__io_msInfo_2_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_2_bits_meta_state;
  logic RequestArb__io_msInfo_2_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_2_bits_meta_alias;
  logic RequestArb__io_msInfo_2_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_2_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_2_bits_meta_accessed;
  logic RequestArb__io_msInfo_2_bits_meta_tagErr;
  logic RequestArb__io_msInfo_2_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_2_bits_metaTag;
  logic RequestArb__io_msInfo_2_bits_dirHit;
  logic RequestArb__io_msInfo_2_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_2_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_2_bits_param;
  logic RequestArb__io_msInfo_2_bits_mergeA;
  logic RequestArb__io_msInfo_2_bits_w_grantfirst;
  logic RequestArb__io_msInfo_2_bits_s_release;
  logic RequestArb__io_msInfo_2_bits_s_refill;
  logic RequestArb__io_msInfo_2_bits_s_cmoresp;
  logic RequestArb__io_msInfo_2_bits_s_cmometaw;
  logic RequestArb__io_msInfo_2_bits_w_releaseack;
  logic RequestArb__io_msInfo_2_bits_w_replResp;
  logic RequestArb__io_msInfo_2_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_2_bits_replaceData;
  logic RequestArb__io_msInfo_2_bits_releaseToClean;
  logic RequestArb__io_msInfo_3_valid;
  logic [2:0] RequestArb__io_msInfo_3_bits_channel;
  logic [8:0] RequestArb__io_msInfo_3_bits_set;
  logic [2:0] RequestArb__io_msInfo_3_bits_way;
  logic [30:0] RequestArb__io_msInfo_3_bits_reqTag;
  logic RequestArb__io_msInfo_3_bits_willFree;
  logic RequestArb__io_msInfo_3_bits_aliasTask;
  logic RequestArb__io_msInfo_3_bits_needRelease;
  logic RequestArb__io_msInfo_3_bits_blockRefill;
  logic RequestArb__io_msInfo_3_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_3_bits_meta_state;
  logic RequestArb__io_msInfo_3_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_3_bits_meta_alias;
  logic RequestArb__io_msInfo_3_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_3_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_3_bits_meta_accessed;
  logic RequestArb__io_msInfo_3_bits_meta_tagErr;
  logic RequestArb__io_msInfo_3_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_3_bits_metaTag;
  logic RequestArb__io_msInfo_3_bits_dirHit;
  logic RequestArb__io_msInfo_3_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_3_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_3_bits_param;
  logic RequestArb__io_msInfo_3_bits_mergeA;
  logic RequestArb__io_msInfo_3_bits_w_grantfirst;
  logic RequestArb__io_msInfo_3_bits_s_release;
  logic RequestArb__io_msInfo_3_bits_s_refill;
  logic RequestArb__io_msInfo_3_bits_s_cmoresp;
  logic RequestArb__io_msInfo_3_bits_s_cmometaw;
  logic RequestArb__io_msInfo_3_bits_w_releaseack;
  logic RequestArb__io_msInfo_3_bits_w_replResp;
  logic RequestArb__io_msInfo_3_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_3_bits_replaceData;
  logic RequestArb__io_msInfo_3_bits_releaseToClean;
  logic RequestArb__io_msInfo_4_valid;
  logic [2:0] RequestArb__io_msInfo_4_bits_channel;
  logic [8:0] RequestArb__io_msInfo_4_bits_set;
  logic [2:0] RequestArb__io_msInfo_4_bits_way;
  logic [30:0] RequestArb__io_msInfo_4_bits_reqTag;
  logic RequestArb__io_msInfo_4_bits_willFree;
  logic RequestArb__io_msInfo_4_bits_aliasTask;
  logic RequestArb__io_msInfo_4_bits_needRelease;
  logic RequestArb__io_msInfo_4_bits_blockRefill;
  logic RequestArb__io_msInfo_4_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_4_bits_meta_state;
  logic RequestArb__io_msInfo_4_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_4_bits_meta_alias;
  logic RequestArb__io_msInfo_4_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_4_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_4_bits_meta_accessed;
  logic RequestArb__io_msInfo_4_bits_meta_tagErr;
  logic RequestArb__io_msInfo_4_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_4_bits_metaTag;
  logic RequestArb__io_msInfo_4_bits_dirHit;
  logic RequestArb__io_msInfo_4_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_4_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_4_bits_param;
  logic RequestArb__io_msInfo_4_bits_mergeA;
  logic RequestArb__io_msInfo_4_bits_w_grantfirst;
  logic RequestArb__io_msInfo_4_bits_s_release;
  logic RequestArb__io_msInfo_4_bits_s_refill;
  logic RequestArb__io_msInfo_4_bits_s_cmoresp;
  logic RequestArb__io_msInfo_4_bits_s_cmometaw;
  logic RequestArb__io_msInfo_4_bits_w_releaseack;
  logic RequestArb__io_msInfo_4_bits_w_replResp;
  logic RequestArb__io_msInfo_4_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_4_bits_replaceData;
  logic RequestArb__io_msInfo_4_bits_releaseToClean;
  logic RequestArb__io_msInfo_5_valid;
  logic [2:0] RequestArb__io_msInfo_5_bits_channel;
  logic [8:0] RequestArb__io_msInfo_5_bits_set;
  logic [2:0] RequestArb__io_msInfo_5_bits_way;
  logic [30:0] RequestArb__io_msInfo_5_bits_reqTag;
  logic RequestArb__io_msInfo_5_bits_willFree;
  logic RequestArb__io_msInfo_5_bits_aliasTask;
  logic RequestArb__io_msInfo_5_bits_needRelease;
  logic RequestArb__io_msInfo_5_bits_blockRefill;
  logic RequestArb__io_msInfo_5_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_5_bits_meta_state;
  logic RequestArb__io_msInfo_5_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_5_bits_meta_alias;
  logic RequestArb__io_msInfo_5_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_5_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_5_bits_meta_accessed;
  logic RequestArb__io_msInfo_5_bits_meta_tagErr;
  logic RequestArb__io_msInfo_5_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_5_bits_metaTag;
  logic RequestArb__io_msInfo_5_bits_dirHit;
  logic RequestArb__io_msInfo_5_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_5_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_5_bits_param;
  logic RequestArb__io_msInfo_5_bits_mergeA;
  logic RequestArb__io_msInfo_5_bits_w_grantfirst;
  logic RequestArb__io_msInfo_5_bits_s_release;
  logic RequestArb__io_msInfo_5_bits_s_refill;
  logic RequestArb__io_msInfo_5_bits_s_cmoresp;
  logic RequestArb__io_msInfo_5_bits_s_cmometaw;
  logic RequestArb__io_msInfo_5_bits_w_releaseack;
  logic RequestArb__io_msInfo_5_bits_w_replResp;
  logic RequestArb__io_msInfo_5_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_5_bits_replaceData;
  logic RequestArb__io_msInfo_5_bits_releaseToClean;
  logic RequestArb__io_msInfo_6_valid;
  logic [2:0] RequestArb__io_msInfo_6_bits_channel;
  logic [8:0] RequestArb__io_msInfo_6_bits_set;
  logic [2:0] RequestArb__io_msInfo_6_bits_way;
  logic [30:0] RequestArb__io_msInfo_6_bits_reqTag;
  logic RequestArb__io_msInfo_6_bits_willFree;
  logic RequestArb__io_msInfo_6_bits_aliasTask;
  logic RequestArb__io_msInfo_6_bits_needRelease;
  logic RequestArb__io_msInfo_6_bits_blockRefill;
  logic RequestArb__io_msInfo_6_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_6_bits_meta_state;
  logic RequestArb__io_msInfo_6_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_6_bits_meta_alias;
  logic RequestArb__io_msInfo_6_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_6_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_6_bits_meta_accessed;
  logic RequestArb__io_msInfo_6_bits_meta_tagErr;
  logic RequestArb__io_msInfo_6_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_6_bits_metaTag;
  logic RequestArb__io_msInfo_6_bits_dirHit;
  logic RequestArb__io_msInfo_6_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_6_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_6_bits_param;
  logic RequestArb__io_msInfo_6_bits_mergeA;
  logic RequestArb__io_msInfo_6_bits_w_grantfirst;
  logic RequestArb__io_msInfo_6_bits_s_release;
  logic RequestArb__io_msInfo_6_bits_s_refill;
  logic RequestArb__io_msInfo_6_bits_s_cmoresp;
  logic RequestArb__io_msInfo_6_bits_s_cmometaw;
  logic RequestArb__io_msInfo_6_bits_w_releaseack;
  logic RequestArb__io_msInfo_6_bits_w_replResp;
  logic RequestArb__io_msInfo_6_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_6_bits_replaceData;
  logic RequestArb__io_msInfo_6_bits_releaseToClean;
  logic RequestArb__io_msInfo_7_valid;
  logic [2:0] RequestArb__io_msInfo_7_bits_channel;
  logic [8:0] RequestArb__io_msInfo_7_bits_set;
  logic [2:0] RequestArb__io_msInfo_7_bits_way;
  logic [30:0] RequestArb__io_msInfo_7_bits_reqTag;
  logic RequestArb__io_msInfo_7_bits_willFree;
  logic RequestArb__io_msInfo_7_bits_aliasTask;
  logic RequestArb__io_msInfo_7_bits_needRelease;
  logic RequestArb__io_msInfo_7_bits_blockRefill;
  logic RequestArb__io_msInfo_7_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_7_bits_meta_state;
  logic RequestArb__io_msInfo_7_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_7_bits_meta_alias;
  logic RequestArb__io_msInfo_7_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_7_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_7_bits_meta_accessed;
  logic RequestArb__io_msInfo_7_bits_meta_tagErr;
  logic RequestArb__io_msInfo_7_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_7_bits_metaTag;
  logic RequestArb__io_msInfo_7_bits_dirHit;
  logic RequestArb__io_msInfo_7_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_7_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_7_bits_param;
  logic RequestArb__io_msInfo_7_bits_mergeA;
  logic RequestArb__io_msInfo_7_bits_w_grantfirst;
  logic RequestArb__io_msInfo_7_bits_s_release;
  logic RequestArb__io_msInfo_7_bits_s_refill;
  logic RequestArb__io_msInfo_7_bits_s_cmoresp;
  logic RequestArb__io_msInfo_7_bits_s_cmometaw;
  logic RequestArb__io_msInfo_7_bits_w_releaseack;
  logic RequestArb__io_msInfo_7_bits_w_replResp;
  logic RequestArb__io_msInfo_7_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_7_bits_replaceData;
  logic RequestArb__io_msInfo_7_bits_releaseToClean;
  logic RequestArb__io_msInfo_8_valid;
  logic [2:0] RequestArb__io_msInfo_8_bits_channel;
  logic [8:0] RequestArb__io_msInfo_8_bits_set;
  logic [2:0] RequestArb__io_msInfo_8_bits_way;
  logic [30:0] RequestArb__io_msInfo_8_bits_reqTag;
  logic RequestArb__io_msInfo_8_bits_willFree;
  logic RequestArb__io_msInfo_8_bits_aliasTask;
  logic RequestArb__io_msInfo_8_bits_needRelease;
  logic RequestArb__io_msInfo_8_bits_blockRefill;
  logic RequestArb__io_msInfo_8_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_8_bits_meta_state;
  logic RequestArb__io_msInfo_8_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_8_bits_meta_alias;
  logic RequestArb__io_msInfo_8_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_8_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_8_bits_meta_accessed;
  logic RequestArb__io_msInfo_8_bits_meta_tagErr;
  logic RequestArb__io_msInfo_8_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_8_bits_metaTag;
  logic RequestArb__io_msInfo_8_bits_dirHit;
  logic RequestArb__io_msInfo_8_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_8_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_8_bits_param;
  logic RequestArb__io_msInfo_8_bits_mergeA;
  logic RequestArb__io_msInfo_8_bits_w_grantfirst;
  logic RequestArb__io_msInfo_8_bits_s_release;
  logic RequestArb__io_msInfo_8_bits_s_refill;
  logic RequestArb__io_msInfo_8_bits_s_cmoresp;
  logic RequestArb__io_msInfo_8_bits_s_cmometaw;
  logic RequestArb__io_msInfo_8_bits_w_releaseack;
  logic RequestArb__io_msInfo_8_bits_w_replResp;
  logic RequestArb__io_msInfo_8_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_8_bits_replaceData;
  logic RequestArb__io_msInfo_8_bits_releaseToClean;
  logic RequestArb__io_msInfo_9_valid;
  logic [2:0] RequestArb__io_msInfo_9_bits_channel;
  logic [8:0] RequestArb__io_msInfo_9_bits_set;
  logic [2:0] RequestArb__io_msInfo_9_bits_way;
  logic [30:0] RequestArb__io_msInfo_9_bits_reqTag;
  logic RequestArb__io_msInfo_9_bits_willFree;
  logic RequestArb__io_msInfo_9_bits_aliasTask;
  logic RequestArb__io_msInfo_9_bits_needRelease;
  logic RequestArb__io_msInfo_9_bits_blockRefill;
  logic RequestArb__io_msInfo_9_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_9_bits_meta_state;
  logic RequestArb__io_msInfo_9_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_9_bits_meta_alias;
  logic RequestArb__io_msInfo_9_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_9_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_9_bits_meta_accessed;
  logic RequestArb__io_msInfo_9_bits_meta_tagErr;
  logic RequestArb__io_msInfo_9_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_9_bits_metaTag;
  logic RequestArb__io_msInfo_9_bits_dirHit;
  logic RequestArb__io_msInfo_9_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_9_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_9_bits_param;
  logic RequestArb__io_msInfo_9_bits_mergeA;
  logic RequestArb__io_msInfo_9_bits_w_grantfirst;
  logic RequestArb__io_msInfo_9_bits_s_release;
  logic RequestArb__io_msInfo_9_bits_s_refill;
  logic RequestArb__io_msInfo_9_bits_s_cmoresp;
  logic RequestArb__io_msInfo_9_bits_s_cmometaw;
  logic RequestArb__io_msInfo_9_bits_w_releaseack;
  logic RequestArb__io_msInfo_9_bits_w_replResp;
  logic RequestArb__io_msInfo_9_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_9_bits_replaceData;
  logic RequestArb__io_msInfo_9_bits_releaseToClean;
  logic RequestArb__io_msInfo_10_valid;
  logic [2:0] RequestArb__io_msInfo_10_bits_channel;
  logic [8:0] RequestArb__io_msInfo_10_bits_set;
  logic [2:0] RequestArb__io_msInfo_10_bits_way;
  logic [30:0] RequestArb__io_msInfo_10_bits_reqTag;
  logic RequestArb__io_msInfo_10_bits_willFree;
  logic RequestArb__io_msInfo_10_bits_aliasTask;
  logic RequestArb__io_msInfo_10_bits_needRelease;
  logic RequestArb__io_msInfo_10_bits_blockRefill;
  logic RequestArb__io_msInfo_10_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_10_bits_meta_state;
  logic RequestArb__io_msInfo_10_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_10_bits_meta_alias;
  logic RequestArb__io_msInfo_10_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_10_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_10_bits_meta_accessed;
  logic RequestArb__io_msInfo_10_bits_meta_tagErr;
  logic RequestArb__io_msInfo_10_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_10_bits_metaTag;
  logic RequestArb__io_msInfo_10_bits_dirHit;
  logic RequestArb__io_msInfo_10_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_10_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_10_bits_param;
  logic RequestArb__io_msInfo_10_bits_mergeA;
  logic RequestArb__io_msInfo_10_bits_w_grantfirst;
  logic RequestArb__io_msInfo_10_bits_s_release;
  logic RequestArb__io_msInfo_10_bits_s_refill;
  logic RequestArb__io_msInfo_10_bits_s_cmoresp;
  logic RequestArb__io_msInfo_10_bits_s_cmometaw;
  logic RequestArb__io_msInfo_10_bits_w_releaseack;
  logic RequestArb__io_msInfo_10_bits_w_replResp;
  logic RequestArb__io_msInfo_10_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_10_bits_replaceData;
  logic RequestArb__io_msInfo_10_bits_releaseToClean;
  logic RequestArb__io_msInfo_11_valid;
  logic [2:0] RequestArb__io_msInfo_11_bits_channel;
  logic [8:0] RequestArb__io_msInfo_11_bits_set;
  logic [2:0] RequestArb__io_msInfo_11_bits_way;
  logic [30:0] RequestArb__io_msInfo_11_bits_reqTag;
  logic RequestArb__io_msInfo_11_bits_willFree;
  logic RequestArb__io_msInfo_11_bits_aliasTask;
  logic RequestArb__io_msInfo_11_bits_needRelease;
  logic RequestArb__io_msInfo_11_bits_blockRefill;
  logic RequestArb__io_msInfo_11_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_11_bits_meta_state;
  logic RequestArb__io_msInfo_11_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_11_bits_meta_alias;
  logic RequestArb__io_msInfo_11_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_11_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_11_bits_meta_accessed;
  logic RequestArb__io_msInfo_11_bits_meta_tagErr;
  logic RequestArb__io_msInfo_11_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_11_bits_metaTag;
  logic RequestArb__io_msInfo_11_bits_dirHit;
  logic RequestArb__io_msInfo_11_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_11_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_11_bits_param;
  logic RequestArb__io_msInfo_11_bits_mergeA;
  logic RequestArb__io_msInfo_11_bits_w_grantfirst;
  logic RequestArb__io_msInfo_11_bits_s_release;
  logic RequestArb__io_msInfo_11_bits_s_refill;
  logic RequestArb__io_msInfo_11_bits_s_cmoresp;
  logic RequestArb__io_msInfo_11_bits_s_cmometaw;
  logic RequestArb__io_msInfo_11_bits_w_releaseack;
  logic RequestArb__io_msInfo_11_bits_w_replResp;
  logic RequestArb__io_msInfo_11_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_11_bits_replaceData;
  logic RequestArb__io_msInfo_11_bits_releaseToClean;
  logic RequestArb__io_msInfo_12_valid;
  logic [2:0] RequestArb__io_msInfo_12_bits_channel;
  logic [8:0] RequestArb__io_msInfo_12_bits_set;
  logic [2:0] RequestArb__io_msInfo_12_bits_way;
  logic [30:0] RequestArb__io_msInfo_12_bits_reqTag;
  logic RequestArb__io_msInfo_12_bits_willFree;
  logic RequestArb__io_msInfo_12_bits_aliasTask;
  logic RequestArb__io_msInfo_12_bits_needRelease;
  logic RequestArb__io_msInfo_12_bits_blockRefill;
  logic RequestArb__io_msInfo_12_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_12_bits_meta_state;
  logic RequestArb__io_msInfo_12_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_12_bits_meta_alias;
  logic RequestArb__io_msInfo_12_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_12_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_12_bits_meta_accessed;
  logic RequestArb__io_msInfo_12_bits_meta_tagErr;
  logic RequestArb__io_msInfo_12_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_12_bits_metaTag;
  logic RequestArb__io_msInfo_12_bits_dirHit;
  logic RequestArb__io_msInfo_12_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_12_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_12_bits_param;
  logic RequestArb__io_msInfo_12_bits_mergeA;
  logic RequestArb__io_msInfo_12_bits_w_grantfirst;
  logic RequestArb__io_msInfo_12_bits_s_release;
  logic RequestArb__io_msInfo_12_bits_s_refill;
  logic RequestArb__io_msInfo_12_bits_s_cmoresp;
  logic RequestArb__io_msInfo_12_bits_s_cmometaw;
  logic RequestArb__io_msInfo_12_bits_w_releaseack;
  logic RequestArb__io_msInfo_12_bits_w_replResp;
  logic RequestArb__io_msInfo_12_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_12_bits_replaceData;
  logic RequestArb__io_msInfo_12_bits_releaseToClean;
  logic RequestArb__io_msInfo_13_valid;
  logic [2:0] RequestArb__io_msInfo_13_bits_channel;
  logic [8:0] RequestArb__io_msInfo_13_bits_set;
  logic [2:0] RequestArb__io_msInfo_13_bits_way;
  logic [30:0] RequestArb__io_msInfo_13_bits_reqTag;
  logic RequestArb__io_msInfo_13_bits_willFree;
  logic RequestArb__io_msInfo_13_bits_aliasTask;
  logic RequestArb__io_msInfo_13_bits_needRelease;
  logic RequestArb__io_msInfo_13_bits_blockRefill;
  logic RequestArb__io_msInfo_13_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_13_bits_meta_state;
  logic RequestArb__io_msInfo_13_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_13_bits_meta_alias;
  logic RequestArb__io_msInfo_13_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_13_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_13_bits_meta_accessed;
  logic RequestArb__io_msInfo_13_bits_meta_tagErr;
  logic RequestArb__io_msInfo_13_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_13_bits_metaTag;
  logic RequestArb__io_msInfo_13_bits_dirHit;
  logic RequestArb__io_msInfo_13_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_13_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_13_bits_param;
  logic RequestArb__io_msInfo_13_bits_mergeA;
  logic RequestArb__io_msInfo_13_bits_w_grantfirst;
  logic RequestArb__io_msInfo_13_bits_s_release;
  logic RequestArb__io_msInfo_13_bits_s_refill;
  logic RequestArb__io_msInfo_13_bits_s_cmoresp;
  logic RequestArb__io_msInfo_13_bits_s_cmometaw;
  logic RequestArb__io_msInfo_13_bits_w_releaseack;
  logic RequestArb__io_msInfo_13_bits_w_replResp;
  logic RequestArb__io_msInfo_13_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_13_bits_replaceData;
  logic RequestArb__io_msInfo_13_bits_releaseToClean;
  logic RequestArb__io_msInfo_14_valid;
  logic [2:0] RequestArb__io_msInfo_14_bits_channel;
  logic [8:0] RequestArb__io_msInfo_14_bits_set;
  logic [2:0] RequestArb__io_msInfo_14_bits_way;
  logic [30:0] RequestArb__io_msInfo_14_bits_reqTag;
  logic RequestArb__io_msInfo_14_bits_willFree;
  logic RequestArb__io_msInfo_14_bits_aliasTask;
  logic RequestArb__io_msInfo_14_bits_needRelease;
  logic RequestArb__io_msInfo_14_bits_blockRefill;
  logic RequestArb__io_msInfo_14_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_14_bits_meta_state;
  logic RequestArb__io_msInfo_14_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_14_bits_meta_alias;
  logic RequestArb__io_msInfo_14_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_14_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_14_bits_meta_accessed;
  logic RequestArb__io_msInfo_14_bits_meta_tagErr;
  logic RequestArb__io_msInfo_14_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_14_bits_metaTag;
  logic RequestArb__io_msInfo_14_bits_dirHit;
  logic RequestArb__io_msInfo_14_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_14_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_14_bits_param;
  logic RequestArb__io_msInfo_14_bits_mergeA;
  logic RequestArb__io_msInfo_14_bits_w_grantfirst;
  logic RequestArb__io_msInfo_14_bits_s_release;
  logic RequestArb__io_msInfo_14_bits_s_refill;
  logic RequestArb__io_msInfo_14_bits_s_cmoresp;
  logic RequestArb__io_msInfo_14_bits_s_cmometaw;
  logic RequestArb__io_msInfo_14_bits_w_releaseack;
  logic RequestArb__io_msInfo_14_bits_w_replResp;
  logic RequestArb__io_msInfo_14_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_14_bits_replaceData;
  logic RequestArb__io_msInfo_14_bits_releaseToClean;
  logic RequestArb__io_msInfo_15_valid;
  logic [2:0] RequestArb__io_msInfo_15_bits_channel;
  logic [8:0] RequestArb__io_msInfo_15_bits_set;
  logic [2:0] RequestArb__io_msInfo_15_bits_way;
  logic [30:0] RequestArb__io_msInfo_15_bits_reqTag;
  logic RequestArb__io_msInfo_15_bits_willFree;
  logic RequestArb__io_msInfo_15_bits_aliasTask;
  logic RequestArb__io_msInfo_15_bits_needRelease;
  logic RequestArb__io_msInfo_15_bits_blockRefill;
  logic RequestArb__io_msInfo_15_bits_meta_dirty;
  logic [1:0] RequestArb__io_msInfo_15_bits_meta_state;
  logic RequestArb__io_msInfo_15_bits_meta_clients;
  logic [1:0] RequestArb__io_msInfo_15_bits_meta_alias;
  logic RequestArb__io_msInfo_15_bits_meta_prefetch;
  logic [2:0] RequestArb__io_msInfo_15_bits_meta_prefetchSrc;
  logic RequestArb__io_msInfo_15_bits_meta_accessed;
  logic RequestArb__io_msInfo_15_bits_meta_tagErr;
  logic RequestArb__io_msInfo_15_bits_meta_dataErr;
  logic [30:0] RequestArb__io_msInfo_15_bits_metaTag;
  logic RequestArb__io_msInfo_15_bits_dirHit;
  logic RequestArb__io_msInfo_15_bits_isAcqOrPrefetch;
  logic RequestArb__io_msInfo_15_bits_isPrefetch;
  logic [2:0] RequestArb__io_msInfo_15_bits_param;
  logic RequestArb__io_msInfo_15_bits_mergeA;
  logic RequestArb__io_msInfo_15_bits_w_grantfirst;
  logic RequestArb__io_msInfo_15_bits_s_release;
  logic RequestArb__io_msInfo_15_bits_s_refill;
  logic RequestArb__io_msInfo_15_bits_s_cmoresp;
  logic RequestArb__io_msInfo_15_bits_s_cmometaw;
  logic RequestArb__io_msInfo_15_bits_w_releaseack;
  logic RequestArb__io_msInfo_15_bits_w_replResp;
  logic RequestArb__io_msInfo_15_bits_w_rprobeacklast;
  logic RequestArb__io_msInfo_15_bits_replaceData;
  logic RequestArb__io_msInfo_15_bits_releaseToClean;
  wire  g_RequestArb__io_sinkA_ready;
  wire  i_RequestArb__io_sinkA_ready;
  logic p_RequestArb__io_sinkA_ready;
  bit   t_RequestArb__io_sinkA_ready;
  wire  g_RequestArb__io_s1Entrance_valid;
  wire  i_RequestArb__io_s1Entrance_valid;
  logic p_RequestArb__io_s1Entrance_valid;
  bit   t_RequestArb__io_s1Entrance_valid;
  wire  [8:0] g_RequestArb__io_s1Entrance_bits_set;
  wire  [8:0] i_RequestArb__io_s1Entrance_bits_set;
  logic [8:0] p_RequestArb__io_s1Entrance_bits_set;
  bit   t_RequestArb__io_s1Entrance_bits_set;
  wire  g_RequestArb__io_sinkB_ready;
  wire  i_RequestArb__io_sinkB_ready;
  logic p_RequestArb__io_sinkB_ready;
  bit   t_RequestArb__io_sinkB_ready;
  wire  g_RequestArb__io_sinkC_ready;
  wire  i_RequestArb__io_sinkC_ready;
  logic p_RequestArb__io_sinkC_ready;
  bit   t_RequestArb__io_sinkC_ready;
  wire  g_RequestArb__io_mshrTask_ready;
  wire  i_RequestArb__io_mshrTask_ready;
  logic p_RequestArb__io_mshrTask_ready;
  bit   t_RequestArb__io_mshrTask_ready;
  wire  g_RequestArb__io_dirRead_s1_valid;
  wire  i_RequestArb__io_dirRead_s1_valid;
  logic p_RequestArb__io_dirRead_s1_valid;
  bit   t_RequestArb__io_dirRead_s1_valid;
  wire  [30:0] g_RequestArb__io_dirRead_s1_bits_tag;
  wire  [30:0] i_RequestArb__io_dirRead_s1_bits_tag;
  logic [30:0] p_RequestArb__io_dirRead_s1_bits_tag;
  bit   t_RequestArb__io_dirRead_s1_bits_tag;
  wire  [8:0] g_RequestArb__io_dirRead_s1_bits_set;
  wire  [8:0] i_RequestArb__io_dirRead_s1_bits_set;
  logic [8:0] p_RequestArb__io_dirRead_s1_bits_set;
  bit   t_RequestArb__io_dirRead_s1_bits_set;
  wire  [7:0] g_RequestArb__io_dirRead_s1_bits_wayMask;
  wire  [7:0] i_RequestArb__io_dirRead_s1_bits_wayMask;
  logic [7:0] p_RequestArb__io_dirRead_s1_bits_wayMask;
  bit   t_RequestArb__io_dirRead_s1_bits_wayMask;
  wire  [2:0] g_RequestArb__io_dirRead_s1_bits_replacerInfo_channel;
  wire  [2:0] i_RequestArb__io_dirRead_s1_bits_replacerInfo_channel;
  logic [2:0] p_RequestArb__io_dirRead_s1_bits_replacerInfo_channel;
  bit   t_RequestArb__io_dirRead_s1_bits_replacerInfo_channel;
  wire  [2:0] g_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode;
  wire  [2:0] i_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode;
  logic [2:0] p_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode;
  bit   t_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode;
  wire  [4:0] g_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource;
  wire  [4:0] i_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource;
  logic [4:0] p_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource;
  bit   t_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource;
  wire  g_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch;
  wire  i_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch;
  logic p_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch;
  bit   t_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch;
  wire  g_RequestArb__io_dirRead_s1_bits_refill;
  wire  i_RequestArb__io_dirRead_s1_bits_refill;
  logic p_RequestArb__io_dirRead_s1_bits_refill;
  bit   t_RequestArb__io_dirRead_s1_bits_refill;
  wire  [7:0] g_RequestArb__io_dirRead_s1_bits_mshrId;
  wire  [7:0] i_RequestArb__io_dirRead_s1_bits_mshrId;
  logic [7:0] p_RequestArb__io_dirRead_s1_bits_mshrId;
  bit   t_RequestArb__io_dirRead_s1_bits_mshrId;
  wire  g_RequestArb__io_dirRead_s1_bits_cmoAll;
  wire  i_RequestArb__io_dirRead_s1_bits_cmoAll;
  logic p_RequestArb__io_dirRead_s1_bits_cmoAll;
  bit   t_RequestArb__io_dirRead_s1_bits_cmoAll;
  wire  [2:0] g_RequestArb__io_dirRead_s1_bits_cmoWay;
  wire  [2:0] i_RequestArb__io_dirRead_s1_bits_cmoWay;
  logic [2:0] p_RequestArb__io_dirRead_s1_bits_cmoWay;
  bit   t_RequestArb__io_dirRead_s1_bits_cmoWay;
  wire  g_RequestArb__io_taskToPipe_s2_valid;
  wire  i_RequestArb__io_taskToPipe_s2_valid;
  logic p_RequestArb__io_taskToPipe_s2_valid;
  bit   t_RequestArb__io_taskToPipe_s2_valid;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_channel;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_channel;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_channel;
  bit   t_RequestArb__io_taskToPipe_s2_bits_channel;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_txChannel;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_txChannel;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_txChannel;
  bit   t_RequestArb__io_taskToPipe_s2_bits_txChannel;
  wire  [8:0] g_RequestArb__io_taskToPipe_s2_bits_set;
  wire  [8:0] i_RequestArb__io_taskToPipe_s2_bits_set;
  logic [8:0] p_RequestArb__io_taskToPipe_s2_bits_set;
  bit   t_RequestArb__io_taskToPipe_s2_bits_set;
  wire  [30:0] g_RequestArb__io_taskToPipe_s2_bits_tag;
  wire  [30:0] i_RequestArb__io_taskToPipe_s2_bits_tag;
  logic [30:0] p_RequestArb__io_taskToPipe_s2_bits_tag;
  bit   t_RequestArb__io_taskToPipe_s2_bits_tag;
  wire  [5:0] g_RequestArb__io_taskToPipe_s2_bits_off;
  wire  [5:0] i_RequestArb__io_taskToPipe_s2_bits_off;
  logic [5:0] p_RequestArb__io_taskToPipe_s2_bits_off;
  bit   t_RequestArb__io_taskToPipe_s2_bits_off;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_alias;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_alias;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_alias;
  bit   t_RequestArb__io_taskToPipe_s2_bits_alias;
  wire  [43:0] g_RequestArb__io_taskToPipe_s2_bits_vaddr;
  wire  [43:0] i_RequestArb__io_taskToPipe_s2_bits_vaddr;
  logic [43:0] p_RequestArb__io_taskToPipe_s2_bits_vaddr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_vaddr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_isKeyword;
  wire  i_RequestArb__io_taskToPipe_s2_bits_isKeyword;
  logic p_RequestArb__io_taskToPipe_s2_bits_isKeyword;
  bit   t_RequestArb__io_taskToPipe_s2_bits_isKeyword;
  wire  [3:0] g_RequestArb__io_taskToPipe_s2_bits_opcode;
  wire  [3:0] i_RequestArb__io_taskToPipe_s2_bits_opcode;
  logic [3:0] p_RequestArb__io_taskToPipe_s2_bits_opcode;
  bit   t_RequestArb__io_taskToPipe_s2_bits_opcode;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_param;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_param;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_param;
  bit   t_RequestArb__io_taskToPipe_s2_bits_param;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_size;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_size;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_size;
  bit   t_RequestArb__io_taskToPipe_s2_bits_size;
  wire  [6:0] g_RequestArb__io_taskToPipe_s2_bits_sourceId;
  wire  [6:0] i_RequestArb__io_taskToPipe_s2_bits_sourceId;
  logic [6:0] p_RequestArb__io_taskToPipe_s2_bits_sourceId;
  bit   t_RequestArb__io_taskToPipe_s2_bits_sourceId;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_bufIdx;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_bufIdx;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_bufIdx;
  bit   t_RequestArb__io_taskToPipe_s2_bits_bufIdx;
  wire  g_RequestArb__io_taskToPipe_s2_bits_needProbeAckData;
  wire  i_RequestArb__io_taskToPipe_s2_bits_needProbeAckData;
  logic p_RequestArb__io_taskToPipe_s2_bits_needProbeAckData;
  bit   t_RequestArb__io_taskToPipe_s2_bits_needProbeAckData;
  wire  g_RequestArb__io_taskToPipe_s2_bits_denied;
  wire  i_RequestArb__io_taskToPipe_s2_bits_denied;
  logic p_RequestArb__io_taskToPipe_s2_bits_denied;
  bit   t_RequestArb__io_taskToPipe_s2_bits_denied;
  wire  g_RequestArb__io_taskToPipe_s2_bits_corrupt;
  wire  i_RequestArb__io_taskToPipe_s2_bits_corrupt;
  logic p_RequestArb__io_taskToPipe_s2_bits_corrupt;
  bit   t_RequestArb__io_taskToPipe_s2_bits_corrupt;
  wire  g_RequestArb__io_taskToPipe_s2_bits_mshrTask;
  wire  i_RequestArb__io_taskToPipe_s2_bits_mshrTask;
  logic p_RequestArb__io_taskToPipe_s2_bits_mshrTask;
  bit   t_RequestArb__io_taskToPipe_s2_bits_mshrTask;
  wire  [7:0] g_RequestArb__io_taskToPipe_s2_bits_mshrId;
  wire  [7:0] i_RequestArb__io_taskToPipe_s2_bits_mshrId;
  logic [7:0] p_RequestArb__io_taskToPipe_s2_bits_mshrId;
  bit   t_RequestArb__io_taskToPipe_s2_bits_mshrId;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aliasTask;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aliasTask;
  logic p_RequestArb__io_taskToPipe_s2_bits_aliasTask;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aliasTask;
  wire  g_RequestArb__io_taskToPipe_s2_bits_useProbeData;
  wire  i_RequestArb__io_taskToPipe_s2_bits_useProbeData;
  logic p_RequestArb__io_taskToPipe_s2_bits_useProbeData;
  bit   t_RequestArb__io_taskToPipe_s2_bits_useProbeData;
  wire  g_RequestArb__io_taskToPipe_s2_bits_mshrRetry;
  wire  i_RequestArb__io_taskToPipe_s2_bits_mshrRetry;
  logic p_RequestArb__io_taskToPipe_s2_bits_mshrRetry;
  bit   t_RequestArb__io_taskToPipe_s2_bits_mshrRetry;
  wire  g_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown;
  wire  i_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown;
  logic p_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown;
  bit   t_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown;
  wire  g_RequestArb__io_taskToPipe_s2_bits_fromL2pft;
  wire  i_RequestArb__io_taskToPipe_s2_bits_fromL2pft;
  logic p_RequestArb__io_taskToPipe_s2_bits_fromL2pft;
  bit   t_RequestArb__io_taskToPipe_s2_bits_fromL2pft;
  wire  g_RequestArb__io_taskToPipe_s2_bits_needHint;
  wire  i_RequestArb__io_taskToPipe_s2_bits_needHint;
  logic p_RequestArb__io_taskToPipe_s2_bits_needHint;
  bit   t_RequestArb__io_taskToPipe_s2_bits_needHint;
  wire  g_RequestArb__io_taskToPipe_s2_bits_dirty;
  wire  i_RequestArb__io_taskToPipe_s2_bits_dirty;
  logic p_RequestArb__io_taskToPipe_s2_bits_dirty;
  bit   t_RequestArb__io_taskToPipe_s2_bits_dirty;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_way;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_way;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_way;
  bit   t_RequestArb__io_taskToPipe_s2_bits_way;
  wire  g_RequestArb__io_taskToPipe_s2_bits_meta_dirty;
  wire  i_RequestArb__io_taskToPipe_s2_bits_meta_dirty;
  logic p_RequestArb__io_taskToPipe_s2_bits_meta_dirty;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_dirty;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_meta_state;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_meta_state;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_meta_state;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_state;
  wire  g_RequestArb__io_taskToPipe_s2_bits_meta_clients;
  wire  i_RequestArb__io_taskToPipe_s2_bits_meta_clients;
  logic p_RequestArb__io_taskToPipe_s2_bits_meta_clients;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_clients;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_meta_alias;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_meta_alias;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_meta_alias;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_alias;
  wire  g_RequestArb__io_taskToPipe_s2_bits_meta_prefetch;
  wire  i_RequestArb__io_taskToPipe_s2_bits_meta_prefetch;
  logic p_RequestArb__io_taskToPipe_s2_bits_meta_prefetch;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_prefetch;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc;
  wire  g_RequestArb__io_taskToPipe_s2_bits_meta_accessed;
  wire  i_RequestArb__io_taskToPipe_s2_bits_meta_accessed;
  logic p_RequestArb__io_taskToPipe_s2_bits_meta_accessed;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_accessed;
  wire  g_RequestArb__io_taskToPipe_s2_bits_meta_tagErr;
  wire  i_RequestArb__io_taskToPipe_s2_bits_meta_tagErr;
  logic p_RequestArb__io_taskToPipe_s2_bits_meta_tagErr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_tagErr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_meta_dataErr;
  wire  i_RequestArb__io_taskToPipe_s2_bits_meta_dataErr;
  logic p_RequestArb__io_taskToPipe_s2_bits_meta_dataErr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_meta_dataErr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_metaWen;
  wire  i_RequestArb__io_taskToPipe_s2_bits_metaWen;
  logic p_RequestArb__io_taskToPipe_s2_bits_metaWen;
  bit   t_RequestArb__io_taskToPipe_s2_bits_metaWen;
  wire  g_RequestArb__io_taskToPipe_s2_bits_tagWen;
  wire  i_RequestArb__io_taskToPipe_s2_bits_tagWen;
  logic p_RequestArb__io_taskToPipe_s2_bits_tagWen;
  bit   t_RequestArb__io_taskToPipe_s2_bits_tagWen;
  wire  g_RequestArb__io_taskToPipe_s2_bits_dsWen;
  wire  i_RequestArb__io_taskToPipe_s2_bits_dsWen;
  logic p_RequestArb__io_taskToPipe_s2_bits_dsWen;
  bit   t_RequestArb__io_taskToPipe_s2_bits_dsWen;
  wire  [7:0] g_RequestArb__io_taskToPipe_s2_bits_wayMask;
  wire  [7:0] i_RequestArb__io_taskToPipe_s2_bits_wayMask;
  logic [7:0] p_RequestArb__io_taskToPipe_s2_bits_wayMask;
  bit   t_RequestArb__io_taskToPipe_s2_bits_wayMask;
  wire  g_RequestArb__io_taskToPipe_s2_bits_replTask;
  wire  i_RequestArb__io_taskToPipe_s2_bits_replTask;
  logic p_RequestArb__io_taskToPipe_s2_bits_replTask;
  bit   t_RequestArb__io_taskToPipe_s2_bits_replTask;
  wire  g_RequestArb__io_taskToPipe_s2_bits_cmoTask;
  wire  i_RequestArb__io_taskToPipe_s2_bits_cmoTask;
  logic p_RequestArb__io_taskToPipe_s2_bits_cmoTask;
  bit   t_RequestArb__io_taskToPipe_s2_bits_cmoTask;
  wire  g_RequestArb__io_taskToPipe_s2_bits_cmoAll;
  wire  i_RequestArb__io_taskToPipe_s2_bits_cmoAll;
  logic p_RequestArb__io_taskToPipe_s2_bits_cmoAll;
  bit   t_RequestArb__io_taskToPipe_s2_bits_cmoAll;
  wire  [4:0] g_RequestArb__io_taskToPipe_s2_bits_reqSource;
  wire  [4:0] i_RequestArb__io_taskToPipe_s2_bits_reqSource;
  logic [4:0] p_RequestArb__io_taskToPipe_s2_bits_reqSource;
  bit   t_RequestArb__io_taskToPipe_s2_bits_reqSource;
  wire  g_RequestArb__io_taskToPipe_s2_bits_mergeA;
  wire  i_RequestArb__io_taskToPipe_s2_bits_mergeA;
  logic p_RequestArb__io_taskToPipe_s2_bits_mergeA;
  bit   t_RequestArb__io_taskToPipe_s2_bits_mergeA;
  wire  [5:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off;
  wire  [5:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off;
  logic [5:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias;
  wire  [43:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr;
  wire  [43:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr;
  logic [43:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param;
  wire  [6:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId;
  wire  [6:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId;
  logic [6:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  wire  i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  logic p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitRelease;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitRelease;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitRelease;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitRelease;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData;
  wire  [7:0] g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx;
  wire  [7:0] i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx;
  logic [7:0] p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
  wire  [1:0] g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  wire  [1:0] i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  logic [1:0] p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
  wire  g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  wire  i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  logic p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  bit   t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
  wire  [10:0] g_RequestArb__io_taskToPipe_s2_bits_tgtID;
  wire  [10:0] i_RequestArb__io_taskToPipe_s2_bits_tgtID;
  logic [10:0] p_RequestArb__io_taskToPipe_s2_bits_tgtID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_tgtID;
  wire  [10:0] g_RequestArb__io_taskToPipe_s2_bits_srcID;
  wire  [10:0] i_RequestArb__io_taskToPipe_s2_bits_srcID;
  logic [10:0] p_RequestArb__io_taskToPipe_s2_bits_srcID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_srcID;
  wire  [11:0] g_RequestArb__io_taskToPipe_s2_bits_txnID;
  wire  [11:0] i_RequestArb__io_taskToPipe_s2_bits_txnID;
  logic [11:0] p_RequestArb__io_taskToPipe_s2_bits_txnID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_txnID;
  wire  [10:0] g_RequestArb__io_taskToPipe_s2_bits_homeNID;
  wire  [10:0] i_RequestArb__io_taskToPipe_s2_bits_homeNID;
  logic [10:0] p_RequestArb__io_taskToPipe_s2_bits_homeNID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_homeNID;
  wire  [11:0] g_RequestArb__io_taskToPipe_s2_bits_dbID;
  wire  [11:0] i_RequestArb__io_taskToPipe_s2_bits_dbID;
  logic [11:0] p_RequestArb__io_taskToPipe_s2_bits_dbID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_dbID;
  wire  [10:0] g_RequestArb__io_taskToPipe_s2_bits_fwdNID;
  wire  [10:0] i_RequestArb__io_taskToPipe_s2_bits_fwdNID;
  logic [10:0] p_RequestArb__io_taskToPipe_s2_bits_fwdNID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_fwdNID;
  wire  [11:0] g_RequestArb__io_taskToPipe_s2_bits_fwdTxnID;
  wire  [11:0] i_RequestArb__io_taskToPipe_s2_bits_fwdTxnID;
  logic [11:0] p_RequestArb__io_taskToPipe_s2_bits_fwdTxnID;
  bit   t_RequestArb__io_taskToPipe_s2_bits_fwdTxnID;
  wire  [6:0] g_RequestArb__io_taskToPipe_s2_bits_chiOpcode;
  wire  [6:0] i_RequestArb__io_taskToPipe_s2_bits_chiOpcode;
  logic [6:0] p_RequestArb__io_taskToPipe_s2_bits_chiOpcode;
  bit   t_RequestArb__io_taskToPipe_s2_bits_chiOpcode;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_resp;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_resp;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_resp;
  bit   t_RequestArb__io_taskToPipe_s2_bits_resp;
  wire  [2:0] g_RequestArb__io_taskToPipe_s2_bits_fwdState;
  wire  [2:0] i_RequestArb__io_taskToPipe_s2_bits_fwdState;
  logic [2:0] p_RequestArb__io_taskToPipe_s2_bits_fwdState;
  bit   t_RequestArb__io_taskToPipe_s2_bits_fwdState;
  wire  [3:0] g_RequestArb__io_taskToPipe_s2_bits_pCrdType;
  wire  [3:0] i_RequestArb__io_taskToPipe_s2_bits_pCrdType;
  logic [3:0] p_RequestArb__io_taskToPipe_s2_bits_pCrdType;
  bit   t_RequestArb__io_taskToPipe_s2_bits_pCrdType;
  wire  g_RequestArb__io_taskToPipe_s2_bits_retToSrc;
  wire  i_RequestArb__io_taskToPipe_s2_bits_retToSrc;
  logic p_RequestArb__io_taskToPipe_s2_bits_retToSrc;
  bit   t_RequestArb__io_taskToPipe_s2_bits_retToSrc;
  wire  g_RequestArb__io_taskToPipe_s2_bits_likelyshared;
  wire  i_RequestArb__io_taskToPipe_s2_bits_likelyshared;
  logic p_RequestArb__io_taskToPipe_s2_bits_likelyshared;
  bit   t_RequestArb__io_taskToPipe_s2_bits_likelyshared;
  wire  g_RequestArb__io_taskToPipe_s2_bits_expCompAck;
  wire  i_RequestArb__io_taskToPipe_s2_bits_expCompAck;
  logic p_RequestArb__io_taskToPipe_s2_bits_expCompAck;
  bit   t_RequestArb__io_taskToPipe_s2_bits_expCompAck;
  wire  g_RequestArb__io_taskToPipe_s2_bits_allowRetry;
  wire  i_RequestArb__io_taskToPipe_s2_bits_allowRetry;
  logic p_RequestArb__io_taskToPipe_s2_bits_allowRetry;
  bit   t_RequestArb__io_taskToPipe_s2_bits_allowRetry;
  wire  g_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate;
  wire  i_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate;
  logic p_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate;
  bit   t_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate;
  wire  g_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable;
  wire  i_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable;
  logic p_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable;
  bit   t_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable;
  wire  g_RequestArb__io_taskToPipe_s2_bits_memAttr_device;
  wire  i_RequestArb__io_taskToPipe_s2_bits_memAttr_device;
  logic p_RequestArb__io_taskToPipe_s2_bits_memAttr_device;
  bit   t_RequestArb__io_taskToPipe_s2_bits_memAttr_device;
  wire  g_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa;
  wire  i_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa;
  logic p_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa;
  bit   t_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa;
  wire  g_RequestArb__io_taskToPipe_s2_bits_traceTag;
  wire  i_RequestArb__io_taskToPipe_s2_bits_traceTag;
  logic p_RequestArb__io_taskToPipe_s2_bits_traceTag;
  bit   t_RequestArb__io_taskToPipe_s2_bits_traceTag;
  wire  g_RequestArb__io_taskInfo_s1_valid;
  wire  i_RequestArb__io_taskInfo_s1_valid;
  logic p_RequestArb__io_taskInfo_s1_valid;
  bit   t_RequestArb__io_taskInfo_s1_valid;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_channel;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_channel;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_channel;
  bit   t_RequestArb__io_taskInfo_s1_bits_channel;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_txChannel;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_txChannel;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_txChannel;
  bit   t_RequestArb__io_taskInfo_s1_bits_txChannel;
  wire  [8:0] g_RequestArb__io_taskInfo_s1_bits_set;
  wire  [8:0] i_RequestArb__io_taskInfo_s1_bits_set;
  logic [8:0] p_RequestArb__io_taskInfo_s1_bits_set;
  bit   t_RequestArb__io_taskInfo_s1_bits_set;
  wire  [30:0] g_RequestArb__io_taskInfo_s1_bits_tag;
  wire  [30:0] i_RequestArb__io_taskInfo_s1_bits_tag;
  logic [30:0] p_RequestArb__io_taskInfo_s1_bits_tag;
  bit   t_RequestArb__io_taskInfo_s1_bits_tag;
  wire  [5:0] g_RequestArb__io_taskInfo_s1_bits_off;
  wire  [5:0] i_RequestArb__io_taskInfo_s1_bits_off;
  logic [5:0] p_RequestArb__io_taskInfo_s1_bits_off;
  bit   t_RequestArb__io_taskInfo_s1_bits_off;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_alias;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_alias;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_alias;
  bit   t_RequestArb__io_taskInfo_s1_bits_alias;
  wire  [43:0] g_RequestArb__io_taskInfo_s1_bits_vaddr;
  wire  [43:0] i_RequestArb__io_taskInfo_s1_bits_vaddr;
  logic [43:0] p_RequestArb__io_taskInfo_s1_bits_vaddr;
  bit   t_RequestArb__io_taskInfo_s1_bits_vaddr;
  wire  g_RequestArb__io_taskInfo_s1_bits_isKeyword;
  wire  i_RequestArb__io_taskInfo_s1_bits_isKeyword;
  logic p_RequestArb__io_taskInfo_s1_bits_isKeyword;
  bit   t_RequestArb__io_taskInfo_s1_bits_isKeyword;
  wire  [3:0] g_RequestArb__io_taskInfo_s1_bits_opcode;
  wire  [3:0] i_RequestArb__io_taskInfo_s1_bits_opcode;
  logic [3:0] p_RequestArb__io_taskInfo_s1_bits_opcode;
  bit   t_RequestArb__io_taskInfo_s1_bits_opcode;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_param;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_param;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_param;
  bit   t_RequestArb__io_taskInfo_s1_bits_param;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_size;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_size;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_size;
  bit   t_RequestArb__io_taskInfo_s1_bits_size;
  wire  [6:0] g_RequestArb__io_taskInfo_s1_bits_sourceId;
  wire  [6:0] i_RequestArb__io_taskInfo_s1_bits_sourceId;
  logic [6:0] p_RequestArb__io_taskInfo_s1_bits_sourceId;
  bit   t_RequestArb__io_taskInfo_s1_bits_sourceId;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_bufIdx;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_bufIdx;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_bufIdx;
  bit   t_RequestArb__io_taskInfo_s1_bits_bufIdx;
  wire  g_RequestArb__io_taskInfo_s1_bits_needProbeAckData;
  wire  i_RequestArb__io_taskInfo_s1_bits_needProbeAckData;
  logic p_RequestArb__io_taskInfo_s1_bits_needProbeAckData;
  bit   t_RequestArb__io_taskInfo_s1_bits_needProbeAckData;
  wire  g_RequestArb__io_taskInfo_s1_bits_denied;
  wire  i_RequestArb__io_taskInfo_s1_bits_denied;
  logic p_RequestArb__io_taskInfo_s1_bits_denied;
  bit   t_RequestArb__io_taskInfo_s1_bits_denied;
  wire  g_RequestArb__io_taskInfo_s1_bits_corrupt;
  wire  i_RequestArb__io_taskInfo_s1_bits_corrupt;
  logic p_RequestArb__io_taskInfo_s1_bits_corrupt;
  bit   t_RequestArb__io_taskInfo_s1_bits_corrupt;
  wire  g_RequestArb__io_taskInfo_s1_bits_mshrTask;
  wire  i_RequestArb__io_taskInfo_s1_bits_mshrTask;
  logic p_RequestArb__io_taskInfo_s1_bits_mshrTask;
  bit   t_RequestArb__io_taskInfo_s1_bits_mshrTask;
  wire  [7:0] g_RequestArb__io_taskInfo_s1_bits_mshrId;
  wire  [7:0] i_RequestArb__io_taskInfo_s1_bits_mshrId;
  logic [7:0] p_RequestArb__io_taskInfo_s1_bits_mshrId;
  bit   t_RequestArb__io_taskInfo_s1_bits_mshrId;
  wire  g_RequestArb__io_taskInfo_s1_bits_aliasTask;
  wire  i_RequestArb__io_taskInfo_s1_bits_aliasTask;
  logic p_RequestArb__io_taskInfo_s1_bits_aliasTask;
  bit   t_RequestArb__io_taskInfo_s1_bits_aliasTask;
  wire  g_RequestArb__io_taskInfo_s1_bits_useProbeData;
  wire  i_RequestArb__io_taskInfo_s1_bits_useProbeData;
  logic p_RequestArb__io_taskInfo_s1_bits_useProbeData;
  bit   t_RequestArb__io_taskInfo_s1_bits_useProbeData;
  wire  g_RequestArb__io_taskInfo_s1_bits_mshrRetry;
  wire  i_RequestArb__io_taskInfo_s1_bits_mshrRetry;
  logic p_RequestArb__io_taskInfo_s1_bits_mshrRetry;
  bit   t_RequestArb__io_taskInfo_s1_bits_mshrRetry;
  wire  g_RequestArb__io_taskInfo_s1_bits_readProbeDataDown;
  wire  i_RequestArb__io_taskInfo_s1_bits_readProbeDataDown;
  logic p_RequestArb__io_taskInfo_s1_bits_readProbeDataDown;
  bit   t_RequestArb__io_taskInfo_s1_bits_readProbeDataDown;
  wire  g_RequestArb__io_taskInfo_s1_bits_fromL2pft;
  wire  i_RequestArb__io_taskInfo_s1_bits_fromL2pft;
  logic p_RequestArb__io_taskInfo_s1_bits_fromL2pft;
  bit   t_RequestArb__io_taskInfo_s1_bits_fromL2pft;
  wire  g_RequestArb__io_taskInfo_s1_bits_needHint;
  wire  i_RequestArb__io_taskInfo_s1_bits_needHint;
  logic p_RequestArb__io_taskInfo_s1_bits_needHint;
  bit   t_RequestArb__io_taskInfo_s1_bits_needHint;
  wire  g_RequestArb__io_taskInfo_s1_bits_dirty;
  wire  i_RequestArb__io_taskInfo_s1_bits_dirty;
  logic p_RequestArb__io_taskInfo_s1_bits_dirty;
  bit   t_RequestArb__io_taskInfo_s1_bits_dirty;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_way;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_way;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_way;
  bit   t_RequestArb__io_taskInfo_s1_bits_way;
  wire  g_RequestArb__io_taskInfo_s1_bits_meta_dirty;
  wire  i_RequestArb__io_taskInfo_s1_bits_meta_dirty;
  logic p_RequestArb__io_taskInfo_s1_bits_meta_dirty;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_dirty;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_meta_state;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_meta_state;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_meta_state;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_state;
  wire  g_RequestArb__io_taskInfo_s1_bits_meta_clients;
  wire  i_RequestArb__io_taskInfo_s1_bits_meta_clients;
  logic p_RequestArb__io_taskInfo_s1_bits_meta_clients;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_clients;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_meta_alias;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_meta_alias;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_meta_alias;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_alias;
  wire  g_RequestArb__io_taskInfo_s1_bits_meta_prefetch;
  wire  i_RequestArb__io_taskInfo_s1_bits_meta_prefetch;
  logic p_RequestArb__io_taskInfo_s1_bits_meta_prefetch;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_prefetch;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc;
  wire  g_RequestArb__io_taskInfo_s1_bits_meta_accessed;
  wire  i_RequestArb__io_taskInfo_s1_bits_meta_accessed;
  logic p_RequestArb__io_taskInfo_s1_bits_meta_accessed;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_accessed;
  wire  g_RequestArb__io_taskInfo_s1_bits_meta_tagErr;
  wire  i_RequestArb__io_taskInfo_s1_bits_meta_tagErr;
  logic p_RequestArb__io_taskInfo_s1_bits_meta_tagErr;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_tagErr;
  wire  g_RequestArb__io_taskInfo_s1_bits_meta_dataErr;
  wire  i_RequestArb__io_taskInfo_s1_bits_meta_dataErr;
  logic p_RequestArb__io_taskInfo_s1_bits_meta_dataErr;
  bit   t_RequestArb__io_taskInfo_s1_bits_meta_dataErr;
  wire  g_RequestArb__io_taskInfo_s1_bits_metaWen;
  wire  i_RequestArb__io_taskInfo_s1_bits_metaWen;
  logic p_RequestArb__io_taskInfo_s1_bits_metaWen;
  bit   t_RequestArb__io_taskInfo_s1_bits_metaWen;
  wire  g_RequestArb__io_taskInfo_s1_bits_tagWen;
  wire  i_RequestArb__io_taskInfo_s1_bits_tagWen;
  logic p_RequestArb__io_taskInfo_s1_bits_tagWen;
  bit   t_RequestArb__io_taskInfo_s1_bits_tagWen;
  wire  g_RequestArb__io_taskInfo_s1_bits_dsWen;
  wire  i_RequestArb__io_taskInfo_s1_bits_dsWen;
  logic p_RequestArb__io_taskInfo_s1_bits_dsWen;
  bit   t_RequestArb__io_taskInfo_s1_bits_dsWen;
  wire  [7:0] g_RequestArb__io_taskInfo_s1_bits_wayMask;
  wire  [7:0] i_RequestArb__io_taskInfo_s1_bits_wayMask;
  logic [7:0] p_RequestArb__io_taskInfo_s1_bits_wayMask;
  bit   t_RequestArb__io_taskInfo_s1_bits_wayMask;
  wire  g_RequestArb__io_taskInfo_s1_bits_replTask;
  wire  i_RequestArb__io_taskInfo_s1_bits_replTask;
  logic p_RequestArb__io_taskInfo_s1_bits_replTask;
  bit   t_RequestArb__io_taskInfo_s1_bits_replTask;
  wire  g_RequestArb__io_taskInfo_s1_bits_cmoTask;
  wire  i_RequestArb__io_taskInfo_s1_bits_cmoTask;
  logic p_RequestArb__io_taskInfo_s1_bits_cmoTask;
  bit   t_RequestArb__io_taskInfo_s1_bits_cmoTask;
  wire  g_RequestArb__io_taskInfo_s1_bits_cmoAll;
  wire  i_RequestArb__io_taskInfo_s1_bits_cmoAll;
  logic p_RequestArb__io_taskInfo_s1_bits_cmoAll;
  bit   t_RequestArb__io_taskInfo_s1_bits_cmoAll;
  wire  [4:0] g_RequestArb__io_taskInfo_s1_bits_reqSource;
  wire  [4:0] i_RequestArb__io_taskInfo_s1_bits_reqSource;
  logic [4:0] p_RequestArb__io_taskInfo_s1_bits_reqSource;
  bit   t_RequestArb__io_taskInfo_s1_bits_reqSource;
  wire  g_RequestArb__io_taskInfo_s1_bits_mergeA;
  wire  i_RequestArb__io_taskInfo_s1_bits_mergeA;
  logic p_RequestArb__io_taskInfo_s1_bits_mergeA;
  bit   t_RequestArb__io_taskInfo_s1_bits_mergeA;
  wire  [5:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_off;
  wire  [5:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_off;
  logic [5:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_off;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_off;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias;
  wire  [43:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr;
  wire  [43:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr;
  logic [43:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_param;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_param;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_param;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_param;
  wire  [6:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId;
  wire  [6:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId;
  logic [6:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
  wire  g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
  wire  i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
  logic p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
  bit   t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitRelease;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitRelease;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitRelease;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitRelease;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData;
  wire  [7:0] g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx;
  wire  [7:0] i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx;
  logic [7:0] p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
  wire  [1:0] g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
  wire  [1:0] i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
  logic [1:0] p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
  wire  g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
  wire  i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
  logic p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
  bit   t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
  wire  [10:0] g_RequestArb__io_taskInfo_s1_bits_tgtID;
  wire  [10:0] i_RequestArb__io_taskInfo_s1_bits_tgtID;
  logic [10:0] p_RequestArb__io_taskInfo_s1_bits_tgtID;
  bit   t_RequestArb__io_taskInfo_s1_bits_tgtID;
  wire  [10:0] g_RequestArb__io_taskInfo_s1_bits_srcID;
  wire  [10:0] i_RequestArb__io_taskInfo_s1_bits_srcID;
  logic [10:0] p_RequestArb__io_taskInfo_s1_bits_srcID;
  bit   t_RequestArb__io_taskInfo_s1_bits_srcID;
  wire  [11:0] g_RequestArb__io_taskInfo_s1_bits_txnID;
  wire  [11:0] i_RequestArb__io_taskInfo_s1_bits_txnID;
  logic [11:0] p_RequestArb__io_taskInfo_s1_bits_txnID;
  bit   t_RequestArb__io_taskInfo_s1_bits_txnID;
  wire  [10:0] g_RequestArb__io_taskInfo_s1_bits_homeNID;
  wire  [10:0] i_RequestArb__io_taskInfo_s1_bits_homeNID;
  logic [10:0] p_RequestArb__io_taskInfo_s1_bits_homeNID;
  bit   t_RequestArb__io_taskInfo_s1_bits_homeNID;
  wire  [11:0] g_RequestArb__io_taskInfo_s1_bits_dbID;
  wire  [11:0] i_RequestArb__io_taskInfo_s1_bits_dbID;
  logic [11:0] p_RequestArb__io_taskInfo_s1_bits_dbID;
  bit   t_RequestArb__io_taskInfo_s1_bits_dbID;
  wire  [10:0] g_RequestArb__io_taskInfo_s1_bits_fwdNID;
  wire  [10:0] i_RequestArb__io_taskInfo_s1_bits_fwdNID;
  logic [10:0] p_RequestArb__io_taskInfo_s1_bits_fwdNID;
  bit   t_RequestArb__io_taskInfo_s1_bits_fwdNID;
  wire  [11:0] g_RequestArb__io_taskInfo_s1_bits_fwdTxnID;
  wire  [11:0] i_RequestArb__io_taskInfo_s1_bits_fwdTxnID;
  logic [11:0] p_RequestArb__io_taskInfo_s1_bits_fwdTxnID;
  bit   t_RequestArb__io_taskInfo_s1_bits_fwdTxnID;
  wire  [6:0] g_RequestArb__io_taskInfo_s1_bits_chiOpcode;
  wire  [6:0] i_RequestArb__io_taskInfo_s1_bits_chiOpcode;
  logic [6:0] p_RequestArb__io_taskInfo_s1_bits_chiOpcode;
  bit   t_RequestArb__io_taskInfo_s1_bits_chiOpcode;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_resp;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_resp;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_resp;
  bit   t_RequestArb__io_taskInfo_s1_bits_resp;
  wire  [2:0] g_RequestArb__io_taskInfo_s1_bits_fwdState;
  wire  [2:0] i_RequestArb__io_taskInfo_s1_bits_fwdState;
  logic [2:0] p_RequestArb__io_taskInfo_s1_bits_fwdState;
  bit   t_RequestArb__io_taskInfo_s1_bits_fwdState;
  wire  [3:0] g_RequestArb__io_taskInfo_s1_bits_pCrdType;
  wire  [3:0] i_RequestArb__io_taskInfo_s1_bits_pCrdType;
  logic [3:0] p_RequestArb__io_taskInfo_s1_bits_pCrdType;
  bit   t_RequestArb__io_taskInfo_s1_bits_pCrdType;
  wire  g_RequestArb__io_taskInfo_s1_bits_retToSrc;
  wire  i_RequestArb__io_taskInfo_s1_bits_retToSrc;
  logic p_RequestArb__io_taskInfo_s1_bits_retToSrc;
  bit   t_RequestArb__io_taskInfo_s1_bits_retToSrc;
  wire  g_RequestArb__io_taskInfo_s1_bits_likelyshared;
  wire  i_RequestArb__io_taskInfo_s1_bits_likelyshared;
  logic p_RequestArb__io_taskInfo_s1_bits_likelyshared;
  bit   t_RequestArb__io_taskInfo_s1_bits_likelyshared;
  wire  g_RequestArb__io_taskInfo_s1_bits_expCompAck;
  wire  i_RequestArb__io_taskInfo_s1_bits_expCompAck;
  logic p_RequestArb__io_taskInfo_s1_bits_expCompAck;
  bit   t_RequestArb__io_taskInfo_s1_bits_expCompAck;
  wire  g_RequestArb__io_taskInfo_s1_bits_allowRetry;
  wire  i_RequestArb__io_taskInfo_s1_bits_allowRetry;
  logic p_RequestArb__io_taskInfo_s1_bits_allowRetry;
  bit   t_RequestArb__io_taskInfo_s1_bits_allowRetry;
  wire  g_RequestArb__io_taskInfo_s1_bits_memAttr_allocate;
  wire  i_RequestArb__io_taskInfo_s1_bits_memAttr_allocate;
  logic p_RequestArb__io_taskInfo_s1_bits_memAttr_allocate;
  bit   t_RequestArb__io_taskInfo_s1_bits_memAttr_allocate;
  wire  g_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable;
  wire  i_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable;
  logic p_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable;
  bit   t_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable;
  wire  g_RequestArb__io_taskInfo_s1_bits_memAttr_device;
  wire  i_RequestArb__io_taskInfo_s1_bits_memAttr_device;
  logic p_RequestArb__io_taskInfo_s1_bits_memAttr_device;
  bit   t_RequestArb__io_taskInfo_s1_bits_memAttr_device;
  wire  g_RequestArb__io_taskInfo_s1_bits_memAttr_ewa;
  wire  i_RequestArb__io_taskInfo_s1_bits_memAttr_ewa;
  logic p_RequestArb__io_taskInfo_s1_bits_memAttr_ewa;
  bit   t_RequestArb__io_taskInfo_s1_bits_memAttr_ewa;
  wire  g_RequestArb__io_taskInfo_s1_bits_traceTag;
  wire  i_RequestArb__io_taskInfo_s1_bits_traceTag;
  logic p_RequestArb__io_taskInfo_s1_bits_traceTag;
  bit   t_RequestArb__io_taskInfo_s1_bits_traceTag;
  wire  g_RequestArb__io_refillBufRead_s2_valid;
  wire  i_RequestArb__io_refillBufRead_s2_valid;
  logic p_RequestArb__io_refillBufRead_s2_valid;
  bit   t_RequestArb__io_refillBufRead_s2_valid;
  wire  [7:0] g_RequestArb__io_refillBufRead_s2_bits_id;
  wire  [7:0] i_RequestArb__io_refillBufRead_s2_bits_id;
  logic [7:0] p_RequestArb__io_refillBufRead_s2_bits_id;
  bit   t_RequestArb__io_refillBufRead_s2_bits_id;
  wire  g_RequestArb__io_releaseBufRead_s2_valid;
  wire  i_RequestArb__io_releaseBufRead_s2_valid;
  logic p_RequestArb__io_releaseBufRead_s2_valid;
  bit   t_RequestArb__io_releaseBufRead_s2_valid;
  wire  [7:0] g_RequestArb__io_releaseBufRead_s2_bits_id;
  wire  [7:0] i_RequestArb__io_releaseBufRead_s2_bits_id;
  logic [7:0] p_RequestArb__io_releaseBufRead_s2_bits_id;
  bit   t_RequestArb__io_releaseBufRead_s2_bits_id;
  wire  [30:0] g_RequestArb__io_status_s1_tags_0;
  wire  [30:0] i_RequestArb__io_status_s1_tags_0;
  logic [30:0] p_RequestArb__io_status_s1_tags_0;
  bit   t_RequestArb__io_status_s1_tags_0;
  wire  [30:0] g_RequestArb__io_status_s1_tags_1;
  wire  [30:0] i_RequestArb__io_status_s1_tags_1;
  logic [30:0] p_RequestArb__io_status_s1_tags_1;
  bit   t_RequestArb__io_status_s1_tags_1;
  wire  [30:0] g_RequestArb__io_status_s1_tags_2;
  wire  [30:0] i_RequestArb__io_status_s1_tags_2;
  logic [30:0] p_RequestArb__io_status_s1_tags_2;
  bit   t_RequestArb__io_status_s1_tags_2;
  wire  [30:0] g_RequestArb__io_status_s1_tags_3;
  wire  [30:0] i_RequestArb__io_status_s1_tags_3;
  logic [30:0] p_RequestArb__io_status_s1_tags_3;
  bit   t_RequestArb__io_status_s1_tags_3;
  wire  [8:0] g_RequestArb__io_status_s1_sets_0;
  wire  [8:0] i_RequestArb__io_status_s1_sets_0;
  logic [8:0] p_RequestArb__io_status_s1_sets_0;
  bit   t_RequestArb__io_status_s1_sets_0;
  wire  [8:0] g_RequestArb__io_status_s1_sets_1;
  wire  [8:0] i_RequestArb__io_status_s1_sets_1;
  logic [8:0] p_RequestArb__io_status_s1_sets_1;
  bit   t_RequestArb__io_status_s1_sets_1;
  wire  [8:0] g_RequestArb__io_status_s1_sets_2;
  wire  [8:0] i_RequestArb__io_status_s1_sets_2;
  logic [8:0] p_RequestArb__io_status_s1_sets_2;
  bit   t_RequestArb__io_status_s1_sets_2;
  wire  [8:0] g_RequestArb__io_status_s1_sets_3;
  wire  [8:0] i_RequestArb__io_status_s1_sets_3;
  logic [8:0] p_RequestArb__io_status_s1_sets_3;
  bit   t_RequestArb__io_status_s1_sets_3;
  wire  g_RequestArb__io_status_vec_0_valid;
  wire  i_RequestArb__io_status_vec_0_valid;
  logic p_RequestArb__io_status_vec_0_valid;
  bit   t_RequestArb__io_status_vec_0_valid;
  wire  [2:0] g_RequestArb__io_status_vec_0_bits_channel;
  wire  [2:0] i_RequestArb__io_status_vec_0_bits_channel;
  logic [2:0] p_RequestArb__io_status_vec_0_bits_channel;
  bit   t_RequestArb__io_status_vec_0_bits_channel;
  wire  g_RequestArb__io_status_vec_1_valid;
  wire  i_RequestArb__io_status_vec_1_valid;
  logic p_RequestArb__io_status_vec_1_valid;
  bit   t_RequestArb__io_status_vec_1_valid;
  wire  [2:0] g_RequestArb__io_status_vec_1_bits_channel;
  wire  [2:0] i_RequestArb__io_status_vec_1_bits_channel;
  logic [2:0] p_RequestArb__io_status_vec_1_bits_channel;
  bit   t_RequestArb__io_status_vec_1_bits_channel;
  wire  g_RequestArb__io_status_vec_toTX_0_valid;
  wire  i_RequestArb__io_status_vec_toTX_0_valid;
  logic p_RequestArb__io_status_vec_toTX_0_valid;
  bit   t_RequestArb__io_status_vec_toTX_0_valid;
  wire  [2:0] g_RequestArb__io_status_vec_toTX_0_bits_channel;
  wire  [2:0] i_RequestArb__io_status_vec_toTX_0_bits_channel;
  logic [2:0] p_RequestArb__io_status_vec_toTX_0_bits_channel;
  bit   t_RequestArb__io_status_vec_toTX_0_bits_channel;
  wire  [2:0] g_RequestArb__io_status_vec_toTX_0_bits_txChannel;
  wire  [2:0] i_RequestArb__io_status_vec_toTX_0_bits_txChannel;
  logic [2:0] p_RequestArb__io_status_vec_toTX_0_bits_txChannel;
  bit   t_RequestArb__io_status_vec_toTX_0_bits_txChannel;
  wire  g_RequestArb__io_status_vec_toTX_0_bits_mshrTask;
  wire  i_RequestArb__io_status_vec_toTX_0_bits_mshrTask;
  logic p_RequestArb__io_status_vec_toTX_0_bits_mshrTask;
  bit   t_RequestArb__io_status_vec_toTX_0_bits_mshrTask;
  wire  g_RequestArb__io_status_vec_toTX_1_valid;
  wire  i_RequestArb__io_status_vec_toTX_1_valid;
  logic p_RequestArb__io_status_vec_toTX_1_valid;
  bit   t_RequestArb__io_status_vec_toTX_1_valid;
  wire  [2:0] g_RequestArb__io_status_vec_toTX_1_bits_channel;
  wire  [2:0] i_RequestArb__io_status_vec_toTX_1_bits_channel;
  logic [2:0] p_RequestArb__io_status_vec_toTX_1_bits_channel;
  bit   t_RequestArb__io_status_vec_toTX_1_bits_channel;
  wire  [2:0] g_RequestArb__io_status_vec_toTX_1_bits_txChannel;
  wire  [2:0] i_RequestArb__io_status_vec_toTX_1_bits_txChannel;
  logic [2:0] p_RequestArb__io_status_vec_toTX_1_bits_txChannel;
  bit   t_RequestArb__io_status_vec_toTX_1_bits_txChannel;
  wire  g_RequestArb__io_status_vec_toTX_1_bits_mshrTask;
  wire  i_RequestArb__io_status_vec_toTX_1_bits_mshrTask;
  logic p_RequestArb__io_status_vec_toTX_1_bits_mshrTask;
  bit   t_RequestArb__io_status_vec_toTX_1_bits_mshrTask;
  RequestArb u_g_RequestArb (
    .clock (clock),
    .reset (reset),
    .io_sinkA_ready (g_RequestArb__io_sinkA_ready),
    .io_sinkA_valid (RequestArb__io_sinkA_valid),
    .io_sinkA_bits_channel (RequestArb__io_sinkA_bits_channel),
    .io_sinkA_bits_txChannel (RequestArb__io_sinkA_bits_txChannel),
    .io_sinkA_bits_set (RequestArb__io_sinkA_bits_set),
    .io_sinkA_bits_tag (RequestArb__io_sinkA_bits_tag),
    .io_sinkA_bits_off (RequestArb__io_sinkA_bits_off),
    .io_sinkA_bits_alias (RequestArb__io_sinkA_bits_alias),
    .io_sinkA_bits_vaddr (RequestArb__io_sinkA_bits_vaddr),
    .io_sinkA_bits_isKeyword (RequestArb__io_sinkA_bits_isKeyword),
    .io_sinkA_bits_opcode (RequestArb__io_sinkA_bits_opcode),
    .io_sinkA_bits_param (RequestArb__io_sinkA_bits_param),
    .io_sinkA_bits_size (RequestArb__io_sinkA_bits_size),
    .io_sinkA_bits_sourceId (RequestArb__io_sinkA_bits_sourceId),
    .io_sinkA_bits_bufIdx (RequestArb__io_sinkA_bits_bufIdx),
    .io_sinkA_bits_needProbeAckData (RequestArb__io_sinkA_bits_needProbeAckData),
    .io_sinkA_bits_denied (RequestArb__io_sinkA_bits_denied),
    .io_sinkA_bits_corrupt (RequestArb__io_sinkA_bits_corrupt),
    .io_sinkA_bits_mshrTask (RequestArb__io_sinkA_bits_mshrTask),
    .io_sinkA_bits_mshrId (RequestArb__io_sinkA_bits_mshrId),
    .io_sinkA_bits_aliasTask (RequestArb__io_sinkA_bits_aliasTask),
    .io_sinkA_bits_useProbeData (RequestArb__io_sinkA_bits_useProbeData),
    .io_sinkA_bits_mshrRetry (RequestArb__io_sinkA_bits_mshrRetry),
    .io_sinkA_bits_readProbeDataDown (RequestArb__io_sinkA_bits_readProbeDataDown),
    .io_sinkA_bits_fromL2pft (RequestArb__io_sinkA_bits_fromL2pft),
    .io_sinkA_bits_needHint (RequestArb__io_sinkA_bits_needHint),
    .io_sinkA_bits_dirty (RequestArb__io_sinkA_bits_dirty),
    .io_sinkA_bits_way (RequestArb__io_sinkA_bits_way),
    .io_sinkA_bits_meta_dirty (RequestArb__io_sinkA_bits_meta_dirty),
    .io_sinkA_bits_meta_state (RequestArb__io_sinkA_bits_meta_state),
    .io_sinkA_bits_meta_clients (RequestArb__io_sinkA_bits_meta_clients),
    .io_sinkA_bits_meta_alias (RequestArb__io_sinkA_bits_meta_alias),
    .io_sinkA_bits_meta_prefetch (RequestArb__io_sinkA_bits_meta_prefetch),
    .io_sinkA_bits_meta_prefetchSrc (RequestArb__io_sinkA_bits_meta_prefetchSrc),
    .io_sinkA_bits_meta_accessed (RequestArb__io_sinkA_bits_meta_accessed),
    .io_sinkA_bits_meta_tagErr (RequestArb__io_sinkA_bits_meta_tagErr),
    .io_sinkA_bits_meta_dataErr (RequestArb__io_sinkA_bits_meta_dataErr),
    .io_sinkA_bits_metaWen (RequestArb__io_sinkA_bits_metaWen),
    .io_sinkA_bits_tagWen (RequestArb__io_sinkA_bits_tagWen),
    .io_sinkA_bits_dsWen (RequestArb__io_sinkA_bits_dsWen),
    .io_sinkA_bits_wayMask (RequestArb__io_sinkA_bits_wayMask),
    .io_sinkA_bits_replTask (RequestArb__io_sinkA_bits_replTask),
    .io_sinkA_bits_cmoTask (RequestArb__io_sinkA_bits_cmoTask),
    .io_sinkA_bits_cmoAll (RequestArb__io_sinkA_bits_cmoAll),
    .io_sinkA_bits_reqSource (RequestArb__io_sinkA_bits_reqSource),
    .io_sinkA_bits_mergeA (RequestArb__io_sinkA_bits_mergeA),
    .io_sinkA_bits_aMergeTask_off (RequestArb__io_sinkA_bits_aMergeTask_off),
    .io_sinkA_bits_aMergeTask_alias (RequestArb__io_sinkA_bits_aMergeTask_alias),
    .io_sinkA_bits_aMergeTask_vaddr (RequestArb__io_sinkA_bits_aMergeTask_vaddr),
    .io_sinkA_bits_aMergeTask_isKeyword (RequestArb__io_sinkA_bits_aMergeTask_isKeyword),
    .io_sinkA_bits_aMergeTask_opcode (RequestArb__io_sinkA_bits_aMergeTask_opcode),
    .io_sinkA_bits_aMergeTask_param (RequestArb__io_sinkA_bits_aMergeTask_param),
    .io_sinkA_bits_aMergeTask_sourceId (RequestArb__io_sinkA_bits_aMergeTask_sourceId),
    .io_sinkA_bits_aMergeTask_meta_dirty (RequestArb__io_sinkA_bits_aMergeTask_meta_dirty),
    .io_sinkA_bits_aMergeTask_meta_state (RequestArb__io_sinkA_bits_aMergeTask_meta_state),
    .io_sinkA_bits_aMergeTask_meta_clients (RequestArb__io_sinkA_bits_aMergeTask_meta_clients),
    .io_sinkA_bits_aMergeTask_meta_alias (RequestArb__io_sinkA_bits_aMergeTask_meta_alias),
    .io_sinkA_bits_aMergeTask_meta_prefetch (RequestArb__io_sinkA_bits_aMergeTask_meta_prefetch),
    .io_sinkA_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_sinkA_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkA_bits_aMergeTask_meta_accessed (RequestArb__io_sinkA_bits_aMergeTask_meta_accessed),
    .io_sinkA_bits_aMergeTask_meta_tagErr (RequestArb__io_sinkA_bits_aMergeTask_meta_tagErr),
    .io_sinkA_bits_aMergeTask_meta_dataErr (RequestArb__io_sinkA_bits_aMergeTask_meta_dataErr),
    .io_sinkA_bits_snpHitRelease (RequestArb__io_sinkA_bits_snpHitRelease),
    .io_sinkA_bits_snpHitReleaseToInval (RequestArb__io_sinkA_bits_snpHitReleaseToInval),
    .io_sinkA_bits_snpHitReleaseToClean (RequestArb__io_sinkA_bits_snpHitReleaseToClean),
    .io_sinkA_bits_snpHitReleaseWithData (RequestArb__io_sinkA_bits_snpHitReleaseWithData),
    .io_sinkA_bits_snpHitReleaseIdx (RequestArb__io_sinkA_bits_snpHitReleaseIdx),
    .io_sinkA_bits_snpHitReleaseMeta_dirty (RequestArb__io_sinkA_bits_snpHitReleaseMeta_dirty),
    .io_sinkA_bits_snpHitReleaseMeta_state (RequestArb__io_sinkA_bits_snpHitReleaseMeta_state),
    .io_sinkA_bits_snpHitReleaseMeta_clients (RequestArb__io_sinkA_bits_snpHitReleaseMeta_clients),
    .io_sinkA_bits_snpHitReleaseMeta_alias (RequestArb__io_sinkA_bits_snpHitReleaseMeta_alias),
    .io_sinkA_bits_snpHitReleaseMeta_prefetch (RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetch),
    .io_sinkA_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkA_bits_snpHitReleaseMeta_accessed (RequestArb__io_sinkA_bits_snpHitReleaseMeta_accessed),
    .io_sinkA_bits_snpHitReleaseMeta_tagErr (RequestArb__io_sinkA_bits_snpHitReleaseMeta_tagErr),
    .io_sinkA_bits_snpHitReleaseMeta_dataErr (RequestArb__io_sinkA_bits_snpHitReleaseMeta_dataErr),
    .io_sinkA_bits_tgtID (RequestArb__io_sinkA_bits_tgtID),
    .io_sinkA_bits_srcID (RequestArb__io_sinkA_bits_srcID),
    .io_sinkA_bits_txnID (RequestArb__io_sinkA_bits_txnID),
    .io_sinkA_bits_homeNID (RequestArb__io_sinkA_bits_homeNID),
    .io_sinkA_bits_dbID (RequestArb__io_sinkA_bits_dbID),
    .io_sinkA_bits_fwdNID (RequestArb__io_sinkA_bits_fwdNID),
    .io_sinkA_bits_fwdTxnID (RequestArb__io_sinkA_bits_fwdTxnID),
    .io_sinkA_bits_chiOpcode (RequestArb__io_sinkA_bits_chiOpcode),
    .io_sinkA_bits_resp (RequestArb__io_sinkA_bits_resp),
    .io_sinkA_bits_fwdState (RequestArb__io_sinkA_bits_fwdState),
    .io_sinkA_bits_pCrdType (RequestArb__io_sinkA_bits_pCrdType),
    .io_sinkA_bits_retToSrc (RequestArb__io_sinkA_bits_retToSrc),
    .io_sinkA_bits_likelyshared (RequestArb__io_sinkA_bits_likelyshared),
    .io_sinkA_bits_expCompAck (RequestArb__io_sinkA_bits_expCompAck),
    .io_sinkA_bits_allowRetry (RequestArb__io_sinkA_bits_allowRetry),
    .io_sinkA_bits_memAttr_allocate (RequestArb__io_sinkA_bits_memAttr_allocate),
    .io_sinkA_bits_memAttr_cacheable (RequestArb__io_sinkA_bits_memAttr_cacheable),
    .io_sinkA_bits_memAttr_device (RequestArb__io_sinkA_bits_memAttr_device),
    .io_sinkA_bits_memAttr_ewa (RequestArb__io_sinkA_bits_memAttr_ewa),
    .io_sinkA_bits_traceTag (RequestArb__io_sinkA_bits_traceTag),
    .io_ATag (RequestArb__io_ATag),
    .io_ASet (RequestArb__io_ASet),
    .io_s1Entrance_valid (g_RequestArb__io_s1Entrance_valid),
    .io_s1Entrance_bits_set (g_RequestArb__io_s1Entrance_bits_set),
    .io_sinkB_ready (g_RequestArb__io_sinkB_ready),
    .io_sinkB_valid (RequestArb__io_sinkB_valid),
    .io_sinkB_bits_channel (RequestArb__io_sinkB_bits_channel),
    .io_sinkB_bits_txChannel (RequestArb__io_sinkB_bits_txChannel),
    .io_sinkB_bits_set (RequestArb__io_sinkB_bits_set),
    .io_sinkB_bits_tag (RequestArb__io_sinkB_bits_tag),
    .io_sinkB_bits_off (RequestArb__io_sinkB_bits_off),
    .io_sinkB_bits_alias (RequestArb__io_sinkB_bits_alias),
    .io_sinkB_bits_vaddr (RequestArb__io_sinkB_bits_vaddr),
    .io_sinkB_bits_isKeyword (RequestArb__io_sinkB_bits_isKeyword),
    .io_sinkB_bits_opcode (RequestArb__io_sinkB_bits_opcode),
    .io_sinkB_bits_param (RequestArb__io_sinkB_bits_param),
    .io_sinkB_bits_size (RequestArb__io_sinkB_bits_size),
    .io_sinkB_bits_sourceId (RequestArb__io_sinkB_bits_sourceId),
    .io_sinkB_bits_bufIdx (RequestArb__io_sinkB_bits_bufIdx),
    .io_sinkB_bits_needProbeAckData (RequestArb__io_sinkB_bits_needProbeAckData),
    .io_sinkB_bits_denied (RequestArb__io_sinkB_bits_denied),
    .io_sinkB_bits_corrupt (RequestArb__io_sinkB_bits_corrupt),
    .io_sinkB_bits_mshrTask (RequestArb__io_sinkB_bits_mshrTask),
    .io_sinkB_bits_mshrId (RequestArb__io_sinkB_bits_mshrId),
    .io_sinkB_bits_aliasTask (RequestArb__io_sinkB_bits_aliasTask),
    .io_sinkB_bits_useProbeData (RequestArb__io_sinkB_bits_useProbeData),
    .io_sinkB_bits_mshrRetry (RequestArb__io_sinkB_bits_mshrRetry),
    .io_sinkB_bits_readProbeDataDown (RequestArb__io_sinkB_bits_readProbeDataDown),
    .io_sinkB_bits_fromL2pft (RequestArb__io_sinkB_bits_fromL2pft),
    .io_sinkB_bits_needHint (RequestArb__io_sinkB_bits_needHint),
    .io_sinkB_bits_dirty (RequestArb__io_sinkB_bits_dirty),
    .io_sinkB_bits_way (RequestArb__io_sinkB_bits_way),
    .io_sinkB_bits_meta_dirty (RequestArb__io_sinkB_bits_meta_dirty),
    .io_sinkB_bits_meta_state (RequestArb__io_sinkB_bits_meta_state),
    .io_sinkB_bits_meta_clients (RequestArb__io_sinkB_bits_meta_clients),
    .io_sinkB_bits_meta_alias (RequestArb__io_sinkB_bits_meta_alias),
    .io_sinkB_bits_meta_prefetch (RequestArb__io_sinkB_bits_meta_prefetch),
    .io_sinkB_bits_meta_prefetchSrc (RequestArb__io_sinkB_bits_meta_prefetchSrc),
    .io_sinkB_bits_meta_accessed (RequestArb__io_sinkB_bits_meta_accessed),
    .io_sinkB_bits_meta_tagErr (RequestArb__io_sinkB_bits_meta_tagErr),
    .io_sinkB_bits_meta_dataErr (RequestArb__io_sinkB_bits_meta_dataErr),
    .io_sinkB_bits_metaWen (RequestArb__io_sinkB_bits_metaWen),
    .io_sinkB_bits_tagWen (RequestArb__io_sinkB_bits_tagWen),
    .io_sinkB_bits_dsWen (RequestArb__io_sinkB_bits_dsWen),
    .io_sinkB_bits_wayMask (RequestArb__io_sinkB_bits_wayMask),
    .io_sinkB_bits_replTask (RequestArb__io_sinkB_bits_replTask),
    .io_sinkB_bits_cmoTask (RequestArb__io_sinkB_bits_cmoTask),
    .io_sinkB_bits_cmoAll (RequestArb__io_sinkB_bits_cmoAll),
    .io_sinkB_bits_reqSource (RequestArb__io_sinkB_bits_reqSource),
    .io_sinkB_bits_mergeA (RequestArb__io_sinkB_bits_mergeA),
    .io_sinkB_bits_aMergeTask_off (RequestArb__io_sinkB_bits_aMergeTask_off),
    .io_sinkB_bits_aMergeTask_alias (RequestArb__io_sinkB_bits_aMergeTask_alias),
    .io_sinkB_bits_aMergeTask_vaddr (RequestArb__io_sinkB_bits_aMergeTask_vaddr),
    .io_sinkB_bits_aMergeTask_isKeyword (RequestArb__io_sinkB_bits_aMergeTask_isKeyword),
    .io_sinkB_bits_aMergeTask_opcode (RequestArb__io_sinkB_bits_aMergeTask_opcode),
    .io_sinkB_bits_aMergeTask_param (RequestArb__io_sinkB_bits_aMergeTask_param),
    .io_sinkB_bits_aMergeTask_sourceId (RequestArb__io_sinkB_bits_aMergeTask_sourceId),
    .io_sinkB_bits_aMergeTask_meta_dirty (RequestArb__io_sinkB_bits_aMergeTask_meta_dirty),
    .io_sinkB_bits_aMergeTask_meta_state (RequestArb__io_sinkB_bits_aMergeTask_meta_state),
    .io_sinkB_bits_aMergeTask_meta_clients (RequestArb__io_sinkB_bits_aMergeTask_meta_clients),
    .io_sinkB_bits_aMergeTask_meta_alias (RequestArb__io_sinkB_bits_aMergeTask_meta_alias),
    .io_sinkB_bits_aMergeTask_meta_prefetch (RequestArb__io_sinkB_bits_aMergeTask_meta_prefetch),
    .io_sinkB_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_sinkB_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkB_bits_aMergeTask_meta_accessed (RequestArb__io_sinkB_bits_aMergeTask_meta_accessed),
    .io_sinkB_bits_aMergeTask_meta_tagErr (RequestArb__io_sinkB_bits_aMergeTask_meta_tagErr),
    .io_sinkB_bits_aMergeTask_meta_dataErr (RequestArb__io_sinkB_bits_aMergeTask_meta_dataErr),
    .io_sinkB_bits_snpHitRelease (RequestArb__io_sinkB_bits_snpHitRelease),
    .io_sinkB_bits_snpHitReleaseToInval (RequestArb__io_sinkB_bits_snpHitReleaseToInval),
    .io_sinkB_bits_snpHitReleaseToClean (RequestArb__io_sinkB_bits_snpHitReleaseToClean),
    .io_sinkB_bits_snpHitReleaseWithData (RequestArb__io_sinkB_bits_snpHitReleaseWithData),
    .io_sinkB_bits_snpHitReleaseIdx (RequestArb__io_sinkB_bits_snpHitReleaseIdx),
    .io_sinkB_bits_snpHitReleaseMeta_dirty (RequestArb__io_sinkB_bits_snpHitReleaseMeta_dirty),
    .io_sinkB_bits_snpHitReleaseMeta_state (RequestArb__io_sinkB_bits_snpHitReleaseMeta_state),
    .io_sinkB_bits_snpHitReleaseMeta_clients (RequestArb__io_sinkB_bits_snpHitReleaseMeta_clients),
    .io_sinkB_bits_snpHitReleaseMeta_alias (RequestArb__io_sinkB_bits_snpHitReleaseMeta_alias),
    .io_sinkB_bits_snpHitReleaseMeta_prefetch (RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetch),
    .io_sinkB_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkB_bits_snpHitReleaseMeta_accessed (RequestArb__io_sinkB_bits_snpHitReleaseMeta_accessed),
    .io_sinkB_bits_snpHitReleaseMeta_tagErr (RequestArb__io_sinkB_bits_snpHitReleaseMeta_tagErr),
    .io_sinkB_bits_snpHitReleaseMeta_dataErr (RequestArb__io_sinkB_bits_snpHitReleaseMeta_dataErr),
    .io_sinkB_bits_tgtID (RequestArb__io_sinkB_bits_tgtID),
    .io_sinkB_bits_srcID (RequestArb__io_sinkB_bits_srcID),
    .io_sinkB_bits_txnID (RequestArb__io_sinkB_bits_txnID),
    .io_sinkB_bits_homeNID (RequestArb__io_sinkB_bits_homeNID),
    .io_sinkB_bits_dbID (RequestArb__io_sinkB_bits_dbID),
    .io_sinkB_bits_fwdNID (RequestArb__io_sinkB_bits_fwdNID),
    .io_sinkB_bits_fwdTxnID (RequestArb__io_sinkB_bits_fwdTxnID),
    .io_sinkB_bits_chiOpcode (RequestArb__io_sinkB_bits_chiOpcode),
    .io_sinkB_bits_resp (RequestArb__io_sinkB_bits_resp),
    .io_sinkB_bits_fwdState (RequestArb__io_sinkB_bits_fwdState),
    .io_sinkB_bits_pCrdType (RequestArb__io_sinkB_bits_pCrdType),
    .io_sinkB_bits_retToSrc (RequestArb__io_sinkB_bits_retToSrc),
    .io_sinkB_bits_likelyshared (RequestArb__io_sinkB_bits_likelyshared),
    .io_sinkB_bits_expCompAck (RequestArb__io_sinkB_bits_expCompAck),
    .io_sinkB_bits_allowRetry (RequestArb__io_sinkB_bits_allowRetry),
    .io_sinkB_bits_memAttr_allocate (RequestArb__io_sinkB_bits_memAttr_allocate),
    .io_sinkB_bits_memAttr_cacheable (RequestArb__io_sinkB_bits_memAttr_cacheable),
    .io_sinkB_bits_memAttr_device (RequestArb__io_sinkB_bits_memAttr_device),
    .io_sinkB_bits_memAttr_ewa (RequestArb__io_sinkB_bits_memAttr_ewa),
    .io_sinkB_bits_traceTag (RequestArb__io_sinkB_bits_traceTag),
    .io_sinkC_ready (g_RequestArb__io_sinkC_ready),
    .io_sinkC_valid (RequestArb__io_sinkC_valid),
    .io_sinkC_bits_channel (RequestArb__io_sinkC_bits_channel),
    .io_sinkC_bits_txChannel (RequestArb__io_sinkC_bits_txChannel),
    .io_sinkC_bits_set (RequestArb__io_sinkC_bits_set),
    .io_sinkC_bits_tag (RequestArb__io_sinkC_bits_tag),
    .io_sinkC_bits_off (RequestArb__io_sinkC_bits_off),
    .io_sinkC_bits_alias (RequestArb__io_sinkC_bits_alias),
    .io_sinkC_bits_vaddr (RequestArb__io_sinkC_bits_vaddr),
    .io_sinkC_bits_isKeyword (RequestArb__io_sinkC_bits_isKeyword),
    .io_sinkC_bits_opcode (RequestArb__io_sinkC_bits_opcode),
    .io_sinkC_bits_param (RequestArb__io_sinkC_bits_param),
    .io_sinkC_bits_size (RequestArb__io_sinkC_bits_size),
    .io_sinkC_bits_sourceId (RequestArb__io_sinkC_bits_sourceId),
    .io_sinkC_bits_bufIdx (RequestArb__io_sinkC_bits_bufIdx),
    .io_sinkC_bits_needProbeAckData (RequestArb__io_sinkC_bits_needProbeAckData),
    .io_sinkC_bits_denied (RequestArb__io_sinkC_bits_denied),
    .io_sinkC_bits_corrupt (RequestArb__io_sinkC_bits_corrupt),
    .io_sinkC_bits_mshrTask (RequestArb__io_sinkC_bits_mshrTask),
    .io_sinkC_bits_mshrId (RequestArb__io_sinkC_bits_mshrId),
    .io_sinkC_bits_aliasTask (RequestArb__io_sinkC_bits_aliasTask),
    .io_sinkC_bits_useProbeData (RequestArb__io_sinkC_bits_useProbeData),
    .io_sinkC_bits_mshrRetry (RequestArb__io_sinkC_bits_mshrRetry),
    .io_sinkC_bits_readProbeDataDown (RequestArb__io_sinkC_bits_readProbeDataDown),
    .io_sinkC_bits_fromL2pft (RequestArb__io_sinkC_bits_fromL2pft),
    .io_sinkC_bits_needHint (RequestArb__io_sinkC_bits_needHint),
    .io_sinkC_bits_dirty (RequestArb__io_sinkC_bits_dirty),
    .io_sinkC_bits_way (RequestArb__io_sinkC_bits_way),
    .io_sinkC_bits_meta_dirty (RequestArb__io_sinkC_bits_meta_dirty),
    .io_sinkC_bits_meta_state (RequestArb__io_sinkC_bits_meta_state),
    .io_sinkC_bits_meta_clients (RequestArb__io_sinkC_bits_meta_clients),
    .io_sinkC_bits_meta_alias (RequestArb__io_sinkC_bits_meta_alias),
    .io_sinkC_bits_meta_prefetch (RequestArb__io_sinkC_bits_meta_prefetch),
    .io_sinkC_bits_meta_prefetchSrc (RequestArb__io_sinkC_bits_meta_prefetchSrc),
    .io_sinkC_bits_meta_accessed (RequestArb__io_sinkC_bits_meta_accessed),
    .io_sinkC_bits_meta_tagErr (RequestArb__io_sinkC_bits_meta_tagErr),
    .io_sinkC_bits_meta_dataErr (RequestArb__io_sinkC_bits_meta_dataErr),
    .io_sinkC_bits_metaWen (RequestArb__io_sinkC_bits_metaWen),
    .io_sinkC_bits_tagWen (RequestArb__io_sinkC_bits_tagWen),
    .io_sinkC_bits_dsWen (RequestArb__io_sinkC_bits_dsWen),
    .io_sinkC_bits_wayMask (RequestArb__io_sinkC_bits_wayMask),
    .io_sinkC_bits_replTask (RequestArb__io_sinkC_bits_replTask),
    .io_sinkC_bits_cmoTask (RequestArb__io_sinkC_bits_cmoTask),
    .io_sinkC_bits_cmoAll (RequestArb__io_sinkC_bits_cmoAll),
    .io_sinkC_bits_reqSource (RequestArb__io_sinkC_bits_reqSource),
    .io_sinkC_bits_mergeA (RequestArb__io_sinkC_bits_mergeA),
    .io_sinkC_bits_aMergeTask_off (RequestArb__io_sinkC_bits_aMergeTask_off),
    .io_sinkC_bits_aMergeTask_alias (RequestArb__io_sinkC_bits_aMergeTask_alias),
    .io_sinkC_bits_aMergeTask_vaddr (RequestArb__io_sinkC_bits_aMergeTask_vaddr),
    .io_sinkC_bits_aMergeTask_isKeyword (RequestArb__io_sinkC_bits_aMergeTask_isKeyword),
    .io_sinkC_bits_aMergeTask_opcode (RequestArb__io_sinkC_bits_aMergeTask_opcode),
    .io_sinkC_bits_aMergeTask_param (RequestArb__io_sinkC_bits_aMergeTask_param),
    .io_sinkC_bits_aMergeTask_sourceId (RequestArb__io_sinkC_bits_aMergeTask_sourceId),
    .io_sinkC_bits_aMergeTask_meta_dirty (RequestArb__io_sinkC_bits_aMergeTask_meta_dirty),
    .io_sinkC_bits_aMergeTask_meta_state (RequestArb__io_sinkC_bits_aMergeTask_meta_state),
    .io_sinkC_bits_aMergeTask_meta_clients (RequestArb__io_sinkC_bits_aMergeTask_meta_clients),
    .io_sinkC_bits_aMergeTask_meta_alias (RequestArb__io_sinkC_bits_aMergeTask_meta_alias),
    .io_sinkC_bits_aMergeTask_meta_prefetch (RequestArb__io_sinkC_bits_aMergeTask_meta_prefetch),
    .io_sinkC_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_sinkC_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkC_bits_aMergeTask_meta_accessed (RequestArb__io_sinkC_bits_aMergeTask_meta_accessed),
    .io_sinkC_bits_aMergeTask_meta_tagErr (RequestArb__io_sinkC_bits_aMergeTask_meta_tagErr),
    .io_sinkC_bits_aMergeTask_meta_dataErr (RequestArb__io_sinkC_bits_aMergeTask_meta_dataErr),
    .io_sinkC_bits_snpHitRelease (RequestArb__io_sinkC_bits_snpHitRelease),
    .io_sinkC_bits_snpHitReleaseToInval (RequestArb__io_sinkC_bits_snpHitReleaseToInval),
    .io_sinkC_bits_snpHitReleaseToClean (RequestArb__io_sinkC_bits_snpHitReleaseToClean),
    .io_sinkC_bits_snpHitReleaseWithData (RequestArb__io_sinkC_bits_snpHitReleaseWithData),
    .io_sinkC_bits_snpHitReleaseIdx (RequestArb__io_sinkC_bits_snpHitReleaseIdx),
    .io_sinkC_bits_snpHitReleaseMeta_dirty (RequestArb__io_sinkC_bits_snpHitReleaseMeta_dirty),
    .io_sinkC_bits_snpHitReleaseMeta_state (RequestArb__io_sinkC_bits_snpHitReleaseMeta_state),
    .io_sinkC_bits_snpHitReleaseMeta_clients (RequestArb__io_sinkC_bits_snpHitReleaseMeta_clients),
    .io_sinkC_bits_snpHitReleaseMeta_alias (RequestArb__io_sinkC_bits_snpHitReleaseMeta_alias),
    .io_sinkC_bits_snpHitReleaseMeta_prefetch (RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetch),
    .io_sinkC_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkC_bits_snpHitReleaseMeta_accessed (RequestArb__io_sinkC_bits_snpHitReleaseMeta_accessed),
    .io_sinkC_bits_snpHitReleaseMeta_tagErr (RequestArb__io_sinkC_bits_snpHitReleaseMeta_tagErr),
    .io_sinkC_bits_snpHitReleaseMeta_dataErr (RequestArb__io_sinkC_bits_snpHitReleaseMeta_dataErr),
    .io_sinkC_bits_tgtID (RequestArb__io_sinkC_bits_tgtID),
    .io_sinkC_bits_srcID (RequestArb__io_sinkC_bits_srcID),
    .io_sinkC_bits_txnID (RequestArb__io_sinkC_bits_txnID),
    .io_sinkC_bits_homeNID (RequestArb__io_sinkC_bits_homeNID),
    .io_sinkC_bits_dbID (RequestArb__io_sinkC_bits_dbID),
    .io_sinkC_bits_fwdNID (RequestArb__io_sinkC_bits_fwdNID),
    .io_sinkC_bits_fwdTxnID (RequestArb__io_sinkC_bits_fwdTxnID),
    .io_sinkC_bits_chiOpcode (RequestArb__io_sinkC_bits_chiOpcode),
    .io_sinkC_bits_resp (RequestArb__io_sinkC_bits_resp),
    .io_sinkC_bits_fwdState (RequestArb__io_sinkC_bits_fwdState),
    .io_sinkC_bits_pCrdType (RequestArb__io_sinkC_bits_pCrdType),
    .io_sinkC_bits_retToSrc (RequestArb__io_sinkC_bits_retToSrc),
    .io_sinkC_bits_likelyshared (RequestArb__io_sinkC_bits_likelyshared),
    .io_sinkC_bits_expCompAck (RequestArb__io_sinkC_bits_expCompAck),
    .io_sinkC_bits_allowRetry (RequestArb__io_sinkC_bits_allowRetry),
    .io_sinkC_bits_memAttr_allocate (RequestArb__io_sinkC_bits_memAttr_allocate),
    .io_sinkC_bits_memAttr_cacheable (RequestArb__io_sinkC_bits_memAttr_cacheable),
    .io_sinkC_bits_memAttr_device (RequestArb__io_sinkC_bits_memAttr_device),
    .io_sinkC_bits_memAttr_ewa (RequestArb__io_sinkC_bits_memAttr_ewa),
    .io_sinkC_bits_traceTag (RequestArb__io_sinkC_bits_traceTag),
    .io_mshrTask_ready (g_RequestArb__io_mshrTask_ready),
    .io_mshrTask_valid (RequestArb__io_mshrTask_valid),
    .io_mshrTask_bits_channel (RequestArb__io_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel (RequestArb__io_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set (RequestArb__io_mshrTask_bits_set),
    .io_mshrTask_bits_tag (RequestArb__io_mshrTask_bits_tag),
    .io_mshrTask_bits_off (RequestArb__io_mshrTask_bits_off),
    .io_mshrTask_bits_alias (RequestArb__io_mshrTask_bits_alias),
    .io_mshrTask_bits_vaddr (RequestArb__io_mshrTask_bits_vaddr),
    .io_mshrTask_bits_isKeyword (RequestArb__io_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode (RequestArb__io_mshrTask_bits_opcode),
    .io_mshrTask_bits_param (RequestArb__io_mshrTask_bits_param),
    .io_mshrTask_bits_size (RequestArb__io_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId (RequestArb__io_mshrTask_bits_sourceId),
    .io_mshrTask_bits_bufIdx (RequestArb__io_mshrTask_bits_bufIdx),
    .io_mshrTask_bits_needProbeAckData (RequestArb__io_mshrTask_bits_needProbeAckData),
    .io_mshrTask_bits_denied (RequestArb__io_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt (RequestArb__io_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask (RequestArb__io_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId (RequestArb__io_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask (RequestArb__io_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData (RequestArb__io_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry (RequestArb__io_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown (RequestArb__io_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft (RequestArb__io_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_needHint (RequestArb__io_mshrTask_bits_needHint),
    .io_mshrTask_bits_dirty (RequestArb__io_mshrTask_bits_dirty),
    .io_mshrTask_bits_way (RequestArb__io_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty (RequestArb__io_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state (RequestArb__io_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients (RequestArb__io_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias (RequestArb__io_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch (RequestArb__io_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc (RequestArb__io_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed (RequestArb__io_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr (RequestArb__io_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr (RequestArb__io_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen (RequestArb__io_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen (RequestArb__io_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen (RequestArb__io_mshrTask_bits_dsWen),
    .io_mshrTask_bits_wayMask (RequestArb__io_mshrTask_bits_wayMask),
    .io_mshrTask_bits_replTask (RequestArb__io_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask (RequestArb__io_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_cmoAll (RequestArb__io_mshrTask_bits_cmoAll),
    .io_mshrTask_bits_reqSource (RequestArb__io_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA (RequestArb__io_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off (RequestArb__io_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias (RequestArb__io_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr (RequestArb__io_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword (RequestArb__io_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode (RequestArb__io_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param (RequestArb__io_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId (RequestArb__io_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty (RequestArb__io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state (RequestArb__io_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients (RequestArb__io_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias (RequestArb__io_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_prefetch (RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetch),
    .io_mshrTask_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetchSrc),
    .io_mshrTask_bits_aMergeTask_meta_accessed (RequestArb__io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_aMergeTask_meta_tagErr (RequestArb__io_mshrTask_bits_aMergeTask_meta_tagErr),
    .io_mshrTask_bits_aMergeTask_meta_dataErr (RequestArb__io_mshrTask_bits_aMergeTask_meta_dataErr),
    .io_mshrTask_bits_snpHitRelease (RequestArb__io_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval (RequestArb__io_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean (RequestArb__io_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData (RequestArb__io_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx (RequestArb__io_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID (RequestArb__io_mshrTask_bits_tgtID),
    .io_mshrTask_bits_srcID (RequestArb__io_mshrTask_bits_srcID),
    .io_mshrTask_bits_txnID (RequestArb__io_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID (RequestArb__io_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID (RequestArb__io_mshrTask_bits_dbID),
    .io_mshrTask_bits_fwdNID (RequestArb__io_mshrTask_bits_fwdNID),
    .io_mshrTask_bits_fwdTxnID (RequestArb__io_mshrTask_bits_fwdTxnID),
    .io_mshrTask_bits_chiOpcode (RequestArb__io_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp (RequestArb__io_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState (RequestArb__io_mshrTask_bits_fwdState),
    .io_mshrTask_bits_pCrdType (RequestArb__io_mshrTask_bits_pCrdType),
    .io_mshrTask_bits_retToSrc (RequestArb__io_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared (RequestArb__io_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck (RequestArb__io_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry (RequestArb__io_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate (RequestArb__io_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable (RequestArb__io_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_device (RequestArb__io_mshrTask_bits_memAttr_device),
    .io_mshrTask_bits_memAttr_ewa (RequestArb__io_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag (RequestArb__io_mshrTask_bits_traceTag),
    .io_dirRead_s1_ready (RequestArb__io_dirRead_s1_ready),
    .io_dirRead_s1_valid (g_RequestArb__io_dirRead_s1_valid),
    .io_dirRead_s1_bits_tag (g_RequestArb__io_dirRead_s1_bits_tag),
    .io_dirRead_s1_bits_set (g_RequestArb__io_dirRead_s1_bits_set),
    .io_dirRead_s1_bits_wayMask (g_RequestArb__io_dirRead_s1_bits_wayMask),
    .io_dirRead_s1_bits_replacerInfo_channel (g_RequestArb__io_dirRead_s1_bits_replacerInfo_channel),
    .io_dirRead_s1_bits_replacerInfo_opcode (g_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode),
    .io_dirRead_s1_bits_replacerInfo_reqSource (g_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource),
    .io_dirRead_s1_bits_replacerInfo_refill_prefetch (g_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch),
    .io_dirRead_s1_bits_refill (g_RequestArb__io_dirRead_s1_bits_refill),
    .io_dirRead_s1_bits_mshrId (g_RequestArb__io_dirRead_s1_bits_mshrId),
    .io_dirRead_s1_bits_cmoAll (g_RequestArb__io_dirRead_s1_bits_cmoAll),
    .io_dirRead_s1_bits_cmoWay (g_RequestArb__io_dirRead_s1_bits_cmoWay),
    .io_taskToPipe_s2_valid (g_RequestArb__io_taskToPipe_s2_valid),
    .io_taskToPipe_s2_bits_channel (g_RequestArb__io_taskToPipe_s2_bits_channel),
    .io_taskToPipe_s2_bits_txChannel (g_RequestArb__io_taskToPipe_s2_bits_txChannel),
    .io_taskToPipe_s2_bits_set (g_RequestArb__io_taskToPipe_s2_bits_set),
    .io_taskToPipe_s2_bits_tag (g_RequestArb__io_taskToPipe_s2_bits_tag),
    .io_taskToPipe_s2_bits_off (g_RequestArb__io_taskToPipe_s2_bits_off),
    .io_taskToPipe_s2_bits_alias (g_RequestArb__io_taskToPipe_s2_bits_alias),
    .io_taskToPipe_s2_bits_vaddr (g_RequestArb__io_taskToPipe_s2_bits_vaddr),
    .io_taskToPipe_s2_bits_isKeyword (g_RequestArb__io_taskToPipe_s2_bits_isKeyword),
    .io_taskToPipe_s2_bits_opcode (g_RequestArb__io_taskToPipe_s2_bits_opcode),
    .io_taskToPipe_s2_bits_param (g_RequestArb__io_taskToPipe_s2_bits_param),
    .io_taskToPipe_s2_bits_size (g_RequestArb__io_taskToPipe_s2_bits_size),
    .io_taskToPipe_s2_bits_sourceId (g_RequestArb__io_taskToPipe_s2_bits_sourceId),
    .io_taskToPipe_s2_bits_bufIdx (g_RequestArb__io_taskToPipe_s2_bits_bufIdx),
    .io_taskToPipe_s2_bits_needProbeAckData (g_RequestArb__io_taskToPipe_s2_bits_needProbeAckData),
    .io_taskToPipe_s2_bits_denied (g_RequestArb__io_taskToPipe_s2_bits_denied),
    .io_taskToPipe_s2_bits_corrupt (g_RequestArb__io_taskToPipe_s2_bits_corrupt),
    .io_taskToPipe_s2_bits_mshrTask (g_RequestArb__io_taskToPipe_s2_bits_mshrTask),
    .io_taskToPipe_s2_bits_mshrId (g_RequestArb__io_taskToPipe_s2_bits_mshrId),
    .io_taskToPipe_s2_bits_aliasTask (g_RequestArb__io_taskToPipe_s2_bits_aliasTask),
    .io_taskToPipe_s2_bits_useProbeData (g_RequestArb__io_taskToPipe_s2_bits_useProbeData),
    .io_taskToPipe_s2_bits_mshrRetry (g_RequestArb__io_taskToPipe_s2_bits_mshrRetry),
    .io_taskToPipe_s2_bits_readProbeDataDown (g_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown),
    .io_taskToPipe_s2_bits_fromL2pft (g_RequestArb__io_taskToPipe_s2_bits_fromL2pft),
    .io_taskToPipe_s2_bits_needHint (g_RequestArb__io_taskToPipe_s2_bits_needHint),
    .io_taskToPipe_s2_bits_dirty (g_RequestArb__io_taskToPipe_s2_bits_dirty),
    .io_taskToPipe_s2_bits_way (g_RequestArb__io_taskToPipe_s2_bits_way),
    .io_taskToPipe_s2_bits_meta_dirty (g_RequestArb__io_taskToPipe_s2_bits_meta_dirty),
    .io_taskToPipe_s2_bits_meta_state (g_RequestArb__io_taskToPipe_s2_bits_meta_state),
    .io_taskToPipe_s2_bits_meta_clients (g_RequestArb__io_taskToPipe_s2_bits_meta_clients),
    .io_taskToPipe_s2_bits_meta_alias (g_RequestArb__io_taskToPipe_s2_bits_meta_alias),
    .io_taskToPipe_s2_bits_meta_prefetch (g_RequestArb__io_taskToPipe_s2_bits_meta_prefetch),
    .io_taskToPipe_s2_bits_meta_prefetchSrc (g_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_meta_accessed (g_RequestArb__io_taskToPipe_s2_bits_meta_accessed),
    .io_taskToPipe_s2_bits_meta_tagErr (g_RequestArb__io_taskToPipe_s2_bits_meta_tagErr),
    .io_taskToPipe_s2_bits_meta_dataErr (g_RequestArb__io_taskToPipe_s2_bits_meta_dataErr),
    .io_taskToPipe_s2_bits_metaWen (g_RequestArb__io_taskToPipe_s2_bits_metaWen),
    .io_taskToPipe_s2_bits_tagWen (g_RequestArb__io_taskToPipe_s2_bits_tagWen),
    .io_taskToPipe_s2_bits_dsWen (g_RequestArb__io_taskToPipe_s2_bits_dsWen),
    .io_taskToPipe_s2_bits_wayMask (g_RequestArb__io_taskToPipe_s2_bits_wayMask),
    .io_taskToPipe_s2_bits_replTask (g_RequestArb__io_taskToPipe_s2_bits_replTask),
    .io_taskToPipe_s2_bits_cmoTask (g_RequestArb__io_taskToPipe_s2_bits_cmoTask),
    .io_taskToPipe_s2_bits_cmoAll (g_RequestArb__io_taskToPipe_s2_bits_cmoAll),
    .io_taskToPipe_s2_bits_reqSource (g_RequestArb__io_taskToPipe_s2_bits_reqSource),
    .io_taskToPipe_s2_bits_mergeA (g_RequestArb__io_taskToPipe_s2_bits_mergeA),
    .io_taskToPipe_s2_bits_aMergeTask_off (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off),
    .io_taskToPipe_s2_bits_aMergeTask_alias (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias),
    .io_taskToPipe_s2_bits_aMergeTask_vaddr (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr),
    .io_taskToPipe_s2_bits_aMergeTask_isKeyword (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword),
    .io_taskToPipe_s2_bits_aMergeTask_opcode (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode),
    .io_taskToPipe_s2_bits_aMergeTask_param (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param),
    .io_taskToPipe_s2_bits_aMergeTask_sourceId (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dirty (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty),
    .io_taskToPipe_s2_bits_aMergeTask_meta_state (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state),
    .io_taskToPipe_s2_bits_aMergeTask_meta_clients (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients),
    .io_taskToPipe_s2_bits_aMergeTask_meta_alias (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetch (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_aMergeTask_meta_accessed (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed),
    .io_taskToPipe_s2_bits_aMergeTask_meta_tagErr (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dataErr (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr),
    .io_taskToPipe_s2_bits_snpHitRelease (g_RequestArb__io_taskToPipe_s2_bits_snpHitRelease),
    .io_taskToPipe_s2_bits_snpHitReleaseToInval (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval),
    .io_taskToPipe_s2_bits_snpHitReleaseToClean (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean),
    .io_taskToPipe_s2_bits_snpHitReleaseWithData (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData),
    .io_taskToPipe_s2_bits_snpHitReleaseIdx (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_state (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_clients (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_alias (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskToPipe_s2_bits_tgtID (g_RequestArb__io_taskToPipe_s2_bits_tgtID),
    .io_taskToPipe_s2_bits_srcID (g_RequestArb__io_taskToPipe_s2_bits_srcID),
    .io_taskToPipe_s2_bits_txnID (g_RequestArb__io_taskToPipe_s2_bits_txnID),
    .io_taskToPipe_s2_bits_homeNID (g_RequestArb__io_taskToPipe_s2_bits_homeNID),
    .io_taskToPipe_s2_bits_dbID (g_RequestArb__io_taskToPipe_s2_bits_dbID),
    .io_taskToPipe_s2_bits_fwdNID (g_RequestArb__io_taskToPipe_s2_bits_fwdNID),
    .io_taskToPipe_s2_bits_fwdTxnID (g_RequestArb__io_taskToPipe_s2_bits_fwdTxnID),
    .io_taskToPipe_s2_bits_chiOpcode (g_RequestArb__io_taskToPipe_s2_bits_chiOpcode),
    .io_taskToPipe_s2_bits_resp (g_RequestArb__io_taskToPipe_s2_bits_resp),
    .io_taskToPipe_s2_bits_fwdState (g_RequestArb__io_taskToPipe_s2_bits_fwdState),
    .io_taskToPipe_s2_bits_pCrdType (g_RequestArb__io_taskToPipe_s2_bits_pCrdType),
    .io_taskToPipe_s2_bits_retToSrc (g_RequestArb__io_taskToPipe_s2_bits_retToSrc),
    .io_taskToPipe_s2_bits_likelyshared (g_RequestArb__io_taskToPipe_s2_bits_likelyshared),
    .io_taskToPipe_s2_bits_expCompAck (g_RequestArb__io_taskToPipe_s2_bits_expCompAck),
    .io_taskToPipe_s2_bits_allowRetry (g_RequestArb__io_taskToPipe_s2_bits_allowRetry),
    .io_taskToPipe_s2_bits_memAttr_allocate (g_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate),
    .io_taskToPipe_s2_bits_memAttr_cacheable (g_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable),
    .io_taskToPipe_s2_bits_memAttr_device (g_RequestArb__io_taskToPipe_s2_bits_memAttr_device),
    .io_taskToPipe_s2_bits_memAttr_ewa (g_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa),
    .io_taskToPipe_s2_bits_traceTag (g_RequestArb__io_taskToPipe_s2_bits_traceTag),
    .io_taskInfo_s1_valid (g_RequestArb__io_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel (g_RequestArb__io_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_txChannel (g_RequestArb__io_taskInfo_s1_bits_txChannel),
    .io_taskInfo_s1_bits_set (g_RequestArb__io_taskInfo_s1_bits_set),
    .io_taskInfo_s1_bits_tag (g_RequestArb__io_taskInfo_s1_bits_tag),
    .io_taskInfo_s1_bits_off (g_RequestArb__io_taskInfo_s1_bits_off),
    .io_taskInfo_s1_bits_alias (g_RequestArb__io_taskInfo_s1_bits_alias),
    .io_taskInfo_s1_bits_vaddr (g_RequestArb__io_taskInfo_s1_bits_vaddr),
    .io_taskInfo_s1_bits_isKeyword (g_RequestArb__io_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode (g_RequestArb__io_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_param (g_RequestArb__io_taskInfo_s1_bits_param),
    .io_taskInfo_s1_bits_size (g_RequestArb__io_taskInfo_s1_bits_size),
    .io_taskInfo_s1_bits_sourceId (g_RequestArb__io_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_bufIdx (g_RequestArb__io_taskInfo_s1_bits_bufIdx),
    .io_taskInfo_s1_bits_needProbeAckData (g_RequestArb__io_taskInfo_s1_bits_needProbeAckData),
    .io_taskInfo_s1_bits_denied (g_RequestArb__io_taskInfo_s1_bits_denied),
    .io_taskInfo_s1_bits_corrupt (g_RequestArb__io_taskInfo_s1_bits_corrupt),
    .io_taskInfo_s1_bits_mshrTask (g_RequestArb__io_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mshrId (g_RequestArb__io_taskInfo_s1_bits_mshrId),
    .io_taskInfo_s1_bits_aliasTask (g_RequestArb__io_taskInfo_s1_bits_aliasTask),
    .io_taskInfo_s1_bits_useProbeData (g_RequestArb__io_taskInfo_s1_bits_useProbeData),
    .io_taskInfo_s1_bits_mshrRetry (g_RequestArb__io_taskInfo_s1_bits_mshrRetry),
    .io_taskInfo_s1_bits_readProbeDataDown (g_RequestArb__io_taskInfo_s1_bits_readProbeDataDown),
    .io_taskInfo_s1_bits_fromL2pft (g_RequestArb__io_taskInfo_s1_bits_fromL2pft),
    .io_taskInfo_s1_bits_needHint (g_RequestArb__io_taskInfo_s1_bits_needHint),
    .io_taskInfo_s1_bits_dirty (g_RequestArb__io_taskInfo_s1_bits_dirty),
    .io_taskInfo_s1_bits_way (g_RequestArb__io_taskInfo_s1_bits_way),
    .io_taskInfo_s1_bits_meta_dirty (g_RequestArb__io_taskInfo_s1_bits_meta_dirty),
    .io_taskInfo_s1_bits_meta_state (g_RequestArb__io_taskInfo_s1_bits_meta_state),
    .io_taskInfo_s1_bits_meta_clients (g_RequestArb__io_taskInfo_s1_bits_meta_clients),
    .io_taskInfo_s1_bits_meta_alias (g_RequestArb__io_taskInfo_s1_bits_meta_alias),
    .io_taskInfo_s1_bits_meta_prefetch (g_RequestArb__io_taskInfo_s1_bits_meta_prefetch),
    .io_taskInfo_s1_bits_meta_prefetchSrc (g_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc),
    .io_taskInfo_s1_bits_meta_accessed (g_RequestArb__io_taskInfo_s1_bits_meta_accessed),
    .io_taskInfo_s1_bits_meta_tagErr (g_RequestArb__io_taskInfo_s1_bits_meta_tagErr),
    .io_taskInfo_s1_bits_meta_dataErr (g_RequestArb__io_taskInfo_s1_bits_meta_dataErr),
    .io_taskInfo_s1_bits_metaWen (g_RequestArb__io_taskInfo_s1_bits_metaWen),
    .io_taskInfo_s1_bits_tagWen (g_RequestArb__io_taskInfo_s1_bits_tagWen),
    .io_taskInfo_s1_bits_dsWen (g_RequestArb__io_taskInfo_s1_bits_dsWen),
    .io_taskInfo_s1_bits_wayMask (g_RequestArb__io_taskInfo_s1_bits_wayMask),
    .io_taskInfo_s1_bits_replTask (g_RequestArb__io_taskInfo_s1_bits_replTask),
    .io_taskInfo_s1_bits_cmoTask (g_RequestArb__io_taskInfo_s1_bits_cmoTask),
    .io_taskInfo_s1_bits_cmoAll (g_RequestArb__io_taskInfo_s1_bits_cmoAll),
    .io_taskInfo_s1_bits_reqSource (g_RequestArb__io_taskInfo_s1_bits_reqSource),
    .io_taskInfo_s1_bits_mergeA (g_RequestArb__io_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_off (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_off),
    .io_taskInfo_s1_bits_aMergeTask_alias (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias),
    .io_taskInfo_s1_bits_aMergeTask_vaddr (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_param (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_param),
    .io_taskInfo_s1_bits_aMergeTask_sourceId (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_taskInfo_s1_bits_aMergeTask_meta_dirty (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty),
    .io_taskInfo_s1_bits_aMergeTask_meta_state (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state),
    .io_taskInfo_s1_bits_aMergeTask_meta_clients (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients),
    .io_taskInfo_s1_bits_aMergeTask_meta_alias (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetch (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc),
    .io_taskInfo_s1_bits_aMergeTask_meta_accessed (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed),
    .io_taskInfo_s1_bits_aMergeTask_meta_tagErr (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr),
    .io_taskInfo_s1_bits_aMergeTask_meta_dataErr (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr),
    .io_taskInfo_s1_bits_snpHitRelease (g_RequestArb__io_taskInfo_s1_bits_snpHitRelease),
    .io_taskInfo_s1_bits_snpHitReleaseToInval (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval),
    .io_taskInfo_s1_bits_snpHitReleaseToClean (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean),
    .io_taskInfo_s1_bits_snpHitReleaseWithData (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData),
    .io_taskInfo_s1_bits_snpHitReleaseIdx (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dirty (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_state (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_clients (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_alias (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_accessed (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr),
    .io_taskInfo_s1_bits_tgtID (g_RequestArb__io_taskInfo_s1_bits_tgtID),
    .io_taskInfo_s1_bits_srcID (g_RequestArb__io_taskInfo_s1_bits_srcID),
    .io_taskInfo_s1_bits_txnID (g_RequestArb__io_taskInfo_s1_bits_txnID),
    .io_taskInfo_s1_bits_homeNID (g_RequestArb__io_taskInfo_s1_bits_homeNID),
    .io_taskInfo_s1_bits_dbID (g_RequestArb__io_taskInfo_s1_bits_dbID),
    .io_taskInfo_s1_bits_fwdNID (g_RequestArb__io_taskInfo_s1_bits_fwdNID),
    .io_taskInfo_s1_bits_fwdTxnID (g_RequestArb__io_taskInfo_s1_bits_fwdTxnID),
    .io_taskInfo_s1_bits_chiOpcode (g_RequestArb__io_taskInfo_s1_bits_chiOpcode),
    .io_taskInfo_s1_bits_resp (g_RequestArb__io_taskInfo_s1_bits_resp),
    .io_taskInfo_s1_bits_fwdState (g_RequestArb__io_taskInfo_s1_bits_fwdState),
    .io_taskInfo_s1_bits_pCrdType (g_RequestArb__io_taskInfo_s1_bits_pCrdType),
    .io_taskInfo_s1_bits_retToSrc (g_RequestArb__io_taskInfo_s1_bits_retToSrc),
    .io_taskInfo_s1_bits_likelyshared (g_RequestArb__io_taskInfo_s1_bits_likelyshared),
    .io_taskInfo_s1_bits_expCompAck (g_RequestArb__io_taskInfo_s1_bits_expCompAck),
    .io_taskInfo_s1_bits_allowRetry (g_RequestArb__io_taskInfo_s1_bits_allowRetry),
    .io_taskInfo_s1_bits_memAttr_allocate (g_RequestArb__io_taskInfo_s1_bits_memAttr_allocate),
    .io_taskInfo_s1_bits_memAttr_cacheable (g_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable),
    .io_taskInfo_s1_bits_memAttr_device (g_RequestArb__io_taskInfo_s1_bits_memAttr_device),
    .io_taskInfo_s1_bits_memAttr_ewa (g_RequestArb__io_taskInfo_s1_bits_memAttr_ewa),
    .io_taskInfo_s1_bits_traceTag (g_RequestArb__io_taskInfo_s1_bits_traceTag),
    .io_refillBufRead_s2_valid (g_RequestArb__io_refillBufRead_s2_valid),
    .io_refillBufRead_s2_bits_id (g_RequestArb__io_refillBufRead_s2_bits_id),
    .io_releaseBufRead_s2_valid (g_RequestArb__io_releaseBufRead_s2_valid),
    .io_releaseBufRead_s2_bits_id (g_RequestArb__io_releaseBufRead_s2_bits_id),
    .io_status_s1_tags_0 (g_RequestArb__io_status_s1_tags_0),
    .io_status_s1_tags_1 (g_RequestArb__io_status_s1_tags_1),
    .io_status_s1_tags_2 (g_RequestArb__io_status_s1_tags_2),
    .io_status_s1_tags_3 (g_RequestArb__io_status_s1_tags_3),
    .io_status_s1_sets_0 (g_RequestArb__io_status_s1_sets_0),
    .io_status_s1_sets_1 (g_RequestArb__io_status_s1_sets_1),
    .io_status_s1_sets_2 (g_RequestArb__io_status_s1_sets_2),
    .io_status_s1_sets_3 (g_RequestArb__io_status_s1_sets_3),
    .io_status_vec_0_valid (g_RequestArb__io_status_vec_0_valid),
    .io_status_vec_0_bits_channel (g_RequestArb__io_status_vec_0_bits_channel),
    .io_status_vec_1_valid (g_RequestArb__io_status_vec_1_valid),
    .io_status_vec_1_bits_channel (g_RequestArb__io_status_vec_1_bits_channel),
    .io_status_vec_toTX_0_valid (g_RequestArb__io_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel (g_RequestArb__io_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel (g_RequestArb__io_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask (g_RequestArb__io_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid (g_RequestArb__io_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel (g_RequestArb__io_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel (g_RequestArb__io_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask (g_RequestArb__io_status_vec_toTX_1_bits_mshrTask),
    .io_fromMSHRCtl_blockG_s1 (RequestArb__io_fromMSHRCtl_blockG_s1),
    .io_fromMSHRCtl_blockA_s1 (RequestArb__io_fromMSHRCtl_blockA_s1),
    .io_fromMSHRCtl_blockB_s1 (RequestArb__io_fromMSHRCtl_blockB_s1),
    .io_fromMSHRCtl_blockC_s1 (RequestArb__io_fromMSHRCtl_blockC_s1),
    .io_fromMainPipe_blockG_s1 (RequestArb__io_fromMainPipe_blockG_s1),
    .io_fromMainPipe_blockA_s1 (RequestArb__io_fromMainPipe_blockA_s1),
    .io_fromMainPipe_blockB_s1 (RequestArb__io_fromMainPipe_blockB_s1),
    .io_fromMainPipe_blockC_s1 (RequestArb__io_fromMainPipe_blockC_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1),
    .io_fromGrantBuffer_blockMSHRReqEntrance (RequestArb__io_fromGrantBuffer_blockMSHRReqEntrance),
    .io_fromTXDAT_blockMSHRReqEntrance (RequestArb__io_fromTXDAT_blockMSHRReqEntrance),
    .io_fromTXDAT_blockSinkBReqEntrance (RequestArb__io_fromTXDAT_blockSinkBReqEntrance),
    .io_fromTXRSP_blockMSHRReqEntrance (RequestArb__io_fromTXRSP_blockMSHRReqEntrance),
    .io_fromTXRSP_blockSinkBReqEntrance (RequestArb__io_fromTXRSP_blockSinkBReqEntrance),
    .io_fromTXREQ_blockMSHRReqEntrance (RequestArb__io_fromTXREQ_blockMSHRReqEntrance),
    .io_msInfo_0_valid (RequestArb__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (RequestArb__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (RequestArb__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (RequestArb__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (RequestArb__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (RequestArb__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (RequestArb__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (RequestArb__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (RequestArb__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (RequestArb__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (RequestArb__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (RequestArb__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (RequestArb__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (RequestArb__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (RequestArb__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (RequestArb__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (RequestArb__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (RequestArb__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (RequestArb__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (RequestArb__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (RequestArb__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (RequestArb__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (RequestArb__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (RequestArb__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (RequestArb__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (RequestArb__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (RequestArb__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (RequestArb__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (RequestArb__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (RequestArb__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (RequestArb__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (RequestArb__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (RequestArb__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (RequestArb__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (RequestArb__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (RequestArb__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (RequestArb__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (RequestArb__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (RequestArb__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (RequestArb__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (RequestArb__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (RequestArb__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (RequestArb__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (RequestArb__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (RequestArb__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (RequestArb__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (RequestArb__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (RequestArb__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (RequestArb__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (RequestArb__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (RequestArb__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (RequestArb__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (RequestArb__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (RequestArb__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (RequestArb__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (RequestArb__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (RequestArb__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (RequestArb__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (RequestArb__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (RequestArb__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (RequestArb__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (RequestArb__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (RequestArb__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (RequestArb__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (RequestArb__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (RequestArb__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (RequestArb__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (RequestArb__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (RequestArb__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (RequestArb__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (RequestArb__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (RequestArb__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (RequestArb__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (RequestArb__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (RequestArb__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (RequestArb__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (RequestArb__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (RequestArb__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (RequestArb__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (RequestArb__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (RequestArb__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (RequestArb__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (RequestArb__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (RequestArb__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (RequestArb__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (RequestArb__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (RequestArb__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (RequestArb__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (RequestArb__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (RequestArb__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (RequestArb__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (RequestArb__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (RequestArb__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (RequestArb__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (RequestArb__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (RequestArb__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (RequestArb__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (RequestArb__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (RequestArb__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (RequestArb__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (RequestArb__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (RequestArb__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (RequestArb__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (RequestArb__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (RequestArb__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (RequestArb__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (RequestArb__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (RequestArb__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (RequestArb__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (RequestArb__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (RequestArb__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (RequestArb__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (RequestArb__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (RequestArb__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (RequestArb__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (RequestArb__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (RequestArb__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (RequestArb__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (RequestArb__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (RequestArb__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (RequestArb__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (RequestArb__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (RequestArb__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (RequestArb__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (RequestArb__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (RequestArb__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (RequestArb__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (RequestArb__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (RequestArb__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (RequestArb__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (RequestArb__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (RequestArb__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (RequestArb__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (RequestArb__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (RequestArb__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (RequestArb__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (RequestArb__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (RequestArb__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (RequestArb__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (RequestArb__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (RequestArb__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (RequestArb__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (RequestArb__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (RequestArb__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (RequestArb__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (RequestArb__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (RequestArb__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (RequestArb__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (RequestArb__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (RequestArb__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (RequestArb__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (RequestArb__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (RequestArb__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (RequestArb__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (RequestArb__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (RequestArb__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (RequestArb__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (RequestArb__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (RequestArb__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (RequestArb__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (RequestArb__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (RequestArb__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (RequestArb__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (RequestArb__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (RequestArb__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (RequestArb__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (RequestArb__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (RequestArb__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (RequestArb__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (RequestArb__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (RequestArb__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (RequestArb__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (RequestArb__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (RequestArb__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (RequestArb__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (RequestArb__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (RequestArb__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (RequestArb__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (RequestArb__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (RequestArb__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (RequestArb__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (RequestArb__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (RequestArb__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (RequestArb__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (RequestArb__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (RequestArb__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (RequestArb__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (RequestArb__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (RequestArb__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (RequestArb__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (RequestArb__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (RequestArb__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (RequestArb__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (RequestArb__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (RequestArb__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (RequestArb__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (RequestArb__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (RequestArb__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (RequestArb__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (RequestArb__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (RequestArb__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (RequestArb__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (RequestArb__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (RequestArb__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (RequestArb__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (RequestArb__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (RequestArb__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (RequestArb__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (RequestArb__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (RequestArb__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (RequestArb__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (RequestArb__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (RequestArb__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (RequestArb__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (RequestArb__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (RequestArb__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (RequestArb__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (RequestArb__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (RequestArb__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (RequestArb__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (RequestArb__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (RequestArb__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (RequestArb__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (RequestArb__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (RequestArb__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (RequestArb__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (RequestArb__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (RequestArb__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (RequestArb__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (RequestArb__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (RequestArb__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (RequestArb__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (RequestArb__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (RequestArb__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (RequestArb__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (RequestArb__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (RequestArb__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (RequestArb__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (RequestArb__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (RequestArb__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (RequestArb__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (RequestArb__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (RequestArb__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (RequestArb__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (RequestArb__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (RequestArb__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (RequestArb__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (RequestArb__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (RequestArb__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (RequestArb__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (RequestArb__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (RequestArb__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (RequestArb__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (RequestArb__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (RequestArb__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (RequestArb__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (RequestArb__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (RequestArb__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (RequestArb__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (RequestArb__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (RequestArb__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (RequestArb__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (RequestArb__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (RequestArb__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (RequestArb__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (RequestArb__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (RequestArb__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (RequestArb__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (RequestArb__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (RequestArb__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (RequestArb__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (RequestArb__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (RequestArb__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (RequestArb__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (RequestArb__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (RequestArb__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (RequestArb__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (RequestArb__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (RequestArb__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (RequestArb__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (RequestArb__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (RequestArb__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (RequestArb__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (RequestArb__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (RequestArb__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (RequestArb__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (RequestArb__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (RequestArb__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (RequestArb__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (RequestArb__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (RequestArb__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (RequestArb__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (RequestArb__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (RequestArb__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (RequestArb__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (RequestArb__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (RequestArb__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (RequestArb__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (RequestArb__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (RequestArb__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (RequestArb__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (RequestArb__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (RequestArb__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (RequestArb__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (RequestArb__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (RequestArb__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (RequestArb__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (RequestArb__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (RequestArb__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (RequestArb__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (RequestArb__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (RequestArb__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (RequestArb__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (RequestArb__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (RequestArb__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (RequestArb__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (RequestArb__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (RequestArb__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (RequestArb__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (RequestArb__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (RequestArb__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (RequestArb__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (RequestArb__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (RequestArb__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (RequestArb__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (RequestArb__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (RequestArb__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (RequestArb__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (RequestArb__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (RequestArb__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (RequestArb__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (RequestArb__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (RequestArb__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (RequestArb__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (RequestArb__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (RequestArb__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (RequestArb__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (RequestArb__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (RequestArb__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (RequestArb__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (RequestArb__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (RequestArb__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (RequestArb__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (RequestArb__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (RequestArb__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (RequestArb__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (RequestArb__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (RequestArb__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (RequestArb__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (RequestArb__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (RequestArb__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (RequestArb__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (RequestArb__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (RequestArb__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (RequestArb__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (RequestArb__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (RequestArb__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (RequestArb__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (RequestArb__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (RequestArb__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (RequestArb__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (RequestArb__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (RequestArb__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (RequestArb__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (RequestArb__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (RequestArb__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (RequestArb__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (RequestArb__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (RequestArb__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (RequestArb__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (RequestArb__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (RequestArb__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (RequestArb__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (RequestArb__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (RequestArb__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (RequestArb__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (RequestArb__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (RequestArb__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (RequestArb__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (RequestArb__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (RequestArb__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (RequestArb__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (RequestArb__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (RequestArb__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (RequestArb__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (RequestArb__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (RequestArb__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (RequestArb__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (RequestArb__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (RequestArb__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (RequestArb__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (RequestArb__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (RequestArb__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (RequestArb__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (RequestArb__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (RequestArb__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (RequestArb__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (RequestArb__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (RequestArb__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (RequestArb__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (RequestArb__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (RequestArb__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (RequestArb__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (RequestArb__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (RequestArb__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (RequestArb__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (RequestArb__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (RequestArb__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (RequestArb__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (RequestArb__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (RequestArb__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (RequestArb__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (RequestArb__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (RequestArb__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (RequestArb__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (RequestArb__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (RequestArb__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (RequestArb__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (RequestArb__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (RequestArb__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (RequestArb__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (RequestArb__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (RequestArb__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (RequestArb__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (RequestArb__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (RequestArb__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (RequestArb__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (RequestArb__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (RequestArb__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (RequestArb__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (RequestArb__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (RequestArb__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (RequestArb__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (RequestArb__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (RequestArb__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (RequestArb__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (RequestArb__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (RequestArb__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (RequestArb__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (RequestArb__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (RequestArb__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (RequestArb__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (RequestArb__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (RequestArb__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (RequestArb__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (RequestArb__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (RequestArb__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (RequestArb__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (RequestArb__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (RequestArb__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (RequestArb__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (RequestArb__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (RequestArb__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (RequestArb__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (RequestArb__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (RequestArb__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (RequestArb__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (RequestArb__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (RequestArb__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (RequestArb__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (RequestArb__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (RequestArb__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (RequestArb__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (RequestArb__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (RequestArb__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (RequestArb__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (RequestArb__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (RequestArb__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (RequestArb__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (RequestArb__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (RequestArb__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (RequestArb__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (RequestArb__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (RequestArb__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (RequestArb__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (RequestArb__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (RequestArb__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (RequestArb__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (RequestArb__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (RequestArb__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (RequestArb__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (RequestArb__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (RequestArb__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (RequestArb__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (RequestArb__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (RequestArb__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (RequestArb__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (RequestArb__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (RequestArb__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (RequestArb__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (RequestArb__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (RequestArb__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (RequestArb__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (RequestArb__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (RequestArb__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (RequestArb__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (RequestArb__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (RequestArb__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (RequestArb__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (RequestArb__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (RequestArb__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (RequestArb__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (RequestArb__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (RequestArb__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (RequestArb__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (RequestArb__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (RequestArb__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (RequestArb__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (RequestArb__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (RequestArb__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (RequestArb__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (RequestArb__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (RequestArb__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (RequestArb__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (RequestArb__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (RequestArb__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (RequestArb__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (RequestArb__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (RequestArb__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (RequestArb__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (RequestArb__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (RequestArb__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (RequestArb__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (RequestArb__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (RequestArb__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (RequestArb__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (RequestArb__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (RequestArb__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (RequestArb__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (RequestArb__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (RequestArb__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (RequestArb__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (RequestArb__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (RequestArb__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (RequestArb__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (RequestArb__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (RequestArb__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (RequestArb__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (RequestArb__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (RequestArb__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (RequestArb__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (RequestArb__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (RequestArb__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (RequestArb__io_msInfo_15_bits_releaseToClean)
  );
  RequestArb_xs u_i_RequestArb (
    .clock (clock),
    .reset (reset),
    .io_sinkA_ready (i_RequestArb__io_sinkA_ready),
    .io_sinkA_valid (RequestArb__io_sinkA_valid),
    .io_sinkA_bits_channel (RequestArb__io_sinkA_bits_channel),
    .io_sinkA_bits_txChannel (RequestArb__io_sinkA_bits_txChannel),
    .io_sinkA_bits_set (RequestArb__io_sinkA_bits_set),
    .io_sinkA_bits_tag (RequestArb__io_sinkA_bits_tag),
    .io_sinkA_bits_off (RequestArb__io_sinkA_bits_off),
    .io_sinkA_bits_alias (RequestArb__io_sinkA_bits_alias),
    .io_sinkA_bits_vaddr (RequestArb__io_sinkA_bits_vaddr),
    .io_sinkA_bits_isKeyword (RequestArb__io_sinkA_bits_isKeyword),
    .io_sinkA_bits_opcode (RequestArb__io_sinkA_bits_opcode),
    .io_sinkA_bits_param (RequestArb__io_sinkA_bits_param),
    .io_sinkA_bits_size (RequestArb__io_sinkA_bits_size),
    .io_sinkA_bits_sourceId (RequestArb__io_sinkA_bits_sourceId),
    .io_sinkA_bits_bufIdx (RequestArb__io_sinkA_bits_bufIdx),
    .io_sinkA_bits_needProbeAckData (RequestArb__io_sinkA_bits_needProbeAckData),
    .io_sinkA_bits_denied (RequestArb__io_sinkA_bits_denied),
    .io_sinkA_bits_corrupt (RequestArb__io_sinkA_bits_corrupt),
    .io_sinkA_bits_mshrTask (RequestArb__io_sinkA_bits_mshrTask),
    .io_sinkA_bits_mshrId (RequestArb__io_sinkA_bits_mshrId),
    .io_sinkA_bits_aliasTask (RequestArb__io_sinkA_bits_aliasTask),
    .io_sinkA_bits_useProbeData (RequestArb__io_sinkA_bits_useProbeData),
    .io_sinkA_bits_mshrRetry (RequestArb__io_sinkA_bits_mshrRetry),
    .io_sinkA_bits_readProbeDataDown (RequestArb__io_sinkA_bits_readProbeDataDown),
    .io_sinkA_bits_fromL2pft (RequestArb__io_sinkA_bits_fromL2pft),
    .io_sinkA_bits_needHint (RequestArb__io_sinkA_bits_needHint),
    .io_sinkA_bits_dirty (RequestArb__io_sinkA_bits_dirty),
    .io_sinkA_bits_way (RequestArb__io_sinkA_bits_way),
    .io_sinkA_bits_meta_dirty (RequestArb__io_sinkA_bits_meta_dirty),
    .io_sinkA_bits_meta_state (RequestArb__io_sinkA_bits_meta_state),
    .io_sinkA_bits_meta_clients (RequestArb__io_sinkA_bits_meta_clients),
    .io_sinkA_bits_meta_alias (RequestArb__io_sinkA_bits_meta_alias),
    .io_sinkA_bits_meta_prefetch (RequestArb__io_sinkA_bits_meta_prefetch),
    .io_sinkA_bits_meta_prefetchSrc (RequestArb__io_sinkA_bits_meta_prefetchSrc),
    .io_sinkA_bits_meta_accessed (RequestArb__io_sinkA_bits_meta_accessed),
    .io_sinkA_bits_meta_tagErr (RequestArb__io_sinkA_bits_meta_tagErr),
    .io_sinkA_bits_meta_dataErr (RequestArb__io_sinkA_bits_meta_dataErr),
    .io_sinkA_bits_metaWen (RequestArb__io_sinkA_bits_metaWen),
    .io_sinkA_bits_tagWen (RequestArb__io_sinkA_bits_tagWen),
    .io_sinkA_bits_dsWen (RequestArb__io_sinkA_bits_dsWen),
    .io_sinkA_bits_wayMask (RequestArb__io_sinkA_bits_wayMask),
    .io_sinkA_bits_replTask (RequestArb__io_sinkA_bits_replTask),
    .io_sinkA_bits_cmoTask (RequestArb__io_sinkA_bits_cmoTask),
    .io_sinkA_bits_cmoAll (RequestArb__io_sinkA_bits_cmoAll),
    .io_sinkA_bits_reqSource (RequestArb__io_sinkA_bits_reqSource),
    .io_sinkA_bits_mergeA (RequestArb__io_sinkA_bits_mergeA),
    .io_sinkA_bits_aMergeTask_off (RequestArb__io_sinkA_bits_aMergeTask_off),
    .io_sinkA_bits_aMergeTask_alias (RequestArb__io_sinkA_bits_aMergeTask_alias),
    .io_sinkA_bits_aMergeTask_vaddr (RequestArb__io_sinkA_bits_aMergeTask_vaddr),
    .io_sinkA_bits_aMergeTask_isKeyword (RequestArb__io_sinkA_bits_aMergeTask_isKeyword),
    .io_sinkA_bits_aMergeTask_opcode (RequestArb__io_sinkA_bits_aMergeTask_opcode),
    .io_sinkA_bits_aMergeTask_param (RequestArb__io_sinkA_bits_aMergeTask_param),
    .io_sinkA_bits_aMergeTask_sourceId (RequestArb__io_sinkA_bits_aMergeTask_sourceId),
    .io_sinkA_bits_aMergeTask_meta_dirty (RequestArb__io_sinkA_bits_aMergeTask_meta_dirty),
    .io_sinkA_bits_aMergeTask_meta_state (RequestArb__io_sinkA_bits_aMergeTask_meta_state),
    .io_sinkA_bits_aMergeTask_meta_clients (RequestArb__io_sinkA_bits_aMergeTask_meta_clients),
    .io_sinkA_bits_aMergeTask_meta_alias (RequestArb__io_sinkA_bits_aMergeTask_meta_alias),
    .io_sinkA_bits_aMergeTask_meta_prefetch (RequestArb__io_sinkA_bits_aMergeTask_meta_prefetch),
    .io_sinkA_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_sinkA_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkA_bits_aMergeTask_meta_accessed (RequestArb__io_sinkA_bits_aMergeTask_meta_accessed),
    .io_sinkA_bits_aMergeTask_meta_tagErr (RequestArb__io_sinkA_bits_aMergeTask_meta_tagErr),
    .io_sinkA_bits_aMergeTask_meta_dataErr (RequestArb__io_sinkA_bits_aMergeTask_meta_dataErr),
    .io_sinkA_bits_snpHitRelease (RequestArb__io_sinkA_bits_snpHitRelease),
    .io_sinkA_bits_snpHitReleaseToInval (RequestArb__io_sinkA_bits_snpHitReleaseToInval),
    .io_sinkA_bits_snpHitReleaseToClean (RequestArb__io_sinkA_bits_snpHitReleaseToClean),
    .io_sinkA_bits_snpHitReleaseWithData (RequestArb__io_sinkA_bits_snpHitReleaseWithData),
    .io_sinkA_bits_snpHitReleaseIdx (RequestArb__io_sinkA_bits_snpHitReleaseIdx),
    .io_sinkA_bits_snpHitReleaseMeta_dirty (RequestArb__io_sinkA_bits_snpHitReleaseMeta_dirty),
    .io_sinkA_bits_snpHitReleaseMeta_state (RequestArb__io_sinkA_bits_snpHitReleaseMeta_state),
    .io_sinkA_bits_snpHitReleaseMeta_clients (RequestArb__io_sinkA_bits_snpHitReleaseMeta_clients),
    .io_sinkA_bits_snpHitReleaseMeta_alias (RequestArb__io_sinkA_bits_snpHitReleaseMeta_alias),
    .io_sinkA_bits_snpHitReleaseMeta_prefetch (RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetch),
    .io_sinkA_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkA_bits_snpHitReleaseMeta_accessed (RequestArb__io_sinkA_bits_snpHitReleaseMeta_accessed),
    .io_sinkA_bits_snpHitReleaseMeta_tagErr (RequestArb__io_sinkA_bits_snpHitReleaseMeta_tagErr),
    .io_sinkA_bits_snpHitReleaseMeta_dataErr (RequestArb__io_sinkA_bits_snpHitReleaseMeta_dataErr),
    .io_sinkA_bits_tgtID (RequestArb__io_sinkA_bits_tgtID),
    .io_sinkA_bits_srcID (RequestArb__io_sinkA_bits_srcID),
    .io_sinkA_bits_txnID (RequestArb__io_sinkA_bits_txnID),
    .io_sinkA_bits_homeNID (RequestArb__io_sinkA_bits_homeNID),
    .io_sinkA_bits_dbID (RequestArb__io_sinkA_bits_dbID),
    .io_sinkA_bits_fwdNID (RequestArb__io_sinkA_bits_fwdNID),
    .io_sinkA_bits_fwdTxnID (RequestArb__io_sinkA_bits_fwdTxnID),
    .io_sinkA_bits_chiOpcode (RequestArb__io_sinkA_bits_chiOpcode),
    .io_sinkA_bits_resp (RequestArb__io_sinkA_bits_resp),
    .io_sinkA_bits_fwdState (RequestArb__io_sinkA_bits_fwdState),
    .io_sinkA_bits_pCrdType (RequestArb__io_sinkA_bits_pCrdType),
    .io_sinkA_bits_retToSrc (RequestArb__io_sinkA_bits_retToSrc),
    .io_sinkA_bits_likelyshared (RequestArb__io_sinkA_bits_likelyshared),
    .io_sinkA_bits_expCompAck (RequestArb__io_sinkA_bits_expCompAck),
    .io_sinkA_bits_allowRetry (RequestArb__io_sinkA_bits_allowRetry),
    .io_sinkA_bits_memAttr_allocate (RequestArb__io_sinkA_bits_memAttr_allocate),
    .io_sinkA_bits_memAttr_cacheable (RequestArb__io_sinkA_bits_memAttr_cacheable),
    .io_sinkA_bits_memAttr_device (RequestArb__io_sinkA_bits_memAttr_device),
    .io_sinkA_bits_memAttr_ewa (RequestArb__io_sinkA_bits_memAttr_ewa),
    .io_sinkA_bits_traceTag (RequestArb__io_sinkA_bits_traceTag),
    .io_ATag (RequestArb__io_ATag),
    .io_ASet (RequestArb__io_ASet),
    .io_s1Entrance_valid (i_RequestArb__io_s1Entrance_valid),
    .io_s1Entrance_bits_set (i_RequestArb__io_s1Entrance_bits_set),
    .io_sinkB_ready (i_RequestArb__io_sinkB_ready),
    .io_sinkB_valid (RequestArb__io_sinkB_valid),
    .io_sinkB_bits_channel (RequestArb__io_sinkB_bits_channel),
    .io_sinkB_bits_txChannel (RequestArb__io_sinkB_bits_txChannel),
    .io_sinkB_bits_set (RequestArb__io_sinkB_bits_set),
    .io_sinkB_bits_tag (RequestArb__io_sinkB_bits_tag),
    .io_sinkB_bits_off (RequestArb__io_sinkB_bits_off),
    .io_sinkB_bits_alias (RequestArb__io_sinkB_bits_alias),
    .io_sinkB_bits_vaddr (RequestArb__io_sinkB_bits_vaddr),
    .io_sinkB_bits_isKeyword (RequestArb__io_sinkB_bits_isKeyword),
    .io_sinkB_bits_opcode (RequestArb__io_sinkB_bits_opcode),
    .io_sinkB_bits_param (RequestArb__io_sinkB_bits_param),
    .io_sinkB_bits_size (RequestArb__io_sinkB_bits_size),
    .io_sinkB_bits_sourceId (RequestArb__io_sinkB_bits_sourceId),
    .io_sinkB_bits_bufIdx (RequestArb__io_sinkB_bits_bufIdx),
    .io_sinkB_bits_needProbeAckData (RequestArb__io_sinkB_bits_needProbeAckData),
    .io_sinkB_bits_denied (RequestArb__io_sinkB_bits_denied),
    .io_sinkB_bits_corrupt (RequestArb__io_sinkB_bits_corrupt),
    .io_sinkB_bits_mshrTask (RequestArb__io_sinkB_bits_mshrTask),
    .io_sinkB_bits_mshrId (RequestArb__io_sinkB_bits_mshrId),
    .io_sinkB_bits_aliasTask (RequestArb__io_sinkB_bits_aliasTask),
    .io_sinkB_bits_useProbeData (RequestArb__io_sinkB_bits_useProbeData),
    .io_sinkB_bits_mshrRetry (RequestArb__io_sinkB_bits_mshrRetry),
    .io_sinkB_bits_readProbeDataDown (RequestArb__io_sinkB_bits_readProbeDataDown),
    .io_sinkB_bits_fromL2pft (RequestArb__io_sinkB_bits_fromL2pft),
    .io_sinkB_bits_needHint (RequestArb__io_sinkB_bits_needHint),
    .io_sinkB_bits_dirty (RequestArb__io_sinkB_bits_dirty),
    .io_sinkB_bits_way (RequestArb__io_sinkB_bits_way),
    .io_sinkB_bits_meta_dirty (RequestArb__io_sinkB_bits_meta_dirty),
    .io_sinkB_bits_meta_state (RequestArb__io_sinkB_bits_meta_state),
    .io_sinkB_bits_meta_clients (RequestArb__io_sinkB_bits_meta_clients),
    .io_sinkB_bits_meta_alias (RequestArb__io_sinkB_bits_meta_alias),
    .io_sinkB_bits_meta_prefetch (RequestArb__io_sinkB_bits_meta_prefetch),
    .io_sinkB_bits_meta_prefetchSrc (RequestArb__io_sinkB_bits_meta_prefetchSrc),
    .io_sinkB_bits_meta_accessed (RequestArb__io_sinkB_bits_meta_accessed),
    .io_sinkB_bits_meta_tagErr (RequestArb__io_sinkB_bits_meta_tagErr),
    .io_sinkB_bits_meta_dataErr (RequestArb__io_sinkB_bits_meta_dataErr),
    .io_sinkB_bits_metaWen (RequestArb__io_sinkB_bits_metaWen),
    .io_sinkB_bits_tagWen (RequestArb__io_sinkB_bits_tagWen),
    .io_sinkB_bits_dsWen (RequestArb__io_sinkB_bits_dsWen),
    .io_sinkB_bits_wayMask (RequestArb__io_sinkB_bits_wayMask),
    .io_sinkB_bits_replTask (RequestArb__io_sinkB_bits_replTask),
    .io_sinkB_bits_cmoTask (RequestArb__io_sinkB_bits_cmoTask),
    .io_sinkB_bits_cmoAll (RequestArb__io_sinkB_bits_cmoAll),
    .io_sinkB_bits_reqSource (RequestArb__io_sinkB_bits_reqSource),
    .io_sinkB_bits_mergeA (RequestArb__io_sinkB_bits_mergeA),
    .io_sinkB_bits_aMergeTask_off (RequestArb__io_sinkB_bits_aMergeTask_off),
    .io_sinkB_bits_aMergeTask_alias (RequestArb__io_sinkB_bits_aMergeTask_alias),
    .io_sinkB_bits_aMergeTask_vaddr (RequestArb__io_sinkB_bits_aMergeTask_vaddr),
    .io_sinkB_bits_aMergeTask_isKeyword (RequestArb__io_sinkB_bits_aMergeTask_isKeyword),
    .io_sinkB_bits_aMergeTask_opcode (RequestArb__io_sinkB_bits_aMergeTask_opcode),
    .io_sinkB_bits_aMergeTask_param (RequestArb__io_sinkB_bits_aMergeTask_param),
    .io_sinkB_bits_aMergeTask_sourceId (RequestArb__io_sinkB_bits_aMergeTask_sourceId),
    .io_sinkB_bits_aMergeTask_meta_dirty (RequestArb__io_sinkB_bits_aMergeTask_meta_dirty),
    .io_sinkB_bits_aMergeTask_meta_state (RequestArb__io_sinkB_bits_aMergeTask_meta_state),
    .io_sinkB_bits_aMergeTask_meta_clients (RequestArb__io_sinkB_bits_aMergeTask_meta_clients),
    .io_sinkB_bits_aMergeTask_meta_alias (RequestArb__io_sinkB_bits_aMergeTask_meta_alias),
    .io_sinkB_bits_aMergeTask_meta_prefetch (RequestArb__io_sinkB_bits_aMergeTask_meta_prefetch),
    .io_sinkB_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_sinkB_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkB_bits_aMergeTask_meta_accessed (RequestArb__io_sinkB_bits_aMergeTask_meta_accessed),
    .io_sinkB_bits_aMergeTask_meta_tagErr (RequestArb__io_sinkB_bits_aMergeTask_meta_tagErr),
    .io_sinkB_bits_aMergeTask_meta_dataErr (RequestArb__io_sinkB_bits_aMergeTask_meta_dataErr),
    .io_sinkB_bits_snpHitRelease (RequestArb__io_sinkB_bits_snpHitRelease),
    .io_sinkB_bits_snpHitReleaseToInval (RequestArb__io_sinkB_bits_snpHitReleaseToInval),
    .io_sinkB_bits_snpHitReleaseToClean (RequestArb__io_sinkB_bits_snpHitReleaseToClean),
    .io_sinkB_bits_snpHitReleaseWithData (RequestArb__io_sinkB_bits_snpHitReleaseWithData),
    .io_sinkB_bits_snpHitReleaseIdx (RequestArb__io_sinkB_bits_snpHitReleaseIdx),
    .io_sinkB_bits_snpHitReleaseMeta_dirty (RequestArb__io_sinkB_bits_snpHitReleaseMeta_dirty),
    .io_sinkB_bits_snpHitReleaseMeta_state (RequestArb__io_sinkB_bits_snpHitReleaseMeta_state),
    .io_sinkB_bits_snpHitReleaseMeta_clients (RequestArb__io_sinkB_bits_snpHitReleaseMeta_clients),
    .io_sinkB_bits_snpHitReleaseMeta_alias (RequestArb__io_sinkB_bits_snpHitReleaseMeta_alias),
    .io_sinkB_bits_snpHitReleaseMeta_prefetch (RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetch),
    .io_sinkB_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkB_bits_snpHitReleaseMeta_accessed (RequestArb__io_sinkB_bits_snpHitReleaseMeta_accessed),
    .io_sinkB_bits_snpHitReleaseMeta_tagErr (RequestArb__io_sinkB_bits_snpHitReleaseMeta_tagErr),
    .io_sinkB_bits_snpHitReleaseMeta_dataErr (RequestArb__io_sinkB_bits_snpHitReleaseMeta_dataErr),
    .io_sinkB_bits_tgtID (RequestArb__io_sinkB_bits_tgtID),
    .io_sinkB_bits_srcID (RequestArb__io_sinkB_bits_srcID),
    .io_sinkB_bits_txnID (RequestArb__io_sinkB_bits_txnID),
    .io_sinkB_bits_homeNID (RequestArb__io_sinkB_bits_homeNID),
    .io_sinkB_bits_dbID (RequestArb__io_sinkB_bits_dbID),
    .io_sinkB_bits_fwdNID (RequestArb__io_sinkB_bits_fwdNID),
    .io_sinkB_bits_fwdTxnID (RequestArb__io_sinkB_bits_fwdTxnID),
    .io_sinkB_bits_chiOpcode (RequestArb__io_sinkB_bits_chiOpcode),
    .io_sinkB_bits_resp (RequestArb__io_sinkB_bits_resp),
    .io_sinkB_bits_fwdState (RequestArb__io_sinkB_bits_fwdState),
    .io_sinkB_bits_pCrdType (RequestArb__io_sinkB_bits_pCrdType),
    .io_sinkB_bits_retToSrc (RequestArb__io_sinkB_bits_retToSrc),
    .io_sinkB_bits_likelyshared (RequestArb__io_sinkB_bits_likelyshared),
    .io_sinkB_bits_expCompAck (RequestArb__io_sinkB_bits_expCompAck),
    .io_sinkB_bits_allowRetry (RequestArb__io_sinkB_bits_allowRetry),
    .io_sinkB_bits_memAttr_allocate (RequestArb__io_sinkB_bits_memAttr_allocate),
    .io_sinkB_bits_memAttr_cacheable (RequestArb__io_sinkB_bits_memAttr_cacheable),
    .io_sinkB_bits_memAttr_device (RequestArb__io_sinkB_bits_memAttr_device),
    .io_sinkB_bits_memAttr_ewa (RequestArb__io_sinkB_bits_memAttr_ewa),
    .io_sinkB_bits_traceTag (RequestArb__io_sinkB_bits_traceTag),
    .io_sinkC_ready (i_RequestArb__io_sinkC_ready),
    .io_sinkC_valid (RequestArb__io_sinkC_valid),
    .io_sinkC_bits_channel (RequestArb__io_sinkC_bits_channel),
    .io_sinkC_bits_txChannel (RequestArb__io_sinkC_bits_txChannel),
    .io_sinkC_bits_set (RequestArb__io_sinkC_bits_set),
    .io_sinkC_bits_tag (RequestArb__io_sinkC_bits_tag),
    .io_sinkC_bits_off (RequestArb__io_sinkC_bits_off),
    .io_sinkC_bits_alias (RequestArb__io_sinkC_bits_alias),
    .io_sinkC_bits_vaddr (RequestArb__io_sinkC_bits_vaddr),
    .io_sinkC_bits_isKeyword (RequestArb__io_sinkC_bits_isKeyword),
    .io_sinkC_bits_opcode (RequestArb__io_sinkC_bits_opcode),
    .io_sinkC_bits_param (RequestArb__io_sinkC_bits_param),
    .io_sinkC_bits_size (RequestArb__io_sinkC_bits_size),
    .io_sinkC_bits_sourceId (RequestArb__io_sinkC_bits_sourceId),
    .io_sinkC_bits_bufIdx (RequestArb__io_sinkC_bits_bufIdx),
    .io_sinkC_bits_needProbeAckData (RequestArb__io_sinkC_bits_needProbeAckData),
    .io_sinkC_bits_denied (RequestArb__io_sinkC_bits_denied),
    .io_sinkC_bits_corrupt (RequestArb__io_sinkC_bits_corrupt),
    .io_sinkC_bits_mshrTask (RequestArb__io_sinkC_bits_mshrTask),
    .io_sinkC_bits_mshrId (RequestArb__io_sinkC_bits_mshrId),
    .io_sinkC_bits_aliasTask (RequestArb__io_sinkC_bits_aliasTask),
    .io_sinkC_bits_useProbeData (RequestArb__io_sinkC_bits_useProbeData),
    .io_sinkC_bits_mshrRetry (RequestArb__io_sinkC_bits_mshrRetry),
    .io_sinkC_bits_readProbeDataDown (RequestArb__io_sinkC_bits_readProbeDataDown),
    .io_sinkC_bits_fromL2pft (RequestArb__io_sinkC_bits_fromL2pft),
    .io_sinkC_bits_needHint (RequestArb__io_sinkC_bits_needHint),
    .io_sinkC_bits_dirty (RequestArb__io_sinkC_bits_dirty),
    .io_sinkC_bits_way (RequestArb__io_sinkC_bits_way),
    .io_sinkC_bits_meta_dirty (RequestArb__io_sinkC_bits_meta_dirty),
    .io_sinkC_bits_meta_state (RequestArb__io_sinkC_bits_meta_state),
    .io_sinkC_bits_meta_clients (RequestArb__io_sinkC_bits_meta_clients),
    .io_sinkC_bits_meta_alias (RequestArb__io_sinkC_bits_meta_alias),
    .io_sinkC_bits_meta_prefetch (RequestArb__io_sinkC_bits_meta_prefetch),
    .io_sinkC_bits_meta_prefetchSrc (RequestArb__io_sinkC_bits_meta_prefetchSrc),
    .io_sinkC_bits_meta_accessed (RequestArb__io_sinkC_bits_meta_accessed),
    .io_sinkC_bits_meta_tagErr (RequestArb__io_sinkC_bits_meta_tagErr),
    .io_sinkC_bits_meta_dataErr (RequestArb__io_sinkC_bits_meta_dataErr),
    .io_sinkC_bits_metaWen (RequestArb__io_sinkC_bits_metaWen),
    .io_sinkC_bits_tagWen (RequestArb__io_sinkC_bits_tagWen),
    .io_sinkC_bits_dsWen (RequestArb__io_sinkC_bits_dsWen),
    .io_sinkC_bits_wayMask (RequestArb__io_sinkC_bits_wayMask),
    .io_sinkC_bits_replTask (RequestArb__io_sinkC_bits_replTask),
    .io_sinkC_bits_cmoTask (RequestArb__io_sinkC_bits_cmoTask),
    .io_sinkC_bits_cmoAll (RequestArb__io_sinkC_bits_cmoAll),
    .io_sinkC_bits_reqSource (RequestArb__io_sinkC_bits_reqSource),
    .io_sinkC_bits_mergeA (RequestArb__io_sinkC_bits_mergeA),
    .io_sinkC_bits_aMergeTask_off (RequestArb__io_sinkC_bits_aMergeTask_off),
    .io_sinkC_bits_aMergeTask_alias (RequestArb__io_sinkC_bits_aMergeTask_alias),
    .io_sinkC_bits_aMergeTask_vaddr (RequestArb__io_sinkC_bits_aMergeTask_vaddr),
    .io_sinkC_bits_aMergeTask_isKeyword (RequestArb__io_sinkC_bits_aMergeTask_isKeyword),
    .io_sinkC_bits_aMergeTask_opcode (RequestArb__io_sinkC_bits_aMergeTask_opcode),
    .io_sinkC_bits_aMergeTask_param (RequestArb__io_sinkC_bits_aMergeTask_param),
    .io_sinkC_bits_aMergeTask_sourceId (RequestArb__io_sinkC_bits_aMergeTask_sourceId),
    .io_sinkC_bits_aMergeTask_meta_dirty (RequestArb__io_sinkC_bits_aMergeTask_meta_dirty),
    .io_sinkC_bits_aMergeTask_meta_state (RequestArb__io_sinkC_bits_aMergeTask_meta_state),
    .io_sinkC_bits_aMergeTask_meta_clients (RequestArb__io_sinkC_bits_aMergeTask_meta_clients),
    .io_sinkC_bits_aMergeTask_meta_alias (RequestArb__io_sinkC_bits_aMergeTask_meta_alias),
    .io_sinkC_bits_aMergeTask_meta_prefetch (RequestArb__io_sinkC_bits_aMergeTask_meta_prefetch),
    .io_sinkC_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_sinkC_bits_aMergeTask_meta_prefetchSrc),
    .io_sinkC_bits_aMergeTask_meta_accessed (RequestArb__io_sinkC_bits_aMergeTask_meta_accessed),
    .io_sinkC_bits_aMergeTask_meta_tagErr (RequestArb__io_sinkC_bits_aMergeTask_meta_tagErr),
    .io_sinkC_bits_aMergeTask_meta_dataErr (RequestArb__io_sinkC_bits_aMergeTask_meta_dataErr),
    .io_sinkC_bits_snpHitRelease (RequestArb__io_sinkC_bits_snpHitRelease),
    .io_sinkC_bits_snpHitReleaseToInval (RequestArb__io_sinkC_bits_snpHitReleaseToInval),
    .io_sinkC_bits_snpHitReleaseToClean (RequestArb__io_sinkC_bits_snpHitReleaseToClean),
    .io_sinkC_bits_snpHitReleaseWithData (RequestArb__io_sinkC_bits_snpHitReleaseWithData),
    .io_sinkC_bits_snpHitReleaseIdx (RequestArb__io_sinkC_bits_snpHitReleaseIdx),
    .io_sinkC_bits_snpHitReleaseMeta_dirty (RequestArb__io_sinkC_bits_snpHitReleaseMeta_dirty),
    .io_sinkC_bits_snpHitReleaseMeta_state (RequestArb__io_sinkC_bits_snpHitReleaseMeta_state),
    .io_sinkC_bits_snpHitReleaseMeta_clients (RequestArb__io_sinkC_bits_snpHitReleaseMeta_clients),
    .io_sinkC_bits_snpHitReleaseMeta_alias (RequestArb__io_sinkC_bits_snpHitReleaseMeta_alias),
    .io_sinkC_bits_snpHitReleaseMeta_prefetch (RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetch),
    .io_sinkC_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetchSrc),
    .io_sinkC_bits_snpHitReleaseMeta_accessed (RequestArb__io_sinkC_bits_snpHitReleaseMeta_accessed),
    .io_sinkC_bits_snpHitReleaseMeta_tagErr (RequestArb__io_sinkC_bits_snpHitReleaseMeta_tagErr),
    .io_sinkC_bits_snpHitReleaseMeta_dataErr (RequestArb__io_sinkC_bits_snpHitReleaseMeta_dataErr),
    .io_sinkC_bits_tgtID (RequestArb__io_sinkC_bits_tgtID),
    .io_sinkC_bits_srcID (RequestArb__io_sinkC_bits_srcID),
    .io_sinkC_bits_txnID (RequestArb__io_sinkC_bits_txnID),
    .io_sinkC_bits_homeNID (RequestArb__io_sinkC_bits_homeNID),
    .io_sinkC_bits_dbID (RequestArb__io_sinkC_bits_dbID),
    .io_sinkC_bits_fwdNID (RequestArb__io_sinkC_bits_fwdNID),
    .io_sinkC_bits_fwdTxnID (RequestArb__io_sinkC_bits_fwdTxnID),
    .io_sinkC_bits_chiOpcode (RequestArb__io_sinkC_bits_chiOpcode),
    .io_sinkC_bits_resp (RequestArb__io_sinkC_bits_resp),
    .io_sinkC_bits_fwdState (RequestArb__io_sinkC_bits_fwdState),
    .io_sinkC_bits_pCrdType (RequestArb__io_sinkC_bits_pCrdType),
    .io_sinkC_bits_retToSrc (RequestArb__io_sinkC_bits_retToSrc),
    .io_sinkC_bits_likelyshared (RequestArb__io_sinkC_bits_likelyshared),
    .io_sinkC_bits_expCompAck (RequestArb__io_sinkC_bits_expCompAck),
    .io_sinkC_bits_allowRetry (RequestArb__io_sinkC_bits_allowRetry),
    .io_sinkC_bits_memAttr_allocate (RequestArb__io_sinkC_bits_memAttr_allocate),
    .io_sinkC_bits_memAttr_cacheable (RequestArb__io_sinkC_bits_memAttr_cacheable),
    .io_sinkC_bits_memAttr_device (RequestArb__io_sinkC_bits_memAttr_device),
    .io_sinkC_bits_memAttr_ewa (RequestArb__io_sinkC_bits_memAttr_ewa),
    .io_sinkC_bits_traceTag (RequestArb__io_sinkC_bits_traceTag),
    .io_mshrTask_ready (i_RequestArb__io_mshrTask_ready),
    .io_mshrTask_valid (RequestArb__io_mshrTask_valid),
    .io_mshrTask_bits_channel (RequestArb__io_mshrTask_bits_channel),
    .io_mshrTask_bits_txChannel (RequestArb__io_mshrTask_bits_txChannel),
    .io_mshrTask_bits_set (RequestArb__io_mshrTask_bits_set),
    .io_mshrTask_bits_tag (RequestArb__io_mshrTask_bits_tag),
    .io_mshrTask_bits_off (RequestArb__io_mshrTask_bits_off),
    .io_mshrTask_bits_alias (RequestArb__io_mshrTask_bits_alias),
    .io_mshrTask_bits_vaddr (RequestArb__io_mshrTask_bits_vaddr),
    .io_mshrTask_bits_isKeyword (RequestArb__io_mshrTask_bits_isKeyword),
    .io_mshrTask_bits_opcode (RequestArb__io_mshrTask_bits_opcode),
    .io_mshrTask_bits_param (RequestArb__io_mshrTask_bits_param),
    .io_mshrTask_bits_size (RequestArb__io_mshrTask_bits_size),
    .io_mshrTask_bits_sourceId (RequestArb__io_mshrTask_bits_sourceId),
    .io_mshrTask_bits_bufIdx (RequestArb__io_mshrTask_bits_bufIdx),
    .io_mshrTask_bits_needProbeAckData (RequestArb__io_mshrTask_bits_needProbeAckData),
    .io_mshrTask_bits_denied (RequestArb__io_mshrTask_bits_denied),
    .io_mshrTask_bits_corrupt (RequestArb__io_mshrTask_bits_corrupt),
    .io_mshrTask_bits_mshrTask (RequestArb__io_mshrTask_bits_mshrTask),
    .io_mshrTask_bits_mshrId (RequestArb__io_mshrTask_bits_mshrId),
    .io_mshrTask_bits_aliasTask (RequestArb__io_mshrTask_bits_aliasTask),
    .io_mshrTask_bits_useProbeData (RequestArb__io_mshrTask_bits_useProbeData),
    .io_mshrTask_bits_mshrRetry (RequestArb__io_mshrTask_bits_mshrRetry),
    .io_mshrTask_bits_readProbeDataDown (RequestArb__io_mshrTask_bits_readProbeDataDown),
    .io_mshrTask_bits_fromL2pft (RequestArb__io_mshrTask_bits_fromL2pft),
    .io_mshrTask_bits_needHint (RequestArb__io_mshrTask_bits_needHint),
    .io_mshrTask_bits_dirty (RequestArb__io_mshrTask_bits_dirty),
    .io_mshrTask_bits_way (RequestArb__io_mshrTask_bits_way),
    .io_mshrTask_bits_meta_dirty (RequestArb__io_mshrTask_bits_meta_dirty),
    .io_mshrTask_bits_meta_state (RequestArb__io_mshrTask_bits_meta_state),
    .io_mshrTask_bits_meta_clients (RequestArb__io_mshrTask_bits_meta_clients),
    .io_mshrTask_bits_meta_alias (RequestArb__io_mshrTask_bits_meta_alias),
    .io_mshrTask_bits_meta_prefetch (RequestArb__io_mshrTask_bits_meta_prefetch),
    .io_mshrTask_bits_meta_prefetchSrc (RequestArb__io_mshrTask_bits_meta_prefetchSrc),
    .io_mshrTask_bits_meta_accessed (RequestArb__io_mshrTask_bits_meta_accessed),
    .io_mshrTask_bits_meta_tagErr (RequestArb__io_mshrTask_bits_meta_tagErr),
    .io_mshrTask_bits_meta_dataErr (RequestArb__io_mshrTask_bits_meta_dataErr),
    .io_mshrTask_bits_metaWen (RequestArb__io_mshrTask_bits_metaWen),
    .io_mshrTask_bits_tagWen (RequestArb__io_mshrTask_bits_tagWen),
    .io_mshrTask_bits_dsWen (RequestArb__io_mshrTask_bits_dsWen),
    .io_mshrTask_bits_wayMask (RequestArb__io_mshrTask_bits_wayMask),
    .io_mshrTask_bits_replTask (RequestArb__io_mshrTask_bits_replTask),
    .io_mshrTask_bits_cmoTask (RequestArb__io_mshrTask_bits_cmoTask),
    .io_mshrTask_bits_cmoAll (RequestArb__io_mshrTask_bits_cmoAll),
    .io_mshrTask_bits_reqSource (RequestArb__io_mshrTask_bits_reqSource),
    .io_mshrTask_bits_mergeA (RequestArb__io_mshrTask_bits_mergeA),
    .io_mshrTask_bits_aMergeTask_off (RequestArb__io_mshrTask_bits_aMergeTask_off),
    .io_mshrTask_bits_aMergeTask_alias (RequestArb__io_mshrTask_bits_aMergeTask_alias),
    .io_mshrTask_bits_aMergeTask_vaddr (RequestArb__io_mshrTask_bits_aMergeTask_vaddr),
    .io_mshrTask_bits_aMergeTask_isKeyword (RequestArb__io_mshrTask_bits_aMergeTask_isKeyword),
    .io_mshrTask_bits_aMergeTask_opcode (RequestArb__io_mshrTask_bits_aMergeTask_opcode),
    .io_mshrTask_bits_aMergeTask_param (RequestArb__io_mshrTask_bits_aMergeTask_param),
    .io_mshrTask_bits_aMergeTask_sourceId (RequestArb__io_mshrTask_bits_aMergeTask_sourceId),
    .io_mshrTask_bits_aMergeTask_meta_dirty (RequestArb__io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_mshrTask_bits_aMergeTask_meta_state (RequestArb__io_mshrTask_bits_aMergeTask_meta_state),
    .io_mshrTask_bits_aMergeTask_meta_clients (RequestArb__io_mshrTask_bits_aMergeTask_meta_clients),
    .io_mshrTask_bits_aMergeTask_meta_alias (RequestArb__io_mshrTask_bits_aMergeTask_meta_alias),
    .io_mshrTask_bits_aMergeTask_meta_prefetch (RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetch),
    .io_mshrTask_bits_aMergeTask_meta_prefetchSrc (RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetchSrc),
    .io_mshrTask_bits_aMergeTask_meta_accessed (RequestArb__io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_mshrTask_bits_aMergeTask_meta_tagErr (RequestArb__io_mshrTask_bits_aMergeTask_meta_tagErr),
    .io_mshrTask_bits_aMergeTask_meta_dataErr (RequestArb__io_mshrTask_bits_aMergeTask_meta_dataErr),
    .io_mshrTask_bits_snpHitRelease (RequestArb__io_mshrTask_bits_snpHitRelease),
    .io_mshrTask_bits_snpHitReleaseToInval (RequestArb__io_mshrTask_bits_snpHitReleaseToInval),
    .io_mshrTask_bits_snpHitReleaseToClean (RequestArb__io_mshrTask_bits_snpHitReleaseToClean),
    .io_mshrTask_bits_snpHitReleaseWithData (RequestArb__io_mshrTask_bits_snpHitReleaseWithData),
    .io_mshrTask_bits_snpHitReleaseIdx (RequestArb__io_mshrTask_bits_snpHitReleaseIdx),
    .io_mshrTask_bits_snpHitReleaseMeta_dirty (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_mshrTask_bits_snpHitReleaseMeta_state (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_mshrTask_bits_snpHitReleaseMeta_clients (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_mshrTask_bits_snpHitReleaseMeta_alias (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetch (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_mshrTask_bits_snpHitReleaseMeta_accessed (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_mshrTask_bits_snpHitReleaseMeta_tagErr (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_mshrTask_bits_snpHitReleaseMeta_dataErr (RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_mshrTask_bits_tgtID (RequestArb__io_mshrTask_bits_tgtID),
    .io_mshrTask_bits_srcID (RequestArb__io_mshrTask_bits_srcID),
    .io_mshrTask_bits_txnID (RequestArb__io_mshrTask_bits_txnID),
    .io_mshrTask_bits_homeNID (RequestArb__io_mshrTask_bits_homeNID),
    .io_mshrTask_bits_dbID (RequestArb__io_mshrTask_bits_dbID),
    .io_mshrTask_bits_fwdNID (RequestArb__io_mshrTask_bits_fwdNID),
    .io_mshrTask_bits_fwdTxnID (RequestArb__io_mshrTask_bits_fwdTxnID),
    .io_mshrTask_bits_chiOpcode (RequestArb__io_mshrTask_bits_chiOpcode),
    .io_mshrTask_bits_resp (RequestArb__io_mshrTask_bits_resp),
    .io_mshrTask_bits_fwdState (RequestArb__io_mshrTask_bits_fwdState),
    .io_mshrTask_bits_pCrdType (RequestArb__io_mshrTask_bits_pCrdType),
    .io_mshrTask_bits_retToSrc (RequestArb__io_mshrTask_bits_retToSrc),
    .io_mshrTask_bits_likelyshared (RequestArb__io_mshrTask_bits_likelyshared),
    .io_mshrTask_bits_expCompAck (RequestArb__io_mshrTask_bits_expCompAck),
    .io_mshrTask_bits_allowRetry (RequestArb__io_mshrTask_bits_allowRetry),
    .io_mshrTask_bits_memAttr_allocate (RequestArb__io_mshrTask_bits_memAttr_allocate),
    .io_mshrTask_bits_memAttr_cacheable (RequestArb__io_mshrTask_bits_memAttr_cacheable),
    .io_mshrTask_bits_memAttr_device (RequestArb__io_mshrTask_bits_memAttr_device),
    .io_mshrTask_bits_memAttr_ewa (RequestArb__io_mshrTask_bits_memAttr_ewa),
    .io_mshrTask_bits_traceTag (RequestArb__io_mshrTask_bits_traceTag),
    .io_dirRead_s1_ready (RequestArb__io_dirRead_s1_ready),
    .io_dirRead_s1_valid (i_RequestArb__io_dirRead_s1_valid),
    .io_dirRead_s1_bits_tag (i_RequestArb__io_dirRead_s1_bits_tag),
    .io_dirRead_s1_bits_set (i_RequestArb__io_dirRead_s1_bits_set),
    .io_dirRead_s1_bits_wayMask (i_RequestArb__io_dirRead_s1_bits_wayMask),
    .io_dirRead_s1_bits_replacerInfo_channel (i_RequestArb__io_dirRead_s1_bits_replacerInfo_channel),
    .io_dirRead_s1_bits_replacerInfo_opcode (i_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode),
    .io_dirRead_s1_bits_replacerInfo_reqSource (i_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource),
    .io_dirRead_s1_bits_replacerInfo_refill_prefetch (i_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch),
    .io_dirRead_s1_bits_refill (i_RequestArb__io_dirRead_s1_bits_refill),
    .io_dirRead_s1_bits_mshrId (i_RequestArb__io_dirRead_s1_bits_mshrId),
    .io_dirRead_s1_bits_cmoAll (i_RequestArb__io_dirRead_s1_bits_cmoAll),
    .io_dirRead_s1_bits_cmoWay (i_RequestArb__io_dirRead_s1_bits_cmoWay),
    .io_taskToPipe_s2_valid (i_RequestArb__io_taskToPipe_s2_valid),
    .io_taskToPipe_s2_bits_channel (i_RequestArb__io_taskToPipe_s2_bits_channel),
    .io_taskToPipe_s2_bits_txChannel (i_RequestArb__io_taskToPipe_s2_bits_txChannel),
    .io_taskToPipe_s2_bits_set (i_RequestArb__io_taskToPipe_s2_bits_set),
    .io_taskToPipe_s2_bits_tag (i_RequestArb__io_taskToPipe_s2_bits_tag),
    .io_taskToPipe_s2_bits_off (i_RequestArb__io_taskToPipe_s2_bits_off),
    .io_taskToPipe_s2_bits_alias (i_RequestArb__io_taskToPipe_s2_bits_alias),
    .io_taskToPipe_s2_bits_vaddr (i_RequestArb__io_taskToPipe_s2_bits_vaddr),
    .io_taskToPipe_s2_bits_isKeyword (i_RequestArb__io_taskToPipe_s2_bits_isKeyword),
    .io_taskToPipe_s2_bits_opcode (i_RequestArb__io_taskToPipe_s2_bits_opcode),
    .io_taskToPipe_s2_bits_param (i_RequestArb__io_taskToPipe_s2_bits_param),
    .io_taskToPipe_s2_bits_size (i_RequestArb__io_taskToPipe_s2_bits_size),
    .io_taskToPipe_s2_bits_sourceId (i_RequestArb__io_taskToPipe_s2_bits_sourceId),
    .io_taskToPipe_s2_bits_bufIdx (i_RequestArb__io_taskToPipe_s2_bits_bufIdx),
    .io_taskToPipe_s2_bits_needProbeAckData (i_RequestArb__io_taskToPipe_s2_bits_needProbeAckData),
    .io_taskToPipe_s2_bits_denied (i_RequestArb__io_taskToPipe_s2_bits_denied),
    .io_taskToPipe_s2_bits_corrupt (i_RequestArb__io_taskToPipe_s2_bits_corrupt),
    .io_taskToPipe_s2_bits_mshrTask (i_RequestArb__io_taskToPipe_s2_bits_mshrTask),
    .io_taskToPipe_s2_bits_mshrId (i_RequestArb__io_taskToPipe_s2_bits_mshrId),
    .io_taskToPipe_s2_bits_aliasTask (i_RequestArb__io_taskToPipe_s2_bits_aliasTask),
    .io_taskToPipe_s2_bits_useProbeData (i_RequestArb__io_taskToPipe_s2_bits_useProbeData),
    .io_taskToPipe_s2_bits_mshrRetry (i_RequestArb__io_taskToPipe_s2_bits_mshrRetry),
    .io_taskToPipe_s2_bits_readProbeDataDown (i_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown),
    .io_taskToPipe_s2_bits_fromL2pft (i_RequestArb__io_taskToPipe_s2_bits_fromL2pft),
    .io_taskToPipe_s2_bits_needHint (i_RequestArb__io_taskToPipe_s2_bits_needHint),
    .io_taskToPipe_s2_bits_dirty (i_RequestArb__io_taskToPipe_s2_bits_dirty),
    .io_taskToPipe_s2_bits_way (i_RequestArb__io_taskToPipe_s2_bits_way),
    .io_taskToPipe_s2_bits_meta_dirty (i_RequestArb__io_taskToPipe_s2_bits_meta_dirty),
    .io_taskToPipe_s2_bits_meta_state (i_RequestArb__io_taskToPipe_s2_bits_meta_state),
    .io_taskToPipe_s2_bits_meta_clients (i_RequestArb__io_taskToPipe_s2_bits_meta_clients),
    .io_taskToPipe_s2_bits_meta_alias (i_RequestArb__io_taskToPipe_s2_bits_meta_alias),
    .io_taskToPipe_s2_bits_meta_prefetch (i_RequestArb__io_taskToPipe_s2_bits_meta_prefetch),
    .io_taskToPipe_s2_bits_meta_prefetchSrc (i_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_meta_accessed (i_RequestArb__io_taskToPipe_s2_bits_meta_accessed),
    .io_taskToPipe_s2_bits_meta_tagErr (i_RequestArb__io_taskToPipe_s2_bits_meta_tagErr),
    .io_taskToPipe_s2_bits_meta_dataErr (i_RequestArb__io_taskToPipe_s2_bits_meta_dataErr),
    .io_taskToPipe_s2_bits_metaWen (i_RequestArb__io_taskToPipe_s2_bits_metaWen),
    .io_taskToPipe_s2_bits_tagWen (i_RequestArb__io_taskToPipe_s2_bits_tagWen),
    .io_taskToPipe_s2_bits_dsWen (i_RequestArb__io_taskToPipe_s2_bits_dsWen),
    .io_taskToPipe_s2_bits_wayMask (i_RequestArb__io_taskToPipe_s2_bits_wayMask),
    .io_taskToPipe_s2_bits_replTask (i_RequestArb__io_taskToPipe_s2_bits_replTask),
    .io_taskToPipe_s2_bits_cmoTask (i_RequestArb__io_taskToPipe_s2_bits_cmoTask),
    .io_taskToPipe_s2_bits_cmoAll (i_RequestArb__io_taskToPipe_s2_bits_cmoAll),
    .io_taskToPipe_s2_bits_reqSource (i_RequestArb__io_taskToPipe_s2_bits_reqSource),
    .io_taskToPipe_s2_bits_mergeA (i_RequestArb__io_taskToPipe_s2_bits_mergeA),
    .io_taskToPipe_s2_bits_aMergeTask_off (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off),
    .io_taskToPipe_s2_bits_aMergeTask_alias (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias),
    .io_taskToPipe_s2_bits_aMergeTask_vaddr (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr),
    .io_taskToPipe_s2_bits_aMergeTask_isKeyword (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword),
    .io_taskToPipe_s2_bits_aMergeTask_opcode (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode),
    .io_taskToPipe_s2_bits_aMergeTask_param (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param),
    .io_taskToPipe_s2_bits_aMergeTask_sourceId (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dirty (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty),
    .io_taskToPipe_s2_bits_aMergeTask_meta_state (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state),
    .io_taskToPipe_s2_bits_aMergeTask_meta_clients (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients),
    .io_taskToPipe_s2_bits_aMergeTask_meta_alias (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetch (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch),
    .io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc),
    .io_taskToPipe_s2_bits_aMergeTask_meta_accessed (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed),
    .io_taskToPipe_s2_bits_aMergeTask_meta_tagErr (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr),
    .io_taskToPipe_s2_bits_aMergeTask_meta_dataErr (i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr),
    .io_taskToPipe_s2_bits_snpHitRelease (i_RequestArb__io_taskToPipe_s2_bits_snpHitRelease),
    .io_taskToPipe_s2_bits_snpHitReleaseToInval (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval),
    .io_taskToPipe_s2_bits_snpHitReleaseToClean (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean),
    .io_taskToPipe_s2_bits_snpHitReleaseWithData (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData),
    .io_taskToPipe_s2_bits_snpHitReleaseIdx (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_state (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_clients (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_alias (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr),
    .io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr (i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr),
    .io_taskToPipe_s2_bits_tgtID (i_RequestArb__io_taskToPipe_s2_bits_tgtID),
    .io_taskToPipe_s2_bits_srcID (i_RequestArb__io_taskToPipe_s2_bits_srcID),
    .io_taskToPipe_s2_bits_txnID (i_RequestArb__io_taskToPipe_s2_bits_txnID),
    .io_taskToPipe_s2_bits_homeNID (i_RequestArb__io_taskToPipe_s2_bits_homeNID),
    .io_taskToPipe_s2_bits_dbID (i_RequestArb__io_taskToPipe_s2_bits_dbID),
    .io_taskToPipe_s2_bits_fwdNID (i_RequestArb__io_taskToPipe_s2_bits_fwdNID),
    .io_taskToPipe_s2_bits_fwdTxnID (i_RequestArb__io_taskToPipe_s2_bits_fwdTxnID),
    .io_taskToPipe_s2_bits_chiOpcode (i_RequestArb__io_taskToPipe_s2_bits_chiOpcode),
    .io_taskToPipe_s2_bits_resp (i_RequestArb__io_taskToPipe_s2_bits_resp),
    .io_taskToPipe_s2_bits_fwdState (i_RequestArb__io_taskToPipe_s2_bits_fwdState),
    .io_taskToPipe_s2_bits_pCrdType (i_RequestArb__io_taskToPipe_s2_bits_pCrdType),
    .io_taskToPipe_s2_bits_retToSrc (i_RequestArb__io_taskToPipe_s2_bits_retToSrc),
    .io_taskToPipe_s2_bits_likelyshared (i_RequestArb__io_taskToPipe_s2_bits_likelyshared),
    .io_taskToPipe_s2_bits_expCompAck (i_RequestArb__io_taskToPipe_s2_bits_expCompAck),
    .io_taskToPipe_s2_bits_allowRetry (i_RequestArb__io_taskToPipe_s2_bits_allowRetry),
    .io_taskToPipe_s2_bits_memAttr_allocate (i_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate),
    .io_taskToPipe_s2_bits_memAttr_cacheable (i_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable),
    .io_taskToPipe_s2_bits_memAttr_device (i_RequestArb__io_taskToPipe_s2_bits_memAttr_device),
    .io_taskToPipe_s2_bits_memAttr_ewa (i_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa),
    .io_taskToPipe_s2_bits_traceTag (i_RequestArb__io_taskToPipe_s2_bits_traceTag),
    .io_taskInfo_s1_valid (i_RequestArb__io_taskInfo_s1_valid),
    .io_taskInfo_s1_bits_channel (i_RequestArb__io_taskInfo_s1_bits_channel),
    .io_taskInfo_s1_bits_txChannel (i_RequestArb__io_taskInfo_s1_bits_txChannel),
    .io_taskInfo_s1_bits_set (i_RequestArb__io_taskInfo_s1_bits_set),
    .io_taskInfo_s1_bits_tag (i_RequestArb__io_taskInfo_s1_bits_tag),
    .io_taskInfo_s1_bits_off (i_RequestArb__io_taskInfo_s1_bits_off),
    .io_taskInfo_s1_bits_alias (i_RequestArb__io_taskInfo_s1_bits_alias),
    .io_taskInfo_s1_bits_vaddr (i_RequestArb__io_taskInfo_s1_bits_vaddr),
    .io_taskInfo_s1_bits_isKeyword (i_RequestArb__io_taskInfo_s1_bits_isKeyword),
    .io_taskInfo_s1_bits_opcode (i_RequestArb__io_taskInfo_s1_bits_opcode),
    .io_taskInfo_s1_bits_param (i_RequestArb__io_taskInfo_s1_bits_param),
    .io_taskInfo_s1_bits_size (i_RequestArb__io_taskInfo_s1_bits_size),
    .io_taskInfo_s1_bits_sourceId (i_RequestArb__io_taskInfo_s1_bits_sourceId),
    .io_taskInfo_s1_bits_bufIdx (i_RequestArb__io_taskInfo_s1_bits_bufIdx),
    .io_taskInfo_s1_bits_needProbeAckData (i_RequestArb__io_taskInfo_s1_bits_needProbeAckData),
    .io_taskInfo_s1_bits_denied (i_RequestArb__io_taskInfo_s1_bits_denied),
    .io_taskInfo_s1_bits_corrupt (i_RequestArb__io_taskInfo_s1_bits_corrupt),
    .io_taskInfo_s1_bits_mshrTask (i_RequestArb__io_taskInfo_s1_bits_mshrTask),
    .io_taskInfo_s1_bits_mshrId (i_RequestArb__io_taskInfo_s1_bits_mshrId),
    .io_taskInfo_s1_bits_aliasTask (i_RequestArb__io_taskInfo_s1_bits_aliasTask),
    .io_taskInfo_s1_bits_useProbeData (i_RequestArb__io_taskInfo_s1_bits_useProbeData),
    .io_taskInfo_s1_bits_mshrRetry (i_RequestArb__io_taskInfo_s1_bits_mshrRetry),
    .io_taskInfo_s1_bits_readProbeDataDown (i_RequestArb__io_taskInfo_s1_bits_readProbeDataDown),
    .io_taskInfo_s1_bits_fromL2pft (i_RequestArb__io_taskInfo_s1_bits_fromL2pft),
    .io_taskInfo_s1_bits_needHint (i_RequestArb__io_taskInfo_s1_bits_needHint),
    .io_taskInfo_s1_bits_dirty (i_RequestArb__io_taskInfo_s1_bits_dirty),
    .io_taskInfo_s1_bits_way (i_RequestArb__io_taskInfo_s1_bits_way),
    .io_taskInfo_s1_bits_meta_dirty (i_RequestArb__io_taskInfo_s1_bits_meta_dirty),
    .io_taskInfo_s1_bits_meta_state (i_RequestArb__io_taskInfo_s1_bits_meta_state),
    .io_taskInfo_s1_bits_meta_clients (i_RequestArb__io_taskInfo_s1_bits_meta_clients),
    .io_taskInfo_s1_bits_meta_alias (i_RequestArb__io_taskInfo_s1_bits_meta_alias),
    .io_taskInfo_s1_bits_meta_prefetch (i_RequestArb__io_taskInfo_s1_bits_meta_prefetch),
    .io_taskInfo_s1_bits_meta_prefetchSrc (i_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc),
    .io_taskInfo_s1_bits_meta_accessed (i_RequestArb__io_taskInfo_s1_bits_meta_accessed),
    .io_taskInfo_s1_bits_meta_tagErr (i_RequestArb__io_taskInfo_s1_bits_meta_tagErr),
    .io_taskInfo_s1_bits_meta_dataErr (i_RequestArb__io_taskInfo_s1_bits_meta_dataErr),
    .io_taskInfo_s1_bits_metaWen (i_RequestArb__io_taskInfo_s1_bits_metaWen),
    .io_taskInfo_s1_bits_tagWen (i_RequestArb__io_taskInfo_s1_bits_tagWen),
    .io_taskInfo_s1_bits_dsWen (i_RequestArb__io_taskInfo_s1_bits_dsWen),
    .io_taskInfo_s1_bits_wayMask (i_RequestArb__io_taskInfo_s1_bits_wayMask),
    .io_taskInfo_s1_bits_replTask (i_RequestArb__io_taskInfo_s1_bits_replTask),
    .io_taskInfo_s1_bits_cmoTask (i_RequestArb__io_taskInfo_s1_bits_cmoTask),
    .io_taskInfo_s1_bits_cmoAll (i_RequestArb__io_taskInfo_s1_bits_cmoAll),
    .io_taskInfo_s1_bits_reqSource (i_RequestArb__io_taskInfo_s1_bits_reqSource),
    .io_taskInfo_s1_bits_mergeA (i_RequestArb__io_taskInfo_s1_bits_mergeA),
    .io_taskInfo_s1_bits_aMergeTask_off (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_off),
    .io_taskInfo_s1_bits_aMergeTask_alias (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias),
    .io_taskInfo_s1_bits_aMergeTask_vaddr (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr),
    .io_taskInfo_s1_bits_aMergeTask_isKeyword (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_taskInfo_s1_bits_aMergeTask_opcode (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_taskInfo_s1_bits_aMergeTask_param (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_param),
    .io_taskInfo_s1_bits_aMergeTask_sourceId (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_taskInfo_s1_bits_aMergeTask_meta_dirty (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty),
    .io_taskInfo_s1_bits_aMergeTask_meta_state (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state),
    .io_taskInfo_s1_bits_aMergeTask_meta_clients (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients),
    .io_taskInfo_s1_bits_aMergeTask_meta_alias (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetch (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch),
    .io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc),
    .io_taskInfo_s1_bits_aMergeTask_meta_accessed (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed),
    .io_taskInfo_s1_bits_aMergeTask_meta_tagErr (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr),
    .io_taskInfo_s1_bits_aMergeTask_meta_dataErr (i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr),
    .io_taskInfo_s1_bits_snpHitRelease (i_RequestArb__io_taskInfo_s1_bits_snpHitRelease),
    .io_taskInfo_s1_bits_snpHitReleaseToInval (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval),
    .io_taskInfo_s1_bits_snpHitReleaseToClean (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean),
    .io_taskInfo_s1_bits_snpHitReleaseWithData (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData),
    .io_taskInfo_s1_bits_snpHitReleaseIdx (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dirty (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_state (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_clients (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_alias (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_accessed (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr),
    .io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr (i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr),
    .io_taskInfo_s1_bits_tgtID (i_RequestArb__io_taskInfo_s1_bits_tgtID),
    .io_taskInfo_s1_bits_srcID (i_RequestArb__io_taskInfo_s1_bits_srcID),
    .io_taskInfo_s1_bits_txnID (i_RequestArb__io_taskInfo_s1_bits_txnID),
    .io_taskInfo_s1_bits_homeNID (i_RequestArb__io_taskInfo_s1_bits_homeNID),
    .io_taskInfo_s1_bits_dbID (i_RequestArb__io_taskInfo_s1_bits_dbID),
    .io_taskInfo_s1_bits_fwdNID (i_RequestArb__io_taskInfo_s1_bits_fwdNID),
    .io_taskInfo_s1_bits_fwdTxnID (i_RequestArb__io_taskInfo_s1_bits_fwdTxnID),
    .io_taskInfo_s1_bits_chiOpcode (i_RequestArb__io_taskInfo_s1_bits_chiOpcode),
    .io_taskInfo_s1_bits_resp (i_RequestArb__io_taskInfo_s1_bits_resp),
    .io_taskInfo_s1_bits_fwdState (i_RequestArb__io_taskInfo_s1_bits_fwdState),
    .io_taskInfo_s1_bits_pCrdType (i_RequestArb__io_taskInfo_s1_bits_pCrdType),
    .io_taskInfo_s1_bits_retToSrc (i_RequestArb__io_taskInfo_s1_bits_retToSrc),
    .io_taskInfo_s1_bits_likelyshared (i_RequestArb__io_taskInfo_s1_bits_likelyshared),
    .io_taskInfo_s1_bits_expCompAck (i_RequestArb__io_taskInfo_s1_bits_expCompAck),
    .io_taskInfo_s1_bits_allowRetry (i_RequestArb__io_taskInfo_s1_bits_allowRetry),
    .io_taskInfo_s1_bits_memAttr_allocate (i_RequestArb__io_taskInfo_s1_bits_memAttr_allocate),
    .io_taskInfo_s1_bits_memAttr_cacheable (i_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable),
    .io_taskInfo_s1_bits_memAttr_device (i_RequestArb__io_taskInfo_s1_bits_memAttr_device),
    .io_taskInfo_s1_bits_memAttr_ewa (i_RequestArb__io_taskInfo_s1_bits_memAttr_ewa),
    .io_taskInfo_s1_bits_traceTag (i_RequestArb__io_taskInfo_s1_bits_traceTag),
    .io_refillBufRead_s2_valid (i_RequestArb__io_refillBufRead_s2_valid),
    .io_refillBufRead_s2_bits_id (i_RequestArb__io_refillBufRead_s2_bits_id),
    .io_releaseBufRead_s2_valid (i_RequestArb__io_releaseBufRead_s2_valid),
    .io_releaseBufRead_s2_bits_id (i_RequestArb__io_releaseBufRead_s2_bits_id),
    .io_status_s1_tags_0 (i_RequestArb__io_status_s1_tags_0),
    .io_status_s1_tags_1 (i_RequestArb__io_status_s1_tags_1),
    .io_status_s1_tags_2 (i_RequestArb__io_status_s1_tags_2),
    .io_status_s1_tags_3 (i_RequestArb__io_status_s1_tags_3),
    .io_status_s1_sets_0 (i_RequestArb__io_status_s1_sets_0),
    .io_status_s1_sets_1 (i_RequestArb__io_status_s1_sets_1),
    .io_status_s1_sets_2 (i_RequestArb__io_status_s1_sets_2),
    .io_status_s1_sets_3 (i_RequestArb__io_status_s1_sets_3),
    .io_status_vec_0_valid (i_RequestArb__io_status_vec_0_valid),
    .io_status_vec_0_bits_channel (i_RequestArb__io_status_vec_0_bits_channel),
    .io_status_vec_1_valid (i_RequestArb__io_status_vec_1_valid),
    .io_status_vec_1_bits_channel (i_RequestArb__io_status_vec_1_bits_channel),
    .io_status_vec_toTX_0_valid (i_RequestArb__io_status_vec_toTX_0_valid),
    .io_status_vec_toTX_0_bits_channel (i_RequestArb__io_status_vec_toTX_0_bits_channel),
    .io_status_vec_toTX_0_bits_txChannel (i_RequestArb__io_status_vec_toTX_0_bits_txChannel),
    .io_status_vec_toTX_0_bits_mshrTask (i_RequestArb__io_status_vec_toTX_0_bits_mshrTask),
    .io_status_vec_toTX_1_valid (i_RequestArb__io_status_vec_toTX_1_valid),
    .io_status_vec_toTX_1_bits_channel (i_RequestArb__io_status_vec_toTX_1_bits_channel),
    .io_status_vec_toTX_1_bits_txChannel (i_RequestArb__io_status_vec_toTX_1_bits_txChannel),
    .io_status_vec_toTX_1_bits_mshrTask (i_RequestArb__io_status_vec_toTX_1_bits_mshrTask),
    .io_fromMSHRCtl_blockG_s1 (RequestArb__io_fromMSHRCtl_blockG_s1),
    .io_fromMSHRCtl_blockA_s1 (RequestArb__io_fromMSHRCtl_blockA_s1),
    .io_fromMSHRCtl_blockB_s1 (RequestArb__io_fromMSHRCtl_blockB_s1),
    .io_fromMSHRCtl_blockC_s1 (RequestArb__io_fromMSHRCtl_blockC_s1),
    .io_fromMainPipe_blockG_s1 (RequestArb__io_fromMainPipe_blockG_s1),
    .io_fromMainPipe_blockA_s1 (RequestArb__io_fromMainPipe_blockA_s1),
    .io_fromMainPipe_blockB_s1 (RequestArb__io_fromMainPipe_blockB_s1),
    .io_fromMainPipe_blockC_s1 (RequestArb__io_fromMainPipe_blockC_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1),
    .io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1 (RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1),
    .io_fromGrantBuffer_blockMSHRReqEntrance (RequestArb__io_fromGrantBuffer_blockMSHRReqEntrance),
    .io_fromTXDAT_blockMSHRReqEntrance (RequestArb__io_fromTXDAT_blockMSHRReqEntrance),
    .io_fromTXDAT_blockSinkBReqEntrance (RequestArb__io_fromTXDAT_blockSinkBReqEntrance),
    .io_fromTXRSP_blockMSHRReqEntrance (RequestArb__io_fromTXRSP_blockMSHRReqEntrance),
    .io_fromTXRSP_blockSinkBReqEntrance (RequestArb__io_fromTXRSP_blockSinkBReqEntrance),
    .io_fromTXREQ_blockMSHRReqEntrance (RequestArb__io_fromTXREQ_blockMSHRReqEntrance),
    .io_msInfo_0_valid (RequestArb__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (RequestArb__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (RequestArb__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (RequestArb__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (RequestArb__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (RequestArb__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (RequestArb__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (RequestArb__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (RequestArb__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (RequestArb__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (RequestArb__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (RequestArb__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (RequestArb__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (RequestArb__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (RequestArb__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (RequestArb__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (RequestArb__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (RequestArb__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (RequestArb__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (RequestArb__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (RequestArb__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (RequestArb__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (RequestArb__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (RequestArb__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (RequestArb__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (RequestArb__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (RequestArb__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (RequestArb__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (RequestArb__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (RequestArb__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (RequestArb__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (RequestArb__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (RequestArb__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (RequestArb__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (RequestArb__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (RequestArb__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (RequestArb__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (RequestArb__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (RequestArb__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (RequestArb__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (RequestArb__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (RequestArb__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (RequestArb__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (RequestArb__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (RequestArb__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (RequestArb__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (RequestArb__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (RequestArb__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (RequestArb__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (RequestArb__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (RequestArb__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (RequestArb__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (RequestArb__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (RequestArb__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (RequestArb__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (RequestArb__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (RequestArb__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (RequestArb__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (RequestArb__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (RequestArb__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (RequestArb__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (RequestArb__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (RequestArb__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (RequestArb__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (RequestArb__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (RequestArb__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (RequestArb__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (RequestArb__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (RequestArb__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (RequestArb__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (RequestArb__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (RequestArb__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (RequestArb__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (RequestArb__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (RequestArb__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (RequestArb__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (RequestArb__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (RequestArb__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (RequestArb__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (RequestArb__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (RequestArb__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (RequestArb__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (RequestArb__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (RequestArb__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (RequestArb__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (RequestArb__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (RequestArb__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (RequestArb__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (RequestArb__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (RequestArb__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (RequestArb__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (RequestArb__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (RequestArb__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (RequestArb__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (RequestArb__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (RequestArb__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (RequestArb__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (RequestArb__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (RequestArb__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (RequestArb__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (RequestArb__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (RequestArb__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (RequestArb__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (RequestArb__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (RequestArb__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (RequestArb__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (RequestArb__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (RequestArb__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (RequestArb__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (RequestArb__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (RequestArb__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (RequestArb__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (RequestArb__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (RequestArb__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (RequestArb__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (RequestArb__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (RequestArb__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (RequestArb__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (RequestArb__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (RequestArb__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (RequestArb__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (RequestArb__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (RequestArb__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (RequestArb__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (RequestArb__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (RequestArb__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (RequestArb__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (RequestArb__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (RequestArb__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (RequestArb__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (RequestArb__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (RequestArb__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (RequestArb__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (RequestArb__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (RequestArb__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (RequestArb__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (RequestArb__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (RequestArb__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (RequestArb__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (RequestArb__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (RequestArb__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (RequestArb__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (RequestArb__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (RequestArb__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (RequestArb__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (RequestArb__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (RequestArb__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (RequestArb__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (RequestArb__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (RequestArb__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (RequestArb__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (RequestArb__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (RequestArb__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (RequestArb__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (RequestArb__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (RequestArb__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (RequestArb__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (RequestArb__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (RequestArb__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (RequestArb__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (RequestArb__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (RequestArb__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (RequestArb__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (RequestArb__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (RequestArb__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (RequestArb__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (RequestArb__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (RequestArb__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (RequestArb__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (RequestArb__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (RequestArb__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (RequestArb__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (RequestArb__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (RequestArb__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (RequestArb__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (RequestArb__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (RequestArb__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (RequestArb__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (RequestArb__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (RequestArb__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (RequestArb__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (RequestArb__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (RequestArb__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (RequestArb__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (RequestArb__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (RequestArb__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (RequestArb__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (RequestArb__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (RequestArb__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (RequestArb__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (RequestArb__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (RequestArb__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (RequestArb__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (RequestArb__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (RequestArb__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (RequestArb__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (RequestArb__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (RequestArb__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (RequestArb__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (RequestArb__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (RequestArb__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (RequestArb__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (RequestArb__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (RequestArb__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (RequestArb__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (RequestArb__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (RequestArb__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (RequestArb__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (RequestArb__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (RequestArb__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (RequestArb__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (RequestArb__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (RequestArb__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (RequestArb__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (RequestArb__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (RequestArb__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (RequestArb__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (RequestArb__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (RequestArb__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (RequestArb__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (RequestArb__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (RequestArb__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (RequestArb__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (RequestArb__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (RequestArb__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (RequestArb__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (RequestArb__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (RequestArb__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (RequestArb__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (RequestArb__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (RequestArb__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (RequestArb__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (RequestArb__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (RequestArb__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (RequestArb__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (RequestArb__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (RequestArb__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (RequestArb__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (RequestArb__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (RequestArb__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (RequestArb__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (RequestArb__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (RequestArb__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (RequestArb__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (RequestArb__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (RequestArb__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (RequestArb__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (RequestArb__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (RequestArb__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (RequestArb__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (RequestArb__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (RequestArb__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (RequestArb__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (RequestArb__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (RequestArb__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (RequestArb__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (RequestArb__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (RequestArb__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (RequestArb__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (RequestArb__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (RequestArb__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (RequestArb__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (RequestArb__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (RequestArb__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (RequestArb__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (RequestArb__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (RequestArb__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (RequestArb__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (RequestArb__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (RequestArb__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (RequestArb__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (RequestArb__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (RequestArb__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (RequestArb__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (RequestArb__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (RequestArb__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (RequestArb__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (RequestArb__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (RequestArb__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (RequestArb__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (RequestArb__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (RequestArb__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (RequestArb__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (RequestArb__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (RequestArb__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (RequestArb__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (RequestArb__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (RequestArb__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (RequestArb__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (RequestArb__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (RequestArb__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (RequestArb__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (RequestArb__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (RequestArb__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (RequestArb__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (RequestArb__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (RequestArb__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (RequestArb__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (RequestArb__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (RequestArb__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (RequestArb__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (RequestArb__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (RequestArb__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (RequestArb__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (RequestArb__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (RequestArb__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (RequestArb__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (RequestArb__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (RequestArb__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (RequestArb__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (RequestArb__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (RequestArb__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (RequestArb__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (RequestArb__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (RequestArb__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (RequestArb__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (RequestArb__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (RequestArb__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (RequestArb__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (RequestArb__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (RequestArb__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (RequestArb__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (RequestArb__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (RequestArb__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (RequestArb__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (RequestArb__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (RequestArb__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (RequestArb__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (RequestArb__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (RequestArb__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (RequestArb__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (RequestArb__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (RequestArb__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (RequestArb__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (RequestArb__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (RequestArb__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (RequestArb__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (RequestArb__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (RequestArb__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (RequestArb__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (RequestArb__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (RequestArb__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (RequestArb__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (RequestArb__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (RequestArb__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (RequestArb__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (RequestArb__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (RequestArb__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (RequestArb__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (RequestArb__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (RequestArb__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (RequestArb__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (RequestArb__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (RequestArb__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (RequestArb__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (RequestArb__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (RequestArb__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (RequestArb__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (RequestArb__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (RequestArb__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (RequestArb__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (RequestArb__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (RequestArb__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (RequestArb__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (RequestArb__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (RequestArb__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (RequestArb__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (RequestArb__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (RequestArb__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (RequestArb__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (RequestArb__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (RequestArb__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (RequestArb__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (RequestArb__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (RequestArb__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (RequestArb__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (RequestArb__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (RequestArb__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (RequestArb__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (RequestArb__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (RequestArb__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (RequestArb__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (RequestArb__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (RequestArb__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (RequestArb__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (RequestArb__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (RequestArb__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (RequestArb__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (RequestArb__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (RequestArb__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (RequestArb__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (RequestArb__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (RequestArb__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (RequestArb__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (RequestArb__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (RequestArb__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (RequestArb__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (RequestArb__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (RequestArb__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (RequestArb__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (RequestArb__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (RequestArb__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (RequestArb__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (RequestArb__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (RequestArb__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (RequestArb__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (RequestArb__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (RequestArb__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (RequestArb__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (RequestArb__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (RequestArb__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (RequestArb__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (RequestArb__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (RequestArb__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (RequestArb__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (RequestArb__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (RequestArb__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (RequestArb__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (RequestArb__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (RequestArb__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (RequestArb__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (RequestArb__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (RequestArb__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (RequestArb__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (RequestArb__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (RequestArb__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (RequestArb__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (RequestArb__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (RequestArb__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (RequestArb__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (RequestArb__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (RequestArb__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (RequestArb__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (RequestArb__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (RequestArb__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (RequestArb__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (RequestArb__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (RequestArb__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (RequestArb__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (RequestArb__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (RequestArb__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (RequestArb__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (RequestArb__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (RequestArb__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (RequestArb__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (RequestArb__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (RequestArb__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (RequestArb__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (RequestArb__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (RequestArb__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (RequestArb__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (RequestArb__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (RequestArb__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (RequestArb__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (RequestArb__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (RequestArb__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (RequestArb__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (RequestArb__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (RequestArb__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (RequestArb__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (RequestArb__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (RequestArb__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (RequestArb__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (RequestArb__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (RequestArb__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (RequestArb__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (RequestArb__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (RequestArb__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (RequestArb__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (RequestArb__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (RequestArb__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (RequestArb__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (RequestArb__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (RequestArb__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (RequestArb__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (RequestArb__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (RequestArb__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (RequestArb__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (RequestArb__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (RequestArb__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (RequestArb__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (RequestArb__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (RequestArb__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (RequestArb__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (RequestArb__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (RequestArb__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (RequestArb__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (RequestArb__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (RequestArb__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (RequestArb__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (RequestArb__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (RequestArb__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (RequestArb__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (RequestArb__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (RequestArb__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (RequestArb__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (RequestArb__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (RequestArb__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (RequestArb__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (RequestArb__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (RequestArb__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (RequestArb__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (RequestArb__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (RequestArb__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (RequestArb__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (RequestArb__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (RequestArb__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (RequestArb__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (RequestArb__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (RequestArb__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (RequestArb__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (RequestArb__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (RequestArb__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (RequestArb__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (RequestArb__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (RequestArb__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (RequestArb__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (RequestArb__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (RequestArb__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (RequestArb__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (RequestArb__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (RequestArb__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (RequestArb__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (RequestArb__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (RequestArb__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (RequestArb__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (RequestArb__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (RequestArb__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (RequestArb__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (RequestArb__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (RequestArb__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (RequestArb__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (RequestArb__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (RequestArb__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (RequestArb__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (RequestArb__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (RequestArb__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (RequestArb__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (RequestArb__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (RequestArb__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (RequestArb__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (RequestArb__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (RequestArb__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (RequestArb__io_msInfo_15_bits_releaseToClean)
  );
  task automatic drive_RequestArb();
    RequestArb__io_sinkA_valid = $urandom % 2;
    RequestArb__io_sinkA_bits_channel = rnd(3);
    RequestArb__io_sinkA_bits_txChannel = rnd(3);
    RequestArb__io_sinkA_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_sinkA_bits_tag = rnd(31);
    RequestArb__io_sinkA_bits_off = rnd(6);
    RequestArb__io_sinkA_bits_alias = rnd(2);
    RequestArb__io_sinkA_bits_vaddr = rnd(44);
    RequestArb__io_sinkA_bits_isKeyword = $urandom % 2;
    RequestArb__io_sinkA_bits_opcode = (($urandom % 2) == 0) ? 4'($urandom_range(1, 5)) : 4'($urandom);
    RequestArb__io_sinkA_bits_param = rnd(3);
    RequestArb__io_sinkA_bits_size = rnd(3);
    RequestArb__io_sinkA_bits_sourceId = rnd(7);
    RequestArb__io_sinkA_bits_bufIdx = rnd(2);
    RequestArb__io_sinkA_bits_needProbeAckData = $urandom % 2;
    RequestArb__io_sinkA_bits_denied = $urandom % 2;
    RequestArb__io_sinkA_bits_corrupt = $urandom % 2;
    RequestArb__io_sinkA_bits_mshrTask = $urandom % 2;
    RequestArb__io_sinkA_bits_mshrId = rnd(8);
    RequestArb__io_sinkA_bits_aliasTask = $urandom % 2;
    RequestArb__io_sinkA_bits_useProbeData = $urandom % 2;
    RequestArb__io_sinkA_bits_mshrRetry = $urandom % 2;
    RequestArb__io_sinkA_bits_readProbeDataDown = $urandom % 2;
    RequestArb__io_sinkA_bits_fromL2pft = $urandom % 2;
    RequestArb__io_sinkA_bits_needHint = $urandom % 2;
    RequestArb__io_sinkA_bits_dirty = $urandom % 2;
    RequestArb__io_sinkA_bits_way = rnd(3);
    RequestArb__io_sinkA_bits_meta_dirty = $urandom % 2;
    RequestArb__io_sinkA_bits_meta_state = rnd(2);
    RequestArb__io_sinkA_bits_meta_clients = $urandom % 2;
    RequestArb__io_sinkA_bits_meta_alias = rnd(2);
    RequestArb__io_sinkA_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_sinkA_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_sinkA_bits_meta_accessed = $urandom % 2;
    RequestArb__io_sinkA_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_sinkA_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_sinkA_bits_metaWen = $urandom % 2;
    RequestArb__io_sinkA_bits_tagWen = $urandom % 2;
    RequestArb__io_sinkA_bits_dsWen = $urandom % 2;
    RequestArb__io_sinkA_bits_wayMask = rnd(8);
    RequestArb__io_sinkA_bits_replTask = $urandom % 2;
    RequestArb__io_sinkA_bits_cmoTask = $urandom % 2;
    RequestArb__io_sinkA_bits_cmoAll = $urandom % 2;
    RequestArb__io_sinkA_bits_reqSource = rnd(5);
    RequestArb__io_sinkA_bits_mergeA = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_off = rnd(6);
    RequestArb__io_sinkA_bits_aMergeTask_alias = rnd(2);
    RequestArb__io_sinkA_bits_aMergeTask_vaddr = rnd(44);
    RequestArb__io_sinkA_bits_aMergeTask_isKeyword = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_opcode = rnd(3);
    RequestArb__io_sinkA_bits_aMergeTask_param = rnd(3);
    RequestArb__io_sinkA_bits_aMergeTask_sourceId = rnd(7);
    RequestArb__io_sinkA_bits_aMergeTask_meta_dirty = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_meta_state = rnd(2);
    RequestArb__io_sinkA_bits_aMergeTask_meta_clients = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_meta_alias = rnd(2);
    RequestArb__io_sinkA_bits_aMergeTask_meta_prefetch = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_meta_prefetchSrc = rnd(3);
    RequestArb__io_sinkA_bits_aMergeTask_meta_accessed = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_meta_tagErr = $urandom % 2;
    RequestArb__io_sinkA_bits_aMergeTask_meta_dataErr = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitRelease = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseToInval = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseToClean = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseWithData = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseIdx = rnd(8);
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_dirty = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_state = rnd(2);
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_clients = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_alias = rnd(2);
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetch = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_prefetchSrc = rnd(3);
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_accessed = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_tagErr = $urandom % 2;
    RequestArb__io_sinkA_bits_snpHitReleaseMeta_dataErr = $urandom % 2;
    RequestArb__io_sinkA_bits_tgtID = rnd(11);
    RequestArb__io_sinkA_bits_srcID = rnd(11);
    RequestArb__io_sinkA_bits_txnID = rnd(12);
    RequestArb__io_sinkA_bits_homeNID = rnd(11);
    RequestArb__io_sinkA_bits_dbID = rnd(12);
    RequestArb__io_sinkA_bits_fwdNID = rnd(11);
    RequestArb__io_sinkA_bits_fwdTxnID = rnd(12);
    RequestArb__io_sinkA_bits_chiOpcode = (($urandom % 2) == 0) ? 7'($urandom) : (($urandom % 4) == 0 ? 7'h1B : ($urandom % 3) == 0 ? 7'h15 : ($urandom % 2) ? 7'h42 : 7'h0D);
    RequestArb__io_sinkA_bits_resp = rnd(3);
    RequestArb__io_sinkA_bits_fwdState = rnd(3);
    RequestArb__io_sinkA_bits_pCrdType = rnd(4);
    RequestArb__io_sinkA_bits_retToSrc = $urandom % 2;
    RequestArb__io_sinkA_bits_likelyshared = $urandom % 2;
    RequestArb__io_sinkA_bits_expCompAck = $urandom % 2;
    RequestArb__io_sinkA_bits_allowRetry = $urandom % 2;
    RequestArb__io_sinkA_bits_memAttr_allocate = $urandom % 2;
    RequestArb__io_sinkA_bits_memAttr_cacheable = $urandom % 2;
    RequestArb__io_sinkA_bits_memAttr_device = $urandom % 2;
    RequestArb__io_sinkA_bits_memAttr_ewa = $urandom % 2;
    RequestArb__io_sinkA_bits_traceTag = $urandom % 2;
    RequestArb__io_ATag = rnd(31);
    RequestArb__io_ASet = rnd(9);
    RequestArb__io_sinkB_valid = $urandom % 2;
    RequestArb__io_sinkB_bits_channel = rnd(3);
    RequestArb__io_sinkB_bits_txChannel = rnd(3);
    RequestArb__io_sinkB_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_sinkB_bits_tag = rnd(31);
    RequestArb__io_sinkB_bits_off = rnd(6);
    RequestArb__io_sinkB_bits_alias = rnd(2);
    RequestArb__io_sinkB_bits_vaddr = rnd(44);
    RequestArb__io_sinkB_bits_isKeyword = $urandom % 2;
    RequestArb__io_sinkB_bits_opcode = (($urandom % 2) == 0) ? 4'($urandom_range(1, 5)) : 4'($urandom);
    RequestArb__io_sinkB_bits_param = rnd(3);
    RequestArb__io_sinkB_bits_size = rnd(3);
    RequestArb__io_sinkB_bits_sourceId = rnd(7);
    RequestArb__io_sinkB_bits_bufIdx = rnd(2);
    RequestArb__io_sinkB_bits_needProbeAckData = $urandom % 2;
    RequestArb__io_sinkB_bits_denied = $urandom % 2;
    RequestArb__io_sinkB_bits_corrupt = $urandom % 2;
    RequestArb__io_sinkB_bits_mshrTask = $urandom % 2;
    RequestArb__io_sinkB_bits_mshrId = rnd(8);
    RequestArb__io_sinkB_bits_aliasTask = $urandom % 2;
    RequestArb__io_sinkB_bits_useProbeData = $urandom % 2;
    RequestArb__io_sinkB_bits_mshrRetry = $urandom % 2;
    RequestArb__io_sinkB_bits_readProbeDataDown = $urandom % 2;
    RequestArb__io_sinkB_bits_fromL2pft = $urandom % 2;
    RequestArb__io_sinkB_bits_needHint = $urandom % 2;
    RequestArb__io_sinkB_bits_dirty = $urandom % 2;
    RequestArb__io_sinkB_bits_way = rnd(3);
    RequestArb__io_sinkB_bits_meta_dirty = $urandom % 2;
    RequestArb__io_sinkB_bits_meta_state = rnd(2);
    RequestArb__io_sinkB_bits_meta_clients = $urandom % 2;
    RequestArb__io_sinkB_bits_meta_alias = rnd(2);
    RequestArb__io_sinkB_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_sinkB_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_sinkB_bits_meta_accessed = $urandom % 2;
    RequestArb__io_sinkB_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_sinkB_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_sinkB_bits_metaWen = $urandom % 2;
    RequestArb__io_sinkB_bits_tagWen = $urandom % 2;
    RequestArb__io_sinkB_bits_dsWen = $urandom % 2;
    RequestArb__io_sinkB_bits_wayMask = rnd(8);
    RequestArb__io_sinkB_bits_replTask = $urandom % 2;
    RequestArb__io_sinkB_bits_cmoTask = $urandom % 2;
    RequestArb__io_sinkB_bits_cmoAll = $urandom % 2;
    RequestArb__io_sinkB_bits_reqSource = rnd(5);
    RequestArb__io_sinkB_bits_mergeA = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_off = rnd(6);
    RequestArb__io_sinkB_bits_aMergeTask_alias = rnd(2);
    RequestArb__io_sinkB_bits_aMergeTask_vaddr = rnd(44);
    RequestArb__io_sinkB_bits_aMergeTask_isKeyword = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_opcode = rnd(3);
    RequestArb__io_sinkB_bits_aMergeTask_param = rnd(3);
    RequestArb__io_sinkB_bits_aMergeTask_sourceId = rnd(7);
    RequestArb__io_sinkB_bits_aMergeTask_meta_dirty = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_meta_state = rnd(2);
    RequestArb__io_sinkB_bits_aMergeTask_meta_clients = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_meta_alias = rnd(2);
    RequestArb__io_sinkB_bits_aMergeTask_meta_prefetch = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_meta_prefetchSrc = rnd(3);
    RequestArb__io_sinkB_bits_aMergeTask_meta_accessed = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_meta_tagErr = $urandom % 2;
    RequestArb__io_sinkB_bits_aMergeTask_meta_dataErr = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitRelease = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseToInval = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseToClean = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseWithData = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseIdx = rnd(8);
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_dirty = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_state = rnd(2);
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_clients = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_alias = rnd(2);
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetch = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_prefetchSrc = rnd(3);
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_accessed = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_tagErr = $urandom % 2;
    RequestArb__io_sinkB_bits_snpHitReleaseMeta_dataErr = $urandom % 2;
    RequestArb__io_sinkB_bits_tgtID = rnd(11);
    RequestArb__io_sinkB_bits_srcID = rnd(11);
    RequestArb__io_sinkB_bits_txnID = rnd(12);
    RequestArb__io_sinkB_bits_homeNID = rnd(11);
    RequestArb__io_sinkB_bits_dbID = rnd(12);
    RequestArb__io_sinkB_bits_fwdNID = rnd(11);
    RequestArb__io_sinkB_bits_fwdTxnID = rnd(12);
    RequestArb__io_sinkB_bits_chiOpcode = (($urandom % 2) == 0) ? 7'($urandom) : (($urandom % 4) == 0 ? 7'h1B : ($urandom % 3) == 0 ? 7'h15 : ($urandom % 2) ? 7'h42 : 7'h0D);
    RequestArb__io_sinkB_bits_resp = rnd(3);
    RequestArb__io_sinkB_bits_fwdState = rnd(3);
    RequestArb__io_sinkB_bits_pCrdType = rnd(4);
    RequestArb__io_sinkB_bits_retToSrc = $urandom % 2;
    RequestArb__io_sinkB_bits_likelyshared = $urandom % 2;
    RequestArb__io_sinkB_bits_expCompAck = $urandom % 2;
    RequestArb__io_sinkB_bits_allowRetry = $urandom % 2;
    RequestArb__io_sinkB_bits_memAttr_allocate = $urandom % 2;
    RequestArb__io_sinkB_bits_memAttr_cacheable = $urandom % 2;
    RequestArb__io_sinkB_bits_memAttr_device = $urandom % 2;
    RequestArb__io_sinkB_bits_memAttr_ewa = $urandom % 2;
    RequestArb__io_sinkB_bits_traceTag = $urandom % 2;
    RequestArb__io_sinkC_valid = $urandom % 2;
    RequestArb__io_sinkC_bits_channel = rnd(3);
    RequestArb__io_sinkC_bits_txChannel = rnd(3);
    RequestArb__io_sinkC_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_sinkC_bits_tag = rnd(31);
    RequestArb__io_sinkC_bits_off = rnd(6);
    RequestArb__io_sinkC_bits_alias = rnd(2);
    RequestArb__io_sinkC_bits_vaddr = rnd(44);
    RequestArb__io_sinkC_bits_isKeyword = $urandom % 2;
    RequestArb__io_sinkC_bits_opcode = (($urandom % 2) == 0) ? 4'($urandom_range(1, 5)) : 4'($urandom);
    RequestArb__io_sinkC_bits_param = rnd(3);
    RequestArb__io_sinkC_bits_size = rnd(3);
    RequestArb__io_sinkC_bits_sourceId = rnd(7);
    RequestArb__io_sinkC_bits_bufIdx = rnd(2);
    RequestArb__io_sinkC_bits_needProbeAckData = $urandom % 2;
    RequestArb__io_sinkC_bits_denied = $urandom % 2;
    RequestArb__io_sinkC_bits_corrupt = $urandom % 2;
    RequestArb__io_sinkC_bits_mshrTask = $urandom % 2;
    RequestArb__io_sinkC_bits_mshrId = rnd(8);
    RequestArb__io_sinkC_bits_aliasTask = $urandom % 2;
    RequestArb__io_sinkC_bits_useProbeData = $urandom % 2;
    RequestArb__io_sinkC_bits_mshrRetry = $urandom % 2;
    RequestArb__io_sinkC_bits_readProbeDataDown = $urandom % 2;
    RequestArb__io_sinkC_bits_fromL2pft = $urandom % 2;
    RequestArb__io_sinkC_bits_needHint = $urandom % 2;
    RequestArb__io_sinkC_bits_dirty = $urandom % 2;
    RequestArb__io_sinkC_bits_way = rnd(3);
    RequestArb__io_sinkC_bits_meta_dirty = $urandom % 2;
    RequestArb__io_sinkC_bits_meta_state = rnd(2);
    RequestArb__io_sinkC_bits_meta_clients = $urandom % 2;
    RequestArb__io_sinkC_bits_meta_alias = rnd(2);
    RequestArb__io_sinkC_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_sinkC_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_sinkC_bits_meta_accessed = $urandom % 2;
    RequestArb__io_sinkC_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_sinkC_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_sinkC_bits_metaWen = $urandom % 2;
    RequestArb__io_sinkC_bits_tagWen = $urandom % 2;
    RequestArb__io_sinkC_bits_dsWen = $urandom % 2;
    RequestArb__io_sinkC_bits_wayMask = rnd(8);
    RequestArb__io_sinkC_bits_replTask = $urandom % 2;
    RequestArb__io_sinkC_bits_cmoTask = $urandom % 2;
    RequestArb__io_sinkC_bits_cmoAll = $urandom % 2;
    RequestArb__io_sinkC_bits_reqSource = rnd(5);
    RequestArb__io_sinkC_bits_mergeA = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_off = rnd(6);
    RequestArb__io_sinkC_bits_aMergeTask_alias = rnd(2);
    RequestArb__io_sinkC_bits_aMergeTask_vaddr = rnd(44);
    RequestArb__io_sinkC_bits_aMergeTask_isKeyword = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_opcode = rnd(3);
    RequestArb__io_sinkC_bits_aMergeTask_param = rnd(3);
    RequestArb__io_sinkC_bits_aMergeTask_sourceId = rnd(7);
    RequestArb__io_sinkC_bits_aMergeTask_meta_dirty = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_meta_state = rnd(2);
    RequestArb__io_sinkC_bits_aMergeTask_meta_clients = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_meta_alias = rnd(2);
    RequestArb__io_sinkC_bits_aMergeTask_meta_prefetch = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_meta_prefetchSrc = rnd(3);
    RequestArb__io_sinkC_bits_aMergeTask_meta_accessed = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_meta_tagErr = $urandom % 2;
    RequestArb__io_sinkC_bits_aMergeTask_meta_dataErr = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitRelease = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseToInval = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseToClean = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseWithData = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseIdx = rnd(8);
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_dirty = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_state = rnd(2);
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_clients = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_alias = rnd(2);
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetch = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_prefetchSrc = rnd(3);
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_accessed = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_tagErr = $urandom % 2;
    RequestArb__io_sinkC_bits_snpHitReleaseMeta_dataErr = $urandom % 2;
    RequestArb__io_sinkC_bits_tgtID = rnd(11);
    RequestArb__io_sinkC_bits_srcID = rnd(11);
    RequestArb__io_sinkC_bits_txnID = rnd(12);
    RequestArb__io_sinkC_bits_homeNID = rnd(11);
    RequestArb__io_sinkC_bits_dbID = rnd(12);
    RequestArb__io_sinkC_bits_fwdNID = rnd(11);
    RequestArb__io_sinkC_bits_fwdTxnID = rnd(12);
    RequestArb__io_sinkC_bits_chiOpcode = (($urandom % 2) == 0) ? 7'($urandom) : (($urandom % 4) == 0 ? 7'h1B : ($urandom % 3) == 0 ? 7'h15 : ($urandom % 2) ? 7'h42 : 7'h0D);
    RequestArb__io_sinkC_bits_resp = rnd(3);
    RequestArb__io_sinkC_bits_fwdState = rnd(3);
    RequestArb__io_sinkC_bits_pCrdType = rnd(4);
    RequestArb__io_sinkC_bits_retToSrc = $urandom % 2;
    RequestArb__io_sinkC_bits_likelyshared = $urandom % 2;
    RequestArb__io_sinkC_bits_expCompAck = $urandom % 2;
    RequestArb__io_sinkC_bits_allowRetry = $urandom % 2;
    RequestArb__io_sinkC_bits_memAttr_allocate = $urandom % 2;
    RequestArb__io_sinkC_bits_memAttr_cacheable = $urandom % 2;
    RequestArb__io_sinkC_bits_memAttr_device = $urandom % 2;
    RequestArb__io_sinkC_bits_memAttr_ewa = $urandom % 2;
    RequestArb__io_sinkC_bits_traceTag = $urandom % 2;
    RequestArb__io_mshrTask_valid = $urandom % 2;
    RequestArb__io_mshrTask_bits_channel = rnd(3);
    RequestArb__io_mshrTask_bits_txChannel = rnd(3);
    RequestArb__io_mshrTask_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_mshrTask_bits_tag = rnd(31);
    RequestArb__io_mshrTask_bits_off = rnd(6);
    RequestArb__io_mshrTask_bits_alias = rnd(2);
    RequestArb__io_mshrTask_bits_vaddr = rnd(44);
    RequestArb__io_mshrTask_bits_isKeyword = $urandom % 2;
    RequestArb__io_mshrTask_bits_opcode = (($urandom % 2) == 0) ? 4'($urandom_range(1, 5)) : 4'($urandom);
    RequestArb__io_mshrTask_bits_param = rnd(3);
    RequestArb__io_mshrTask_bits_size = rnd(3);
    RequestArb__io_mshrTask_bits_sourceId = rnd(7);
    RequestArb__io_mshrTask_bits_bufIdx = rnd(2);
    RequestArb__io_mshrTask_bits_needProbeAckData = $urandom % 2;
    RequestArb__io_mshrTask_bits_denied = $urandom % 2;
    RequestArb__io_mshrTask_bits_corrupt = $urandom % 2;
    RequestArb__io_mshrTask_bits_mshrTask = $urandom % 2;
    RequestArb__io_mshrTask_bits_mshrId = rnd(8);
    RequestArb__io_mshrTask_bits_aliasTask = $urandom % 2;
    RequestArb__io_mshrTask_bits_useProbeData = $urandom % 2;
    RequestArb__io_mshrTask_bits_mshrRetry = $urandom % 2;
    RequestArb__io_mshrTask_bits_readProbeDataDown = $urandom % 2;
    RequestArb__io_mshrTask_bits_fromL2pft = $urandom % 2;
    RequestArb__io_mshrTask_bits_needHint = $urandom % 2;
    RequestArb__io_mshrTask_bits_dirty = $urandom % 2;
    RequestArb__io_mshrTask_bits_way = rnd(3);
    RequestArb__io_mshrTask_bits_meta_dirty = $urandom % 2;
    RequestArb__io_mshrTask_bits_meta_state = rnd(2);
    RequestArb__io_mshrTask_bits_meta_clients = $urandom % 2;
    RequestArb__io_mshrTask_bits_meta_alias = rnd(2);
    RequestArb__io_mshrTask_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_mshrTask_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_mshrTask_bits_meta_accessed = $urandom % 2;
    RequestArb__io_mshrTask_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_mshrTask_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_mshrTask_bits_metaWen = $urandom % 2;
    RequestArb__io_mshrTask_bits_tagWen = $urandom % 2;
    RequestArb__io_mshrTask_bits_dsWen = $urandom % 2;
    RequestArb__io_mshrTask_bits_wayMask = rnd(8);
    RequestArb__io_mshrTask_bits_replTask = $urandom % 2;
    RequestArb__io_mshrTask_bits_cmoTask = $urandom % 2;
    RequestArb__io_mshrTask_bits_cmoAll = $urandom % 2;
    RequestArb__io_mshrTask_bits_reqSource = rnd(5);
    RequestArb__io_mshrTask_bits_mergeA = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_off = rnd(6);
    RequestArb__io_mshrTask_bits_aMergeTask_alias = rnd(2);
    RequestArb__io_mshrTask_bits_aMergeTask_vaddr = rnd(44);
    RequestArb__io_mshrTask_bits_aMergeTask_isKeyword = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_opcode = rnd(3);
    RequestArb__io_mshrTask_bits_aMergeTask_param = rnd(3);
    RequestArb__io_mshrTask_bits_aMergeTask_sourceId = rnd(7);
    RequestArb__io_mshrTask_bits_aMergeTask_meta_dirty = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_meta_state = rnd(2);
    RequestArb__io_mshrTask_bits_aMergeTask_meta_clients = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_meta_alias = rnd(2);
    RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetch = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_meta_prefetchSrc = rnd(3);
    RequestArb__io_mshrTask_bits_aMergeTask_meta_accessed = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_meta_tagErr = $urandom % 2;
    RequestArb__io_mshrTask_bits_aMergeTask_meta_dataErr = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitRelease = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseToInval = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseToClean = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseWithData = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseIdx = rnd(8);
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dirty = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_state = rnd(2);
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_clients = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_alias = rnd(2);
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetch = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc = rnd(3);
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_accessed = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_tagErr = $urandom % 2;
    RequestArb__io_mshrTask_bits_snpHitReleaseMeta_dataErr = $urandom % 2;
    RequestArb__io_mshrTask_bits_tgtID = rnd(11);
    RequestArb__io_mshrTask_bits_srcID = rnd(11);
    RequestArb__io_mshrTask_bits_txnID = rnd(12);
    RequestArb__io_mshrTask_bits_homeNID = rnd(11);
    RequestArb__io_mshrTask_bits_dbID = rnd(12);
    RequestArb__io_mshrTask_bits_fwdNID = rnd(11);
    RequestArb__io_mshrTask_bits_fwdTxnID = rnd(12);
    RequestArb__io_mshrTask_bits_chiOpcode = (($urandom % 2) == 0) ? 7'($urandom) : (($urandom % 4) == 0 ? 7'h1B : ($urandom % 3) == 0 ? 7'h15 : ($urandom % 2) ? 7'h42 : 7'h0D);
    RequestArb__io_mshrTask_bits_resp = rnd(3);
    RequestArb__io_mshrTask_bits_fwdState = rnd(3);
    RequestArb__io_mshrTask_bits_pCrdType = rnd(4);
    RequestArb__io_mshrTask_bits_retToSrc = $urandom % 2;
    RequestArb__io_mshrTask_bits_likelyshared = $urandom % 2;
    RequestArb__io_mshrTask_bits_expCompAck = $urandom % 2;
    RequestArb__io_mshrTask_bits_allowRetry = $urandom % 2;
    RequestArb__io_mshrTask_bits_memAttr_allocate = $urandom % 2;
    RequestArb__io_mshrTask_bits_memAttr_cacheable = $urandom % 2;
    RequestArb__io_mshrTask_bits_memAttr_device = $urandom % 2;
    RequestArb__io_mshrTask_bits_memAttr_ewa = $urandom % 2;
    RequestArb__io_mshrTask_bits_traceTag = $urandom % 2;
    RequestArb__io_dirRead_s1_ready = (($urandom % 4) != 0);
    RequestArb__io_fromMSHRCtl_blockG_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMSHRCtl_blockA_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMSHRCtl_blockB_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMSHRCtl_blockC_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMainPipe_blockG_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMainPipe_blockA_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMainPipe_blockB_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromMainPipe_blockC_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1 = (($urandom % 8) == 0);
    RequestArb__io_fromGrantBuffer_blockMSHRReqEntrance = (($urandom % 8) == 0);
    RequestArb__io_fromTXDAT_blockMSHRReqEntrance = (($urandom % 8) == 0);
    RequestArb__io_fromTXDAT_blockSinkBReqEntrance = (($urandom % 8) == 0);
    RequestArb__io_fromTXRSP_blockMSHRReqEntrance = (($urandom % 8) == 0);
    RequestArb__io_fromTXRSP_blockSinkBReqEntrance = (($urandom % 8) == 0);
    RequestArb__io_fromTXREQ_blockMSHRReqEntrance = (($urandom % 8) == 0);
    RequestArb__io_msInfo_0_valid = $urandom % 2;
    RequestArb__io_msInfo_0_bits_channel = rnd(3);
    RequestArb__io_msInfo_0_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_0_bits_way = rnd(3);
    RequestArb__io_msInfo_0_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_0_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_0_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_0_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_0_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_0_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_0_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_0_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_0_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_0_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_0_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_0_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_0_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_0_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_0_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_0_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_0_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_0_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_0_bits_param = rnd(3);
    RequestArb__io_msInfo_0_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_0_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_0_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_0_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_0_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_0_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_0_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_0_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_0_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_0_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_0_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_1_valid = $urandom % 2;
    RequestArb__io_msInfo_1_bits_channel = rnd(3);
    RequestArb__io_msInfo_1_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_1_bits_way = rnd(3);
    RequestArb__io_msInfo_1_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_1_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_1_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_1_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_1_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_1_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_1_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_1_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_1_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_1_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_1_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_1_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_1_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_1_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_1_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_1_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_1_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_1_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_1_bits_param = rnd(3);
    RequestArb__io_msInfo_1_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_1_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_1_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_1_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_1_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_1_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_1_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_1_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_1_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_1_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_1_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_2_valid = $urandom % 2;
    RequestArb__io_msInfo_2_bits_channel = rnd(3);
    RequestArb__io_msInfo_2_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_2_bits_way = rnd(3);
    RequestArb__io_msInfo_2_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_2_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_2_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_2_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_2_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_2_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_2_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_2_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_2_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_2_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_2_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_2_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_2_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_2_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_2_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_2_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_2_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_2_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_2_bits_param = rnd(3);
    RequestArb__io_msInfo_2_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_2_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_2_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_2_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_2_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_2_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_2_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_2_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_2_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_2_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_2_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_3_valid = $urandom % 2;
    RequestArb__io_msInfo_3_bits_channel = rnd(3);
    RequestArb__io_msInfo_3_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_3_bits_way = rnd(3);
    RequestArb__io_msInfo_3_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_3_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_3_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_3_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_3_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_3_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_3_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_3_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_3_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_3_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_3_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_3_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_3_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_3_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_3_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_3_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_3_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_3_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_3_bits_param = rnd(3);
    RequestArb__io_msInfo_3_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_3_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_3_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_3_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_3_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_3_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_3_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_3_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_3_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_3_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_3_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_4_valid = $urandom % 2;
    RequestArb__io_msInfo_4_bits_channel = rnd(3);
    RequestArb__io_msInfo_4_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_4_bits_way = rnd(3);
    RequestArb__io_msInfo_4_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_4_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_4_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_4_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_4_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_4_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_4_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_4_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_4_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_4_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_4_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_4_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_4_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_4_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_4_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_4_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_4_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_4_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_4_bits_param = rnd(3);
    RequestArb__io_msInfo_4_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_4_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_4_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_4_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_4_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_4_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_4_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_4_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_4_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_4_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_4_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_5_valid = $urandom % 2;
    RequestArb__io_msInfo_5_bits_channel = rnd(3);
    RequestArb__io_msInfo_5_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_5_bits_way = rnd(3);
    RequestArb__io_msInfo_5_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_5_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_5_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_5_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_5_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_5_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_5_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_5_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_5_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_5_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_5_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_5_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_5_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_5_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_5_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_5_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_5_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_5_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_5_bits_param = rnd(3);
    RequestArb__io_msInfo_5_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_5_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_5_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_5_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_5_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_5_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_5_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_5_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_5_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_5_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_5_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_6_valid = $urandom % 2;
    RequestArb__io_msInfo_6_bits_channel = rnd(3);
    RequestArb__io_msInfo_6_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_6_bits_way = rnd(3);
    RequestArb__io_msInfo_6_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_6_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_6_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_6_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_6_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_6_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_6_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_6_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_6_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_6_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_6_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_6_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_6_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_6_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_6_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_6_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_6_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_6_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_6_bits_param = rnd(3);
    RequestArb__io_msInfo_6_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_6_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_6_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_6_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_6_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_6_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_6_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_6_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_6_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_6_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_6_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_7_valid = $urandom % 2;
    RequestArb__io_msInfo_7_bits_channel = rnd(3);
    RequestArb__io_msInfo_7_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_7_bits_way = rnd(3);
    RequestArb__io_msInfo_7_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_7_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_7_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_7_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_7_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_7_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_7_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_7_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_7_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_7_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_7_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_7_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_7_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_7_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_7_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_7_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_7_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_7_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_7_bits_param = rnd(3);
    RequestArb__io_msInfo_7_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_7_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_7_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_7_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_7_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_7_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_7_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_7_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_7_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_7_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_7_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_8_valid = $urandom % 2;
    RequestArb__io_msInfo_8_bits_channel = rnd(3);
    RequestArb__io_msInfo_8_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_8_bits_way = rnd(3);
    RequestArb__io_msInfo_8_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_8_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_8_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_8_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_8_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_8_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_8_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_8_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_8_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_8_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_8_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_8_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_8_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_8_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_8_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_8_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_8_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_8_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_8_bits_param = rnd(3);
    RequestArb__io_msInfo_8_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_8_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_8_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_8_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_8_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_8_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_8_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_8_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_8_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_8_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_8_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_9_valid = $urandom % 2;
    RequestArb__io_msInfo_9_bits_channel = rnd(3);
    RequestArb__io_msInfo_9_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_9_bits_way = rnd(3);
    RequestArb__io_msInfo_9_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_9_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_9_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_9_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_9_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_9_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_9_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_9_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_9_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_9_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_9_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_9_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_9_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_9_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_9_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_9_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_9_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_9_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_9_bits_param = rnd(3);
    RequestArb__io_msInfo_9_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_9_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_9_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_9_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_9_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_9_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_9_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_9_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_9_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_9_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_9_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_10_valid = $urandom % 2;
    RequestArb__io_msInfo_10_bits_channel = rnd(3);
    RequestArb__io_msInfo_10_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_10_bits_way = rnd(3);
    RequestArb__io_msInfo_10_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_10_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_10_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_10_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_10_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_10_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_10_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_10_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_10_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_10_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_10_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_10_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_10_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_10_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_10_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_10_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_10_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_10_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_10_bits_param = rnd(3);
    RequestArb__io_msInfo_10_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_10_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_10_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_10_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_10_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_10_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_10_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_10_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_10_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_10_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_10_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_11_valid = $urandom % 2;
    RequestArb__io_msInfo_11_bits_channel = rnd(3);
    RequestArb__io_msInfo_11_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_11_bits_way = rnd(3);
    RequestArb__io_msInfo_11_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_11_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_11_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_11_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_11_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_11_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_11_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_11_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_11_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_11_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_11_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_11_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_11_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_11_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_11_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_11_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_11_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_11_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_11_bits_param = rnd(3);
    RequestArb__io_msInfo_11_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_11_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_11_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_11_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_11_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_11_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_11_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_11_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_11_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_11_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_11_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_12_valid = $urandom % 2;
    RequestArb__io_msInfo_12_bits_channel = rnd(3);
    RequestArb__io_msInfo_12_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_12_bits_way = rnd(3);
    RequestArb__io_msInfo_12_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_12_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_12_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_12_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_12_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_12_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_12_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_12_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_12_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_12_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_12_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_12_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_12_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_12_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_12_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_12_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_12_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_12_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_12_bits_param = rnd(3);
    RequestArb__io_msInfo_12_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_12_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_12_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_12_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_12_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_12_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_12_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_12_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_12_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_12_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_12_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_13_valid = $urandom % 2;
    RequestArb__io_msInfo_13_bits_channel = rnd(3);
    RequestArb__io_msInfo_13_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_13_bits_way = rnd(3);
    RequestArb__io_msInfo_13_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_13_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_13_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_13_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_13_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_13_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_13_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_13_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_13_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_13_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_13_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_13_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_13_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_13_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_13_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_13_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_13_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_13_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_13_bits_param = rnd(3);
    RequestArb__io_msInfo_13_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_13_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_13_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_13_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_13_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_13_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_13_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_13_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_13_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_13_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_13_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_14_valid = $urandom % 2;
    RequestArb__io_msInfo_14_bits_channel = rnd(3);
    RequestArb__io_msInfo_14_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_14_bits_way = rnd(3);
    RequestArb__io_msInfo_14_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_14_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_14_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_14_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_14_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_14_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_14_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_14_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_14_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_14_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_14_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_14_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_14_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_14_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_14_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_14_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_14_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_14_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_14_bits_param = rnd(3);
    RequestArb__io_msInfo_14_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_14_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_14_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_14_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_14_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_14_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_14_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_14_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_14_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_14_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_14_bits_releaseToClean = $urandom % 2;
    RequestArb__io_msInfo_15_valid = $urandom % 2;
    RequestArb__io_msInfo_15_bits_channel = rnd(3);
    RequestArb__io_msInfo_15_bits_set = 9'($urandom_range(0, 3));
    RequestArb__io_msInfo_15_bits_way = rnd(3);
    RequestArb__io_msInfo_15_bits_reqTag = rnd(31);
    RequestArb__io_msInfo_15_bits_willFree = $urandom % 2;
    RequestArb__io_msInfo_15_bits_aliasTask = $urandom % 2;
    RequestArb__io_msInfo_15_bits_needRelease = $urandom % 2;
    RequestArb__io_msInfo_15_bits_blockRefill = $urandom % 2;
    RequestArb__io_msInfo_15_bits_meta_dirty = $urandom % 2;
    RequestArb__io_msInfo_15_bits_meta_state = rnd(2);
    RequestArb__io_msInfo_15_bits_meta_clients = $urandom % 2;
    RequestArb__io_msInfo_15_bits_meta_alias = rnd(2);
    RequestArb__io_msInfo_15_bits_meta_prefetch = $urandom % 2;
    RequestArb__io_msInfo_15_bits_meta_prefetchSrc = rnd(3);
    RequestArb__io_msInfo_15_bits_meta_accessed = $urandom % 2;
    RequestArb__io_msInfo_15_bits_meta_tagErr = $urandom % 2;
    RequestArb__io_msInfo_15_bits_meta_dataErr = $urandom % 2;
    RequestArb__io_msInfo_15_bits_metaTag = rnd(31);
    RequestArb__io_msInfo_15_bits_dirHit = $urandom % 2;
    RequestArb__io_msInfo_15_bits_isAcqOrPrefetch = $urandom % 2;
    RequestArb__io_msInfo_15_bits_isPrefetch = $urandom % 2;
    RequestArb__io_msInfo_15_bits_param = rnd(3);
    RequestArb__io_msInfo_15_bits_mergeA = $urandom % 2;
    RequestArb__io_msInfo_15_bits_w_grantfirst = $urandom % 2;
    RequestArb__io_msInfo_15_bits_s_release = $urandom % 2;
    RequestArb__io_msInfo_15_bits_s_refill = $urandom % 2;
    RequestArb__io_msInfo_15_bits_s_cmoresp = $urandom % 2;
    RequestArb__io_msInfo_15_bits_s_cmometaw = $urandom % 2;
    RequestArb__io_msInfo_15_bits_w_releaseack = $urandom % 2;
    RequestArb__io_msInfo_15_bits_w_replResp = $urandom % 2;
    RequestArb__io_msInfo_15_bits_w_rprobeacklast = $urandom % 2;
    RequestArb__io_msInfo_15_bits_replaceData = $urandom % 2;
    RequestArb__io_msInfo_15_bits_releaseToClean = $urandom % 2;
  endtask
  task automatic check_RequestArb();
    checks++;
    if (g_RequestArb__io_sinkA_ready !== i_RequestArb__io_sinkA_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_sinkA_ready g=%h i=%h", cyc, g_RequestArb__io_sinkA_ready, i_RequestArb__io_sinkA_ready);
    end
    if (g_RequestArb__io_sinkA_ready !== p_RequestArb__io_sinkA_ready) t_RequestArb__io_sinkA_ready = 1'b1;
    p_RequestArb__io_sinkA_ready = g_RequestArb__io_sinkA_ready;
    checks++;
    if (g_RequestArb__io_s1Entrance_valid !== i_RequestArb__io_s1Entrance_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_s1Entrance_valid g=%h i=%h", cyc, g_RequestArb__io_s1Entrance_valid, i_RequestArb__io_s1Entrance_valid);
    end
    if (g_RequestArb__io_s1Entrance_valid !== p_RequestArb__io_s1Entrance_valid) t_RequestArb__io_s1Entrance_valid = 1'b1;
    p_RequestArb__io_s1Entrance_valid = g_RequestArb__io_s1Entrance_valid;
    checks++;
    if (g_RequestArb__io_s1Entrance_bits_set !== i_RequestArb__io_s1Entrance_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_s1Entrance_bits_set g=%h i=%h", cyc, g_RequestArb__io_s1Entrance_bits_set, i_RequestArb__io_s1Entrance_bits_set);
    end
    if (g_RequestArb__io_s1Entrance_bits_set !== p_RequestArb__io_s1Entrance_bits_set) t_RequestArb__io_s1Entrance_bits_set = 1'b1;
    p_RequestArb__io_s1Entrance_bits_set = g_RequestArb__io_s1Entrance_bits_set;
    checks++;
    if (g_RequestArb__io_sinkB_ready !== i_RequestArb__io_sinkB_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_sinkB_ready g=%h i=%h", cyc, g_RequestArb__io_sinkB_ready, i_RequestArb__io_sinkB_ready);
    end
    if (g_RequestArb__io_sinkB_ready !== p_RequestArb__io_sinkB_ready) t_RequestArb__io_sinkB_ready = 1'b1;
    p_RequestArb__io_sinkB_ready = g_RequestArb__io_sinkB_ready;
    checks++;
    if (g_RequestArb__io_sinkC_ready !== i_RequestArb__io_sinkC_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_sinkC_ready g=%h i=%h", cyc, g_RequestArb__io_sinkC_ready, i_RequestArb__io_sinkC_ready);
    end
    if (g_RequestArb__io_sinkC_ready !== p_RequestArb__io_sinkC_ready) t_RequestArb__io_sinkC_ready = 1'b1;
    p_RequestArb__io_sinkC_ready = g_RequestArb__io_sinkC_ready;
    checks++;
    if (g_RequestArb__io_mshrTask_ready !== i_RequestArb__io_mshrTask_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_mshrTask_ready g=%h i=%h", cyc, g_RequestArb__io_mshrTask_ready, i_RequestArb__io_mshrTask_ready);
    end
    if (g_RequestArb__io_mshrTask_ready !== p_RequestArb__io_mshrTask_ready) t_RequestArb__io_mshrTask_ready = 1'b1;
    p_RequestArb__io_mshrTask_ready = g_RequestArb__io_mshrTask_ready;
    checks++;
    if (g_RequestArb__io_dirRead_s1_valid !== i_RequestArb__io_dirRead_s1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_valid g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_valid, i_RequestArb__io_dirRead_s1_valid);
    end
    if (g_RequestArb__io_dirRead_s1_valid !== p_RequestArb__io_dirRead_s1_valid) t_RequestArb__io_dirRead_s1_valid = 1'b1;
    p_RequestArb__io_dirRead_s1_valid = g_RequestArb__io_dirRead_s1_valid;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_tag !== i_RequestArb__io_dirRead_s1_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_tag g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_tag, i_RequestArb__io_dirRead_s1_bits_tag);
    end
    if (g_RequestArb__io_dirRead_s1_bits_tag !== p_RequestArb__io_dirRead_s1_bits_tag) t_RequestArb__io_dirRead_s1_bits_tag = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_tag = g_RequestArb__io_dirRead_s1_bits_tag;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_set !== i_RequestArb__io_dirRead_s1_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_set g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_set, i_RequestArb__io_dirRead_s1_bits_set);
    end
    if (g_RequestArb__io_dirRead_s1_bits_set !== p_RequestArb__io_dirRead_s1_bits_set) t_RequestArb__io_dirRead_s1_bits_set = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_set = g_RequestArb__io_dirRead_s1_bits_set;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_wayMask !== i_RequestArb__io_dirRead_s1_bits_wayMask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_wayMask g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_wayMask, i_RequestArb__io_dirRead_s1_bits_wayMask);
    end
    if (g_RequestArb__io_dirRead_s1_bits_wayMask !== p_RequestArb__io_dirRead_s1_bits_wayMask) t_RequestArb__io_dirRead_s1_bits_wayMask = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_wayMask = g_RequestArb__io_dirRead_s1_bits_wayMask;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_channel !== i_RequestArb__io_dirRead_s1_bits_replacerInfo_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_replacerInfo_channel g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_replacerInfo_channel, i_RequestArb__io_dirRead_s1_bits_replacerInfo_channel);
    end
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_channel !== p_RequestArb__io_dirRead_s1_bits_replacerInfo_channel) t_RequestArb__io_dirRead_s1_bits_replacerInfo_channel = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_replacerInfo_channel = g_RequestArb__io_dirRead_s1_bits_replacerInfo_channel;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode !== i_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_replacerInfo_opcode g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode, i_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode);
    end
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode !== p_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode) t_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode = g_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource !== i_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_replacerInfo_reqSource g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource, i_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource);
    end
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource !== p_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource) t_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource = g_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch !== i_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_replacerInfo_refill_prefetch g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch, i_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch);
    end
    if (g_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch !== p_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch) t_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch = g_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_refill !== i_RequestArb__io_dirRead_s1_bits_refill) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_refill g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_refill, i_RequestArb__io_dirRead_s1_bits_refill);
    end
    if (g_RequestArb__io_dirRead_s1_bits_refill !== p_RequestArb__io_dirRead_s1_bits_refill) t_RequestArb__io_dirRead_s1_bits_refill = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_refill = g_RequestArb__io_dirRead_s1_bits_refill;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_mshrId !== i_RequestArb__io_dirRead_s1_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_mshrId g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_mshrId, i_RequestArb__io_dirRead_s1_bits_mshrId);
    end
    if (g_RequestArb__io_dirRead_s1_bits_mshrId !== p_RequestArb__io_dirRead_s1_bits_mshrId) t_RequestArb__io_dirRead_s1_bits_mshrId = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_mshrId = g_RequestArb__io_dirRead_s1_bits_mshrId;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_cmoAll !== i_RequestArb__io_dirRead_s1_bits_cmoAll) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_cmoAll g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_cmoAll, i_RequestArb__io_dirRead_s1_bits_cmoAll);
    end
    if (g_RequestArb__io_dirRead_s1_bits_cmoAll !== p_RequestArb__io_dirRead_s1_bits_cmoAll) t_RequestArb__io_dirRead_s1_bits_cmoAll = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_cmoAll = g_RequestArb__io_dirRead_s1_bits_cmoAll;
    checks++;
    if (g_RequestArb__io_dirRead_s1_bits_cmoWay !== i_RequestArb__io_dirRead_s1_bits_cmoWay) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_dirRead_s1_bits_cmoWay g=%h i=%h", cyc, g_RequestArb__io_dirRead_s1_bits_cmoWay, i_RequestArb__io_dirRead_s1_bits_cmoWay);
    end
    if (g_RequestArb__io_dirRead_s1_bits_cmoWay !== p_RequestArb__io_dirRead_s1_bits_cmoWay) t_RequestArb__io_dirRead_s1_bits_cmoWay = 1'b1;
    p_RequestArb__io_dirRead_s1_bits_cmoWay = g_RequestArb__io_dirRead_s1_bits_cmoWay;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_valid !== i_RequestArb__io_taskToPipe_s2_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_valid g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_valid, i_RequestArb__io_taskToPipe_s2_valid);
    end
    if (g_RequestArb__io_taskToPipe_s2_valid !== p_RequestArb__io_taskToPipe_s2_valid) t_RequestArb__io_taskToPipe_s2_valid = 1'b1;
    p_RequestArb__io_taskToPipe_s2_valid = g_RequestArb__io_taskToPipe_s2_valid;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_channel !== i_RequestArb__io_taskToPipe_s2_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_channel g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_channel, i_RequestArb__io_taskToPipe_s2_bits_channel);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_channel !== p_RequestArb__io_taskToPipe_s2_bits_channel) t_RequestArb__io_taskToPipe_s2_bits_channel = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_channel = g_RequestArb__io_taskToPipe_s2_bits_channel;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_txChannel !== i_RequestArb__io_taskToPipe_s2_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_txChannel g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_txChannel, i_RequestArb__io_taskToPipe_s2_bits_txChannel);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_txChannel !== p_RequestArb__io_taskToPipe_s2_bits_txChannel) t_RequestArb__io_taskToPipe_s2_bits_txChannel = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_txChannel = g_RequestArb__io_taskToPipe_s2_bits_txChannel;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_set !== i_RequestArb__io_taskToPipe_s2_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_set g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_set, i_RequestArb__io_taskToPipe_s2_bits_set);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_set !== p_RequestArb__io_taskToPipe_s2_bits_set) t_RequestArb__io_taskToPipe_s2_bits_set = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_set = g_RequestArb__io_taskToPipe_s2_bits_set;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_tag !== i_RequestArb__io_taskToPipe_s2_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_tag g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_tag, i_RequestArb__io_taskToPipe_s2_bits_tag);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_tag !== p_RequestArb__io_taskToPipe_s2_bits_tag) t_RequestArb__io_taskToPipe_s2_bits_tag = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_tag = g_RequestArb__io_taskToPipe_s2_bits_tag;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_off !== i_RequestArb__io_taskToPipe_s2_bits_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_off g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_off, i_RequestArb__io_taskToPipe_s2_bits_off);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_off !== p_RequestArb__io_taskToPipe_s2_bits_off) t_RequestArb__io_taskToPipe_s2_bits_off = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_off = g_RequestArb__io_taskToPipe_s2_bits_off;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_alias !== i_RequestArb__io_taskToPipe_s2_bits_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_alias g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_alias, i_RequestArb__io_taskToPipe_s2_bits_alias);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_alias !== p_RequestArb__io_taskToPipe_s2_bits_alias) t_RequestArb__io_taskToPipe_s2_bits_alias = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_alias = g_RequestArb__io_taskToPipe_s2_bits_alias;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_vaddr !== i_RequestArb__io_taskToPipe_s2_bits_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_vaddr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_vaddr, i_RequestArb__io_taskToPipe_s2_bits_vaddr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_vaddr !== p_RequestArb__io_taskToPipe_s2_bits_vaddr) t_RequestArb__io_taskToPipe_s2_bits_vaddr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_vaddr = g_RequestArb__io_taskToPipe_s2_bits_vaddr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_isKeyword !== i_RequestArb__io_taskToPipe_s2_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_isKeyword g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_isKeyword, i_RequestArb__io_taskToPipe_s2_bits_isKeyword);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_isKeyword !== p_RequestArb__io_taskToPipe_s2_bits_isKeyword) t_RequestArb__io_taskToPipe_s2_bits_isKeyword = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_isKeyword = g_RequestArb__io_taskToPipe_s2_bits_isKeyword;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_opcode !== i_RequestArb__io_taskToPipe_s2_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_opcode g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_opcode, i_RequestArb__io_taskToPipe_s2_bits_opcode);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_opcode !== p_RequestArb__io_taskToPipe_s2_bits_opcode) t_RequestArb__io_taskToPipe_s2_bits_opcode = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_opcode = g_RequestArb__io_taskToPipe_s2_bits_opcode;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_param !== i_RequestArb__io_taskToPipe_s2_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_param g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_param, i_RequestArb__io_taskToPipe_s2_bits_param);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_param !== p_RequestArb__io_taskToPipe_s2_bits_param) t_RequestArb__io_taskToPipe_s2_bits_param = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_param = g_RequestArb__io_taskToPipe_s2_bits_param;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_size !== i_RequestArb__io_taskToPipe_s2_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_size g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_size, i_RequestArb__io_taskToPipe_s2_bits_size);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_size !== p_RequestArb__io_taskToPipe_s2_bits_size) t_RequestArb__io_taskToPipe_s2_bits_size = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_size = g_RequestArb__io_taskToPipe_s2_bits_size;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_sourceId !== i_RequestArb__io_taskToPipe_s2_bits_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_sourceId g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_sourceId, i_RequestArb__io_taskToPipe_s2_bits_sourceId);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_sourceId !== p_RequestArb__io_taskToPipe_s2_bits_sourceId) t_RequestArb__io_taskToPipe_s2_bits_sourceId = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_sourceId = g_RequestArb__io_taskToPipe_s2_bits_sourceId;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_bufIdx !== i_RequestArb__io_taskToPipe_s2_bits_bufIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_bufIdx g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_bufIdx, i_RequestArb__io_taskToPipe_s2_bits_bufIdx);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_bufIdx !== p_RequestArb__io_taskToPipe_s2_bits_bufIdx) t_RequestArb__io_taskToPipe_s2_bits_bufIdx = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_bufIdx = g_RequestArb__io_taskToPipe_s2_bits_bufIdx;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_needProbeAckData !== i_RequestArb__io_taskToPipe_s2_bits_needProbeAckData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_needProbeAckData g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_needProbeAckData, i_RequestArb__io_taskToPipe_s2_bits_needProbeAckData);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_needProbeAckData !== p_RequestArb__io_taskToPipe_s2_bits_needProbeAckData) t_RequestArb__io_taskToPipe_s2_bits_needProbeAckData = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_needProbeAckData = g_RequestArb__io_taskToPipe_s2_bits_needProbeAckData;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_denied !== i_RequestArb__io_taskToPipe_s2_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_denied g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_denied, i_RequestArb__io_taskToPipe_s2_bits_denied);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_denied !== p_RequestArb__io_taskToPipe_s2_bits_denied) t_RequestArb__io_taskToPipe_s2_bits_denied = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_denied = g_RequestArb__io_taskToPipe_s2_bits_denied;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_corrupt !== i_RequestArb__io_taskToPipe_s2_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_corrupt g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_corrupt, i_RequestArb__io_taskToPipe_s2_bits_corrupt);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_corrupt !== p_RequestArb__io_taskToPipe_s2_bits_corrupt) t_RequestArb__io_taskToPipe_s2_bits_corrupt = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_corrupt = g_RequestArb__io_taskToPipe_s2_bits_corrupt;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_mshrTask !== i_RequestArb__io_taskToPipe_s2_bits_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_mshrTask g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_mshrTask, i_RequestArb__io_taskToPipe_s2_bits_mshrTask);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_mshrTask !== p_RequestArb__io_taskToPipe_s2_bits_mshrTask) t_RequestArb__io_taskToPipe_s2_bits_mshrTask = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_mshrTask = g_RequestArb__io_taskToPipe_s2_bits_mshrTask;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_mshrId !== i_RequestArb__io_taskToPipe_s2_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_mshrId g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_mshrId, i_RequestArb__io_taskToPipe_s2_bits_mshrId);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_mshrId !== p_RequestArb__io_taskToPipe_s2_bits_mshrId) t_RequestArb__io_taskToPipe_s2_bits_mshrId = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_mshrId = g_RequestArb__io_taskToPipe_s2_bits_mshrId;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aliasTask !== i_RequestArb__io_taskToPipe_s2_bits_aliasTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aliasTask g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aliasTask, i_RequestArb__io_taskToPipe_s2_bits_aliasTask);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aliasTask !== p_RequestArb__io_taskToPipe_s2_bits_aliasTask) t_RequestArb__io_taskToPipe_s2_bits_aliasTask = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aliasTask = g_RequestArb__io_taskToPipe_s2_bits_aliasTask;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_useProbeData !== i_RequestArb__io_taskToPipe_s2_bits_useProbeData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_useProbeData g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_useProbeData, i_RequestArb__io_taskToPipe_s2_bits_useProbeData);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_useProbeData !== p_RequestArb__io_taskToPipe_s2_bits_useProbeData) t_RequestArb__io_taskToPipe_s2_bits_useProbeData = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_useProbeData = g_RequestArb__io_taskToPipe_s2_bits_useProbeData;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_mshrRetry !== i_RequestArb__io_taskToPipe_s2_bits_mshrRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_mshrRetry g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_mshrRetry, i_RequestArb__io_taskToPipe_s2_bits_mshrRetry);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_mshrRetry !== p_RequestArb__io_taskToPipe_s2_bits_mshrRetry) t_RequestArb__io_taskToPipe_s2_bits_mshrRetry = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_mshrRetry = g_RequestArb__io_taskToPipe_s2_bits_mshrRetry;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown !== i_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_readProbeDataDown g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown, i_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown !== p_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown) t_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown = g_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_fromL2pft !== i_RequestArb__io_taskToPipe_s2_bits_fromL2pft) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_fromL2pft g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_fromL2pft, i_RequestArb__io_taskToPipe_s2_bits_fromL2pft);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_fromL2pft !== p_RequestArb__io_taskToPipe_s2_bits_fromL2pft) t_RequestArb__io_taskToPipe_s2_bits_fromL2pft = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_fromL2pft = g_RequestArb__io_taskToPipe_s2_bits_fromL2pft;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_needHint !== i_RequestArb__io_taskToPipe_s2_bits_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_needHint g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_needHint, i_RequestArb__io_taskToPipe_s2_bits_needHint);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_needHint !== p_RequestArb__io_taskToPipe_s2_bits_needHint) t_RequestArb__io_taskToPipe_s2_bits_needHint = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_needHint = g_RequestArb__io_taskToPipe_s2_bits_needHint;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_dirty !== i_RequestArb__io_taskToPipe_s2_bits_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_dirty g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_dirty, i_RequestArb__io_taskToPipe_s2_bits_dirty);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_dirty !== p_RequestArb__io_taskToPipe_s2_bits_dirty) t_RequestArb__io_taskToPipe_s2_bits_dirty = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_dirty = g_RequestArb__io_taskToPipe_s2_bits_dirty;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_way !== i_RequestArb__io_taskToPipe_s2_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_way g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_way, i_RequestArb__io_taskToPipe_s2_bits_way);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_way !== p_RequestArb__io_taskToPipe_s2_bits_way) t_RequestArb__io_taskToPipe_s2_bits_way = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_way = g_RequestArb__io_taskToPipe_s2_bits_way;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_dirty !== i_RequestArb__io_taskToPipe_s2_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_dirty g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_dirty, i_RequestArb__io_taskToPipe_s2_bits_meta_dirty);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_dirty !== p_RequestArb__io_taskToPipe_s2_bits_meta_dirty) t_RequestArb__io_taskToPipe_s2_bits_meta_dirty = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_dirty = g_RequestArb__io_taskToPipe_s2_bits_meta_dirty;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_state !== i_RequestArb__io_taskToPipe_s2_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_state g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_state, i_RequestArb__io_taskToPipe_s2_bits_meta_state);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_state !== p_RequestArb__io_taskToPipe_s2_bits_meta_state) t_RequestArb__io_taskToPipe_s2_bits_meta_state = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_state = g_RequestArb__io_taskToPipe_s2_bits_meta_state;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_clients !== i_RequestArb__io_taskToPipe_s2_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_clients g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_clients, i_RequestArb__io_taskToPipe_s2_bits_meta_clients);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_clients !== p_RequestArb__io_taskToPipe_s2_bits_meta_clients) t_RequestArb__io_taskToPipe_s2_bits_meta_clients = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_clients = g_RequestArb__io_taskToPipe_s2_bits_meta_clients;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_alias !== i_RequestArb__io_taskToPipe_s2_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_alias g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_alias, i_RequestArb__io_taskToPipe_s2_bits_meta_alias);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_alias !== p_RequestArb__io_taskToPipe_s2_bits_meta_alias) t_RequestArb__io_taskToPipe_s2_bits_meta_alias = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_alias = g_RequestArb__io_taskToPipe_s2_bits_meta_alias;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_prefetch !== i_RequestArb__io_taskToPipe_s2_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_prefetch g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_prefetch, i_RequestArb__io_taskToPipe_s2_bits_meta_prefetch);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_prefetch !== p_RequestArb__io_taskToPipe_s2_bits_meta_prefetch) t_RequestArb__io_taskToPipe_s2_bits_meta_prefetch = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_prefetch = g_RequestArb__io_taskToPipe_s2_bits_meta_prefetch;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc !== i_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_prefetchSrc g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc, i_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc !== p_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc) t_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc = g_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_accessed !== i_RequestArb__io_taskToPipe_s2_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_accessed g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_accessed, i_RequestArb__io_taskToPipe_s2_bits_meta_accessed);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_accessed !== p_RequestArb__io_taskToPipe_s2_bits_meta_accessed) t_RequestArb__io_taskToPipe_s2_bits_meta_accessed = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_accessed = g_RequestArb__io_taskToPipe_s2_bits_meta_accessed;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_tagErr !== i_RequestArb__io_taskToPipe_s2_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_tagErr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_tagErr, i_RequestArb__io_taskToPipe_s2_bits_meta_tagErr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_tagErr !== p_RequestArb__io_taskToPipe_s2_bits_meta_tagErr) t_RequestArb__io_taskToPipe_s2_bits_meta_tagErr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_tagErr = g_RequestArb__io_taskToPipe_s2_bits_meta_tagErr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_dataErr !== i_RequestArb__io_taskToPipe_s2_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_meta_dataErr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_meta_dataErr, i_RequestArb__io_taskToPipe_s2_bits_meta_dataErr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_meta_dataErr !== p_RequestArb__io_taskToPipe_s2_bits_meta_dataErr) t_RequestArb__io_taskToPipe_s2_bits_meta_dataErr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_meta_dataErr = g_RequestArb__io_taskToPipe_s2_bits_meta_dataErr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_metaWen !== i_RequestArb__io_taskToPipe_s2_bits_metaWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_metaWen g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_metaWen, i_RequestArb__io_taskToPipe_s2_bits_metaWen);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_metaWen !== p_RequestArb__io_taskToPipe_s2_bits_metaWen) t_RequestArb__io_taskToPipe_s2_bits_metaWen = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_metaWen = g_RequestArb__io_taskToPipe_s2_bits_metaWen;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_tagWen !== i_RequestArb__io_taskToPipe_s2_bits_tagWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_tagWen g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_tagWen, i_RequestArb__io_taskToPipe_s2_bits_tagWen);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_tagWen !== p_RequestArb__io_taskToPipe_s2_bits_tagWen) t_RequestArb__io_taskToPipe_s2_bits_tagWen = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_tagWen = g_RequestArb__io_taskToPipe_s2_bits_tagWen;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_dsWen !== i_RequestArb__io_taskToPipe_s2_bits_dsWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_dsWen g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_dsWen, i_RequestArb__io_taskToPipe_s2_bits_dsWen);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_dsWen !== p_RequestArb__io_taskToPipe_s2_bits_dsWen) t_RequestArb__io_taskToPipe_s2_bits_dsWen = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_dsWen = g_RequestArb__io_taskToPipe_s2_bits_dsWen;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_wayMask !== i_RequestArb__io_taskToPipe_s2_bits_wayMask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_wayMask g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_wayMask, i_RequestArb__io_taskToPipe_s2_bits_wayMask);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_wayMask !== p_RequestArb__io_taskToPipe_s2_bits_wayMask) t_RequestArb__io_taskToPipe_s2_bits_wayMask = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_wayMask = g_RequestArb__io_taskToPipe_s2_bits_wayMask;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_replTask !== i_RequestArb__io_taskToPipe_s2_bits_replTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_replTask g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_replTask, i_RequestArb__io_taskToPipe_s2_bits_replTask);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_replTask !== p_RequestArb__io_taskToPipe_s2_bits_replTask) t_RequestArb__io_taskToPipe_s2_bits_replTask = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_replTask = g_RequestArb__io_taskToPipe_s2_bits_replTask;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_cmoTask !== i_RequestArb__io_taskToPipe_s2_bits_cmoTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_cmoTask g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_cmoTask, i_RequestArb__io_taskToPipe_s2_bits_cmoTask);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_cmoTask !== p_RequestArb__io_taskToPipe_s2_bits_cmoTask) t_RequestArb__io_taskToPipe_s2_bits_cmoTask = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_cmoTask = g_RequestArb__io_taskToPipe_s2_bits_cmoTask;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_cmoAll !== i_RequestArb__io_taskToPipe_s2_bits_cmoAll) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_cmoAll g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_cmoAll, i_RequestArb__io_taskToPipe_s2_bits_cmoAll);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_cmoAll !== p_RequestArb__io_taskToPipe_s2_bits_cmoAll) t_RequestArb__io_taskToPipe_s2_bits_cmoAll = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_cmoAll = g_RequestArb__io_taskToPipe_s2_bits_cmoAll;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_reqSource !== i_RequestArb__io_taskToPipe_s2_bits_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_reqSource g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_reqSource, i_RequestArb__io_taskToPipe_s2_bits_reqSource);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_reqSource !== p_RequestArb__io_taskToPipe_s2_bits_reqSource) t_RequestArb__io_taskToPipe_s2_bits_reqSource = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_reqSource = g_RequestArb__io_taskToPipe_s2_bits_reqSource;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_mergeA !== i_RequestArb__io_taskToPipe_s2_bits_mergeA) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_mergeA g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_mergeA, i_RequestArb__io_taskToPipe_s2_bits_mergeA);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_mergeA !== p_RequestArb__io_taskToPipe_s2_bits_mergeA) t_RequestArb__io_taskToPipe_s2_bits_mergeA = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_mergeA = g_RequestArb__io_taskToPipe_s2_bits_mergeA;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_off g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_alias g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_vaddr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_isKeyword g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_opcode g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_param g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_sourceId g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_dirty g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_state g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_clients g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_alias g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_prefetch g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_accessed g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_tagErr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr !== i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_dataErr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr, i_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr !== p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr) t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr = g_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitRelease !== i_RequestArb__io_taskToPipe_s2_bits_snpHitRelease) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitRelease g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitRelease, i_RequestArb__io_taskToPipe_s2_bits_snpHitRelease);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitRelease !== p_RequestArb__io_taskToPipe_s2_bits_snpHitRelease) t_RequestArb__io_taskToPipe_s2_bits_snpHitRelease = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitRelease = g_RequestArb__io_taskToPipe_s2_bits_snpHitRelease;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseToInval g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseToClean g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseWithData g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseIdx g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_state g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_clients g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_alias g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr !== i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr, i_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr !== p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr) t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr = g_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_tgtID !== i_RequestArb__io_taskToPipe_s2_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_tgtID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_tgtID, i_RequestArb__io_taskToPipe_s2_bits_tgtID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_tgtID !== p_RequestArb__io_taskToPipe_s2_bits_tgtID) t_RequestArb__io_taskToPipe_s2_bits_tgtID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_tgtID = g_RequestArb__io_taskToPipe_s2_bits_tgtID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_srcID !== i_RequestArb__io_taskToPipe_s2_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_srcID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_srcID, i_RequestArb__io_taskToPipe_s2_bits_srcID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_srcID !== p_RequestArb__io_taskToPipe_s2_bits_srcID) t_RequestArb__io_taskToPipe_s2_bits_srcID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_srcID = g_RequestArb__io_taskToPipe_s2_bits_srcID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_txnID !== i_RequestArb__io_taskToPipe_s2_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_txnID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_txnID, i_RequestArb__io_taskToPipe_s2_bits_txnID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_txnID !== p_RequestArb__io_taskToPipe_s2_bits_txnID) t_RequestArb__io_taskToPipe_s2_bits_txnID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_txnID = g_RequestArb__io_taskToPipe_s2_bits_txnID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_homeNID !== i_RequestArb__io_taskToPipe_s2_bits_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_homeNID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_homeNID, i_RequestArb__io_taskToPipe_s2_bits_homeNID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_homeNID !== p_RequestArb__io_taskToPipe_s2_bits_homeNID) t_RequestArb__io_taskToPipe_s2_bits_homeNID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_homeNID = g_RequestArb__io_taskToPipe_s2_bits_homeNID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_dbID !== i_RequestArb__io_taskToPipe_s2_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_dbID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_dbID, i_RequestArb__io_taskToPipe_s2_bits_dbID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_dbID !== p_RequestArb__io_taskToPipe_s2_bits_dbID) t_RequestArb__io_taskToPipe_s2_bits_dbID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_dbID = g_RequestArb__io_taskToPipe_s2_bits_dbID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_fwdNID !== i_RequestArb__io_taskToPipe_s2_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_fwdNID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_fwdNID, i_RequestArb__io_taskToPipe_s2_bits_fwdNID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_fwdNID !== p_RequestArb__io_taskToPipe_s2_bits_fwdNID) t_RequestArb__io_taskToPipe_s2_bits_fwdNID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_fwdNID = g_RequestArb__io_taskToPipe_s2_bits_fwdNID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_fwdTxnID !== i_RequestArb__io_taskToPipe_s2_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_fwdTxnID g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_fwdTxnID, i_RequestArb__io_taskToPipe_s2_bits_fwdTxnID);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_fwdTxnID !== p_RequestArb__io_taskToPipe_s2_bits_fwdTxnID) t_RequestArb__io_taskToPipe_s2_bits_fwdTxnID = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_fwdTxnID = g_RequestArb__io_taskToPipe_s2_bits_fwdTxnID;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_chiOpcode !== i_RequestArb__io_taskToPipe_s2_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_chiOpcode g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_chiOpcode, i_RequestArb__io_taskToPipe_s2_bits_chiOpcode);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_chiOpcode !== p_RequestArb__io_taskToPipe_s2_bits_chiOpcode) t_RequestArb__io_taskToPipe_s2_bits_chiOpcode = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_chiOpcode = g_RequestArb__io_taskToPipe_s2_bits_chiOpcode;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_resp !== i_RequestArb__io_taskToPipe_s2_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_resp g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_resp, i_RequestArb__io_taskToPipe_s2_bits_resp);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_resp !== p_RequestArb__io_taskToPipe_s2_bits_resp) t_RequestArb__io_taskToPipe_s2_bits_resp = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_resp = g_RequestArb__io_taskToPipe_s2_bits_resp;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_fwdState !== i_RequestArb__io_taskToPipe_s2_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_fwdState g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_fwdState, i_RequestArb__io_taskToPipe_s2_bits_fwdState);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_fwdState !== p_RequestArb__io_taskToPipe_s2_bits_fwdState) t_RequestArb__io_taskToPipe_s2_bits_fwdState = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_fwdState = g_RequestArb__io_taskToPipe_s2_bits_fwdState;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_pCrdType !== i_RequestArb__io_taskToPipe_s2_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_pCrdType g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_pCrdType, i_RequestArb__io_taskToPipe_s2_bits_pCrdType);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_pCrdType !== p_RequestArb__io_taskToPipe_s2_bits_pCrdType) t_RequestArb__io_taskToPipe_s2_bits_pCrdType = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_pCrdType = g_RequestArb__io_taskToPipe_s2_bits_pCrdType;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_retToSrc !== i_RequestArb__io_taskToPipe_s2_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_retToSrc g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_retToSrc, i_RequestArb__io_taskToPipe_s2_bits_retToSrc);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_retToSrc !== p_RequestArb__io_taskToPipe_s2_bits_retToSrc) t_RequestArb__io_taskToPipe_s2_bits_retToSrc = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_retToSrc = g_RequestArb__io_taskToPipe_s2_bits_retToSrc;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_likelyshared !== i_RequestArb__io_taskToPipe_s2_bits_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_likelyshared g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_likelyshared, i_RequestArb__io_taskToPipe_s2_bits_likelyshared);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_likelyshared !== p_RequestArb__io_taskToPipe_s2_bits_likelyshared) t_RequestArb__io_taskToPipe_s2_bits_likelyshared = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_likelyshared = g_RequestArb__io_taskToPipe_s2_bits_likelyshared;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_expCompAck !== i_RequestArb__io_taskToPipe_s2_bits_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_expCompAck g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_expCompAck, i_RequestArb__io_taskToPipe_s2_bits_expCompAck);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_expCompAck !== p_RequestArb__io_taskToPipe_s2_bits_expCompAck) t_RequestArb__io_taskToPipe_s2_bits_expCompAck = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_expCompAck = g_RequestArb__io_taskToPipe_s2_bits_expCompAck;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_allowRetry !== i_RequestArb__io_taskToPipe_s2_bits_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_allowRetry g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_allowRetry, i_RequestArb__io_taskToPipe_s2_bits_allowRetry);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_allowRetry !== p_RequestArb__io_taskToPipe_s2_bits_allowRetry) t_RequestArb__io_taskToPipe_s2_bits_allowRetry = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_allowRetry = g_RequestArb__io_taskToPipe_s2_bits_allowRetry;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate !== i_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_memAttr_allocate g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate, i_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate !== p_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate) t_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate = g_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable !== i_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_memAttr_cacheable g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable, i_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable !== p_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable) t_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable = g_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_device !== i_RequestArb__io_taskToPipe_s2_bits_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_memAttr_device g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_memAttr_device, i_RequestArb__io_taskToPipe_s2_bits_memAttr_device);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_device !== p_RequestArb__io_taskToPipe_s2_bits_memAttr_device) t_RequestArb__io_taskToPipe_s2_bits_memAttr_device = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_memAttr_device = g_RequestArb__io_taskToPipe_s2_bits_memAttr_device;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa !== i_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_memAttr_ewa g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa, i_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa !== p_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa) t_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa = g_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa;
    checks++;
    if (g_RequestArb__io_taskToPipe_s2_bits_traceTag !== i_RequestArb__io_taskToPipe_s2_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskToPipe_s2_bits_traceTag g=%h i=%h", cyc, g_RequestArb__io_taskToPipe_s2_bits_traceTag, i_RequestArb__io_taskToPipe_s2_bits_traceTag);
    end
    if (g_RequestArb__io_taskToPipe_s2_bits_traceTag !== p_RequestArb__io_taskToPipe_s2_bits_traceTag) t_RequestArb__io_taskToPipe_s2_bits_traceTag = 1'b1;
    p_RequestArb__io_taskToPipe_s2_bits_traceTag = g_RequestArb__io_taskToPipe_s2_bits_traceTag;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_valid !== i_RequestArb__io_taskInfo_s1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_valid g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_valid, i_RequestArb__io_taskInfo_s1_valid);
    end
    if (g_RequestArb__io_taskInfo_s1_valid !== p_RequestArb__io_taskInfo_s1_valid) t_RequestArb__io_taskInfo_s1_valid = 1'b1;
    p_RequestArb__io_taskInfo_s1_valid = g_RequestArb__io_taskInfo_s1_valid;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_channel !== i_RequestArb__io_taskInfo_s1_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_channel g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_channel, i_RequestArb__io_taskInfo_s1_bits_channel);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_channel !== p_RequestArb__io_taskInfo_s1_bits_channel) t_RequestArb__io_taskInfo_s1_bits_channel = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_channel = g_RequestArb__io_taskInfo_s1_bits_channel;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_txChannel !== i_RequestArb__io_taskInfo_s1_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_txChannel g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_txChannel, i_RequestArb__io_taskInfo_s1_bits_txChannel);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_txChannel !== p_RequestArb__io_taskInfo_s1_bits_txChannel) t_RequestArb__io_taskInfo_s1_bits_txChannel = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_txChannel = g_RequestArb__io_taskInfo_s1_bits_txChannel;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_set !== i_RequestArb__io_taskInfo_s1_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_set g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_set, i_RequestArb__io_taskInfo_s1_bits_set);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_set !== p_RequestArb__io_taskInfo_s1_bits_set) t_RequestArb__io_taskInfo_s1_bits_set = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_set = g_RequestArb__io_taskInfo_s1_bits_set;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_tag !== i_RequestArb__io_taskInfo_s1_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_tag g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_tag, i_RequestArb__io_taskInfo_s1_bits_tag);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_tag !== p_RequestArb__io_taskInfo_s1_bits_tag) t_RequestArb__io_taskInfo_s1_bits_tag = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_tag = g_RequestArb__io_taskInfo_s1_bits_tag;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_off !== i_RequestArb__io_taskInfo_s1_bits_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_off g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_off, i_RequestArb__io_taskInfo_s1_bits_off);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_off !== p_RequestArb__io_taskInfo_s1_bits_off) t_RequestArb__io_taskInfo_s1_bits_off = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_off = g_RequestArb__io_taskInfo_s1_bits_off;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_alias !== i_RequestArb__io_taskInfo_s1_bits_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_alias g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_alias, i_RequestArb__io_taskInfo_s1_bits_alias);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_alias !== p_RequestArb__io_taskInfo_s1_bits_alias) t_RequestArb__io_taskInfo_s1_bits_alias = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_alias = g_RequestArb__io_taskInfo_s1_bits_alias;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_vaddr !== i_RequestArb__io_taskInfo_s1_bits_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_vaddr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_vaddr, i_RequestArb__io_taskInfo_s1_bits_vaddr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_vaddr !== p_RequestArb__io_taskInfo_s1_bits_vaddr) t_RequestArb__io_taskInfo_s1_bits_vaddr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_vaddr = g_RequestArb__io_taskInfo_s1_bits_vaddr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_isKeyword !== i_RequestArb__io_taskInfo_s1_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_isKeyword g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_isKeyword, i_RequestArb__io_taskInfo_s1_bits_isKeyword);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_isKeyword !== p_RequestArb__io_taskInfo_s1_bits_isKeyword) t_RequestArb__io_taskInfo_s1_bits_isKeyword = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_isKeyword = g_RequestArb__io_taskInfo_s1_bits_isKeyword;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_opcode !== i_RequestArb__io_taskInfo_s1_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_opcode g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_opcode, i_RequestArb__io_taskInfo_s1_bits_opcode);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_opcode !== p_RequestArb__io_taskInfo_s1_bits_opcode) t_RequestArb__io_taskInfo_s1_bits_opcode = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_opcode = g_RequestArb__io_taskInfo_s1_bits_opcode;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_param !== i_RequestArb__io_taskInfo_s1_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_param g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_param, i_RequestArb__io_taskInfo_s1_bits_param);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_param !== p_RequestArb__io_taskInfo_s1_bits_param) t_RequestArb__io_taskInfo_s1_bits_param = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_param = g_RequestArb__io_taskInfo_s1_bits_param;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_size !== i_RequestArb__io_taskInfo_s1_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_size g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_size, i_RequestArb__io_taskInfo_s1_bits_size);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_size !== p_RequestArb__io_taskInfo_s1_bits_size) t_RequestArb__io_taskInfo_s1_bits_size = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_size = g_RequestArb__io_taskInfo_s1_bits_size;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_sourceId !== i_RequestArb__io_taskInfo_s1_bits_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_sourceId g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_sourceId, i_RequestArb__io_taskInfo_s1_bits_sourceId);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_sourceId !== p_RequestArb__io_taskInfo_s1_bits_sourceId) t_RequestArb__io_taskInfo_s1_bits_sourceId = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_sourceId = g_RequestArb__io_taskInfo_s1_bits_sourceId;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_bufIdx !== i_RequestArb__io_taskInfo_s1_bits_bufIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_bufIdx g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_bufIdx, i_RequestArb__io_taskInfo_s1_bits_bufIdx);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_bufIdx !== p_RequestArb__io_taskInfo_s1_bits_bufIdx) t_RequestArb__io_taskInfo_s1_bits_bufIdx = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_bufIdx = g_RequestArb__io_taskInfo_s1_bits_bufIdx;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_needProbeAckData !== i_RequestArb__io_taskInfo_s1_bits_needProbeAckData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_needProbeAckData g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_needProbeAckData, i_RequestArb__io_taskInfo_s1_bits_needProbeAckData);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_needProbeAckData !== p_RequestArb__io_taskInfo_s1_bits_needProbeAckData) t_RequestArb__io_taskInfo_s1_bits_needProbeAckData = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_needProbeAckData = g_RequestArb__io_taskInfo_s1_bits_needProbeAckData;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_denied !== i_RequestArb__io_taskInfo_s1_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_denied g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_denied, i_RequestArb__io_taskInfo_s1_bits_denied);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_denied !== p_RequestArb__io_taskInfo_s1_bits_denied) t_RequestArb__io_taskInfo_s1_bits_denied = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_denied = g_RequestArb__io_taskInfo_s1_bits_denied;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_corrupt !== i_RequestArb__io_taskInfo_s1_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_corrupt g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_corrupt, i_RequestArb__io_taskInfo_s1_bits_corrupt);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_corrupt !== p_RequestArb__io_taskInfo_s1_bits_corrupt) t_RequestArb__io_taskInfo_s1_bits_corrupt = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_corrupt = g_RequestArb__io_taskInfo_s1_bits_corrupt;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_mshrTask !== i_RequestArb__io_taskInfo_s1_bits_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_mshrTask g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_mshrTask, i_RequestArb__io_taskInfo_s1_bits_mshrTask);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_mshrTask !== p_RequestArb__io_taskInfo_s1_bits_mshrTask) t_RequestArb__io_taskInfo_s1_bits_mshrTask = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_mshrTask = g_RequestArb__io_taskInfo_s1_bits_mshrTask;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_mshrId !== i_RequestArb__io_taskInfo_s1_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_mshrId g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_mshrId, i_RequestArb__io_taskInfo_s1_bits_mshrId);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_mshrId !== p_RequestArb__io_taskInfo_s1_bits_mshrId) t_RequestArb__io_taskInfo_s1_bits_mshrId = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_mshrId = g_RequestArb__io_taskInfo_s1_bits_mshrId;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aliasTask !== i_RequestArb__io_taskInfo_s1_bits_aliasTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aliasTask g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aliasTask, i_RequestArb__io_taskInfo_s1_bits_aliasTask);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aliasTask !== p_RequestArb__io_taskInfo_s1_bits_aliasTask) t_RequestArb__io_taskInfo_s1_bits_aliasTask = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aliasTask = g_RequestArb__io_taskInfo_s1_bits_aliasTask;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_useProbeData !== i_RequestArb__io_taskInfo_s1_bits_useProbeData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_useProbeData g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_useProbeData, i_RequestArb__io_taskInfo_s1_bits_useProbeData);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_useProbeData !== p_RequestArb__io_taskInfo_s1_bits_useProbeData) t_RequestArb__io_taskInfo_s1_bits_useProbeData = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_useProbeData = g_RequestArb__io_taskInfo_s1_bits_useProbeData;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_mshrRetry !== i_RequestArb__io_taskInfo_s1_bits_mshrRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_mshrRetry g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_mshrRetry, i_RequestArb__io_taskInfo_s1_bits_mshrRetry);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_mshrRetry !== p_RequestArb__io_taskInfo_s1_bits_mshrRetry) t_RequestArb__io_taskInfo_s1_bits_mshrRetry = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_mshrRetry = g_RequestArb__io_taskInfo_s1_bits_mshrRetry;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_readProbeDataDown !== i_RequestArb__io_taskInfo_s1_bits_readProbeDataDown) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_readProbeDataDown g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_readProbeDataDown, i_RequestArb__io_taskInfo_s1_bits_readProbeDataDown);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_readProbeDataDown !== p_RequestArb__io_taskInfo_s1_bits_readProbeDataDown) t_RequestArb__io_taskInfo_s1_bits_readProbeDataDown = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_readProbeDataDown = g_RequestArb__io_taskInfo_s1_bits_readProbeDataDown;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_fromL2pft !== i_RequestArb__io_taskInfo_s1_bits_fromL2pft) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_fromL2pft g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_fromL2pft, i_RequestArb__io_taskInfo_s1_bits_fromL2pft);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_fromL2pft !== p_RequestArb__io_taskInfo_s1_bits_fromL2pft) t_RequestArb__io_taskInfo_s1_bits_fromL2pft = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_fromL2pft = g_RequestArb__io_taskInfo_s1_bits_fromL2pft;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_needHint !== i_RequestArb__io_taskInfo_s1_bits_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_needHint g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_needHint, i_RequestArb__io_taskInfo_s1_bits_needHint);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_needHint !== p_RequestArb__io_taskInfo_s1_bits_needHint) t_RequestArb__io_taskInfo_s1_bits_needHint = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_needHint = g_RequestArb__io_taskInfo_s1_bits_needHint;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_dirty !== i_RequestArb__io_taskInfo_s1_bits_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_dirty g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_dirty, i_RequestArb__io_taskInfo_s1_bits_dirty);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_dirty !== p_RequestArb__io_taskInfo_s1_bits_dirty) t_RequestArb__io_taskInfo_s1_bits_dirty = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_dirty = g_RequestArb__io_taskInfo_s1_bits_dirty;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_way !== i_RequestArb__io_taskInfo_s1_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_way g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_way, i_RequestArb__io_taskInfo_s1_bits_way);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_way !== p_RequestArb__io_taskInfo_s1_bits_way) t_RequestArb__io_taskInfo_s1_bits_way = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_way = g_RequestArb__io_taskInfo_s1_bits_way;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_dirty !== i_RequestArb__io_taskInfo_s1_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_dirty g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_dirty, i_RequestArb__io_taskInfo_s1_bits_meta_dirty);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_dirty !== p_RequestArb__io_taskInfo_s1_bits_meta_dirty) t_RequestArb__io_taskInfo_s1_bits_meta_dirty = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_dirty = g_RequestArb__io_taskInfo_s1_bits_meta_dirty;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_state !== i_RequestArb__io_taskInfo_s1_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_state g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_state, i_RequestArb__io_taskInfo_s1_bits_meta_state);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_state !== p_RequestArb__io_taskInfo_s1_bits_meta_state) t_RequestArb__io_taskInfo_s1_bits_meta_state = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_state = g_RequestArb__io_taskInfo_s1_bits_meta_state;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_clients !== i_RequestArb__io_taskInfo_s1_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_clients g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_clients, i_RequestArb__io_taskInfo_s1_bits_meta_clients);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_clients !== p_RequestArb__io_taskInfo_s1_bits_meta_clients) t_RequestArb__io_taskInfo_s1_bits_meta_clients = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_clients = g_RequestArb__io_taskInfo_s1_bits_meta_clients;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_alias !== i_RequestArb__io_taskInfo_s1_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_alias g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_alias, i_RequestArb__io_taskInfo_s1_bits_meta_alias);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_alias !== p_RequestArb__io_taskInfo_s1_bits_meta_alias) t_RequestArb__io_taskInfo_s1_bits_meta_alias = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_alias = g_RequestArb__io_taskInfo_s1_bits_meta_alias;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_prefetch !== i_RequestArb__io_taskInfo_s1_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_prefetch g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_prefetch, i_RequestArb__io_taskInfo_s1_bits_meta_prefetch);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_prefetch !== p_RequestArb__io_taskInfo_s1_bits_meta_prefetch) t_RequestArb__io_taskInfo_s1_bits_meta_prefetch = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_prefetch = g_RequestArb__io_taskInfo_s1_bits_meta_prefetch;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc !== i_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_prefetchSrc g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc, i_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc !== p_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc) t_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc = g_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_accessed !== i_RequestArb__io_taskInfo_s1_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_accessed g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_accessed, i_RequestArb__io_taskInfo_s1_bits_meta_accessed);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_accessed !== p_RequestArb__io_taskInfo_s1_bits_meta_accessed) t_RequestArb__io_taskInfo_s1_bits_meta_accessed = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_accessed = g_RequestArb__io_taskInfo_s1_bits_meta_accessed;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_tagErr !== i_RequestArb__io_taskInfo_s1_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_tagErr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_tagErr, i_RequestArb__io_taskInfo_s1_bits_meta_tagErr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_tagErr !== p_RequestArb__io_taskInfo_s1_bits_meta_tagErr) t_RequestArb__io_taskInfo_s1_bits_meta_tagErr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_tagErr = g_RequestArb__io_taskInfo_s1_bits_meta_tagErr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_meta_dataErr !== i_RequestArb__io_taskInfo_s1_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_meta_dataErr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_meta_dataErr, i_RequestArb__io_taskInfo_s1_bits_meta_dataErr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_meta_dataErr !== p_RequestArb__io_taskInfo_s1_bits_meta_dataErr) t_RequestArb__io_taskInfo_s1_bits_meta_dataErr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_meta_dataErr = g_RequestArb__io_taskInfo_s1_bits_meta_dataErr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_metaWen !== i_RequestArb__io_taskInfo_s1_bits_metaWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_metaWen g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_metaWen, i_RequestArb__io_taskInfo_s1_bits_metaWen);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_metaWen !== p_RequestArb__io_taskInfo_s1_bits_metaWen) t_RequestArb__io_taskInfo_s1_bits_metaWen = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_metaWen = g_RequestArb__io_taskInfo_s1_bits_metaWen;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_tagWen !== i_RequestArb__io_taskInfo_s1_bits_tagWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_tagWen g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_tagWen, i_RequestArb__io_taskInfo_s1_bits_tagWen);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_tagWen !== p_RequestArb__io_taskInfo_s1_bits_tagWen) t_RequestArb__io_taskInfo_s1_bits_tagWen = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_tagWen = g_RequestArb__io_taskInfo_s1_bits_tagWen;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_dsWen !== i_RequestArb__io_taskInfo_s1_bits_dsWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_dsWen g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_dsWen, i_RequestArb__io_taskInfo_s1_bits_dsWen);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_dsWen !== p_RequestArb__io_taskInfo_s1_bits_dsWen) t_RequestArb__io_taskInfo_s1_bits_dsWen = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_dsWen = g_RequestArb__io_taskInfo_s1_bits_dsWen;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_wayMask !== i_RequestArb__io_taskInfo_s1_bits_wayMask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_wayMask g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_wayMask, i_RequestArb__io_taskInfo_s1_bits_wayMask);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_wayMask !== p_RequestArb__io_taskInfo_s1_bits_wayMask) t_RequestArb__io_taskInfo_s1_bits_wayMask = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_wayMask = g_RequestArb__io_taskInfo_s1_bits_wayMask;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_replTask !== i_RequestArb__io_taskInfo_s1_bits_replTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_replTask g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_replTask, i_RequestArb__io_taskInfo_s1_bits_replTask);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_replTask !== p_RequestArb__io_taskInfo_s1_bits_replTask) t_RequestArb__io_taskInfo_s1_bits_replTask = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_replTask = g_RequestArb__io_taskInfo_s1_bits_replTask;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_cmoTask !== i_RequestArb__io_taskInfo_s1_bits_cmoTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_cmoTask g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_cmoTask, i_RequestArb__io_taskInfo_s1_bits_cmoTask);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_cmoTask !== p_RequestArb__io_taskInfo_s1_bits_cmoTask) t_RequestArb__io_taskInfo_s1_bits_cmoTask = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_cmoTask = g_RequestArb__io_taskInfo_s1_bits_cmoTask;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_cmoAll !== i_RequestArb__io_taskInfo_s1_bits_cmoAll) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_cmoAll g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_cmoAll, i_RequestArb__io_taskInfo_s1_bits_cmoAll);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_cmoAll !== p_RequestArb__io_taskInfo_s1_bits_cmoAll) t_RequestArb__io_taskInfo_s1_bits_cmoAll = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_cmoAll = g_RequestArb__io_taskInfo_s1_bits_cmoAll;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_reqSource !== i_RequestArb__io_taskInfo_s1_bits_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_reqSource g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_reqSource, i_RequestArb__io_taskInfo_s1_bits_reqSource);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_reqSource !== p_RequestArb__io_taskInfo_s1_bits_reqSource) t_RequestArb__io_taskInfo_s1_bits_reqSource = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_reqSource = g_RequestArb__io_taskInfo_s1_bits_reqSource;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_mergeA !== i_RequestArb__io_taskInfo_s1_bits_mergeA) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_mergeA g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_mergeA, i_RequestArb__io_taskInfo_s1_bits_mergeA);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_mergeA !== p_RequestArb__io_taskInfo_s1_bits_mergeA) t_RequestArb__io_taskInfo_s1_bits_mergeA = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_mergeA = g_RequestArb__io_taskInfo_s1_bits_mergeA;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_off !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_off g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_off, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_off);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_off !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_off) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_off = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_off = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_off;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_alias g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_vaddr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_isKeyword g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_opcode g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_param !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_param g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_param, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_param);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_param !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_param) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_param = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_param = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_param;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_sourceId g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_dirty g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_state g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_clients g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_alias g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_prefetch g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_accessed g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_tagErr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr !== i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_dataErr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr, i_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr !== p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr) t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr = g_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitRelease !== i_RequestArb__io_taskInfo_s1_bits_snpHitRelease) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitRelease g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitRelease, i_RequestArb__io_taskInfo_s1_bits_snpHitRelease);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitRelease !== p_RequestArb__io_taskInfo_s1_bits_snpHitRelease) t_RequestArb__io_taskInfo_s1_bits_snpHitRelease = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitRelease = g_RequestArb__io_taskInfo_s1_bits_snpHitRelease;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseToInval g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseToClean g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseWithData g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseIdx g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_dirty g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_state g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_clients g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_alias g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_accessed g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr !== i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr, i_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr !== p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr) t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr = g_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_tgtID !== i_RequestArb__io_taskInfo_s1_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_tgtID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_tgtID, i_RequestArb__io_taskInfo_s1_bits_tgtID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_tgtID !== p_RequestArb__io_taskInfo_s1_bits_tgtID) t_RequestArb__io_taskInfo_s1_bits_tgtID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_tgtID = g_RequestArb__io_taskInfo_s1_bits_tgtID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_srcID !== i_RequestArb__io_taskInfo_s1_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_srcID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_srcID, i_RequestArb__io_taskInfo_s1_bits_srcID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_srcID !== p_RequestArb__io_taskInfo_s1_bits_srcID) t_RequestArb__io_taskInfo_s1_bits_srcID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_srcID = g_RequestArb__io_taskInfo_s1_bits_srcID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_txnID !== i_RequestArb__io_taskInfo_s1_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_txnID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_txnID, i_RequestArb__io_taskInfo_s1_bits_txnID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_txnID !== p_RequestArb__io_taskInfo_s1_bits_txnID) t_RequestArb__io_taskInfo_s1_bits_txnID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_txnID = g_RequestArb__io_taskInfo_s1_bits_txnID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_homeNID !== i_RequestArb__io_taskInfo_s1_bits_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_homeNID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_homeNID, i_RequestArb__io_taskInfo_s1_bits_homeNID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_homeNID !== p_RequestArb__io_taskInfo_s1_bits_homeNID) t_RequestArb__io_taskInfo_s1_bits_homeNID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_homeNID = g_RequestArb__io_taskInfo_s1_bits_homeNID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_dbID !== i_RequestArb__io_taskInfo_s1_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_dbID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_dbID, i_RequestArb__io_taskInfo_s1_bits_dbID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_dbID !== p_RequestArb__io_taskInfo_s1_bits_dbID) t_RequestArb__io_taskInfo_s1_bits_dbID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_dbID = g_RequestArb__io_taskInfo_s1_bits_dbID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_fwdNID !== i_RequestArb__io_taskInfo_s1_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_fwdNID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_fwdNID, i_RequestArb__io_taskInfo_s1_bits_fwdNID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_fwdNID !== p_RequestArb__io_taskInfo_s1_bits_fwdNID) t_RequestArb__io_taskInfo_s1_bits_fwdNID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_fwdNID = g_RequestArb__io_taskInfo_s1_bits_fwdNID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_fwdTxnID !== i_RequestArb__io_taskInfo_s1_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_fwdTxnID g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_fwdTxnID, i_RequestArb__io_taskInfo_s1_bits_fwdTxnID);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_fwdTxnID !== p_RequestArb__io_taskInfo_s1_bits_fwdTxnID) t_RequestArb__io_taskInfo_s1_bits_fwdTxnID = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_fwdTxnID = g_RequestArb__io_taskInfo_s1_bits_fwdTxnID;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_chiOpcode !== i_RequestArb__io_taskInfo_s1_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_chiOpcode g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_chiOpcode, i_RequestArb__io_taskInfo_s1_bits_chiOpcode);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_chiOpcode !== p_RequestArb__io_taskInfo_s1_bits_chiOpcode) t_RequestArb__io_taskInfo_s1_bits_chiOpcode = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_chiOpcode = g_RequestArb__io_taskInfo_s1_bits_chiOpcode;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_resp !== i_RequestArb__io_taskInfo_s1_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_resp g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_resp, i_RequestArb__io_taskInfo_s1_bits_resp);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_resp !== p_RequestArb__io_taskInfo_s1_bits_resp) t_RequestArb__io_taskInfo_s1_bits_resp = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_resp = g_RequestArb__io_taskInfo_s1_bits_resp;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_fwdState !== i_RequestArb__io_taskInfo_s1_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_fwdState g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_fwdState, i_RequestArb__io_taskInfo_s1_bits_fwdState);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_fwdState !== p_RequestArb__io_taskInfo_s1_bits_fwdState) t_RequestArb__io_taskInfo_s1_bits_fwdState = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_fwdState = g_RequestArb__io_taskInfo_s1_bits_fwdState;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_pCrdType !== i_RequestArb__io_taskInfo_s1_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_pCrdType g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_pCrdType, i_RequestArb__io_taskInfo_s1_bits_pCrdType);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_pCrdType !== p_RequestArb__io_taskInfo_s1_bits_pCrdType) t_RequestArb__io_taskInfo_s1_bits_pCrdType = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_pCrdType = g_RequestArb__io_taskInfo_s1_bits_pCrdType;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_retToSrc !== i_RequestArb__io_taskInfo_s1_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_retToSrc g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_retToSrc, i_RequestArb__io_taskInfo_s1_bits_retToSrc);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_retToSrc !== p_RequestArb__io_taskInfo_s1_bits_retToSrc) t_RequestArb__io_taskInfo_s1_bits_retToSrc = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_retToSrc = g_RequestArb__io_taskInfo_s1_bits_retToSrc;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_likelyshared !== i_RequestArb__io_taskInfo_s1_bits_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_likelyshared g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_likelyshared, i_RequestArb__io_taskInfo_s1_bits_likelyshared);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_likelyshared !== p_RequestArb__io_taskInfo_s1_bits_likelyshared) t_RequestArb__io_taskInfo_s1_bits_likelyshared = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_likelyshared = g_RequestArb__io_taskInfo_s1_bits_likelyshared;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_expCompAck !== i_RequestArb__io_taskInfo_s1_bits_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_expCompAck g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_expCompAck, i_RequestArb__io_taskInfo_s1_bits_expCompAck);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_expCompAck !== p_RequestArb__io_taskInfo_s1_bits_expCompAck) t_RequestArb__io_taskInfo_s1_bits_expCompAck = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_expCompAck = g_RequestArb__io_taskInfo_s1_bits_expCompAck;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_allowRetry !== i_RequestArb__io_taskInfo_s1_bits_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_allowRetry g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_allowRetry, i_RequestArb__io_taskInfo_s1_bits_allowRetry);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_allowRetry !== p_RequestArb__io_taskInfo_s1_bits_allowRetry) t_RequestArb__io_taskInfo_s1_bits_allowRetry = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_allowRetry = g_RequestArb__io_taskInfo_s1_bits_allowRetry;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_allocate !== i_RequestArb__io_taskInfo_s1_bits_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_memAttr_allocate g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_memAttr_allocate, i_RequestArb__io_taskInfo_s1_bits_memAttr_allocate);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_allocate !== p_RequestArb__io_taskInfo_s1_bits_memAttr_allocate) t_RequestArb__io_taskInfo_s1_bits_memAttr_allocate = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_memAttr_allocate = g_RequestArb__io_taskInfo_s1_bits_memAttr_allocate;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable !== i_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_memAttr_cacheable g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable, i_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable !== p_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable) t_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable = g_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_device !== i_RequestArb__io_taskInfo_s1_bits_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_memAttr_device g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_memAttr_device, i_RequestArb__io_taskInfo_s1_bits_memAttr_device);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_device !== p_RequestArb__io_taskInfo_s1_bits_memAttr_device) t_RequestArb__io_taskInfo_s1_bits_memAttr_device = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_memAttr_device = g_RequestArb__io_taskInfo_s1_bits_memAttr_device;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_ewa !== i_RequestArb__io_taskInfo_s1_bits_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_memAttr_ewa g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_memAttr_ewa, i_RequestArb__io_taskInfo_s1_bits_memAttr_ewa);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_memAttr_ewa !== p_RequestArb__io_taskInfo_s1_bits_memAttr_ewa) t_RequestArb__io_taskInfo_s1_bits_memAttr_ewa = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_memAttr_ewa = g_RequestArb__io_taskInfo_s1_bits_memAttr_ewa;
    checks++;
    if (g_RequestArb__io_taskInfo_s1_bits_traceTag !== i_RequestArb__io_taskInfo_s1_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_taskInfo_s1_bits_traceTag g=%h i=%h", cyc, g_RequestArb__io_taskInfo_s1_bits_traceTag, i_RequestArb__io_taskInfo_s1_bits_traceTag);
    end
    if (g_RequestArb__io_taskInfo_s1_bits_traceTag !== p_RequestArb__io_taskInfo_s1_bits_traceTag) t_RequestArb__io_taskInfo_s1_bits_traceTag = 1'b1;
    p_RequestArb__io_taskInfo_s1_bits_traceTag = g_RequestArb__io_taskInfo_s1_bits_traceTag;
    checks++;
    if (g_RequestArb__io_refillBufRead_s2_valid !== i_RequestArb__io_refillBufRead_s2_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_refillBufRead_s2_valid g=%h i=%h", cyc, g_RequestArb__io_refillBufRead_s2_valid, i_RequestArb__io_refillBufRead_s2_valid);
    end
    if (g_RequestArb__io_refillBufRead_s2_valid !== p_RequestArb__io_refillBufRead_s2_valid) t_RequestArb__io_refillBufRead_s2_valid = 1'b1;
    p_RequestArb__io_refillBufRead_s2_valid = g_RequestArb__io_refillBufRead_s2_valid;
    checks++;
    if (g_RequestArb__io_refillBufRead_s2_bits_id !== i_RequestArb__io_refillBufRead_s2_bits_id) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_refillBufRead_s2_bits_id g=%h i=%h", cyc, g_RequestArb__io_refillBufRead_s2_bits_id, i_RequestArb__io_refillBufRead_s2_bits_id);
    end
    if (g_RequestArb__io_refillBufRead_s2_bits_id !== p_RequestArb__io_refillBufRead_s2_bits_id) t_RequestArb__io_refillBufRead_s2_bits_id = 1'b1;
    p_RequestArb__io_refillBufRead_s2_bits_id = g_RequestArb__io_refillBufRead_s2_bits_id;
    checks++;
    if (g_RequestArb__io_releaseBufRead_s2_valid !== i_RequestArb__io_releaseBufRead_s2_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_releaseBufRead_s2_valid g=%h i=%h", cyc, g_RequestArb__io_releaseBufRead_s2_valid, i_RequestArb__io_releaseBufRead_s2_valid);
    end
    if (g_RequestArb__io_releaseBufRead_s2_valid !== p_RequestArb__io_releaseBufRead_s2_valid) t_RequestArb__io_releaseBufRead_s2_valid = 1'b1;
    p_RequestArb__io_releaseBufRead_s2_valid = g_RequestArb__io_releaseBufRead_s2_valid;
    checks++;
    if (g_RequestArb__io_releaseBufRead_s2_bits_id !== i_RequestArb__io_releaseBufRead_s2_bits_id) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_releaseBufRead_s2_bits_id g=%h i=%h", cyc, g_RequestArb__io_releaseBufRead_s2_bits_id, i_RequestArb__io_releaseBufRead_s2_bits_id);
    end
    if (g_RequestArb__io_releaseBufRead_s2_bits_id !== p_RequestArb__io_releaseBufRead_s2_bits_id) t_RequestArb__io_releaseBufRead_s2_bits_id = 1'b1;
    p_RequestArb__io_releaseBufRead_s2_bits_id = g_RequestArb__io_releaseBufRead_s2_bits_id;
    checks++;
    if (g_RequestArb__io_status_s1_tags_0 !== i_RequestArb__io_status_s1_tags_0) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_tags_0 g=%h i=%h", cyc, g_RequestArb__io_status_s1_tags_0, i_RequestArb__io_status_s1_tags_0);
    end
    if (g_RequestArb__io_status_s1_tags_0 !== p_RequestArb__io_status_s1_tags_0) t_RequestArb__io_status_s1_tags_0 = 1'b1;
    p_RequestArb__io_status_s1_tags_0 = g_RequestArb__io_status_s1_tags_0;
    checks++;
    if (g_RequestArb__io_status_s1_tags_1 !== i_RequestArb__io_status_s1_tags_1) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_tags_1 g=%h i=%h", cyc, g_RequestArb__io_status_s1_tags_1, i_RequestArb__io_status_s1_tags_1);
    end
    if (g_RequestArb__io_status_s1_tags_1 !== p_RequestArb__io_status_s1_tags_1) t_RequestArb__io_status_s1_tags_1 = 1'b1;
    p_RequestArb__io_status_s1_tags_1 = g_RequestArb__io_status_s1_tags_1;
    checks++;
    if (g_RequestArb__io_status_s1_tags_2 !== i_RequestArb__io_status_s1_tags_2) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_tags_2 g=%h i=%h", cyc, g_RequestArb__io_status_s1_tags_2, i_RequestArb__io_status_s1_tags_2);
    end
    if (g_RequestArb__io_status_s1_tags_2 !== p_RequestArb__io_status_s1_tags_2) t_RequestArb__io_status_s1_tags_2 = 1'b1;
    p_RequestArb__io_status_s1_tags_2 = g_RequestArb__io_status_s1_tags_2;
    checks++;
    if (g_RequestArb__io_status_s1_tags_3 !== i_RequestArb__io_status_s1_tags_3) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_tags_3 g=%h i=%h", cyc, g_RequestArb__io_status_s1_tags_3, i_RequestArb__io_status_s1_tags_3);
    end
    if (g_RequestArb__io_status_s1_tags_3 !== p_RequestArb__io_status_s1_tags_3) t_RequestArb__io_status_s1_tags_3 = 1'b1;
    p_RequestArb__io_status_s1_tags_3 = g_RequestArb__io_status_s1_tags_3;
    checks++;
    if (g_RequestArb__io_status_s1_sets_0 !== i_RequestArb__io_status_s1_sets_0) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_sets_0 g=%h i=%h", cyc, g_RequestArb__io_status_s1_sets_0, i_RequestArb__io_status_s1_sets_0);
    end
    if (g_RequestArb__io_status_s1_sets_0 !== p_RequestArb__io_status_s1_sets_0) t_RequestArb__io_status_s1_sets_0 = 1'b1;
    p_RequestArb__io_status_s1_sets_0 = g_RequestArb__io_status_s1_sets_0;
    checks++;
    if (g_RequestArb__io_status_s1_sets_1 !== i_RequestArb__io_status_s1_sets_1) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_sets_1 g=%h i=%h", cyc, g_RequestArb__io_status_s1_sets_1, i_RequestArb__io_status_s1_sets_1);
    end
    if (g_RequestArb__io_status_s1_sets_1 !== p_RequestArb__io_status_s1_sets_1) t_RequestArb__io_status_s1_sets_1 = 1'b1;
    p_RequestArb__io_status_s1_sets_1 = g_RequestArb__io_status_s1_sets_1;
    checks++;
    if (g_RequestArb__io_status_s1_sets_2 !== i_RequestArb__io_status_s1_sets_2) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_sets_2 g=%h i=%h", cyc, g_RequestArb__io_status_s1_sets_2, i_RequestArb__io_status_s1_sets_2);
    end
    if (g_RequestArb__io_status_s1_sets_2 !== p_RequestArb__io_status_s1_sets_2) t_RequestArb__io_status_s1_sets_2 = 1'b1;
    p_RequestArb__io_status_s1_sets_2 = g_RequestArb__io_status_s1_sets_2;
    checks++;
    if (g_RequestArb__io_status_s1_sets_3 !== i_RequestArb__io_status_s1_sets_3) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_s1_sets_3 g=%h i=%h", cyc, g_RequestArb__io_status_s1_sets_3, i_RequestArb__io_status_s1_sets_3);
    end
    if (g_RequestArb__io_status_s1_sets_3 !== p_RequestArb__io_status_s1_sets_3) t_RequestArb__io_status_s1_sets_3 = 1'b1;
    p_RequestArb__io_status_s1_sets_3 = g_RequestArb__io_status_s1_sets_3;
    checks++;
    if (g_RequestArb__io_status_vec_0_valid !== i_RequestArb__io_status_vec_0_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_0_valid g=%h i=%h", cyc, g_RequestArb__io_status_vec_0_valid, i_RequestArb__io_status_vec_0_valid);
    end
    if (g_RequestArb__io_status_vec_0_valid !== p_RequestArb__io_status_vec_0_valid) t_RequestArb__io_status_vec_0_valid = 1'b1;
    p_RequestArb__io_status_vec_0_valid = g_RequestArb__io_status_vec_0_valid;
    checks++;
    if (g_RequestArb__io_status_vec_0_bits_channel !== i_RequestArb__io_status_vec_0_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_0_bits_channel g=%h i=%h", cyc, g_RequestArb__io_status_vec_0_bits_channel, i_RequestArb__io_status_vec_0_bits_channel);
    end
    if (g_RequestArb__io_status_vec_0_bits_channel !== p_RequestArb__io_status_vec_0_bits_channel) t_RequestArb__io_status_vec_0_bits_channel = 1'b1;
    p_RequestArb__io_status_vec_0_bits_channel = g_RequestArb__io_status_vec_0_bits_channel;
    checks++;
    if (g_RequestArb__io_status_vec_1_valid !== i_RequestArb__io_status_vec_1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_1_valid g=%h i=%h", cyc, g_RequestArb__io_status_vec_1_valid, i_RequestArb__io_status_vec_1_valid);
    end
    if (g_RequestArb__io_status_vec_1_valid !== p_RequestArb__io_status_vec_1_valid) t_RequestArb__io_status_vec_1_valid = 1'b1;
    p_RequestArb__io_status_vec_1_valid = g_RequestArb__io_status_vec_1_valid;
    checks++;
    if (g_RequestArb__io_status_vec_1_bits_channel !== i_RequestArb__io_status_vec_1_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_1_bits_channel g=%h i=%h", cyc, g_RequestArb__io_status_vec_1_bits_channel, i_RequestArb__io_status_vec_1_bits_channel);
    end
    if (g_RequestArb__io_status_vec_1_bits_channel !== p_RequestArb__io_status_vec_1_bits_channel) t_RequestArb__io_status_vec_1_bits_channel = 1'b1;
    p_RequestArb__io_status_vec_1_bits_channel = g_RequestArb__io_status_vec_1_bits_channel;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_0_valid !== i_RequestArb__io_status_vec_toTX_0_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_0_valid g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_0_valid, i_RequestArb__io_status_vec_toTX_0_valid);
    end
    if (g_RequestArb__io_status_vec_toTX_0_valid !== p_RequestArb__io_status_vec_toTX_0_valid) t_RequestArb__io_status_vec_toTX_0_valid = 1'b1;
    p_RequestArb__io_status_vec_toTX_0_valid = g_RequestArb__io_status_vec_toTX_0_valid;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_0_bits_channel !== i_RequestArb__io_status_vec_toTX_0_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_0_bits_channel g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_0_bits_channel, i_RequestArb__io_status_vec_toTX_0_bits_channel);
    end
    if (g_RequestArb__io_status_vec_toTX_0_bits_channel !== p_RequestArb__io_status_vec_toTX_0_bits_channel) t_RequestArb__io_status_vec_toTX_0_bits_channel = 1'b1;
    p_RequestArb__io_status_vec_toTX_0_bits_channel = g_RequestArb__io_status_vec_toTX_0_bits_channel;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_0_bits_txChannel !== i_RequestArb__io_status_vec_toTX_0_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_0_bits_txChannel g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_0_bits_txChannel, i_RequestArb__io_status_vec_toTX_0_bits_txChannel);
    end
    if (g_RequestArb__io_status_vec_toTX_0_bits_txChannel !== p_RequestArb__io_status_vec_toTX_0_bits_txChannel) t_RequestArb__io_status_vec_toTX_0_bits_txChannel = 1'b1;
    p_RequestArb__io_status_vec_toTX_0_bits_txChannel = g_RequestArb__io_status_vec_toTX_0_bits_txChannel;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_0_bits_mshrTask !== i_RequestArb__io_status_vec_toTX_0_bits_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_0_bits_mshrTask g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_0_bits_mshrTask, i_RequestArb__io_status_vec_toTX_0_bits_mshrTask);
    end
    if (g_RequestArb__io_status_vec_toTX_0_bits_mshrTask !== p_RequestArb__io_status_vec_toTX_0_bits_mshrTask) t_RequestArb__io_status_vec_toTX_0_bits_mshrTask = 1'b1;
    p_RequestArb__io_status_vec_toTX_0_bits_mshrTask = g_RequestArb__io_status_vec_toTX_0_bits_mshrTask;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_1_valid !== i_RequestArb__io_status_vec_toTX_1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_1_valid g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_1_valid, i_RequestArb__io_status_vec_toTX_1_valid);
    end
    if (g_RequestArb__io_status_vec_toTX_1_valid !== p_RequestArb__io_status_vec_toTX_1_valid) t_RequestArb__io_status_vec_toTX_1_valid = 1'b1;
    p_RequestArb__io_status_vec_toTX_1_valid = g_RequestArb__io_status_vec_toTX_1_valid;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_1_bits_channel !== i_RequestArb__io_status_vec_toTX_1_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_1_bits_channel g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_1_bits_channel, i_RequestArb__io_status_vec_toTX_1_bits_channel);
    end
    if (g_RequestArb__io_status_vec_toTX_1_bits_channel !== p_RequestArb__io_status_vec_toTX_1_bits_channel) t_RequestArb__io_status_vec_toTX_1_bits_channel = 1'b1;
    p_RequestArb__io_status_vec_toTX_1_bits_channel = g_RequestArb__io_status_vec_toTX_1_bits_channel;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_1_bits_txChannel !== i_RequestArb__io_status_vec_toTX_1_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_1_bits_txChannel g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_1_bits_txChannel, i_RequestArb__io_status_vec_toTX_1_bits_txChannel);
    end
    if (g_RequestArb__io_status_vec_toTX_1_bits_txChannel !== p_RequestArb__io_status_vec_toTX_1_bits_txChannel) t_RequestArb__io_status_vec_toTX_1_bits_txChannel = 1'b1;
    p_RequestArb__io_status_vec_toTX_1_bits_txChannel = g_RequestArb__io_status_vec_toTX_1_bits_txChannel;
    checks++;
    if (g_RequestArb__io_status_vec_toTX_1_bits_mshrTask !== i_RequestArb__io_status_vec_toTX_1_bits_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestArb.io_status_vec_toTX_1_bits_mshrTask g=%h i=%h", cyc, g_RequestArb__io_status_vec_toTX_1_bits_mshrTask, i_RequestArb__io_status_vec_toTX_1_bits_mshrTask);
    end
    if (g_RequestArb__io_status_vec_toTX_1_bits_mshrTask !== p_RequestArb__io_status_vec_toTX_1_bits_mshrTask) t_RequestArb__io_status_vec_toTX_1_bits_mshrTask = 1'b1;
    p_RequestArb__io_status_vec_toTX_1_bits_mshrTask = g_RequestArb__io_status_vec_toTX_1_bits_mshrTask;
  endtask
  longint cov_RequestArb_s0 = 0;
  longint cov_RequestArb_s1 = 0;
  longint cov_RequestArb_replRead = 0;
  longint cov_RequestArb_selC = 0;
  longint cov_RequestArb_selB = 0;
  longint cov_RequestArb_selA = 0;
  longint cov_RequestArb_refillBuf = 0;
  longint cov_RequestArb_releaseBuf = 0;
  longint cov_RequestArb_initDone = 0;
  task automatic cover_RequestArb();
    if (u_g_RequestArb.s0_fire_probe) cov_RequestArb_s0++;
    if (u_g_RequestArb.s1_fire) cov_RequestArb_s1++;
    if (u_g_RequestArb.s1_needs_replRead) cov_RequestArb_replRead++;
    if (u_g_RequestArb.io_sinkC_ready && u_g_RequestArb.io_sinkC_valid) cov_RequestArb_selC++;
    if (u_g_RequestArb.io_sinkB_ready && u_g_RequestArb.io_sinkB_valid) cov_RequestArb_selB++;
    if (u_g_RequestArb.io_sinkA_ready && u_g_RequestArb.io_sinkA_valid) cov_RequestArb_selA++;
    if (u_g_RequestArb.io_refillBufRead_s2_valid) cov_RequestArb_refillBuf++;
    if (u_g_RequestArb.io_releaseBufRead_s2_valid) cov_RequestArb_releaseBuf++;
    if (u_g_RequestArb.resetFinish) cov_RequestArb_initDone++;
  endtask
  task automatic preinit_RequestArb();
  endtask
  task automatic sync_RequestArb();
    force u_i_RequestArb.u_core.ds_mcp2_stall = u_g_RequestArb.ds_mcp2_stall;
    #0 release u_i_RequestArb.u_core.ds_mcp2_stall;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_RequestArb();
    #1;
    preinit_RequestArb();
    sync_RequestArb();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_RequestArb();
      #1;
      check_RequestArb();
      cover_RequestArb();
    end
    begin int tg; tg = 0;
      if (t_RequestArb__io_sinkA_ready) tg++; else $display("COV: RequestArb.io_sinkA_ready never toggled");
      if (t_RequestArb__io_s1Entrance_valid) tg++; else $display("COV: RequestArb.io_s1Entrance_valid never toggled");
      if (t_RequestArb__io_s1Entrance_bits_set) tg++; else $display("COV: RequestArb.io_s1Entrance_bits_set never toggled");
      if (t_RequestArb__io_sinkB_ready) tg++; else $display("COV: RequestArb.io_sinkB_ready never toggled");
      if (t_RequestArb__io_sinkC_ready) tg++; else $display("COV: RequestArb.io_sinkC_ready never toggled");
      if (t_RequestArb__io_mshrTask_ready) tg++; else $display("COV: RequestArb.io_mshrTask_ready never toggled");
      if (t_RequestArb__io_dirRead_s1_valid) tg++; else $display("COV: RequestArb.io_dirRead_s1_valid never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_tag) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_tag never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_set) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_set never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_wayMask) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_wayMask never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_replacerInfo_channel) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_replacerInfo_channel never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_replacerInfo_opcode) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_replacerInfo_opcode never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_replacerInfo_reqSource) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_replacerInfo_reqSource never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_replacerInfo_refill_prefetch) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_replacerInfo_refill_prefetch never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_refill) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_refill never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_mshrId) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_mshrId never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_cmoAll) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_cmoAll never toggled");
      if (t_RequestArb__io_dirRead_s1_bits_cmoWay) tg++; else $display("COV: RequestArb.io_dirRead_s1_bits_cmoWay never toggled");
      if (t_RequestArb__io_taskToPipe_s2_valid) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_valid never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_channel) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_channel never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_txChannel) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_txChannel never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_set) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_set never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_tag) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_tag never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_off) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_off never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_alias) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_alias never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_vaddr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_vaddr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_isKeyword) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_isKeyword never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_opcode) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_opcode never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_param) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_param never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_size) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_size never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_sourceId) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_sourceId never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_bufIdx) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_bufIdx never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_needProbeAckData) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_needProbeAckData never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_denied) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_denied never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_corrupt) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_corrupt never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_mshrTask) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_mshrTask never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_mshrId) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_mshrId never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aliasTask) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aliasTask never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_useProbeData) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_useProbeData never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_mshrRetry) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_mshrRetry never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_readProbeDataDown) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_readProbeDataDown never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_fromL2pft) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_fromL2pft never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_needHint) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_needHint never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_dirty) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_dirty never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_way) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_way never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_dirty) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_dirty never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_state) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_state never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_clients) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_clients never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_alias) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_alias never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_prefetch) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_prefetch never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_prefetchSrc) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_prefetchSrc never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_accessed) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_accessed never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_tagErr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_tagErr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_meta_dataErr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_meta_dataErr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_metaWen) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_metaWen never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_tagWen) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_tagWen never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_dsWen) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_dsWen never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_wayMask) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_wayMask never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_replTask) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_replTask never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_cmoTask) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_cmoTask never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_cmoAll) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_cmoAll never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_reqSource) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_reqSource never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_mergeA) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_mergeA never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_off) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_off never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_alias) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_alias never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_vaddr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_vaddr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_isKeyword) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_isKeyword never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_opcode) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_opcode never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_param) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_param never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_sourceId) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_sourceId never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dirty) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_dirty never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_state) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_state never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_clients) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_clients never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_alias) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_alias never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetch) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_prefetch never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_accessed) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_accessed never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_tagErr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_tagErr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_aMergeTask_meta_dataErr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_aMergeTask_meta_dataErr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitRelease) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitRelease never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToInval) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseToInval never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseToClean) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseToClean never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseWithData) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseWithData never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseIdx) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseIdx never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_state) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_state never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_clients) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_clients never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_alias) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_alias never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_tgtID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_tgtID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_srcID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_srcID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_txnID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_txnID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_homeNID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_homeNID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_dbID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_dbID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_fwdNID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_fwdNID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_fwdTxnID) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_fwdTxnID never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_chiOpcode) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_chiOpcode never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_resp) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_resp never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_fwdState) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_fwdState never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_pCrdType) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_pCrdType never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_retToSrc) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_retToSrc never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_likelyshared) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_likelyshared never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_expCompAck) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_expCompAck never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_allowRetry) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_allowRetry never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_memAttr_allocate) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_memAttr_allocate never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_memAttr_cacheable) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_memAttr_cacheable never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_memAttr_device) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_memAttr_device never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_memAttr_ewa) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_memAttr_ewa never toggled");
      if (t_RequestArb__io_taskToPipe_s2_bits_traceTag) tg++; else $display("COV: RequestArb.io_taskToPipe_s2_bits_traceTag never toggled");
      if (t_RequestArb__io_taskInfo_s1_valid) tg++; else $display("COV: RequestArb.io_taskInfo_s1_valid never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_channel) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_channel never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_txChannel) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_txChannel never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_set) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_set never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_tag) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_tag never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_off) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_off never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_alias) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_alias never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_vaddr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_vaddr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_isKeyword) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_isKeyword never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_opcode) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_opcode never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_param) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_param never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_size) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_size never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_sourceId) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_sourceId never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_bufIdx) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_bufIdx never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_needProbeAckData) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_needProbeAckData never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_denied) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_denied never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_corrupt) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_corrupt never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_mshrTask) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_mshrTask never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_mshrId) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_mshrId never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aliasTask) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aliasTask never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_useProbeData) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_useProbeData never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_mshrRetry) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_mshrRetry never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_readProbeDataDown) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_readProbeDataDown never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_fromL2pft) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_fromL2pft never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_needHint) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_needHint never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_dirty) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_dirty never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_way) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_way never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_dirty) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_dirty never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_state) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_state never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_clients) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_clients never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_alias) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_alias never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_prefetch) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_prefetch never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_prefetchSrc) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_prefetchSrc never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_accessed) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_accessed never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_tagErr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_tagErr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_meta_dataErr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_meta_dataErr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_metaWen) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_metaWen never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_tagWen) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_tagWen never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_dsWen) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_dsWen never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_wayMask) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_wayMask never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_replTask) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_replTask never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_cmoTask) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_cmoTask never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_cmoAll) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_cmoAll never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_reqSource) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_reqSource never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_mergeA) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_mergeA never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_off) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_off never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_alias) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_alias never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_vaddr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_vaddr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_isKeyword) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_isKeyword never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_opcode) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_opcode never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_param) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_param never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_sourceId) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_sourceId never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dirty) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_dirty never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_state) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_state never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_clients) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_clients never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_alias) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_alias never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetch) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_prefetch never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_accessed) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_accessed never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_tagErr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_tagErr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_aMergeTask_meta_dataErr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_aMergeTask_meta_dataErr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitRelease) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitRelease never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToInval) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseToInval never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseToClean) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseToClean never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseWithData) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseWithData never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseIdx) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseIdx never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dirty) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_dirty never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_state) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_state never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_clients) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_clients never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_alias) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_alias never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_accessed) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_accessed never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_tgtID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_tgtID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_srcID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_srcID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_txnID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_txnID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_homeNID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_homeNID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_dbID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_dbID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_fwdNID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_fwdNID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_fwdTxnID) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_fwdTxnID never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_chiOpcode) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_chiOpcode never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_resp) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_resp never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_fwdState) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_fwdState never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_pCrdType) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_pCrdType never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_retToSrc) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_retToSrc never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_likelyshared) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_likelyshared never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_expCompAck) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_expCompAck never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_allowRetry) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_allowRetry never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_memAttr_allocate) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_memAttr_allocate never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_memAttr_cacheable) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_memAttr_cacheable never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_memAttr_device) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_memAttr_device never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_memAttr_ewa) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_memAttr_ewa never toggled");
      if (t_RequestArb__io_taskInfo_s1_bits_traceTag) tg++; else $display("COV: RequestArb.io_taskInfo_s1_bits_traceTag never toggled");
      if (t_RequestArb__io_refillBufRead_s2_valid) tg++; else $display("COV: RequestArb.io_refillBufRead_s2_valid never toggled");
      if (t_RequestArb__io_refillBufRead_s2_bits_id) tg++; else $display("COV: RequestArb.io_refillBufRead_s2_bits_id never toggled");
      if (t_RequestArb__io_releaseBufRead_s2_valid) tg++; else $display("COV: RequestArb.io_releaseBufRead_s2_valid never toggled");
      if (t_RequestArb__io_releaseBufRead_s2_bits_id) tg++; else $display("COV: RequestArb.io_releaseBufRead_s2_bits_id never toggled");
      if (t_RequestArb__io_status_s1_tags_0) tg++; else $display("COV: RequestArb.io_status_s1_tags_0 never toggled");
      if (t_RequestArb__io_status_s1_tags_1) tg++; else $display("COV: RequestArb.io_status_s1_tags_1 never toggled");
      if (t_RequestArb__io_status_s1_tags_2) tg++; else $display("COV: RequestArb.io_status_s1_tags_2 never toggled");
      if (t_RequestArb__io_status_s1_tags_3) tg++; else $display("COV: RequestArb.io_status_s1_tags_3 never toggled");
      if (t_RequestArb__io_status_s1_sets_0) tg++; else $display("COV: RequestArb.io_status_s1_sets_0 never toggled");
      if (t_RequestArb__io_status_s1_sets_1) tg++; else $display("COV: RequestArb.io_status_s1_sets_1 never toggled");
      if (t_RequestArb__io_status_s1_sets_2) tg++; else $display("COV: RequestArb.io_status_s1_sets_2 never toggled");
      if (t_RequestArb__io_status_s1_sets_3) tg++; else $display("COV: RequestArb.io_status_s1_sets_3 never toggled");
      if (t_RequestArb__io_status_vec_0_valid) tg++; else $display("COV: RequestArb.io_status_vec_0_valid never toggled");
      if (t_RequestArb__io_status_vec_0_bits_channel) tg++; else $display("COV: RequestArb.io_status_vec_0_bits_channel never toggled");
      if (t_RequestArb__io_status_vec_1_valid) tg++; else $display("COV: RequestArb.io_status_vec_1_valid never toggled");
      if (t_RequestArb__io_status_vec_1_bits_channel) tg++; else $display("COV: RequestArb.io_status_vec_1_bits_channel never toggled");
      if (t_RequestArb__io_status_vec_toTX_0_valid) tg++; else $display("COV: RequestArb.io_status_vec_toTX_0_valid never toggled");
      if (t_RequestArb__io_status_vec_toTX_0_bits_channel) tg++; else $display("COV: RequestArb.io_status_vec_toTX_0_bits_channel never toggled");
      if (t_RequestArb__io_status_vec_toTX_0_bits_txChannel) tg++; else $display("COV: RequestArb.io_status_vec_toTX_0_bits_txChannel never toggled");
      if (t_RequestArb__io_status_vec_toTX_0_bits_mshrTask) tg++; else $display("COV: RequestArb.io_status_vec_toTX_0_bits_mshrTask never toggled");
      if (t_RequestArb__io_status_vec_toTX_1_valid) tg++; else $display("COV: RequestArb.io_status_vec_toTX_1_valid never toggled");
      if (t_RequestArb__io_status_vec_toTX_1_bits_channel) tg++; else $display("COV: RequestArb.io_status_vec_toTX_1_bits_channel never toggled");
      if (t_RequestArb__io_status_vec_toTX_1_bits_txChannel) tg++; else $display("COV: RequestArb.io_status_vec_toTX_1_bits_txChannel never toggled");
      if (t_RequestArb__io_status_vec_toTX_1_bits_mshrTask) tg++; else $display("COV: RequestArb.io_status_vec_toTX_1_bits_mshrTask never toggled");
      $display("RequestArb: toggled=%0d/232 (need >= 232)", tg);
      if (tg < 232) covfail = 1;
      $display("RequestArb: cover s0 = %0d", cov_RequestArb_s0);
      if (cov_RequestArb_s0 == 0) covfail = 1;
      $display("RequestArb: cover s1 = %0d", cov_RequestArb_s1);
      if (cov_RequestArb_s1 == 0) covfail = 1;
      $display("RequestArb: cover replRead = %0d", cov_RequestArb_replRead);
      if (cov_RequestArb_replRead == 0) covfail = 1;
      $display("RequestArb: cover selC = %0d", cov_RequestArb_selC);
      if (cov_RequestArb_selC == 0) covfail = 1;
      $display("RequestArb: cover selB = %0d", cov_RequestArb_selB);
      if (cov_RequestArb_selB == 0) covfail = 1;
      $display("RequestArb: cover selA = %0d", cov_RequestArb_selA);
      if (cov_RequestArb_selA == 0) covfail = 1;
      $display("RequestArb: cover refillBuf = %0d", cov_RequestArb_refillBuf);
      if (cov_RequestArb_refillBuf == 0) covfail = 1;
      $display("RequestArb: cover releaseBuf = %0d", cov_RequestArb_releaseBuf);
      if (cov_RequestArb_releaseBuf == 0) covfail = 1;
      $display("RequestArb: cover initDone = %0d", cov_RequestArb_initDone);
      if (cov_RequestArb_initDone == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
