// 自动生成 scripts/gen_directory.py —— 勿手改
// Directory 双例化逐拍比对: golden Directory vs 可读重写 Directory_xs。
// MBIST 端口置闲(req/all/sig 全 0), 偏向小 set/tag 域促成命中与 DRRIP 替换。
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
  logic io_read_valid;
  logic [30:0] io_read_bits_tag;
  logic [8:0] io_read_bits_set;
  logic [7:0] io_read_bits_wayMask;
  logic [2:0] io_read_bits_replacerInfo_channel;
  logic [2:0] io_read_bits_replacerInfo_opcode;
  logic [4:0] io_read_bits_replacerInfo_reqSource;
  logic io_read_bits_replacerInfo_refill_prefetch;
  logic io_read_bits_refill;
  logic [7:0] io_read_bits_mshrId;
  logic io_read_bits_cmoAll;
  logic [2:0] io_read_bits_cmoWay;
  logic io_metaWReq_valid;
  logic [8:0] io_metaWReq_bits_set;
  logic [7:0] io_metaWReq_bits_wayOH;
  logic io_metaWReq_bits_wmeta_dirty;
  logic [1:0] io_metaWReq_bits_wmeta_state;
  logic io_metaWReq_bits_wmeta_clients;
  logic [1:0] io_metaWReq_bits_wmeta_alias;
  logic io_metaWReq_bits_wmeta_prefetch;
  logic [2:0] io_metaWReq_bits_wmeta_prefetchSrc;
  logic io_metaWReq_bits_wmeta_accessed;
  logic io_metaWReq_bits_wmeta_tagErr;
  logic io_metaWReq_bits_wmeta_dataErr;
  logic io_tagWReq_valid;
  logic [8:0] io_tagWReq_bits_set;
  logic [2:0] io_tagWReq_bits_way;
  logic [30:0] io_tagWReq_bits_wtag;
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
  logic [3:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [7:0] boreChildrenBd_bore_be;
  logic [9:0] boreChildrenBd_bore_addr;
  logic [103:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [9:0] boreChildrenBd_bore_addr_rd;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic sigFromSrams_bore_2_ram_hold;
  logic sigFromSrams_bore_2_ram_bypass;
  logic sigFromSrams_bore_2_ram_bp_clken;
  logic sigFromSrams_bore_2_ram_aux_clk;
  logic sigFromSrams_bore_2_ram_aux_ckbp;
  logic sigFromSrams_bore_2_ram_mcp_hold;
  logic sigFromSrams_bore_2_cgen;
  logic sigFromSrams_bore_3_ram_hold;
  logic sigFromSrams_bore_3_ram_bypass;
  logic sigFromSrams_bore_3_ram_bp_clken;
  logic sigFromSrams_bore_3_ram_aux_clk;
  logic sigFromSrams_bore_3_ram_aux_ckbp;
  logic sigFromSrams_bore_3_ram_mcp_hold;
  logic sigFromSrams_bore_3_cgen;
  logic sigFromSrams_bore_4_ram_hold;
  logic sigFromSrams_bore_4_ram_bypass;
  logic sigFromSrams_bore_4_ram_bp_clken;
  logic sigFromSrams_bore_4_ram_aux_clk;
  logic sigFromSrams_bore_4_ram_aux_ckbp;
  logic sigFromSrams_bore_4_ram_mcp_hold;
  logic sigFromSrams_bore_4_cgen;
  logic sigFromSrams_bore_5_ram_hold;
  logic sigFromSrams_bore_5_ram_bypass;
  logic sigFromSrams_bore_5_ram_bp_clken;
  logic sigFromSrams_bore_5_ram_aux_clk;
  logic sigFromSrams_bore_5_ram_aux_ckbp;
  logic sigFromSrams_bore_5_ram_mcp_hold;
  logic sigFromSrams_bore_5_cgen;
  logic sigFromSrams_bore_6_ram_hold;
  logic sigFromSrams_bore_6_ram_bypass;
  logic sigFromSrams_bore_6_ram_bp_clken;
  logic sigFromSrams_bore_6_ram_aux_clk;
  logic sigFromSrams_bore_6_ram_aux_ckbp;
  logic sigFromSrams_bore_6_ram_mcp_hold;
  logic sigFromSrams_bore_6_cgen;
  wire g_io_read_ready;
  wire i_io_read_ready;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire g_io_resp_bits_hit;
  wire i_io_resp_bits_hit;
  wire [30:0] g_io_resp_bits_tag;
  wire [30:0] i_io_resp_bits_tag;
  wire [8:0] g_io_resp_bits_set;
  wire [8:0] i_io_resp_bits_set;
  wire [2:0] g_io_resp_bits_way;
  wire [2:0] i_io_resp_bits_way;
  wire g_io_resp_bits_meta_dirty;
  wire i_io_resp_bits_meta_dirty;
  wire [1:0] g_io_resp_bits_meta_state;
  wire [1:0] i_io_resp_bits_meta_state;
  wire g_io_resp_bits_meta_clients;
  wire i_io_resp_bits_meta_clients;
  wire [1:0] g_io_resp_bits_meta_alias;
  wire [1:0] i_io_resp_bits_meta_alias;
  wire g_io_resp_bits_meta_prefetch;
  wire i_io_resp_bits_meta_prefetch;
  wire [2:0] g_io_resp_bits_meta_prefetchSrc;
  wire [2:0] i_io_resp_bits_meta_prefetchSrc;
  wire g_io_resp_bits_meta_accessed;
  wire i_io_resp_bits_meta_accessed;
  wire g_io_resp_bits_meta_tagErr;
  wire i_io_resp_bits_meta_tagErr;
  wire g_io_resp_bits_meta_dataErr;
  wire i_io_resp_bits_meta_dataErr;
  wire g_io_resp_bits_error;
  wire i_io_resp_bits_error;
  wire [2:0] g_io_resp_bits_replacerInfo_channel;
  wire [2:0] i_io_resp_bits_replacerInfo_channel;
  wire [2:0] g_io_resp_bits_replacerInfo_opcode;
  wire [2:0] i_io_resp_bits_replacerInfo_opcode;
  wire [4:0] g_io_resp_bits_replacerInfo_reqSource;
  wire [4:0] i_io_resp_bits_replacerInfo_reqSource;
  wire g_io_resp_bits_replacerInfo_refill_prefetch;
  wire i_io_resp_bits_replacerInfo_refill_prefetch;
  wire g_io_replResp_valid;
  wire i_io_replResp_valid;
  wire [30:0] g_io_replResp_bits_tag;
  wire [30:0] i_io_replResp_bits_tag;
  wire [8:0] g_io_replResp_bits_set;
  wire [8:0] i_io_replResp_bits_set;
  wire [2:0] g_io_replResp_bits_way;
  wire [2:0] i_io_replResp_bits_way;
  wire g_io_replResp_bits_meta_dirty;
  wire i_io_replResp_bits_meta_dirty;
  wire [1:0] g_io_replResp_bits_meta_state;
  wire [1:0] i_io_replResp_bits_meta_state;
  wire g_io_replResp_bits_meta_clients;
  wire i_io_replResp_bits_meta_clients;
  wire [1:0] g_io_replResp_bits_meta_alias;
  wire [1:0] i_io_replResp_bits_meta_alias;
  wire g_io_replResp_bits_meta_prefetch;
  wire i_io_replResp_bits_meta_prefetch;
  wire [2:0] g_io_replResp_bits_meta_prefetchSrc;
  wire [2:0] i_io_replResp_bits_meta_prefetchSrc;
  wire g_io_replResp_bits_meta_accessed;
  wire i_io_replResp_bits_meta_accessed;
  wire g_io_replResp_bits_meta_tagErr;
  wire i_io_replResp_bits_meta_tagErr;
  wire g_io_replResp_bits_meta_dataErr;
  wire i_io_replResp_bits_meta_dataErr;
  wire [7:0] g_io_replResp_bits_mshrId;
  wire [7:0] i_io_replResp_bits_mshrId;
  wire g_io_replResp_bits_retry;
  wire i_io_replResp_bits_retry;
  wire g_boreChildrenBd_bore_ack;
  wire i_boreChildrenBd_bore_ack;
  wire [103:0] g_boreChildrenBd_bore_outdata;
  wire [103:0] i_boreChildrenBd_bore_outdata;

  Directory u_g (
    .clock(clock),
    .reset(reset),
    .io_read_ready(g_io_read_ready),
    .io_read_valid(io_read_valid),
    .io_read_bits_tag(io_read_bits_tag),
    .io_read_bits_set(io_read_bits_set),
    .io_read_bits_wayMask(io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel(io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode(io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource(io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch(io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill(io_read_bits_refill),
    .io_read_bits_mshrId(io_read_bits_mshrId),
    .io_read_bits_cmoAll(io_read_bits_cmoAll),
    .io_read_bits_cmoWay(io_read_bits_cmoWay),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_bits_hit(g_io_resp_bits_hit),
    .io_resp_bits_tag(g_io_resp_bits_tag),
    .io_resp_bits_set(g_io_resp_bits_set),
    .io_resp_bits_way(g_io_resp_bits_way),
    .io_resp_bits_meta_dirty(g_io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state(g_io_resp_bits_meta_state),
    .io_resp_bits_meta_clients(g_io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias(g_io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch(g_io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc(g_io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed(g_io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr(g_io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr(g_io_resp_bits_meta_dataErr),
    .io_resp_bits_error(g_io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel(g_io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode(g_io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource(g_io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch(g_io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty(io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state(io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients(io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias(io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch(io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc(io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed(io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr(io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr(io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_replResp_valid(g_io_replResp_valid),
    .io_replResp_bits_tag(g_io_replResp_bits_tag),
    .io_replResp_bits_set(g_io_replResp_bits_set),
    .io_replResp_bits_way(g_io_replResp_bits_way),
    .io_replResp_bits_meta_dirty(g_io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state(g_io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients(g_io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias(g_io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch(g_io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc(g_io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed(g_io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr(g_io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr(g_io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId(g_io_replResp_bits_mshrId),
    .io_replResp_bits_retry(g_io_replResp_bits_retry),
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
    .io_msInfo_15_bits_releaseToClean(io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen)
  );
  Directory_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_read_ready(i_io_read_ready),
    .io_read_valid(io_read_valid),
    .io_read_bits_tag(io_read_bits_tag),
    .io_read_bits_set(io_read_bits_set),
    .io_read_bits_wayMask(io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel(io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode(io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource(io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch(io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill(io_read_bits_refill),
    .io_read_bits_mshrId(io_read_bits_mshrId),
    .io_read_bits_cmoAll(io_read_bits_cmoAll),
    .io_read_bits_cmoWay(io_read_bits_cmoWay),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_bits_hit(i_io_resp_bits_hit),
    .io_resp_bits_tag(i_io_resp_bits_tag),
    .io_resp_bits_set(i_io_resp_bits_set),
    .io_resp_bits_way(i_io_resp_bits_way),
    .io_resp_bits_meta_dirty(i_io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state(i_io_resp_bits_meta_state),
    .io_resp_bits_meta_clients(i_io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias(i_io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch(i_io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc(i_io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed(i_io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr(i_io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr(i_io_resp_bits_meta_dataErr),
    .io_resp_bits_error(i_io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel(i_io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode(i_io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource(i_io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch(i_io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty(io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state(io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients(io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias(io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch(io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc(io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed(io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr(io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr(io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_replResp_valid(i_io_replResp_valid),
    .io_replResp_bits_tag(i_io_replResp_bits_tag),
    .io_replResp_bits_set(i_io_replResp_bits_set),
    .io_replResp_bits_way(i_io_replResp_bits_way),
    .io_replResp_bits_meta_dirty(i_io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state(i_io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients(i_io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias(i_io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch(i_io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc(i_io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed(i_io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr(i_io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr(i_io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId(i_io_replResp_bits_mshrId),
    .io_replResp_bits_retry(i_io_replResp_bits_retry),
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
    .io_msInfo_15_bits_releaseToClean(io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen)
  );

  task automatic drive_random();
    io_read_valid = ($urandom_range(0,1) == 0);
    io_read_bits_tag = $urandom_range(0,7);
    io_read_bits_set = $urandom_range(0,15);
    io_read_bits_wayMask = $urandom;
    io_read_bits_replacerInfo_channel = $urandom;
    io_read_bits_replacerInfo_opcode = $urandom;
    io_read_bits_replacerInfo_reqSource = $urandom;
    io_read_bits_replacerInfo_refill_prefetch = $urandom;
    io_read_bits_refill = ($urandom_range(0,1) == 0);
    io_read_bits_mshrId = $urandom;
    io_read_bits_cmoAll = ($urandom_range(0,7) == 0);
    io_read_bits_cmoWay = $urandom;
    io_metaWReq_valid = ($urandom_range(0,3) == 0);
    io_metaWReq_bits_set = $urandom_range(0,15);
    io_metaWReq_bits_wayOH = (8'h1 << $urandom_range(0,7));
    io_metaWReq_bits_wmeta_dirty = $urandom;
    io_metaWReq_bits_wmeta_state = $urandom_range(0,3);
    io_metaWReq_bits_wmeta_clients = $urandom;
    io_metaWReq_bits_wmeta_alias = $urandom;
    io_metaWReq_bits_wmeta_prefetch = $urandom;
    io_metaWReq_bits_wmeta_prefetchSrc = $urandom;
    io_metaWReq_bits_wmeta_accessed = $urandom;
    io_metaWReq_bits_wmeta_tagErr = $urandom;
    io_metaWReq_bits_wmeta_dataErr = $urandom;
    io_tagWReq_valid = ($urandom_range(0,3) == 0);
    io_tagWReq_bits_set = $urandom_range(0,15);
    io_tagWReq_bits_way = $urandom;
    io_tagWReq_bits_wtag = $urandom_range(0,7);
    io_msInfo_0_valid = ($urandom_range(0,2) == 0);
    io_msInfo_0_bits_channel = $urandom;
    io_msInfo_0_bits_set = $urandom_range(0,15);
    io_msInfo_0_bits_way = $urandom;
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
    io_msInfo_1_valid = ($urandom_range(0,2) == 0);
    io_msInfo_1_bits_channel = $urandom;
    io_msInfo_1_bits_set = $urandom_range(0,15);
    io_msInfo_1_bits_way = $urandom;
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
    io_msInfo_2_valid = ($urandom_range(0,2) == 0);
    io_msInfo_2_bits_channel = $urandom;
    io_msInfo_2_bits_set = $urandom_range(0,15);
    io_msInfo_2_bits_way = $urandom;
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
    io_msInfo_3_valid = ($urandom_range(0,2) == 0);
    io_msInfo_3_bits_channel = $urandom;
    io_msInfo_3_bits_set = $urandom_range(0,15);
    io_msInfo_3_bits_way = $urandom;
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
    io_msInfo_4_valid = ($urandom_range(0,2) == 0);
    io_msInfo_4_bits_channel = $urandom;
    io_msInfo_4_bits_set = $urandom_range(0,15);
    io_msInfo_4_bits_way = $urandom;
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
    io_msInfo_5_valid = ($urandom_range(0,2) == 0);
    io_msInfo_5_bits_channel = $urandom;
    io_msInfo_5_bits_set = $urandom_range(0,15);
    io_msInfo_5_bits_way = $urandom;
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
    io_msInfo_6_valid = ($urandom_range(0,2) == 0);
    io_msInfo_6_bits_channel = $urandom;
    io_msInfo_6_bits_set = $urandom_range(0,15);
    io_msInfo_6_bits_way = $urandom;
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
    io_msInfo_7_valid = ($urandom_range(0,2) == 0);
    io_msInfo_7_bits_channel = $urandom;
    io_msInfo_7_bits_set = $urandom_range(0,15);
    io_msInfo_7_bits_way = $urandom;
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
    io_msInfo_8_valid = ($urandom_range(0,2) == 0);
    io_msInfo_8_bits_channel = $urandom;
    io_msInfo_8_bits_set = $urandom_range(0,15);
    io_msInfo_8_bits_way = $urandom;
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
    io_msInfo_9_valid = ($urandom_range(0,2) == 0);
    io_msInfo_9_bits_channel = $urandom;
    io_msInfo_9_bits_set = $urandom_range(0,15);
    io_msInfo_9_bits_way = $urandom;
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
    io_msInfo_10_valid = ($urandom_range(0,2) == 0);
    io_msInfo_10_bits_channel = $urandom;
    io_msInfo_10_bits_set = $urandom_range(0,15);
    io_msInfo_10_bits_way = $urandom;
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
    io_msInfo_11_valid = ($urandom_range(0,2) == 0);
    io_msInfo_11_bits_channel = $urandom;
    io_msInfo_11_bits_set = $urandom_range(0,15);
    io_msInfo_11_bits_way = $urandom;
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
    io_msInfo_12_valid = ($urandom_range(0,2) == 0);
    io_msInfo_12_bits_channel = $urandom;
    io_msInfo_12_bits_set = $urandom_range(0,15);
    io_msInfo_12_bits_way = $urandom;
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
    io_msInfo_13_valid = ($urandom_range(0,2) == 0);
    io_msInfo_13_bits_channel = $urandom;
    io_msInfo_13_bits_set = $urandom_range(0,15);
    io_msInfo_13_bits_way = $urandom;
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
    io_msInfo_14_valid = ($urandom_range(0,2) == 0);
    io_msInfo_14_bits_channel = $urandom;
    io_msInfo_14_bits_set = $urandom_range(0,15);
    io_msInfo_14_bits_way = $urandom;
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
    io_msInfo_15_valid = ($urandom_range(0,2) == 0);
    io_msInfo_15_bits_channel = $urandom;
    io_msInfo_15_bits_set = $urandom_range(0,15);
    io_msInfo_15_bits_way = $urandom;
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
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    sigFromSrams_bore_1_ram_hold = '0;
    sigFromSrams_bore_1_ram_bypass = '0;
    sigFromSrams_bore_1_ram_bp_clken = '0;
    sigFromSrams_bore_1_ram_aux_clk = '0;
    sigFromSrams_bore_1_ram_aux_ckbp = '0;
    sigFromSrams_bore_1_ram_mcp_hold = '0;
    sigFromSrams_bore_1_cgen = '0;
    sigFromSrams_bore_2_ram_hold = '0;
    sigFromSrams_bore_2_ram_bypass = '0;
    sigFromSrams_bore_2_ram_bp_clken = '0;
    sigFromSrams_bore_2_ram_aux_clk = '0;
    sigFromSrams_bore_2_ram_aux_ckbp = '0;
    sigFromSrams_bore_2_ram_mcp_hold = '0;
    sigFromSrams_bore_2_cgen = '0;
    sigFromSrams_bore_3_ram_hold = '0;
    sigFromSrams_bore_3_ram_bypass = '0;
    sigFromSrams_bore_3_ram_bp_clken = '0;
    sigFromSrams_bore_3_ram_aux_clk = '0;
    sigFromSrams_bore_3_ram_aux_ckbp = '0;
    sigFromSrams_bore_3_ram_mcp_hold = '0;
    sigFromSrams_bore_3_cgen = '0;
    sigFromSrams_bore_4_ram_hold = '0;
    sigFromSrams_bore_4_ram_bypass = '0;
    sigFromSrams_bore_4_ram_bp_clken = '0;
    sigFromSrams_bore_4_ram_aux_clk = '0;
    sigFromSrams_bore_4_ram_aux_ckbp = '0;
    sigFromSrams_bore_4_ram_mcp_hold = '0;
    sigFromSrams_bore_4_cgen = '0;
    sigFromSrams_bore_5_ram_hold = '0;
    sigFromSrams_bore_5_ram_bypass = '0;
    sigFromSrams_bore_5_ram_bp_clken = '0;
    sigFromSrams_bore_5_ram_aux_clk = '0;
    sigFromSrams_bore_5_ram_aux_ckbp = '0;
    sigFromSrams_bore_5_ram_mcp_hold = '0;
    sigFromSrams_bore_5_cgen = '0;
    sigFromSrams_bore_6_ram_hold = '0;
    sigFromSrams_bore_6_ram_bypass = '0;
    sigFromSrams_bore_6_ram_bp_clken = '0;
    sigFromSrams_bore_6_ram_aux_clk = '0;
    sigFromSrams_bore_6_ram_aux_ckbp = '0;
    sigFromSrams_bore_6_ram_mcp_hold = '0;
    sigFromSrams_bore_6_cgen = '0;
  endtask

  task automatic check_outputs();
    `CHK(io_read_ready)
    `CHK(io_resp_valid)
    `CHK(io_resp_bits_hit)
    `CHK(io_resp_bits_tag)
    `CHK(io_resp_bits_set)
    `CHK(io_resp_bits_way)
    `CHK(io_resp_bits_meta_dirty)
    `CHK(io_resp_bits_meta_state)
    `CHK(io_resp_bits_meta_clients)
    `CHK(io_resp_bits_meta_alias)
    `CHK(io_resp_bits_meta_prefetch)
    `CHK(io_resp_bits_meta_prefetchSrc)
    `CHK(io_resp_bits_meta_accessed)
    `CHK(io_resp_bits_meta_tagErr)
    `CHK(io_resp_bits_meta_dataErr)
    `CHK(io_resp_bits_error)
    `CHK(io_resp_bits_replacerInfo_channel)
    `CHK(io_resp_bits_replacerInfo_opcode)
    `CHK(io_resp_bits_replacerInfo_reqSource)
    `CHK(io_resp_bits_replacerInfo_refill_prefetch)
    `CHK(io_replResp_valid)
    `CHK(io_replResp_bits_tag)
    `CHK(io_replResp_bits_set)
    `CHK(io_replResp_bits_way)
    `CHK(io_replResp_bits_meta_dirty)
    `CHK(io_replResp_bits_meta_state)
    `CHK(io_replResp_bits_meta_clients)
    `CHK(io_replResp_bits_meta_alias)
    `CHK(io_replResp_bits_meta_prefetch)
    `CHK(io_replResp_bits_meta_prefetchSrc)
    `CHK(io_replResp_bits_meta_accessed)
    `CHK(io_replResp_bits_meta_tagErr)
    `CHK(io_replResp_bits_meta_dataErr)
    `CHK(io_replResp_bits_mshrId)
    `CHK(io_replResp_bits_retry)
    `CHK(boreChildrenBd_bore_ack)
    `CHK(boreChildrenBd_bore_outdata)
  endtask

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
    `IPROBE(resetFinish)
    `IPROBE(resetIdx)
    `IPROBE(reqValid_s2)
    `IPROBE(reqValid_s3)
    `IPROBE(refillReqValid_s2)
    `IPROBE(refillReqValid_s3)
    `IPROBE(req_s3_set)
    `IPROBE(req_s3_tag)
    `IPROBE(repl_state_s3)
    `IPROBE(PSEL)
    `IPROBE(freeWayMask_s3)
    `IPROBE(REG)
    `IPROBE(hit_s3)
    `IPROBE(way_s3)
    `IPROBE(finalWay)
    `IPROBE(chosenWay)
    `IPROBE(replaceWay)
    `IPROBE(replacerWen)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_read_valid = '0;
    io_read_bits_tag = '0;
    io_read_bits_set = '0;
    io_read_bits_wayMask = '0;
    io_read_bits_replacerInfo_channel = '0;
    io_read_bits_replacerInfo_opcode = '0;
    io_read_bits_replacerInfo_reqSource = '0;
    io_read_bits_replacerInfo_refill_prefetch = '0;
    io_read_bits_refill = '0;
    io_read_bits_mshrId = '0;
    io_read_bits_cmoAll = '0;
    io_read_bits_cmoWay = '0;
    io_metaWReq_valid = '0;
    io_metaWReq_bits_set = '0;
    io_metaWReq_bits_wayOH = '0;
    io_metaWReq_bits_wmeta_dirty = '0;
    io_metaWReq_bits_wmeta_state = '0;
    io_metaWReq_bits_wmeta_clients = '0;
    io_metaWReq_bits_wmeta_alias = '0;
    io_metaWReq_bits_wmeta_prefetch = '0;
    io_metaWReq_bits_wmeta_prefetchSrc = '0;
    io_metaWReq_bits_wmeta_accessed = '0;
    io_metaWReq_bits_wmeta_tagErr = '0;
    io_metaWReq_bits_wmeta_dataErr = '0;
    io_tagWReq_valid = '0;
    io_tagWReq_bits_set = '0;
    io_tagWReq_bits_way = '0;
    io_tagWReq_bits_wtag = '0;
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
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    sigFromSrams_bore_1_ram_hold = '0;
    sigFromSrams_bore_1_ram_bypass = '0;
    sigFromSrams_bore_1_ram_bp_clken = '0;
    sigFromSrams_bore_1_ram_aux_clk = '0;
    sigFromSrams_bore_1_ram_aux_ckbp = '0;
    sigFromSrams_bore_1_ram_mcp_hold = '0;
    sigFromSrams_bore_1_cgen = '0;
    sigFromSrams_bore_2_ram_hold = '0;
    sigFromSrams_bore_2_ram_bypass = '0;
    sigFromSrams_bore_2_ram_bp_clken = '0;
    sigFromSrams_bore_2_ram_aux_clk = '0;
    sigFromSrams_bore_2_ram_aux_ckbp = '0;
    sigFromSrams_bore_2_ram_mcp_hold = '0;
    sigFromSrams_bore_2_cgen = '0;
    sigFromSrams_bore_3_ram_hold = '0;
    sigFromSrams_bore_3_ram_bypass = '0;
    sigFromSrams_bore_3_ram_bp_clken = '0;
    sigFromSrams_bore_3_ram_aux_clk = '0;
    sigFromSrams_bore_3_ram_aux_ckbp = '0;
    sigFromSrams_bore_3_ram_mcp_hold = '0;
    sigFromSrams_bore_3_cgen = '0;
    sigFromSrams_bore_4_ram_hold = '0;
    sigFromSrams_bore_4_ram_bypass = '0;
    sigFromSrams_bore_4_ram_bp_clken = '0;
    sigFromSrams_bore_4_ram_aux_clk = '0;
    sigFromSrams_bore_4_ram_aux_ckbp = '0;
    sigFromSrams_bore_4_ram_mcp_hold = '0;
    sigFromSrams_bore_4_cgen = '0;
    sigFromSrams_bore_5_ram_hold = '0;
    sigFromSrams_bore_5_ram_bypass = '0;
    sigFromSrams_bore_5_ram_bp_clken = '0;
    sigFromSrams_bore_5_ram_aux_clk = '0;
    sigFromSrams_bore_5_ram_aux_ckbp = '0;
    sigFromSrams_bore_5_ram_mcp_hold = '0;
    sigFromSrams_bore_5_cgen = '0;
    sigFromSrams_bore_6_ram_hold = '0;
    sigFromSrams_bore_6_ram_bypass = '0;
    sigFromSrams_bore_6_ram_bp_clken = '0;
    sigFromSrams_bore_6_ram_aux_clk = '0;
    sigFromSrams_bore_6_ram_aux_ckbp = '0;
    sigFromSrams_bore_6_ram_mcp_hold = '0;
    sigFromSrams_bore_6_cgen = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("Directory checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
