// Queue16_GrantQueueTask.sv —— GrantBuffer 的 grant 任务队列（D 通道报文头）
//
// chisel3 Queue(entries=16, flow=false) 的单态化（父模块 GrantBuffer）。控制逻辑全在
// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 ram_16x25 行为级
// 存储叶子（16 项 x 25 位，两侧同源 inline）。本文件只做字段拼接/拆分：
//   ram 字（lsb 起）：task_isKeyword[0:0]  task_opcode[4:1]  task_param[7:5]  task_sourceId[14:8]  task_denied[15:15]  task_corrupt[16:16]  grantid[24:17]
// 另有 88 个 io_enq_bits_* 端口在 golden 里没有被存进 ram（父模块出队时用不到，firtool
// 删掉了存储但保留了端口），这里同样只留端口、不接任何东西。
// golden 276 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue16_GrantQueueTask) —— scripts/gen_l2_queues.py
module Queue16_GrantQueueTask (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [2:0] io_enq_bits_task_channel,
  input  logic [2:0] io_enq_bits_task_txChannel,
  input  logic [8:0] io_enq_bits_task_set,
  input  logic [30:0] io_enq_bits_task_tag,
  input  logic [5:0] io_enq_bits_task_off,
  input  logic [1:0] io_enq_bits_task_alias,
  input  logic [43:0] io_enq_bits_task_vaddr,
  input  logic io_enq_bits_task_isKeyword,
  input  logic [3:0] io_enq_bits_task_opcode,
  input  logic [2:0] io_enq_bits_task_param,
  input  logic [2:0] io_enq_bits_task_size,
  input  logic [6:0] io_enq_bits_task_sourceId,
  input  logic [1:0] io_enq_bits_task_bufIdx,
  input  logic io_enq_bits_task_needProbeAckData,
  input  logic io_enq_bits_task_denied,
  input  logic io_enq_bits_task_corrupt,
  input  logic io_enq_bits_task_mshrTask,
  input  logic [7:0] io_enq_bits_task_mshrId,
  input  logic io_enq_bits_task_aliasTask,
  input  logic io_enq_bits_task_useProbeData,
  input  logic io_enq_bits_task_mshrRetry,
  input  logic io_enq_bits_task_readProbeDataDown,
  input  logic io_enq_bits_task_fromL2pft,
  input  logic io_enq_bits_task_needHint,
  input  logic io_enq_bits_task_dirty,
  input  logic [2:0] io_enq_bits_task_way,
  input  logic io_enq_bits_task_meta_dirty,
  input  logic [1:0] io_enq_bits_task_meta_state,
  input  logic io_enq_bits_task_meta_clients,
  input  logic [1:0] io_enq_bits_task_meta_alias,
  input  logic io_enq_bits_task_meta_prefetch,
  input  logic [2:0] io_enq_bits_task_meta_prefetchSrc,
  input  logic io_enq_bits_task_meta_accessed,
  input  logic io_enq_bits_task_meta_tagErr,
  input  logic io_enq_bits_task_meta_dataErr,
  input  logic io_enq_bits_task_metaWen,
  input  logic io_enq_bits_task_tagWen,
  input  logic io_enq_bits_task_dsWen,
  input  logic [7:0] io_enq_bits_task_wayMask,
  input  logic io_enq_bits_task_replTask,
  input  logic io_enq_bits_task_cmoTask,
  input  logic io_enq_bits_task_cmoAll,
  input  logic [4:0] io_enq_bits_task_reqSource,
  input  logic io_enq_bits_task_mergeA,
  input  logic [5:0] io_enq_bits_task_aMergeTask_off,
  input  logic [1:0] io_enq_bits_task_aMergeTask_alias,
  input  logic [43:0] io_enq_bits_task_aMergeTask_vaddr,
  input  logic io_enq_bits_task_aMergeTask_isKeyword,
  input  logic [2:0] io_enq_bits_task_aMergeTask_opcode,
  input  logic [2:0] io_enq_bits_task_aMergeTask_param,
  input  logic [6:0] io_enq_bits_task_aMergeTask_sourceId,
  input  logic io_enq_bits_task_aMergeTask_meta_dirty,
  input  logic [1:0] io_enq_bits_task_aMergeTask_meta_state,
  input  logic io_enq_bits_task_aMergeTask_meta_clients,
  input  logic [1:0] io_enq_bits_task_aMergeTask_meta_alias,
  input  logic io_enq_bits_task_aMergeTask_meta_prefetch,
  input  logic [2:0] io_enq_bits_task_aMergeTask_meta_prefetchSrc,
  input  logic io_enq_bits_task_aMergeTask_meta_accessed,
  input  logic io_enq_bits_task_aMergeTask_meta_tagErr,
  input  logic io_enq_bits_task_aMergeTask_meta_dataErr,
  input  logic io_enq_bits_task_snpHitRelease,
  input  logic io_enq_bits_task_snpHitReleaseToInval,
  input  logic io_enq_bits_task_snpHitReleaseToClean,
  input  logic io_enq_bits_task_snpHitReleaseWithData,
  input  logic [7:0] io_enq_bits_task_snpHitReleaseIdx,
  input  logic io_enq_bits_task_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_enq_bits_task_snpHitReleaseMeta_state,
  input  logic io_enq_bits_task_snpHitReleaseMeta_clients,
  input  logic [1:0] io_enq_bits_task_snpHitReleaseMeta_alias,
  input  logic io_enq_bits_task_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_enq_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  logic io_enq_bits_task_snpHitReleaseMeta_accessed,
  input  logic io_enq_bits_task_snpHitReleaseMeta_tagErr,
  input  logic io_enq_bits_task_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_enq_bits_task_tgtID,
  input  logic [10:0] io_enq_bits_task_srcID,
  input  logic [11:0] io_enq_bits_task_txnID,
  input  logic [10:0] io_enq_bits_task_homeNID,
  input  logic [11:0] io_enq_bits_task_dbID,
  input  logic [10:0] io_enq_bits_task_fwdNID,
  input  logic [11:0] io_enq_bits_task_fwdTxnID,
  input  logic [6:0] io_enq_bits_task_chiOpcode,
  input  logic [2:0] io_enq_bits_task_resp,
  input  logic [2:0] io_enq_bits_task_fwdState,
  input  logic [3:0] io_enq_bits_task_pCrdType,
  input  logic io_enq_bits_task_retToSrc,
  input  logic io_enq_bits_task_likelyshared,
  input  logic io_enq_bits_task_expCompAck,
  input  logic io_enq_bits_task_allowRetry,
  input  logic io_enq_bits_task_memAttr_allocate,
  input  logic io_enq_bits_task_memAttr_cacheable,
  input  logic io_enq_bits_task_memAttr_device,
  input  logic io_enq_bits_task_memAttr_ewa,
  input  logic io_enq_bits_task_traceTag,
  input  logic [7:0] io_enq_bits_grantid,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic io_deq_bits_task_isKeyword,
  output logic [3:0] io_deq_bits_task_opcode,
  output logic [2:0] io_deq_bits_task_param,
  output logic [6:0] io_deq_bits_task_sourceId,
  output logic io_deq_bits_task_denied,
  output logic io_deq_bits_task_corrupt,
  output logic [7:0] io_deq_bits_grantid,
  output logic [4:0] io_count
);

  logic             do_enq;
  logic [3:0]       enq_ptr, deq_ptr;
  logic             empty;
  logic [4:0]       count;
  logic             enq_ready, deq_valid;
  logic [24:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(16), .FLOW(1'b0)) u_core (
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
  ram_16x25 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_grantid, io_enq_bits_task_corrupt, io_enq_bits_task_denied, io_enq_bits_task_sourceId, io_enq_bits_task_param, io_enq_bits_task_opcode, io_enq_bits_task_isKeyword})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;
  assign io_count     = count;
  assign io_deq_bits_grantid = ramReadWord[24:17];
  assign io_deq_bits_task_corrupt = ramReadWord[16];
  assign io_deq_bits_task_denied = ramReadWord[15];
  assign io_deq_bits_task_sourceId = ramReadWord[14:8];
  assign io_deq_bits_task_param = ramReadWord[7:5];
  assign io_deq_bits_task_opcode = ramReadWord[4:1];
  assign io_deq_bits_task_isKeyword = ramReadWord[0];

endmodule
// END GENERATED(Queue16_GrantQueueTask)
