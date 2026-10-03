// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：RequestBuffer
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

  // ======================= RequestBuffer =======================
  logic RequestBuffer__io_in_valid;
  logic [8:0] RequestBuffer__io_in_bits_set;
  logic [30:0] RequestBuffer__io_in_bits_tag;
  logic [5:0] RequestBuffer__io_in_bits_off;
  logic [1:0] RequestBuffer__io_in_bits_alias;
  logic [43:0] RequestBuffer__io_in_bits_vaddr;
  logic RequestBuffer__io_in_bits_isKeyword;
  logic [3:0] RequestBuffer__io_in_bits_opcode;
  logic [2:0] RequestBuffer__io_in_bits_param;
  logic [2:0] RequestBuffer__io_in_bits_size;
  logic [6:0] RequestBuffer__io_in_bits_sourceId;
  logic RequestBuffer__io_in_bits_corrupt;
  logic RequestBuffer__io_in_bits_fromL2pft;
  logic RequestBuffer__io_in_bits_needHint;
  logic [4:0] RequestBuffer__io_in_bits_reqSource;
  logic RequestBuffer__io_out_ready;
  logic RequestBuffer__io_mshrInfo_0_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_0_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_0_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_0_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_0_bits_willFree;
  logic RequestBuffer__io_mshrInfo_0_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_0_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_0_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_0_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_0_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_0_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_0_bits_param;
  logic RequestBuffer__io_mshrInfo_0_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_0_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_1_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_1_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_1_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_1_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_1_bits_willFree;
  logic RequestBuffer__io_mshrInfo_1_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_1_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_1_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_1_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_1_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_1_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_1_bits_param;
  logic RequestBuffer__io_mshrInfo_1_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_1_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_2_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_2_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_2_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_2_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_2_bits_willFree;
  logic RequestBuffer__io_mshrInfo_2_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_2_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_2_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_2_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_2_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_2_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_2_bits_param;
  logic RequestBuffer__io_mshrInfo_2_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_2_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_3_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_3_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_3_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_3_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_3_bits_willFree;
  logic RequestBuffer__io_mshrInfo_3_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_3_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_3_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_3_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_3_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_3_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_3_bits_param;
  logic RequestBuffer__io_mshrInfo_3_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_3_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_4_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_4_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_4_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_4_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_4_bits_willFree;
  logic RequestBuffer__io_mshrInfo_4_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_4_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_4_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_4_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_4_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_4_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_4_bits_param;
  logic RequestBuffer__io_mshrInfo_4_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_4_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_5_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_5_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_5_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_5_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_5_bits_willFree;
  logic RequestBuffer__io_mshrInfo_5_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_5_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_5_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_5_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_5_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_5_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_5_bits_param;
  logic RequestBuffer__io_mshrInfo_5_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_5_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_6_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_6_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_6_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_6_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_6_bits_willFree;
  logic RequestBuffer__io_mshrInfo_6_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_6_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_6_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_6_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_6_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_6_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_6_bits_param;
  logic RequestBuffer__io_mshrInfo_6_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_6_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_7_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_7_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_7_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_7_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_7_bits_willFree;
  logic RequestBuffer__io_mshrInfo_7_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_7_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_7_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_7_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_7_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_7_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_7_bits_param;
  logic RequestBuffer__io_mshrInfo_7_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_7_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_8_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_8_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_8_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_8_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_8_bits_willFree;
  logic RequestBuffer__io_mshrInfo_8_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_8_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_8_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_8_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_8_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_8_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_8_bits_param;
  logic RequestBuffer__io_mshrInfo_8_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_8_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_9_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_9_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_9_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_9_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_9_bits_willFree;
  logic RequestBuffer__io_mshrInfo_9_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_9_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_9_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_9_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_9_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_9_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_9_bits_param;
  logic RequestBuffer__io_mshrInfo_9_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_9_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_10_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_10_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_10_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_10_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_10_bits_willFree;
  logic RequestBuffer__io_mshrInfo_10_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_10_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_10_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_10_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_10_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_10_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_10_bits_param;
  logic RequestBuffer__io_mshrInfo_10_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_10_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_11_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_11_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_11_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_11_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_11_bits_willFree;
  logic RequestBuffer__io_mshrInfo_11_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_11_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_11_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_11_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_11_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_11_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_11_bits_param;
  logic RequestBuffer__io_mshrInfo_11_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_11_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_12_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_12_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_12_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_12_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_12_bits_willFree;
  logic RequestBuffer__io_mshrInfo_12_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_12_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_12_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_12_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_12_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_12_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_12_bits_param;
  logic RequestBuffer__io_mshrInfo_12_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_12_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_13_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_13_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_13_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_13_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_13_bits_willFree;
  logic RequestBuffer__io_mshrInfo_13_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_13_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_13_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_13_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_13_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_13_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_13_bits_param;
  logic RequestBuffer__io_mshrInfo_13_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_13_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_14_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_14_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_14_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_14_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_14_bits_willFree;
  logic RequestBuffer__io_mshrInfo_14_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_14_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_14_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_14_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_14_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_14_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_14_bits_param;
  logic RequestBuffer__io_mshrInfo_14_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_14_bits_s_refill;
  logic RequestBuffer__io_mshrInfo_15_valid;
  logic [2:0] RequestBuffer__io_mshrInfo_15_bits_channel;
  logic [8:0] RequestBuffer__io_mshrInfo_15_bits_set;
  logic [30:0] RequestBuffer__io_mshrInfo_15_bits_reqTag;
  logic RequestBuffer__io_mshrInfo_15_bits_willFree;
  logic RequestBuffer__io_mshrInfo_15_bits_needRelease;
  logic [2:0] RequestBuffer__io_mshrInfo_15_bits_meta_prefetchSrc;
  logic [30:0] RequestBuffer__io_mshrInfo_15_bits_metaTag;
  logic RequestBuffer__io_mshrInfo_15_bits_dirHit;
  logic RequestBuffer__io_mshrInfo_15_bits_isAcqOrPrefetch;
  logic RequestBuffer__io_mshrInfo_15_bits_isPrefetch;
  logic [2:0] RequestBuffer__io_mshrInfo_15_bits_param;
  logic RequestBuffer__io_mshrInfo_15_bits_mergeA;
  logic RequestBuffer__io_mshrInfo_15_bits_s_refill;
  logic RequestBuffer__io_mainPipeBlock_0;
  logic RequestBuffer__io_mainPipeBlock_1;
  logic RequestBuffer__io_taskFromArb_s2_valid;
  logic [2:0] RequestBuffer__io_taskFromArb_s2_bits_channel;
  logic [8:0] RequestBuffer__io_taskFromArb_s2_bits_set;
  logic RequestBuffer__io_taskFromArb_s2_bits_mshrTask;
  logic RequestBuffer__io_s1Entrance_valid;
  logic [8:0] RequestBuffer__io_s1Entrance_bits_set;
  wire  g_RequestBuffer__io_in_ready;
  wire  i_RequestBuffer__io_in_ready;
  logic p_RequestBuffer__io_in_ready;
  bit   t_RequestBuffer__io_in_ready;
  wire  g_RequestBuffer__io_out_valid;
  wire  i_RequestBuffer__io_out_valid;
  logic p_RequestBuffer__io_out_valid;
  bit   t_RequestBuffer__io_out_valid;
  wire  [2:0] g_RequestBuffer__io_out_bits_channel;
  wire  [2:0] i_RequestBuffer__io_out_bits_channel;
  logic [2:0] p_RequestBuffer__io_out_bits_channel;
  bit   t_RequestBuffer__io_out_bits_channel;
  wire  [2:0] g_RequestBuffer__io_out_bits_txChannel;
  wire  [2:0] i_RequestBuffer__io_out_bits_txChannel;
  logic [2:0] p_RequestBuffer__io_out_bits_txChannel;
  bit   t_RequestBuffer__io_out_bits_txChannel;
  wire  [8:0] g_RequestBuffer__io_out_bits_set;
  wire  [8:0] i_RequestBuffer__io_out_bits_set;
  logic [8:0] p_RequestBuffer__io_out_bits_set;
  bit   t_RequestBuffer__io_out_bits_set;
  wire  [30:0] g_RequestBuffer__io_out_bits_tag;
  wire  [30:0] i_RequestBuffer__io_out_bits_tag;
  logic [30:0] p_RequestBuffer__io_out_bits_tag;
  bit   t_RequestBuffer__io_out_bits_tag;
  wire  [5:0] g_RequestBuffer__io_out_bits_off;
  wire  [5:0] i_RequestBuffer__io_out_bits_off;
  logic [5:0] p_RequestBuffer__io_out_bits_off;
  bit   t_RequestBuffer__io_out_bits_off;
  wire  [1:0] g_RequestBuffer__io_out_bits_alias;
  wire  [1:0] i_RequestBuffer__io_out_bits_alias;
  logic [1:0] p_RequestBuffer__io_out_bits_alias;
  bit   t_RequestBuffer__io_out_bits_alias;
  wire  [43:0] g_RequestBuffer__io_out_bits_vaddr;
  wire  [43:0] i_RequestBuffer__io_out_bits_vaddr;
  logic [43:0] p_RequestBuffer__io_out_bits_vaddr;
  bit   t_RequestBuffer__io_out_bits_vaddr;
  wire  g_RequestBuffer__io_out_bits_isKeyword;
  wire  i_RequestBuffer__io_out_bits_isKeyword;
  logic p_RequestBuffer__io_out_bits_isKeyword;
  bit   t_RequestBuffer__io_out_bits_isKeyword;
  wire  [3:0] g_RequestBuffer__io_out_bits_opcode;
  wire  [3:0] i_RequestBuffer__io_out_bits_opcode;
  logic [3:0] p_RequestBuffer__io_out_bits_opcode;
  bit   t_RequestBuffer__io_out_bits_opcode;
  wire  [2:0] g_RequestBuffer__io_out_bits_param;
  wire  [2:0] i_RequestBuffer__io_out_bits_param;
  logic [2:0] p_RequestBuffer__io_out_bits_param;
  bit   t_RequestBuffer__io_out_bits_param;
  wire  [2:0] g_RequestBuffer__io_out_bits_size;
  wire  [2:0] i_RequestBuffer__io_out_bits_size;
  logic [2:0] p_RequestBuffer__io_out_bits_size;
  bit   t_RequestBuffer__io_out_bits_size;
  wire  [6:0] g_RequestBuffer__io_out_bits_sourceId;
  wire  [6:0] i_RequestBuffer__io_out_bits_sourceId;
  logic [6:0] p_RequestBuffer__io_out_bits_sourceId;
  bit   t_RequestBuffer__io_out_bits_sourceId;
  wire  [1:0] g_RequestBuffer__io_out_bits_bufIdx;
  wire  [1:0] i_RequestBuffer__io_out_bits_bufIdx;
  logic [1:0] p_RequestBuffer__io_out_bits_bufIdx;
  bit   t_RequestBuffer__io_out_bits_bufIdx;
  wire  g_RequestBuffer__io_out_bits_needProbeAckData;
  wire  i_RequestBuffer__io_out_bits_needProbeAckData;
  logic p_RequestBuffer__io_out_bits_needProbeAckData;
  bit   t_RequestBuffer__io_out_bits_needProbeAckData;
  wire  g_RequestBuffer__io_out_bits_denied;
  wire  i_RequestBuffer__io_out_bits_denied;
  logic p_RequestBuffer__io_out_bits_denied;
  bit   t_RequestBuffer__io_out_bits_denied;
  wire  g_RequestBuffer__io_out_bits_corrupt;
  wire  i_RequestBuffer__io_out_bits_corrupt;
  logic p_RequestBuffer__io_out_bits_corrupt;
  bit   t_RequestBuffer__io_out_bits_corrupt;
  wire  g_RequestBuffer__io_out_bits_mshrTask;
  wire  i_RequestBuffer__io_out_bits_mshrTask;
  logic p_RequestBuffer__io_out_bits_mshrTask;
  bit   t_RequestBuffer__io_out_bits_mshrTask;
  wire  [7:0] g_RequestBuffer__io_out_bits_mshrId;
  wire  [7:0] i_RequestBuffer__io_out_bits_mshrId;
  logic [7:0] p_RequestBuffer__io_out_bits_mshrId;
  bit   t_RequestBuffer__io_out_bits_mshrId;
  wire  g_RequestBuffer__io_out_bits_aliasTask;
  wire  i_RequestBuffer__io_out_bits_aliasTask;
  logic p_RequestBuffer__io_out_bits_aliasTask;
  bit   t_RequestBuffer__io_out_bits_aliasTask;
  wire  g_RequestBuffer__io_out_bits_useProbeData;
  wire  i_RequestBuffer__io_out_bits_useProbeData;
  logic p_RequestBuffer__io_out_bits_useProbeData;
  bit   t_RequestBuffer__io_out_bits_useProbeData;
  wire  g_RequestBuffer__io_out_bits_mshrRetry;
  wire  i_RequestBuffer__io_out_bits_mshrRetry;
  logic p_RequestBuffer__io_out_bits_mshrRetry;
  bit   t_RequestBuffer__io_out_bits_mshrRetry;
  wire  g_RequestBuffer__io_out_bits_readProbeDataDown;
  wire  i_RequestBuffer__io_out_bits_readProbeDataDown;
  logic p_RequestBuffer__io_out_bits_readProbeDataDown;
  bit   t_RequestBuffer__io_out_bits_readProbeDataDown;
  wire  g_RequestBuffer__io_out_bits_fromL2pft;
  wire  i_RequestBuffer__io_out_bits_fromL2pft;
  logic p_RequestBuffer__io_out_bits_fromL2pft;
  bit   t_RequestBuffer__io_out_bits_fromL2pft;
  wire  g_RequestBuffer__io_out_bits_needHint;
  wire  i_RequestBuffer__io_out_bits_needHint;
  logic p_RequestBuffer__io_out_bits_needHint;
  bit   t_RequestBuffer__io_out_bits_needHint;
  wire  g_RequestBuffer__io_out_bits_dirty;
  wire  i_RequestBuffer__io_out_bits_dirty;
  logic p_RequestBuffer__io_out_bits_dirty;
  bit   t_RequestBuffer__io_out_bits_dirty;
  wire  [2:0] g_RequestBuffer__io_out_bits_way;
  wire  [2:0] i_RequestBuffer__io_out_bits_way;
  logic [2:0] p_RequestBuffer__io_out_bits_way;
  bit   t_RequestBuffer__io_out_bits_way;
  wire  g_RequestBuffer__io_out_bits_meta_dirty;
  wire  i_RequestBuffer__io_out_bits_meta_dirty;
  logic p_RequestBuffer__io_out_bits_meta_dirty;
  bit   t_RequestBuffer__io_out_bits_meta_dirty;
  wire  [1:0] g_RequestBuffer__io_out_bits_meta_state;
  wire  [1:0] i_RequestBuffer__io_out_bits_meta_state;
  logic [1:0] p_RequestBuffer__io_out_bits_meta_state;
  bit   t_RequestBuffer__io_out_bits_meta_state;
  wire  g_RequestBuffer__io_out_bits_meta_clients;
  wire  i_RequestBuffer__io_out_bits_meta_clients;
  logic p_RequestBuffer__io_out_bits_meta_clients;
  bit   t_RequestBuffer__io_out_bits_meta_clients;
  wire  [1:0] g_RequestBuffer__io_out_bits_meta_alias;
  wire  [1:0] i_RequestBuffer__io_out_bits_meta_alias;
  logic [1:0] p_RequestBuffer__io_out_bits_meta_alias;
  bit   t_RequestBuffer__io_out_bits_meta_alias;
  wire  g_RequestBuffer__io_out_bits_meta_prefetch;
  wire  i_RequestBuffer__io_out_bits_meta_prefetch;
  logic p_RequestBuffer__io_out_bits_meta_prefetch;
  bit   t_RequestBuffer__io_out_bits_meta_prefetch;
  wire  [2:0] g_RequestBuffer__io_out_bits_meta_prefetchSrc;
  wire  [2:0] i_RequestBuffer__io_out_bits_meta_prefetchSrc;
  logic [2:0] p_RequestBuffer__io_out_bits_meta_prefetchSrc;
  bit   t_RequestBuffer__io_out_bits_meta_prefetchSrc;
  wire  g_RequestBuffer__io_out_bits_meta_accessed;
  wire  i_RequestBuffer__io_out_bits_meta_accessed;
  logic p_RequestBuffer__io_out_bits_meta_accessed;
  bit   t_RequestBuffer__io_out_bits_meta_accessed;
  wire  g_RequestBuffer__io_out_bits_meta_tagErr;
  wire  i_RequestBuffer__io_out_bits_meta_tagErr;
  logic p_RequestBuffer__io_out_bits_meta_tagErr;
  bit   t_RequestBuffer__io_out_bits_meta_tagErr;
  wire  g_RequestBuffer__io_out_bits_meta_dataErr;
  wire  i_RequestBuffer__io_out_bits_meta_dataErr;
  logic p_RequestBuffer__io_out_bits_meta_dataErr;
  bit   t_RequestBuffer__io_out_bits_meta_dataErr;
  wire  g_RequestBuffer__io_out_bits_metaWen;
  wire  i_RequestBuffer__io_out_bits_metaWen;
  logic p_RequestBuffer__io_out_bits_metaWen;
  bit   t_RequestBuffer__io_out_bits_metaWen;
  wire  g_RequestBuffer__io_out_bits_tagWen;
  wire  i_RequestBuffer__io_out_bits_tagWen;
  logic p_RequestBuffer__io_out_bits_tagWen;
  bit   t_RequestBuffer__io_out_bits_tagWen;
  wire  g_RequestBuffer__io_out_bits_dsWen;
  wire  i_RequestBuffer__io_out_bits_dsWen;
  logic p_RequestBuffer__io_out_bits_dsWen;
  bit   t_RequestBuffer__io_out_bits_dsWen;
  wire  g_RequestBuffer__io_out_bits_replTask;
  wire  i_RequestBuffer__io_out_bits_replTask;
  logic p_RequestBuffer__io_out_bits_replTask;
  bit   t_RequestBuffer__io_out_bits_replTask;
  wire  g_RequestBuffer__io_out_bits_cmoTask;
  wire  i_RequestBuffer__io_out_bits_cmoTask;
  logic p_RequestBuffer__io_out_bits_cmoTask;
  bit   t_RequestBuffer__io_out_bits_cmoTask;
  wire  g_RequestBuffer__io_out_bits_cmoAll;
  wire  i_RequestBuffer__io_out_bits_cmoAll;
  logic p_RequestBuffer__io_out_bits_cmoAll;
  bit   t_RequestBuffer__io_out_bits_cmoAll;
  wire  [4:0] g_RequestBuffer__io_out_bits_reqSource;
  wire  [4:0] i_RequestBuffer__io_out_bits_reqSource;
  logic [4:0] p_RequestBuffer__io_out_bits_reqSource;
  bit   t_RequestBuffer__io_out_bits_reqSource;
  wire  g_RequestBuffer__io_out_bits_mergeA;
  wire  i_RequestBuffer__io_out_bits_mergeA;
  logic p_RequestBuffer__io_out_bits_mergeA;
  bit   t_RequestBuffer__io_out_bits_mergeA;
  wire  [5:0] g_RequestBuffer__io_out_bits_aMergeTask_off;
  wire  [5:0] i_RequestBuffer__io_out_bits_aMergeTask_off;
  logic [5:0] p_RequestBuffer__io_out_bits_aMergeTask_off;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_off;
  wire  [1:0] g_RequestBuffer__io_out_bits_aMergeTask_alias;
  wire  [1:0] i_RequestBuffer__io_out_bits_aMergeTask_alias;
  logic [1:0] p_RequestBuffer__io_out_bits_aMergeTask_alias;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_alias;
  wire  [43:0] g_RequestBuffer__io_out_bits_aMergeTask_vaddr;
  wire  [43:0] i_RequestBuffer__io_out_bits_aMergeTask_vaddr;
  logic [43:0] p_RequestBuffer__io_out_bits_aMergeTask_vaddr;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_vaddr;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_isKeyword;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_isKeyword;
  logic p_RequestBuffer__io_out_bits_aMergeTask_isKeyword;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_isKeyword;
  wire  [2:0] g_RequestBuffer__io_out_bits_aMergeTask_opcode;
  wire  [2:0] i_RequestBuffer__io_out_bits_aMergeTask_opcode;
  logic [2:0] p_RequestBuffer__io_out_bits_aMergeTask_opcode;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_opcode;
  wire  [2:0] g_RequestBuffer__io_out_bits_aMergeTask_param;
  wire  [2:0] i_RequestBuffer__io_out_bits_aMergeTask_param;
  logic [2:0] p_RequestBuffer__io_out_bits_aMergeTask_param;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_param;
  wire  [6:0] g_RequestBuffer__io_out_bits_aMergeTask_sourceId;
  wire  [6:0] i_RequestBuffer__io_out_bits_aMergeTask_sourceId;
  logic [6:0] p_RequestBuffer__io_out_bits_aMergeTask_sourceId;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_sourceId;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_meta_dirty;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_meta_dirty;
  logic p_RequestBuffer__io_out_bits_aMergeTask_meta_dirty;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_dirty;
  wire  [1:0] g_RequestBuffer__io_out_bits_aMergeTask_meta_state;
  wire  [1:0] i_RequestBuffer__io_out_bits_aMergeTask_meta_state;
  logic [1:0] p_RequestBuffer__io_out_bits_aMergeTask_meta_state;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_state;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_meta_clients;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_meta_clients;
  logic p_RequestBuffer__io_out_bits_aMergeTask_meta_clients;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_clients;
  wire  [1:0] g_RequestBuffer__io_out_bits_aMergeTask_meta_alias;
  wire  [1:0] i_RequestBuffer__io_out_bits_aMergeTask_meta_alias;
  logic [1:0] p_RequestBuffer__io_out_bits_aMergeTask_meta_alias;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_alias;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch;
  logic p_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch;
  wire  [2:0] g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc;
  wire  [2:0] i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc;
  logic [2:0] p_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_meta_accessed;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_meta_accessed;
  logic p_RequestBuffer__io_out_bits_aMergeTask_meta_accessed;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_accessed;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr;
  logic p_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr;
  wire  g_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr;
  wire  i_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr;
  logic p_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr;
  bit   t_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr;
  wire  g_RequestBuffer__io_out_bits_snpHitRelease;
  wire  i_RequestBuffer__io_out_bits_snpHitRelease;
  logic p_RequestBuffer__io_out_bits_snpHitRelease;
  bit   t_RequestBuffer__io_out_bits_snpHitRelease;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseToInval;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseToInval;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseToInval;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseToInval;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseToClean;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseToClean;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseToClean;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseToClean;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseWithData;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseWithData;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseWithData;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseWithData;
  wire  [7:0] g_RequestBuffer__io_out_bits_snpHitReleaseIdx;
  wire  [7:0] i_RequestBuffer__io_out_bits_snpHitReleaseIdx;
  logic [7:0] p_RequestBuffer__io_out_bits_snpHitReleaseIdx;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseIdx;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty;
  wire  [1:0] g_RequestBuffer__io_out_bits_snpHitReleaseMeta_state;
  wire  [1:0] i_RequestBuffer__io_out_bits_snpHitReleaseMeta_state;
  logic [1:0] p_RequestBuffer__io_out_bits_snpHitReleaseMeta_state;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_state;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients;
  wire  [1:0] g_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias;
  wire  [1:0] i_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias;
  logic [1:0] p_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch;
  wire  [2:0] g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc;
  wire  [2:0] i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] p_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr;
  wire  g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr;
  wire  i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr;
  logic p_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr;
  bit   t_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr;
  wire  [10:0] g_RequestBuffer__io_out_bits_tgtID;
  wire  [10:0] i_RequestBuffer__io_out_bits_tgtID;
  logic [10:0] p_RequestBuffer__io_out_bits_tgtID;
  bit   t_RequestBuffer__io_out_bits_tgtID;
  wire  [10:0] g_RequestBuffer__io_out_bits_srcID;
  wire  [10:0] i_RequestBuffer__io_out_bits_srcID;
  logic [10:0] p_RequestBuffer__io_out_bits_srcID;
  bit   t_RequestBuffer__io_out_bits_srcID;
  wire  [11:0] g_RequestBuffer__io_out_bits_txnID;
  wire  [11:0] i_RequestBuffer__io_out_bits_txnID;
  logic [11:0] p_RequestBuffer__io_out_bits_txnID;
  bit   t_RequestBuffer__io_out_bits_txnID;
  wire  [10:0] g_RequestBuffer__io_out_bits_homeNID;
  wire  [10:0] i_RequestBuffer__io_out_bits_homeNID;
  logic [10:0] p_RequestBuffer__io_out_bits_homeNID;
  bit   t_RequestBuffer__io_out_bits_homeNID;
  wire  [11:0] g_RequestBuffer__io_out_bits_dbID;
  wire  [11:0] i_RequestBuffer__io_out_bits_dbID;
  logic [11:0] p_RequestBuffer__io_out_bits_dbID;
  bit   t_RequestBuffer__io_out_bits_dbID;
  wire  [10:0] g_RequestBuffer__io_out_bits_fwdNID;
  wire  [10:0] i_RequestBuffer__io_out_bits_fwdNID;
  logic [10:0] p_RequestBuffer__io_out_bits_fwdNID;
  bit   t_RequestBuffer__io_out_bits_fwdNID;
  wire  [11:0] g_RequestBuffer__io_out_bits_fwdTxnID;
  wire  [11:0] i_RequestBuffer__io_out_bits_fwdTxnID;
  logic [11:0] p_RequestBuffer__io_out_bits_fwdTxnID;
  bit   t_RequestBuffer__io_out_bits_fwdTxnID;
  wire  [6:0] g_RequestBuffer__io_out_bits_chiOpcode;
  wire  [6:0] i_RequestBuffer__io_out_bits_chiOpcode;
  logic [6:0] p_RequestBuffer__io_out_bits_chiOpcode;
  bit   t_RequestBuffer__io_out_bits_chiOpcode;
  wire  [2:0] g_RequestBuffer__io_out_bits_resp;
  wire  [2:0] i_RequestBuffer__io_out_bits_resp;
  logic [2:0] p_RequestBuffer__io_out_bits_resp;
  bit   t_RequestBuffer__io_out_bits_resp;
  wire  [2:0] g_RequestBuffer__io_out_bits_fwdState;
  wire  [2:0] i_RequestBuffer__io_out_bits_fwdState;
  logic [2:0] p_RequestBuffer__io_out_bits_fwdState;
  bit   t_RequestBuffer__io_out_bits_fwdState;
  wire  [3:0] g_RequestBuffer__io_out_bits_pCrdType;
  wire  [3:0] i_RequestBuffer__io_out_bits_pCrdType;
  logic [3:0] p_RequestBuffer__io_out_bits_pCrdType;
  bit   t_RequestBuffer__io_out_bits_pCrdType;
  wire  g_RequestBuffer__io_out_bits_retToSrc;
  wire  i_RequestBuffer__io_out_bits_retToSrc;
  logic p_RequestBuffer__io_out_bits_retToSrc;
  bit   t_RequestBuffer__io_out_bits_retToSrc;
  wire  g_RequestBuffer__io_out_bits_likelyshared;
  wire  i_RequestBuffer__io_out_bits_likelyshared;
  logic p_RequestBuffer__io_out_bits_likelyshared;
  bit   t_RequestBuffer__io_out_bits_likelyshared;
  wire  g_RequestBuffer__io_out_bits_expCompAck;
  wire  i_RequestBuffer__io_out_bits_expCompAck;
  logic p_RequestBuffer__io_out_bits_expCompAck;
  bit   t_RequestBuffer__io_out_bits_expCompAck;
  wire  g_RequestBuffer__io_out_bits_allowRetry;
  wire  i_RequestBuffer__io_out_bits_allowRetry;
  logic p_RequestBuffer__io_out_bits_allowRetry;
  bit   t_RequestBuffer__io_out_bits_allowRetry;
  wire  g_RequestBuffer__io_out_bits_memAttr_allocate;
  wire  i_RequestBuffer__io_out_bits_memAttr_allocate;
  logic p_RequestBuffer__io_out_bits_memAttr_allocate;
  bit   t_RequestBuffer__io_out_bits_memAttr_allocate;
  wire  g_RequestBuffer__io_out_bits_memAttr_cacheable;
  wire  i_RequestBuffer__io_out_bits_memAttr_cacheable;
  logic p_RequestBuffer__io_out_bits_memAttr_cacheable;
  bit   t_RequestBuffer__io_out_bits_memAttr_cacheable;
  wire  g_RequestBuffer__io_out_bits_memAttr_device;
  wire  i_RequestBuffer__io_out_bits_memAttr_device;
  logic p_RequestBuffer__io_out_bits_memAttr_device;
  bit   t_RequestBuffer__io_out_bits_memAttr_device;
  wire  g_RequestBuffer__io_out_bits_memAttr_ewa;
  wire  i_RequestBuffer__io_out_bits_memAttr_ewa;
  logic p_RequestBuffer__io_out_bits_memAttr_ewa;
  bit   t_RequestBuffer__io_out_bits_memAttr_ewa;
  wire  g_RequestBuffer__io_out_bits_traceTag;
  wire  i_RequestBuffer__io_out_bits_traceTag;
  logic p_RequestBuffer__io_out_bits_traceTag;
  bit   t_RequestBuffer__io_out_bits_traceTag;
  wire  g_RequestBuffer__io_aMergeTask_valid;
  wire  i_RequestBuffer__io_aMergeTask_valid;
  logic p_RequestBuffer__io_aMergeTask_valid;
  bit   t_RequestBuffer__io_aMergeTask_valid;
  wire  [7:0] g_RequestBuffer__io_aMergeTask_bits_id;
  wire  [7:0] i_RequestBuffer__io_aMergeTask_bits_id;
  logic [7:0] p_RequestBuffer__io_aMergeTask_bits_id;
  bit   t_RequestBuffer__io_aMergeTask_bits_id;
  wire  [5:0] g_RequestBuffer__io_aMergeTask_bits_task_off;
  wire  [5:0] i_RequestBuffer__io_aMergeTask_bits_task_off;
  logic [5:0] p_RequestBuffer__io_aMergeTask_bits_task_off;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_off;
  wire  [1:0] g_RequestBuffer__io_aMergeTask_bits_task_alias;
  wire  [1:0] i_RequestBuffer__io_aMergeTask_bits_task_alias;
  logic [1:0] p_RequestBuffer__io_aMergeTask_bits_task_alias;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_alias;
  wire  [43:0] g_RequestBuffer__io_aMergeTask_bits_task_vaddr;
  wire  [43:0] i_RequestBuffer__io_aMergeTask_bits_task_vaddr;
  logic [43:0] p_RequestBuffer__io_aMergeTask_bits_task_vaddr;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_vaddr;
  wire  g_RequestBuffer__io_aMergeTask_bits_task_isKeyword;
  wire  i_RequestBuffer__io_aMergeTask_bits_task_isKeyword;
  logic p_RequestBuffer__io_aMergeTask_bits_task_isKeyword;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_isKeyword;
  wire  [3:0] g_RequestBuffer__io_aMergeTask_bits_task_opcode;
  wire  [3:0] i_RequestBuffer__io_aMergeTask_bits_task_opcode;
  logic [3:0] p_RequestBuffer__io_aMergeTask_bits_task_opcode;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_opcode;
  wire  [2:0] g_RequestBuffer__io_aMergeTask_bits_task_param;
  wire  [2:0] i_RequestBuffer__io_aMergeTask_bits_task_param;
  logic [2:0] p_RequestBuffer__io_aMergeTask_bits_task_param;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_param;
  wire  [6:0] g_RequestBuffer__io_aMergeTask_bits_task_sourceId;
  wire  [6:0] i_RequestBuffer__io_aMergeTask_bits_task_sourceId;
  logic [6:0] p_RequestBuffer__io_aMergeTask_bits_task_sourceId;
  bit   t_RequestBuffer__io_aMergeTask_bits_task_sourceId;
  wire  [30:0] g_RequestBuffer__io_ATag;
  wire  [30:0] i_RequestBuffer__io_ATag;
  logic [30:0] p_RequestBuffer__io_ATag;
  bit   t_RequestBuffer__io_ATag;
  wire  [8:0] g_RequestBuffer__io_ASet;
  wire  [8:0] i_RequestBuffer__io_ASet;
  logic [8:0] p_RequestBuffer__io_ASet;
  bit   t_RequestBuffer__io_ASet;
  wire  g_RequestBuffer__io_hasHitPfInMSHR_valid;
  wire  i_RequestBuffer__io_hasHitPfInMSHR_valid;
  logic p_RequestBuffer__io_hasHitPfInMSHR_valid;
  bit   t_RequestBuffer__io_hasHitPfInMSHR_valid;
  wire  [2:0] g_RequestBuffer__io_hasHitPfInMSHR_bits;
  wire  [2:0] i_RequestBuffer__io_hasHitPfInMSHR_bits;
  logic [2:0] p_RequestBuffer__io_hasHitPfInMSHR_bits;
  bit   t_RequestBuffer__io_hasHitPfInMSHR_bits;
  wire  g_RequestBuffer__io_hasPfLateInMSHR_valid;
  wire  i_RequestBuffer__io_hasPfLateInMSHR_valid;
  logic p_RequestBuffer__io_hasPfLateInMSHR_valid;
  bit   t_RequestBuffer__io_hasPfLateInMSHR_valid;
  wire  [4:0] g_RequestBuffer__io_hasPfLateInMSHR_bits;
  wire  [4:0] i_RequestBuffer__io_hasPfLateInMSHR_bits;
  logic [4:0] p_RequestBuffer__io_hasPfLateInMSHR_bits;
  bit   t_RequestBuffer__io_hasPfLateInMSHR_bits;
  wire  g_RequestBuffer__io_hasMergeA;
  wire  i_RequestBuffer__io_hasMergeA;
  logic p_RequestBuffer__io_hasMergeA;
  bit   t_RequestBuffer__io_hasMergeA;
  RequestBuffer u_g_RequestBuffer (
    .clock (clock),
    .reset (reset),
    .io_in_ready (g_RequestBuffer__io_in_ready),
    .io_in_valid (RequestBuffer__io_in_valid),
    .io_in_bits_set (RequestBuffer__io_in_bits_set),
    .io_in_bits_tag (RequestBuffer__io_in_bits_tag),
    .io_in_bits_off (RequestBuffer__io_in_bits_off),
    .io_in_bits_alias (RequestBuffer__io_in_bits_alias),
    .io_in_bits_vaddr (RequestBuffer__io_in_bits_vaddr),
    .io_in_bits_isKeyword (RequestBuffer__io_in_bits_isKeyword),
    .io_in_bits_opcode (RequestBuffer__io_in_bits_opcode),
    .io_in_bits_param (RequestBuffer__io_in_bits_param),
    .io_in_bits_size (RequestBuffer__io_in_bits_size),
    .io_in_bits_sourceId (RequestBuffer__io_in_bits_sourceId),
    .io_in_bits_corrupt (RequestBuffer__io_in_bits_corrupt),
    .io_in_bits_fromL2pft (RequestBuffer__io_in_bits_fromL2pft),
    .io_in_bits_needHint (RequestBuffer__io_in_bits_needHint),
    .io_in_bits_reqSource (RequestBuffer__io_in_bits_reqSource),
    .io_out_ready (RequestBuffer__io_out_ready),
    .io_out_valid (g_RequestBuffer__io_out_valid),
    .io_out_bits_channel (g_RequestBuffer__io_out_bits_channel),
    .io_out_bits_txChannel (g_RequestBuffer__io_out_bits_txChannel),
    .io_out_bits_set (g_RequestBuffer__io_out_bits_set),
    .io_out_bits_tag (g_RequestBuffer__io_out_bits_tag),
    .io_out_bits_off (g_RequestBuffer__io_out_bits_off),
    .io_out_bits_alias (g_RequestBuffer__io_out_bits_alias),
    .io_out_bits_vaddr (g_RequestBuffer__io_out_bits_vaddr),
    .io_out_bits_isKeyword (g_RequestBuffer__io_out_bits_isKeyword),
    .io_out_bits_opcode (g_RequestBuffer__io_out_bits_opcode),
    .io_out_bits_param (g_RequestBuffer__io_out_bits_param),
    .io_out_bits_size (g_RequestBuffer__io_out_bits_size),
    .io_out_bits_sourceId (g_RequestBuffer__io_out_bits_sourceId),
    .io_out_bits_bufIdx (g_RequestBuffer__io_out_bits_bufIdx),
    .io_out_bits_needProbeAckData (g_RequestBuffer__io_out_bits_needProbeAckData),
    .io_out_bits_denied (g_RequestBuffer__io_out_bits_denied),
    .io_out_bits_corrupt (g_RequestBuffer__io_out_bits_corrupt),
    .io_out_bits_mshrTask (g_RequestBuffer__io_out_bits_mshrTask),
    .io_out_bits_mshrId (g_RequestBuffer__io_out_bits_mshrId),
    .io_out_bits_aliasTask (g_RequestBuffer__io_out_bits_aliasTask),
    .io_out_bits_useProbeData (g_RequestBuffer__io_out_bits_useProbeData),
    .io_out_bits_mshrRetry (g_RequestBuffer__io_out_bits_mshrRetry),
    .io_out_bits_readProbeDataDown (g_RequestBuffer__io_out_bits_readProbeDataDown),
    .io_out_bits_fromL2pft (g_RequestBuffer__io_out_bits_fromL2pft),
    .io_out_bits_needHint (g_RequestBuffer__io_out_bits_needHint),
    .io_out_bits_dirty (g_RequestBuffer__io_out_bits_dirty),
    .io_out_bits_way (g_RequestBuffer__io_out_bits_way),
    .io_out_bits_meta_dirty (g_RequestBuffer__io_out_bits_meta_dirty),
    .io_out_bits_meta_state (g_RequestBuffer__io_out_bits_meta_state),
    .io_out_bits_meta_clients (g_RequestBuffer__io_out_bits_meta_clients),
    .io_out_bits_meta_alias (g_RequestBuffer__io_out_bits_meta_alias),
    .io_out_bits_meta_prefetch (g_RequestBuffer__io_out_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc (g_RequestBuffer__io_out_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed (g_RequestBuffer__io_out_bits_meta_accessed),
    .io_out_bits_meta_tagErr (g_RequestBuffer__io_out_bits_meta_tagErr),
    .io_out_bits_meta_dataErr (g_RequestBuffer__io_out_bits_meta_dataErr),
    .io_out_bits_metaWen (g_RequestBuffer__io_out_bits_metaWen),
    .io_out_bits_tagWen (g_RequestBuffer__io_out_bits_tagWen),
    .io_out_bits_dsWen (g_RequestBuffer__io_out_bits_dsWen),
    .io_out_bits_replTask (g_RequestBuffer__io_out_bits_replTask),
    .io_out_bits_cmoTask (g_RequestBuffer__io_out_bits_cmoTask),
    .io_out_bits_cmoAll (g_RequestBuffer__io_out_bits_cmoAll),
    .io_out_bits_reqSource (g_RequestBuffer__io_out_bits_reqSource),
    .io_out_bits_mergeA (g_RequestBuffer__io_out_bits_mergeA),
    .io_out_bits_aMergeTask_off (g_RequestBuffer__io_out_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias (g_RequestBuffer__io_out_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr (g_RequestBuffer__io_out_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword (g_RequestBuffer__io_out_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode (g_RequestBuffer__io_out_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param (g_RequestBuffer__io_out_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId (g_RequestBuffer__io_out_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty (g_RequestBuffer__io_out_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state (g_RequestBuffer__io_out_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients (g_RequestBuffer__io_out_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias (g_RequestBuffer__io_out_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_prefetch (g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch),
    .io_out_bits_aMergeTask_meta_prefetchSrc (g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc),
    .io_out_bits_aMergeTask_meta_accessed (g_RequestBuffer__io_out_bits_aMergeTask_meta_accessed),
    .io_out_bits_aMergeTask_meta_tagErr (g_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr),
    .io_out_bits_aMergeTask_meta_dataErr (g_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr),
    .io_out_bits_snpHitRelease (g_RequestBuffer__io_out_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval (g_RequestBuffer__io_out_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean (g_RequestBuffer__io_out_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData (g_RequestBuffer__io_out_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx (g_RequestBuffer__io_out_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID (g_RequestBuffer__io_out_bits_tgtID),
    .io_out_bits_srcID (g_RequestBuffer__io_out_bits_srcID),
    .io_out_bits_txnID (g_RequestBuffer__io_out_bits_txnID),
    .io_out_bits_homeNID (g_RequestBuffer__io_out_bits_homeNID),
    .io_out_bits_dbID (g_RequestBuffer__io_out_bits_dbID),
    .io_out_bits_fwdNID (g_RequestBuffer__io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID (g_RequestBuffer__io_out_bits_fwdTxnID),
    .io_out_bits_chiOpcode (g_RequestBuffer__io_out_bits_chiOpcode),
    .io_out_bits_resp (g_RequestBuffer__io_out_bits_resp),
    .io_out_bits_fwdState (g_RequestBuffer__io_out_bits_fwdState),
    .io_out_bits_pCrdType (g_RequestBuffer__io_out_bits_pCrdType),
    .io_out_bits_retToSrc (g_RequestBuffer__io_out_bits_retToSrc),
    .io_out_bits_likelyshared (g_RequestBuffer__io_out_bits_likelyshared),
    .io_out_bits_expCompAck (g_RequestBuffer__io_out_bits_expCompAck),
    .io_out_bits_allowRetry (g_RequestBuffer__io_out_bits_allowRetry),
    .io_out_bits_memAttr_allocate (g_RequestBuffer__io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable (g_RequestBuffer__io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device (g_RequestBuffer__io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa (g_RequestBuffer__io_out_bits_memAttr_ewa),
    .io_out_bits_traceTag (g_RequestBuffer__io_out_bits_traceTag),
    .io_mshrInfo_0_valid (RequestBuffer__io_mshrInfo_0_valid),
    .io_mshrInfo_0_bits_channel (RequestBuffer__io_mshrInfo_0_bits_channel),
    .io_mshrInfo_0_bits_set (RequestBuffer__io_mshrInfo_0_bits_set),
    .io_mshrInfo_0_bits_reqTag (RequestBuffer__io_mshrInfo_0_bits_reqTag),
    .io_mshrInfo_0_bits_willFree (RequestBuffer__io_mshrInfo_0_bits_willFree),
    .io_mshrInfo_0_bits_needRelease (RequestBuffer__io_mshrInfo_0_bits_needRelease),
    .io_mshrInfo_0_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_0_bits_meta_prefetchSrc),
    .io_mshrInfo_0_bits_metaTag (RequestBuffer__io_mshrInfo_0_bits_metaTag),
    .io_mshrInfo_0_bits_dirHit (RequestBuffer__io_mshrInfo_0_bits_dirHit),
    .io_mshrInfo_0_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_0_bits_isAcqOrPrefetch),
    .io_mshrInfo_0_bits_isPrefetch (RequestBuffer__io_mshrInfo_0_bits_isPrefetch),
    .io_mshrInfo_0_bits_param (RequestBuffer__io_mshrInfo_0_bits_param),
    .io_mshrInfo_0_bits_mergeA (RequestBuffer__io_mshrInfo_0_bits_mergeA),
    .io_mshrInfo_0_bits_s_refill (RequestBuffer__io_mshrInfo_0_bits_s_refill),
    .io_mshrInfo_1_valid (RequestBuffer__io_mshrInfo_1_valid),
    .io_mshrInfo_1_bits_channel (RequestBuffer__io_mshrInfo_1_bits_channel),
    .io_mshrInfo_1_bits_set (RequestBuffer__io_mshrInfo_1_bits_set),
    .io_mshrInfo_1_bits_reqTag (RequestBuffer__io_mshrInfo_1_bits_reqTag),
    .io_mshrInfo_1_bits_willFree (RequestBuffer__io_mshrInfo_1_bits_willFree),
    .io_mshrInfo_1_bits_needRelease (RequestBuffer__io_mshrInfo_1_bits_needRelease),
    .io_mshrInfo_1_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_1_bits_meta_prefetchSrc),
    .io_mshrInfo_1_bits_metaTag (RequestBuffer__io_mshrInfo_1_bits_metaTag),
    .io_mshrInfo_1_bits_dirHit (RequestBuffer__io_mshrInfo_1_bits_dirHit),
    .io_mshrInfo_1_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_1_bits_isAcqOrPrefetch),
    .io_mshrInfo_1_bits_isPrefetch (RequestBuffer__io_mshrInfo_1_bits_isPrefetch),
    .io_mshrInfo_1_bits_param (RequestBuffer__io_mshrInfo_1_bits_param),
    .io_mshrInfo_1_bits_mergeA (RequestBuffer__io_mshrInfo_1_bits_mergeA),
    .io_mshrInfo_1_bits_s_refill (RequestBuffer__io_mshrInfo_1_bits_s_refill),
    .io_mshrInfo_2_valid (RequestBuffer__io_mshrInfo_2_valid),
    .io_mshrInfo_2_bits_channel (RequestBuffer__io_mshrInfo_2_bits_channel),
    .io_mshrInfo_2_bits_set (RequestBuffer__io_mshrInfo_2_bits_set),
    .io_mshrInfo_2_bits_reqTag (RequestBuffer__io_mshrInfo_2_bits_reqTag),
    .io_mshrInfo_2_bits_willFree (RequestBuffer__io_mshrInfo_2_bits_willFree),
    .io_mshrInfo_2_bits_needRelease (RequestBuffer__io_mshrInfo_2_bits_needRelease),
    .io_mshrInfo_2_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_2_bits_meta_prefetchSrc),
    .io_mshrInfo_2_bits_metaTag (RequestBuffer__io_mshrInfo_2_bits_metaTag),
    .io_mshrInfo_2_bits_dirHit (RequestBuffer__io_mshrInfo_2_bits_dirHit),
    .io_mshrInfo_2_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_2_bits_isAcqOrPrefetch),
    .io_mshrInfo_2_bits_isPrefetch (RequestBuffer__io_mshrInfo_2_bits_isPrefetch),
    .io_mshrInfo_2_bits_param (RequestBuffer__io_mshrInfo_2_bits_param),
    .io_mshrInfo_2_bits_mergeA (RequestBuffer__io_mshrInfo_2_bits_mergeA),
    .io_mshrInfo_2_bits_s_refill (RequestBuffer__io_mshrInfo_2_bits_s_refill),
    .io_mshrInfo_3_valid (RequestBuffer__io_mshrInfo_3_valid),
    .io_mshrInfo_3_bits_channel (RequestBuffer__io_mshrInfo_3_bits_channel),
    .io_mshrInfo_3_bits_set (RequestBuffer__io_mshrInfo_3_bits_set),
    .io_mshrInfo_3_bits_reqTag (RequestBuffer__io_mshrInfo_3_bits_reqTag),
    .io_mshrInfo_3_bits_willFree (RequestBuffer__io_mshrInfo_3_bits_willFree),
    .io_mshrInfo_3_bits_needRelease (RequestBuffer__io_mshrInfo_3_bits_needRelease),
    .io_mshrInfo_3_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_3_bits_meta_prefetchSrc),
    .io_mshrInfo_3_bits_metaTag (RequestBuffer__io_mshrInfo_3_bits_metaTag),
    .io_mshrInfo_3_bits_dirHit (RequestBuffer__io_mshrInfo_3_bits_dirHit),
    .io_mshrInfo_3_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_3_bits_isAcqOrPrefetch),
    .io_mshrInfo_3_bits_isPrefetch (RequestBuffer__io_mshrInfo_3_bits_isPrefetch),
    .io_mshrInfo_3_bits_param (RequestBuffer__io_mshrInfo_3_bits_param),
    .io_mshrInfo_3_bits_mergeA (RequestBuffer__io_mshrInfo_3_bits_mergeA),
    .io_mshrInfo_3_bits_s_refill (RequestBuffer__io_mshrInfo_3_bits_s_refill),
    .io_mshrInfo_4_valid (RequestBuffer__io_mshrInfo_4_valid),
    .io_mshrInfo_4_bits_channel (RequestBuffer__io_mshrInfo_4_bits_channel),
    .io_mshrInfo_4_bits_set (RequestBuffer__io_mshrInfo_4_bits_set),
    .io_mshrInfo_4_bits_reqTag (RequestBuffer__io_mshrInfo_4_bits_reqTag),
    .io_mshrInfo_4_bits_willFree (RequestBuffer__io_mshrInfo_4_bits_willFree),
    .io_mshrInfo_4_bits_needRelease (RequestBuffer__io_mshrInfo_4_bits_needRelease),
    .io_mshrInfo_4_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_4_bits_meta_prefetchSrc),
    .io_mshrInfo_4_bits_metaTag (RequestBuffer__io_mshrInfo_4_bits_metaTag),
    .io_mshrInfo_4_bits_dirHit (RequestBuffer__io_mshrInfo_4_bits_dirHit),
    .io_mshrInfo_4_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_4_bits_isAcqOrPrefetch),
    .io_mshrInfo_4_bits_isPrefetch (RequestBuffer__io_mshrInfo_4_bits_isPrefetch),
    .io_mshrInfo_4_bits_param (RequestBuffer__io_mshrInfo_4_bits_param),
    .io_mshrInfo_4_bits_mergeA (RequestBuffer__io_mshrInfo_4_bits_mergeA),
    .io_mshrInfo_4_bits_s_refill (RequestBuffer__io_mshrInfo_4_bits_s_refill),
    .io_mshrInfo_5_valid (RequestBuffer__io_mshrInfo_5_valid),
    .io_mshrInfo_5_bits_channel (RequestBuffer__io_mshrInfo_5_bits_channel),
    .io_mshrInfo_5_bits_set (RequestBuffer__io_mshrInfo_5_bits_set),
    .io_mshrInfo_5_bits_reqTag (RequestBuffer__io_mshrInfo_5_bits_reqTag),
    .io_mshrInfo_5_bits_willFree (RequestBuffer__io_mshrInfo_5_bits_willFree),
    .io_mshrInfo_5_bits_needRelease (RequestBuffer__io_mshrInfo_5_bits_needRelease),
    .io_mshrInfo_5_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_5_bits_meta_prefetchSrc),
    .io_mshrInfo_5_bits_metaTag (RequestBuffer__io_mshrInfo_5_bits_metaTag),
    .io_mshrInfo_5_bits_dirHit (RequestBuffer__io_mshrInfo_5_bits_dirHit),
    .io_mshrInfo_5_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_5_bits_isAcqOrPrefetch),
    .io_mshrInfo_5_bits_isPrefetch (RequestBuffer__io_mshrInfo_5_bits_isPrefetch),
    .io_mshrInfo_5_bits_param (RequestBuffer__io_mshrInfo_5_bits_param),
    .io_mshrInfo_5_bits_mergeA (RequestBuffer__io_mshrInfo_5_bits_mergeA),
    .io_mshrInfo_5_bits_s_refill (RequestBuffer__io_mshrInfo_5_bits_s_refill),
    .io_mshrInfo_6_valid (RequestBuffer__io_mshrInfo_6_valid),
    .io_mshrInfo_6_bits_channel (RequestBuffer__io_mshrInfo_6_bits_channel),
    .io_mshrInfo_6_bits_set (RequestBuffer__io_mshrInfo_6_bits_set),
    .io_mshrInfo_6_bits_reqTag (RequestBuffer__io_mshrInfo_6_bits_reqTag),
    .io_mshrInfo_6_bits_willFree (RequestBuffer__io_mshrInfo_6_bits_willFree),
    .io_mshrInfo_6_bits_needRelease (RequestBuffer__io_mshrInfo_6_bits_needRelease),
    .io_mshrInfo_6_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_6_bits_meta_prefetchSrc),
    .io_mshrInfo_6_bits_metaTag (RequestBuffer__io_mshrInfo_6_bits_metaTag),
    .io_mshrInfo_6_bits_dirHit (RequestBuffer__io_mshrInfo_6_bits_dirHit),
    .io_mshrInfo_6_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_6_bits_isAcqOrPrefetch),
    .io_mshrInfo_6_bits_isPrefetch (RequestBuffer__io_mshrInfo_6_bits_isPrefetch),
    .io_mshrInfo_6_bits_param (RequestBuffer__io_mshrInfo_6_bits_param),
    .io_mshrInfo_6_bits_mergeA (RequestBuffer__io_mshrInfo_6_bits_mergeA),
    .io_mshrInfo_6_bits_s_refill (RequestBuffer__io_mshrInfo_6_bits_s_refill),
    .io_mshrInfo_7_valid (RequestBuffer__io_mshrInfo_7_valid),
    .io_mshrInfo_7_bits_channel (RequestBuffer__io_mshrInfo_7_bits_channel),
    .io_mshrInfo_7_bits_set (RequestBuffer__io_mshrInfo_7_bits_set),
    .io_mshrInfo_7_bits_reqTag (RequestBuffer__io_mshrInfo_7_bits_reqTag),
    .io_mshrInfo_7_bits_willFree (RequestBuffer__io_mshrInfo_7_bits_willFree),
    .io_mshrInfo_7_bits_needRelease (RequestBuffer__io_mshrInfo_7_bits_needRelease),
    .io_mshrInfo_7_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_7_bits_meta_prefetchSrc),
    .io_mshrInfo_7_bits_metaTag (RequestBuffer__io_mshrInfo_7_bits_metaTag),
    .io_mshrInfo_7_bits_dirHit (RequestBuffer__io_mshrInfo_7_bits_dirHit),
    .io_mshrInfo_7_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_7_bits_isAcqOrPrefetch),
    .io_mshrInfo_7_bits_isPrefetch (RequestBuffer__io_mshrInfo_7_bits_isPrefetch),
    .io_mshrInfo_7_bits_param (RequestBuffer__io_mshrInfo_7_bits_param),
    .io_mshrInfo_7_bits_mergeA (RequestBuffer__io_mshrInfo_7_bits_mergeA),
    .io_mshrInfo_7_bits_s_refill (RequestBuffer__io_mshrInfo_7_bits_s_refill),
    .io_mshrInfo_8_valid (RequestBuffer__io_mshrInfo_8_valid),
    .io_mshrInfo_8_bits_channel (RequestBuffer__io_mshrInfo_8_bits_channel),
    .io_mshrInfo_8_bits_set (RequestBuffer__io_mshrInfo_8_bits_set),
    .io_mshrInfo_8_bits_reqTag (RequestBuffer__io_mshrInfo_8_bits_reqTag),
    .io_mshrInfo_8_bits_willFree (RequestBuffer__io_mshrInfo_8_bits_willFree),
    .io_mshrInfo_8_bits_needRelease (RequestBuffer__io_mshrInfo_8_bits_needRelease),
    .io_mshrInfo_8_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_8_bits_meta_prefetchSrc),
    .io_mshrInfo_8_bits_metaTag (RequestBuffer__io_mshrInfo_8_bits_metaTag),
    .io_mshrInfo_8_bits_dirHit (RequestBuffer__io_mshrInfo_8_bits_dirHit),
    .io_mshrInfo_8_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_8_bits_isAcqOrPrefetch),
    .io_mshrInfo_8_bits_isPrefetch (RequestBuffer__io_mshrInfo_8_bits_isPrefetch),
    .io_mshrInfo_8_bits_param (RequestBuffer__io_mshrInfo_8_bits_param),
    .io_mshrInfo_8_bits_mergeA (RequestBuffer__io_mshrInfo_8_bits_mergeA),
    .io_mshrInfo_8_bits_s_refill (RequestBuffer__io_mshrInfo_8_bits_s_refill),
    .io_mshrInfo_9_valid (RequestBuffer__io_mshrInfo_9_valid),
    .io_mshrInfo_9_bits_channel (RequestBuffer__io_mshrInfo_9_bits_channel),
    .io_mshrInfo_9_bits_set (RequestBuffer__io_mshrInfo_9_bits_set),
    .io_mshrInfo_9_bits_reqTag (RequestBuffer__io_mshrInfo_9_bits_reqTag),
    .io_mshrInfo_9_bits_willFree (RequestBuffer__io_mshrInfo_9_bits_willFree),
    .io_mshrInfo_9_bits_needRelease (RequestBuffer__io_mshrInfo_9_bits_needRelease),
    .io_mshrInfo_9_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_9_bits_meta_prefetchSrc),
    .io_mshrInfo_9_bits_metaTag (RequestBuffer__io_mshrInfo_9_bits_metaTag),
    .io_mshrInfo_9_bits_dirHit (RequestBuffer__io_mshrInfo_9_bits_dirHit),
    .io_mshrInfo_9_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_9_bits_isAcqOrPrefetch),
    .io_mshrInfo_9_bits_isPrefetch (RequestBuffer__io_mshrInfo_9_bits_isPrefetch),
    .io_mshrInfo_9_bits_param (RequestBuffer__io_mshrInfo_9_bits_param),
    .io_mshrInfo_9_bits_mergeA (RequestBuffer__io_mshrInfo_9_bits_mergeA),
    .io_mshrInfo_9_bits_s_refill (RequestBuffer__io_mshrInfo_9_bits_s_refill),
    .io_mshrInfo_10_valid (RequestBuffer__io_mshrInfo_10_valid),
    .io_mshrInfo_10_bits_channel (RequestBuffer__io_mshrInfo_10_bits_channel),
    .io_mshrInfo_10_bits_set (RequestBuffer__io_mshrInfo_10_bits_set),
    .io_mshrInfo_10_bits_reqTag (RequestBuffer__io_mshrInfo_10_bits_reqTag),
    .io_mshrInfo_10_bits_willFree (RequestBuffer__io_mshrInfo_10_bits_willFree),
    .io_mshrInfo_10_bits_needRelease (RequestBuffer__io_mshrInfo_10_bits_needRelease),
    .io_mshrInfo_10_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_10_bits_meta_prefetchSrc),
    .io_mshrInfo_10_bits_metaTag (RequestBuffer__io_mshrInfo_10_bits_metaTag),
    .io_mshrInfo_10_bits_dirHit (RequestBuffer__io_mshrInfo_10_bits_dirHit),
    .io_mshrInfo_10_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_10_bits_isAcqOrPrefetch),
    .io_mshrInfo_10_bits_isPrefetch (RequestBuffer__io_mshrInfo_10_bits_isPrefetch),
    .io_mshrInfo_10_bits_param (RequestBuffer__io_mshrInfo_10_bits_param),
    .io_mshrInfo_10_bits_mergeA (RequestBuffer__io_mshrInfo_10_bits_mergeA),
    .io_mshrInfo_10_bits_s_refill (RequestBuffer__io_mshrInfo_10_bits_s_refill),
    .io_mshrInfo_11_valid (RequestBuffer__io_mshrInfo_11_valid),
    .io_mshrInfo_11_bits_channel (RequestBuffer__io_mshrInfo_11_bits_channel),
    .io_mshrInfo_11_bits_set (RequestBuffer__io_mshrInfo_11_bits_set),
    .io_mshrInfo_11_bits_reqTag (RequestBuffer__io_mshrInfo_11_bits_reqTag),
    .io_mshrInfo_11_bits_willFree (RequestBuffer__io_mshrInfo_11_bits_willFree),
    .io_mshrInfo_11_bits_needRelease (RequestBuffer__io_mshrInfo_11_bits_needRelease),
    .io_mshrInfo_11_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_11_bits_meta_prefetchSrc),
    .io_mshrInfo_11_bits_metaTag (RequestBuffer__io_mshrInfo_11_bits_metaTag),
    .io_mshrInfo_11_bits_dirHit (RequestBuffer__io_mshrInfo_11_bits_dirHit),
    .io_mshrInfo_11_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_11_bits_isAcqOrPrefetch),
    .io_mshrInfo_11_bits_isPrefetch (RequestBuffer__io_mshrInfo_11_bits_isPrefetch),
    .io_mshrInfo_11_bits_param (RequestBuffer__io_mshrInfo_11_bits_param),
    .io_mshrInfo_11_bits_mergeA (RequestBuffer__io_mshrInfo_11_bits_mergeA),
    .io_mshrInfo_11_bits_s_refill (RequestBuffer__io_mshrInfo_11_bits_s_refill),
    .io_mshrInfo_12_valid (RequestBuffer__io_mshrInfo_12_valid),
    .io_mshrInfo_12_bits_channel (RequestBuffer__io_mshrInfo_12_bits_channel),
    .io_mshrInfo_12_bits_set (RequestBuffer__io_mshrInfo_12_bits_set),
    .io_mshrInfo_12_bits_reqTag (RequestBuffer__io_mshrInfo_12_bits_reqTag),
    .io_mshrInfo_12_bits_willFree (RequestBuffer__io_mshrInfo_12_bits_willFree),
    .io_mshrInfo_12_bits_needRelease (RequestBuffer__io_mshrInfo_12_bits_needRelease),
    .io_mshrInfo_12_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_12_bits_meta_prefetchSrc),
    .io_mshrInfo_12_bits_metaTag (RequestBuffer__io_mshrInfo_12_bits_metaTag),
    .io_mshrInfo_12_bits_dirHit (RequestBuffer__io_mshrInfo_12_bits_dirHit),
    .io_mshrInfo_12_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_12_bits_isAcqOrPrefetch),
    .io_mshrInfo_12_bits_isPrefetch (RequestBuffer__io_mshrInfo_12_bits_isPrefetch),
    .io_mshrInfo_12_bits_param (RequestBuffer__io_mshrInfo_12_bits_param),
    .io_mshrInfo_12_bits_mergeA (RequestBuffer__io_mshrInfo_12_bits_mergeA),
    .io_mshrInfo_12_bits_s_refill (RequestBuffer__io_mshrInfo_12_bits_s_refill),
    .io_mshrInfo_13_valid (RequestBuffer__io_mshrInfo_13_valid),
    .io_mshrInfo_13_bits_channel (RequestBuffer__io_mshrInfo_13_bits_channel),
    .io_mshrInfo_13_bits_set (RequestBuffer__io_mshrInfo_13_bits_set),
    .io_mshrInfo_13_bits_reqTag (RequestBuffer__io_mshrInfo_13_bits_reqTag),
    .io_mshrInfo_13_bits_willFree (RequestBuffer__io_mshrInfo_13_bits_willFree),
    .io_mshrInfo_13_bits_needRelease (RequestBuffer__io_mshrInfo_13_bits_needRelease),
    .io_mshrInfo_13_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_13_bits_meta_prefetchSrc),
    .io_mshrInfo_13_bits_metaTag (RequestBuffer__io_mshrInfo_13_bits_metaTag),
    .io_mshrInfo_13_bits_dirHit (RequestBuffer__io_mshrInfo_13_bits_dirHit),
    .io_mshrInfo_13_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_13_bits_isAcqOrPrefetch),
    .io_mshrInfo_13_bits_isPrefetch (RequestBuffer__io_mshrInfo_13_bits_isPrefetch),
    .io_mshrInfo_13_bits_param (RequestBuffer__io_mshrInfo_13_bits_param),
    .io_mshrInfo_13_bits_mergeA (RequestBuffer__io_mshrInfo_13_bits_mergeA),
    .io_mshrInfo_13_bits_s_refill (RequestBuffer__io_mshrInfo_13_bits_s_refill),
    .io_mshrInfo_14_valid (RequestBuffer__io_mshrInfo_14_valid),
    .io_mshrInfo_14_bits_channel (RequestBuffer__io_mshrInfo_14_bits_channel),
    .io_mshrInfo_14_bits_set (RequestBuffer__io_mshrInfo_14_bits_set),
    .io_mshrInfo_14_bits_reqTag (RequestBuffer__io_mshrInfo_14_bits_reqTag),
    .io_mshrInfo_14_bits_willFree (RequestBuffer__io_mshrInfo_14_bits_willFree),
    .io_mshrInfo_14_bits_needRelease (RequestBuffer__io_mshrInfo_14_bits_needRelease),
    .io_mshrInfo_14_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_14_bits_meta_prefetchSrc),
    .io_mshrInfo_14_bits_metaTag (RequestBuffer__io_mshrInfo_14_bits_metaTag),
    .io_mshrInfo_14_bits_dirHit (RequestBuffer__io_mshrInfo_14_bits_dirHit),
    .io_mshrInfo_14_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_14_bits_isAcqOrPrefetch),
    .io_mshrInfo_14_bits_isPrefetch (RequestBuffer__io_mshrInfo_14_bits_isPrefetch),
    .io_mshrInfo_14_bits_param (RequestBuffer__io_mshrInfo_14_bits_param),
    .io_mshrInfo_14_bits_mergeA (RequestBuffer__io_mshrInfo_14_bits_mergeA),
    .io_mshrInfo_14_bits_s_refill (RequestBuffer__io_mshrInfo_14_bits_s_refill),
    .io_mshrInfo_15_valid (RequestBuffer__io_mshrInfo_15_valid),
    .io_mshrInfo_15_bits_channel (RequestBuffer__io_mshrInfo_15_bits_channel),
    .io_mshrInfo_15_bits_set (RequestBuffer__io_mshrInfo_15_bits_set),
    .io_mshrInfo_15_bits_reqTag (RequestBuffer__io_mshrInfo_15_bits_reqTag),
    .io_mshrInfo_15_bits_willFree (RequestBuffer__io_mshrInfo_15_bits_willFree),
    .io_mshrInfo_15_bits_needRelease (RequestBuffer__io_mshrInfo_15_bits_needRelease),
    .io_mshrInfo_15_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_15_bits_meta_prefetchSrc),
    .io_mshrInfo_15_bits_metaTag (RequestBuffer__io_mshrInfo_15_bits_metaTag),
    .io_mshrInfo_15_bits_dirHit (RequestBuffer__io_mshrInfo_15_bits_dirHit),
    .io_mshrInfo_15_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_15_bits_isAcqOrPrefetch),
    .io_mshrInfo_15_bits_isPrefetch (RequestBuffer__io_mshrInfo_15_bits_isPrefetch),
    .io_mshrInfo_15_bits_param (RequestBuffer__io_mshrInfo_15_bits_param),
    .io_mshrInfo_15_bits_mergeA (RequestBuffer__io_mshrInfo_15_bits_mergeA),
    .io_mshrInfo_15_bits_s_refill (RequestBuffer__io_mshrInfo_15_bits_s_refill),
    .io_aMergeTask_valid (g_RequestBuffer__io_aMergeTask_valid),
    .io_aMergeTask_bits_id (g_RequestBuffer__io_aMergeTask_bits_id),
    .io_aMergeTask_bits_task_off (g_RequestBuffer__io_aMergeTask_bits_task_off),
    .io_aMergeTask_bits_task_alias (g_RequestBuffer__io_aMergeTask_bits_task_alias),
    .io_aMergeTask_bits_task_vaddr (g_RequestBuffer__io_aMergeTask_bits_task_vaddr),
    .io_aMergeTask_bits_task_isKeyword (g_RequestBuffer__io_aMergeTask_bits_task_isKeyword),
    .io_aMergeTask_bits_task_opcode (g_RequestBuffer__io_aMergeTask_bits_task_opcode),
    .io_aMergeTask_bits_task_param (g_RequestBuffer__io_aMergeTask_bits_task_param),
    .io_aMergeTask_bits_task_sourceId (g_RequestBuffer__io_aMergeTask_bits_task_sourceId),
    .io_mainPipeBlock_0 (RequestBuffer__io_mainPipeBlock_0),
    .io_mainPipeBlock_1 (RequestBuffer__io_mainPipeBlock_1),
    .io_taskFromArb_s2_valid (RequestBuffer__io_taskFromArb_s2_valid),
    .io_taskFromArb_s2_bits_channel (RequestBuffer__io_taskFromArb_s2_bits_channel),
    .io_taskFromArb_s2_bits_set (RequestBuffer__io_taskFromArb_s2_bits_set),
    .io_taskFromArb_s2_bits_mshrTask (RequestBuffer__io_taskFromArb_s2_bits_mshrTask),
    .io_ATag (g_RequestBuffer__io_ATag),
    .io_ASet (g_RequestBuffer__io_ASet),
    .io_s1Entrance_valid (RequestBuffer__io_s1Entrance_valid),
    .io_s1Entrance_bits_set (RequestBuffer__io_s1Entrance_bits_set),
    .io_hasHitPfInMSHR_valid (g_RequestBuffer__io_hasHitPfInMSHR_valid),
    .io_hasHitPfInMSHR_bits (g_RequestBuffer__io_hasHitPfInMSHR_bits),
    .io_hasPfLateInMSHR_valid (g_RequestBuffer__io_hasPfLateInMSHR_valid),
    .io_hasPfLateInMSHR_bits (g_RequestBuffer__io_hasPfLateInMSHR_bits),
    .io_hasMergeA (g_RequestBuffer__io_hasMergeA)
  );
  RequestBuffer_xs u_i_RequestBuffer (
    .clock (clock),
    .reset (reset),
    .io_in_ready (i_RequestBuffer__io_in_ready),
    .io_in_valid (RequestBuffer__io_in_valid),
    .io_in_bits_set (RequestBuffer__io_in_bits_set),
    .io_in_bits_tag (RequestBuffer__io_in_bits_tag),
    .io_in_bits_off (RequestBuffer__io_in_bits_off),
    .io_in_bits_alias (RequestBuffer__io_in_bits_alias),
    .io_in_bits_vaddr (RequestBuffer__io_in_bits_vaddr),
    .io_in_bits_isKeyword (RequestBuffer__io_in_bits_isKeyword),
    .io_in_bits_opcode (RequestBuffer__io_in_bits_opcode),
    .io_in_bits_param (RequestBuffer__io_in_bits_param),
    .io_in_bits_size (RequestBuffer__io_in_bits_size),
    .io_in_bits_sourceId (RequestBuffer__io_in_bits_sourceId),
    .io_in_bits_corrupt (RequestBuffer__io_in_bits_corrupt),
    .io_in_bits_fromL2pft (RequestBuffer__io_in_bits_fromL2pft),
    .io_in_bits_needHint (RequestBuffer__io_in_bits_needHint),
    .io_in_bits_reqSource (RequestBuffer__io_in_bits_reqSource),
    .io_out_ready (RequestBuffer__io_out_ready),
    .io_out_valid (i_RequestBuffer__io_out_valid),
    .io_out_bits_channel (i_RequestBuffer__io_out_bits_channel),
    .io_out_bits_txChannel (i_RequestBuffer__io_out_bits_txChannel),
    .io_out_bits_set (i_RequestBuffer__io_out_bits_set),
    .io_out_bits_tag (i_RequestBuffer__io_out_bits_tag),
    .io_out_bits_off (i_RequestBuffer__io_out_bits_off),
    .io_out_bits_alias (i_RequestBuffer__io_out_bits_alias),
    .io_out_bits_vaddr (i_RequestBuffer__io_out_bits_vaddr),
    .io_out_bits_isKeyword (i_RequestBuffer__io_out_bits_isKeyword),
    .io_out_bits_opcode (i_RequestBuffer__io_out_bits_opcode),
    .io_out_bits_param (i_RequestBuffer__io_out_bits_param),
    .io_out_bits_size (i_RequestBuffer__io_out_bits_size),
    .io_out_bits_sourceId (i_RequestBuffer__io_out_bits_sourceId),
    .io_out_bits_bufIdx (i_RequestBuffer__io_out_bits_bufIdx),
    .io_out_bits_needProbeAckData (i_RequestBuffer__io_out_bits_needProbeAckData),
    .io_out_bits_denied (i_RequestBuffer__io_out_bits_denied),
    .io_out_bits_corrupt (i_RequestBuffer__io_out_bits_corrupt),
    .io_out_bits_mshrTask (i_RequestBuffer__io_out_bits_mshrTask),
    .io_out_bits_mshrId (i_RequestBuffer__io_out_bits_mshrId),
    .io_out_bits_aliasTask (i_RequestBuffer__io_out_bits_aliasTask),
    .io_out_bits_useProbeData (i_RequestBuffer__io_out_bits_useProbeData),
    .io_out_bits_mshrRetry (i_RequestBuffer__io_out_bits_mshrRetry),
    .io_out_bits_readProbeDataDown (i_RequestBuffer__io_out_bits_readProbeDataDown),
    .io_out_bits_fromL2pft (i_RequestBuffer__io_out_bits_fromL2pft),
    .io_out_bits_needHint (i_RequestBuffer__io_out_bits_needHint),
    .io_out_bits_dirty (i_RequestBuffer__io_out_bits_dirty),
    .io_out_bits_way (i_RequestBuffer__io_out_bits_way),
    .io_out_bits_meta_dirty (i_RequestBuffer__io_out_bits_meta_dirty),
    .io_out_bits_meta_state (i_RequestBuffer__io_out_bits_meta_state),
    .io_out_bits_meta_clients (i_RequestBuffer__io_out_bits_meta_clients),
    .io_out_bits_meta_alias (i_RequestBuffer__io_out_bits_meta_alias),
    .io_out_bits_meta_prefetch (i_RequestBuffer__io_out_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc (i_RequestBuffer__io_out_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed (i_RequestBuffer__io_out_bits_meta_accessed),
    .io_out_bits_meta_tagErr (i_RequestBuffer__io_out_bits_meta_tagErr),
    .io_out_bits_meta_dataErr (i_RequestBuffer__io_out_bits_meta_dataErr),
    .io_out_bits_metaWen (i_RequestBuffer__io_out_bits_metaWen),
    .io_out_bits_tagWen (i_RequestBuffer__io_out_bits_tagWen),
    .io_out_bits_dsWen (i_RequestBuffer__io_out_bits_dsWen),
    .io_out_bits_replTask (i_RequestBuffer__io_out_bits_replTask),
    .io_out_bits_cmoTask (i_RequestBuffer__io_out_bits_cmoTask),
    .io_out_bits_cmoAll (i_RequestBuffer__io_out_bits_cmoAll),
    .io_out_bits_reqSource (i_RequestBuffer__io_out_bits_reqSource),
    .io_out_bits_mergeA (i_RequestBuffer__io_out_bits_mergeA),
    .io_out_bits_aMergeTask_off (i_RequestBuffer__io_out_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias (i_RequestBuffer__io_out_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr (i_RequestBuffer__io_out_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword (i_RequestBuffer__io_out_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode (i_RequestBuffer__io_out_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param (i_RequestBuffer__io_out_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId (i_RequestBuffer__io_out_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty (i_RequestBuffer__io_out_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state (i_RequestBuffer__io_out_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients (i_RequestBuffer__io_out_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias (i_RequestBuffer__io_out_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_prefetch (i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch),
    .io_out_bits_aMergeTask_meta_prefetchSrc (i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc),
    .io_out_bits_aMergeTask_meta_accessed (i_RequestBuffer__io_out_bits_aMergeTask_meta_accessed),
    .io_out_bits_aMergeTask_meta_tagErr (i_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr),
    .io_out_bits_aMergeTask_meta_dataErr (i_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr),
    .io_out_bits_snpHitRelease (i_RequestBuffer__io_out_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval (i_RequestBuffer__io_out_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean (i_RequestBuffer__io_out_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData (i_RequestBuffer__io_out_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx (i_RequestBuffer__io_out_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr (i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID (i_RequestBuffer__io_out_bits_tgtID),
    .io_out_bits_srcID (i_RequestBuffer__io_out_bits_srcID),
    .io_out_bits_txnID (i_RequestBuffer__io_out_bits_txnID),
    .io_out_bits_homeNID (i_RequestBuffer__io_out_bits_homeNID),
    .io_out_bits_dbID (i_RequestBuffer__io_out_bits_dbID),
    .io_out_bits_fwdNID (i_RequestBuffer__io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID (i_RequestBuffer__io_out_bits_fwdTxnID),
    .io_out_bits_chiOpcode (i_RequestBuffer__io_out_bits_chiOpcode),
    .io_out_bits_resp (i_RequestBuffer__io_out_bits_resp),
    .io_out_bits_fwdState (i_RequestBuffer__io_out_bits_fwdState),
    .io_out_bits_pCrdType (i_RequestBuffer__io_out_bits_pCrdType),
    .io_out_bits_retToSrc (i_RequestBuffer__io_out_bits_retToSrc),
    .io_out_bits_likelyshared (i_RequestBuffer__io_out_bits_likelyshared),
    .io_out_bits_expCompAck (i_RequestBuffer__io_out_bits_expCompAck),
    .io_out_bits_allowRetry (i_RequestBuffer__io_out_bits_allowRetry),
    .io_out_bits_memAttr_allocate (i_RequestBuffer__io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable (i_RequestBuffer__io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device (i_RequestBuffer__io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa (i_RequestBuffer__io_out_bits_memAttr_ewa),
    .io_out_bits_traceTag (i_RequestBuffer__io_out_bits_traceTag),
    .io_mshrInfo_0_valid (RequestBuffer__io_mshrInfo_0_valid),
    .io_mshrInfo_0_bits_channel (RequestBuffer__io_mshrInfo_0_bits_channel),
    .io_mshrInfo_0_bits_set (RequestBuffer__io_mshrInfo_0_bits_set),
    .io_mshrInfo_0_bits_reqTag (RequestBuffer__io_mshrInfo_0_bits_reqTag),
    .io_mshrInfo_0_bits_willFree (RequestBuffer__io_mshrInfo_0_bits_willFree),
    .io_mshrInfo_0_bits_needRelease (RequestBuffer__io_mshrInfo_0_bits_needRelease),
    .io_mshrInfo_0_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_0_bits_meta_prefetchSrc),
    .io_mshrInfo_0_bits_metaTag (RequestBuffer__io_mshrInfo_0_bits_metaTag),
    .io_mshrInfo_0_bits_dirHit (RequestBuffer__io_mshrInfo_0_bits_dirHit),
    .io_mshrInfo_0_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_0_bits_isAcqOrPrefetch),
    .io_mshrInfo_0_bits_isPrefetch (RequestBuffer__io_mshrInfo_0_bits_isPrefetch),
    .io_mshrInfo_0_bits_param (RequestBuffer__io_mshrInfo_0_bits_param),
    .io_mshrInfo_0_bits_mergeA (RequestBuffer__io_mshrInfo_0_bits_mergeA),
    .io_mshrInfo_0_bits_s_refill (RequestBuffer__io_mshrInfo_0_bits_s_refill),
    .io_mshrInfo_1_valid (RequestBuffer__io_mshrInfo_1_valid),
    .io_mshrInfo_1_bits_channel (RequestBuffer__io_mshrInfo_1_bits_channel),
    .io_mshrInfo_1_bits_set (RequestBuffer__io_mshrInfo_1_bits_set),
    .io_mshrInfo_1_bits_reqTag (RequestBuffer__io_mshrInfo_1_bits_reqTag),
    .io_mshrInfo_1_bits_willFree (RequestBuffer__io_mshrInfo_1_bits_willFree),
    .io_mshrInfo_1_bits_needRelease (RequestBuffer__io_mshrInfo_1_bits_needRelease),
    .io_mshrInfo_1_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_1_bits_meta_prefetchSrc),
    .io_mshrInfo_1_bits_metaTag (RequestBuffer__io_mshrInfo_1_bits_metaTag),
    .io_mshrInfo_1_bits_dirHit (RequestBuffer__io_mshrInfo_1_bits_dirHit),
    .io_mshrInfo_1_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_1_bits_isAcqOrPrefetch),
    .io_mshrInfo_1_bits_isPrefetch (RequestBuffer__io_mshrInfo_1_bits_isPrefetch),
    .io_mshrInfo_1_bits_param (RequestBuffer__io_mshrInfo_1_bits_param),
    .io_mshrInfo_1_bits_mergeA (RequestBuffer__io_mshrInfo_1_bits_mergeA),
    .io_mshrInfo_1_bits_s_refill (RequestBuffer__io_mshrInfo_1_bits_s_refill),
    .io_mshrInfo_2_valid (RequestBuffer__io_mshrInfo_2_valid),
    .io_mshrInfo_2_bits_channel (RequestBuffer__io_mshrInfo_2_bits_channel),
    .io_mshrInfo_2_bits_set (RequestBuffer__io_mshrInfo_2_bits_set),
    .io_mshrInfo_2_bits_reqTag (RequestBuffer__io_mshrInfo_2_bits_reqTag),
    .io_mshrInfo_2_bits_willFree (RequestBuffer__io_mshrInfo_2_bits_willFree),
    .io_mshrInfo_2_bits_needRelease (RequestBuffer__io_mshrInfo_2_bits_needRelease),
    .io_mshrInfo_2_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_2_bits_meta_prefetchSrc),
    .io_mshrInfo_2_bits_metaTag (RequestBuffer__io_mshrInfo_2_bits_metaTag),
    .io_mshrInfo_2_bits_dirHit (RequestBuffer__io_mshrInfo_2_bits_dirHit),
    .io_mshrInfo_2_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_2_bits_isAcqOrPrefetch),
    .io_mshrInfo_2_bits_isPrefetch (RequestBuffer__io_mshrInfo_2_bits_isPrefetch),
    .io_mshrInfo_2_bits_param (RequestBuffer__io_mshrInfo_2_bits_param),
    .io_mshrInfo_2_bits_mergeA (RequestBuffer__io_mshrInfo_2_bits_mergeA),
    .io_mshrInfo_2_bits_s_refill (RequestBuffer__io_mshrInfo_2_bits_s_refill),
    .io_mshrInfo_3_valid (RequestBuffer__io_mshrInfo_3_valid),
    .io_mshrInfo_3_bits_channel (RequestBuffer__io_mshrInfo_3_bits_channel),
    .io_mshrInfo_3_bits_set (RequestBuffer__io_mshrInfo_3_bits_set),
    .io_mshrInfo_3_bits_reqTag (RequestBuffer__io_mshrInfo_3_bits_reqTag),
    .io_mshrInfo_3_bits_willFree (RequestBuffer__io_mshrInfo_3_bits_willFree),
    .io_mshrInfo_3_bits_needRelease (RequestBuffer__io_mshrInfo_3_bits_needRelease),
    .io_mshrInfo_3_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_3_bits_meta_prefetchSrc),
    .io_mshrInfo_3_bits_metaTag (RequestBuffer__io_mshrInfo_3_bits_metaTag),
    .io_mshrInfo_3_bits_dirHit (RequestBuffer__io_mshrInfo_3_bits_dirHit),
    .io_mshrInfo_3_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_3_bits_isAcqOrPrefetch),
    .io_mshrInfo_3_bits_isPrefetch (RequestBuffer__io_mshrInfo_3_bits_isPrefetch),
    .io_mshrInfo_3_bits_param (RequestBuffer__io_mshrInfo_3_bits_param),
    .io_mshrInfo_3_bits_mergeA (RequestBuffer__io_mshrInfo_3_bits_mergeA),
    .io_mshrInfo_3_bits_s_refill (RequestBuffer__io_mshrInfo_3_bits_s_refill),
    .io_mshrInfo_4_valid (RequestBuffer__io_mshrInfo_4_valid),
    .io_mshrInfo_4_bits_channel (RequestBuffer__io_mshrInfo_4_bits_channel),
    .io_mshrInfo_4_bits_set (RequestBuffer__io_mshrInfo_4_bits_set),
    .io_mshrInfo_4_bits_reqTag (RequestBuffer__io_mshrInfo_4_bits_reqTag),
    .io_mshrInfo_4_bits_willFree (RequestBuffer__io_mshrInfo_4_bits_willFree),
    .io_mshrInfo_4_bits_needRelease (RequestBuffer__io_mshrInfo_4_bits_needRelease),
    .io_mshrInfo_4_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_4_bits_meta_prefetchSrc),
    .io_mshrInfo_4_bits_metaTag (RequestBuffer__io_mshrInfo_4_bits_metaTag),
    .io_mshrInfo_4_bits_dirHit (RequestBuffer__io_mshrInfo_4_bits_dirHit),
    .io_mshrInfo_4_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_4_bits_isAcqOrPrefetch),
    .io_mshrInfo_4_bits_isPrefetch (RequestBuffer__io_mshrInfo_4_bits_isPrefetch),
    .io_mshrInfo_4_bits_param (RequestBuffer__io_mshrInfo_4_bits_param),
    .io_mshrInfo_4_bits_mergeA (RequestBuffer__io_mshrInfo_4_bits_mergeA),
    .io_mshrInfo_4_bits_s_refill (RequestBuffer__io_mshrInfo_4_bits_s_refill),
    .io_mshrInfo_5_valid (RequestBuffer__io_mshrInfo_5_valid),
    .io_mshrInfo_5_bits_channel (RequestBuffer__io_mshrInfo_5_bits_channel),
    .io_mshrInfo_5_bits_set (RequestBuffer__io_mshrInfo_5_bits_set),
    .io_mshrInfo_5_bits_reqTag (RequestBuffer__io_mshrInfo_5_bits_reqTag),
    .io_mshrInfo_5_bits_willFree (RequestBuffer__io_mshrInfo_5_bits_willFree),
    .io_mshrInfo_5_bits_needRelease (RequestBuffer__io_mshrInfo_5_bits_needRelease),
    .io_mshrInfo_5_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_5_bits_meta_prefetchSrc),
    .io_mshrInfo_5_bits_metaTag (RequestBuffer__io_mshrInfo_5_bits_metaTag),
    .io_mshrInfo_5_bits_dirHit (RequestBuffer__io_mshrInfo_5_bits_dirHit),
    .io_mshrInfo_5_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_5_bits_isAcqOrPrefetch),
    .io_mshrInfo_5_bits_isPrefetch (RequestBuffer__io_mshrInfo_5_bits_isPrefetch),
    .io_mshrInfo_5_bits_param (RequestBuffer__io_mshrInfo_5_bits_param),
    .io_mshrInfo_5_bits_mergeA (RequestBuffer__io_mshrInfo_5_bits_mergeA),
    .io_mshrInfo_5_bits_s_refill (RequestBuffer__io_mshrInfo_5_bits_s_refill),
    .io_mshrInfo_6_valid (RequestBuffer__io_mshrInfo_6_valid),
    .io_mshrInfo_6_bits_channel (RequestBuffer__io_mshrInfo_6_bits_channel),
    .io_mshrInfo_6_bits_set (RequestBuffer__io_mshrInfo_6_bits_set),
    .io_mshrInfo_6_bits_reqTag (RequestBuffer__io_mshrInfo_6_bits_reqTag),
    .io_mshrInfo_6_bits_willFree (RequestBuffer__io_mshrInfo_6_bits_willFree),
    .io_mshrInfo_6_bits_needRelease (RequestBuffer__io_mshrInfo_6_bits_needRelease),
    .io_mshrInfo_6_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_6_bits_meta_prefetchSrc),
    .io_mshrInfo_6_bits_metaTag (RequestBuffer__io_mshrInfo_6_bits_metaTag),
    .io_mshrInfo_6_bits_dirHit (RequestBuffer__io_mshrInfo_6_bits_dirHit),
    .io_mshrInfo_6_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_6_bits_isAcqOrPrefetch),
    .io_mshrInfo_6_bits_isPrefetch (RequestBuffer__io_mshrInfo_6_bits_isPrefetch),
    .io_mshrInfo_6_bits_param (RequestBuffer__io_mshrInfo_6_bits_param),
    .io_mshrInfo_6_bits_mergeA (RequestBuffer__io_mshrInfo_6_bits_mergeA),
    .io_mshrInfo_6_bits_s_refill (RequestBuffer__io_mshrInfo_6_bits_s_refill),
    .io_mshrInfo_7_valid (RequestBuffer__io_mshrInfo_7_valid),
    .io_mshrInfo_7_bits_channel (RequestBuffer__io_mshrInfo_7_bits_channel),
    .io_mshrInfo_7_bits_set (RequestBuffer__io_mshrInfo_7_bits_set),
    .io_mshrInfo_7_bits_reqTag (RequestBuffer__io_mshrInfo_7_bits_reqTag),
    .io_mshrInfo_7_bits_willFree (RequestBuffer__io_mshrInfo_7_bits_willFree),
    .io_mshrInfo_7_bits_needRelease (RequestBuffer__io_mshrInfo_7_bits_needRelease),
    .io_mshrInfo_7_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_7_bits_meta_prefetchSrc),
    .io_mshrInfo_7_bits_metaTag (RequestBuffer__io_mshrInfo_7_bits_metaTag),
    .io_mshrInfo_7_bits_dirHit (RequestBuffer__io_mshrInfo_7_bits_dirHit),
    .io_mshrInfo_7_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_7_bits_isAcqOrPrefetch),
    .io_mshrInfo_7_bits_isPrefetch (RequestBuffer__io_mshrInfo_7_bits_isPrefetch),
    .io_mshrInfo_7_bits_param (RequestBuffer__io_mshrInfo_7_bits_param),
    .io_mshrInfo_7_bits_mergeA (RequestBuffer__io_mshrInfo_7_bits_mergeA),
    .io_mshrInfo_7_bits_s_refill (RequestBuffer__io_mshrInfo_7_bits_s_refill),
    .io_mshrInfo_8_valid (RequestBuffer__io_mshrInfo_8_valid),
    .io_mshrInfo_8_bits_channel (RequestBuffer__io_mshrInfo_8_bits_channel),
    .io_mshrInfo_8_bits_set (RequestBuffer__io_mshrInfo_8_bits_set),
    .io_mshrInfo_8_bits_reqTag (RequestBuffer__io_mshrInfo_8_bits_reqTag),
    .io_mshrInfo_8_bits_willFree (RequestBuffer__io_mshrInfo_8_bits_willFree),
    .io_mshrInfo_8_bits_needRelease (RequestBuffer__io_mshrInfo_8_bits_needRelease),
    .io_mshrInfo_8_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_8_bits_meta_prefetchSrc),
    .io_mshrInfo_8_bits_metaTag (RequestBuffer__io_mshrInfo_8_bits_metaTag),
    .io_mshrInfo_8_bits_dirHit (RequestBuffer__io_mshrInfo_8_bits_dirHit),
    .io_mshrInfo_8_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_8_bits_isAcqOrPrefetch),
    .io_mshrInfo_8_bits_isPrefetch (RequestBuffer__io_mshrInfo_8_bits_isPrefetch),
    .io_mshrInfo_8_bits_param (RequestBuffer__io_mshrInfo_8_bits_param),
    .io_mshrInfo_8_bits_mergeA (RequestBuffer__io_mshrInfo_8_bits_mergeA),
    .io_mshrInfo_8_bits_s_refill (RequestBuffer__io_mshrInfo_8_bits_s_refill),
    .io_mshrInfo_9_valid (RequestBuffer__io_mshrInfo_9_valid),
    .io_mshrInfo_9_bits_channel (RequestBuffer__io_mshrInfo_9_bits_channel),
    .io_mshrInfo_9_bits_set (RequestBuffer__io_mshrInfo_9_bits_set),
    .io_mshrInfo_9_bits_reqTag (RequestBuffer__io_mshrInfo_9_bits_reqTag),
    .io_mshrInfo_9_bits_willFree (RequestBuffer__io_mshrInfo_9_bits_willFree),
    .io_mshrInfo_9_bits_needRelease (RequestBuffer__io_mshrInfo_9_bits_needRelease),
    .io_mshrInfo_9_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_9_bits_meta_prefetchSrc),
    .io_mshrInfo_9_bits_metaTag (RequestBuffer__io_mshrInfo_9_bits_metaTag),
    .io_mshrInfo_9_bits_dirHit (RequestBuffer__io_mshrInfo_9_bits_dirHit),
    .io_mshrInfo_9_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_9_bits_isAcqOrPrefetch),
    .io_mshrInfo_9_bits_isPrefetch (RequestBuffer__io_mshrInfo_9_bits_isPrefetch),
    .io_mshrInfo_9_bits_param (RequestBuffer__io_mshrInfo_9_bits_param),
    .io_mshrInfo_9_bits_mergeA (RequestBuffer__io_mshrInfo_9_bits_mergeA),
    .io_mshrInfo_9_bits_s_refill (RequestBuffer__io_mshrInfo_9_bits_s_refill),
    .io_mshrInfo_10_valid (RequestBuffer__io_mshrInfo_10_valid),
    .io_mshrInfo_10_bits_channel (RequestBuffer__io_mshrInfo_10_bits_channel),
    .io_mshrInfo_10_bits_set (RequestBuffer__io_mshrInfo_10_bits_set),
    .io_mshrInfo_10_bits_reqTag (RequestBuffer__io_mshrInfo_10_bits_reqTag),
    .io_mshrInfo_10_bits_willFree (RequestBuffer__io_mshrInfo_10_bits_willFree),
    .io_mshrInfo_10_bits_needRelease (RequestBuffer__io_mshrInfo_10_bits_needRelease),
    .io_mshrInfo_10_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_10_bits_meta_prefetchSrc),
    .io_mshrInfo_10_bits_metaTag (RequestBuffer__io_mshrInfo_10_bits_metaTag),
    .io_mshrInfo_10_bits_dirHit (RequestBuffer__io_mshrInfo_10_bits_dirHit),
    .io_mshrInfo_10_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_10_bits_isAcqOrPrefetch),
    .io_mshrInfo_10_bits_isPrefetch (RequestBuffer__io_mshrInfo_10_bits_isPrefetch),
    .io_mshrInfo_10_bits_param (RequestBuffer__io_mshrInfo_10_bits_param),
    .io_mshrInfo_10_bits_mergeA (RequestBuffer__io_mshrInfo_10_bits_mergeA),
    .io_mshrInfo_10_bits_s_refill (RequestBuffer__io_mshrInfo_10_bits_s_refill),
    .io_mshrInfo_11_valid (RequestBuffer__io_mshrInfo_11_valid),
    .io_mshrInfo_11_bits_channel (RequestBuffer__io_mshrInfo_11_bits_channel),
    .io_mshrInfo_11_bits_set (RequestBuffer__io_mshrInfo_11_bits_set),
    .io_mshrInfo_11_bits_reqTag (RequestBuffer__io_mshrInfo_11_bits_reqTag),
    .io_mshrInfo_11_bits_willFree (RequestBuffer__io_mshrInfo_11_bits_willFree),
    .io_mshrInfo_11_bits_needRelease (RequestBuffer__io_mshrInfo_11_bits_needRelease),
    .io_mshrInfo_11_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_11_bits_meta_prefetchSrc),
    .io_mshrInfo_11_bits_metaTag (RequestBuffer__io_mshrInfo_11_bits_metaTag),
    .io_mshrInfo_11_bits_dirHit (RequestBuffer__io_mshrInfo_11_bits_dirHit),
    .io_mshrInfo_11_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_11_bits_isAcqOrPrefetch),
    .io_mshrInfo_11_bits_isPrefetch (RequestBuffer__io_mshrInfo_11_bits_isPrefetch),
    .io_mshrInfo_11_bits_param (RequestBuffer__io_mshrInfo_11_bits_param),
    .io_mshrInfo_11_bits_mergeA (RequestBuffer__io_mshrInfo_11_bits_mergeA),
    .io_mshrInfo_11_bits_s_refill (RequestBuffer__io_mshrInfo_11_bits_s_refill),
    .io_mshrInfo_12_valid (RequestBuffer__io_mshrInfo_12_valid),
    .io_mshrInfo_12_bits_channel (RequestBuffer__io_mshrInfo_12_bits_channel),
    .io_mshrInfo_12_bits_set (RequestBuffer__io_mshrInfo_12_bits_set),
    .io_mshrInfo_12_bits_reqTag (RequestBuffer__io_mshrInfo_12_bits_reqTag),
    .io_mshrInfo_12_bits_willFree (RequestBuffer__io_mshrInfo_12_bits_willFree),
    .io_mshrInfo_12_bits_needRelease (RequestBuffer__io_mshrInfo_12_bits_needRelease),
    .io_mshrInfo_12_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_12_bits_meta_prefetchSrc),
    .io_mshrInfo_12_bits_metaTag (RequestBuffer__io_mshrInfo_12_bits_metaTag),
    .io_mshrInfo_12_bits_dirHit (RequestBuffer__io_mshrInfo_12_bits_dirHit),
    .io_mshrInfo_12_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_12_bits_isAcqOrPrefetch),
    .io_mshrInfo_12_bits_isPrefetch (RequestBuffer__io_mshrInfo_12_bits_isPrefetch),
    .io_mshrInfo_12_bits_param (RequestBuffer__io_mshrInfo_12_bits_param),
    .io_mshrInfo_12_bits_mergeA (RequestBuffer__io_mshrInfo_12_bits_mergeA),
    .io_mshrInfo_12_bits_s_refill (RequestBuffer__io_mshrInfo_12_bits_s_refill),
    .io_mshrInfo_13_valid (RequestBuffer__io_mshrInfo_13_valid),
    .io_mshrInfo_13_bits_channel (RequestBuffer__io_mshrInfo_13_bits_channel),
    .io_mshrInfo_13_bits_set (RequestBuffer__io_mshrInfo_13_bits_set),
    .io_mshrInfo_13_bits_reqTag (RequestBuffer__io_mshrInfo_13_bits_reqTag),
    .io_mshrInfo_13_bits_willFree (RequestBuffer__io_mshrInfo_13_bits_willFree),
    .io_mshrInfo_13_bits_needRelease (RequestBuffer__io_mshrInfo_13_bits_needRelease),
    .io_mshrInfo_13_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_13_bits_meta_prefetchSrc),
    .io_mshrInfo_13_bits_metaTag (RequestBuffer__io_mshrInfo_13_bits_metaTag),
    .io_mshrInfo_13_bits_dirHit (RequestBuffer__io_mshrInfo_13_bits_dirHit),
    .io_mshrInfo_13_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_13_bits_isAcqOrPrefetch),
    .io_mshrInfo_13_bits_isPrefetch (RequestBuffer__io_mshrInfo_13_bits_isPrefetch),
    .io_mshrInfo_13_bits_param (RequestBuffer__io_mshrInfo_13_bits_param),
    .io_mshrInfo_13_bits_mergeA (RequestBuffer__io_mshrInfo_13_bits_mergeA),
    .io_mshrInfo_13_bits_s_refill (RequestBuffer__io_mshrInfo_13_bits_s_refill),
    .io_mshrInfo_14_valid (RequestBuffer__io_mshrInfo_14_valid),
    .io_mshrInfo_14_bits_channel (RequestBuffer__io_mshrInfo_14_bits_channel),
    .io_mshrInfo_14_bits_set (RequestBuffer__io_mshrInfo_14_bits_set),
    .io_mshrInfo_14_bits_reqTag (RequestBuffer__io_mshrInfo_14_bits_reqTag),
    .io_mshrInfo_14_bits_willFree (RequestBuffer__io_mshrInfo_14_bits_willFree),
    .io_mshrInfo_14_bits_needRelease (RequestBuffer__io_mshrInfo_14_bits_needRelease),
    .io_mshrInfo_14_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_14_bits_meta_prefetchSrc),
    .io_mshrInfo_14_bits_metaTag (RequestBuffer__io_mshrInfo_14_bits_metaTag),
    .io_mshrInfo_14_bits_dirHit (RequestBuffer__io_mshrInfo_14_bits_dirHit),
    .io_mshrInfo_14_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_14_bits_isAcqOrPrefetch),
    .io_mshrInfo_14_bits_isPrefetch (RequestBuffer__io_mshrInfo_14_bits_isPrefetch),
    .io_mshrInfo_14_bits_param (RequestBuffer__io_mshrInfo_14_bits_param),
    .io_mshrInfo_14_bits_mergeA (RequestBuffer__io_mshrInfo_14_bits_mergeA),
    .io_mshrInfo_14_bits_s_refill (RequestBuffer__io_mshrInfo_14_bits_s_refill),
    .io_mshrInfo_15_valid (RequestBuffer__io_mshrInfo_15_valid),
    .io_mshrInfo_15_bits_channel (RequestBuffer__io_mshrInfo_15_bits_channel),
    .io_mshrInfo_15_bits_set (RequestBuffer__io_mshrInfo_15_bits_set),
    .io_mshrInfo_15_bits_reqTag (RequestBuffer__io_mshrInfo_15_bits_reqTag),
    .io_mshrInfo_15_bits_willFree (RequestBuffer__io_mshrInfo_15_bits_willFree),
    .io_mshrInfo_15_bits_needRelease (RequestBuffer__io_mshrInfo_15_bits_needRelease),
    .io_mshrInfo_15_bits_meta_prefetchSrc (RequestBuffer__io_mshrInfo_15_bits_meta_prefetchSrc),
    .io_mshrInfo_15_bits_metaTag (RequestBuffer__io_mshrInfo_15_bits_metaTag),
    .io_mshrInfo_15_bits_dirHit (RequestBuffer__io_mshrInfo_15_bits_dirHit),
    .io_mshrInfo_15_bits_isAcqOrPrefetch (RequestBuffer__io_mshrInfo_15_bits_isAcqOrPrefetch),
    .io_mshrInfo_15_bits_isPrefetch (RequestBuffer__io_mshrInfo_15_bits_isPrefetch),
    .io_mshrInfo_15_bits_param (RequestBuffer__io_mshrInfo_15_bits_param),
    .io_mshrInfo_15_bits_mergeA (RequestBuffer__io_mshrInfo_15_bits_mergeA),
    .io_mshrInfo_15_bits_s_refill (RequestBuffer__io_mshrInfo_15_bits_s_refill),
    .io_aMergeTask_valid (i_RequestBuffer__io_aMergeTask_valid),
    .io_aMergeTask_bits_id (i_RequestBuffer__io_aMergeTask_bits_id),
    .io_aMergeTask_bits_task_off (i_RequestBuffer__io_aMergeTask_bits_task_off),
    .io_aMergeTask_bits_task_alias (i_RequestBuffer__io_aMergeTask_bits_task_alias),
    .io_aMergeTask_bits_task_vaddr (i_RequestBuffer__io_aMergeTask_bits_task_vaddr),
    .io_aMergeTask_bits_task_isKeyword (i_RequestBuffer__io_aMergeTask_bits_task_isKeyword),
    .io_aMergeTask_bits_task_opcode (i_RequestBuffer__io_aMergeTask_bits_task_opcode),
    .io_aMergeTask_bits_task_param (i_RequestBuffer__io_aMergeTask_bits_task_param),
    .io_aMergeTask_bits_task_sourceId (i_RequestBuffer__io_aMergeTask_bits_task_sourceId),
    .io_mainPipeBlock_0 (RequestBuffer__io_mainPipeBlock_0),
    .io_mainPipeBlock_1 (RequestBuffer__io_mainPipeBlock_1),
    .io_taskFromArb_s2_valid (RequestBuffer__io_taskFromArb_s2_valid),
    .io_taskFromArb_s2_bits_channel (RequestBuffer__io_taskFromArb_s2_bits_channel),
    .io_taskFromArb_s2_bits_set (RequestBuffer__io_taskFromArb_s2_bits_set),
    .io_taskFromArb_s2_bits_mshrTask (RequestBuffer__io_taskFromArb_s2_bits_mshrTask),
    .io_ATag (i_RequestBuffer__io_ATag),
    .io_ASet (i_RequestBuffer__io_ASet),
    .io_s1Entrance_valid (RequestBuffer__io_s1Entrance_valid),
    .io_s1Entrance_bits_set (RequestBuffer__io_s1Entrance_bits_set),
    .io_hasHitPfInMSHR_valid (i_RequestBuffer__io_hasHitPfInMSHR_valid),
    .io_hasHitPfInMSHR_bits (i_RequestBuffer__io_hasHitPfInMSHR_bits),
    .io_hasPfLateInMSHR_valid (i_RequestBuffer__io_hasPfLateInMSHR_valid),
    .io_hasPfLateInMSHR_bits (i_RequestBuffer__io_hasPfLateInMSHR_bits),
    .io_hasMergeA (i_RequestBuffer__io_hasMergeA)
  );
  task automatic drive_RequestBuffer();
    RequestBuffer__io_in_valid = $urandom % 2;
    RequestBuffer__io_in_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_in_bits_tag = 31'($urandom_range(0, 3));
    RequestBuffer__io_in_bits_off = rnd(6);
    RequestBuffer__io_in_bits_alias = rnd(2);
    RequestBuffer__io_in_bits_vaddr = rnd(44);
    RequestBuffer__io_in_bits_isKeyword = $urandom % 2;
    RequestBuffer__io_in_bits_opcode = (($urandom % 2) == 0) ? 4'($urandom_range(5, 7)) : 4'($urandom);
    RequestBuffer__io_in_bits_param = rnd(3);
    RequestBuffer__io_in_bits_size = rnd(3);
    RequestBuffer__io_in_bits_sourceId = rnd(7);
    RequestBuffer__io_in_bits_corrupt = $urandom % 2;
    RequestBuffer__io_in_bits_fromL2pft = $urandom % 2;
    RequestBuffer__io_in_bits_needHint = $urandom % 2;
    RequestBuffer__io_in_bits_reqSource = rnd(5);
    RequestBuffer__io_out_ready = (($urandom % 4) != 0);
    RequestBuffer__io_mshrInfo_0_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_0_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_0_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_0_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_0_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_0_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_0_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_0_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_0_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_0_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_0_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_0_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_0_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_0_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_1_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_1_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_1_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_1_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_1_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_1_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_1_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_1_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_2_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_2_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_2_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_2_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_2_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_2_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_2_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_2_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_3_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_3_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_3_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_3_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_3_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_3_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_3_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_3_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_4_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_4_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_4_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_4_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_4_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_4_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_4_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_4_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_5_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_5_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_5_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_5_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_5_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_5_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_5_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_5_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_6_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_6_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_6_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_6_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_6_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_6_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_6_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_6_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_7_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_7_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_7_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_7_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_7_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_7_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_7_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_7_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_8_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_8_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_8_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_8_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_8_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_8_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_8_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_8_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_9_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_9_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_9_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_9_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_9_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_9_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_9_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_9_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_10_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_10_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_10_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_10_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_10_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_10_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_10_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_10_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_11_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_11_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_11_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_11_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_11_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_11_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_11_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_11_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_12_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_12_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_12_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_12_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_12_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_12_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_12_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_12_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_13_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_13_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_13_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_13_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_13_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_13_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_13_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_13_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_14_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_14_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_14_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_14_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_14_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_14_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_14_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_14_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_valid = ((cyc / 1000) % 4 == 0) ? (($urandom % 16) < 7) : (($urandom % 4) == 0);
    RequestBuffer__io_mshrInfo_15_bits_channel = ((cyc / 1000) % 4 == 0) ? 3'h1 : 3'($urandom);
    RequestBuffer__io_mshrInfo_15_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_15_bits_reqTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_15_bits_willFree = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_bits_needRelease = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_bits_meta_prefetchSrc = rnd(3);
    RequestBuffer__io_mshrInfo_15_bits_metaTag = 31'($urandom_range(0, 3));
    RequestBuffer__io_mshrInfo_15_bits_dirHit = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_bits_isAcqOrPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_bits_isPrefetch = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_bits_param = rnd(3);
    RequestBuffer__io_mshrInfo_15_bits_mergeA = $urandom % 2;
    RequestBuffer__io_mshrInfo_15_bits_s_refill = $urandom % 2;
    RequestBuffer__io_mainPipeBlock_0 = (($urandom % 8) == 0);
    RequestBuffer__io_mainPipeBlock_1 = (($urandom % 8) == 0);
    RequestBuffer__io_taskFromArb_s2_valid = $urandom % 2;
    RequestBuffer__io_taskFromArb_s2_bits_channel = rnd(3);
    RequestBuffer__io_taskFromArb_s2_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
    RequestBuffer__io_taskFromArb_s2_bits_mshrTask = $urandom % 2;
    RequestBuffer__io_s1Entrance_valid = (($urandom % 4) == 0);
    RequestBuffer__io_s1Entrance_bits_set = ((cyc / 1000) % 4 == 0) ? 9'h0 : 9'($urandom_range(0, 3));
  endtask
  task automatic check_RequestBuffer();
    checks++;
    if (g_RequestBuffer__io_in_ready !== i_RequestBuffer__io_in_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_in_ready g=%h i=%h", cyc, g_RequestBuffer__io_in_ready, i_RequestBuffer__io_in_ready);
    end
    if (g_RequestBuffer__io_in_ready !== p_RequestBuffer__io_in_ready) t_RequestBuffer__io_in_ready = 1'b1;
    p_RequestBuffer__io_in_ready = g_RequestBuffer__io_in_ready;
    checks++;
    if (g_RequestBuffer__io_out_valid !== i_RequestBuffer__io_out_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_valid g=%h i=%h", cyc, g_RequestBuffer__io_out_valid, i_RequestBuffer__io_out_valid);
    end
    if (g_RequestBuffer__io_out_valid !== p_RequestBuffer__io_out_valid) t_RequestBuffer__io_out_valid = 1'b1;
    p_RequestBuffer__io_out_valid = g_RequestBuffer__io_out_valid;
    checks++;
    if (g_RequestBuffer__io_out_bits_channel !== i_RequestBuffer__io_out_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_channel g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_channel, i_RequestBuffer__io_out_bits_channel);
    end
    if (g_RequestBuffer__io_out_bits_channel !== p_RequestBuffer__io_out_bits_channel) t_RequestBuffer__io_out_bits_channel = 1'b1;
    p_RequestBuffer__io_out_bits_channel = g_RequestBuffer__io_out_bits_channel;
    checks++;
    if (g_RequestBuffer__io_out_bits_txChannel !== i_RequestBuffer__io_out_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_txChannel g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_txChannel, i_RequestBuffer__io_out_bits_txChannel);
    end
    if (g_RequestBuffer__io_out_bits_txChannel !== p_RequestBuffer__io_out_bits_txChannel) t_RequestBuffer__io_out_bits_txChannel = 1'b1;
    p_RequestBuffer__io_out_bits_txChannel = g_RequestBuffer__io_out_bits_txChannel;
    checks++;
    if (g_RequestBuffer__io_out_bits_set !== i_RequestBuffer__io_out_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_set g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_set, i_RequestBuffer__io_out_bits_set);
    end
    if (g_RequestBuffer__io_out_bits_set !== p_RequestBuffer__io_out_bits_set) t_RequestBuffer__io_out_bits_set = 1'b1;
    p_RequestBuffer__io_out_bits_set = g_RequestBuffer__io_out_bits_set;
    checks++;
    if (g_RequestBuffer__io_out_bits_tag !== i_RequestBuffer__io_out_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_tag g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_tag, i_RequestBuffer__io_out_bits_tag);
    end
    if (g_RequestBuffer__io_out_bits_tag !== p_RequestBuffer__io_out_bits_tag) t_RequestBuffer__io_out_bits_tag = 1'b1;
    p_RequestBuffer__io_out_bits_tag = g_RequestBuffer__io_out_bits_tag;
    checks++;
    if (g_RequestBuffer__io_out_bits_off !== i_RequestBuffer__io_out_bits_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_off g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_off, i_RequestBuffer__io_out_bits_off);
    end
    if (g_RequestBuffer__io_out_bits_off !== p_RequestBuffer__io_out_bits_off) t_RequestBuffer__io_out_bits_off = 1'b1;
    p_RequestBuffer__io_out_bits_off = g_RequestBuffer__io_out_bits_off;
    checks++;
    if (g_RequestBuffer__io_out_bits_alias !== i_RequestBuffer__io_out_bits_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_alias g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_alias, i_RequestBuffer__io_out_bits_alias);
    end
    if (g_RequestBuffer__io_out_bits_alias !== p_RequestBuffer__io_out_bits_alias) t_RequestBuffer__io_out_bits_alias = 1'b1;
    p_RequestBuffer__io_out_bits_alias = g_RequestBuffer__io_out_bits_alias;
    checks++;
    if (g_RequestBuffer__io_out_bits_vaddr !== i_RequestBuffer__io_out_bits_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_vaddr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_vaddr, i_RequestBuffer__io_out_bits_vaddr);
    end
    if (g_RequestBuffer__io_out_bits_vaddr !== p_RequestBuffer__io_out_bits_vaddr) t_RequestBuffer__io_out_bits_vaddr = 1'b1;
    p_RequestBuffer__io_out_bits_vaddr = g_RequestBuffer__io_out_bits_vaddr;
    checks++;
    if (g_RequestBuffer__io_out_bits_isKeyword !== i_RequestBuffer__io_out_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_isKeyword g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_isKeyword, i_RequestBuffer__io_out_bits_isKeyword);
    end
    if (g_RequestBuffer__io_out_bits_isKeyword !== p_RequestBuffer__io_out_bits_isKeyword) t_RequestBuffer__io_out_bits_isKeyword = 1'b1;
    p_RequestBuffer__io_out_bits_isKeyword = g_RequestBuffer__io_out_bits_isKeyword;
    checks++;
    if (g_RequestBuffer__io_out_bits_opcode !== i_RequestBuffer__io_out_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_opcode g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_opcode, i_RequestBuffer__io_out_bits_opcode);
    end
    if (g_RequestBuffer__io_out_bits_opcode !== p_RequestBuffer__io_out_bits_opcode) t_RequestBuffer__io_out_bits_opcode = 1'b1;
    p_RequestBuffer__io_out_bits_opcode = g_RequestBuffer__io_out_bits_opcode;
    checks++;
    if (g_RequestBuffer__io_out_bits_param !== i_RequestBuffer__io_out_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_param g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_param, i_RequestBuffer__io_out_bits_param);
    end
    if (g_RequestBuffer__io_out_bits_param !== p_RequestBuffer__io_out_bits_param) t_RequestBuffer__io_out_bits_param = 1'b1;
    p_RequestBuffer__io_out_bits_param = g_RequestBuffer__io_out_bits_param;
    checks++;
    if (g_RequestBuffer__io_out_bits_size !== i_RequestBuffer__io_out_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_size g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_size, i_RequestBuffer__io_out_bits_size);
    end
    if (g_RequestBuffer__io_out_bits_size !== p_RequestBuffer__io_out_bits_size) t_RequestBuffer__io_out_bits_size = 1'b1;
    p_RequestBuffer__io_out_bits_size = g_RequestBuffer__io_out_bits_size;
    checks++;
    if (g_RequestBuffer__io_out_bits_sourceId !== i_RequestBuffer__io_out_bits_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_sourceId g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_sourceId, i_RequestBuffer__io_out_bits_sourceId);
    end
    if (g_RequestBuffer__io_out_bits_sourceId !== p_RequestBuffer__io_out_bits_sourceId) t_RequestBuffer__io_out_bits_sourceId = 1'b1;
    p_RequestBuffer__io_out_bits_sourceId = g_RequestBuffer__io_out_bits_sourceId;
    checks++;
    if (g_RequestBuffer__io_out_bits_bufIdx !== i_RequestBuffer__io_out_bits_bufIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_bufIdx g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_bufIdx, i_RequestBuffer__io_out_bits_bufIdx);
    end
    if (g_RequestBuffer__io_out_bits_bufIdx !== p_RequestBuffer__io_out_bits_bufIdx) t_RequestBuffer__io_out_bits_bufIdx = 1'b1;
    p_RequestBuffer__io_out_bits_bufIdx = g_RequestBuffer__io_out_bits_bufIdx;
    checks++;
    if (g_RequestBuffer__io_out_bits_needProbeAckData !== i_RequestBuffer__io_out_bits_needProbeAckData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_needProbeAckData g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_needProbeAckData, i_RequestBuffer__io_out_bits_needProbeAckData);
    end
    if (g_RequestBuffer__io_out_bits_needProbeAckData !== p_RequestBuffer__io_out_bits_needProbeAckData) t_RequestBuffer__io_out_bits_needProbeAckData = 1'b1;
    p_RequestBuffer__io_out_bits_needProbeAckData = g_RequestBuffer__io_out_bits_needProbeAckData;
    checks++;
    if (g_RequestBuffer__io_out_bits_denied !== i_RequestBuffer__io_out_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_denied g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_denied, i_RequestBuffer__io_out_bits_denied);
    end
    if (g_RequestBuffer__io_out_bits_denied !== p_RequestBuffer__io_out_bits_denied) t_RequestBuffer__io_out_bits_denied = 1'b1;
    p_RequestBuffer__io_out_bits_denied = g_RequestBuffer__io_out_bits_denied;
    checks++;
    if (g_RequestBuffer__io_out_bits_corrupt !== i_RequestBuffer__io_out_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_corrupt g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_corrupt, i_RequestBuffer__io_out_bits_corrupt);
    end
    if (g_RequestBuffer__io_out_bits_corrupt !== p_RequestBuffer__io_out_bits_corrupt) t_RequestBuffer__io_out_bits_corrupt = 1'b1;
    p_RequestBuffer__io_out_bits_corrupt = g_RequestBuffer__io_out_bits_corrupt;
    checks++;
    if (g_RequestBuffer__io_out_bits_mshrTask !== i_RequestBuffer__io_out_bits_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_mshrTask g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_mshrTask, i_RequestBuffer__io_out_bits_mshrTask);
    end
    if (g_RequestBuffer__io_out_bits_mshrTask !== p_RequestBuffer__io_out_bits_mshrTask) t_RequestBuffer__io_out_bits_mshrTask = 1'b1;
    p_RequestBuffer__io_out_bits_mshrTask = g_RequestBuffer__io_out_bits_mshrTask;
    checks++;
    if (g_RequestBuffer__io_out_bits_mshrId !== i_RequestBuffer__io_out_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_mshrId g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_mshrId, i_RequestBuffer__io_out_bits_mshrId);
    end
    if (g_RequestBuffer__io_out_bits_mshrId !== p_RequestBuffer__io_out_bits_mshrId) t_RequestBuffer__io_out_bits_mshrId = 1'b1;
    p_RequestBuffer__io_out_bits_mshrId = g_RequestBuffer__io_out_bits_mshrId;
    checks++;
    if (g_RequestBuffer__io_out_bits_aliasTask !== i_RequestBuffer__io_out_bits_aliasTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aliasTask g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aliasTask, i_RequestBuffer__io_out_bits_aliasTask);
    end
    if (g_RequestBuffer__io_out_bits_aliasTask !== p_RequestBuffer__io_out_bits_aliasTask) t_RequestBuffer__io_out_bits_aliasTask = 1'b1;
    p_RequestBuffer__io_out_bits_aliasTask = g_RequestBuffer__io_out_bits_aliasTask;
    checks++;
    if (g_RequestBuffer__io_out_bits_useProbeData !== i_RequestBuffer__io_out_bits_useProbeData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_useProbeData g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_useProbeData, i_RequestBuffer__io_out_bits_useProbeData);
    end
    if (g_RequestBuffer__io_out_bits_useProbeData !== p_RequestBuffer__io_out_bits_useProbeData) t_RequestBuffer__io_out_bits_useProbeData = 1'b1;
    p_RequestBuffer__io_out_bits_useProbeData = g_RequestBuffer__io_out_bits_useProbeData;
    checks++;
    if (g_RequestBuffer__io_out_bits_mshrRetry !== i_RequestBuffer__io_out_bits_mshrRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_mshrRetry g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_mshrRetry, i_RequestBuffer__io_out_bits_mshrRetry);
    end
    if (g_RequestBuffer__io_out_bits_mshrRetry !== p_RequestBuffer__io_out_bits_mshrRetry) t_RequestBuffer__io_out_bits_mshrRetry = 1'b1;
    p_RequestBuffer__io_out_bits_mshrRetry = g_RequestBuffer__io_out_bits_mshrRetry;
    checks++;
    if (g_RequestBuffer__io_out_bits_readProbeDataDown !== i_RequestBuffer__io_out_bits_readProbeDataDown) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_readProbeDataDown g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_readProbeDataDown, i_RequestBuffer__io_out_bits_readProbeDataDown);
    end
    if (g_RequestBuffer__io_out_bits_readProbeDataDown !== p_RequestBuffer__io_out_bits_readProbeDataDown) t_RequestBuffer__io_out_bits_readProbeDataDown = 1'b1;
    p_RequestBuffer__io_out_bits_readProbeDataDown = g_RequestBuffer__io_out_bits_readProbeDataDown;
    checks++;
    if (g_RequestBuffer__io_out_bits_fromL2pft !== i_RequestBuffer__io_out_bits_fromL2pft) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_fromL2pft g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_fromL2pft, i_RequestBuffer__io_out_bits_fromL2pft);
    end
    if (g_RequestBuffer__io_out_bits_fromL2pft !== p_RequestBuffer__io_out_bits_fromL2pft) t_RequestBuffer__io_out_bits_fromL2pft = 1'b1;
    p_RequestBuffer__io_out_bits_fromL2pft = g_RequestBuffer__io_out_bits_fromL2pft;
    checks++;
    if (g_RequestBuffer__io_out_bits_needHint !== i_RequestBuffer__io_out_bits_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_needHint g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_needHint, i_RequestBuffer__io_out_bits_needHint);
    end
    if (g_RequestBuffer__io_out_bits_needHint !== p_RequestBuffer__io_out_bits_needHint) t_RequestBuffer__io_out_bits_needHint = 1'b1;
    p_RequestBuffer__io_out_bits_needHint = g_RequestBuffer__io_out_bits_needHint;
    checks++;
    if (g_RequestBuffer__io_out_bits_dirty !== i_RequestBuffer__io_out_bits_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_dirty g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_dirty, i_RequestBuffer__io_out_bits_dirty);
    end
    if (g_RequestBuffer__io_out_bits_dirty !== p_RequestBuffer__io_out_bits_dirty) t_RequestBuffer__io_out_bits_dirty = 1'b1;
    p_RequestBuffer__io_out_bits_dirty = g_RequestBuffer__io_out_bits_dirty;
    checks++;
    if (g_RequestBuffer__io_out_bits_way !== i_RequestBuffer__io_out_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_way g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_way, i_RequestBuffer__io_out_bits_way);
    end
    if (g_RequestBuffer__io_out_bits_way !== p_RequestBuffer__io_out_bits_way) t_RequestBuffer__io_out_bits_way = 1'b1;
    p_RequestBuffer__io_out_bits_way = g_RequestBuffer__io_out_bits_way;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_dirty !== i_RequestBuffer__io_out_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_dirty g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_dirty, i_RequestBuffer__io_out_bits_meta_dirty);
    end
    if (g_RequestBuffer__io_out_bits_meta_dirty !== p_RequestBuffer__io_out_bits_meta_dirty) t_RequestBuffer__io_out_bits_meta_dirty = 1'b1;
    p_RequestBuffer__io_out_bits_meta_dirty = g_RequestBuffer__io_out_bits_meta_dirty;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_state !== i_RequestBuffer__io_out_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_state g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_state, i_RequestBuffer__io_out_bits_meta_state);
    end
    if (g_RequestBuffer__io_out_bits_meta_state !== p_RequestBuffer__io_out_bits_meta_state) t_RequestBuffer__io_out_bits_meta_state = 1'b1;
    p_RequestBuffer__io_out_bits_meta_state = g_RequestBuffer__io_out_bits_meta_state;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_clients !== i_RequestBuffer__io_out_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_clients g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_clients, i_RequestBuffer__io_out_bits_meta_clients);
    end
    if (g_RequestBuffer__io_out_bits_meta_clients !== p_RequestBuffer__io_out_bits_meta_clients) t_RequestBuffer__io_out_bits_meta_clients = 1'b1;
    p_RequestBuffer__io_out_bits_meta_clients = g_RequestBuffer__io_out_bits_meta_clients;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_alias !== i_RequestBuffer__io_out_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_alias g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_alias, i_RequestBuffer__io_out_bits_meta_alias);
    end
    if (g_RequestBuffer__io_out_bits_meta_alias !== p_RequestBuffer__io_out_bits_meta_alias) t_RequestBuffer__io_out_bits_meta_alias = 1'b1;
    p_RequestBuffer__io_out_bits_meta_alias = g_RequestBuffer__io_out_bits_meta_alias;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_prefetch !== i_RequestBuffer__io_out_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_prefetch g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_prefetch, i_RequestBuffer__io_out_bits_meta_prefetch);
    end
    if (g_RequestBuffer__io_out_bits_meta_prefetch !== p_RequestBuffer__io_out_bits_meta_prefetch) t_RequestBuffer__io_out_bits_meta_prefetch = 1'b1;
    p_RequestBuffer__io_out_bits_meta_prefetch = g_RequestBuffer__io_out_bits_meta_prefetch;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_prefetchSrc !== i_RequestBuffer__io_out_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_prefetchSrc g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_prefetchSrc, i_RequestBuffer__io_out_bits_meta_prefetchSrc);
    end
    if (g_RequestBuffer__io_out_bits_meta_prefetchSrc !== p_RequestBuffer__io_out_bits_meta_prefetchSrc) t_RequestBuffer__io_out_bits_meta_prefetchSrc = 1'b1;
    p_RequestBuffer__io_out_bits_meta_prefetchSrc = g_RequestBuffer__io_out_bits_meta_prefetchSrc;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_accessed !== i_RequestBuffer__io_out_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_accessed g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_accessed, i_RequestBuffer__io_out_bits_meta_accessed);
    end
    if (g_RequestBuffer__io_out_bits_meta_accessed !== p_RequestBuffer__io_out_bits_meta_accessed) t_RequestBuffer__io_out_bits_meta_accessed = 1'b1;
    p_RequestBuffer__io_out_bits_meta_accessed = g_RequestBuffer__io_out_bits_meta_accessed;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_tagErr !== i_RequestBuffer__io_out_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_tagErr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_tagErr, i_RequestBuffer__io_out_bits_meta_tagErr);
    end
    if (g_RequestBuffer__io_out_bits_meta_tagErr !== p_RequestBuffer__io_out_bits_meta_tagErr) t_RequestBuffer__io_out_bits_meta_tagErr = 1'b1;
    p_RequestBuffer__io_out_bits_meta_tagErr = g_RequestBuffer__io_out_bits_meta_tagErr;
    checks++;
    if (g_RequestBuffer__io_out_bits_meta_dataErr !== i_RequestBuffer__io_out_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_meta_dataErr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_meta_dataErr, i_RequestBuffer__io_out_bits_meta_dataErr);
    end
    if (g_RequestBuffer__io_out_bits_meta_dataErr !== p_RequestBuffer__io_out_bits_meta_dataErr) t_RequestBuffer__io_out_bits_meta_dataErr = 1'b1;
    p_RequestBuffer__io_out_bits_meta_dataErr = g_RequestBuffer__io_out_bits_meta_dataErr;
    checks++;
    if (g_RequestBuffer__io_out_bits_metaWen !== i_RequestBuffer__io_out_bits_metaWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_metaWen g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_metaWen, i_RequestBuffer__io_out_bits_metaWen);
    end
    if (g_RequestBuffer__io_out_bits_metaWen !== p_RequestBuffer__io_out_bits_metaWen) t_RequestBuffer__io_out_bits_metaWen = 1'b1;
    p_RequestBuffer__io_out_bits_metaWen = g_RequestBuffer__io_out_bits_metaWen;
    checks++;
    if (g_RequestBuffer__io_out_bits_tagWen !== i_RequestBuffer__io_out_bits_tagWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_tagWen g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_tagWen, i_RequestBuffer__io_out_bits_tagWen);
    end
    if (g_RequestBuffer__io_out_bits_tagWen !== p_RequestBuffer__io_out_bits_tagWen) t_RequestBuffer__io_out_bits_tagWen = 1'b1;
    p_RequestBuffer__io_out_bits_tagWen = g_RequestBuffer__io_out_bits_tagWen;
    checks++;
    if (g_RequestBuffer__io_out_bits_dsWen !== i_RequestBuffer__io_out_bits_dsWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_dsWen g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_dsWen, i_RequestBuffer__io_out_bits_dsWen);
    end
    if (g_RequestBuffer__io_out_bits_dsWen !== p_RequestBuffer__io_out_bits_dsWen) t_RequestBuffer__io_out_bits_dsWen = 1'b1;
    p_RequestBuffer__io_out_bits_dsWen = g_RequestBuffer__io_out_bits_dsWen;
    checks++;
    if (g_RequestBuffer__io_out_bits_replTask !== i_RequestBuffer__io_out_bits_replTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_replTask g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_replTask, i_RequestBuffer__io_out_bits_replTask);
    end
    if (g_RequestBuffer__io_out_bits_replTask !== p_RequestBuffer__io_out_bits_replTask) t_RequestBuffer__io_out_bits_replTask = 1'b1;
    p_RequestBuffer__io_out_bits_replTask = g_RequestBuffer__io_out_bits_replTask;
    checks++;
    if (g_RequestBuffer__io_out_bits_cmoTask !== i_RequestBuffer__io_out_bits_cmoTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_cmoTask g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_cmoTask, i_RequestBuffer__io_out_bits_cmoTask);
    end
    if (g_RequestBuffer__io_out_bits_cmoTask !== p_RequestBuffer__io_out_bits_cmoTask) t_RequestBuffer__io_out_bits_cmoTask = 1'b1;
    p_RequestBuffer__io_out_bits_cmoTask = g_RequestBuffer__io_out_bits_cmoTask;
    checks++;
    if (g_RequestBuffer__io_out_bits_cmoAll !== i_RequestBuffer__io_out_bits_cmoAll) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_cmoAll g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_cmoAll, i_RequestBuffer__io_out_bits_cmoAll);
    end
    if (g_RequestBuffer__io_out_bits_cmoAll !== p_RequestBuffer__io_out_bits_cmoAll) t_RequestBuffer__io_out_bits_cmoAll = 1'b1;
    p_RequestBuffer__io_out_bits_cmoAll = g_RequestBuffer__io_out_bits_cmoAll;
    checks++;
    if (g_RequestBuffer__io_out_bits_reqSource !== i_RequestBuffer__io_out_bits_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_reqSource g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_reqSource, i_RequestBuffer__io_out_bits_reqSource);
    end
    if (g_RequestBuffer__io_out_bits_reqSource !== p_RequestBuffer__io_out_bits_reqSource) t_RequestBuffer__io_out_bits_reqSource = 1'b1;
    p_RequestBuffer__io_out_bits_reqSource = g_RequestBuffer__io_out_bits_reqSource;
    checks++;
    if (g_RequestBuffer__io_out_bits_mergeA !== i_RequestBuffer__io_out_bits_mergeA) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_mergeA g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_mergeA, i_RequestBuffer__io_out_bits_mergeA);
    end
    if (g_RequestBuffer__io_out_bits_mergeA !== p_RequestBuffer__io_out_bits_mergeA) t_RequestBuffer__io_out_bits_mergeA = 1'b1;
    p_RequestBuffer__io_out_bits_mergeA = g_RequestBuffer__io_out_bits_mergeA;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_off !== i_RequestBuffer__io_out_bits_aMergeTask_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_off g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_off, i_RequestBuffer__io_out_bits_aMergeTask_off);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_off !== p_RequestBuffer__io_out_bits_aMergeTask_off) t_RequestBuffer__io_out_bits_aMergeTask_off = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_off = g_RequestBuffer__io_out_bits_aMergeTask_off;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_alias !== i_RequestBuffer__io_out_bits_aMergeTask_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_alias g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_alias, i_RequestBuffer__io_out_bits_aMergeTask_alias);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_alias !== p_RequestBuffer__io_out_bits_aMergeTask_alias) t_RequestBuffer__io_out_bits_aMergeTask_alias = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_alias = g_RequestBuffer__io_out_bits_aMergeTask_alias;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_vaddr !== i_RequestBuffer__io_out_bits_aMergeTask_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_vaddr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_vaddr, i_RequestBuffer__io_out_bits_aMergeTask_vaddr);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_vaddr !== p_RequestBuffer__io_out_bits_aMergeTask_vaddr) t_RequestBuffer__io_out_bits_aMergeTask_vaddr = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_vaddr = g_RequestBuffer__io_out_bits_aMergeTask_vaddr;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_isKeyword !== i_RequestBuffer__io_out_bits_aMergeTask_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_isKeyword g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_isKeyword, i_RequestBuffer__io_out_bits_aMergeTask_isKeyword);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_isKeyword !== p_RequestBuffer__io_out_bits_aMergeTask_isKeyword) t_RequestBuffer__io_out_bits_aMergeTask_isKeyword = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_isKeyword = g_RequestBuffer__io_out_bits_aMergeTask_isKeyword;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_opcode !== i_RequestBuffer__io_out_bits_aMergeTask_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_opcode g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_opcode, i_RequestBuffer__io_out_bits_aMergeTask_opcode);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_opcode !== p_RequestBuffer__io_out_bits_aMergeTask_opcode) t_RequestBuffer__io_out_bits_aMergeTask_opcode = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_opcode = g_RequestBuffer__io_out_bits_aMergeTask_opcode;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_param !== i_RequestBuffer__io_out_bits_aMergeTask_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_param g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_param, i_RequestBuffer__io_out_bits_aMergeTask_param);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_param !== p_RequestBuffer__io_out_bits_aMergeTask_param) t_RequestBuffer__io_out_bits_aMergeTask_param = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_param = g_RequestBuffer__io_out_bits_aMergeTask_param;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_sourceId !== i_RequestBuffer__io_out_bits_aMergeTask_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_sourceId g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_sourceId, i_RequestBuffer__io_out_bits_aMergeTask_sourceId);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_sourceId !== p_RequestBuffer__io_out_bits_aMergeTask_sourceId) t_RequestBuffer__io_out_bits_aMergeTask_sourceId = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_sourceId = g_RequestBuffer__io_out_bits_aMergeTask_sourceId;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_dirty !== i_RequestBuffer__io_out_bits_aMergeTask_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_dirty g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_dirty, i_RequestBuffer__io_out_bits_aMergeTask_meta_dirty);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_dirty !== p_RequestBuffer__io_out_bits_aMergeTask_meta_dirty) t_RequestBuffer__io_out_bits_aMergeTask_meta_dirty = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_dirty = g_RequestBuffer__io_out_bits_aMergeTask_meta_dirty;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_state !== i_RequestBuffer__io_out_bits_aMergeTask_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_state g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_state, i_RequestBuffer__io_out_bits_aMergeTask_meta_state);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_state !== p_RequestBuffer__io_out_bits_aMergeTask_meta_state) t_RequestBuffer__io_out_bits_aMergeTask_meta_state = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_state = g_RequestBuffer__io_out_bits_aMergeTask_meta_state;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_clients !== i_RequestBuffer__io_out_bits_aMergeTask_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_clients g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_clients, i_RequestBuffer__io_out_bits_aMergeTask_meta_clients);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_clients !== p_RequestBuffer__io_out_bits_aMergeTask_meta_clients) t_RequestBuffer__io_out_bits_aMergeTask_meta_clients = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_clients = g_RequestBuffer__io_out_bits_aMergeTask_meta_clients;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_alias !== i_RequestBuffer__io_out_bits_aMergeTask_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_alias g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_alias, i_RequestBuffer__io_out_bits_aMergeTask_meta_alias);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_alias !== p_RequestBuffer__io_out_bits_aMergeTask_meta_alias) t_RequestBuffer__io_out_bits_aMergeTask_meta_alias = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_alias = g_RequestBuffer__io_out_bits_aMergeTask_meta_alias;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch !== i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_prefetch g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch, i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch !== p_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch) t_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch = g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc !== i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_prefetchSrc g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc, i_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc !== p_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc) t_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc = g_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_accessed !== i_RequestBuffer__io_out_bits_aMergeTask_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_accessed g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_accessed, i_RequestBuffer__io_out_bits_aMergeTask_meta_accessed);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_accessed !== p_RequestBuffer__io_out_bits_aMergeTask_meta_accessed) t_RequestBuffer__io_out_bits_aMergeTask_meta_accessed = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_accessed = g_RequestBuffer__io_out_bits_aMergeTask_meta_accessed;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr !== i_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_tagErr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr, i_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr !== p_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr) t_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr = g_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr;
    checks++;
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr !== i_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_aMergeTask_meta_dataErr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr, i_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr);
    end
    if (g_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr !== p_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr) t_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr = 1'b1;
    p_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr = g_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitRelease !== i_RequestBuffer__io_out_bits_snpHitRelease) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitRelease g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitRelease, i_RequestBuffer__io_out_bits_snpHitRelease);
    end
    if (g_RequestBuffer__io_out_bits_snpHitRelease !== p_RequestBuffer__io_out_bits_snpHitRelease) t_RequestBuffer__io_out_bits_snpHitRelease = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitRelease = g_RequestBuffer__io_out_bits_snpHitRelease;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseToInval !== i_RequestBuffer__io_out_bits_snpHitReleaseToInval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseToInval g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseToInval, i_RequestBuffer__io_out_bits_snpHitReleaseToInval);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseToInval !== p_RequestBuffer__io_out_bits_snpHitReleaseToInval) t_RequestBuffer__io_out_bits_snpHitReleaseToInval = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseToInval = g_RequestBuffer__io_out_bits_snpHitReleaseToInval;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseToClean !== i_RequestBuffer__io_out_bits_snpHitReleaseToClean) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseToClean g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseToClean, i_RequestBuffer__io_out_bits_snpHitReleaseToClean);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseToClean !== p_RequestBuffer__io_out_bits_snpHitReleaseToClean) t_RequestBuffer__io_out_bits_snpHitReleaseToClean = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseToClean = g_RequestBuffer__io_out_bits_snpHitReleaseToClean;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseWithData !== i_RequestBuffer__io_out_bits_snpHitReleaseWithData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseWithData g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseWithData, i_RequestBuffer__io_out_bits_snpHitReleaseWithData);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseWithData !== p_RequestBuffer__io_out_bits_snpHitReleaseWithData) t_RequestBuffer__io_out_bits_snpHitReleaseWithData = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseWithData = g_RequestBuffer__io_out_bits_snpHitReleaseWithData;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseIdx !== i_RequestBuffer__io_out_bits_snpHitReleaseIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseIdx g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseIdx, i_RequestBuffer__io_out_bits_snpHitReleaseIdx);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseIdx !== p_RequestBuffer__io_out_bits_snpHitReleaseIdx) t_RequestBuffer__io_out_bits_snpHitReleaseIdx = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseIdx = g_RequestBuffer__io_out_bits_snpHitReleaseIdx;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_dirty g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_state !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_state g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_state, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_state);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_state !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_state) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_state = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_state = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_state;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_clients g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_alias g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_prefetch g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_prefetchSrc g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_accessed g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_tagErr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr;
    checks++;
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr !== i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_snpHitReleaseMeta_dataErr g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr, i_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr);
    end
    if (g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr !== p_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr) t_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr = 1'b1;
    p_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr = g_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr;
    checks++;
    if (g_RequestBuffer__io_out_bits_tgtID !== i_RequestBuffer__io_out_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_tgtID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_tgtID, i_RequestBuffer__io_out_bits_tgtID);
    end
    if (g_RequestBuffer__io_out_bits_tgtID !== p_RequestBuffer__io_out_bits_tgtID) t_RequestBuffer__io_out_bits_tgtID = 1'b1;
    p_RequestBuffer__io_out_bits_tgtID = g_RequestBuffer__io_out_bits_tgtID;
    checks++;
    if (g_RequestBuffer__io_out_bits_srcID !== i_RequestBuffer__io_out_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_srcID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_srcID, i_RequestBuffer__io_out_bits_srcID);
    end
    if (g_RequestBuffer__io_out_bits_srcID !== p_RequestBuffer__io_out_bits_srcID) t_RequestBuffer__io_out_bits_srcID = 1'b1;
    p_RequestBuffer__io_out_bits_srcID = g_RequestBuffer__io_out_bits_srcID;
    checks++;
    if (g_RequestBuffer__io_out_bits_txnID !== i_RequestBuffer__io_out_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_txnID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_txnID, i_RequestBuffer__io_out_bits_txnID);
    end
    if (g_RequestBuffer__io_out_bits_txnID !== p_RequestBuffer__io_out_bits_txnID) t_RequestBuffer__io_out_bits_txnID = 1'b1;
    p_RequestBuffer__io_out_bits_txnID = g_RequestBuffer__io_out_bits_txnID;
    checks++;
    if (g_RequestBuffer__io_out_bits_homeNID !== i_RequestBuffer__io_out_bits_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_homeNID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_homeNID, i_RequestBuffer__io_out_bits_homeNID);
    end
    if (g_RequestBuffer__io_out_bits_homeNID !== p_RequestBuffer__io_out_bits_homeNID) t_RequestBuffer__io_out_bits_homeNID = 1'b1;
    p_RequestBuffer__io_out_bits_homeNID = g_RequestBuffer__io_out_bits_homeNID;
    checks++;
    if (g_RequestBuffer__io_out_bits_dbID !== i_RequestBuffer__io_out_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_dbID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_dbID, i_RequestBuffer__io_out_bits_dbID);
    end
    if (g_RequestBuffer__io_out_bits_dbID !== p_RequestBuffer__io_out_bits_dbID) t_RequestBuffer__io_out_bits_dbID = 1'b1;
    p_RequestBuffer__io_out_bits_dbID = g_RequestBuffer__io_out_bits_dbID;
    checks++;
    if (g_RequestBuffer__io_out_bits_fwdNID !== i_RequestBuffer__io_out_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_fwdNID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_fwdNID, i_RequestBuffer__io_out_bits_fwdNID);
    end
    if (g_RequestBuffer__io_out_bits_fwdNID !== p_RequestBuffer__io_out_bits_fwdNID) t_RequestBuffer__io_out_bits_fwdNID = 1'b1;
    p_RequestBuffer__io_out_bits_fwdNID = g_RequestBuffer__io_out_bits_fwdNID;
    checks++;
    if (g_RequestBuffer__io_out_bits_fwdTxnID !== i_RequestBuffer__io_out_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_fwdTxnID g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_fwdTxnID, i_RequestBuffer__io_out_bits_fwdTxnID);
    end
    if (g_RequestBuffer__io_out_bits_fwdTxnID !== p_RequestBuffer__io_out_bits_fwdTxnID) t_RequestBuffer__io_out_bits_fwdTxnID = 1'b1;
    p_RequestBuffer__io_out_bits_fwdTxnID = g_RequestBuffer__io_out_bits_fwdTxnID;
    checks++;
    if (g_RequestBuffer__io_out_bits_chiOpcode !== i_RequestBuffer__io_out_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_chiOpcode g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_chiOpcode, i_RequestBuffer__io_out_bits_chiOpcode);
    end
    if (g_RequestBuffer__io_out_bits_chiOpcode !== p_RequestBuffer__io_out_bits_chiOpcode) t_RequestBuffer__io_out_bits_chiOpcode = 1'b1;
    p_RequestBuffer__io_out_bits_chiOpcode = g_RequestBuffer__io_out_bits_chiOpcode;
    checks++;
    if (g_RequestBuffer__io_out_bits_resp !== i_RequestBuffer__io_out_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_resp g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_resp, i_RequestBuffer__io_out_bits_resp);
    end
    if (g_RequestBuffer__io_out_bits_resp !== p_RequestBuffer__io_out_bits_resp) t_RequestBuffer__io_out_bits_resp = 1'b1;
    p_RequestBuffer__io_out_bits_resp = g_RequestBuffer__io_out_bits_resp;
    checks++;
    if (g_RequestBuffer__io_out_bits_fwdState !== i_RequestBuffer__io_out_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_fwdState g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_fwdState, i_RequestBuffer__io_out_bits_fwdState);
    end
    if (g_RequestBuffer__io_out_bits_fwdState !== p_RequestBuffer__io_out_bits_fwdState) t_RequestBuffer__io_out_bits_fwdState = 1'b1;
    p_RequestBuffer__io_out_bits_fwdState = g_RequestBuffer__io_out_bits_fwdState;
    checks++;
    if (g_RequestBuffer__io_out_bits_pCrdType !== i_RequestBuffer__io_out_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_pCrdType g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_pCrdType, i_RequestBuffer__io_out_bits_pCrdType);
    end
    if (g_RequestBuffer__io_out_bits_pCrdType !== p_RequestBuffer__io_out_bits_pCrdType) t_RequestBuffer__io_out_bits_pCrdType = 1'b1;
    p_RequestBuffer__io_out_bits_pCrdType = g_RequestBuffer__io_out_bits_pCrdType;
    checks++;
    if (g_RequestBuffer__io_out_bits_retToSrc !== i_RequestBuffer__io_out_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_retToSrc g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_retToSrc, i_RequestBuffer__io_out_bits_retToSrc);
    end
    if (g_RequestBuffer__io_out_bits_retToSrc !== p_RequestBuffer__io_out_bits_retToSrc) t_RequestBuffer__io_out_bits_retToSrc = 1'b1;
    p_RequestBuffer__io_out_bits_retToSrc = g_RequestBuffer__io_out_bits_retToSrc;
    checks++;
    if (g_RequestBuffer__io_out_bits_likelyshared !== i_RequestBuffer__io_out_bits_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_likelyshared g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_likelyshared, i_RequestBuffer__io_out_bits_likelyshared);
    end
    if (g_RequestBuffer__io_out_bits_likelyshared !== p_RequestBuffer__io_out_bits_likelyshared) t_RequestBuffer__io_out_bits_likelyshared = 1'b1;
    p_RequestBuffer__io_out_bits_likelyshared = g_RequestBuffer__io_out_bits_likelyshared;
    checks++;
    if (g_RequestBuffer__io_out_bits_expCompAck !== i_RequestBuffer__io_out_bits_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_expCompAck g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_expCompAck, i_RequestBuffer__io_out_bits_expCompAck);
    end
    if (g_RequestBuffer__io_out_bits_expCompAck !== p_RequestBuffer__io_out_bits_expCompAck) t_RequestBuffer__io_out_bits_expCompAck = 1'b1;
    p_RequestBuffer__io_out_bits_expCompAck = g_RequestBuffer__io_out_bits_expCompAck;
    checks++;
    if (g_RequestBuffer__io_out_bits_allowRetry !== i_RequestBuffer__io_out_bits_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_allowRetry g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_allowRetry, i_RequestBuffer__io_out_bits_allowRetry);
    end
    if (g_RequestBuffer__io_out_bits_allowRetry !== p_RequestBuffer__io_out_bits_allowRetry) t_RequestBuffer__io_out_bits_allowRetry = 1'b1;
    p_RequestBuffer__io_out_bits_allowRetry = g_RequestBuffer__io_out_bits_allowRetry;
    checks++;
    if (g_RequestBuffer__io_out_bits_memAttr_allocate !== i_RequestBuffer__io_out_bits_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_memAttr_allocate g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_memAttr_allocate, i_RequestBuffer__io_out_bits_memAttr_allocate);
    end
    if (g_RequestBuffer__io_out_bits_memAttr_allocate !== p_RequestBuffer__io_out_bits_memAttr_allocate) t_RequestBuffer__io_out_bits_memAttr_allocate = 1'b1;
    p_RequestBuffer__io_out_bits_memAttr_allocate = g_RequestBuffer__io_out_bits_memAttr_allocate;
    checks++;
    if (g_RequestBuffer__io_out_bits_memAttr_cacheable !== i_RequestBuffer__io_out_bits_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_memAttr_cacheable g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_memAttr_cacheable, i_RequestBuffer__io_out_bits_memAttr_cacheable);
    end
    if (g_RequestBuffer__io_out_bits_memAttr_cacheable !== p_RequestBuffer__io_out_bits_memAttr_cacheable) t_RequestBuffer__io_out_bits_memAttr_cacheable = 1'b1;
    p_RequestBuffer__io_out_bits_memAttr_cacheable = g_RequestBuffer__io_out_bits_memAttr_cacheable;
    checks++;
    if (g_RequestBuffer__io_out_bits_memAttr_device !== i_RequestBuffer__io_out_bits_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_memAttr_device g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_memAttr_device, i_RequestBuffer__io_out_bits_memAttr_device);
    end
    if (g_RequestBuffer__io_out_bits_memAttr_device !== p_RequestBuffer__io_out_bits_memAttr_device) t_RequestBuffer__io_out_bits_memAttr_device = 1'b1;
    p_RequestBuffer__io_out_bits_memAttr_device = g_RequestBuffer__io_out_bits_memAttr_device;
    checks++;
    if (g_RequestBuffer__io_out_bits_memAttr_ewa !== i_RequestBuffer__io_out_bits_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_memAttr_ewa g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_memAttr_ewa, i_RequestBuffer__io_out_bits_memAttr_ewa);
    end
    if (g_RequestBuffer__io_out_bits_memAttr_ewa !== p_RequestBuffer__io_out_bits_memAttr_ewa) t_RequestBuffer__io_out_bits_memAttr_ewa = 1'b1;
    p_RequestBuffer__io_out_bits_memAttr_ewa = g_RequestBuffer__io_out_bits_memAttr_ewa;
    checks++;
    if (g_RequestBuffer__io_out_bits_traceTag !== i_RequestBuffer__io_out_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_out_bits_traceTag g=%h i=%h", cyc, g_RequestBuffer__io_out_bits_traceTag, i_RequestBuffer__io_out_bits_traceTag);
    end
    if (g_RequestBuffer__io_out_bits_traceTag !== p_RequestBuffer__io_out_bits_traceTag) t_RequestBuffer__io_out_bits_traceTag = 1'b1;
    p_RequestBuffer__io_out_bits_traceTag = g_RequestBuffer__io_out_bits_traceTag;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_valid !== i_RequestBuffer__io_aMergeTask_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_valid g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_valid, i_RequestBuffer__io_aMergeTask_valid);
    end
    if (g_RequestBuffer__io_aMergeTask_valid !== p_RequestBuffer__io_aMergeTask_valid) t_RequestBuffer__io_aMergeTask_valid = 1'b1;
    p_RequestBuffer__io_aMergeTask_valid = g_RequestBuffer__io_aMergeTask_valid;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_id !== i_RequestBuffer__io_aMergeTask_bits_id) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_id g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_id, i_RequestBuffer__io_aMergeTask_bits_id);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_id !== p_RequestBuffer__io_aMergeTask_bits_id) t_RequestBuffer__io_aMergeTask_bits_id = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_id = g_RequestBuffer__io_aMergeTask_bits_id;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_off !== i_RequestBuffer__io_aMergeTask_bits_task_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_off g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_off, i_RequestBuffer__io_aMergeTask_bits_task_off);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_off !== p_RequestBuffer__io_aMergeTask_bits_task_off) t_RequestBuffer__io_aMergeTask_bits_task_off = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_off = g_RequestBuffer__io_aMergeTask_bits_task_off;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_alias !== i_RequestBuffer__io_aMergeTask_bits_task_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_alias g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_alias, i_RequestBuffer__io_aMergeTask_bits_task_alias);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_alias !== p_RequestBuffer__io_aMergeTask_bits_task_alias) t_RequestBuffer__io_aMergeTask_bits_task_alias = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_alias = g_RequestBuffer__io_aMergeTask_bits_task_alias;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_vaddr !== i_RequestBuffer__io_aMergeTask_bits_task_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_vaddr g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_vaddr, i_RequestBuffer__io_aMergeTask_bits_task_vaddr);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_vaddr !== p_RequestBuffer__io_aMergeTask_bits_task_vaddr) t_RequestBuffer__io_aMergeTask_bits_task_vaddr = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_vaddr = g_RequestBuffer__io_aMergeTask_bits_task_vaddr;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_isKeyword !== i_RequestBuffer__io_aMergeTask_bits_task_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_isKeyword g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_isKeyword, i_RequestBuffer__io_aMergeTask_bits_task_isKeyword);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_isKeyword !== p_RequestBuffer__io_aMergeTask_bits_task_isKeyword) t_RequestBuffer__io_aMergeTask_bits_task_isKeyword = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_isKeyword = g_RequestBuffer__io_aMergeTask_bits_task_isKeyword;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_opcode !== i_RequestBuffer__io_aMergeTask_bits_task_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_opcode g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_opcode, i_RequestBuffer__io_aMergeTask_bits_task_opcode);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_opcode !== p_RequestBuffer__io_aMergeTask_bits_task_opcode) t_RequestBuffer__io_aMergeTask_bits_task_opcode = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_opcode = g_RequestBuffer__io_aMergeTask_bits_task_opcode;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_param !== i_RequestBuffer__io_aMergeTask_bits_task_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_param g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_param, i_RequestBuffer__io_aMergeTask_bits_task_param);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_param !== p_RequestBuffer__io_aMergeTask_bits_task_param) t_RequestBuffer__io_aMergeTask_bits_task_param = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_param = g_RequestBuffer__io_aMergeTask_bits_task_param;
    checks++;
    if (g_RequestBuffer__io_aMergeTask_bits_task_sourceId !== i_RequestBuffer__io_aMergeTask_bits_task_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_aMergeTask_bits_task_sourceId g=%h i=%h", cyc, g_RequestBuffer__io_aMergeTask_bits_task_sourceId, i_RequestBuffer__io_aMergeTask_bits_task_sourceId);
    end
    if (g_RequestBuffer__io_aMergeTask_bits_task_sourceId !== p_RequestBuffer__io_aMergeTask_bits_task_sourceId) t_RequestBuffer__io_aMergeTask_bits_task_sourceId = 1'b1;
    p_RequestBuffer__io_aMergeTask_bits_task_sourceId = g_RequestBuffer__io_aMergeTask_bits_task_sourceId;
    checks++;
    if (g_RequestBuffer__io_ATag !== i_RequestBuffer__io_ATag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_ATag g=%h i=%h", cyc, g_RequestBuffer__io_ATag, i_RequestBuffer__io_ATag);
    end
    if (g_RequestBuffer__io_ATag !== p_RequestBuffer__io_ATag) t_RequestBuffer__io_ATag = 1'b1;
    p_RequestBuffer__io_ATag = g_RequestBuffer__io_ATag;
    checks++;
    if (g_RequestBuffer__io_ASet !== i_RequestBuffer__io_ASet) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_ASet g=%h i=%h", cyc, g_RequestBuffer__io_ASet, i_RequestBuffer__io_ASet);
    end
    if (g_RequestBuffer__io_ASet !== p_RequestBuffer__io_ASet) t_RequestBuffer__io_ASet = 1'b1;
    p_RequestBuffer__io_ASet = g_RequestBuffer__io_ASet;
    checks++;
    if (g_RequestBuffer__io_hasHitPfInMSHR_valid !== i_RequestBuffer__io_hasHitPfInMSHR_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_hasHitPfInMSHR_valid g=%h i=%h", cyc, g_RequestBuffer__io_hasHitPfInMSHR_valid, i_RequestBuffer__io_hasHitPfInMSHR_valid);
    end
    if (g_RequestBuffer__io_hasHitPfInMSHR_valid !== p_RequestBuffer__io_hasHitPfInMSHR_valid) t_RequestBuffer__io_hasHitPfInMSHR_valid = 1'b1;
    p_RequestBuffer__io_hasHitPfInMSHR_valid = g_RequestBuffer__io_hasHitPfInMSHR_valid;
    checks++;
    if (g_RequestBuffer__io_hasHitPfInMSHR_bits !== i_RequestBuffer__io_hasHitPfInMSHR_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_hasHitPfInMSHR_bits g=%h i=%h", cyc, g_RequestBuffer__io_hasHitPfInMSHR_bits, i_RequestBuffer__io_hasHitPfInMSHR_bits);
    end
    if (g_RequestBuffer__io_hasHitPfInMSHR_bits !== p_RequestBuffer__io_hasHitPfInMSHR_bits) t_RequestBuffer__io_hasHitPfInMSHR_bits = 1'b1;
    p_RequestBuffer__io_hasHitPfInMSHR_bits = g_RequestBuffer__io_hasHitPfInMSHR_bits;
    checks++;
    if (g_RequestBuffer__io_hasPfLateInMSHR_valid !== i_RequestBuffer__io_hasPfLateInMSHR_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_hasPfLateInMSHR_valid g=%h i=%h", cyc, g_RequestBuffer__io_hasPfLateInMSHR_valid, i_RequestBuffer__io_hasPfLateInMSHR_valid);
    end
    if (g_RequestBuffer__io_hasPfLateInMSHR_valid !== p_RequestBuffer__io_hasPfLateInMSHR_valid) t_RequestBuffer__io_hasPfLateInMSHR_valid = 1'b1;
    p_RequestBuffer__io_hasPfLateInMSHR_valid = g_RequestBuffer__io_hasPfLateInMSHR_valid;
    checks++;
    if (g_RequestBuffer__io_hasPfLateInMSHR_bits !== i_RequestBuffer__io_hasPfLateInMSHR_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_hasPfLateInMSHR_bits g=%h i=%h", cyc, g_RequestBuffer__io_hasPfLateInMSHR_bits, i_RequestBuffer__io_hasPfLateInMSHR_bits);
    end
    if (g_RequestBuffer__io_hasPfLateInMSHR_bits !== p_RequestBuffer__io_hasPfLateInMSHR_bits) t_RequestBuffer__io_hasPfLateInMSHR_bits = 1'b1;
    p_RequestBuffer__io_hasPfLateInMSHR_bits = g_RequestBuffer__io_hasPfLateInMSHR_bits;
    checks++;
    if (g_RequestBuffer__io_hasMergeA !== i_RequestBuffer__io_hasMergeA) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH RequestBuffer.io_hasMergeA g=%h i=%h", cyc, g_RequestBuffer__io_hasMergeA, i_RequestBuffer__io_hasMergeA);
    end
    if (g_RequestBuffer__io_hasMergeA !== p_RequestBuffer__io_hasMergeA) t_RequestBuffer__io_hasMergeA = 1'b1;
    p_RequestBuffer__io_hasMergeA = g_RequestBuffer__io_hasMergeA;
  endtask
  longint cov_RequestBuffer_flow = 0;
  longint cov_RequestBuffer_alloc = 0;
  longint cov_RequestBuffer_dup = 0;
  longint cov_RequestBuffer_mergeA = 0;
  longint cov_RequestBuffer_full = 0;
  longint cov_RequestBuffer_cancel = 0;
  longint cov_RequestBuffer_issue = 0;
  longint cov_RequestBuffer_noFreeWay = 0;
  task automatic cover_RequestBuffer();
    if (u_g_RequestBuffer.io_in_valid && u_g_RequestBuffer.doFlow) cov_RequestBuffer_flow++;
    if (u_g_RequestBuffer.alloc_probe) cov_RequestBuffer_alloc++;
    if (u_g_RequestBuffer._io_hasPfLateInMSHR_valid_T_probe) cov_RequestBuffer_dup++;
    if (u_g_RequestBuffer.io_aMergeTask_valid) cov_RequestBuffer_mergeA++;
    if (u_g_RequestBuffer.full_probe) cov_RequestBuffer_full++;
    if (u_g_RequestBuffer._GEN_5) cov_RequestBuffer_cancel++;
    if (u_g_RequestBuffer._GEN_16) cov_RequestBuffer_issue++;
    if (u_g_RequestBuffer.canFlow_sameSetCnt[4:3] != 2'h0) cov_RequestBuffer_noFreeWay++;
  endtask
  task automatic preinit_RequestBuffer();
  endtask
  task automatic sync_RequestBuffer();
    force u_i_RequestBuffer.chosenQ.u_core.ram = u_g_RequestBuffer.chosenQ.ram;
    #0 release u_i_RequestBuffer.chosenQ.u_core.ram;
    force u_i_RequestBuffer.u_core.hitPfPrev_set = u_g_RequestBuffer.io_hasHitPfInMSHR_valid_REG_set;
    #0 release u_i_RequestBuffer.u_core.hitPfPrev_set;
    force u_i_RequestBuffer.u_core.hitPfPrev_tag = u_g_RequestBuffer.io_hasHitPfInMSHR_valid_REG_tag;
    #0 release u_i_RequestBuffer.u_core.hitPfPrev_tag;
    force u_i_RequestBuffer.u_core.mergeAPrev_set = u_g_RequestBuffer.io_hasMergeA_REG_set;
    #0 release u_i_RequestBuffer.u_core.mergeAPrev_set;
    force u_i_RequestBuffer.u_core.mergeAPrev_tag = u_g_RequestBuffer.io_hasMergeA_REG_tag;
    #0 release u_i_RequestBuffer.u_core.mergeAPrev_tag;
    force u_i_RequestBuffer.u_core.sameSetS3Valid[0] = u_g_RequestBuffer.canFlow_sameSet_s3_REG;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Valid[0];
    force u_i_RequestBuffer.u_core.sameSetS3Set[0] = u_g_RequestBuffer.canFlow_sameSet_s3_r;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Set[0];
    force u_i_RequestBuffer.u_core.sameSetS3Valid[1] = u_g_RequestBuffer.buffer_rdy_sameSet_s3_REG;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Valid[1];
    force u_i_RequestBuffer.u_core.sameSetS3Set[1] = u_g_RequestBuffer.buffer_rdy_sameSet_s3_r;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Set[1];
    force u_i_RequestBuffer.u_core.sameSetS3Valid[2] = u_g_RequestBuffer.buffer_0_rdy_sameSet_s3_REG;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Valid[2];
    force u_i_RequestBuffer.u_core.sameSetS3Set[2] = u_g_RequestBuffer.buffer_0_rdy_sameSet_s3_r;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Set[2];
    force u_i_RequestBuffer.u_core.sameSetS3Valid[3] = u_g_RequestBuffer.buffer_1_rdy_sameSet_s3_REG;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Valid[3];
    force u_i_RequestBuffer.u_core.sameSetS3Set[3] = u_g_RequestBuffer.buffer_1_rdy_sameSet_s3_r;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Set[3];
    force u_i_RequestBuffer.u_core.sameSetS3Valid[4] = u_g_RequestBuffer.buffer_2_rdy_sameSet_s3_REG;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Valid[4];
    force u_i_RequestBuffer.u_core.sameSetS3Set[4] = u_g_RequestBuffer.buffer_2_rdy_sameSet_s3_r;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Set[4];
    force u_i_RequestBuffer.u_core.sameSetS3Valid[5] = u_g_RequestBuffer.buffer_3_rdy_sameSet_s3_REG;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Valid[5];
    force u_i_RequestBuffer.u_core.sameSetS3Set[5] = u_g_RequestBuffer.buffer_3_rdy_sameSet_s3_r;
    #0 release u_i_RequestBuffer.u_core.sameSetS3Set[5];
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_RequestBuffer();
    #1;
    preinit_RequestBuffer();
    sync_RequestBuffer();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_RequestBuffer();
      #1;
      check_RequestBuffer();
      cover_RequestBuffer();
    end
    begin int tg; tg = 0;
      if (t_RequestBuffer__io_in_ready) tg++; else $display("COV: RequestBuffer.io_in_ready never toggled");
      if (t_RequestBuffer__io_out_valid) tg++; else $display("COV: RequestBuffer.io_out_valid never toggled");
      if (t_RequestBuffer__io_out_bits_channel) tg++; else $display("COV: RequestBuffer.io_out_bits_channel never toggled");
      if (t_RequestBuffer__io_out_bits_txChannel) tg++; else $display("COV: RequestBuffer.io_out_bits_txChannel never toggled");
      if (t_RequestBuffer__io_out_bits_set) tg++; else $display("COV: RequestBuffer.io_out_bits_set never toggled");
      if (t_RequestBuffer__io_out_bits_tag) tg++; else $display("COV: RequestBuffer.io_out_bits_tag never toggled");
      if (t_RequestBuffer__io_out_bits_off) tg++; else $display("COV: RequestBuffer.io_out_bits_off never toggled");
      if (t_RequestBuffer__io_out_bits_alias) tg++; else $display("COV: RequestBuffer.io_out_bits_alias never toggled");
      if (t_RequestBuffer__io_out_bits_vaddr) tg++; else $display("COV: RequestBuffer.io_out_bits_vaddr never toggled");
      if (t_RequestBuffer__io_out_bits_isKeyword) tg++; else $display("COV: RequestBuffer.io_out_bits_isKeyword never toggled");
      if (t_RequestBuffer__io_out_bits_opcode) tg++; else $display("COV: RequestBuffer.io_out_bits_opcode never toggled");
      if (t_RequestBuffer__io_out_bits_param) tg++; else $display("COV: RequestBuffer.io_out_bits_param never toggled");
      if (t_RequestBuffer__io_out_bits_size) tg++; else $display("COV: RequestBuffer.io_out_bits_size never toggled");
      if (t_RequestBuffer__io_out_bits_sourceId) tg++; else $display("COV: RequestBuffer.io_out_bits_sourceId never toggled");
      if (t_RequestBuffer__io_out_bits_bufIdx) tg++; else $display("COV: RequestBuffer.io_out_bits_bufIdx never toggled");
      if (t_RequestBuffer__io_out_bits_needProbeAckData) tg++; else $display("COV: RequestBuffer.io_out_bits_needProbeAckData never toggled");
      if (t_RequestBuffer__io_out_bits_denied) tg++; else $display("COV: RequestBuffer.io_out_bits_denied never toggled");
      if (t_RequestBuffer__io_out_bits_corrupt) tg++; else $display("COV: RequestBuffer.io_out_bits_corrupt never toggled");
      if (t_RequestBuffer__io_out_bits_mshrTask) tg++; else $display("COV: RequestBuffer.io_out_bits_mshrTask never toggled");
      if (t_RequestBuffer__io_out_bits_mshrId) tg++; else $display("COV: RequestBuffer.io_out_bits_mshrId never toggled");
      if (t_RequestBuffer__io_out_bits_aliasTask) tg++; else $display("COV: RequestBuffer.io_out_bits_aliasTask never toggled");
      if (t_RequestBuffer__io_out_bits_useProbeData) tg++; else $display("COV: RequestBuffer.io_out_bits_useProbeData never toggled");
      if (t_RequestBuffer__io_out_bits_mshrRetry) tg++; else $display("COV: RequestBuffer.io_out_bits_mshrRetry never toggled");
      if (t_RequestBuffer__io_out_bits_readProbeDataDown) tg++; else $display("COV: RequestBuffer.io_out_bits_readProbeDataDown never toggled");
      if (t_RequestBuffer__io_out_bits_fromL2pft) tg++; else $display("COV: RequestBuffer.io_out_bits_fromL2pft never toggled");
      if (t_RequestBuffer__io_out_bits_needHint) tg++; else $display("COV: RequestBuffer.io_out_bits_needHint never toggled");
      if (t_RequestBuffer__io_out_bits_dirty) tg++; else $display("COV: RequestBuffer.io_out_bits_dirty never toggled");
      if (t_RequestBuffer__io_out_bits_way) tg++; else $display("COV: RequestBuffer.io_out_bits_way never toggled");
      if (t_RequestBuffer__io_out_bits_meta_dirty) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_dirty never toggled");
      if (t_RequestBuffer__io_out_bits_meta_state) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_state never toggled");
      if (t_RequestBuffer__io_out_bits_meta_clients) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_clients never toggled");
      if (t_RequestBuffer__io_out_bits_meta_alias) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_alias never toggled");
      if (t_RequestBuffer__io_out_bits_meta_prefetch) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_prefetch never toggled");
      if (t_RequestBuffer__io_out_bits_meta_prefetchSrc) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_prefetchSrc never toggled");
      if (t_RequestBuffer__io_out_bits_meta_accessed) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_accessed never toggled");
      if (t_RequestBuffer__io_out_bits_meta_tagErr) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_tagErr never toggled");
      if (t_RequestBuffer__io_out_bits_meta_dataErr) tg++; else $display("COV: RequestBuffer.io_out_bits_meta_dataErr never toggled");
      if (t_RequestBuffer__io_out_bits_metaWen) tg++; else $display("COV: RequestBuffer.io_out_bits_metaWen never toggled");
      if (t_RequestBuffer__io_out_bits_tagWen) tg++; else $display("COV: RequestBuffer.io_out_bits_tagWen never toggled");
      if (t_RequestBuffer__io_out_bits_dsWen) tg++; else $display("COV: RequestBuffer.io_out_bits_dsWen never toggled");
      if (t_RequestBuffer__io_out_bits_replTask) tg++; else $display("COV: RequestBuffer.io_out_bits_replTask never toggled");
      if (t_RequestBuffer__io_out_bits_cmoTask) tg++; else $display("COV: RequestBuffer.io_out_bits_cmoTask never toggled");
      if (t_RequestBuffer__io_out_bits_cmoAll) tg++; else $display("COV: RequestBuffer.io_out_bits_cmoAll never toggled");
      if (t_RequestBuffer__io_out_bits_reqSource) tg++; else $display("COV: RequestBuffer.io_out_bits_reqSource never toggled");
      if (t_RequestBuffer__io_out_bits_mergeA) tg++; else $display("COV: RequestBuffer.io_out_bits_mergeA never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_off) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_off never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_alias) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_alias never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_vaddr) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_vaddr never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_isKeyword) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_isKeyword never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_opcode) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_opcode never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_param) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_param never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_sourceId) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_sourceId never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_dirty) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_dirty never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_state) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_state never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_clients) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_clients never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_alias) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_alias never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_prefetch) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_prefetch never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_prefetchSrc) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_prefetchSrc never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_accessed) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_accessed never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_tagErr) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_tagErr never toggled");
      if (t_RequestBuffer__io_out_bits_aMergeTask_meta_dataErr) tg++; else $display("COV: RequestBuffer.io_out_bits_aMergeTask_meta_dataErr never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitRelease) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitRelease never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseToInval) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseToInval never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseToClean) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseToClean never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseWithData) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseWithData never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseIdx) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseIdx never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_dirty) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_dirty never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_state) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_state never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_clients) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_clients never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_alias) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_alias never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetch) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_prefetch never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_prefetchSrc) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_prefetchSrc never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_accessed) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_accessed never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_tagErr) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_tagErr never toggled");
      if (t_RequestBuffer__io_out_bits_snpHitReleaseMeta_dataErr) tg++; else $display("COV: RequestBuffer.io_out_bits_snpHitReleaseMeta_dataErr never toggled");
      if (t_RequestBuffer__io_out_bits_tgtID) tg++; else $display("COV: RequestBuffer.io_out_bits_tgtID never toggled");
      if (t_RequestBuffer__io_out_bits_srcID) tg++; else $display("COV: RequestBuffer.io_out_bits_srcID never toggled");
      if (t_RequestBuffer__io_out_bits_txnID) tg++; else $display("COV: RequestBuffer.io_out_bits_txnID never toggled");
      if (t_RequestBuffer__io_out_bits_homeNID) tg++; else $display("COV: RequestBuffer.io_out_bits_homeNID never toggled");
      if (t_RequestBuffer__io_out_bits_dbID) tg++; else $display("COV: RequestBuffer.io_out_bits_dbID never toggled");
      if (t_RequestBuffer__io_out_bits_fwdNID) tg++; else $display("COV: RequestBuffer.io_out_bits_fwdNID never toggled");
      if (t_RequestBuffer__io_out_bits_fwdTxnID) tg++; else $display("COV: RequestBuffer.io_out_bits_fwdTxnID never toggled");
      if (t_RequestBuffer__io_out_bits_chiOpcode) tg++; else $display("COV: RequestBuffer.io_out_bits_chiOpcode never toggled");
      if (t_RequestBuffer__io_out_bits_resp) tg++; else $display("COV: RequestBuffer.io_out_bits_resp never toggled");
      if (t_RequestBuffer__io_out_bits_fwdState) tg++; else $display("COV: RequestBuffer.io_out_bits_fwdState never toggled");
      if (t_RequestBuffer__io_out_bits_pCrdType) tg++; else $display("COV: RequestBuffer.io_out_bits_pCrdType never toggled");
      if (t_RequestBuffer__io_out_bits_retToSrc) tg++; else $display("COV: RequestBuffer.io_out_bits_retToSrc never toggled");
      if (t_RequestBuffer__io_out_bits_likelyshared) tg++; else $display("COV: RequestBuffer.io_out_bits_likelyshared never toggled");
      if (t_RequestBuffer__io_out_bits_expCompAck) tg++; else $display("COV: RequestBuffer.io_out_bits_expCompAck never toggled");
      if (t_RequestBuffer__io_out_bits_allowRetry) tg++; else $display("COV: RequestBuffer.io_out_bits_allowRetry never toggled");
      if (t_RequestBuffer__io_out_bits_memAttr_allocate) tg++; else $display("COV: RequestBuffer.io_out_bits_memAttr_allocate never toggled");
      if (t_RequestBuffer__io_out_bits_memAttr_cacheable) tg++; else $display("COV: RequestBuffer.io_out_bits_memAttr_cacheable never toggled");
      if (t_RequestBuffer__io_out_bits_memAttr_device) tg++; else $display("COV: RequestBuffer.io_out_bits_memAttr_device never toggled");
      if (t_RequestBuffer__io_out_bits_memAttr_ewa) tg++; else $display("COV: RequestBuffer.io_out_bits_memAttr_ewa never toggled");
      if (t_RequestBuffer__io_out_bits_traceTag) tg++; else $display("COV: RequestBuffer.io_out_bits_traceTag never toggled");
      if (t_RequestBuffer__io_aMergeTask_valid) tg++; else $display("COV: RequestBuffer.io_aMergeTask_valid never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_id) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_id never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_off) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_off never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_alias) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_alias never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_vaddr) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_vaddr never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_isKeyword) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_isKeyword never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_opcode) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_opcode never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_param) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_param never toggled");
      if (t_RequestBuffer__io_aMergeTask_bits_task_sourceId) tg++; else $display("COV: RequestBuffer.io_aMergeTask_bits_task_sourceId never toggled");
      if (t_RequestBuffer__io_ATag) tg++; else $display("COV: RequestBuffer.io_ATag never toggled");
      if (t_RequestBuffer__io_ASet) tg++; else $display("COV: RequestBuffer.io_ASet never toggled");
      if (t_RequestBuffer__io_hasHitPfInMSHR_valid) tg++; else $display("COV: RequestBuffer.io_hasHitPfInMSHR_valid never toggled");
      if (t_RequestBuffer__io_hasHitPfInMSHR_bits) tg++; else $display("COV: RequestBuffer.io_hasHitPfInMSHR_bits never toggled");
      if (t_RequestBuffer__io_hasPfLateInMSHR_valid) tg++; else $display("COV: RequestBuffer.io_hasPfLateInMSHR_valid never toggled");
      if (t_RequestBuffer__io_hasPfLateInMSHR_bits) tg++; else $display("COV: RequestBuffer.io_hasPfLateInMSHR_bits never toggled");
      if (t_RequestBuffer__io_hasMergeA) tg++; else $display("COV: RequestBuffer.io_hasMergeA never toggled");
      $display("RequestBuffer: toggled=%0d/111 (need >= 33)", tg);
      if (tg < 33) covfail = 1;
      $display("RequestBuffer: cover flow = %0d", cov_RequestBuffer_flow);
      if (cov_RequestBuffer_flow == 0) covfail = 1;
      $display("RequestBuffer: cover alloc = %0d", cov_RequestBuffer_alloc);
      if (cov_RequestBuffer_alloc == 0) covfail = 1;
      $display("RequestBuffer: cover dup = %0d", cov_RequestBuffer_dup);
      if (cov_RequestBuffer_dup == 0) covfail = 1;
      $display("RequestBuffer: cover mergeA = %0d", cov_RequestBuffer_mergeA);
      if (cov_RequestBuffer_mergeA == 0) covfail = 1;
      $display("RequestBuffer: cover full = %0d", cov_RequestBuffer_full);
      if (cov_RequestBuffer_full == 0) covfail = 1;
      $display("RequestBuffer: cover cancel = %0d", cov_RequestBuffer_cancel);
      if (cov_RequestBuffer_cancel == 0) covfail = 1;
      $display("RequestBuffer: cover issue = %0d", cov_RequestBuffer_issue);
      if (cov_RequestBuffer_issue == 0) covfail = 1;
      $display("RequestBuffer: cover noFreeWay = %0d", cov_RequestBuffer_noFreeWay);
      if (cov_RequestBuffer_noFreeWay == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
