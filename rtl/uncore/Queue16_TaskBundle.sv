// Queue16_TaskBundle.sv —— TXDAT 的任务队列：只留下拼 CHI DAT 报文要用的 10 个字段，flow
//
// chisel3 Queue(entries=16, flow=true) 的单态化（父模块 TXDAT）。控制逻辑全在
// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 ram_16x67 行为级
// 存储叶子（16 项 x 67 位，两侧同源 inline）。本文件只做字段拼接/拆分：
//   ram 字（lsb 起）：off[5:0]  corrupt[6:6]  tgtID[17:7]  txnID[29:18]  homeNID[40:30]  dbID[52:41]  chiOpcode[59:53]  resp[62:60]  fwdState[65:63]  traceTag[66:66]
// 另有 84 个 io_enq_bits_* 端口在 golden 里没有被存进 ram（父模块出队时用不到，firtool
// 删掉了存储但保留了端口），这里同样只留端口、不接任何东西。
// golden 285 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue16_TaskBundle) —— scripts/gen_l2_queues.py
module Queue16_TaskBundle (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [2:0] io_enq_bits_channel,
  input  logic [2:0] io_enq_bits_txChannel,
  input  logic [8:0] io_enq_bits_set,
  input  logic [30:0] io_enq_bits_tag,
  input  logic [5:0] io_enq_bits_off,
  input  logic [1:0] io_enq_bits_alias,
  input  logic [43:0] io_enq_bits_vaddr,
  input  logic io_enq_bits_isKeyword,
  input  logic [3:0] io_enq_bits_opcode,
  input  logic [2:0] io_enq_bits_param,
  input  logic [2:0] io_enq_bits_size,
  input  logic [6:0] io_enq_bits_sourceId,
  input  logic [1:0] io_enq_bits_bufIdx,
  input  logic io_enq_bits_needProbeAckData,
  input  logic io_enq_bits_denied,
  input  logic io_enq_bits_corrupt,
  input  logic io_enq_bits_mshrTask,
  input  logic [7:0] io_enq_bits_mshrId,
  input  logic io_enq_bits_aliasTask,
  input  logic io_enq_bits_useProbeData,
  input  logic io_enq_bits_mshrRetry,
  input  logic io_enq_bits_readProbeDataDown,
  input  logic io_enq_bits_fromL2pft,
  input  logic io_enq_bits_needHint,
  input  logic io_enq_bits_dirty,
  input  logic [2:0] io_enq_bits_way,
  input  logic io_enq_bits_meta_dirty,
  input  logic [1:0] io_enq_bits_meta_state,
  input  logic io_enq_bits_meta_clients,
  input  logic [1:0] io_enq_bits_meta_alias,
  input  logic io_enq_bits_meta_prefetch,
  input  logic [2:0] io_enq_bits_meta_prefetchSrc,
  input  logic io_enq_bits_meta_accessed,
  input  logic io_enq_bits_meta_tagErr,
  input  logic io_enq_bits_meta_dataErr,
  input  logic io_enq_bits_metaWen,
  input  logic io_enq_bits_tagWen,
  input  logic io_enq_bits_dsWen,
  input  logic [7:0] io_enq_bits_wayMask,
  input  logic io_enq_bits_replTask,
  input  logic io_enq_bits_cmoTask,
  input  logic io_enq_bits_cmoAll,
  input  logic [4:0] io_enq_bits_reqSource,
  input  logic io_enq_bits_mergeA,
  input  logic [5:0] io_enq_bits_aMergeTask_off,
  input  logic [1:0] io_enq_bits_aMergeTask_alias,
  input  logic [43:0] io_enq_bits_aMergeTask_vaddr,
  input  logic io_enq_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_enq_bits_aMergeTask_opcode,
  input  logic [2:0] io_enq_bits_aMergeTask_param,
  input  logic [6:0] io_enq_bits_aMergeTask_sourceId,
  input  logic io_enq_bits_aMergeTask_meta_dirty,
  input  logic [1:0] io_enq_bits_aMergeTask_meta_state,
  input  logic io_enq_bits_aMergeTask_meta_clients,
  input  logic [1:0] io_enq_bits_aMergeTask_meta_alias,
  input  logic io_enq_bits_aMergeTask_meta_prefetch,
  input  logic [2:0] io_enq_bits_aMergeTask_meta_prefetchSrc,
  input  logic io_enq_bits_aMergeTask_meta_accessed,
  input  logic io_enq_bits_aMergeTask_meta_tagErr,
  input  logic io_enq_bits_aMergeTask_meta_dataErr,
  input  logic io_enq_bits_snpHitRelease,
  input  logic io_enq_bits_snpHitReleaseToInval,
  input  logic io_enq_bits_snpHitReleaseToClean,
  input  logic io_enq_bits_snpHitReleaseWithData,
  input  logic [7:0] io_enq_bits_snpHitReleaseIdx,
  input  logic io_enq_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_enq_bits_snpHitReleaseMeta_state,
  input  logic io_enq_bits_snpHitReleaseMeta_clients,
  input  logic [1:0] io_enq_bits_snpHitReleaseMeta_alias,
  input  logic io_enq_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_enq_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic io_enq_bits_snpHitReleaseMeta_accessed,
  input  logic io_enq_bits_snpHitReleaseMeta_tagErr,
  input  logic io_enq_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_enq_bits_tgtID,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic [11:0] io_enq_bits_txnID,
  input  logic [10:0] io_enq_bits_homeNID,
  input  logic [11:0] io_enq_bits_dbID,
  input  logic [10:0] io_enq_bits_fwdNID,
  input  logic [11:0] io_enq_bits_fwdTxnID,
  input  logic [6:0] io_enq_bits_chiOpcode,
  input  logic [2:0] io_enq_bits_resp,
  input  logic [2:0] io_enq_bits_fwdState,
  input  logic [3:0] io_enq_bits_pCrdType,
  input  logic io_enq_bits_retToSrc,
  input  logic io_enq_bits_likelyshared,
  input  logic io_enq_bits_expCompAck,
  input  logic io_enq_bits_allowRetry,
  input  logic io_enq_bits_memAttr_allocate,
  input  logic io_enq_bits_memAttr_cacheable,
  input  logic io_enq_bits_memAttr_device,
  input  logic io_enq_bits_memAttr_ewa,
  input  logic io_enq_bits_traceTag,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [5:0] io_deq_bits_off,
  output logic io_deq_bits_corrupt,
  output logic [10:0] io_deq_bits_tgtID,
  output logic [11:0] io_deq_bits_txnID,
  output logic [10:0] io_deq_bits_homeNID,
  output logic [11:0] io_deq_bits_dbID,
  output logic [6:0] io_deq_bits_chiOpcode,
  output logic [2:0] io_deq_bits_resp,
  output logic [2:0] io_deq_bits_fwdState,
  output logic io_deq_bits_traceTag,
  output logic [4:0] io_count
);

  logic             do_enq;
  logic [3:0]       enq_ptr, deq_ptr;
  logic             empty;
  logic [4:0]       count;
  logic             enq_ready, deq_valid;
  logic [66:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(16), .FLOW(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (enq_ready),
    .deq_valid (deq_valid),
    .deq_ready (io_deq_ready),
    .do_enq    (do_enq),
    .enq_ptr   (enq_ptr),
    .deq_ptr   (deq_ptr),
    .empty     (empty),
    .count     (count)
  );

  // 存储：写口在 enq_ptr、读口恒使能读 deq_ptr（组合读）
  ram_16x67 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_traceTag, io_enq_bits_fwdState, io_enq_bits_resp, io_enq_bits_chiOpcode, io_enq_bits_dbID, io_enq_bits_homeNID, io_enq_bits_txnID, io_enq_bits_tgtID, io_enq_bits_corrupt, io_enq_bits_off})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;
  assign io_count     = count;
  // flow：队列空时 enq 数据直接旁路到 deq
  assign io_deq_bits_traceTag = empty ? io_enq_bits_traceTag : ramReadWord[66];
  assign io_deq_bits_fwdState = empty ? io_enq_bits_fwdState : ramReadWord[65:63];
  assign io_deq_bits_resp = empty ? io_enq_bits_resp : ramReadWord[62:60];
  assign io_deq_bits_chiOpcode = empty ? io_enq_bits_chiOpcode : ramReadWord[59:53];
  assign io_deq_bits_dbID = empty ? io_enq_bits_dbID : ramReadWord[52:41];
  assign io_deq_bits_homeNID = empty ? io_enq_bits_homeNID : ramReadWord[40:30];
  assign io_deq_bits_txnID = empty ? io_enq_bits_txnID : ramReadWord[29:18];
  assign io_deq_bits_tgtID = empty ? io_enq_bits_tgtID : ramReadWord[17:7];
  assign io_deq_bits_corrupt = empty ? io_enq_bits_corrupt : ramReadWord[6];
  assign io_deq_bits_off = empty ? io_enq_bits_off : ramReadWord[5:0];

endmodule
// END GENERATED(Queue16_TaskBundle)
