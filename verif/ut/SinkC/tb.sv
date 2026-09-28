// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：SinkC
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

  // ======================= SinkC =======================
  logic SinkC__io_c_valid;
  logic [2:0] SinkC__io_c_bits_opcode;
  logic [2:0] SinkC__io_c_bits_param;
  logic [2:0] SinkC__io_c_bits_size;
  logic [6:0] SinkC__io_c_bits_source;
  logic [47:0] SinkC__io_c_bits_address;
  logic [255:0] SinkC__io_c_bits_data;
  logic SinkC__io_c_bits_corrupt;
  logic SinkC__io_task_ready;
  logic SinkC__io_msInfo_0_valid;
  logic [8:0] SinkC__io_msInfo_0_bits_set;
  logic [30:0] SinkC__io_msInfo_0_bits_reqTag;
  logic SinkC__io_msInfo_0_bits_blockRefill;
  logic SinkC__io_msInfo_1_valid;
  logic [8:0] SinkC__io_msInfo_1_bits_set;
  logic [30:0] SinkC__io_msInfo_1_bits_reqTag;
  logic SinkC__io_msInfo_1_bits_blockRefill;
  logic SinkC__io_msInfo_2_valid;
  logic [8:0] SinkC__io_msInfo_2_bits_set;
  logic [30:0] SinkC__io_msInfo_2_bits_reqTag;
  logic SinkC__io_msInfo_2_bits_blockRefill;
  logic SinkC__io_msInfo_3_valid;
  logic [8:0] SinkC__io_msInfo_3_bits_set;
  logic [30:0] SinkC__io_msInfo_3_bits_reqTag;
  logic SinkC__io_msInfo_3_bits_blockRefill;
  logic SinkC__io_msInfo_4_valid;
  logic [8:0] SinkC__io_msInfo_4_bits_set;
  logic [30:0] SinkC__io_msInfo_4_bits_reqTag;
  logic SinkC__io_msInfo_4_bits_blockRefill;
  logic SinkC__io_msInfo_5_valid;
  logic [8:0] SinkC__io_msInfo_5_bits_set;
  logic [30:0] SinkC__io_msInfo_5_bits_reqTag;
  logic SinkC__io_msInfo_5_bits_blockRefill;
  logic SinkC__io_msInfo_6_valid;
  logic [8:0] SinkC__io_msInfo_6_bits_set;
  logic [30:0] SinkC__io_msInfo_6_bits_reqTag;
  logic SinkC__io_msInfo_6_bits_blockRefill;
  logic SinkC__io_msInfo_7_valid;
  logic [8:0] SinkC__io_msInfo_7_bits_set;
  logic [30:0] SinkC__io_msInfo_7_bits_reqTag;
  logic SinkC__io_msInfo_7_bits_blockRefill;
  logic SinkC__io_msInfo_8_valid;
  logic [8:0] SinkC__io_msInfo_8_bits_set;
  logic [30:0] SinkC__io_msInfo_8_bits_reqTag;
  logic SinkC__io_msInfo_8_bits_blockRefill;
  logic SinkC__io_msInfo_9_valid;
  logic [8:0] SinkC__io_msInfo_9_bits_set;
  logic [30:0] SinkC__io_msInfo_9_bits_reqTag;
  logic SinkC__io_msInfo_9_bits_blockRefill;
  logic SinkC__io_msInfo_10_valid;
  logic [8:0] SinkC__io_msInfo_10_bits_set;
  logic [30:0] SinkC__io_msInfo_10_bits_reqTag;
  logic SinkC__io_msInfo_10_bits_blockRefill;
  logic SinkC__io_msInfo_11_valid;
  logic [8:0] SinkC__io_msInfo_11_bits_set;
  logic [30:0] SinkC__io_msInfo_11_bits_reqTag;
  logic SinkC__io_msInfo_11_bits_blockRefill;
  logic SinkC__io_msInfo_12_valid;
  logic [8:0] SinkC__io_msInfo_12_bits_set;
  logic [30:0] SinkC__io_msInfo_12_bits_reqTag;
  logic SinkC__io_msInfo_12_bits_blockRefill;
  logic SinkC__io_msInfo_13_valid;
  logic [8:0] SinkC__io_msInfo_13_bits_set;
  logic [30:0] SinkC__io_msInfo_13_bits_reqTag;
  logic SinkC__io_msInfo_13_bits_blockRefill;
  logic SinkC__io_msInfo_14_valid;
  logic [8:0] SinkC__io_msInfo_14_bits_set;
  logic [30:0] SinkC__io_msInfo_14_bits_reqTag;
  logic SinkC__io_msInfo_14_bits_blockRefill;
  logic SinkC__io_msInfo_15_valid;
  logic [8:0] SinkC__io_msInfo_15_bits_set;
  logic [30:0] SinkC__io_msInfo_15_bits_reqTag;
  logic SinkC__io_msInfo_15_bits_blockRefill;
  wire  g_SinkC__io_c_ready;
  wire  i_SinkC__io_c_ready;
  logic p_SinkC__io_c_ready;
  bit   t_SinkC__io_c_ready;
  wire  g_SinkC__io_task_valid;
  wire  i_SinkC__io_task_valid;
  logic p_SinkC__io_task_valid;
  bit   t_SinkC__io_task_valid;
  wire  [2:0] g_SinkC__io_task_bits_channel;
  wire  [2:0] i_SinkC__io_task_bits_channel;
  logic [2:0] p_SinkC__io_task_bits_channel;
  bit   t_SinkC__io_task_bits_channel;
  wire  [2:0] g_SinkC__io_task_bits_txChannel;
  wire  [2:0] i_SinkC__io_task_bits_txChannel;
  logic [2:0] p_SinkC__io_task_bits_txChannel;
  bit   t_SinkC__io_task_bits_txChannel;
  wire  [8:0] g_SinkC__io_task_bits_set;
  wire  [8:0] i_SinkC__io_task_bits_set;
  logic [8:0] p_SinkC__io_task_bits_set;
  bit   t_SinkC__io_task_bits_set;
  wire  [30:0] g_SinkC__io_task_bits_tag;
  wire  [30:0] i_SinkC__io_task_bits_tag;
  logic [30:0] p_SinkC__io_task_bits_tag;
  bit   t_SinkC__io_task_bits_tag;
  wire  [5:0] g_SinkC__io_task_bits_off;
  wire  [5:0] i_SinkC__io_task_bits_off;
  logic [5:0] p_SinkC__io_task_bits_off;
  bit   t_SinkC__io_task_bits_off;
  wire  [1:0] g_SinkC__io_task_bits_alias;
  wire  [1:0] i_SinkC__io_task_bits_alias;
  logic [1:0] p_SinkC__io_task_bits_alias;
  bit   t_SinkC__io_task_bits_alias;
  wire  [43:0] g_SinkC__io_task_bits_vaddr;
  wire  [43:0] i_SinkC__io_task_bits_vaddr;
  logic [43:0] p_SinkC__io_task_bits_vaddr;
  bit   t_SinkC__io_task_bits_vaddr;
  wire  g_SinkC__io_task_bits_isKeyword;
  wire  i_SinkC__io_task_bits_isKeyword;
  logic p_SinkC__io_task_bits_isKeyword;
  bit   t_SinkC__io_task_bits_isKeyword;
  wire  [3:0] g_SinkC__io_task_bits_opcode;
  wire  [3:0] i_SinkC__io_task_bits_opcode;
  logic [3:0] p_SinkC__io_task_bits_opcode;
  bit   t_SinkC__io_task_bits_opcode;
  wire  [2:0] g_SinkC__io_task_bits_param;
  wire  [2:0] i_SinkC__io_task_bits_param;
  logic [2:0] p_SinkC__io_task_bits_param;
  bit   t_SinkC__io_task_bits_param;
  wire  [2:0] g_SinkC__io_task_bits_size;
  wire  [2:0] i_SinkC__io_task_bits_size;
  logic [2:0] p_SinkC__io_task_bits_size;
  bit   t_SinkC__io_task_bits_size;
  wire  [6:0] g_SinkC__io_task_bits_sourceId;
  wire  [6:0] i_SinkC__io_task_bits_sourceId;
  logic [6:0] p_SinkC__io_task_bits_sourceId;
  bit   t_SinkC__io_task_bits_sourceId;
  wire  [1:0] g_SinkC__io_task_bits_bufIdx;
  wire  [1:0] i_SinkC__io_task_bits_bufIdx;
  logic [1:0] p_SinkC__io_task_bits_bufIdx;
  bit   t_SinkC__io_task_bits_bufIdx;
  wire  g_SinkC__io_task_bits_needProbeAckData;
  wire  i_SinkC__io_task_bits_needProbeAckData;
  logic p_SinkC__io_task_bits_needProbeAckData;
  bit   t_SinkC__io_task_bits_needProbeAckData;
  wire  g_SinkC__io_task_bits_denied;
  wire  i_SinkC__io_task_bits_denied;
  logic p_SinkC__io_task_bits_denied;
  bit   t_SinkC__io_task_bits_denied;
  wire  g_SinkC__io_task_bits_corrupt;
  wire  i_SinkC__io_task_bits_corrupt;
  logic p_SinkC__io_task_bits_corrupt;
  bit   t_SinkC__io_task_bits_corrupt;
  wire  g_SinkC__io_task_bits_mshrTask;
  wire  i_SinkC__io_task_bits_mshrTask;
  logic p_SinkC__io_task_bits_mshrTask;
  bit   t_SinkC__io_task_bits_mshrTask;
  wire  [7:0] g_SinkC__io_task_bits_mshrId;
  wire  [7:0] i_SinkC__io_task_bits_mshrId;
  logic [7:0] p_SinkC__io_task_bits_mshrId;
  bit   t_SinkC__io_task_bits_mshrId;
  wire  g_SinkC__io_task_bits_aliasTask;
  wire  i_SinkC__io_task_bits_aliasTask;
  logic p_SinkC__io_task_bits_aliasTask;
  bit   t_SinkC__io_task_bits_aliasTask;
  wire  g_SinkC__io_task_bits_useProbeData;
  wire  i_SinkC__io_task_bits_useProbeData;
  logic p_SinkC__io_task_bits_useProbeData;
  bit   t_SinkC__io_task_bits_useProbeData;
  wire  g_SinkC__io_task_bits_mshrRetry;
  wire  i_SinkC__io_task_bits_mshrRetry;
  logic p_SinkC__io_task_bits_mshrRetry;
  bit   t_SinkC__io_task_bits_mshrRetry;
  wire  g_SinkC__io_task_bits_readProbeDataDown;
  wire  i_SinkC__io_task_bits_readProbeDataDown;
  logic p_SinkC__io_task_bits_readProbeDataDown;
  bit   t_SinkC__io_task_bits_readProbeDataDown;
  wire  g_SinkC__io_task_bits_fromL2pft;
  wire  i_SinkC__io_task_bits_fromL2pft;
  logic p_SinkC__io_task_bits_fromL2pft;
  bit   t_SinkC__io_task_bits_fromL2pft;
  wire  g_SinkC__io_task_bits_needHint;
  wire  i_SinkC__io_task_bits_needHint;
  logic p_SinkC__io_task_bits_needHint;
  bit   t_SinkC__io_task_bits_needHint;
  wire  g_SinkC__io_task_bits_dirty;
  wire  i_SinkC__io_task_bits_dirty;
  logic p_SinkC__io_task_bits_dirty;
  bit   t_SinkC__io_task_bits_dirty;
  wire  [2:0] g_SinkC__io_task_bits_way;
  wire  [2:0] i_SinkC__io_task_bits_way;
  logic [2:0] p_SinkC__io_task_bits_way;
  bit   t_SinkC__io_task_bits_way;
  wire  g_SinkC__io_task_bits_meta_dirty;
  wire  i_SinkC__io_task_bits_meta_dirty;
  logic p_SinkC__io_task_bits_meta_dirty;
  bit   t_SinkC__io_task_bits_meta_dirty;
  wire  [1:0] g_SinkC__io_task_bits_meta_state;
  wire  [1:0] i_SinkC__io_task_bits_meta_state;
  logic [1:0] p_SinkC__io_task_bits_meta_state;
  bit   t_SinkC__io_task_bits_meta_state;
  wire  g_SinkC__io_task_bits_meta_clients;
  wire  i_SinkC__io_task_bits_meta_clients;
  logic p_SinkC__io_task_bits_meta_clients;
  bit   t_SinkC__io_task_bits_meta_clients;
  wire  [1:0] g_SinkC__io_task_bits_meta_alias;
  wire  [1:0] i_SinkC__io_task_bits_meta_alias;
  logic [1:0] p_SinkC__io_task_bits_meta_alias;
  bit   t_SinkC__io_task_bits_meta_alias;
  wire  g_SinkC__io_task_bits_meta_prefetch;
  wire  i_SinkC__io_task_bits_meta_prefetch;
  logic p_SinkC__io_task_bits_meta_prefetch;
  bit   t_SinkC__io_task_bits_meta_prefetch;
  wire  [2:0] g_SinkC__io_task_bits_meta_prefetchSrc;
  wire  [2:0] i_SinkC__io_task_bits_meta_prefetchSrc;
  logic [2:0] p_SinkC__io_task_bits_meta_prefetchSrc;
  bit   t_SinkC__io_task_bits_meta_prefetchSrc;
  wire  g_SinkC__io_task_bits_meta_accessed;
  wire  i_SinkC__io_task_bits_meta_accessed;
  logic p_SinkC__io_task_bits_meta_accessed;
  bit   t_SinkC__io_task_bits_meta_accessed;
  wire  g_SinkC__io_task_bits_meta_tagErr;
  wire  i_SinkC__io_task_bits_meta_tagErr;
  logic p_SinkC__io_task_bits_meta_tagErr;
  bit   t_SinkC__io_task_bits_meta_tagErr;
  wire  g_SinkC__io_task_bits_meta_dataErr;
  wire  i_SinkC__io_task_bits_meta_dataErr;
  logic p_SinkC__io_task_bits_meta_dataErr;
  bit   t_SinkC__io_task_bits_meta_dataErr;
  wire  g_SinkC__io_task_bits_metaWen;
  wire  i_SinkC__io_task_bits_metaWen;
  logic p_SinkC__io_task_bits_metaWen;
  bit   t_SinkC__io_task_bits_metaWen;
  wire  g_SinkC__io_task_bits_tagWen;
  wire  i_SinkC__io_task_bits_tagWen;
  logic p_SinkC__io_task_bits_tagWen;
  bit   t_SinkC__io_task_bits_tagWen;
  wire  g_SinkC__io_task_bits_dsWen;
  wire  i_SinkC__io_task_bits_dsWen;
  logic p_SinkC__io_task_bits_dsWen;
  bit   t_SinkC__io_task_bits_dsWen;
  wire  [7:0] g_SinkC__io_task_bits_wayMask;
  wire  [7:0] i_SinkC__io_task_bits_wayMask;
  logic [7:0] p_SinkC__io_task_bits_wayMask;
  bit   t_SinkC__io_task_bits_wayMask;
  wire  g_SinkC__io_task_bits_replTask;
  wire  i_SinkC__io_task_bits_replTask;
  logic p_SinkC__io_task_bits_replTask;
  bit   t_SinkC__io_task_bits_replTask;
  wire  g_SinkC__io_task_bits_cmoTask;
  wire  i_SinkC__io_task_bits_cmoTask;
  logic p_SinkC__io_task_bits_cmoTask;
  bit   t_SinkC__io_task_bits_cmoTask;
  wire  g_SinkC__io_task_bits_cmoAll;
  wire  i_SinkC__io_task_bits_cmoAll;
  logic p_SinkC__io_task_bits_cmoAll;
  bit   t_SinkC__io_task_bits_cmoAll;
  wire  [4:0] g_SinkC__io_task_bits_reqSource;
  wire  [4:0] i_SinkC__io_task_bits_reqSource;
  logic [4:0] p_SinkC__io_task_bits_reqSource;
  bit   t_SinkC__io_task_bits_reqSource;
  wire  g_SinkC__io_task_bits_mergeA;
  wire  i_SinkC__io_task_bits_mergeA;
  logic p_SinkC__io_task_bits_mergeA;
  bit   t_SinkC__io_task_bits_mergeA;
  wire  [5:0] g_SinkC__io_task_bits_aMergeTask_off;
  wire  [5:0] i_SinkC__io_task_bits_aMergeTask_off;
  logic [5:0] p_SinkC__io_task_bits_aMergeTask_off;
  bit   t_SinkC__io_task_bits_aMergeTask_off;
  wire  [1:0] g_SinkC__io_task_bits_aMergeTask_alias;
  wire  [1:0] i_SinkC__io_task_bits_aMergeTask_alias;
  logic [1:0] p_SinkC__io_task_bits_aMergeTask_alias;
  bit   t_SinkC__io_task_bits_aMergeTask_alias;
  wire  [43:0] g_SinkC__io_task_bits_aMergeTask_vaddr;
  wire  [43:0] i_SinkC__io_task_bits_aMergeTask_vaddr;
  logic [43:0] p_SinkC__io_task_bits_aMergeTask_vaddr;
  bit   t_SinkC__io_task_bits_aMergeTask_vaddr;
  wire  g_SinkC__io_task_bits_aMergeTask_isKeyword;
  wire  i_SinkC__io_task_bits_aMergeTask_isKeyword;
  logic p_SinkC__io_task_bits_aMergeTask_isKeyword;
  bit   t_SinkC__io_task_bits_aMergeTask_isKeyword;
  wire  [2:0] g_SinkC__io_task_bits_aMergeTask_opcode;
  wire  [2:0] i_SinkC__io_task_bits_aMergeTask_opcode;
  logic [2:0] p_SinkC__io_task_bits_aMergeTask_opcode;
  bit   t_SinkC__io_task_bits_aMergeTask_opcode;
  wire  [2:0] g_SinkC__io_task_bits_aMergeTask_param;
  wire  [2:0] i_SinkC__io_task_bits_aMergeTask_param;
  logic [2:0] p_SinkC__io_task_bits_aMergeTask_param;
  bit   t_SinkC__io_task_bits_aMergeTask_param;
  wire  [6:0] g_SinkC__io_task_bits_aMergeTask_sourceId;
  wire  [6:0] i_SinkC__io_task_bits_aMergeTask_sourceId;
  logic [6:0] p_SinkC__io_task_bits_aMergeTask_sourceId;
  bit   t_SinkC__io_task_bits_aMergeTask_sourceId;
  wire  g_SinkC__io_task_bits_aMergeTask_meta_dirty;
  wire  i_SinkC__io_task_bits_aMergeTask_meta_dirty;
  logic p_SinkC__io_task_bits_aMergeTask_meta_dirty;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_dirty;
  wire  [1:0] g_SinkC__io_task_bits_aMergeTask_meta_state;
  wire  [1:0] i_SinkC__io_task_bits_aMergeTask_meta_state;
  logic [1:0] p_SinkC__io_task_bits_aMergeTask_meta_state;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_state;
  wire  g_SinkC__io_task_bits_aMergeTask_meta_clients;
  wire  i_SinkC__io_task_bits_aMergeTask_meta_clients;
  logic p_SinkC__io_task_bits_aMergeTask_meta_clients;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_clients;
  wire  [1:0] g_SinkC__io_task_bits_aMergeTask_meta_alias;
  wire  [1:0] i_SinkC__io_task_bits_aMergeTask_meta_alias;
  logic [1:0] p_SinkC__io_task_bits_aMergeTask_meta_alias;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_alias;
  wire  g_SinkC__io_task_bits_aMergeTask_meta_prefetch;
  wire  i_SinkC__io_task_bits_aMergeTask_meta_prefetch;
  logic p_SinkC__io_task_bits_aMergeTask_meta_prefetch;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_prefetch;
  wire  [2:0] g_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc;
  wire  [2:0] i_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc;
  logic [2:0] p_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc;
  wire  g_SinkC__io_task_bits_aMergeTask_meta_accessed;
  wire  i_SinkC__io_task_bits_aMergeTask_meta_accessed;
  logic p_SinkC__io_task_bits_aMergeTask_meta_accessed;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_accessed;
  wire  g_SinkC__io_task_bits_aMergeTask_meta_tagErr;
  wire  i_SinkC__io_task_bits_aMergeTask_meta_tagErr;
  logic p_SinkC__io_task_bits_aMergeTask_meta_tagErr;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_tagErr;
  wire  g_SinkC__io_task_bits_aMergeTask_meta_dataErr;
  wire  i_SinkC__io_task_bits_aMergeTask_meta_dataErr;
  logic p_SinkC__io_task_bits_aMergeTask_meta_dataErr;
  bit   t_SinkC__io_task_bits_aMergeTask_meta_dataErr;
  wire  g_SinkC__io_task_bits_snpHitRelease;
  wire  i_SinkC__io_task_bits_snpHitRelease;
  logic p_SinkC__io_task_bits_snpHitRelease;
  bit   t_SinkC__io_task_bits_snpHitRelease;
  wire  g_SinkC__io_task_bits_snpHitReleaseToInval;
  wire  i_SinkC__io_task_bits_snpHitReleaseToInval;
  logic p_SinkC__io_task_bits_snpHitReleaseToInval;
  bit   t_SinkC__io_task_bits_snpHitReleaseToInval;
  wire  g_SinkC__io_task_bits_snpHitReleaseToClean;
  wire  i_SinkC__io_task_bits_snpHitReleaseToClean;
  logic p_SinkC__io_task_bits_snpHitReleaseToClean;
  bit   t_SinkC__io_task_bits_snpHitReleaseToClean;
  wire  g_SinkC__io_task_bits_snpHitReleaseWithData;
  wire  i_SinkC__io_task_bits_snpHitReleaseWithData;
  logic p_SinkC__io_task_bits_snpHitReleaseWithData;
  bit   t_SinkC__io_task_bits_snpHitReleaseWithData;
  wire  [7:0] g_SinkC__io_task_bits_snpHitReleaseIdx;
  wire  [7:0] i_SinkC__io_task_bits_snpHitReleaseIdx;
  logic [7:0] p_SinkC__io_task_bits_snpHitReleaseIdx;
  bit   t_SinkC__io_task_bits_snpHitReleaseIdx;
  wire  g_SinkC__io_task_bits_snpHitReleaseMeta_dirty;
  wire  i_SinkC__io_task_bits_snpHitReleaseMeta_dirty;
  logic p_SinkC__io_task_bits_snpHitReleaseMeta_dirty;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_dirty;
  wire  [1:0] g_SinkC__io_task_bits_snpHitReleaseMeta_state;
  wire  [1:0] i_SinkC__io_task_bits_snpHitReleaseMeta_state;
  logic [1:0] p_SinkC__io_task_bits_snpHitReleaseMeta_state;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_state;
  wire  g_SinkC__io_task_bits_snpHitReleaseMeta_clients;
  wire  i_SinkC__io_task_bits_snpHitReleaseMeta_clients;
  logic p_SinkC__io_task_bits_snpHitReleaseMeta_clients;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_clients;
  wire  [1:0] g_SinkC__io_task_bits_snpHitReleaseMeta_alias;
  wire  [1:0] i_SinkC__io_task_bits_snpHitReleaseMeta_alias;
  logic [1:0] p_SinkC__io_task_bits_snpHitReleaseMeta_alias;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_alias;
  wire  g_SinkC__io_task_bits_snpHitReleaseMeta_prefetch;
  wire  i_SinkC__io_task_bits_snpHitReleaseMeta_prefetch;
  logic p_SinkC__io_task_bits_snpHitReleaseMeta_prefetch;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_prefetch;
  wire  [2:0] g_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  wire  [2:0] i_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] p_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc;
  wire  g_SinkC__io_task_bits_snpHitReleaseMeta_accessed;
  wire  i_SinkC__io_task_bits_snpHitReleaseMeta_accessed;
  logic p_SinkC__io_task_bits_snpHitReleaseMeta_accessed;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_accessed;
  wire  g_SinkC__io_task_bits_snpHitReleaseMeta_tagErr;
  wire  i_SinkC__io_task_bits_snpHitReleaseMeta_tagErr;
  logic p_SinkC__io_task_bits_snpHitReleaseMeta_tagErr;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_tagErr;
  wire  g_SinkC__io_task_bits_snpHitReleaseMeta_dataErr;
  wire  i_SinkC__io_task_bits_snpHitReleaseMeta_dataErr;
  logic p_SinkC__io_task_bits_snpHitReleaseMeta_dataErr;
  bit   t_SinkC__io_task_bits_snpHitReleaseMeta_dataErr;
  wire  [10:0] g_SinkC__io_task_bits_tgtID;
  wire  [10:0] i_SinkC__io_task_bits_tgtID;
  logic [10:0] p_SinkC__io_task_bits_tgtID;
  bit   t_SinkC__io_task_bits_tgtID;
  wire  [10:0] g_SinkC__io_task_bits_srcID;
  wire  [10:0] i_SinkC__io_task_bits_srcID;
  logic [10:0] p_SinkC__io_task_bits_srcID;
  bit   t_SinkC__io_task_bits_srcID;
  wire  [11:0] g_SinkC__io_task_bits_txnID;
  wire  [11:0] i_SinkC__io_task_bits_txnID;
  logic [11:0] p_SinkC__io_task_bits_txnID;
  bit   t_SinkC__io_task_bits_txnID;
  wire  [10:0] g_SinkC__io_task_bits_homeNID;
  wire  [10:0] i_SinkC__io_task_bits_homeNID;
  logic [10:0] p_SinkC__io_task_bits_homeNID;
  bit   t_SinkC__io_task_bits_homeNID;
  wire  [11:0] g_SinkC__io_task_bits_dbID;
  wire  [11:0] i_SinkC__io_task_bits_dbID;
  logic [11:0] p_SinkC__io_task_bits_dbID;
  bit   t_SinkC__io_task_bits_dbID;
  wire  [10:0] g_SinkC__io_task_bits_fwdNID;
  wire  [10:0] i_SinkC__io_task_bits_fwdNID;
  logic [10:0] p_SinkC__io_task_bits_fwdNID;
  bit   t_SinkC__io_task_bits_fwdNID;
  wire  [11:0] g_SinkC__io_task_bits_fwdTxnID;
  wire  [11:0] i_SinkC__io_task_bits_fwdTxnID;
  logic [11:0] p_SinkC__io_task_bits_fwdTxnID;
  bit   t_SinkC__io_task_bits_fwdTxnID;
  wire  [6:0] g_SinkC__io_task_bits_chiOpcode;
  wire  [6:0] i_SinkC__io_task_bits_chiOpcode;
  logic [6:0] p_SinkC__io_task_bits_chiOpcode;
  bit   t_SinkC__io_task_bits_chiOpcode;
  wire  [2:0] g_SinkC__io_task_bits_resp;
  wire  [2:0] i_SinkC__io_task_bits_resp;
  logic [2:0] p_SinkC__io_task_bits_resp;
  bit   t_SinkC__io_task_bits_resp;
  wire  [2:0] g_SinkC__io_task_bits_fwdState;
  wire  [2:0] i_SinkC__io_task_bits_fwdState;
  logic [2:0] p_SinkC__io_task_bits_fwdState;
  bit   t_SinkC__io_task_bits_fwdState;
  wire  [3:0] g_SinkC__io_task_bits_pCrdType;
  wire  [3:0] i_SinkC__io_task_bits_pCrdType;
  logic [3:0] p_SinkC__io_task_bits_pCrdType;
  bit   t_SinkC__io_task_bits_pCrdType;
  wire  g_SinkC__io_task_bits_retToSrc;
  wire  i_SinkC__io_task_bits_retToSrc;
  logic p_SinkC__io_task_bits_retToSrc;
  bit   t_SinkC__io_task_bits_retToSrc;
  wire  g_SinkC__io_task_bits_likelyshared;
  wire  i_SinkC__io_task_bits_likelyshared;
  logic p_SinkC__io_task_bits_likelyshared;
  bit   t_SinkC__io_task_bits_likelyshared;
  wire  g_SinkC__io_task_bits_expCompAck;
  wire  i_SinkC__io_task_bits_expCompAck;
  logic p_SinkC__io_task_bits_expCompAck;
  bit   t_SinkC__io_task_bits_expCompAck;
  wire  g_SinkC__io_task_bits_allowRetry;
  wire  i_SinkC__io_task_bits_allowRetry;
  logic p_SinkC__io_task_bits_allowRetry;
  bit   t_SinkC__io_task_bits_allowRetry;
  wire  g_SinkC__io_task_bits_memAttr_allocate;
  wire  i_SinkC__io_task_bits_memAttr_allocate;
  logic p_SinkC__io_task_bits_memAttr_allocate;
  bit   t_SinkC__io_task_bits_memAttr_allocate;
  wire  g_SinkC__io_task_bits_memAttr_cacheable;
  wire  i_SinkC__io_task_bits_memAttr_cacheable;
  logic p_SinkC__io_task_bits_memAttr_cacheable;
  bit   t_SinkC__io_task_bits_memAttr_cacheable;
  wire  g_SinkC__io_task_bits_memAttr_device;
  wire  i_SinkC__io_task_bits_memAttr_device;
  logic p_SinkC__io_task_bits_memAttr_device;
  bit   t_SinkC__io_task_bits_memAttr_device;
  wire  g_SinkC__io_task_bits_memAttr_ewa;
  wire  i_SinkC__io_task_bits_memAttr_ewa;
  logic p_SinkC__io_task_bits_memAttr_ewa;
  bit   t_SinkC__io_task_bits_memAttr_ewa;
  wire  g_SinkC__io_task_bits_traceTag;
  wire  i_SinkC__io_task_bits_traceTag;
  logic p_SinkC__io_task_bits_traceTag;
  bit   t_SinkC__io_task_bits_traceTag;
  wire  g_SinkC__io_resp_valid;
  wire  i_SinkC__io_resp_valid;
  logic p_SinkC__io_resp_valid;
  bit   t_SinkC__io_resp_valid;
  wire  [8:0] g_SinkC__io_resp_set;
  wire  [8:0] i_SinkC__io_resp_set;
  logic [8:0] p_SinkC__io_resp_set;
  bit   t_SinkC__io_resp_set;
  wire  [30:0] g_SinkC__io_resp_tag;
  wire  [30:0] i_SinkC__io_resp_tag;
  logic [30:0] p_SinkC__io_resp_tag;
  bit   t_SinkC__io_resp_tag;
  wire  [2:0] g_SinkC__io_resp_respInfo_opcode;
  wire  [2:0] i_SinkC__io_resp_respInfo_opcode;
  logic [2:0] p_SinkC__io_resp_respInfo_opcode;
  bit   t_SinkC__io_resp_respInfo_opcode;
  wire  [2:0] g_SinkC__io_resp_respInfo_param;
  wire  [2:0] i_SinkC__io_resp_respInfo_param;
  logic [2:0] p_SinkC__io_resp_respInfo_param;
  bit   t_SinkC__io_resp_respInfo_param;
  wire  g_SinkC__io_resp_respInfo_last;
  wire  i_SinkC__io_resp_respInfo_last;
  logic p_SinkC__io_resp_respInfo_last;
  bit   t_SinkC__io_resp_respInfo_last;
  wire  g_SinkC__io_resp_respInfo_denied;
  wire  i_SinkC__io_resp_respInfo_denied;
  logic p_SinkC__io_resp_respInfo_denied;
  bit   t_SinkC__io_resp_respInfo_denied;
  wire  g_SinkC__io_resp_respInfo_corrupt;
  wire  i_SinkC__io_resp_respInfo_corrupt;
  logic p_SinkC__io_resp_respInfo_corrupt;
  bit   t_SinkC__io_resp_respInfo_corrupt;
  wire  g_SinkC__io_releaseBufWrite_valid;
  wire  i_SinkC__io_releaseBufWrite_valid;
  logic p_SinkC__io_releaseBufWrite_valid;
  bit   t_SinkC__io_releaseBufWrite_valid;
  wire  [511:0] g_SinkC__io_releaseBufWrite_bits_data_data;
  wire  [511:0] i_SinkC__io_releaseBufWrite_bits_data_data;
  logic [511:0] p_SinkC__io_releaseBufWrite_bits_data_data;
  bit   t_SinkC__io_releaseBufWrite_bits_data_data;
  wire  [255:0] g_SinkC__io_bufResp_data_0;
  wire  [255:0] i_SinkC__io_bufResp_data_0;
  logic [255:0] p_SinkC__io_bufResp_data_0;
  bit   t_SinkC__io_bufResp_data_0;
  wire  [255:0] g_SinkC__io_bufResp_data_1;
  wire  [255:0] i_SinkC__io_bufResp_data_1;
  logic [255:0] p_SinkC__io_bufResp_data_1;
  bit   t_SinkC__io_bufResp_data_1;
  wire  g_SinkC__io_refillBufWrite_valid;
  wire  i_SinkC__io_refillBufWrite_valid;
  logic p_SinkC__io_refillBufWrite_valid;
  bit   t_SinkC__io_refillBufWrite_valid;
  wire  [7:0] g_SinkC__io_refillBufWrite_bits_id;
  wire  [7:0] i_SinkC__io_refillBufWrite_bits_id;
  logic [7:0] p_SinkC__io_refillBufWrite_bits_id;
  bit   t_SinkC__io_refillBufWrite_bits_id;
  wire  [511:0] g_SinkC__io_refillBufWrite_bits_data_data;
  wire  [511:0] i_SinkC__io_refillBufWrite_bits_data_data;
  logic [511:0] p_SinkC__io_refillBufWrite_bits_data_data;
  bit   t_SinkC__io_refillBufWrite_bits_data_data;
  SinkC u_g_SinkC (
    .clock (clock),
    .reset (reset),
    .io_c_ready (g_SinkC__io_c_ready),
    .io_c_valid (SinkC__io_c_valid),
    .io_c_bits_opcode (SinkC__io_c_bits_opcode),
    .io_c_bits_param (SinkC__io_c_bits_param),
    .io_c_bits_size (SinkC__io_c_bits_size),
    .io_c_bits_source (SinkC__io_c_bits_source),
    .io_c_bits_address (SinkC__io_c_bits_address),
    .io_c_bits_data (SinkC__io_c_bits_data),
    .io_c_bits_corrupt (SinkC__io_c_bits_corrupt),
    .io_task_ready (SinkC__io_task_ready),
    .io_task_valid (g_SinkC__io_task_valid),
    .io_task_bits_channel (g_SinkC__io_task_bits_channel),
    .io_task_bits_txChannel (g_SinkC__io_task_bits_txChannel),
    .io_task_bits_set (g_SinkC__io_task_bits_set),
    .io_task_bits_tag (g_SinkC__io_task_bits_tag),
    .io_task_bits_off (g_SinkC__io_task_bits_off),
    .io_task_bits_alias (g_SinkC__io_task_bits_alias),
    .io_task_bits_vaddr (g_SinkC__io_task_bits_vaddr),
    .io_task_bits_isKeyword (g_SinkC__io_task_bits_isKeyword),
    .io_task_bits_opcode (g_SinkC__io_task_bits_opcode),
    .io_task_bits_param (g_SinkC__io_task_bits_param),
    .io_task_bits_size (g_SinkC__io_task_bits_size),
    .io_task_bits_sourceId (g_SinkC__io_task_bits_sourceId),
    .io_task_bits_bufIdx (g_SinkC__io_task_bits_bufIdx),
    .io_task_bits_needProbeAckData (g_SinkC__io_task_bits_needProbeAckData),
    .io_task_bits_denied (g_SinkC__io_task_bits_denied),
    .io_task_bits_corrupt (g_SinkC__io_task_bits_corrupt),
    .io_task_bits_mshrTask (g_SinkC__io_task_bits_mshrTask),
    .io_task_bits_mshrId (g_SinkC__io_task_bits_mshrId),
    .io_task_bits_aliasTask (g_SinkC__io_task_bits_aliasTask),
    .io_task_bits_useProbeData (g_SinkC__io_task_bits_useProbeData),
    .io_task_bits_mshrRetry (g_SinkC__io_task_bits_mshrRetry),
    .io_task_bits_readProbeDataDown (g_SinkC__io_task_bits_readProbeDataDown),
    .io_task_bits_fromL2pft (g_SinkC__io_task_bits_fromL2pft),
    .io_task_bits_needHint (g_SinkC__io_task_bits_needHint),
    .io_task_bits_dirty (g_SinkC__io_task_bits_dirty),
    .io_task_bits_way (g_SinkC__io_task_bits_way),
    .io_task_bits_meta_dirty (g_SinkC__io_task_bits_meta_dirty),
    .io_task_bits_meta_state (g_SinkC__io_task_bits_meta_state),
    .io_task_bits_meta_clients (g_SinkC__io_task_bits_meta_clients),
    .io_task_bits_meta_alias (g_SinkC__io_task_bits_meta_alias),
    .io_task_bits_meta_prefetch (g_SinkC__io_task_bits_meta_prefetch),
    .io_task_bits_meta_prefetchSrc (g_SinkC__io_task_bits_meta_prefetchSrc),
    .io_task_bits_meta_accessed (g_SinkC__io_task_bits_meta_accessed),
    .io_task_bits_meta_tagErr (g_SinkC__io_task_bits_meta_tagErr),
    .io_task_bits_meta_dataErr (g_SinkC__io_task_bits_meta_dataErr),
    .io_task_bits_metaWen (g_SinkC__io_task_bits_metaWen),
    .io_task_bits_tagWen (g_SinkC__io_task_bits_tagWen),
    .io_task_bits_dsWen (g_SinkC__io_task_bits_dsWen),
    .io_task_bits_wayMask (g_SinkC__io_task_bits_wayMask),
    .io_task_bits_replTask (g_SinkC__io_task_bits_replTask),
    .io_task_bits_cmoTask (g_SinkC__io_task_bits_cmoTask),
    .io_task_bits_cmoAll (g_SinkC__io_task_bits_cmoAll),
    .io_task_bits_reqSource (g_SinkC__io_task_bits_reqSource),
    .io_task_bits_mergeA (g_SinkC__io_task_bits_mergeA),
    .io_task_bits_aMergeTask_off (g_SinkC__io_task_bits_aMergeTask_off),
    .io_task_bits_aMergeTask_alias (g_SinkC__io_task_bits_aMergeTask_alias),
    .io_task_bits_aMergeTask_vaddr (g_SinkC__io_task_bits_aMergeTask_vaddr),
    .io_task_bits_aMergeTask_isKeyword (g_SinkC__io_task_bits_aMergeTask_isKeyword),
    .io_task_bits_aMergeTask_opcode (g_SinkC__io_task_bits_aMergeTask_opcode),
    .io_task_bits_aMergeTask_param (g_SinkC__io_task_bits_aMergeTask_param),
    .io_task_bits_aMergeTask_sourceId (g_SinkC__io_task_bits_aMergeTask_sourceId),
    .io_task_bits_aMergeTask_meta_dirty (g_SinkC__io_task_bits_aMergeTask_meta_dirty),
    .io_task_bits_aMergeTask_meta_state (g_SinkC__io_task_bits_aMergeTask_meta_state),
    .io_task_bits_aMergeTask_meta_clients (g_SinkC__io_task_bits_aMergeTask_meta_clients),
    .io_task_bits_aMergeTask_meta_alias (g_SinkC__io_task_bits_aMergeTask_meta_alias),
    .io_task_bits_aMergeTask_meta_prefetch (g_SinkC__io_task_bits_aMergeTask_meta_prefetch),
    .io_task_bits_aMergeTask_meta_prefetchSrc (g_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc),
    .io_task_bits_aMergeTask_meta_accessed (g_SinkC__io_task_bits_aMergeTask_meta_accessed),
    .io_task_bits_aMergeTask_meta_tagErr (g_SinkC__io_task_bits_aMergeTask_meta_tagErr),
    .io_task_bits_aMergeTask_meta_dataErr (g_SinkC__io_task_bits_aMergeTask_meta_dataErr),
    .io_task_bits_snpHitRelease (g_SinkC__io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval (g_SinkC__io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean (g_SinkC__io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData (g_SinkC__io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx (g_SinkC__io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty (g_SinkC__io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state (g_SinkC__io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients (g_SinkC__io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias (g_SinkC__io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch (g_SinkC__io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc (g_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed (g_SinkC__io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr (g_SinkC__io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr (g_SinkC__io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_tgtID (g_SinkC__io_task_bits_tgtID),
    .io_task_bits_srcID (g_SinkC__io_task_bits_srcID),
    .io_task_bits_txnID (g_SinkC__io_task_bits_txnID),
    .io_task_bits_homeNID (g_SinkC__io_task_bits_homeNID),
    .io_task_bits_dbID (g_SinkC__io_task_bits_dbID),
    .io_task_bits_fwdNID (g_SinkC__io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID (g_SinkC__io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode (g_SinkC__io_task_bits_chiOpcode),
    .io_task_bits_resp (g_SinkC__io_task_bits_resp),
    .io_task_bits_fwdState (g_SinkC__io_task_bits_fwdState),
    .io_task_bits_pCrdType (g_SinkC__io_task_bits_pCrdType),
    .io_task_bits_retToSrc (g_SinkC__io_task_bits_retToSrc),
    .io_task_bits_likelyshared (g_SinkC__io_task_bits_likelyshared),
    .io_task_bits_expCompAck (g_SinkC__io_task_bits_expCompAck),
    .io_task_bits_allowRetry (g_SinkC__io_task_bits_allowRetry),
    .io_task_bits_memAttr_allocate (g_SinkC__io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable (g_SinkC__io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device (g_SinkC__io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa (g_SinkC__io_task_bits_memAttr_ewa),
    .io_task_bits_traceTag (g_SinkC__io_task_bits_traceTag),
    .io_resp_valid (g_SinkC__io_resp_valid),
    .io_resp_set (g_SinkC__io_resp_set),
    .io_resp_tag (g_SinkC__io_resp_tag),
    .io_resp_respInfo_opcode (g_SinkC__io_resp_respInfo_opcode),
    .io_resp_respInfo_param (g_SinkC__io_resp_respInfo_param),
    .io_resp_respInfo_last (g_SinkC__io_resp_respInfo_last),
    .io_resp_respInfo_denied (g_SinkC__io_resp_respInfo_denied),
    .io_resp_respInfo_corrupt (g_SinkC__io_resp_respInfo_corrupt),
    .io_releaseBufWrite_valid (g_SinkC__io_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_data_data (g_SinkC__io_releaseBufWrite_bits_data_data),
    .io_bufResp_data_0 (g_SinkC__io_bufResp_data_0),
    .io_bufResp_data_1 (g_SinkC__io_bufResp_data_1),
    .io_refillBufWrite_valid (g_SinkC__io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id (g_SinkC__io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data (g_SinkC__io_refillBufWrite_bits_data_data),
    .io_msInfo_0_valid (SinkC__io_msInfo_0_valid),
    .io_msInfo_0_bits_set (SinkC__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag (SinkC__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_blockRefill (SinkC__io_msInfo_0_bits_blockRefill),
    .io_msInfo_1_valid (SinkC__io_msInfo_1_valid),
    .io_msInfo_1_bits_set (SinkC__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag (SinkC__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_blockRefill (SinkC__io_msInfo_1_bits_blockRefill),
    .io_msInfo_2_valid (SinkC__io_msInfo_2_valid),
    .io_msInfo_2_bits_set (SinkC__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag (SinkC__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_blockRefill (SinkC__io_msInfo_2_bits_blockRefill),
    .io_msInfo_3_valid (SinkC__io_msInfo_3_valid),
    .io_msInfo_3_bits_set (SinkC__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag (SinkC__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_blockRefill (SinkC__io_msInfo_3_bits_blockRefill),
    .io_msInfo_4_valid (SinkC__io_msInfo_4_valid),
    .io_msInfo_4_bits_set (SinkC__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag (SinkC__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_blockRefill (SinkC__io_msInfo_4_bits_blockRefill),
    .io_msInfo_5_valid (SinkC__io_msInfo_5_valid),
    .io_msInfo_5_bits_set (SinkC__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag (SinkC__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_blockRefill (SinkC__io_msInfo_5_bits_blockRefill),
    .io_msInfo_6_valid (SinkC__io_msInfo_6_valid),
    .io_msInfo_6_bits_set (SinkC__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag (SinkC__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_blockRefill (SinkC__io_msInfo_6_bits_blockRefill),
    .io_msInfo_7_valid (SinkC__io_msInfo_7_valid),
    .io_msInfo_7_bits_set (SinkC__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag (SinkC__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_blockRefill (SinkC__io_msInfo_7_bits_blockRefill),
    .io_msInfo_8_valid (SinkC__io_msInfo_8_valid),
    .io_msInfo_8_bits_set (SinkC__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag (SinkC__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_blockRefill (SinkC__io_msInfo_8_bits_blockRefill),
    .io_msInfo_9_valid (SinkC__io_msInfo_9_valid),
    .io_msInfo_9_bits_set (SinkC__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag (SinkC__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_blockRefill (SinkC__io_msInfo_9_bits_blockRefill),
    .io_msInfo_10_valid (SinkC__io_msInfo_10_valid),
    .io_msInfo_10_bits_set (SinkC__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag (SinkC__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_blockRefill (SinkC__io_msInfo_10_bits_blockRefill),
    .io_msInfo_11_valid (SinkC__io_msInfo_11_valid),
    .io_msInfo_11_bits_set (SinkC__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag (SinkC__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_blockRefill (SinkC__io_msInfo_11_bits_blockRefill),
    .io_msInfo_12_valid (SinkC__io_msInfo_12_valid),
    .io_msInfo_12_bits_set (SinkC__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag (SinkC__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_blockRefill (SinkC__io_msInfo_12_bits_blockRefill),
    .io_msInfo_13_valid (SinkC__io_msInfo_13_valid),
    .io_msInfo_13_bits_set (SinkC__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag (SinkC__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_blockRefill (SinkC__io_msInfo_13_bits_blockRefill),
    .io_msInfo_14_valid (SinkC__io_msInfo_14_valid),
    .io_msInfo_14_bits_set (SinkC__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag (SinkC__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_blockRefill (SinkC__io_msInfo_14_bits_blockRefill),
    .io_msInfo_15_valid (SinkC__io_msInfo_15_valid),
    .io_msInfo_15_bits_set (SinkC__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag (SinkC__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_blockRefill (SinkC__io_msInfo_15_bits_blockRefill)
  );
  SinkC_xs u_i_SinkC (
    .clock (clock),
    .reset (reset),
    .io_c_ready (i_SinkC__io_c_ready),
    .io_c_valid (SinkC__io_c_valid),
    .io_c_bits_opcode (SinkC__io_c_bits_opcode),
    .io_c_bits_param (SinkC__io_c_bits_param),
    .io_c_bits_size (SinkC__io_c_bits_size),
    .io_c_bits_source (SinkC__io_c_bits_source),
    .io_c_bits_address (SinkC__io_c_bits_address),
    .io_c_bits_data (SinkC__io_c_bits_data),
    .io_c_bits_corrupt (SinkC__io_c_bits_corrupt),
    .io_task_ready (SinkC__io_task_ready),
    .io_task_valid (i_SinkC__io_task_valid),
    .io_task_bits_channel (i_SinkC__io_task_bits_channel),
    .io_task_bits_txChannel (i_SinkC__io_task_bits_txChannel),
    .io_task_bits_set (i_SinkC__io_task_bits_set),
    .io_task_bits_tag (i_SinkC__io_task_bits_tag),
    .io_task_bits_off (i_SinkC__io_task_bits_off),
    .io_task_bits_alias (i_SinkC__io_task_bits_alias),
    .io_task_bits_vaddr (i_SinkC__io_task_bits_vaddr),
    .io_task_bits_isKeyword (i_SinkC__io_task_bits_isKeyword),
    .io_task_bits_opcode (i_SinkC__io_task_bits_opcode),
    .io_task_bits_param (i_SinkC__io_task_bits_param),
    .io_task_bits_size (i_SinkC__io_task_bits_size),
    .io_task_bits_sourceId (i_SinkC__io_task_bits_sourceId),
    .io_task_bits_bufIdx (i_SinkC__io_task_bits_bufIdx),
    .io_task_bits_needProbeAckData (i_SinkC__io_task_bits_needProbeAckData),
    .io_task_bits_denied (i_SinkC__io_task_bits_denied),
    .io_task_bits_corrupt (i_SinkC__io_task_bits_corrupt),
    .io_task_bits_mshrTask (i_SinkC__io_task_bits_mshrTask),
    .io_task_bits_mshrId (i_SinkC__io_task_bits_mshrId),
    .io_task_bits_aliasTask (i_SinkC__io_task_bits_aliasTask),
    .io_task_bits_useProbeData (i_SinkC__io_task_bits_useProbeData),
    .io_task_bits_mshrRetry (i_SinkC__io_task_bits_mshrRetry),
    .io_task_bits_readProbeDataDown (i_SinkC__io_task_bits_readProbeDataDown),
    .io_task_bits_fromL2pft (i_SinkC__io_task_bits_fromL2pft),
    .io_task_bits_needHint (i_SinkC__io_task_bits_needHint),
    .io_task_bits_dirty (i_SinkC__io_task_bits_dirty),
    .io_task_bits_way (i_SinkC__io_task_bits_way),
    .io_task_bits_meta_dirty (i_SinkC__io_task_bits_meta_dirty),
    .io_task_bits_meta_state (i_SinkC__io_task_bits_meta_state),
    .io_task_bits_meta_clients (i_SinkC__io_task_bits_meta_clients),
    .io_task_bits_meta_alias (i_SinkC__io_task_bits_meta_alias),
    .io_task_bits_meta_prefetch (i_SinkC__io_task_bits_meta_prefetch),
    .io_task_bits_meta_prefetchSrc (i_SinkC__io_task_bits_meta_prefetchSrc),
    .io_task_bits_meta_accessed (i_SinkC__io_task_bits_meta_accessed),
    .io_task_bits_meta_tagErr (i_SinkC__io_task_bits_meta_tagErr),
    .io_task_bits_meta_dataErr (i_SinkC__io_task_bits_meta_dataErr),
    .io_task_bits_metaWen (i_SinkC__io_task_bits_metaWen),
    .io_task_bits_tagWen (i_SinkC__io_task_bits_tagWen),
    .io_task_bits_dsWen (i_SinkC__io_task_bits_dsWen),
    .io_task_bits_wayMask (i_SinkC__io_task_bits_wayMask),
    .io_task_bits_replTask (i_SinkC__io_task_bits_replTask),
    .io_task_bits_cmoTask (i_SinkC__io_task_bits_cmoTask),
    .io_task_bits_cmoAll (i_SinkC__io_task_bits_cmoAll),
    .io_task_bits_reqSource (i_SinkC__io_task_bits_reqSource),
    .io_task_bits_mergeA (i_SinkC__io_task_bits_mergeA),
    .io_task_bits_aMergeTask_off (i_SinkC__io_task_bits_aMergeTask_off),
    .io_task_bits_aMergeTask_alias (i_SinkC__io_task_bits_aMergeTask_alias),
    .io_task_bits_aMergeTask_vaddr (i_SinkC__io_task_bits_aMergeTask_vaddr),
    .io_task_bits_aMergeTask_isKeyword (i_SinkC__io_task_bits_aMergeTask_isKeyword),
    .io_task_bits_aMergeTask_opcode (i_SinkC__io_task_bits_aMergeTask_opcode),
    .io_task_bits_aMergeTask_param (i_SinkC__io_task_bits_aMergeTask_param),
    .io_task_bits_aMergeTask_sourceId (i_SinkC__io_task_bits_aMergeTask_sourceId),
    .io_task_bits_aMergeTask_meta_dirty (i_SinkC__io_task_bits_aMergeTask_meta_dirty),
    .io_task_bits_aMergeTask_meta_state (i_SinkC__io_task_bits_aMergeTask_meta_state),
    .io_task_bits_aMergeTask_meta_clients (i_SinkC__io_task_bits_aMergeTask_meta_clients),
    .io_task_bits_aMergeTask_meta_alias (i_SinkC__io_task_bits_aMergeTask_meta_alias),
    .io_task_bits_aMergeTask_meta_prefetch (i_SinkC__io_task_bits_aMergeTask_meta_prefetch),
    .io_task_bits_aMergeTask_meta_prefetchSrc (i_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc),
    .io_task_bits_aMergeTask_meta_accessed (i_SinkC__io_task_bits_aMergeTask_meta_accessed),
    .io_task_bits_aMergeTask_meta_tagErr (i_SinkC__io_task_bits_aMergeTask_meta_tagErr),
    .io_task_bits_aMergeTask_meta_dataErr (i_SinkC__io_task_bits_aMergeTask_meta_dataErr),
    .io_task_bits_snpHitRelease (i_SinkC__io_task_bits_snpHitRelease),
    .io_task_bits_snpHitReleaseToInval (i_SinkC__io_task_bits_snpHitReleaseToInval),
    .io_task_bits_snpHitReleaseToClean (i_SinkC__io_task_bits_snpHitReleaseToClean),
    .io_task_bits_snpHitReleaseWithData (i_SinkC__io_task_bits_snpHitReleaseWithData),
    .io_task_bits_snpHitReleaseIdx (i_SinkC__io_task_bits_snpHitReleaseIdx),
    .io_task_bits_snpHitReleaseMeta_dirty (i_SinkC__io_task_bits_snpHitReleaseMeta_dirty),
    .io_task_bits_snpHitReleaseMeta_state (i_SinkC__io_task_bits_snpHitReleaseMeta_state),
    .io_task_bits_snpHitReleaseMeta_clients (i_SinkC__io_task_bits_snpHitReleaseMeta_clients),
    .io_task_bits_snpHitReleaseMeta_alias (i_SinkC__io_task_bits_snpHitReleaseMeta_alias),
    .io_task_bits_snpHitReleaseMeta_prefetch (i_SinkC__io_task_bits_snpHitReleaseMeta_prefetch),
    .io_task_bits_snpHitReleaseMeta_prefetchSrc (i_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_task_bits_snpHitReleaseMeta_accessed (i_SinkC__io_task_bits_snpHitReleaseMeta_accessed),
    .io_task_bits_snpHitReleaseMeta_tagErr (i_SinkC__io_task_bits_snpHitReleaseMeta_tagErr),
    .io_task_bits_snpHitReleaseMeta_dataErr (i_SinkC__io_task_bits_snpHitReleaseMeta_dataErr),
    .io_task_bits_tgtID (i_SinkC__io_task_bits_tgtID),
    .io_task_bits_srcID (i_SinkC__io_task_bits_srcID),
    .io_task_bits_txnID (i_SinkC__io_task_bits_txnID),
    .io_task_bits_homeNID (i_SinkC__io_task_bits_homeNID),
    .io_task_bits_dbID (i_SinkC__io_task_bits_dbID),
    .io_task_bits_fwdNID (i_SinkC__io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID (i_SinkC__io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode (i_SinkC__io_task_bits_chiOpcode),
    .io_task_bits_resp (i_SinkC__io_task_bits_resp),
    .io_task_bits_fwdState (i_SinkC__io_task_bits_fwdState),
    .io_task_bits_pCrdType (i_SinkC__io_task_bits_pCrdType),
    .io_task_bits_retToSrc (i_SinkC__io_task_bits_retToSrc),
    .io_task_bits_likelyshared (i_SinkC__io_task_bits_likelyshared),
    .io_task_bits_expCompAck (i_SinkC__io_task_bits_expCompAck),
    .io_task_bits_allowRetry (i_SinkC__io_task_bits_allowRetry),
    .io_task_bits_memAttr_allocate (i_SinkC__io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable (i_SinkC__io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device (i_SinkC__io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa (i_SinkC__io_task_bits_memAttr_ewa),
    .io_task_bits_traceTag (i_SinkC__io_task_bits_traceTag),
    .io_resp_valid (i_SinkC__io_resp_valid),
    .io_resp_set (i_SinkC__io_resp_set),
    .io_resp_tag (i_SinkC__io_resp_tag),
    .io_resp_respInfo_opcode (i_SinkC__io_resp_respInfo_opcode),
    .io_resp_respInfo_param (i_SinkC__io_resp_respInfo_param),
    .io_resp_respInfo_last (i_SinkC__io_resp_respInfo_last),
    .io_resp_respInfo_denied (i_SinkC__io_resp_respInfo_denied),
    .io_resp_respInfo_corrupt (i_SinkC__io_resp_respInfo_corrupt),
    .io_releaseBufWrite_valid (i_SinkC__io_releaseBufWrite_valid),
    .io_releaseBufWrite_bits_data_data (i_SinkC__io_releaseBufWrite_bits_data_data),
    .io_bufResp_data_0 (i_SinkC__io_bufResp_data_0),
    .io_bufResp_data_1 (i_SinkC__io_bufResp_data_1),
    .io_refillBufWrite_valid (i_SinkC__io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id (i_SinkC__io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data (i_SinkC__io_refillBufWrite_bits_data_data),
    .io_msInfo_0_valid (SinkC__io_msInfo_0_valid),
    .io_msInfo_0_bits_set (SinkC__io_msInfo_0_bits_set),
    .io_msInfo_0_bits_reqTag (SinkC__io_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_blockRefill (SinkC__io_msInfo_0_bits_blockRefill),
    .io_msInfo_1_valid (SinkC__io_msInfo_1_valid),
    .io_msInfo_1_bits_set (SinkC__io_msInfo_1_bits_set),
    .io_msInfo_1_bits_reqTag (SinkC__io_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_blockRefill (SinkC__io_msInfo_1_bits_blockRefill),
    .io_msInfo_2_valid (SinkC__io_msInfo_2_valid),
    .io_msInfo_2_bits_set (SinkC__io_msInfo_2_bits_set),
    .io_msInfo_2_bits_reqTag (SinkC__io_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_blockRefill (SinkC__io_msInfo_2_bits_blockRefill),
    .io_msInfo_3_valid (SinkC__io_msInfo_3_valid),
    .io_msInfo_3_bits_set (SinkC__io_msInfo_3_bits_set),
    .io_msInfo_3_bits_reqTag (SinkC__io_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_blockRefill (SinkC__io_msInfo_3_bits_blockRefill),
    .io_msInfo_4_valid (SinkC__io_msInfo_4_valid),
    .io_msInfo_4_bits_set (SinkC__io_msInfo_4_bits_set),
    .io_msInfo_4_bits_reqTag (SinkC__io_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_blockRefill (SinkC__io_msInfo_4_bits_blockRefill),
    .io_msInfo_5_valid (SinkC__io_msInfo_5_valid),
    .io_msInfo_5_bits_set (SinkC__io_msInfo_5_bits_set),
    .io_msInfo_5_bits_reqTag (SinkC__io_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_blockRefill (SinkC__io_msInfo_5_bits_blockRefill),
    .io_msInfo_6_valid (SinkC__io_msInfo_6_valid),
    .io_msInfo_6_bits_set (SinkC__io_msInfo_6_bits_set),
    .io_msInfo_6_bits_reqTag (SinkC__io_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_blockRefill (SinkC__io_msInfo_6_bits_blockRefill),
    .io_msInfo_7_valid (SinkC__io_msInfo_7_valid),
    .io_msInfo_7_bits_set (SinkC__io_msInfo_7_bits_set),
    .io_msInfo_7_bits_reqTag (SinkC__io_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_blockRefill (SinkC__io_msInfo_7_bits_blockRefill),
    .io_msInfo_8_valid (SinkC__io_msInfo_8_valid),
    .io_msInfo_8_bits_set (SinkC__io_msInfo_8_bits_set),
    .io_msInfo_8_bits_reqTag (SinkC__io_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_blockRefill (SinkC__io_msInfo_8_bits_blockRefill),
    .io_msInfo_9_valid (SinkC__io_msInfo_9_valid),
    .io_msInfo_9_bits_set (SinkC__io_msInfo_9_bits_set),
    .io_msInfo_9_bits_reqTag (SinkC__io_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_blockRefill (SinkC__io_msInfo_9_bits_blockRefill),
    .io_msInfo_10_valid (SinkC__io_msInfo_10_valid),
    .io_msInfo_10_bits_set (SinkC__io_msInfo_10_bits_set),
    .io_msInfo_10_bits_reqTag (SinkC__io_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_blockRefill (SinkC__io_msInfo_10_bits_blockRefill),
    .io_msInfo_11_valid (SinkC__io_msInfo_11_valid),
    .io_msInfo_11_bits_set (SinkC__io_msInfo_11_bits_set),
    .io_msInfo_11_bits_reqTag (SinkC__io_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_blockRefill (SinkC__io_msInfo_11_bits_blockRefill),
    .io_msInfo_12_valid (SinkC__io_msInfo_12_valid),
    .io_msInfo_12_bits_set (SinkC__io_msInfo_12_bits_set),
    .io_msInfo_12_bits_reqTag (SinkC__io_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_blockRefill (SinkC__io_msInfo_12_bits_blockRefill),
    .io_msInfo_13_valid (SinkC__io_msInfo_13_valid),
    .io_msInfo_13_bits_set (SinkC__io_msInfo_13_bits_set),
    .io_msInfo_13_bits_reqTag (SinkC__io_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_blockRefill (SinkC__io_msInfo_13_bits_blockRefill),
    .io_msInfo_14_valid (SinkC__io_msInfo_14_valid),
    .io_msInfo_14_bits_set (SinkC__io_msInfo_14_bits_set),
    .io_msInfo_14_bits_reqTag (SinkC__io_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_blockRefill (SinkC__io_msInfo_14_bits_blockRefill),
    .io_msInfo_15_valid (SinkC__io_msInfo_15_valid),
    .io_msInfo_15_bits_set (SinkC__io_msInfo_15_bits_set),
    .io_msInfo_15_bits_reqTag (SinkC__io_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_blockRefill (SinkC__io_msInfo_15_bits_blockRefill)
  );
  task automatic drive_SinkC();
    SinkC__io_c_valid = $urandom % 2;
    SinkC__io_c_bits_opcode = (($urandom % 8) != 0) ? 3'($urandom_range(4, 7)) : 3'($urandom);
    SinkC__io_c_bits_param = rnd(3);
    SinkC__io_c_bits_size = (($urandom % 4) != 0) ? 3'h6 : 3'($urandom);
    SinkC__io_c_bits_source = rnd(7);
    SinkC__io_c_bits_address = {30'h0, 1'($urandom), 8'h0, 1'($urandom), 8'($urandom)};
    SinkC__io_c_bits_data = rnd(256);
    SinkC__io_c_bits_corrupt = $urandom % 2;
    SinkC__io_task_ready = (($urandom % 4) != 0);
    SinkC__io_msInfo_0_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_0_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_0_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_0_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_1_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_1_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_1_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_1_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_2_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_2_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_2_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_2_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_3_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_3_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_3_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_3_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_4_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_4_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_4_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_4_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_5_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_5_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_5_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_5_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_6_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_6_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_6_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_6_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_7_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_7_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_7_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_7_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_8_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_8_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_8_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_8_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_9_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_9_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_9_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_9_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_10_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_10_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_10_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_10_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_11_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_11_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_11_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_11_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_12_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_12_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_12_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_12_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_13_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_13_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_13_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_13_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_14_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_14_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_14_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_14_bits_blockRefill = $urandom % 2;
    SinkC__io_msInfo_15_valid = (($urandom % 4) == 0);
    SinkC__io_msInfo_15_bits_set = 9'($urandom_range(0, 1));
    SinkC__io_msInfo_15_bits_reqTag = 31'($urandom_range(0, 1));
    SinkC__io_msInfo_15_bits_blockRefill = $urandom % 2;
  endtask
  task automatic check_SinkC();
    checks++;
    if (g_SinkC__io_c_ready !== i_SinkC__io_c_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_c_ready g=%h i=%h", cyc, g_SinkC__io_c_ready, i_SinkC__io_c_ready);
    end
    if (g_SinkC__io_c_ready !== p_SinkC__io_c_ready) t_SinkC__io_c_ready = 1'b1;
    p_SinkC__io_c_ready = g_SinkC__io_c_ready;
    checks++;
    if (g_SinkC__io_task_valid !== i_SinkC__io_task_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_valid g=%h i=%h", cyc, g_SinkC__io_task_valid, i_SinkC__io_task_valid);
    end
    if (g_SinkC__io_task_valid !== p_SinkC__io_task_valid) t_SinkC__io_task_valid = 1'b1;
    p_SinkC__io_task_valid = g_SinkC__io_task_valid;
    checks++;
    if (g_SinkC__io_task_bits_channel !== i_SinkC__io_task_bits_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_channel g=%h i=%h", cyc, g_SinkC__io_task_bits_channel, i_SinkC__io_task_bits_channel);
    end
    if (g_SinkC__io_task_bits_channel !== p_SinkC__io_task_bits_channel) t_SinkC__io_task_bits_channel = 1'b1;
    p_SinkC__io_task_bits_channel = g_SinkC__io_task_bits_channel;
    checks++;
    if (g_SinkC__io_task_bits_txChannel !== i_SinkC__io_task_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_txChannel g=%h i=%h", cyc, g_SinkC__io_task_bits_txChannel, i_SinkC__io_task_bits_txChannel);
    end
    if (g_SinkC__io_task_bits_txChannel !== p_SinkC__io_task_bits_txChannel) t_SinkC__io_task_bits_txChannel = 1'b1;
    p_SinkC__io_task_bits_txChannel = g_SinkC__io_task_bits_txChannel;
    checks++;
    if (g_SinkC__io_task_bits_set !== i_SinkC__io_task_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_set g=%h i=%h", cyc, g_SinkC__io_task_bits_set, i_SinkC__io_task_bits_set);
    end
    if (g_SinkC__io_task_bits_set !== p_SinkC__io_task_bits_set) t_SinkC__io_task_bits_set = 1'b1;
    p_SinkC__io_task_bits_set = g_SinkC__io_task_bits_set;
    checks++;
    if (g_SinkC__io_task_bits_tag !== i_SinkC__io_task_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_tag g=%h i=%h", cyc, g_SinkC__io_task_bits_tag, i_SinkC__io_task_bits_tag);
    end
    if (g_SinkC__io_task_bits_tag !== p_SinkC__io_task_bits_tag) t_SinkC__io_task_bits_tag = 1'b1;
    p_SinkC__io_task_bits_tag = g_SinkC__io_task_bits_tag;
    checks++;
    if (g_SinkC__io_task_bits_off !== i_SinkC__io_task_bits_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_off g=%h i=%h", cyc, g_SinkC__io_task_bits_off, i_SinkC__io_task_bits_off);
    end
    if (g_SinkC__io_task_bits_off !== p_SinkC__io_task_bits_off) t_SinkC__io_task_bits_off = 1'b1;
    p_SinkC__io_task_bits_off = g_SinkC__io_task_bits_off;
    checks++;
    if (g_SinkC__io_task_bits_alias !== i_SinkC__io_task_bits_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_alias g=%h i=%h", cyc, g_SinkC__io_task_bits_alias, i_SinkC__io_task_bits_alias);
    end
    if (g_SinkC__io_task_bits_alias !== p_SinkC__io_task_bits_alias) t_SinkC__io_task_bits_alias = 1'b1;
    p_SinkC__io_task_bits_alias = g_SinkC__io_task_bits_alias;
    checks++;
    if (g_SinkC__io_task_bits_vaddr !== i_SinkC__io_task_bits_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_vaddr g=%h i=%h", cyc, g_SinkC__io_task_bits_vaddr, i_SinkC__io_task_bits_vaddr);
    end
    if (g_SinkC__io_task_bits_vaddr !== p_SinkC__io_task_bits_vaddr) t_SinkC__io_task_bits_vaddr = 1'b1;
    p_SinkC__io_task_bits_vaddr = g_SinkC__io_task_bits_vaddr;
    checks++;
    if (g_SinkC__io_task_bits_isKeyword !== i_SinkC__io_task_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_isKeyword g=%h i=%h", cyc, g_SinkC__io_task_bits_isKeyword, i_SinkC__io_task_bits_isKeyword);
    end
    if (g_SinkC__io_task_bits_isKeyword !== p_SinkC__io_task_bits_isKeyword) t_SinkC__io_task_bits_isKeyword = 1'b1;
    p_SinkC__io_task_bits_isKeyword = g_SinkC__io_task_bits_isKeyword;
    checks++;
    if (g_SinkC__io_task_bits_opcode !== i_SinkC__io_task_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_opcode g=%h i=%h", cyc, g_SinkC__io_task_bits_opcode, i_SinkC__io_task_bits_opcode);
    end
    if (g_SinkC__io_task_bits_opcode !== p_SinkC__io_task_bits_opcode) t_SinkC__io_task_bits_opcode = 1'b1;
    p_SinkC__io_task_bits_opcode = g_SinkC__io_task_bits_opcode;
    checks++;
    if (g_SinkC__io_task_bits_param !== i_SinkC__io_task_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_param g=%h i=%h", cyc, g_SinkC__io_task_bits_param, i_SinkC__io_task_bits_param);
    end
    if (g_SinkC__io_task_bits_param !== p_SinkC__io_task_bits_param) t_SinkC__io_task_bits_param = 1'b1;
    p_SinkC__io_task_bits_param = g_SinkC__io_task_bits_param;
    checks++;
    if (g_SinkC__io_task_bits_size !== i_SinkC__io_task_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_size g=%h i=%h", cyc, g_SinkC__io_task_bits_size, i_SinkC__io_task_bits_size);
    end
    if (g_SinkC__io_task_bits_size !== p_SinkC__io_task_bits_size) t_SinkC__io_task_bits_size = 1'b1;
    p_SinkC__io_task_bits_size = g_SinkC__io_task_bits_size;
    checks++;
    if (g_SinkC__io_task_bits_sourceId !== i_SinkC__io_task_bits_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_sourceId g=%h i=%h", cyc, g_SinkC__io_task_bits_sourceId, i_SinkC__io_task_bits_sourceId);
    end
    if (g_SinkC__io_task_bits_sourceId !== p_SinkC__io_task_bits_sourceId) t_SinkC__io_task_bits_sourceId = 1'b1;
    p_SinkC__io_task_bits_sourceId = g_SinkC__io_task_bits_sourceId;
    checks++;
    if (g_SinkC__io_task_bits_bufIdx !== i_SinkC__io_task_bits_bufIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_bufIdx g=%h i=%h", cyc, g_SinkC__io_task_bits_bufIdx, i_SinkC__io_task_bits_bufIdx);
    end
    if (g_SinkC__io_task_bits_bufIdx !== p_SinkC__io_task_bits_bufIdx) t_SinkC__io_task_bits_bufIdx = 1'b1;
    p_SinkC__io_task_bits_bufIdx = g_SinkC__io_task_bits_bufIdx;
    checks++;
    if (g_SinkC__io_task_bits_needProbeAckData !== i_SinkC__io_task_bits_needProbeAckData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_needProbeAckData g=%h i=%h", cyc, g_SinkC__io_task_bits_needProbeAckData, i_SinkC__io_task_bits_needProbeAckData);
    end
    if (g_SinkC__io_task_bits_needProbeAckData !== p_SinkC__io_task_bits_needProbeAckData) t_SinkC__io_task_bits_needProbeAckData = 1'b1;
    p_SinkC__io_task_bits_needProbeAckData = g_SinkC__io_task_bits_needProbeAckData;
    checks++;
    if (g_SinkC__io_task_bits_denied !== i_SinkC__io_task_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_denied g=%h i=%h", cyc, g_SinkC__io_task_bits_denied, i_SinkC__io_task_bits_denied);
    end
    if (g_SinkC__io_task_bits_denied !== p_SinkC__io_task_bits_denied) t_SinkC__io_task_bits_denied = 1'b1;
    p_SinkC__io_task_bits_denied = g_SinkC__io_task_bits_denied;
    checks++;
    if (g_SinkC__io_task_bits_corrupt !== i_SinkC__io_task_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_corrupt g=%h i=%h", cyc, g_SinkC__io_task_bits_corrupt, i_SinkC__io_task_bits_corrupt);
    end
    if (g_SinkC__io_task_bits_corrupt !== p_SinkC__io_task_bits_corrupt) t_SinkC__io_task_bits_corrupt = 1'b1;
    p_SinkC__io_task_bits_corrupt = g_SinkC__io_task_bits_corrupt;
    checks++;
    if (g_SinkC__io_task_bits_mshrTask !== i_SinkC__io_task_bits_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_mshrTask g=%h i=%h", cyc, g_SinkC__io_task_bits_mshrTask, i_SinkC__io_task_bits_mshrTask);
    end
    if (g_SinkC__io_task_bits_mshrTask !== p_SinkC__io_task_bits_mshrTask) t_SinkC__io_task_bits_mshrTask = 1'b1;
    p_SinkC__io_task_bits_mshrTask = g_SinkC__io_task_bits_mshrTask;
    checks++;
    if (g_SinkC__io_task_bits_mshrId !== i_SinkC__io_task_bits_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_mshrId g=%h i=%h", cyc, g_SinkC__io_task_bits_mshrId, i_SinkC__io_task_bits_mshrId);
    end
    if (g_SinkC__io_task_bits_mshrId !== p_SinkC__io_task_bits_mshrId) t_SinkC__io_task_bits_mshrId = 1'b1;
    p_SinkC__io_task_bits_mshrId = g_SinkC__io_task_bits_mshrId;
    checks++;
    if (g_SinkC__io_task_bits_aliasTask !== i_SinkC__io_task_bits_aliasTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aliasTask g=%h i=%h", cyc, g_SinkC__io_task_bits_aliasTask, i_SinkC__io_task_bits_aliasTask);
    end
    if (g_SinkC__io_task_bits_aliasTask !== p_SinkC__io_task_bits_aliasTask) t_SinkC__io_task_bits_aliasTask = 1'b1;
    p_SinkC__io_task_bits_aliasTask = g_SinkC__io_task_bits_aliasTask;
    checks++;
    if (g_SinkC__io_task_bits_useProbeData !== i_SinkC__io_task_bits_useProbeData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_useProbeData g=%h i=%h", cyc, g_SinkC__io_task_bits_useProbeData, i_SinkC__io_task_bits_useProbeData);
    end
    if (g_SinkC__io_task_bits_useProbeData !== p_SinkC__io_task_bits_useProbeData) t_SinkC__io_task_bits_useProbeData = 1'b1;
    p_SinkC__io_task_bits_useProbeData = g_SinkC__io_task_bits_useProbeData;
    checks++;
    if (g_SinkC__io_task_bits_mshrRetry !== i_SinkC__io_task_bits_mshrRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_mshrRetry g=%h i=%h", cyc, g_SinkC__io_task_bits_mshrRetry, i_SinkC__io_task_bits_mshrRetry);
    end
    if (g_SinkC__io_task_bits_mshrRetry !== p_SinkC__io_task_bits_mshrRetry) t_SinkC__io_task_bits_mshrRetry = 1'b1;
    p_SinkC__io_task_bits_mshrRetry = g_SinkC__io_task_bits_mshrRetry;
    checks++;
    if (g_SinkC__io_task_bits_readProbeDataDown !== i_SinkC__io_task_bits_readProbeDataDown) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_readProbeDataDown g=%h i=%h", cyc, g_SinkC__io_task_bits_readProbeDataDown, i_SinkC__io_task_bits_readProbeDataDown);
    end
    if (g_SinkC__io_task_bits_readProbeDataDown !== p_SinkC__io_task_bits_readProbeDataDown) t_SinkC__io_task_bits_readProbeDataDown = 1'b1;
    p_SinkC__io_task_bits_readProbeDataDown = g_SinkC__io_task_bits_readProbeDataDown;
    checks++;
    if (g_SinkC__io_task_bits_fromL2pft !== i_SinkC__io_task_bits_fromL2pft) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_fromL2pft g=%h i=%h", cyc, g_SinkC__io_task_bits_fromL2pft, i_SinkC__io_task_bits_fromL2pft);
    end
    if (g_SinkC__io_task_bits_fromL2pft !== p_SinkC__io_task_bits_fromL2pft) t_SinkC__io_task_bits_fromL2pft = 1'b1;
    p_SinkC__io_task_bits_fromL2pft = g_SinkC__io_task_bits_fromL2pft;
    checks++;
    if (g_SinkC__io_task_bits_needHint !== i_SinkC__io_task_bits_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_needHint g=%h i=%h", cyc, g_SinkC__io_task_bits_needHint, i_SinkC__io_task_bits_needHint);
    end
    if (g_SinkC__io_task_bits_needHint !== p_SinkC__io_task_bits_needHint) t_SinkC__io_task_bits_needHint = 1'b1;
    p_SinkC__io_task_bits_needHint = g_SinkC__io_task_bits_needHint;
    checks++;
    if (g_SinkC__io_task_bits_dirty !== i_SinkC__io_task_bits_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_dirty g=%h i=%h", cyc, g_SinkC__io_task_bits_dirty, i_SinkC__io_task_bits_dirty);
    end
    if (g_SinkC__io_task_bits_dirty !== p_SinkC__io_task_bits_dirty) t_SinkC__io_task_bits_dirty = 1'b1;
    p_SinkC__io_task_bits_dirty = g_SinkC__io_task_bits_dirty;
    checks++;
    if (g_SinkC__io_task_bits_way !== i_SinkC__io_task_bits_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_way g=%h i=%h", cyc, g_SinkC__io_task_bits_way, i_SinkC__io_task_bits_way);
    end
    if (g_SinkC__io_task_bits_way !== p_SinkC__io_task_bits_way) t_SinkC__io_task_bits_way = 1'b1;
    p_SinkC__io_task_bits_way = g_SinkC__io_task_bits_way;
    checks++;
    if (g_SinkC__io_task_bits_meta_dirty !== i_SinkC__io_task_bits_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_dirty g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_dirty, i_SinkC__io_task_bits_meta_dirty);
    end
    if (g_SinkC__io_task_bits_meta_dirty !== p_SinkC__io_task_bits_meta_dirty) t_SinkC__io_task_bits_meta_dirty = 1'b1;
    p_SinkC__io_task_bits_meta_dirty = g_SinkC__io_task_bits_meta_dirty;
    checks++;
    if (g_SinkC__io_task_bits_meta_state !== i_SinkC__io_task_bits_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_state g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_state, i_SinkC__io_task_bits_meta_state);
    end
    if (g_SinkC__io_task_bits_meta_state !== p_SinkC__io_task_bits_meta_state) t_SinkC__io_task_bits_meta_state = 1'b1;
    p_SinkC__io_task_bits_meta_state = g_SinkC__io_task_bits_meta_state;
    checks++;
    if (g_SinkC__io_task_bits_meta_clients !== i_SinkC__io_task_bits_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_clients g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_clients, i_SinkC__io_task_bits_meta_clients);
    end
    if (g_SinkC__io_task_bits_meta_clients !== p_SinkC__io_task_bits_meta_clients) t_SinkC__io_task_bits_meta_clients = 1'b1;
    p_SinkC__io_task_bits_meta_clients = g_SinkC__io_task_bits_meta_clients;
    checks++;
    if (g_SinkC__io_task_bits_meta_alias !== i_SinkC__io_task_bits_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_alias g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_alias, i_SinkC__io_task_bits_meta_alias);
    end
    if (g_SinkC__io_task_bits_meta_alias !== p_SinkC__io_task_bits_meta_alias) t_SinkC__io_task_bits_meta_alias = 1'b1;
    p_SinkC__io_task_bits_meta_alias = g_SinkC__io_task_bits_meta_alias;
    checks++;
    if (g_SinkC__io_task_bits_meta_prefetch !== i_SinkC__io_task_bits_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_prefetch g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_prefetch, i_SinkC__io_task_bits_meta_prefetch);
    end
    if (g_SinkC__io_task_bits_meta_prefetch !== p_SinkC__io_task_bits_meta_prefetch) t_SinkC__io_task_bits_meta_prefetch = 1'b1;
    p_SinkC__io_task_bits_meta_prefetch = g_SinkC__io_task_bits_meta_prefetch;
    checks++;
    if (g_SinkC__io_task_bits_meta_prefetchSrc !== i_SinkC__io_task_bits_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_prefetchSrc g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_prefetchSrc, i_SinkC__io_task_bits_meta_prefetchSrc);
    end
    if (g_SinkC__io_task_bits_meta_prefetchSrc !== p_SinkC__io_task_bits_meta_prefetchSrc) t_SinkC__io_task_bits_meta_prefetchSrc = 1'b1;
    p_SinkC__io_task_bits_meta_prefetchSrc = g_SinkC__io_task_bits_meta_prefetchSrc;
    checks++;
    if (g_SinkC__io_task_bits_meta_accessed !== i_SinkC__io_task_bits_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_accessed g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_accessed, i_SinkC__io_task_bits_meta_accessed);
    end
    if (g_SinkC__io_task_bits_meta_accessed !== p_SinkC__io_task_bits_meta_accessed) t_SinkC__io_task_bits_meta_accessed = 1'b1;
    p_SinkC__io_task_bits_meta_accessed = g_SinkC__io_task_bits_meta_accessed;
    checks++;
    if (g_SinkC__io_task_bits_meta_tagErr !== i_SinkC__io_task_bits_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_tagErr g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_tagErr, i_SinkC__io_task_bits_meta_tagErr);
    end
    if (g_SinkC__io_task_bits_meta_tagErr !== p_SinkC__io_task_bits_meta_tagErr) t_SinkC__io_task_bits_meta_tagErr = 1'b1;
    p_SinkC__io_task_bits_meta_tagErr = g_SinkC__io_task_bits_meta_tagErr;
    checks++;
    if (g_SinkC__io_task_bits_meta_dataErr !== i_SinkC__io_task_bits_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_meta_dataErr g=%h i=%h", cyc, g_SinkC__io_task_bits_meta_dataErr, i_SinkC__io_task_bits_meta_dataErr);
    end
    if (g_SinkC__io_task_bits_meta_dataErr !== p_SinkC__io_task_bits_meta_dataErr) t_SinkC__io_task_bits_meta_dataErr = 1'b1;
    p_SinkC__io_task_bits_meta_dataErr = g_SinkC__io_task_bits_meta_dataErr;
    checks++;
    if (g_SinkC__io_task_bits_metaWen !== i_SinkC__io_task_bits_metaWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_metaWen g=%h i=%h", cyc, g_SinkC__io_task_bits_metaWen, i_SinkC__io_task_bits_metaWen);
    end
    if (g_SinkC__io_task_bits_metaWen !== p_SinkC__io_task_bits_metaWen) t_SinkC__io_task_bits_metaWen = 1'b1;
    p_SinkC__io_task_bits_metaWen = g_SinkC__io_task_bits_metaWen;
    checks++;
    if (g_SinkC__io_task_bits_tagWen !== i_SinkC__io_task_bits_tagWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_tagWen g=%h i=%h", cyc, g_SinkC__io_task_bits_tagWen, i_SinkC__io_task_bits_tagWen);
    end
    if (g_SinkC__io_task_bits_tagWen !== p_SinkC__io_task_bits_tagWen) t_SinkC__io_task_bits_tagWen = 1'b1;
    p_SinkC__io_task_bits_tagWen = g_SinkC__io_task_bits_tagWen;
    checks++;
    if (g_SinkC__io_task_bits_dsWen !== i_SinkC__io_task_bits_dsWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_dsWen g=%h i=%h", cyc, g_SinkC__io_task_bits_dsWen, i_SinkC__io_task_bits_dsWen);
    end
    if (g_SinkC__io_task_bits_dsWen !== p_SinkC__io_task_bits_dsWen) t_SinkC__io_task_bits_dsWen = 1'b1;
    p_SinkC__io_task_bits_dsWen = g_SinkC__io_task_bits_dsWen;
    checks++;
    if (g_SinkC__io_task_bits_wayMask !== i_SinkC__io_task_bits_wayMask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_wayMask g=%h i=%h", cyc, g_SinkC__io_task_bits_wayMask, i_SinkC__io_task_bits_wayMask);
    end
    if (g_SinkC__io_task_bits_wayMask !== p_SinkC__io_task_bits_wayMask) t_SinkC__io_task_bits_wayMask = 1'b1;
    p_SinkC__io_task_bits_wayMask = g_SinkC__io_task_bits_wayMask;
    checks++;
    if (g_SinkC__io_task_bits_replTask !== i_SinkC__io_task_bits_replTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_replTask g=%h i=%h", cyc, g_SinkC__io_task_bits_replTask, i_SinkC__io_task_bits_replTask);
    end
    if (g_SinkC__io_task_bits_replTask !== p_SinkC__io_task_bits_replTask) t_SinkC__io_task_bits_replTask = 1'b1;
    p_SinkC__io_task_bits_replTask = g_SinkC__io_task_bits_replTask;
    checks++;
    if (g_SinkC__io_task_bits_cmoTask !== i_SinkC__io_task_bits_cmoTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_cmoTask g=%h i=%h", cyc, g_SinkC__io_task_bits_cmoTask, i_SinkC__io_task_bits_cmoTask);
    end
    if (g_SinkC__io_task_bits_cmoTask !== p_SinkC__io_task_bits_cmoTask) t_SinkC__io_task_bits_cmoTask = 1'b1;
    p_SinkC__io_task_bits_cmoTask = g_SinkC__io_task_bits_cmoTask;
    checks++;
    if (g_SinkC__io_task_bits_cmoAll !== i_SinkC__io_task_bits_cmoAll) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_cmoAll g=%h i=%h", cyc, g_SinkC__io_task_bits_cmoAll, i_SinkC__io_task_bits_cmoAll);
    end
    if (g_SinkC__io_task_bits_cmoAll !== p_SinkC__io_task_bits_cmoAll) t_SinkC__io_task_bits_cmoAll = 1'b1;
    p_SinkC__io_task_bits_cmoAll = g_SinkC__io_task_bits_cmoAll;
    checks++;
    if (g_SinkC__io_task_bits_reqSource !== i_SinkC__io_task_bits_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_reqSource g=%h i=%h", cyc, g_SinkC__io_task_bits_reqSource, i_SinkC__io_task_bits_reqSource);
    end
    if (g_SinkC__io_task_bits_reqSource !== p_SinkC__io_task_bits_reqSource) t_SinkC__io_task_bits_reqSource = 1'b1;
    p_SinkC__io_task_bits_reqSource = g_SinkC__io_task_bits_reqSource;
    checks++;
    if (g_SinkC__io_task_bits_mergeA !== i_SinkC__io_task_bits_mergeA) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_mergeA g=%h i=%h", cyc, g_SinkC__io_task_bits_mergeA, i_SinkC__io_task_bits_mergeA);
    end
    if (g_SinkC__io_task_bits_mergeA !== p_SinkC__io_task_bits_mergeA) t_SinkC__io_task_bits_mergeA = 1'b1;
    p_SinkC__io_task_bits_mergeA = g_SinkC__io_task_bits_mergeA;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_off !== i_SinkC__io_task_bits_aMergeTask_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_off g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_off, i_SinkC__io_task_bits_aMergeTask_off);
    end
    if (g_SinkC__io_task_bits_aMergeTask_off !== p_SinkC__io_task_bits_aMergeTask_off) t_SinkC__io_task_bits_aMergeTask_off = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_off = g_SinkC__io_task_bits_aMergeTask_off;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_alias !== i_SinkC__io_task_bits_aMergeTask_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_alias g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_alias, i_SinkC__io_task_bits_aMergeTask_alias);
    end
    if (g_SinkC__io_task_bits_aMergeTask_alias !== p_SinkC__io_task_bits_aMergeTask_alias) t_SinkC__io_task_bits_aMergeTask_alias = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_alias = g_SinkC__io_task_bits_aMergeTask_alias;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_vaddr !== i_SinkC__io_task_bits_aMergeTask_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_vaddr g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_vaddr, i_SinkC__io_task_bits_aMergeTask_vaddr);
    end
    if (g_SinkC__io_task_bits_aMergeTask_vaddr !== p_SinkC__io_task_bits_aMergeTask_vaddr) t_SinkC__io_task_bits_aMergeTask_vaddr = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_vaddr = g_SinkC__io_task_bits_aMergeTask_vaddr;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_isKeyword !== i_SinkC__io_task_bits_aMergeTask_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_isKeyword g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_isKeyword, i_SinkC__io_task_bits_aMergeTask_isKeyword);
    end
    if (g_SinkC__io_task_bits_aMergeTask_isKeyword !== p_SinkC__io_task_bits_aMergeTask_isKeyword) t_SinkC__io_task_bits_aMergeTask_isKeyword = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_isKeyword = g_SinkC__io_task_bits_aMergeTask_isKeyword;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_opcode !== i_SinkC__io_task_bits_aMergeTask_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_opcode g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_opcode, i_SinkC__io_task_bits_aMergeTask_opcode);
    end
    if (g_SinkC__io_task_bits_aMergeTask_opcode !== p_SinkC__io_task_bits_aMergeTask_opcode) t_SinkC__io_task_bits_aMergeTask_opcode = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_opcode = g_SinkC__io_task_bits_aMergeTask_opcode;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_param !== i_SinkC__io_task_bits_aMergeTask_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_param g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_param, i_SinkC__io_task_bits_aMergeTask_param);
    end
    if (g_SinkC__io_task_bits_aMergeTask_param !== p_SinkC__io_task_bits_aMergeTask_param) t_SinkC__io_task_bits_aMergeTask_param = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_param = g_SinkC__io_task_bits_aMergeTask_param;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_sourceId !== i_SinkC__io_task_bits_aMergeTask_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_sourceId g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_sourceId, i_SinkC__io_task_bits_aMergeTask_sourceId);
    end
    if (g_SinkC__io_task_bits_aMergeTask_sourceId !== p_SinkC__io_task_bits_aMergeTask_sourceId) t_SinkC__io_task_bits_aMergeTask_sourceId = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_sourceId = g_SinkC__io_task_bits_aMergeTask_sourceId;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_dirty !== i_SinkC__io_task_bits_aMergeTask_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_dirty g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_dirty, i_SinkC__io_task_bits_aMergeTask_meta_dirty);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_dirty !== p_SinkC__io_task_bits_aMergeTask_meta_dirty) t_SinkC__io_task_bits_aMergeTask_meta_dirty = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_dirty = g_SinkC__io_task_bits_aMergeTask_meta_dirty;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_state !== i_SinkC__io_task_bits_aMergeTask_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_state g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_state, i_SinkC__io_task_bits_aMergeTask_meta_state);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_state !== p_SinkC__io_task_bits_aMergeTask_meta_state) t_SinkC__io_task_bits_aMergeTask_meta_state = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_state = g_SinkC__io_task_bits_aMergeTask_meta_state;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_clients !== i_SinkC__io_task_bits_aMergeTask_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_clients g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_clients, i_SinkC__io_task_bits_aMergeTask_meta_clients);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_clients !== p_SinkC__io_task_bits_aMergeTask_meta_clients) t_SinkC__io_task_bits_aMergeTask_meta_clients = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_clients = g_SinkC__io_task_bits_aMergeTask_meta_clients;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_alias !== i_SinkC__io_task_bits_aMergeTask_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_alias g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_alias, i_SinkC__io_task_bits_aMergeTask_meta_alias);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_alias !== p_SinkC__io_task_bits_aMergeTask_meta_alias) t_SinkC__io_task_bits_aMergeTask_meta_alias = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_alias = g_SinkC__io_task_bits_aMergeTask_meta_alias;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_prefetch !== i_SinkC__io_task_bits_aMergeTask_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_prefetch g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_prefetch, i_SinkC__io_task_bits_aMergeTask_meta_prefetch);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_prefetch !== p_SinkC__io_task_bits_aMergeTask_meta_prefetch) t_SinkC__io_task_bits_aMergeTask_meta_prefetch = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_prefetch = g_SinkC__io_task_bits_aMergeTask_meta_prefetch;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc !== i_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_prefetchSrc g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc, i_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc !== p_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc) t_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc = g_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_accessed !== i_SinkC__io_task_bits_aMergeTask_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_accessed g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_accessed, i_SinkC__io_task_bits_aMergeTask_meta_accessed);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_accessed !== p_SinkC__io_task_bits_aMergeTask_meta_accessed) t_SinkC__io_task_bits_aMergeTask_meta_accessed = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_accessed = g_SinkC__io_task_bits_aMergeTask_meta_accessed;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_tagErr !== i_SinkC__io_task_bits_aMergeTask_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_tagErr g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_tagErr, i_SinkC__io_task_bits_aMergeTask_meta_tagErr);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_tagErr !== p_SinkC__io_task_bits_aMergeTask_meta_tagErr) t_SinkC__io_task_bits_aMergeTask_meta_tagErr = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_tagErr = g_SinkC__io_task_bits_aMergeTask_meta_tagErr;
    checks++;
    if (g_SinkC__io_task_bits_aMergeTask_meta_dataErr !== i_SinkC__io_task_bits_aMergeTask_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_aMergeTask_meta_dataErr g=%h i=%h", cyc, g_SinkC__io_task_bits_aMergeTask_meta_dataErr, i_SinkC__io_task_bits_aMergeTask_meta_dataErr);
    end
    if (g_SinkC__io_task_bits_aMergeTask_meta_dataErr !== p_SinkC__io_task_bits_aMergeTask_meta_dataErr) t_SinkC__io_task_bits_aMergeTask_meta_dataErr = 1'b1;
    p_SinkC__io_task_bits_aMergeTask_meta_dataErr = g_SinkC__io_task_bits_aMergeTask_meta_dataErr;
    checks++;
    if (g_SinkC__io_task_bits_snpHitRelease !== i_SinkC__io_task_bits_snpHitRelease) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitRelease g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitRelease, i_SinkC__io_task_bits_snpHitRelease);
    end
    if (g_SinkC__io_task_bits_snpHitRelease !== p_SinkC__io_task_bits_snpHitRelease) t_SinkC__io_task_bits_snpHitRelease = 1'b1;
    p_SinkC__io_task_bits_snpHitRelease = g_SinkC__io_task_bits_snpHitRelease;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseToInval !== i_SinkC__io_task_bits_snpHitReleaseToInval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseToInval g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseToInval, i_SinkC__io_task_bits_snpHitReleaseToInval);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseToInval !== p_SinkC__io_task_bits_snpHitReleaseToInval) t_SinkC__io_task_bits_snpHitReleaseToInval = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseToInval = g_SinkC__io_task_bits_snpHitReleaseToInval;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseToClean !== i_SinkC__io_task_bits_snpHitReleaseToClean) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseToClean g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseToClean, i_SinkC__io_task_bits_snpHitReleaseToClean);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseToClean !== p_SinkC__io_task_bits_snpHitReleaseToClean) t_SinkC__io_task_bits_snpHitReleaseToClean = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseToClean = g_SinkC__io_task_bits_snpHitReleaseToClean;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseWithData !== i_SinkC__io_task_bits_snpHitReleaseWithData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseWithData g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseWithData, i_SinkC__io_task_bits_snpHitReleaseWithData);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseWithData !== p_SinkC__io_task_bits_snpHitReleaseWithData) t_SinkC__io_task_bits_snpHitReleaseWithData = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseWithData = g_SinkC__io_task_bits_snpHitReleaseWithData;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseIdx !== i_SinkC__io_task_bits_snpHitReleaseIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseIdx g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseIdx, i_SinkC__io_task_bits_snpHitReleaseIdx);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseIdx !== p_SinkC__io_task_bits_snpHitReleaseIdx) t_SinkC__io_task_bits_snpHitReleaseIdx = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseIdx = g_SinkC__io_task_bits_snpHitReleaseIdx;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_dirty !== i_SinkC__io_task_bits_snpHitReleaseMeta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_dirty g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_dirty, i_SinkC__io_task_bits_snpHitReleaseMeta_dirty);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_dirty !== p_SinkC__io_task_bits_snpHitReleaseMeta_dirty) t_SinkC__io_task_bits_snpHitReleaseMeta_dirty = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_dirty = g_SinkC__io_task_bits_snpHitReleaseMeta_dirty;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_state !== i_SinkC__io_task_bits_snpHitReleaseMeta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_state g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_state, i_SinkC__io_task_bits_snpHitReleaseMeta_state);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_state !== p_SinkC__io_task_bits_snpHitReleaseMeta_state) t_SinkC__io_task_bits_snpHitReleaseMeta_state = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_state = g_SinkC__io_task_bits_snpHitReleaseMeta_state;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_clients !== i_SinkC__io_task_bits_snpHitReleaseMeta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_clients g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_clients, i_SinkC__io_task_bits_snpHitReleaseMeta_clients);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_clients !== p_SinkC__io_task_bits_snpHitReleaseMeta_clients) t_SinkC__io_task_bits_snpHitReleaseMeta_clients = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_clients = g_SinkC__io_task_bits_snpHitReleaseMeta_clients;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_alias !== i_SinkC__io_task_bits_snpHitReleaseMeta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_alias g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_alias, i_SinkC__io_task_bits_snpHitReleaseMeta_alias);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_alias !== p_SinkC__io_task_bits_snpHitReleaseMeta_alias) t_SinkC__io_task_bits_snpHitReleaseMeta_alias = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_alias = g_SinkC__io_task_bits_snpHitReleaseMeta_alias;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_prefetch !== i_SinkC__io_task_bits_snpHitReleaseMeta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_prefetch g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_prefetch, i_SinkC__io_task_bits_snpHitReleaseMeta_prefetch);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_prefetch !== p_SinkC__io_task_bits_snpHitReleaseMeta_prefetch) t_SinkC__io_task_bits_snpHitReleaseMeta_prefetch = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_prefetch = g_SinkC__io_task_bits_snpHitReleaseMeta_prefetch;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc !== i_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_prefetchSrc g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc, i_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc !== p_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc) t_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc = g_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_accessed !== i_SinkC__io_task_bits_snpHitReleaseMeta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_accessed g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_accessed, i_SinkC__io_task_bits_snpHitReleaseMeta_accessed);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_accessed !== p_SinkC__io_task_bits_snpHitReleaseMeta_accessed) t_SinkC__io_task_bits_snpHitReleaseMeta_accessed = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_accessed = g_SinkC__io_task_bits_snpHitReleaseMeta_accessed;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_tagErr !== i_SinkC__io_task_bits_snpHitReleaseMeta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_tagErr g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_tagErr, i_SinkC__io_task_bits_snpHitReleaseMeta_tagErr);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_tagErr !== p_SinkC__io_task_bits_snpHitReleaseMeta_tagErr) t_SinkC__io_task_bits_snpHitReleaseMeta_tagErr = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_tagErr = g_SinkC__io_task_bits_snpHitReleaseMeta_tagErr;
    checks++;
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_dataErr !== i_SinkC__io_task_bits_snpHitReleaseMeta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_snpHitReleaseMeta_dataErr g=%h i=%h", cyc, g_SinkC__io_task_bits_snpHitReleaseMeta_dataErr, i_SinkC__io_task_bits_snpHitReleaseMeta_dataErr);
    end
    if (g_SinkC__io_task_bits_snpHitReleaseMeta_dataErr !== p_SinkC__io_task_bits_snpHitReleaseMeta_dataErr) t_SinkC__io_task_bits_snpHitReleaseMeta_dataErr = 1'b1;
    p_SinkC__io_task_bits_snpHitReleaseMeta_dataErr = g_SinkC__io_task_bits_snpHitReleaseMeta_dataErr;
    checks++;
    if (g_SinkC__io_task_bits_tgtID !== i_SinkC__io_task_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_tgtID g=%h i=%h", cyc, g_SinkC__io_task_bits_tgtID, i_SinkC__io_task_bits_tgtID);
    end
    if (g_SinkC__io_task_bits_tgtID !== p_SinkC__io_task_bits_tgtID) t_SinkC__io_task_bits_tgtID = 1'b1;
    p_SinkC__io_task_bits_tgtID = g_SinkC__io_task_bits_tgtID;
    checks++;
    if (g_SinkC__io_task_bits_srcID !== i_SinkC__io_task_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_srcID g=%h i=%h", cyc, g_SinkC__io_task_bits_srcID, i_SinkC__io_task_bits_srcID);
    end
    if (g_SinkC__io_task_bits_srcID !== p_SinkC__io_task_bits_srcID) t_SinkC__io_task_bits_srcID = 1'b1;
    p_SinkC__io_task_bits_srcID = g_SinkC__io_task_bits_srcID;
    checks++;
    if (g_SinkC__io_task_bits_txnID !== i_SinkC__io_task_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_txnID g=%h i=%h", cyc, g_SinkC__io_task_bits_txnID, i_SinkC__io_task_bits_txnID);
    end
    if (g_SinkC__io_task_bits_txnID !== p_SinkC__io_task_bits_txnID) t_SinkC__io_task_bits_txnID = 1'b1;
    p_SinkC__io_task_bits_txnID = g_SinkC__io_task_bits_txnID;
    checks++;
    if (g_SinkC__io_task_bits_homeNID !== i_SinkC__io_task_bits_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_homeNID g=%h i=%h", cyc, g_SinkC__io_task_bits_homeNID, i_SinkC__io_task_bits_homeNID);
    end
    if (g_SinkC__io_task_bits_homeNID !== p_SinkC__io_task_bits_homeNID) t_SinkC__io_task_bits_homeNID = 1'b1;
    p_SinkC__io_task_bits_homeNID = g_SinkC__io_task_bits_homeNID;
    checks++;
    if (g_SinkC__io_task_bits_dbID !== i_SinkC__io_task_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_dbID g=%h i=%h", cyc, g_SinkC__io_task_bits_dbID, i_SinkC__io_task_bits_dbID);
    end
    if (g_SinkC__io_task_bits_dbID !== p_SinkC__io_task_bits_dbID) t_SinkC__io_task_bits_dbID = 1'b1;
    p_SinkC__io_task_bits_dbID = g_SinkC__io_task_bits_dbID;
    checks++;
    if (g_SinkC__io_task_bits_fwdNID !== i_SinkC__io_task_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_fwdNID g=%h i=%h", cyc, g_SinkC__io_task_bits_fwdNID, i_SinkC__io_task_bits_fwdNID);
    end
    if (g_SinkC__io_task_bits_fwdNID !== p_SinkC__io_task_bits_fwdNID) t_SinkC__io_task_bits_fwdNID = 1'b1;
    p_SinkC__io_task_bits_fwdNID = g_SinkC__io_task_bits_fwdNID;
    checks++;
    if (g_SinkC__io_task_bits_fwdTxnID !== i_SinkC__io_task_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_fwdTxnID g=%h i=%h", cyc, g_SinkC__io_task_bits_fwdTxnID, i_SinkC__io_task_bits_fwdTxnID);
    end
    if (g_SinkC__io_task_bits_fwdTxnID !== p_SinkC__io_task_bits_fwdTxnID) t_SinkC__io_task_bits_fwdTxnID = 1'b1;
    p_SinkC__io_task_bits_fwdTxnID = g_SinkC__io_task_bits_fwdTxnID;
    checks++;
    if (g_SinkC__io_task_bits_chiOpcode !== i_SinkC__io_task_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_chiOpcode g=%h i=%h", cyc, g_SinkC__io_task_bits_chiOpcode, i_SinkC__io_task_bits_chiOpcode);
    end
    if (g_SinkC__io_task_bits_chiOpcode !== p_SinkC__io_task_bits_chiOpcode) t_SinkC__io_task_bits_chiOpcode = 1'b1;
    p_SinkC__io_task_bits_chiOpcode = g_SinkC__io_task_bits_chiOpcode;
    checks++;
    if (g_SinkC__io_task_bits_resp !== i_SinkC__io_task_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_resp g=%h i=%h", cyc, g_SinkC__io_task_bits_resp, i_SinkC__io_task_bits_resp);
    end
    if (g_SinkC__io_task_bits_resp !== p_SinkC__io_task_bits_resp) t_SinkC__io_task_bits_resp = 1'b1;
    p_SinkC__io_task_bits_resp = g_SinkC__io_task_bits_resp;
    checks++;
    if (g_SinkC__io_task_bits_fwdState !== i_SinkC__io_task_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_fwdState g=%h i=%h", cyc, g_SinkC__io_task_bits_fwdState, i_SinkC__io_task_bits_fwdState);
    end
    if (g_SinkC__io_task_bits_fwdState !== p_SinkC__io_task_bits_fwdState) t_SinkC__io_task_bits_fwdState = 1'b1;
    p_SinkC__io_task_bits_fwdState = g_SinkC__io_task_bits_fwdState;
    checks++;
    if (g_SinkC__io_task_bits_pCrdType !== i_SinkC__io_task_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_pCrdType g=%h i=%h", cyc, g_SinkC__io_task_bits_pCrdType, i_SinkC__io_task_bits_pCrdType);
    end
    if (g_SinkC__io_task_bits_pCrdType !== p_SinkC__io_task_bits_pCrdType) t_SinkC__io_task_bits_pCrdType = 1'b1;
    p_SinkC__io_task_bits_pCrdType = g_SinkC__io_task_bits_pCrdType;
    checks++;
    if (g_SinkC__io_task_bits_retToSrc !== i_SinkC__io_task_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_retToSrc g=%h i=%h", cyc, g_SinkC__io_task_bits_retToSrc, i_SinkC__io_task_bits_retToSrc);
    end
    if (g_SinkC__io_task_bits_retToSrc !== p_SinkC__io_task_bits_retToSrc) t_SinkC__io_task_bits_retToSrc = 1'b1;
    p_SinkC__io_task_bits_retToSrc = g_SinkC__io_task_bits_retToSrc;
    checks++;
    if (g_SinkC__io_task_bits_likelyshared !== i_SinkC__io_task_bits_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_likelyshared g=%h i=%h", cyc, g_SinkC__io_task_bits_likelyshared, i_SinkC__io_task_bits_likelyshared);
    end
    if (g_SinkC__io_task_bits_likelyshared !== p_SinkC__io_task_bits_likelyshared) t_SinkC__io_task_bits_likelyshared = 1'b1;
    p_SinkC__io_task_bits_likelyshared = g_SinkC__io_task_bits_likelyshared;
    checks++;
    if (g_SinkC__io_task_bits_expCompAck !== i_SinkC__io_task_bits_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_expCompAck g=%h i=%h", cyc, g_SinkC__io_task_bits_expCompAck, i_SinkC__io_task_bits_expCompAck);
    end
    if (g_SinkC__io_task_bits_expCompAck !== p_SinkC__io_task_bits_expCompAck) t_SinkC__io_task_bits_expCompAck = 1'b1;
    p_SinkC__io_task_bits_expCompAck = g_SinkC__io_task_bits_expCompAck;
    checks++;
    if (g_SinkC__io_task_bits_allowRetry !== i_SinkC__io_task_bits_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_allowRetry g=%h i=%h", cyc, g_SinkC__io_task_bits_allowRetry, i_SinkC__io_task_bits_allowRetry);
    end
    if (g_SinkC__io_task_bits_allowRetry !== p_SinkC__io_task_bits_allowRetry) t_SinkC__io_task_bits_allowRetry = 1'b1;
    p_SinkC__io_task_bits_allowRetry = g_SinkC__io_task_bits_allowRetry;
    checks++;
    if (g_SinkC__io_task_bits_memAttr_allocate !== i_SinkC__io_task_bits_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_memAttr_allocate g=%h i=%h", cyc, g_SinkC__io_task_bits_memAttr_allocate, i_SinkC__io_task_bits_memAttr_allocate);
    end
    if (g_SinkC__io_task_bits_memAttr_allocate !== p_SinkC__io_task_bits_memAttr_allocate) t_SinkC__io_task_bits_memAttr_allocate = 1'b1;
    p_SinkC__io_task_bits_memAttr_allocate = g_SinkC__io_task_bits_memAttr_allocate;
    checks++;
    if (g_SinkC__io_task_bits_memAttr_cacheable !== i_SinkC__io_task_bits_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_memAttr_cacheable g=%h i=%h", cyc, g_SinkC__io_task_bits_memAttr_cacheable, i_SinkC__io_task_bits_memAttr_cacheable);
    end
    if (g_SinkC__io_task_bits_memAttr_cacheable !== p_SinkC__io_task_bits_memAttr_cacheable) t_SinkC__io_task_bits_memAttr_cacheable = 1'b1;
    p_SinkC__io_task_bits_memAttr_cacheable = g_SinkC__io_task_bits_memAttr_cacheable;
    checks++;
    if (g_SinkC__io_task_bits_memAttr_device !== i_SinkC__io_task_bits_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_memAttr_device g=%h i=%h", cyc, g_SinkC__io_task_bits_memAttr_device, i_SinkC__io_task_bits_memAttr_device);
    end
    if (g_SinkC__io_task_bits_memAttr_device !== p_SinkC__io_task_bits_memAttr_device) t_SinkC__io_task_bits_memAttr_device = 1'b1;
    p_SinkC__io_task_bits_memAttr_device = g_SinkC__io_task_bits_memAttr_device;
    checks++;
    if (g_SinkC__io_task_bits_memAttr_ewa !== i_SinkC__io_task_bits_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_memAttr_ewa g=%h i=%h", cyc, g_SinkC__io_task_bits_memAttr_ewa, i_SinkC__io_task_bits_memAttr_ewa);
    end
    if (g_SinkC__io_task_bits_memAttr_ewa !== p_SinkC__io_task_bits_memAttr_ewa) t_SinkC__io_task_bits_memAttr_ewa = 1'b1;
    p_SinkC__io_task_bits_memAttr_ewa = g_SinkC__io_task_bits_memAttr_ewa;
    checks++;
    if (g_SinkC__io_task_bits_traceTag !== i_SinkC__io_task_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_task_bits_traceTag g=%h i=%h", cyc, g_SinkC__io_task_bits_traceTag, i_SinkC__io_task_bits_traceTag);
    end
    if (g_SinkC__io_task_bits_traceTag !== p_SinkC__io_task_bits_traceTag) t_SinkC__io_task_bits_traceTag = 1'b1;
    p_SinkC__io_task_bits_traceTag = g_SinkC__io_task_bits_traceTag;
    checks++;
    if (g_SinkC__io_resp_valid !== i_SinkC__io_resp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_valid g=%h i=%h", cyc, g_SinkC__io_resp_valid, i_SinkC__io_resp_valid);
    end
    if (g_SinkC__io_resp_valid !== p_SinkC__io_resp_valid) t_SinkC__io_resp_valid = 1'b1;
    p_SinkC__io_resp_valid = g_SinkC__io_resp_valid;
    checks++;
    if (g_SinkC__io_resp_set !== i_SinkC__io_resp_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_set g=%h i=%h", cyc, g_SinkC__io_resp_set, i_SinkC__io_resp_set);
    end
    if (g_SinkC__io_resp_set !== p_SinkC__io_resp_set) t_SinkC__io_resp_set = 1'b1;
    p_SinkC__io_resp_set = g_SinkC__io_resp_set;
    checks++;
    if (g_SinkC__io_resp_tag !== i_SinkC__io_resp_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_tag g=%h i=%h", cyc, g_SinkC__io_resp_tag, i_SinkC__io_resp_tag);
    end
    if (g_SinkC__io_resp_tag !== p_SinkC__io_resp_tag) t_SinkC__io_resp_tag = 1'b1;
    p_SinkC__io_resp_tag = g_SinkC__io_resp_tag;
    checks++;
    if (g_SinkC__io_resp_respInfo_opcode !== i_SinkC__io_resp_respInfo_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_respInfo_opcode g=%h i=%h", cyc, g_SinkC__io_resp_respInfo_opcode, i_SinkC__io_resp_respInfo_opcode);
    end
    if (g_SinkC__io_resp_respInfo_opcode !== p_SinkC__io_resp_respInfo_opcode) t_SinkC__io_resp_respInfo_opcode = 1'b1;
    p_SinkC__io_resp_respInfo_opcode = g_SinkC__io_resp_respInfo_opcode;
    checks++;
    if (g_SinkC__io_resp_respInfo_param !== i_SinkC__io_resp_respInfo_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_respInfo_param g=%h i=%h", cyc, g_SinkC__io_resp_respInfo_param, i_SinkC__io_resp_respInfo_param);
    end
    if (g_SinkC__io_resp_respInfo_param !== p_SinkC__io_resp_respInfo_param) t_SinkC__io_resp_respInfo_param = 1'b1;
    p_SinkC__io_resp_respInfo_param = g_SinkC__io_resp_respInfo_param;
    checks++;
    if (g_SinkC__io_resp_respInfo_last !== i_SinkC__io_resp_respInfo_last) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_respInfo_last g=%h i=%h", cyc, g_SinkC__io_resp_respInfo_last, i_SinkC__io_resp_respInfo_last);
    end
    if (g_SinkC__io_resp_respInfo_last !== p_SinkC__io_resp_respInfo_last) t_SinkC__io_resp_respInfo_last = 1'b1;
    p_SinkC__io_resp_respInfo_last = g_SinkC__io_resp_respInfo_last;
    checks++;
    if (g_SinkC__io_resp_respInfo_denied !== i_SinkC__io_resp_respInfo_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_respInfo_denied g=%h i=%h", cyc, g_SinkC__io_resp_respInfo_denied, i_SinkC__io_resp_respInfo_denied);
    end
    if (g_SinkC__io_resp_respInfo_denied !== p_SinkC__io_resp_respInfo_denied) t_SinkC__io_resp_respInfo_denied = 1'b1;
    p_SinkC__io_resp_respInfo_denied = g_SinkC__io_resp_respInfo_denied;
    checks++;
    if (g_SinkC__io_resp_respInfo_corrupt !== i_SinkC__io_resp_respInfo_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_resp_respInfo_corrupt g=%h i=%h", cyc, g_SinkC__io_resp_respInfo_corrupt, i_SinkC__io_resp_respInfo_corrupt);
    end
    if (g_SinkC__io_resp_respInfo_corrupt !== p_SinkC__io_resp_respInfo_corrupt) t_SinkC__io_resp_respInfo_corrupt = 1'b1;
    p_SinkC__io_resp_respInfo_corrupt = g_SinkC__io_resp_respInfo_corrupt;
    checks++;
    if (g_SinkC__io_releaseBufWrite_valid !== i_SinkC__io_releaseBufWrite_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_releaseBufWrite_valid g=%h i=%h", cyc, g_SinkC__io_releaseBufWrite_valid, i_SinkC__io_releaseBufWrite_valid);
    end
    if (g_SinkC__io_releaseBufWrite_valid !== p_SinkC__io_releaseBufWrite_valid) t_SinkC__io_releaseBufWrite_valid = 1'b1;
    p_SinkC__io_releaseBufWrite_valid = g_SinkC__io_releaseBufWrite_valid;
    checks++;
    if (g_SinkC__io_releaseBufWrite_bits_data_data !== i_SinkC__io_releaseBufWrite_bits_data_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_releaseBufWrite_bits_data_data g=%h i=%h", cyc, g_SinkC__io_releaseBufWrite_bits_data_data, i_SinkC__io_releaseBufWrite_bits_data_data);
    end
    if (g_SinkC__io_releaseBufWrite_bits_data_data !== p_SinkC__io_releaseBufWrite_bits_data_data) t_SinkC__io_releaseBufWrite_bits_data_data = 1'b1;
    p_SinkC__io_releaseBufWrite_bits_data_data = g_SinkC__io_releaseBufWrite_bits_data_data;
    checks++;
    if (g_SinkC__io_bufResp_data_0 !== i_SinkC__io_bufResp_data_0) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_bufResp_data_0 g=%h i=%h", cyc, g_SinkC__io_bufResp_data_0, i_SinkC__io_bufResp_data_0);
    end
    if (g_SinkC__io_bufResp_data_0 !== p_SinkC__io_bufResp_data_0) t_SinkC__io_bufResp_data_0 = 1'b1;
    p_SinkC__io_bufResp_data_0 = g_SinkC__io_bufResp_data_0;
    checks++;
    if (g_SinkC__io_bufResp_data_1 !== i_SinkC__io_bufResp_data_1) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_bufResp_data_1 g=%h i=%h", cyc, g_SinkC__io_bufResp_data_1, i_SinkC__io_bufResp_data_1);
    end
    if (g_SinkC__io_bufResp_data_1 !== p_SinkC__io_bufResp_data_1) t_SinkC__io_bufResp_data_1 = 1'b1;
    p_SinkC__io_bufResp_data_1 = g_SinkC__io_bufResp_data_1;
    checks++;
    if (g_SinkC__io_refillBufWrite_valid !== i_SinkC__io_refillBufWrite_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_refillBufWrite_valid g=%h i=%h", cyc, g_SinkC__io_refillBufWrite_valid, i_SinkC__io_refillBufWrite_valid);
    end
    if (g_SinkC__io_refillBufWrite_valid !== p_SinkC__io_refillBufWrite_valid) t_SinkC__io_refillBufWrite_valid = 1'b1;
    p_SinkC__io_refillBufWrite_valid = g_SinkC__io_refillBufWrite_valid;
    checks++;
    if (g_SinkC__io_refillBufWrite_bits_id !== i_SinkC__io_refillBufWrite_bits_id) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_refillBufWrite_bits_id g=%h i=%h", cyc, g_SinkC__io_refillBufWrite_bits_id, i_SinkC__io_refillBufWrite_bits_id);
    end
    if (g_SinkC__io_refillBufWrite_bits_id !== p_SinkC__io_refillBufWrite_bits_id) t_SinkC__io_refillBufWrite_bits_id = 1'b1;
    p_SinkC__io_refillBufWrite_bits_id = g_SinkC__io_refillBufWrite_bits_id;
    checks++;
    if (g_SinkC__io_refillBufWrite_bits_data_data !== i_SinkC__io_refillBufWrite_bits_data_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH SinkC.io_refillBufWrite_bits_data_data g=%h i=%h", cyc, g_SinkC__io_refillBufWrite_bits_data_data, i_SinkC__io_refillBufWrite_bits_data_data);
    end
    if (g_SinkC__io_refillBufWrite_bits_data_data !== p_SinkC__io_refillBufWrite_bits_data_data) t_SinkC__io_refillBufWrite_bits_data_data = 1'b1;
    p_SinkC__io_refillBufWrite_bits_data_data = g_SinkC__io_refillBufWrite_bits_data_data;
  endtask
  longint cov_SinkC_full = 0;
  longint cov_SinkC_stall = 0;
  longint cov_SinkC_task = 0;
  longint cov_SinkC_refill = 0;
  longint cov_SinkC_pAckData = 0;
  longint cov_SinkC_twoBeat = 0;
  task automatic cover_SinkC();
    if (u_g_SinkC.full_probe) cov_SinkC_full++;
    if (u_g_SinkC.stall_probe) cov_SinkC_stall++;
    if (u_g_SinkC.io_task_valid && u_g_SinkC.io_task_ready) cov_SinkC_task++;
    if (u_g_SinkC.io_refillBufWrite_valid) cov_SinkC_refill++;
    if (u_g_SinkC.io_releaseBufWrite_valid) cov_SinkC_pAckData++;
    if (u_g_SinkC.r_counter) cov_SinkC_twoBeat++;
  endtask
  task automatic preinit_SinkC();
  endtask
  task automatic sync_SinkC();
    force u_i_SinkC.u_core.bufRespStage[0] = u_g_SinkC.r_0;
    #0 release u_i_SinkC.u_core.bufRespStage[0];
    force u_i_SinkC.u_core.bufRespStage[1] = u_g_SinkC.r_1;
    #0 release u_i_SinkC.u_core.bufRespStage[1];
    force u_i_SinkC.u_core.bufRespOut[0] = u_g_SinkC.REG_0;
    #0 release u_i_SinkC.u_core.bufRespOut[0];
    force u_i_SinkC.u_core.bufRespOut[1] = u_g_SinkC.REG_1;
    #0 release u_i_SinkC.u_core.bufRespOut[1];
    force u_i_SinkC.u_core.refillIdReg = u_g_SinkC.io_refillBufWrite_bits_id_REG;
    #0 release u_i_SinkC.u_core.refillIdReg;
    force u_i_SinkC.u_core.refillBufIdxReg = u_g_SinkC.io_refillBufWrite_bits_data_data_REG;
    #0 release u_i_SinkC.u_core.refillBufIdxReg;
    force u_i_SinkC.u_core.taskFirePrev = u_g_SinkC.REG_1_0;
    #0 release u_i_SinkC.u_core.taskFirePrev;
    force u_i_SinkC.u_core.taskBufIdxPrev = u_g_SinkC.REG_2;
    #0 release u_i_SinkC.u_core.taskBufIdxPrev;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_SinkC();
    #1;
    preinit_SinkC();
    sync_SinkC();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_SinkC();
      #1;
      check_SinkC();
      cover_SinkC();
    end
    begin int tg; tg = 0;
      if (t_SinkC__io_c_ready) tg++; else $display("COV: SinkC.io_c_ready never toggled");
      if (t_SinkC__io_task_valid) tg++; else $display("COV: SinkC.io_task_valid never toggled");
      if (t_SinkC__io_task_bits_channel) tg++; else $display("COV: SinkC.io_task_bits_channel never toggled");
      if (t_SinkC__io_task_bits_txChannel) tg++; else $display("COV: SinkC.io_task_bits_txChannel never toggled");
      if (t_SinkC__io_task_bits_set) tg++; else $display("COV: SinkC.io_task_bits_set never toggled");
      if (t_SinkC__io_task_bits_tag) tg++; else $display("COV: SinkC.io_task_bits_tag never toggled");
      if (t_SinkC__io_task_bits_off) tg++; else $display("COV: SinkC.io_task_bits_off never toggled");
      if (t_SinkC__io_task_bits_alias) tg++; else $display("COV: SinkC.io_task_bits_alias never toggled");
      if (t_SinkC__io_task_bits_vaddr) tg++; else $display("COV: SinkC.io_task_bits_vaddr never toggled");
      if (t_SinkC__io_task_bits_isKeyword) tg++; else $display("COV: SinkC.io_task_bits_isKeyword never toggled");
      if (t_SinkC__io_task_bits_opcode) tg++; else $display("COV: SinkC.io_task_bits_opcode never toggled");
      if (t_SinkC__io_task_bits_param) tg++; else $display("COV: SinkC.io_task_bits_param never toggled");
      if (t_SinkC__io_task_bits_size) tg++; else $display("COV: SinkC.io_task_bits_size never toggled");
      if (t_SinkC__io_task_bits_sourceId) tg++; else $display("COV: SinkC.io_task_bits_sourceId never toggled");
      if (t_SinkC__io_task_bits_bufIdx) tg++; else $display("COV: SinkC.io_task_bits_bufIdx never toggled");
      if (t_SinkC__io_task_bits_needProbeAckData) tg++; else $display("COV: SinkC.io_task_bits_needProbeAckData never toggled");
      if (t_SinkC__io_task_bits_denied) tg++; else $display("COV: SinkC.io_task_bits_denied never toggled");
      if (t_SinkC__io_task_bits_corrupt) tg++; else $display("COV: SinkC.io_task_bits_corrupt never toggled");
      if (t_SinkC__io_task_bits_mshrTask) tg++; else $display("COV: SinkC.io_task_bits_mshrTask never toggled");
      if (t_SinkC__io_task_bits_mshrId) tg++; else $display("COV: SinkC.io_task_bits_mshrId never toggled");
      if (t_SinkC__io_task_bits_aliasTask) tg++; else $display("COV: SinkC.io_task_bits_aliasTask never toggled");
      if (t_SinkC__io_task_bits_useProbeData) tg++; else $display("COV: SinkC.io_task_bits_useProbeData never toggled");
      if (t_SinkC__io_task_bits_mshrRetry) tg++; else $display("COV: SinkC.io_task_bits_mshrRetry never toggled");
      if (t_SinkC__io_task_bits_readProbeDataDown) tg++; else $display("COV: SinkC.io_task_bits_readProbeDataDown never toggled");
      if (t_SinkC__io_task_bits_fromL2pft) tg++; else $display("COV: SinkC.io_task_bits_fromL2pft never toggled");
      if (t_SinkC__io_task_bits_needHint) tg++; else $display("COV: SinkC.io_task_bits_needHint never toggled");
      if (t_SinkC__io_task_bits_dirty) tg++; else $display("COV: SinkC.io_task_bits_dirty never toggled");
      if (t_SinkC__io_task_bits_way) tg++; else $display("COV: SinkC.io_task_bits_way never toggled");
      if (t_SinkC__io_task_bits_meta_dirty) tg++; else $display("COV: SinkC.io_task_bits_meta_dirty never toggled");
      if (t_SinkC__io_task_bits_meta_state) tg++; else $display("COV: SinkC.io_task_bits_meta_state never toggled");
      if (t_SinkC__io_task_bits_meta_clients) tg++; else $display("COV: SinkC.io_task_bits_meta_clients never toggled");
      if (t_SinkC__io_task_bits_meta_alias) tg++; else $display("COV: SinkC.io_task_bits_meta_alias never toggled");
      if (t_SinkC__io_task_bits_meta_prefetch) tg++; else $display("COV: SinkC.io_task_bits_meta_prefetch never toggled");
      if (t_SinkC__io_task_bits_meta_prefetchSrc) tg++; else $display("COV: SinkC.io_task_bits_meta_prefetchSrc never toggled");
      if (t_SinkC__io_task_bits_meta_accessed) tg++; else $display("COV: SinkC.io_task_bits_meta_accessed never toggled");
      if (t_SinkC__io_task_bits_meta_tagErr) tg++; else $display("COV: SinkC.io_task_bits_meta_tagErr never toggled");
      if (t_SinkC__io_task_bits_meta_dataErr) tg++; else $display("COV: SinkC.io_task_bits_meta_dataErr never toggled");
      if (t_SinkC__io_task_bits_metaWen) tg++; else $display("COV: SinkC.io_task_bits_metaWen never toggled");
      if (t_SinkC__io_task_bits_tagWen) tg++; else $display("COV: SinkC.io_task_bits_tagWen never toggled");
      if (t_SinkC__io_task_bits_dsWen) tg++; else $display("COV: SinkC.io_task_bits_dsWen never toggled");
      if (t_SinkC__io_task_bits_wayMask) tg++; else $display("COV: SinkC.io_task_bits_wayMask never toggled");
      if (t_SinkC__io_task_bits_replTask) tg++; else $display("COV: SinkC.io_task_bits_replTask never toggled");
      if (t_SinkC__io_task_bits_cmoTask) tg++; else $display("COV: SinkC.io_task_bits_cmoTask never toggled");
      if (t_SinkC__io_task_bits_cmoAll) tg++; else $display("COV: SinkC.io_task_bits_cmoAll never toggled");
      if (t_SinkC__io_task_bits_reqSource) tg++; else $display("COV: SinkC.io_task_bits_reqSource never toggled");
      if (t_SinkC__io_task_bits_mergeA) tg++; else $display("COV: SinkC.io_task_bits_mergeA never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_off) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_off never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_alias) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_alias never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_vaddr) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_vaddr never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_isKeyword) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_isKeyword never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_opcode) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_opcode never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_param) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_param never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_sourceId) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_sourceId never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_dirty) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_dirty never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_state) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_state never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_clients) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_clients never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_alias) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_alias never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_prefetch) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_prefetch never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_prefetchSrc) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_prefetchSrc never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_accessed) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_accessed never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_tagErr) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_tagErr never toggled");
      if (t_SinkC__io_task_bits_aMergeTask_meta_dataErr) tg++; else $display("COV: SinkC.io_task_bits_aMergeTask_meta_dataErr never toggled");
      if (t_SinkC__io_task_bits_snpHitRelease) tg++; else $display("COV: SinkC.io_task_bits_snpHitRelease never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseToInval) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseToInval never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseToClean) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseToClean never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseWithData) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseWithData never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseIdx) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseIdx never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_dirty) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_dirty never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_state) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_state never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_clients) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_clients never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_alias) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_alias never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_prefetch) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_prefetch never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_prefetchSrc) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_prefetchSrc never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_accessed) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_accessed never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_tagErr) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_tagErr never toggled");
      if (t_SinkC__io_task_bits_snpHitReleaseMeta_dataErr) tg++; else $display("COV: SinkC.io_task_bits_snpHitReleaseMeta_dataErr never toggled");
      if (t_SinkC__io_task_bits_tgtID) tg++; else $display("COV: SinkC.io_task_bits_tgtID never toggled");
      if (t_SinkC__io_task_bits_srcID) tg++; else $display("COV: SinkC.io_task_bits_srcID never toggled");
      if (t_SinkC__io_task_bits_txnID) tg++; else $display("COV: SinkC.io_task_bits_txnID never toggled");
      if (t_SinkC__io_task_bits_homeNID) tg++; else $display("COV: SinkC.io_task_bits_homeNID never toggled");
      if (t_SinkC__io_task_bits_dbID) tg++; else $display("COV: SinkC.io_task_bits_dbID never toggled");
      if (t_SinkC__io_task_bits_fwdNID) tg++; else $display("COV: SinkC.io_task_bits_fwdNID never toggled");
      if (t_SinkC__io_task_bits_fwdTxnID) tg++; else $display("COV: SinkC.io_task_bits_fwdTxnID never toggled");
      if (t_SinkC__io_task_bits_chiOpcode) tg++; else $display("COV: SinkC.io_task_bits_chiOpcode never toggled");
      if (t_SinkC__io_task_bits_resp) tg++; else $display("COV: SinkC.io_task_bits_resp never toggled");
      if (t_SinkC__io_task_bits_fwdState) tg++; else $display("COV: SinkC.io_task_bits_fwdState never toggled");
      if (t_SinkC__io_task_bits_pCrdType) tg++; else $display("COV: SinkC.io_task_bits_pCrdType never toggled");
      if (t_SinkC__io_task_bits_retToSrc) tg++; else $display("COV: SinkC.io_task_bits_retToSrc never toggled");
      if (t_SinkC__io_task_bits_likelyshared) tg++; else $display("COV: SinkC.io_task_bits_likelyshared never toggled");
      if (t_SinkC__io_task_bits_expCompAck) tg++; else $display("COV: SinkC.io_task_bits_expCompAck never toggled");
      if (t_SinkC__io_task_bits_allowRetry) tg++; else $display("COV: SinkC.io_task_bits_allowRetry never toggled");
      if (t_SinkC__io_task_bits_memAttr_allocate) tg++; else $display("COV: SinkC.io_task_bits_memAttr_allocate never toggled");
      if (t_SinkC__io_task_bits_memAttr_cacheable) tg++; else $display("COV: SinkC.io_task_bits_memAttr_cacheable never toggled");
      if (t_SinkC__io_task_bits_memAttr_device) tg++; else $display("COV: SinkC.io_task_bits_memAttr_device never toggled");
      if (t_SinkC__io_task_bits_memAttr_ewa) tg++; else $display("COV: SinkC.io_task_bits_memAttr_ewa never toggled");
      if (t_SinkC__io_task_bits_traceTag) tg++; else $display("COV: SinkC.io_task_bits_traceTag never toggled");
      if (t_SinkC__io_resp_valid) tg++; else $display("COV: SinkC.io_resp_valid never toggled");
      if (t_SinkC__io_resp_set) tg++; else $display("COV: SinkC.io_resp_set never toggled");
      if (t_SinkC__io_resp_tag) tg++; else $display("COV: SinkC.io_resp_tag never toggled");
      if (t_SinkC__io_resp_respInfo_opcode) tg++; else $display("COV: SinkC.io_resp_respInfo_opcode never toggled");
      if (t_SinkC__io_resp_respInfo_param) tg++; else $display("COV: SinkC.io_resp_respInfo_param never toggled");
      if (t_SinkC__io_resp_respInfo_last) tg++; else $display("COV: SinkC.io_resp_respInfo_last never toggled");
      if (t_SinkC__io_resp_respInfo_denied) tg++; else $display("COV: SinkC.io_resp_respInfo_denied never toggled");
      if (t_SinkC__io_resp_respInfo_corrupt) tg++; else $display("COV: SinkC.io_resp_respInfo_corrupt never toggled");
      if (t_SinkC__io_releaseBufWrite_valid) tg++; else $display("COV: SinkC.io_releaseBufWrite_valid never toggled");
      if (t_SinkC__io_releaseBufWrite_bits_data_data) tg++; else $display("COV: SinkC.io_releaseBufWrite_bits_data_data never toggled");
      if (t_SinkC__io_bufResp_data_0) tg++; else $display("COV: SinkC.io_bufResp_data_0 never toggled");
      if (t_SinkC__io_bufResp_data_1) tg++; else $display("COV: SinkC.io_bufResp_data_1 never toggled");
      if (t_SinkC__io_refillBufWrite_valid) tg++; else $display("COV: SinkC.io_refillBufWrite_valid never toggled");
      if (t_SinkC__io_refillBufWrite_bits_id) tg++; else $display("COV: SinkC.io_refillBufWrite_bits_id never toggled");
      if (t_SinkC__io_refillBufWrite_bits_data_data) tg++; else $display("COV: SinkC.io_refillBufWrite_bits_data_data never toggled");
      $display("SinkC: toggled=%0d/111 (need >= 111)", tg);
      if (tg < 111) covfail = 1;
      $display("SinkC: cover full = %0d", cov_SinkC_full);
      if (cov_SinkC_full == 0) covfail = 1;
      $display("SinkC: cover stall = %0d", cov_SinkC_stall);
      if (cov_SinkC_stall == 0) covfail = 1;
      $display("SinkC: cover task = %0d", cov_SinkC_task);
      if (cov_SinkC_task == 0) covfail = 1;
      $display("SinkC: cover refill = %0d", cov_SinkC_refill);
      if (cov_SinkC_refill == 0) covfail = 1;
      $display("SinkC: cover pAckData = %0d", cov_SinkC_pAckData);
      if (cov_SinkC_pAckData == 0) covfail = 1;
      $display("SinkC: cover twoBeat = %0d", cov_SinkC_twoBeat);
      if (cov_SinkC_twoBeat == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
