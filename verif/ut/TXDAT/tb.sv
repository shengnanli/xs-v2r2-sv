// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：TXDAT
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

  // ======================= TXDAT =======================
  logic TXDAT__io_in_valid;
  logic [2:0] TXDAT__io_in_bits_task_channel;
  logic [2:0] TXDAT__io_in_bits_task_txChannel;
  logic [8:0] TXDAT__io_in_bits_task_set;
  logic [30:0] TXDAT__io_in_bits_task_tag;
  logic [5:0] TXDAT__io_in_bits_task_off;
  logic [1:0] TXDAT__io_in_bits_task_alias;
  logic [43:0] TXDAT__io_in_bits_task_vaddr;
  logic TXDAT__io_in_bits_task_isKeyword;
  logic [3:0] TXDAT__io_in_bits_task_opcode;
  logic [2:0] TXDAT__io_in_bits_task_param;
  logic [2:0] TXDAT__io_in_bits_task_size;
  logic [6:0] TXDAT__io_in_bits_task_sourceId;
  logic [1:0] TXDAT__io_in_bits_task_bufIdx;
  logic TXDAT__io_in_bits_task_needProbeAckData;
  logic TXDAT__io_in_bits_task_denied;
  logic TXDAT__io_in_bits_task_corrupt;
  logic TXDAT__io_in_bits_task_mshrTask;
  logic [7:0] TXDAT__io_in_bits_task_mshrId;
  logic TXDAT__io_in_bits_task_aliasTask;
  logic TXDAT__io_in_bits_task_useProbeData;
  logic TXDAT__io_in_bits_task_mshrRetry;
  logic TXDAT__io_in_bits_task_readProbeDataDown;
  logic TXDAT__io_in_bits_task_fromL2pft;
  logic TXDAT__io_in_bits_task_needHint;
  logic TXDAT__io_in_bits_task_dirty;
  logic [2:0] TXDAT__io_in_bits_task_way;
  logic TXDAT__io_in_bits_task_meta_dirty;
  logic [1:0] TXDAT__io_in_bits_task_meta_state;
  logic TXDAT__io_in_bits_task_meta_clients;
  logic [1:0] TXDAT__io_in_bits_task_meta_alias;
  logic TXDAT__io_in_bits_task_meta_prefetch;
  logic [2:0] TXDAT__io_in_bits_task_meta_prefetchSrc;
  logic TXDAT__io_in_bits_task_meta_accessed;
  logic TXDAT__io_in_bits_task_meta_tagErr;
  logic TXDAT__io_in_bits_task_meta_dataErr;
  logic TXDAT__io_in_bits_task_metaWen;
  logic TXDAT__io_in_bits_task_tagWen;
  logic TXDAT__io_in_bits_task_dsWen;
  logic [7:0] TXDAT__io_in_bits_task_wayMask;
  logic TXDAT__io_in_bits_task_replTask;
  logic TXDAT__io_in_bits_task_cmoTask;
  logic TXDAT__io_in_bits_task_cmoAll;
  logic [4:0] TXDAT__io_in_bits_task_reqSource;
  logic TXDAT__io_in_bits_task_mergeA;
  logic [5:0] TXDAT__io_in_bits_task_aMergeTask_off;
  logic [1:0] TXDAT__io_in_bits_task_aMergeTask_alias;
  logic [43:0] TXDAT__io_in_bits_task_aMergeTask_vaddr;
  logic TXDAT__io_in_bits_task_aMergeTask_isKeyword;
  logic [2:0] TXDAT__io_in_bits_task_aMergeTask_opcode;
  logic [2:0] TXDAT__io_in_bits_task_aMergeTask_param;
  logic [6:0] TXDAT__io_in_bits_task_aMergeTask_sourceId;
  logic TXDAT__io_in_bits_task_aMergeTask_meta_dirty;
  logic [1:0] TXDAT__io_in_bits_task_aMergeTask_meta_state;
  logic TXDAT__io_in_bits_task_aMergeTask_meta_clients;
  logic [1:0] TXDAT__io_in_bits_task_aMergeTask_meta_alias;
  logic TXDAT__io_in_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] TXDAT__io_in_bits_task_aMergeTask_meta_prefetchSrc;
  logic TXDAT__io_in_bits_task_aMergeTask_meta_accessed;
  logic TXDAT__io_in_bits_task_aMergeTask_meta_tagErr;
  logic TXDAT__io_in_bits_task_aMergeTask_meta_dataErr;
  logic TXDAT__io_in_bits_task_snpHitRelease;
  logic TXDAT__io_in_bits_task_snpHitReleaseToInval;
  logic TXDAT__io_in_bits_task_snpHitReleaseToClean;
  logic TXDAT__io_in_bits_task_snpHitReleaseWithData;
  logic [7:0] TXDAT__io_in_bits_task_snpHitReleaseIdx;
  logic TXDAT__io_in_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] TXDAT__io_in_bits_task_snpHitReleaseMeta_state;
  logic TXDAT__io_in_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] TXDAT__io_in_bits_task_snpHitReleaseMeta_alias;
  logic TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic TXDAT__io_in_bits_task_snpHitReleaseMeta_accessed;
  logic TXDAT__io_in_bits_task_snpHitReleaseMeta_tagErr;
  logic TXDAT__io_in_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] TXDAT__io_in_bits_task_tgtID;
  logic [10:0] TXDAT__io_in_bits_task_srcID;
  logic [11:0] TXDAT__io_in_bits_task_txnID;
  logic [10:0] TXDAT__io_in_bits_task_homeNID;
  logic [11:0] TXDAT__io_in_bits_task_dbID;
  logic [10:0] TXDAT__io_in_bits_task_fwdNID;
  logic [11:0] TXDAT__io_in_bits_task_fwdTxnID;
  logic [6:0] TXDAT__io_in_bits_task_chiOpcode;
  logic [2:0] TXDAT__io_in_bits_task_resp;
  logic [2:0] TXDAT__io_in_bits_task_fwdState;
  logic [3:0] TXDAT__io_in_bits_task_pCrdType;
  logic TXDAT__io_in_bits_task_retToSrc;
  logic TXDAT__io_in_bits_task_likelyshared;
  logic TXDAT__io_in_bits_task_expCompAck;
  logic TXDAT__io_in_bits_task_allowRetry;
  logic TXDAT__io_in_bits_task_memAttr_allocate;
  logic TXDAT__io_in_bits_task_memAttr_cacheable;
  logic TXDAT__io_in_bits_task_memAttr_device;
  logic TXDAT__io_in_bits_task_memAttr_ewa;
  logic TXDAT__io_in_bits_task_traceTag;
  logic [511:0] TXDAT__io_in_bits_data_data;
  logic TXDAT__io_out_ready;
  logic TXDAT__io_pipeStatusVec_1_valid;
  logic [2:0] TXDAT__io_pipeStatusVec_1_bits_channel;
  logic [2:0] TXDAT__io_pipeStatusVec_1_bits_txChannel;
  logic TXDAT__io_pipeStatusVec_1_bits_mshrTask;
  logic TXDAT__io_pipeStatusVec_2_valid;
  logic [2:0] TXDAT__io_pipeStatusVec_2_bits_channel;
  logic [2:0] TXDAT__io_pipeStatusVec_2_bits_txChannel;
  logic TXDAT__io_pipeStatusVec_2_bits_mshrTask;
  logic TXDAT__io_pipeStatusVec_3_valid;
  logic [2:0] TXDAT__io_pipeStatusVec_3_bits_channel;
  logic [2:0] TXDAT__io_pipeStatusVec_3_bits_txChannel;
  logic TXDAT__io_pipeStatusVec_3_bits_mshrTask;
  logic TXDAT__io_pipeStatusVec_4_valid;
  logic [2:0] TXDAT__io_pipeStatusVec_4_bits_channel;
  logic [2:0] TXDAT__io_pipeStatusVec_4_bits_txChannel;
  logic TXDAT__io_pipeStatusVec_4_bits_mshrTask;
  wire  g_TXDAT__io_in_ready;
  wire  i_TXDAT__io_in_ready;
  logic p_TXDAT__io_in_ready;
  bit   t_TXDAT__io_in_ready;
  wire  g_TXDAT__io_out_valid;
  wire  i_TXDAT__io_out_valid;
  logic p_TXDAT__io_out_valid;
  bit   t_TXDAT__io_out_valid;
  wire  [10:0] g_TXDAT__io_out_bits_tgtID;
  wire  [10:0] i_TXDAT__io_out_bits_tgtID;
  logic [10:0] p_TXDAT__io_out_bits_tgtID;
  bit   t_TXDAT__io_out_bits_tgtID;
  wire  [11:0] g_TXDAT__io_out_bits_txnID;
  wire  [11:0] i_TXDAT__io_out_bits_txnID;
  logic [11:0] p_TXDAT__io_out_bits_txnID;
  bit   t_TXDAT__io_out_bits_txnID;
  wire  [10:0] g_TXDAT__io_out_bits_homeNID;
  wire  [10:0] i_TXDAT__io_out_bits_homeNID;
  logic [10:0] p_TXDAT__io_out_bits_homeNID;
  bit   t_TXDAT__io_out_bits_homeNID;
  wire  [3:0] g_TXDAT__io_out_bits_opcode;
  wire  [3:0] i_TXDAT__io_out_bits_opcode;
  logic [3:0] p_TXDAT__io_out_bits_opcode;
  bit   t_TXDAT__io_out_bits_opcode;
  wire  [1:0] g_TXDAT__io_out_bits_respErr;
  wire  [1:0] i_TXDAT__io_out_bits_respErr;
  logic [1:0] p_TXDAT__io_out_bits_respErr;
  bit   t_TXDAT__io_out_bits_respErr;
  wire  [2:0] g_TXDAT__io_out_bits_resp;
  wire  [2:0] i_TXDAT__io_out_bits_resp;
  logic [2:0] p_TXDAT__io_out_bits_resp;
  bit   t_TXDAT__io_out_bits_resp;
  wire  [3:0] g_TXDAT__io_out_bits_dataSource;
  wire  [3:0] i_TXDAT__io_out_bits_dataSource;
  logic [3:0] p_TXDAT__io_out_bits_dataSource;
  bit   t_TXDAT__io_out_bits_dataSource;
  wire  [11:0] g_TXDAT__io_out_bits_dbID;
  wire  [11:0] i_TXDAT__io_out_bits_dbID;
  logic [11:0] p_TXDAT__io_out_bits_dbID;
  bit   t_TXDAT__io_out_bits_dbID;
  wire  [1:0] g_TXDAT__io_out_bits_ccID;
  wire  [1:0] i_TXDAT__io_out_bits_ccID;
  logic [1:0] p_TXDAT__io_out_bits_ccID;
  bit   t_TXDAT__io_out_bits_ccID;
  wire  [1:0] g_TXDAT__io_out_bits_dataID;
  wire  [1:0] i_TXDAT__io_out_bits_dataID;
  logic [1:0] p_TXDAT__io_out_bits_dataID;
  bit   t_TXDAT__io_out_bits_dataID;
  wire  g_TXDAT__io_out_bits_traceTag;
  wire  i_TXDAT__io_out_bits_traceTag;
  logic p_TXDAT__io_out_bits_traceTag;
  bit   t_TXDAT__io_out_bits_traceTag;
  wire  [31:0] g_TXDAT__io_out_bits_be;
  wire  [31:0] i_TXDAT__io_out_bits_be;
  logic [31:0] p_TXDAT__io_out_bits_be;
  bit   t_TXDAT__io_out_bits_be;
  wire  [255:0] g_TXDAT__io_out_bits_data;
  wire  [255:0] i_TXDAT__io_out_bits_data;
  logic [255:0] p_TXDAT__io_out_bits_data;
  bit   t_TXDAT__io_out_bits_data;
  wire  [31:0] g_TXDAT__io_out_bits_dataCheck;
  wire  [31:0] i_TXDAT__io_out_bits_dataCheck;
  logic [31:0] p_TXDAT__io_out_bits_dataCheck;
  bit   t_TXDAT__io_out_bits_dataCheck;
  wire  [3:0] g_TXDAT__io_out_bits_poison;
  wire  [3:0] i_TXDAT__io_out_bits_poison;
  logic [3:0] p_TXDAT__io_out_bits_poison;
  bit   t_TXDAT__io_out_bits_poison;
  wire  g_TXDAT__io_toReqArb_blockMSHRReqEntrance;
  wire  i_TXDAT__io_toReqArb_blockMSHRReqEntrance;
  logic p_TXDAT__io_toReqArb_blockMSHRReqEntrance;
  bit   t_TXDAT__io_toReqArb_blockMSHRReqEntrance;
  wire  g_TXDAT__io_toReqArb_blockSinkBReqEntrance;
  wire  i_TXDAT__io_toReqArb_blockSinkBReqEntrance;
  logic p_TXDAT__io_toReqArb_blockSinkBReqEntrance;
  bit   t_TXDAT__io_toReqArb_blockSinkBReqEntrance;
  TXDAT u_g_TXDAT (
    .clock (clock),
    .reset (reset),
    .io_in_ready (g_TXDAT__io_in_ready),
    .io_in_valid (TXDAT__io_in_valid),
    .io_in_bits_task_channel (TXDAT__io_in_bits_task_channel),
    .io_in_bits_task_txChannel (TXDAT__io_in_bits_task_txChannel),
    .io_in_bits_task_set (TXDAT__io_in_bits_task_set),
    .io_in_bits_task_tag (TXDAT__io_in_bits_task_tag),
    .io_in_bits_task_off (TXDAT__io_in_bits_task_off),
    .io_in_bits_task_alias (TXDAT__io_in_bits_task_alias),
    .io_in_bits_task_vaddr (TXDAT__io_in_bits_task_vaddr),
    .io_in_bits_task_isKeyword (TXDAT__io_in_bits_task_isKeyword),
    .io_in_bits_task_opcode (TXDAT__io_in_bits_task_opcode),
    .io_in_bits_task_param (TXDAT__io_in_bits_task_param),
    .io_in_bits_task_size (TXDAT__io_in_bits_task_size),
    .io_in_bits_task_sourceId (TXDAT__io_in_bits_task_sourceId),
    .io_in_bits_task_bufIdx (TXDAT__io_in_bits_task_bufIdx),
    .io_in_bits_task_needProbeAckData (TXDAT__io_in_bits_task_needProbeAckData),
    .io_in_bits_task_denied (TXDAT__io_in_bits_task_denied),
    .io_in_bits_task_corrupt (TXDAT__io_in_bits_task_corrupt),
    .io_in_bits_task_mshrTask (TXDAT__io_in_bits_task_mshrTask),
    .io_in_bits_task_mshrId (TXDAT__io_in_bits_task_mshrId),
    .io_in_bits_task_aliasTask (TXDAT__io_in_bits_task_aliasTask),
    .io_in_bits_task_useProbeData (TXDAT__io_in_bits_task_useProbeData),
    .io_in_bits_task_mshrRetry (TXDAT__io_in_bits_task_mshrRetry),
    .io_in_bits_task_readProbeDataDown (TXDAT__io_in_bits_task_readProbeDataDown),
    .io_in_bits_task_fromL2pft (TXDAT__io_in_bits_task_fromL2pft),
    .io_in_bits_task_needHint (TXDAT__io_in_bits_task_needHint),
    .io_in_bits_task_dirty (TXDAT__io_in_bits_task_dirty),
    .io_in_bits_task_way (TXDAT__io_in_bits_task_way),
    .io_in_bits_task_meta_dirty (TXDAT__io_in_bits_task_meta_dirty),
    .io_in_bits_task_meta_state (TXDAT__io_in_bits_task_meta_state),
    .io_in_bits_task_meta_clients (TXDAT__io_in_bits_task_meta_clients),
    .io_in_bits_task_meta_alias (TXDAT__io_in_bits_task_meta_alias),
    .io_in_bits_task_meta_prefetch (TXDAT__io_in_bits_task_meta_prefetch),
    .io_in_bits_task_meta_prefetchSrc (TXDAT__io_in_bits_task_meta_prefetchSrc),
    .io_in_bits_task_meta_accessed (TXDAT__io_in_bits_task_meta_accessed),
    .io_in_bits_task_meta_tagErr (TXDAT__io_in_bits_task_meta_tagErr),
    .io_in_bits_task_meta_dataErr (TXDAT__io_in_bits_task_meta_dataErr),
    .io_in_bits_task_metaWen (TXDAT__io_in_bits_task_metaWen),
    .io_in_bits_task_tagWen (TXDAT__io_in_bits_task_tagWen),
    .io_in_bits_task_dsWen (TXDAT__io_in_bits_task_dsWen),
    .io_in_bits_task_wayMask (TXDAT__io_in_bits_task_wayMask),
    .io_in_bits_task_replTask (TXDAT__io_in_bits_task_replTask),
    .io_in_bits_task_cmoTask (TXDAT__io_in_bits_task_cmoTask),
    .io_in_bits_task_cmoAll (TXDAT__io_in_bits_task_cmoAll),
    .io_in_bits_task_reqSource (TXDAT__io_in_bits_task_reqSource),
    .io_in_bits_task_mergeA (TXDAT__io_in_bits_task_mergeA),
    .io_in_bits_task_aMergeTask_off (TXDAT__io_in_bits_task_aMergeTask_off),
    .io_in_bits_task_aMergeTask_alias (TXDAT__io_in_bits_task_aMergeTask_alias),
    .io_in_bits_task_aMergeTask_vaddr (TXDAT__io_in_bits_task_aMergeTask_vaddr),
    .io_in_bits_task_aMergeTask_isKeyword (TXDAT__io_in_bits_task_aMergeTask_isKeyword),
    .io_in_bits_task_aMergeTask_opcode (TXDAT__io_in_bits_task_aMergeTask_opcode),
    .io_in_bits_task_aMergeTask_param (TXDAT__io_in_bits_task_aMergeTask_param),
    .io_in_bits_task_aMergeTask_sourceId (TXDAT__io_in_bits_task_aMergeTask_sourceId),
    .io_in_bits_task_aMergeTask_meta_dirty (TXDAT__io_in_bits_task_aMergeTask_meta_dirty),
    .io_in_bits_task_aMergeTask_meta_state (TXDAT__io_in_bits_task_aMergeTask_meta_state),
    .io_in_bits_task_aMergeTask_meta_clients (TXDAT__io_in_bits_task_aMergeTask_meta_clients),
    .io_in_bits_task_aMergeTask_meta_alias (TXDAT__io_in_bits_task_aMergeTask_meta_alias),
    .io_in_bits_task_aMergeTask_meta_prefetch (TXDAT__io_in_bits_task_aMergeTask_meta_prefetch),
    .io_in_bits_task_aMergeTask_meta_prefetchSrc (TXDAT__io_in_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_bits_task_aMergeTask_meta_accessed (TXDAT__io_in_bits_task_aMergeTask_meta_accessed),
    .io_in_bits_task_aMergeTask_meta_tagErr (TXDAT__io_in_bits_task_aMergeTask_meta_tagErr),
    .io_in_bits_task_aMergeTask_meta_dataErr (TXDAT__io_in_bits_task_aMergeTask_meta_dataErr),
    .io_in_bits_task_snpHitRelease (TXDAT__io_in_bits_task_snpHitRelease),
    .io_in_bits_task_snpHitReleaseToInval (TXDAT__io_in_bits_task_snpHitReleaseToInval),
    .io_in_bits_task_snpHitReleaseToClean (TXDAT__io_in_bits_task_snpHitReleaseToClean),
    .io_in_bits_task_snpHitReleaseWithData (TXDAT__io_in_bits_task_snpHitReleaseWithData),
    .io_in_bits_task_snpHitReleaseIdx (TXDAT__io_in_bits_task_snpHitReleaseIdx),
    .io_in_bits_task_snpHitReleaseMeta_dirty (TXDAT__io_in_bits_task_snpHitReleaseMeta_dirty),
    .io_in_bits_task_snpHitReleaseMeta_state (TXDAT__io_in_bits_task_snpHitReleaseMeta_state),
    .io_in_bits_task_snpHitReleaseMeta_clients (TXDAT__io_in_bits_task_snpHitReleaseMeta_clients),
    .io_in_bits_task_snpHitReleaseMeta_alias (TXDAT__io_in_bits_task_snpHitReleaseMeta_alias),
    .io_in_bits_task_snpHitReleaseMeta_prefetch (TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_bits_task_snpHitReleaseMeta_prefetchSrc (TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_bits_task_snpHitReleaseMeta_accessed (TXDAT__io_in_bits_task_snpHitReleaseMeta_accessed),
    .io_in_bits_task_snpHitReleaseMeta_tagErr (TXDAT__io_in_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_bits_task_snpHitReleaseMeta_dataErr (TXDAT__io_in_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_bits_task_tgtID (TXDAT__io_in_bits_task_tgtID),
    .io_in_bits_task_srcID (TXDAT__io_in_bits_task_srcID),
    .io_in_bits_task_txnID (TXDAT__io_in_bits_task_txnID),
    .io_in_bits_task_homeNID (TXDAT__io_in_bits_task_homeNID),
    .io_in_bits_task_dbID (TXDAT__io_in_bits_task_dbID),
    .io_in_bits_task_fwdNID (TXDAT__io_in_bits_task_fwdNID),
    .io_in_bits_task_fwdTxnID (TXDAT__io_in_bits_task_fwdTxnID),
    .io_in_bits_task_chiOpcode (TXDAT__io_in_bits_task_chiOpcode),
    .io_in_bits_task_resp (TXDAT__io_in_bits_task_resp),
    .io_in_bits_task_fwdState (TXDAT__io_in_bits_task_fwdState),
    .io_in_bits_task_pCrdType (TXDAT__io_in_bits_task_pCrdType),
    .io_in_bits_task_retToSrc (TXDAT__io_in_bits_task_retToSrc),
    .io_in_bits_task_likelyshared (TXDAT__io_in_bits_task_likelyshared),
    .io_in_bits_task_expCompAck (TXDAT__io_in_bits_task_expCompAck),
    .io_in_bits_task_allowRetry (TXDAT__io_in_bits_task_allowRetry),
    .io_in_bits_task_memAttr_allocate (TXDAT__io_in_bits_task_memAttr_allocate),
    .io_in_bits_task_memAttr_cacheable (TXDAT__io_in_bits_task_memAttr_cacheable),
    .io_in_bits_task_memAttr_device (TXDAT__io_in_bits_task_memAttr_device),
    .io_in_bits_task_memAttr_ewa (TXDAT__io_in_bits_task_memAttr_ewa),
    .io_in_bits_task_traceTag (TXDAT__io_in_bits_task_traceTag),
    .io_in_bits_data_data (TXDAT__io_in_bits_data_data),
    .io_out_ready (TXDAT__io_out_ready),
    .io_out_valid (g_TXDAT__io_out_valid),
    .io_out_bits_tgtID (g_TXDAT__io_out_bits_tgtID),
    .io_out_bits_txnID (g_TXDAT__io_out_bits_txnID),
    .io_out_bits_homeNID (g_TXDAT__io_out_bits_homeNID),
    .io_out_bits_opcode (g_TXDAT__io_out_bits_opcode),
    .io_out_bits_respErr (g_TXDAT__io_out_bits_respErr),
    .io_out_bits_resp (g_TXDAT__io_out_bits_resp),
    .io_out_bits_dataSource (g_TXDAT__io_out_bits_dataSource),
    .io_out_bits_dbID (g_TXDAT__io_out_bits_dbID),
    .io_out_bits_ccID (g_TXDAT__io_out_bits_ccID),
    .io_out_bits_dataID (g_TXDAT__io_out_bits_dataID),
    .io_out_bits_traceTag (g_TXDAT__io_out_bits_traceTag),
    .io_out_bits_be (g_TXDAT__io_out_bits_be),
    .io_out_bits_data (g_TXDAT__io_out_bits_data),
    .io_out_bits_dataCheck (g_TXDAT__io_out_bits_dataCheck),
    .io_out_bits_poison (g_TXDAT__io_out_bits_poison),
    .io_pipeStatusVec_1_valid (TXDAT__io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel (TXDAT__io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel (TXDAT__io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask (TXDAT__io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid (TXDAT__io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel (TXDAT__io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel (TXDAT__io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask (TXDAT__io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid (TXDAT__io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel (TXDAT__io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel (TXDAT__io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask (TXDAT__io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid (TXDAT__io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel (TXDAT__io_pipeStatusVec_4_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel (TXDAT__io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask (TXDAT__io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance (g_TXDAT__io_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance (g_TXDAT__io_toReqArb_blockSinkBReqEntrance)
  );
  TXDAT_xs u_i_TXDAT (
    .clock (clock),
    .reset (reset),
    .io_in_ready (i_TXDAT__io_in_ready),
    .io_in_valid (TXDAT__io_in_valid),
    .io_in_bits_task_channel (TXDAT__io_in_bits_task_channel),
    .io_in_bits_task_txChannel (TXDAT__io_in_bits_task_txChannel),
    .io_in_bits_task_set (TXDAT__io_in_bits_task_set),
    .io_in_bits_task_tag (TXDAT__io_in_bits_task_tag),
    .io_in_bits_task_off (TXDAT__io_in_bits_task_off),
    .io_in_bits_task_alias (TXDAT__io_in_bits_task_alias),
    .io_in_bits_task_vaddr (TXDAT__io_in_bits_task_vaddr),
    .io_in_bits_task_isKeyword (TXDAT__io_in_bits_task_isKeyword),
    .io_in_bits_task_opcode (TXDAT__io_in_bits_task_opcode),
    .io_in_bits_task_param (TXDAT__io_in_bits_task_param),
    .io_in_bits_task_size (TXDAT__io_in_bits_task_size),
    .io_in_bits_task_sourceId (TXDAT__io_in_bits_task_sourceId),
    .io_in_bits_task_bufIdx (TXDAT__io_in_bits_task_bufIdx),
    .io_in_bits_task_needProbeAckData (TXDAT__io_in_bits_task_needProbeAckData),
    .io_in_bits_task_denied (TXDAT__io_in_bits_task_denied),
    .io_in_bits_task_corrupt (TXDAT__io_in_bits_task_corrupt),
    .io_in_bits_task_mshrTask (TXDAT__io_in_bits_task_mshrTask),
    .io_in_bits_task_mshrId (TXDAT__io_in_bits_task_mshrId),
    .io_in_bits_task_aliasTask (TXDAT__io_in_bits_task_aliasTask),
    .io_in_bits_task_useProbeData (TXDAT__io_in_bits_task_useProbeData),
    .io_in_bits_task_mshrRetry (TXDAT__io_in_bits_task_mshrRetry),
    .io_in_bits_task_readProbeDataDown (TXDAT__io_in_bits_task_readProbeDataDown),
    .io_in_bits_task_fromL2pft (TXDAT__io_in_bits_task_fromL2pft),
    .io_in_bits_task_needHint (TXDAT__io_in_bits_task_needHint),
    .io_in_bits_task_dirty (TXDAT__io_in_bits_task_dirty),
    .io_in_bits_task_way (TXDAT__io_in_bits_task_way),
    .io_in_bits_task_meta_dirty (TXDAT__io_in_bits_task_meta_dirty),
    .io_in_bits_task_meta_state (TXDAT__io_in_bits_task_meta_state),
    .io_in_bits_task_meta_clients (TXDAT__io_in_bits_task_meta_clients),
    .io_in_bits_task_meta_alias (TXDAT__io_in_bits_task_meta_alias),
    .io_in_bits_task_meta_prefetch (TXDAT__io_in_bits_task_meta_prefetch),
    .io_in_bits_task_meta_prefetchSrc (TXDAT__io_in_bits_task_meta_prefetchSrc),
    .io_in_bits_task_meta_accessed (TXDAT__io_in_bits_task_meta_accessed),
    .io_in_bits_task_meta_tagErr (TXDAT__io_in_bits_task_meta_tagErr),
    .io_in_bits_task_meta_dataErr (TXDAT__io_in_bits_task_meta_dataErr),
    .io_in_bits_task_metaWen (TXDAT__io_in_bits_task_metaWen),
    .io_in_bits_task_tagWen (TXDAT__io_in_bits_task_tagWen),
    .io_in_bits_task_dsWen (TXDAT__io_in_bits_task_dsWen),
    .io_in_bits_task_wayMask (TXDAT__io_in_bits_task_wayMask),
    .io_in_bits_task_replTask (TXDAT__io_in_bits_task_replTask),
    .io_in_bits_task_cmoTask (TXDAT__io_in_bits_task_cmoTask),
    .io_in_bits_task_cmoAll (TXDAT__io_in_bits_task_cmoAll),
    .io_in_bits_task_reqSource (TXDAT__io_in_bits_task_reqSource),
    .io_in_bits_task_mergeA (TXDAT__io_in_bits_task_mergeA),
    .io_in_bits_task_aMergeTask_off (TXDAT__io_in_bits_task_aMergeTask_off),
    .io_in_bits_task_aMergeTask_alias (TXDAT__io_in_bits_task_aMergeTask_alias),
    .io_in_bits_task_aMergeTask_vaddr (TXDAT__io_in_bits_task_aMergeTask_vaddr),
    .io_in_bits_task_aMergeTask_isKeyword (TXDAT__io_in_bits_task_aMergeTask_isKeyword),
    .io_in_bits_task_aMergeTask_opcode (TXDAT__io_in_bits_task_aMergeTask_opcode),
    .io_in_bits_task_aMergeTask_param (TXDAT__io_in_bits_task_aMergeTask_param),
    .io_in_bits_task_aMergeTask_sourceId (TXDAT__io_in_bits_task_aMergeTask_sourceId),
    .io_in_bits_task_aMergeTask_meta_dirty (TXDAT__io_in_bits_task_aMergeTask_meta_dirty),
    .io_in_bits_task_aMergeTask_meta_state (TXDAT__io_in_bits_task_aMergeTask_meta_state),
    .io_in_bits_task_aMergeTask_meta_clients (TXDAT__io_in_bits_task_aMergeTask_meta_clients),
    .io_in_bits_task_aMergeTask_meta_alias (TXDAT__io_in_bits_task_aMergeTask_meta_alias),
    .io_in_bits_task_aMergeTask_meta_prefetch (TXDAT__io_in_bits_task_aMergeTask_meta_prefetch),
    .io_in_bits_task_aMergeTask_meta_prefetchSrc (TXDAT__io_in_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_bits_task_aMergeTask_meta_accessed (TXDAT__io_in_bits_task_aMergeTask_meta_accessed),
    .io_in_bits_task_aMergeTask_meta_tagErr (TXDAT__io_in_bits_task_aMergeTask_meta_tagErr),
    .io_in_bits_task_aMergeTask_meta_dataErr (TXDAT__io_in_bits_task_aMergeTask_meta_dataErr),
    .io_in_bits_task_snpHitRelease (TXDAT__io_in_bits_task_snpHitRelease),
    .io_in_bits_task_snpHitReleaseToInval (TXDAT__io_in_bits_task_snpHitReleaseToInval),
    .io_in_bits_task_snpHitReleaseToClean (TXDAT__io_in_bits_task_snpHitReleaseToClean),
    .io_in_bits_task_snpHitReleaseWithData (TXDAT__io_in_bits_task_snpHitReleaseWithData),
    .io_in_bits_task_snpHitReleaseIdx (TXDAT__io_in_bits_task_snpHitReleaseIdx),
    .io_in_bits_task_snpHitReleaseMeta_dirty (TXDAT__io_in_bits_task_snpHitReleaseMeta_dirty),
    .io_in_bits_task_snpHitReleaseMeta_state (TXDAT__io_in_bits_task_snpHitReleaseMeta_state),
    .io_in_bits_task_snpHitReleaseMeta_clients (TXDAT__io_in_bits_task_snpHitReleaseMeta_clients),
    .io_in_bits_task_snpHitReleaseMeta_alias (TXDAT__io_in_bits_task_snpHitReleaseMeta_alias),
    .io_in_bits_task_snpHitReleaseMeta_prefetch (TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_bits_task_snpHitReleaseMeta_prefetchSrc (TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_bits_task_snpHitReleaseMeta_accessed (TXDAT__io_in_bits_task_snpHitReleaseMeta_accessed),
    .io_in_bits_task_snpHitReleaseMeta_tagErr (TXDAT__io_in_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_bits_task_snpHitReleaseMeta_dataErr (TXDAT__io_in_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_bits_task_tgtID (TXDAT__io_in_bits_task_tgtID),
    .io_in_bits_task_srcID (TXDAT__io_in_bits_task_srcID),
    .io_in_bits_task_txnID (TXDAT__io_in_bits_task_txnID),
    .io_in_bits_task_homeNID (TXDAT__io_in_bits_task_homeNID),
    .io_in_bits_task_dbID (TXDAT__io_in_bits_task_dbID),
    .io_in_bits_task_fwdNID (TXDAT__io_in_bits_task_fwdNID),
    .io_in_bits_task_fwdTxnID (TXDAT__io_in_bits_task_fwdTxnID),
    .io_in_bits_task_chiOpcode (TXDAT__io_in_bits_task_chiOpcode),
    .io_in_bits_task_resp (TXDAT__io_in_bits_task_resp),
    .io_in_bits_task_fwdState (TXDAT__io_in_bits_task_fwdState),
    .io_in_bits_task_pCrdType (TXDAT__io_in_bits_task_pCrdType),
    .io_in_bits_task_retToSrc (TXDAT__io_in_bits_task_retToSrc),
    .io_in_bits_task_likelyshared (TXDAT__io_in_bits_task_likelyshared),
    .io_in_bits_task_expCompAck (TXDAT__io_in_bits_task_expCompAck),
    .io_in_bits_task_allowRetry (TXDAT__io_in_bits_task_allowRetry),
    .io_in_bits_task_memAttr_allocate (TXDAT__io_in_bits_task_memAttr_allocate),
    .io_in_bits_task_memAttr_cacheable (TXDAT__io_in_bits_task_memAttr_cacheable),
    .io_in_bits_task_memAttr_device (TXDAT__io_in_bits_task_memAttr_device),
    .io_in_bits_task_memAttr_ewa (TXDAT__io_in_bits_task_memAttr_ewa),
    .io_in_bits_task_traceTag (TXDAT__io_in_bits_task_traceTag),
    .io_in_bits_data_data (TXDAT__io_in_bits_data_data),
    .io_out_ready (TXDAT__io_out_ready),
    .io_out_valid (i_TXDAT__io_out_valid),
    .io_out_bits_tgtID (i_TXDAT__io_out_bits_tgtID),
    .io_out_bits_txnID (i_TXDAT__io_out_bits_txnID),
    .io_out_bits_homeNID (i_TXDAT__io_out_bits_homeNID),
    .io_out_bits_opcode (i_TXDAT__io_out_bits_opcode),
    .io_out_bits_respErr (i_TXDAT__io_out_bits_respErr),
    .io_out_bits_resp (i_TXDAT__io_out_bits_resp),
    .io_out_bits_dataSource (i_TXDAT__io_out_bits_dataSource),
    .io_out_bits_dbID (i_TXDAT__io_out_bits_dbID),
    .io_out_bits_ccID (i_TXDAT__io_out_bits_ccID),
    .io_out_bits_dataID (i_TXDAT__io_out_bits_dataID),
    .io_out_bits_traceTag (i_TXDAT__io_out_bits_traceTag),
    .io_out_bits_be (i_TXDAT__io_out_bits_be),
    .io_out_bits_data (i_TXDAT__io_out_bits_data),
    .io_out_bits_dataCheck (i_TXDAT__io_out_bits_dataCheck),
    .io_out_bits_poison (i_TXDAT__io_out_bits_poison),
    .io_pipeStatusVec_1_valid (TXDAT__io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel (TXDAT__io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel (TXDAT__io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask (TXDAT__io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid (TXDAT__io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel (TXDAT__io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel (TXDAT__io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask (TXDAT__io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid (TXDAT__io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel (TXDAT__io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel (TXDAT__io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask (TXDAT__io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid (TXDAT__io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel (TXDAT__io_pipeStatusVec_4_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel (TXDAT__io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask (TXDAT__io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance (i_TXDAT__io_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance (i_TXDAT__io_toReqArb_blockSinkBReqEntrance)
  );
  task automatic drive_TXDAT();
    TXDAT__io_in_valid = $urandom % 2;
    TXDAT__io_in_bits_task_channel = rnd(3);
    TXDAT__io_in_bits_task_txChannel = rnd(3);
    TXDAT__io_in_bits_task_set = rnd(9);
    TXDAT__io_in_bits_task_tag = rnd(31);
    TXDAT__io_in_bits_task_off = rnd(6);
    TXDAT__io_in_bits_task_alias = rnd(2);
    TXDAT__io_in_bits_task_vaddr = rnd(44);
    TXDAT__io_in_bits_task_isKeyword = $urandom % 2;
    TXDAT__io_in_bits_task_opcode = rnd(4);
    TXDAT__io_in_bits_task_param = rnd(3);
    TXDAT__io_in_bits_task_size = rnd(3);
    TXDAT__io_in_bits_task_sourceId = rnd(7);
    TXDAT__io_in_bits_task_bufIdx = rnd(2);
    TXDAT__io_in_bits_task_needProbeAckData = $urandom % 2;
    TXDAT__io_in_bits_task_denied = $urandom % 2;
    TXDAT__io_in_bits_task_corrupt = $urandom % 2;
    TXDAT__io_in_bits_task_mshrTask = $urandom % 2;
    TXDAT__io_in_bits_task_mshrId = rnd(8);
    TXDAT__io_in_bits_task_aliasTask = $urandom % 2;
    TXDAT__io_in_bits_task_useProbeData = $urandom % 2;
    TXDAT__io_in_bits_task_mshrRetry = $urandom % 2;
    TXDAT__io_in_bits_task_readProbeDataDown = $urandom % 2;
    TXDAT__io_in_bits_task_fromL2pft = $urandom % 2;
    TXDAT__io_in_bits_task_needHint = $urandom % 2;
    TXDAT__io_in_bits_task_dirty = $urandom % 2;
    TXDAT__io_in_bits_task_way = rnd(3);
    TXDAT__io_in_bits_task_meta_dirty = $urandom % 2;
    TXDAT__io_in_bits_task_meta_state = rnd(2);
    TXDAT__io_in_bits_task_meta_clients = $urandom % 2;
    TXDAT__io_in_bits_task_meta_alias = rnd(2);
    TXDAT__io_in_bits_task_meta_prefetch = $urandom % 2;
    TXDAT__io_in_bits_task_meta_prefetchSrc = rnd(3);
    TXDAT__io_in_bits_task_meta_accessed = $urandom % 2;
    TXDAT__io_in_bits_task_meta_tagErr = $urandom % 2;
    TXDAT__io_in_bits_task_meta_dataErr = $urandom % 2;
    TXDAT__io_in_bits_task_metaWen = $urandom % 2;
    TXDAT__io_in_bits_task_tagWen = $urandom % 2;
    TXDAT__io_in_bits_task_dsWen = $urandom % 2;
    TXDAT__io_in_bits_task_wayMask = rnd(8);
    TXDAT__io_in_bits_task_replTask = $urandom % 2;
    TXDAT__io_in_bits_task_cmoTask = $urandom % 2;
    TXDAT__io_in_bits_task_cmoAll = $urandom % 2;
    TXDAT__io_in_bits_task_reqSource = rnd(5);
    TXDAT__io_in_bits_task_mergeA = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_off = rnd(6);
    TXDAT__io_in_bits_task_aMergeTask_alias = rnd(2);
    TXDAT__io_in_bits_task_aMergeTask_vaddr = rnd(44);
    TXDAT__io_in_bits_task_aMergeTask_isKeyword = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_opcode = rnd(3);
    TXDAT__io_in_bits_task_aMergeTask_param = rnd(3);
    TXDAT__io_in_bits_task_aMergeTask_sourceId = rnd(7);
    TXDAT__io_in_bits_task_aMergeTask_meta_dirty = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_meta_state = rnd(2);
    TXDAT__io_in_bits_task_aMergeTask_meta_clients = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_meta_alias = rnd(2);
    TXDAT__io_in_bits_task_aMergeTask_meta_prefetch = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_meta_prefetchSrc = rnd(3);
    TXDAT__io_in_bits_task_aMergeTask_meta_accessed = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_meta_tagErr = $urandom % 2;
    TXDAT__io_in_bits_task_aMergeTask_meta_dataErr = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitRelease = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseToInval = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseToClean = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseWithData = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseIdx = rnd(8);
    TXDAT__io_in_bits_task_snpHitReleaseMeta_dirty = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseMeta_state = rnd(2);
    TXDAT__io_in_bits_task_snpHitReleaseMeta_clients = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseMeta_alias = rnd(2);
    TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetch = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseMeta_prefetchSrc = rnd(3);
    TXDAT__io_in_bits_task_snpHitReleaseMeta_accessed = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseMeta_tagErr = $urandom % 2;
    TXDAT__io_in_bits_task_snpHitReleaseMeta_dataErr = $urandom % 2;
    TXDAT__io_in_bits_task_tgtID = rnd(11);
    TXDAT__io_in_bits_task_srcID = rnd(11);
    TXDAT__io_in_bits_task_txnID = rnd(12);
    TXDAT__io_in_bits_task_homeNID = rnd(11);
    TXDAT__io_in_bits_task_dbID = rnd(12);
    TXDAT__io_in_bits_task_fwdNID = rnd(11);
    TXDAT__io_in_bits_task_fwdTxnID = rnd(12);
    TXDAT__io_in_bits_task_chiOpcode = (($urandom % 4) == 0) ? 7'h02 : ((($urandom % 3) == 0) ? 7'h07 : 7'($urandom));
    TXDAT__io_in_bits_task_resp = (($urandom % 2) == 0) ? 3'h0 : 3'($urandom);
    TXDAT__io_in_bits_task_fwdState = rnd(3);
    TXDAT__io_in_bits_task_pCrdType = rnd(4);
    TXDAT__io_in_bits_task_retToSrc = $urandom % 2;
    TXDAT__io_in_bits_task_likelyshared = $urandom % 2;
    TXDAT__io_in_bits_task_expCompAck = $urandom % 2;
    TXDAT__io_in_bits_task_allowRetry = $urandom % 2;
    TXDAT__io_in_bits_task_memAttr_allocate = $urandom % 2;
    TXDAT__io_in_bits_task_memAttr_cacheable = $urandom % 2;
    TXDAT__io_in_bits_task_memAttr_device = $urandom % 2;
    TXDAT__io_in_bits_task_memAttr_ewa = $urandom % 2;
    TXDAT__io_in_bits_task_traceTag = $urandom % 2;
    TXDAT__io_in_bits_data_data = rnd(512);
    TXDAT__io_out_ready = ((cyc / 3000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    TXDAT__io_pipeStatusVec_1_valid = $urandom % 2;
    TXDAT__io_pipeStatusVec_1_bits_channel = rnd(3);
    TXDAT__io_pipeStatusVec_1_bits_txChannel = rnd(3);
    TXDAT__io_pipeStatusVec_1_bits_mshrTask = $urandom % 2;
    TXDAT__io_pipeStatusVec_2_valid = $urandom % 2;
    TXDAT__io_pipeStatusVec_2_bits_channel = rnd(3);
    TXDAT__io_pipeStatusVec_2_bits_txChannel = rnd(3);
    TXDAT__io_pipeStatusVec_2_bits_mshrTask = $urandom % 2;
    TXDAT__io_pipeStatusVec_3_valid = $urandom % 2;
    TXDAT__io_pipeStatusVec_3_bits_channel = rnd(3);
    TXDAT__io_pipeStatusVec_3_bits_txChannel = rnd(3);
    TXDAT__io_pipeStatusVec_3_bits_mshrTask = $urandom % 2;
    TXDAT__io_pipeStatusVec_4_valid = $urandom % 2;
    TXDAT__io_pipeStatusVec_4_bits_channel = rnd(3);
    TXDAT__io_pipeStatusVec_4_bits_txChannel = rnd(3);
    TXDAT__io_pipeStatusVec_4_bits_mshrTask = $urandom % 2;
  endtask
  task automatic check_TXDAT();
    checks++;
    if (g_TXDAT__io_in_ready !== i_TXDAT__io_in_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_in_ready g=%h i=%h", cyc, g_TXDAT__io_in_ready, i_TXDAT__io_in_ready);
    end
    if (g_TXDAT__io_in_ready !== p_TXDAT__io_in_ready) t_TXDAT__io_in_ready = 1'b1;
    p_TXDAT__io_in_ready = g_TXDAT__io_in_ready;
    checks++;
    if (g_TXDAT__io_out_valid !== i_TXDAT__io_out_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_valid g=%h i=%h", cyc, g_TXDAT__io_out_valid, i_TXDAT__io_out_valid);
    end
    if (g_TXDAT__io_out_valid !== p_TXDAT__io_out_valid) t_TXDAT__io_out_valid = 1'b1;
    p_TXDAT__io_out_valid = g_TXDAT__io_out_valid;
    checks++;
    if (g_TXDAT__io_out_bits_tgtID !== i_TXDAT__io_out_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_tgtID g=%h i=%h", cyc, g_TXDAT__io_out_bits_tgtID, i_TXDAT__io_out_bits_tgtID);
    end
    if (g_TXDAT__io_out_bits_tgtID !== p_TXDAT__io_out_bits_tgtID) t_TXDAT__io_out_bits_tgtID = 1'b1;
    p_TXDAT__io_out_bits_tgtID = g_TXDAT__io_out_bits_tgtID;
    checks++;
    if (g_TXDAT__io_out_bits_txnID !== i_TXDAT__io_out_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_txnID g=%h i=%h", cyc, g_TXDAT__io_out_bits_txnID, i_TXDAT__io_out_bits_txnID);
    end
    if (g_TXDAT__io_out_bits_txnID !== p_TXDAT__io_out_bits_txnID) t_TXDAT__io_out_bits_txnID = 1'b1;
    p_TXDAT__io_out_bits_txnID = g_TXDAT__io_out_bits_txnID;
    checks++;
    if (g_TXDAT__io_out_bits_homeNID !== i_TXDAT__io_out_bits_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_homeNID g=%h i=%h", cyc, g_TXDAT__io_out_bits_homeNID, i_TXDAT__io_out_bits_homeNID);
    end
    if (g_TXDAT__io_out_bits_homeNID !== p_TXDAT__io_out_bits_homeNID) t_TXDAT__io_out_bits_homeNID = 1'b1;
    p_TXDAT__io_out_bits_homeNID = g_TXDAT__io_out_bits_homeNID;
    checks++;
    if (g_TXDAT__io_out_bits_opcode !== i_TXDAT__io_out_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_opcode g=%h i=%h", cyc, g_TXDAT__io_out_bits_opcode, i_TXDAT__io_out_bits_opcode);
    end
    if (g_TXDAT__io_out_bits_opcode !== p_TXDAT__io_out_bits_opcode) t_TXDAT__io_out_bits_opcode = 1'b1;
    p_TXDAT__io_out_bits_opcode = g_TXDAT__io_out_bits_opcode;
    checks++;
    if (g_TXDAT__io_out_bits_respErr !== i_TXDAT__io_out_bits_respErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_respErr g=%h i=%h", cyc, g_TXDAT__io_out_bits_respErr, i_TXDAT__io_out_bits_respErr);
    end
    if (g_TXDAT__io_out_bits_respErr !== p_TXDAT__io_out_bits_respErr) t_TXDAT__io_out_bits_respErr = 1'b1;
    p_TXDAT__io_out_bits_respErr = g_TXDAT__io_out_bits_respErr;
    checks++;
    if (g_TXDAT__io_out_bits_resp !== i_TXDAT__io_out_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_resp g=%h i=%h", cyc, g_TXDAT__io_out_bits_resp, i_TXDAT__io_out_bits_resp);
    end
    if (g_TXDAT__io_out_bits_resp !== p_TXDAT__io_out_bits_resp) t_TXDAT__io_out_bits_resp = 1'b1;
    p_TXDAT__io_out_bits_resp = g_TXDAT__io_out_bits_resp;
    checks++;
    if (g_TXDAT__io_out_bits_dataSource !== i_TXDAT__io_out_bits_dataSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_dataSource g=%h i=%h", cyc, g_TXDAT__io_out_bits_dataSource, i_TXDAT__io_out_bits_dataSource);
    end
    if (g_TXDAT__io_out_bits_dataSource !== p_TXDAT__io_out_bits_dataSource) t_TXDAT__io_out_bits_dataSource = 1'b1;
    p_TXDAT__io_out_bits_dataSource = g_TXDAT__io_out_bits_dataSource;
    checks++;
    if (g_TXDAT__io_out_bits_dbID !== i_TXDAT__io_out_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_dbID g=%h i=%h", cyc, g_TXDAT__io_out_bits_dbID, i_TXDAT__io_out_bits_dbID);
    end
    if (g_TXDAT__io_out_bits_dbID !== p_TXDAT__io_out_bits_dbID) t_TXDAT__io_out_bits_dbID = 1'b1;
    p_TXDAT__io_out_bits_dbID = g_TXDAT__io_out_bits_dbID;
    checks++;
    if (g_TXDAT__io_out_bits_ccID !== i_TXDAT__io_out_bits_ccID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_ccID g=%h i=%h", cyc, g_TXDAT__io_out_bits_ccID, i_TXDAT__io_out_bits_ccID);
    end
    if (g_TXDAT__io_out_bits_ccID !== p_TXDAT__io_out_bits_ccID) t_TXDAT__io_out_bits_ccID = 1'b1;
    p_TXDAT__io_out_bits_ccID = g_TXDAT__io_out_bits_ccID;
    checks++;
    if (g_TXDAT__io_out_bits_dataID !== i_TXDAT__io_out_bits_dataID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_dataID g=%h i=%h", cyc, g_TXDAT__io_out_bits_dataID, i_TXDAT__io_out_bits_dataID);
    end
    if (g_TXDAT__io_out_bits_dataID !== p_TXDAT__io_out_bits_dataID) t_TXDAT__io_out_bits_dataID = 1'b1;
    p_TXDAT__io_out_bits_dataID = g_TXDAT__io_out_bits_dataID;
    checks++;
    if (g_TXDAT__io_out_bits_traceTag !== i_TXDAT__io_out_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_traceTag g=%h i=%h", cyc, g_TXDAT__io_out_bits_traceTag, i_TXDAT__io_out_bits_traceTag);
    end
    if (g_TXDAT__io_out_bits_traceTag !== p_TXDAT__io_out_bits_traceTag) t_TXDAT__io_out_bits_traceTag = 1'b1;
    p_TXDAT__io_out_bits_traceTag = g_TXDAT__io_out_bits_traceTag;
    checks++;
    if (g_TXDAT__io_out_bits_be !== i_TXDAT__io_out_bits_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_be g=%h i=%h", cyc, g_TXDAT__io_out_bits_be, i_TXDAT__io_out_bits_be);
    end
    if (g_TXDAT__io_out_bits_be !== p_TXDAT__io_out_bits_be) t_TXDAT__io_out_bits_be = 1'b1;
    p_TXDAT__io_out_bits_be = g_TXDAT__io_out_bits_be;
    checks++;
    if (g_TXDAT__io_out_bits_data !== i_TXDAT__io_out_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_data g=%h i=%h", cyc, g_TXDAT__io_out_bits_data, i_TXDAT__io_out_bits_data);
    end
    if (g_TXDAT__io_out_bits_data !== p_TXDAT__io_out_bits_data) t_TXDAT__io_out_bits_data = 1'b1;
    p_TXDAT__io_out_bits_data = g_TXDAT__io_out_bits_data;
    checks++;
    if (g_TXDAT__io_out_bits_dataCheck !== i_TXDAT__io_out_bits_dataCheck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_dataCheck g=%h i=%h", cyc, g_TXDAT__io_out_bits_dataCheck, i_TXDAT__io_out_bits_dataCheck);
    end
    if (g_TXDAT__io_out_bits_dataCheck !== p_TXDAT__io_out_bits_dataCheck) t_TXDAT__io_out_bits_dataCheck = 1'b1;
    p_TXDAT__io_out_bits_dataCheck = g_TXDAT__io_out_bits_dataCheck;
    checks++;
    if (g_TXDAT__io_out_bits_poison !== i_TXDAT__io_out_bits_poison) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_out_bits_poison g=%h i=%h", cyc, g_TXDAT__io_out_bits_poison, i_TXDAT__io_out_bits_poison);
    end
    if (g_TXDAT__io_out_bits_poison !== p_TXDAT__io_out_bits_poison) t_TXDAT__io_out_bits_poison = 1'b1;
    p_TXDAT__io_out_bits_poison = g_TXDAT__io_out_bits_poison;
    checks++;
    if (g_TXDAT__io_toReqArb_blockMSHRReqEntrance !== i_TXDAT__io_toReqArb_blockMSHRReqEntrance) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_toReqArb_blockMSHRReqEntrance g=%h i=%h", cyc, g_TXDAT__io_toReqArb_blockMSHRReqEntrance, i_TXDAT__io_toReqArb_blockMSHRReqEntrance);
    end
    if (g_TXDAT__io_toReqArb_blockMSHRReqEntrance !== p_TXDAT__io_toReqArb_blockMSHRReqEntrance) t_TXDAT__io_toReqArb_blockMSHRReqEntrance = 1'b1;
    p_TXDAT__io_toReqArb_blockMSHRReqEntrance = g_TXDAT__io_toReqArb_blockMSHRReqEntrance;
    checks++;
    if (g_TXDAT__io_toReqArb_blockSinkBReqEntrance !== i_TXDAT__io_toReqArb_blockSinkBReqEntrance) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH TXDAT.io_toReqArb_blockSinkBReqEntrance g=%h i=%h", cyc, g_TXDAT__io_toReqArb_blockSinkBReqEntrance, i_TXDAT__io_toReqArb_blockSinkBReqEntrance);
    end
    if (g_TXDAT__io_toReqArb_blockSinkBReqEntrance !== p_TXDAT__io_toReqArb_blockSinkBReqEntrance) t_TXDAT__io_toReqArb_blockSinkBReqEntrance = 1'b1;
    p_TXDAT__io_toReqArb_blockSinkBReqEntrance = g_TXDAT__io_toReqArb_blockSinkBReqEntrance;
  endtask
  longint cov_TXDAT_take = 0;
  longint cov_TXDAT_beat1 = 0;
  longint cov_TXDAT_deassert = 0;
  longint cov_TXDAT_blkSnp = 0;
  longint cov_TXDAT_notBlk = 0;
  longint cov_TXDAT_pipe4 = 0;
  longint cov_TXDAT_blkMshrOnly = 0;
  task automatic cover_TXDAT();
    if (u_g_TXDAT._GEN_0) cov_TXDAT_take++;
    if (u_g_TXDAT.io_out_valid && u_g_TXDAT.io_out_ready && !u_g_TXDAT.beatValids_0) cov_TXDAT_beat1++;
    if (u_g_TXDAT.io_out_valid && u_g_TXDAT.io_out_bits_deassertBE) cov_TXDAT_deassert++;
    if (u_g_TXDAT.io_toReqArb_blockSinkBReqEntrance) cov_TXDAT_blkSnp++;
    if (!u_g_TXDAT.io_toReqArb_blockMSHRReqEntrance) cov_TXDAT_notBlk++;
    if (u_g_TXDAT._inflightCnt_T_30 == u_g_TXDAT._queue_io_count && u_g_TXDAT.io_pipeStatusVec_1_valid && u_g_TXDAT.io_pipeStatusVec_2_valid && u_g_TXDAT.io_pipeStatusVec_3_valid && u_g_TXDAT.io_pipeStatusVec_4_valid && u_g_TXDAT.io_pipeStatusVec_2_bits_txChannel[2] && u_g_TXDAT.io_pipeStatusVec_3_bits_txChannel[2] && u_g_TXDAT.io_pipeStatusVec_4_bits_txChannel[2] && u_g_TXDAT.io_pipeStatusVec_2_bits_mshrTask && u_g_TXDAT.io_pipeStatusVec_3_bits_mshrTask && u_g_TXDAT.io_pipeStatusVec_4_bits_mshrTask) cov_TXDAT_pipe4++;
    if (u_g_TXDAT.io_toReqArb_blockMSHRReqEntrance && !u_g_TXDAT.io_toReqArb_blockSinkBReqEntrance) cov_TXDAT_blkMshrOnly++;
  endtask
  task automatic preinit_TXDAT();
  endtask
  task automatic sync_TXDAT();
    u_i_TXDAT.queue.ram_ext.Memory = u_g_TXDAT.queue.ram_ext.Memory;
    u_i_TXDAT.queueData0.ram_data_ext.Memory = u_g_TXDAT.queueData0.ram_data_ext.Memory;
    u_i_TXDAT.queueData1.ram_data_ext.Memory = u_g_TXDAT.queueData1.ram_data_ext.Memory;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_TXDAT();
    #1;
    preinit_TXDAT();
    sync_TXDAT();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_TXDAT();
      #1;
      check_TXDAT();
      cover_TXDAT();
    end
    begin int tg; tg = 0;
      if (t_TXDAT__io_in_ready) tg++; else $display("COV: TXDAT.io_in_ready never toggled");
      if (t_TXDAT__io_out_valid) tg++; else $display("COV: TXDAT.io_out_valid never toggled");
      if (t_TXDAT__io_out_bits_tgtID) tg++; else $display("COV: TXDAT.io_out_bits_tgtID never toggled");
      if (t_TXDAT__io_out_bits_txnID) tg++; else $display("COV: TXDAT.io_out_bits_txnID never toggled");
      if (t_TXDAT__io_out_bits_homeNID) tg++; else $display("COV: TXDAT.io_out_bits_homeNID never toggled");
      if (t_TXDAT__io_out_bits_opcode) tg++; else $display("COV: TXDAT.io_out_bits_opcode never toggled");
      if (t_TXDAT__io_out_bits_respErr) tg++; else $display("COV: TXDAT.io_out_bits_respErr never toggled");
      if (t_TXDAT__io_out_bits_resp) tg++; else $display("COV: TXDAT.io_out_bits_resp never toggled");
      if (t_TXDAT__io_out_bits_dataSource) tg++; else $display("COV: TXDAT.io_out_bits_dataSource never toggled");
      if (t_TXDAT__io_out_bits_dbID) tg++; else $display("COV: TXDAT.io_out_bits_dbID never toggled");
      if (t_TXDAT__io_out_bits_ccID) tg++; else $display("COV: TXDAT.io_out_bits_ccID never toggled");
      if (t_TXDAT__io_out_bits_dataID) tg++; else $display("COV: TXDAT.io_out_bits_dataID never toggled");
      if (t_TXDAT__io_out_bits_traceTag) tg++; else $display("COV: TXDAT.io_out_bits_traceTag never toggled");
      if (t_TXDAT__io_out_bits_be) tg++; else $display("COV: TXDAT.io_out_bits_be never toggled");
      if (t_TXDAT__io_out_bits_data) tg++; else $display("COV: TXDAT.io_out_bits_data never toggled");
      if (t_TXDAT__io_out_bits_dataCheck) tg++; else $display("COV: TXDAT.io_out_bits_dataCheck never toggled");
      if (t_TXDAT__io_out_bits_poison) tg++; else $display("COV: TXDAT.io_out_bits_poison never toggled");
      if (t_TXDAT__io_toReqArb_blockMSHRReqEntrance) tg++; else $display("COV: TXDAT.io_toReqArb_blockMSHRReqEntrance never toggled");
      if (t_TXDAT__io_toReqArb_blockSinkBReqEntrance) tg++; else $display("COV: TXDAT.io_toReqArb_blockSinkBReqEntrance never toggled");
      $display("TXDAT: toggled=%0d/19 (need >= 19)", tg);
      if (tg < 19) covfail = 1;
      $display("TXDAT: cover take = %0d", cov_TXDAT_take);
      if (cov_TXDAT_take == 0) covfail = 1;
      $display("TXDAT: cover beat1 = %0d", cov_TXDAT_beat1);
      if (cov_TXDAT_beat1 == 0) covfail = 1;
      $display("TXDAT: cover deassert = %0d", cov_TXDAT_deassert);
      if (cov_TXDAT_deassert == 0) covfail = 1;
      $display("TXDAT: cover blkSnp = %0d", cov_TXDAT_blkSnp);
      if (cov_TXDAT_blkSnp == 0) covfail = 1;
      $display("TXDAT: cover notBlk = %0d", cov_TXDAT_notBlk);
      if (cov_TXDAT_notBlk == 0) covfail = 1;
      $display("TXDAT: cover pipe4 = %0d", cov_TXDAT_pipe4);
      if (cov_TXDAT_pipe4 == 0) covfail = 1;
      $display("TXDAT: cover blkMshrOnly = %0d", cov_TXDAT_blkMshrOnly);
      if (cov_TXDAT_blkMshrOnly == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
