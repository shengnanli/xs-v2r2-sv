// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：Queue16_DSBeat Queue16_TaskBundle Queue2_CHISNP Queue16_GrantQueueTask Queue16_GrantQueueData
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

  // ======================= Queue16_DSBeat =======================
  logic Queue16_DSBeat__io_enq_valid;
  logic [255:0] Queue16_DSBeat__io_enq_bits_data;
  logic Queue16_DSBeat__io_deq_ready;
  wire  [255:0] g_Queue16_DSBeat__io_deq_bits_data;
  wire  [255:0] i_Queue16_DSBeat__io_deq_bits_data;
  logic [255:0] p_Queue16_DSBeat__io_deq_bits_data;
  bit   t_Queue16_DSBeat__io_deq_bits_data;
  Queue16_DSBeat u_g_Queue16_DSBeat (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_DSBeat__io_enq_valid),
    .io_enq_bits_data (Queue16_DSBeat__io_enq_bits_data),
    .io_deq_ready (Queue16_DSBeat__io_deq_ready),
    .io_deq_bits_data (g_Queue16_DSBeat__io_deq_bits_data)
  );
  Queue16_DSBeat_xs u_i_Queue16_DSBeat (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_DSBeat__io_enq_valid),
    .io_enq_bits_data (Queue16_DSBeat__io_enq_bits_data),
    .io_deq_ready (Queue16_DSBeat__io_deq_ready),
    .io_deq_bits_data (i_Queue16_DSBeat__io_deq_bits_data)
  );
  task automatic drive_Queue16_DSBeat();
    Queue16_DSBeat__io_enq_valid = $urandom % 2;
    Queue16_DSBeat__io_enq_bits_data = rnd(256);
    Queue16_DSBeat__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_DSBeat();
    checks++;
    if (g_Queue16_DSBeat__io_deq_bits_data !== i_Queue16_DSBeat__io_deq_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_DSBeat.io_deq_bits_data g=%h i=%h", cyc, g_Queue16_DSBeat__io_deq_bits_data, i_Queue16_DSBeat__io_deq_bits_data);
    end
    if (g_Queue16_DSBeat__io_deq_bits_data !== p_Queue16_DSBeat__io_deq_bits_data) t_Queue16_DSBeat__io_deq_bits_data = 1'b1;
    p_Queue16_DSBeat__io_deq_bits_data = g_Queue16_DSBeat__io_deq_bits_data;
  endtask
  longint cov_Queue16_DSBeat_full = 0;
  longint cov_Queue16_DSBeat_deq = 0;
  longint cov_Queue16_DSBeat_bypass = 0;
  task automatic cover_Queue16_DSBeat();
    if (u_g_Queue16_DSBeat.maybe_full && u_g_Queue16_DSBeat.ptr_match) cov_Queue16_DSBeat_full++;
    if (u_g_Queue16_DSBeat.do_deq) cov_Queue16_DSBeat_deq++;
    if (u_g_Queue16_DSBeat.empty && Queue16_DSBeat__io_enq_valid && Queue16_DSBeat__io_deq_ready) cov_Queue16_DSBeat_bypass++;
  endtask
  task automatic sync_Queue16_DSBeat();
    u_i_Queue16_DSBeat.ram_data_ext.Memory = u_g_Queue16_DSBeat.ram_data_ext.Memory;
  endtask

  // ======================= Queue16_TaskBundle =======================
  logic Queue16_TaskBundle__io_enq_valid;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_channel;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_txChannel;
  logic [8:0] Queue16_TaskBundle__io_enq_bits_set;
  logic [30:0] Queue16_TaskBundle__io_enq_bits_tag;
  logic [5:0] Queue16_TaskBundle__io_enq_bits_off;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_alias;
  logic [43:0] Queue16_TaskBundle__io_enq_bits_vaddr;
  logic Queue16_TaskBundle__io_enq_bits_isKeyword;
  logic [3:0] Queue16_TaskBundle__io_enq_bits_opcode;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_param;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_size;
  logic [6:0] Queue16_TaskBundle__io_enq_bits_sourceId;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_bufIdx;
  logic Queue16_TaskBundle__io_enq_bits_needProbeAckData;
  logic Queue16_TaskBundle__io_enq_bits_denied;
  logic Queue16_TaskBundle__io_enq_bits_corrupt;
  logic Queue16_TaskBundle__io_enq_bits_mshrTask;
  logic [7:0] Queue16_TaskBundle__io_enq_bits_mshrId;
  logic Queue16_TaskBundle__io_enq_bits_aliasTask;
  logic Queue16_TaskBundle__io_enq_bits_useProbeData;
  logic Queue16_TaskBundle__io_enq_bits_mshrRetry;
  logic Queue16_TaskBundle__io_enq_bits_readProbeDataDown;
  logic Queue16_TaskBundle__io_enq_bits_fromL2pft;
  logic Queue16_TaskBundle__io_enq_bits_needHint;
  logic Queue16_TaskBundle__io_enq_bits_dirty;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_way;
  logic Queue16_TaskBundle__io_enq_bits_meta_dirty;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_meta_state;
  logic Queue16_TaskBundle__io_enq_bits_meta_clients;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_meta_alias;
  logic Queue16_TaskBundle__io_enq_bits_meta_prefetch;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_meta_prefetchSrc;
  logic Queue16_TaskBundle__io_enq_bits_meta_accessed;
  logic Queue16_TaskBundle__io_enq_bits_meta_tagErr;
  logic Queue16_TaskBundle__io_enq_bits_meta_dataErr;
  logic Queue16_TaskBundle__io_enq_bits_metaWen;
  logic Queue16_TaskBundle__io_enq_bits_tagWen;
  logic Queue16_TaskBundle__io_enq_bits_dsWen;
  logic [7:0] Queue16_TaskBundle__io_enq_bits_wayMask;
  logic Queue16_TaskBundle__io_enq_bits_replTask;
  logic Queue16_TaskBundle__io_enq_bits_cmoTask;
  logic Queue16_TaskBundle__io_enq_bits_cmoAll;
  logic [4:0] Queue16_TaskBundle__io_enq_bits_reqSource;
  logic Queue16_TaskBundle__io_enq_bits_mergeA;
  logic [5:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_off;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_alias;
  logic [43:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_vaddr;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_isKeyword;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_opcode;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_param;
  logic [6:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_sourceId;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dirty;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_state;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_clients;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_alias;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetch;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetchSrc;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_accessed;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_tagErr;
  logic Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dataErr;
  logic Queue16_TaskBundle__io_enq_bits_snpHitRelease;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseToInval;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseToClean;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseWithData;
  logic [7:0] Queue16_TaskBundle__io_enq_bits_snpHitReleaseIdx;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dirty;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_state;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_clients;
  logic [1:0] Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_alias;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetch;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetchSrc;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_accessed;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_tagErr;
  logic Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] Queue16_TaskBundle__io_enq_bits_tgtID;
  logic [10:0] Queue16_TaskBundle__io_enq_bits_srcID;
  logic [11:0] Queue16_TaskBundle__io_enq_bits_txnID;
  logic [10:0] Queue16_TaskBundle__io_enq_bits_homeNID;
  logic [11:0] Queue16_TaskBundle__io_enq_bits_dbID;
  logic [10:0] Queue16_TaskBundle__io_enq_bits_fwdNID;
  logic [11:0] Queue16_TaskBundle__io_enq_bits_fwdTxnID;
  logic [6:0] Queue16_TaskBundle__io_enq_bits_chiOpcode;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_resp;
  logic [2:0] Queue16_TaskBundle__io_enq_bits_fwdState;
  logic [3:0] Queue16_TaskBundle__io_enq_bits_pCrdType;
  logic Queue16_TaskBundle__io_enq_bits_retToSrc;
  logic Queue16_TaskBundle__io_enq_bits_likelyshared;
  logic Queue16_TaskBundle__io_enq_bits_expCompAck;
  logic Queue16_TaskBundle__io_enq_bits_allowRetry;
  logic Queue16_TaskBundle__io_enq_bits_memAttr_allocate;
  logic Queue16_TaskBundle__io_enq_bits_memAttr_cacheable;
  logic Queue16_TaskBundle__io_enq_bits_memAttr_device;
  logic Queue16_TaskBundle__io_enq_bits_memAttr_ewa;
  logic Queue16_TaskBundle__io_enq_bits_traceTag;
  logic Queue16_TaskBundle__io_deq_ready;
  wire  g_Queue16_TaskBundle__io_enq_ready;
  wire  i_Queue16_TaskBundle__io_enq_ready;
  logic p_Queue16_TaskBundle__io_enq_ready;
  bit   t_Queue16_TaskBundle__io_enq_ready;
  wire  g_Queue16_TaskBundle__io_deq_valid;
  wire  i_Queue16_TaskBundle__io_deq_valid;
  logic p_Queue16_TaskBundle__io_deq_valid;
  bit   t_Queue16_TaskBundle__io_deq_valid;
  wire  [5:0] g_Queue16_TaskBundle__io_deq_bits_off;
  wire  [5:0] i_Queue16_TaskBundle__io_deq_bits_off;
  logic [5:0] p_Queue16_TaskBundle__io_deq_bits_off;
  bit   t_Queue16_TaskBundle__io_deq_bits_off;
  wire  g_Queue16_TaskBundle__io_deq_bits_corrupt;
  wire  i_Queue16_TaskBundle__io_deq_bits_corrupt;
  logic p_Queue16_TaskBundle__io_deq_bits_corrupt;
  bit   t_Queue16_TaskBundle__io_deq_bits_corrupt;
  wire  [10:0] g_Queue16_TaskBundle__io_deq_bits_tgtID;
  wire  [10:0] i_Queue16_TaskBundle__io_deq_bits_tgtID;
  logic [10:0] p_Queue16_TaskBundle__io_deq_bits_tgtID;
  bit   t_Queue16_TaskBundle__io_deq_bits_tgtID;
  wire  [11:0] g_Queue16_TaskBundle__io_deq_bits_txnID;
  wire  [11:0] i_Queue16_TaskBundle__io_deq_bits_txnID;
  logic [11:0] p_Queue16_TaskBundle__io_deq_bits_txnID;
  bit   t_Queue16_TaskBundle__io_deq_bits_txnID;
  wire  [10:0] g_Queue16_TaskBundle__io_deq_bits_homeNID;
  wire  [10:0] i_Queue16_TaskBundle__io_deq_bits_homeNID;
  logic [10:0] p_Queue16_TaskBundle__io_deq_bits_homeNID;
  bit   t_Queue16_TaskBundle__io_deq_bits_homeNID;
  wire  [11:0] g_Queue16_TaskBundle__io_deq_bits_dbID;
  wire  [11:0] i_Queue16_TaskBundle__io_deq_bits_dbID;
  logic [11:0] p_Queue16_TaskBundle__io_deq_bits_dbID;
  bit   t_Queue16_TaskBundle__io_deq_bits_dbID;
  wire  [6:0] g_Queue16_TaskBundle__io_deq_bits_chiOpcode;
  wire  [6:0] i_Queue16_TaskBundle__io_deq_bits_chiOpcode;
  logic [6:0] p_Queue16_TaskBundle__io_deq_bits_chiOpcode;
  bit   t_Queue16_TaskBundle__io_deq_bits_chiOpcode;
  wire  [2:0] g_Queue16_TaskBundle__io_deq_bits_resp;
  wire  [2:0] i_Queue16_TaskBundle__io_deq_bits_resp;
  logic [2:0] p_Queue16_TaskBundle__io_deq_bits_resp;
  bit   t_Queue16_TaskBundle__io_deq_bits_resp;
  wire  [2:0] g_Queue16_TaskBundle__io_deq_bits_fwdState;
  wire  [2:0] i_Queue16_TaskBundle__io_deq_bits_fwdState;
  logic [2:0] p_Queue16_TaskBundle__io_deq_bits_fwdState;
  bit   t_Queue16_TaskBundle__io_deq_bits_fwdState;
  wire  g_Queue16_TaskBundle__io_deq_bits_traceTag;
  wire  i_Queue16_TaskBundle__io_deq_bits_traceTag;
  logic p_Queue16_TaskBundle__io_deq_bits_traceTag;
  bit   t_Queue16_TaskBundle__io_deq_bits_traceTag;
  wire  [4:0] g_Queue16_TaskBundle__io_count;
  wire  [4:0] i_Queue16_TaskBundle__io_count;
  logic [4:0] p_Queue16_TaskBundle__io_count;
  bit   t_Queue16_TaskBundle__io_count;
  Queue16_TaskBundle u_g_Queue16_TaskBundle (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue16_TaskBundle__io_enq_ready),
    .io_enq_valid (Queue16_TaskBundle__io_enq_valid),
    .io_enq_bits_channel (Queue16_TaskBundle__io_enq_bits_channel),
    .io_enq_bits_txChannel (Queue16_TaskBundle__io_enq_bits_txChannel),
    .io_enq_bits_set (Queue16_TaskBundle__io_enq_bits_set),
    .io_enq_bits_tag (Queue16_TaskBundle__io_enq_bits_tag),
    .io_enq_bits_off (Queue16_TaskBundle__io_enq_bits_off),
    .io_enq_bits_alias (Queue16_TaskBundle__io_enq_bits_alias),
    .io_enq_bits_vaddr (Queue16_TaskBundle__io_enq_bits_vaddr),
    .io_enq_bits_isKeyword (Queue16_TaskBundle__io_enq_bits_isKeyword),
    .io_enq_bits_opcode (Queue16_TaskBundle__io_enq_bits_opcode),
    .io_enq_bits_param (Queue16_TaskBundle__io_enq_bits_param),
    .io_enq_bits_size (Queue16_TaskBundle__io_enq_bits_size),
    .io_enq_bits_sourceId (Queue16_TaskBundle__io_enq_bits_sourceId),
    .io_enq_bits_bufIdx (Queue16_TaskBundle__io_enq_bits_bufIdx),
    .io_enq_bits_needProbeAckData (Queue16_TaskBundle__io_enq_bits_needProbeAckData),
    .io_enq_bits_denied (Queue16_TaskBundle__io_enq_bits_denied),
    .io_enq_bits_corrupt (Queue16_TaskBundle__io_enq_bits_corrupt),
    .io_enq_bits_mshrTask (Queue16_TaskBundle__io_enq_bits_mshrTask),
    .io_enq_bits_mshrId (Queue16_TaskBundle__io_enq_bits_mshrId),
    .io_enq_bits_aliasTask (Queue16_TaskBundle__io_enq_bits_aliasTask),
    .io_enq_bits_useProbeData (Queue16_TaskBundle__io_enq_bits_useProbeData),
    .io_enq_bits_mshrRetry (Queue16_TaskBundle__io_enq_bits_mshrRetry),
    .io_enq_bits_readProbeDataDown (Queue16_TaskBundle__io_enq_bits_readProbeDataDown),
    .io_enq_bits_fromL2pft (Queue16_TaskBundle__io_enq_bits_fromL2pft),
    .io_enq_bits_needHint (Queue16_TaskBundle__io_enq_bits_needHint),
    .io_enq_bits_dirty (Queue16_TaskBundle__io_enq_bits_dirty),
    .io_enq_bits_way (Queue16_TaskBundle__io_enq_bits_way),
    .io_enq_bits_meta_dirty (Queue16_TaskBundle__io_enq_bits_meta_dirty),
    .io_enq_bits_meta_state (Queue16_TaskBundle__io_enq_bits_meta_state),
    .io_enq_bits_meta_clients (Queue16_TaskBundle__io_enq_bits_meta_clients),
    .io_enq_bits_meta_alias (Queue16_TaskBundle__io_enq_bits_meta_alias),
    .io_enq_bits_meta_prefetch (Queue16_TaskBundle__io_enq_bits_meta_prefetch),
    .io_enq_bits_meta_prefetchSrc (Queue16_TaskBundle__io_enq_bits_meta_prefetchSrc),
    .io_enq_bits_meta_accessed (Queue16_TaskBundle__io_enq_bits_meta_accessed),
    .io_enq_bits_meta_tagErr (Queue16_TaskBundle__io_enq_bits_meta_tagErr),
    .io_enq_bits_meta_dataErr (Queue16_TaskBundle__io_enq_bits_meta_dataErr),
    .io_enq_bits_metaWen (Queue16_TaskBundle__io_enq_bits_metaWen),
    .io_enq_bits_tagWen (Queue16_TaskBundle__io_enq_bits_tagWen),
    .io_enq_bits_dsWen (Queue16_TaskBundle__io_enq_bits_dsWen),
    .io_enq_bits_wayMask (Queue16_TaskBundle__io_enq_bits_wayMask),
    .io_enq_bits_replTask (Queue16_TaskBundle__io_enq_bits_replTask),
    .io_enq_bits_cmoTask (Queue16_TaskBundle__io_enq_bits_cmoTask),
    .io_enq_bits_cmoAll (Queue16_TaskBundle__io_enq_bits_cmoAll),
    .io_enq_bits_reqSource (Queue16_TaskBundle__io_enq_bits_reqSource),
    .io_enq_bits_mergeA (Queue16_TaskBundle__io_enq_bits_mergeA),
    .io_enq_bits_aMergeTask_off (Queue16_TaskBundle__io_enq_bits_aMergeTask_off),
    .io_enq_bits_aMergeTask_alias (Queue16_TaskBundle__io_enq_bits_aMergeTask_alias),
    .io_enq_bits_aMergeTask_vaddr (Queue16_TaskBundle__io_enq_bits_aMergeTask_vaddr),
    .io_enq_bits_aMergeTask_isKeyword (Queue16_TaskBundle__io_enq_bits_aMergeTask_isKeyword),
    .io_enq_bits_aMergeTask_opcode (Queue16_TaskBundle__io_enq_bits_aMergeTask_opcode),
    .io_enq_bits_aMergeTask_param (Queue16_TaskBundle__io_enq_bits_aMergeTask_param),
    .io_enq_bits_aMergeTask_sourceId (Queue16_TaskBundle__io_enq_bits_aMergeTask_sourceId),
    .io_enq_bits_aMergeTask_meta_dirty (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dirty),
    .io_enq_bits_aMergeTask_meta_state (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_state),
    .io_enq_bits_aMergeTask_meta_clients (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_clients),
    .io_enq_bits_aMergeTask_meta_alias (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_alias),
    .io_enq_bits_aMergeTask_meta_prefetch (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetch),
    .io_enq_bits_aMergeTask_meta_prefetchSrc (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetchSrc),
    .io_enq_bits_aMergeTask_meta_accessed (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_accessed),
    .io_enq_bits_aMergeTask_meta_tagErr (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_tagErr),
    .io_enq_bits_aMergeTask_meta_dataErr (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dataErr),
    .io_enq_bits_snpHitRelease (Queue16_TaskBundle__io_enq_bits_snpHitRelease),
    .io_enq_bits_snpHitReleaseToInval (Queue16_TaskBundle__io_enq_bits_snpHitReleaseToInval),
    .io_enq_bits_snpHitReleaseToClean (Queue16_TaskBundle__io_enq_bits_snpHitReleaseToClean),
    .io_enq_bits_snpHitReleaseWithData (Queue16_TaskBundle__io_enq_bits_snpHitReleaseWithData),
    .io_enq_bits_snpHitReleaseIdx (Queue16_TaskBundle__io_enq_bits_snpHitReleaseIdx),
    .io_enq_bits_snpHitReleaseMeta_dirty (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dirty),
    .io_enq_bits_snpHitReleaseMeta_state (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_state),
    .io_enq_bits_snpHitReleaseMeta_clients (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_clients),
    .io_enq_bits_snpHitReleaseMeta_alias (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_alias),
    .io_enq_bits_snpHitReleaseMeta_prefetch (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetch),
    .io_enq_bits_snpHitReleaseMeta_prefetchSrc (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_snpHitReleaseMeta_accessed (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_accessed),
    .io_enq_bits_snpHitReleaseMeta_tagErr (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_tagErr),
    .io_enq_bits_snpHitReleaseMeta_dataErr (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dataErr),
    .io_enq_bits_tgtID (Queue16_TaskBundle__io_enq_bits_tgtID),
    .io_enq_bits_srcID (Queue16_TaskBundle__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue16_TaskBundle__io_enq_bits_txnID),
    .io_enq_bits_homeNID (Queue16_TaskBundle__io_enq_bits_homeNID),
    .io_enq_bits_dbID (Queue16_TaskBundle__io_enq_bits_dbID),
    .io_enq_bits_fwdNID (Queue16_TaskBundle__io_enq_bits_fwdNID),
    .io_enq_bits_fwdTxnID (Queue16_TaskBundle__io_enq_bits_fwdTxnID),
    .io_enq_bits_chiOpcode (Queue16_TaskBundle__io_enq_bits_chiOpcode),
    .io_enq_bits_resp (Queue16_TaskBundle__io_enq_bits_resp),
    .io_enq_bits_fwdState (Queue16_TaskBundle__io_enq_bits_fwdState),
    .io_enq_bits_pCrdType (Queue16_TaskBundle__io_enq_bits_pCrdType),
    .io_enq_bits_retToSrc (Queue16_TaskBundle__io_enq_bits_retToSrc),
    .io_enq_bits_likelyshared (Queue16_TaskBundle__io_enq_bits_likelyshared),
    .io_enq_bits_expCompAck (Queue16_TaskBundle__io_enq_bits_expCompAck),
    .io_enq_bits_allowRetry (Queue16_TaskBundle__io_enq_bits_allowRetry),
    .io_enq_bits_memAttr_allocate (Queue16_TaskBundle__io_enq_bits_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable (Queue16_TaskBundle__io_enq_bits_memAttr_cacheable),
    .io_enq_bits_memAttr_device (Queue16_TaskBundle__io_enq_bits_memAttr_device),
    .io_enq_bits_memAttr_ewa (Queue16_TaskBundle__io_enq_bits_memAttr_ewa),
    .io_enq_bits_traceTag (Queue16_TaskBundle__io_enq_bits_traceTag),
    .io_deq_ready (Queue16_TaskBundle__io_deq_ready),
    .io_deq_valid (g_Queue16_TaskBundle__io_deq_valid),
    .io_deq_bits_off (g_Queue16_TaskBundle__io_deq_bits_off),
    .io_deq_bits_corrupt (g_Queue16_TaskBundle__io_deq_bits_corrupt),
    .io_deq_bits_tgtID (g_Queue16_TaskBundle__io_deq_bits_tgtID),
    .io_deq_bits_txnID (g_Queue16_TaskBundle__io_deq_bits_txnID),
    .io_deq_bits_homeNID (g_Queue16_TaskBundle__io_deq_bits_homeNID),
    .io_deq_bits_dbID (g_Queue16_TaskBundle__io_deq_bits_dbID),
    .io_deq_bits_chiOpcode (g_Queue16_TaskBundle__io_deq_bits_chiOpcode),
    .io_deq_bits_resp (g_Queue16_TaskBundle__io_deq_bits_resp),
    .io_deq_bits_fwdState (g_Queue16_TaskBundle__io_deq_bits_fwdState),
    .io_deq_bits_traceTag (g_Queue16_TaskBundle__io_deq_bits_traceTag),
    .io_count (g_Queue16_TaskBundle__io_count)
  );
  Queue16_TaskBundle_xs u_i_Queue16_TaskBundle (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue16_TaskBundle__io_enq_ready),
    .io_enq_valid (Queue16_TaskBundle__io_enq_valid),
    .io_enq_bits_channel (Queue16_TaskBundle__io_enq_bits_channel),
    .io_enq_bits_txChannel (Queue16_TaskBundle__io_enq_bits_txChannel),
    .io_enq_bits_set (Queue16_TaskBundle__io_enq_bits_set),
    .io_enq_bits_tag (Queue16_TaskBundle__io_enq_bits_tag),
    .io_enq_bits_off (Queue16_TaskBundle__io_enq_bits_off),
    .io_enq_bits_alias (Queue16_TaskBundle__io_enq_bits_alias),
    .io_enq_bits_vaddr (Queue16_TaskBundle__io_enq_bits_vaddr),
    .io_enq_bits_isKeyword (Queue16_TaskBundle__io_enq_bits_isKeyword),
    .io_enq_bits_opcode (Queue16_TaskBundle__io_enq_bits_opcode),
    .io_enq_bits_param (Queue16_TaskBundle__io_enq_bits_param),
    .io_enq_bits_size (Queue16_TaskBundle__io_enq_bits_size),
    .io_enq_bits_sourceId (Queue16_TaskBundle__io_enq_bits_sourceId),
    .io_enq_bits_bufIdx (Queue16_TaskBundle__io_enq_bits_bufIdx),
    .io_enq_bits_needProbeAckData (Queue16_TaskBundle__io_enq_bits_needProbeAckData),
    .io_enq_bits_denied (Queue16_TaskBundle__io_enq_bits_denied),
    .io_enq_bits_corrupt (Queue16_TaskBundle__io_enq_bits_corrupt),
    .io_enq_bits_mshrTask (Queue16_TaskBundle__io_enq_bits_mshrTask),
    .io_enq_bits_mshrId (Queue16_TaskBundle__io_enq_bits_mshrId),
    .io_enq_bits_aliasTask (Queue16_TaskBundle__io_enq_bits_aliasTask),
    .io_enq_bits_useProbeData (Queue16_TaskBundle__io_enq_bits_useProbeData),
    .io_enq_bits_mshrRetry (Queue16_TaskBundle__io_enq_bits_mshrRetry),
    .io_enq_bits_readProbeDataDown (Queue16_TaskBundle__io_enq_bits_readProbeDataDown),
    .io_enq_bits_fromL2pft (Queue16_TaskBundle__io_enq_bits_fromL2pft),
    .io_enq_bits_needHint (Queue16_TaskBundle__io_enq_bits_needHint),
    .io_enq_bits_dirty (Queue16_TaskBundle__io_enq_bits_dirty),
    .io_enq_bits_way (Queue16_TaskBundle__io_enq_bits_way),
    .io_enq_bits_meta_dirty (Queue16_TaskBundle__io_enq_bits_meta_dirty),
    .io_enq_bits_meta_state (Queue16_TaskBundle__io_enq_bits_meta_state),
    .io_enq_bits_meta_clients (Queue16_TaskBundle__io_enq_bits_meta_clients),
    .io_enq_bits_meta_alias (Queue16_TaskBundle__io_enq_bits_meta_alias),
    .io_enq_bits_meta_prefetch (Queue16_TaskBundle__io_enq_bits_meta_prefetch),
    .io_enq_bits_meta_prefetchSrc (Queue16_TaskBundle__io_enq_bits_meta_prefetchSrc),
    .io_enq_bits_meta_accessed (Queue16_TaskBundle__io_enq_bits_meta_accessed),
    .io_enq_bits_meta_tagErr (Queue16_TaskBundle__io_enq_bits_meta_tagErr),
    .io_enq_bits_meta_dataErr (Queue16_TaskBundle__io_enq_bits_meta_dataErr),
    .io_enq_bits_metaWen (Queue16_TaskBundle__io_enq_bits_metaWen),
    .io_enq_bits_tagWen (Queue16_TaskBundle__io_enq_bits_tagWen),
    .io_enq_bits_dsWen (Queue16_TaskBundle__io_enq_bits_dsWen),
    .io_enq_bits_wayMask (Queue16_TaskBundle__io_enq_bits_wayMask),
    .io_enq_bits_replTask (Queue16_TaskBundle__io_enq_bits_replTask),
    .io_enq_bits_cmoTask (Queue16_TaskBundle__io_enq_bits_cmoTask),
    .io_enq_bits_cmoAll (Queue16_TaskBundle__io_enq_bits_cmoAll),
    .io_enq_bits_reqSource (Queue16_TaskBundle__io_enq_bits_reqSource),
    .io_enq_bits_mergeA (Queue16_TaskBundle__io_enq_bits_mergeA),
    .io_enq_bits_aMergeTask_off (Queue16_TaskBundle__io_enq_bits_aMergeTask_off),
    .io_enq_bits_aMergeTask_alias (Queue16_TaskBundle__io_enq_bits_aMergeTask_alias),
    .io_enq_bits_aMergeTask_vaddr (Queue16_TaskBundle__io_enq_bits_aMergeTask_vaddr),
    .io_enq_bits_aMergeTask_isKeyword (Queue16_TaskBundle__io_enq_bits_aMergeTask_isKeyword),
    .io_enq_bits_aMergeTask_opcode (Queue16_TaskBundle__io_enq_bits_aMergeTask_opcode),
    .io_enq_bits_aMergeTask_param (Queue16_TaskBundle__io_enq_bits_aMergeTask_param),
    .io_enq_bits_aMergeTask_sourceId (Queue16_TaskBundle__io_enq_bits_aMergeTask_sourceId),
    .io_enq_bits_aMergeTask_meta_dirty (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dirty),
    .io_enq_bits_aMergeTask_meta_state (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_state),
    .io_enq_bits_aMergeTask_meta_clients (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_clients),
    .io_enq_bits_aMergeTask_meta_alias (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_alias),
    .io_enq_bits_aMergeTask_meta_prefetch (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetch),
    .io_enq_bits_aMergeTask_meta_prefetchSrc (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetchSrc),
    .io_enq_bits_aMergeTask_meta_accessed (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_accessed),
    .io_enq_bits_aMergeTask_meta_tagErr (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_tagErr),
    .io_enq_bits_aMergeTask_meta_dataErr (Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dataErr),
    .io_enq_bits_snpHitRelease (Queue16_TaskBundle__io_enq_bits_snpHitRelease),
    .io_enq_bits_snpHitReleaseToInval (Queue16_TaskBundle__io_enq_bits_snpHitReleaseToInval),
    .io_enq_bits_snpHitReleaseToClean (Queue16_TaskBundle__io_enq_bits_snpHitReleaseToClean),
    .io_enq_bits_snpHitReleaseWithData (Queue16_TaskBundle__io_enq_bits_snpHitReleaseWithData),
    .io_enq_bits_snpHitReleaseIdx (Queue16_TaskBundle__io_enq_bits_snpHitReleaseIdx),
    .io_enq_bits_snpHitReleaseMeta_dirty (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dirty),
    .io_enq_bits_snpHitReleaseMeta_state (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_state),
    .io_enq_bits_snpHitReleaseMeta_clients (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_clients),
    .io_enq_bits_snpHitReleaseMeta_alias (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_alias),
    .io_enq_bits_snpHitReleaseMeta_prefetch (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetch),
    .io_enq_bits_snpHitReleaseMeta_prefetchSrc (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_snpHitReleaseMeta_accessed (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_accessed),
    .io_enq_bits_snpHitReleaseMeta_tagErr (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_tagErr),
    .io_enq_bits_snpHitReleaseMeta_dataErr (Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dataErr),
    .io_enq_bits_tgtID (Queue16_TaskBundle__io_enq_bits_tgtID),
    .io_enq_bits_srcID (Queue16_TaskBundle__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue16_TaskBundle__io_enq_bits_txnID),
    .io_enq_bits_homeNID (Queue16_TaskBundle__io_enq_bits_homeNID),
    .io_enq_bits_dbID (Queue16_TaskBundle__io_enq_bits_dbID),
    .io_enq_bits_fwdNID (Queue16_TaskBundle__io_enq_bits_fwdNID),
    .io_enq_bits_fwdTxnID (Queue16_TaskBundle__io_enq_bits_fwdTxnID),
    .io_enq_bits_chiOpcode (Queue16_TaskBundle__io_enq_bits_chiOpcode),
    .io_enq_bits_resp (Queue16_TaskBundle__io_enq_bits_resp),
    .io_enq_bits_fwdState (Queue16_TaskBundle__io_enq_bits_fwdState),
    .io_enq_bits_pCrdType (Queue16_TaskBundle__io_enq_bits_pCrdType),
    .io_enq_bits_retToSrc (Queue16_TaskBundle__io_enq_bits_retToSrc),
    .io_enq_bits_likelyshared (Queue16_TaskBundle__io_enq_bits_likelyshared),
    .io_enq_bits_expCompAck (Queue16_TaskBundle__io_enq_bits_expCompAck),
    .io_enq_bits_allowRetry (Queue16_TaskBundle__io_enq_bits_allowRetry),
    .io_enq_bits_memAttr_allocate (Queue16_TaskBundle__io_enq_bits_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable (Queue16_TaskBundle__io_enq_bits_memAttr_cacheable),
    .io_enq_bits_memAttr_device (Queue16_TaskBundle__io_enq_bits_memAttr_device),
    .io_enq_bits_memAttr_ewa (Queue16_TaskBundle__io_enq_bits_memAttr_ewa),
    .io_enq_bits_traceTag (Queue16_TaskBundle__io_enq_bits_traceTag),
    .io_deq_ready (Queue16_TaskBundle__io_deq_ready),
    .io_deq_valid (i_Queue16_TaskBundle__io_deq_valid),
    .io_deq_bits_off (i_Queue16_TaskBundle__io_deq_bits_off),
    .io_deq_bits_corrupt (i_Queue16_TaskBundle__io_deq_bits_corrupt),
    .io_deq_bits_tgtID (i_Queue16_TaskBundle__io_deq_bits_tgtID),
    .io_deq_bits_txnID (i_Queue16_TaskBundle__io_deq_bits_txnID),
    .io_deq_bits_homeNID (i_Queue16_TaskBundle__io_deq_bits_homeNID),
    .io_deq_bits_dbID (i_Queue16_TaskBundle__io_deq_bits_dbID),
    .io_deq_bits_chiOpcode (i_Queue16_TaskBundle__io_deq_bits_chiOpcode),
    .io_deq_bits_resp (i_Queue16_TaskBundle__io_deq_bits_resp),
    .io_deq_bits_fwdState (i_Queue16_TaskBundle__io_deq_bits_fwdState),
    .io_deq_bits_traceTag (i_Queue16_TaskBundle__io_deq_bits_traceTag),
    .io_count (i_Queue16_TaskBundle__io_count)
  );
  task automatic drive_Queue16_TaskBundle();
    Queue16_TaskBundle__io_enq_valid = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_channel = rnd(3);
    Queue16_TaskBundle__io_enq_bits_txChannel = rnd(3);
    Queue16_TaskBundle__io_enq_bits_set = rnd(9);
    Queue16_TaskBundle__io_enq_bits_tag = rnd(31);
    Queue16_TaskBundle__io_enq_bits_off = rnd(6);
    Queue16_TaskBundle__io_enq_bits_alias = rnd(2);
    Queue16_TaskBundle__io_enq_bits_vaddr = rnd(44);
    Queue16_TaskBundle__io_enq_bits_isKeyword = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_opcode = rnd(4);
    Queue16_TaskBundle__io_enq_bits_param = rnd(3);
    Queue16_TaskBundle__io_enq_bits_size = rnd(3);
    Queue16_TaskBundle__io_enq_bits_sourceId = rnd(7);
    Queue16_TaskBundle__io_enq_bits_bufIdx = rnd(2);
    Queue16_TaskBundle__io_enq_bits_needProbeAckData = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_denied = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_corrupt = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_mshrTask = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_mshrId = rnd(8);
    Queue16_TaskBundle__io_enq_bits_aliasTask = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_useProbeData = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_mshrRetry = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_readProbeDataDown = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_fromL2pft = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_needHint = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_dirty = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_way = rnd(3);
    Queue16_TaskBundle__io_enq_bits_meta_dirty = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_meta_state = rnd(2);
    Queue16_TaskBundle__io_enq_bits_meta_clients = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_meta_alias = rnd(2);
    Queue16_TaskBundle__io_enq_bits_meta_prefetch = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_meta_prefetchSrc = rnd(3);
    Queue16_TaskBundle__io_enq_bits_meta_accessed = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_meta_tagErr = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_meta_dataErr = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_metaWen = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_tagWen = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_dsWen = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_wayMask = rnd(8);
    Queue16_TaskBundle__io_enq_bits_replTask = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_cmoTask = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_cmoAll = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_reqSource = rnd(5);
    Queue16_TaskBundle__io_enq_bits_mergeA = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_off = rnd(6);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_alias = rnd(2);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_vaddr = rnd(44);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_isKeyword = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_opcode = rnd(3);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_param = rnd(3);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_sourceId = rnd(7);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dirty = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_state = rnd(2);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_clients = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_alias = rnd(2);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetch = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_prefetchSrc = rnd(3);
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_accessed = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_tagErr = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_aMergeTask_meta_dataErr = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitRelease = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseToInval = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseToClean = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseWithData = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseIdx = rnd(8);
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dirty = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_state = rnd(2);
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_clients = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_alias = rnd(2);
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetch = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_prefetchSrc = rnd(3);
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_accessed = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_tagErr = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_snpHitReleaseMeta_dataErr = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_tgtID = rnd(11);
    Queue16_TaskBundle__io_enq_bits_srcID = rnd(11);
    Queue16_TaskBundle__io_enq_bits_txnID = rnd(12);
    Queue16_TaskBundle__io_enq_bits_homeNID = rnd(11);
    Queue16_TaskBundle__io_enq_bits_dbID = rnd(12);
    Queue16_TaskBundle__io_enq_bits_fwdNID = rnd(11);
    Queue16_TaskBundle__io_enq_bits_fwdTxnID = rnd(12);
    Queue16_TaskBundle__io_enq_bits_chiOpcode = rnd(7);
    Queue16_TaskBundle__io_enq_bits_resp = rnd(3);
    Queue16_TaskBundle__io_enq_bits_fwdState = rnd(3);
    Queue16_TaskBundle__io_enq_bits_pCrdType = rnd(4);
    Queue16_TaskBundle__io_enq_bits_retToSrc = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_likelyshared = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_expCompAck = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_allowRetry = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_memAttr_allocate = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_memAttr_cacheable = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_memAttr_device = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_memAttr_ewa = $urandom % 2;
    Queue16_TaskBundle__io_enq_bits_traceTag = $urandom % 2;
    Queue16_TaskBundle__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_TaskBundle();
    checks++;
    if (g_Queue16_TaskBundle__io_enq_ready !== i_Queue16_TaskBundle__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_enq_ready g=%h i=%h", cyc, g_Queue16_TaskBundle__io_enq_ready, i_Queue16_TaskBundle__io_enq_ready);
    end
    if (g_Queue16_TaskBundle__io_enq_ready !== p_Queue16_TaskBundle__io_enq_ready) t_Queue16_TaskBundle__io_enq_ready = 1'b1;
    p_Queue16_TaskBundle__io_enq_ready = g_Queue16_TaskBundle__io_enq_ready;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_valid !== i_Queue16_TaskBundle__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_valid g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_valid, i_Queue16_TaskBundle__io_deq_valid);
    end
    if (g_Queue16_TaskBundle__io_deq_valid !== p_Queue16_TaskBundle__io_deq_valid) t_Queue16_TaskBundle__io_deq_valid = 1'b1;
    p_Queue16_TaskBundle__io_deq_valid = g_Queue16_TaskBundle__io_deq_valid;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_off !== i_Queue16_TaskBundle__io_deq_bits_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_off g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_off, i_Queue16_TaskBundle__io_deq_bits_off);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_off !== p_Queue16_TaskBundle__io_deq_bits_off) t_Queue16_TaskBundle__io_deq_bits_off = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_off = g_Queue16_TaskBundle__io_deq_bits_off;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_corrupt !== i_Queue16_TaskBundle__io_deq_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_corrupt g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_corrupt, i_Queue16_TaskBundle__io_deq_bits_corrupt);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_corrupt !== p_Queue16_TaskBundle__io_deq_bits_corrupt) t_Queue16_TaskBundle__io_deq_bits_corrupt = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_corrupt = g_Queue16_TaskBundle__io_deq_bits_corrupt;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_tgtID !== i_Queue16_TaskBundle__io_deq_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_tgtID g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_tgtID, i_Queue16_TaskBundle__io_deq_bits_tgtID);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_tgtID !== p_Queue16_TaskBundle__io_deq_bits_tgtID) t_Queue16_TaskBundle__io_deq_bits_tgtID = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_tgtID = g_Queue16_TaskBundle__io_deq_bits_tgtID;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_txnID !== i_Queue16_TaskBundle__io_deq_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_txnID g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_txnID, i_Queue16_TaskBundle__io_deq_bits_txnID);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_txnID !== p_Queue16_TaskBundle__io_deq_bits_txnID) t_Queue16_TaskBundle__io_deq_bits_txnID = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_txnID = g_Queue16_TaskBundle__io_deq_bits_txnID;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_homeNID !== i_Queue16_TaskBundle__io_deq_bits_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_homeNID g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_homeNID, i_Queue16_TaskBundle__io_deq_bits_homeNID);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_homeNID !== p_Queue16_TaskBundle__io_deq_bits_homeNID) t_Queue16_TaskBundle__io_deq_bits_homeNID = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_homeNID = g_Queue16_TaskBundle__io_deq_bits_homeNID;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_dbID !== i_Queue16_TaskBundle__io_deq_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_dbID g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_dbID, i_Queue16_TaskBundle__io_deq_bits_dbID);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_dbID !== p_Queue16_TaskBundle__io_deq_bits_dbID) t_Queue16_TaskBundle__io_deq_bits_dbID = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_dbID = g_Queue16_TaskBundle__io_deq_bits_dbID;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_chiOpcode !== i_Queue16_TaskBundle__io_deq_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_chiOpcode g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_chiOpcode, i_Queue16_TaskBundle__io_deq_bits_chiOpcode);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_chiOpcode !== p_Queue16_TaskBundle__io_deq_bits_chiOpcode) t_Queue16_TaskBundle__io_deq_bits_chiOpcode = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_chiOpcode = g_Queue16_TaskBundle__io_deq_bits_chiOpcode;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_resp !== i_Queue16_TaskBundle__io_deq_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_resp g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_resp, i_Queue16_TaskBundle__io_deq_bits_resp);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_resp !== p_Queue16_TaskBundle__io_deq_bits_resp) t_Queue16_TaskBundle__io_deq_bits_resp = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_resp = g_Queue16_TaskBundle__io_deq_bits_resp;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_fwdState !== i_Queue16_TaskBundle__io_deq_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_fwdState g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_fwdState, i_Queue16_TaskBundle__io_deq_bits_fwdState);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_fwdState !== p_Queue16_TaskBundle__io_deq_bits_fwdState) t_Queue16_TaskBundle__io_deq_bits_fwdState = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_fwdState = g_Queue16_TaskBundle__io_deq_bits_fwdState;
    checks++;
    if (g_Queue16_TaskBundle__io_deq_bits_traceTag !== i_Queue16_TaskBundle__io_deq_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_deq_bits_traceTag g=%h i=%h", cyc, g_Queue16_TaskBundle__io_deq_bits_traceTag, i_Queue16_TaskBundle__io_deq_bits_traceTag);
    end
    if (g_Queue16_TaskBundle__io_deq_bits_traceTag !== p_Queue16_TaskBundle__io_deq_bits_traceTag) t_Queue16_TaskBundle__io_deq_bits_traceTag = 1'b1;
    p_Queue16_TaskBundle__io_deq_bits_traceTag = g_Queue16_TaskBundle__io_deq_bits_traceTag;
    checks++;
    if (g_Queue16_TaskBundle__io_count !== i_Queue16_TaskBundle__io_count) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_TaskBundle.io_count g=%h i=%h", cyc, g_Queue16_TaskBundle__io_count, i_Queue16_TaskBundle__io_count);
    end
    if (g_Queue16_TaskBundle__io_count !== p_Queue16_TaskBundle__io_count) t_Queue16_TaskBundle__io_count = 1'b1;
    p_Queue16_TaskBundle__io_count = g_Queue16_TaskBundle__io_count;
  endtask
  longint cov_Queue16_TaskBundle_full = 0;
  longint cov_Queue16_TaskBundle_deq = 0;
  longint cov_Queue16_TaskBundle_bypass = 0;
  task automatic cover_Queue16_TaskBundle();
    if (u_g_Queue16_TaskBundle.maybe_full && u_g_Queue16_TaskBundle.ptr_match) cov_Queue16_TaskBundle_full++;
    if (u_g_Queue16_TaskBundle.do_deq) cov_Queue16_TaskBundle_deq++;
    if (u_g_Queue16_TaskBundle.empty && Queue16_TaskBundle__io_enq_valid && Queue16_TaskBundle__io_deq_ready) cov_Queue16_TaskBundle_bypass++;
  endtask
  task automatic sync_Queue16_TaskBundle();
    u_i_Queue16_TaskBundle.ram_ext.Memory = u_g_Queue16_TaskBundle.ram_ext.Memory;
  endtask

  // ======================= Queue2_CHISNP =======================
  logic Queue2_CHISNP__io_enq_valid;
  logic [3:0] Queue2_CHISNP__io_enq_bits_qos;
  logic [10:0] Queue2_CHISNP__io_enq_bits_srcID;
  logic [11:0] Queue2_CHISNP__io_enq_bits_txnID;
  logic [10:0] Queue2_CHISNP__io_enq_bits_fwdNID;
  logic [11:0] Queue2_CHISNP__io_enq_bits_fwdTxnID;
  logic [4:0] Queue2_CHISNP__io_enq_bits_opcode;
  logic [44:0] Queue2_CHISNP__io_enq_bits_addr;
  logic Queue2_CHISNP__io_enq_bits_ns;
  logic Queue2_CHISNP__io_enq_bits_doNotGoToSD;
  logic Queue2_CHISNP__io_enq_bits_retToSrc;
  logic Queue2_CHISNP__io_enq_bits_traceTag;
  logic Queue2_CHISNP__io_enq_bits_mpam_perfMonGroup;
  logic [8:0] Queue2_CHISNP__io_enq_bits_mpam_partID;
  logic Queue2_CHISNP__io_enq_bits_mpam_mpamNS;
  logic Queue2_CHISNP__io_deq_ready;
  wire  g_Queue2_CHISNP__io_enq_ready;
  wire  i_Queue2_CHISNP__io_enq_ready;
  logic p_Queue2_CHISNP__io_enq_ready;
  bit   t_Queue2_CHISNP__io_enq_ready;
  wire  g_Queue2_CHISNP__io_deq_valid;
  wire  i_Queue2_CHISNP__io_deq_valid;
  logic p_Queue2_CHISNP__io_deq_valid;
  bit   t_Queue2_CHISNP__io_deq_valid;
  wire  [10:0] g_Queue2_CHISNP__io_deq_bits_srcID;
  wire  [10:0] i_Queue2_CHISNP__io_deq_bits_srcID;
  logic [10:0] p_Queue2_CHISNP__io_deq_bits_srcID;
  bit   t_Queue2_CHISNP__io_deq_bits_srcID;
  wire  [11:0] g_Queue2_CHISNP__io_deq_bits_txnID;
  wire  [11:0] i_Queue2_CHISNP__io_deq_bits_txnID;
  logic [11:0] p_Queue2_CHISNP__io_deq_bits_txnID;
  bit   t_Queue2_CHISNP__io_deq_bits_txnID;
  wire  [10:0] g_Queue2_CHISNP__io_deq_bits_fwdNID;
  wire  [10:0] i_Queue2_CHISNP__io_deq_bits_fwdNID;
  logic [10:0] p_Queue2_CHISNP__io_deq_bits_fwdNID;
  bit   t_Queue2_CHISNP__io_deq_bits_fwdNID;
  wire  [11:0] g_Queue2_CHISNP__io_deq_bits_fwdTxnID;
  wire  [11:0] i_Queue2_CHISNP__io_deq_bits_fwdTxnID;
  logic [11:0] p_Queue2_CHISNP__io_deq_bits_fwdTxnID;
  bit   t_Queue2_CHISNP__io_deq_bits_fwdTxnID;
  wire  [4:0] g_Queue2_CHISNP__io_deq_bits_opcode;
  wire  [4:0] i_Queue2_CHISNP__io_deq_bits_opcode;
  logic [4:0] p_Queue2_CHISNP__io_deq_bits_opcode;
  bit   t_Queue2_CHISNP__io_deq_bits_opcode;
  wire  [44:0] g_Queue2_CHISNP__io_deq_bits_addr;
  wire  [44:0] i_Queue2_CHISNP__io_deq_bits_addr;
  logic [44:0] p_Queue2_CHISNP__io_deq_bits_addr;
  bit   t_Queue2_CHISNP__io_deq_bits_addr;
  wire  g_Queue2_CHISNP__io_deq_bits_retToSrc;
  wire  i_Queue2_CHISNP__io_deq_bits_retToSrc;
  logic p_Queue2_CHISNP__io_deq_bits_retToSrc;
  bit   t_Queue2_CHISNP__io_deq_bits_retToSrc;
  wire  g_Queue2_CHISNP__io_deq_bits_traceTag;
  wire  i_Queue2_CHISNP__io_deq_bits_traceTag;
  logic p_Queue2_CHISNP__io_deq_bits_traceTag;
  bit   t_Queue2_CHISNP__io_deq_bits_traceTag;
  Queue2_CHISNP u_g_Queue2_CHISNP (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue2_CHISNP__io_enq_ready),
    .io_enq_valid (Queue2_CHISNP__io_enq_valid),
    .io_enq_bits_qos (Queue2_CHISNP__io_enq_bits_qos),
    .io_enq_bits_srcID (Queue2_CHISNP__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue2_CHISNP__io_enq_bits_txnID),
    .io_enq_bits_fwdNID (Queue2_CHISNP__io_enq_bits_fwdNID),
    .io_enq_bits_fwdTxnID (Queue2_CHISNP__io_enq_bits_fwdTxnID),
    .io_enq_bits_opcode (Queue2_CHISNP__io_enq_bits_opcode),
    .io_enq_bits_addr (Queue2_CHISNP__io_enq_bits_addr),
    .io_enq_bits_ns (Queue2_CHISNP__io_enq_bits_ns),
    .io_enq_bits_doNotGoToSD (Queue2_CHISNP__io_enq_bits_doNotGoToSD),
    .io_enq_bits_retToSrc (Queue2_CHISNP__io_enq_bits_retToSrc),
    .io_enq_bits_traceTag (Queue2_CHISNP__io_enq_bits_traceTag),
    .io_enq_bits_mpam_perfMonGroup (Queue2_CHISNP__io_enq_bits_mpam_perfMonGroup),
    .io_enq_bits_mpam_partID (Queue2_CHISNP__io_enq_bits_mpam_partID),
    .io_enq_bits_mpam_mpamNS (Queue2_CHISNP__io_enq_bits_mpam_mpamNS),
    .io_deq_ready (Queue2_CHISNP__io_deq_ready),
    .io_deq_valid (g_Queue2_CHISNP__io_deq_valid),
    .io_deq_bits_srcID (g_Queue2_CHISNP__io_deq_bits_srcID),
    .io_deq_bits_txnID (g_Queue2_CHISNP__io_deq_bits_txnID),
    .io_deq_bits_fwdNID (g_Queue2_CHISNP__io_deq_bits_fwdNID),
    .io_deq_bits_fwdTxnID (g_Queue2_CHISNP__io_deq_bits_fwdTxnID),
    .io_deq_bits_opcode (g_Queue2_CHISNP__io_deq_bits_opcode),
    .io_deq_bits_addr (g_Queue2_CHISNP__io_deq_bits_addr),
    .io_deq_bits_retToSrc (g_Queue2_CHISNP__io_deq_bits_retToSrc),
    .io_deq_bits_traceTag (g_Queue2_CHISNP__io_deq_bits_traceTag)
  );
  Queue2_CHISNP_xs u_i_Queue2_CHISNP (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue2_CHISNP__io_enq_ready),
    .io_enq_valid (Queue2_CHISNP__io_enq_valid),
    .io_enq_bits_qos (Queue2_CHISNP__io_enq_bits_qos),
    .io_enq_bits_srcID (Queue2_CHISNP__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue2_CHISNP__io_enq_bits_txnID),
    .io_enq_bits_fwdNID (Queue2_CHISNP__io_enq_bits_fwdNID),
    .io_enq_bits_fwdTxnID (Queue2_CHISNP__io_enq_bits_fwdTxnID),
    .io_enq_bits_opcode (Queue2_CHISNP__io_enq_bits_opcode),
    .io_enq_bits_addr (Queue2_CHISNP__io_enq_bits_addr),
    .io_enq_bits_ns (Queue2_CHISNP__io_enq_bits_ns),
    .io_enq_bits_doNotGoToSD (Queue2_CHISNP__io_enq_bits_doNotGoToSD),
    .io_enq_bits_retToSrc (Queue2_CHISNP__io_enq_bits_retToSrc),
    .io_enq_bits_traceTag (Queue2_CHISNP__io_enq_bits_traceTag),
    .io_enq_bits_mpam_perfMonGroup (Queue2_CHISNP__io_enq_bits_mpam_perfMonGroup),
    .io_enq_bits_mpam_partID (Queue2_CHISNP__io_enq_bits_mpam_partID),
    .io_enq_bits_mpam_mpamNS (Queue2_CHISNP__io_enq_bits_mpam_mpamNS),
    .io_deq_ready (Queue2_CHISNP__io_deq_ready),
    .io_deq_valid (i_Queue2_CHISNP__io_deq_valid),
    .io_deq_bits_srcID (i_Queue2_CHISNP__io_deq_bits_srcID),
    .io_deq_bits_txnID (i_Queue2_CHISNP__io_deq_bits_txnID),
    .io_deq_bits_fwdNID (i_Queue2_CHISNP__io_deq_bits_fwdNID),
    .io_deq_bits_fwdTxnID (i_Queue2_CHISNP__io_deq_bits_fwdTxnID),
    .io_deq_bits_opcode (i_Queue2_CHISNP__io_deq_bits_opcode),
    .io_deq_bits_addr (i_Queue2_CHISNP__io_deq_bits_addr),
    .io_deq_bits_retToSrc (i_Queue2_CHISNP__io_deq_bits_retToSrc),
    .io_deq_bits_traceTag (i_Queue2_CHISNP__io_deq_bits_traceTag)
  );
  task automatic drive_Queue2_CHISNP();
    Queue2_CHISNP__io_enq_valid = $urandom % 2;
    Queue2_CHISNP__io_enq_bits_qos = rnd(4);
    Queue2_CHISNP__io_enq_bits_srcID = rnd(11);
    Queue2_CHISNP__io_enq_bits_txnID = rnd(12);
    Queue2_CHISNP__io_enq_bits_fwdNID = rnd(11);
    Queue2_CHISNP__io_enq_bits_fwdTxnID = rnd(12);
    Queue2_CHISNP__io_enq_bits_opcode = rnd(5);
    Queue2_CHISNP__io_enq_bits_addr = rnd(45);
    Queue2_CHISNP__io_enq_bits_ns = $urandom % 2;
    Queue2_CHISNP__io_enq_bits_doNotGoToSD = $urandom % 2;
    Queue2_CHISNP__io_enq_bits_retToSrc = $urandom % 2;
    Queue2_CHISNP__io_enq_bits_traceTag = $urandom % 2;
    Queue2_CHISNP__io_enq_bits_mpam_perfMonGroup = $urandom % 2;
    Queue2_CHISNP__io_enq_bits_mpam_partID = rnd(9);
    Queue2_CHISNP__io_enq_bits_mpam_mpamNS = $urandom % 2;
    Queue2_CHISNP__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue2_CHISNP();
    checks++;
    if (g_Queue2_CHISNP__io_enq_ready !== i_Queue2_CHISNP__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_enq_ready g=%h i=%h", cyc, g_Queue2_CHISNP__io_enq_ready, i_Queue2_CHISNP__io_enq_ready);
    end
    if (g_Queue2_CHISNP__io_enq_ready !== p_Queue2_CHISNP__io_enq_ready) t_Queue2_CHISNP__io_enq_ready = 1'b1;
    p_Queue2_CHISNP__io_enq_ready = g_Queue2_CHISNP__io_enq_ready;
    checks++;
    if (g_Queue2_CHISNP__io_deq_valid !== i_Queue2_CHISNP__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_valid g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_valid, i_Queue2_CHISNP__io_deq_valid);
    end
    if (g_Queue2_CHISNP__io_deq_valid !== p_Queue2_CHISNP__io_deq_valid) t_Queue2_CHISNP__io_deq_valid = 1'b1;
    p_Queue2_CHISNP__io_deq_valid = g_Queue2_CHISNP__io_deq_valid;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_srcID !== i_Queue2_CHISNP__io_deq_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_srcID g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_srcID, i_Queue2_CHISNP__io_deq_bits_srcID);
    end
    if (g_Queue2_CHISNP__io_deq_bits_srcID !== p_Queue2_CHISNP__io_deq_bits_srcID) t_Queue2_CHISNP__io_deq_bits_srcID = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_srcID = g_Queue2_CHISNP__io_deq_bits_srcID;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_txnID !== i_Queue2_CHISNP__io_deq_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_txnID g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_txnID, i_Queue2_CHISNP__io_deq_bits_txnID);
    end
    if (g_Queue2_CHISNP__io_deq_bits_txnID !== p_Queue2_CHISNP__io_deq_bits_txnID) t_Queue2_CHISNP__io_deq_bits_txnID = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_txnID = g_Queue2_CHISNP__io_deq_bits_txnID;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_fwdNID !== i_Queue2_CHISNP__io_deq_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_fwdNID g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_fwdNID, i_Queue2_CHISNP__io_deq_bits_fwdNID);
    end
    if (g_Queue2_CHISNP__io_deq_bits_fwdNID !== p_Queue2_CHISNP__io_deq_bits_fwdNID) t_Queue2_CHISNP__io_deq_bits_fwdNID = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_fwdNID = g_Queue2_CHISNP__io_deq_bits_fwdNID;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_fwdTxnID !== i_Queue2_CHISNP__io_deq_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_fwdTxnID g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_fwdTxnID, i_Queue2_CHISNP__io_deq_bits_fwdTxnID);
    end
    if (g_Queue2_CHISNP__io_deq_bits_fwdTxnID !== p_Queue2_CHISNP__io_deq_bits_fwdTxnID) t_Queue2_CHISNP__io_deq_bits_fwdTxnID = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_fwdTxnID = g_Queue2_CHISNP__io_deq_bits_fwdTxnID;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_opcode !== i_Queue2_CHISNP__io_deq_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_opcode g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_opcode, i_Queue2_CHISNP__io_deq_bits_opcode);
    end
    if (g_Queue2_CHISNP__io_deq_bits_opcode !== p_Queue2_CHISNP__io_deq_bits_opcode) t_Queue2_CHISNP__io_deq_bits_opcode = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_opcode = g_Queue2_CHISNP__io_deq_bits_opcode;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_addr !== i_Queue2_CHISNP__io_deq_bits_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_addr g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_addr, i_Queue2_CHISNP__io_deq_bits_addr);
    end
    if (g_Queue2_CHISNP__io_deq_bits_addr !== p_Queue2_CHISNP__io_deq_bits_addr) t_Queue2_CHISNP__io_deq_bits_addr = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_addr = g_Queue2_CHISNP__io_deq_bits_addr;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_retToSrc !== i_Queue2_CHISNP__io_deq_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_retToSrc g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_retToSrc, i_Queue2_CHISNP__io_deq_bits_retToSrc);
    end
    if (g_Queue2_CHISNP__io_deq_bits_retToSrc !== p_Queue2_CHISNP__io_deq_bits_retToSrc) t_Queue2_CHISNP__io_deq_bits_retToSrc = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_retToSrc = g_Queue2_CHISNP__io_deq_bits_retToSrc;
    checks++;
    if (g_Queue2_CHISNP__io_deq_bits_traceTag !== i_Queue2_CHISNP__io_deq_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_CHISNP.io_deq_bits_traceTag g=%h i=%h", cyc, g_Queue2_CHISNP__io_deq_bits_traceTag, i_Queue2_CHISNP__io_deq_bits_traceTag);
    end
    if (g_Queue2_CHISNP__io_deq_bits_traceTag !== p_Queue2_CHISNP__io_deq_bits_traceTag) t_Queue2_CHISNP__io_deq_bits_traceTag = 1'b1;
    p_Queue2_CHISNP__io_deq_bits_traceTag = g_Queue2_CHISNP__io_deq_bits_traceTag;
  endtask
  longint cov_Queue2_CHISNP_full = 0;
  longint cov_Queue2_CHISNP_deq = 0;
  task automatic cover_Queue2_CHISNP();
    if (u_g_Queue2_CHISNP.maybe_full && u_g_Queue2_CHISNP.ptr_match) cov_Queue2_CHISNP_full++;
    if (u_g_Queue2_CHISNP.do_deq) cov_Queue2_CHISNP_deq++;
  endtask
  task automatic sync_Queue2_CHISNP();
    u_i_Queue2_CHISNP.ram_ext.Memory = u_g_Queue2_CHISNP.ram_ext.Memory;
  endtask

  // ======================= Queue16_GrantQueueTask =======================
  logic Queue16_GrantQueueTask__io_enq_valid;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_channel;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_txChannel;
  logic [8:0] Queue16_GrantQueueTask__io_enq_bits_task_set;
  logic [30:0] Queue16_GrantQueueTask__io_enq_bits_task_tag;
  logic [5:0] Queue16_GrantQueueTask__io_enq_bits_task_off;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_alias;
  logic [43:0] Queue16_GrantQueueTask__io_enq_bits_task_vaddr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_isKeyword;
  logic [3:0] Queue16_GrantQueueTask__io_enq_bits_task_opcode;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_param;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_size;
  logic [6:0] Queue16_GrantQueueTask__io_enq_bits_task_sourceId;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_bufIdx;
  logic Queue16_GrantQueueTask__io_enq_bits_task_needProbeAckData;
  logic Queue16_GrantQueueTask__io_enq_bits_task_denied;
  logic Queue16_GrantQueueTask__io_enq_bits_task_corrupt;
  logic Queue16_GrantQueueTask__io_enq_bits_task_mshrTask;
  logic [7:0] Queue16_GrantQueueTask__io_enq_bits_task_mshrId;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aliasTask;
  logic Queue16_GrantQueueTask__io_enq_bits_task_useProbeData;
  logic Queue16_GrantQueueTask__io_enq_bits_task_mshrRetry;
  logic Queue16_GrantQueueTask__io_enq_bits_task_readProbeDataDown;
  logic Queue16_GrantQueueTask__io_enq_bits_task_fromL2pft;
  logic Queue16_GrantQueueTask__io_enq_bits_task_needHint;
  logic Queue16_GrantQueueTask__io_enq_bits_task_dirty;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_way;
  logic Queue16_GrantQueueTask__io_enq_bits_task_meta_dirty;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_meta_state;
  logic Queue16_GrantQueueTask__io_enq_bits_task_meta_clients;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_meta_alias;
  logic Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetch;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetchSrc;
  logic Queue16_GrantQueueTask__io_enq_bits_task_meta_accessed;
  logic Queue16_GrantQueueTask__io_enq_bits_task_meta_tagErr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_meta_dataErr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_metaWen;
  logic Queue16_GrantQueueTask__io_enq_bits_task_tagWen;
  logic Queue16_GrantQueueTask__io_enq_bits_task_dsWen;
  logic [7:0] Queue16_GrantQueueTask__io_enq_bits_task_wayMask;
  logic Queue16_GrantQueueTask__io_enq_bits_task_replTask;
  logic Queue16_GrantQueueTask__io_enq_bits_task_cmoTask;
  logic Queue16_GrantQueueTask__io_enq_bits_task_cmoAll;
  logic [4:0] Queue16_GrantQueueTask__io_enq_bits_task_reqSource;
  logic Queue16_GrantQueueTask__io_enq_bits_task_mergeA;
  logic [5:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_off;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_alias;
  logic [43:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_vaddr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_isKeyword;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_opcode;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_param;
  logic [6:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_sourceId;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dirty;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_state;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_clients;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_alias;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetchSrc;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_accessed;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_tagErr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dataErr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitRelease;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToInval;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToClean;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseWithData;
  logic [7:0] Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseIdx;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_state;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_alias;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_accessed;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_tagErr;
  logic Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] Queue16_GrantQueueTask__io_enq_bits_task_tgtID;
  logic [10:0] Queue16_GrantQueueTask__io_enq_bits_task_srcID;
  logic [11:0] Queue16_GrantQueueTask__io_enq_bits_task_txnID;
  logic [10:0] Queue16_GrantQueueTask__io_enq_bits_task_homeNID;
  logic [11:0] Queue16_GrantQueueTask__io_enq_bits_task_dbID;
  logic [10:0] Queue16_GrantQueueTask__io_enq_bits_task_fwdNID;
  logic [11:0] Queue16_GrantQueueTask__io_enq_bits_task_fwdTxnID;
  logic [6:0] Queue16_GrantQueueTask__io_enq_bits_task_chiOpcode;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_resp;
  logic [2:0] Queue16_GrantQueueTask__io_enq_bits_task_fwdState;
  logic [3:0] Queue16_GrantQueueTask__io_enq_bits_task_pCrdType;
  logic Queue16_GrantQueueTask__io_enq_bits_task_retToSrc;
  logic Queue16_GrantQueueTask__io_enq_bits_task_likelyshared;
  logic Queue16_GrantQueueTask__io_enq_bits_task_expCompAck;
  logic Queue16_GrantQueueTask__io_enq_bits_task_allowRetry;
  logic Queue16_GrantQueueTask__io_enq_bits_task_memAttr_allocate;
  logic Queue16_GrantQueueTask__io_enq_bits_task_memAttr_cacheable;
  logic Queue16_GrantQueueTask__io_enq_bits_task_memAttr_device;
  logic Queue16_GrantQueueTask__io_enq_bits_task_memAttr_ewa;
  logic Queue16_GrantQueueTask__io_enq_bits_task_traceTag;
  logic [7:0] Queue16_GrantQueueTask__io_enq_bits_grantid;
  logic Queue16_GrantQueueTask__io_deq_ready;
  wire  g_Queue16_GrantQueueTask__io_enq_ready;
  wire  i_Queue16_GrantQueueTask__io_enq_ready;
  logic p_Queue16_GrantQueueTask__io_enq_ready;
  bit   t_Queue16_GrantQueueTask__io_enq_ready;
  wire  g_Queue16_GrantQueueTask__io_deq_valid;
  wire  i_Queue16_GrantQueueTask__io_deq_valid;
  logic p_Queue16_GrantQueueTask__io_deq_valid;
  bit   t_Queue16_GrantQueueTask__io_deq_valid;
  wire  g_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword;
  wire  i_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword;
  logic p_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword;
  wire  [3:0] g_Queue16_GrantQueueTask__io_deq_bits_task_opcode;
  wire  [3:0] i_Queue16_GrantQueueTask__io_deq_bits_task_opcode;
  logic [3:0] p_Queue16_GrantQueueTask__io_deq_bits_task_opcode;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_task_opcode;
  wire  [2:0] g_Queue16_GrantQueueTask__io_deq_bits_task_param;
  wire  [2:0] i_Queue16_GrantQueueTask__io_deq_bits_task_param;
  logic [2:0] p_Queue16_GrantQueueTask__io_deq_bits_task_param;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_task_param;
  wire  [6:0] g_Queue16_GrantQueueTask__io_deq_bits_task_sourceId;
  wire  [6:0] i_Queue16_GrantQueueTask__io_deq_bits_task_sourceId;
  logic [6:0] p_Queue16_GrantQueueTask__io_deq_bits_task_sourceId;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_task_sourceId;
  wire  g_Queue16_GrantQueueTask__io_deq_bits_task_denied;
  wire  i_Queue16_GrantQueueTask__io_deq_bits_task_denied;
  logic p_Queue16_GrantQueueTask__io_deq_bits_task_denied;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_task_denied;
  wire  g_Queue16_GrantQueueTask__io_deq_bits_task_corrupt;
  wire  i_Queue16_GrantQueueTask__io_deq_bits_task_corrupt;
  logic p_Queue16_GrantQueueTask__io_deq_bits_task_corrupt;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_task_corrupt;
  wire  [7:0] g_Queue16_GrantQueueTask__io_deq_bits_grantid;
  wire  [7:0] i_Queue16_GrantQueueTask__io_deq_bits_grantid;
  logic [7:0] p_Queue16_GrantQueueTask__io_deq_bits_grantid;
  bit   t_Queue16_GrantQueueTask__io_deq_bits_grantid;
  wire  [4:0] g_Queue16_GrantQueueTask__io_count;
  wire  [4:0] i_Queue16_GrantQueueTask__io_count;
  logic [4:0] p_Queue16_GrantQueueTask__io_count;
  bit   t_Queue16_GrantQueueTask__io_count;
  Queue16_GrantQueueTask u_g_Queue16_GrantQueueTask (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue16_GrantQueueTask__io_enq_ready),
    .io_enq_valid (Queue16_GrantQueueTask__io_enq_valid),
    .io_enq_bits_task_channel (Queue16_GrantQueueTask__io_enq_bits_task_channel),
    .io_enq_bits_task_txChannel (Queue16_GrantQueueTask__io_enq_bits_task_txChannel),
    .io_enq_bits_task_set (Queue16_GrantQueueTask__io_enq_bits_task_set),
    .io_enq_bits_task_tag (Queue16_GrantQueueTask__io_enq_bits_task_tag),
    .io_enq_bits_task_off (Queue16_GrantQueueTask__io_enq_bits_task_off),
    .io_enq_bits_task_alias (Queue16_GrantQueueTask__io_enq_bits_task_alias),
    .io_enq_bits_task_vaddr (Queue16_GrantQueueTask__io_enq_bits_task_vaddr),
    .io_enq_bits_task_isKeyword (Queue16_GrantQueueTask__io_enq_bits_task_isKeyword),
    .io_enq_bits_task_opcode (Queue16_GrantQueueTask__io_enq_bits_task_opcode),
    .io_enq_bits_task_param (Queue16_GrantQueueTask__io_enq_bits_task_param),
    .io_enq_bits_task_size (Queue16_GrantQueueTask__io_enq_bits_task_size),
    .io_enq_bits_task_sourceId (Queue16_GrantQueueTask__io_enq_bits_task_sourceId),
    .io_enq_bits_task_bufIdx (Queue16_GrantQueueTask__io_enq_bits_task_bufIdx),
    .io_enq_bits_task_needProbeAckData (Queue16_GrantQueueTask__io_enq_bits_task_needProbeAckData),
    .io_enq_bits_task_denied (Queue16_GrantQueueTask__io_enq_bits_task_denied),
    .io_enq_bits_task_corrupt (Queue16_GrantQueueTask__io_enq_bits_task_corrupt),
    .io_enq_bits_task_mshrTask (Queue16_GrantQueueTask__io_enq_bits_task_mshrTask),
    .io_enq_bits_task_mshrId (Queue16_GrantQueueTask__io_enq_bits_task_mshrId),
    .io_enq_bits_task_aliasTask (Queue16_GrantQueueTask__io_enq_bits_task_aliasTask),
    .io_enq_bits_task_useProbeData (Queue16_GrantQueueTask__io_enq_bits_task_useProbeData),
    .io_enq_bits_task_mshrRetry (Queue16_GrantQueueTask__io_enq_bits_task_mshrRetry),
    .io_enq_bits_task_readProbeDataDown (Queue16_GrantQueueTask__io_enq_bits_task_readProbeDataDown),
    .io_enq_bits_task_fromL2pft (Queue16_GrantQueueTask__io_enq_bits_task_fromL2pft),
    .io_enq_bits_task_needHint (Queue16_GrantQueueTask__io_enq_bits_task_needHint),
    .io_enq_bits_task_dirty (Queue16_GrantQueueTask__io_enq_bits_task_dirty),
    .io_enq_bits_task_way (Queue16_GrantQueueTask__io_enq_bits_task_way),
    .io_enq_bits_task_meta_dirty (Queue16_GrantQueueTask__io_enq_bits_task_meta_dirty),
    .io_enq_bits_task_meta_state (Queue16_GrantQueueTask__io_enq_bits_task_meta_state),
    .io_enq_bits_task_meta_clients (Queue16_GrantQueueTask__io_enq_bits_task_meta_clients),
    .io_enq_bits_task_meta_alias (Queue16_GrantQueueTask__io_enq_bits_task_meta_alias),
    .io_enq_bits_task_meta_prefetch (Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetch),
    .io_enq_bits_task_meta_prefetchSrc (Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetchSrc),
    .io_enq_bits_task_meta_accessed (Queue16_GrantQueueTask__io_enq_bits_task_meta_accessed),
    .io_enq_bits_task_meta_tagErr (Queue16_GrantQueueTask__io_enq_bits_task_meta_tagErr),
    .io_enq_bits_task_meta_dataErr (Queue16_GrantQueueTask__io_enq_bits_task_meta_dataErr),
    .io_enq_bits_task_metaWen (Queue16_GrantQueueTask__io_enq_bits_task_metaWen),
    .io_enq_bits_task_tagWen (Queue16_GrantQueueTask__io_enq_bits_task_tagWen),
    .io_enq_bits_task_dsWen (Queue16_GrantQueueTask__io_enq_bits_task_dsWen),
    .io_enq_bits_task_wayMask (Queue16_GrantQueueTask__io_enq_bits_task_wayMask),
    .io_enq_bits_task_replTask (Queue16_GrantQueueTask__io_enq_bits_task_replTask),
    .io_enq_bits_task_cmoTask (Queue16_GrantQueueTask__io_enq_bits_task_cmoTask),
    .io_enq_bits_task_cmoAll (Queue16_GrantQueueTask__io_enq_bits_task_cmoAll),
    .io_enq_bits_task_reqSource (Queue16_GrantQueueTask__io_enq_bits_task_reqSource),
    .io_enq_bits_task_mergeA (Queue16_GrantQueueTask__io_enq_bits_task_mergeA),
    .io_enq_bits_task_aMergeTask_off (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_off),
    .io_enq_bits_task_aMergeTask_alias (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_alias),
    .io_enq_bits_task_aMergeTask_vaddr (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_vaddr),
    .io_enq_bits_task_aMergeTask_isKeyword (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_isKeyword),
    .io_enq_bits_task_aMergeTask_opcode (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_opcode),
    .io_enq_bits_task_aMergeTask_param (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_param),
    .io_enq_bits_task_aMergeTask_sourceId (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_sourceId),
    .io_enq_bits_task_aMergeTask_meta_dirty (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dirty),
    .io_enq_bits_task_aMergeTask_meta_state (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_state),
    .io_enq_bits_task_aMergeTask_meta_clients (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_clients),
    .io_enq_bits_task_aMergeTask_meta_alias (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_alias),
    .io_enq_bits_task_aMergeTask_meta_prefetch (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetch),
    .io_enq_bits_task_aMergeTask_meta_prefetchSrc (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetchSrc),
    .io_enq_bits_task_aMergeTask_meta_accessed (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_accessed),
    .io_enq_bits_task_aMergeTask_meta_tagErr (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_tagErr),
    .io_enq_bits_task_aMergeTask_meta_dataErr (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dataErr),
    .io_enq_bits_task_snpHitRelease (Queue16_GrantQueueTask__io_enq_bits_task_snpHitRelease),
    .io_enq_bits_task_snpHitReleaseToInval (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToInval),
    .io_enq_bits_task_snpHitReleaseToClean (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToClean),
    .io_enq_bits_task_snpHitReleaseWithData (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseWithData),
    .io_enq_bits_task_snpHitReleaseIdx (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseIdx),
    .io_enq_bits_task_snpHitReleaseMeta_dirty (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dirty),
    .io_enq_bits_task_snpHitReleaseMeta_state (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_state),
    .io_enq_bits_task_snpHitReleaseMeta_clients (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_clients),
    .io_enq_bits_task_snpHitReleaseMeta_alias (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_alias),
    .io_enq_bits_task_snpHitReleaseMeta_prefetch (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetch),
    .io_enq_bits_task_snpHitReleaseMeta_prefetchSrc (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_task_snpHitReleaseMeta_accessed (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_accessed),
    .io_enq_bits_task_snpHitReleaseMeta_tagErr (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_tagErr),
    .io_enq_bits_task_snpHitReleaseMeta_dataErr (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dataErr),
    .io_enq_bits_task_tgtID (Queue16_GrantQueueTask__io_enq_bits_task_tgtID),
    .io_enq_bits_task_srcID (Queue16_GrantQueueTask__io_enq_bits_task_srcID),
    .io_enq_bits_task_txnID (Queue16_GrantQueueTask__io_enq_bits_task_txnID),
    .io_enq_bits_task_homeNID (Queue16_GrantQueueTask__io_enq_bits_task_homeNID),
    .io_enq_bits_task_dbID (Queue16_GrantQueueTask__io_enq_bits_task_dbID),
    .io_enq_bits_task_fwdNID (Queue16_GrantQueueTask__io_enq_bits_task_fwdNID),
    .io_enq_bits_task_fwdTxnID (Queue16_GrantQueueTask__io_enq_bits_task_fwdTxnID),
    .io_enq_bits_task_chiOpcode (Queue16_GrantQueueTask__io_enq_bits_task_chiOpcode),
    .io_enq_bits_task_resp (Queue16_GrantQueueTask__io_enq_bits_task_resp),
    .io_enq_bits_task_fwdState (Queue16_GrantQueueTask__io_enq_bits_task_fwdState),
    .io_enq_bits_task_pCrdType (Queue16_GrantQueueTask__io_enq_bits_task_pCrdType),
    .io_enq_bits_task_retToSrc (Queue16_GrantQueueTask__io_enq_bits_task_retToSrc),
    .io_enq_bits_task_likelyshared (Queue16_GrantQueueTask__io_enq_bits_task_likelyshared),
    .io_enq_bits_task_expCompAck (Queue16_GrantQueueTask__io_enq_bits_task_expCompAck),
    .io_enq_bits_task_allowRetry (Queue16_GrantQueueTask__io_enq_bits_task_allowRetry),
    .io_enq_bits_task_memAttr_allocate (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_allocate),
    .io_enq_bits_task_memAttr_cacheable (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_cacheable),
    .io_enq_bits_task_memAttr_device (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_device),
    .io_enq_bits_task_memAttr_ewa (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_ewa),
    .io_enq_bits_task_traceTag (Queue16_GrantQueueTask__io_enq_bits_task_traceTag),
    .io_enq_bits_grantid (Queue16_GrantQueueTask__io_enq_bits_grantid),
    .io_deq_ready (Queue16_GrantQueueTask__io_deq_ready),
    .io_deq_valid (g_Queue16_GrantQueueTask__io_deq_valid),
    .io_deq_bits_task_isKeyword (g_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword),
    .io_deq_bits_task_opcode (g_Queue16_GrantQueueTask__io_deq_bits_task_opcode),
    .io_deq_bits_task_param (g_Queue16_GrantQueueTask__io_deq_bits_task_param),
    .io_deq_bits_task_sourceId (g_Queue16_GrantQueueTask__io_deq_bits_task_sourceId),
    .io_deq_bits_task_denied (g_Queue16_GrantQueueTask__io_deq_bits_task_denied),
    .io_deq_bits_task_corrupt (g_Queue16_GrantQueueTask__io_deq_bits_task_corrupt),
    .io_deq_bits_grantid (g_Queue16_GrantQueueTask__io_deq_bits_grantid),
    .io_count (g_Queue16_GrantQueueTask__io_count)
  );
  Queue16_GrantQueueTask_xs u_i_Queue16_GrantQueueTask (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue16_GrantQueueTask__io_enq_ready),
    .io_enq_valid (Queue16_GrantQueueTask__io_enq_valid),
    .io_enq_bits_task_channel (Queue16_GrantQueueTask__io_enq_bits_task_channel),
    .io_enq_bits_task_txChannel (Queue16_GrantQueueTask__io_enq_bits_task_txChannel),
    .io_enq_bits_task_set (Queue16_GrantQueueTask__io_enq_bits_task_set),
    .io_enq_bits_task_tag (Queue16_GrantQueueTask__io_enq_bits_task_tag),
    .io_enq_bits_task_off (Queue16_GrantQueueTask__io_enq_bits_task_off),
    .io_enq_bits_task_alias (Queue16_GrantQueueTask__io_enq_bits_task_alias),
    .io_enq_bits_task_vaddr (Queue16_GrantQueueTask__io_enq_bits_task_vaddr),
    .io_enq_bits_task_isKeyword (Queue16_GrantQueueTask__io_enq_bits_task_isKeyword),
    .io_enq_bits_task_opcode (Queue16_GrantQueueTask__io_enq_bits_task_opcode),
    .io_enq_bits_task_param (Queue16_GrantQueueTask__io_enq_bits_task_param),
    .io_enq_bits_task_size (Queue16_GrantQueueTask__io_enq_bits_task_size),
    .io_enq_bits_task_sourceId (Queue16_GrantQueueTask__io_enq_bits_task_sourceId),
    .io_enq_bits_task_bufIdx (Queue16_GrantQueueTask__io_enq_bits_task_bufIdx),
    .io_enq_bits_task_needProbeAckData (Queue16_GrantQueueTask__io_enq_bits_task_needProbeAckData),
    .io_enq_bits_task_denied (Queue16_GrantQueueTask__io_enq_bits_task_denied),
    .io_enq_bits_task_corrupt (Queue16_GrantQueueTask__io_enq_bits_task_corrupt),
    .io_enq_bits_task_mshrTask (Queue16_GrantQueueTask__io_enq_bits_task_mshrTask),
    .io_enq_bits_task_mshrId (Queue16_GrantQueueTask__io_enq_bits_task_mshrId),
    .io_enq_bits_task_aliasTask (Queue16_GrantQueueTask__io_enq_bits_task_aliasTask),
    .io_enq_bits_task_useProbeData (Queue16_GrantQueueTask__io_enq_bits_task_useProbeData),
    .io_enq_bits_task_mshrRetry (Queue16_GrantQueueTask__io_enq_bits_task_mshrRetry),
    .io_enq_bits_task_readProbeDataDown (Queue16_GrantQueueTask__io_enq_bits_task_readProbeDataDown),
    .io_enq_bits_task_fromL2pft (Queue16_GrantQueueTask__io_enq_bits_task_fromL2pft),
    .io_enq_bits_task_needHint (Queue16_GrantQueueTask__io_enq_bits_task_needHint),
    .io_enq_bits_task_dirty (Queue16_GrantQueueTask__io_enq_bits_task_dirty),
    .io_enq_bits_task_way (Queue16_GrantQueueTask__io_enq_bits_task_way),
    .io_enq_bits_task_meta_dirty (Queue16_GrantQueueTask__io_enq_bits_task_meta_dirty),
    .io_enq_bits_task_meta_state (Queue16_GrantQueueTask__io_enq_bits_task_meta_state),
    .io_enq_bits_task_meta_clients (Queue16_GrantQueueTask__io_enq_bits_task_meta_clients),
    .io_enq_bits_task_meta_alias (Queue16_GrantQueueTask__io_enq_bits_task_meta_alias),
    .io_enq_bits_task_meta_prefetch (Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetch),
    .io_enq_bits_task_meta_prefetchSrc (Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetchSrc),
    .io_enq_bits_task_meta_accessed (Queue16_GrantQueueTask__io_enq_bits_task_meta_accessed),
    .io_enq_bits_task_meta_tagErr (Queue16_GrantQueueTask__io_enq_bits_task_meta_tagErr),
    .io_enq_bits_task_meta_dataErr (Queue16_GrantQueueTask__io_enq_bits_task_meta_dataErr),
    .io_enq_bits_task_metaWen (Queue16_GrantQueueTask__io_enq_bits_task_metaWen),
    .io_enq_bits_task_tagWen (Queue16_GrantQueueTask__io_enq_bits_task_tagWen),
    .io_enq_bits_task_dsWen (Queue16_GrantQueueTask__io_enq_bits_task_dsWen),
    .io_enq_bits_task_wayMask (Queue16_GrantQueueTask__io_enq_bits_task_wayMask),
    .io_enq_bits_task_replTask (Queue16_GrantQueueTask__io_enq_bits_task_replTask),
    .io_enq_bits_task_cmoTask (Queue16_GrantQueueTask__io_enq_bits_task_cmoTask),
    .io_enq_bits_task_cmoAll (Queue16_GrantQueueTask__io_enq_bits_task_cmoAll),
    .io_enq_bits_task_reqSource (Queue16_GrantQueueTask__io_enq_bits_task_reqSource),
    .io_enq_bits_task_mergeA (Queue16_GrantQueueTask__io_enq_bits_task_mergeA),
    .io_enq_bits_task_aMergeTask_off (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_off),
    .io_enq_bits_task_aMergeTask_alias (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_alias),
    .io_enq_bits_task_aMergeTask_vaddr (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_vaddr),
    .io_enq_bits_task_aMergeTask_isKeyword (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_isKeyword),
    .io_enq_bits_task_aMergeTask_opcode (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_opcode),
    .io_enq_bits_task_aMergeTask_param (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_param),
    .io_enq_bits_task_aMergeTask_sourceId (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_sourceId),
    .io_enq_bits_task_aMergeTask_meta_dirty (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dirty),
    .io_enq_bits_task_aMergeTask_meta_state (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_state),
    .io_enq_bits_task_aMergeTask_meta_clients (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_clients),
    .io_enq_bits_task_aMergeTask_meta_alias (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_alias),
    .io_enq_bits_task_aMergeTask_meta_prefetch (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetch),
    .io_enq_bits_task_aMergeTask_meta_prefetchSrc (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetchSrc),
    .io_enq_bits_task_aMergeTask_meta_accessed (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_accessed),
    .io_enq_bits_task_aMergeTask_meta_tagErr (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_tagErr),
    .io_enq_bits_task_aMergeTask_meta_dataErr (Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dataErr),
    .io_enq_bits_task_snpHitRelease (Queue16_GrantQueueTask__io_enq_bits_task_snpHitRelease),
    .io_enq_bits_task_snpHitReleaseToInval (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToInval),
    .io_enq_bits_task_snpHitReleaseToClean (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToClean),
    .io_enq_bits_task_snpHitReleaseWithData (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseWithData),
    .io_enq_bits_task_snpHitReleaseIdx (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseIdx),
    .io_enq_bits_task_snpHitReleaseMeta_dirty (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dirty),
    .io_enq_bits_task_snpHitReleaseMeta_state (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_state),
    .io_enq_bits_task_snpHitReleaseMeta_clients (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_clients),
    .io_enq_bits_task_snpHitReleaseMeta_alias (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_alias),
    .io_enq_bits_task_snpHitReleaseMeta_prefetch (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetch),
    .io_enq_bits_task_snpHitReleaseMeta_prefetchSrc (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_task_snpHitReleaseMeta_accessed (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_accessed),
    .io_enq_bits_task_snpHitReleaseMeta_tagErr (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_tagErr),
    .io_enq_bits_task_snpHitReleaseMeta_dataErr (Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dataErr),
    .io_enq_bits_task_tgtID (Queue16_GrantQueueTask__io_enq_bits_task_tgtID),
    .io_enq_bits_task_srcID (Queue16_GrantQueueTask__io_enq_bits_task_srcID),
    .io_enq_bits_task_txnID (Queue16_GrantQueueTask__io_enq_bits_task_txnID),
    .io_enq_bits_task_homeNID (Queue16_GrantQueueTask__io_enq_bits_task_homeNID),
    .io_enq_bits_task_dbID (Queue16_GrantQueueTask__io_enq_bits_task_dbID),
    .io_enq_bits_task_fwdNID (Queue16_GrantQueueTask__io_enq_bits_task_fwdNID),
    .io_enq_bits_task_fwdTxnID (Queue16_GrantQueueTask__io_enq_bits_task_fwdTxnID),
    .io_enq_bits_task_chiOpcode (Queue16_GrantQueueTask__io_enq_bits_task_chiOpcode),
    .io_enq_bits_task_resp (Queue16_GrantQueueTask__io_enq_bits_task_resp),
    .io_enq_bits_task_fwdState (Queue16_GrantQueueTask__io_enq_bits_task_fwdState),
    .io_enq_bits_task_pCrdType (Queue16_GrantQueueTask__io_enq_bits_task_pCrdType),
    .io_enq_bits_task_retToSrc (Queue16_GrantQueueTask__io_enq_bits_task_retToSrc),
    .io_enq_bits_task_likelyshared (Queue16_GrantQueueTask__io_enq_bits_task_likelyshared),
    .io_enq_bits_task_expCompAck (Queue16_GrantQueueTask__io_enq_bits_task_expCompAck),
    .io_enq_bits_task_allowRetry (Queue16_GrantQueueTask__io_enq_bits_task_allowRetry),
    .io_enq_bits_task_memAttr_allocate (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_allocate),
    .io_enq_bits_task_memAttr_cacheable (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_cacheable),
    .io_enq_bits_task_memAttr_device (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_device),
    .io_enq_bits_task_memAttr_ewa (Queue16_GrantQueueTask__io_enq_bits_task_memAttr_ewa),
    .io_enq_bits_task_traceTag (Queue16_GrantQueueTask__io_enq_bits_task_traceTag),
    .io_enq_bits_grantid (Queue16_GrantQueueTask__io_enq_bits_grantid),
    .io_deq_ready (Queue16_GrantQueueTask__io_deq_ready),
    .io_deq_valid (i_Queue16_GrantQueueTask__io_deq_valid),
    .io_deq_bits_task_isKeyword (i_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword),
    .io_deq_bits_task_opcode (i_Queue16_GrantQueueTask__io_deq_bits_task_opcode),
    .io_deq_bits_task_param (i_Queue16_GrantQueueTask__io_deq_bits_task_param),
    .io_deq_bits_task_sourceId (i_Queue16_GrantQueueTask__io_deq_bits_task_sourceId),
    .io_deq_bits_task_denied (i_Queue16_GrantQueueTask__io_deq_bits_task_denied),
    .io_deq_bits_task_corrupt (i_Queue16_GrantQueueTask__io_deq_bits_task_corrupt),
    .io_deq_bits_grantid (i_Queue16_GrantQueueTask__io_deq_bits_grantid),
    .io_count (i_Queue16_GrantQueueTask__io_count)
  );
  task automatic drive_Queue16_GrantQueueTask();
    Queue16_GrantQueueTask__io_enq_valid = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_channel = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_txChannel = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_set = rnd(9);
    Queue16_GrantQueueTask__io_enq_bits_task_tag = rnd(31);
    Queue16_GrantQueueTask__io_enq_bits_task_off = rnd(6);
    Queue16_GrantQueueTask__io_enq_bits_task_alias = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_vaddr = rnd(44);
    Queue16_GrantQueueTask__io_enq_bits_task_isKeyword = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_opcode = rnd(4);
    Queue16_GrantQueueTask__io_enq_bits_task_param = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_size = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_sourceId = rnd(7);
    Queue16_GrantQueueTask__io_enq_bits_task_bufIdx = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_needProbeAckData = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_denied = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_corrupt = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_mshrTask = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_mshrId = rnd(8);
    Queue16_GrantQueueTask__io_enq_bits_task_aliasTask = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_useProbeData = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_mshrRetry = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_readProbeDataDown = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_fromL2pft = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_needHint = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_dirty = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_way = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_meta_dirty = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_meta_state = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_meta_clients = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_meta_alias = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetch = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_meta_prefetchSrc = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_meta_accessed = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_meta_tagErr = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_meta_dataErr = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_metaWen = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_tagWen = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_dsWen = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_wayMask = rnd(8);
    Queue16_GrantQueueTask__io_enq_bits_task_replTask = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_cmoTask = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_cmoAll = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_reqSource = rnd(5);
    Queue16_GrantQueueTask__io_enq_bits_task_mergeA = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_off = rnd(6);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_alias = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_vaddr = rnd(44);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_isKeyword = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_opcode = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_param = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_sourceId = rnd(7);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dirty = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_state = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_clients = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_alias = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetch = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_prefetchSrc = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_accessed = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_tagErr = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_aMergeTask_meta_dataErr = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitRelease = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToInval = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseToClean = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseWithData = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseIdx = rnd(8);
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dirty = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_state = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_clients = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_alias = rnd(2);
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetch = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_prefetchSrc = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_accessed = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_tagErr = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_snpHitReleaseMeta_dataErr = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_tgtID = rnd(11);
    Queue16_GrantQueueTask__io_enq_bits_task_srcID = rnd(11);
    Queue16_GrantQueueTask__io_enq_bits_task_txnID = rnd(12);
    Queue16_GrantQueueTask__io_enq_bits_task_homeNID = rnd(11);
    Queue16_GrantQueueTask__io_enq_bits_task_dbID = rnd(12);
    Queue16_GrantQueueTask__io_enq_bits_task_fwdNID = rnd(11);
    Queue16_GrantQueueTask__io_enq_bits_task_fwdTxnID = rnd(12);
    Queue16_GrantQueueTask__io_enq_bits_task_chiOpcode = rnd(7);
    Queue16_GrantQueueTask__io_enq_bits_task_resp = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_fwdState = rnd(3);
    Queue16_GrantQueueTask__io_enq_bits_task_pCrdType = rnd(4);
    Queue16_GrantQueueTask__io_enq_bits_task_retToSrc = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_likelyshared = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_expCompAck = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_allowRetry = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_memAttr_allocate = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_memAttr_cacheable = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_memAttr_device = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_memAttr_ewa = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_task_traceTag = $urandom % 2;
    Queue16_GrantQueueTask__io_enq_bits_grantid = rnd(8);
    Queue16_GrantQueueTask__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_GrantQueueTask();
    checks++;
    if (g_Queue16_GrantQueueTask__io_enq_ready !== i_Queue16_GrantQueueTask__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_enq_ready g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_enq_ready, i_Queue16_GrantQueueTask__io_enq_ready);
    end
    if (g_Queue16_GrantQueueTask__io_enq_ready !== p_Queue16_GrantQueueTask__io_enq_ready) t_Queue16_GrantQueueTask__io_enq_ready = 1'b1;
    p_Queue16_GrantQueueTask__io_enq_ready = g_Queue16_GrantQueueTask__io_enq_ready;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_valid !== i_Queue16_GrantQueueTask__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_valid g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_valid, i_Queue16_GrantQueueTask__io_deq_valid);
    end
    if (g_Queue16_GrantQueueTask__io_deq_valid !== p_Queue16_GrantQueueTask__io_deq_valid) t_Queue16_GrantQueueTask__io_deq_valid = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_valid = g_Queue16_GrantQueueTask__io_deq_valid;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword !== i_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_task_isKeyword g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword, i_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword !== p_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword) t_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword = g_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_opcode !== i_Queue16_GrantQueueTask__io_deq_bits_task_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_task_opcode g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_task_opcode, i_Queue16_GrantQueueTask__io_deq_bits_task_opcode);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_opcode !== p_Queue16_GrantQueueTask__io_deq_bits_task_opcode) t_Queue16_GrantQueueTask__io_deq_bits_task_opcode = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_task_opcode = g_Queue16_GrantQueueTask__io_deq_bits_task_opcode;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_param !== i_Queue16_GrantQueueTask__io_deq_bits_task_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_task_param g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_task_param, i_Queue16_GrantQueueTask__io_deq_bits_task_param);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_param !== p_Queue16_GrantQueueTask__io_deq_bits_task_param) t_Queue16_GrantQueueTask__io_deq_bits_task_param = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_task_param = g_Queue16_GrantQueueTask__io_deq_bits_task_param;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_sourceId !== i_Queue16_GrantQueueTask__io_deq_bits_task_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_task_sourceId g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_task_sourceId, i_Queue16_GrantQueueTask__io_deq_bits_task_sourceId);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_sourceId !== p_Queue16_GrantQueueTask__io_deq_bits_task_sourceId) t_Queue16_GrantQueueTask__io_deq_bits_task_sourceId = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_task_sourceId = g_Queue16_GrantQueueTask__io_deq_bits_task_sourceId;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_denied !== i_Queue16_GrantQueueTask__io_deq_bits_task_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_task_denied g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_task_denied, i_Queue16_GrantQueueTask__io_deq_bits_task_denied);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_denied !== p_Queue16_GrantQueueTask__io_deq_bits_task_denied) t_Queue16_GrantQueueTask__io_deq_bits_task_denied = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_task_denied = g_Queue16_GrantQueueTask__io_deq_bits_task_denied;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_corrupt !== i_Queue16_GrantQueueTask__io_deq_bits_task_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_task_corrupt g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_task_corrupt, i_Queue16_GrantQueueTask__io_deq_bits_task_corrupt);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_task_corrupt !== p_Queue16_GrantQueueTask__io_deq_bits_task_corrupt) t_Queue16_GrantQueueTask__io_deq_bits_task_corrupt = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_task_corrupt = g_Queue16_GrantQueueTask__io_deq_bits_task_corrupt;
    checks++;
    if (g_Queue16_GrantQueueTask__io_deq_bits_grantid !== i_Queue16_GrantQueueTask__io_deq_bits_grantid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_deq_bits_grantid g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_deq_bits_grantid, i_Queue16_GrantQueueTask__io_deq_bits_grantid);
    end
    if (g_Queue16_GrantQueueTask__io_deq_bits_grantid !== p_Queue16_GrantQueueTask__io_deq_bits_grantid) t_Queue16_GrantQueueTask__io_deq_bits_grantid = 1'b1;
    p_Queue16_GrantQueueTask__io_deq_bits_grantid = g_Queue16_GrantQueueTask__io_deq_bits_grantid;
    checks++;
    if (g_Queue16_GrantQueueTask__io_count !== i_Queue16_GrantQueueTask__io_count) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueTask.io_count g=%h i=%h", cyc, g_Queue16_GrantQueueTask__io_count, i_Queue16_GrantQueueTask__io_count);
    end
    if (g_Queue16_GrantQueueTask__io_count !== p_Queue16_GrantQueueTask__io_count) t_Queue16_GrantQueueTask__io_count = 1'b1;
    p_Queue16_GrantQueueTask__io_count = g_Queue16_GrantQueueTask__io_count;
  endtask
  longint cov_Queue16_GrantQueueTask_full = 0;
  longint cov_Queue16_GrantQueueTask_deq = 0;
  task automatic cover_Queue16_GrantQueueTask();
    if (u_g_Queue16_GrantQueueTask.maybe_full && u_g_Queue16_GrantQueueTask.ptr_match) cov_Queue16_GrantQueueTask_full++;
    if (u_g_Queue16_GrantQueueTask.do_deq) cov_Queue16_GrantQueueTask_deq++;
  endtask
  task automatic sync_Queue16_GrantQueueTask();
    u_i_Queue16_GrantQueueTask.ram_ext.Memory = u_g_Queue16_GrantQueueTask.ram_ext.Memory;
  endtask

  // ======================= Queue16_GrantQueueData =======================
  logic Queue16_GrantQueueData__io_enq_valid;
  logic [255:0] Queue16_GrantQueueData__io_enq_bits_data_data;
  logic Queue16_GrantQueueData__io_deq_ready;
  wire  [255:0] g_Queue16_GrantQueueData__io_deq_bits_data_data;
  wire  [255:0] i_Queue16_GrantQueueData__io_deq_bits_data_data;
  logic [255:0] p_Queue16_GrantQueueData__io_deq_bits_data_data;
  bit   t_Queue16_GrantQueueData__io_deq_bits_data_data;
  Queue16_GrantQueueData u_g_Queue16_GrantQueueData (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_GrantQueueData__io_enq_valid),
    .io_enq_bits_data_data (Queue16_GrantQueueData__io_enq_bits_data_data),
    .io_deq_ready (Queue16_GrantQueueData__io_deq_ready),
    .io_deq_bits_data_data (g_Queue16_GrantQueueData__io_deq_bits_data_data)
  );
  Queue16_GrantQueueData_xs u_i_Queue16_GrantQueueData (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_GrantQueueData__io_enq_valid),
    .io_enq_bits_data_data (Queue16_GrantQueueData__io_enq_bits_data_data),
    .io_deq_ready (Queue16_GrantQueueData__io_deq_ready),
    .io_deq_bits_data_data (i_Queue16_GrantQueueData__io_deq_bits_data_data)
  );
  task automatic drive_Queue16_GrantQueueData();
    Queue16_GrantQueueData__io_enq_valid = $urandom % 2;
    Queue16_GrantQueueData__io_enq_bits_data_data = rnd(256);
    Queue16_GrantQueueData__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_GrantQueueData();
    checks++;
    if (g_Queue16_GrantQueueData__io_deq_bits_data_data !== i_Queue16_GrantQueueData__io_deq_bits_data_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_GrantQueueData.io_deq_bits_data_data g=%h i=%h", cyc, g_Queue16_GrantQueueData__io_deq_bits_data_data, i_Queue16_GrantQueueData__io_deq_bits_data_data);
    end
    if (g_Queue16_GrantQueueData__io_deq_bits_data_data !== p_Queue16_GrantQueueData__io_deq_bits_data_data) t_Queue16_GrantQueueData__io_deq_bits_data_data = 1'b1;
    p_Queue16_GrantQueueData__io_deq_bits_data_data = g_Queue16_GrantQueueData__io_deq_bits_data_data;
  endtask
  longint cov_Queue16_GrantQueueData_full = 0;
  longint cov_Queue16_GrantQueueData_deq = 0;
  task automatic cover_Queue16_GrantQueueData();
    if (!u_g_Queue16_GrantQueueData.io_enq_ready) cov_Queue16_GrantQueueData_full++;
    if (u_g_Queue16_GrantQueueData.do_deq) cov_Queue16_GrantQueueData_deq++;
  endtask
  task automatic sync_Queue16_GrantQueueData();
    u_i_Queue16_GrantQueueData.ram_data_data_ext.Memory = u_g_Queue16_GrantQueueData.ram_data_data_ext.Memory;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_Queue16_DSBeat();
    drive_Queue16_TaskBundle();
    drive_Queue2_CHISNP();
    drive_Queue16_GrantQueueTask();
    drive_Queue16_GrantQueueData();
    #1;
    sync_Queue16_DSBeat();
    sync_Queue16_TaskBundle();
    sync_Queue2_CHISNP();
    sync_Queue16_GrantQueueTask();
    sync_Queue16_GrantQueueData();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_Queue16_DSBeat();
      drive_Queue16_TaskBundle();
      drive_Queue2_CHISNP();
      drive_Queue16_GrantQueueTask();
      drive_Queue16_GrantQueueData();
      #1;
      check_Queue16_DSBeat();
      cover_Queue16_DSBeat();
      check_Queue16_TaskBundle();
      cover_Queue16_TaskBundle();
      check_Queue2_CHISNP();
      cover_Queue2_CHISNP();
      check_Queue16_GrantQueueTask();
      cover_Queue16_GrantQueueTask();
      check_Queue16_GrantQueueData();
      cover_Queue16_GrantQueueData();
    end
    begin int tg; tg = 0;
      if (t_Queue16_DSBeat__io_deq_bits_data) tg++; else $display("COV: Queue16_DSBeat.io_deq_bits_data never toggled");
      $display("Queue16_DSBeat: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("Queue16_DSBeat: cover full = %0d", cov_Queue16_DSBeat_full);
      if (cov_Queue16_DSBeat_full == 0) covfail = 1;
      $display("Queue16_DSBeat: cover deq = %0d", cov_Queue16_DSBeat_deq);
      if (cov_Queue16_DSBeat_deq == 0) covfail = 1;
      $display("Queue16_DSBeat: cover bypass = %0d", cov_Queue16_DSBeat_bypass);
      if (cov_Queue16_DSBeat_bypass == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue16_TaskBundle__io_enq_ready) tg++; else $display("COV: Queue16_TaskBundle.io_enq_ready never toggled");
      if (t_Queue16_TaskBundle__io_deq_valid) tg++; else $display("COV: Queue16_TaskBundle.io_deq_valid never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_off) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_off never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_corrupt) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_corrupt never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_tgtID) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_tgtID never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_txnID) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_txnID never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_homeNID) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_homeNID never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_dbID) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_dbID never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_chiOpcode) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_chiOpcode never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_resp) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_resp never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_fwdState) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_fwdState never toggled");
      if (t_Queue16_TaskBundle__io_deq_bits_traceTag) tg++; else $display("COV: Queue16_TaskBundle.io_deq_bits_traceTag never toggled");
      if (t_Queue16_TaskBundle__io_count) tg++; else $display("COV: Queue16_TaskBundle.io_count never toggled");
      $display("Queue16_TaskBundle: toggled=%0d/13 (need >= 13)", tg);
      if (tg < 13) covfail = 1;
      $display("Queue16_TaskBundle: cover full = %0d", cov_Queue16_TaskBundle_full);
      if (cov_Queue16_TaskBundle_full == 0) covfail = 1;
      $display("Queue16_TaskBundle: cover deq = %0d", cov_Queue16_TaskBundle_deq);
      if (cov_Queue16_TaskBundle_deq == 0) covfail = 1;
      $display("Queue16_TaskBundle: cover bypass = %0d", cov_Queue16_TaskBundle_bypass);
      if (cov_Queue16_TaskBundle_bypass == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue2_CHISNP__io_enq_ready) tg++; else $display("COV: Queue2_CHISNP.io_enq_ready never toggled");
      if (t_Queue2_CHISNP__io_deq_valid) tg++; else $display("COV: Queue2_CHISNP.io_deq_valid never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_srcID) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_srcID never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_txnID) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_txnID never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_fwdNID) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_fwdNID never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_fwdTxnID) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_fwdTxnID never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_opcode) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_opcode never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_addr) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_addr never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_retToSrc) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_retToSrc never toggled");
      if (t_Queue2_CHISNP__io_deq_bits_traceTag) tg++; else $display("COV: Queue2_CHISNP.io_deq_bits_traceTag never toggled");
      $display("Queue2_CHISNP: toggled=%0d/10 (need >= 10)", tg);
      if (tg < 10) covfail = 1;
      $display("Queue2_CHISNP: cover full = %0d", cov_Queue2_CHISNP_full);
      if (cov_Queue2_CHISNP_full == 0) covfail = 1;
      $display("Queue2_CHISNP: cover deq = %0d", cov_Queue2_CHISNP_deq);
      if (cov_Queue2_CHISNP_deq == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue16_GrantQueueTask__io_enq_ready) tg++; else $display("COV: Queue16_GrantQueueTask.io_enq_ready never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_valid) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_valid never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_task_isKeyword) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_task_isKeyword never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_task_opcode) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_task_opcode never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_task_param) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_task_param never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_task_sourceId) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_task_sourceId never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_task_denied) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_task_denied never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_task_corrupt) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_task_corrupt never toggled");
      if (t_Queue16_GrantQueueTask__io_deq_bits_grantid) tg++; else $display("COV: Queue16_GrantQueueTask.io_deq_bits_grantid never toggled");
      if (t_Queue16_GrantQueueTask__io_count) tg++; else $display("COV: Queue16_GrantQueueTask.io_count never toggled");
      $display("Queue16_GrantQueueTask: toggled=%0d/10 (need >= 10)", tg);
      if (tg < 10) covfail = 1;
      $display("Queue16_GrantQueueTask: cover full = %0d", cov_Queue16_GrantQueueTask_full);
      if (cov_Queue16_GrantQueueTask_full == 0) covfail = 1;
      $display("Queue16_GrantQueueTask: cover deq = %0d", cov_Queue16_GrantQueueTask_deq);
      if (cov_Queue16_GrantQueueTask_deq == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue16_GrantQueueData__io_deq_bits_data_data) tg++; else $display("COV: Queue16_GrantQueueData.io_deq_bits_data_data never toggled");
      $display("Queue16_GrantQueueData: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("Queue16_GrantQueueData: cover full = %0d", cov_Queue16_GrantQueueData_full);
      if (cov_Queue16_GrantQueueData_full == 0) covfail = 1;
      $display("Queue16_GrantQueueData: cover deq = %0d", cov_Queue16_GrantQueueData_deq);
      if (cov_Queue16_GrantQueueData_deq == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
