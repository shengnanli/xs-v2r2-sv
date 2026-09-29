// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：Directory Directory_1 Directory_2 Directory_3
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

  // ======================= Directory =======================
  logic Directory__io_read_valid;
  logic [30:0] Directory__io_read_bits_tag;
  logic [8:0] Directory__io_read_bits_set;
  logic [7:0] Directory__io_read_bits_wayMask;
  logic [2:0] Directory__io_read_bits_replacerInfo_channel;
  logic [2:0] Directory__io_read_bits_replacerInfo_opcode;
  logic [4:0] Directory__io_read_bits_replacerInfo_reqSource;
  logic Directory__io_read_bits_replacerInfo_refill_prefetch;
  logic Directory__io_read_bits_refill;
  logic [7:0] Directory__io_read_bits_mshrId;
  logic Directory__io_read_bits_cmoAll;
  logic [2:0] Directory__io_read_bits_cmoWay;
  logic Directory__io_metaWReq_valid;
  logic [8:0] Directory__io_metaWReq_bits_set;
  logic [7:0] Directory__io_metaWReq_bits_wayOH;
  logic Directory__io_metaWReq_bits_wmeta_dirty;
  logic [1:0] Directory__io_metaWReq_bits_wmeta_state;
  logic Directory__io_metaWReq_bits_wmeta_clients;
  logic [1:0] Directory__io_metaWReq_bits_wmeta_alias;
  logic Directory__io_metaWReq_bits_wmeta_prefetch;
  logic [2:0] Directory__io_metaWReq_bits_wmeta_prefetchSrc;
  logic Directory__io_metaWReq_bits_wmeta_accessed;
  logic Directory__io_metaWReq_bits_wmeta_tagErr;
  logic Directory__io_metaWReq_bits_wmeta_dataErr;
  logic Directory__io_tagWReq_valid;
  logic [8:0] Directory__io_tagWReq_bits_set;
  logic [2:0] Directory__io_tagWReq_bits_way;
  logic [30:0] Directory__io_tagWReq_bits_wtag;
  logic Directory__io_msInfo_0_valid;
  logic [2:0] Directory__io_msInfo_0_bits_channel;
  logic [8:0] Directory__io_msInfo_0_bits_set;
  logic [2:0] Directory__io_msInfo_0_bits_way;
  logic [30:0] Directory__io_msInfo_0_bits_reqTag;
  logic Directory__io_msInfo_0_bits_willFree;
  logic Directory__io_msInfo_0_bits_aliasTask;
  logic Directory__io_msInfo_0_bits_needRelease;
  logic Directory__io_msInfo_0_bits_blockRefill;
  logic Directory__io_msInfo_0_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_0_bits_meta_state;
  logic Directory__io_msInfo_0_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_0_bits_meta_alias;
  logic Directory__io_msInfo_0_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_0_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_0_bits_meta_accessed;
  logic Directory__io_msInfo_0_bits_meta_tagErr;
  logic Directory__io_msInfo_0_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_0_bits_metaTag;
  logic Directory__io_msInfo_0_bits_dirHit;
  logic Directory__io_msInfo_0_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_0_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_0_bits_param;
  logic Directory__io_msInfo_0_bits_mergeA;
  logic Directory__io_msInfo_0_bits_w_grantfirst;
  logic Directory__io_msInfo_0_bits_s_release;
  logic Directory__io_msInfo_0_bits_s_refill;
  logic Directory__io_msInfo_0_bits_s_cmoresp;
  logic Directory__io_msInfo_0_bits_s_cmometaw;
  logic Directory__io_msInfo_0_bits_w_releaseack;
  logic Directory__io_msInfo_0_bits_w_replResp;
  logic Directory__io_msInfo_0_bits_w_rprobeacklast;
  logic Directory__io_msInfo_0_bits_replaceData;
  logic Directory__io_msInfo_0_bits_releaseToClean;
  logic Directory__io_msInfo_1_valid;
  logic [2:0] Directory__io_msInfo_1_bits_channel;
  logic [8:0] Directory__io_msInfo_1_bits_set;
  logic [2:0] Directory__io_msInfo_1_bits_way;
  logic [30:0] Directory__io_msInfo_1_bits_reqTag;
  logic Directory__io_msInfo_1_bits_willFree;
  logic Directory__io_msInfo_1_bits_aliasTask;
  logic Directory__io_msInfo_1_bits_needRelease;
  logic Directory__io_msInfo_1_bits_blockRefill;
  logic Directory__io_msInfo_1_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_1_bits_meta_state;
  logic Directory__io_msInfo_1_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_1_bits_meta_alias;
  logic Directory__io_msInfo_1_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_1_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_1_bits_meta_accessed;
  logic Directory__io_msInfo_1_bits_meta_tagErr;
  logic Directory__io_msInfo_1_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_1_bits_metaTag;
  logic Directory__io_msInfo_1_bits_dirHit;
  logic Directory__io_msInfo_1_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_1_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_1_bits_param;
  logic Directory__io_msInfo_1_bits_mergeA;
  logic Directory__io_msInfo_1_bits_w_grantfirst;
  logic Directory__io_msInfo_1_bits_s_release;
  logic Directory__io_msInfo_1_bits_s_refill;
  logic Directory__io_msInfo_1_bits_s_cmoresp;
  logic Directory__io_msInfo_1_bits_s_cmometaw;
  logic Directory__io_msInfo_1_bits_w_releaseack;
  logic Directory__io_msInfo_1_bits_w_replResp;
  logic Directory__io_msInfo_1_bits_w_rprobeacklast;
  logic Directory__io_msInfo_1_bits_replaceData;
  logic Directory__io_msInfo_1_bits_releaseToClean;
  logic Directory__io_msInfo_2_valid;
  logic [2:0] Directory__io_msInfo_2_bits_channel;
  logic [8:0] Directory__io_msInfo_2_bits_set;
  logic [2:0] Directory__io_msInfo_2_bits_way;
  logic [30:0] Directory__io_msInfo_2_bits_reqTag;
  logic Directory__io_msInfo_2_bits_willFree;
  logic Directory__io_msInfo_2_bits_aliasTask;
  logic Directory__io_msInfo_2_bits_needRelease;
  logic Directory__io_msInfo_2_bits_blockRefill;
  logic Directory__io_msInfo_2_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_2_bits_meta_state;
  logic Directory__io_msInfo_2_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_2_bits_meta_alias;
  logic Directory__io_msInfo_2_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_2_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_2_bits_meta_accessed;
  logic Directory__io_msInfo_2_bits_meta_tagErr;
  logic Directory__io_msInfo_2_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_2_bits_metaTag;
  logic Directory__io_msInfo_2_bits_dirHit;
  logic Directory__io_msInfo_2_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_2_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_2_bits_param;
  logic Directory__io_msInfo_2_bits_mergeA;
  logic Directory__io_msInfo_2_bits_w_grantfirst;
  logic Directory__io_msInfo_2_bits_s_release;
  logic Directory__io_msInfo_2_bits_s_refill;
  logic Directory__io_msInfo_2_bits_s_cmoresp;
  logic Directory__io_msInfo_2_bits_s_cmometaw;
  logic Directory__io_msInfo_2_bits_w_releaseack;
  logic Directory__io_msInfo_2_bits_w_replResp;
  logic Directory__io_msInfo_2_bits_w_rprobeacklast;
  logic Directory__io_msInfo_2_bits_replaceData;
  logic Directory__io_msInfo_2_bits_releaseToClean;
  logic Directory__io_msInfo_3_valid;
  logic [2:0] Directory__io_msInfo_3_bits_channel;
  logic [8:0] Directory__io_msInfo_3_bits_set;
  logic [2:0] Directory__io_msInfo_3_bits_way;
  logic [30:0] Directory__io_msInfo_3_bits_reqTag;
  logic Directory__io_msInfo_3_bits_willFree;
  logic Directory__io_msInfo_3_bits_aliasTask;
  logic Directory__io_msInfo_3_bits_needRelease;
  logic Directory__io_msInfo_3_bits_blockRefill;
  logic Directory__io_msInfo_3_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_3_bits_meta_state;
  logic Directory__io_msInfo_3_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_3_bits_meta_alias;
  logic Directory__io_msInfo_3_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_3_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_3_bits_meta_accessed;
  logic Directory__io_msInfo_3_bits_meta_tagErr;
  logic Directory__io_msInfo_3_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_3_bits_metaTag;
  logic Directory__io_msInfo_3_bits_dirHit;
  logic Directory__io_msInfo_3_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_3_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_3_bits_param;
  logic Directory__io_msInfo_3_bits_mergeA;
  logic Directory__io_msInfo_3_bits_w_grantfirst;
  logic Directory__io_msInfo_3_bits_s_release;
  logic Directory__io_msInfo_3_bits_s_refill;
  logic Directory__io_msInfo_3_bits_s_cmoresp;
  logic Directory__io_msInfo_3_bits_s_cmometaw;
  logic Directory__io_msInfo_3_bits_w_releaseack;
  logic Directory__io_msInfo_3_bits_w_replResp;
  logic Directory__io_msInfo_3_bits_w_rprobeacklast;
  logic Directory__io_msInfo_3_bits_replaceData;
  logic Directory__io_msInfo_3_bits_releaseToClean;
  logic Directory__io_msInfo_4_valid;
  logic [2:0] Directory__io_msInfo_4_bits_channel;
  logic [8:0] Directory__io_msInfo_4_bits_set;
  logic [2:0] Directory__io_msInfo_4_bits_way;
  logic [30:0] Directory__io_msInfo_4_bits_reqTag;
  logic Directory__io_msInfo_4_bits_willFree;
  logic Directory__io_msInfo_4_bits_aliasTask;
  logic Directory__io_msInfo_4_bits_needRelease;
  logic Directory__io_msInfo_4_bits_blockRefill;
  logic Directory__io_msInfo_4_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_4_bits_meta_state;
  logic Directory__io_msInfo_4_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_4_bits_meta_alias;
  logic Directory__io_msInfo_4_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_4_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_4_bits_meta_accessed;
  logic Directory__io_msInfo_4_bits_meta_tagErr;
  logic Directory__io_msInfo_4_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_4_bits_metaTag;
  logic Directory__io_msInfo_4_bits_dirHit;
  logic Directory__io_msInfo_4_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_4_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_4_bits_param;
  logic Directory__io_msInfo_4_bits_mergeA;
  logic Directory__io_msInfo_4_bits_w_grantfirst;
  logic Directory__io_msInfo_4_bits_s_release;
  logic Directory__io_msInfo_4_bits_s_refill;
  logic Directory__io_msInfo_4_bits_s_cmoresp;
  logic Directory__io_msInfo_4_bits_s_cmometaw;
  logic Directory__io_msInfo_4_bits_w_releaseack;
  logic Directory__io_msInfo_4_bits_w_replResp;
  logic Directory__io_msInfo_4_bits_w_rprobeacklast;
  logic Directory__io_msInfo_4_bits_replaceData;
  logic Directory__io_msInfo_4_bits_releaseToClean;
  logic Directory__io_msInfo_5_valid;
  logic [2:0] Directory__io_msInfo_5_bits_channel;
  logic [8:0] Directory__io_msInfo_5_bits_set;
  logic [2:0] Directory__io_msInfo_5_bits_way;
  logic [30:0] Directory__io_msInfo_5_bits_reqTag;
  logic Directory__io_msInfo_5_bits_willFree;
  logic Directory__io_msInfo_5_bits_aliasTask;
  logic Directory__io_msInfo_5_bits_needRelease;
  logic Directory__io_msInfo_5_bits_blockRefill;
  logic Directory__io_msInfo_5_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_5_bits_meta_state;
  logic Directory__io_msInfo_5_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_5_bits_meta_alias;
  logic Directory__io_msInfo_5_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_5_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_5_bits_meta_accessed;
  logic Directory__io_msInfo_5_bits_meta_tagErr;
  logic Directory__io_msInfo_5_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_5_bits_metaTag;
  logic Directory__io_msInfo_5_bits_dirHit;
  logic Directory__io_msInfo_5_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_5_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_5_bits_param;
  logic Directory__io_msInfo_5_bits_mergeA;
  logic Directory__io_msInfo_5_bits_w_grantfirst;
  logic Directory__io_msInfo_5_bits_s_release;
  logic Directory__io_msInfo_5_bits_s_refill;
  logic Directory__io_msInfo_5_bits_s_cmoresp;
  logic Directory__io_msInfo_5_bits_s_cmometaw;
  logic Directory__io_msInfo_5_bits_w_releaseack;
  logic Directory__io_msInfo_5_bits_w_replResp;
  logic Directory__io_msInfo_5_bits_w_rprobeacklast;
  logic Directory__io_msInfo_5_bits_replaceData;
  logic Directory__io_msInfo_5_bits_releaseToClean;
  logic Directory__io_msInfo_6_valid;
  logic [2:0] Directory__io_msInfo_6_bits_channel;
  logic [8:0] Directory__io_msInfo_6_bits_set;
  logic [2:0] Directory__io_msInfo_6_bits_way;
  logic [30:0] Directory__io_msInfo_6_bits_reqTag;
  logic Directory__io_msInfo_6_bits_willFree;
  logic Directory__io_msInfo_6_bits_aliasTask;
  logic Directory__io_msInfo_6_bits_needRelease;
  logic Directory__io_msInfo_6_bits_blockRefill;
  logic Directory__io_msInfo_6_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_6_bits_meta_state;
  logic Directory__io_msInfo_6_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_6_bits_meta_alias;
  logic Directory__io_msInfo_6_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_6_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_6_bits_meta_accessed;
  logic Directory__io_msInfo_6_bits_meta_tagErr;
  logic Directory__io_msInfo_6_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_6_bits_metaTag;
  logic Directory__io_msInfo_6_bits_dirHit;
  logic Directory__io_msInfo_6_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_6_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_6_bits_param;
  logic Directory__io_msInfo_6_bits_mergeA;
  logic Directory__io_msInfo_6_bits_w_grantfirst;
  logic Directory__io_msInfo_6_bits_s_release;
  logic Directory__io_msInfo_6_bits_s_refill;
  logic Directory__io_msInfo_6_bits_s_cmoresp;
  logic Directory__io_msInfo_6_bits_s_cmometaw;
  logic Directory__io_msInfo_6_bits_w_releaseack;
  logic Directory__io_msInfo_6_bits_w_replResp;
  logic Directory__io_msInfo_6_bits_w_rprobeacklast;
  logic Directory__io_msInfo_6_bits_replaceData;
  logic Directory__io_msInfo_6_bits_releaseToClean;
  logic Directory__io_msInfo_7_valid;
  logic [2:0] Directory__io_msInfo_7_bits_channel;
  logic [8:0] Directory__io_msInfo_7_bits_set;
  logic [2:0] Directory__io_msInfo_7_bits_way;
  logic [30:0] Directory__io_msInfo_7_bits_reqTag;
  logic Directory__io_msInfo_7_bits_willFree;
  logic Directory__io_msInfo_7_bits_aliasTask;
  logic Directory__io_msInfo_7_bits_needRelease;
  logic Directory__io_msInfo_7_bits_blockRefill;
  logic Directory__io_msInfo_7_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_7_bits_meta_state;
  logic Directory__io_msInfo_7_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_7_bits_meta_alias;
  logic Directory__io_msInfo_7_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_7_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_7_bits_meta_accessed;
  logic Directory__io_msInfo_7_bits_meta_tagErr;
  logic Directory__io_msInfo_7_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_7_bits_metaTag;
  logic Directory__io_msInfo_7_bits_dirHit;
  logic Directory__io_msInfo_7_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_7_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_7_bits_param;
  logic Directory__io_msInfo_7_bits_mergeA;
  logic Directory__io_msInfo_7_bits_w_grantfirst;
  logic Directory__io_msInfo_7_bits_s_release;
  logic Directory__io_msInfo_7_bits_s_refill;
  logic Directory__io_msInfo_7_bits_s_cmoresp;
  logic Directory__io_msInfo_7_bits_s_cmometaw;
  logic Directory__io_msInfo_7_bits_w_releaseack;
  logic Directory__io_msInfo_7_bits_w_replResp;
  logic Directory__io_msInfo_7_bits_w_rprobeacklast;
  logic Directory__io_msInfo_7_bits_replaceData;
  logic Directory__io_msInfo_7_bits_releaseToClean;
  logic Directory__io_msInfo_8_valid;
  logic [2:0] Directory__io_msInfo_8_bits_channel;
  logic [8:0] Directory__io_msInfo_8_bits_set;
  logic [2:0] Directory__io_msInfo_8_bits_way;
  logic [30:0] Directory__io_msInfo_8_bits_reqTag;
  logic Directory__io_msInfo_8_bits_willFree;
  logic Directory__io_msInfo_8_bits_aliasTask;
  logic Directory__io_msInfo_8_bits_needRelease;
  logic Directory__io_msInfo_8_bits_blockRefill;
  logic Directory__io_msInfo_8_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_8_bits_meta_state;
  logic Directory__io_msInfo_8_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_8_bits_meta_alias;
  logic Directory__io_msInfo_8_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_8_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_8_bits_meta_accessed;
  logic Directory__io_msInfo_8_bits_meta_tagErr;
  logic Directory__io_msInfo_8_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_8_bits_metaTag;
  logic Directory__io_msInfo_8_bits_dirHit;
  logic Directory__io_msInfo_8_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_8_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_8_bits_param;
  logic Directory__io_msInfo_8_bits_mergeA;
  logic Directory__io_msInfo_8_bits_w_grantfirst;
  logic Directory__io_msInfo_8_bits_s_release;
  logic Directory__io_msInfo_8_bits_s_refill;
  logic Directory__io_msInfo_8_bits_s_cmoresp;
  logic Directory__io_msInfo_8_bits_s_cmometaw;
  logic Directory__io_msInfo_8_bits_w_releaseack;
  logic Directory__io_msInfo_8_bits_w_replResp;
  logic Directory__io_msInfo_8_bits_w_rprobeacklast;
  logic Directory__io_msInfo_8_bits_replaceData;
  logic Directory__io_msInfo_8_bits_releaseToClean;
  logic Directory__io_msInfo_9_valid;
  logic [2:0] Directory__io_msInfo_9_bits_channel;
  logic [8:0] Directory__io_msInfo_9_bits_set;
  logic [2:0] Directory__io_msInfo_9_bits_way;
  logic [30:0] Directory__io_msInfo_9_bits_reqTag;
  logic Directory__io_msInfo_9_bits_willFree;
  logic Directory__io_msInfo_9_bits_aliasTask;
  logic Directory__io_msInfo_9_bits_needRelease;
  logic Directory__io_msInfo_9_bits_blockRefill;
  logic Directory__io_msInfo_9_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_9_bits_meta_state;
  logic Directory__io_msInfo_9_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_9_bits_meta_alias;
  logic Directory__io_msInfo_9_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_9_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_9_bits_meta_accessed;
  logic Directory__io_msInfo_9_bits_meta_tagErr;
  logic Directory__io_msInfo_9_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_9_bits_metaTag;
  logic Directory__io_msInfo_9_bits_dirHit;
  logic Directory__io_msInfo_9_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_9_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_9_bits_param;
  logic Directory__io_msInfo_9_bits_mergeA;
  logic Directory__io_msInfo_9_bits_w_grantfirst;
  logic Directory__io_msInfo_9_bits_s_release;
  logic Directory__io_msInfo_9_bits_s_refill;
  logic Directory__io_msInfo_9_bits_s_cmoresp;
  logic Directory__io_msInfo_9_bits_s_cmometaw;
  logic Directory__io_msInfo_9_bits_w_releaseack;
  logic Directory__io_msInfo_9_bits_w_replResp;
  logic Directory__io_msInfo_9_bits_w_rprobeacklast;
  logic Directory__io_msInfo_9_bits_replaceData;
  logic Directory__io_msInfo_9_bits_releaseToClean;
  logic Directory__io_msInfo_10_valid;
  logic [2:0] Directory__io_msInfo_10_bits_channel;
  logic [8:0] Directory__io_msInfo_10_bits_set;
  logic [2:0] Directory__io_msInfo_10_bits_way;
  logic [30:0] Directory__io_msInfo_10_bits_reqTag;
  logic Directory__io_msInfo_10_bits_willFree;
  logic Directory__io_msInfo_10_bits_aliasTask;
  logic Directory__io_msInfo_10_bits_needRelease;
  logic Directory__io_msInfo_10_bits_blockRefill;
  logic Directory__io_msInfo_10_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_10_bits_meta_state;
  logic Directory__io_msInfo_10_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_10_bits_meta_alias;
  logic Directory__io_msInfo_10_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_10_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_10_bits_meta_accessed;
  logic Directory__io_msInfo_10_bits_meta_tagErr;
  logic Directory__io_msInfo_10_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_10_bits_metaTag;
  logic Directory__io_msInfo_10_bits_dirHit;
  logic Directory__io_msInfo_10_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_10_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_10_bits_param;
  logic Directory__io_msInfo_10_bits_mergeA;
  logic Directory__io_msInfo_10_bits_w_grantfirst;
  logic Directory__io_msInfo_10_bits_s_release;
  logic Directory__io_msInfo_10_bits_s_refill;
  logic Directory__io_msInfo_10_bits_s_cmoresp;
  logic Directory__io_msInfo_10_bits_s_cmometaw;
  logic Directory__io_msInfo_10_bits_w_releaseack;
  logic Directory__io_msInfo_10_bits_w_replResp;
  logic Directory__io_msInfo_10_bits_w_rprobeacklast;
  logic Directory__io_msInfo_10_bits_replaceData;
  logic Directory__io_msInfo_10_bits_releaseToClean;
  logic Directory__io_msInfo_11_valid;
  logic [2:0] Directory__io_msInfo_11_bits_channel;
  logic [8:0] Directory__io_msInfo_11_bits_set;
  logic [2:0] Directory__io_msInfo_11_bits_way;
  logic [30:0] Directory__io_msInfo_11_bits_reqTag;
  logic Directory__io_msInfo_11_bits_willFree;
  logic Directory__io_msInfo_11_bits_aliasTask;
  logic Directory__io_msInfo_11_bits_needRelease;
  logic Directory__io_msInfo_11_bits_blockRefill;
  logic Directory__io_msInfo_11_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_11_bits_meta_state;
  logic Directory__io_msInfo_11_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_11_bits_meta_alias;
  logic Directory__io_msInfo_11_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_11_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_11_bits_meta_accessed;
  logic Directory__io_msInfo_11_bits_meta_tagErr;
  logic Directory__io_msInfo_11_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_11_bits_metaTag;
  logic Directory__io_msInfo_11_bits_dirHit;
  logic Directory__io_msInfo_11_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_11_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_11_bits_param;
  logic Directory__io_msInfo_11_bits_mergeA;
  logic Directory__io_msInfo_11_bits_w_grantfirst;
  logic Directory__io_msInfo_11_bits_s_release;
  logic Directory__io_msInfo_11_bits_s_refill;
  logic Directory__io_msInfo_11_bits_s_cmoresp;
  logic Directory__io_msInfo_11_bits_s_cmometaw;
  logic Directory__io_msInfo_11_bits_w_releaseack;
  logic Directory__io_msInfo_11_bits_w_replResp;
  logic Directory__io_msInfo_11_bits_w_rprobeacklast;
  logic Directory__io_msInfo_11_bits_replaceData;
  logic Directory__io_msInfo_11_bits_releaseToClean;
  logic Directory__io_msInfo_12_valid;
  logic [2:0] Directory__io_msInfo_12_bits_channel;
  logic [8:0] Directory__io_msInfo_12_bits_set;
  logic [2:0] Directory__io_msInfo_12_bits_way;
  logic [30:0] Directory__io_msInfo_12_bits_reqTag;
  logic Directory__io_msInfo_12_bits_willFree;
  logic Directory__io_msInfo_12_bits_aliasTask;
  logic Directory__io_msInfo_12_bits_needRelease;
  logic Directory__io_msInfo_12_bits_blockRefill;
  logic Directory__io_msInfo_12_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_12_bits_meta_state;
  logic Directory__io_msInfo_12_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_12_bits_meta_alias;
  logic Directory__io_msInfo_12_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_12_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_12_bits_meta_accessed;
  logic Directory__io_msInfo_12_bits_meta_tagErr;
  logic Directory__io_msInfo_12_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_12_bits_metaTag;
  logic Directory__io_msInfo_12_bits_dirHit;
  logic Directory__io_msInfo_12_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_12_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_12_bits_param;
  logic Directory__io_msInfo_12_bits_mergeA;
  logic Directory__io_msInfo_12_bits_w_grantfirst;
  logic Directory__io_msInfo_12_bits_s_release;
  logic Directory__io_msInfo_12_bits_s_refill;
  logic Directory__io_msInfo_12_bits_s_cmoresp;
  logic Directory__io_msInfo_12_bits_s_cmometaw;
  logic Directory__io_msInfo_12_bits_w_releaseack;
  logic Directory__io_msInfo_12_bits_w_replResp;
  logic Directory__io_msInfo_12_bits_w_rprobeacklast;
  logic Directory__io_msInfo_12_bits_replaceData;
  logic Directory__io_msInfo_12_bits_releaseToClean;
  logic Directory__io_msInfo_13_valid;
  logic [2:0] Directory__io_msInfo_13_bits_channel;
  logic [8:0] Directory__io_msInfo_13_bits_set;
  logic [2:0] Directory__io_msInfo_13_bits_way;
  logic [30:0] Directory__io_msInfo_13_bits_reqTag;
  logic Directory__io_msInfo_13_bits_willFree;
  logic Directory__io_msInfo_13_bits_aliasTask;
  logic Directory__io_msInfo_13_bits_needRelease;
  logic Directory__io_msInfo_13_bits_blockRefill;
  logic Directory__io_msInfo_13_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_13_bits_meta_state;
  logic Directory__io_msInfo_13_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_13_bits_meta_alias;
  logic Directory__io_msInfo_13_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_13_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_13_bits_meta_accessed;
  logic Directory__io_msInfo_13_bits_meta_tagErr;
  logic Directory__io_msInfo_13_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_13_bits_metaTag;
  logic Directory__io_msInfo_13_bits_dirHit;
  logic Directory__io_msInfo_13_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_13_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_13_bits_param;
  logic Directory__io_msInfo_13_bits_mergeA;
  logic Directory__io_msInfo_13_bits_w_grantfirst;
  logic Directory__io_msInfo_13_bits_s_release;
  logic Directory__io_msInfo_13_bits_s_refill;
  logic Directory__io_msInfo_13_bits_s_cmoresp;
  logic Directory__io_msInfo_13_bits_s_cmometaw;
  logic Directory__io_msInfo_13_bits_w_releaseack;
  logic Directory__io_msInfo_13_bits_w_replResp;
  logic Directory__io_msInfo_13_bits_w_rprobeacklast;
  logic Directory__io_msInfo_13_bits_replaceData;
  logic Directory__io_msInfo_13_bits_releaseToClean;
  logic Directory__io_msInfo_14_valid;
  logic [2:0] Directory__io_msInfo_14_bits_channel;
  logic [8:0] Directory__io_msInfo_14_bits_set;
  logic [2:0] Directory__io_msInfo_14_bits_way;
  logic [30:0] Directory__io_msInfo_14_bits_reqTag;
  logic Directory__io_msInfo_14_bits_willFree;
  logic Directory__io_msInfo_14_bits_aliasTask;
  logic Directory__io_msInfo_14_bits_needRelease;
  logic Directory__io_msInfo_14_bits_blockRefill;
  logic Directory__io_msInfo_14_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_14_bits_meta_state;
  logic Directory__io_msInfo_14_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_14_bits_meta_alias;
  logic Directory__io_msInfo_14_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_14_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_14_bits_meta_accessed;
  logic Directory__io_msInfo_14_bits_meta_tagErr;
  logic Directory__io_msInfo_14_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_14_bits_metaTag;
  logic Directory__io_msInfo_14_bits_dirHit;
  logic Directory__io_msInfo_14_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_14_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_14_bits_param;
  logic Directory__io_msInfo_14_bits_mergeA;
  logic Directory__io_msInfo_14_bits_w_grantfirst;
  logic Directory__io_msInfo_14_bits_s_release;
  logic Directory__io_msInfo_14_bits_s_refill;
  logic Directory__io_msInfo_14_bits_s_cmoresp;
  logic Directory__io_msInfo_14_bits_s_cmometaw;
  logic Directory__io_msInfo_14_bits_w_releaseack;
  logic Directory__io_msInfo_14_bits_w_replResp;
  logic Directory__io_msInfo_14_bits_w_rprobeacklast;
  logic Directory__io_msInfo_14_bits_replaceData;
  logic Directory__io_msInfo_14_bits_releaseToClean;
  logic Directory__io_msInfo_15_valid;
  logic [2:0] Directory__io_msInfo_15_bits_channel;
  logic [8:0] Directory__io_msInfo_15_bits_set;
  logic [2:0] Directory__io_msInfo_15_bits_way;
  logic [30:0] Directory__io_msInfo_15_bits_reqTag;
  logic Directory__io_msInfo_15_bits_willFree;
  logic Directory__io_msInfo_15_bits_aliasTask;
  logic Directory__io_msInfo_15_bits_needRelease;
  logic Directory__io_msInfo_15_bits_blockRefill;
  logic Directory__io_msInfo_15_bits_meta_dirty;
  logic [1:0] Directory__io_msInfo_15_bits_meta_state;
  logic Directory__io_msInfo_15_bits_meta_clients;
  logic [1:0] Directory__io_msInfo_15_bits_meta_alias;
  logic Directory__io_msInfo_15_bits_meta_prefetch;
  logic [2:0] Directory__io_msInfo_15_bits_meta_prefetchSrc;
  logic Directory__io_msInfo_15_bits_meta_accessed;
  logic Directory__io_msInfo_15_bits_meta_tagErr;
  logic Directory__io_msInfo_15_bits_meta_dataErr;
  logic [30:0] Directory__io_msInfo_15_bits_metaTag;
  logic Directory__io_msInfo_15_bits_dirHit;
  logic Directory__io_msInfo_15_bits_isAcqOrPrefetch;
  logic Directory__io_msInfo_15_bits_isPrefetch;
  logic [2:0] Directory__io_msInfo_15_bits_param;
  logic Directory__io_msInfo_15_bits_mergeA;
  logic Directory__io_msInfo_15_bits_w_grantfirst;
  logic Directory__io_msInfo_15_bits_s_release;
  logic Directory__io_msInfo_15_bits_s_refill;
  logic Directory__io_msInfo_15_bits_s_cmoresp;
  logic Directory__io_msInfo_15_bits_s_cmometaw;
  logic Directory__io_msInfo_15_bits_w_releaseack;
  logic Directory__io_msInfo_15_bits_w_replResp;
  logic Directory__io_msInfo_15_bits_w_rprobeacklast;
  logic Directory__io_msInfo_15_bits_replaceData;
  logic Directory__io_msInfo_15_bits_releaseToClean;
  logic [3:0] Directory__boreChildrenBd_bore_array;
  logic Directory__boreChildrenBd_bore_all;
  logic Directory__boreChildrenBd_bore_req;
  logic Directory__boreChildrenBd_bore_writeen;
  logic [7:0] Directory__boreChildrenBd_bore_be;
  logic [9:0] Directory__boreChildrenBd_bore_addr;
  logic [103:0] Directory__boreChildrenBd_bore_indata;
  logic Directory__boreChildrenBd_bore_readen;
  logic [9:0] Directory__boreChildrenBd_bore_addr_rd;
  logic Directory__sigFromSrams_bore_ram_hold;
  logic Directory__sigFromSrams_bore_ram_bypass;
  logic Directory__sigFromSrams_bore_ram_bp_clken;
  logic Directory__sigFromSrams_bore_ram_aux_clk;
  logic Directory__sigFromSrams_bore_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_cgen;
  logic Directory__sigFromSrams_bore_1_ram_hold;
  logic Directory__sigFromSrams_bore_1_ram_bypass;
  logic Directory__sigFromSrams_bore_1_ram_bp_clken;
  logic Directory__sigFromSrams_bore_1_ram_aux_clk;
  logic Directory__sigFromSrams_bore_1_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_1_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_1_cgen;
  logic Directory__sigFromSrams_bore_2_ram_hold;
  logic Directory__sigFromSrams_bore_2_ram_bypass;
  logic Directory__sigFromSrams_bore_2_ram_bp_clken;
  logic Directory__sigFromSrams_bore_2_ram_aux_clk;
  logic Directory__sigFromSrams_bore_2_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_2_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_2_cgen;
  logic Directory__sigFromSrams_bore_3_ram_hold;
  logic Directory__sigFromSrams_bore_3_ram_bypass;
  logic Directory__sigFromSrams_bore_3_ram_bp_clken;
  logic Directory__sigFromSrams_bore_3_ram_aux_clk;
  logic Directory__sigFromSrams_bore_3_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_3_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_3_cgen;
  logic Directory__sigFromSrams_bore_4_ram_hold;
  logic Directory__sigFromSrams_bore_4_ram_bypass;
  logic Directory__sigFromSrams_bore_4_ram_bp_clken;
  logic Directory__sigFromSrams_bore_4_ram_aux_clk;
  logic Directory__sigFromSrams_bore_4_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_4_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_4_cgen;
  logic Directory__sigFromSrams_bore_5_ram_hold;
  logic Directory__sigFromSrams_bore_5_ram_bypass;
  logic Directory__sigFromSrams_bore_5_ram_bp_clken;
  logic Directory__sigFromSrams_bore_5_ram_aux_clk;
  logic Directory__sigFromSrams_bore_5_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_5_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_5_cgen;
  logic Directory__sigFromSrams_bore_6_ram_hold;
  logic Directory__sigFromSrams_bore_6_ram_bypass;
  logic Directory__sigFromSrams_bore_6_ram_bp_clken;
  logic Directory__sigFromSrams_bore_6_ram_aux_clk;
  logic Directory__sigFromSrams_bore_6_ram_aux_ckbp;
  logic Directory__sigFromSrams_bore_6_ram_mcp_hold;
  logic Directory__sigFromSrams_bore_6_cgen;
  wire  g_Directory__io_read_ready;
  wire  i_Directory__io_read_ready;
  logic p_Directory__io_read_ready;
  bit   t_Directory__io_read_ready;
  wire  g_Directory__io_resp_valid;
  wire  i_Directory__io_resp_valid;
  logic p_Directory__io_resp_valid;
  bit   t_Directory__io_resp_valid;
  wire  g_Directory__io_resp_bits_hit;
  wire  i_Directory__io_resp_bits_hit;
  logic p_Directory__io_resp_bits_hit;
  bit   t_Directory__io_resp_bits_hit;
  wire  [30:0] g_Directory__io_resp_bits_tag;
  wire  [30:0] i_Directory__io_resp_bits_tag;
  logic [30:0] p_Directory__io_resp_bits_tag;
  bit   t_Directory__io_resp_bits_tag;
  wire  [8:0] g_Directory__io_resp_bits_set;
  wire  [8:0] i_Directory__io_resp_bits_set;
  logic [8:0] p_Directory__io_resp_bits_set;
  bit   t_Directory__io_resp_bits_set;
  wire  [2:0] g_Directory__io_resp_bits_way;
  wire  [2:0] i_Directory__io_resp_bits_way;
  logic [2:0] p_Directory__io_resp_bits_way;
  bit   t_Directory__io_resp_bits_way;
  wire  g_Directory__io_resp_bits_meta_dirty;
  wire  i_Directory__io_resp_bits_meta_dirty;
  logic p_Directory__io_resp_bits_meta_dirty;
  bit   t_Directory__io_resp_bits_meta_dirty;
  wire  [1:0] g_Directory__io_resp_bits_meta_state;
  wire  [1:0] i_Directory__io_resp_bits_meta_state;
  logic [1:0] p_Directory__io_resp_bits_meta_state;
  bit   t_Directory__io_resp_bits_meta_state;
  wire  g_Directory__io_resp_bits_meta_clients;
  wire  i_Directory__io_resp_bits_meta_clients;
  logic p_Directory__io_resp_bits_meta_clients;
  bit   t_Directory__io_resp_bits_meta_clients;
  wire  [1:0] g_Directory__io_resp_bits_meta_alias;
  wire  [1:0] i_Directory__io_resp_bits_meta_alias;
  logic [1:0] p_Directory__io_resp_bits_meta_alias;
  bit   t_Directory__io_resp_bits_meta_alias;
  wire  g_Directory__io_resp_bits_meta_prefetch;
  wire  i_Directory__io_resp_bits_meta_prefetch;
  logic p_Directory__io_resp_bits_meta_prefetch;
  bit   t_Directory__io_resp_bits_meta_prefetch;
  wire  [2:0] g_Directory__io_resp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory__io_resp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory__io_resp_bits_meta_prefetchSrc;
  bit   t_Directory__io_resp_bits_meta_prefetchSrc;
  wire  g_Directory__io_resp_bits_meta_accessed;
  wire  i_Directory__io_resp_bits_meta_accessed;
  logic p_Directory__io_resp_bits_meta_accessed;
  bit   t_Directory__io_resp_bits_meta_accessed;
  wire  g_Directory__io_resp_bits_meta_tagErr;
  wire  i_Directory__io_resp_bits_meta_tagErr;
  logic p_Directory__io_resp_bits_meta_tagErr;
  bit   t_Directory__io_resp_bits_meta_tagErr;
  wire  g_Directory__io_resp_bits_meta_dataErr;
  wire  i_Directory__io_resp_bits_meta_dataErr;
  logic p_Directory__io_resp_bits_meta_dataErr;
  bit   t_Directory__io_resp_bits_meta_dataErr;
  wire  g_Directory__io_resp_bits_error;
  wire  i_Directory__io_resp_bits_error;
  logic p_Directory__io_resp_bits_error;
  bit   t_Directory__io_resp_bits_error;
  wire  [2:0] g_Directory__io_resp_bits_replacerInfo_channel;
  wire  [2:0] i_Directory__io_resp_bits_replacerInfo_channel;
  logic [2:0] p_Directory__io_resp_bits_replacerInfo_channel;
  bit   t_Directory__io_resp_bits_replacerInfo_channel;
  wire  [2:0] g_Directory__io_resp_bits_replacerInfo_opcode;
  wire  [2:0] i_Directory__io_resp_bits_replacerInfo_opcode;
  logic [2:0] p_Directory__io_resp_bits_replacerInfo_opcode;
  bit   t_Directory__io_resp_bits_replacerInfo_opcode;
  wire  [4:0] g_Directory__io_resp_bits_replacerInfo_reqSource;
  wire  [4:0] i_Directory__io_resp_bits_replacerInfo_reqSource;
  logic [4:0] p_Directory__io_resp_bits_replacerInfo_reqSource;
  bit   t_Directory__io_resp_bits_replacerInfo_reqSource;
  wire  g_Directory__io_resp_bits_replacerInfo_refill_prefetch;
  wire  i_Directory__io_resp_bits_replacerInfo_refill_prefetch;
  logic p_Directory__io_resp_bits_replacerInfo_refill_prefetch;
  bit   t_Directory__io_resp_bits_replacerInfo_refill_prefetch;
  wire  g_Directory__io_replResp_valid;
  wire  i_Directory__io_replResp_valid;
  logic p_Directory__io_replResp_valid;
  bit   t_Directory__io_replResp_valid;
  wire  [30:0] g_Directory__io_replResp_bits_tag;
  wire  [30:0] i_Directory__io_replResp_bits_tag;
  logic [30:0] p_Directory__io_replResp_bits_tag;
  bit   t_Directory__io_replResp_bits_tag;
  wire  [8:0] g_Directory__io_replResp_bits_set;
  wire  [8:0] i_Directory__io_replResp_bits_set;
  logic [8:0] p_Directory__io_replResp_bits_set;
  bit   t_Directory__io_replResp_bits_set;
  wire  [2:0] g_Directory__io_replResp_bits_way;
  wire  [2:0] i_Directory__io_replResp_bits_way;
  logic [2:0] p_Directory__io_replResp_bits_way;
  bit   t_Directory__io_replResp_bits_way;
  wire  g_Directory__io_replResp_bits_meta_dirty;
  wire  i_Directory__io_replResp_bits_meta_dirty;
  logic p_Directory__io_replResp_bits_meta_dirty;
  bit   t_Directory__io_replResp_bits_meta_dirty;
  wire  [1:0] g_Directory__io_replResp_bits_meta_state;
  wire  [1:0] i_Directory__io_replResp_bits_meta_state;
  logic [1:0] p_Directory__io_replResp_bits_meta_state;
  bit   t_Directory__io_replResp_bits_meta_state;
  wire  g_Directory__io_replResp_bits_meta_clients;
  wire  i_Directory__io_replResp_bits_meta_clients;
  logic p_Directory__io_replResp_bits_meta_clients;
  bit   t_Directory__io_replResp_bits_meta_clients;
  wire  [1:0] g_Directory__io_replResp_bits_meta_alias;
  wire  [1:0] i_Directory__io_replResp_bits_meta_alias;
  logic [1:0] p_Directory__io_replResp_bits_meta_alias;
  bit   t_Directory__io_replResp_bits_meta_alias;
  wire  g_Directory__io_replResp_bits_meta_prefetch;
  wire  i_Directory__io_replResp_bits_meta_prefetch;
  logic p_Directory__io_replResp_bits_meta_prefetch;
  bit   t_Directory__io_replResp_bits_meta_prefetch;
  wire  [2:0] g_Directory__io_replResp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory__io_replResp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory__io_replResp_bits_meta_prefetchSrc;
  bit   t_Directory__io_replResp_bits_meta_prefetchSrc;
  wire  g_Directory__io_replResp_bits_meta_accessed;
  wire  i_Directory__io_replResp_bits_meta_accessed;
  logic p_Directory__io_replResp_bits_meta_accessed;
  bit   t_Directory__io_replResp_bits_meta_accessed;
  wire  g_Directory__io_replResp_bits_meta_tagErr;
  wire  i_Directory__io_replResp_bits_meta_tagErr;
  logic p_Directory__io_replResp_bits_meta_tagErr;
  bit   t_Directory__io_replResp_bits_meta_tagErr;
  wire  g_Directory__io_replResp_bits_meta_dataErr;
  wire  i_Directory__io_replResp_bits_meta_dataErr;
  logic p_Directory__io_replResp_bits_meta_dataErr;
  bit   t_Directory__io_replResp_bits_meta_dataErr;
  wire  [7:0] g_Directory__io_replResp_bits_mshrId;
  wire  [7:0] i_Directory__io_replResp_bits_mshrId;
  logic [7:0] p_Directory__io_replResp_bits_mshrId;
  bit   t_Directory__io_replResp_bits_mshrId;
  wire  g_Directory__io_replResp_bits_retry;
  wire  i_Directory__io_replResp_bits_retry;
  logic p_Directory__io_replResp_bits_retry;
  bit   t_Directory__io_replResp_bits_retry;
  wire  g_Directory__io_replResp_bits_error;
  wire  i_Directory__io_replResp_bits_error;
  logic p_Directory__io_replResp_bits_error;
  bit   t_Directory__io_replResp_bits_error;
  wire  g_Directory__boreChildrenBd_bore_ack;
  wire  i_Directory__boreChildrenBd_bore_ack;
  logic p_Directory__boreChildrenBd_bore_ack;
  bit   t_Directory__boreChildrenBd_bore_ack;
  wire  [103:0] g_Directory__boreChildrenBd_bore_outdata;
  wire  [103:0] i_Directory__boreChildrenBd_bore_outdata;
  logic [103:0] p_Directory__boreChildrenBd_bore_outdata;
  bit   t_Directory__boreChildrenBd_bore_outdata;
  Directory u_g_Directory (
    .clock (clock),
    .reset (reset),
    .io_read_ready (g_Directory__io_read_ready),
    .io_read_valid (Directory__io_read_valid),
    .io_read_bits_tag (Directory__io_read_bits_tag),
    .io_read_bits_set (Directory__io_read_bits_set),
    .io_read_bits_wayMask (Directory__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory__io_read_bits_refill),
    .io_read_bits_mshrId (Directory__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory__io_read_bits_cmoWay),
    .io_resp_valid (g_Directory__io_resp_valid),
    .io_resp_bits_hit (g_Directory__io_resp_bits_hit),
    .io_resp_bits_tag (g_Directory__io_resp_bits_tag),
    .io_resp_bits_set (g_Directory__io_resp_bits_set),
    .io_resp_bits_way (g_Directory__io_resp_bits_way),
    .io_resp_bits_meta_dirty (g_Directory__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (g_Directory__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (g_Directory__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (g_Directory__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (g_Directory__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (g_Directory__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (g_Directory__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (g_Directory__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (g_Directory__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (g_Directory__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (g_Directory__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (g_Directory__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (g_Directory__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (g_Directory__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory__io_tagWReq_bits_wtag),
    .io_replResp_valid (g_Directory__io_replResp_valid),
    .io_replResp_bits_tag (g_Directory__io_replResp_bits_tag),
    .io_replResp_bits_set (g_Directory__io_replResp_bits_set),
    .io_replResp_bits_way (g_Directory__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (g_Directory__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (g_Directory__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (g_Directory__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (g_Directory__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (g_Directory__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (g_Directory__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (g_Directory__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (g_Directory__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (g_Directory__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (g_Directory__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (g_Directory__io_replResp_bits_retry),
    .io_replResp_bits_error (g_Directory__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_Directory__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_Directory__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory__sigFromSrams_bore_6_cgen)
  );
  Directory_xs u_i_Directory (
    .clock (clock),
    .reset (reset),
    .io_read_ready (i_Directory__io_read_ready),
    .io_read_valid (Directory__io_read_valid),
    .io_read_bits_tag (Directory__io_read_bits_tag),
    .io_read_bits_set (Directory__io_read_bits_set),
    .io_read_bits_wayMask (Directory__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory__io_read_bits_refill),
    .io_read_bits_mshrId (Directory__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory__io_read_bits_cmoWay),
    .io_resp_valid (i_Directory__io_resp_valid),
    .io_resp_bits_hit (i_Directory__io_resp_bits_hit),
    .io_resp_bits_tag (i_Directory__io_resp_bits_tag),
    .io_resp_bits_set (i_Directory__io_resp_bits_set),
    .io_resp_bits_way (i_Directory__io_resp_bits_way),
    .io_resp_bits_meta_dirty (i_Directory__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (i_Directory__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (i_Directory__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (i_Directory__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (i_Directory__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (i_Directory__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (i_Directory__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (i_Directory__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (i_Directory__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (i_Directory__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (i_Directory__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (i_Directory__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (i_Directory__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (i_Directory__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory__io_tagWReq_bits_wtag),
    .io_replResp_valid (i_Directory__io_replResp_valid),
    .io_replResp_bits_tag (i_Directory__io_replResp_bits_tag),
    .io_replResp_bits_set (i_Directory__io_replResp_bits_set),
    .io_replResp_bits_way (i_Directory__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (i_Directory__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (i_Directory__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (i_Directory__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (i_Directory__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (i_Directory__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (i_Directory__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (i_Directory__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (i_Directory__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (i_Directory__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (i_Directory__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (i_Directory__io_replResp_bits_retry),
    .io_replResp_bits_error (i_Directory__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_Directory__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_Directory__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory__sigFromSrams_bore_6_cgen)
  );
  task automatic drive_Directory();
    Directory__io_read_valid = $urandom % 2;
    Directory__io_read_bits_tag = 31'($urandom_range(0, 3));
    Directory__io_read_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_read_bits_wayMask = rnd(8);
    Directory__io_read_bits_replacerInfo_channel = rnd(3);
    Directory__io_read_bits_replacerInfo_opcode = rnd(3);
    Directory__io_read_bits_replacerInfo_reqSource = rnd(5);
    Directory__io_read_bits_replacerInfo_refill_prefetch = $urandom % 2;
    Directory__io_read_bits_refill = $urandom % 2;
    Directory__io_read_bits_mshrId = rnd(8);
    Directory__io_read_bits_cmoAll = $urandom % 2;
    Directory__io_read_bits_cmoWay = rnd(3);
    Directory__io_metaWReq_valid = (($urandom % 4) == 0);
    Directory__io_metaWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_metaWReq_bits_wayOH = rnd(8);
    Directory__io_metaWReq_bits_wmeta_dirty = $urandom % 2;
    Directory__io_metaWReq_bits_wmeta_state = rnd(2);
    Directory__io_metaWReq_bits_wmeta_clients = $urandom % 2;
    Directory__io_metaWReq_bits_wmeta_alias = rnd(2);
    Directory__io_metaWReq_bits_wmeta_prefetch = $urandom % 2;
    Directory__io_metaWReq_bits_wmeta_prefetchSrc = rnd(3);
    Directory__io_metaWReq_bits_wmeta_accessed = $urandom % 2;
    Directory__io_metaWReq_bits_wmeta_tagErr = $urandom % 2;
    Directory__io_metaWReq_bits_wmeta_dataErr = $urandom % 2;
    Directory__io_tagWReq_valid = (($urandom % 4) == 0);
    Directory__io_tagWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_tagWReq_bits_way = rnd(3);
    Directory__io_tagWReq_bits_wtag = 31'($urandom_range(0, 3));
    Directory__io_msInfo_0_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_0_bits_channel = rnd(3);
    Directory__io_msInfo_0_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_0_bits_way = rnd(3);
    Directory__io_msInfo_0_bits_reqTag = rnd(31);
    Directory__io_msInfo_0_bits_willFree = $urandom % 2;
    Directory__io_msInfo_0_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_0_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_0_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_0_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_0_bits_meta_state = rnd(2);
    Directory__io_msInfo_0_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_0_bits_meta_alias = rnd(2);
    Directory__io_msInfo_0_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_0_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_0_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_0_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_0_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_0_bits_metaTag = rnd(31);
    Directory__io_msInfo_0_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_0_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_0_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_0_bits_param = rnd(3);
    Directory__io_msInfo_0_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_0_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_0_bits_s_release = $urandom % 2;
    Directory__io_msInfo_0_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_0_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_0_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_0_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_0_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_0_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_0_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_0_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_1_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_1_bits_channel = rnd(3);
    Directory__io_msInfo_1_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_1_bits_way = rnd(3);
    Directory__io_msInfo_1_bits_reqTag = rnd(31);
    Directory__io_msInfo_1_bits_willFree = $urandom % 2;
    Directory__io_msInfo_1_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_1_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_1_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_1_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_1_bits_meta_state = rnd(2);
    Directory__io_msInfo_1_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_1_bits_meta_alias = rnd(2);
    Directory__io_msInfo_1_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_1_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_1_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_1_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_1_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_1_bits_metaTag = rnd(31);
    Directory__io_msInfo_1_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_1_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_1_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_1_bits_param = rnd(3);
    Directory__io_msInfo_1_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_1_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_1_bits_s_release = $urandom % 2;
    Directory__io_msInfo_1_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_1_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_1_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_1_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_1_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_1_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_1_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_1_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_2_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_2_bits_channel = rnd(3);
    Directory__io_msInfo_2_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_2_bits_way = rnd(3);
    Directory__io_msInfo_2_bits_reqTag = rnd(31);
    Directory__io_msInfo_2_bits_willFree = $urandom % 2;
    Directory__io_msInfo_2_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_2_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_2_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_2_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_2_bits_meta_state = rnd(2);
    Directory__io_msInfo_2_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_2_bits_meta_alias = rnd(2);
    Directory__io_msInfo_2_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_2_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_2_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_2_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_2_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_2_bits_metaTag = rnd(31);
    Directory__io_msInfo_2_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_2_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_2_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_2_bits_param = rnd(3);
    Directory__io_msInfo_2_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_2_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_2_bits_s_release = $urandom % 2;
    Directory__io_msInfo_2_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_2_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_2_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_2_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_2_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_2_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_2_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_2_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_3_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_3_bits_channel = rnd(3);
    Directory__io_msInfo_3_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_3_bits_way = rnd(3);
    Directory__io_msInfo_3_bits_reqTag = rnd(31);
    Directory__io_msInfo_3_bits_willFree = $urandom % 2;
    Directory__io_msInfo_3_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_3_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_3_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_3_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_3_bits_meta_state = rnd(2);
    Directory__io_msInfo_3_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_3_bits_meta_alias = rnd(2);
    Directory__io_msInfo_3_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_3_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_3_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_3_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_3_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_3_bits_metaTag = rnd(31);
    Directory__io_msInfo_3_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_3_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_3_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_3_bits_param = rnd(3);
    Directory__io_msInfo_3_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_3_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_3_bits_s_release = $urandom % 2;
    Directory__io_msInfo_3_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_3_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_3_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_3_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_3_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_3_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_3_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_3_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_4_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_4_bits_channel = rnd(3);
    Directory__io_msInfo_4_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_4_bits_way = rnd(3);
    Directory__io_msInfo_4_bits_reqTag = rnd(31);
    Directory__io_msInfo_4_bits_willFree = $urandom % 2;
    Directory__io_msInfo_4_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_4_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_4_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_4_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_4_bits_meta_state = rnd(2);
    Directory__io_msInfo_4_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_4_bits_meta_alias = rnd(2);
    Directory__io_msInfo_4_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_4_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_4_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_4_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_4_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_4_bits_metaTag = rnd(31);
    Directory__io_msInfo_4_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_4_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_4_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_4_bits_param = rnd(3);
    Directory__io_msInfo_4_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_4_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_4_bits_s_release = $urandom % 2;
    Directory__io_msInfo_4_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_4_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_4_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_4_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_4_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_4_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_4_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_4_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_5_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_5_bits_channel = rnd(3);
    Directory__io_msInfo_5_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_5_bits_way = rnd(3);
    Directory__io_msInfo_5_bits_reqTag = rnd(31);
    Directory__io_msInfo_5_bits_willFree = $urandom % 2;
    Directory__io_msInfo_5_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_5_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_5_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_5_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_5_bits_meta_state = rnd(2);
    Directory__io_msInfo_5_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_5_bits_meta_alias = rnd(2);
    Directory__io_msInfo_5_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_5_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_5_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_5_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_5_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_5_bits_metaTag = rnd(31);
    Directory__io_msInfo_5_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_5_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_5_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_5_bits_param = rnd(3);
    Directory__io_msInfo_5_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_5_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_5_bits_s_release = $urandom % 2;
    Directory__io_msInfo_5_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_5_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_5_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_5_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_5_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_5_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_5_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_5_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_6_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_6_bits_channel = rnd(3);
    Directory__io_msInfo_6_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_6_bits_way = rnd(3);
    Directory__io_msInfo_6_bits_reqTag = rnd(31);
    Directory__io_msInfo_6_bits_willFree = $urandom % 2;
    Directory__io_msInfo_6_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_6_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_6_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_6_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_6_bits_meta_state = rnd(2);
    Directory__io_msInfo_6_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_6_bits_meta_alias = rnd(2);
    Directory__io_msInfo_6_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_6_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_6_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_6_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_6_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_6_bits_metaTag = rnd(31);
    Directory__io_msInfo_6_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_6_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_6_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_6_bits_param = rnd(3);
    Directory__io_msInfo_6_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_6_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_6_bits_s_release = $urandom % 2;
    Directory__io_msInfo_6_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_6_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_6_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_6_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_6_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_6_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_6_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_6_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_7_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_7_bits_channel = rnd(3);
    Directory__io_msInfo_7_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_7_bits_way = rnd(3);
    Directory__io_msInfo_7_bits_reqTag = rnd(31);
    Directory__io_msInfo_7_bits_willFree = $urandom % 2;
    Directory__io_msInfo_7_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_7_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_7_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_7_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_7_bits_meta_state = rnd(2);
    Directory__io_msInfo_7_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_7_bits_meta_alias = rnd(2);
    Directory__io_msInfo_7_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_7_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_7_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_7_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_7_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_7_bits_metaTag = rnd(31);
    Directory__io_msInfo_7_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_7_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_7_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_7_bits_param = rnd(3);
    Directory__io_msInfo_7_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_7_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_7_bits_s_release = $urandom % 2;
    Directory__io_msInfo_7_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_7_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_7_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_7_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_7_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_7_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_7_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_7_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_8_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_8_bits_channel = rnd(3);
    Directory__io_msInfo_8_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_8_bits_way = rnd(3);
    Directory__io_msInfo_8_bits_reqTag = rnd(31);
    Directory__io_msInfo_8_bits_willFree = $urandom % 2;
    Directory__io_msInfo_8_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_8_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_8_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_8_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_8_bits_meta_state = rnd(2);
    Directory__io_msInfo_8_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_8_bits_meta_alias = rnd(2);
    Directory__io_msInfo_8_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_8_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_8_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_8_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_8_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_8_bits_metaTag = rnd(31);
    Directory__io_msInfo_8_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_8_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_8_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_8_bits_param = rnd(3);
    Directory__io_msInfo_8_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_8_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_8_bits_s_release = $urandom % 2;
    Directory__io_msInfo_8_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_8_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_8_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_8_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_8_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_8_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_8_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_8_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_9_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_9_bits_channel = rnd(3);
    Directory__io_msInfo_9_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_9_bits_way = rnd(3);
    Directory__io_msInfo_9_bits_reqTag = rnd(31);
    Directory__io_msInfo_9_bits_willFree = $urandom % 2;
    Directory__io_msInfo_9_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_9_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_9_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_9_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_9_bits_meta_state = rnd(2);
    Directory__io_msInfo_9_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_9_bits_meta_alias = rnd(2);
    Directory__io_msInfo_9_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_9_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_9_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_9_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_9_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_9_bits_metaTag = rnd(31);
    Directory__io_msInfo_9_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_9_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_9_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_9_bits_param = rnd(3);
    Directory__io_msInfo_9_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_9_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_9_bits_s_release = $urandom % 2;
    Directory__io_msInfo_9_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_9_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_9_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_9_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_9_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_9_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_9_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_9_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_10_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_10_bits_channel = rnd(3);
    Directory__io_msInfo_10_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_10_bits_way = rnd(3);
    Directory__io_msInfo_10_bits_reqTag = rnd(31);
    Directory__io_msInfo_10_bits_willFree = $urandom % 2;
    Directory__io_msInfo_10_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_10_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_10_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_10_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_10_bits_meta_state = rnd(2);
    Directory__io_msInfo_10_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_10_bits_meta_alias = rnd(2);
    Directory__io_msInfo_10_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_10_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_10_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_10_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_10_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_10_bits_metaTag = rnd(31);
    Directory__io_msInfo_10_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_10_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_10_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_10_bits_param = rnd(3);
    Directory__io_msInfo_10_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_10_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_10_bits_s_release = $urandom % 2;
    Directory__io_msInfo_10_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_10_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_10_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_10_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_10_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_10_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_10_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_10_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_11_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_11_bits_channel = rnd(3);
    Directory__io_msInfo_11_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_11_bits_way = rnd(3);
    Directory__io_msInfo_11_bits_reqTag = rnd(31);
    Directory__io_msInfo_11_bits_willFree = $urandom % 2;
    Directory__io_msInfo_11_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_11_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_11_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_11_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_11_bits_meta_state = rnd(2);
    Directory__io_msInfo_11_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_11_bits_meta_alias = rnd(2);
    Directory__io_msInfo_11_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_11_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_11_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_11_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_11_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_11_bits_metaTag = rnd(31);
    Directory__io_msInfo_11_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_11_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_11_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_11_bits_param = rnd(3);
    Directory__io_msInfo_11_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_11_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_11_bits_s_release = $urandom % 2;
    Directory__io_msInfo_11_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_11_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_11_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_11_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_11_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_11_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_11_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_11_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_12_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_12_bits_channel = rnd(3);
    Directory__io_msInfo_12_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_12_bits_way = rnd(3);
    Directory__io_msInfo_12_bits_reqTag = rnd(31);
    Directory__io_msInfo_12_bits_willFree = $urandom % 2;
    Directory__io_msInfo_12_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_12_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_12_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_12_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_12_bits_meta_state = rnd(2);
    Directory__io_msInfo_12_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_12_bits_meta_alias = rnd(2);
    Directory__io_msInfo_12_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_12_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_12_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_12_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_12_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_12_bits_metaTag = rnd(31);
    Directory__io_msInfo_12_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_12_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_12_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_12_bits_param = rnd(3);
    Directory__io_msInfo_12_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_12_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_12_bits_s_release = $urandom % 2;
    Directory__io_msInfo_12_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_12_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_12_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_12_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_12_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_12_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_12_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_12_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_13_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_13_bits_channel = rnd(3);
    Directory__io_msInfo_13_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_13_bits_way = rnd(3);
    Directory__io_msInfo_13_bits_reqTag = rnd(31);
    Directory__io_msInfo_13_bits_willFree = $urandom % 2;
    Directory__io_msInfo_13_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_13_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_13_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_13_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_13_bits_meta_state = rnd(2);
    Directory__io_msInfo_13_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_13_bits_meta_alias = rnd(2);
    Directory__io_msInfo_13_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_13_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_13_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_13_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_13_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_13_bits_metaTag = rnd(31);
    Directory__io_msInfo_13_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_13_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_13_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_13_bits_param = rnd(3);
    Directory__io_msInfo_13_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_13_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_13_bits_s_release = $urandom % 2;
    Directory__io_msInfo_13_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_13_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_13_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_13_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_13_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_13_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_13_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_13_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_14_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_14_bits_channel = rnd(3);
    Directory__io_msInfo_14_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_14_bits_way = rnd(3);
    Directory__io_msInfo_14_bits_reqTag = rnd(31);
    Directory__io_msInfo_14_bits_willFree = $urandom % 2;
    Directory__io_msInfo_14_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_14_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_14_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_14_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_14_bits_meta_state = rnd(2);
    Directory__io_msInfo_14_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_14_bits_meta_alias = rnd(2);
    Directory__io_msInfo_14_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_14_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_14_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_14_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_14_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_14_bits_metaTag = rnd(31);
    Directory__io_msInfo_14_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_14_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_14_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_14_bits_param = rnd(3);
    Directory__io_msInfo_14_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_14_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_14_bits_s_release = $urandom % 2;
    Directory__io_msInfo_14_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_14_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_14_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_14_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_14_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_14_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_14_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_14_bits_releaseToClean = $urandom % 2;
    Directory__io_msInfo_15_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory__io_msInfo_15_bits_channel = rnd(3);
    Directory__io_msInfo_15_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory__io_msInfo_15_bits_way = rnd(3);
    Directory__io_msInfo_15_bits_reqTag = rnd(31);
    Directory__io_msInfo_15_bits_willFree = $urandom % 2;
    Directory__io_msInfo_15_bits_aliasTask = $urandom % 2;
    Directory__io_msInfo_15_bits_needRelease = $urandom % 2;
    Directory__io_msInfo_15_bits_blockRefill = $urandom % 2;
    Directory__io_msInfo_15_bits_meta_dirty = $urandom % 2;
    Directory__io_msInfo_15_bits_meta_state = rnd(2);
    Directory__io_msInfo_15_bits_meta_clients = $urandom % 2;
    Directory__io_msInfo_15_bits_meta_alias = rnd(2);
    Directory__io_msInfo_15_bits_meta_prefetch = $urandom % 2;
    Directory__io_msInfo_15_bits_meta_prefetchSrc = rnd(3);
    Directory__io_msInfo_15_bits_meta_accessed = $urandom % 2;
    Directory__io_msInfo_15_bits_meta_tagErr = $urandom % 2;
    Directory__io_msInfo_15_bits_meta_dataErr = $urandom % 2;
    Directory__io_msInfo_15_bits_metaTag = rnd(31);
    Directory__io_msInfo_15_bits_dirHit = $urandom % 2;
    Directory__io_msInfo_15_bits_isAcqOrPrefetch = $urandom % 2;
    Directory__io_msInfo_15_bits_isPrefetch = $urandom % 2;
    Directory__io_msInfo_15_bits_param = rnd(3);
    Directory__io_msInfo_15_bits_mergeA = $urandom % 2;
    Directory__io_msInfo_15_bits_w_grantfirst = $urandom % 2;
    Directory__io_msInfo_15_bits_s_release = $urandom % 2;
    Directory__io_msInfo_15_bits_s_refill = $urandom % 2;
    Directory__io_msInfo_15_bits_s_cmoresp = $urandom % 2;
    Directory__io_msInfo_15_bits_s_cmometaw = $urandom % 2;
    Directory__io_msInfo_15_bits_w_releaseack = $urandom % 2;
    Directory__io_msInfo_15_bits_w_replResp = $urandom % 2;
    Directory__io_msInfo_15_bits_w_rprobeacklast = $urandom % 2;
    Directory__io_msInfo_15_bits_replaceData = $urandom % 2;
    Directory__io_msInfo_15_bits_releaseToClean = $urandom % 2;
    Directory__boreChildrenBd_bore_array = rnd(4);
    Directory__boreChildrenBd_bore_all = $urandom % 2;
    Directory__boreChildrenBd_bore_req = $urandom % 2;
    Directory__boreChildrenBd_bore_writeen = $urandom % 2;
    Directory__boreChildrenBd_bore_be = rnd(8);
    Directory__boreChildrenBd_bore_addr = rnd(10);
    Directory__boreChildrenBd_bore_indata = rnd(104);
    Directory__boreChildrenBd_bore_readen = $urandom % 2;
    Directory__boreChildrenBd_bore_addr_rd = rnd(10);
    Directory__sigFromSrams_bore_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_cgen = $urandom % 2;
    Directory__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_1_cgen = $urandom % 2;
    Directory__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_2_cgen = $urandom % 2;
    Directory__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_3_cgen = $urandom % 2;
    Directory__sigFromSrams_bore_4_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_4_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_4_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_4_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_4_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_4_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_4_cgen = $urandom % 2;
    Directory__sigFromSrams_bore_5_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_5_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_5_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_5_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_5_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_5_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_5_cgen = $urandom % 2;
    Directory__sigFromSrams_bore_6_ram_hold = $urandom % 2;
    Directory__sigFromSrams_bore_6_ram_bypass = $urandom % 2;
    Directory__sigFromSrams_bore_6_ram_bp_clken = $urandom % 2;
    Directory__sigFromSrams_bore_6_ram_aux_clk = 1'b0;
    Directory__sigFromSrams_bore_6_ram_aux_ckbp = 1'b0;
    Directory__sigFromSrams_bore_6_ram_mcp_hold = $urandom % 2;
    Directory__sigFromSrams_bore_6_cgen = $urandom % 2;
  endtask
  task automatic check_Directory();
    checks++;
    if (g_Directory__io_read_ready !== i_Directory__io_read_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_read_ready g=%h i=%h", cyc, g_Directory__io_read_ready, i_Directory__io_read_ready);
    end
    if (g_Directory__io_read_ready !== p_Directory__io_read_ready) t_Directory__io_read_ready = 1'b1;
    p_Directory__io_read_ready = g_Directory__io_read_ready;
    checks++;
    if (g_Directory__io_resp_valid !== i_Directory__io_resp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_valid g=%h i=%h", cyc, g_Directory__io_resp_valid, i_Directory__io_resp_valid);
    end
    if (g_Directory__io_resp_valid !== p_Directory__io_resp_valid) t_Directory__io_resp_valid = 1'b1;
    p_Directory__io_resp_valid = g_Directory__io_resp_valid;
    checks++;
    if (g_Directory__io_resp_bits_hit !== i_Directory__io_resp_bits_hit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_hit g=%h i=%h", cyc, g_Directory__io_resp_bits_hit, i_Directory__io_resp_bits_hit);
    end
    if (g_Directory__io_resp_bits_hit !== p_Directory__io_resp_bits_hit) t_Directory__io_resp_bits_hit = 1'b1;
    p_Directory__io_resp_bits_hit = g_Directory__io_resp_bits_hit;
    checks++;
    if (g_Directory__io_resp_bits_tag !== i_Directory__io_resp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_tag g=%h i=%h", cyc, g_Directory__io_resp_bits_tag, i_Directory__io_resp_bits_tag);
    end
    if (g_Directory__io_resp_bits_tag !== p_Directory__io_resp_bits_tag) t_Directory__io_resp_bits_tag = 1'b1;
    p_Directory__io_resp_bits_tag = g_Directory__io_resp_bits_tag;
    checks++;
    if (g_Directory__io_resp_bits_set !== i_Directory__io_resp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_set g=%h i=%h", cyc, g_Directory__io_resp_bits_set, i_Directory__io_resp_bits_set);
    end
    if (g_Directory__io_resp_bits_set !== p_Directory__io_resp_bits_set) t_Directory__io_resp_bits_set = 1'b1;
    p_Directory__io_resp_bits_set = g_Directory__io_resp_bits_set;
    checks++;
    if (g_Directory__io_resp_bits_way !== i_Directory__io_resp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_way g=%h i=%h", cyc, g_Directory__io_resp_bits_way, i_Directory__io_resp_bits_way);
    end
    if (g_Directory__io_resp_bits_way !== p_Directory__io_resp_bits_way) t_Directory__io_resp_bits_way = 1'b1;
    p_Directory__io_resp_bits_way = g_Directory__io_resp_bits_way;
    checks++;
    if (g_Directory__io_resp_bits_meta_dirty !== i_Directory__io_resp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_dirty g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_dirty, i_Directory__io_resp_bits_meta_dirty);
    end
    if (g_Directory__io_resp_bits_meta_dirty !== p_Directory__io_resp_bits_meta_dirty) t_Directory__io_resp_bits_meta_dirty = 1'b1;
    p_Directory__io_resp_bits_meta_dirty = g_Directory__io_resp_bits_meta_dirty;
    checks++;
    if (g_Directory__io_resp_bits_meta_state !== i_Directory__io_resp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_state g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_state, i_Directory__io_resp_bits_meta_state);
    end
    if (g_Directory__io_resp_bits_meta_state !== p_Directory__io_resp_bits_meta_state) t_Directory__io_resp_bits_meta_state = 1'b1;
    p_Directory__io_resp_bits_meta_state = g_Directory__io_resp_bits_meta_state;
    checks++;
    if (g_Directory__io_resp_bits_meta_clients !== i_Directory__io_resp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_clients g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_clients, i_Directory__io_resp_bits_meta_clients);
    end
    if (g_Directory__io_resp_bits_meta_clients !== p_Directory__io_resp_bits_meta_clients) t_Directory__io_resp_bits_meta_clients = 1'b1;
    p_Directory__io_resp_bits_meta_clients = g_Directory__io_resp_bits_meta_clients;
    checks++;
    if (g_Directory__io_resp_bits_meta_alias !== i_Directory__io_resp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_alias g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_alias, i_Directory__io_resp_bits_meta_alias);
    end
    if (g_Directory__io_resp_bits_meta_alias !== p_Directory__io_resp_bits_meta_alias) t_Directory__io_resp_bits_meta_alias = 1'b1;
    p_Directory__io_resp_bits_meta_alias = g_Directory__io_resp_bits_meta_alias;
    checks++;
    if (g_Directory__io_resp_bits_meta_prefetch !== i_Directory__io_resp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_prefetch, i_Directory__io_resp_bits_meta_prefetch);
    end
    if (g_Directory__io_resp_bits_meta_prefetch !== p_Directory__io_resp_bits_meta_prefetch) t_Directory__io_resp_bits_meta_prefetch = 1'b1;
    p_Directory__io_resp_bits_meta_prefetch = g_Directory__io_resp_bits_meta_prefetch;
    checks++;
    if (g_Directory__io_resp_bits_meta_prefetchSrc !== i_Directory__io_resp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_prefetchSrc, i_Directory__io_resp_bits_meta_prefetchSrc);
    end
    if (g_Directory__io_resp_bits_meta_prefetchSrc !== p_Directory__io_resp_bits_meta_prefetchSrc) t_Directory__io_resp_bits_meta_prefetchSrc = 1'b1;
    p_Directory__io_resp_bits_meta_prefetchSrc = g_Directory__io_resp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory__io_resp_bits_meta_accessed !== i_Directory__io_resp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_accessed g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_accessed, i_Directory__io_resp_bits_meta_accessed);
    end
    if (g_Directory__io_resp_bits_meta_accessed !== p_Directory__io_resp_bits_meta_accessed) t_Directory__io_resp_bits_meta_accessed = 1'b1;
    p_Directory__io_resp_bits_meta_accessed = g_Directory__io_resp_bits_meta_accessed;
    checks++;
    if (g_Directory__io_resp_bits_meta_tagErr !== i_Directory__io_resp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_tagErr, i_Directory__io_resp_bits_meta_tagErr);
    end
    if (g_Directory__io_resp_bits_meta_tagErr !== p_Directory__io_resp_bits_meta_tagErr) t_Directory__io_resp_bits_meta_tagErr = 1'b1;
    p_Directory__io_resp_bits_meta_tagErr = g_Directory__io_resp_bits_meta_tagErr;
    checks++;
    if (g_Directory__io_resp_bits_meta_dataErr !== i_Directory__io_resp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory__io_resp_bits_meta_dataErr, i_Directory__io_resp_bits_meta_dataErr);
    end
    if (g_Directory__io_resp_bits_meta_dataErr !== p_Directory__io_resp_bits_meta_dataErr) t_Directory__io_resp_bits_meta_dataErr = 1'b1;
    p_Directory__io_resp_bits_meta_dataErr = g_Directory__io_resp_bits_meta_dataErr;
    checks++;
    if (g_Directory__io_resp_bits_error !== i_Directory__io_resp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_error g=%h i=%h", cyc, g_Directory__io_resp_bits_error, i_Directory__io_resp_bits_error);
    end
    if (g_Directory__io_resp_bits_error !== p_Directory__io_resp_bits_error) t_Directory__io_resp_bits_error = 1'b1;
    p_Directory__io_resp_bits_error = g_Directory__io_resp_bits_error;
    checks++;
    if (g_Directory__io_resp_bits_replacerInfo_channel !== i_Directory__io_resp_bits_replacerInfo_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_replacerInfo_channel g=%h i=%h", cyc, g_Directory__io_resp_bits_replacerInfo_channel, i_Directory__io_resp_bits_replacerInfo_channel);
    end
    if (g_Directory__io_resp_bits_replacerInfo_channel !== p_Directory__io_resp_bits_replacerInfo_channel) t_Directory__io_resp_bits_replacerInfo_channel = 1'b1;
    p_Directory__io_resp_bits_replacerInfo_channel = g_Directory__io_resp_bits_replacerInfo_channel;
    checks++;
    if (g_Directory__io_resp_bits_replacerInfo_opcode !== i_Directory__io_resp_bits_replacerInfo_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_replacerInfo_opcode g=%h i=%h", cyc, g_Directory__io_resp_bits_replacerInfo_opcode, i_Directory__io_resp_bits_replacerInfo_opcode);
    end
    if (g_Directory__io_resp_bits_replacerInfo_opcode !== p_Directory__io_resp_bits_replacerInfo_opcode) t_Directory__io_resp_bits_replacerInfo_opcode = 1'b1;
    p_Directory__io_resp_bits_replacerInfo_opcode = g_Directory__io_resp_bits_replacerInfo_opcode;
    checks++;
    if (g_Directory__io_resp_bits_replacerInfo_reqSource !== i_Directory__io_resp_bits_replacerInfo_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_replacerInfo_reqSource g=%h i=%h", cyc, g_Directory__io_resp_bits_replacerInfo_reqSource, i_Directory__io_resp_bits_replacerInfo_reqSource);
    end
    if (g_Directory__io_resp_bits_replacerInfo_reqSource !== p_Directory__io_resp_bits_replacerInfo_reqSource) t_Directory__io_resp_bits_replacerInfo_reqSource = 1'b1;
    p_Directory__io_resp_bits_replacerInfo_reqSource = g_Directory__io_resp_bits_replacerInfo_reqSource;
    checks++;
    if (g_Directory__io_resp_bits_replacerInfo_refill_prefetch !== i_Directory__io_resp_bits_replacerInfo_refill_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_resp_bits_replacerInfo_refill_prefetch g=%h i=%h", cyc, g_Directory__io_resp_bits_replacerInfo_refill_prefetch, i_Directory__io_resp_bits_replacerInfo_refill_prefetch);
    end
    if (g_Directory__io_resp_bits_replacerInfo_refill_prefetch !== p_Directory__io_resp_bits_replacerInfo_refill_prefetch) t_Directory__io_resp_bits_replacerInfo_refill_prefetch = 1'b1;
    p_Directory__io_resp_bits_replacerInfo_refill_prefetch = g_Directory__io_resp_bits_replacerInfo_refill_prefetch;
    checks++;
    if (g_Directory__io_replResp_valid !== i_Directory__io_replResp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_valid g=%h i=%h", cyc, g_Directory__io_replResp_valid, i_Directory__io_replResp_valid);
    end
    if (g_Directory__io_replResp_valid !== p_Directory__io_replResp_valid) t_Directory__io_replResp_valid = 1'b1;
    p_Directory__io_replResp_valid = g_Directory__io_replResp_valid;
    checks++;
    if (g_Directory__io_replResp_bits_tag !== i_Directory__io_replResp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_tag g=%h i=%h", cyc, g_Directory__io_replResp_bits_tag, i_Directory__io_replResp_bits_tag);
    end
    if (g_Directory__io_replResp_bits_tag !== p_Directory__io_replResp_bits_tag) t_Directory__io_replResp_bits_tag = 1'b1;
    p_Directory__io_replResp_bits_tag = g_Directory__io_replResp_bits_tag;
    checks++;
    if (g_Directory__io_replResp_bits_set !== i_Directory__io_replResp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_set g=%h i=%h", cyc, g_Directory__io_replResp_bits_set, i_Directory__io_replResp_bits_set);
    end
    if (g_Directory__io_replResp_bits_set !== p_Directory__io_replResp_bits_set) t_Directory__io_replResp_bits_set = 1'b1;
    p_Directory__io_replResp_bits_set = g_Directory__io_replResp_bits_set;
    checks++;
    if (g_Directory__io_replResp_bits_way !== i_Directory__io_replResp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_way g=%h i=%h", cyc, g_Directory__io_replResp_bits_way, i_Directory__io_replResp_bits_way);
    end
    if (g_Directory__io_replResp_bits_way !== p_Directory__io_replResp_bits_way) t_Directory__io_replResp_bits_way = 1'b1;
    p_Directory__io_replResp_bits_way = g_Directory__io_replResp_bits_way;
    checks++;
    if (g_Directory__io_replResp_bits_meta_dirty !== i_Directory__io_replResp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_dirty g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_dirty, i_Directory__io_replResp_bits_meta_dirty);
    end
    if (g_Directory__io_replResp_bits_meta_dirty !== p_Directory__io_replResp_bits_meta_dirty) t_Directory__io_replResp_bits_meta_dirty = 1'b1;
    p_Directory__io_replResp_bits_meta_dirty = g_Directory__io_replResp_bits_meta_dirty;
    checks++;
    if (g_Directory__io_replResp_bits_meta_state !== i_Directory__io_replResp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_state g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_state, i_Directory__io_replResp_bits_meta_state);
    end
    if (g_Directory__io_replResp_bits_meta_state !== p_Directory__io_replResp_bits_meta_state) t_Directory__io_replResp_bits_meta_state = 1'b1;
    p_Directory__io_replResp_bits_meta_state = g_Directory__io_replResp_bits_meta_state;
    checks++;
    if (g_Directory__io_replResp_bits_meta_clients !== i_Directory__io_replResp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_clients g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_clients, i_Directory__io_replResp_bits_meta_clients);
    end
    if (g_Directory__io_replResp_bits_meta_clients !== p_Directory__io_replResp_bits_meta_clients) t_Directory__io_replResp_bits_meta_clients = 1'b1;
    p_Directory__io_replResp_bits_meta_clients = g_Directory__io_replResp_bits_meta_clients;
    checks++;
    if (g_Directory__io_replResp_bits_meta_alias !== i_Directory__io_replResp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_alias g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_alias, i_Directory__io_replResp_bits_meta_alias);
    end
    if (g_Directory__io_replResp_bits_meta_alias !== p_Directory__io_replResp_bits_meta_alias) t_Directory__io_replResp_bits_meta_alias = 1'b1;
    p_Directory__io_replResp_bits_meta_alias = g_Directory__io_replResp_bits_meta_alias;
    checks++;
    if (g_Directory__io_replResp_bits_meta_prefetch !== i_Directory__io_replResp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_prefetch, i_Directory__io_replResp_bits_meta_prefetch);
    end
    if (g_Directory__io_replResp_bits_meta_prefetch !== p_Directory__io_replResp_bits_meta_prefetch) t_Directory__io_replResp_bits_meta_prefetch = 1'b1;
    p_Directory__io_replResp_bits_meta_prefetch = g_Directory__io_replResp_bits_meta_prefetch;
    checks++;
    if (g_Directory__io_replResp_bits_meta_prefetchSrc !== i_Directory__io_replResp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_prefetchSrc, i_Directory__io_replResp_bits_meta_prefetchSrc);
    end
    if (g_Directory__io_replResp_bits_meta_prefetchSrc !== p_Directory__io_replResp_bits_meta_prefetchSrc) t_Directory__io_replResp_bits_meta_prefetchSrc = 1'b1;
    p_Directory__io_replResp_bits_meta_prefetchSrc = g_Directory__io_replResp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory__io_replResp_bits_meta_accessed !== i_Directory__io_replResp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_accessed g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_accessed, i_Directory__io_replResp_bits_meta_accessed);
    end
    if (g_Directory__io_replResp_bits_meta_accessed !== p_Directory__io_replResp_bits_meta_accessed) t_Directory__io_replResp_bits_meta_accessed = 1'b1;
    p_Directory__io_replResp_bits_meta_accessed = g_Directory__io_replResp_bits_meta_accessed;
    checks++;
    if (g_Directory__io_replResp_bits_meta_tagErr !== i_Directory__io_replResp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_tagErr, i_Directory__io_replResp_bits_meta_tagErr);
    end
    if (g_Directory__io_replResp_bits_meta_tagErr !== p_Directory__io_replResp_bits_meta_tagErr) t_Directory__io_replResp_bits_meta_tagErr = 1'b1;
    p_Directory__io_replResp_bits_meta_tagErr = g_Directory__io_replResp_bits_meta_tagErr;
    checks++;
    if (g_Directory__io_replResp_bits_meta_dataErr !== i_Directory__io_replResp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory__io_replResp_bits_meta_dataErr, i_Directory__io_replResp_bits_meta_dataErr);
    end
    if (g_Directory__io_replResp_bits_meta_dataErr !== p_Directory__io_replResp_bits_meta_dataErr) t_Directory__io_replResp_bits_meta_dataErr = 1'b1;
    p_Directory__io_replResp_bits_meta_dataErr = g_Directory__io_replResp_bits_meta_dataErr;
    checks++;
    if (g_Directory__io_replResp_bits_mshrId !== i_Directory__io_replResp_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_mshrId g=%h i=%h", cyc, g_Directory__io_replResp_bits_mshrId, i_Directory__io_replResp_bits_mshrId);
    end
    if (g_Directory__io_replResp_bits_mshrId !== p_Directory__io_replResp_bits_mshrId) t_Directory__io_replResp_bits_mshrId = 1'b1;
    p_Directory__io_replResp_bits_mshrId = g_Directory__io_replResp_bits_mshrId;
    checks++;
    if (g_Directory__io_replResp_bits_retry !== i_Directory__io_replResp_bits_retry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_retry g=%h i=%h", cyc, g_Directory__io_replResp_bits_retry, i_Directory__io_replResp_bits_retry);
    end
    if (g_Directory__io_replResp_bits_retry !== p_Directory__io_replResp_bits_retry) t_Directory__io_replResp_bits_retry = 1'b1;
    p_Directory__io_replResp_bits_retry = g_Directory__io_replResp_bits_retry;
    checks++;
    if (g_Directory__io_replResp_bits_error !== i_Directory__io_replResp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.io_replResp_bits_error g=%h i=%h", cyc, g_Directory__io_replResp_bits_error, i_Directory__io_replResp_bits_error);
    end
    if (g_Directory__io_replResp_bits_error !== p_Directory__io_replResp_bits_error) t_Directory__io_replResp_bits_error = 1'b1;
    p_Directory__io_replResp_bits_error = g_Directory__io_replResp_bits_error;
    checks++;
    if (g_Directory__boreChildrenBd_bore_ack !== i_Directory__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_Directory__boreChildrenBd_bore_ack, i_Directory__boreChildrenBd_bore_ack);
    end
    if (g_Directory__boreChildrenBd_bore_ack !== p_Directory__boreChildrenBd_bore_ack) t_Directory__boreChildrenBd_bore_ack = 1'b1;
    p_Directory__boreChildrenBd_bore_ack = g_Directory__boreChildrenBd_bore_ack;
    checks++;
    if (g_Directory__boreChildrenBd_bore_outdata !== i_Directory__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_Directory__boreChildrenBd_bore_outdata, i_Directory__boreChildrenBd_bore_outdata);
    end
    if (g_Directory__boreChildrenBd_bore_outdata !== p_Directory__boreChildrenBd_bore_outdata) t_Directory__boreChildrenBd_bore_outdata = 1'b1;
    p_Directory__boreChildrenBd_bore_outdata = g_Directory__boreChildrenBd_bore_outdata;
  endtask
  longint cov_Directory_hit = 0;
  longint cov_Directory_miss = 0;
  longint cov_Directory_repl = 0;
  longint cov_Directory_retry = 0;
  longint cov_Directory_err = 0;
  longint cov_Directory_pselUp = 0;
  longint cov_Directory_pselDn = 0;
  longint cov_Directory_initDone = 0;
  task automatic cover_Directory();
    if (u_g_Directory.io_resp_valid && u_g_Directory.io_resp_bits_hit) cov_Directory_hit++;
    if (u_g_Directory.io_resp_valid && !u_g_Directory.io_resp_bits_hit) cov_Directory_miss++;
    if (u_g_Directory.io_replResp_valid) cov_Directory_repl++;
    if (u_g_Directory.io_replResp_valid && u_g_Directory.io_replResp_bits_retry) cov_Directory_retry++;
    if (u_g_Directory.io_resp_valid && u_g_Directory.io_resp_bits_error) cov_Directory_err++;
    if (u_g_Directory.PSEL > 10'h200) cov_Directory_pselUp++;
    if (u_g_Directory.refillReqValid_s3 && u_g_Directory.match_b && !u_g_Directory.hit_s3) cov_Directory_pselDn++;
    if (u_g_Directory.resetFinish) cov_Directory_initDone++;
  endtask
  task automatic preinit_Directory();
    foreach (u_g_Directory.tagArray.array_0_0_0.array.array.array_14_ext.ram[e]) u_g_Directory.tagArray.array_0_0_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory.tagArray.array_0_0_1.array.array.array_14_ext.ram[e]) u_g_Directory.tagArray.array_0_0_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory.tagArray.array_0_1_0.array.array.array_14_ext.ram[e]) u_g_Directory.tagArray.array_0_1_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory.tagArray.array_0_1_1.array.array.array_14_ext.ram[e]) u_g_Directory.tagArray.array_0_1_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory.metaArray.array.array.array_15_ext.ram[e]) u_g_Directory.metaArray.array.array.array_15_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory.replacer_sram_opt.array.array.array_16_ext.ram[e]) u_g_Directory.replacer_sram_opt.array.array.array_16_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory.origin_bit_opt.array.array.array_17_ext.ram[e]) u_g_Directory.origin_bit_opt.array.array.array_17_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
  endtask
  task automatic sync_Directory();
    u_i_Directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g_Directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i_Directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory.tagArray.array_0_0_0.u_core.rdataReg = u_g_Directory.tagArray.array_0_0_0.rdataReg;
    #0 release u_i_Directory.tagArray.array_0_0_0.u_core.rdataReg;
    u_i_Directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g_Directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i_Directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory.tagArray.array_0_0_1.u_core.rdataReg = u_g_Directory.tagArray.array_0_0_1.rdataReg;
    #0 release u_i_Directory.tagArray.array_0_0_1.u_core.rdataReg;
    u_i_Directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g_Directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i_Directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory.tagArray.array_0_1_0.u_core.rdataReg = u_g_Directory.tagArray.array_0_1_0.rdataReg;
    #0 release u_i_Directory.tagArray.array_0_1_0.u_core.rdataReg;
    u_i_Directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g_Directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i_Directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory.tagArray.array_0_1_1.u_core.rdataReg = u_g_Directory.tagArray.array_0_1_1.rdataReg;
    #0 release u_i_Directory.tagArray.array_0_1_1.u_core.rdataReg;
    u_i_Directory.metaArray.array.array.array_15_ext.ram = u_g_Directory.metaArray.array.array.array_15_ext.ram;
    u_i_Directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g_Directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i_Directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g_Directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i_Directory.metaArray.u_core.rdataReg = u_g_Directory.metaArray.rdataReg;
    #0 release u_i_Directory.metaArray.u_core.rdataReg;
    u_i_Directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g_Directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i_Directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g_Directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i_Directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g_Directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i_Directory.replacer_sram_opt.u_core.rdataReg = u_g_Directory.replacer_sram_opt.rdataReg;
    #0 release u_i_Directory.replacer_sram_opt.u_core.rdataReg;
    u_i_Directory.origin_bit_opt.array.array.array_17_ext.ram = u_g_Directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i_Directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g_Directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i_Directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g_Directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i_Directory.origin_bit_opt.u_core.rdataReg = u_g_Directory.origin_bit_opt.rdataReg;
    #0 release u_i_Directory.origin_bit_opt.u_core.rdataReg;
  endtask

  // ======================= Directory_1 =======================
  logic Directory_1__io_read_valid;
  logic [30:0] Directory_1__io_read_bits_tag;
  logic [8:0] Directory_1__io_read_bits_set;
  logic [7:0] Directory_1__io_read_bits_wayMask;
  logic [2:0] Directory_1__io_read_bits_replacerInfo_channel;
  logic [2:0] Directory_1__io_read_bits_replacerInfo_opcode;
  logic [4:0] Directory_1__io_read_bits_replacerInfo_reqSource;
  logic Directory_1__io_read_bits_replacerInfo_refill_prefetch;
  logic Directory_1__io_read_bits_refill;
  logic [7:0] Directory_1__io_read_bits_mshrId;
  logic Directory_1__io_read_bits_cmoAll;
  logic [2:0] Directory_1__io_read_bits_cmoWay;
  logic Directory_1__io_metaWReq_valid;
  logic [8:0] Directory_1__io_metaWReq_bits_set;
  logic [7:0] Directory_1__io_metaWReq_bits_wayOH;
  logic Directory_1__io_metaWReq_bits_wmeta_dirty;
  logic [1:0] Directory_1__io_metaWReq_bits_wmeta_state;
  logic Directory_1__io_metaWReq_bits_wmeta_clients;
  logic [1:0] Directory_1__io_metaWReq_bits_wmeta_alias;
  logic Directory_1__io_metaWReq_bits_wmeta_prefetch;
  logic [2:0] Directory_1__io_metaWReq_bits_wmeta_prefetchSrc;
  logic Directory_1__io_metaWReq_bits_wmeta_accessed;
  logic Directory_1__io_metaWReq_bits_wmeta_tagErr;
  logic Directory_1__io_metaWReq_bits_wmeta_dataErr;
  logic Directory_1__io_tagWReq_valid;
  logic [8:0] Directory_1__io_tagWReq_bits_set;
  logic [2:0] Directory_1__io_tagWReq_bits_way;
  logic [30:0] Directory_1__io_tagWReq_bits_wtag;
  logic Directory_1__io_msInfo_0_valid;
  logic [2:0] Directory_1__io_msInfo_0_bits_channel;
  logic [8:0] Directory_1__io_msInfo_0_bits_set;
  logic [2:0] Directory_1__io_msInfo_0_bits_way;
  logic [30:0] Directory_1__io_msInfo_0_bits_reqTag;
  logic Directory_1__io_msInfo_0_bits_willFree;
  logic Directory_1__io_msInfo_0_bits_aliasTask;
  logic Directory_1__io_msInfo_0_bits_needRelease;
  logic Directory_1__io_msInfo_0_bits_blockRefill;
  logic Directory_1__io_msInfo_0_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_0_bits_meta_state;
  logic Directory_1__io_msInfo_0_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_0_bits_meta_alias;
  logic Directory_1__io_msInfo_0_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_0_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_0_bits_meta_accessed;
  logic Directory_1__io_msInfo_0_bits_meta_tagErr;
  logic Directory_1__io_msInfo_0_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_0_bits_metaTag;
  logic Directory_1__io_msInfo_0_bits_dirHit;
  logic Directory_1__io_msInfo_0_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_0_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_0_bits_param;
  logic Directory_1__io_msInfo_0_bits_mergeA;
  logic Directory_1__io_msInfo_0_bits_w_grantfirst;
  logic Directory_1__io_msInfo_0_bits_s_release;
  logic Directory_1__io_msInfo_0_bits_s_refill;
  logic Directory_1__io_msInfo_0_bits_s_cmoresp;
  logic Directory_1__io_msInfo_0_bits_s_cmometaw;
  logic Directory_1__io_msInfo_0_bits_w_releaseack;
  logic Directory_1__io_msInfo_0_bits_w_replResp;
  logic Directory_1__io_msInfo_0_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_0_bits_replaceData;
  logic Directory_1__io_msInfo_0_bits_releaseToClean;
  logic Directory_1__io_msInfo_1_valid;
  logic [2:0] Directory_1__io_msInfo_1_bits_channel;
  logic [8:0] Directory_1__io_msInfo_1_bits_set;
  logic [2:0] Directory_1__io_msInfo_1_bits_way;
  logic [30:0] Directory_1__io_msInfo_1_bits_reqTag;
  logic Directory_1__io_msInfo_1_bits_willFree;
  logic Directory_1__io_msInfo_1_bits_aliasTask;
  logic Directory_1__io_msInfo_1_bits_needRelease;
  logic Directory_1__io_msInfo_1_bits_blockRefill;
  logic Directory_1__io_msInfo_1_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_1_bits_meta_state;
  logic Directory_1__io_msInfo_1_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_1_bits_meta_alias;
  logic Directory_1__io_msInfo_1_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_1_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_1_bits_meta_accessed;
  logic Directory_1__io_msInfo_1_bits_meta_tagErr;
  logic Directory_1__io_msInfo_1_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_1_bits_metaTag;
  logic Directory_1__io_msInfo_1_bits_dirHit;
  logic Directory_1__io_msInfo_1_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_1_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_1_bits_param;
  logic Directory_1__io_msInfo_1_bits_mergeA;
  logic Directory_1__io_msInfo_1_bits_w_grantfirst;
  logic Directory_1__io_msInfo_1_bits_s_release;
  logic Directory_1__io_msInfo_1_bits_s_refill;
  logic Directory_1__io_msInfo_1_bits_s_cmoresp;
  logic Directory_1__io_msInfo_1_bits_s_cmometaw;
  logic Directory_1__io_msInfo_1_bits_w_releaseack;
  logic Directory_1__io_msInfo_1_bits_w_replResp;
  logic Directory_1__io_msInfo_1_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_1_bits_replaceData;
  logic Directory_1__io_msInfo_1_bits_releaseToClean;
  logic Directory_1__io_msInfo_2_valid;
  logic [2:0] Directory_1__io_msInfo_2_bits_channel;
  logic [8:0] Directory_1__io_msInfo_2_bits_set;
  logic [2:0] Directory_1__io_msInfo_2_bits_way;
  logic [30:0] Directory_1__io_msInfo_2_bits_reqTag;
  logic Directory_1__io_msInfo_2_bits_willFree;
  logic Directory_1__io_msInfo_2_bits_aliasTask;
  logic Directory_1__io_msInfo_2_bits_needRelease;
  logic Directory_1__io_msInfo_2_bits_blockRefill;
  logic Directory_1__io_msInfo_2_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_2_bits_meta_state;
  logic Directory_1__io_msInfo_2_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_2_bits_meta_alias;
  logic Directory_1__io_msInfo_2_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_2_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_2_bits_meta_accessed;
  logic Directory_1__io_msInfo_2_bits_meta_tagErr;
  logic Directory_1__io_msInfo_2_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_2_bits_metaTag;
  logic Directory_1__io_msInfo_2_bits_dirHit;
  logic Directory_1__io_msInfo_2_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_2_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_2_bits_param;
  logic Directory_1__io_msInfo_2_bits_mergeA;
  logic Directory_1__io_msInfo_2_bits_w_grantfirst;
  logic Directory_1__io_msInfo_2_bits_s_release;
  logic Directory_1__io_msInfo_2_bits_s_refill;
  logic Directory_1__io_msInfo_2_bits_s_cmoresp;
  logic Directory_1__io_msInfo_2_bits_s_cmometaw;
  logic Directory_1__io_msInfo_2_bits_w_releaseack;
  logic Directory_1__io_msInfo_2_bits_w_replResp;
  logic Directory_1__io_msInfo_2_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_2_bits_replaceData;
  logic Directory_1__io_msInfo_2_bits_releaseToClean;
  logic Directory_1__io_msInfo_3_valid;
  logic [2:0] Directory_1__io_msInfo_3_bits_channel;
  logic [8:0] Directory_1__io_msInfo_3_bits_set;
  logic [2:0] Directory_1__io_msInfo_3_bits_way;
  logic [30:0] Directory_1__io_msInfo_3_bits_reqTag;
  logic Directory_1__io_msInfo_3_bits_willFree;
  logic Directory_1__io_msInfo_3_bits_aliasTask;
  logic Directory_1__io_msInfo_3_bits_needRelease;
  logic Directory_1__io_msInfo_3_bits_blockRefill;
  logic Directory_1__io_msInfo_3_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_3_bits_meta_state;
  logic Directory_1__io_msInfo_3_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_3_bits_meta_alias;
  logic Directory_1__io_msInfo_3_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_3_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_3_bits_meta_accessed;
  logic Directory_1__io_msInfo_3_bits_meta_tagErr;
  logic Directory_1__io_msInfo_3_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_3_bits_metaTag;
  logic Directory_1__io_msInfo_3_bits_dirHit;
  logic Directory_1__io_msInfo_3_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_3_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_3_bits_param;
  logic Directory_1__io_msInfo_3_bits_mergeA;
  logic Directory_1__io_msInfo_3_bits_w_grantfirst;
  logic Directory_1__io_msInfo_3_bits_s_release;
  logic Directory_1__io_msInfo_3_bits_s_refill;
  logic Directory_1__io_msInfo_3_bits_s_cmoresp;
  logic Directory_1__io_msInfo_3_bits_s_cmometaw;
  logic Directory_1__io_msInfo_3_bits_w_releaseack;
  logic Directory_1__io_msInfo_3_bits_w_replResp;
  logic Directory_1__io_msInfo_3_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_3_bits_replaceData;
  logic Directory_1__io_msInfo_3_bits_releaseToClean;
  logic Directory_1__io_msInfo_4_valid;
  logic [2:0] Directory_1__io_msInfo_4_bits_channel;
  logic [8:0] Directory_1__io_msInfo_4_bits_set;
  logic [2:0] Directory_1__io_msInfo_4_bits_way;
  logic [30:0] Directory_1__io_msInfo_4_bits_reqTag;
  logic Directory_1__io_msInfo_4_bits_willFree;
  logic Directory_1__io_msInfo_4_bits_aliasTask;
  logic Directory_1__io_msInfo_4_bits_needRelease;
  logic Directory_1__io_msInfo_4_bits_blockRefill;
  logic Directory_1__io_msInfo_4_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_4_bits_meta_state;
  logic Directory_1__io_msInfo_4_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_4_bits_meta_alias;
  logic Directory_1__io_msInfo_4_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_4_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_4_bits_meta_accessed;
  logic Directory_1__io_msInfo_4_bits_meta_tagErr;
  logic Directory_1__io_msInfo_4_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_4_bits_metaTag;
  logic Directory_1__io_msInfo_4_bits_dirHit;
  logic Directory_1__io_msInfo_4_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_4_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_4_bits_param;
  logic Directory_1__io_msInfo_4_bits_mergeA;
  logic Directory_1__io_msInfo_4_bits_w_grantfirst;
  logic Directory_1__io_msInfo_4_bits_s_release;
  logic Directory_1__io_msInfo_4_bits_s_refill;
  logic Directory_1__io_msInfo_4_bits_s_cmoresp;
  logic Directory_1__io_msInfo_4_bits_s_cmometaw;
  logic Directory_1__io_msInfo_4_bits_w_releaseack;
  logic Directory_1__io_msInfo_4_bits_w_replResp;
  logic Directory_1__io_msInfo_4_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_4_bits_replaceData;
  logic Directory_1__io_msInfo_4_bits_releaseToClean;
  logic Directory_1__io_msInfo_5_valid;
  logic [2:0] Directory_1__io_msInfo_5_bits_channel;
  logic [8:0] Directory_1__io_msInfo_5_bits_set;
  logic [2:0] Directory_1__io_msInfo_5_bits_way;
  logic [30:0] Directory_1__io_msInfo_5_bits_reqTag;
  logic Directory_1__io_msInfo_5_bits_willFree;
  logic Directory_1__io_msInfo_5_bits_aliasTask;
  logic Directory_1__io_msInfo_5_bits_needRelease;
  logic Directory_1__io_msInfo_5_bits_blockRefill;
  logic Directory_1__io_msInfo_5_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_5_bits_meta_state;
  logic Directory_1__io_msInfo_5_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_5_bits_meta_alias;
  logic Directory_1__io_msInfo_5_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_5_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_5_bits_meta_accessed;
  logic Directory_1__io_msInfo_5_bits_meta_tagErr;
  logic Directory_1__io_msInfo_5_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_5_bits_metaTag;
  logic Directory_1__io_msInfo_5_bits_dirHit;
  logic Directory_1__io_msInfo_5_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_5_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_5_bits_param;
  logic Directory_1__io_msInfo_5_bits_mergeA;
  logic Directory_1__io_msInfo_5_bits_w_grantfirst;
  logic Directory_1__io_msInfo_5_bits_s_release;
  logic Directory_1__io_msInfo_5_bits_s_refill;
  logic Directory_1__io_msInfo_5_bits_s_cmoresp;
  logic Directory_1__io_msInfo_5_bits_s_cmometaw;
  logic Directory_1__io_msInfo_5_bits_w_releaseack;
  logic Directory_1__io_msInfo_5_bits_w_replResp;
  logic Directory_1__io_msInfo_5_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_5_bits_replaceData;
  logic Directory_1__io_msInfo_5_bits_releaseToClean;
  logic Directory_1__io_msInfo_6_valid;
  logic [2:0] Directory_1__io_msInfo_6_bits_channel;
  logic [8:0] Directory_1__io_msInfo_6_bits_set;
  logic [2:0] Directory_1__io_msInfo_6_bits_way;
  logic [30:0] Directory_1__io_msInfo_6_bits_reqTag;
  logic Directory_1__io_msInfo_6_bits_willFree;
  logic Directory_1__io_msInfo_6_bits_aliasTask;
  logic Directory_1__io_msInfo_6_bits_needRelease;
  logic Directory_1__io_msInfo_6_bits_blockRefill;
  logic Directory_1__io_msInfo_6_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_6_bits_meta_state;
  logic Directory_1__io_msInfo_6_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_6_bits_meta_alias;
  logic Directory_1__io_msInfo_6_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_6_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_6_bits_meta_accessed;
  logic Directory_1__io_msInfo_6_bits_meta_tagErr;
  logic Directory_1__io_msInfo_6_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_6_bits_metaTag;
  logic Directory_1__io_msInfo_6_bits_dirHit;
  logic Directory_1__io_msInfo_6_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_6_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_6_bits_param;
  logic Directory_1__io_msInfo_6_bits_mergeA;
  logic Directory_1__io_msInfo_6_bits_w_grantfirst;
  logic Directory_1__io_msInfo_6_bits_s_release;
  logic Directory_1__io_msInfo_6_bits_s_refill;
  logic Directory_1__io_msInfo_6_bits_s_cmoresp;
  logic Directory_1__io_msInfo_6_bits_s_cmometaw;
  logic Directory_1__io_msInfo_6_bits_w_releaseack;
  logic Directory_1__io_msInfo_6_bits_w_replResp;
  logic Directory_1__io_msInfo_6_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_6_bits_replaceData;
  logic Directory_1__io_msInfo_6_bits_releaseToClean;
  logic Directory_1__io_msInfo_7_valid;
  logic [2:0] Directory_1__io_msInfo_7_bits_channel;
  logic [8:0] Directory_1__io_msInfo_7_bits_set;
  logic [2:0] Directory_1__io_msInfo_7_bits_way;
  logic [30:0] Directory_1__io_msInfo_7_bits_reqTag;
  logic Directory_1__io_msInfo_7_bits_willFree;
  logic Directory_1__io_msInfo_7_bits_aliasTask;
  logic Directory_1__io_msInfo_7_bits_needRelease;
  logic Directory_1__io_msInfo_7_bits_blockRefill;
  logic Directory_1__io_msInfo_7_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_7_bits_meta_state;
  logic Directory_1__io_msInfo_7_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_7_bits_meta_alias;
  logic Directory_1__io_msInfo_7_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_7_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_7_bits_meta_accessed;
  logic Directory_1__io_msInfo_7_bits_meta_tagErr;
  logic Directory_1__io_msInfo_7_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_7_bits_metaTag;
  logic Directory_1__io_msInfo_7_bits_dirHit;
  logic Directory_1__io_msInfo_7_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_7_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_7_bits_param;
  logic Directory_1__io_msInfo_7_bits_mergeA;
  logic Directory_1__io_msInfo_7_bits_w_grantfirst;
  logic Directory_1__io_msInfo_7_bits_s_release;
  logic Directory_1__io_msInfo_7_bits_s_refill;
  logic Directory_1__io_msInfo_7_bits_s_cmoresp;
  logic Directory_1__io_msInfo_7_bits_s_cmometaw;
  logic Directory_1__io_msInfo_7_bits_w_releaseack;
  logic Directory_1__io_msInfo_7_bits_w_replResp;
  logic Directory_1__io_msInfo_7_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_7_bits_replaceData;
  logic Directory_1__io_msInfo_7_bits_releaseToClean;
  logic Directory_1__io_msInfo_8_valid;
  logic [2:0] Directory_1__io_msInfo_8_bits_channel;
  logic [8:0] Directory_1__io_msInfo_8_bits_set;
  logic [2:0] Directory_1__io_msInfo_8_bits_way;
  logic [30:0] Directory_1__io_msInfo_8_bits_reqTag;
  logic Directory_1__io_msInfo_8_bits_willFree;
  logic Directory_1__io_msInfo_8_bits_aliasTask;
  logic Directory_1__io_msInfo_8_bits_needRelease;
  logic Directory_1__io_msInfo_8_bits_blockRefill;
  logic Directory_1__io_msInfo_8_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_8_bits_meta_state;
  logic Directory_1__io_msInfo_8_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_8_bits_meta_alias;
  logic Directory_1__io_msInfo_8_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_8_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_8_bits_meta_accessed;
  logic Directory_1__io_msInfo_8_bits_meta_tagErr;
  logic Directory_1__io_msInfo_8_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_8_bits_metaTag;
  logic Directory_1__io_msInfo_8_bits_dirHit;
  logic Directory_1__io_msInfo_8_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_8_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_8_bits_param;
  logic Directory_1__io_msInfo_8_bits_mergeA;
  logic Directory_1__io_msInfo_8_bits_w_grantfirst;
  logic Directory_1__io_msInfo_8_bits_s_release;
  logic Directory_1__io_msInfo_8_bits_s_refill;
  logic Directory_1__io_msInfo_8_bits_s_cmoresp;
  logic Directory_1__io_msInfo_8_bits_s_cmometaw;
  logic Directory_1__io_msInfo_8_bits_w_releaseack;
  logic Directory_1__io_msInfo_8_bits_w_replResp;
  logic Directory_1__io_msInfo_8_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_8_bits_replaceData;
  logic Directory_1__io_msInfo_8_bits_releaseToClean;
  logic Directory_1__io_msInfo_9_valid;
  logic [2:0] Directory_1__io_msInfo_9_bits_channel;
  logic [8:0] Directory_1__io_msInfo_9_bits_set;
  logic [2:0] Directory_1__io_msInfo_9_bits_way;
  logic [30:0] Directory_1__io_msInfo_9_bits_reqTag;
  logic Directory_1__io_msInfo_9_bits_willFree;
  logic Directory_1__io_msInfo_9_bits_aliasTask;
  logic Directory_1__io_msInfo_9_bits_needRelease;
  logic Directory_1__io_msInfo_9_bits_blockRefill;
  logic Directory_1__io_msInfo_9_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_9_bits_meta_state;
  logic Directory_1__io_msInfo_9_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_9_bits_meta_alias;
  logic Directory_1__io_msInfo_9_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_9_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_9_bits_meta_accessed;
  logic Directory_1__io_msInfo_9_bits_meta_tagErr;
  logic Directory_1__io_msInfo_9_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_9_bits_metaTag;
  logic Directory_1__io_msInfo_9_bits_dirHit;
  logic Directory_1__io_msInfo_9_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_9_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_9_bits_param;
  logic Directory_1__io_msInfo_9_bits_mergeA;
  logic Directory_1__io_msInfo_9_bits_w_grantfirst;
  logic Directory_1__io_msInfo_9_bits_s_release;
  logic Directory_1__io_msInfo_9_bits_s_refill;
  logic Directory_1__io_msInfo_9_bits_s_cmoresp;
  logic Directory_1__io_msInfo_9_bits_s_cmometaw;
  logic Directory_1__io_msInfo_9_bits_w_releaseack;
  logic Directory_1__io_msInfo_9_bits_w_replResp;
  logic Directory_1__io_msInfo_9_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_9_bits_replaceData;
  logic Directory_1__io_msInfo_9_bits_releaseToClean;
  logic Directory_1__io_msInfo_10_valid;
  logic [2:0] Directory_1__io_msInfo_10_bits_channel;
  logic [8:0] Directory_1__io_msInfo_10_bits_set;
  logic [2:0] Directory_1__io_msInfo_10_bits_way;
  logic [30:0] Directory_1__io_msInfo_10_bits_reqTag;
  logic Directory_1__io_msInfo_10_bits_willFree;
  logic Directory_1__io_msInfo_10_bits_aliasTask;
  logic Directory_1__io_msInfo_10_bits_needRelease;
  logic Directory_1__io_msInfo_10_bits_blockRefill;
  logic Directory_1__io_msInfo_10_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_10_bits_meta_state;
  logic Directory_1__io_msInfo_10_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_10_bits_meta_alias;
  logic Directory_1__io_msInfo_10_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_10_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_10_bits_meta_accessed;
  logic Directory_1__io_msInfo_10_bits_meta_tagErr;
  logic Directory_1__io_msInfo_10_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_10_bits_metaTag;
  logic Directory_1__io_msInfo_10_bits_dirHit;
  logic Directory_1__io_msInfo_10_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_10_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_10_bits_param;
  logic Directory_1__io_msInfo_10_bits_mergeA;
  logic Directory_1__io_msInfo_10_bits_w_grantfirst;
  logic Directory_1__io_msInfo_10_bits_s_release;
  logic Directory_1__io_msInfo_10_bits_s_refill;
  logic Directory_1__io_msInfo_10_bits_s_cmoresp;
  logic Directory_1__io_msInfo_10_bits_s_cmometaw;
  logic Directory_1__io_msInfo_10_bits_w_releaseack;
  logic Directory_1__io_msInfo_10_bits_w_replResp;
  logic Directory_1__io_msInfo_10_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_10_bits_replaceData;
  logic Directory_1__io_msInfo_10_bits_releaseToClean;
  logic Directory_1__io_msInfo_11_valid;
  logic [2:0] Directory_1__io_msInfo_11_bits_channel;
  logic [8:0] Directory_1__io_msInfo_11_bits_set;
  logic [2:0] Directory_1__io_msInfo_11_bits_way;
  logic [30:0] Directory_1__io_msInfo_11_bits_reqTag;
  logic Directory_1__io_msInfo_11_bits_willFree;
  logic Directory_1__io_msInfo_11_bits_aliasTask;
  logic Directory_1__io_msInfo_11_bits_needRelease;
  logic Directory_1__io_msInfo_11_bits_blockRefill;
  logic Directory_1__io_msInfo_11_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_11_bits_meta_state;
  logic Directory_1__io_msInfo_11_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_11_bits_meta_alias;
  logic Directory_1__io_msInfo_11_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_11_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_11_bits_meta_accessed;
  logic Directory_1__io_msInfo_11_bits_meta_tagErr;
  logic Directory_1__io_msInfo_11_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_11_bits_metaTag;
  logic Directory_1__io_msInfo_11_bits_dirHit;
  logic Directory_1__io_msInfo_11_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_11_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_11_bits_param;
  logic Directory_1__io_msInfo_11_bits_mergeA;
  logic Directory_1__io_msInfo_11_bits_w_grantfirst;
  logic Directory_1__io_msInfo_11_bits_s_release;
  logic Directory_1__io_msInfo_11_bits_s_refill;
  logic Directory_1__io_msInfo_11_bits_s_cmoresp;
  logic Directory_1__io_msInfo_11_bits_s_cmometaw;
  logic Directory_1__io_msInfo_11_bits_w_releaseack;
  logic Directory_1__io_msInfo_11_bits_w_replResp;
  logic Directory_1__io_msInfo_11_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_11_bits_replaceData;
  logic Directory_1__io_msInfo_11_bits_releaseToClean;
  logic Directory_1__io_msInfo_12_valid;
  logic [2:0] Directory_1__io_msInfo_12_bits_channel;
  logic [8:0] Directory_1__io_msInfo_12_bits_set;
  logic [2:0] Directory_1__io_msInfo_12_bits_way;
  logic [30:0] Directory_1__io_msInfo_12_bits_reqTag;
  logic Directory_1__io_msInfo_12_bits_willFree;
  logic Directory_1__io_msInfo_12_bits_aliasTask;
  logic Directory_1__io_msInfo_12_bits_needRelease;
  logic Directory_1__io_msInfo_12_bits_blockRefill;
  logic Directory_1__io_msInfo_12_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_12_bits_meta_state;
  logic Directory_1__io_msInfo_12_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_12_bits_meta_alias;
  logic Directory_1__io_msInfo_12_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_12_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_12_bits_meta_accessed;
  logic Directory_1__io_msInfo_12_bits_meta_tagErr;
  logic Directory_1__io_msInfo_12_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_12_bits_metaTag;
  logic Directory_1__io_msInfo_12_bits_dirHit;
  logic Directory_1__io_msInfo_12_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_12_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_12_bits_param;
  logic Directory_1__io_msInfo_12_bits_mergeA;
  logic Directory_1__io_msInfo_12_bits_w_grantfirst;
  logic Directory_1__io_msInfo_12_bits_s_release;
  logic Directory_1__io_msInfo_12_bits_s_refill;
  logic Directory_1__io_msInfo_12_bits_s_cmoresp;
  logic Directory_1__io_msInfo_12_bits_s_cmometaw;
  logic Directory_1__io_msInfo_12_bits_w_releaseack;
  logic Directory_1__io_msInfo_12_bits_w_replResp;
  logic Directory_1__io_msInfo_12_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_12_bits_replaceData;
  logic Directory_1__io_msInfo_12_bits_releaseToClean;
  logic Directory_1__io_msInfo_13_valid;
  logic [2:0] Directory_1__io_msInfo_13_bits_channel;
  logic [8:0] Directory_1__io_msInfo_13_bits_set;
  logic [2:0] Directory_1__io_msInfo_13_bits_way;
  logic [30:0] Directory_1__io_msInfo_13_bits_reqTag;
  logic Directory_1__io_msInfo_13_bits_willFree;
  logic Directory_1__io_msInfo_13_bits_aliasTask;
  logic Directory_1__io_msInfo_13_bits_needRelease;
  logic Directory_1__io_msInfo_13_bits_blockRefill;
  logic Directory_1__io_msInfo_13_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_13_bits_meta_state;
  logic Directory_1__io_msInfo_13_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_13_bits_meta_alias;
  logic Directory_1__io_msInfo_13_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_13_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_13_bits_meta_accessed;
  logic Directory_1__io_msInfo_13_bits_meta_tagErr;
  logic Directory_1__io_msInfo_13_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_13_bits_metaTag;
  logic Directory_1__io_msInfo_13_bits_dirHit;
  logic Directory_1__io_msInfo_13_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_13_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_13_bits_param;
  logic Directory_1__io_msInfo_13_bits_mergeA;
  logic Directory_1__io_msInfo_13_bits_w_grantfirst;
  logic Directory_1__io_msInfo_13_bits_s_release;
  logic Directory_1__io_msInfo_13_bits_s_refill;
  logic Directory_1__io_msInfo_13_bits_s_cmoresp;
  logic Directory_1__io_msInfo_13_bits_s_cmometaw;
  logic Directory_1__io_msInfo_13_bits_w_releaseack;
  logic Directory_1__io_msInfo_13_bits_w_replResp;
  logic Directory_1__io_msInfo_13_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_13_bits_replaceData;
  logic Directory_1__io_msInfo_13_bits_releaseToClean;
  logic Directory_1__io_msInfo_14_valid;
  logic [2:0] Directory_1__io_msInfo_14_bits_channel;
  logic [8:0] Directory_1__io_msInfo_14_bits_set;
  logic [2:0] Directory_1__io_msInfo_14_bits_way;
  logic [30:0] Directory_1__io_msInfo_14_bits_reqTag;
  logic Directory_1__io_msInfo_14_bits_willFree;
  logic Directory_1__io_msInfo_14_bits_aliasTask;
  logic Directory_1__io_msInfo_14_bits_needRelease;
  logic Directory_1__io_msInfo_14_bits_blockRefill;
  logic Directory_1__io_msInfo_14_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_14_bits_meta_state;
  logic Directory_1__io_msInfo_14_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_14_bits_meta_alias;
  logic Directory_1__io_msInfo_14_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_14_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_14_bits_meta_accessed;
  logic Directory_1__io_msInfo_14_bits_meta_tagErr;
  logic Directory_1__io_msInfo_14_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_14_bits_metaTag;
  logic Directory_1__io_msInfo_14_bits_dirHit;
  logic Directory_1__io_msInfo_14_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_14_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_14_bits_param;
  logic Directory_1__io_msInfo_14_bits_mergeA;
  logic Directory_1__io_msInfo_14_bits_w_grantfirst;
  logic Directory_1__io_msInfo_14_bits_s_release;
  logic Directory_1__io_msInfo_14_bits_s_refill;
  logic Directory_1__io_msInfo_14_bits_s_cmoresp;
  logic Directory_1__io_msInfo_14_bits_s_cmometaw;
  logic Directory_1__io_msInfo_14_bits_w_releaseack;
  logic Directory_1__io_msInfo_14_bits_w_replResp;
  logic Directory_1__io_msInfo_14_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_14_bits_replaceData;
  logic Directory_1__io_msInfo_14_bits_releaseToClean;
  logic Directory_1__io_msInfo_15_valid;
  logic [2:0] Directory_1__io_msInfo_15_bits_channel;
  logic [8:0] Directory_1__io_msInfo_15_bits_set;
  logic [2:0] Directory_1__io_msInfo_15_bits_way;
  logic [30:0] Directory_1__io_msInfo_15_bits_reqTag;
  logic Directory_1__io_msInfo_15_bits_willFree;
  logic Directory_1__io_msInfo_15_bits_aliasTask;
  logic Directory_1__io_msInfo_15_bits_needRelease;
  logic Directory_1__io_msInfo_15_bits_blockRefill;
  logic Directory_1__io_msInfo_15_bits_meta_dirty;
  logic [1:0] Directory_1__io_msInfo_15_bits_meta_state;
  logic Directory_1__io_msInfo_15_bits_meta_clients;
  logic [1:0] Directory_1__io_msInfo_15_bits_meta_alias;
  logic Directory_1__io_msInfo_15_bits_meta_prefetch;
  logic [2:0] Directory_1__io_msInfo_15_bits_meta_prefetchSrc;
  logic Directory_1__io_msInfo_15_bits_meta_accessed;
  logic Directory_1__io_msInfo_15_bits_meta_tagErr;
  logic Directory_1__io_msInfo_15_bits_meta_dataErr;
  logic [30:0] Directory_1__io_msInfo_15_bits_metaTag;
  logic Directory_1__io_msInfo_15_bits_dirHit;
  logic Directory_1__io_msInfo_15_bits_isAcqOrPrefetch;
  logic Directory_1__io_msInfo_15_bits_isPrefetch;
  logic [2:0] Directory_1__io_msInfo_15_bits_param;
  logic Directory_1__io_msInfo_15_bits_mergeA;
  logic Directory_1__io_msInfo_15_bits_w_grantfirst;
  logic Directory_1__io_msInfo_15_bits_s_release;
  logic Directory_1__io_msInfo_15_bits_s_refill;
  logic Directory_1__io_msInfo_15_bits_s_cmoresp;
  logic Directory_1__io_msInfo_15_bits_s_cmometaw;
  logic Directory_1__io_msInfo_15_bits_w_releaseack;
  logic Directory_1__io_msInfo_15_bits_w_replResp;
  logic Directory_1__io_msInfo_15_bits_w_rprobeacklast;
  logic Directory_1__io_msInfo_15_bits_replaceData;
  logic Directory_1__io_msInfo_15_bits_releaseToClean;
  logic [4:0] Directory_1__boreChildrenBd_bore_array;
  logic Directory_1__boreChildrenBd_bore_all;
  logic Directory_1__boreChildrenBd_bore_req;
  logic Directory_1__boreChildrenBd_bore_writeen;
  logic [7:0] Directory_1__boreChildrenBd_bore_be;
  logic [9:0] Directory_1__boreChildrenBd_bore_addr;
  logic [103:0] Directory_1__boreChildrenBd_bore_indata;
  logic Directory_1__boreChildrenBd_bore_readen;
  logic [9:0] Directory_1__boreChildrenBd_bore_addr_rd;
  logic Directory_1__sigFromSrams_bore_ram_hold;
  logic Directory_1__sigFromSrams_bore_ram_bypass;
  logic Directory_1__sigFromSrams_bore_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_cgen;
  logic Directory_1__sigFromSrams_bore_1_ram_hold;
  logic Directory_1__sigFromSrams_bore_1_ram_bypass;
  logic Directory_1__sigFromSrams_bore_1_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_1_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_1_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_1_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_1_cgen;
  logic Directory_1__sigFromSrams_bore_2_ram_hold;
  logic Directory_1__sigFromSrams_bore_2_ram_bypass;
  logic Directory_1__sigFromSrams_bore_2_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_2_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_2_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_2_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_2_cgen;
  logic Directory_1__sigFromSrams_bore_3_ram_hold;
  logic Directory_1__sigFromSrams_bore_3_ram_bypass;
  logic Directory_1__sigFromSrams_bore_3_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_3_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_3_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_3_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_3_cgen;
  logic Directory_1__sigFromSrams_bore_4_ram_hold;
  logic Directory_1__sigFromSrams_bore_4_ram_bypass;
  logic Directory_1__sigFromSrams_bore_4_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_4_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_4_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_4_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_4_cgen;
  logic Directory_1__sigFromSrams_bore_5_ram_hold;
  logic Directory_1__sigFromSrams_bore_5_ram_bypass;
  logic Directory_1__sigFromSrams_bore_5_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_5_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_5_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_5_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_5_cgen;
  logic Directory_1__sigFromSrams_bore_6_ram_hold;
  logic Directory_1__sigFromSrams_bore_6_ram_bypass;
  logic Directory_1__sigFromSrams_bore_6_ram_bp_clken;
  logic Directory_1__sigFromSrams_bore_6_ram_aux_clk;
  logic Directory_1__sigFromSrams_bore_6_ram_aux_ckbp;
  logic Directory_1__sigFromSrams_bore_6_ram_mcp_hold;
  logic Directory_1__sigFromSrams_bore_6_cgen;
  wire  g_Directory_1__io_read_ready;
  wire  i_Directory_1__io_read_ready;
  logic p_Directory_1__io_read_ready;
  bit   t_Directory_1__io_read_ready;
  wire  g_Directory_1__io_resp_valid;
  wire  i_Directory_1__io_resp_valid;
  logic p_Directory_1__io_resp_valid;
  bit   t_Directory_1__io_resp_valid;
  wire  g_Directory_1__io_resp_bits_hit;
  wire  i_Directory_1__io_resp_bits_hit;
  logic p_Directory_1__io_resp_bits_hit;
  bit   t_Directory_1__io_resp_bits_hit;
  wire  [30:0] g_Directory_1__io_resp_bits_tag;
  wire  [30:0] i_Directory_1__io_resp_bits_tag;
  logic [30:0] p_Directory_1__io_resp_bits_tag;
  bit   t_Directory_1__io_resp_bits_tag;
  wire  [8:0] g_Directory_1__io_resp_bits_set;
  wire  [8:0] i_Directory_1__io_resp_bits_set;
  logic [8:0] p_Directory_1__io_resp_bits_set;
  bit   t_Directory_1__io_resp_bits_set;
  wire  [2:0] g_Directory_1__io_resp_bits_way;
  wire  [2:0] i_Directory_1__io_resp_bits_way;
  logic [2:0] p_Directory_1__io_resp_bits_way;
  bit   t_Directory_1__io_resp_bits_way;
  wire  g_Directory_1__io_resp_bits_meta_dirty;
  wire  i_Directory_1__io_resp_bits_meta_dirty;
  logic p_Directory_1__io_resp_bits_meta_dirty;
  bit   t_Directory_1__io_resp_bits_meta_dirty;
  wire  [1:0] g_Directory_1__io_resp_bits_meta_state;
  wire  [1:0] i_Directory_1__io_resp_bits_meta_state;
  logic [1:0] p_Directory_1__io_resp_bits_meta_state;
  bit   t_Directory_1__io_resp_bits_meta_state;
  wire  g_Directory_1__io_resp_bits_meta_clients;
  wire  i_Directory_1__io_resp_bits_meta_clients;
  logic p_Directory_1__io_resp_bits_meta_clients;
  bit   t_Directory_1__io_resp_bits_meta_clients;
  wire  [1:0] g_Directory_1__io_resp_bits_meta_alias;
  wire  [1:0] i_Directory_1__io_resp_bits_meta_alias;
  logic [1:0] p_Directory_1__io_resp_bits_meta_alias;
  bit   t_Directory_1__io_resp_bits_meta_alias;
  wire  g_Directory_1__io_resp_bits_meta_prefetch;
  wire  i_Directory_1__io_resp_bits_meta_prefetch;
  logic p_Directory_1__io_resp_bits_meta_prefetch;
  bit   t_Directory_1__io_resp_bits_meta_prefetch;
  wire  [2:0] g_Directory_1__io_resp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory_1__io_resp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory_1__io_resp_bits_meta_prefetchSrc;
  bit   t_Directory_1__io_resp_bits_meta_prefetchSrc;
  wire  g_Directory_1__io_resp_bits_meta_accessed;
  wire  i_Directory_1__io_resp_bits_meta_accessed;
  logic p_Directory_1__io_resp_bits_meta_accessed;
  bit   t_Directory_1__io_resp_bits_meta_accessed;
  wire  g_Directory_1__io_resp_bits_meta_tagErr;
  wire  i_Directory_1__io_resp_bits_meta_tagErr;
  logic p_Directory_1__io_resp_bits_meta_tagErr;
  bit   t_Directory_1__io_resp_bits_meta_tagErr;
  wire  g_Directory_1__io_resp_bits_meta_dataErr;
  wire  i_Directory_1__io_resp_bits_meta_dataErr;
  logic p_Directory_1__io_resp_bits_meta_dataErr;
  bit   t_Directory_1__io_resp_bits_meta_dataErr;
  wire  g_Directory_1__io_resp_bits_error;
  wire  i_Directory_1__io_resp_bits_error;
  logic p_Directory_1__io_resp_bits_error;
  bit   t_Directory_1__io_resp_bits_error;
  wire  [2:0] g_Directory_1__io_resp_bits_replacerInfo_channel;
  wire  [2:0] i_Directory_1__io_resp_bits_replacerInfo_channel;
  logic [2:0] p_Directory_1__io_resp_bits_replacerInfo_channel;
  bit   t_Directory_1__io_resp_bits_replacerInfo_channel;
  wire  [2:0] g_Directory_1__io_resp_bits_replacerInfo_opcode;
  wire  [2:0] i_Directory_1__io_resp_bits_replacerInfo_opcode;
  logic [2:0] p_Directory_1__io_resp_bits_replacerInfo_opcode;
  bit   t_Directory_1__io_resp_bits_replacerInfo_opcode;
  wire  [4:0] g_Directory_1__io_resp_bits_replacerInfo_reqSource;
  wire  [4:0] i_Directory_1__io_resp_bits_replacerInfo_reqSource;
  logic [4:0] p_Directory_1__io_resp_bits_replacerInfo_reqSource;
  bit   t_Directory_1__io_resp_bits_replacerInfo_reqSource;
  wire  g_Directory_1__io_resp_bits_replacerInfo_refill_prefetch;
  wire  i_Directory_1__io_resp_bits_replacerInfo_refill_prefetch;
  logic p_Directory_1__io_resp_bits_replacerInfo_refill_prefetch;
  bit   t_Directory_1__io_resp_bits_replacerInfo_refill_prefetch;
  wire  g_Directory_1__io_replResp_valid;
  wire  i_Directory_1__io_replResp_valid;
  logic p_Directory_1__io_replResp_valid;
  bit   t_Directory_1__io_replResp_valid;
  wire  [30:0] g_Directory_1__io_replResp_bits_tag;
  wire  [30:0] i_Directory_1__io_replResp_bits_tag;
  logic [30:0] p_Directory_1__io_replResp_bits_tag;
  bit   t_Directory_1__io_replResp_bits_tag;
  wire  [8:0] g_Directory_1__io_replResp_bits_set;
  wire  [8:0] i_Directory_1__io_replResp_bits_set;
  logic [8:0] p_Directory_1__io_replResp_bits_set;
  bit   t_Directory_1__io_replResp_bits_set;
  wire  [2:0] g_Directory_1__io_replResp_bits_way;
  wire  [2:0] i_Directory_1__io_replResp_bits_way;
  logic [2:0] p_Directory_1__io_replResp_bits_way;
  bit   t_Directory_1__io_replResp_bits_way;
  wire  g_Directory_1__io_replResp_bits_meta_dirty;
  wire  i_Directory_1__io_replResp_bits_meta_dirty;
  logic p_Directory_1__io_replResp_bits_meta_dirty;
  bit   t_Directory_1__io_replResp_bits_meta_dirty;
  wire  [1:0] g_Directory_1__io_replResp_bits_meta_state;
  wire  [1:0] i_Directory_1__io_replResp_bits_meta_state;
  logic [1:0] p_Directory_1__io_replResp_bits_meta_state;
  bit   t_Directory_1__io_replResp_bits_meta_state;
  wire  g_Directory_1__io_replResp_bits_meta_clients;
  wire  i_Directory_1__io_replResp_bits_meta_clients;
  logic p_Directory_1__io_replResp_bits_meta_clients;
  bit   t_Directory_1__io_replResp_bits_meta_clients;
  wire  [1:0] g_Directory_1__io_replResp_bits_meta_alias;
  wire  [1:0] i_Directory_1__io_replResp_bits_meta_alias;
  logic [1:0] p_Directory_1__io_replResp_bits_meta_alias;
  bit   t_Directory_1__io_replResp_bits_meta_alias;
  wire  g_Directory_1__io_replResp_bits_meta_prefetch;
  wire  i_Directory_1__io_replResp_bits_meta_prefetch;
  logic p_Directory_1__io_replResp_bits_meta_prefetch;
  bit   t_Directory_1__io_replResp_bits_meta_prefetch;
  wire  [2:0] g_Directory_1__io_replResp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory_1__io_replResp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory_1__io_replResp_bits_meta_prefetchSrc;
  bit   t_Directory_1__io_replResp_bits_meta_prefetchSrc;
  wire  g_Directory_1__io_replResp_bits_meta_accessed;
  wire  i_Directory_1__io_replResp_bits_meta_accessed;
  logic p_Directory_1__io_replResp_bits_meta_accessed;
  bit   t_Directory_1__io_replResp_bits_meta_accessed;
  wire  g_Directory_1__io_replResp_bits_meta_tagErr;
  wire  i_Directory_1__io_replResp_bits_meta_tagErr;
  logic p_Directory_1__io_replResp_bits_meta_tagErr;
  bit   t_Directory_1__io_replResp_bits_meta_tagErr;
  wire  g_Directory_1__io_replResp_bits_meta_dataErr;
  wire  i_Directory_1__io_replResp_bits_meta_dataErr;
  logic p_Directory_1__io_replResp_bits_meta_dataErr;
  bit   t_Directory_1__io_replResp_bits_meta_dataErr;
  wire  [7:0] g_Directory_1__io_replResp_bits_mshrId;
  wire  [7:0] i_Directory_1__io_replResp_bits_mshrId;
  logic [7:0] p_Directory_1__io_replResp_bits_mshrId;
  bit   t_Directory_1__io_replResp_bits_mshrId;
  wire  g_Directory_1__io_replResp_bits_retry;
  wire  i_Directory_1__io_replResp_bits_retry;
  logic p_Directory_1__io_replResp_bits_retry;
  bit   t_Directory_1__io_replResp_bits_retry;
  wire  g_Directory_1__io_replResp_bits_error;
  wire  i_Directory_1__io_replResp_bits_error;
  logic p_Directory_1__io_replResp_bits_error;
  bit   t_Directory_1__io_replResp_bits_error;
  wire  g_Directory_1__boreChildrenBd_bore_ack;
  wire  i_Directory_1__boreChildrenBd_bore_ack;
  logic p_Directory_1__boreChildrenBd_bore_ack;
  bit   t_Directory_1__boreChildrenBd_bore_ack;
  wire  [103:0] g_Directory_1__boreChildrenBd_bore_outdata;
  wire  [103:0] i_Directory_1__boreChildrenBd_bore_outdata;
  logic [103:0] p_Directory_1__boreChildrenBd_bore_outdata;
  bit   t_Directory_1__boreChildrenBd_bore_outdata;
  Directory_1 u_g_Directory_1 (
    .clock (clock),
    .reset (reset),
    .io_read_ready (g_Directory_1__io_read_ready),
    .io_read_valid (Directory_1__io_read_valid),
    .io_read_bits_tag (Directory_1__io_read_bits_tag),
    .io_read_bits_set (Directory_1__io_read_bits_set),
    .io_read_bits_wayMask (Directory_1__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory_1__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory_1__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory_1__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory_1__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory_1__io_read_bits_refill),
    .io_read_bits_mshrId (Directory_1__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory_1__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory_1__io_read_bits_cmoWay),
    .io_resp_valid (g_Directory_1__io_resp_valid),
    .io_resp_bits_hit (g_Directory_1__io_resp_bits_hit),
    .io_resp_bits_tag (g_Directory_1__io_resp_bits_tag),
    .io_resp_bits_set (g_Directory_1__io_resp_bits_set),
    .io_resp_bits_way (g_Directory_1__io_resp_bits_way),
    .io_resp_bits_meta_dirty (g_Directory_1__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (g_Directory_1__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (g_Directory_1__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (g_Directory_1__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (g_Directory_1__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (g_Directory_1__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (g_Directory_1__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (g_Directory_1__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (g_Directory_1__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (g_Directory_1__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (g_Directory_1__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (g_Directory_1__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (g_Directory_1__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (g_Directory_1__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory_1__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory_1__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory_1__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory_1__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory_1__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory_1__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory_1__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory_1__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory_1__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory_1__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory_1__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory_1__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory_1__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory_1__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory_1__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory_1__io_tagWReq_bits_wtag),
    .io_replResp_valid (g_Directory_1__io_replResp_valid),
    .io_replResp_bits_tag (g_Directory_1__io_replResp_bits_tag),
    .io_replResp_bits_set (g_Directory_1__io_replResp_bits_set),
    .io_replResp_bits_way (g_Directory_1__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (g_Directory_1__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (g_Directory_1__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (g_Directory_1__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (g_Directory_1__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (g_Directory_1__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (g_Directory_1__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (g_Directory_1__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (g_Directory_1__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (g_Directory_1__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (g_Directory_1__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (g_Directory_1__io_replResp_bits_retry),
    .io_replResp_bits_error (g_Directory_1__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory_1__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory_1__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory_1__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory_1__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory_1__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory_1__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory_1__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory_1__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory_1__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory_1__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory_1__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory_1__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory_1__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory_1__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory_1__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory_1__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory_1__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory_1__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory_1__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory_1__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory_1__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory_1__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory_1__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory_1__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory_1__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory_1__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory_1__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory_1__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory_1__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory_1__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory_1__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory_1__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory_1__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory_1__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory_1__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory_1__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory_1__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory_1__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory_1__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory_1__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory_1__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory_1__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory_1__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory_1__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory_1__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory_1__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory_1__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory_1__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory_1__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory_1__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory_1__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory_1__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory_1__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory_1__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory_1__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory_1__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory_1__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory_1__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory_1__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory_1__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory_1__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory_1__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory_1__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory_1__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory_1__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory_1__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory_1__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory_1__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory_1__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory_1__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory_1__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory_1__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory_1__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory_1__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory_1__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory_1__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory_1__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory_1__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory_1__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory_1__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory_1__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory_1__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory_1__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory_1__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory_1__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory_1__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory_1__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory_1__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory_1__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory_1__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory_1__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory_1__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory_1__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory_1__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory_1__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory_1__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory_1__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory_1__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory_1__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory_1__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory_1__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory_1__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory_1__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory_1__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory_1__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory_1__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory_1__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory_1__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory_1__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory_1__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory_1__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory_1__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory_1__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory_1__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory_1__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory_1__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory_1__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory_1__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory_1__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory_1__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory_1__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory_1__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory_1__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory_1__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory_1__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory_1__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory_1__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory_1__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory_1__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory_1__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory_1__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory_1__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory_1__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory_1__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory_1__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory_1__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory_1__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory_1__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory_1__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory_1__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory_1__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory_1__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory_1__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory_1__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory_1__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory_1__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory_1__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory_1__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory_1__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory_1__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory_1__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory_1__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory_1__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory_1__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory_1__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory_1__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory_1__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory_1__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory_1__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory_1__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory_1__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory_1__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory_1__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory_1__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory_1__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory_1__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory_1__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory_1__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory_1__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory_1__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory_1__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory_1__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory_1__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory_1__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory_1__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory_1__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory_1__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory_1__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory_1__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory_1__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory_1__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory_1__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory_1__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory_1__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory_1__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory_1__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory_1__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory_1__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory_1__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory_1__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory_1__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory_1__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory_1__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory_1__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory_1__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory_1__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory_1__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory_1__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory_1__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory_1__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory_1__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory_1__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory_1__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory_1__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory_1__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory_1__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory_1__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory_1__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory_1__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory_1__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory_1__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory_1__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory_1__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory_1__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory_1__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory_1__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory_1__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory_1__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory_1__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory_1__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory_1__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory_1__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory_1__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory_1__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory_1__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory_1__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory_1__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory_1__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory_1__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory_1__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory_1__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory_1__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory_1__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory_1__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory_1__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory_1__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory_1__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory_1__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory_1__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory_1__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory_1__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory_1__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory_1__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory_1__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory_1__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory_1__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory_1__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory_1__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory_1__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory_1__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory_1__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory_1__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory_1__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory_1__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory_1__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory_1__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory_1__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory_1__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory_1__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory_1__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory_1__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory_1__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory_1__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory_1__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory_1__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory_1__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory_1__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory_1__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory_1__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory_1__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory_1__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory_1__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory_1__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory_1__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory_1__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory_1__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory_1__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory_1__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory_1__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory_1__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory_1__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory_1__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory_1__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory_1__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory_1__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory_1__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory_1__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory_1__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory_1__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory_1__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory_1__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory_1__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory_1__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory_1__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory_1__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory_1__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory_1__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory_1__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory_1__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory_1__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory_1__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory_1__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory_1__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory_1__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory_1__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory_1__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory_1__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory_1__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory_1__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory_1__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory_1__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory_1__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory_1__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory_1__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory_1__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory_1__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory_1__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory_1__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory_1__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory_1__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory_1__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory_1__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory_1__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory_1__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory_1__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory_1__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory_1__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory_1__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory_1__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory_1__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory_1__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory_1__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory_1__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory_1__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory_1__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory_1__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory_1__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory_1__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory_1__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory_1__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory_1__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory_1__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory_1__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory_1__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory_1__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory_1__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory_1__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory_1__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory_1__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory_1__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory_1__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory_1__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory_1__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory_1__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory_1__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory_1__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory_1__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory_1__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory_1__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory_1__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory_1__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory_1__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory_1__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory_1__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory_1__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory_1__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory_1__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory_1__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory_1__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory_1__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory_1__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory_1__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory_1__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory_1__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory_1__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory_1__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory_1__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory_1__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory_1__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory_1__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory_1__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory_1__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory_1__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory_1__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory_1__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory_1__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory_1__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory_1__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory_1__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory_1__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory_1__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory_1__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory_1__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory_1__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory_1__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory_1__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory_1__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory_1__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory_1__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory_1__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory_1__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory_1__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory_1__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory_1__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory_1__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory_1__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory_1__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory_1__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory_1__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory_1__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory_1__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory_1__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory_1__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory_1__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory_1__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory_1__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory_1__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory_1__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory_1__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory_1__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory_1__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory_1__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory_1__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory_1__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory_1__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory_1__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory_1__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory_1__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory_1__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory_1__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory_1__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory_1__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory_1__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory_1__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory_1__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory_1__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory_1__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory_1__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory_1__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory_1__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory_1__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory_1__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory_1__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory_1__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory_1__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory_1__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory_1__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory_1__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory_1__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory_1__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory_1__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory_1__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory_1__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory_1__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory_1__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory_1__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory_1__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory_1__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory_1__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory_1__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory_1__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory_1__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory_1__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory_1__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory_1__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory_1__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory_1__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory_1__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory_1__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory_1__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory_1__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory_1__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory_1__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory_1__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory_1__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory_1__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory_1__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory_1__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory_1__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory_1__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory_1__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory_1__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory_1__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory_1__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory_1__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory_1__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory_1__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory_1__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory_1__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory_1__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory_1__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory_1__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory_1__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory_1__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory_1__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory_1__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory_1__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory_1__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory_1__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory_1__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory_1__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory_1__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory_1__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory_1__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory_1__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory_1__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory_1__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory_1__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory_1__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory_1__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory_1__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory_1__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory_1__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory_1__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory_1__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory_1__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory_1__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory_1__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory_1__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory_1__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory_1__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory_1__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory_1__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory_1__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory_1__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory_1__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory_1__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory_1__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory_1__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory_1__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory_1__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory_1__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory_1__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory_1__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory_1__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory_1__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory_1__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory_1__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory_1__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory_1__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory_1__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory_1__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory_1__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory_1__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory_1__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory_1__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory_1__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_Directory_1__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory_1__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory_1__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory_1__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory_1__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory_1__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory_1__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_Directory_1__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory_1__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory_1__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory_1__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory_1__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory_1__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory_1__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory_1__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory_1__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory_1__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory_1__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory_1__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory_1__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory_1__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory_1__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory_1__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory_1__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory_1__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory_1__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory_1__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory_1__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory_1__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory_1__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory_1__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory_1__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory_1__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory_1__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory_1__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory_1__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory_1__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory_1__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory_1__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory_1__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory_1__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory_1__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory_1__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory_1__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory_1__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory_1__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory_1__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory_1__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory_1__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory_1__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory_1__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory_1__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory_1__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory_1__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory_1__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory_1__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory_1__sigFromSrams_bore_6_cgen)
  );
  Directory_1_xs u_i_Directory_1 (
    .clock (clock),
    .reset (reset),
    .io_read_ready (i_Directory_1__io_read_ready),
    .io_read_valid (Directory_1__io_read_valid),
    .io_read_bits_tag (Directory_1__io_read_bits_tag),
    .io_read_bits_set (Directory_1__io_read_bits_set),
    .io_read_bits_wayMask (Directory_1__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory_1__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory_1__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory_1__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory_1__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory_1__io_read_bits_refill),
    .io_read_bits_mshrId (Directory_1__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory_1__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory_1__io_read_bits_cmoWay),
    .io_resp_valid (i_Directory_1__io_resp_valid),
    .io_resp_bits_hit (i_Directory_1__io_resp_bits_hit),
    .io_resp_bits_tag (i_Directory_1__io_resp_bits_tag),
    .io_resp_bits_set (i_Directory_1__io_resp_bits_set),
    .io_resp_bits_way (i_Directory_1__io_resp_bits_way),
    .io_resp_bits_meta_dirty (i_Directory_1__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (i_Directory_1__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (i_Directory_1__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (i_Directory_1__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (i_Directory_1__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (i_Directory_1__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (i_Directory_1__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (i_Directory_1__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (i_Directory_1__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (i_Directory_1__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (i_Directory_1__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (i_Directory_1__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (i_Directory_1__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (i_Directory_1__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory_1__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory_1__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory_1__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory_1__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory_1__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory_1__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory_1__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory_1__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory_1__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory_1__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory_1__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory_1__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory_1__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory_1__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory_1__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory_1__io_tagWReq_bits_wtag),
    .io_replResp_valid (i_Directory_1__io_replResp_valid),
    .io_replResp_bits_tag (i_Directory_1__io_replResp_bits_tag),
    .io_replResp_bits_set (i_Directory_1__io_replResp_bits_set),
    .io_replResp_bits_way (i_Directory_1__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (i_Directory_1__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (i_Directory_1__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (i_Directory_1__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (i_Directory_1__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (i_Directory_1__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (i_Directory_1__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (i_Directory_1__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (i_Directory_1__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (i_Directory_1__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (i_Directory_1__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (i_Directory_1__io_replResp_bits_retry),
    .io_replResp_bits_error (i_Directory_1__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory_1__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory_1__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory_1__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory_1__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory_1__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory_1__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory_1__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory_1__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory_1__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory_1__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory_1__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory_1__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory_1__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory_1__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory_1__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory_1__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory_1__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory_1__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory_1__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory_1__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory_1__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory_1__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory_1__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory_1__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory_1__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory_1__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory_1__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory_1__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory_1__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory_1__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory_1__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory_1__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory_1__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory_1__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory_1__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory_1__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory_1__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory_1__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory_1__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory_1__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory_1__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory_1__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory_1__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory_1__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory_1__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory_1__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory_1__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory_1__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory_1__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory_1__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory_1__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory_1__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory_1__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory_1__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory_1__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory_1__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory_1__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory_1__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory_1__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory_1__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory_1__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory_1__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory_1__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory_1__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory_1__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory_1__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory_1__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory_1__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory_1__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory_1__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory_1__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory_1__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory_1__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory_1__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory_1__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory_1__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory_1__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory_1__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory_1__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory_1__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory_1__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory_1__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory_1__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory_1__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory_1__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory_1__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory_1__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory_1__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory_1__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory_1__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory_1__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory_1__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory_1__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory_1__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory_1__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory_1__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory_1__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory_1__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory_1__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory_1__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory_1__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory_1__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory_1__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory_1__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory_1__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory_1__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory_1__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory_1__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory_1__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory_1__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory_1__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory_1__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory_1__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory_1__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory_1__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory_1__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory_1__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory_1__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory_1__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory_1__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory_1__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory_1__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory_1__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory_1__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory_1__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory_1__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory_1__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory_1__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory_1__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory_1__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory_1__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory_1__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory_1__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory_1__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory_1__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory_1__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory_1__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory_1__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory_1__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory_1__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory_1__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory_1__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory_1__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory_1__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory_1__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory_1__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory_1__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory_1__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory_1__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory_1__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory_1__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory_1__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory_1__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory_1__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory_1__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory_1__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory_1__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory_1__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory_1__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory_1__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory_1__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory_1__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory_1__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory_1__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory_1__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory_1__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory_1__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory_1__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory_1__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory_1__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory_1__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory_1__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory_1__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory_1__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory_1__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory_1__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory_1__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory_1__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory_1__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory_1__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory_1__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory_1__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory_1__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory_1__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory_1__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory_1__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory_1__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory_1__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory_1__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory_1__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory_1__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory_1__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory_1__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory_1__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory_1__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory_1__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory_1__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory_1__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory_1__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory_1__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory_1__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory_1__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory_1__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory_1__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory_1__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory_1__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory_1__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory_1__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory_1__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory_1__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory_1__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory_1__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory_1__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory_1__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory_1__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory_1__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory_1__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory_1__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory_1__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory_1__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory_1__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory_1__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory_1__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory_1__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory_1__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory_1__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory_1__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory_1__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory_1__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory_1__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory_1__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory_1__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory_1__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory_1__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory_1__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory_1__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory_1__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory_1__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory_1__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory_1__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory_1__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory_1__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory_1__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory_1__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory_1__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory_1__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory_1__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory_1__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory_1__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory_1__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory_1__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory_1__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory_1__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory_1__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory_1__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory_1__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory_1__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory_1__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory_1__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory_1__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory_1__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory_1__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory_1__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory_1__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory_1__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory_1__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory_1__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory_1__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory_1__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory_1__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory_1__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory_1__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory_1__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory_1__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory_1__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory_1__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory_1__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory_1__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory_1__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory_1__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory_1__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory_1__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory_1__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory_1__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory_1__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory_1__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory_1__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory_1__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory_1__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory_1__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory_1__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory_1__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory_1__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory_1__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory_1__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory_1__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory_1__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory_1__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory_1__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory_1__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory_1__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory_1__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory_1__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory_1__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory_1__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory_1__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory_1__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory_1__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory_1__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory_1__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory_1__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory_1__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory_1__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory_1__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory_1__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory_1__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory_1__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory_1__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory_1__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory_1__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory_1__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory_1__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory_1__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory_1__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory_1__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory_1__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory_1__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory_1__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory_1__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory_1__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory_1__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory_1__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory_1__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory_1__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory_1__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory_1__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory_1__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory_1__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory_1__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory_1__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory_1__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory_1__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory_1__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory_1__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory_1__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory_1__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory_1__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory_1__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory_1__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory_1__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory_1__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory_1__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory_1__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory_1__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory_1__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory_1__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory_1__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory_1__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory_1__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory_1__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory_1__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory_1__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory_1__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory_1__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory_1__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory_1__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory_1__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory_1__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory_1__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory_1__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory_1__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory_1__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory_1__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory_1__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory_1__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory_1__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory_1__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory_1__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory_1__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory_1__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory_1__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory_1__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory_1__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory_1__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory_1__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory_1__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory_1__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory_1__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory_1__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory_1__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory_1__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory_1__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory_1__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory_1__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory_1__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory_1__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory_1__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory_1__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory_1__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory_1__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory_1__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory_1__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory_1__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory_1__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory_1__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory_1__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory_1__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory_1__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory_1__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory_1__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory_1__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory_1__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory_1__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory_1__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory_1__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory_1__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory_1__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory_1__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory_1__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory_1__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory_1__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory_1__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory_1__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory_1__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory_1__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory_1__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory_1__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory_1__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory_1__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory_1__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory_1__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory_1__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory_1__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory_1__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory_1__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory_1__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory_1__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory_1__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory_1__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory_1__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory_1__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory_1__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory_1__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory_1__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory_1__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory_1__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory_1__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory_1__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory_1__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory_1__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory_1__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory_1__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory_1__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory_1__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory_1__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory_1__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory_1__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory_1__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory_1__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory_1__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory_1__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory_1__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory_1__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory_1__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory_1__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory_1__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory_1__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory_1__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory_1__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory_1__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory_1__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory_1__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory_1__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory_1__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory_1__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory_1__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory_1__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory_1__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory_1__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory_1__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory_1__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory_1__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory_1__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory_1__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory_1__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory_1__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory_1__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory_1__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory_1__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory_1__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory_1__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory_1__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory_1__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory_1__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory_1__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory_1__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory_1__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory_1__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory_1__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory_1__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory_1__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory_1__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory_1__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory_1__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory_1__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory_1__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory_1__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory_1__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory_1__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory_1__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory_1__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory_1__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory_1__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory_1__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory_1__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory_1__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory_1__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory_1__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory_1__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory_1__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory_1__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory_1__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory_1__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory_1__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory_1__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory_1__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory_1__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory_1__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory_1__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory_1__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory_1__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory_1__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory_1__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory_1__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory_1__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory_1__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory_1__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory_1__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory_1__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory_1__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory_1__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory_1__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory_1__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory_1__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory_1__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory_1__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory_1__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_Directory_1__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory_1__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory_1__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory_1__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory_1__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory_1__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory_1__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_Directory_1__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory_1__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory_1__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory_1__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory_1__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory_1__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory_1__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory_1__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory_1__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory_1__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory_1__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory_1__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory_1__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory_1__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory_1__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory_1__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory_1__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory_1__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory_1__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory_1__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory_1__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory_1__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory_1__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory_1__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory_1__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory_1__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory_1__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory_1__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory_1__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory_1__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory_1__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory_1__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory_1__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory_1__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory_1__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory_1__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory_1__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory_1__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory_1__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory_1__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory_1__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory_1__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory_1__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory_1__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory_1__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory_1__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory_1__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory_1__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory_1__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory_1__sigFromSrams_bore_6_cgen)
  );
  task automatic drive_Directory_1();
    Directory_1__io_read_valid = $urandom % 2;
    Directory_1__io_read_bits_tag = 31'($urandom_range(0, 3));
    Directory_1__io_read_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_read_bits_wayMask = rnd(8);
    Directory_1__io_read_bits_replacerInfo_channel = rnd(3);
    Directory_1__io_read_bits_replacerInfo_opcode = rnd(3);
    Directory_1__io_read_bits_replacerInfo_reqSource = rnd(5);
    Directory_1__io_read_bits_replacerInfo_refill_prefetch = $urandom % 2;
    Directory_1__io_read_bits_refill = $urandom % 2;
    Directory_1__io_read_bits_mshrId = rnd(8);
    Directory_1__io_read_bits_cmoAll = $urandom % 2;
    Directory_1__io_read_bits_cmoWay = rnd(3);
    Directory_1__io_metaWReq_valid = (($urandom % 4) == 0);
    Directory_1__io_metaWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_metaWReq_bits_wayOH = rnd(8);
    Directory_1__io_metaWReq_bits_wmeta_dirty = $urandom % 2;
    Directory_1__io_metaWReq_bits_wmeta_state = rnd(2);
    Directory_1__io_metaWReq_bits_wmeta_clients = $urandom % 2;
    Directory_1__io_metaWReq_bits_wmeta_alias = rnd(2);
    Directory_1__io_metaWReq_bits_wmeta_prefetch = $urandom % 2;
    Directory_1__io_metaWReq_bits_wmeta_prefetchSrc = rnd(3);
    Directory_1__io_metaWReq_bits_wmeta_accessed = $urandom % 2;
    Directory_1__io_metaWReq_bits_wmeta_tagErr = $urandom % 2;
    Directory_1__io_metaWReq_bits_wmeta_dataErr = $urandom % 2;
    Directory_1__io_tagWReq_valid = (($urandom % 4) == 0);
    Directory_1__io_tagWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_tagWReq_bits_way = rnd(3);
    Directory_1__io_tagWReq_bits_wtag = 31'($urandom_range(0, 3));
    Directory_1__io_msInfo_0_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_0_bits_channel = rnd(3);
    Directory_1__io_msInfo_0_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_0_bits_way = rnd(3);
    Directory_1__io_msInfo_0_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_0_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_0_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_0_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_0_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_0_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_0_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_0_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_0_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_0_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_0_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_0_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_0_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_0_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_0_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_0_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_0_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_0_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_0_bits_param = rnd(3);
    Directory_1__io_msInfo_0_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_0_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_0_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_0_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_0_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_0_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_0_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_0_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_0_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_0_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_0_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_1_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_1_bits_channel = rnd(3);
    Directory_1__io_msInfo_1_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_1_bits_way = rnd(3);
    Directory_1__io_msInfo_1_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_1_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_1_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_1_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_1_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_1_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_1_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_1_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_1_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_1_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_1_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_1_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_1_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_1_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_1_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_1_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_1_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_1_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_1_bits_param = rnd(3);
    Directory_1__io_msInfo_1_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_1_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_1_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_1_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_1_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_1_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_1_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_1_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_1_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_1_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_1_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_2_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_2_bits_channel = rnd(3);
    Directory_1__io_msInfo_2_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_2_bits_way = rnd(3);
    Directory_1__io_msInfo_2_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_2_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_2_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_2_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_2_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_2_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_2_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_2_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_2_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_2_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_2_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_2_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_2_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_2_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_2_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_2_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_2_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_2_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_2_bits_param = rnd(3);
    Directory_1__io_msInfo_2_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_2_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_2_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_2_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_2_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_2_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_2_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_2_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_2_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_2_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_2_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_3_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_3_bits_channel = rnd(3);
    Directory_1__io_msInfo_3_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_3_bits_way = rnd(3);
    Directory_1__io_msInfo_3_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_3_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_3_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_3_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_3_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_3_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_3_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_3_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_3_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_3_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_3_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_3_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_3_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_3_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_3_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_3_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_3_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_3_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_3_bits_param = rnd(3);
    Directory_1__io_msInfo_3_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_3_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_3_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_3_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_3_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_3_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_3_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_3_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_3_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_3_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_3_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_4_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_4_bits_channel = rnd(3);
    Directory_1__io_msInfo_4_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_4_bits_way = rnd(3);
    Directory_1__io_msInfo_4_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_4_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_4_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_4_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_4_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_4_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_4_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_4_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_4_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_4_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_4_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_4_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_4_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_4_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_4_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_4_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_4_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_4_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_4_bits_param = rnd(3);
    Directory_1__io_msInfo_4_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_4_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_4_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_4_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_4_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_4_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_4_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_4_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_4_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_4_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_4_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_5_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_5_bits_channel = rnd(3);
    Directory_1__io_msInfo_5_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_5_bits_way = rnd(3);
    Directory_1__io_msInfo_5_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_5_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_5_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_5_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_5_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_5_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_5_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_5_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_5_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_5_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_5_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_5_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_5_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_5_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_5_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_5_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_5_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_5_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_5_bits_param = rnd(3);
    Directory_1__io_msInfo_5_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_5_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_5_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_5_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_5_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_5_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_5_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_5_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_5_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_5_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_5_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_6_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_6_bits_channel = rnd(3);
    Directory_1__io_msInfo_6_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_6_bits_way = rnd(3);
    Directory_1__io_msInfo_6_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_6_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_6_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_6_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_6_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_6_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_6_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_6_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_6_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_6_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_6_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_6_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_6_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_6_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_6_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_6_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_6_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_6_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_6_bits_param = rnd(3);
    Directory_1__io_msInfo_6_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_6_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_6_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_6_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_6_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_6_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_6_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_6_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_6_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_6_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_6_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_7_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_7_bits_channel = rnd(3);
    Directory_1__io_msInfo_7_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_7_bits_way = rnd(3);
    Directory_1__io_msInfo_7_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_7_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_7_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_7_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_7_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_7_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_7_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_7_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_7_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_7_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_7_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_7_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_7_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_7_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_7_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_7_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_7_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_7_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_7_bits_param = rnd(3);
    Directory_1__io_msInfo_7_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_7_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_7_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_7_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_7_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_7_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_7_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_7_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_7_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_7_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_7_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_8_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_8_bits_channel = rnd(3);
    Directory_1__io_msInfo_8_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_8_bits_way = rnd(3);
    Directory_1__io_msInfo_8_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_8_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_8_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_8_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_8_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_8_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_8_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_8_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_8_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_8_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_8_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_8_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_8_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_8_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_8_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_8_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_8_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_8_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_8_bits_param = rnd(3);
    Directory_1__io_msInfo_8_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_8_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_8_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_8_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_8_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_8_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_8_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_8_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_8_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_8_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_8_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_9_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_9_bits_channel = rnd(3);
    Directory_1__io_msInfo_9_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_9_bits_way = rnd(3);
    Directory_1__io_msInfo_9_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_9_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_9_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_9_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_9_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_9_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_9_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_9_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_9_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_9_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_9_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_9_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_9_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_9_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_9_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_9_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_9_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_9_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_9_bits_param = rnd(3);
    Directory_1__io_msInfo_9_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_9_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_9_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_9_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_9_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_9_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_9_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_9_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_9_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_9_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_9_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_10_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_10_bits_channel = rnd(3);
    Directory_1__io_msInfo_10_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_10_bits_way = rnd(3);
    Directory_1__io_msInfo_10_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_10_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_10_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_10_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_10_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_10_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_10_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_10_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_10_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_10_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_10_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_10_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_10_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_10_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_10_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_10_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_10_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_10_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_10_bits_param = rnd(3);
    Directory_1__io_msInfo_10_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_10_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_10_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_10_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_10_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_10_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_10_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_10_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_10_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_10_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_10_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_11_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_11_bits_channel = rnd(3);
    Directory_1__io_msInfo_11_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_11_bits_way = rnd(3);
    Directory_1__io_msInfo_11_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_11_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_11_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_11_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_11_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_11_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_11_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_11_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_11_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_11_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_11_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_11_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_11_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_11_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_11_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_11_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_11_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_11_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_11_bits_param = rnd(3);
    Directory_1__io_msInfo_11_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_11_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_11_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_11_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_11_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_11_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_11_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_11_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_11_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_11_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_11_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_12_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_12_bits_channel = rnd(3);
    Directory_1__io_msInfo_12_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_12_bits_way = rnd(3);
    Directory_1__io_msInfo_12_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_12_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_12_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_12_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_12_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_12_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_12_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_12_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_12_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_12_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_12_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_12_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_12_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_12_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_12_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_12_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_12_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_12_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_12_bits_param = rnd(3);
    Directory_1__io_msInfo_12_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_12_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_12_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_12_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_12_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_12_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_12_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_12_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_12_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_12_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_12_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_13_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_13_bits_channel = rnd(3);
    Directory_1__io_msInfo_13_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_13_bits_way = rnd(3);
    Directory_1__io_msInfo_13_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_13_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_13_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_13_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_13_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_13_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_13_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_13_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_13_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_13_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_13_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_13_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_13_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_13_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_13_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_13_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_13_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_13_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_13_bits_param = rnd(3);
    Directory_1__io_msInfo_13_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_13_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_13_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_13_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_13_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_13_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_13_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_13_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_13_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_13_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_13_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_14_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_14_bits_channel = rnd(3);
    Directory_1__io_msInfo_14_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_14_bits_way = rnd(3);
    Directory_1__io_msInfo_14_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_14_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_14_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_14_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_14_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_14_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_14_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_14_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_14_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_14_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_14_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_14_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_14_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_14_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_14_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_14_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_14_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_14_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_14_bits_param = rnd(3);
    Directory_1__io_msInfo_14_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_14_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_14_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_14_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_14_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_14_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_14_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_14_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_14_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_14_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_14_bits_releaseToClean = $urandom % 2;
    Directory_1__io_msInfo_15_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_1__io_msInfo_15_bits_channel = rnd(3);
    Directory_1__io_msInfo_15_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_1__io_msInfo_15_bits_way = rnd(3);
    Directory_1__io_msInfo_15_bits_reqTag = rnd(31);
    Directory_1__io_msInfo_15_bits_willFree = $urandom % 2;
    Directory_1__io_msInfo_15_bits_aliasTask = $urandom % 2;
    Directory_1__io_msInfo_15_bits_needRelease = $urandom % 2;
    Directory_1__io_msInfo_15_bits_blockRefill = $urandom % 2;
    Directory_1__io_msInfo_15_bits_meta_dirty = $urandom % 2;
    Directory_1__io_msInfo_15_bits_meta_state = rnd(2);
    Directory_1__io_msInfo_15_bits_meta_clients = $urandom % 2;
    Directory_1__io_msInfo_15_bits_meta_alias = rnd(2);
    Directory_1__io_msInfo_15_bits_meta_prefetch = $urandom % 2;
    Directory_1__io_msInfo_15_bits_meta_prefetchSrc = rnd(3);
    Directory_1__io_msInfo_15_bits_meta_accessed = $urandom % 2;
    Directory_1__io_msInfo_15_bits_meta_tagErr = $urandom % 2;
    Directory_1__io_msInfo_15_bits_meta_dataErr = $urandom % 2;
    Directory_1__io_msInfo_15_bits_metaTag = rnd(31);
    Directory_1__io_msInfo_15_bits_dirHit = $urandom % 2;
    Directory_1__io_msInfo_15_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_1__io_msInfo_15_bits_isPrefetch = $urandom % 2;
    Directory_1__io_msInfo_15_bits_param = rnd(3);
    Directory_1__io_msInfo_15_bits_mergeA = $urandom % 2;
    Directory_1__io_msInfo_15_bits_w_grantfirst = $urandom % 2;
    Directory_1__io_msInfo_15_bits_s_release = $urandom % 2;
    Directory_1__io_msInfo_15_bits_s_refill = $urandom % 2;
    Directory_1__io_msInfo_15_bits_s_cmoresp = $urandom % 2;
    Directory_1__io_msInfo_15_bits_s_cmometaw = $urandom % 2;
    Directory_1__io_msInfo_15_bits_w_releaseack = $urandom % 2;
    Directory_1__io_msInfo_15_bits_w_replResp = $urandom % 2;
    Directory_1__io_msInfo_15_bits_w_rprobeacklast = $urandom % 2;
    Directory_1__io_msInfo_15_bits_replaceData = $urandom % 2;
    Directory_1__io_msInfo_15_bits_releaseToClean = $urandom % 2;
    Directory_1__boreChildrenBd_bore_array = rnd(5);
    Directory_1__boreChildrenBd_bore_all = $urandom % 2;
    Directory_1__boreChildrenBd_bore_req = $urandom % 2;
    Directory_1__boreChildrenBd_bore_writeen = $urandom % 2;
    Directory_1__boreChildrenBd_bore_be = rnd(8);
    Directory_1__boreChildrenBd_bore_addr = rnd(10);
    Directory_1__boreChildrenBd_bore_indata = rnd(104);
    Directory_1__boreChildrenBd_bore_readen = $urandom % 2;
    Directory_1__boreChildrenBd_bore_addr_rd = rnd(10);
    Directory_1__sigFromSrams_bore_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_cgen = $urandom % 2;
    Directory_1__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_1_cgen = $urandom % 2;
    Directory_1__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_2_cgen = $urandom % 2;
    Directory_1__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_3_cgen = $urandom % 2;
    Directory_1__sigFromSrams_bore_4_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_4_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_4_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_4_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_4_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_4_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_4_cgen = $urandom % 2;
    Directory_1__sigFromSrams_bore_5_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_5_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_5_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_5_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_5_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_5_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_5_cgen = $urandom % 2;
    Directory_1__sigFromSrams_bore_6_ram_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_6_ram_bypass = $urandom % 2;
    Directory_1__sigFromSrams_bore_6_ram_bp_clken = $urandom % 2;
    Directory_1__sigFromSrams_bore_6_ram_aux_clk = 1'b0;
    Directory_1__sigFromSrams_bore_6_ram_aux_ckbp = 1'b0;
    Directory_1__sigFromSrams_bore_6_ram_mcp_hold = $urandom % 2;
    Directory_1__sigFromSrams_bore_6_cgen = $urandom % 2;
  endtask
  task automatic check_Directory_1();
    checks++;
    if (g_Directory_1__io_read_ready !== i_Directory_1__io_read_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_read_ready g=%h i=%h", cyc, g_Directory_1__io_read_ready, i_Directory_1__io_read_ready);
    end
    if (g_Directory_1__io_read_ready !== p_Directory_1__io_read_ready) t_Directory_1__io_read_ready = 1'b1;
    p_Directory_1__io_read_ready = g_Directory_1__io_read_ready;
    checks++;
    if (g_Directory_1__io_resp_valid !== i_Directory_1__io_resp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_valid g=%h i=%h", cyc, g_Directory_1__io_resp_valid, i_Directory_1__io_resp_valid);
    end
    if (g_Directory_1__io_resp_valid !== p_Directory_1__io_resp_valid) t_Directory_1__io_resp_valid = 1'b1;
    p_Directory_1__io_resp_valid = g_Directory_1__io_resp_valid;
    checks++;
    if (g_Directory_1__io_resp_bits_hit !== i_Directory_1__io_resp_bits_hit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_hit g=%h i=%h", cyc, g_Directory_1__io_resp_bits_hit, i_Directory_1__io_resp_bits_hit);
    end
    if (g_Directory_1__io_resp_bits_hit !== p_Directory_1__io_resp_bits_hit) t_Directory_1__io_resp_bits_hit = 1'b1;
    p_Directory_1__io_resp_bits_hit = g_Directory_1__io_resp_bits_hit;
    checks++;
    if (g_Directory_1__io_resp_bits_tag !== i_Directory_1__io_resp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_tag g=%h i=%h", cyc, g_Directory_1__io_resp_bits_tag, i_Directory_1__io_resp_bits_tag);
    end
    if (g_Directory_1__io_resp_bits_tag !== p_Directory_1__io_resp_bits_tag) t_Directory_1__io_resp_bits_tag = 1'b1;
    p_Directory_1__io_resp_bits_tag = g_Directory_1__io_resp_bits_tag;
    checks++;
    if (g_Directory_1__io_resp_bits_set !== i_Directory_1__io_resp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_set g=%h i=%h", cyc, g_Directory_1__io_resp_bits_set, i_Directory_1__io_resp_bits_set);
    end
    if (g_Directory_1__io_resp_bits_set !== p_Directory_1__io_resp_bits_set) t_Directory_1__io_resp_bits_set = 1'b1;
    p_Directory_1__io_resp_bits_set = g_Directory_1__io_resp_bits_set;
    checks++;
    if (g_Directory_1__io_resp_bits_way !== i_Directory_1__io_resp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_way g=%h i=%h", cyc, g_Directory_1__io_resp_bits_way, i_Directory_1__io_resp_bits_way);
    end
    if (g_Directory_1__io_resp_bits_way !== p_Directory_1__io_resp_bits_way) t_Directory_1__io_resp_bits_way = 1'b1;
    p_Directory_1__io_resp_bits_way = g_Directory_1__io_resp_bits_way;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_dirty !== i_Directory_1__io_resp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_dirty g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_dirty, i_Directory_1__io_resp_bits_meta_dirty);
    end
    if (g_Directory_1__io_resp_bits_meta_dirty !== p_Directory_1__io_resp_bits_meta_dirty) t_Directory_1__io_resp_bits_meta_dirty = 1'b1;
    p_Directory_1__io_resp_bits_meta_dirty = g_Directory_1__io_resp_bits_meta_dirty;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_state !== i_Directory_1__io_resp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_state g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_state, i_Directory_1__io_resp_bits_meta_state);
    end
    if (g_Directory_1__io_resp_bits_meta_state !== p_Directory_1__io_resp_bits_meta_state) t_Directory_1__io_resp_bits_meta_state = 1'b1;
    p_Directory_1__io_resp_bits_meta_state = g_Directory_1__io_resp_bits_meta_state;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_clients !== i_Directory_1__io_resp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_clients g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_clients, i_Directory_1__io_resp_bits_meta_clients);
    end
    if (g_Directory_1__io_resp_bits_meta_clients !== p_Directory_1__io_resp_bits_meta_clients) t_Directory_1__io_resp_bits_meta_clients = 1'b1;
    p_Directory_1__io_resp_bits_meta_clients = g_Directory_1__io_resp_bits_meta_clients;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_alias !== i_Directory_1__io_resp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_alias g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_alias, i_Directory_1__io_resp_bits_meta_alias);
    end
    if (g_Directory_1__io_resp_bits_meta_alias !== p_Directory_1__io_resp_bits_meta_alias) t_Directory_1__io_resp_bits_meta_alias = 1'b1;
    p_Directory_1__io_resp_bits_meta_alias = g_Directory_1__io_resp_bits_meta_alias;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_prefetch !== i_Directory_1__io_resp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_prefetch, i_Directory_1__io_resp_bits_meta_prefetch);
    end
    if (g_Directory_1__io_resp_bits_meta_prefetch !== p_Directory_1__io_resp_bits_meta_prefetch) t_Directory_1__io_resp_bits_meta_prefetch = 1'b1;
    p_Directory_1__io_resp_bits_meta_prefetch = g_Directory_1__io_resp_bits_meta_prefetch;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_prefetchSrc !== i_Directory_1__io_resp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_prefetchSrc, i_Directory_1__io_resp_bits_meta_prefetchSrc);
    end
    if (g_Directory_1__io_resp_bits_meta_prefetchSrc !== p_Directory_1__io_resp_bits_meta_prefetchSrc) t_Directory_1__io_resp_bits_meta_prefetchSrc = 1'b1;
    p_Directory_1__io_resp_bits_meta_prefetchSrc = g_Directory_1__io_resp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_accessed !== i_Directory_1__io_resp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_accessed g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_accessed, i_Directory_1__io_resp_bits_meta_accessed);
    end
    if (g_Directory_1__io_resp_bits_meta_accessed !== p_Directory_1__io_resp_bits_meta_accessed) t_Directory_1__io_resp_bits_meta_accessed = 1'b1;
    p_Directory_1__io_resp_bits_meta_accessed = g_Directory_1__io_resp_bits_meta_accessed;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_tagErr !== i_Directory_1__io_resp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_tagErr, i_Directory_1__io_resp_bits_meta_tagErr);
    end
    if (g_Directory_1__io_resp_bits_meta_tagErr !== p_Directory_1__io_resp_bits_meta_tagErr) t_Directory_1__io_resp_bits_meta_tagErr = 1'b1;
    p_Directory_1__io_resp_bits_meta_tagErr = g_Directory_1__io_resp_bits_meta_tagErr;
    checks++;
    if (g_Directory_1__io_resp_bits_meta_dataErr !== i_Directory_1__io_resp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory_1__io_resp_bits_meta_dataErr, i_Directory_1__io_resp_bits_meta_dataErr);
    end
    if (g_Directory_1__io_resp_bits_meta_dataErr !== p_Directory_1__io_resp_bits_meta_dataErr) t_Directory_1__io_resp_bits_meta_dataErr = 1'b1;
    p_Directory_1__io_resp_bits_meta_dataErr = g_Directory_1__io_resp_bits_meta_dataErr;
    checks++;
    if (g_Directory_1__io_resp_bits_error !== i_Directory_1__io_resp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_error g=%h i=%h", cyc, g_Directory_1__io_resp_bits_error, i_Directory_1__io_resp_bits_error);
    end
    if (g_Directory_1__io_resp_bits_error !== p_Directory_1__io_resp_bits_error) t_Directory_1__io_resp_bits_error = 1'b1;
    p_Directory_1__io_resp_bits_error = g_Directory_1__io_resp_bits_error;
    checks++;
    if (g_Directory_1__io_resp_bits_replacerInfo_channel !== i_Directory_1__io_resp_bits_replacerInfo_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_replacerInfo_channel g=%h i=%h", cyc, g_Directory_1__io_resp_bits_replacerInfo_channel, i_Directory_1__io_resp_bits_replacerInfo_channel);
    end
    if (g_Directory_1__io_resp_bits_replacerInfo_channel !== p_Directory_1__io_resp_bits_replacerInfo_channel) t_Directory_1__io_resp_bits_replacerInfo_channel = 1'b1;
    p_Directory_1__io_resp_bits_replacerInfo_channel = g_Directory_1__io_resp_bits_replacerInfo_channel;
    checks++;
    if (g_Directory_1__io_resp_bits_replacerInfo_opcode !== i_Directory_1__io_resp_bits_replacerInfo_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_replacerInfo_opcode g=%h i=%h", cyc, g_Directory_1__io_resp_bits_replacerInfo_opcode, i_Directory_1__io_resp_bits_replacerInfo_opcode);
    end
    if (g_Directory_1__io_resp_bits_replacerInfo_opcode !== p_Directory_1__io_resp_bits_replacerInfo_opcode) t_Directory_1__io_resp_bits_replacerInfo_opcode = 1'b1;
    p_Directory_1__io_resp_bits_replacerInfo_opcode = g_Directory_1__io_resp_bits_replacerInfo_opcode;
    checks++;
    if (g_Directory_1__io_resp_bits_replacerInfo_reqSource !== i_Directory_1__io_resp_bits_replacerInfo_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_replacerInfo_reqSource g=%h i=%h", cyc, g_Directory_1__io_resp_bits_replacerInfo_reqSource, i_Directory_1__io_resp_bits_replacerInfo_reqSource);
    end
    if (g_Directory_1__io_resp_bits_replacerInfo_reqSource !== p_Directory_1__io_resp_bits_replacerInfo_reqSource) t_Directory_1__io_resp_bits_replacerInfo_reqSource = 1'b1;
    p_Directory_1__io_resp_bits_replacerInfo_reqSource = g_Directory_1__io_resp_bits_replacerInfo_reqSource;
    checks++;
    if (g_Directory_1__io_resp_bits_replacerInfo_refill_prefetch !== i_Directory_1__io_resp_bits_replacerInfo_refill_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_resp_bits_replacerInfo_refill_prefetch g=%h i=%h", cyc, g_Directory_1__io_resp_bits_replacerInfo_refill_prefetch, i_Directory_1__io_resp_bits_replacerInfo_refill_prefetch);
    end
    if (g_Directory_1__io_resp_bits_replacerInfo_refill_prefetch !== p_Directory_1__io_resp_bits_replacerInfo_refill_prefetch) t_Directory_1__io_resp_bits_replacerInfo_refill_prefetch = 1'b1;
    p_Directory_1__io_resp_bits_replacerInfo_refill_prefetch = g_Directory_1__io_resp_bits_replacerInfo_refill_prefetch;
    checks++;
    if (g_Directory_1__io_replResp_valid !== i_Directory_1__io_replResp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_valid g=%h i=%h", cyc, g_Directory_1__io_replResp_valid, i_Directory_1__io_replResp_valid);
    end
    if (g_Directory_1__io_replResp_valid !== p_Directory_1__io_replResp_valid) t_Directory_1__io_replResp_valid = 1'b1;
    p_Directory_1__io_replResp_valid = g_Directory_1__io_replResp_valid;
    checks++;
    if (g_Directory_1__io_replResp_bits_tag !== i_Directory_1__io_replResp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_tag g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_tag, i_Directory_1__io_replResp_bits_tag);
    end
    if (g_Directory_1__io_replResp_bits_tag !== p_Directory_1__io_replResp_bits_tag) t_Directory_1__io_replResp_bits_tag = 1'b1;
    p_Directory_1__io_replResp_bits_tag = g_Directory_1__io_replResp_bits_tag;
    checks++;
    if (g_Directory_1__io_replResp_bits_set !== i_Directory_1__io_replResp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_set g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_set, i_Directory_1__io_replResp_bits_set);
    end
    if (g_Directory_1__io_replResp_bits_set !== p_Directory_1__io_replResp_bits_set) t_Directory_1__io_replResp_bits_set = 1'b1;
    p_Directory_1__io_replResp_bits_set = g_Directory_1__io_replResp_bits_set;
    checks++;
    if (g_Directory_1__io_replResp_bits_way !== i_Directory_1__io_replResp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_way g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_way, i_Directory_1__io_replResp_bits_way);
    end
    if (g_Directory_1__io_replResp_bits_way !== p_Directory_1__io_replResp_bits_way) t_Directory_1__io_replResp_bits_way = 1'b1;
    p_Directory_1__io_replResp_bits_way = g_Directory_1__io_replResp_bits_way;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_dirty !== i_Directory_1__io_replResp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_dirty g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_dirty, i_Directory_1__io_replResp_bits_meta_dirty);
    end
    if (g_Directory_1__io_replResp_bits_meta_dirty !== p_Directory_1__io_replResp_bits_meta_dirty) t_Directory_1__io_replResp_bits_meta_dirty = 1'b1;
    p_Directory_1__io_replResp_bits_meta_dirty = g_Directory_1__io_replResp_bits_meta_dirty;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_state !== i_Directory_1__io_replResp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_state g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_state, i_Directory_1__io_replResp_bits_meta_state);
    end
    if (g_Directory_1__io_replResp_bits_meta_state !== p_Directory_1__io_replResp_bits_meta_state) t_Directory_1__io_replResp_bits_meta_state = 1'b1;
    p_Directory_1__io_replResp_bits_meta_state = g_Directory_1__io_replResp_bits_meta_state;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_clients !== i_Directory_1__io_replResp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_clients g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_clients, i_Directory_1__io_replResp_bits_meta_clients);
    end
    if (g_Directory_1__io_replResp_bits_meta_clients !== p_Directory_1__io_replResp_bits_meta_clients) t_Directory_1__io_replResp_bits_meta_clients = 1'b1;
    p_Directory_1__io_replResp_bits_meta_clients = g_Directory_1__io_replResp_bits_meta_clients;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_alias !== i_Directory_1__io_replResp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_alias g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_alias, i_Directory_1__io_replResp_bits_meta_alias);
    end
    if (g_Directory_1__io_replResp_bits_meta_alias !== p_Directory_1__io_replResp_bits_meta_alias) t_Directory_1__io_replResp_bits_meta_alias = 1'b1;
    p_Directory_1__io_replResp_bits_meta_alias = g_Directory_1__io_replResp_bits_meta_alias;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_prefetch !== i_Directory_1__io_replResp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_prefetch, i_Directory_1__io_replResp_bits_meta_prefetch);
    end
    if (g_Directory_1__io_replResp_bits_meta_prefetch !== p_Directory_1__io_replResp_bits_meta_prefetch) t_Directory_1__io_replResp_bits_meta_prefetch = 1'b1;
    p_Directory_1__io_replResp_bits_meta_prefetch = g_Directory_1__io_replResp_bits_meta_prefetch;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_prefetchSrc !== i_Directory_1__io_replResp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_prefetchSrc, i_Directory_1__io_replResp_bits_meta_prefetchSrc);
    end
    if (g_Directory_1__io_replResp_bits_meta_prefetchSrc !== p_Directory_1__io_replResp_bits_meta_prefetchSrc) t_Directory_1__io_replResp_bits_meta_prefetchSrc = 1'b1;
    p_Directory_1__io_replResp_bits_meta_prefetchSrc = g_Directory_1__io_replResp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_accessed !== i_Directory_1__io_replResp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_accessed g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_accessed, i_Directory_1__io_replResp_bits_meta_accessed);
    end
    if (g_Directory_1__io_replResp_bits_meta_accessed !== p_Directory_1__io_replResp_bits_meta_accessed) t_Directory_1__io_replResp_bits_meta_accessed = 1'b1;
    p_Directory_1__io_replResp_bits_meta_accessed = g_Directory_1__io_replResp_bits_meta_accessed;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_tagErr !== i_Directory_1__io_replResp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_tagErr, i_Directory_1__io_replResp_bits_meta_tagErr);
    end
    if (g_Directory_1__io_replResp_bits_meta_tagErr !== p_Directory_1__io_replResp_bits_meta_tagErr) t_Directory_1__io_replResp_bits_meta_tagErr = 1'b1;
    p_Directory_1__io_replResp_bits_meta_tagErr = g_Directory_1__io_replResp_bits_meta_tagErr;
    checks++;
    if (g_Directory_1__io_replResp_bits_meta_dataErr !== i_Directory_1__io_replResp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_meta_dataErr, i_Directory_1__io_replResp_bits_meta_dataErr);
    end
    if (g_Directory_1__io_replResp_bits_meta_dataErr !== p_Directory_1__io_replResp_bits_meta_dataErr) t_Directory_1__io_replResp_bits_meta_dataErr = 1'b1;
    p_Directory_1__io_replResp_bits_meta_dataErr = g_Directory_1__io_replResp_bits_meta_dataErr;
    checks++;
    if (g_Directory_1__io_replResp_bits_mshrId !== i_Directory_1__io_replResp_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_mshrId g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_mshrId, i_Directory_1__io_replResp_bits_mshrId);
    end
    if (g_Directory_1__io_replResp_bits_mshrId !== p_Directory_1__io_replResp_bits_mshrId) t_Directory_1__io_replResp_bits_mshrId = 1'b1;
    p_Directory_1__io_replResp_bits_mshrId = g_Directory_1__io_replResp_bits_mshrId;
    checks++;
    if (g_Directory_1__io_replResp_bits_retry !== i_Directory_1__io_replResp_bits_retry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_retry g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_retry, i_Directory_1__io_replResp_bits_retry);
    end
    if (g_Directory_1__io_replResp_bits_retry !== p_Directory_1__io_replResp_bits_retry) t_Directory_1__io_replResp_bits_retry = 1'b1;
    p_Directory_1__io_replResp_bits_retry = g_Directory_1__io_replResp_bits_retry;
    checks++;
    if (g_Directory_1__io_replResp_bits_error !== i_Directory_1__io_replResp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.io_replResp_bits_error g=%h i=%h", cyc, g_Directory_1__io_replResp_bits_error, i_Directory_1__io_replResp_bits_error);
    end
    if (g_Directory_1__io_replResp_bits_error !== p_Directory_1__io_replResp_bits_error) t_Directory_1__io_replResp_bits_error = 1'b1;
    p_Directory_1__io_replResp_bits_error = g_Directory_1__io_replResp_bits_error;
    checks++;
    if (g_Directory_1__boreChildrenBd_bore_ack !== i_Directory_1__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_Directory_1__boreChildrenBd_bore_ack, i_Directory_1__boreChildrenBd_bore_ack);
    end
    if (g_Directory_1__boreChildrenBd_bore_ack !== p_Directory_1__boreChildrenBd_bore_ack) t_Directory_1__boreChildrenBd_bore_ack = 1'b1;
    p_Directory_1__boreChildrenBd_bore_ack = g_Directory_1__boreChildrenBd_bore_ack;
    checks++;
    if (g_Directory_1__boreChildrenBd_bore_outdata !== i_Directory_1__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_1.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_Directory_1__boreChildrenBd_bore_outdata, i_Directory_1__boreChildrenBd_bore_outdata);
    end
    if (g_Directory_1__boreChildrenBd_bore_outdata !== p_Directory_1__boreChildrenBd_bore_outdata) t_Directory_1__boreChildrenBd_bore_outdata = 1'b1;
    p_Directory_1__boreChildrenBd_bore_outdata = g_Directory_1__boreChildrenBd_bore_outdata;
  endtask
  longint cov_Directory_1_hit = 0;
  longint cov_Directory_1_miss = 0;
  longint cov_Directory_1_repl = 0;
  longint cov_Directory_1_retry = 0;
  longint cov_Directory_1_err = 0;
  longint cov_Directory_1_pselUp = 0;
  longint cov_Directory_1_pselDn = 0;
  longint cov_Directory_1_initDone = 0;
  task automatic cover_Directory_1();
    if (u_g_Directory_1.io_resp_valid && u_g_Directory_1.io_resp_bits_hit) cov_Directory_1_hit++;
    if (u_g_Directory_1.io_resp_valid && !u_g_Directory_1.io_resp_bits_hit) cov_Directory_1_miss++;
    if (u_g_Directory_1.io_replResp_valid) cov_Directory_1_repl++;
    if (u_g_Directory_1.io_replResp_valid && u_g_Directory_1.io_replResp_bits_retry) cov_Directory_1_retry++;
    if (u_g_Directory_1.io_resp_valid && u_g_Directory_1.io_resp_bits_error) cov_Directory_1_err++;
    if (u_g_Directory_1.PSEL > 10'h200) cov_Directory_1_pselUp++;
    if (u_g_Directory_1.refillReqValid_s3 && u_g_Directory_1.match_b && !u_g_Directory_1.hit_s3) cov_Directory_1_pselDn++;
    if (u_g_Directory_1.resetFinish) cov_Directory_1_initDone++;
  endtask
  task automatic preinit_Directory_1();
    foreach (u_g_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.ram[e]) u_g_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.ram[e]) u_g_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.ram[e]) u_g_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.ram[e]) u_g_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_1.metaArray.array.array.array_15_ext.ram[e]) u_g_Directory_1.metaArray.array.array.array_15_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_1.replacer_sram_opt.array.array.array_16_ext.ram[e]) u_g_Directory_1.replacer_sram_opt.array.array.array_16_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_1.origin_bit_opt.array.array.array_17_ext.ram[e]) u_g_Directory_1.origin_bit_opt.array.array.array_17_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
  endtask
  task automatic sync_Directory_1();
    u_i_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_1.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_1.tagArray.array_0_0_0.u_core.rdataReg = u_g_Directory_1.tagArray.array_0_0_0.rdataReg;
    #0 release u_i_Directory_1.tagArray.array_0_0_0.u_core.rdataReg;
    u_i_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_1.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_1.tagArray.array_0_0_1.u_core.rdataReg = u_g_Directory_1.tagArray.array_0_0_1.rdataReg;
    #0 release u_i_Directory_1.tagArray.array_0_0_1.u_core.rdataReg;
    u_i_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_1.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_1.tagArray.array_0_1_0.u_core.rdataReg = u_g_Directory_1.tagArray.array_0_1_0.rdataReg;
    #0 release u_i_Directory_1.tagArray.array_0_1_0.u_core.rdataReg;
    u_i_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_1.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_1.tagArray.array_0_1_1.u_core.rdataReg = u_g_Directory_1.tagArray.array_0_1_1.rdataReg;
    #0 release u_i_Directory_1.tagArray.array_0_1_1.u_core.rdataReg;
    u_i_Directory_1.metaArray.array.array.array_15_ext.ram = u_g_Directory_1.metaArray.array.array.array_15_ext.ram;
    u_i_Directory_1.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g_Directory_1.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i_Directory_1.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g_Directory_1.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i_Directory_1.metaArray.u_core.rdataReg = u_g_Directory_1.metaArray.rdataReg;
    #0 release u_i_Directory_1.metaArray.u_core.rdataReg;
    u_i_Directory_1.replacer_sram_opt.array.array.array_16_ext.ram = u_g_Directory_1.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i_Directory_1.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g_Directory_1.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i_Directory_1.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g_Directory_1.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i_Directory_1.replacer_sram_opt.u_core.rdataReg = u_g_Directory_1.replacer_sram_opt.rdataReg;
    #0 release u_i_Directory_1.replacer_sram_opt.u_core.rdataReg;
    u_i_Directory_1.origin_bit_opt.array.array.array_17_ext.ram = u_g_Directory_1.origin_bit_opt.array.array.array_17_ext.ram;
    u_i_Directory_1.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g_Directory_1.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i_Directory_1.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g_Directory_1.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i_Directory_1.origin_bit_opt.u_core.rdataReg = u_g_Directory_1.origin_bit_opt.rdataReg;
    #0 release u_i_Directory_1.origin_bit_opt.u_core.rdataReg;
  endtask

  // ======================= Directory_2 =======================
  logic Directory_2__io_read_valid;
  logic [30:0] Directory_2__io_read_bits_tag;
  logic [8:0] Directory_2__io_read_bits_set;
  logic [7:0] Directory_2__io_read_bits_wayMask;
  logic [2:0] Directory_2__io_read_bits_replacerInfo_channel;
  logic [2:0] Directory_2__io_read_bits_replacerInfo_opcode;
  logic [4:0] Directory_2__io_read_bits_replacerInfo_reqSource;
  logic Directory_2__io_read_bits_replacerInfo_refill_prefetch;
  logic Directory_2__io_read_bits_refill;
  logic [7:0] Directory_2__io_read_bits_mshrId;
  logic Directory_2__io_read_bits_cmoAll;
  logic [2:0] Directory_2__io_read_bits_cmoWay;
  logic Directory_2__io_metaWReq_valid;
  logic [8:0] Directory_2__io_metaWReq_bits_set;
  logic [7:0] Directory_2__io_metaWReq_bits_wayOH;
  logic Directory_2__io_metaWReq_bits_wmeta_dirty;
  logic [1:0] Directory_2__io_metaWReq_bits_wmeta_state;
  logic Directory_2__io_metaWReq_bits_wmeta_clients;
  logic [1:0] Directory_2__io_metaWReq_bits_wmeta_alias;
  logic Directory_2__io_metaWReq_bits_wmeta_prefetch;
  logic [2:0] Directory_2__io_metaWReq_bits_wmeta_prefetchSrc;
  logic Directory_2__io_metaWReq_bits_wmeta_accessed;
  logic Directory_2__io_metaWReq_bits_wmeta_tagErr;
  logic Directory_2__io_metaWReq_bits_wmeta_dataErr;
  logic Directory_2__io_tagWReq_valid;
  logic [8:0] Directory_2__io_tagWReq_bits_set;
  logic [2:0] Directory_2__io_tagWReq_bits_way;
  logic [30:0] Directory_2__io_tagWReq_bits_wtag;
  logic Directory_2__io_msInfo_0_valid;
  logic [2:0] Directory_2__io_msInfo_0_bits_channel;
  logic [8:0] Directory_2__io_msInfo_0_bits_set;
  logic [2:0] Directory_2__io_msInfo_0_bits_way;
  logic [30:0] Directory_2__io_msInfo_0_bits_reqTag;
  logic Directory_2__io_msInfo_0_bits_willFree;
  logic Directory_2__io_msInfo_0_bits_aliasTask;
  logic Directory_2__io_msInfo_0_bits_needRelease;
  logic Directory_2__io_msInfo_0_bits_blockRefill;
  logic Directory_2__io_msInfo_0_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_0_bits_meta_state;
  logic Directory_2__io_msInfo_0_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_0_bits_meta_alias;
  logic Directory_2__io_msInfo_0_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_0_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_0_bits_meta_accessed;
  logic Directory_2__io_msInfo_0_bits_meta_tagErr;
  logic Directory_2__io_msInfo_0_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_0_bits_metaTag;
  logic Directory_2__io_msInfo_0_bits_dirHit;
  logic Directory_2__io_msInfo_0_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_0_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_0_bits_param;
  logic Directory_2__io_msInfo_0_bits_mergeA;
  logic Directory_2__io_msInfo_0_bits_w_grantfirst;
  logic Directory_2__io_msInfo_0_bits_s_release;
  logic Directory_2__io_msInfo_0_bits_s_refill;
  logic Directory_2__io_msInfo_0_bits_s_cmoresp;
  logic Directory_2__io_msInfo_0_bits_s_cmometaw;
  logic Directory_2__io_msInfo_0_bits_w_releaseack;
  logic Directory_2__io_msInfo_0_bits_w_replResp;
  logic Directory_2__io_msInfo_0_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_0_bits_replaceData;
  logic Directory_2__io_msInfo_0_bits_releaseToClean;
  logic Directory_2__io_msInfo_1_valid;
  logic [2:0] Directory_2__io_msInfo_1_bits_channel;
  logic [8:0] Directory_2__io_msInfo_1_bits_set;
  logic [2:0] Directory_2__io_msInfo_1_bits_way;
  logic [30:0] Directory_2__io_msInfo_1_bits_reqTag;
  logic Directory_2__io_msInfo_1_bits_willFree;
  logic Directory_2__io_msInfo_1_bits_aliasTask;
  logic Directory_2__io_msInfo_1_bits_needRelease;
  logic Directory_2__io_msInfo_1_bits_blockRefill;
  logic Directory_2__io_msInfo_1_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_1_bits_meta_state;
  logic Directory_2__io_msInfo_1_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_1_bits_meta_alias;
  logic Directory_2__io_msInfo_1_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_1_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_1_bits_meta_accessed;
  logic Directory_2__io_msInfo_1_bits_meta_tagErr;
  logic Directory_2__io_msInfo_1_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_1_bits_metaTag;
  logic Directory_2__io_msInfo_1_bits_dirHit;
  logic Directory_2__io_msInfo_1_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_1_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_1_bits_param;
  logic Directory_2__io_msInfo_1_bits_mergeA;
  logic Directory_2__io_msInfo_1_bits_w_grantfirst;
  logic Directory_2__io_msInfo_1_bits_s_release;
  logic Directory_2__io_msInfo_1_bits_s_refill;
  logic Directory_2__io_msInfo_1_bits_s_cmoresp;
  logic Directory_2__io_msInfo_1_bits_s_cmometaw;
  logic Directory_2__io_msInfo_1_bits_w_releaseack;
  logic Directory_2__io_msInfo_1_bits_w_replResp;
  logic Directory_2__io_msInfo_1_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_1_bits_replaceData;
  logic Directory_2__io_msInfo_1_bits_releaseToClean;
  logic Directory_2__io_msInfo_2_valid;
  logic [2:0] Directory_2__io_msInfo_2_bits_channel;
  logic [8:0] Directory_2__io_msInfo_2_bits_set;
  logic [2:0] Directory_2__io_msInfo_2_bits_way;
  logic [30:0] Directory_2__io_msInfo_2_bits_reqTag;
  logic Directory_2__io_msInfo_2_bits_willFree;
  logic Directory_2__io_msInfo_2_bits_aliasTask;
  logic Directory_2__io_msInfo_2_bits_needRelease;
  logic Directory_2__io_msInfo_2_bits_blockRefill;
  logic Directory_2__io_msInfo_2_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_2_bits_meta_state;
  logic Directory_2__io_msInfo_2_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_2_bits_meta_alias;
  logic Directory_2__io_msInfo_2_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_2_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_2_bits_meta_accessed;
  logic Directory_2__io_msInfo_2_bits_meta_tagErr;
  logic Directory_2__io_msInfo_2_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_2_bits_metaTag;
  logic Directory_2__io_msInfo_2_bits_dirHit;
  logic Directory_2__io_msInfo_2_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_2_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_2_bits_param;
  logic Directory_2__io_msInfo_2_bits_mergeA;
  logic Directory_2__io_msInfo_2_bits_w_grantfirst;
  logic Directory_2__io_msInfo_2_bits_s_release;
  logic Directory_2__io_msInfo_2_bits_s_refill;
  logic Directory_2__io_msInfo_2_bits_s_cmoresp;
  logic Directory_2__io_msInfo_2_bits_s_cmometaw;
  logic Directory_2__io_msInfo_2_bits_w_releaseack;
  logic Directory_2__io_msInfo_2_bits_w_replResp;
  logic Directory_2__io_msInfo_2_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_2_bits_replaceData;
  logic Directory_2__io_msInfo_2_bits_releaseToClean;
  logic Directory_2__io_msInfo_3_valid;
  logic [2:0] Directory_2__io_msInfo_3_bits_channel;
  logic [8:0] Directory_2__io_msInfo_3_bits_set;
  logic [2:0] Directory_2__io_msInfo_3_bits_way;
  logic [30:0] Directory_2__io_msInfo_3_bits_reqTag;
  logic Directory_2__io_msInfo_3_bits_willFree;
  logic Directory_2__io_msInfo_3_bits_aliasTask;
  logic Directory_2__io_msInfo_3_bits_needRelease;
  logic Directory_2__io_msInfo_3_bits_blockRefill;
  logic Directory_2__io_msInfo_3_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_3_bits_meta_state;
  logic Directory_2__io_msInfo_3_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_3_bits_meta_alias;
  logic Directory_2__io_msInfo_3_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_3_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_3_bits_meta_accessed;
  logic Directory_2__io_msInfo_3_bits_meta_tagErr;
  logic Directory_2__io_msInfo_3_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_3_bits_metaTag;
  logic Directory_2__io_msInfo_3_bits_dirHit;
  logic Directory_2__io_msInfo_3_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_3_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_3_bits_param;
  logic Directory_2__io_msInfo_3_bits_mergeA;
  logic Directory_2__io_msInfo_3_bits_w_grantfirst;
  logic Directory_2__io_msInfo_3_bits_s_release;
  logic Directory_2__io_msInfo_3_bits_s_refill;
  logic Directory_2__io_msInfo_3_bits_s_cmoresp;
  logic Directory_2__io_msInfo_3_bits_s_cmometaw;
  logic Directory_2__io_msInfo_3_bits_w_releaseack;
  logic Directory_2__io_msInfo_3_bits_w_replResp;
  logic Directory_2__io_msInfo_3_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_3_bits_replaceData;
  logic Directory_2__io_msInfo_3_bits_releaseToClean;
  logic Directory_2__io_msInfo_4_valid;
  logic [2:0] Directory_2__io_msInfo_4_bits_channel;
  logic [8:0] Directory_2__io_msInfo_4_bits_set;
  logic [2:0] Directory_2__io_msInfo_4_bits_way;
  logic [30:0] Directory_2__io_msInfo_4_bits_reqTag;
  logic Directory_2__io_msInfo_4_bits_willFree;
  logic Directory_2__io_msInfo_4_bits_aliasTask;
  logic Directory_2__io_msInfo_4_bits_needRelease;
  logic Directory_2__io_msInfo_4_bits_blockRefill;
  logic Directory_2__io_msInfo_4_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_4_bits_meta_state;
  logic Directory_2__io_msInfo_4_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_4_bits_meta_alias;
  logic Directory_2__io_msInfo_4_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_4_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_4_bits_meta_accessed;
  logic Directory_2__io_msInfo_4_bits_meta_tagErr;
  logic Directory_2__io_msInfo_4_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_4_bits_metaTag;
  logic Directory_2__io_msInfo_4_bits_dirHit;
  logic Directory_2__io_msInfo_4_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_4_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_4_bits_param;
  logic Directory_2__io_msInfo_4_bits_mergeA;
  logic Directory_2__io_msInfo_4_bits_w_grantfirst;
  logic Directory_2__io_msInfo_4_bits_s_release;
  logic Directory_2__io_msInfo_4_bits_s_refill;
  logic Directory_2__io_msInfo_4_bits_s_cmoresp;
  logic Directory_2__io_msInfo_4_bits_s_cmometaw;
  logic Directory_2__io_msInfo_4_bits_w_releaseack;
  logic Directory_2__io_msInfo_4_bits_w_replResp;
  logic Directory_2__io_msInfo_4_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_4_bits_replaceData;
  logic Directory_2__io_msInfo_4_bits_releaseToClean;
  logic Directory_2__io_msInfo_5_valid;
  logic [2:0] Directory_2__io_msInfo_5_bits_channel;
  logic [8:0] Directory_2__io_msInfo_5_bits_set;
  logic [2:0] Directory_2__io_msInfo_5_bits_way;
  logic [30:0] Directory_2__io_msInfo_5_bits_reqTag;
  logic Directory_2__io_msInfo_5_bits_willFree;
  logic Directory_2__io_msInfo_5_bits_aliasTask;
  logic Directory_2__io_msInfo_5_bits_needRelease;
  logic Directory_2__io_msInfo_5_bits_blockRefill;
  logic Directory_2__io_msInfo_5_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_5_bits_meta_state;
  logic Directory_2__io_msInfo_5_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_5_bits_meta_alias;
  logic Directory_2__io_msInfo_5_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_5_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_5_bits_meta_accessed;
  logic Directory_2__io_msInfo_5_bits_meta_tagErr;
  logic Directory_2__io_msInfo_5_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_5_bits_metaTag;
  logic Directory_2__io_msInfo_5_bits_dirHit;
  logic Directory_2__io_msInfo_5_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_5_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_5_bits_param;
  logic Directory_2__io_msInfo_5_bits_mergeA;
  logic Directory_2__io_msInfo_5_bits_w_grantfirst;
  logic Directory_2__io_msInfo_5_bits_s_release;
  logic Directory_2__io_msInfo_5_bits_s_refill;
  logic Directory_2__io_msInfo_5_bits_s_cmoresp;
  logic Directory_2__io_msInfo_5_bits_s_cmometaw;
  logic Directory_2__io_msInfo_5_bits_w_releaseack;
  logic Directory_2__io_msInfo_5_bits_w_replResp;
  logic Directory_2__io_msInfo_5_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_5_bits_replaceData;
  logic Directory_2__io_msInfo_5_bits_releaseToClean;
  logic Directory_2__io_msInfo_6_valid;
  logic [2:0] Directory_2__io_msInfo_6_bits_channel;
  logic [8:0] Directory_2__io_msInfo_6_bits_set;
  logic [2:0] Directory_2__io_msInfo_6_bits_way;
  logic [30:0] Directory_2__io_msInfo_6_bits_reqTag;
  logic Directory_2__io_msInfo_6_bits_willFree;
  logic Directory_2__io_msInfo_6_bits_aliasTask;
  logic Directory_2__io_msInfo_6_bits_needRelease;
  logic Directory_2__io_msInfo_6_bits_blockRefill;
  logic Directory_2__io_msInfo_6_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_6_bits_meta_state;
  logic Directory_2__io_msInfo_6_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_6_bits_meta_alias;
  logic Directory_2__io_msInfo_6_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_6_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_6_bits_meta_accessed;
  logic Directory_2__io_msInfo_6_bits_meta_tagErr;
  logic Directory_2__io_msInfo_6_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_6_bits_metaTag;
  logic Directory_2__io_msInfo_6_bits_dirHit;
  logic Directory_2__io_msInfo_6_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_6_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_6_bits_param;
  logic Directory_2__io_msInfo_6_bits_mergeA;
  logic Directory_2__io_msInfo_6_bits_w_grantfirst;
  logic Directory_2__io_msInfo_6_bits_s_release;
  logic Directory_2__io_msInfo_6_bits_s_refill;
  logic Directory_2__io_msInfo_6_bits_s_cmoresp;
  logic Directory_2__io_msInfo_6_bits_s_cmometaw;
  logic Directory_2__io_msInfo_6_bits_w_releaseack;
  logic Directory_2__io_msInfo_6_bits_w_replResp;
  logic Directory_2__io_msInfo_6_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_6_bits_replaceData;
  logic Directory_2__io_msInfo_6_bits_releaseToClean;
  logic Directory_2__io_msInfo_7_valid;
  logic [2:0] Directory_2__io_msInfo_7_bits_channel;
  logic [8:0] Directory_2__io_msInfo_7_bits_set;
  logic [2:0] Directory_2__io_msInfo_7_bits_way;
  logic [30:0] Directory_2__io_msInfo_7_bits_reqTag;
  logic Directory_2__io_msInfo_7_bits_willFree;
  logic Directory_2__io_msInfo_7_bits_aliasTask;
  logic Directory_2__io_msInfo_7_bits_needRelease;
  logic Directory_2__io_msInfo_7_bits_blockRefill;
  logic Directory_2__io_msInfo_7_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_7_bits_meta_state;
  logic Directory_2__io_msInfo_7_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_7_bits_meta_alias;
  logic Directory_2__io_msInfo_7_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_7_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_7_bits_meta_accessed;
  logic Directory_2__io_msInfo_7_bits_meta_tagErr;
  logic Directory_2__io_msInfo_7_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_7_bits_metaTag;
  logic Directory_2__io_msInfo_7_bits_dirHit;
  logic Directory_2__io_msInfo_7_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_7_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_7_bits_param;
  logic Directory_2__io_msInfo_7_bits_mergeA;
  logic Directory_2__io_msInfo_7_bits_w_grantfirst;
  logic Directory_2__io_msInfo_7_bits_s_release;
  logic Directory_2__io_msInfo_7_bits_s_refill;
  logic Directory_2__io_msInfo_7_bits_s_cmoresp;
  logic Directory_2__io_msInfo_7_bits_s_cmometaw;
  logic Directory_2__io_msInfo_7_bits_w_releaseack;
  logic Directory_2__io_msInfo_7_bits_w_replResp;
  logic Directory_2__io_msInfo_7_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_7_bits_replaceData;
  logic Directory_2__io_msInfo_7_bits_releaseToClean;
  logic Directory_2__io_msInfo_8_valid;
  logic [2:0] Directory_2__io_msInfo_8_bits_channel;
  logic [8:0] Directory_2__io_msInfo_8_bits_set;
  logic [2:0] Directory_2__io_msInfo_8_bits_way;
  logic [30:0] Directory_2__io_msInfo_8_bits_reqTag;
  logic Directory_2__io_msInfo_8_bits_willFree;
  logic Directory_2__io_msInfo_8_bits_aliasTask;
  logic Directory_2__io_msInfo_8_bits_needRelease;
  logic Directory_2__io_msInfo_8_bits_blockRefill;
  logic Directory_2__io_msInfo_8_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_8_bits_meta_state;
  logic Directory_2__io_msInfo_8_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_8_bits_meta_alias;
  logic Directory_2__io_msInfo_8_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_8_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_8_bits_meta_accessed;
  logic Directory_2__io_msInfo_8_bits_meta_tagErr;
  logic Directory_2__io_msInfo_8_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_8_bits_metaTag;
  logic Directory_2__io_msInfo_8_bits_dirHit;
  logic Directory_2__io_msInfo_8_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_8_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_8_bits_param;
  logic Directory_2__io_msInfo_8_bits_mergeA;
  logic Directory_2__io_msInfo_8_bits_w_grantfirst;
  logic Directory_2__io_msInfo_8_bits_s_release;
  logic Directory_2__io_msInfo_8_bits_s_refill;
  logic Directory_2__io_msInfo_8_bits_s_cmoresp;
  logic Directory_2__io_msInfo_8_bits_s_cmometaw;
  logic Directory_2__io_msInfo_8_bits_w_releaseack;
  logic Directory_2__io_msInfo_8_bits_w_replResp;
  logic Directory_2__io_msInfo_8_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_8_bits_replaceData;
  logic Directory_2__io_msInfo_8_bits_releaseToClean;
  logic Directory_2__io_msInfo_9_valid;
  logic [2:0] Directory_2__io_msInfo_9_bits_channel;
  logic [8:0] Directory_2__io_msInfo_9_bits_set;
  logic [2:0] Directory_2__io_msInfo_9_bits_way;
  logic [30:0] Directory_2__io_msInfo_9_bits_reqTag;
  logic Directory_2__io_msInfo_9_bits_willFree;
  logic Directory_2__io_msInfo_9_bits_aliasTask;
  logic Directory_2__io_msInfo_9_bits_needRelease;
  logic Directory_2__io_msInfo_9_bits_blockRefill;
  logic Directory_2__io_msInfo_9_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_9_bits_meta_state;
  logic Directory_2__io_msInfo_9_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_9_bits_meta_alias;
  logic Directory_2__io_msInfo_9_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_9_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_9_bits_meta_accessed;
  logic Directory_2__io_msInfo_9_bits_meta_tagErr;
  logic Directory_2__io_msInfo_9_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_9_bits_metaTag;
  logic Directory_2__io_msInfo_9_bits_dirHit;
  logic Directory_2__io_msInfo_9_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_9_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_9_bits_param;
  logic Directory_2__io_msInfo_9_bits_mergeA;
  logic Directory_2__io_msInfo_9_bits_w_grantfirst;
  logic Directory_2__io_msInfo_9_bits_s_release;
  logic Directory_2__io_msInfo_9_bits_s_refill;
  logic Directory_2__io_msInfo_9_bits_s_cmoresp;
  logic Directory_2__io_msInfo_9_bits_s_cmometaw;
  logic Directory_2__io_msInfo_9_bits_w_releaseack;
  logic Directory_2__io_msInfo_9_bits_w_replResp;
  logic Directory_2__io_msInfo_9_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_9_bits_replaceData;
  logic Directory_2__io_msInfo_9_bits_releaseToClean;
  logic Directory_2__io_msInfo_10_valid;
  logic [2:0] Directory_2__io_msInfo_10_bits_channel;
  logic [8:0] Directory_2__io_msInfo_10_bits_set;
  logic [2:0] Directory_2__io_msInfo_10_bits_way;
  logic [30:0] Directory_2__io_msInfo_10_bits_reqTag;
  logic Directory_2__io_msInfo_10_bits_willFree;
  logic Directory_2__io_msInfo_10_bits_aliasTask;
  logic Directory_2__io_msInfo_10_bits_needRelease;
  logic Directory_2__io_msInfo_10_bits_blockRefill;
  logic Directory_2__io_msInfo_10_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_10_bits_meta_state;
  logic Directory_2__io_msInfo_10_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_10_bits_meta_alias;
  logic Directory_2__io_msInfo_10_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_10_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_10_bits_meta_accessed;
  logic Directory_2__io_msInfo_10_bits_meta_tagErr;
  logic Directory_2__io_msInfo_10_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_10_bits_metaTag;
  logic Directory_2__io_msInfo_10_bits_dirHit;
  logic Directory_2__io_msInfo_10_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_10_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_10_bits_param;
  logic Directory_2__io_msInfo_10_bits_mergeA;
  logic Directory_2__io_msInfo_10_bits_w_grantfirst;
  logic Directory_2__io_msInfo_10_bits_s_release;
  logic Directory_2__io_msInfo_10_bits_s_refill;
  logic Directory_2__io_msInfo_10_bits_s_cmoresp;
  logic Directory_2__io_msInfo_10_bits_s_cmometaw;
  logic Directory_2__io_msInfo_10_bits_w_releaseack;
  logic Directory_2__io_msInfo_10_bits_w_replResp;
  logic Directory_2__io_msInfo_10_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_10_bits_replaceData;
  logic Directory_2__io_msInfo_10_bits_releaseToClean;
  logic Directory_2__io_msInfo_11_valid;
  logic [2:0] Directory_2__io_msInfo_11_bits_channel;
  logic [8:0] Directory_2__io_msInfo_11_bits_set;
  logic [2:0] Directory_2__io_msInfo_11_bits_way;
  logic [30:0] Directory_2__io_msInfo_11_bits_reqTag;
  logic Directory_2__io_msInfo_11_bits_willFree;
  logic Directory_2__io_msInfo_11_bits_aliasTask;
  logic Directory_2__io_msInfo_11_bits_needRelease;
  logic Directory_2__io_msInfo_11_bits_blockRefill;
  logic Directory_2__io_msInfo_11_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_11_bits_meta_state;
  logic Directory_2__io_msInfo_11_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_11_bits_meta_alias;
  logic Directory_2__io_msInfo_11_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_11_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_11_bits_meta_accessed;
  logic Directory_2__io_msInfo_11_bits_meta_tagErr;
  logic Directory_2__io_msInfo_11_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_11_bits_metaTag;
  logic Directory_2__io_msInfo_11_bits_dirHit;
  logic Directory_2__io_msInfo_11_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_11_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_11_bits_param;
  logic Directory_2__io_msInfo_11_bits_mergeA;
  logic Directory_2__io_msInfo_11_bits_w_grantfirst;
  logic Directory_2__io_msInfo_11_bits_s_release;
  logic Directory_2__io_msInfo_11_bits_s_refill;
  logic Directory_2__io_msInfo_11_bits_s_cmoresp;
  logic Directory_2__io_msInfo_11_bits_s_cmometaw;
  logic Directory_2__io_msInfo_11_bits_w_releaseack;
  logic Directory_2__io_msInfo_11_bits_w_replResp;
  logic Directory_2__io_msInfo_11_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_11_bits_replaceData;
  logic Directory_2__io_msInfo_11_bits_releaseToClean;
  logic Directory_2__io_msInfo_12_valid;
  logic [2:0] Directory_2__io_msInfo_12_bits_channel;
  logic [8:0] Directory_2__io_msInfo_12_bits_set;
  logic [2:0] Directory_2__io_msInfo_12_bits_way;
  logic [30:0] Directory_2__io_msInfo_12_bits_reqTag;
  logic Directory_2__io_msInfo_12_bits_willFree;
  logic Directory_2__io_msInfo_12_bits_aliasTask;
  logic Directory_2__io_msInfo_12_bits_needRelease;
  logic Directory_2__io_msInfo_12_bits_blockRefill;
  logic Directory_2__io_msInfo_12_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_12_bits_meta_state;
  logic Directory_2__io_msInfo_12_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_12_bits_meta_alias;
  logic Directory_2__io_msInfo_12_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_12_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_12_bits_meta_accessed;
  logic Directory_2__io_msInfo_12_bits_meta_tagErr;
  logic Directory_2__io_msInfo_12_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_12_bits_metaTag;
  logic Directory_2__io_msInfo_12_bits_dirHit;
  logic Directory_2__io_msInfo_12_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_12_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_12_bits_param;
  logic Directory_2__io_msInfo_12_bits_mergeA;
  logic Directory_2__io_msInfo_12_bits_w_grantfirst;
  logic Directory_2__io_msInfo_12_bits_s_release;
  logic Directory_2__io_msInfo_12_bits_s_refill;
  logic Directory_2__io_msInfo_12_bits_s_cmoresp;
  logic Directory_2__io_msInfo_12_bits_s_cmometaw;
  logic Directory_2__io_msInfo_12_bits_w_releaseack;
  logic Directory_2__io_msInfo_12_bits_w_replResp;
  logic Directory_2__io_msInfo_12_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_12_bits_replaceData;
  logic Directory_2__io_msInfo_12_bits_releaseToClean;
  logic Directory_2__io_msInfo_13_valid;
  logic [2:0] Directory_2__io_msInfo_13_bits_channel;
  logic [8:0] Directory_2__io_msInfo_13_bits_set;
  logic [2:0] Directory_2__io_msInfo_13_bits_way;
  logic [30:0] Directory_2__io_msInfo_13_bits_reqTag;
  logic Directory_2__io_msInfo_13_bits_willFree;
  logic Directory_2__io_msInfo_13_bits_aliasTask;
  logic Directory_2__io_msInfo_13_bits_needRelease;
  logic Directory_2__io_msInfo_13_bits_blockRefill;
  logic Directory_2__io_msInfo_13_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_13_bits_meta_state;
  logic Directory_2__io_msInfo_13_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_13_bits_meta_alias;
  logic Directory_2__io_msInfo_13_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_13_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_13_bits_meta_accessed;
  logic Directory_2__io_msInfo_13_bits_meta_tagErr;
  logic Directory_2__io_msInfo_13_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_13_bits_metaTag;
  logic Directory_2__io_msInfo_13_bits_dirHit;
  logic Directory_2__io_msInfo_13_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_13_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_13_bits_param;
  logic Directory_2__io_msInfo_13_bits_mergeA;
  logic Directory_2__io_msInfo_13_bits_w_grantfirst;
  logic Directory_2__io_msInfo_13_bits_s_release;
  logic Directory_2__io_msInfo_13_bits_s_refill;
  logic Directory_2__io_msInfo_13_bits_s_cmoresp;
  logic Directory_2__io_msInfo_13_bits_s_cmometaw;
  logic Directory_2__io_msInfo_13_bits_w_releaseack;
  logic Directory_2__io_msInfo_13_bits_w_replResp;
  logic Directory_2__io_msInfo_13_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_13_bits_replaceData;
  logic Directory_2__io_msInfo_13_bits_releaseToClean;
  logic Directory_2__io_msInfo_14_valid;
  logic [2:0] Directory_2__io_msInfo_14_bits_channel;
  logic [8:0] Directory_2__io_msInfo_14_bits_set;
  logic [2:0] Directory_2__io_msInfo_14_bits_way;
  logic [30:0] Directory_2__io_msInfo_14_bits_reqTag;
  logic Directory_2__io_msInfo_14_bits_willFree;
  logic Directory_2__io_msInfo_14_bits_aliasTask;
  logic Directory_2__io_msInfo_14_bits_needRelease;
  logic Directory_2__io_msInfo_14_bits_blockRefill;
  logic Directory_2__io_msInfo_14_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_14_bits_meta_state;
  logic Directory_2__io_msInfo_14_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_14_bits_meta_alias;
  logic Directory_2__io_msInfo_14_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_14_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_14_bits_meta_accessed;
  logic Directory_2__io_msInfo_14_bits_meta_tagErr;
  logic Directory_2__io_msInfo_14_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_14_bits_metaTag;
  logic Directory_2__io_msInfo_14_bits_dirHit;
  logic Directory_2__io_msInfo_14_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_14_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_14_bits_param;
  logic Directory_2__io_msInfo_14_bits_mergeA;
  logic Directory_2__io_msInfo_14_bits_w_grantfirst;
  logic Directory_2__io_msInfo_14_bits_s_release;
  logic Directory_2__io_msInfo_14_bits_s_refill;
  logic Directory_2__io_msInfo_14_bits_s_cmoresp;
  logic Directory_2__io_msInfo_14_bits_s_cmometaw;
  logic Directory_2__io_msInfo_14_bits_w_releaseack;
  logic Directory_2__io_msInfo_14_bits_w_replResp;
  logic Directory_2__io_msInfo_14_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_14_bits_replaceData;
  logic Directory_2__io_msInfo_14_bits_releaseToClean;
  logic Directory_2__io_msInfo_15_valid;
  logic [2:0] Directory_2__io_msInfo_15_bits_channel;
  logic [8:0] Directory_2__io_msInfo_15_bits_set;
  logic [2:0] Directory_2__io_msInfo_15_bits_way;
  logic [30:0] Directory_2__io_msInfo_15_bits_reqTag;
  logic Directory_2__io_msInfo_15_bits_willFree;
  logic Directory_2__io_msInfo_15_bits_aliasTask;
  logic Directory_2__io_msInfo_15_bits_needRelease;
  logic Directory_2__io_msInfo_15_bits_blockRefill;
  logic Directory_2__io_msInfo_15_bits_meta_dirty;
  logic [1:0] Directory_2__io_msInfo_15_bits_meta_state;
  logic Directory_2__io_msInfo_15_bits_meta_clients;
  logic [1:0] Directory_2__io_msInfo_15_bits_meta_alias;
  logic Directory_2__io_msInfo_15_bits_meta_prefetch;
  logic [2:0] Directory_2__io_msInfo_15_bits_meta_prefetchSrc;
  logic Directory_2__io_msInfo_15_bits_meta_accessed;
  logic Directory_2__io_msInfo_15_bits_meta_tagErr;
  logic Directory_2__io_msInfo_15_bits_meta_dataErr;
  logic [30:0] Directory_2__io_msInfo_15_bits_metaTag;
  logic Directory_2__io_msInfo_15_bits_dirHit;
  logic Directory_2__io_msInfo_15_bits_isAcqOrPrefetch;
  logic Directory_2__io_msInfo_15_bits_isPrefetch;
  logic [2:0] Directory_2__io_msInfo_15_bits_param;
  logic Directory_2__io_msInfo_15_bits_mergeA;
  logic Directory_2__io_msInfo_15_bits_w_grantfirst;
  logic Directory_2__io_msInfo_15_bits_s_release;
  logic Directory_2__io_msInfo_15_bits_s_refill;
  logic Directory_2__io_msInfo_15_bits_s_cmoresp;
  logic Directory_2__io_msInfo_15_bits_s_cmometaw;
  logic Directory_2__io_msInfo_15_bits_w_releaseack;
  logic Directory_2__io_msInfo_15_bits_w_replResp;
  logic Directory_2__io_msInfo_15_bits_w_rprobeacklast;
  logic Directory_2__io_msInfo_15_bits_replaceData;
  logic Directory_2__io_msInfo_15_bits_releaseToClean;
  logic [4:0] Directory_2__boreChildrenBd_bore_array;
  logic Directory_2__boreChildrenBd_bore_all;
  logic Directory_2__boreChildrenBd_bore_req;
  logic Directory_2__boreChildrenBd_bore_writeen;
  logic [7:0] Directory_2__boreChildrenBd_bore_be;
  logic [9:0] Directory_2__boreChildrenBd_bore_addr;
  logic [103:0] Directory_2__boreChildrenBd_bore_indata;
  logic Directory_2__boreChildrenBd_bore_readen;
  logic [9:0] Directory_2__boreChildrenBd_bore_addr_rd;
  logic Directory_2__sigFromSrams_bore_ram_hold;
  logic Directory_2__sigFromSrams_bore_ram_bypass;
  logic Directory_2__sigFromSrams_bore_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_cgen;
  logic Directory_2__sigFromSrams_bore_1_ram_hold;
  logic Directory_2__sigFromSrams_bore_1_ram_bypass;
  logic Directory_2__sigFromSrams_bore_1_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_1_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_1_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_1_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_1_cgen;
  logic Directory_2__sigFromSrams_bore_2_ram_hold;
  logic Directory_2__sigFromSrams_bore_2_ram_bypass;
  logic Directory_2__sigFromSrams_bore_2_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_2_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_2_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_2_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_2_cgen;
  logic Directory_2__sigFromSrams_bore_3_ram_hold;
  logic Directory_2__sigFromSrams_bore_3_ram_bypass;
  logic Directory_2__sigFromSrams_bore_3_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_3_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_3_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_3_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_3_cgen;
  logic Directory_2__sigFromSrams_bore_4_ram_hold;
  logic Directory_2__sigFromSrams_bore_4_ram_bypass;
  logic Directory_2__sigFromSrams_bore_4_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_4_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_4_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_4_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_4_cgen;
  logic Directory_2__sigFromSrams_bore_5_ram_hold;
  logic Directory_2__sigFromSrams_bore_5_ram_bypass;
  logic Directory_2__sigFromSrams_bore_5_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_5_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_5_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_5_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_5_cgen;
  logic Directory_2__sigFromSrams_bore_6_ram_hold;
  logic Directory_2__sigFromSrams_bore_6_ram_bypass;
  logic Directory_2__sigFromSrams_bore_6_ram_bp_clken;
  logic Directory_2__sigFromSrams_bore_6_ram_aux_clk;
  logic Directory_2__sigFromSrams_bore_6_ram_aux_ckbp;
  logic Directory_2__sigFromSrams_bore_6_ram_mcp_hold;
  logic Directory_2__sigFromSrams_bore_6_cgen;
  wire  g_Directory_2__io_read_ready;
  wire  i_Directory_2__io_read_ready;
  logic p_Directory_2__io_read_ready;
  bit   t_Directory_2__io_read_ready;
  wire  g_Directory_2__io_resp_valid;
  wire  i_Directory_2__io_resp_valid;
  logic p_Directory_2__io_resp_valid;
  bit   t_Directory_2__io_resp_valid;
  wire  g_Directory_2__io_resp_bits_hit;
  wire  i_Directory_2__io_resp_bits_hit;
  logic p_Directory_2__io_resp_bits_hit;
  bit   t_Directory_2__io_resp_bits_hit;
  wire  [30:0] g_Directory_2__io_resp_bits_tag;
  wire  [30:0] i_Directory_2__io_resp_bits_tag;
  logic [30:0] p_Directory_2__io_resp_bits_tag;
  bit   t_Directory_2__io_resp_bits_tag;
  wire  [8:0] g_Directory_2__io_resp_bits_set;
  wire  [8:0] i_Directory_2__io_resp_bits_set;
  logic [8:0] p_Directory_2__io_resp_bits_set;
  bit   t_Directory_2__io_resp_bits_set;
  wire  [2:0] g_Directory_2__io_resp_bits_way;
  wire  [2:0] i_Directory_2__io_resp_bits_way;
  logic [2:0] p_Directory_2__io_resp_bits_way;
  bit   t_Directory_2__io_resp_bits_way;
  wire  g_Directory_2__io_resp_bits_meta_dirty;
  wire  i_Directory_2__io_resp_bits_meta_dirty;
  logic p_Directory_2__io_resp_bits_meta_dirty;
  bit   t_Directory_2__io_resp_bits_meta_dirty;
  wire  [1:0] g_Directory_2__io_resp_bits_meta_state;
  wire  [1:0] i_Directory_2__io_resp_bits_meta_state;
  logic [1:0] p_Directory_2__io_resp_bits_meta_state;
  bit   t_Directory_2__io_resp_bits_meta_state;
  wire  g_Directory_2__io_resp_bits_meta_clients;
  wire  i_Directory_2__io_resp_bits_meta_clients;
  logic p_Directory_2__io_resp_bits_meta_clients;
  bit   t_Directory_2__io_resp_bits_meta_clients;
  wire  [1:0] g_Directory_2__io_resp_bits_meta_alias;
  wire  [1:0] i_Directory_2__io_resp_bits_meta_alias;
  logic [1:0] p_Directory_2__io_resp_bits_meta_alias;
  bit   t_Directory_2__io_resp_bits_meta_alias;
  wire  g_Directory_2__io_resp_bits_meta_prefetch;
  wire  i_Directory_2__io_resp_bits_meta_prefetch;
  logic p_Directory_2__io_resp_bits_meta_prefetch;
  bit   t_Directory_2__io_resp_bits_meta_prefetch;
  wire  [2:0] g_Directory_2__io_resp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory_2__io_resp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory_2__io_resp_bits_meta_prefetchSrc;
  bit   t_Directory_2__io_resp_bits_meta_prefetchSrc;
  wire  g_Directory_2__io_resp_bits_meta_accessed;
  wire  i_Directory_2__io_resp_bits_meta_accessed;
  logic p_Directory_2__io_resp_bits_meta_accessed;
  bit   t_Directory_2__io_resp_bits_meta_accessed;
  wire  g_Directory_2__io_resp_bits_meta_tagErr;
  wire  i_Directory_2__io_resp_bits_meta_tagErr;
  logic p_Directory_2__io_resp_bits_meta_tagErr;
  bit   t_Directory_2__io_resp_bits_meta_tagErr;
  wire  g_Directory_2__io_resp_bits_meta_dataErr;
  wire  i_Directory_2__io_resp_bits_meta_dataErr;
  logic p_Directory_2__io_resp_bits_meta_dataErr;
  bit   t_Directory_2__io_resp_bits_meta_dataErr;
  wire  g_Directory_2__io_resp_bits_error;
  wire  i_Directory_2__io_resp_bits_error;
  logic p_Directory_2__io_resp_bits_error;
  bit   t_Directory_2__io_resp_bits_error;
  wire  [2:0] g_Directory_2__io_resp_bits_replacerInfo_channel;
  wire  [2:0] i_Directory_2__io_resp_bits_replacerInfo_channel;
  logic [2:0] p_Directory_2__io_resp_bits_replacerInfo_channel;
  bit   t_Directory_2__io_resp_bits_replacerInfo_channel;
  wire  [2:0] g_Directory_2__io_resp_bits_replacerInfo_opcode;
  wire  [2:0] i_Directory_2__io_resp_bits_replacerInfo_opcode;
  logic [2:0] p_Directory_2__io_resp_bits_replacerInfo_opcode;
  bit   t_Directory_2__io_resp_bits_replacerInfo_opcode;
  wire  [4:0] g_Directory_2__io_resp_bits_replacerInfo_reqSource;
  wire  [4:0] i_Directory_2__io_resp_bits_replacerInfo_reqSource;
  logic [4:0] p_Directory_2__io_resp_bits_replacerInfo_reqSource;
  bit   t_Directory_2__io_resp_bits_replacerInfo_reqSource;
  wire  g_Directory_2__io_resp_bits_replacerInfo_refill_prefetch;
  wire  i_Directory_2__io_resp_bits_replacerInfo_refill_prefetch;
  logic p_Directory_2__io_resp_bits_replacerInfo_refill_prefetch;
  bit   t_Directory_2__io_resp_bits_replacerInfo_refill_prefetch;
  wire  g_Directory_2__io_replResp_valid;
  wire  i_Directory_2__io_replResp_valid;
  logic p_Directory_2__io_replResp_valid;
  bit   t_Directory_2__io_replResp_valid;
  wire  [30:0] g_Directory_2__io_replResp_bits_tag;
  wire  [30:0] i_Directory_2__io_replResp_bits_tag;
  logic [30:0] p_Directory_2__io_replResp_bits_tag;
  bit   t_Directory_2__io_replResp_bits_tag;
  wire  [8:0] g_Directory_2__io_replResp_bits_set;
  wire  [8:0] i_Directory_2__io_replResp_bits_set;
  logic [8:0] p_Directory_2__io_replResp_bits_set;
  bit   t_Directory_2__io_replResp_bits_set;
  wire  [2:0] g_Directory_2__io_replResp_bits_way;
  wire  [2:0] i_Directory_2__io_replResp_bits_way;
  logic [2:0] p_Directory_2__io_replResp_bits_way;
  bit   t_Directory_2__io_replResp_bits_way;
  wire  g_Directory_2__io_replResp_bits_meta_dirty;
  wire  i_Directory_2__io_replResp_bits_meta_dirty;
  logic p_Directory_2__io_replResp_bits_meta_dirty;
  bit   t_Directory_2__io_replResp_bits_meta_dirty;
  wire  [1:0] g_Directory_2__io_replResp_bits_meta_state;
  wire  [1:0] i_Directory_2__io_replResp_bits_meta_state;
  logic [1:0] p_Directory_2__io_replResp_bits_meta_state;
  bit   t_Directory_2__io_replResp_bits_meta_state;
  wire  g_Directory_2__io_replResp_bits_meta_clients;
  wire  i_Directory_2__io_replResp_bits_meta_clients;
  logic p_Directory_2__io_replResp_bits_meta_clients;
  bit   t_Directory_2__io_replResp_bits_meta_clients;
  wire  [1:0] g_Directory_2__io_replResp_bits_meta_alias;
  wire  [1:0] i_Directory_2__io_replResp_bits_meta_alias;
  logic [1:0] p_Directory_2__io_replResp_bits_meta_alias;
  bit   t_Directory_2__io_replResp_bits_meta_alias;
  wire  g_Directory_2__io_replResp_bits_meta_prefetch;
  wire  i_Directory_2__io_replResp_bits_meta_prefetch;
  logic p_Directory_2__io_replResp_bits_meta_prefetch;
  bit   t_Directory_2__io_replResp_bits_meta_prefetch;
  wire  [2:0] g_Directory_2__io_replResp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory_2__io_replResp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory_2__io_replResp_bits_meta_prefetchSrc;
  bit   t_Directory_2__io_replResp_bits_meta_prefetchSrc;
  wire  g_Directory_2__io_replResp_bits_meta_accessed;
  wire  i_Directory_2__io_replResp_bits_meta_accessed;
  logic p_Directory_2__io_replResp_bits_meta_accessed;
  bit   t_Directory_2__io_replResp_bits_meta_accessed;
  wire  g_Directory_2__io_replResp_bits_meta_tagErr;
  wire  i_Directory_2__io_replResp_bits_meta_tagErr;
  logic p_Directory_2__io_replResp_bits_meta_tagErr;
  bit   t_Directory_2__io_replResp_bits_meta_tagErr;
  wire  g_Directory_2__io_replResp_bits_meta_dataErr;
  wire  i_Directory_2__io_replResp_bits_meta_dataErr;
  logic p_Directory_2__io_replResp_bits_meta_dataErr;
  bit   t_Directory_2__io_replResp_bits_meta_dataErr;
  wire  [7:0] g_Directory_2__io_replResp_bits_mshrId;
  wire  [7:0] i_Directory_2__io_replResp_bits_mshrId;
  logic [7:0] p_Directory_2__io_replResp_bits_mshrId;
  bit   t_Directory_2__io_replResp_bits_mshrId;
  wire  g_Directory_2__io_replResp_bits_retry;
  wire  i_Directory_2__io_replResp_bits_retry;
  logic p_Directory_2__io_replResp_bits_retry;
  bit   t_Directory_2__io_replResp_bits_retry;
  wire  g_Directory_2__io_replResp_bits_error;
  wire  i_Directory_2__io_replResp_bits_error;
  logic p_Directory_2__io_replResp_bits_error;
  bit   t_Directory_2__io_replResp_bits_error;
  wire  g_Directory_2__boreChildrenBd_bore_ack;
  wire  i_Directory_2__boreChildrenBd_bore_ack;
  logic p_Directory_2__boreChildrenBd_bore_ack;
  bit   t_Directory_2__boreChildrenBd_bore_ack;
  wire  [103:0] g_Directory_2__boreChildrenBd_bore_outdata;
  wire  [103:0] i_Directory_2__boreChildrenBd_bore_outdata;
  logic [103:0] p_Directory_2__boreChildrenBd_bore_outdata;
  bit   t_Directory_2__boreChildrenBd_bore_outdata;
  Directory_2 u_g_Directory_2 (
    .clock (clock),
    .reset (reset),
    .io_read_ready (g_Directory_2__io_read_ready),
    .io_read_valid (Directory_2__io_read_valid),
    .io_read_bits_tag (Directory_2__io_read_bits_tag),
    .io_read_bits_set (Directory_2__io_read_bits_set),
    .io_read_bits_wayMask (Directory_2__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory_2__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory_2__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory_2__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory_2__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory_2__io_read_bits_refill),
    .io_read_bits_mshrId (Directory_2__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory_2__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory_2__io_read_bits_cmoWay),
    .io_resp_valid (g_Directory_2__io_resp_valid),
    .io_resp_bits_hit (g_Directory_2__io_resp_bits_hit),
    .io_resp_bits_tag (g_Directory_2__io_resp_bits_tag),
    .io_resp_bits_set (g_Directory_2__io_resp_bits_set),
    .io_resp_bits_way (g_Directory_2__io_resp_bits_way),
    .io_resp_bits_meta_dirty (g_Directory_2__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (g_Directory_2__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (g_Directory_2__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (g_Directory_2__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (g_Directory_2__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (g_Directory_2__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (g_Directory_2__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (g_Directory_2__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (g_Directory_2__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (g_Directory_2__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (g_Directory_2__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (g_Directory_2__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (g_Directory_2__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (g_Directory_2__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory_2__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory_2__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory_2__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory_2__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory_2__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory_2__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory_2__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory_2__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory_2__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory_2__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory_2__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory_2__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory_2__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory_2__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory_2__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory_2__io_tagWReq_bits_wtag),
    .io_replResp_valid (g_Directory_2__io_replResp_valid),
    .io_replResp_bits_tag (g_Directory_2__io_replResp_bits_tag),
    .io_replResp_bits_set (g_Directory_2__io_replResp_bits_set),
    .io_replResp_bits_way (g_Directory_2__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (g_Directory_2__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (g_Directory_2__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (g_Directory_2__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (g_Directory_2__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (g_Directory_2__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (g_Directory_2__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (g_Directory_2__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (g_Directory_2__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (g_Directory_2__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (g_Directory_2__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (g_Directory_2__io_replResp_bits_retry),
    .io_replResp_bits_error (g_Directory_2__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory_2__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory_2__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory_2__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory_2__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory_2__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory_2__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory_2__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory_2__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory_2__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory_2__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory_2__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory_2__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory_2__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory_2__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory_2__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory_2__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory_2__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory_2__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory_2__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory_2__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory_2__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory_2__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory_2__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory_2__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory_2__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory_2__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory_2__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory_2__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory_2__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory_2__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory_2__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory_2__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory_2__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory_2__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory_2__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory_2__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory_2__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory_2__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory_2__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory_2__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory_2__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory_2__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory_2__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory_2__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory_2__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory_2__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory_2__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory_2__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory_2__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory_2__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory_2__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory_2__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory_2__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory_2__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory_2__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory_2__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory_2__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory_2__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory_2__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory_2__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory_2__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory_2__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory_2__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory_2__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory_2__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory_2__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory_2__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory_2__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory_2__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory_2__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory_2__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory_2__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory_2__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory_2__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory_2__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory_2__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory_2__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory_2__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory_2__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory_2__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory_2__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory_2__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory_2__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory_2__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory_2__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory_2__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory_2__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory_2__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory_2__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory_2__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory_2__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory_2__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory_2__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory_2__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory_2__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory_2__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory_2__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory_2__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory_2__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory_2__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory_2__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory_2__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory_2__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory_2__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory_2__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory_2__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory_2__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory_2__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory_2__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory_2__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory_2__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory_2__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory_2__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory_2__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory_2__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory_2__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory_2__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory_2__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory_2__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory_2__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory_2__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory_2__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory_2__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory_2__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory_2__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory_2__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory_2__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory_2__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory_2__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory_2__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory_2__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory_2__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory_2__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory_2__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory_2__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory_2__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory_2__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory_2__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory_2__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory_2__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory_2__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory_2__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory_2__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory_2__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory_2__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory_2__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory_2__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory_2__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory_2__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory_2__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory_2__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory_2__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory_2__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory_2__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory_2__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory_2__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory_2__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory_2__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory_2__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory_2__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory_2__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory_2__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory_2__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory_2__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory_2__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory_2__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory_2__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory_2__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory_2__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory_2__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory_2__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory_2__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory_2__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory_2__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory_2__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory_2__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory_2__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory_2__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory_2__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory_2__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory_2__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory_2__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory_2__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory_2__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory_2__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory_2__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory_2__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory_2__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory_2__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory_2__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory_2__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory_2__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory_2__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory_2__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory_2__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory_2__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory_2__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory_2__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory_2__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory_2__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory_2__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory_2__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory_2__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory_2__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory_2__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory_2__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory_2__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory_2__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory_2__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory_2__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory_2__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory_2__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory_2__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory_2__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory_2__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory_2__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory_2__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory_2__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory_2__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory_2__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory_2__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory_2__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory_2__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory_2__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory_2__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory_2__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory_2__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory_2__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory_2__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory_2__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory_2__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory_2__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory_2__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory_2__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory_2__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory_2__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory_2__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory_2__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory_2__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory_2__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory_2__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory_2__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory_2__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory_2__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory_2__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory_2__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory_2__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory_2__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory_2__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory_2__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory_2__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory_2__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory_2__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory_2__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory_2__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory_2__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory_2__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory_2__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory_2__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory_2__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory_2__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory_2__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory_2__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory_2__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory_2__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory_2__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory_2__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory_2__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory_2__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory_2__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory_2__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory_2__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory_2__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory_2__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory_2__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory_2__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory_2__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory_2__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory_2__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory_2__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory_2__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory_2__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory_2__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory_2__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory_2__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory_2__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory_2__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory_2__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory_2__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory_2__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory_2__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory_2__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory_2__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory_2__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory_2__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory_2__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory_2__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory_2__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory_2__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory_2__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory_2__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory_2__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory_2__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory_2__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory_2__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory_2__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory_2__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory_2__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory_2__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory_2__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory_2__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory_2__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory_2__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory_2__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory_2__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory_2__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory_2__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory_2__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory_2__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory_2__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory_2__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory_2__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory_2__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory_2__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory_2__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory_2__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory_2__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory_2__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory_2__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory_2__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory_2__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory_2__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory_2__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory_2__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory_2__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory_2__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory_2__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory_2__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory_2__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory_2__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory_2__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory_2__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory_2__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory_2__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory_2__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory_2__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory_2__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory_2__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory_2__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory_2__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory_2__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory_2__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory_2__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory_2__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory_2__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory_2__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory_2__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory_2__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory_2__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory_2__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory_2__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory_2__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory_2__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory_2__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory_2__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory_2__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory_2__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory_2__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory_2__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory_2__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory_2__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory_2__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory_2__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory_2__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory_2__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory_2__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory_2__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory_2__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory_2__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory_2__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory_2__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory_2__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory_2__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory_2__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory_2__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory_2__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory_2__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory_2__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory_2__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory_2__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory_2__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory_2__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory_2__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory_2__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory_2__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory_2__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory_2__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory_2__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory_2__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory_2__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory_2__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory_2__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory_2__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory_2__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory_2__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory_2__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory_2__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory_2__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory_2__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory_2__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory_2__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory_2__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory_2__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory_2__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory_2__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory_2__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory_2__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory_2__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory_2__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory_2__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory_2__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory_2__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory_2__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory_2__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory_2__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory_2__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory_2__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory_2__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory_2__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory_2__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory_2__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory_2__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory_2__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory_2__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory_2__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory_2__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory_2__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory_2__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory_2__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory_2__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory_2__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory_2__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory_2__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory_2__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory_2__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory_2__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory_2__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory_2__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory_2__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory_2__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory_2__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory_2__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory_2__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory_2__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory_2__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory_2__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory_2__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory_2__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory_2__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory_2__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory_2__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory_2__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory_2__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory_2__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory_2__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory_2__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory_2__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory_2__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory_2__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory_2__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory_2__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory_2__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory_2__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory_2__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory_2__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory_2__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory_2__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory_2__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory_2__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory_2__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory_2__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory_2__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory_2__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory_2__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory_2__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory_2__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory_2__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory_2__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory_2__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory_2__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory_2__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory_2__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory_2__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory_2__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory_2__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory_2__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory_2__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory_2__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory_2__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory_2__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory_2__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory_2__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory_2__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory_2__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory_2__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory_2__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory_2__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory_2__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory_2__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory_2__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory_2__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory_2__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory_2__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory_2__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory_2__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory_2__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory_2__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory_2__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory_2__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory_2__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory_2__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory_2__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory_2__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory_2__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory_2__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory_2__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory_2__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory_2__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory_2__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory_2__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory_2__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory_2__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory_2__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory_2__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory_2__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory_2__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory_2__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory_2__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory_2__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory_2__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory_2__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory_2__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory_2__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory_2__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory_2__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory_2__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory_2__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_Directory_2__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory_2__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory_2__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory_2__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory_2__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory_2__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory_2__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_Directory_2__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory_2__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory_2__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory_2__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory_2__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory_2__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory_2__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory_2__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory_2__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory_2__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory_2__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory_2__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory_2__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory_2__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory_2__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory_2__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory_2__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory_2__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory_2__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory_2__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory_2__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory_2__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory_2__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory_2__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory_2__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory_2__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory_2__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory_2__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory_2__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory_2__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory_2__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory_2__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory_2__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory_2__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory_2__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory_2__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory_2__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory_2__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory_2__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory_2__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory_2__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory_2__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory_2__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory_2__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory_2__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory_2__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory_2__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory_2__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory_2__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory_2__sigFromSrams_bore_6_cgen)
  );
  Directory_2_xs u_i_Directory_2 (
    .clock (clock),
    .reset (reset),
    .io_read_ready (i_Directory_2__io_read_ready),
    .io_read_valid (Directory_2__io_read_valid),
    .io_read_bits_tag (Directory_2__io_read_bits_tag),
    .io_read_bits_set (Directory_2__io_read_bits_set),
    .io_read_bits_wayMask (Directory_2__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory_2__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory_2__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory_2__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory_2__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory_2__io_read_bits_refill),
    .io_read_bits_mshrId (Directory_2__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory_2__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory_2__io_read_bits_cmoWay),
    .io_resp_valid (i_Directory_2__io_resp_valid),
    .io_resp_bits_hit (i_Directory_2__io_resp_bits_hit),
    .io_resp_bits_tag (i_Directory_2__io_resp_bits_tag),
    .io_resp_bits_set (i_Directory_2__io_resp_bits_set),
    .io_resp_bits_way (i_Directory_2__io_resp_bits_way),
    .io_resp_bits_meta_dirty (i_Directory_2__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (i_Directory_2__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (i_Directory_2__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (i_Directory_2__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (i_Directory_2__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (i_Directory_2__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (i_Directory_2__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (i_Directory_2__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (i_Directory_2__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (i_Directory_2__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (i_Directory_2__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (i_Directory_2__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (i_Directory_2__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (i_Directory_2__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory_2__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory_2__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory_2__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory_2__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory_2__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory_2__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory_2__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory_2__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory_2__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory_2__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory_2__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory_2__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory_2__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory_2__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory_2__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory_2__io_tagWReq_bits_wtag),
    .io_replResp_valid (i_Directory_2__io_replResp_valid),
    .io_replResp_bits_tag (i_Directory_2__io_replResp_bits_tag),
    .io_replResp_bits_set (i_Directory_2__io_replResp_bits_set),
    .io_replResp_bits_way (i_Directory_2__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (i_Directory_2__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (i_Directory_2__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (i_Directory_2__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (i_Directory_2__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (i_Directory_2__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (i_Directory_2__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (i_Directory_2__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (i_Directory_2__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (i_Directory_2__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (i_Directory_2__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (i_Directory_2__io_replResp_bits_retry),
    .io_replResp_bits_error (i_Directory_2__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory_2__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory_2__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory_2__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory_2__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory_2__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory_2__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory_2__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory_2__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory_2__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory_2__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory_2__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory_2__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory_2__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory_2__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory_2__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory_2__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory_2__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory_2__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory_2__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory_2__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory_2__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory_2__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory_2__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory_2__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory_2__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory_2__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory_2__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory_2__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory_2__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory_2__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory_2__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory_2__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory_2__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory_2__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory_2__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory_2__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory_2__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory_2__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory_2__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory_2__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory_2__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory_2__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory_2__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory_2__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory_2__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory_2__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory_2__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory_2__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory_2__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory_2__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory_2__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory_2__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory_2__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory_2__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory_2__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory_2__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory_2__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory_2__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory_2__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory_2__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory_2__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory_2__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory_2__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory_2__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory_2__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory_2__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory_2__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory_2__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory_2__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory_2__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory_2__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory_2__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory_2__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory_2__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory_2__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory_2__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory_2__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory_2__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory_2__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory_2__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory_2__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory_2__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory_2__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory_2__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory_2__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory_2__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory_2__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory_2__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory_2__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory_2__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory_2__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory_2__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory_2__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory_2__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory_2__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory_2__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory_2__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory_2__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory_2__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory_2__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory_2__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory_2__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory_2__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory_2__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory_2__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory_2__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory_2__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory_2__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory_2__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory_2__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory_2__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory_2__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory_2__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory_2__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory_2__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory_2__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory_2__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory_2__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory_2__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory_2__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory_2__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory_2__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory_2__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory_2__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory_2__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory_2__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory_2__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory_2__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory_2__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory_2__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory_2__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory_2__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory_2__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory_2__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory_2__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory_2__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory_2__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory_2__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory_2__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory_2__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory_2__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory_2__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory_2__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory_2__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory_2__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory_2__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory_2__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory_2__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory_2__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory_2__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory_2__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory_2__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory_2__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory_2__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory_2__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory_2__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory_2__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory_2__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory_2__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory_2__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory_2__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory_2__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory_2__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory_2__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory_2__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory_2__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory_2__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory_2__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory_2__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory_2__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory_2__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory_2__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory_2__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory_2__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory_2__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory_2__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory_2__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory_2__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory_2__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory_2__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory_2__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory_2__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory_2__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory_2__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory_2__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory_2__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory_2__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory_2__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory_2__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory_2__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory_2__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory_2__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory_2__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory_2__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory_2__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory_2__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory_2__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory_2__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory_2__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory_2__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory_2__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory_2__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory_2__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory_2__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory_2__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory_2__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory_2__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory_2__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory_2__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory_2__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory_2__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory_2__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory_2__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory_2__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory_2__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory_2__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory_2__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory_2__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory_2__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory_2__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory_2__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory_2__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory_2__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory_2__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory_2__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory_2__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory_2__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory_2__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory_2__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory_2__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory_2__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory_2__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory_2__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory_2__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory_2__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory_2__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory_2__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory_2__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory_2__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory_2__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory_2__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory_2__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory_2__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory_2__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory_2__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory_2__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory_2__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory_2__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory_2__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory_2__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory_2__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory_2__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory_2__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory_2__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory_2__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory_2__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory_2__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory_2__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory_2__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory_2__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory_2__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory_2__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory_2__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory_2__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory_2__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory_2__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory_2__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory_2__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory_2__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory_2__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory_2__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory_2__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory_2__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory_2__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory_2__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory_2__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory_2__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory_2__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory_2__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory_2__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory_2__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory_2__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory_2__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory_2__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory_2__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory_2__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory_2__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory_2__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory_2__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory_2__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory_2__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory_2__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory_2__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory_2__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory_2__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory_2__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory_2__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory_2__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory_2__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory_2__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory_2__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory_2__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory_2__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory_2__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory_2__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory_2__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory_2__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory_2__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory_2__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory_2__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory_2__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory_2__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory_2__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory_2__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory_2__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory_2__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory_2__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory_2__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory_2__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory_2__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory_2__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory_2__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory_2__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory_2__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory_2__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory_2__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory_2__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory_2__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory_2__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory_2__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory_2__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory_2__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory_2__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory_2__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory_2__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory_2__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory_2__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory_2__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory_2__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory_2__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory_2__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory_2__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory_2__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory_2__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory_2__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory_2__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory_2__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory_2__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory_2__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory_2__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory_2__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory_2__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory_2__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory_2__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory_2__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory_2__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory_2__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory_2__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory_2__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory_2__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory_2__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory_2__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory_2__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory_2__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory_2__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory_2__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory_2__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory_2__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory_2__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory_2__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory_2__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory_2__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory_2__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory_2__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory_2__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory_2__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory_2__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory_2__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory_2__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory_2__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory_2__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory_2__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory_2__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory_2__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory_2__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory_2__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory_2__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory_2__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory_2__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory_2__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory_2__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory_2__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory_2__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory_2__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory_2__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory_2__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory_2__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory_2__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory_2__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory_2__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory_2__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory_2__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory_2__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory_2__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory_2__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory_2__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory_2__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory_2__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory_2__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory_2__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory_2__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory_2__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory_2__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory_2__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory_2__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory_2__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory_2__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory_2__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory_2__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory_2__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory_2__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory_2__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory_2__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory_2__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory_2__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory_2__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory_2__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory_2__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory_2__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory_2__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory_2__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory_2__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory_2__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory_2__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory_2__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory_2__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory_2__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory_2__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory_2__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory_2__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory_2__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory_2__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory_2__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory_2__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory_2__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory_2__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory_2__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory_2__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory_2__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory_2__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory_2__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory_2__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory_2__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory_2__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory_2__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory_2__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory_2__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory_2__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory_2__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory_2__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory_2__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory_2__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory_2__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory_2__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory_2__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory_2__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory_2__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory_2__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory_2__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory_2__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory_2__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory_2__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory_2__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory_2__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory_2__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory_2__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory_2__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory_2__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory_2__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory_2__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory_2__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory_2__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory_2__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory_2__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory_2__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory_2__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory_2__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory_2__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory_2__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory_2__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory_2__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory_2__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory_2__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory_2__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory_2__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory_2__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory_2__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory_2__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory_2__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory_2__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory_2__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory_2__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory_2__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory_2__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory_2__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory_2__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory_2__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory_2__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory_2__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory_2__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory_2__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory_2__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory_2__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory_2__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory_2__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory_2__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory_2__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory_2__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory_2__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory_2__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory_2__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory_2__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory_2__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory_2__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory_2__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory_2__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory_2__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory_2__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory_2__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory_2__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory_2__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory_2__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory_2__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory_2__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory_2__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory_2__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory_2__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory_2__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory_2__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory_2__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory_2__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory_2__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory_2__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory_2__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory_2__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory_2__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory_2__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_Directory_2__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory_2__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory_2__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory_2__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory_2__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory_2__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory_2__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_Directory_2__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory_2__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory_2__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory_2__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory_2__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory_2__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory_2__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory_2__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory_2__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory_2__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory_2__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory_2__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory_2__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory_2__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory_2__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory_2__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory_2__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory_2__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory_2__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory_2__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory_2__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory_2__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory_2__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory_2__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory_2__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory_2__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory_2__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory_2__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory_2__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory_2__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory_2__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory_2__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory_2__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory_2__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory_2__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory_2__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory_2__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory_2__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory_2__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory_2__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory_2__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory_2__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory_2__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory_2__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory_2__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory_2__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory_2__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory_2__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory_2__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory_2__sigFromSrams_bore_6_cgen)
  );
  task automatic drive_Directory_2();
    Directory_2__io_read_valid = $urandom % 2;
    Directory_2__io_read_bits_tag = 31'($urandom_range(0, 3));
    Directory_2__io_read_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_read_bits_wayMask = rnd(8);
    Directory_2__io_read_bits_replacerInfo_channel = rnd(3);
    Directory_2__io_read_bits_replacerInfo_opcode = rnd(3);
    Directory_2__io_read_bits_replacerInfo_reqSource = rnd(5);
    Directory_2__io_read_bits_replacerInfo_refill_prefetch = $urandom % 2;
    Directory_2__io_read_bits_refill = $urandom % 2;
    Directory_2__io_read_bits_mshrId = rnd(8);
    Directory_2__io_read_bits_cmoAll = $urandom % 2;
    Directory_2__io_read_bits_cmoWay = rnd(3);
    Directory_2__io_metaWReq_valid = (($urandom % 4) == 0);
    Directory_2__io_metaWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_metaWReq_bits_wayOH = rnd(8);
    Directory_2__io_metaWReq_bits_wmeta_dirty = $urandom % 2;
    Directory_2__io_metaWReq_bits_wmeta_state = rnd(2);
    Directory_2__io_metaWReq_bits_wmeta_clients = $urandom % 2;
    Directory_2__io_metaWReq_bits_wmeta_alias = rnd(2);
    Directory_2__io_metaWReq_bits_wmeta_prefetch = $urandom % 2;
    Directory_2__io_metaWReq_bits_wmeta_prefetchSrc = rnd(3);
    Directory_2__io_metaWReq_bits_wmeta_accessed = $urandom % 2;
    Directory_2__io_metaWReq_bits_wmeta_tagErr = $urandom % 2;
    Directory_2__io_metaWReq_bits_wmeta_dataErr = $urandom % 2;
    Directory_2__io_tagWReq_valid = (($urandom % 4) == 0);
    Directory_2__io_tagWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_tagWReq_bits_way = rnd(3);
    Directory_2__io_tagWReq_bits_wtag = 31'($urandom_range(0, 3));
    Directory_2__io_msInfo_0_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_0_bits_channel = rnd(3);
    Directory_2__io_msInfo_0_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_0_bits_way = rnd(3);
    Directory_2__io_msInfo_0_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_0_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_0_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_0_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_0_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_0_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_0_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_0_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_0_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_0_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_0_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_0_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_0_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_0_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_0_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_0_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_0_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_0_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_0_bits_param = rnd(3);
    Directory_2__io_msInfo_0_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_0_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_0_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_0_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_0_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_0_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_0_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_0_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_0_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_0_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_0_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_1_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_1_bits_channel = rnd(3);
    Directory_2__io_msInfo_1_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_1_bits_way = rnd(3);
    Directory_2__io_msInfo_1_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_1_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_1_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_1_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_1_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_1_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_1_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_1_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_1_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_1_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_1_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_1_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_1_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_1_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_1_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_1_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_1_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_1_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_1_bits_param = rnd(3);
    Directory_2__io_msInfo_1_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_1_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_1_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_1_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_1_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_1_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_1_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_1_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_1_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_1_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_1_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_2_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_2_bits_channel = rnd(3);
    Directory_2__io_msInfo_2_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_2_bits_way = rnd(3);
    Directory_2__io_msInfo_2_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_2_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_2_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_2_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_2_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_2_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_2_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_2_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_2_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_2_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_2_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_2_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_2_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_2_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_2_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_2_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_2_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_2_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_2_bits_param = rnd(3);
    Directory_2__io_msInfo_2_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_2_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_2_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_2_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_2_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_2_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_2_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_2_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_2_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_2_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_2_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_3_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_3_bits_channel = rnd(3);
    Directory_2__io_msInfo_3_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_3_bits_way = rnd(3);
    Directory_2__io_msInfo_3_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_3_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_3_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_3_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_3_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_3_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_3_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_3_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_3_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_3_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_3_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_3_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_3_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_3_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_3_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_3_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_3_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_3_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_3_bits_param = rnd(3);
    Directory_2__io_msInfo_3_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_3_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_3_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_3_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_3_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_3_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_3_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_3_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_3_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_3_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_3_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_4_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_4_bits_channel = rnd(3);
    Directory_2__io_msInfo_4_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_4_bits_way = rnd(3);
    Directory_2__io_msInfo_4_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_4_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_4_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_4_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_4_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_4_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_4_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_4_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_4_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_4_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_4_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_4_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_4_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_4_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_4_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_4_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_4_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_4_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_4_bits_param = rnd(3);
    Directory_2__io_msInfo_4_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_4_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_4_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_4_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_4_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_4_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_4_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_4_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_4_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_4_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_4_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_5_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_5_bits_channel = rnd(3);
    Directory_2__io_msInfo_5_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_5_bits_way = rnd(3);
    Directory_2__io_msInfo_5_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_5_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_5_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_5_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_5_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_5_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_5_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_5_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_5_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_5_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_5_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_5_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_5_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_5_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_5_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_5_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_5_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_5_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_5_bits_param = rnd(3);
    Directory_2__io_msInfo_5_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_5_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_5_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_5_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_5_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_5_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_5_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_5_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_5_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_5_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_5_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_6_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_6_bits_channel = rnd(3);
    Directory_2__io_msInfo_6_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_6_bits_way = rnd(3);
    Directory_2__io_msInfo_6_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_6_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_6_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_6_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_6_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_6_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_6_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_6_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_6_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_6_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_6_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_6_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_6_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_6_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_6_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_6_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_6_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_6_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_6_bits_param = rnd(3);
    Directory_2__io_msInfo_6_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_6_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_6_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_6_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_6_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_6_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_6_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_6_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_6_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_6_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_6_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_7_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_7_bits_channel = rnd(3);
    Directory_2__io_msInfo_7_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_7_bits_way = rnd(3);
    Directory_2__io_msInfo_7_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_7_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_7_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_7_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_7_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_7_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_7_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_7_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_7_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_7_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_7_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_7_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_7_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_7_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_7_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_7_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_7_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_7_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_7_bits_param = rnd(3);
    Directory_2__io_msInfo_7_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_7_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_7_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_7_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_7_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_7_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_7_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_7_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_7_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_7_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_7_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_8_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_8_bits_channel = rnd(3);
    Directory_2__io_msInfo_8_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_8_bits_way = rnd(3);
    Directory_2__io_msInfo_8_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_8_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_8_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_8_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_8_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_8_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_8_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_8_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_8_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_8_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_8_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_8_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_8_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_8_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_8_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_8_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_8_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_8_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_8_bits_param = rnd(3);
    Directory_2__io_msInfo_8_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_8_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_8_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_8_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_8_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_8_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_8_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_8_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_8_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_8_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_8_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_9_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_9_bits_channel = rnd(3);
    Directory_2__io_msInfo_9_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_9_bits_way = rnd(3);
    Directory_2__io_msInfo_9_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_9_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_9_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_9_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_9_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_9_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_9_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_9_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_9_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_9_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_9_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_9_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_9_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_9_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_9_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_9_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_9_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_9_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_9_bits_param = rnd(3);
    Directory_2__io_msInfo_9_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_9_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_9_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_9_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_9_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_9_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_9_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_9_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_9_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_9_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_9_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_10_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_10_bits_channel = rnd(3);
    Directory_2__io_msInfo_10_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_10_bits_way = rnd(3);
    Directory_2__io_msInfo_10_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_10_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_10_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_10_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_10_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_10_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_10_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_10_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_10_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_10_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_10_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_10_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_10_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_10_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_10_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_10_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_10_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_10_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_10_bits_param = rnd(3);
    Directory_2__io_msInfo_10_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_10_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_10_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_10_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_10_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_10_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_10_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_10_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_10_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_10_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_10_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_11_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_11_bits_channel = rnd(3);
    Directory_2__io_msInfo_11_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_11_bits_way = rnd(3);
    Directory_2__io_msInfo_11_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_11_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_11_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_11_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_11_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_11_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_11_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_11_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_11_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_11_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_11_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_11_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_11_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_11_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_11_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_11_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_11_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_11_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_11_bits_param = rnd(3);
    Directory_2__io_msInfo_11_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_11_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_11_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_11_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_11_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_11_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_11_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_11_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_11_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_11_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_11_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_12_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_12_bits_channel = rnd(3);
    Directory_2__io_msInfo_12_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_12_bits_way = rnd(3);
    Directory_2__io_msInfo_12_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_12_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_12_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_12_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_12_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_12_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_12_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_12_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_12_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_12_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_12_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_12_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_12_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_12_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_12_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_12_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_12_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_12_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_12_bits_param = rnd(3);
    Directory_2__io_msInfo_12_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_12_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_12_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_12_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_12_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_12_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_12_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_12_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_12_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_12_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_12_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_13_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_13_bits_channel = rnd(3);
    Directory_2__io_msInfo_13_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_13_bits_way = rnd(3);
    Directory_2__io_msInfo_13_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_13_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_13_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_13_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_13_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_13_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_13_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_13_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_13_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_13_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_13_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_13_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_13_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_13_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_13_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_13_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_13_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_13_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_13_bits_param = rnd(3);
    Directory_2__io_msInfo_13_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_13_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_13_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_13_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_13_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_13_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_13_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_13_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_13_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_13_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_13_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_14_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_14_bits_channel = rnd(3);
    Directory_2__io_msInfo_14_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_14_bits_way = rnd(3);
    Directory_2__io_msInfo_14_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_14_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_14_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_14_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_14_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_14_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_14_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_14_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_14_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_14_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_14_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_14_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_14_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_14_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_14_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_14_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_14_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_14_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_14_bits_param = rnd(3);
    Directory_2__io_msInfo_14_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_14_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_14_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_14_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_14_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_14_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_14_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_14_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_14_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_14_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_14_bits_releaseToClean = $urandom % 2;
    Directory_2__io_msInfo_15_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_2__io_msInfo_15_bits_channel = rnd(3);
    Directory_2__io_msInfo_15_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_2__io_msInfo_15_bits_way = rnd(3);
    Directory_2__io_msInfo_15_bits_reqTag = rnd(31);
    Directory_2__io_msInfo_15_bits_willFree = $urandom % 2;
    Directory_2__io_msInfo_15_bits_aliasTask = $urandom % 2;
    Directory_2__io_msInfo_15_bits_needRelease = $urandom % 2;
    Directory_2__io_msInfo_15_bits_blockRefill = $urandom % 2;
    Directory_2__io_msInfo_15_bits_meta_dirty = $urandom % 2;
    Directory_2__io_msInfo_15_bits_meta_state = rnd(2);
    Directory_2__io_msInfo_15_bits_meta_clients = $urandom % 2;
    Directory_2__io_msInfo_15_bits_meta_alias = rnd(2);
    Directory_2__io_msInfo_15_bits_meta_prefetch = $urandom % 2;
    Directory_2__io_msInfo_15_bits_meta_prefetchSrc = rnd(3);
    Directory_2__io_msInfo_15_bits_meta_accessed = $urandom % 2;
    Directory_2__io_msInfo_15_bits_meta_tagErr = $urandom % 2;
    Directory_2__io_msInfo_15_bits_meta_dataErr = $urandom % 2;
    Directory_2__io_msInfo_15_bits_metaTag = rnd(31);
    Directory_2__io_msInfo_15_bits_dirHit = $urandom % 2;
    Directory_2__io_msInfo_15_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_2__io_msInfo_15_bits_isPrefetch = $urandom % 2;
    Directory_2__io_msInfo_15_bits_param = rnd(3);
    Directory_2__io_msInfo_15_bits_mergeA = $urandom % 2;
    Directory_2__io_msInfo_15_bits_w_grantfirst = $urandom % 2;
    Directory_2__io_msInfo_15_bits_s_release = $urandom % 2;
    Directory_2__io_msInfo_15_bits_s_refill = $urandom % 2;
    Directory_2__io_msInfo_15_bits_s_cmoresp = $urandom % 2;
    Directory_2__io_msInfo_15_bits_s_cmometaw = $urandom % 2;
    Directory_2__io_msInfo_15_bits_w_releaseack = $urandom % 2;
    Directory_2__io_msInfo_15_bits_w_replResp = $urandom % 2;
    Directory_2__io_msInfo_15_bits_w_rprobeacklast = $urandom % 2;
    Directory_2__io_msInfo_15_bits_replaceData = $urandom % 2;
    Directory_2__io_msInfo_15_bits_releaseToClean = $urandom % 2;
    Directory_2__boreChildrenBd_bore_array = rnd(5);
    Directory_2__boreChildrenBd_bore_all = $urandom % 2;
    Directory_2__boreChildrenBd_bore_req = $urandom % 2;
    Directory_2__boreChildrenBd_bore_writeen = $urandom % 2;
    Directory_2__boreChildrenBd_bore_be = rnd(8);
    Directory_2__boreChildrenBd_bore_addr = rnd(10);
    Directory_2__boreChildrenBd_bore_indata = rnd(104);
    Directory_2__boreChildrenBd_bore_readen = $urandom % 2;
    Directory_2__boreChildrenBd_bore_addr_rd = rnd(10);
    Directory_2__sigFromSrams_bore_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_cgen = $urandom % 2;
    Directory_2__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_1_cgen = $urandom % 2;
    Directory_2__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_2_cgen = $urandom % 2;
    Directory_2__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_3_cgen = $urandom % 2;
    Directory_2__sigFromSrams_bore_4_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_4_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_4_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_4_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_4_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_4_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_4_cgen = $urandom % 2;
    Directory_2__sigFromSrams_bore_5_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_5_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_5_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_5_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_5_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_5_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_5_cgen = $urandom % 2;
    Directory_2__sigFromSrams_bore_6_ram_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_6_ram_bypass = $urandom % 2;
    Directory_2__sigFromSrams_bore_6_ram_bp_clken = $urandom % 2;
    Directory_2__sigFromSrams_bore_6_ram_aux_clk = 1'b0;
    Directory_2__sigFromSrams_bore_6_ram_aux_ckbp = 1'b0;
    Directory_2__sigFromSrams_bore_6_ram_mcp_hold = $urandom % 2;
    Directory_2__sigFromSrams_bore_6_cgen = $urandom % 2;
  endtask
  task automatic check_Directory_2();
    checks++;
    if (g_Directory_2__io_read_ready !== i_Directory_2__io_read_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_read_ready g=%h i=%h", cyc, g_Directory_2__io_read_ready, i_Directory_2__io_read_ready);
    end
    if (g_Directory_2__io_read_ready !== p_Directory_2__io_read_ready) t_Directory_2__io_read_ready = 1'b1;
    p_Directory_2__io_read_ready = g_Directory_2__io_read_ready;
    checks++;
    if (g_Directory_2__io_resp_valid !== i_Directory_2__io_resp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_valid g=%h i=%h", cyc, g_Directory_2__io_resp_valid, i_Directory_2__io_resp_valid);
    end
    if (g_Directory_2__io_resp_valid !== p_Directory_2__io_resp_valid) t_Directory_2__io_resp_valid = 1'b1;
    p_Directory_2__io_resp_valid = g_Directory_2__io_resp_valid;
    checks++;
    if (g_Directory_2__io_resp_bits_hit !== i_Directory_2__io_resp_bits_hit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_hit g=%h i=%h", cyc, g_Directory_2__io_resp_bits_hit, i_Directory_2__io_resp_bits_hit);
    end
    if (g_Directory_2__io_resp_bits_hit !== p_Directory_2__io_resp_bits_hit) t_Directory_2__io_resp_bits_hit = 1'b1;
    p_Directory_2__io_resp_bits_hit = g_Directory_2__io_resp_bits_hit;
    checks++;
    if (g_Directory_2__io_resp_bits_tag !== i_Directory_2__io_resp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_tag g=%h i=%h", cyc, g_Directory_2__io_resp_bits_tag, i_Directory_2__io_resp_bits_tag);
    end
    if (g_Directory_2__io_resp_bits_tag !== p_Directory_2__io_resp_bits_tag) t_Directory_2__io_resp_bits_tag = 1'b1;
    p_Directory_2__io_resp_bits_tag = g_Directory_2__io_resp_bits_tag;
    checks++;
    if (g_Directory_2__io_resp_bits_set !== i_Directory_2__io_resp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_set g=%h i=%h", cyc, g_Directory_2__io_resp_bits_set, i_Directory_2__io_resp_bits_set);
    end
    if (g_Directory_2__io_resp_bits_set !== p_Directory_2__io_resp_bits_set) t_Directory_2__io_resp_bits_set = 1'b1;
    p_Directory_2__io_resp_bits_set = g_Directory_2__io_resp_bits_set;
    checks++;
    if (g_Directory_2__io_resp_bits_way !== i_Directory_2__io_resp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_way g=%h i=%h", cyc, g_Directory_2__io_resp_bits_way, i_Directory_2__io_resp_bits_way);
    end
    if (g_Directory_2__io_resp_bits_way !== p_Directory_2__io_resp_bits_way) t_Directory_2__io_resp_bits_way = 1'b1;
    p_Directory_2__io_resp_bits_way = g_Directory_2__io_resp_bits_way;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_dirty !== i_Directory_2__io_resp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_dirty g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_dirty, i_Directory_2__io_resp_bits_meta_dirty);
    end
    if (g_Directory_2__io_resp_bits_meta_dirty !== p_Directory_2__io_resp_bits_meta_dirty) t_Directory_2__io_resp_bits_meta_dirty = 1'b1;
    p_Directory_2__io_resp_bits_meta_dirty = g_Directory_2__io_resp_bits_meta_dirty;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_state !== i_Directory_2__io_resp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_state g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_state, i_Directory_2__io_resp_bits_meta_state);
    end
    if (g_Directory_2__io_resp_bits_meta_state !== p_Directory_2__io_resp_bits_meta_state) t_Directory_2__io_resp_bits_meta_state = 1'b1;
    p_Directory_2__io_resp_bits_meta_state = g_Directory_2__io_resp_bits_meta_state;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_clients !== i_Directory_2__io_resp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_clients g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_clients, i_Directory_2__io_resp_bits_meta_clients);
    end
    if (g_Directory_2__io_resp_bits_meta_clients !== p_Directory_2__io_resp_bits_meta_clients) t_Directory_2__io_resp_bits_meta_clients = 1'b1;
    p_Directory_2__io_resp_bits_meta_clients = g_Directory_2__io_resp_bits_meta_clients;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_alias !== i_Directory_2__io_resp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_alias g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_alias, i_Directory_2__io_resp_bits_meta_alias);
    end
    if (g_Directory_2__io_resp_bits_meta_alias !== p_Directory_2__io_resp_bits_meta_alias) t_Directory_2__io_resp_bits_meta_alias = 1'b1;
    p_Directory_2__io_resp_bits_meta_alias = g_Directory_2__io_resp_bits_meta_alias;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_prefetch !== i_Directory_2__io_resp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_prefetch, i_Directory_2__io_resp_bits_meta_prefetch);
    end
    if (g_Directory_2__io_resp_bits_meta_prefetch !== p_Directory_2__io_resp_bits_meta_prefetch) t_Directory_2__io_resp_bits_meta_prefetch = 1'b1;
    p_Directory_2__io_resp_bits_meta_prefetch = g_Directory_2__io_resp_bits_meta_prefetch;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_prefetchSrc !== i_Directory_2__io_resp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_prefetchSrc, i_Directory_2__io_resp_bits_meta_prefetchSrc);
    end
    if (g_Directory_2__io_resp_bits_meta_prefetchSrc !== p_Directory_2__io_resp_bits_meta_prefetchSrc) t_Directory_2__io_resp_bits_meta_prefetchSrc = 1'b1;
    p_Directory_2__io_resp_bits_meta_prefetchSrc = g_Directory_2__io_resp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_accessed !== i_Directory_2__io_resp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_accessed g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_accessed, i_Directory_2__io_resp_bits_meta_accessed);
    end
    if (g_Directory_2__io_resp_bits_meta_accessed !== p_Directory_2__io_resp_bits_meta_accessed) t_Directory_2__io_resp_bits_meta_accessed = 1'b1;
    p_Directory_2__io_resp_bits_meta_accessed = g_Directory_2__io_resp_bits_meta_accessed;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_tagErr !== i_Directory_2__io_resp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_tagErr, i_Directory_2__io_resp_bits_meta_tagErr);
    end
    if (g_Directory_2__io_resp_bits_meta_tagErr !== p_Directory_2__io_resp_bits_meta_tagErr) t_Directory_2__io_resp_bits_meta_tagErr = 1'b1;
    p_Directory_2__io_resp_bits_meta_tagErr = g_Directory_2__io_resp_bits_meta_tagErr;
    checks++;
    if (g_Directory_2__io_resp_bits_meta_dataErr !== i_Directory_2__io_resp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory_2__io_resp_bits_meta_dataErr, i_Directory_2__io_resp_bits_meta_dataErr);
    end
    if (g_Directory_2__io_resp_bits_meta_dataErr !== p_Directory_2__io_resp_bits_meta_dataErr) t_Directory_2__io_resp_bits_meta_dataErr = 1'b1;
    p_Directory_2__io_resp_bits_meta_dataErr = g_Directory_2__io_resp_bits_meta_dataErr;
    checks++;
    if (g_Directory_2__io_resp_bits_error !== i_Directory_2__io_resp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_error g=%h i=%h", cyc, g_Directory_2__io_resp_bits_error, i_Directory_2__io_resp_bits_error);
    end
    if (g_Directory_2__io_resp_bits_error !== p_Directory_2__io_resp_bits_error) t_Directory_2__io_resp_bits_error = 1'b1;
    p_Directory_2__io_resp_bits_error = g_Directory_2__io_resp_bits_error;
    checks++;
    if (g_Directory_2__io_resp_bits_replacerInfo_channel !== i_Directory_2__io_resp_bits_replacerInfo_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_replacerInfo_channel g=%h i=%h", cyc, g_Directory_2__io_resp_bits_replacerInfo_channel, i_Directory_2__io_resp_bits_replacerInfo_channel);
    end
    if (g_Directory_2__io_resp_bits_replacerInfo_channel !== p_Directory_2__io_resp_bits_replacerInfo_channel) t_Directory_2__io_resp_bits_replacerInfo_channel = 1'b1;
    p_Directory_2__io_resp_bits_replacerInfo_channel = g_Directory_2__io_resp_bits_replacerInfo_channel;
    checks++;
    if (g_Directory_2__io_resp_bits_replacerInfo_opcode !== i_Directory_2__io_resp_bits_replacerInfo_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_replacerInfo_opcode g=%h i=%h", cyc, g_Directory_2__io_resp_bits_replacerInfo_opcode, i_Directory_2__io_resp_bits_replacerInfo_opcode);
    end
    if (g_Directory_2__io_resp_bits_replacerInfo_opcode !== p_Directory_2__io_resp_bits_replacerInfo_opcode) t_Directory_2__io_resp_bits_replacerInfo_opcode = 1'b1;
    p_Directory_2__io_resp_bits_replacerInfo_opcode = g_Directory_2__io_resp_bits_replacerInfo_opcode;
    checks++;
    if (g_Directory_2__io_resp_bits_replacerInfo_reqSource !== i_Directory_2__io_resp_bits_replacerInfo_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_replacerInfo_reqSource g=%h i=%h", cyc, g_Directory_2__io_resp_bits_replacerInfo_reqSource, i_Directory_2__io_resp_bits_replacerInfo_reqSource);
    end
    if (g_Directory_2__io_resp_bits_replacerInfo_reqSource !== p_Directory_2__io_resp_bits_replacerInfo_reqSource) t_Directory_2__io_resp_bits_replacerInfo_reqSource = 1'b1;
    p_Directory_2__io_resp_bits_replacerInfo_reqSource = g_Directory_2__io_resp_bits_replacerInfo_reqSource;
    checks++;
    if (g_Directory_2__io_resp_bits_replacerInfo_refill_prefetch !== i_Directory_2__io_resp_bits_replacerInfo_refill_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_resp_bits_replacerInfo_refill_prefetch g=%h i=%h", cyc, g_Directory_2__io_resp_bits_replacerInfo_refill_prefetch, i_Directory_2__io_resp_bits_replacerInfo_refill_prefetch);
    end
    if (g_Directory_2__io_resp_bits_replacerInfo_refill_prefetch !== p_Directory_2__io_resp_bits_replacerInfo_refill_prefetch) t_Directory_2__io_resp_bits_replacerInfo_refill_prefetch = 1'b1;
    p_Directory_2__io_resp_bits_replacerInfo_refill_prefetch = g_Directory_2__io_resp_bits_replacerInfo_refill_prefetch;
    checks++;
    if (g_Directory_2__io_replResp_valid !== i_Directory_2__io_replResp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_valid g=%h i=%h", cyc, g_Directory_2__io_replResp_valid, i_Directory_2__io_replResp_valid);
    end
    if (g_Directory_2__io_replResp_valid !== p_Directory_2__io_replResp_valid) t_Directory_2__io_replResp_valid = 1'b1;
    p_Directory_2__io_replResp_valid = g_Directory_2__io_replResp_valid;
    checks++;
    if (g_Directory_2__io_replResp_bits_tag !== i_Directory_2__io_replResp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_tag g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_tag, i_Directory_2__io_replResp_bits_tag);
    end
    if (g_Directory_2__io_replResp_bits_tag !== p_Directory_2__io_replResp_bits_tag) t_Directory_2__io_replResp_bits_tag = 1'b1;
    p_Directory_2__io_replResp_bits_tag = g_Directory_2__io_replResp_bits_tag;
    checks++;
    if (g_Directory_2__io_replResp_bits_set !== i_Directory_2__io_replResp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_set g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_set, i_Directory_2__io_replResp_bits_set);
    end
    if (g_Directory_2__io_replResp_bits_set !== p_Directory_2__io_replResp_bits_set) t_Directory_2__io_replResp_bits_set = 1'b1;
    p_Directory_2__io_replResp_bits_set = g_Directory_2__io_replResp_bits_set;
    checks++;
    if (g_Directory_2__io_replResp_bits_way !== i_Directory_2__io_replResp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_way g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_way, i_Directory_2__io_replResp_bits_way);
    end
    if (g_Directory_2__io_replResp_bits_way !== p_Directory_2__io_replResp_bits_way) t_Directory_2__io_replResp_bits_way = 1'b1;
    p_Directory_2__io_replResp_bits_way = g_Directory_2__io_replResp_bits_way;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_dirty !== i_Directory_2__io_replResp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_dirty g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_dirty, i_Directory_2__io_replResp_bits_meta_dirty);
    end
    if (g_Directory_2__io_replResp_bits_meta_dirty !== p_Directory_2__io_replResp_bits_meta_dirty) t_Directory_2__io_replResp_bits_meta_dirty = 1'b1;
    p_Directory_2__io_replResp_bits_meta_dirty = g_Directory_2__io_replResp_bits_meta_dirty;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_state !== i_Directory_2__io_replResp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_state g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_state, i_Directory_2__io_replResp_bits_meta_state);
    end
    if (g_Directory_2__io_replResp_bits_meta_state !== p_Directory_2__io_replResp_bits_meta_state) t_Directory_2__io_replResp_bits_meta_state = 1'b1;
    p_Directory_2__io_replResp_bits_meta_state = g_Directory_2__io_replResp_bits_meta_state;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_clients !== i_Directory_2__io_replResp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_clients g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_clients, i_Directory_2__io_replResp_bits_meta_clients);
    end
    if (g_Directory_2__io_replResp_bits_meta_clients !== p_Directory_2__io_replResp_bits_meta_clients) t_Directory_2__io_replResp_bits_meta_clients = 1'b1;
    p_Directory_2__io_replResp_bits_meta_clients = g_Directory_2__io_replResp_bits_meta_clients;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_alias !== i_Directory_2__io_replResp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_alias g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_alias, i_Directory_2__io_replResp_bits_meta_alias);
    end
    if (g_Directory_2__io_replResp_bits_meta_alias !== p_Directory_2__io_replResp_bits_meta_alias) t_Directory_2__io_replResp_bits_meta_alias = 1'b1;
    p_Directory_2__io_replResp_bits_meta_alias = g_Directory_2__io_replResp_bits_meta_alias;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_prefetch !== i_Directory_2__io_replResp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_prefetch, i_Directory_2__io_replResp_bits_meta_prefetch);
    end
    if (g_Directory_2__io_replResp_bits_meta_prefetch !== p_Directory_2__io_replResp_bits_meta_prefetch) t_Directory_2__io_replResp_bits_meta_prefetch = 1'b1;
    p_Directory_2__io_replResp_bits_meta_prefetch = g_Directory_2__io_replResp_bits_meta_prefetch;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_prefetchSrc !== i_Directory_2__io_replResp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_prefetchSrc, i_Directory_2__io_replResp_bits_meta_prefetchSrc);
    end
    if (g_Directory_2__io_replResp_bits_meta_prefetchSrc !== p_Directory_2__io_replResp_bits_meta_prefetchSrc) t_Directory_2__io_replResp_bits_meta_prefetchSrc = 1'b1;
    p_Directory_2__io_replResp_bits_meta_prefetchSrc = g_Directory_2__io_replResp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_accessed !== i_Directory_2__io_replResp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_accessed g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_accessed, i_Directory_2__io_replResp_bits_meta_accessed);
    end
    if (g_Directory_2__io_replResp_bits_meta_accessed !== p_Directory_2__io_replResp_bits_meta_accessed) t_Directory_2__io_replResp_bits_meta_accessed = 1'b1;
    p_Directory_2__io_replResp_bits_meta_accessed = g_Directory_2__io_replResp_bits_meta_accessed;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_tagErr !== i_Directory_2__io_replResp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_tagErr, i_Directory_2__io_replResp_bits_meta_tagErr);
    end
    if (g_Directory_2__io_replResp_bits_meta_tagErr !== p_Directory_2__io_replResp_bits_meta_tagErr) t_Directory_2__io_replResp_bits_meta_tagErr = 1'b1;
    p_Directory_2__io_replResp_bits_meta_tagErr = g_Directory_2__io_replResp_bits_meta_tagErr;
    checks++;
    if (g_Directory_2__io_replResp_bits_meta_dataErr !== i_Directory_2__io_replResp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_meta_dataErr, i_Directory_2__io_replResp_bits_meta_dataErr);
    end
    if (g_Directory_2__io_replResp_bits_meta_dataErr !== p_Directory_2__io_replResp_bits_meta_dataErr) t_Directory_2__io_replResp_bits_meta_dataErr = 1'b1;
    p_Directory_2__io_replResp_bits_meta_dataErr = g_Directory_2__io_replResp_bits_meta_dataErr;
    checks++;
    if (g_Directory_2__io_replResp_bits_mshrId !== i_Directory_2__io_replResp_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_mshrId g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_mshrId, i_Directory_2__io_replResp_bits_mshrId);
    end
    if (g_Directory_2__io_replResp_bits_mshrId !== p_Directory_2__io_replResp_bits_mshrId) t_Directory_2__io_replResp_bits_mshrId = 1'b1;
    p_Directory_2__io_replResp_bits_mshrId = g_Directory_2__io_replResp_bits_mshrId;
    checks++;
    if (g_Directory_2__io_replResp_bits_retry !== i_Directory_2__io_replResp_bits_retry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_retry g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_retry, i_Directory_2__io_replResp_bits_retry);
    end
    if (g_Directory_2__io_replResp_bits_retry !== p_Directory_2__io_replResp_bits_retry) t_Directory_2__io_replResp_bits_retry = 1'b1;
    p_Directory_2__io_replResp_bits_retry = g_Directory_2__io_replResp_bits_retry;
    checks++;
    if (g_Directory_2__io_replResp_bits_error !== i_Directory_2__io_replResp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.io_replResp_bits_error g=%h i=%h", cyc, g_Directory_2__io_replResp_bits_error, i_Directory_2__io_replResp_bits_error);
    end
    if (g_Directory_2__io_replResp_bits_error !== p_Directory_2__io_replResp_bits_error) t_Directory_2__io_replResp_bits_error = 1'b1;
    p_Directory_2__io_replResp_bits_error = g_Directory_2__io_replResp_bits_error;
    checks++;
    if (g_Directory_2__boreChildrenBd_bore_ack !== i_Directory_2__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_Directory_2__boreChildrenBd_bore_ack, i_Directory_2__boreChildrenBd_bore_ack);
    end
    if (g_Directory_2__boreChildrenBd_bore_ack !== p_Directory_2__boreChildrenBd_bore_ack) t_Directory_2__boreChildrenBd_bore_ack = 1'b1;
    p_Directory_2__boreChildrenBd_bore_ack = g_Directory_2__boreChildrenBd_bore_ack;
    checks++;
    if (g_Directory_2__boreChildrenBd_bore_outdata !== i_Directory_2__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_2.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_Directory_2__boreChildrenBd_bore_outdata, i_Directory_2__boreChildrenBd_bore_outdata);
    end
    if (g_Directory_2__boreChildrenBd_bore_outdata !== p_Directory_2__boreChildrenBd_bore_outdata) t_Directory_2__boreChildrenBd_bore_outdata = 1'b1;
    p_Directory_2__boreChildrenBd_bore_outdata = g_Directory_2__boreChildrenBd_bore_outdata;
  endtask
  longint cov_Directory_2_hit = 0;
  longint cov_Directory_2_miss = 0;
  longint cov_Directory_2_repl = 0;
  longint cov_Directory_2_retry = 0;
  longint cov_Directory_2_err = 0;
  longint cov_Directory_2_pselUp = 0;
  longint cov_Directory_2_pselDn = 0;
  longint cov_Directory_2_initDone = 0;
  task automatic cover_Directory_2();
    if (u_g_Directory_2.io_resp_valid && u_g_Directory_2.io_resp_bits_hit) cov_Directory_2_hit++;
    if (u_g_Directory_2.io_resp_valid && !u_g_Directory_2.io_resp_bits_hit) cov_Directory_2_miss++;
    if (u_g_Directory_2.io_replResp_valid) cov_Directory_2_repl++;
    if (u_g_Directory_2.io_replResp_valid && u_g_Directory_2.io_replResp_bits_retry) cov_Directory_2_retry++;
    if (u_g_Directory_2.io_resp_valid && u_g_Directory_2.io_resp_bits_error) cov_Directory_2_err++;
    if (u_g_Directory_2.PSEL > 10'h200) cov_Directory_2_pselUp++;
    if (u_g_Directory_2.refillReqValid_s3 && u_g_Directory_2.match_b && !u_g_Directory_2.hit_s3) cov_Directory_2_pselDn++;
    if (u_g_Directory_2.resetFinish) cov_Directory_2_initDone++;
  endtask
  task automatic preinit_Directory_2();
    foreach (u_g_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.ram[e]) u_g_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.ram[e]) u_g_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.ram[e]) u_g_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.ram[e]) u_g_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_2.metaArray.array.array.array_15_ext.ram[e]) u_g_Directory_2.metaArray.array.array.array_15_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_2.replacer_sram_opt.array.array.array_16_ext.ram[e]) u_g_Directory_2.replacer_sram_opt.array.array.array_16_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_2.origin_bit_opt.array.array.array_17_ext.ram[e]) u_g_Directory_2.origin_bit_opt.array.array.array_17_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
  endtask
  task automatic sync_Directory_2();
    u_i_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_2.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_2.tagArray.array_0_0_0.u_core.rdataReg = u_g_Directory_2.tagArray.array_0_0_0.rdataReg;
    #0 release u_i_Directory_2.tagArray.array_0_0_0.u_core.rdataReg;
    u_i_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_2.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_2.tagArray.array_0_0_1.u_core.rdataReg = u_g_Directory_2.tagArray.array_0_0_1.rdataReg;
    #0 release u_i_Directory_2.tagArray.array_0_0_1.u_core.rdataReg;
    u_i_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_2.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_2.tagArray.array_0_1_0.u_core.rdataReg = u_g_Directory_2.tagArray.array_0_1_0.rdataReg;
    #0 release u_i_Directory_2.tagArray.array_0_1_0.u_core.rdataReg;
    u_i_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_2.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_2.tagArray.array_0_1_1.u_core.rdataReg = u_g_Directory_2.tagArray.array_0_1_1.rdataReg;
    #0 release u_i_Directory_2.tagArray.array_0_1_1.u_core.rdataReg;
    u_i_Directory_2.metaArray.array.array.array_15_ext.ram = u_g_Directory_2.metaArray.array.array.array_15_ext.ram;
    u_i_Directory_2.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g_Directory_2.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i_Directory_2.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g_Directory_2.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i_Directory_2.metaArray.u_core.rdataReg = u_g_Directory_2.metaArray.rdataReg;
    #0 release u_i_Directory_2.metaArray.u_core.rdataReg;
    u_i_Directory_2.replacer_sram_opt.array.array.array_16_ext.ram = u_g_Directory_2.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i_Directory_2.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g_Directory_2.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i_Directory_2.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g_Directory_2.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i_Directory_2.replacer_sram_opt.u_core.rdataReg = u_g_Directory_2.replacer_sram_opt.rdataReg;
    #0 release u_i_Directory_2.replacer_sram_opt.u_core.rdataReg;
    u_i_Directory_2.origin_bit_opt.array.array.array_17_ext.ram = u_g_Directory_2.origin_bit_opt.array.array.array_17_ext.ram;
    u_i_Directory_2.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g_Directory_2.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i_Directory_2.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g_Directory_2.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i_Directory_2.origin_bit_opt.u_core.rdataReg = u_g_Directory_2.origin_bit_opt.rdataReg;
    #0 release u_i_Directory_2.origin_bit_opt.u_core.rdataReg;
  endtask

  // ======================= Directory_3 =======================
  logic Directory_3__io_read_valid;
  logic [30:0] Directory_3__io_read_bits_tag;
  logic [8:0] Directory_3__io_read_bits_set;
  logic [7:0] Directory_3__io_read_bits_wayMask;
  logic [2:0] Directory_3__io_read_bits_replacerInfo_channel;
  logic [2:0] Directory_3__io_read_bits_replacerInfo_opcode;
  logic [4:0] Directory_3__io_read_bits_replacerInfo_reqSource;
  logic Directory_3__io_read_bits_replacerInfo_refill_prefetch;
  logic Directory_3__io_read_bits_refill;
  logic [7:0] Directory_3__io_read_bits_mshrId;
  logic Directory_3__io_read_bits_cmoAll;
  logic [2:0] Directory_3__io_read_bits_cmoWay;
  logic Directory_3__io_metaWReq_valid;
  logic [8:0] Directory_3__io_metaWReq_bits_set;
  logic [7:0] Directory_3__io_metaWReq_bits_wayOH;
  logic Directory_3__io_metaWReq_bits_wmeta_dirty;
  logic [1:0] Directory_3__io_metaWReq_bits_wmeta_state;
  logic Directory_3__io_metaWReq_bits_wmeta_clients;
  logic [1:0] Directory_3__io_metaWReq_bits_wmeta_alias;
  logic Directory_3__io_metaWReq_bits_wmeta_prefetch;
  logic [2:0] Directory_3__io_metaWReq_bits_wmeta_prefetchSrc;
  logic Directory_3__io_metaWReq_bits_wmeta_accessed;
  logic Directory_3__io_metaWReq_bits_wmeta_tagErr;
  logic Directory_3__io_metaWReq_bits_wmeta_dataErr;
  logic Directory_3__io_tagWReq_valid;
  logic [8:0] Directory_3__io_tagWReq_bits_set;
  logic [2:0] Directory_3__io_tagWReq_bits_way;
  logic [30:0] Directory_3__io_tagWReq_bits_wtag;
  logic Directory_3__io_msInfo_0_valid;
  logic [2:0] Directory_3__io_msInfo_0_bits_channel;
  logic [8:0] Directory_3__io_msInfo_0_bits_set;
  logic [2:0] Directory_3__io_msInfo_0_bits_way;
  logic [30:0] Directory_3__io_msInfo_0_bits_reqTag;
  logic Directory_3__io_msInfo_0_bits_willFree;
  logic Directory_3__io_msInfo_0_bits_aliasTask;
  logic Directory_3__io_msInfo_0_bits_needRelease;
  logic Directory_3__io_msInfo_0_bits_blockRefill;
  logic Directory_3__io_msInfo_0_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_0_bits_meta_state;
  logic Directory_3__io_msInfo_0_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_0_bits_meta_alias;
  logic Directory_3__io_msInfo_0_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_0_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_0_bits_meta_accessed;
  logic Directory_3__io_msInfo_0_bits_meta_tagErr;
  logic Directory_3__io_msInfo_0_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_0_bits_metaTag;
  logic Directory_3__io_msInfo_0_bits_dirHit;
  logic Directory_3__io_msInfo_0_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_0_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_0_bits_param;
  logic Directory_3__io_msInfo_0_bits_mergeA;
  logic Directory_3__io_msInfo_0_bits_w_grantfirst;
  logic Directory_3__io_msInfo_0_bits_s_release;
  logic Directory_3__io_msInfo_0_bits_s_refill;
  logic Directory_3__io_msInfo_0_bits_s_cmoresp;
  logic Directory_3__io_msInfo_0_bits_s_cmometaw;
  logic Directory_3__io_msInfo_0_bits_w_releaseack;
  logic Directory_3__io_msInfo_0_bits_w_replResp;
  logic Directory_3__io_msInfo_0_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_0_bits_replaceData;
  logic Directory_3__io_msInfo_0_bits_releaseToClean;
  logic Directory_3__io_msInfo_1_valid;
  logic [2:0] Directory_3__io_msInfo_1_bits_channel;
  logic [8:0] Directory_3__io_msInfo_1_bits_set;
  logic [2:0] Directory_3__io_msInfo_1_bits_way;
  logic [30:0] Directory_3__io_msInfo_1_bits_reqTag;
  logic Directory_3__io_msInfo_1_bits_willFree;
  logic Directory_3__io_msInfo_1_bits_aliasTask;
  logic Directory_3__io_msInfo_1_bits_needRelease;
  logic Directory_3__io_msInfo_1_bits_blockRefill;
  logic Directory_3__io_msInfo_1_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_1_bits_meta_state;
  logic Directory_3__io_msInfo_1_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_1_bits_meta_alias;
  logic Directory_3__io_msInfo_1_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_1_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_1_bits_meta_accessed;
  logic Directory_3__io_msInfo_1_bits_meta_tagErr;
  logic Directory_3__io_msInfo_1_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_1_bits_metaTag;
  logic Directory_3__io_msInfo_1_bits_dirHit;
  logic Directory_3__io_msInfo_1_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_1_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_1_bits_param;
  logic Directory_3__io_msInfo_1_bits_mergeA;
  logic Directory_3__io_msInfo_1_bits_w_grantfirst;
  logic Directory_3__io_msInfo_1_bits_s_release;
  logic Directory_3__io_msInfo_1_bits_s_refill;
  logic Directory_3__io_msInfo_1_bits_s_cmoresp;
  logic Directory_3__io_msInfo_1_bits_s_cmometaw;
  logic Directory_3__io_msInfo_1_bits_w_releaseack;
  logic Directory_3__io_msInfo_1_bits_w_replResp;
  logic Directory_3__io_msInfo_1_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_1_bits_replaceData;
  logic Directory_3__io_msInfo_1_bits_releaseToClean;
  logic Directory_3__io_msInfo_2_valid;
  logic [2:0] Directory_3__io_msInfo_2_bits_channel;
  logic [8:0] Directory_3__io_msInfo_2_bits_set;
  logic [2:0] Directory_3__io_msInfo_2_bits_way;
  logic [30:0] Directory_3__io_msInfo_2_bits_reqTag;
  logic Directory_3__io_msInfo_2_bits_willFree;
  logic Directory_3__io_msInfo_2_bits_aliasTask;
  logic Directory_3__io_msInfo_2_bits_needRelease;
  logic Directory_3__io_msInfo_2_bits_blockRefill;
  logic Directory_3__io_msInfo_2_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_2_bits_meta_state;
  logic Directory_3__io_msInfo_2_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_2_bits_meta_alias;
  logic Directory_3__io_msInfo_2_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_2_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_2_bits_meta_accessed;
  logic Directory_3__io_msInfo_2_bits_meta_tagErr;
  logic Directory_3__io_msInfo_2_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_2_bits_metaTag;
  logic Directory_3__io_msInfo_2_bits_dirHit;
  logic Directory_3__io_msInfo_2_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_2_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_2_bits_param;
  logic Directory_3__io_msInfo_2_bits_mergeA;
  logic Directory_3__io_msInfo_2_bits_w_grantfirst;
  logic Directory_3__io_msInfo_2_bits_s_release;
  logic Directory_3__io_msInfo_2_bits_s_refill;
  logic Directory_3__io_msInfo_2_bits_s_cmoresp;
  logic Directory_3__io_msInfo_2_bits_s_cmometaw;
  logic Directory_3__io_msInfo_2_bits_w_releaseack;
  logic Directory_3__io_msInfo_2_bits_w_replResp;
  logic Directory_3__io_msInfo_2_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_2_bits_replaceData;
  logic Directory_3__io_msInfo_2_bits_releaseToClean;
  logic Directory_3__io_msInfo_3_valid;
  logic [2:0] Directory_3__io_msInfo_3_bits_channel;
  logic [8:0] Directory_3__io_msInfo_3_bits_set;
  logic [2:0] Directory_3__io_msInfo_3_bits_way;
  logic [30:0] Directory_3__io_msInfo_3_bits_reqTag;
  logic Directory_3__io_msInfo_3_bits_willFree;
  logic Directory_3__io_msInfo_3_bits_aliasTask;
  logic Directory_3__io_msInfo_3_bits_needRelease;
  logic Directory_3__io_msInfo_3_bits_blockRefill;
  logic Directory_3__io_msInfo_3_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_3_bits_meta_state;
  logic Directory_3__io_msInfo_3_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_3_bits_meta_alias;
  logic Directory_3__io_msInfo_3_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_3_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_3_bits_meta_accessed;
  logic Directory_3__io_msInfo_3_bits_meta_tagErr;
  logic Directory_3__io_msInfo_3_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_3_bits_metaTag;
  logic Directory_3__io_msInfo_3_bits_dirHit;
  logic Directory_3__io_msInfo_3_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_3_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_3_bits_param;
  logic Directory_3__io_msInfo_3_bits_mergeA;
  logic Directory_3__io_msInfo_3_bits_w_grantfirst;
  logic Directory_3__io_msInfo_3_bits_s_release;
  logic Directory_3__io_msInfo_3_bits_s_refill;
  logic Directory_3__io_msInfo_3_bits_s_cmoresp;
  logic Directory_3__io_msInfo_3_bits_s_cmometaw;
  logic Directory_3__io_msInfo_3_bits_w_releaseack;
  logic Directory_3__io_msInfo_3_bits_w_replResp;
  logic Directory_3__io_msInfo_3_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_3_bits_replaceData;
  logic Directory_3__io_msInfo_3_bits_releaseToClean;
  logic Directory_3__io_msInfo_4_valid;
  logic [2:0] Directory_3__io_msInfo_4_bits_channel;
  logic [8:0] Directory_3__io_msInfo_4_bits_set;
  logic [2:0] Directory_3__io_msInfo_4_bits_way;
  logic [30:0] Directory_3__io_msInfo_4_bits_reqTag;
  logic Directory_3__io_msInfo_4_bits_willFree;
  logic Directory_3__io_msInfo_4_bits_aliasTask;
  logic Directory_3__io_msInfo_4_bits_needRelease;
  logic Directory_3__io_msInfo_4_bits_blockRefill;
  logic Directory_3__io_msInfo_4_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_4_bits_meta_state;
  logic Directory_3__io_msInfo_4_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_4_bits_meta_alias;
  logic Directory_3__io_msInfo_4_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_4_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_4_bits_meta_accessed;
  logic Directory_3__io_msInfo_4_bits_meta_tagErr;
  logic Directory_3__io_msInfo_4_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_4_bits_metaTag;
  logic Directory_3__io_msInfo_4_bits_dirHit;
  logic Directory_3__io_msInfo_4_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_4_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_4_bits_param;
  logic Directory_3__io_msInfo_4_bits_mergeA;
  logic Directory_3__io_msInfo_4_bits_w_grantfirst;
  logic Directory_3__io_msInfo_4_bits_s_release;
  logic Directory_3__io_msInfo_4_bits_s_refill;
  logic Directory_3__io_msInfo_4_bits_s_cmoresp;
  logic Directory_3__io_msInfo_4_bits_s_cmometaw;
  logic Directory_3__io_msInfo_4_bits_w_releaseack;
  logic Directory_3__io_msInfo_4_bits_w_replResp;
  logic Directory_3__io_msInfo_4_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_4_bits_replaceData;
  logic Directory_3__io_msInfo_4_bits_releaseToClean;
  logic Directory_3__io_msInfo_5_valid;
  logic [2:0] Directory_3__io_msInfo_5_bits_channel;
  logic [8:0] Directory_3__io_msInfo_5_bits_set;
  logic [2:0] Directory_3__io_msInfo_5_bits_way;
  logic [30:0] Directory_3__io_msInfo_5_bits_reqTag;
  logic Directory_3__io_msInfo_5_bits_willFree;
  logic Directory_3__io_msInfo_5_bits_aliasTask;
  logic Directory_3__io_msInfo_5_bits_needRelease;
  logic Directory_3__io_msInfo_5_bits_blockRefill;
  logic Directory_3__io_msInfo_5_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_5_bits_meta_state;
  logic Directory_3__io_msInfo_5_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_5_bits_meta_alias;
  logic Directory_3__io_msInfo_5_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_5_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_5_bits_meta_accessed;
  logic Directory_3__io_msInfo_5_bits_meta_tagErr;
  logic Directory_3__io_msInfo_5_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_5_bits_metaTag;
  logic Directory_3__io_msInfo_5_bits_dirHit;
  logic Directory_3__io_msInfo_5_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_5_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_5_bits_param;
  logic Directory_3__io_msInfo_5_bits_mergeA;
  logic Directory_3__io_msInfo_5_bits_w_grantfirst;
  logic Directory_3__io_msInfo_5_bits_s_release;
  logic Directory_3__io_msInfo_5_bits_s_refill;
  logic Directory_3__io_msInfo_5_bits_s_cmoresp;
  logic Directory_3__io_msInfo_5_bits_s_cmometaw;
  logic Directory_3__io_msInfo_5_bits_w_releaseack;
  logic Directory_3__io_msInfo_5_bits_w_replResp;
  logic Directory_3__io_msInfo_5_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_5_bits_replaceData;
  logic Directory_3__io_msInfo_5_bits_releaseToClean;
  logic Directory_3__io_msInfo_6_valid;
  logic [2:0] Directory_3__io_msInfo_6_bits_channel;
  logic [8:0] Directory_3__io_msInfo_6_bits_set;
  logic [2:0] Directory_3__io_msInfo_6_bits_way;
  logic [30:0] Directory_3__io_msInfo_6_bits_reqTag;
  logic Directory_3__io_msInfo_6_bits_willFree;
  logic Directory_3__io_msInfo_6_bits_aliasTask;
  logic Directory_3__io_msInfo_6_bits_needRelease;
  logic Directory_3__io_msInfo_6_bits_blockRefill;
  logic Directory_3__io_msInfo_6_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_6_bits_meta_state;
  logic Directory_3__io_msInfo_6_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_6_bits_meta_alias;
  logic Directory_3__io_msInfo_6_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_6_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_6_bits_meta_accessed;
  logic Directory_3__io_msInfo_6_bits_meta_tagErr;
  logic Directory_3__io_msInfo_6_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_6_bits_metaTag;
  logic Directory_3__io_msInfo_6_bits_dirHit;
  logic Directory_3__io_msInfo_6_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_6_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_6_bits_param;
  logic Directory_3__io_msInfo_6_bits_mergeA;
  logic Directory_3__io_msInfo_6_bits_w_grantfirst;
  logic Directory_3__io_msInfo_6_bits_s_release;
  logic Directory_3__io_msInfo_6_bits_s_refill;
  logic Directory_3__io_msInfo_6_bits_s_cmoresp;
  logic Directory_3__io_msInfo_6_bits_s_cmometaw;
  logic Directory_3__io_msInfo_6_bits_w_releaseack;
  logic Directory_3__io_msInfo_6_bits_w_replResp;
  logic Directory_3__io_msInfo_6_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_6_bits_replaceData;
  logic Directory_3__io_msInfo_6_bits_releaseToClean;
  logic Directory_3__io_msInfo_7_valid;
  logic [2:0] Directory_3__io_msInfo_7_bits_channel;
  logic [8:0] Directory_3__io_msInfo_7_bits_set;
  logic [2:0] Directory_3__io_msInfo_7_bits_way;
  logic [30:0] Directory_3__io_msInfo_7_bits_reqTag;
  logic Directory_3__io_msInfo_7_bits_willFree;
  logic Directory_3__io_msInfo_7_bits_aliasTask;
  logic Directory_3__io_msInfo_7_bits_needRelease;
  logic Directory_3__io_msInfo_7_bits_blockRefill;
  logic Directory_3__io_msInfo_7_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_7_bits_meta_state;
  logic Directory_3__io_msInfo_7_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_7_bits_meta_alias;
  logic Directory_3__io_msInfo_7_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_7_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_7_bits_meta_accessed;
  logic Directory_3__io_msInfo_7_bits_meta_tagErr;
  logic Directory_3__io_msInfo_7_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_7_bits_metaTag;
  logic Directory_3__io_msInfo_7_bits_dirHit;
  logic Directory_3__io_msInfo_7_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_7_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_7_bits_param;
  logic Directory_3__io_msInfo_7_bits_mergeA;
  logic Directory_3__io_msInfo_7_bits_w_grantfirst;
  logic Directory_3__io_msInfo_7_bits_s_release;
  logic Directory_3__io_msInfo_7_bits_s_refill;
  logic Directory_3__io_msInfo_7_bits_s_cmoresp;
  logic Directory_3__io_msInfo_7_bits_s_cmometaw;
  logic Directory_3__io_msInfo_7_bits_w_releaseack;
  logic Directory_3__io_msInfo_7_bits_w_replResp;
  logic Directory_3__io_msInfo_7_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_7_bits_replaceData;
  logic Directory_3__io_msInfo_7_bits_releaseToClean;
  logic Directory_3__io_msInfo_8_valid;
  logic [2:0] Directory_3__io_msInfo_8_bits_channel;
  logic [8:0] Directory_3__io_msInfo_8_bits_set;
  logic [2:0] Directory_3__io_msInfo_8_bits_way;
  logic [30:0] Directory_3__io_msInfo_8_bits_reqTag;
  logic Directory_3__io_msInfo_8_bits_willFree;
  logic Directory_3__io_msInfo_8_bits_aliasTask;
  logic Directory_3__io_msInfo_8_bits_needRelease;
  logic Directory_3__io_msInfo_8_bits_blockRefill;
  logic Directory_3__io_msInfo_8_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_8_bits_meta_state;
  logic Directory_3__io_msInfo_8_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_8_bits_meta_alias;
  logic Directory_3__io_msInfo_8_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_8_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_8_bits_meta_accessed;
  logic Directory_3__io_msInfo_8_bits_meta_tagErr;
  logic Directory_3__io_msInfo_8_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_8_bits_metaTag;
  logic Directory_3__io_msInfo_8_bits_dirHit;
  logic Directory_3__io_msInfo_8_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_8_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_8_bits_param;
  logic Directory_3__io_msInfo_8_bits_mergeA;
  logic Directory_3__io_msInfo_8_bits_w_grantfirst;
  logic Directory_3__io_msInfo_8_bits_s_release;
  logic Directory_3__io_msInfo_8_bits_s_refill;
  logic Directory_3__io_msInfo_8_bits_s_cmoresp;
  logic Directory_3__io_msInfo_8_bits_s_cmometaw;
  logic Directory_3__io_msInfo_8_bits_w_releaseack;
  logic Directory_3__io_msInfo_8_bits_w_replResp;
  logic Directory_3__io_msInfo_8_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_8_bits_replaceData;
  logic Directory_3__io_msInfo_8_bits_releaseToClean;
  logic Directory_3__io_msInfo_9_valid;
  logic [2:0] Directory_3__io_msInfo_9_bits_channel;
  logic [8:0] Directory_3__io_msInfo_9_bits_set;
  logic [2:0] Directory_3__io_msInfo_9_bits_way;
  logic [30:0] Directory_3__io_msInfo_9_bits_reqTag;
  logic Directory_3__io_msInfo_9_bits_willFree;
  logic Directory_3__io_msInfo_9_bits_aliasTask;
  logic Directory_3__io_msInfo_9_bits_needRelease;
  logic Directory_3__io_msInfo_9_bits_blockRefill;
  logic Directory_3__io_msInfo_9_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_9_bits_meta_state;
  logic Directory_3__io_msInfo_9_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_9_bits_meta_alias;
  logic Directory_3__io_msInfo_9_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_9_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_9_bits_meta_accessed;
  logic Directory_3__io_msInfo_9_bits_meta_tagErr;
  logic Directory_3__io_msInfo_9_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_9_bits_metaTag;
  logic Directory_3__io_msInfo_9_bits_dirHit;
  logic Directory_3__io_msInfo_9_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_9_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_9_bits_param;
  logic Directory_3__io_msInfo_9_bits_mergeA;
  logic Directory_3__io_msInfo_9_bits_w_grantfirst;
  logic Directory_3__io_msInfo_9_bits_s_release;
  logic Directory_3__io_msInfo_9_bits_s_refill;
  logic Directory_3__io_msInfo_9_bits_s_cmoresp;
  logic Directory_3__io_msInfo_9_bits_s_cmometaw;
  logic Directory_3__io_msInfo_9_bits_w_releaseack;
  logic Directory_3__io_msInfo_9_bits_w_replResp;
  logic Directory_3__io_msInfo_9_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_9_bits_replaceData;
  logic Directory_3__io_msInfo_9_bits_releaseToClean;
  logic Directory_3__io_msInfo_10_valid;
  logic [2:0] Directory_3__io_msInfo_10_bits_channel;
  logic [8:0] Directory_3__io_msInfo_10_bits_set;
  logic [2:0] Directory_3__io_msInfo_10_bits_way;
  logic [30:0] Directory_3__io_msInfo_10_bits_reqTag;
  logic Directory_3__io_msInfo_10_bits_willFree;
  logic Directory_3__io_msInfo_10_bits_aliasTask;
  logic Directory_3__io_msInfo_10_bits_needRelease;
  logic Directory_3__io_msInfo_10_bits_blockRefill;
  logic Directory_3__io_msInfo_10_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_10_bits_meta_state;
  logic Directory_3__io_msInfo_10_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_10_bits_meta_alias;
  logic Directory_3__io_msInfo_10_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_10_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_10_bits_meta_accessed;
  logic Directory_3__io_msInfo_10_bits_meta_tagErr;
  logic Directory_3__io_msInfo_10_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_10_bits_metaTag;
  logic Directory_3__io_msInfo_10_bits_dirHit;
  logic Directory_3__io_msInfo_10_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_10_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_10_bits_param;
  logic Directory_3__io_msInfo_10_bits_mergeA;
  logic Directory_3__io_msInfo_10_bits_w_grantfirst;
  logic Directory_3__io_msInfo_10_bits_s_release;
  logic Directory_3__io_msInfo_10_bits_s_refill;
  logic Directory_3__io_msInfo_10_bits_s_cmoresp;
  logic Directory_3__io_msInfo_10_bits_s_cmometaw;
  logic Directory_3__io_msInfo_10_bits_w_releaseack;
  logic Directory_3__io_msInfo_10_bits_w_replResp;
  logic Directory_3__io_msInfo_10_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_10_bits_replaceData;
  logic Directory_3__io_msInfo_10_bits_releaseToClean;
  logic Directory_3__io_msInfo_11_valid;
  logic [2:0] Directory_3__io_msInfo_11_bits_channel;
  logic [8:0] Directory_3__io_msInfo_11_bits_set;
  logic [2:0] Directory_3__io_msInfo_11_bits_way;
  logic [30:0] Directory_3__io_msInfo_11_bits_reqTag;
  logic Directory_3__io_msInfo_11_bits_willFree;
  logic Directory_3__io_msInfo_11_bits_aliasTask;
  logic Directory_3__io_msInfo_11_bits_needRelease;
  logic Directory_3__io_msInfo_11_bits_blockRefill;
  logic Directory_3__io_msInfo_11_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_11_bits_meta_state;
  logic Directory_3__io_msInfo_11_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_11_bits_meta_alias;
  logic Directory_3__io_msInfo_11_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_11_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_11_bits_meta_accessed;
  logic Directory_3__io_msInfo_11_bits_meta_tagErr;
  logic Directory_3__io_msInfo_11_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_11_bits_metaTag;
  logic Directory_3__io_msInfo_11_bits_dirHit;
  logic Directory_3__io_msInfo_11_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_11_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_11_bits_param;
  logic Directory_3__io_msInfo_11_bits_mergeA;
  logic Directory_3__io_msInfo_11_bits_w_grantfirst;
  logic Directory_3__io_msInfo_11_bits_s_release;
  logic Directory_3__io_msInfo_11_bits_s_refill;
  logic Directory_3__io_msInfo_11_bits_s_cmoresp;
  logic Directory_3__io_msInfo_11_bits_s_cmometaw;
  logic Directory_3__io_msInfo_11_bits_w_releaseack;
  logic Directory_3__io_msInfo_11_bits_w_replResp;
  logic Directory_3__io_msInfo_11_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_11_bits_replaceData;
  logic Directory_3__io_msInfo_11_bits_releaseToClean;
  logic Directory_3__io_msInfo_12_valid;
  logic [2:0] Directory_3__io_msInfo_12_bits_channel;
  logic [8:0] Directory_3__io_msInfo_12_bits_set;
  logic [2:0] Directory_3__io_msInfo_12_bits_way;
  logic [30:0] Directory_3__io_msInfo_12_bits_reqTag;
  logic Directory_3__io_msInfo_12_bits_willFree;
  logic Directory_3__io_msInfo_12_bits_aliasTask;
  logic Directory_3__io_msInfo_12_bits_needRelease;
  logic Directory_3__io_msInfo_12_bits_blockRefill;
  logic Directory_3__io_msInfo_12_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_12_bits_meta_state;
  logic Directory_3__io_msInfo_12_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_12_bits_meta_alias;
  logic Directory_3__io_msInfo_12_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_12_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_12_bits_meta_accessed;
  logic Directory_3__io_msInfo_12_bits_meta_tagErr;
  logic Directory_3__io_msInfo_12_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_12_bits_metaTag;
  logic Directory_3__io_msInfo_12_bits_dirHit;
  logic Directory_3__io_msInfo_12_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_12_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_12_bits_param;
  logic Directory_3__io_msInfo_12_bits_mergeA;
  logic Directory_3__io_msInfo_12_bits_w_grantfirst;
  logic Directory_3__io_msInfo_12_bits_s_release;
  logic Directory_3__io_msInfo_12_bits_s_refill;
  logic Directory_3__io_msInfo_12_bits_s_cmoresp;
  logic Directory_3__io_msInfo_12_bits_s_cmometaw;
  logic Directory_3__io_msInfo_12_bits_w_releaseack;
  logic Directory_3__io_msInfo_12_bits_w_replResp;
  logic Directory_3__io_msInfo_12_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_12_bits_replaceData;
  logic Directory_3__io_msInfo_12_bits_releaseToClean;
  logic Directory_3__io_msInfo_13_valid;
  logic [2:0] Directory_3__io_msInfo_13_bits_channel;
  logic [8:0] Directory_3__io_msInfo_13_bits_set;
  logic [2:0] Directory_3__io_msInfo_13_bits_way;
  logic [30:0] Directory_3__io_msInfo_13_bits_reqTag;
  logic Directory_3__io_msInfo_13_bits_willFree;
  logic Directory_3__io_msInfo_13_bits_aliasTask;
  logic Directory_3__io_msInfo_13_bits_needRelease;
  logic Directory_3__io_msInfo_13_bits_blockRefill;
  logic Directory_3__io_msInfo_13_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_13_bits_meta_state;
  logic Directory_3__io_msInfo_13_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_13_bits_meta_alias;
  logic Directory_3__io_msInfo_13_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_13_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_13_bits_meta_accessed;
  logic Directory_3__io_msInfo_13_bits_meta_tagErr;
  logic Directory_3__io_msInfo_13_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_13_bits_metaTag;
  logic Directory_3__io_msInfo_13_bits_dirHit;
  logic Directory_3__io_msInfo_13_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_13_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_13_bits_param;
  logic Directory_3__io_msInfo_13_bits_mergeA;
  logic Directory_3__io_msInfo_13_bits_w_grantfirst;
  logic Directory_3__io_msInfo_13_bits_s_release;
  logic Directory_3__io_msInfo_13_bits_s_refill;
  logic Directory_3__io_msInfo_13_bits_s_cmoresp;
  logic Directory_3__io_msInfo_13_bits_s_cmometaw;
  logic Directory_3__io_msInfo_13_bits_w_releaseack;
  logic Directory_3__io_msInfo_13_bits_w_replResp;
  logic Directory_3__io_msInfo_13_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_13_bits_replaceData;
  logic Directory_3__io_msInfo_13_bits_releaseToClean;
  logic Directory_3__io_msInfo_14_valid;
  logic [2:0] Directory_3__io_msInfo_14_bits_channel;
  logic [8:0] Directory_3__io_msInfo_14_bits_set;
  logic [2:0] Directory_3__io_msInfo_14_bits_way;
  logic [30:0] Directory_3__io_msInfo_14_bits_reqTag;
  logic Directory_3__io_msInfo_14_bits_willFree;
  logic Directory_3__io_msInfo_14_bits_aliasTask;
  logic Directory_3__io_msInfo_14_bits_needRelease;
  logic Directory_3__io_msInfo_14_bits_blockRefill;
  logic Directory_3__io_msInfo_14_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_14_bits_meta_state;
  logic Directory_3__io_msInfo_14_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_14_bits_meta_alias;
  logic Directory_3__io_msInfo_14_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_14_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_14_bits_meta_accessed;
  logic Directory_3__io_msInfo_14_bits_meta_tagErr;
  logic Directory_3__io_msInfo_14_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_14_bits_metaTag;
  logic Directory_3__io_msInfo_14_bits_dirHit;
  logic Directory_3__io_msInfo_14_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_14_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_14_bits_param;
  logic Directory_3__io_msInfo_14_bits_mergeA;
  logic Directory_3__io_msInfo_14_bits_w_grantfirst;
  logic Directory_3__io_msInfo_14_bits_s_release;
  logic Directory_3__io_msInfo_14_bits_s_refill;
  logic Directory_3__io_msInfo_14_bits_s_cmoresp;
  logic Directory_3__io_msInfo_14_bits_s_cmometaw;
  logic Directory_3__io_msInfo_14_bits_w_releaseack;
  logic Directory_3__io_msInfo_14_bits_w_replResp;
  logic Directory_3__io_msInfo_14_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_14_bits_replaceData;
  logic Directory_3__io_msInfo_14_bits_releaseToClean;
  logic Directory_3__io_msInfo_15_valid;
  logic [2:0] Directory_3__io_msInfo_15_bits_channel;
  logic [8:0] Directory_3__io_msInfo_15_bits_set;
  logic [2:0] Directory_3__io_msInfo_15_bits_way;
  logic [30:0] Directory_3__io_msInfo_15_bits_reqTag;
  logic Directory_3__io_msInfo_15_bits_willFree;
  logic Directory_3__io_msInfo_15_bits_aliasTask;
  logic Directory_3__io_msInfo_15_bits_needRelease;
  logic Directory_3__io_msInfo_15_bits_blockRefill;
  logic Directory_3__io_msInfo_15_bits_meta_dirty;
  logic [1:0] Directory_3__io_msInfo_15_bits_meta_state;
  logic Directory_3__io_msInfo_15_bits_meta_clients;
  logic [1:0] Directory_3__io_msInfo_15_bits_meta_alias;
  logic Directory_3__io_msInfo_15_bits_meta_prefetch;
  logic [2:0] Directory_3__io_msInfo_15_bits_meta_prefetchSrc;
  logic Directory_3__io_msInfo_15_bits_meta_accessed;
  logic Directory_3__io_msInfo_15_bits_meta_tagErr;
  logic Directory_3__io_msInfo_15_bits_meta_dataErr;
  logic [30:0] Directory_3__io_msInfo_15_bits_metaTag;
  logic Directory_3__io_msInfo_15_bits_dirHit;
  logic Directory_3__io_msInfo_15_bits_isAcqOrPrefetch;
  logic Directory_3__io_msInfo_15_bits_isPrefetch;
  logic [2:0] Directory_3__io_msInfo_15_bits_param;
  logic Directory_3__io_msInfo_15_bits_mergeA;
  logic Directory_3__io_msInfo_15_bits_w_grantfirst;
  logic Directory_3__io_msInfo_15_bits_s_release;
  logic Directory_3__io_msInfo_15_bits_s_refill;
  logic Directory_3__io_msInfo_15_bits_s_cmoresp;
  logic Directory_3__io_msInfo_15_bits_s_cmometaw;
  logic Directory_3__io_msInfo_15_bits_w_releaseack;
  logic Directory_3__io_msInfo_15_bits_w_replResp;
  logic Directory_3__io_msInfo_15_bits_w_rprobeacklast;
  logic Directory_3__io_msInfo_15_bits_replaceData;
  logic Directory_3__io_msInfo_15_bits_releaseToClean;
  logic [5:0] Directory_3__boreChildrenBd_bore_array;
  logic Directory_3__boreChildrenBd_bore_all;
  logic Directory_3__boreChildrenBd_bore_req;
  logic Directory_3__boreChildrenBd_bore_writeen;
  logic [7:0] Directory_3__boreChildrenBd_bore_be;
  logic [9:0] Directory_3__boreChildrenBd_bore_addr;
  logic [103:0] Directory_3__boreChildrenBd_bore_indata;
  logic Directory_3__boreChildrenBd_bore_readen;
  logic [9:0] Directory_3__boreChildrenBd_bore_addr_rd;
  logic Directory_3__sigFromSrams_bore_ram_hold;
  logic Directory_3__sigFromSrams_bore_ram_bypass;
  logic Directory_3__sigFromSrams_bore_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_cgen;
  logic Directory_3__sigFromSrams_bore_1_ram_hold;
  logic Directory_3__sigFromSrams_bore_1_ram_bypass;
  logic Directory_3__sigFromSrams_bore_1_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_1_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_1_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_1_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_1_cgen;
  logic Directory_3__sigFromSrams_bore_2_ram_hold;
  logic Directory_3__sigFromSrams_bore_2_ram_bypass;
  logic Directory_3__sigFromSrams_bore_2_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_2_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_2_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_2_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_2_cgen;
  logic Directory_3__sigFromSrams_bore_3_ram_hold;
  logic Directory_3__sigFromSrams_bore_3_ram_bypass;
  logic Directory_3__sigFromSrams_bore_3_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_3_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_3_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_3_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_3_cgen;
  logic Directory_3__sigFromSrams_bore_4_ram_hold;
  logic Directory_3__sigFromSrams_bore_4_ram_bypass;
  logic Directory_3__sigFromSrams_bore_4_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_4_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_4_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_4_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_4_cgen;
  logic Directory_3__sigFromSrams_bore_5_ram_hold;
  logic Directory_3__sigFromSrams_bore_5_ram_bypass;
  logic Directory_3__sigFromSrams_bore_5_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_5_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_5_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_5_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_5_cgen;
  logic Directory_3__sigFromSrams_bore_6_ram_hold;
  logic Directory_3__sigFromSrams_bore_6_ram_bypass;
  logic Directory_3__sigFromSrams_bore_6_ram_bp_clken;
  logic Directory_3__sigFromSrams_bore_6_ram_aux_clk;
  logic Directory_3__sigFromSrams_bore_6_ram_aux_ckbp;
  logic Directory_3__sigFromSrams_bore_6_ram_mcp_hold;
  logic Directory_3__sigFromSrams_bore_6_cgen;
  wire  g_Directory_3__io_read_ready;
  wire  i_Directory_3__io_read_ready;
  logic p_Directory_3__io_read_ready;
  bit   t_Directory_3__io_read_ready;
  wire  g_Directory_3__io_resp_valid;
  wire  i_Directory_3__io_resp_valid;
  logic p_Directory_3__io_resp_valid;
  bit   t_Directory_3__io_resp_valid;
  wire  g_Directory_3__io_resp_bits_hit;
  wire  i_Directory_3__io_resp_bits_hit;
  logic p_Directory_3__io_resp_bits_hit;
  bit   t_Directory_3__io_resp_bits_hit;
  wire  [30:0] g_Directory_3__io_resp_bits_tag;
  wire  [30:0] i_Directory_3__io_resp_bits_tag;
  logic [30:0] p_Directory_3__io_resp_bits_tag;
  bit   t_Directory_3__io_resp_bits_tag;
  wire  [8:0] g_Directory_3__io_resp_bits_set;
  wire  [8:0] i_Directory_3__io_resp_bits_set;
  logic [8:0] p_Directory_3__io_resp_bits_set;
  bit   t_Directory_3__io_resp_bits_set;
  wire  [2:0] g_Directory_3__io_resp_bits_way;
  wire  [2:0] i_Directory_3__io_resp_bits_way;
  logic [2:0] p_Directory_3__io_resp_bits_way;
  bit   t_Directory_3__io_resp_bits_way;
  wire  g_Directory_3__io_resp_bits_meta_dirty;
  wire  i_Directory_3__io_resp_bits_meta_dirty;
  logic p_Directory_3__io_resp_bits_meta_dirty;
  bit   t_Directory_3__io_resp_bits_meta_dirty;
  wire  [1:0] g_Directory_3__io_resp_bits_meta_state;
  wire  [1:0] i_Directory_3__io_resp_bits_meta_state;
  logic [1:0] p_Directory_3__io_resp_bits_meta_state;
  bit   t_Directory_3__io_resp_bits_meta_state;
  wire  g_Directory_3__io_resp_bits_meta_clients;
  wire  i_Directory_3__io_resp_bits_meta_clients;
  logic p_Directory_3__io_resp_bits_meta_clients;
  bit   t_Directory_3__io_resp_bits_meta_clients;
  wire  [1:0] g_Directory_3__io_resp_bits_meta_alias;
  wire  [1:0] i_Directory_3__io_resp_bits_meta_alias;
  logic [1:0] p_Directory_3__io_resp_bits_meta_alias;
  bit   t_Directory_3__io_resp_bits_meta_alias;
  wire  g_Directory_3__io_resp_bits_meta_prefetch;
  wire  i_Directory_3__io_resp_bits_meta_prefetch;
  logic p_Directory_3__io_resp_bits_meta_prefetch;
  bit   t_Directory_3__io_resp_bits_meta_prefetch;
  wire  [2:0] g_Directory_3__io_resp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory_3__io_resp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory_3__io_resp_bits_meta_prefetchSrc;
  bit   t_Directory_3__io_resp_bits_meta_prefetchSrc;
  wire  g_Directory_3__io_resp_bits_meta_accessed;
  wire  i_Directory_3__io_resp_bits_meta_accessed;
  logic p_Directory_3__io_resp_bits_meta_accessed;
  bit   t_Directory_3__io_resp_bits_meta_accessed;
  wire  g_Directory_3__io_resp_bits_meta_tagErr;
  wire  i_Directory_3__io_resp_bits_meta_tagErr;
  logic p_Directory_3__io_resp_bits_meta_tagErr;
  bit   t_Directory_3__io_resp_bits_meta_tagErr;
  wire  g_Directory_3__io_resp_bits_meta_dataErr;
  wire  i_Directory_3__io_resp_bits_meta_dataErr;
  logic p_Directory_3__io_resp_bits_meta_dataErr;
  bit   t_Directory_3__io_resp_bits_meta_dataErr;
  wire  g_Directory_3__io_resp_bits_error;
  wire  i_Directory_3__io_resp_bits_error;
  logic p_Directory_3__io_resp_bits_error;
  bit   t_Directory_3__io_resp_bits_error;
  wire  [2:0] g_Directory_3__io_resp_bits_replacerInfo_channel;
  wire  [2:0] i_Directory_3__io_resp_bits_replacerInfo_channel;
  logic [2:0] p_Directory_3__io_resp_bits_replacerInfo_channel;
  bit   t_Directory_3__io_resp_bits_replacerInfo_channel;
  wire  [2:0] g_Directory_3__io_resp_bits_replacerInfo_opcode;
  wire  [2:0] i_Directory_3__io_resp_bits_replacerInfo_opcode;
  logic [2:0] p_Directory_3__io_resp_bits_replacerInfo_opcode;
  bit   t_Directory_3__io_resp_bits_replacerInfo_opcode;
  wire  [4:0] g_Directory_3__io_resp_bits_replacerInfo_reqSource;
  wire  [4:0] i_Directory_3__io_resp_bits_replacerInfo_reqSource;
  logic [4:0] p_Directory_3__io_resp_bits_replacerInfo_reqSource;
  bit   t_Directory_3__io_resp_bits_replacerInfo_reqSource;
  wire  g_Directory_3__io_resp_bits_replacerInfo_refill_prefetch;
  wire  i_Directory_3__io_resp_bits_replacerInfo_refill_prefetch;
  logic p_Directory_3__io_resp_bits_replacerInfo_refill_prefetch;
  bit   t_Directory_3__io_resp_bits_replacerInfo_refill_prefetch;
  wire  g_Directory_3__io_replResp_valid;
  wire  i_Directory_3__io_replResp_valid;
  logic p_Directory_3__io_replResp_valid;
  bit   t_Directory_3__io_replResp_valid;
  wire  [30:0] g_Directory_3__io_replResp_bits_tag;
  wire  [30:0] i_Directory_3__io_replResp_bits_tag;
  logic [30:0] p_Directory_3__io_replResp_bits_tag;
  bit   t_Directory_3__io_replResp_bits_tag;
  wire  [8:0] g_Directory_3__io_replResp_bits_set;
  wire  [8:0] i_Directory_3__io_replResp_bits_set;
  logic [8:0] p_Directory_3__io_replResp_bits_set;
  bit   t_Directory_3__io_replResp_bits_set;
  wire  [2:0] g_Directory_3__io_replResp_bits_way;
  wire  [2:0] i_Directory_3__io_replResp_bits_way;
  logic [2:0] p_Directory_3__io_replResp_bits_way;
  bit   t_Directory_3__io_replResp_bits_way;
  wire  g_Directory_3__io_replResp_bits_meta_dirty;
  wire  i_Directory_3__io_replResp_bits_meta_dirty;
  logic p_Directory_3__io_replResp_bits_meta_dirty;
  bit   t_Directory_3__io_replResp_bits_meta_dirty;
  wire  [1:0] g_Directory_3__io_replResp_bits_meta_state;
  wire  [1:0] i_Directory_3__io_replResp_bits_meta_state;
  logic [1:0] p_Directory_3__io_replResp_bits_meta_state;
  bit   t_Directory_3__io_replResp_bits_meta_state;
  wire  g_Directory_3__io_replResp_bits_meta_clients;
  wire  i_Directory_3__io_replResp_bits_meta_clients;
  logic p_Directory_3__io_replResp_bits_meta_clients;
  bit   t_Directory_3__io_replResp_bits_meta_clients;
  wire  [1:0] g_Directory_3__io_replResp_bits_meta_alias;
  wire  [1:0] i_Directory_3__io_replResp_bits_meta_alias;
  logic [1:0] p_Directory_3__io_replResp_bits_meta_alias;
  bit   t_Directory_3__io_replResp_bits_meta_alias;
  wire  g_Directory_3__io_replResp_bits_meta_prefetch;
  wire  i_Directory_3__io_replResp_bits_meta_prefetch;
  logic p_Directory_3__io_replResp_bits_meta_prefetch;
  bit   t_Directory_3__io_replResp_bits_meta_prefetch;
  wire  [2:0] g_Directory_3__io_replResp_bits_meta_prefetchSrc;
  wire  [2:0] i_Directory_3__io_replResp_bits_meta_prefetchSrc;
  logic [2:0] p_Directory_3__io_replResp_bits_meta_prefetchSrc;
  bit   t_Directory_3__io_replResp_bits_meta_prefetchSrc;
  wire  g_Directory_3__io_replResp_bits_meta_accessed;
  wire  i_Directory_3__io_replResp_bits_meta_accessed;
  logic p_Directory_3__io_replResp_bits_meta_accessed;
  bit   t_Directory_3__io_replResp_bits_meta_accessed;
  wire  g_Directory_3__io_replResp_bits_meta_tagErr;
  wire  i_Directory_3__io_replResp_bits_meta_tagErr;
  logic p_Directory_3__io_replResp_bits_meta_tagErr;
  bit   t_Directory_3__io_replResp_bits_meta_tagErr;
  wire  g_Directory_3__io_replResp_bits_meta_dataErr;
  wire  i_Directory_3__io_replResp_bits_meta_dataErr;
  logic p_Directory_3__io_replResp_bits_meta_dataErr;
  bit   t_Directory_3__io_replResp_bits_meta_dataErr;
  wire  [7:0] g_Directory_3__io_replResp_bits_mshrId;
  wire  [7:0] i_Directory_3__io_replResp_bits_mshrId;
  logic [7:0] p_Directory_3__io_replResp_bits_mshrId;
  bit   t_Directory_3__io_replResp_bits_mshrId;
  wire  g_Directory_3__io_replResp_bits_retry;
  wire  i_Directory_3__io_replResp_bits_retry;
  logic p_Directory_3__io_replResp_bits_retry;
  bit   t_Directory_3__io_replResp_bits_retry;
  wire  g_Directory_3__io_replResp_bits_error;
  wire  i_Directory_3__io_replResp_bits_error;
  logic p_Directory_3__io_replResp_bits_error;
  bit   t_Directory_3__io_replResp_bits_error;
  wire  g_Directory_3__boreChildrenBd_bore_ack;
  wire  i_Directory_3__boreChildrenBd_bore_ack;
  logic p_Directory_3__boreChildrenBd_bore_ack;
  bit   t_Directory_3__boreChildrenBd_bore_ack;
  wire  [103:0] g_Directory_3__boreChildrenBd_bore_outdata;
  wire  [103:0] i_Directory_3__boreChildrenBd_bore_outdata;
  logic [103:0] p_Directory_3__boreChildrenBd_bore_outdata;
  bit   t_Directory_3__boreChildrenBd_bore_outdata;
  Directory_3 u_g_Directory_3 (
    .clock (clock),
    .reset (reset),
    .io_read_ready (g_Directory_3__io_read_ready),
    .io_read_valid (Directory_3__io_read_valid),
    .io_read_bits_tag (Directory_3__io_read_bits_tag),
    .io_read_bits_set (Directory_3__io_read_bits_set),
    .io_read_bits_wayMask (Directory_3__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory_3__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory_3__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory_3__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory_3__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory_3__io_read_bits_refill),
    .io_read_bits_mshrId (Directory_3__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory_3__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory_3__io_read_bits_cmoWay),
    .io_resp_valid (g_Directory_3__io_resp_valid),
    .io_resp_bits_hit (g_Directory_3__io_resp_bits_hit),
    .io_resp_bits_tag (g_Directory_3__io_resp_bits_tag),
    .io_resp_bits_set (g_Directory_3__io_resp_bits_set),
    .io_resp_bits_way (g_Directory_3__io_resp_bits_way),
    .io_resp_bits_meta_dirty (g_Directory_3__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (g_Directory_3__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (g_Directory_3__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (g_Directory_3__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (g_Directory_3__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (g_Directory_3__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (g_Directory_3__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (g_Directory_3__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (g_Directory_3__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (g_Directory_3__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (g_Directory_3__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (g_Directory_3__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (g_Directory_3__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (g_Directory_3__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory_3__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory_3__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory_3__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory_3__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory_3__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory_3__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory_3__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory_3__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory_3__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory_3__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory_3__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory_3__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory_3__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory_3__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory_3__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory_3__io_tagWReq_bits_wtag),
    .io_replResp_valid (g_Directory_3__io_replResp_valid),
    .io_replResp_bits_tag (g_Directory_3__io_replResp_bits_tag),
    .io_replResp_bits_set (g_Directory_3__io_replResp_bits_set),
    .io_replResp_bits_way (g_Directory_3__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (g_Directory_3__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (g_Directory_3__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (g_Directory_3__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (g_Directory_3__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (g_Directory_3__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (g_Directory_3__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (g_Directory_3__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (g_Directory_3__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (g_Directory_3__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (g_Directory_3__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (g_Directory_3__io_replResp_bits_retry),
    .io_replResp_bits_error (g_Directory_3__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory_3__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory_3__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory_3__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory_3__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory_3__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory_3__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory_3__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory_3__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory_3__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory_3__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory_3__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory_3__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory_3__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory_3__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory_3__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory_3__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory_3__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory_3__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory_3__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory_3__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory_3__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory_3__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory_3__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory_3__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory_3__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory_3__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory_3__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory_3__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory_3__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory_3__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory_3__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory_3__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory_3__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory_3__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory_3__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory_3__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory_3__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory_3__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory_3__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory_3__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory_3__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory_3__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory_3__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory_3__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory_3__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory_3__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory_3__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory_3__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory_3__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory_3__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory_3__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory_3__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory_3__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory_3__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory_3__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory_3__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory_3__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory_3__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory_3__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory_3__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory_3__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory_3__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory_3__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory_3__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory_3__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory_3__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory_3__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory_3__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory_3__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory_3__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory_3__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory_3__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory_3__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory_3__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory_3__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory_3__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory_3__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory_3__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory_3__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory_3__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory_3__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory_3__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory_3__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory_3__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory_3__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory_3__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory_3__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory_3__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory_3__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory_3__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory_3__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory_3__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory_3__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory_3__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory_3__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory_3__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory_3__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory_3__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory_3__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory_3__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory_3__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory_3__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory_3__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory_3__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory_3__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory_3__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory_3__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory_3__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory_3__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory_3__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory_3__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory_3__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory_3__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory_3__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory_3__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory_3__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory_3__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory_3__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory_3__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory_3__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory_3__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory_3__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory_3__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory_3__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory_3__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory_3__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory_3__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory_3__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory_3__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory_3__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory_3__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory_3__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory_3__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory_3__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory_3__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory_3__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory_3__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory_3__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory_3__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory_3__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory_3__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory_3__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory_3__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory_3__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory_3__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory_3__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory_3__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory_3__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory_3__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory_3__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory_3__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory_3__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory_3__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory_3__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory_3__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory_3__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory_3__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory_3__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory_3__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory_3__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory_3__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory_3__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory_3__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory_3__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory_3__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory_3__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory_3__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory_3__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory_3__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory_3__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory_3__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory_3__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory_3__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory_3__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory_3__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory_3__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory_3__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory_3__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory_3__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory_3__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory_3__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory_3__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory_3__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory_3__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory_3__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory_3__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory_3__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory_3__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory_3__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory_3__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory_3__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory_3__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory_3__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory_3__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory_3__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory_3__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory_3__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory_3__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory_3__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory_3__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory_3__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory_3__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory_3__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory_3__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory_3__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory_3__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory_3__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory_3__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory_3__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory_3__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory_3__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory_3__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory_3__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory_3__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory_3__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory_3__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory_3__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory_3__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory_3__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory_3__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory_3__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory_3__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory_3__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory_3__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory_3__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory_3__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory_3__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory_3__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory_3__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory_3__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory_3__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory_3__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory_3__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory_3__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory_3__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory_3__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory_3__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory_3__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory_3__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory_3__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory_3__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory_3__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory_3__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory_3__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory_3__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory_3__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory_3__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory_3__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory_3__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory_3__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory_3__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory_3__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory_3__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory_3__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory_3__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory_3__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory_3__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory_3__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory_3__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory_3__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory_3__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory_3__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory_3__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory_3__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory_3__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory_3__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory_3__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory_3__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory_3__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory_3__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory_3__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory_3__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory_3__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory_3__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory_3__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory_3__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory_3__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory_3__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory_3__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory_3__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory_3__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory_3__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory_3__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory_3__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory_3__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory_3__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory_3__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory_3__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory_3__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory_3__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory_3__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory_3__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory_3__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory_3__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory_3__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory_3__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory_3__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory_3__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory_3__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory_3__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory_3__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory_3__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory_3__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory_3__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory_3__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory_3__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory_3__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory_3__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory_3__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory_3__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory_3__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory_3__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory_3__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory_3__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory_3__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory_3__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory_3__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory_3__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory_3__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory_3__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory_3__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory_3__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory_3__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory_3__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory_3__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory_3__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory_3__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory_3__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory_3__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory_3__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory_3__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory_3__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory_3__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory_3__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory_3__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory_3__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory_3__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory_3__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory_3__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory_3__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory_3__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory_3__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory_3__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory_3__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory_3__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory_3__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory_3__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory_3__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory_3__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory_3__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory_3__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory_3__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory_3__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory_3__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory_3__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory_3__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory_3__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory_3__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory_3__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory_3__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory_3__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory_3__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory_3__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory_3__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory_3__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory_3__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory_3__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory_3__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory_3__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory_3__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory_3__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory_3__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory_3__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory_3__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory_3__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory_3__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory_3__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory_3__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory_3__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory_3__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory_3__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory_3__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory_3__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory_3__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory_3__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory_3__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory_3__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory_3__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory_3__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory_3__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory_3__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory_3__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory_3__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory_3__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory_3__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory_3__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory_3__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory_3__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory_3__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory_3__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory_3__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory_3__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory_3__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory_3__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory_3__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory_3__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory_3__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory_3__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory_3__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory_3__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory_3__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory_3__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory_3__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory_3__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory_3__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory_3__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory_3__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory_3__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory_3__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory_3__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory_3__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory_3__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory_3__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory_3__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory_3__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory_3__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory_3__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory_3__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory_3__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory_3__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory_3__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory_3__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory_3__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory_3__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory_3__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory_3__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory_3__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory_3__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory_3__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory_3__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory_3__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory_3__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory_3__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory_3__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory_3__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory_3__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory_3__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory_3__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory_3__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory_3__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory_3__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory_3__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory_3__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory_3__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory_3__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory_3__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory_3__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory_3__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory_3__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory_3__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory_3__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory_3__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory_3__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory_3__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory_3__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory_3__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory_3__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory_3__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory_3__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory_3__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory_3__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory_3__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory_3__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory_3__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory_3__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory_3__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory_3__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory_3__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory_3__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory_3__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory_3__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory_3__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory_3__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory_3__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory_3__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory_3__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory_3__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory_3__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory_3__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory_3__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory_3__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory_3__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory_3__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory_3__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory_3__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory_3__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory_3__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory_3__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory_3__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory_3__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory_3__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory_3__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory_3__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory_3__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory_3__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory_3__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory_3__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory_3__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory_3__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory_3__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory_3__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory_3__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory_3__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory_3__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory_3__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory_3__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory_3__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory_3__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory_3__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory_3__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory_3__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory_3__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory_3__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory_3__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory_3__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory_3__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory_3__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory_3__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory_3__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory_3__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory_3__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory_3__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory_3__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory_3__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory_3__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory_3__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory_3__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory_3__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory_3__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory_3__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory_3__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory_3__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory_3__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory_3__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory_3__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory_3__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory_3__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_Directory_3__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory_3__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory_3__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory_3__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory_3__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory_3__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory_3__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_Directory_3__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory_3__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory_3__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory_3__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory_3__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory_3__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory_3__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory_3__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory_3__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory_3__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory_3__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory_3__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory_3__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory_3__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory_3__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory_3__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory_3__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory_3__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory_3__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory_3__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory_3__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory_3__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory_3__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory_3__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory_3__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory_3__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory_3__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory_3__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory_3__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory_3__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory_3__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory_3__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory_3__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory_3__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory_3__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory_3__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory_3__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory_3__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory_3__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory_3__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory_3__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory_3__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory_3__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory_3__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory_3__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory_3__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory_3__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory_3__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory_3__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory_3__sigFromSrams_bore_6_cgen)
  );
  Directory_3_xs u_i_Directory_3 (
    .clock (clock),
    .reset (reset),
    .io_read_ready (i_Directory_3__io_read_ready),
    .io_read_valid (Directory_3__io_read_valid),
    .io_read_bits_tag (Directory_3__io_read_bits_tag),
    .io_read_bits_set (Directory_3__io_read_bits_set),
    .io_read_bits_wayMask (Directory_3__io_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel (Directory_3__io_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode (Directory_3__io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource (Directory_3__io_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (Directory_3__io_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill (Directory_3__io_read_bits_refill),
    .io_read_bits_mshrId (Directory_3__io_read_bits_mshrId),
    .io_read_bits_cmoAll (Directory_3__io_read_bits_cmoAll),
    .io_read_bits_cmoWay (Directory_3__io_read_bits_cmoWay),
    .io_resp_valid (i_Directory_3__io_resp_valid),
    .io_resp_bits_hit (i_Directory_3__io_resp_bits_hit),
    .io_resp_bits_tag (i_Directory_3__io_resp_bits_tag),
    .io_resp_bits_set (i_Directory_3__io_resp_bits_set),
    .io_resp_bits_way (i_Directory_3__io_resp_bits_way),
    .io_resp_bits_meta_dirty (i_Directory_3__io_resp_bits_meta_dirty),
    .io_resp_bits_meta_state (i_Directory_3__io_resp_bits_meta_state),
    .io_resp_bits_meta_clients (i_Directory_3__io_resp_bits_meta_clients),
    .io_resp_bits_meta_alias (i_Directory_3__io_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch (i_Directory_3__io_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc (i_Directory_3__io_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed (i_Directory_3__io_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr (i_Directory_3__io_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr (i_Directory_3__io_resp_bits_meta_dataErr),
    .io_resp_bits_error (i_Directory_3__io_resp_bits_error),
    .io_resp_bits_replacerInfo_channel (i_Directory_3__io_resp_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode (i_Directory_3__io_resp_bits_replacerInfo_opcode),
    .io_resp_bits_replacerInfo_reqSource (i_Directory_3__io_resp_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (i_Directory_3__io_resp_bits_replacerInfo_refill_prefetch),
    .io_metaWReq_valid (Directory_3__io_metaWReq_valid),
    .io_metaWReq_bits_set (Directory_3__io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH (Directory_3__io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty (Directory_3__io_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state (Directory_3__io_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients (Directory_3__io_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias (Directory_3__io_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch (Directory_3__io_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc (Directory_3__io_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed (Directory_3__io_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr (Directory_3__io_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr (Directory_3__io_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid (Directory_3__io_tagWReq_valid),
    .io_tagWReq_bits_set (Directory_3__io_tagWReq_bits_set),
    .io_tagWReq_bits_way (Directory_3__io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag (Directory_3__io_tagWReq_bits_wtag),
    .io_replResp_valid (i_Directory_3__io_replResp_valid),
    .io_replResp_bits_tag (i_Directory_3__io_replResp_bits_tag),
    .io_replResp_bits_set (i_Directory_3__io_replResp_bits_set),
    .io_replResp_bits_way (i_Directory_3__io_replResp_bits_way),
    .io_replResp_bits_meta_dirty (i_Directory_3__io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state (i_Directory_3__io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients (i_Directory_3__io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias (i_Directory_3__io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch (i_Directory_3__io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc (i_Directory_3__io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed (i_Directory_3__io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr (i_Directory_3__io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr (i_Directory_3__io_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId (i_Directory_3__io_replResp_bits_mshrId),
    .io_replResp_bits_retry (i_Directory_3__io_replResp_bits_retry),
    .io_replResp_bits_error (i_Directory_3__io_replResp_bits_error),
    .io_msInfo_0_valid (Directory_3__io_msInfo_0_valid),
    .io_msInfo_0_bits_channel (Directory_3__io_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set (Directory_3__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_way (Directory_3__io_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag (Directory_3__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree (Directory_3__io_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask (Directory_3__io_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease (Directory_3__io_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill (Directory_3__io_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty (Directory_3__io_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state (Directory_3__io_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients (Directory_3__io_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias (Directory_3__io_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch (Directory_3__io_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc (Directory_3__io_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed (Directory_3__io_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr (Directory_3__io_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr (Directory_3__io_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag (Directory_3__io_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit (Directory_3__io_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch (Directory_3__io_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch (Directory_3__io_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param (Directory_3__io_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA (Directory_3__io_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst (Directory_3__io_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release (Directory_3__io_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill (Directory_3__io_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp (Directory_3__io_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw (Directory_3__io_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack (Directory_3__io_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp (Directory_3__io_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast (Directory_3__io_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData (Directory_3__io_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean (Directory_3__io_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid (Directory_3__io_msInfo_1_valid),
    .io_msInfo_1_bits_channel (Directory_3__io_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set (Directory_3__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_way (Directory_3__io_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag (Directory_3__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree (Directory_3__io_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask (Directory_3__io_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease (Directory_3__io_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill (Directory_3__io_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty (Directory_3__io_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state (Directory_3__io_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients (Directory_3__io_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias (Directory_3__io_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch (Directory_3__io_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc (Directory_3__io_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed (Directory_3__io_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr (Directory_3__io_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr (Directory_3__io_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag (Directory_3__io_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit (Directory_3__io_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch (Directory_3__io_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch (Directory_3__io_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param (Directory_3__io_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA (Directory_3__io_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst (Directory_3__io_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release (Directory_3__io_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill (Directory_3__io_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp (Directory_3__io_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw (Directory_3__io_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack (Directory_3__io_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp (Directory_3__io_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast (Directory_3__io_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData (Directory_3__io_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean (Directory_3__io_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid (Directory_3__io_msInfo_2_valid),
    .io_msInfo_2_bits_channel (Directory_3__io_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set (Directory_3__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_way (Directory_3__io_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag (Directory_3__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree (Directory_3__io_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask (Directory_3__io_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease (Directory_3__io_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill (Directory_3__io_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty (Directory_3__io_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state (Directory_3__io_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients (Directory_3__io_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias (Directory_3__io_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch (Directory_3__io_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc (Directory_3__io_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed (Directory_3__io_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr (Directory_3__io_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr (Directory_3__io_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag (Directory_3__io_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit (Directory_3__io_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch (Directory_3__io_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch (Directory_3__io_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param (Directory_3__io_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA (Directory_3__io_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst (Directory_3__io_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release (Directory_3__io_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill (Directory_3__io_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp (Directory_3__io_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw (Directory_3__io_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack (Directory_3__io_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp (Directory_3__io_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast (Directory_3__io_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData (Directory_3__io_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean (Directory_3__io_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid (Directory_3__io_msInfo_3_valid),
    .io_msInfo_3_bits_channel (Directory_3__io_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set (Directory_3__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_way (Directory_3__io_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag (Directory_3__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree (Directory_3__io_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask (Directory_3__io_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease (Directory_3__io_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill (Directory_3__io_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty (Directory_3__io_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state (Directory_3__io_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients (Directory_3__io_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias (Directory_3__io_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch (Directory_3__io_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc (Directory_3__io_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed (Directory_3__io_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr (Directory_3__io_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr (Directory_3__io_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag (Directory_3__io_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit (Directory_3__io_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch (Directory_3__io_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch (Directory_3__io_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param (Directory_3__io_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA (Directory_3__io_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst (Directory_3__io_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release (Directory_3__io_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill (Directory_3__io_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp (Directory_3__io_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw (Directory_3__io_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack (Directory_3__io_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp (Directory_3__io_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast (Directory_3__io_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData (Directory_3__io_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean (Directory_3__io_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid (Directory_3__io_msInfo_4_valid),
    .io_msInfo_4_bits_channel (Directory_3__io_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set (Directory_3__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_way (Directory_3__io_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag (Directory_3__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree (Directory_3__io_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask (Directory_3__io_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease (Directory_3__io_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill (Directory_3__io_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty (Directory_3__io_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state (Directory_3__io_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients (Directory_3__io_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias (Directory_3__io_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch (Directory_3__io_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc (Directory_3__io_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed (Directory_3__io_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr (Directory_3__io_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr (Directory_3__io_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag (Directory_3__io_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit (Directory_3__io_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch (Directory_3__io_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch (Directory_3__io_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param (Directory_3__io_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA (Directory_3__io_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst (Directory_3__io_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release (Directory_3__io_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill (Directory_3__io_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp (Directory_3__io_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw (Directory_3__io_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack (Directory_3__io_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp (Directory_3__io_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast (Directory_3__io_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData (Directory_3__io_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean (Directory_3__io_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid (Directory_3__io_msInfo_5_valid),
    .io_msInfo_5_bits_channel (Directory_3__io_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set (Directory_3__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_way (Directory_3__io_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag (Directory_3__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree (Directory_3__io_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask (Directory_3__io_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease (Directory_3__io_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill (Directory_3__io_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty (Directory_3__io_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state (Directory_3__io_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients (Directory_3__io_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias (Directory_3__io_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch (Directory_3__io_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc (Directory_3__io_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed (Directory_3__io_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr (Directory_3__io_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr (Directory_3__io_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag (Directory_3__io_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit (Directory_3__io_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch (Directory_3__io_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch (Directory_3__io_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param (Directory_3__io_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA (Directory_3__io_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst (Directory_3__io_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release (Directory_3__io_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill (Directory_3__io_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp (Directory_3__io_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw (Directory_3__io_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack (Directory_3__io_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp (Directory_3__io_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast (Directory_3__io_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData (Directory_3__io_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean (Directory_3__io_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid (Directory_3__io_msInfo_6_valid),
    .io_msInfo_6_bits_channel (Directory_3__io_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set (Directory_3__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_way (Directory_3__io_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag (Directory_3__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree (Directory_3__io_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask (Directory_3__io_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease (Directory_3__io_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill (Directory_3__io_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty (Directory_3__io_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state (Directory_3__io_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients (Directory_3__io_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias (Directory_3__io_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch (Directory_3__io_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc (Directory_3__io_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed (Directory_3__io_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr (Directory_3__io_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr (Directory_3__io_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag (Directory_3__io_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit (Directory_3__io_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch (Directory_3__io_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch (Directory_3__io_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param (Directory_3__io_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA (Directory_3__io_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst (Directory_3__io_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release (Directory_3__io_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill (Directory_3__io_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp (Directory_3__io_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw (Directory_3__io_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack (Directory_3__io_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp (Directory_3__io_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast (Directory_3__io_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData (Directory_3__io_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean (Directory_3__io_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid (Directory_3__io_msInfo_7_valid),
    .io_msInfo_7_bits_channel (Directory_3__io_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set (Directory_3__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_way (Directory_3__io_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag (Directory_3__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree (Directory_3__io_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask (Directory_3__io_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease (Directory_3__io_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill (Directory_3__io_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty (Directory_3__io_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state (Directory_3__io_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients (Directory_3__io_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias (Directory_3__io_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch (Directory_3__io_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc (Directory_3__io_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed (Directory_3__io_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr (Directory_3__io_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr (Directory_3__io_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag (Directory_3__io_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit (Directory_3__io_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch (Directory_3__io_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch (Directory_3__io_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param (Directory_3__io_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA (Directory_3__io_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst (Directory_3__io_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release (Directory_3__io_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill (Directory_3__io_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp (Directory_3__io_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw (Directory_3__io_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack (Directory_3__io_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp (Directory_3__io_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast (Directory_3__io_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData (Directory_3__io_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean (Directory_3__io_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid (Directory_3__io_msInfo_8_valid),
    .io_msInfo_8_bits_channel (Directory_3__io_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set (Directory_3__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_way (Directory_3__io_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag (Directory_3__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree (Directory_3__io_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask (Directory_3__io_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease (Directory_3__io_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill (Directory_3__io_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty (Directory_3__io_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state (Directory_3__io_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients (Directory_3__io_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias (Directory_3__io_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch (Directory_3__io_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc (Directory_3__io_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed (Directory_3__io_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr (Directory_3__io_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr (Directory_3__io_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag (Directory_3__io_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit (Directory_3__io_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch (Directory_3__io_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch (Directory_3__io_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param (Directory_3__io_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA (Directory_3__io_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst (Directory_3__io_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release (Directory_3__io_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill (Directory_3__io_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp (Directory_3__io_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw (Directory_3__io_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack (Directory_3__io_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp (Directory_3__io_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast (Directory_3__io_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData (Directory_3__io_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean (Directory_3__io_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid (Directory_3__io_msInfo_9_valid),
    .io_msInfo_9_bits_channel (Directory_3__io_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set (Directory_3__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_way (Directory_3__io_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag (Directory_3__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree (Directory_3__io_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask (Directory_3__io_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease (Directory_3__io_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill (Directory_3__io_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty (Directory_3__io_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state (Directory_3__io_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients (Directory_3__io_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias (Directory_3__io_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch (Directory_3__io_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc (Directory_3__io_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed (Directory_3__io_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr (Directory_3__io_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr (Directory_3__io_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag (Directory_3__io_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit (Directory_3__io_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch (Directory_3__io_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch (Directory_3__io_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param (Directory_3__io_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA (Directory_3__io_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst (Directory_3__io_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release (Directory_3__io_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill (Directory_3__io_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp (Directory_3__io_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw (Directory_3__io_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack (Directory_3__io_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp (Directory_3__io_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast (Directory_3__io_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData (Directory_3__io_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean (Directory_3__io_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid (Directory_3__io_msInfo_10_valid),
    .io_msInfo_10_bits_channel (Directory_3__io_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set (Directory_3__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_way (Directory_3__io_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag (Directory_3__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree (Directory_3__io_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask (Directory_3__io_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease (Directory_3__io_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill (Directory_3__io_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty (Directory_3__io_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state (Directory_3__io_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients (Directory_3__io_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias (Directory_3__io_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch (Directory_3__io_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc (Directory_3__io_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed (Directory_3__io_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr (Directory_3__io_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr (Directory_3__io_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag (Directory_3__io_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit (Directory_3__io_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch (Directory_3__io_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch (Directory_3__io_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param (Directory_3__io_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA (Directory_3__io_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst (Directory_3__io_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release (Directory_3__io_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill (Directory_3__io_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp (Directory_3__io_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw (Directory_3__io_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack (Directory_3__io_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp (Directory_3__io_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast (Directory_3__io_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData (Directory_3__io_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean (Directory_3__io_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid (Directory_3__io_msInfo_11_valid),
    .io_msInfo_11_bits_channel (Directory_3__io_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set (Directory_3__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_way (Directory_3__io_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag (Directory_3__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree (Directory_3__io_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask (Directory_3__io_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease (Directory_3__io_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill (Directory_3__io_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty (Directory_3__io_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state (Directory_3__io_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients (Directory_3__io_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias (Directory_3__io_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch (Directory_3__io_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc (Directory_3__io_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed (Directory_3__io_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr (Directory_3__io_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr (Directory_3__io_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag (Directory_3__io_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit (Directory_3__io_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch (Directory_3__io_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch (Directory_3__io_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param (Directory_3__io_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA (Directory_3__io_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst (Directory_3__io_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release (Directory_3__io_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill (Directory_3__io_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp (Directory_3__io_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw (Directory_3__io_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack (Directory_3__io_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp (Directory_3__io_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast (Directory_3__io_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData (Directory_3__io_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean (Directory_3__io_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid (Directory_3__io_msInfo_12_valid),
    .io_msInfo_12_bits_channel (Directory_3__io_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set (Directory_3__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_way (Directory_3__io_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag (Directory_3__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree (Directory_3__io_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask (Directory_3__io_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease (Directory_3__io_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill (Directory_3__io_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty (Directory_3__io_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state (Directory_3__io_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients (Directory_3__io_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias (Directory_3__io_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch (Directory_3__io_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc (Directory_3__io_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed (Directory_3__io_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr (Directory_3__io_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr (Directory_3__io_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag (Directory_3__io_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit (Directory_3__io_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch (Directory_3__io_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch (Directory_3__io_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param (Directory_3__io_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA (Directory_3__io_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst (Directory_3__io_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release (Directory_3__io_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill (Directory_3__io_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp (Directory_3__io_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw (Directory_3__io_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack (Directory_3__io_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp (Directory_3__io_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast (Directory_3__io_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData (Directory_3__io_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean (Directory_3__io_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid (Directory_3__io_msInfo_13_valid),
    .io_msInfo_13_bits_channel (Directory_3__io_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set (Directory_3__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_way (Directory_3__io_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag (Directory_3__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree (Directory_3__io_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask (Directory_3__io_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease (Directory_3__io_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill (Directory_3__io_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty (Directory_3__io_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state (Directory_3__io_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients (Directory_3__io_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias (Directory_3__io_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch (Directory_3__io_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc (Directory_3__io_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed (Directory_3__io_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr (Directory_3__io_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr (Directory_3__io_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag (Directory_3__io_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit (Directory_3__io_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch (Directory_3__io_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch (Directory_3__io_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param (Directory_3__io_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA (Directory_3__io_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst (Directory_3__io_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release (Directory_3__io_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill (Directory_3__io_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp (Directory_3__io_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw (Directory_3__io_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack (Directory_3__io_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp (Directory_3__io_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast (Directory_3__io_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData (Directory_3__io_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean (Directory_3__io_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid (Directory_3__io_msInfo_14_valid),
    .io_msInfo_14_bits_channel (Directory_3__io_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set (Directory_3__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_way (Directory_3__io_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag (Directory_3__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree (Directory_3__io_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask (Directory_3__io_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease (Directory_3__io_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill (Directory_3__io_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty (Directory_3__io_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state (Directory_3__io_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients (Directory_3__io_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias (Directory_3__io_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch (Directory_3__io_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc (Directory_3__io_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed (Directory_3__io_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr (Directory_3__io_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr (Directory_3__io_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag (Directory_3__io_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit (Directory_3__io_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch (Directory_3__io_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch (Directory_3__io_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param (Directory_3__io_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA (Directory_3__io_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst (Directory_3__io_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release (Directory_3__io_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill (Directory_3__io_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp (Directory_3__io_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw (Directory_3__io_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack (Directory_3__io_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp (Directory_3__io_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast (Directory_3__io_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData (Directory_3__io_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean (Directory_3__io_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid (Directory_3__io_msInfo_15_valid),
    .io_msInfo_15_bits_channel (Directory_3__io_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set (Directory_3__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_way (Directory_3__io_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag (Directory_3__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree (Directory_3__io_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask (Directory_3__io_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease (Directory_3__io_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill (Directory_3__io_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty (Directory_3__io_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state (Directory_3__io_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients (Directory_3__io_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias (Directory_3__io_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch (Directory_3__io_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc (Directory_3__io_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed (Directory_3__io_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr (Directory_3__io_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr (Directory_3__io_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag (Directory_3__io_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit (Directory_3__io_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch (Directory_3__io_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch (Directory_3__io_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param (Directory_3__io_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA (Directory_3__io_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst (Directory_3__io_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release (Directory_3__io_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill (Directory_3__io_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp (Directory_3__io_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw (Directory_3__io_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack (Directory_3__io_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp (Directory_3__io_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast (Directory_3__io_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData (Directory_3__io_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean (Directory_3__io_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array (Directory_3__boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (Directory_3__boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (Directory_3__boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_Directory_3__boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (Directory_3__boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (Directory_3__boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (Directory_3__boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (Directory_3__boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (Directory_3__boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (Directory_3__boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_Directory_3__boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold (Directory_3__sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (Directory_3__sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (Directory_3__sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (Directory_3__sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (Directory_3__sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (Directory_3__sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (Directory_3__sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (Directory_3__sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (Directory_3__sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (Directory_3__sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (Directory_3__sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (Directory_3__sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (Directory_3__sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (Directory_3__sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (Directory_3__sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (Directory_3__sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (Directory_3__sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (Directory_3__sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (Directory_3__sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (Directory_3__sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (Directory_3__sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (Directory_3__sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (Directory_3__sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (Directory_3__sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (Directory_3__sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (Directory_3__sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (Directory_3__sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (Directory_3__sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (Directory_3__sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (Directory_3__sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (Directory_3__sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (Directory_3__sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (Directory_3__sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (Directory_3__sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (Directory_3__sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (Directory_3__sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (Directory_3__sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (Directory_3__sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (Directory_3__sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (Directory_3__sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (Directory_3__sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (Directory_3__sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (Directory_3__sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (Directory_3__sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (Directory_3__sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (Directory_3__sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (Directory_3__sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (Directory_3__sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (Directory_3__sigFromSrams_bore_6_cgen)
  );
  task automatic drive_Directory_3();
    Directory_3__io_read_valid = $urandom % 2;
    Directory_3__io_read_bits_tag = 31'($urandom_range(0, 3));
    Directory_3__io_read_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_read_bits_wayMask = rnd(8);
    Directory_3__io_read_bits_replacerInfo_channel = rnd(3);
    Directory_3__io_read_bits_replacerInfo_opcode = rnd(3);
    Directory_3__io_read_bits_replacerInfo_reqSource = rnd(5);
    Directory_3__io_read_bits_replacerInfo_refill_prefetch = $urandom % 2;
    Directory_3__io_read_bits_refill = $urandom % 2;
    Directory_3__io_read_bits_mshrId = rnd(8);
    Directory_3__io_read_bits_cmoAll = $urandom % 2;
    Directory_3__io_read_bits_cmoWay = rnd(3);
    Directory_3__io_metaWReq_valid = (($urandom % 4) == 0);
    Directory_3__io_metaWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_metaWReq_bits_wayOH = rnd(8);
    Directory_3__io_metaWReq_bits_wmeta_dirty = $urandom % 2;
    Directory_3__io_metaWReq_bits_wmeta_state = rnd(2);
    Directory_3__io_metaWReq_bits_wmeta_clients = $urandom % 2;
    Directory_3__io_metaWReq_bits_wmeta_alias = rnd(2);
    Directory_3__io_metaWReq_bits_wmeta_prefetch = $urandom % 2;
    Directory_3__io_metaWReq_bits_wmeta_prefetchSrc = rnd(3);
    Directory_3__io_metaWReq_bits_wmeta_accessed = $urandom % 2;
    Directory_3__io_metaWReq_bits_wmeta_tagErr = $urandom % 2;
    Directory_3__io_metaWReq_bits_wmeta_dataErr = $urandom % 2;
    Directory_3__io_tagWReq_valid = (($urandom % 4) == 0);
    Directory_3__io_tagWReq_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_tagWReq_bits_way = rnd(3);
    Directory_3__io_tagWReq_bits_wtag = 31'($urandom_range(0, 3));
    Directory_3__io_msInfo_0_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_0_bits_channel = rnd(3);
    Directory_3__io_msInfo_0_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_0_bits_way = rnd(3);
    Directory_3__io_msInfo_0_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_0_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_0_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_0_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_0_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_0_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_0_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_0_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_0_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_0_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_0_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_0_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_0_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_0_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_0_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_0_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_0_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_0_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_0_bits_param = rnd(3);
    Directory_3__io_msInfo_0_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_0_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_0_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_0_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_0_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_0_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_0_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_0_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_0_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_0_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_0_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_1_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_1_bits_channel = rnd(3);
    Directory_3__io_msInfo_1_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_1_bits_way = rnd(3);
    Directory_3__io_msInfo_1_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_1_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_1_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_1_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_1_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_1_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_1_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_1_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_1_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_1_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_1_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_1_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_1_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_1_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_1_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_1_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_1_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_1_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_1_bits_param = rnd(3);
    Directory_3__io_msInfo_1_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_1_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_1_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_1_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_1_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_1_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_1_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_1_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_1_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_1_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_1_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_2_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_2_bits_channel = rnd(3);
    Directory_3__io_msInfo_2_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_2_bits_way = rnd(3);
    Directory_3__io_msInfo_2_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_2_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_2_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_2_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_2_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_2_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_2_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_2_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_2_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_2_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_2_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_2_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_2_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_2_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_2_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_2_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_2_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_2_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_2_bits_param = rnd(3);
    Directory_3__io_msInfo_2_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_2_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_2_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_2_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_2_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_2_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_2_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_2_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_2_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_2_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_2_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_3_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_3_bits_channel = rnd(3);
    Directory_3__io_msInfo_3_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_3_bits_way = rnd(3);
    Directory_3__io_msInfo_3_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_3_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_3_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_3_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_3_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_3_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_3_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_3_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_3_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_3_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_3_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_3_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_3_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_3_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_3_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_3_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_3_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_3_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_3_bits_param = rnd(3);
    Directory_3__io_msInfo_3_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_3_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_3_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_3_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_3_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_3_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_3_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_3_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_3_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_3_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_3_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_4_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_4_bits_channel = rnd(3);
    Directory_3__io_msInfo_4_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_4_bits_way = rnd(3);
    Directory_3__io_msInfo_4_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_4_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_4_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_4_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_4_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_4_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_4_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_4_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_4_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_4_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_4_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_4_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_4_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_4_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_4_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_4_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_4_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_4_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_4_bits_param = rnd(3);
    Directory_3__io_msInfo_4_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_4_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_4_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_4_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_4_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_4_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_4_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_4_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_4_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_4_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_4_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_5_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_5_bits_channel = rnd(3);
    Directory_3__io_msInfo_5_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_5_bits_way = rnd(3);
    Directory_3__io_msInfo_5_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_5_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_5_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_5_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_5_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_5_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_5_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_5_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_5_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_5_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_5_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_5_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_5_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_5_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_5_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_5_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_5_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_5_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_5_bits_param = rnd(3);
    Directory_3__io_msInfo_5_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_5_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_5_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_5_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_5_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_5_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_5_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_5_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_5_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_5_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_5_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_6_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_6_bits_channel = rnd(3);
    Directory_3__io_msInfo_6_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_6_bits_way = rnd(3);
    Directory_3__io_msInfo_6_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_6_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_6_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_6_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_6_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_6_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_6_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_6_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_6_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_6_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_6_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_6_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_6_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_6_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_6_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_6_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_6_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_6_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_6_bits_param = rnd(3);
    Directory_3__io_msInfo_6_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_6_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_6_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_6_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_6_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_6_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_6_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_6_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_6_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_6_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_6_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_7_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_7_bits_channel = rnd(3);
    Directory_3__io_msInfo_7_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_7_bits_way = rnd(3);
    Directory_3__io_msInfo_7_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_7_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_7_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_7_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_7_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_7_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_7_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_7_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_7_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_7_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_7_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_7_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_7_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_7_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_7_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_7_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_7_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_7_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_7_bits_param = rnd(3);
    Directory_3__io_msInfo_7_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_7_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_7_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_7_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_7_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_7_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_7_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_7_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_7_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_7_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_7_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_8_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_8_bits_channel = rnd(3);
    Directory_3__io_msInfo_8_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_8_bits_way = rnd(3);
    Directory_3__io_msInfo_8_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_8_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_8_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_8_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_8_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_8_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_8_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_8_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_8_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_8_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_8_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_8_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_8_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_8_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_8_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_8_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_8_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_8_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_8_bits_param = rnd(3);
    Directory_3__io_msInfo_8_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_8_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_8_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_8_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_8_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_8_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_8_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_8_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_8_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_8_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_8_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_9_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_9_bits_channel = rnd(3);
    Directory_3__io_msInfo_9_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_9_bits_way = rnd(3);
    Directory_3__io_msInfo_9_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_9_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_9_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_9_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_9_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_9_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_9_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_9_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_9_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_9_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_9_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_9_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_9_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_9_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_9_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_9_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_9_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_9_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_9_bits_param = rnd(3);
    Directory_3__io_msInfo_9_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_9_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_9_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_9_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_9_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_9_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_9_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_9_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_9_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_9_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_9_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_10_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_10_bits_channel = rnd(3);
    Directory_3__io_msInfo_10_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_10_bits_way = rnd(3);
    Directory_3__io_msInfo_10_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_10_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_10_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_10_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_10_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_10_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_10_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_10_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_10_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_10_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_10_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_10_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_10_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_10_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_10_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_10_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_10_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_10_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_10_bits_param = rnd(3);
    Directory_3__io_msInfo_10_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_10_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_10_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_10_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_10_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_10_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_10_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_10_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_10_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_10_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_10_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_11_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_11_bits_channel = rnd(3);
    Directory_3__io_msInfo_11_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_11_bits_way = rnd(3);
    Directory_3__io_msInfo_11_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_11_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_11_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_11_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_11_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_11_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_11_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_11_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_11_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_11_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_11_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_11_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_11_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_11_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_11_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_11_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_11_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_11_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_11_bits_param = rnd(3);
    Directory_3__io_msInfo_11_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_11_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_11_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_11_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_11_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_11_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_11_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_11_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_11_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_11_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_11_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_12_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_12_bits_channel = rnd(3);
    Directory_3__io_msInfo_12_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_12_bits_way = rnd(3);
    Directory_3__io_msInfo_12_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_12_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_12_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_12_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_12_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_12_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_12_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_12_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_12_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_12_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_12_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_12_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_12_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_12_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_12_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_12_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_12_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_12_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_12_bits_param = rnd(3);
    Directory_3__io_msInfo_12_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_12_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_12_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_12_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_12_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_12_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_12_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_12_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_12_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_12_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_12_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_13_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_13_bits_channel = rnd(3);
    Directory_3__io_msInfo_13_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_13_bits_way = rnd(3);
    Directory_3__io_msInfo_13_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_13_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_13_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_13_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_13_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_13_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_13_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_13_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_13_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_13_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_13_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_13_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_13_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_13_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_13_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_13_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_13_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_13_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_13_bits_param = rnd(3);
    Directory_3__io_msInfo_13_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_13_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_13_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_13_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_13_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_13_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_13_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_13_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_13_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_13_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_13_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_14_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_14_bits_channel = rnd(3);
    Directory_3__io_msInfo_14_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_14_bits_way = rnd(3);
    Directory_3__io_msInfo_14_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_14_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_14_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_14_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_14_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_14_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_14_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_14_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_14_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_14_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_14_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_14_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_14_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_14_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_14_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_14_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_14_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_14_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_14_bits_param = rnd(3);
    Directory_3__io_msInfo_14_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_14_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_14_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_14_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_14_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_14_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_14_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_14_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_14_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_14_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_14_bits_releaseToClean = $urandom % 2;
    Directory_3__io_msInfo_15_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 8) != 0) : (($urandom % 4) == 0);
    Directory_3__io_msInfo_15_bits_channel = rnd(3);
    Directory_3__io_msInfo_15_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2));
    Directory_3__io_msInfo_15_bits_way = rnd(3);
    Directory_3__io_msInfo_15_bits_reqTag = rnd(31);
    Directory_3__io_msInfo_15_bits_willFree = $urandom % 2;
    Directory_3__io_msInfo_15_bits_aliasTask = $urandom % 2;
    Directory_3__io_msInfo_15_bits_needRelease = $urandom % 2;
    Directory_3__io_msInfo_15_bits_blockRefill = $urandom % 2;
    Directory_3__io_msInfo_15_bits_meta_dirty = $urandom % 2;
    Directory_3__io_msInfo_15_bits_meta_state = rnd(2);
    Directory_3__io_msInfo_15_bits_meta_clients = $urandom % 2;
    Directory_3__io_msInfo_15_bits_meta_alias = rnd(2);
    Directory_3__io_msInfo_15_bits_meta_prefetch = $urandom % 2;
    Directory_3__io_msInfo_15_bits_meta_prefetchSrc = rnd(3);
    Directory_3__io_msInfo_15_bits_meta_accessed = $urandom % 2;
    Directory_3__io_msInfo_15_bits_meta_tagErr = $urandom % 2;
    Directory_3__io_msInfo_15_bits_meta_dataErr = $urandom % 2;
    Directory_3__io_msInfo_15_bits_metaTag = rnd(31);
    Directory_3__io_msInfo_15_bits_dirHit = $urandom % 2;
    Directory_3__io_msInfo_15_bits_isAcqOrPrefetch = $urandom % 2;
    Directory_3__io_msInfo_15_bits_isPrefetch = $urandom % 2;
    Directory_3__io_msInfo_15_bits_param = rnd(3);
    Directory_3__io_msInfo_15_bits_mergeA = $urandom % 2;
    Directory_3__io_msInfo_15_bits_w_grantfirst = $urandom % 2;
    Directory_3__io_msInfo_15_bits_s_release = $urandom % 2;
    Directory_3__io_msInfo_15_bits_s_refill = $urandom % 2;
    Directory_3__io_msInfo_15_bits_s_cmoresp = $urandom % 2;
    Directory_3__io_msInfo_15_bits_s_cmometaw = $urandom % 2;
    Directory_3__io_msInfo_15_bits_w_releaseack = $urandom % 2;
    Directory_3__io_msInfo_15_bits_w_replResp = $urandom % 2;
    Directory_3__io_msInfo_15_bits_w_rprobeacklast = $urandom % 2;
    Directory_3__io_msInfo_15_bits_replaceData = $urandom % 2;
    Directory_3__io_msInfo_15_bits_releaseToClean = $urandom % 2;
    Directory_3__boreChildrenBd_bore_array = rnd(6);
    Directory_3__boreChildrenBd_bore_all = $urandom % 2;
    Directory_3__boreChildrenBd_bore_req = $urandom % 2;
    Directory_3__boreChildrenBd_bore_writeen = $urandom % 2;
    Directory_3__boreChildrenBd_bore_be = rnd(8);
    Directory_3__boreChildrenBd_bore_addr = rnd(10);
    Directory_3__boreChildrenBd_bore_indata = rnd(104);
    Directory_3__boreChildrenBd_bore_readen = $urandom % 2;
    Directory_3__boreChildrenBd_bore_addr_rd = rnd(10);
    Directory_3__sigFromSrams_bore_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_cgen = $urandom % 2;
    Directory_3__sigFromSrams_bore_1_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_1_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_1_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_1_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_1_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_1_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_1_cgen = $urandom % 2;
    Directory_3__sigFromSrams_bore_2_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_2_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_2_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_2_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_2_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_2_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_2_cgen = $urandom % 2;
    Directory_3__sigFromSrams_bore_3_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_3_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_3_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_3_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_3_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_3_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_3_cgen = $urandom % 2;
    Directory_3__sigFromSrams_bore_4_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_4_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_4_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_4_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_4_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_4_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_4_cgen = $urandom % 2;
    Directory_3__sigFromSrams_bore_5_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_5_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_5_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_5_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_5_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_5_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_5_cgen = $urandom % 2;
    Directory_3__sigFromSrams_bore_6_ram_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_6_ram_bypass = $urandom % 2;
    Directory_3__sigFromSrams_bore_6_ram_bp_clken = $urandom % 2;
    Directory_3__sigFromSrams_bore_6_ram_aux_clk = 1'b0;
    Directory_3__sigFromSrams_bore_6_ram_aux_ckbp = 1'b0;
    Directory_3__sigFromSrams_bore_6_ram_mcp_hold = $urandom % 2;
    Directory_3__sigFromSrams_bore_6_cgen = $urandom % 2;
  endtask
  task automatic check_Directory_3();
    checks++;
    if (g_Directory_3__io_read_ready !== i_Directory_3__io_read_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_read_ready g=%h i=%h", cyc, g_Directory_3__io_read_ready, i_Directory_3__io_read_ready);
    end
    if (g_Directory_3__io_read_ready !== p_Directory_3__io_read_ready) t_Directory_3__io_read_ready = 1'b1;
    p_Directory_3__io_read_ready = g_Directory_3__io_read_ready;
    checks++;
    if (g_Directory_3__io_resp_valid !== i_Directory_3__io_resp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_valid g=%h i=%h", cyc, g_Directory_3__io_resp_valid, i_Directory_3__io_resp_valid);
    end
    if (g_Directory_3__io_resp_valid !== p_Directory_3__io_resp_valid) t_Directory_3__io_resp_valid = 1'b1;
    p_Directory_3__io_resp_valid = g_Directory_3__io_resp_valid;
    checks++;
    if (g_Directory_3__io_resp_bits_hit !== i_Directory_3__io_resp_bits_hit) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_hit g=%h i=%h", cyc, g_Directory_3__io_resp_bits_hit, i_Directory_3__io_resp_bits_hit);
    end
    if (g_Directory_3__io_resp_bits_hit !== p_Directory_3__io_resp_bits_hit) t_Directory_3__io_resp_bits_hit = 1'b1;
    p_Directory_3__io_resp_bits_hit = g_Directory_3__io_resp_bits_hit;
    checks++;
    if (g_Directory_3__io_resp_bits_tag !== i_Directory_3__io_resp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_tag g=%h i=%h", cyc, g_Directory_3__io_resp_bits_tag, i_Directory_3__io_resp_bits_tag);
    end
    if (g_Directory_3__io_resp_bits_tag !== p_Directory_3__io_resp_bits_tag) t_Directory_3__io_resp_bits_tag = 1'b1;
    p_Directory_3__io_resp_bits_tag = g_Directory_3__io_resp_bits_tag;
    checks++;
    if (g_Directory_3__io_resp_bits_set !== i_Directory_3__io_resp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_set g=%h i=%h", cyc, g_Directory_3__io_resp_bits_set, i_Directory_3__io_resp_bits_set);
    end
    if (g_Directory_3__io_resp_bits_set !== p_Directory_3__io_resp_bits_set) t_Directory_3__io_resp_bits_set = 1'b1;
    p_Directory_3__io_resp_bits_set = g_Directory_3__io_resp_bits_set;
    checks++;
    if (g_Directory_3__io_resp_bits_way !== i_Directory_3__io_resp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_way g=%h i=%h", cyc, g_Directory_3__io_resp_bits_way, i_Directory_3__io_resp_bits_way);
    end
    if (g_Directory_3__io_resp_bits_way !== p_Directory_3__io_resp_bits_way) t_Directory_3__io_resp_bits_way = 1'b1;
    p_Directory_3__io_resp_bits_way = g_Directory_3__io_resp_bits_way;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_dirty !== i_Directory_3__io_resp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_dirty g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_dirty, i_Directory_3__io_resp_bits_meta_dirty);
    end
    if (g_Directory_3__io_resp_bits_meta_dirty !== p_Directory_3__io_resp_bits_meta_dirty) t_Directory_3__io_resp_bits_meta_dirty = 1'b1;
    p_Directory_3__io_resp_bits_meta_dirty = g_Directory_3__io_resp_bits_meta_dirty;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_state !== i_Directory_3__io_resp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_state g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_state, i_Directory_3__io_resp_bits_meta_state);
    end
    if (g_Directory_3__io_resp_bits_meta_state !== p_Directory_3__io_resp_bits_meta_state) t_Directory_3__io_resp_bits_meta_state = 1'b1;
    p_Directory_3__io_resp_bits_meta_state = g_Directory_3__io_resp_bits_meta_state;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_clients !== i_Directory_3__io_resp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_clients g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_clients, i_Directory_3__io_resp_bits_meta_clients);
    end
    if (g_Directory_3__io_resp_bits_meta_clients !== p_Directory_3__io_resp_bits_meta_clients) t_Directory_3__io_resp_bits_meta_clients = 1'b1;
    p_Directory_3__io_resp_bits_meta_clients = g_Directory_3__io_resp_bits_meta_clients;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_alias !== i_Directory_3__io_resp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_alias g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_alias, i_Directory_3__io_resp_bits_meta_alias);
    end
    if (g_Directory_3__io_resp_bits_meta_alias !== p_Directory_3__io_resp_bits_meta_alias) t_Directory_3__io_resp_bits_meta_alias = 1'b1;
    p_Directory_3__io_resp_bits_meta_alias = g_Directory_3__io_resp_bits_meta_alias;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_prefetch !== i_Directory_3__io_resp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_prefetch, i_Directory_3__io_resp_bits_meta_prefetch);
    end
    if (g_Directory_3__io_resp_bits_meta_prefetch !== p_Directory_3__io_resp_bits_meta_prefetch) t_Directory_3__io_resp_bits_meta_prefetch = 1'b1;
    p_Directory_3__io_resp_bits_meta_prefetch = g_Directory_3__io_resp_bits_meta_prefetch;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_prefetchSrc !== i_Directory_3__io_resp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_prefetchSrc, i_Directory_3__io_resp_bits_meta_prefetchSrc);
    end
    if (g_Directory_3__io_resp_bits_meta_prefetchSrc !== p_Directory_3__io_resp_bits_meta_prefetchSrc) t_Directory_3__io_resp_bits_meta_prefetchSrc = 1'b1;
    p_Directory_3__io_resp_bits_meta_prefetchSrc = g_Directory_3__io_resp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_accessed !== i_Directory_3__io_resp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_accessed g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_accessed, i_Directory_3__io_resp_bits_meta_accessed);
    end
    if (g_Directory_3__io_resp_bits_meta_accessed !== p_Directory_3__io_resp_bits_meta_accessed) t_Directory_3__io_resp_bits_meta_accessed = 1'b1;
    p_Directory_3__io_resp_bits_meta_accessed = g_Directory_3__io_resp_bits_meta_accessed;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_tagErr !== i_Directory_3__io_resp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_tagErr, i_Directory_3__io_resp_bits_meta_tagErr);
    end
    if (g_Directory_3__io_resp_bits_meta_tagErr !== p_Directory_3__io_resp_bits_meta_tagErr) t_Directory_3__io_resp_bits_meta_tagErr = 1'b1;
    p_Directory_3__io_resp_bits_meta_tagErr = g_Directory_3__io_resp_bits_meta_tagErr;
    checks++;
    if (g_Directory_3__io_resp_bits_meta_dataErr !== i_Directory_3__io_resp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory_3__io_resp_bits_meta_dataErr, i_Directory_3__io_resp_bits_meta_dataErr);
    end
    if (g_Directory_3__io_resp_bits_meta_dataErr !== p_Directory_3__io_resp_bits_meta_dataErr) t_Directory_3__io_resp_bits_meta_dataErr = 1'b1;
    p_Directory_3__io_resp_bits_meta_dataErr = g_Directory_3__io_resp_bits_meta_dataErr;
    checks++;
    if (g_Directory_3__io_resp_bits_error !== i_Directory_3__io_resp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_error g=%h i=%h", cyc, g_Directory_3__io_resp_bits_error, i_Directory_3__io_resp_bits_error);
    end
    if (g_Directory_3__io_resp_bits_error !== p_Directory_3__io_resp_bits_error) t_Directory_3__io_resp_bits_error = 1'b1;
    p_Directory_3__io_resp_bits_error = g_Directory_3__io_resp_bits_error;
    checks++;
    if (g_Directory_3__io_resp_bits_replacerInfo_channel !== i_Directory_3__io_resp_bits_replacerInfo_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_replacerInfo_channel g=%h i=%h", cyc, g_Directory_3__io_resp_bits_replacerInfo_channel, i_Directory_3__io_resp_bits_replacerInfo_channel);
    end
    if (g_Directory_3__io_resp_bits_replacerInfo_channel !== p_Directory_3__io_resp_bits_replacerInfo_channel) t_Directory_3__io_resp_bits_replacerInfo_channel = 1'b1;
    p_Directory_3__io_resp_bits_replacerInfo_channel = g_Directory_3__io_resp_bits_replacerInfo_channel;
    checks++;
    if (g_Directory_3__io_resp_bits_replacerInfo_opcode !== i_Directory_3__io_resp_bits_replacerInfo_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_replacerInfo_opcode g=%h i=%h", cyc, g_Directory_3__io_resp_bits_replacerInfo_opcode, i_Directory_3__io_resp_bits_replacerInfo_opcode);
    end
    if (g_Directory_3__io_resp_bits_replacerInfo_opcode !== p_Directory_3__io_resp_bits_replacerInfo_opcode) t_Directory_3__io_resp_bits_replacerInfo_opcode = 1'b1;
    p_Directory_3__io_resp_bits_replacerInfo_opcode = g_Directory_3__io_resp_bits_replacerInfo_opcode;
    checks++;
    if (g_Directory_3__io_resp_bits_replacerInfo_reqSource !== i_Directory_3__io_resp_bits_replacerInfo_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_replacerInfo_reqSource g=%h i=%h", cyc, g_Directory_3__io_resp_bits_replacerInfo_reqSource, i_Directory_3__io_resp_bits_replacerInfo_reqSource);
    end
    if (g_Directory_3__io_resp_bits_replacerInfo_reqSource !== p_Directory_3__io_resp_bits_replacerInfo_reqSource) t_Directory_3__io_resp_bits_replacerInfo_reqSource = 1'b1;
    p_Directory_3__io_resp_bits_replacerInfo_reqSource = g_Directory_3__io_resp_bits_replacerInfo_reqSource;
    checks++;
    if (g_Directory_3__io_resp_bits_replacerInfo_refill_prefetch !== i_Directory_3__io_resp_bits_replacerInfo_refill_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_resp_bits_replacerInfo_refill_prefetch g=%h i=%h", cyc, g_Directory_3__io_resp_bits_replacerInfo_refill_prefetch, i_Directory_3__io_resp_bits_replacerInfo_refill_prefetch);
    end
    if (g_Directory_3__io_resp_bits_replacerInfo_refill_prefetch !== p_Directory_3__io_resp_bits_replacerInfo_refill_prefetch) t_Directory_3__io_resp_bits_replacerInfo_refill_prefetch = 1'b1;
    p_Directory_3__io_resp_bits_replacerInfo_refill_prefetch = g_Directory_3__io_resp_bits_replacerInfo_refill_prefetch;
    checks++;
    if (g_Directory_3__io_replResp_valid !== i_Directory_3__io_replResp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_valid g=%h i=%h", cyc, g_Directory_3__io_replResp_valid, i_Directory_3__io_replResp_valid);
    end
    if (g_Directory_3__io_replResp_valid !== p_Directory_3__io_replResp_valid) t_Directory_3__io_replResp_valid = 1'b1;
    p_Directory_3__io_replResp_valid = g_Directory_3__io_replResp_valid;
    checks++;
    if (g_Directory_3__io_replResp_bits_tag !== i_Directory_3__io_replResp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_tag g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_tag, i_Directory_3__io_replResp_bits_tag);
    end
    if (g_Directory_3__io_replResp_bits_tag !== p_Directory_3__io_replResp_bits_tag) t_Directory_3__io_replResp_bits_tag = 1'b1;
    p_Directory_3__io_replResp_bits_tag = g_Directory_3__io_replResp_bits_tag;
    checks++;
    if (g_Directory_3__io_replResp_bits_set !== i_Directory_3__io_replResp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_set g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_set, i_Directory_3__io_replResp_bits_set);
    end
    if (g_Directory_3__io_replResp_bits_set !== p_Directory_3__io_replResp_bits_set) t_Directory_3__io_replResp_bits_set = 1'b1;
    p_Directory_3__io_replResp_bits_set = g_Directory_3__io_replResp_bits_set;
    checks++;
    if (g_Directory_3__io_replResp_bits_way !== i_Directory_3__io_replResp_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_way g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_way, i_Directory_3__io_replResp_bits_way);
    end
    if (g_Directory_3__io_replResp_bits_way !== p_Directory_3__io_replResp_bits_way) t_Directory_3__io_replResp_bits_way = 1'b1;
    p_Directory_3__io_replResp_bits_way = g_Directory_3__io_replResp_bits_way;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_dirty !== i_Directory_3__io_replResp_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_dirty g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_dirty, i_Directory_3__io_replResp_bits_meta_dirty);
    end
    if (g_Directory_3__io_replResp_bits_meta_dirty !== p_Directory_3__io_replResp_bits_meta_dirty) t_Directory_3__io_replResp_bits_meta_dirty = 1'b1;
    p_Directory_3__io_replResp_bits_meta_dirty = g_Directory_3__io_replResp_bits_meta_dirty;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_state !== i_Directory_3__io_replResp_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_state g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_state, i_Directory_3__io_replResp_bits_meta_state);
    end
    if (g_Directory_3__io_replResp_bits_meta_state !== p_Directory_3__io_replResp_bits_meta_state) t_Directory_3__io_replResp_bits_meta_state = 1'b1;
    p_Directory_3__io_replResp_bits_meta_state = g_Directory_3__io_replResp_bits_meta_state;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_clients !== i_Directory_3__io_replResp_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_clients g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_clients, i_Directory_3__io_replResp_bits_meta_clients);
    end
    if (g_Directory_3__io_replResp_bits_meta_clients !== p_Directory_3__io_replResp_bits_meta_clients) t_Directory_3__io_replResp_bits_meta_clients = 1'b1;
    p_Directory_3__io_replResp_bits_meta_clients = g_Directory_3__io_replResp_bits_meta_clients;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_alias !== i_Directory_3__io_replResp_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_alias g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_alias, i_Directory_3__io_replResp_bits_meta_alias);
    end
    if (g_Directory_3__io_replResp_bits_meta_alias !== p_Directory_3__io_replResp_bits_meta_alias) t_Directory_3__io_replResp_bits_meta_alias = 1'b1;
    p_Directory_3__io_replResp_bits_meta_alias = g_Directory_3__io_replResp_bits_meta_alias;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_prefetch !== i_Directory_3__io_replResp_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_prefetch g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_prefetch, i_Directory_3__io_replResp_bits_meta_prefetch);
    end
    if (g_Directory_3__io_replResp_bits_meta_prefetch !== p_Directory_3__io_replResp_bits_meta_prefetch) t_Directory_3__io_replResp_bits_meta_prefetch = 1'b1;
    p_Directory_3__io_replResp_bits_meta_prefetch = g_Directory_3__io_replResp_bits_meta_prefetch;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_prefetchSrc !== i_Directory_3__io_replResp_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_prefetchSrc g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_prefetchSrc, i_Directory_3__io_replResp_bits_meta_prefetchSrc);
    end
    if (g_Directory_3__io_replResp_bits_meta_prefetchSrc !== p_Directory_3__io_replResp_bits_meta_prefetchSrc) t_Directory_3__io_replResp_bits_meta_prefetchSrc = 1'b1;
    p_Directory_3__io_replResp_bits_meta_prefetchSrc = g_Directory_3__io_replResp_bits_meta_prefetchSrc;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_accessed !== i_Directory_3__io_replResp_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_accessed g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_accessed, i_Directory_3__io_replResp_bits_meta_accessed);
    end
    if (g_Directory_3__io_replResp_bits_meta_accessed !== p_Directory_3__io_replResp_bits_meta_accessed) t_Directory_3__io_replResp_bits_meta_accessed = 1'b1;
    p_Directory_3__io_replResp_bits_meta_accessed = g_Directory_3__io_replResp_bits_meta_accessed;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_tagErr !== i_Directory_3__io_replResp_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_tagErr g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_tagErr, i_Directory_3__io_replResp_bits_meta_tagErr);
    end
    if (g_Directory_3__io_replResp_bits_meta_tagErr !== p_Directory_3__io_replResp_bits_meta_tagErr) t_Directory_3__io_replResp_bits_meta_tagErr = 1'b1;
    p_Directory_3__io_replResp_bits_meta_tagErr = g_Directory_3__io_replResp_bits_meta_tagErr;
    checks++;
    if (g_Directory_3__io_replResp_bits_meta_dataErr !== i_Directory_3__io_replResp_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_meta_dataErr g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_meta_dataErr, i_Directory_3__io_replResp_bits_meta_dataErr);
    end
    if (g_Directory_3__io_replResp_bits_meta_dataErr !== p_Directory_3__io_replResp_bits_meta_dataErr) t_Directory_3__io_replResp_bits_meta_dataErr = 1'b1;
    p_Directory_3__io_replResp_bits_meta_dataErr = g_Directory_3__io_replResp_bits_meta_dataErr;
    checks++;
    if (g_Directory_3__io_replResp_bits_mshrId !== i_Directory_3__io_replResp_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_mshrId g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_mshrId, i_Directory_3__io_replResp_bits_mshrId);
    end
    if (g_Directory_3__io_replResp_bits_mshrId !== p_Directory_3__io_replResp_bits_mshrId) t_Directory_3__io_replResp_bits_mshrId = 1'b1;
    p_Directory_3__io_replResp_bits_mshrId = g_Directory_3__io_replResp_bits_mshrId;
    checks++;
    if (g_Directory_3__io_replResp_bits_retry !== i_Directory_3__io_replResp_bits_retry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_retry g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_retry, i_Directory_3__io_replResp_bits_retry);
    end
    if (g_Directory_3__io_replResp_bits_retry !== p_Directory_3__io_replResp_bits_retry) t_Directory_3__io_replResp_bits_retry = 1'b1;
    p_Directory_3__io_replResp_bits_retry = g_Directory_3__io_replResp_bits_retry;
    checks++;
    if (g_Directory_3__io_replResp_bits_error !== i_Directory_3__io_replResp_bits_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.io_replResp_bits_error g=%h i=%h", cyc, g_Directory_3__io_replResp_bits_error, i_Directory_3__io_replResp_bits_error);
    end
    if (g_Directory_3__io_replResp_bits_error !== p_Directory_3__io_replResp_bits_error) t_Directory_3__io_replResp_bits_error = 1'b1;
    p_Directory_3__io_replResp_bits_error = g_Directory_3__io_replResp_bits_error;
    checks++;
    if (g_Directory_3__boreChildrenBd_bore_ack !== i_Directory_3__boreChildrenBd_bore_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_Directory_3__boreChildrenBd_bore_ack, i_Directory_3__boreChildrenBd_bore_ack);
    end
    if (g_Directory_3__boreChildrenBd_bore_ack !== p_Directory_3__boreChildrenBd_bore_ack) t_Directory_3__boreChildrenBd_bore_ack = 1'b1;
    p_Directory_3__boreChildrenBd_bore_ack = g_Directory_3__boreChildrenBd_bore_ack;
    checks++;
    if (g_Directory_3__boreChildrenBd_bore_outdata !== i_Directory_3__boreChildrenBd_bore_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Directory_3.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_Directory_3__boreChildrenBd_bore_outdata, i_Directory_3__boreChildrenBd_bore_outdata);
    end
    if (g_Directory_3__boreChildrenBd_bore_outdata !== p_Directory_3__boreChildrenBd_bore_outdata) t_Directory_3__boreChildrenBd_bore_outdata = 1'b1;
    p_Directory_3__boreChildrenBd_bore_outdata = g_Directory_3__boreChildrenBd_bore_outdata;
  endtask
  longint cov_Directory_3_hit = 0;
  longint cov_Directory_3_miss = 0;
  longint cov_Directory_3_repl = 0;
  longint cov_Directory_3_retry = 0;
  longint cov_Directory_3_err = 0;
  longint cov_Directory_3_pselUp = 0;
  longint cov_Directory_3_pselDn = 0;
  longint cov_Directory_3_initDone = 0;
  task automatic cover_Directory_3();
    if (u_g_Directory_3.io_resp_valid && u_g_Directory_3.io_resp_bits_hit) cov_Directory_3_hit++;
    if (u_g_Directory_3.io_resp_valid && !u_g_Directory_3.io_resp_bits_hit) cov_Directory_3_miss++;
    if (u_g_Directory_3.io_replResp_valid) cov_Directory_3_repl++;
    if (u_g_Directory_3.io_replResp_valid && u_g_Directory_3.io_replResp_bits_retry) cov_Directory_3_retry++;
    if (u_g_Directory_3.io_resp_valid && u_g_Directory_3.io_resp_bits_error) cov_Directory_3_err++;
    if (u_g_Directory_3.PSEL > 10'h200) cov_Directory_3_pselUp++;
    if (u_g_Directory_3.refillReqValid_s3 && u_g_Directory_3.match_b && !u_g_Directory_3.hit_s3) cov_Directory_3_pselDn++;
    if (u_g_Directory_3.resetFinish) cov_Directory_3_initDone++;
  endtask
  task automatic preinit_Directory_3();
    foreach (u_g_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.ram[e]) u_g_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.ram[e]) u_g_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.ram[e]) u_g_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.ram[e]) u_g_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_3.metaArray.array.array.array_15_ext.ram[e]) u_g_Directory_3.metaArray.array.array.array_15_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_3.replacer_sram_opt.array.array.array_16_ext.ram[e]) u_g_Directory_3.replacer_sram_opt.array.array.array_16_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    foreach (u_g_Directory_3.origin_bit_opt.array.array.array_17_ext.ram[e]) u_g_Directory_3.origin_bit_opt.array.array.array_17_ext.ram[e] = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
  endtask
  task automatic sync_Directory_3();
    u_i_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_3.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_3.tagArray.array_0_0_0.u_core.rdataReg = u_g_Directory_3.tagArray.array_0_0_0.rdataReg;
    #0 release u_i_Directory_3.tagArray.array_0_0_0.u_core.rdataReg;
    u_i_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_3.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_3.tagArray.array_0_0_1.u_core.rdataReg = u_g_Directory_3.tagArray.array_0_0_1.rdataReg;
    #0 release u_i_Directory_3.tagArray.array_0_0_1.u_core.rdataReg;
    u_i_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_3.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_3.tagArray.array_0_1_0.u_core.rdataReg = u_g_Directory_3.tagArray.array_0_1_0.rdataReg;
    #0 release u_i_Directory_3.tagArray.array_0_1_0.u_core.rdataReg;
    u_i_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g_Directory_3.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i_Directory_3.tagArray.array_0_1_1.u_core.rdataReg = u_g_Directory_3.tagArray.array_0_1_1.rdataReg;
    #0 release u_i_Directory_3.tagArray.array_0_1_1.u_core.rdataReg;
    u_i_Directory_3.metaArray.array.array.array_15_ext.ram = u_g_Directory_3.metaArray.array.array.array_15_ext.ram;
    u_i_Directory_3.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g_Directory_3.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i_Directory_3.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g_Directory_3.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i_Directory_3.metaArray.u_core.rdataReg = u_g_Directory_3.metaArray.rdataReg;
    #0 release u_i_Directory_3.metaArray.u_core.rdataReg;
    u_i_Directory_3.replacer_sram_opt.array.array.array_16_ext.ram = u_g_Directory_3.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i_Directory_3.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g_Directory_3.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i_Directory_3.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g_Directory_3.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i_Directory_3.replacer_sram_opt.u_core.rdataReg = u_g_Directory_3.replacer_sram_opt.rdataReg;
    #0 release u_i_Directory_3.replacer_sram_opt.u_core.rdataReg;
    u_i_Directory_3.origin_bit_opt.array.array.array_17_ext.ram = u_g_Directory_3.origin_bit_opt.array.array.array_17_ext.ram;
    u_i_Directory_3.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g_Directory_3.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i_Directory_3.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g_Directory_3.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i_Directory_3.origin_bit_opt.u_core.rdataReg = u_g_Directory_3.origin_bit_opt.rdataReg;
    #0 release u_i_Directory_3.origin_bit_opt.u_core.rdataReg;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_Directory();
    drive_Directory_1();
    drive_Directory_2();
    drive_Directory_3();
    #1;
    preinit_Directory();
    preinit_Directory_1();
    preinit_Directory_2();
    preinit_Directory_3();
    sync_Directory();
    sync_Directory_1();
    sync_Directory_2();
    sync_Directory_3();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_Directory();
      drive_Directory_1();
      drive_Directory_2();
      drive_Directory_3();
      #1;
      check_Directory();
      cover_Directory();
      check_Directory_1();
      cover_Directory_1();
      check_Directory_2();
      cover_Directory_2();
      check_Directory_3();
      cover_Directory_3();
    end
    begin int tg; tg = 0;
      if (t_Directory__io_read_ready) tg++; else $display("COV: Directory.io_read_ready never toggled");
      if (t_Directory__io_resp_valid) tg++; else $display("COV: Directory.io_resp_valid never toggled");
      if (t_Directory__io_resp_bits_hit) tg++; else $display("COV: Directory.io_resp_bits_hit never toggled");
      if (t_Directory__io_resp_bits_tag) tg++; else $display("COV: Directory.io_resp_bits_tag never toggled");
      if (t_Directory__io_resp_bits_set) tg++; else $display("COV: Directory.io_resp_bits_set never toggled");
      if (t_Directory__io_resp_bits_way) tg++; else $display("COV: Directory.io_resp_bits_way never toggled");
      if (t_Directory__io_resp_bits_meta_dirty) tg++; else $display("COV: Directory.io_resp_bits_meta_dirty never toggled");
      if (t_Directory__io_resp_bits_meta_state) tg++; else $display("COV: Directory.io_resp_bits_meta_state never toggled");
      if (t_Directory__io_resp_bits_meta_clients) tg++; else $display("COV: Directory.io_resp_bits_meta_clients never toggled");
      if (t_Directory__io_resp_bits_meta_alias) tg++; else $display("COV: Directory.io_resp_bits_meta_alias never toggled");
      if (t_Directory__io_resp_bits_meta_prefetch) tg++; else $display("COV: Directory.io_resp_bits_meta_prefetch never toggled");
      if (t_Directory__io_resp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory.io_resp_bits_meta_prefetchSrc never toggled");
      if (t_Directory__io_resp_bits_meta_accessed) tg++; else $display("COV: Directory.io_resp_bits_meta_accessed never toggled");
      if (t_Directory__io_resp_bits_meta_tagErr) tg++; else $display("COV: Directory.io_resp_bits_meta_tagErr never toggled");
      if (t_Directory__io_resp_bits_meta_dataErr) tg++; else $display("COV: Directory.io_resp_bits_meta_dataErr never toggled");
      if (t_Directory__io_resp_bits_error) tg++; else $display("COV: Directory.io_resp_bits_error never toggled");
      if (t_Directory__io_resp_bits_replacerInfo_channel) tg++; else $display("COV: Directory.io_resp_bits_replacerInfo_channel never toggled");
      if (t_Directory__io_resp_bits_replacerInfo_opcode) tg++; else $display("COV: Directory.io_resp_bits_replacerInfo_opcode never toggled");
      if (t_Directory__io_resp_bits_replacerInfo_reqSource) tg++; else $display("COV: Directory.io_resp_bits_replacerInfo_reqSource never toggled");
      if (t_Directory__io_resp_bits_replacerInfo_refill_prefetch) tg++; else $display("COV: Directory.io_resp_bits_replacerInfo_refill_prefetch never toggled");
      if (t_Directory__io_replResp_valid) tg++; else $display("COV: Directory.io_replResp_valid never toggled");
      if (t_Directory__io_replResp_bits_tag) tg++; else $display("COV: Directory.io_replResp_bits_tag never toggled");
      if (t_Directory__io_replResp_bits_set) tg++; else $display("COV: Directory.io_replResp_bits_set never toggled");
      if (t_Directory__io_replResp_bits_way) tg++; else $display("COV: Directory.io_replResp_bits_way never toggled");
      if (t_Directory__io_replResp_bits_meta_dirty) tg++; else $display("COV: Directory.io_replResp_bits_meta_dirty never toggled");
      if (t_Directory__io_replResp_bits_meta_state) tg++; else $display("COV: Directory.io_replResp_bits_meta_state never toggled");
      if (t_Directory__io_replResp_bits_meta_clients) tg++; else $display("COV: Directory.io_replResp_bits_meta_clients never toggled");
      if (t_Directory__io_replResp_bits_meta_alias) tg++; else $display("COV: Directory.io_replResp_bits_meta_alias never toggled");
      if (t_Directory__io_replResp_bits_meta_prefetch) tg++; else $display("COV: Directory.io_replResp_bits_meta_prefetch never toggled");
      if (t_Directory__io_replResp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory.io_replResp_bits_meta_prefetchSrc never toggled");
      if (t_Directory__io_replResp_bits_meta_accessed) tg++; else $display("COV: Directory.io_replResp_bits_meta_accessed never toggled");
      if (t_Directory__io_replResp_bits_meta_tagErr) tg++; else $display("COV: Directory.io_replResp_bits_meta_tagErr never toggled");
      if (t_Directory__io_replResp_bits_meta_dataErr) tg++; else $display("COV: Directory.io_replResp_bits_meta_dataErr never toggled");
      if (t_Directory__io_replResp_bits_mshrId) tg++; else $display("COV: Directory.io_replResp_bits_mshrId never toggled");
      if (t_Directory__io_replResp_bits_retry) tg++; else $display("COV: Directory.io_replResp_bits_retry never toggled");
      if (t_Directory__io_replResp_bits_error) tg++; else $display("COV: Directory.io_replResp_bits_error never toggled");
      if (t_Directory__boreChildrenBd_bore_ack) tg++; else $display("COV: Directory.boreChildrenBd_bore_ack never toggled");
      if (t_Directory__boreChildrenBd_bore_outdata) tg++; else $display("COV: Directory.boreChildrenBd_bore_outdata never toggled");
      $display("Directory: toggled=%0d/38 (need >= 38)", tg);
      if (tg < 38) covfail = 1;
      $display("Directory: cover hit = %0d", cov_Directory_hit);
      if (cov_Directory_hit == 0) covfail = 1;
      $display("Directory: cover miss = %0d", cov_Directory_miss);
      if (cov_Directory_miss == 0) covfail = 1;
      $display("Directory: cover repl = %0d", cov_Directory_repl);
      if (cov_Directory_repl == 0) covfail = 1;
      $display("Directory: cover retry = %0d", cov_Directory_retry);
      if (cov_Directory_retry == 0) covfail = 1;
      $display("Directory: cover err = %0d", cov_Directory_err);
      if (cov_Directory_err == 0) covfail = 1;
      $display("Directory: cover pselUp = %0d", cov_Directory_pselUp);
      if (cov_Directory_pselUp == 0) covfail = 1;
      $display("Directory: cover pselDn = %0d", cov_Directory_pselDn);
      if (cov_Directory_pselDn == 0) covfail = 1;
      $display("Directory: cover initDone = %0d", cov_Directory_initDone);
      if (cov_Directory_initDone == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Directory_1__io_read_ready) tg++; else $display("COV: Directory_1.io_read_ready never toggled");
      if (t_Directory_1__io_resp_valid) tg++; else $display("COV: Directory_1.io_resp_valid never toggled");
      if (t_Directory_1__io_resp_bits_hit) tg++; else $display("COV: Directory_1.io_resp_bits_hit never toggled");
      if (t_Directory_1__io_resp_bits_tag) tg++; else $display("COV: Directory_1.io_resp_bits_tag never toggled");
      if (t_Directory_1__io_resp_bits_set) tg++; else $display("COV: Directory_1.io_resp_bits_set never toggled");
      if (t_Directory_1__io_resp_bits_way) tg++; else $display("COV: Directory_1.io_resp_bits_way never toggled");
      if (t_Directory_1__io_resp_bits_meta_dirty) tg++; else $display("COV: Directory_1.io_resp_bits_meta_dirty never toggled");
      if (t_Directory_1__io_resp_bits_meta_state) tg++; else $display("COV: Directory_1.io_resp_bits_meta_state never toggled");
      if (t_Directory_1__io_resp_bits_meta_clients) tg++; else $display("COV: Directory_1.io_resp_bits_meta_clients never toggled");
      if (t_Directory_1__io_resp_bits_meta_alias) tg++; else $display("COV: Directory_1.io_resp_bits_meta_alias never toggled");
      if (t_Directory_1__io_resp_bits_meta_prefetch) tg++; else $display("COV: Directory_1.io_resp_bits_meta_prefetch never toggled");
      if (t_Directory_1__io_resp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory_1.io_resp_bits_meta_prefetchSrc never toggled");
      if (t_Directory_1__io_resp_bits_meta_accessed) tg++; else $display("COV: Directory_1.io_resp_bits_meta_accessed never toggled");
      if (t_Directory_1__io_resp_bits_meta_tagErr) tg++; else $display("COV: Directory_1.io_resp_bits_meta_tagErr never toggled");
      if (t_Directory_1__io_resp_bits_meta_dataErr) tg++; else $display("COV: Directory_1.io_resp_bits_meta_dataErr never toggled");
      if (t_Directory_1__io_resp_bits_error) tg++; else $display("COV: Directory_1.io_resp_bits_error never toggled");
      if (t_Directory_1__io_resp_bits_replacerInfo_channel) tg++; else $display("COV: Directory_1.io_resp_bits_replacerInfo_channel never toggled");
      if (t_Directory_1__io_resp_bits_replacerInfo_opcode) tg++; else $display("COV: Directory_1.io_resp_bits_replacerInfo_opcode never toggled");
      if (t_Directory_1__io_resp_bits_replacerInfo_reqSource) tg++; else $display("COV: Directory_1.io_resp_bits_replacerInfo_reqSource never toggled");
      if (t_Directory_1__io_resp_bits_replacerInfo_refill_prefetch) tg++; else $display("COV: Directory_1.io_resp_bits_replacerInfo_refill_prefetch never toggled");
      if (t_Directory_1__io_replResp_valid) tg++; else $display("COV: Directory_1.io_replResp_valid never toggled");
      if (t_Directory_1__io_replResp_bits_tag) tg++; else $display("COV: Directory_1.io_replResp_bits_tag never toggled");
      if (t_Directory_1__io_replResp_bits_set) tg++; else $display("COV: Directory_1.io_replResp_bits_set never toggled");
      if (t_Directory_1__io_replResp_bits_way) tg++; else $display("COV: Directory_1.io_replResp_bits_way never toggled");
      if (t_Directory_1__io_replResp_bits_meta_dirty) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_dirty never toggled");
      if (t_Directory_1__io_replResp_bits_meta_state) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_state never toggled");
      if (t_Directory_1__io_replResp_bits_meta_clients) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_clients never toggled");
      if (t_Directory_1__io_replResp_bits_meta_alias) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_alias never toggled");
      if (t_Directory_1__io_replResp_bits_meta_prefetch) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_prefetch never toggled");
      if (t_Directory_1__io_replResp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_prefetchSrc never toggled");
      if (t_Directory_1__io_replResp_bits_meta_accessed) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_accessed never toggled");
      if (t_Directory_1__io_replResp_bits_meta_tagErr) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_tagErr never toggled");
      if (t_Directory_1__io_replResp_bits_meta_dataErr) tg++; else $display("COV: Directory_1.io_replResp_bits_meta_dataErr never toggled");
      if (t_Directory_1__io_replResp_bits_mshrId) tg++; else $display("COV: Directory_1.io_replResp_bits_mshrId never toggled");
      if (t_Directory_1__io_replResp_bits_retry) tg++; else $display("COV: Directory_1.io_replResp_bits_retry never toggled");
      if (t_Directory_1__io_replResp_bits_error) tg++; else $display("COV: Directory_1.io_replResp_bits_error never toggled");
      if (t_Directory_1__boreChildrenBd_bore_ack) tg++; else $display("COV: Directory_1.boreChildrenBd_bore_ack never toggled");
      if (t_Directory_1__boreChildrenBd_bore_outdata) tg++; else $display("COV: Directory_1.boreChildrenBd_bore_outdata never toggled");
      $display("Directory_1: toggled=%0d/38 (need >= 38)", tg);
      if (tg < 38) covfail = 1;
      $display("Directory_1: cover hit = %0d", cov_Directory_1_hit);
      if (cov_Directory_1_hit == 0) covfail = 1;
      $display("Directory_1: cover miss = %0d", cov_Directory_1_miss);
      if (cov_Directory_1_miss == 0) covfail = 1;
      $display("Directory_1: cover repl = %0d", cov_Directory_1_repl);
      if (cov_Directory_1_repl == 0) covfail = 1;
      $display("Directory_1: cover retry = %0d", cov_Directory_1_retry);
      if (cov_Directory_1_retry == 0) covfail = 1;
      $display("Directory_1: cover err = %0d", cov_Directory_1_err);
      if (cov_Directory_1_err == 0) covfail = 1;
      $display("Directory_1: cover pselUp = %0d", cov_Directory_1_pselUp);
      if (cov_Directory_1_pselUp == 0) covfail = 1;
      $display("Directory_1: cover pselDn = %0d", cov_Directory_1_pselDn);
      if (cov_Directory_1_pselDn == 0) covfail = 1;
      $display("Directory_1: cover initDone = %0d", cov_Directory_1_initDone);
      if (cov_Directory_1_initDone == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Directory_2__io_read_ready) tg++; else $display("COV: Directory_2.io_read_ready never toggled");
      if (t_Directory_2__io_resp_valid) tg++; else $display("COV: Directory_2.io_resp_valid never toggled");
      if (t_Directory_2__io_resp_bits_hit) tg++; else $display("COV: Directory_2.io_resp_bits_hit never toggled");
      if (t_Directory_2__io_resp_bits_tag) tg++; else $display("COV: Directory_2.io_resp_bits_tag never toggled");
      if (t_Directory_2__io_resp_bits_set) tg++; else $display("COV: Directory_2.io_resp_bits_set never toggled");
      if (t_Directory_2__io_resp_bits_way) tg++; else $display("COV: Directory_2.io_resp_bits_way never toggled");
      if (t_Directory_2__io_resp_bits_meta_dirty) tg++; else $display("COV: Directory_2.io_resp_bits_meta_dirty never toggled");
      if (t_Directory_2__io_resp_bits_meta_state) tg++; else $display("COV: Directory_2.io_resp_bits_meta_state never toggled");
      if (t_Directory_2__io_resp_bits_meta_clients) tg++; else $display("COV: Directory_2.io_resp_bits_meta_clients never toggled");
      if (t_Directory_2__io_resp_bits_meta_alias) tg++; else $display("COV: Directory_2.io_resp_bits_meta_alias never toggled");
      if (t_Directory_2__io_resp_bits_meta_prefetch) tg++; else $display("COV: Directory_2.io_resp_bits_meta_prefetch never toggled");
      if (t_Directory_2__io_resp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory_2.io_resp_bits_meta_prefetchSrc never toggled");
      if (t_Directory_2__io_resp_bits_meta_accessed) tg++; else $display("COV: Directory_2.io_resp_bits_meta_accessed never toggled");
      if (t_Directory_2__io_resp_bits_meta_tagErr) tg++; else $display("COV: Directory_2.io_resp_bits_meta_tagErr never toggled");
      if (t_Directory_2__io_resp_bits_meta_dataErr) tg++; else $display("COV: Directory_2.io_resp_bits_meta_dataErr never toggled");
      if (t_Directory_2__io_resp_bits_error) tg++; else $display("COV: Directory_2.io_resp_bits_error never toggled");
      if (t_Directory_2__io_resp_bits_replacerInfo_channel) tg++; else $display("COV: Directory_2.io_resp_bits_replacerInfo_channel never toggled");
      if (t_Directory_2__io_resp_bits_replacerInfo_opcode) tg++; else $display("COV: Directory_2.io_resp_bits_replacerInfo_opcode never toggled");
      if (t_Directory_2__io_resp_bits_replacerInfo_reqSource) tg++; else $display("COV: Directory_2.io_resp_bits_replacerInfo_reqSource never toggled");
      if (t_Directory_2__io_resp_bits_replacerInfo_refill_prefetch) tg++; else $display("COV: Directory_2.io_resp_bits_replacerInfo_refill_prefetch never toggled");
      if (t_Directory_2__io_replResp_valid) tg++; else $display("COV: Directory_2.io_replResp_valid never toggled");
      if (t_Directory_2__io_replResp_bits_tag) tg++; else $display("COV: Directory_2.io_replResp_bits_tag never toggled");
      if (t_Directory_2__io_replResp_bits_set) tg++; else $display("COV: Directory_2.io_replResp_bits_set never toggled");
      if (t_Directory_2__io_replResp_bits_way) tg++; else $display("COV: Directory_2.io_replResp_bits_way never toggled");
      if (t_Directory_2__io_replResp_bits_meta_dirty) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_dirty never toggled");
      if (t_Directory_2__io_replResp_bits_meta_state) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_state never toggled");
      if (t_Directory_2__io_replResp_bits_meta_clients) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_clients never toggled");
      if (t_Directory_2__io_replResp_bits_meta_alias) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_alias never toggled");
      if (t_Directory_2__io_replResp_bits_meta_prefetch) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_prefetch never toggled");
      if (t_Directory_2__io_replResp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_prefetchSrc never toggled");
      if (t_Directory_2__io_replResp_bits_meta_accessed) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_accessed never toggled");
      if (t_Directory_2__io_replResp_bits_meta_tagErr) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_tagErr never toggled");
      if (t_Directory_2__io_replResp_bits_meta_dataErr) tg++; else $display("COV: Directory_2.io_replResp_bits_meta_dataErr never toggled");
      if (t_Directory_2__io_replResp_bits_mshrId) tg++; else $display("COV: Directory_2.io_replResp_bits_mshrId never toggled");
      if (t_Directory_2__io_replResp_bits_retry) tg++; else $display("COV: Directory_2.io_replResp_bits_retry never toggled");
      if (t_Directory_2__io_replResp_bits_error) tg++; else $display("COV: Directory_2.io_replResp_bits_error never toggled");
      if (t_Directory_2__boreChildrenBd_bore_ack) tg++; else $display("COV: Directory_2.boreChildrenBd_bore_ack never toggled");
      if (t_Directory_2__boreChildrenBd_bore_outdata) tg++; else $display("COV: Directory_2.boreChildrenBd_bore_outdata never toggled");
      $display("Directory_2: toggled=%0d/38 (need >= 38)", tg);
      if (tg < 38) covfail = 1;
      $display("Directory_2: cover hit = %0d", cov_Directory_2_hit);
      if (cov_Directory_2_hit == 0) covfail = 1;
      $display("Directory_2: cover miss = %0d", cov_Directory_2_miss);
      if (cov_Directory_2_miss == 0) covfail = 1;
      $display("Directory_2: cover repl = %0d", cov_Directory_2_repl);
      if (cov_Directory_2_repl == 0) covfail = 1;
      $display("Directory_2: cover retry = %0d", cov_Directory_2_retry);
      if (cov_Directory_2_retry == 0) covfail = 1;
      $display("Directory_2: cover err = %0d", cov_Directory_2_err);
      if (cov_Directory_2_err == 0) covfail = 1;
      $display("Directory_2: cover pselUp = %0d", cov_Directory_2_pselUp);
      if (cov_Directory_2_pselUp == 0) covfail = 1;
      $display("Directory_2: cover pselDn = %0d", cov_Directory_2_pselDn);
      if (cov_Directory_2_pselDn == 0) covfail = 1;
      $display("Directory_2: cover initDone = %0d", cov_Directory_2_initDone);
      if (cov_Directory_2_initDone == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Directory_3__io_read_ready) tg++; else $display("COV: Directory_3.io_read_ready never toggled");
      if (t_Directory_3__io_resp_valid) tg++; else $display("COV: Directory_3.io_resp_valid never toggled");
      if (t_Directory_3__io_resp_bits_hit) tg++; else $display("COV: Directory_3.io_resp_bits_hit never toggled");
      if (t_Directory_3__io_resp_bits_tag) tg++; else $display("COV: Directory_3.io_resp_bits_tag never toggled");
      if (t_Directory_3__io_resp_bits_set) tg++; else $display("COV: Directory_3.io_resp_bits_set never toggled");
      if (t_Directory_3__io_resp_bits_way) tg++; else $display("COV: Directory_3.io_resp_bits_way never toggled");
      if (t_Directory_3__io_resp_bits_meta_dirty) tg++; else $display("COV: Directory_3.io_resp_bits_meta_dirty never toggled");
      if (t_Directory_3__io_resp_bits_meta_state) tg++; else $display("COV: Directory_3.io_resp_bits_meta_state never toggled");
      if (t_Directory_3__io_resp_bits_meta_clients) tg++; else $display("COV: Directory_3.io_resp_bits_meta_clients never toggled");
      if (t_Directory_3__io_resp_bits_meta_alias) tg++; else $display("COV: Directory_3.io_resp_bits_meta_alias never toggled");
      if (t_Directory_3__io_resp_bits_meta_prefetch) tg++; else $display("COV: Directory_3.io_resp_bits_meta_prefetch never toggled");
      if (t_Directory_3__io_resp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory_3.io_resp_bits_meta_prefetchSrc never toggled");
      if (t_Directory_3__io_resp_bits_meta_accessed) tg++; else $display("COV: Directory_3.io_resp_bits_meta_accessed never toggled");
      if (t_Directory_3__io_resp_bits_meta_tagErr) tg++; else $display("COV: Directory_3.io_resp_bits_meta_tagErr never toggled");
      if (t_Directory_3__io_resp_bits_meta_dataErr) tg++; else $display("COV: Directory_3.io_resp_bits_meta_dataErr never toggled");
      if (t_Directory_3__io_resp_bits_error) tg++; else $display("COV: Directory_3.io_resp_bits_error never toggled");
      if (t_Directory_3__io_resp_bits_replacerInfo_channel) tg++; else $display("COV: Directory_3.io_resp_bits_replacerInfo_channel never toggled");
      if (t_Directory_3__io_resp_bits_replacerInfo_opcode) tg++; else $display("COV: Directory_3.io_resp_bits_replacerInfo_opcode never toggled");
      if (t_Directory_3__io_resp_bits_replacerInfo_reqSource) tg++; else $display("COV: Directory_3.io_resp_bits_replacerInfo_reqSource never toggled");
      if (t_Directory_3__io_resp_bits_replacerInfo_refill_prefetch) tg++; else $display("COV: Directory_3.io_resp_bits_replacerInfo_refill_prefetch never toggled");
      if (t_Directory_3__io_replResp_valid) tg++; else $display("COV: Directory_3.io_replResp_valid never toggled");
      if (t_Directory_3__io_replResp_bits_tag) tg++; else $display("COV: Directory_3.io_replResp_bits_tag never toggled");
      if (t_Directory_3__io_replResp_bits_set) tg++; else $display("COV: Directory_3.io_replResp_bits_set never toggled");
      if (t_Directory_3__io_replResp_bits_way) tg++; else $display("COV: Directory_3.io_replResp_bits_way never toggled");
      if (t_Directory_3__io_replResp_bits_meta_dirty) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_dirty never toggled");
      if (t_Directory_3__io_replResp_bits_meta_state) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_state never toggled");
      if (t_Directory_3__io_replResp_bits_meta_clients) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_clients never toggled");
      if (t_Directory_3__io_replResp_bits_meta_alias) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_alias never toggled");
      if (t_Directory_3__io_replResp_bits_meta_prefetch) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_prefetch never toggled");
      if (t_Directory_3__io_replResp_bits_meta_prefetchSrc) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_prefetchSrc never toggled");
      if (t_Directory_3__io_replResp_bits_meta_accessed) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_accessed never toggled");
      if (t_Directory_3__io_replResp_bits_meta_tagErr) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_tagErr never toggled");
      if (t_Directory_3__io_replResp_bits_meta_dataErr) tg++; else $display("COV: Directory_3.io_replResp_bits_meta_dataErr never toggled");
      if (t_Directory_3__io_replResp_bits_mshrId) tg++; else $display("COV: Directory_3.io_replResp_bits_mshrId never toggled");
      if (t_Directory_3__io_replResp_bits_retry) tg++; else $display("COV: Directory_3.io_replResp_bits_retry never toggled");
      if (t_Directory_3__io_replResp_bits_error) tg++; else $display("COV: Directory_3.io_replResp_bits_error never toggled");
      if (t_Directory_3__boreChildrenBd_bore_ack) tg++; else $display("COV: Directory_3.boreChildrenBd_bore_ack never toggled");
      if (t_Directory_3__boreChildrenBd_bore_outdata) tg++; else $display("COV: Directory_3.boreChildrenBd_bore_outdata never toggled");
      $display("Directory_3: toggled=%0d/38 (need >= 38)", tg);
      if (tg < 38) covfail = 1;
      $display("Directory_3: cover hit = %0d", cov_Directory_3_hit);
      if (cov_Directory_3_hit == 0) covfail = 1;
      $display("Directory_3: cover miss = %0d", cov_Directory_3_miss);
      if (cov_Directory_3_miss == 0) covfail = 1;
      $display("Directory_3: cover repl = %0d", cov_Directory_3_repl);
      if (cov_Directory_3_repl == 0) covfail = 1;
      $display("Directory_3: cover retry = %0d", cov_Directory_3_retry);
      if (cov_Directory_3_retry == 0) covfail = 1;
      $display("Directory_3: cover err = %0d", cov_Directory_3_err);
      if (cov_Directory_3_err == 0) covfail = 1;
      $display("Directory_3: cover pselUp = %0d", cov_Directory_3_pselUp);
      if (cov_Directory_3_pselUp == 0) covfail = 1;
      $display("Directory_3: cover pselDn = %0d", cov_Directory_3_pselDn);
      if (cov_Directory_3_pselDn == 0) covfail = 1;
      $display("Directory_3: cover initDone = %0d", cov_Directory_3_initDone);
      if (cov_Directory_3_initDone == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
