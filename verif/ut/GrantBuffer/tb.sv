// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：GrantBuffer Queue10_GrantBuffer_Anon
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

  // ======================= GrantBuffer =======================
  logic GrantBuffer__io_d_task_valid;
  logic [2:0] GrantBuffer__io_d_task_bits_task_channel;
  logic [2:0] GrantBuffer__io_d_task_bits_task_txChannel;
  logic [8:0] GrantBuffer__io_d_task_bits_task_set;
  logic [30:0] GrantBuffer__io_d_task_bits_task_tag;
  logic [5:0] GrantBuffer__io_d_task_bits_task_off;
  logic [1:0] GrantBuffer__io_d_task_bits_task_alias;
  logic [43:0] GrantBuffer__io_d_task_bits_task_vaddr;
  logic GrantBuffer__io_d_task_bits_task_isKeyword;
  logic [3:0] GrantBuffer__io_d_task_bits_task_opcode;
  logic [2:0] GrantBuffer__io_d_task_bits_task_param;
  logic [2:0] GrantBuffer__io_d_task_bits_task_size;
  logic [6:0] GrantBuffer__io_d_task_bits_task_sourceId;
  logic [1:0] GrantBuffer__io_d_task_bits_task_bufIdx;
  logic GrantBuffer__io_d_task_bits_task_needProbeAckData;
  logic GrantBuffer__io_d_task_bits_task_denied;
  logic GrantBuffer__io_d_task_bits_task_corrupt;
  logic GrantBuffer__io_d_task_bits_task_mshrTask;
  logic [7:0] GrantBuffer__io_d_task_bits_task_mshrId;
  logic GrantBuffer__io_d_task_bits_task_aliasTask;
  logic GrantBuffer__io_d_task_bits_task_useProbeData;
  logic GrantBuffer__io_d_task_bits_task_mshrRetry;
  logic GrantBuffer__io_d_task_bits_task_readProbeDataDown;
  logic GrantBuffer__io_d_task_bits_task_fromL2pft;
  logic GrantBuffer__io_d_task_bits_task_needHint;
  logic GrantBuffer__io_d_task_bits_task_dirty;
  logic [2:0] GrantBuffer__io_d_task_bits_task_way;
  logic GrantBuffer__io_d_task_bits_task_meta_dirty;
  logic [1:0] GrantBuffer__io_d_task_bits_task_meta_state;
  logic GrantBuffer__io_d_task_bits_task_meta_clients;
  logic [1:0] GrantBuffer__io_d_task_bits_task_meta_alias;
  logic GrantBuffer__io_d_task_bits_task_meta_prefetch;
  logic [2:0] GrantBuffer__io_d_task_bits_task_meta_prefetchSrc;
  logic GrantBuffer__io_d_task_bits_task_meta_accessed;
  logic GrantBuffer__io_d_task_bits_task_meta_tagErr;
  logic GrantBuffer__io_d_task_bits_task_meta_dataErr;
  logic GrantBuffer__io_d_task_bits_task_metaWen;
  logic GrantBuffer__io_d_task_bits_task_tagWen;
  logic GrantBuffer__io_d_task_bits_task_dsWen;
  logic [7:0] GrantBuffer__io_d_task_bits_task_wayMask;
  logic GrantBuffer__io_d_task_bits_task_replTask;
  logic GrantBuffer__io_d_task_bits_task_cmoTask;
  logic GrantBuffer__io_d_task_bits_task_cmoAll;
  logic [4:0] GrantBuffer__io_d_task_bits_task_reqSource;
  logic GrantBuffer__io_d_task_bits_task_mergeA;
  logic [5:0] GrantBuffer__io_d_task_bits_task_aMergeTask_off;
  logic [1:0] GrantBuffer__io_d_task_bits_task_aMergeTask_alias;
  logic [43:0] GrantBuffer__io_d_task_bits_task_aMergeTask_vaddr;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_isKeyword;
  logic [2:0] GrantBuffer__io_d_task_bits_task_aMergeTask_opcode;
  logic [2:0] GrantBuffer__io_d_task_bits_task_aMergeTask_param;
  logic [6:0] GrantBuffer__io_d_task_bits_task_aMergeTask_sourceId;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dirty;
  logic [1:0] GrantBuffer__io_d_task_bits_task_aMergeTask_meta_state;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_meta_clients;
  logic [1:0] GrantBuffer__io_d_task_bits_task_aMergeTask_meta_alias;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetchSrc;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_meta_accessed;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_meta_tagErr;
  logic GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dataErr;
  logic GrantBuffer__io_d_task_bits_task_snpHitRelease;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseToInval;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseToClean;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseWithData;
  logic [7:0] GrantBuffer__io_d_task_bits_task_snpHitReleaseIdx;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_state;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_alias;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_accessed;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_tagErr;
  logic GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] GrantBuffer__io_d_task_bits_task_tgtID;
  logic [10:0] GrantBuffer__io_d_task_bits_task_srcID;
  logic [11:0] GrantBuffer__io_d_task_bits_task_txnID;
  logic [10:0] GrantBuffer__io_d_task_bits_task_homeNID;
  logic [11:0] GrantBuffer__io_d_task_bits_task_dbID;
  logic [10:0] GrantBuffer__io_d_task_bits_task_fwdNID;
  logic [11:0] GrantBuffer__io_d_task_bits_task_fwdTxnID;
  logic [6:0] GrantBuffer__io_d_task_bits_task_chiOpcode;
  logic [2:0] GrantBuffer__io_d_task_bits_task_resp;
  logic [2:0] GrantBuffer__io_d_task_bits_task_fwdState;
  logic [3:0] GrantBuffer__io_d_task_bits_task_pCrdType;
  logic GrantBuffer__io_d_task_bits_task_retToSrc;
  logic GrantBuffer__io_d_task_bits_task_likelyshared;
  logic GrantBuffer__io_d_task_bits_task_expCompAck;
  logic GrantBuffer__io_d_task_bits_task_allowRetry;
  logic GrantBuffer__io_d_task_bits_task_memAttr_allocate;
  logic GrantBuffer__io_d_task_bits_task_memAttr_cacheable;
  logic GrantBuffer__io_d_task_bits_task_memAttr_device;
  logic GrantBuffer__io_d_task_bits_task_memAttr_ewa;
  logic GrantBuffer__io_d_task_bits_task_traceTag;
  logic [511:0] GrantBuffer__io_d_task_bits_data_data;
  logic GrantBuffer__io_d_ready;
  logic GrantBuffer__io_e_valid;
  logic [7:0] GrantBuffer__io_e_bits_sink;
  logic [30:0] GrantBuffer__io_fromReqArb_status_s1_tags_1;
  logic [8:0] GrantBuffer__io_fromReqArb_status_s1_sets_1;
  logic GrantBuffer__io_pipeStatusVec_1_valid;
  logic [2:0] GrantBuffer__io_pipeStatusVec_1_bits_channel;
  logic GrantBuffer__io_pipeStatusVec_2_valid;
  logic [2:0] GrantBuffer__io_pipeStatusVec_2_bits_channel;
  logic GrantBuffer__io_pipeStatusVec_3_valid;
  logic [2:0] GrantBuffer__io_pipeStatusVec_3_bits_channel;
  logic GrantBuffer__io_pipeStatusVec_4_valid;
  logic [2:0] GrantBuffer__io_pipeStatusVec_4_bits_channel;
  logic GrantBuffer__io_prefetchResp_ready;
  wire  g_GrantBuffer__io_d_valid;
  wire  i_GrantBuffer__io_d_valid;
  logic p_GrantBuffer__io_d_valid;
  bit   t_GrantBuffer__io_d_valid;
  wire  [3:0] g_GrantBuffer__io_d_bits_opcode;
  wire  [3:0] i_GrantBuffer__io_d_bits_opcode;
  logic [3:0] p_GrantBuffer__io_d_bits_opcode;
  bit   t_GrantBuffer__io_d_bits_opcode;
  wire  [1:0] g_GrantBuffer__io_d_bits_param;
  wire  [1:0] i_GrantBuffer__io_d_bits_param;
  logic [1:0] p_GrantBuffer__io_d_bits_param;
  bit   t_GrantBuffer__io_d_bits_param;
  wire  [6:0] g_GrantBuffer__io_d_bits_source;
  wire  [6:0] i_GrantBuffer__io_d_bits_source;
  logic [6:0] p_GrantBuffer__io_d_bits_source;
  bit   t_GrantBuffer__io_d_bits_source;
  wire  [7:0] g_GrantBuffer__io_d_bits_sink;
  wire  [7:0] i_GrantBuffer__io_d_bits_sink;
  logic [7:0] p_GrantBuffer__io_d_bits_sink;
  bit   t_GrantBuffer__io_d_bits_sink;
  wire  g_GrantBuffer__io_d_bits_denied;
  wire  i_GrantBuffer__io_d_bits_denied;
  logic p_GrantBuffer__io_d_bits_denied;
  bit   t_GrantBuffer__io_d_bits_denied;
  wire  g_GrantBuffer__io_d_bits_echo_isKeyword;
  wire  i_GrantBuffer__io_d_bits_echo_isKeyword;
  logic p_GrantBuffer__io_d_bits_echo_isKeyword;
  bit   t_GrantBuffer__io_d_bits_echo_isKeyword;
  wire  [255:0] g_GrantBuffer__io_d_bits_data;
  wire  [255:0] i_GrantBuffer__io_d_bits_data;
  logic [255:0] p_GrantBuffer__io_d_bits_data;
  bit   t_GrantBuffer__io_d_bits_data;
  wire  g_GrantBuffer__io_d_bits_corrupt;
  wire  i_GrantBuffer__io_d_bits_corrupt;
  logic p_GrantBuffer__io_d_bits_corrupt;
  bit   t_GrantBuffer__io_d_bits_corrupt;
  wire  g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1;
  wire  i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1;
  logic p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1;
  bit   t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1;
  wire  g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1;
  wire  i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1;
  logic p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1;
  bit   t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1;
  wire  g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1;
  wire  i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1;
  logic p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1;
  bit   t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1;
  wire  g_GrantBuffer__io_toReqArb_blockMSHRReqEntrance;
  wire  i_GrantBuffer__io_toReqArb_blockMSHRReqEntrance;
  logic p_GrantBuffer__io_toReqArb_blockMSHRReqEntrance;
  bit   t_GrantBuffer__io_toReqArb_blockMSHRReqEntrance;
  wire  g_GrantBuffer__io_prefetchResp_valid;
  wire  i_GrantBuffer__io_prefetchResp_valid;
  logic p_GrantBuffer__io_prefetchResp_valid;
  bit   t_GrantBuffer__io_prefetchResp_valid;
  wire  [32:0] g_GrantBuffer__io_prefetchResp_bits_tag;
  wire  [32:0] i_GrantBuffer__io_prefetchResp_bits_tag;
  logic [32:0] p_GrantBuffer__io_prefetchResp_bits_tag;
  bit   t_GrantBuffer__io_prefetchResp_bits_tag;
  wire  [8:0] g_GrantBuffer__io_prefetchResp_bits_set;
  wire  [8:0] i_GrantBuffer__io_prefetchResp_bits_set;
  logic [8:0] p_GrantBuffer__io_prefetchResp_bits_set;
  bit   t_GrantBuffer__io_prefetchResp_bits_set;
  wire  [43:0] g_GrantBuffer__io_prefetchResp_bits_vaddr;
  wire  [43:0] i_GrantBuffer__io_prefetchResp_bits_vaddr;
  logic [43:0] p_GrantBuffer__io_prefetchResp_bits_vaddr;
  bit   t_GrantBuffer__io_prefetchResp_bits_vaddr;
  wire  [4:0] g_GrantBuffer__io_prefetchResp_bits_pfSource;
  wire  [4:0] i_GrantBuffer__io_prefetchResp_bits_pfSource;
  logic [4:0] p_GrantBuffer__io_prefetchResp_bits_pfSource;
  bit   t_GrantBuffer__io_prefetchResp_bits_pfSource;
  wire  g_GrantBuffer__io_grantStatus_0_valid;
  wire  i_GrantBuffer__io_grantStatus_0_valid;
  logic p_GrantBuffer__io_grantStatus_0_valid;
  bit   t_GrantBuffer__io_grantStatus_0_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_0_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_0_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_0_set;
  bit   t_GrantBuffer__io_grantStatus_0_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_0_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_0_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_0_tag;
  bit   t_GrantBuffer__io_grantStatus_0_tag;
  wire  g_GrantBuffer__io_grantStatus_1_valid;
  wire  i_GrantBuffer__io_grantStatus_1_valid;
  logic p_GrantBuffer__io_grantStatus_1_valid;
  bit   t_GrantBuffer__io_grantStatus_1_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_1_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_1_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_1_set;
  bit   t_GrantBuffer__io_grantStatus_1_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_1_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_1_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_1_tag;
  bit   t_GrantBuffer__io_grantStatus_1_tag;
  wire  g_GrantBuffer__io_grantStatus_2_valid;
  wire  i_GrantBuffer__io_grantStatus_2_valid;
  logic p_GrantBuffer__io_grantStatus_2_valid;
  bit   t_GrantBuffer__io_grantStatus_2_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_2_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_2_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_2_set;
  bit   t_GrantBuffer__io_grantStatus_2_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_2_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_2_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_2_tag;
  bit   t_GrantBuffer__io_grantStatus_2_tag;
  wire  g_GrantBuffer__io_grantStatus_3_valid;
  wire  i_GrantBuffer__io_grantStatus_3_valid;
  logic p_GrantBuffer__io_grantStatus_3_valid;
  bit   t_GrantBuffer__io_grantStatus_3_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_3_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_3_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_3_set;
  bit   t_GrantBuffer__io_grantStatus_3_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_3_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_3_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_3_tag;
  bit   t_GrantBuffer__io_grantStatus_3_tag;
  wire  g_GrantBuffer__io_grantStatus_4_valid;
  wire  i_GrantBuffer__io_grantStatus_4_valid;
  logic p_GrantBuffer__io_grantStatus_4_valid;
  bit   t_GrantBuffer__io_grantStatus_4_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_4_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_4_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_4_set;
  bit   t_GrantBuffer__io_grantStatus_4_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_4_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_4_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_4_tag;
  bit   t_GrantBuffer__io_grantStatus_4_tag;
  wire  g_GrantBuffer__io_grantStatus_5_valid;
  wire  i_GrantBuffer__io_grantStatus_5_valid;
  logic p_GrantBuffer__io_grantStatus_5_valid;
  bit   t_GrantBuffer__io_grantStatus_5_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_5_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_5_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_5_set;
  bit   t_GrantBuffer__io_grantStatus_5_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_5_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_5_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_5_tag;
  bit   t_GrantBuffer__io_grantStatus_5_tag;
  wire  g_GrantBuffer__io_grantStatus_6_valid;
  wire  i_GrantBuffer__io_grantStatus_6_valid;
  logic p_GrantBuffer__io_grantStatus_6_valid;
  bit   t_GrantBuffer__io_grantStatus_6_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_6_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_6_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_6_set;
  bit   t_GrantBuffer__io_grantStatus_6_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_6_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_6_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_6_tag;
  bit   t_GrantBuffer__io_grantStatus_6_tag;
  wire  g_GrantBuffer__io_grantStatus_7_valid;
  wire  i_GrantBuffer__io_grantStatus_7_valid;
  logic p_GrantBuffer__io_grantStatus_7_valid;
  bit   t_GrantBuffer__io_grantStatus_7_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_7_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_7_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_7_set;
  bit   t_GrantBuffer__io_grantStatus_7_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_7_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_7_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_7_tag;
  bit   t_GrantBuffer__io_grantStatus_7_tag;
  wire  g_GrantBuffer__io_grantStatus_8_valid;
  wire  i_GrantBuffer__io_grantStatus_8_valid;
  logic p_GrantBuffer__io_grantStatus_8_valid;
  bit   t_GrantBuffer__io_grantStatus_8_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_8_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_8_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_8_set;
  bit   t_GrantBuffer__io_grantStatus_8_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_8_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_8_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_8_tag;
  bit   t_GrantBuffer__io_grantStatus_8_tag;
  wire  g_GrantBuffer__io_grantStatus_9_valid;
  wire  i_GrantBuffer__io_grantStatus_9_valid;
  logic p_GrantBuffer__io_grantStatus_9_valid;
  bit   t_GrantBuffer__io_grantStatus_9_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_9_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_9_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_9_set;
  bit   t_GrantBuffer__io_grantStatus_9_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_9_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_9_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_9_tag;
  bit   t_GrantBuffer__io_grantStatus_9_tag;
  wire  g_GrantBuffer__io_grantStatus_10_valid;
  wire  i_GrantBuffer__io_grantStatus_10_valid;
  logic p_GrantBuffer__io_grantStatus_10_valid;
  bit   t_GrantBuffer__io_grantStatus_10_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_10_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_10_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_10_set;
  bit   t_GrantBuffer__io_grantStatus_10_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_10_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_10_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_10_tag;
  bit   t_GrantBuffer__io_grantStatus_10_tag;
  wire  g_GrantBuffer__io_grantStatus_11_valid;
  wire  i_GrantBuffer__io_grantStatus_11_valid;
  logic p_GrantBuffer__io_grantStatus_11_valid;
  bit   t_GrantBuffer__io_grantStatus_11_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_11_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_11_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_11_set;
  bit   t_GrantBuffer__io_grantStatus_11_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_11_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_11_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_11_tag;
  bit   t_GrantBuffer__io_grantStatus_11_tag;
  wire  g_GrantBuffer__io_grantStatus_12_valid;
  wire  i_GrantBuffer__io_grantStatus_12_valid;
  logic p_GrantBuffer__io_grantStatus_12_valid;
  bit   t_GrantBuffer__io_grantStatus_12_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_12_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_12_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_12_set;
  bit   t_GrantBuffer__io_grantStatus_12_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_12_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_12_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_12_tag;
  bit   t_GrantBuffer__io_grantStatus_12_tag;
  wire  g_GrantBuffer__io_grantStatus_13_valid;
  wire  i_GrantBuffer__io_grantStatus_13_valid;
  logic p_GrantBuffer__io_grantStatus_13_valid;
  bit   t_GrantBuffer__io_grantStatus_13_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_13_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_13_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_13_set;
  bit   t_GrantBuffer__io_grantStatus_13_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_13_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_13_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_13_tag;
  bit   t_GrantBuffer__io_grantStatus_13_tag;
  wire  g_GrantBuffer__io_grantStatus_14_valid;
  wire  i_GrantBuffer__io_grantStatus_14_valid;
  logic p_GrantBuffer__io_grantStatus_14_valid;
  bit   t_GrantBuffer__io_grantStatus_14_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_14_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_14_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_14_set;
  bit   t_GrantBuffer__io_grantStatus_14_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_14_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_14_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_14_tag;
  bit   t_GrantBuffer__io_grantStatus_14_tag;
  wire  g_GrantBuffer__io_grantStatus_15_valid;
  wire  i_GrantBuffer__io_grantStatus_15_valid;
  logic p_GrantBuffer__io_grantStatus_15_valid;
  bit   t_GrantBuffer__io_grantStatus_15_valid;
  wire  [8:0] g_GrantBuffer__io_grantStatus_15_set;
  wire  [8:0] i_GrantBuffer__io_grantStatus_15_set;
  logic [8:0] p_GrantBuffer__io_grantStatus_15_set;
  bit   t_GrantBuffer__io_grantStatus_15_set;
  wire  [30:0] g_GrantBuffer__io_grantStatus_15_tag;
  wire  [30:0] i_GrantBuffer__io_grantStatus_15_tag;
  logic [30:0] p_GrantBuffer__io_grantStatus_15_tag;
  bit   t_GrantBuffer__io_grantStatus_15_tag;
  GrantBuffer u_g_GrantBuffer (
    .clock (clock),
    .reset (reset),
    .io_d_task_valid (GrantBuffer__io_d_task_valid),
    .io_d_task_bits_task_channel (GrantBuffer__io_d_task_bits_task_channel),
    .io_d_task_bits_task_txChannel (GrantBuffer__io_d_task_bits_task_txChannel),
    .io_d_task_bits_task_set (GrantBuffer__io_d_task_bits_task_set),
    .io_d_task_bits_task_tag (GrantBuffer__io_d_task_bits_task_tag),
    .io_d_task_bits_task_off (GrantBuffer__io_d_task_bits_task_off),
    .io_d_task_bits_task_alias (GrantBuffer__io_d_task_bits_task_alias),
    .io_d_task_bits_task_vaddr (GrantBuffer__io_d_task_bits_task_vaddr),
    .io_d_task_bits_task_isKeyword (GrantBuffer__io_d_task_bits_task_isKeyword),
    .io_d_task_bits_task_opcode (GrantBuffer__io_d_task_bits_task_opcode),
    .io_d_task_bits_task_param (GrantBuffer__io_d_task_bits_task_param),
    .io_d_task_bits_task_size (GrantBuffer__io_d_task_bits_task_size),
    .io_d_task_bits_task_sourceId (GrantBuffer__io_d_task_bits_task_sourceId),
    .io_d_task_bits_task_bufIdx (GrantBuffer__io_d_task_bits_task_bufIdx),
    .io_d_task_bits_task_needProbeAckData (GrantBuffer__io_d_task_bits_task_needProbeAckData),
    .io_d_task_bits_task_denied (GrantBuffer__io_d_task_bits_task_denied),
    .io_d_task_bits_task_corrupt (GrantBuffer__io_d_task_bits_task_corrupt),
    .io_d_task_bits_task_mshrTask (GrantBuffer__io_d_task_bits_task_mshrTask),
    .io_d_task_bits_task_mshrId (GrantBuffer__io_d_task_bits_task_mshrId),
    .io_d_task_bits_task_aliasTask (GrantBuffer__io_d_task_bits_task_aliasTask),
    .io_d_task_bits_task_useProbeData (GrantBuffer__io_d_task_bits_task_useProbeData),
    .io_d_task_bits_task_mshrRetry (GrantBuffer__io_d_task_bits_task_mshrRetry),
    .io_d_task_bits_task_readProbeDataDown (GrantBuffer__io_d_task_bits_task_readProbeDataDown),
    .io_d_task_bits_task_fromL2pft (GrantBuffer__io_d_task_bits_task_fromL2pft),
    .io_d_task_bits_task_needHint (GrantBuffer__io_d_task_bits_task_needHint),
    .io_d_task_bits_task_dirty (GrantBuffer__io_d_task_bits_task_dirty),
    .io_d_task_bits_task_way (GrantBuffer__io_d_task_bits_task_way),
    .io_d_task_bits_task_meta_dirty (GrantBuffer__io_d_task_bits_task_meta_dirty),
    .io_d_task_bits_task_meta_state (GrantBuffer__io_d_task_bits_task_meta_state),
    .io_d_task_bits_task_meta_clients (GrantBuffer__io_d_task_bits_task_meta_clients),
    .io_d_task_bits_task_meta_alias (GrantBuffer__io_d_task_bits_task_meta_alias),
    .io_d_task_bits_task_meta_prefetch (GrantBuffer__io_d_task_bits_task_meta_prefetch),
    .io_d_task_bits_task_meta_prefetchSrc (GrantBuffer__io_d_task_bits_task_meta_prefetchSrc),
    .io_d_task_bits_task_meta_accessed (GrantBuffer__io_d_task_bits_task_meta_accessed),
    .io_d_task_bits_task_meta_tagErr (GrantBuffer__io_d_task_bits_task_meta_tagErr),
    .io_d_task_bits_task_meta_dataErr (GrantBuffer__io_d_task_bits_task_meta_dataErr),
    .io_d_task_bits_task_metaWen (GrantBuffer__io_d_task_bits_task_metaWen),
    .io_d_task_bits_task_tagWen (GrantBuffer__io_d_task_bits_task_tagWen),
    .io_d_task_bits_task_dsWen (GrantBuffer__io_d_task_bits_task_dsWen),
    .io_d_task_bits_task_wayMask (GrantBuffer__io_d_task_bits_task_wayMask),
    .io_d_task_bits_task_replTask (GrantBuffer__io_d_task_bits_task_replTask),
    .io_d_task_bits_task_cmoTask (GrantBuffer__io_d_task_bits_task_cmoTask),
    .io_d_task_bits_task_cmoAll (GrantBuffer__io_d_task_bits_task_cmoAll),
    .io_d_task_bits_task_reqSource (GrantBuffer__io_d_task_bits_task_reqSource),
    .io_d_task_bits_task_mergeA (GrantBuffer__io_d_task_bits_task_mergeA),
    .io_d_task_bits_task_aMergeTask_off (GrantBuffer__io_d_task_bits_task_aMergeTask_off),
    .io_d_task_bits_task_aMergeTask_alias (GrantBuffer__io_d_task_bits_task_aMergeTask_alias),
    .io_d_task_bits_task_aMergeTask_vaddr (GrantBuffer__io_d_task_bits_task_aMergeTask_vaddr),
    .io_d_task_bits_task_aMergeTask_isKeyword (GrantBuffer__io_d_task_bits_task_aMergeTask_isKeyword),
    .io_d_task_bits_task_aMergeTask_opcode (GrantBuffer__io_d_task_bits_task_aMergeTask_opcode),
    .io_d_task_bits_task_aMergeTask_param (GrantBuffer__io_d_task_bits_task_aMergeTask_param),
    .io_d_task_bits_task_aMergeTask_sourceId (GrantBuffer__io_d_task_bits_task_aMergeTask_sourceId),
    .io_d_task_bits_task_aMergeTask_meta_dirty (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dirty),
    .io_d_task_bits_task_aMergeTask_meta_state (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_state),
    .io_d_task_bits_task_aMergeTask_meta_clients (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_clients),
    .io_d_task_bits_task_aMergeTask_meta_alias (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_alias),
    .io_d_task_bits_task_aMergeTask_meta_prefetch (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetch),
    .io_d_task_bits_task_aMergeTask_meta_prefetchSrc (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetchSrc),
    .io_d_task_bits_task_aMergeTask_meta_accessed (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_accessed),
    .io_d_task_bits_task_aMergeTask_meta_tagErr (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_tagErr),
    .io_d_task_bits_task_aMergeTask_meta_dataErr (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dataErr),
    .io_d_task_bits_task_snpHitRelease (GrantBuffer__io_d_task_bits_task_snpHitRelease),
    .io_d_task_bits_task_snpHitReleaseToInval (GrantBuffer__io_d_task_bits_task_snpHitReleaseToInval),
    .io_d_task_bits_task_snpHitReleaseToClean (GrantBuffer__io_d_task_bits_task_snpHitReleaseToClean),
    .io_d_task_bits_task_snpHitReleaseWithData (GrantBuffer__io_d_task_bits_task_snpHitReleaseWithData),
    .io_d_task_bits_task_snpHitReleaseIdx (GrantBuffer__io_d_task_bits_task_snpHitReleaseIdx),
    .io_d_task_bits_task_snpHitReleaseMeta_dirty (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dirty),
    .io_d_task_bits_task_snpHitReleaseMeta_state (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_state),
    .io_d_task_bits_task_snpHitReleaseMeta_clients (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_clients),
    .io_d_task_bits_task_snpHitReleaseMeta_alias (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_alias),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetch (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetch),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_d_task_bits_task_snpHitReleaseMeta_accessed (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_accessed),
    .io_d_task_bits_task_snpHitReleaseMeta_tagErr (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_tagErr),
    .io_d_task_bits_task_snpHitReleaseMeta_dataErr (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dataErr),
    .io_d_task_bits_task_tgtID (GrantBuffer__io_d_task_bits_task_tgtID),
    .io_d_task_bits_task_srcID (GrantBuffer__io_d_task_bits_task_srcID),
    .io_d_task_bits_task_txnID (GrantBuffer__io_d_task_bits_task_txnID),
    .io_d_task_bits_task_homeNID (GrantBuffer__io_d_task_bits_task_homeNID),
    .io_d_task_bits_task_dbID (GrantBuffer__io_d_task_bits_task_dbID),
    .io_d_task_bits_task_fwdNID (GrantBuffer__io_d_task_bits_task_fwdNID),
    .io_d_task_bits_task_fwdTxnID (GrantBuffer__io_d_task_bits_task_fwdTxnID),
    .io_d_task_bits_task_chiOpcode (GrantBuffer__io_d_task_bits_task_chiOpcode),
    .io_d_task_bits_task_resp (GrantBuffer__io_d_task_bits_task_resp),
    .io_d_task_bits_task_fwdState (GrantBuffer__io_d_task_bits_task_fwdState),
    .io_d_task_bits_task_pCrdType (GrantBuffer__io_d_task_bits_task_pCrdType),
    .io_d_task_bits_task_retToSrc (GrantBuffer__io_d_task_bits_task_retToSrc),
    .io_d_task_bits_task_likelyshared (GrantBuffer__io_d_task_bits_task_likelyshared),
    .io_d_task_bits_task_expCompAck (GrantBuffer__io_d_task_bits_task_expCompAck),
    .io_d_task_bits_task_allowRetry (GrantBuffer__io_d_task_bits_task_allowRetry),
    .io_d_task_bits_task_memAttr_allocate (GrantBuffer__io_d_task_bits_task_memAttr_allocate),
    .io_d_task_bits_task_memAttr_cacheable (GrantBuffer__io_d_task_bits_task_memAttr_cacheable),
    .io_d_task_bits_task_memAttr_device (GrantBuffer__io_d_task_bits_task_memAttr_device),
    .io_d_task_bits_task_memAttr_ewa (GrantBuffer__io_d_task_bits_task_memAttr_ewa),
    .io_d_task_bits_task_traceTag (GrantBuffer__io_d_task_bits_task_traceTag),
    .io_d_task_bits_data_data (GrantBuffer__io_d_task_bits_data_data),
    .io_d_ready (GrantBuffer__io_d_ready),
    .io_d_valid (g_GrantBuffer__io_d_valid),
    .io_d_bits_opcode (g_GrantBuffer__io_d_bits_opcode),
    .io_d_bits_param (g_GrantBuffer__io_d_bits_param),
    .io_d_bits_source (g_GrantBuffer__io_d_bits_source),
    .io_d_bits_sink (g_GrantBuffer__io_d_bits_sink),
    .io_d_bits_denied (g_GrantBuffer__io_d_bits_denied),
    .io_d_bits_echo_isKeyword (g_GrantBuffer__io_d_bits_echo_isKeyword),
    .io_d_bits_data (g_GrantBuffer__io_d_bits_data),
    .io_d_bits_corrupt (g_GrantBuffer__io_d_bits_corrupt),
    .io_e_valid (GrantBuffer__io_e_valid),
    .io_e_bits_sink (GrantBuffer__io_e_bits_sink),
    .io_fromReqArb_status_s1_tags_1 (GrantBuffer__io_fromReqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_1 (GrantBuffer__io_fromReqArb_status_s1_sets_1),
    .io_pipeStatusVec_1_valid (GrantBuffer__io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel (GrantBuffer__io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_2_valid (GrantBuffer__io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel (GrantBuffer__io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_3_valid (GrantBuffer__io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel (GrantBuffer__io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_4_valid (GrantBuffer__io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel (GrantBuffer__io_pipeStatusVec_4_bits_channel),
    .io_toReqArb_blockSinkReqEntrance_blockA_s1 (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1),
    .io_toReqArb_blockSinkReqEntrance_blockB_s1 (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1),
    .io_toReqArb_blockSinkReqEntrance_blockC_s1 (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1),
    .io_toReqArb_blockMSHRReqEntrance (g_GrantBuffer__io_toReqArb_blockMSHRReqEntrance),
    .io_prefetchResp_ready (GrantBuffer__io_prefetchResp_ready),
    .io_prefetchResp_valid (g_GrantBuffer__io_prefetchResp_valid),
    .io_prefetchResp_bits_tag (g_GrantBuffer__io_prefetchResp_bits_tag),
    .io_prefetchResp_bits_set (g_GrantBuffer__io_prefetchResp_bits_set),
    .io_prefetchResp_bits_vaddr (g_GrantBuffer__io_prefetchResp_bits_vaddr),
    .io_prefetchResp_bits_pfSource (g_GrantBuffer__io_prefetchResp_bits_pfSource),
    .io_grantStatus_0_valid (g_GrantBuffer__io_grantStatus_0_valid),
    .io_grantStatus_0_set (g_GrantBuffer__io_grantStatus_0_set),
    .io_grantStatus_0_tag (g_GrantBuffer__io_grantStatus_0_tag),
    .io_grantStatus_1_valid (g_GrantBuffer__io_grantStatus_1_valid),
    .io_grantStatus_1_set (g_GrantBuffer__io_grantStatus_1_set),
    .io_grantStatus_1_tag (g_GrantBuffer__io_grantStatus_1_tag),
    .io_grantStatus_2_valid (g_GrantBuffer__io_grantStatus_2_valid),
    .io_grantStatus_2_set (g_GrantBuffer__io_grantStatus_2_set),
    .io_grantStatus_2_tag (g_GrantBuffer__io_grantStatus_2_tag),
    .io_grantStatus_3_valid (g_GrantBuffer__io_grantStatus_3_valid),
    .io_grantStatus_3_set (g_GrantBuffer__io_grantStatus_3_set),
    .io_grantStatus_3_tag (g_GrantBuffer__io_grantStatus_3_tag),
    .io_grantStatus_4_valid (g_GrantBuffer__io_grantStatus_4_valid),
    .io_grantStatus_4_set (g_GrantBuffer__io_grantStatus_4_set),
    .io_grantStatus_4_tag (g_GrantBuffer__io_grantStatus_4_tag),
    .io_grantStatus_5_valid (g_GrantBuffer__io_grantStatus_5_valid),
    .io_grantStatus_5_set (g_GrantBuffer__io_grantStatus_5_set),
    .io_grantStatus_5_tag (g_GrantBuffer__io_grantStatus_5_tag),
    .io_grantStatus_6_valid (g_GrantBuffer__io_grantStatus_6_valid),
    .io_grantStatus_6_set (g_GrantBuffer__io_grantStatus_6_set),
    .io_grantStatus_6_tag (g_GrantBuffer__io_grantStatus_6_tag),
    .io_grantStatus_7_valid (g_GrantBuffer__io_grantStatus_7_valid),
    .io_grantStatus_7_set (g_GrantBuffer__io_grantStatus_7_set),
    .io_grantStatus_7_tag (g_GrantBuffer__io_grantStatus_7_tag),
    .io_grantStatus_8_valid (g_GrantBuffer__io_grantStatus_8_valid),
    .io_grantStatus_8_set (g_GrantBuffer__io_grantStatus_8_set),
    .io_grantStatus_8_tag (g_GrantBuffer__io_grantStatus_8_tag),
    .io_grantStatus_9_valid (g_GrantBuffer__io_grantStatus_9_valid),
    .io_grantStatus_9_set (g_GrantBuffer__io_grantStatus_9_set),
    .io_grantStatus_9_tag (g_GrantBuffer__io_grantStatus_9_tag),
    .io_grantStatus_10_valid (g_GrantBuffer__io_grantStatus_10_valid),
    .io_grantStatus_10_set (g_GrantBuffer__io_grantStatus_10_set),
    .io_grantStatus_10_tag (g_GrantBuffer__io_grantStatus_10_tag),
    .io_grantStatus_11_valid (g_GrantBuffer__io_grantStatus_11_valid),
    .io_grantStatus_11_set (g_GrantBuffer__io_grantStatus_11_set),
    .io_grantStatus_11_tag (g_GrantBuffer__io_grantStatus_11_tag),
    .io_grantStatus_12_valid (g_GrantBuffer__io_grantStatus_12_valid),
    .io_grantStatus_12_set (g_GrantBuffer__io_grantStatus_12_set),
    .io_grantStatus_12_tag (g_GrantBuffer__io_grantStatus_12_tag),
    .io_grantStatus_13_valid (g_GrantBuffer__io_grantStatus_13_valid),
    .io_grantStatus_13_set (g_GrantBuffer__io_grantStatus_13_set),
    .io_grantStatus_13_tag (g_GrantBuffer__io_grantStatus_13_tag),
    .io_grantStatus_14_valid (g_GrantBuffer__io_grantStatus_14_valid),
    .io_grantStatus_14_set (g_GrantBuffer__io_grantStatus_14_set),
    .io_grantStatus_14_tag (g_GrantBuffer__io_grantStatus_14_tag),
    .io_grantStatus_15_valid (g_GrantBuffer__io_grantStatus_15_valid),
    .io_grantStatus_15_set (g_GrantBuffer__io_grantStatus_15_set),
    .io_grantStatus_15_tag (g_GrantBuffer__io_grantStatus_15_tag)
  );
  GrantBuffer_xs u_i_GrantBuffer (
    .clock (clock),
    .reset (reset),
    .io_d_task_valid (GrantBuffer__io_d_task_valid),
    .io_d_task_bits_task_channel (GrantBuffer__io_d_task_bits_task_channel),
    .io_d_task_bits_task_txChannel (GrantBuffer__io_d_task_bits_task_txChannel),
    .io_d_task_bits_task_set (GrantBuffer__io_d_task_bits_task_set),
    .io_d_task_bits_task_tag (GrantBuffer__io_d_task_bits_task_tag),
    .io_d_task_bits_task_off (GrantBuffer__io_d_task_bits_task_off),
    .io_d_task_bits_task_alias (GrantBuffer__io_d_task_bits_task_alias),
    .io_d_task_bits_task_vaddr (GrantBuffer__io_d_task_bits_task_vaddr),
    .io_d_task_bits_task_isKeyword (GrantBuffer__io_d_task_bits_task_isKeyword),
    .io_d_task_bits_task_opcode (GrantBuffer__io_d_task_bits_task_opcode),
    .io_d_task_bits_task_param (GrantBuffer__io_d_task_bits_task_param),
    .io_d_task_bits_task_size (GrantBuffer__io_d_task_bits_task_size),
    .io_d_task_bits_task_sourceId (GrantBuffer__io_d_task_bits_task_sourceId),
    .io_d_task_bits_task_bufIdx (GrantBuffer__io_d_task_bits_task_bufIdx),
    .io_d_task_bits_task_needProbeAckData (GrantBuffer__io_d_task_bits_task_needProbeAckData),
    .io_d_task_bits_task_denied (GrantBuffer__io_d_task_bits_task_denied),
    .io_d_task_bits_task_corrupt (GrantBuffer__io_d_task_bits_task_corrupt),
    .io_d_task_bits_task_mshrTask (GrantBuffer__io_d_task_bits_task_mshrTask),
    .io_d_task_bits_task_mshrId (GrantBuffer__io_d_task_bits_task_mshrId),
    .io_d_task_bits_task_aliasTask (GrantBuffer__io_d_task_bits_task_aliasTask),
    .io_d_task_bits_task_useProbeData (GrantBuffer__io_d_task_bits_task_useProbeData),
    .io_d_task_bits_task_mshrRetry (GrantBuffer__io_d_task_bits_task_mshrRetry),
    .io_d_task_bits_task_readProbeDataDown (GrantBuffer__io_d_task_bits_task_readProbeDataDown),
    .io_d_task_bits_task_fromL2pft (GrantBuffer__io_d_task_bits_task_fromL2pft),
    .io_d_task_bits_task_needHint (GrantBuffer__io_d_task_bits_task_needHint),
    .io_d_task_bits_task_dirty (GrantBuffer__io_d_task_bits_task_dirty),
    .io_d_task_bits_task_way (GrantBuffer__io_d_task_bits_task_way),
    .io_d_task_bits_task_meta_dirty (GrantBuffer__io_d_task_bits_task_meta_dirty),
    .io_d_task_bits_task_meta_state (GrantBuffer__io_d_task_bits_task_meta_state),
    .io_d_task_bits_task_meta_clients (GrantBuffer__io_d_task_bits_task_meta_clients),
    .io_d_task_bits_task_meta_alias (GrantBuffer__io_d_task_bits_task_meta_alias),
    .io_d_task_bits_task_meta_prefetch (GrantBuffer__io_d_task_bits_task_meta_prefetch),
    .io_d_task_bits_task_meta_prefetchSrc (GrantBuffer__io_d_task_bits_task_meta_prefetchSrc),
    .io_d_task_bits_task_meta_accessed (GrantBuffer__io_d_task_bits_task_meta_accessed),
    .io_d_task_bits_task_meta_tagErr (GrantBuffer__io_d_task_bits_task_meta_tagErr),
    .io_d_task_bits_task_meta_dataErr (GrantBuffer__io_d_task_bits_task_meta_dataErr),
    .io_d_task_bits_task_metaWen (GrantBuffer__io_d_task_bits_task_metaWen),
    .io_d_task_bits_task_tagWen (GrantBuffer__io_d_task_bits_task_tagWen),
    .io_d_task_bits_task_dsWen (GrantBuffer__io_d_task_bits_task_dsWen),
    .io_d_task_bits_task_wayMask (GrantBuffer__io_d_task_bits_task_wayMask),
    .io_d_task_bits_task_replTask (GrantBuffer__io_d_task_bits_task_replTask),
    .io_d_task_bits_task_cmoTask (GrantBuffer__io_d_task_bits_task_cmoTask),
    .io_d_task_bits_task_cmoAll (GrantBuffer__io_d_task_bits_task_cmoAll),
    .io_d_task_bits_task_reqSource (GrantBuffer__io_d_task_bits_task_reqSource),
    .io_d_task_bits_task_mergeA (GrantBuffer__io_d_task_bits_task_mergeA),
    .io_d_task_bits_task_aMergeTask_off (GrantBuffer__io_d_task_bits_task_aMergeTask_off),
    .io_d_task_bits_task_aMergeTask_alias (GrantBuffer__io_d_task_bits_task_aMergeTask_alias),
    .io_d_task_bits_task_aMergeTask_vaddr (GrantBuffer__io_d_task_bits_task_aMergeTask_vaddr),
    .io_d_task_bits_task_aMergeTask_isKeyword (GrantBuffer__io_d_task_bits_task_aMergeTask_isKeyword),
    .io_d_task_bits_task_aMergeTask_opcode (GrantBuffer__io_d_task_bits_task_aMergeTask_opcode),
    .io_d_task_bits_task_aMergeTask_param (GrantBuffer__io_d_task_bits_task_aMergeTask_param),
    .io_d_task_bits_task_aMergeTask_sourceId (GrantBuffer__io_d_task_bits_task_aMergeTask_sourceId),
    .io_d_task_bits_task_aMergeTask_meta_dirty (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dirty),
    .io_d_task_bits_task_aMergeTask_meta_state (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_state),
    .io_d_task_bits_task_aMergeTask_meta_clients (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_clients),
    .io_d_task_bits_task_aMergeTask_meta_alias (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_alias),
    .io_d_task_bits_task_aMergeTask_meta_prefetch (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetch),
    .io_d_task_bits_task_aMergeTask_meta_prefetchSrc (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetchSrc),
    .io_d_task_bits_task_aMergeTask_meta_accessed (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_accessed),
    .io_d_task_bits_task_aMergeTask_meta_tagErr (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_tagErr),
    .io_d_task_bits_task_aMergeTask_meta_dataErr (GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dataErr),
    .io_d_task_bits_task_snpHitRelease (GrantBuffer__io_d_task_bits_task_snpHitRelease),
    .io_d_task_bits_task_snpHitReleaseToInval (GrantBuffer__io_d_task_bits_task_snpHitReleaseToInval),
    .io_d_task_bits_task_snpHitReleaseToClean (GrantBuffer__io_d_task_bits_task_snpHitReleaseToClean),
    .io_d_task_bits_task_snpHitReleaseWithData (GrantBuffer__io_d_task_bits_task_snpHitReleaseWithData),
    .io_d_task_bits_task_snpHitReleaseIdx (GrantBuffer__io_d_task_bits_task_snpHitReleaseIdx),
    .io_d_task_bits_task_snpHitReleaseMeta_dirty (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dirty),
    .io_d_task_bits_task_snpHitReleaseMeta_state (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_state),
    .io_d_task_bits_task_snpHitReleaseMeta_clients (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_clients),
    .io_d_task_bits_task_snpHitReleaseMeta_alias (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_alias),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetch (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetch),
    .io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_d_task_bits_task_snpHitReleaseMeta_accessed (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_accessed),
    .io_d_task_bits_task_snpHitReleaseMeta_tagErr (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_tagErr),
    .io_d_task_bits_task_snpHitReleaseMeta_dataErr (GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dataErr),
    .io_d_task_bits_task_tgtID (GrantBuffer__io_d_task_bits_task_tgtID),
    .io_d_task_bits_task_srcID (GrantBuffer__io_d_task_bits_task_srcID),
    .io_d_task_bits_task_txnID (GrantBuffer__io_d_task_bits_task_txnID),
    .io_d_task_bits_task_homeNID (GrantBuffer__io_d_task_bits_task_homeNID),
    .io_d_task_bits_task_dbID (GrantBuffer__io_d_task_bits_task_dbID),
    .io_d_task_bits_task_fwdNID (GrantBuffer__io_d_task_bits_task_fwdNID),
    .io_d_task_bits_task_fwdTxnID (GrantBuffer__io_d_task_bits_task_fwdTxnID),
    .io_d_task_bits_task_chiOpcode (GrantBuffer__io_d_task_bits_task_chiOpcode),
    .io_d_task_bits_task_resp (GrantBuffer__io_d_task_bits_task_resp),
    .io_d_task_bits_task_fwdState (GrantBuffer__io_d_task_bits_task_fwdState),
    .io_d_task_bits_task_pCrdType (GrantBuffer__io_d_task_bits_task_pCrdType),
    .io_d_task_bits_task_retToSrc (GrantBuffer__io_d_task_bits_task_retToSrc),
    .io_d_task_bits_task_likelyshared (GrantBuffer__io_d_task_bits_task_likelyshared),
    .io_d_task_bits_task_expCompAck (GrantBuffer__io_d_task_bits_task_expCompAck),
    .io_d_task_bits_task_allowRetry (GrantBuffer__io_d_task_bits_task_allowRetry),
    .io_d_task_bits_task_memAttr_allocate (GrantBuffer__io_d_task_bits_task_memAttr_allocate),
    .io_d_task_bits_task_memAttr_cacheable (GrantBuffer__io_d_task_bits_task_memAttr_cacheable),
    .io_d_task_bits_task_memAttr_device (GrantBuffer__io_d_task_bits_task_memAttr_device),
    .io_d_task_bits_task_memAttr_ewa (GrantBuffer__io_d_task_bits_task_memAttr_ewa),
    .io_d_task_bits_task_traceTag (GrantBuffer__io_d_task_bits_task_traceTag),
    .io_d_task_bits_data_data (GrantBuffer__io_d_task_bits_data_data),
    .io_d_ready (GrantBuffer__io_d_ready),
    .io_d_valid (i_GrantBuffer__io_d_valid),
    .io_d_bits_opcode (i_GrantBuffer__io_d_bits_opcode),
    .io_d_bits_param (i_GrantBuffer__io_d_bits_param),
    .io_d_bits_source (i_GrantBuffer__io_d_bits_source),
    .io_d_bits_sink (i_GrantBuffer__io_d_bits_sink),
    .io_d_bits_denied (i_GrantBuffer__io_d_bits_denied),
    .io_d_bits_echo_isKeyword (i_GrantBuffer__io_d_bits_echo_isKeyword),
    .io_d_bits_data (i_GrantBuffer__io_d_bits_data),
    .io_d_bits_corrupt (i_GrantBuffer__io_d_bits_corrupt),
    .io_e_valid (GrantBuffer__io_e_valid),
    .io_e_bits_sink (GrantBuffer__io_e_bits_sink),
    .io_fromReqArb_status_s1_tags_1 (GrantBuffer__io_fromReqArb_status_s1_tags_1),
    .io_fromReqArb_status_s1_sets_1 (GrantBuffer__io_fromReqArb_status_s1_sets_1),
    .io_pipeStatusVec_1_valid (GrantBuffer__io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel (GrantBuffer__io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_2_valid (GrantBuffer__io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel (GrantBuffer__io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_3_valid (GrantBuffer__io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel (GrantBuffer__io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_4_valid (GrantBuffer__io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel (GrantBuffer__io_pipeStatusVec_4_bits_channel),
    .io_toReqArb_blockSinkReqEntrance_blockA_s1 (i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1),
    .io_toReqArb_blockSinkReqEntrance_blockB_s1 (i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1),
    .io_toReqArb_blockSinkReqEntrance_blockC_s1 (i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1),
    .io_toReqArb_blockMSHRReqEntrance (i_GrantBuffer__io_toReqArb_blockMSHRReqEntrance),
    .io_prefetchResp_ready (GrantBuffer__io_prefetchResp_ready),
    .io_prefetchResp_valid (i_GrantBuffer__io_prefetchResp_valid),
    .io_prefetchResp_bits_tag (i_GrantBuffer__io_prefetchResp_bits_tag),
    .io_prefetchResp_bits_set (i_GrantBuffer__io_prefetchResp_bits_set),
    .io_prefetchResp_bits_vaddr (i_GrantBuffer__io_prefetchResp_bits_vaddr),
    .io_prefetchResp_bits_pfSource (i_GrantBuffer__io_prefetchResp_bits_pfSource),
    .io_grantStatus_0_valid (i_GrantBuffer__io_grantStatus_0_valid),
    .io_grantStatus_0_set (i_GrantBuffer__io_grantStatus_0_set),
    .io_grantStatus_0_tag (i_GrantBuffer__io_grantStatus_0_tag),
    .io_grantStatus_1_valid (i_GrantBuffer__io_grantStatus_1_valid),
    .io_grantStatus_1_set (i_GrantBuffer__io_grantStatus_1_set),
    .io_grantStatus_1_tag (i_GrantBuffer__io_grantStatus_1_tag),
    .io_grantStatus_2_valid (i_GrantBuffer__io_grantStatus_2_valid),
    .io_grantStatus_2_set (i_GrantBuffer__io_grantStatus_2_set),
    .io_grantStatus_2_tag (i_GrantBuffer__io_grantStatus_2_tag),
    .io_grantStatus_3_valid (i_GrantBuffer__io_grantStatus_3_valid),
    .io_grantStatus_3_set (i_GrantBuffer__io_grantStatus_3_set),
    .io_grantStatus_3_tag (i_GrantBuffer__io_grantStatus_3_tag),
    .io_grantStatus_4_valid (i_GrantBuffer__io_grantStatus_4_valid),
    .io_grantStatus_4_set (i_GrantBuffer__io_grantStatus_4_set),
    .io_grantStatus_4_tag (i_GrantBuffer__io_grantStatus_4_tag),
    .io_grantStatus_5_valid (i_GrantBuffer__io_grantStatus_5_valid),
    .io_grantStatus_5_set (i_GrantBuffer__io_grantStatus_5_set),
    .io_grantStatus_5_tag (i_GrantBuffer__io_grantStatus_5_tag),
    .io_grantStatus_6_valid (i_GrantBuffer__io_grantStatus_6_valid),
    .io_grantStatus_6_set (i_GrantBuffer__io_grantStatus_6_set),
    .io_grantStatus_6_tag (i_GrantBuffer__io_grantStatus_6_tag),
    .io_grantStatus_7_valid (i_GrantBuffer__io_grantStatus_7_valid),
    .io_grantStatus_7_set (i_GrantBuffer__io_grantStatus_7_set),
    .io_grantStatus_7_tag (i_GrantBuffer__io_grantStatus_7_tag),
    .io_grantStatus_8_valid (i_GrantBuffer__io_grantStatus_8_valid),
    .io_grantStatus_8_set (i_GrantBuffer__io_grantStatus_8_set),
    .io_grantStatus_8_tag (i_GrantBuffer__io_grantStatus_8_tag),
    .io_grantStatus_9_valid (i_GrantBuffer__io_grantStatus_9_valid),
    .io_grantStatus_9_set (i_GrantBuffer__io_grantStatus_9_set),
    .io_grantStatus_9_tag (i_GrantBuffer__io_grantStatus_9_tag),
    .io_grantStatus_10_valid (i_GrantBuffer__io_grantStatus_10_valid),
    .io_grantStatus_10_set (i_GrantBuffer__io_grantStatus_10_set),
    .io_grantStatus_10_tag (i_GrantBuffer__io_grantStatus_10_tag),
    .io_grantStatus_11_valid (i_GrantBuffer__io_grantStatus_11_valid),
    .io_grantStatus_11_set (i_GrantBuffer__io_grantStatus_11_set),
    .io_grantStatus_11_tag (i_GrantBuffer__io_grantStatus_11_tag),
    .io_grantStatus_12_valid (i_GrantBuffer__io_grantStatus_12_valid),
    .io_grantStatus_12_set (i_GrantBuffer__io_grantStatus_12_set),
    .io_grantStatus_12_tag (i_GrantBuffer__io_grantStatus_12_tag),
    .io_grantStatus_13_valid (i_GrantBuffer__io_grantStatus_13_valid),
    .io_grantStatus_13_set (i_GrantBuffer__io_grantStatus_13_set),
    .io_grantStatus_13_tag (i_GrantBuffer__io_grantStatus_13_tag),
    .io_grantStatus_14_valid (i_GrantBuffer__io_grantStatus_14_valid),
    .io_grantStatus_14_set (i_GrantBuffer__io_grantStatus_14_set),
    .io_grantStatus_14_tag (i_GrantBuffer__io_grantStatus_14_tag),
    .io_grantStatus_15_valid (i_GrantBuffer__io_grantStatus_15_valid),
    .io_grantStatus_15_set (i_GrantBuffer__io_grantStatus_15_set),
    .io_grantStatus_15_tag (i_GrantBuffer__io_grantStatus_15_tag)
  );
  task automatic drive_GrantBuffer();
    GrantBuffer__io_d_task_valid = (($urandom % 3) == 0);
    GrantBuffer__io_d_task_bits_task_channel = rnd(3);
    GrantBuffer__io_d_task_bits_task_txChannel = rnd(3);
    GrantBuffer__io_d_task_bits_task_set = 9'($urandom_range(0, 3));
    GrantBuffer__io_d_task_bits_task_tag = 31'($urandom_range(0, 3));
    GrantBuffer__io_d_task_bits_task_off = rnd(6);
    GrantBuffer__io_d_task_bits_task_alias = rnd(2);
    GrantBuffer__io_d_task_bits_task_vaddr = rnd(44);
    GrantBuffer__io_d_task_bits_task_isKeyword = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_opcode = 4'($urandom_range(0, 7) < 3 ? 4 : ($urandom_range(0, 7) < 2 ? 5 : ($urandom_range(0, 3) == 0 ? 2 : $urandom_range(0, 6))));
    GrantBuffer__io_d_task_bits_task_param = rnd(3);
    GrantBuffer__io_d_task_bits_task_size = rnd(3);
    GrantBuffer__io_d_task_bits_task_sourceId = rnd(7);
    GrantBuffer__io_d_task_bits_task_bufIdx = rnd(2);
    GrantBuffer__io_d_task_bits_task_needProbeAckData = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_denied = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_corrupt = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_mshrTask = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_mshrId = rnd(8);
    GrantBuffer__io_d_task_bits_task_aliasTask = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_useProbeData = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_mshrRetry = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_readProbeDataDown = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_fromL2pft = (($urandom % 2) == 0);
    GrantBuffer__io_d_task_bits_task_needHint = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_dirty = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_way = rnd(3);
    GrantBuffer__io_d_task_bits_task_meta_dirty = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_meta_state = rnd(2);
    GrantBuffer__io_d_task_bits_task_meta_clients = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_meta_alias = rnd(2);
    GrantBuffer__io_d_task_bits_task_meta_prefetch = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_meta_prefetchSrc = rnd(3);
    GrantBuffer__io_d_task_bits_task_meta_accessed = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_meta_tagErr = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_meta_dataErr = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_metaWen = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_tagWen = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_dsWen = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_wayMask = rnd(8);
    GrantBuffer__io_d_task_bits_task_replTask = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_cmoTask = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_cmoAll = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_reqSource = rnd(5);
    GrantBuffer__io_d_task_bits_task_mergeA = (($urandom % 8) == 0);
    GrantBuffer__io_d_task_bits_task_aMergeTask_off = rnd(6);
    GrantBuffer__io_d_task_bits_task_aMergeTask_alias = rnd(2);
    GrantBuffer__io_d_task_bits_task_aMergeTask_vaddr = rnd(44);
    GrantBuffer__io_d_task_bits_task_aMergeTask_isKeyword = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_aMergeTask_opcode = rnd(3);
    GrantBuffer__io_d_task_bits_task_aMergeTask_param = rnd(3);
    GrantBuffer__io_d_task_bits_task_aMergeTask_sourceId = rnd(7);
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dirty = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_state = rnd(2);
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_clients = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_alias = rnd(2);
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetch = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_prefetchSrc = rnd(3);
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_accessed = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_tagErr = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_aMergeTask_meta_dataErr = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitRelease = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseToInval = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseToClean = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseWithData = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseIdx = rnd(8);
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dirty = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_state = rnd(2);
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_clients = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_alias = rnd(2);
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetch = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc = rnd(3);
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_accessed = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_tagErr = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_snpHitReleaseMeta_dataErr = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_tgtID = rnd(11);
    GrantBuffer__io_d_task_bits_task_srcID = rnd(11);
    GrantBuffer__io_d_task_bits_task_txnID = rnd(12);
    GrantBuffer__io_d_task_bits_task_homeNID = rnd(11);
    GrantBuffer__io_d_task_bits_task_dbID = rnd(12);
    GrantBuffer__io_d_task_bits_task_fwdNID = rnd(11);
    GrantBuffer__io_d_task_bits_task_fwdTxnID = rnd(12);
    GrantBuffer__io_d_task_bits_task_chiOpcode = rnd(7);
    GrantBuffer__io_d_task_bits_task_resp = rnd(3);
    GrantBuffer__io_d_task_bits_task_fwdState = rnd(3);
    GrantBuffer__io_d_task_bits_task_pCrdType = rnd(4);
    GrantBuffer__io_d_task_bits_task_retToSrc = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_likelyshared = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_expCompAck = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_allowRetry = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_memAttr_allocate = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_memAttr_cacheable = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_memAttr_device = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_memAttr_ewa = $urandom % 2;
    GrantBuffer__io_d_task_bits_task_traceTag = $urandom % 2;
    GrantBuffer__io_d_task_bits_data_data = rnd(512);
    GrantBuffer__io_d_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    GrantBuffer__io_e_valid = ((cyc / 2000) % 2) ? (($urandom % 3) == 0) : (($urandom % 8) == 0);
    GrantBuffer__io_e_bits_sink = (($urandom % 16) == 0) ? 8'($urandom) : 8'($urandom_range(0, 15));
    GrantBuffer__io_fromReqArb_status_s1_tags_1 = 31'($urandom_range(0, 3));
    GrantBuffer__io_fromReqArb_status_s1_sets_1 = 9'($urandom_range(0, 3));
    GrantBuffer__io_pipeStatusVec_1_valid = $urandom % 2;
    GrantBuffer__io_pipeStatusVec_1_bits_channel = rnd(3);
    GrantBuffer__io_pipeStatusVec_2_valid = $urandom % 2;
    GrantBuffer__io_pipeStatusVec_2_bits_channel = rnd(3);
    GrantBuffer__io_pipeStatusVec_3_valid = $urandom % 2;
    GrantBuffer__io_pipeStatusVec_3_bits_channel = rnd(3);
    GrantBuffer__io_pipeStatusVec_4_valid = $urandom % 2;
    GrantBuffer__io_pipeStatusVec_4_bits_channel = rnd(3);
    GrantBuffer__io_prefetchResp_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 32) == 0);
  endtask
  task automatic check_GrantBuffer();
    checks++;
    if (g_GrantBuffer__io_d_valid !== i_GrantBuffer__io_d_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_valid g=%h i=%h", cyc, g_GrantBuffer__io_d_valid, i_GrantBuffer__io_d_valid);
    end
    if (g_GrantBuffer__io_d_valid !== p_GrantBuffer__io_d_valid) t_GrantBuffer__io_d_valid = 1'b1;
    p_GrantBuffer__io_d_valid = g_GrantBuffer__io_d_valid;
    checks++;
    if (g_GrantBuffer__io_d_bits_opcode !== i_GrantBuffer__io_d_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_opcode g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_opcode, i_GrantBuffer__io_d_bits_opcode);
    end
    if (g_GrantBuffer__io_d_bits_opcode !== p_GrantBuffer__io_d_bits_opcode) t_GrantBuffer__io_d_bits_opcode = 1'b1;
    p_GrantBuffer__io_d_bits_opcode = g_GrantBuffer__io_d_bits_opcode;
    checks++;
    if (g_GrantBuffer__io_d_bits_param !== i_GrantBuffer__io_d_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_param g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_param, i_GrantBuffer__io_d_bits_param);
    end
    if (g_GrantBuffer__io_d_bits_param !== p_GrantBuffer__io_d_bits_param) t_GrantBuffer__io_d_bits_param = 1'b1;
    p_GrantBuffer__io_d_bits_param = g_GrantBuffer__io_d_bits_param;
    checks++;
    if (g_GrantBuffer__io_d_bits_source !== i_GrantBuffer__io_d_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_source g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_source, i_GrantBuffer__io_d_bits_source);
    end
    if (g_GrantBuffer__io_d_bits_source !== p_GrantBuffer__io_d_bits_source) t_GrantBuffer__io_d_bits_source = 1'b1;
    p_GrantBuffer__io_d_bits_source = g_GrantBuffer__io_d_bits_source;
    checks++;
    if (g_GrantBuffer__io_d_bits_sink !== i_GrantBuffer__io_d_bits_sink) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_sink g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_sink, i_GrantBuffer__io_d_bits_sink);
    end
    if (g_GrantBuffer__io_d_bits_sink !== p_GrantBuffer__io_d_bits_sink) t_GrantBuffer__io_d_bits_sink = 1'b1;
    p_GrantBuffer__io_d_bits_sink = g_GrantBuffer__io_d_bits_sink;
    checks++;
    if (g_GrantBuffer__io_d_bits_denied !== i_GrantBuffer__io_d_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_denied g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_denied, i_GrantBuffer__io_d_bits_denied);
    end
    if (g_GrantBuffer__io_d_bits_denied !== p_GrantBuffer__io_d_bits_denied) t_GrantBuffer__io_d_bits_denied = 1'b1;
    p_GrantBuffer__io_d_bits_denied = g_GrantBuffer__io_d_bits_denied;
    checks++;
    if (g_GrantBuffer__io_d_bits_echo_isKeyword !== i_GrantBuffer__io_d_bits_echo_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_echo_isKeyword g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_echo_isKeyword, i_GrantBuffer__io_d_bits_echo_isKeyword);
    end
    if (g_GrantBuffer__io_d_bits_echo_isKeyword !== p_GrantBuffer__io_d_bits_echo_isKeyword) t_GrantBuffer__io_d_bits_echo_isKeyword = 1'b1;
    p_GrantBuffer__io_d_bits_echo_isKeyword = g_GrantBuffer__io_d_bits_echo_isKeyword;
    checks++;
    if (g_GrantBuffer__io_d_bits_data !== i_GrantBuffer__io_d_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_data g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_data, i_GrantBuffer__io_d_bits_data);
    end
    if (g_GrantBuffer__io_d_bits_data !== p_GrantBuffer__io_d_bits_data) t_GrantBuffer__io_d_bits_data = 1'b1;
    p_GrantBuffer__io_d_bits_data = g_GrantBuffer__io_d_bits_data;
    checks++;
    if (g_GrantBuffer__io_d_bits_corrupt !== i_GrantBuffer__io_d_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_d_bits_corrupt g=%h i=%h", cyc, g_GrantBuffer__io_d_bits_corrupt, i_GrantBuffer__io_d_bits_corrupt);
    end
    if (g_GrantBuffer__io_d_bits_corrupt !== p_GrantBuffer__io_d_bits_corrupt) t_GrantBuffer__io_d_bits_corrupt = 1'b1;
    p_GrantBuffer__io_d_bits_corrupt = g_GrantBuffer__io_d_bits_corrupt;
    checks++;
    if (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1 !== i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockA_s1 g=%h i=%h", cyc, g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1, i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1);
    end
    if (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1 !== p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1) t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1 = 1'b1;
    p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1 = g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1;
    checks++;
    if (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1 !== i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockB_s1 g=%h i=%h", cyc, g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1, i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1);
    end
    if (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1 !== p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1) t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1 = 1'b1;
    p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1 = g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1;
    checks++;
    if (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1 !== i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockC_s1 g=%h i=%h", cyc, g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1, i_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1);
    end
    if (g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1 !== p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1) t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1 = 1'b1;
    p_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1 = g_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1;
    checks++;
    if (g_GrantBuffer__io_toReqArb_blockMSHRReqEntrance !== i_GrantBuffer__io_toReqArb_blockMSHRReqEntrance) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_toReqArb_blockMSHRReqEntrance g=%h i=%h", cyc, g_GrantBuffer__io_toReqArb_blockMSHRReqEntrance, i_GrantBuffer__io_toReqArb_blockMSHRReqEntrance);
    end
    if (g_GrantBuffer__io_toReqArb_blockMSHRReqEntrance !== p_GrantBuffer__io_toReqArb_blockMSHRReqEntrance) t_GrantBuffer__io_toReqArb_blockMSHRReqEntrance = 1'b1;
    p_GrantBuffer__io_toReqArb_blockMSHRReqEntrance = g_GrantBuffer__io_toReqArb_blockMSHRReqEntrance;
    checks++;
    if (g_GrantBuffer__io_prefetchResp_valid !== i_GrantBuffer__io_prefetchResp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_prefetchResp_valid g=%h i=%h", cyc, g_GrantBuffer__io_prefetchResp_valid, i_GrantBuffer__io_prefetchResp_valid);
    end
    if (g_GrantBuffer__io_prefetchResp_valid !== p_GrantBuffer__io_prefetchResp_valid) t_GrantBuffer__io_prefetchResp_valid = 1'b1;
    p_GrantBuffer__io_prefetchResp_valid = g_GrantBuffer__io_prefetchResp_valid;
    checks++;
    if (g_GrantBuffer__io_prefetchResp_bits_tag !== i_GrantBuffer__io_prefetchResp_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_prefetchResp_bits_tag g=%h i=%h", cyc, g_GrantBuffer__io_prefetchResp_bits_tag, i_GrantBuffer__io_prefetchResp_bits_tag);
    end
    if (g_GrantBuffer__io_prefetchResp_bits_tag !== p_GrantBuffer__io_prefetchResp_bits_tag) t_GrantBuffer__io_prefetchResp_bits_tag = 1'b1;
    p_GrantBuffer__io_prefetchResp_bits_tag = g_GrantBuffer__io_prefetchResp_bits_tag;
    checks++;
    if (g_GrantBuffer__io_prefetchResp_bits_set !== i_GrantBuffer__io_prefetchResp_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_prefetchResp_bits_set g=%h i=%h", cyc, g_GrantBuffer__io_prefetchResp_bits_set, i_GrantBuffer__io_prefetchResp_bits_set);
    end
    if (g_GrantBuffer__io_prefetchResp_bits_set !== p_GrantBuffer__io_prefetchResp_bits_set) t_GrantBuffer__io_prefetchResp_bits_set = 1'b1;
    p_GrantBuffer__io_prefetchResp_bits_set = g_GrantBuffer__io_prefetchResp_bits_set;
    checks++;
    if (g_GrantBuffer__io_prefetchResp_bits_vaddr !== i_GrantBuffer__io_prefetchResp_bits_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_prefetchResp_bits_vaddr g=%h i=%h", cyc, g_GrantBuffer__io_prefetchResp_bits_vaddr, i_GrantBuffer__io_prefetchResp_bits_vaddr);
    end
    if (g_GrantBuffer__io_prefetchResp_bits_vaddr !== p_GrantBuffer__io_prefetchResp_bits_vaddr) t_GrantBuffer__io_prefetchResp_bits_vaddr = 1'b1;
    p_GrantBuffer__io_prefetchResp_bits_vaddr = g_GrantBuffer__io_prefetchResp_bits_vaddr;
    checks++;
    if (g_GrantBuffer__io_prefetchResp_bits_pfSource !== i_GrantBuffer__io_prefetchResp_bits_pfSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_prefetchResp_bits_pfSource g=%h i=%h", cyc, g_GrantBuffer__io_prefetchResp_bits_pfSource, i_GrantBuffer__io_prefetchResp_bits_pfSource);
    end
    if (g_GrantBuffer__io_prefetchResp_bits_pfSource !== p_GrantBuffer__io_prefetchResp_bits_pfSource) t_GrantBuffer__io_prefetchResp_bits_pfSource = 1'b1;
    p_GrantBuffer__io_prefetchResp_bits_pfSource = g_GrantBuffer__io_prefetchResp_bits_pfSource;
    checks++;
    if (g_GrantBuffer__io_grantStatus_0_valid !== i_GrantBuffer__io_grantStatus_0_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_0_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_0_valid, i_GrantBuffer__io_grantStatus_0_valid);
    end
    if (g_GrantBuffer__io_grantStatus_0_valid !== p_GrantBuffer__io_grantStatus_0_valid) t_GrantBuffer__io_grantStatus_0_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_0_valid = g_GrantBuffer__io_grantStatus_0_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_0_set !== i_GrantBuffer__io_grantStatus_0_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_0_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_0_set, i_GrantBuffer__io_grantStatus_0_set);
    end
    if (g_GrantBuffer__io_grantStatus_0_set !== p_GrantBuffer__io_grantStatus_0_set) t_GrantBuffer__io_grantStatus_0_set = 1'b1;
    p_GrantBuffer__io_grantStatus_0_set = g_GrantBuffer__io_grantStatus_0_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_0_tag !== i_GrantBuffer__io_grantStatus_0_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_0_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_0_tag, i_GrantBuffer__io_grantStatus_0_tag);
    end
    if (g_GrantBuffer__io_grantStatus_0_tag !== p_GrantBuffer__io_grantStatus_0_tag) t_GrantBuffer__io_grantStatus_0_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_0_tag = g_GrantBuffer__io_grantStatus_0_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_1_valid !== i_GrantBuffer__io_grantStatus_1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_1_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_1_valid, i_GrantBuffer__io_grantStatus_1_valid);
    end
    if (g_GrantBuffer__io_grantStatus_1_valid !== p_GrantBuffer__io_grantStatus_1_valid) t_GrantBuffer__io_grantStatus_1_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_1_valid = g_GrantBuffer__io_grantStatus_1_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_1_set !== i_GrantBuffer__io_grantStatus_1_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_1_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_1_set, i_GrantBuffer__io_grantStatus_1_set);
    end
    if (g_GrantBuffer__io_grantStatus_1_set !== p_GrantBuffer__io_grantStatus_1_set) t_GrantBuffer__io_grantStatus_1_set = 1'b1;
    p_GrantBuffer__io_grantStatus_1_set = g_GrantBuffer__io_grantStatus_1_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_1_tag !== i_GrantBuffer__io_grantStatus_1_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_1_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_1_tag, i_GrantBuffer__io_grantStatus_1_tag);
    end
    if (g_GrantBuffer__io_grantStatus_1_tag !== p_GrantBuffer__io_grantStatus_1_tag) t_GrantBuffer__io_grantStatus_1_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_1_tag = g_GrantBuffer__io_grantStatus_1_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_2_valid !== i_GrantBuffer__io_grantStatus_2_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_2_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_2_valid, i_GrantBuffer__io_grantStatus_2_valid);
    end
    if (g_GrantBuffer__io_grantStatus_2_valid !== p_GrantBuffer__io_grantStatus_2_valid) t_GrantBuffer__io_grantStatus_2_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_2_valid = g_GrantBuffer__io_grantStatus_2_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_2_set !== i_GrantBuffer__io_grantStatus_2_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_2_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_2_set, i_GrantBuffer__io_grantStatus_2_set);
    end
    if (g_GrantBuffer__io_grantStatus_2_set !== p_GrantBuffer__io_grantStatus_2_set) t_GrantBuffer__io_grantStatus_2_set = 1'b1;
    p_GrantBuffer__io_grantStatus_2_set = g_GrantBuffer__io_grantStatus_2_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_2_tag !== i_GrantBuffer__io_grantStatus_2_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_2_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_2_tag, i_GrantBuffer__io_grantStatus_2_tag);
    end
    if (g_GrantBuffer__io_grantStatus_2_tag !== p_GrantBuffer__io_grantStatus_2_tag) t_GrantBuffer__io_grantStatus_2_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_2_tag = g_GrantBuffer__io_grantStatus_2_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_3_valid !== i_GrantBuffer__io_grantStatus_3_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_3_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_3_valid, i_GrantBuffer__io_grantStatus_3_valid);
    end
    if (g_GrantBuffer__io_grantStatus_3_valid !== p_GrantBuffer__io_grantStatus_3_valid) t_GrantBuffer__io_grantStatus_3_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_3_valid = g_GrantBuffer__io_grantStatus_3_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_3_set !== i_GrantBuffer__io_grantStatus_3_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_3_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_3_set, i_GrantBuffer__io_grantStatus_3_set);
    end
    if (g_GrantBuffer__io_grantStatus_3_set !== p_GrantBuffer__io_grantStatus_3_set) t_GrantBuffer__io_grantStatus_3_set = 1'b1;
    p_GrantBuffer__io_grantStatus_3_set = g_GrantBuffer__io_grantStatus_3_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_3_tag !== i_GrantBuffer__io_grantStatus_3_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_3_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_3_tag, i_GrantBuffer__io_grantStatus_3_tag);
    end
    if (g_GrantBuffer__io_grantStatus_3_tag !== p_GrantBuffer__io_grantStatus_3_tag) t_GrantBuffer__io_grantStatus_3_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_3_tag = g_GrantBuffer__io_grantStatus_3_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_4_valid !== i_GrantBuffer__io_grantStatus_4_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_4_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_4_valid, i_GrantBuffer__io_grantStatus_4_valid);
    end
    if (g_GrantBuffer__io_grantStatus_4_valid !== p_GrantBuffer__io_grantStatus_4_valid) t_GrantBuffer__io_grantStatus_4_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_4_valid = g_GrantBuffer__io_grantStatus_4_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_4_set !== i_GrantBuffer__io_grantStatus_4_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_4_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_4_set, i_GrantBuffer__io_grantStatus_4_set);
    end
    if (g_GrantBuffer__io_grantStatus_4_set !== p_GrantBuffer__io_grantStatus_4_set) t_GrantBuffer__io_grantStatus_4_set = 1'b1;
    p_GrantBuffer__io_grantStatus_4_set = g_GrantBuffer__io_grantStatus_4_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_4_tag !== i_GrantBuffer__io_grantStatus_4_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_4_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_4_tag, i_GrantBuffer__io_grantStatus_4_tag);
    end
    if (g_GrantBuffer__io_grantStatus_4_tag !== p_GrantBuffer__io_grantStatus_4_tag) t_GrantBuffer__io_grantStatus_4_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_4_tag = g_GrantBuffer__io_grantStatus_4_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_5_valid !== i_GrantBuffer__io_grantStatus_5_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_5_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_5_valid, i_GrantBuffer__io_grantStatus_5_valid);
    end
    if (g_GrantBuffer__io_grantStatus_5_valid !== p_GrantBuffer__io_grantStatus_5_valid) t_GrantBuffer__io_grantStatus_5_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_5_valid = g_GrantBuffer__io_grantStatus_5_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_5_set !== i_GrantBuffer__io_grantStatus_5_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_5_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_5_set, i_GrantBuffer__io_grantStatus_5_set);
    end
    if (g_GrantBuffer__io_grantStatus_5_set !== p_GrantBuffer__io_grantStatus_5_set) t_GrantBuffer__io_grantStatus_5_set = 1'b1;
    p_GrantBuffer__io_grantStatus_5_set = g_GrantBuffer__io_grantStatus_5_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_5_tag !== i_GrantBuffer__io_grantStatus_5_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_5_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_5_tag, i_GrantBuffer__io_grantStatus_5_tag);
    end
    if (g_GrantBuffer__io_grantStatus_5_tag !== p_GrantBuffer__io_grantStatus_5_tag) t_GrantBuffer__io_grantStatus_5_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_5_tag = g_GrantBuffer__io_grantStatus_5_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_6_valid !== i_GrantBuffer__io_grantStatus_6_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_6_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_6_valid, i_GrantBuffer__io_grantStatus_6_valid);
    end
    if (g_GrantBuffer__io_grantStatus_6_valid !== p_GrantBuffer__io_grantStatus_6_valid) t_GrantBuffer__io_grantStatus_6_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_6_valid = g_GrantBuffer__io_grantStatus_6_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_6_set !== i_GrantBuffer__io_grantStatus_6_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_6_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_6_set, i_GrantBuffer__io_grantStatus_6_set);
    end
    if (g_GrantBuffer__io_grantStatus_6_set !== p_GrantBuffer__io_grantStatus_6_set) t_GrantBuffer__io_grantStatus_6_set = 1'b1;
    p_GrantBuffer__io_grantStatus_6_set = g_GrantBuffer__io_grantStatus_6_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_6_tag !== i_GrantBuffer__io_grantStatus_6_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_6_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_6_tag, i_GrantBuffer__io_grantStatus_6_tag);
    end
    if (g_GrantBuffer__io_grantStatus_6_tag !== p_GrantBuffer__io_grantStatus_6_tag) t_GrantBuffer__io_grantStatus_6_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_6_tag = g_GrantBuffer__io_grantStatus_6_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_7_valid !== i_GrantBuffer__io_grantStatus_7_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_7_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_7_valid, i_GrantBuffer__io_grantStatus_7_valid);
    end
    if (g_GrantBuffer__io_grantStatus_7_valid !== p_GrantBuffer__io_grantStatus_7_valid) t_GrantBuffer__io_grantStatus_7_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_7_valid = g_GrantBuffer__io_grantStatus_7_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_7_set !== i_GrantBuffer__io_grantStatus_7_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_7_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_7_set, i_GrantBuffer__io_grantStatus_7_set);
    end
    if (g_GrantBuffer__io_grantStatus_7_set !== p_GrantBuffer__io_grantStatus_7_set) t_GrantBuffer__io_grantStatus_7_set = 1'b1;
    p_GrantBuffer__io_grantStatus_7_set = g_GrantBuffer__io_grantStatus_7_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_7_tag !== i_GrantBuffer__io_grantStatus_7_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_7_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_7_tag, i_GrantBuffer__io_grantStatus_7_tag);
    end
    if (g_GrantBuffer__io_grantStatus_7_tag !== p_GrantBuffer__io_grantStatus_7_tag) t_GrantBuffer__io_grantStatus_7_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_7_tag = g_GrantBuffer__io_grantStatus_7_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_8_valid !== i_GrantBuffer__io_grantStatus_8_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_8_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_8_valid, i_GrantBuffer__io_grantStatus_8_valid);
    end
    if (g_GrantBuffer__io_grantStatus_8_valid !== p_GrantBuffer__io_grantStatus_8_valid) t_GrantBuffer__io_grantStatus_8_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_8_valid = g_GrantBuffer__io_grantStatus_8_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_8_set !== i_GrantBuffer__io_grantStatus_8_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_8_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_8_set, i_GrantBuffer__io_grantStatus_8_set);
    end
    if (g_GrantBuffer__io_grantStatus_8_set !== p_GrantBuffer__io_grantStatus_8_set) t_GrantBuffer__io_grantStatus_8_set = 1'b1;
    p_GrantBuffer__io_grantStatus_8_set = g_GrantBuffer__io_grantStatus_8_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_8_tag !== i_GrantBuffer__io_grantStatus_8_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_8_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_8_tag, i_GrantBuffer__io_grantStatus_8_tag);
    end
    if (g_GrantBuffer__io_grantStatus_8_tag !== p_GrantBuffer__io_grantStatus_8_tag) t_GrantBuffer__io_grantStatus_8_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_8_tag = g_GrantBuffer__io_grantStatus_8_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_9_valid !== i_GrantBuffer__io_grantStatus_9_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_9_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_9_valid, i_GrantBuffer__io_grantStatus_9_valid);
    end
    if (g_GrantBuffer__io_grantStatus_9_valid !== p_GrantBuffer__io_grantStatus_9_valid) t_GrantBuffer__io_grantStatus_9_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_9_valid = g_GrantBuffer__io_grantStatus_9_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_9_set !== i_GrantBuffer__io_grantStatus_9_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_9_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_9_set, i_GrantBuffer__io_grantStatus_9_set);
    end
    if (g_GrantBuffer__io_grantStatus_9_set !== p_GrantBuffer__io_grantStatus_9_set) t_GrantBuffer__io_grantStatus_9_set = 1'b1;
    p_GrantBuffer__io_grantStatus_9_set = g_GrantBuffer__io_grantStatus_9_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_9_tag !== i_GrantBuffer__io_grantStatus_9_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_9_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_9_tag, i_GrantBuffer__io_grantStatus_9_tag);
    end
    if (g_GrantBuffer__io_grantStatus_9_tag !== p_GrantBuffer__io_grantStatus_9_tag) t_GrantBuffer__io_grantStatus_9_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_9_tag = g_GrantBuffer__io_grantStatus_9_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_10_valid !== i_GrantBuffer__io_grantStatus_10_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_10_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_10_valid, i_GrantBuffer__io_grantStatus_10_valid);
    end
    if (g_GrantBuffer__io_grantStatus_10_valid !== p_GrantBuffer__io_grantStatus_10_valid) t_GrantBuffer__io_grantStatus_10_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_10_valid = g_GrantBuffer__io_grantStatus_10_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_10_set !== i_GrantBuffer__io_grantStatus_10_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_10_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_10_set, i_GrantBuffer__io_grantStatus_10_set);
    end
    if (g_GrantBuffer__io_grantStatus_10_set !== p_GrantBuffer__io_grantStatus_10_set) t_GrantBuffer__io_grantStatus_10_set = 1'b1;
    p_GrantBuffer__io_grantStatus_10_set = g_GrantBuffer__io_grantStatus_10_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_10_tag !== i_GrantBuffer__io_grantStatus_10_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_10_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_10_tag, i_GrantBuffer__io_grantStatus_10_tag);
    end
    if (g_GrantBuffer__io_grantStatus_10_tag !== p_GrantBuffer__io_grantStatus_10_tag) t_GrantBuffer__io_grantStatus_10_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_10_tag = g_GrantBuffer__io_grantStatus_10_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_11_valid !== i_GrantBuffer__io_grantStatus_11_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_11_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_11_valid, i_GrantBuffer__io_grantStatus_11_valid);
    end
    if (g_GrantBuffer__io_grantStatus_11_valid !== p_GrantBuffer__io_grantStatus_11_valid) t_GrantBuffer__io_grantStatus_11_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_11_valid = g_GrantBuffer__io_grantStatus_11_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_11_set !== i_GrantBuffer__io_grantStatus_11_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_11_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_11_set, i_GrantBuffer__io_grantStatus_11_set);
    end
    if (g_GrantBuffer__io_grantStatus_11_set !== p_GrantBuffer__io_grantStatus_11_set) t_GrantBuffer__io_grantStatus_11_set = 1'b1;
    p_GrantBuffer__io_grantStatus_11_set = g_GrantBuffer__io_grantStatus_11_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_11_tag !== i_GrantBuffer__io_grantStatus_11_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_11_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_11_tag, i_GrantBuffer__io_grantStatus_11_tag);
    end
    if (g_GrantBuffer__io_grantStatus_11_tag !== p_GrantBuffer__io_grantStatus_11_tag) t_GrantBuffer__io_grantStatus_11_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_11_tag = g_GrantBuffer__io_grantStatus_11_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_12_valid !== i_GrantBuffer__io_grantStatus_12_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_12_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_12_valid, i_GrantBuffer__io_grantStatus_12_valid);
    end
    if (g_GrantBuffer__io_grantStatus_12_valid !== p_GrantBuffer__io_grantStatus_12_valid) t_GrantBuffer__io_grantStatus_12_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_12_valid = g_GrantBuffer__io_grantStatus_12_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_12_set !== i_GrantBuffer__io_grantStatus_12_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_12_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_12_set, i_GrantBuffer__io_grantStatus_12_set);
    end
    if (g_GrantBuffer__io_grantStatus_12_set !== p_GrantBuffer__io_grantStatus_12_set) t_GrantBuffer__io_grantStatus_12_set = 1'b1;
    p_GrantBuffer__io_grantStatus_12_set = g_GrantBuffer__io_grantStatus_12_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_12_tag !== i_GrantBuffer__io_grantStatus_12_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_12_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_12_tag, i_GrantBuffer__io_grantStatus_12_tag);
    end
    if (g_GrantBuffer__io_grantStatus_12_tag !== p_GrantBuffer__io_grantStatus_12_tag) t_GrantBuffer__io_grantStatus_12_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_12_tag = g_GrantBuffer__io_grantStatus_12_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_13_valid !== i_GrantBuffer__io_grantStatus_13_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_13_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_13_valid, i_GrantBuffer__io_grantStatus_13_valid);
    end
    if (g_GrantBuffer__io_grantStatus_13_valid !== p_GrantBuffer__io_grantStatus_13_valid) t_GrantBuffer__io_grantStatus_13_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_13_valid = g_GrantBuffer__io_grantStatus_13_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_13_set !== i_GrantBuffer__io_grantStatus_13_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_13_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_13_set, i_GrantBuffer__io_grantStatus_13_set);
    end
    if (g_GrantBuffer__io_grantStatus_13_set !== p_GrantBuffer__io_grantStatus_13_set) t_GrantBuffer__io_grantStatus_13_set = 1'b1;
    p_GrantBuffer__io_grantStatus_13_set = g_GrantBuffer__io_grantStatus_13_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_13_tag !== i_GrantBuffer__io_grantStatus_13_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_13_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_13_tag, i_GrantBuffer__io_grantStatus_13_tag);
    end
    if (g_GrantBuffer__io_grantStatus_13_tag !== p_GrantBuffer__io_grantStatus_13_tag) t_GrantBuffer__io_grantStatus_13_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_13_tag = g_GrantBuffer__io_grantStatus_13_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_14_valid !== i_GrantBuffer__io_grantStatus_14_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_14_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_14_valid, i_GrantBuffer__io_grantStatus_14_valid);
    end
    if (g_GrantBuffer__io_grantStatus_14_valid !== p_GrantBuffer__io_grantStatus_14_valid) t_GrantBuffer__io_grantStatus_14_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_14_valid = g_GrantBuffer__io_grantStatus_14_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_14_set !== i_GrantBuffer__io_grantStatus_14_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_14_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_14_set, i_GrantBuffer__io_grantStatus_14_set);
    end
    if (g_GrantBuffer__io_grantStatus_14_set !== p_GrantBuffer__io_grantStatus_14_set) t_GrantBuffer__io_grantStatus_14_set = 1'b1;
    p_GrantBuffer__io_grantStatus_14_set = g_GrantBuffer__io_grantStatus_14_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_14_tag !== i_GrantBuffer__io_grantStatus_14_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_14_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_14_tag, i_GrantBuffer__io_grantStatus_14_tag);
    end
    if (g_GrantBuffer__io_grantStatus_14_tag !== p_GrantBuffer__io_grantStatus_14_tag) t_GrantBuffer__io_grantStatus_14_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_14_tag = g_GrantBuffer__io_grantStatus_14_tag;
    checks++;
    if (g_GrantBuffer__io_grantStatus_15_valid !== i_GrantBuffer__io_grantStatus_15_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_15_valid g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_15_valid, i_GrantBuffer__io_grantStatus_15_valid);
    end
    if (g_GrantBuffer__io_grantStatus_15_valid !== p_GrantBuffer__io_grantStatus_15_valid) t_GrantBuffer__io_grantStatus_15_valid = 1'b1;
    p_GrantBuffer__io_grantStatus_15_valid = g_GrantBuffer__io_grantStatus_15_valid;
    checks++;
    if (g_GrantBuffer__io_grantStatus_15_set !== i_GrantBuffer__io_grantStatus_15_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_15_set g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_15_set, i_GrantBuffer__io_grantStatus_15_set);
    end
    if (g_GrantBuffer__io_grantStatus_15_set !== p_GrantBuffer__io_grantStatus_15_set) t_GrantBuffer__io_grantStatus_15_set = 1'b1;
    p_GrantBuffer__io_grantStatus_15_set = g_GrantBuffer__io_grantStatus_15_set;
    checks++;
    if (g_GrantBuffer__io_grantStatus_15_tag !== i_GrantBuffer__io_grantStatus_15_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH GrantBuffer.io_grantStatus_15_tag g=%h i=%h", cyc, g_GrantBuffer__io_grantStatus_15_tag, i_GrantBuffer__io_grantStatus_15_tag);
    end
    if (g_GrantBuffer__io_grantStatus_15_tag !== p_GrantBuffer__io_grantStatus_15_tag) t_GrantBuffer__io_grantStatus_15_tag = 1'b1;
    p_GrantBuffer__io_grantStatus_15_tag = g_GrantBuffer__io_grantStatus_15_tag;
  endtask
  longint cov_GrantBuffer_secondBeat = 0;
  longint cov_GrantBuffer_blockA = 0;
  longint cov_GrantBuffer_blockB = 0;
  longint cov_GrantBuffer_blockC = 0;
  longint cov_GrantBuffer_blockMSHR = 0;
  longint cov_GrantBuffer_pftBlock = 0;
  longint cov_GrantBuffer_inflightFull = 0;
  longint cov_GrantBuffer_keyword = 0;
  longint cov_GrantBuffer_timerClear = 0;
  task automatic cover_GrantBuffer();
    if (u_g_GrantBuffer.grantBufValid) cov_GrantBuffer_secondBeat++;
    if (u_g_GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockA_s1) cov_GrantBuffer_blockA++;
    if (u_g_GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockB_s1) cov_GrantBuffer_blockB++;
    if (u_g_GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockC_s1) cov_GrantBuffer_blockC++;
    if (u_g_GrantBuffer.io_toReqArb_blockMSHRReqEntrance) cov_GrantBuffer_blockMSHR++;
    if (u_g_GrantBuffer.noSpaceForMSHRPft_probe) cov_GrantBuffer_pftBlock++;
    if ((&{u_g_GrantBuffer.inflightGrant_0_valid, u_g_GrantBuffer.inflightGrant_1_valid, u_g_GrantBuffer.inflightGrant_2_valid, u_g_GrantBuffer.inflightGrant_3_valid, u_g_GrantBuffer.inflightGrant_4_valid, u_g_GrantBuffer.inflightGrant_5_valid, u_g_GrantBuffer.inflightGrant_6_valid, u_g_GrantBuffer.inflightGrant_7_valid, u_g_GrantBuffer.inflightGrant_8_valid, u_g_GrantBuffer.inflightGrant_9_valid, u_g_GrantBuffer.inflightGrant_10_valid, u_g_GrantBuffer.inflightGrant_11_valid, u_g_GrantBuffer.inflightGrant_12_valid, u_g_GrantBuffer.inflightGrant_13_valid, u_g_GrantBuffer.inflightGrant_14_valid, u_g_GrantBuffer.inflightGrant_15_valid})) cov_GrantBuffer_inflightFull++;
    if (u_g_GrantBuffer._grantQueue_io_deq_valid && u_g_GrantBuffer._grantQueue_io_deq_bits_task_isKeyword) cov_GrantBuffer_keyword++;
    if (u_g_GrantBuffer.REG && !u_g_GrantBuffer.inflightGrant_0_valid) cov_GrantBuffer_timerClear++;
  endtask
  task automatic preinit_GrantBuffer();
  endtask
  task automatic sync_GrantBuffer();
    u_i_GrantBuffer.grantQueue.ram_ext.Memory = u_g_GrantBuffer.grantQueue.ram_ext.Memory;
    u_i_GrantBuffer.grantQueueData0.ram_data_data_ext.Memory = u_g_GrantBuffer.grantQueueData0.ram_data_data_ext.Memory;
    u_i_GrantBuffer.grantQueueData1.ram_data_data_ext.Memory = u_g_GrantBuffer.grantQueueData1.ram_data_data_ext.Memory;
    u_i_GrantBuffer.pftRespQueue.ram_ext.Memory = u_g_GrantBuffer.pftRespQueue.ram_ext.Memory;
    force u_i_GrantBuffer.u_core.validPrev[0] = u_g_GrantBuffer.REG;
    #0 release u_i_GrantBuffer.u_core.validPrev[0];
    force u_i_GrantBuffer.u_core.histValidPrev[0] = u_g_GrantBuffer.enable_REG;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[0];
    force u_i_GrantBuffer.u_core.validPrev[1] = u_g_GrantBuffer.REG_1;
    #0 release u_i_GrantBuffer.u_core.validPrev[1];
    force u_i_GrantBuffer.u_core.histValidPrev[1] = u_g_GrantBuffer.enable_REG_1;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[1];
    force u_i_GrantBuffer.u_core.validPrev[2] = u_g_GrantBuffer.REG_2;
    #0 release u_i_GrantBuffer.u_core.validPrev[2];
    force u_i_GrantBuffer.u_core.histValidPrev[2] = u_g_GrantBuffer.enable_REG_2;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[2];
    force u_i_GrantBuffer.u_core.validPrev[3] = u_g_GrantBuffer.REG_3;
    #0 release u_i_GrantBuffer.u_core.validPrev[3];
    force u_i_GrantBuffer.u_core.histValidPrev[3] = u_g_GrantBuffer.enable_REG_3;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[3];
    force u_i_GrantBuffer.u_core.validPrev[4] = u_g_GrantBuffer.REG_4;
    #0 release u_i_GrantBuffer.u_core.validPrev[4];
    force u_i_GrantBuffer.u_core.histValidPrev[4] = u_g_GrantBuffer.enable_REG_4;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[4];
    force u_i_GrantBuffer.u_core.validPrev[5] = u_g_GrantBuffer.REG_5;
    #0 release u_i_GrantBuffer.u_core.validPrev[5];
    force u_i_GrantBuffer.u_core.histValidPrev[5] = u_g_GrantBuffer.enable_REG_5;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[5];
    force u_i_GrantBuffer.u_core.validPrev[6] = u_g_GrantBuffer.REG_6;
    #0 release u_i_GrantBuffer.u_core.validPrev[6];
    force u_i_GrantBuffer.u_core.histValidPrev[6] = u_g_GrantBuffer.enable_REG_6;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[6];
    force u_i_GrantBuffer.u_core.validPrev[7] = u_g_GrantBuffer.REG_7;
    #0 release u_i_GrantBuffer.u_core.validPrev[7];
    force u_i_GrantBuffer.u_core.histValidPrev[7] = u_g_GrantBuffer.enable_REG_7;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[7];
    force u_i_GrantBuffer.u_core.validPrev[8] = u_g_GrantBuffer.REG_8;
    #0 release u_i_GrantBuffer.u_core.validPrev[8];
    force u_i_GrantBuffer.u_core.histValidPrev[8] = u_g_GrantBuffer.enable_REG_8;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[8];
    force u_i_GrantBuffer.u_core.validPrev[9] = u_g_GrantBuffer.REG_9;
    #0 release u_i_GrantBuffer.u_core.validPrev[9];
    force u_i_GrantBuffer.u_core.histValidPrev[9] = u_g_GrantBuffer.enable_REG_9;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[9];
    force u_i_GrantBuffer.u_core.validPrev[10] = u_g_GrantBuffer.REG_10;
    #0 release u_i_GrantBuffer.u_core.validPrev[10];
    force u_i_GrantBuffer.u_core.histValidPrev[10] = u_g_GrantBuffer.enable_REG_10;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[10];
    force u_i_GrantBuffer.u_core.validPrev[11] = u_g_GrantBuffer.REG_11;
    #0 release u_i_GrantBuffer.u_core.validPrev[11];
    force u_i_GrantBuffer.u_core.histValidPrev[11] = u_g_GrantBuffer.enable_REG_11;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[11];
    force u_i_GrantBuffer.u_core.validPrev[12] = u_g_GrantBuffer.REG_12;
    #0 release u_i_GrantBuffer.u_core.validPrev[12];
    force u_i_GrantBuffer.u_core.histValidPrev[12] = u_g_GrantBuffer.enable_REG_12;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[12];
    force u_i_GrantBuffer.u_core.validPrev[13] = u_g_GrantBuffer.REG_13;
    #0 release u_i_GrantBuffer.u_core.validPrev[13];
    force u_i_GrantBuffer.u_core.histValidPrev[13] = u_g_GrantBuffer.enable_REG_13;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[13];
    force u_i_GrantBuffer.u_core.validPrev[14] = u_g_GrantBuffer.REG_14;
    #0 release u_i_GrantBuffer.u_core.validPrev[14];
    force u_i_GrantBuffer.u_core.histValidPrev[14] = u_g_GrantBuffer.enable_REG_14;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[14];
    force u_i_GrantBuffer.u_core.validPrev[15] = u_g_GrantBuffer.REG_15;
    #0 release u_i_GrantBuffer.u_core.validPrev[15];
    force u_i_GrantBuffer.u_core.histValidPrev[15] = u_g_GrantBuffer.enable_REG_15;
    #0 release u_i_GrantBuffer.u_core.histValidPrev[15];
  endtask

  // ======================= Queue10_GrantBuffer_Anon =======================
  logic Queue10_GrantBuffer_Anon__io_enq_valid;
  logic [30:0] Queue10_GrantBuffer_Anon__io_enq_bits_tag;
  logic [8:0] Queue10_GrantBuffer_Anon__io_enq_bits_set;
  logic [43:0] Queue10_GrantBuffer_Anon__io_enq_bits_vaddr;
  logic [4:0] Queue10_GrantBuffer_Anon__io_enq_bits_pfSource;
  logic Queue10_GrantBuffer_Anon__io_deq_ready;
  wire  g_Queue10_GrantBuffer_Anon__io_enq_ready;
  wire  i_Queue10_GrantBuffer_Anon__io_enq_ready;
  logic p_Queue10_GrantBuffer_Anon__io_enq_ready;
  bit   t_Queue10_GrantBuffer_Anon__io_enq_ready;
  wire  g_Queue10_GrantBuffer_Anon__io_deq_valid;
  wire  i_Queue10_GrantBuffer_Anon__io_deq_valid;
  logic p_Queue10_GrantBuffer_Anon__io_deq_valid;
  bit   t_Queue10_GrantBuffer_Anon__io_deq_valid;
  wire  [30:0] g_Queue10_GrantBuffer_Anon__io_deq_bits_tag;
  wire  [30:0] i_Queue10_GrantBuffer_Anon__io_deq_bits_tag;
  logic [30:0] p_Queue10_GrantBuffer_Anon__io_deq_bits_tag;
  bit   t_Queue10_GrantBuffer_Anon__io_deq_bits_tag;
  wire  [8:0] g_Queue10_GrantBuffer_Anon__io_deq_bits_set;
  wire  [8:0] i_Queue10_GrantBuffer_Anon__io_deq_bits_set;
  logic [8:0] p_Queue10_GrantBuffer_Anon__io_deq_bits_set;
  bit   t_Queue10_GrantBuffer_Anon__io_deq_bits_set;
  wire  [43:0] g_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr;
  wire  [43:0] i_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr;
  logic [43:0] p_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr;
  bit   t_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr;
  wire  [4:0] g_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource;
  wire  [4:0] i_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource;
  logic [4:0] p_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource;
  bit   t_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource;
  wire  [3:0] g_Queue10_GrantBuffer_Anon__io_count;
  wire  [3:0] i_Queue10_GrantBuffer_Anon__io_count;
  logic [3:0] p_Queue10_GrantBuffer_Anon__io_count;
  bit   t_Queue10_GrantBuffer_Anon__io_count;
  Queue10_GrantBuffer_Anon u_g_Queue10_GrantBuffer_Anon (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue10_GrantBuffer_Anon__io_enq_ready),
    .io_enq_valid (Queue10_GrantBuffer_Anon__io_enq_valid),
    .io_enq_bits_tag (Queue10_GrantBuffer_Anon__io_enq_bits_tag),
    .io_enq_bits_set (Queue10_GrantBuffer_Anon__io_enq_bits_set),
    .io_enq_bits_vaddr (Queue10_GrantBuffer_Anon__io_enq_bits_vaddr),
    .io_enq_bits_pfSource (Queue10_GrantBuffer_Anon__io_enq_bits_pfSource),
    .io_deq_ready (Queue10_GrantBuffer_Anon__io_deq_ready),
    .io_deq_valid (g_Queue10_GrantBuffer_Anon__io_deq_valid),
    .io_deq_bits_tag (g_Queue10_GrantBuffer_Anon__io_deq_bits_tag),
    .io_deq_bits_set (g_Queue10_GrantBuffer_Anon__io_deq_bits_set),
    .io_deq_bits_vaddr (g_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr),
    .io_deq_bits_pfSource (g_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource),
    .io_count (g_Queue10_GrantBuffer_Anon__io_count)
  );
  Queue10_GrantBuffer_Anon_xs u_i_Queue10_GrantBuffer_Anon (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue10_GrantBuffer_Anon__io_enq_ready),
    .io_enq_valid (Queue10_GrantBuffer_Anon__io_enq_valid),
    .io_enq_bits_tag (Queue10_GrantBuffer_Anon__io_enq_bits_tag),
    .io_enq_bits_set (Queue10_GrantBuffer_Anon__io_enq_bits_set),
    .io_enq_bits_vaddr (Queue10_GrantBuffer_Anon__io_enq_bits_vaddr),
    .io_enq_bits_pfSource (Queue10_GrantBuffer_Anon__io_enq_bits_pfSource),
    .io_deq_ready (Queue10_GrantBuffer_Anon__io_deq_ready),
    .io_deq_valid (i_Queue10_GrantBuffer_Anon__io_deq_valid),
    .io_deq_bits_tag (i_Queue10_GrantBuffer_Anon__io_deq_bits_tag),
    .io_deq_bits_set (i_Queue10_GrantBuffer_Anon__io_deq_bits_set),
    .io_deq_bits_vaddr (i_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr),
    .io_deq_bits_pfSource (i_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource),
    .io_count (i_Queue10_GrantBuffer_Anon__io_count)
  );
  task automatic drive_Queue10_GrantBuffer_Anon();
    Queue10_GrantBuffer_Anon__io_enq_valid = (($urandom % 2) == 0);
    Queue10_GrantBuffer_Anon__io_enq_bits_tag = rnd(31);
    Queue10_GrantBuffer_Anon__io_enq_bits_set = rnd(9);
    Queue10_GrantBuffer_Anon__io_enq_bits_vaddr = rnd(44);
    Queue10_GrantBuffer_Anon__io_enq_bits_pfSource = rnd(5);
    Queue10_GrantBuffer_Anon__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue10_GrantBuffer_Anon();
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_enq_ready !== i_Queue10_GrantBuffer_Anon__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_enq_ready g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_enq_ready, i_Queue10_GrantBuffer_Anon__io_enq_ready);
    end
    if (g_Queue10_GrantBuffer_Anon__io_enq_ready !== p_Queue10_GrantBuffer_Anon__io_enq_ready) t_Queue10_GrantBuffer_Anon__io_enq_ready = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_enq_ready = g_Queue10_GrantBuffer_Anon__io_enq_ready;
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_deq_valid !== i_Queue10_GrantBuffer_Anon__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_deq_valid g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_deq_valid, i_Queue10_GrantBuffer_Anon__io_deq_valid);
    end
    if (g_Queue10_GrantBuffer_Anon__io_deq_valid !== p_Queue10_GrantBuffer_Anon__io_deq_valid) t_Queue10_GrantBuffer_Anon__io_deq_valid = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_deq_valid = g_Queue10_GrantBuffer_Anon__io_deq_valid;
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_tag !== i_Queue10_GrantBuffer_Anon__io_deq_bits_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_deq_bits_tag g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_deq_bits_tag, i_Queue10_GrantBuffer_Anon__io_deq_bits_tag);
    end
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_tag !== p_Queue10_GrantBuffer_Anon__io_deq_bits_tag) t_Queue10_GrantBuffer_Anon__io_deq_bits_tag = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_deq_bits_tag = g_Queue10_GrantBuffer_Anon__io_deq_bits_tag;
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_set !== i_Queue10_GrantBuffer_Anon__io_deq_bits_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_deq_bits_set g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_deq_bits_set, i_Queue10_GrantBuffer_Anon__io_deq_bits_set);
    end
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_set !== p_Queue10_GrantBuffer_Anon__io_deq_bits_set) t_Queue10_GrantBuffer_Anon__io_deq_bits_set = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_deq_bits_set = g_Queue10_GrantBuffer_Anon__io_deq_bits_set;
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr !== i_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_deq_bits_vaddr g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr, i_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr);
    end
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr !== p_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr) t_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr = g_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr;
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource !== i_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_deq_bits_pfSource g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource, i_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource);
    end
    if (g_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource !== p_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource) t_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource = g_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource;
    checks++;
    if (g_Queue10_GrantBuffer_Anon__io_count !== i_Queue10_GrantBuffer_Anon__io_count) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue10_GrantBuffer_Anon.io_count g=%h i=%h", cyc, g_Queue10_GrantBuffer_Anon__io_count, i_Queue10_GrantBuffer_Anon__io_count);
    end
    if (g_Queue10_GrantBuffer_Anon__io_count !== p_Queue10_GrantBuffer_Anon__io_count) t_Queue10_GrantBuffer_Anon__io_count = 1'b1;
    p_Queue10_GrantBuffer_Anon__io_count = g_Queue10_GrantBuffer_Anon__io_count;
  endtask
  longint cov_Queue10_GrantBuffer_Anon_full = 0;
  longint cov_Queue10_GrantBuffer_Anon_bypass = 0;
  task automatic cover_Queue10_GrantBuffer_Anon();
    if (!u_g_Queue10_GrantBuffer_Anon.io_enq_ready) cov_Queue10_GrantBuffer_Anon_full++;
    if (u_g_Queue10_GrantBuffer_Anon.empty && Queue10_GrantBuffer_Anon__io_enq_valid && Queue10_GrantBuffer_Anon__io_deq_ready) cov_Queue10_GrantBuffer_Anon_bypass++;
  endtask
  task automatic preinit_Queue10_GrantBuffer_Anon();
  endtask
  task automatic sync_Queue10_GrantBuffer_Anon();
    u_i_Queue10_GrantBuffer_Anon.ram_ext.Memory = u_g_Queue10_GrantBuffer_Anon.ram_ext.Memory;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_GrantBuffer();
    drive_Queue10_GrantBuffer_Anon();
    #1;
    preinit_GrantBuffer();
    preinit_Queue10_GrantBuffer_Anon();
    sync_GrantBuffer();
    sync_Queue10_GrantBuffer_Anon();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_GrantBuffer();
      drive_Queue10_GrantBuffer_Anon();
      #1;
      check_GrantBuffer();
      cover_GrantBuffer();
      check_Queue10_GrantBuffer_Anon();
      cover_Queue10_GrantBuffer_Anon();
    end
    begin int tg; tg = 0;
      if (t_GrantBuffer__io_d_valid) tg++; else $display("COV: GrantBuffer.io_d_valid never toggled");
      if (t_GrantBuffer__io_d_bits_opcode) tg++; else $display("COV: GrantBuffer.io_d_bits_opcode never toggled");
      if (t_GrantBuffer__io_d_bits_param) tg++; else $display("COV: GrantBuffer.io_d_bits_param never toggled");
      if (t_GrantBuffer__io_d_bits_source) tg++; else $display("COV: GrantBuffer.io_d_bits_source never toggled");
      if (t_GrantBuffer__io_d_bits_sink) tg++; else $display("COV: GrantBuffer.io_d_bits_sink never toggled");
      if (t_GrantBuffer__io_d_bits_denied) tg++; else $display("COV: GrantBuffer.io_d_bits_denied never toggled");
      if (t_GrantBuffer__io_d_bits_echo_isKeyword) tg++; else $display("COV: GrantBuffer.io_d_bits_echo_isKeyword never toggled");
      if (t_GrantBuffer__io_d_bits_data) tg++; else $display("COV: GrantBuffer.io_d_bits_data never toggled");
      if (t_GrantBuffer__io_d_bits_corrupt) tg++; else $display("COV: GrantBuffer.io_d_bits_corrupt never toggled");
      if (t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockA_s1) tg++; else $display("COV: GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockA_s1 never toggled");
      if (t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockB_s1) tg++; else $display("COV: GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockB_s1 never toggled");
      if (t_GrantBuffer__io_toReqArb_blockSinkReqEntrance_blockC_s1) tg++; else $display("COV: GrantBuffer.io_toReqArb_blockSinkReqEntrance_blockC_s1 never toggled");
      if (t_GrantBuffer__io_toReqArb_blockMSHRReqEntrance) tg++; else $display("COV: GrantBuffer.io_toReqArb_blockMSHRReqEntrance never toggled");
      if (t_GrantBuffer__io_prefetchResp_valid) tg++; else $display("COV: GrantBuffer.io_prefetchResp_valid never toggled");
      if (t_GrantBuffer__io_prefetchResp_bits_tag) tg++; else $display("COV: GrantBuffer.io_prefetchResp_bits_tag never toggled");
      if (t_GrantBuffer__io_prefetchResp_bits_set) tg++; else $display("COV: GrantBuffer.io_prefetchResp_bits_set never toggled");
      if (t_GrantBuffer__io_prefetchResp_bits_vaddr) tg++; else $display("COV: GrantBuffer.io_prefetchResp_bits_vaddr never toggled");
      if (t_GrantBuffer__io_prefetchResp_bits_pfSource) tg++; else $display("COV: GrantBuffer.io_prefetchResp_bits_pfSource never toggled");
      if (t_GrantBuffer__io_grantStatus_0_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_0_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_0_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_0_set never toggled");
      if (t_GrantBuffer__io_grantStatus_0_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_0_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_1_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_1_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_1_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_1_set never toggled");
      if (t_GrantBuffer__io_grantStatus_1_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_1_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_2_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_2_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_2_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_2_set never toggled");
      if (t_GrantBuffer__io_grantStatus_2_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_2_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_3_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_3_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_3_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_3_set never toggled");
      if (t_GrantBuffer__io_grantStatus_3_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_3_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_4_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_4_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_4_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_4_set never toggled");
      if (t_GrantBuffer__io_grantStatus_4_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_4_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_5_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_5_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_5_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_5_set never toggled");
      if (t_GrantBuffer__io_grantStatus_5_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_5_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_6_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_6_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_6_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_6_set never toggled");
      if (t_GrantBuffer__io_grantStatus_6_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_6_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_7_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_7_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_7_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_7_set never toggled");
      if (t_GrantBuffer__io_grantStatus_7_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_7_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_8_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_8_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_8_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_8_set never toggled");
      if (t_GrantBuffer__io_grantStatus_8_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_8_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_9_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_9_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_9_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_9_set never toggled");
      if (t_GrantBuffer__io_grantStatus_9_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_9_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_10_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_10_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_10_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_10_set never toggled");
      if (t_GrantBuffer__io_grantStatus_10_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_10_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_11_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_11_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_11_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_11_set never toggled");
      if (t_GrantBuffer__io_grantStatus_11_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_11_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_12_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_12_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_12_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_12_set never toggled");
      if (t_GrantBuffer__io_grantStatus_12_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_12_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_13_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_13_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_13_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_13_set never toggled");
      if (t_GrantBuffer__io_grantStatus_13_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_13_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_14_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_14_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_14_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_14_set never toggled");
      if (t_GrantBuffer__io_grantStatus_14_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_14_tag never toggled");
      if (t_GrantBuffer__io_grantStatus_15_valid) tg++; else $display("COV: GrantBuffer.io_grantStatus_15_valid never toggled");
      if (t_GrantBuffer__io_grantStatus_15_set) tg++; else $display("COV: GrantBuffer.io_grantStatus_15_set never toggled");
      if (t_GrantBuffer__io_grantStatus_15_tag) tg++; else $display("COV: GrantBuffer.io_grantStatus_15_tag never toggled");
      $display("GrantBuffer: toggled=%0d/66 (need >= 66)", tg);
      if (tg < 66) covfail = 1;
      $display("GrantBuffer: cover secondBeat = %0d", cov_GrantBuffer_secondBeat);
      if (cov_GrantBuffer_secondBeat == 0) covfail = 1;
      $display("GrantBuffer: cover blockA = %0d", cov_GrantBuffer_blockA);
      if (cov_GrantBuffer_blockA == 0) covfail = 1;
      $display("GrantBuffer: cover blockB = %0d", cov_GrantBuffer_blockB);
      if (cov_GrantBuffer_blockB == 0) covfail = 1;
      $display("GrantBuffer: cover blockC = %0d", cov_GrantBuffer_blockC);
      if (cov_GrantBuffer_blockC == 0) covfail = 1;
      $display("GrantBuffer: cover blockMSHR = %0d", cov_GrantBuffer_blockMSHR);
      if (cov_GrantBuffer_blockMSHR == 0) covfail = 1;
      $display("GrantBuffer: cover pftBlock = %0d", cov_GrantBuffer_pftBlock);
      if (cov_GrantBuffer_pftBlock == 0) covfail = 1;
      $display("GrantBuffer: cover inflightFull = %0d", cov_GrantBuffer_inflightFull);
      if (cov_GrantBuffer_inflightFull == 0) covfail = 1;
      $display("GrantBuffer: cover keyword = %0d", cov_GrantBuffer_keyword);
      if (cov_GrantBuffer_keyword == 0) covfail = 1;
      $display("GrantBuffer: cover timerClear = %0d", cov_GrantBuffer_timerClear);
      if (cov_GrantBuffer_timerClear == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue10_GrantBuffer_Anon__io_enq_ready) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_enq_ready never toggled");
      if (t_Queue10_GrantBuffer_Anon__io_deq_valid) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_deq_valid never toggled");
      if (t_Queue10_GrantBuffer_Anon__io_deq_bits_tag) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_deq_bits_tag never toggled");
      if (t_Queue10_GrantBuffer_Anon__io_deq_bits_set) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_deq_bits_set never toggled");
      if (t_Queue10_GrantBuffer_Anon__io_deq_bits_vaddr) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_deq_bits_vaddr never toggled");
      if (t_Queue10_GrantBuffer_Anon__io_deq_bits_pfSource) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_deq_bits_pfSource never toggled");
      if (t_Queue10_GrantBuffer_Anon__io_count) tg++; else $display("COV: Queue10_GrantBuffer_Anon.io_count never toggled");
      $display("Queue10_GrantBuffer_Anon: toggled=%0d/7 (need >= 7)", tg);
      if (tg < 7) covfail = 1;
      $display("Queue10_GrantBuffer_Anon: cover full = %0d", cov_Queue10_GrantBuffer_Anon_full);
      if (cov_Queue10_GrantBuffer_Anon_full == 0) covfail = 1;
      $display("Queue10_GrantBuffer_Anon: cover bypass = %0d", cov_Queue10_GrantBuffer_Anon_bypass);
      if (cov_Queue10_GrantBuffer_Anon_bypass == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
