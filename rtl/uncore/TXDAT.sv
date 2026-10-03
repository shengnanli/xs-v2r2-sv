// TXDAT.sv —— coupledL2（tl2chi）slice 的 CHI DAT 发送通道：把要写回/转发的整块数据拆成两拍发出去
//
// 对照 coupledL2/src/main/scala/coupledL2/tl2chi/TXDAT.scala。在 Slice 里的位置：
//   MainPipe s3 / MSHR 产生"要走 TXDAT 的任务 + 512 位整块数据"（io_in）→ 本模块缓冲 →
//   以 CHI DAT flit 每拍 256 位发往互联（io_out），同时告诉 RequestArb 还能不能再放请求进来
//   （io_toReqArb，反压）。
//
// 结构：
//   1. 三个 16 项 flow 队列同步入队：queue 存任务（只剩拼报文要用的 10 个字段）、
//      queueData0 / queueData1 各存一个 256 位 beat。三者 enq/deq 永远同拍，所以只用 queue
//      的 ready/valid/count 当权威（两个数据队列的握手口在 golden 里已被 firtool 删掉）。
//   2. 发送寄存器 taskR + 两位 beatValids：队列出一个任务（仅当 beatValids 全 0 时才出队，
//      即上一块发完才取下一块）→ beatValids 置 2'b11；每拍 io_out 握手成功就清掉最低的那一位，
//      按 beat0、beat1 的顺序发。io_out_valid = |beatValids。
//   3. 反压计数：inflightCnt = queue 里的项数 + 流水线 s2~s5 上"即将流进 TXDAT"的任务数（后者模 4，见 §1）；
//      ≥16 挡 SinkB（snoop）入口，≥14 挡 MSHR 入口（留 2 项余量）。
//   4. 报文组装（toCHIDATBundle）：CopyBackWrData 且 resp=I、或 WriteDataCancel 时字节使能全 0、
//      数据也清 0；dataCheck 为逐字节奇校验；poison/respErr 由 corrupt 决定。
//
// 端口单态化说明（KunminghuV2Config）：pipeStatusVec 只剩 _1.._4（= s2..s5；s1 没被用到，firtool 删了）；
// 位字段：toTXDAT = txChannel[2]，fromB = channel[1]。golden 里的 assert 在 `ifndef SYNTHESIS 内，不属于电路。

module xs_TXDAT_core (
  input  logic         clock,
  input  logic         reset,

  // ---- 任务队列出口（queue.io.deq）与两个数据队列出口 ----
  input  logic         taskQ_valid,
  input  logic [4:0]   taskQ_count,
  input  logic [5:0]   taskQ_off,
  input  logic         taskQ_corrupt,
  input  logic [10:0]  taskQ_tgtID,
  input  logic [11:0]  taskQ_txnID,
  input  logic [10:0]  taskQ_homeNID,
  input  logic [11:0]  taskQ_dbID,
  input  logic [6:0]   taskQ_chiOpcode,
  input  logic [2:0]   taskQ_resp,
  input  logic [2:0]   taskQ_fwdState,
  input  logic         taskQ_traceTag,
  input  logic [255:0] dataQ0_beat,
  input  logic [255:0] dataQ1_beat,
  output logic         deqReady,         // 三个队列共用的出队 ready

  // ---- 流水线状态 s2..s5（pipeStatusVec_1.._4）----
  input  logic         ps_valid     [1:4],
  input  logic [2:0]   ps_channel   [1:4],
  input  logic [2:0]   ps_txChannel [1:4],
  input  logic         ps_mshrTask  [1:4],

  // ---- CHI DAT 输出 ----
  input  logic         out_ready,
  output logic         out_valid,
  output logic [10:0]  out_tgtID,
  output logic [11:0]  out_txnID,
  output logic [10:0]  out_homeNID,
  output logic [3:0]   out_opcode,
  output logic [1:0]   out_respErr,
  output logic [2:0]   out_resp,
  output logic [3:0]   out_dataSource,
  output logic [11:0]  out_dbID,
  output logic [1:0]   out_ccID,
  output logic [1:0]   out_dataID,
  output logic         out_traceTag,
  output logic [31:0]  out_be,
  output logic [255:0] out_data,
  output logic [31:0]  out_dataCheck,
  output logic [3:0]   out_poison,

  // ---- 给 RequestArb 的反压 ----
  output logic         blockMSHRReqEntrance,
  output logic         blockSinkBReqEntrance
);

  // CHI DAT opcode（CHI Issue E）
  localparam logic [6:0] CopyBackWrData  = 7'h02;
  localparam logic [6:0] WriteDataCancel = 7'h07;
  localparam logic [2:0] RESP_I          = 3'h0;
  localparam int unsigned MSHRS_ALL      = 16;

  // ===========================================================================
  // §1 反压：在飞计数
  //   s3..s5：valid && toTXDAT && (fromB || mshrTask) —— 这些已经确定要流进来
  //   s2    ：valid && (mshrTask ? toTXDAT : fromB)    —— s2 还没读目录，只能按来源估
  //   再加上队列里已有的项数。
  //   ★bug-for-bug★：Scala 写的是 PopCount(3 路) + PopCount(1 路) —— Chisel 的 `+` 不扩位，
  //   结果只有 max(2,1)=2 位，所以流水线那部分是**模 4** 的：4 个同时在飞时算成 0。
  //   golden（firtool）里就是 2'(2'(a+b) + 2'(c+d))，这里照搬这 2 位截断。
  // ===========================================================================
  logic [1:0] pipeInflight;   // 故意只有 2 位（见上）
  logic [4:0] inflightCnt;

  always_comb begin
    pipeInflight = '0;
    for (int s = 2; s <= 4; s++)
      pipeInflight += 2'(ps_valid[s] & ps_txChannel[s][2] & (ps_channel[s][1] | ps_mshrTask[s]));
    pipeInflight += 2'(ps_valid[1] & (ps_mshrTask[1] ? ps_txChannel[1][2] : ps_channel[1][1]));
  end
  assign inflightCnt = 5'(pipeInflight + taskQ_count);

  assign blockSinkBReqEntrance = inflightCnt >= 5'(MSHRS_ALL);
  assign blockMSHRReqEntrance  = inflightCnt >= 5'(MSHRS_ALL - 2);

  // ===========================================================================
  // §2 发送寄存器：一块数据拆两拍发
  // ===========================================================================
  logic         beatValids [2];     // 还没发出去的 beat（[0] 先发）
  logic         taskValid;          // 正在发某一块
  logic [5:0]   taskR_task_off;
  logic         taskR_task_corrupt;
  logic [10:0]  taskR_task_tgtID;
  logic [11:0]  taskR_task_txnID;
  logic [10:0]  taskR_task_homeNID;
  logic [11:0]  taskR_task_dbID;
  logic [6:0]   taskR_task_chiOpcode;
  logic [2:0]   taskR_task_resp;
  logic [2:0]   taskR_task_fwdState;
  logic         taskR_task_traceTag;
  logic [511:0] taskR_data_data;

  assign taskValid = beatValids[0] | beatValids[1];
  assign deqReady  = ~taskValid;            // 上一块发完才取下一块（有一拍气泡，golden 如此）

  logic takeTask;                           // 本拍从队列取出一个任务
  logic sendBeat;                           // 本拍发出一个 beat
  assign takeTask = deqReady & taskQ_valid;
  assign sendBeat = out_ready & taskValid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      beatValids[0]        <= 1'b0;
      beatValids[1]        <= 1'b0;
      taskR_task_off       <= '0;
      taskR_task_corrupt   <= 1'b0;
      taskR_task_tgtID     <= '0;
      taskR_task_txnID     <= '0;
      taskR_task_homeNID   <= '0;
      taskR_task_dbID      <= '0;
      taskR_task_chiOpcode <= '0;
      taskR_task_resp      <= '0;
      taskR_task_fwdState  <= '0;
      taskR_task_traceTag  <= 1'b0;
      taskR_data_data      <= '0;
    end else begin
      if (sendBeat) begin
        // 清掉最低的那个有效位（PriorityEncoderOH）
        beatValids[0] <= 1'b0;
        beatValids[1] <= beatValids[1] & beatValids[0];
      end else if (takeTask) begin
        beatValids[0] <= 1'b1;
        beatValids[1] <= 1'b1;
      end
      if (takeTask) begin
        taskR_task_off       <= taskQ_off;
        taskR_task_corrupt   <= taskQ_corrupt;
        taskR_task_tgtID     <= taskQ_tgtID;
        taskR_task_txnID     <= taskQ_txnID;
        taskR_task_homeNID   <= taskQ_homeNID;
        taskR_task_dbID      <= taskQ_dbID;
        taskR_task_chiOpcode <= taskQ_chiOpcode;
        taskR_task_resp      <= taskQ_resp;
        taskR_task_fwdState  <= taskQ_fwdState;
        taskR_task_traceTag  <= taskQ_traceTag;
        taskR_data_data      <= {dataQ1_beat, dataQ0_beat};
      end
    end
  end

  // ===========================================================================
  // §3 报文组装（toCHIDATBundle）
  // ===========================================================================
  logic [255:0] beat;          // 本拍要发的 beat：[0] 优先
  logic         deassertBE;    // 这类报文不带有效数据：字节使能与数据全清
  logic [255:0] maskedData;

  assign beat       = beatValids[0] ? taskR_data_data[255:0] : taskR_data_data[511:256];
  assign deassertBE = (taskR_task_chiOpcode == CopyBackWrData && taskR_task_resp == RESP_I)
                    || taskR_task_chiOpcode == WriteDataCancel;
  assign maskedData = deassertBE ? '0 : beat;

  assign out_valid      = taskValid;
  assign out_tgtID      = taskR_task_tgtID;
  assign out_txnID      = taskR_task_txnID;
  assign out_homeNID    = taskR_task_homeNID;
  assign out_dbID       = taskR_task_dbID;
  assign out_opcode     = taskR_task_chiOpcode[3:0];          // CHIDAT 的 opcode 只有 4 位
  assign out_resp       = taskR_task_resp;
  assign out_dataSource = {1'b0, taskR_task_fwdState};         // setFwdState：fwdState 放在 dataSource 低 3 位
  assign out_ccID       = taskR_task_off[5:4];                 // = 原请求地址 [5:4]
  assign out_dataID     = beatValids[0] ? 2'd0 : 2'd2;         // beat0 -> 0，beat1 -> 2（Addr[5:4]）
  assign out_traceTag   = taskR_task_traceTag;
  assign out_respErr    = taskR_task_corrupt ? 2'b10 : 2'b00;  // DERR : OK
  assign out_poison     = {4{taskR_task_corrupt}};
  assign out_be         = {32{~deassertBE}};
  assign out_data       = maskedData;

  // 逐字节奇校验：每个字节的校验位 = ~^byte
  for (genvar i = 0; i < 32; i++) begin : g_check
    assign out_dataCheck[i] = ~(^maskedData[8*i +: 8]);
  end

endmodule

// =============================================================================
// TXDAT —— golden 同名 wrapper：例化三个队列（实例名与 golden 一致）+ 可读核
// =============================================================================
module TXDAT (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [2:0] io_in_bits_task_channel,
  input  logic [2:0] io_in_bits_task_txChannel,
  input  logic [8:0] io_in_bits_task_set,
  input  logic [30:0] io_in_bits_task_tag,
  input  logic [5:0] io_in_bits_task_off,
  input  logic [1:0] io_in_bits_task_alias,
  input  logic [43:0] io_in_bits_task_vaddr,
  input  logic io_in_bits_task_isKeyword,
  input  logic [3:0] io_in_bits_task_opcode,
  input  logic [2:0] io_in_bits_task_param,
  input  logic [2:0] io_in_bits_task_size,
  input  logic [6:0] io_in_bits_task_sourceId,
  input  logic [1:0] io_in_bits_task_bufIdx,
  input  logic io_in_bits_task_needProbeAckData,
  input  logic io_in_bits_task_denied,
  input  logic io_in_bits_task_corrupt,
  input  logic io_in_bits_task_mshrTask,
  input  logic [7:0] io_in_bits_task_mshrId,
  input  logic io_in_bits_task_aliasTask,
  input  logic io_in_bits_task_useProbeData,
  input  logic io_in_bits_task_mshrRetry,
  input  logic io_in_bits_task_readProbeDataDown,
  input  logic io_in_bits_task_fromL2pft,
  input  logic io_in_bits_task_needHint,
  input  logic io_in_bits_task_dirty,
  input  logic [2:0] io_in_bits_task_way,
  input  logic io_in_bits_task_meta_dirty,
  input  logic [1:0] io_in_bits_task_meta_state,
  input  logic io_in_bits_task_meta_clients,
  input  logic [1:0] io_in_bits_task_meta_alias,
  input  logic io_in_bits_task_meta_prefetch,
  input  logic [2:0] io_in_bits_task_meta_prefetchSrc,
  input  logic io_in_bits_task_meta_accessed,
  input  logic io_in_bits_task_meta_tagErr,
  input  logic io_in_bits_task_meta_dataErr,
  input  logic io_in_bits_task_metaWen,
  input  logic io_in_bits_task_tagWen,
  input  logic io_in_bits_task_dsWen,
  input  logic [7:0] io_in_bits_task_wayMask,
  input  logic io_in_bits_task_replTask,
  input  logic io_in_bits_task_cmoTask,
  input  logic io_in_bits_task_cmoAll,
  input  logic [4:0] io_in_bits_task_reqSource,
  input  logic io_in_bits_task_mergeA,
  input  logic [5:0] io_in_bits_task_aMergeTask_off,
  input  logic [1:0] io_in_bits_task_aMergeTask_alias,
  input  logic [43:0] io_in_bits_task_aMergeTask_vaddr,
  input  logic io_in_bits_task_aMergeTask_isKeyword,
  input  logic [2:0] io_in_bits_task_aMergeTask_opcode,
  input  logic [2:0] io_in_bits_task_aMergeTask_param,
  input  logic [6:0] io_in_bits_task_aMergeTask_sourceId,
  input  logic io_in_bits_task_aMergeTask_meta_dirty,
  input  logic [1:0] io_in_bits_task_aMergeTask_meta_state,
  input  logic io_in_bits_task_aMergeTask_meta_clients,
  input  logic [1:0] io_in_bits_task_aMergeTask_meta_alias,
  input  logic io_in_bits_task_aMergeTask_meta_prefetch,
  input  logic [2:0] io_in_bits_task_aMergeTask_meta_prefetchSrc,
  input  logic io_in_bits_task_aMergeTask_meta_accessed,
  input  logic io_in_bits_task_aMergeTask_meta_tagErr,
  input  logic io_in_bits_task_aMergeTask_meta_dataErr,
  input  logic io_in_bits_task_snpHitRelease,
  input  logic io_in_bits_task_snpHitReleaseToInval,
  input  logic io_in_bits_task_snpHitReleaseToClean,
  input  logic io_in_bits_task_snpHitReleaseWithData,
  input  logic [7:0] io_in_bits_task_snpHitReleaseIdx,
  input  logic io_in_bits_task_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_in_bits_task_snpHitReleaseMeta_state,
  input  logic io_in_bits_task_snpHitReleaseMeta_clients,
  input  logic [1:0] io_in_bits_task_snpHitReleaseMeta_alias,
  input  logic io_in_bits_task_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_in_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  logic io_in_bits_task_snpHitReleaseMeta_accessed,
  input  logic io_in_bits_task_snpHitReleaseMeta_tagErr,
  input  logic io_in_bits_task_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_in_bits_task_tgtID,
  input  logic [10:0] io_in_bits_task_srcID,
  input  logic [11:0] io_in_bits_task_txnID,
  input  logic [10:0] io_in_bits_task_homeNID,
  input  logic [11:0] io_in_bits_task_dbID,
  input  logic [10:0] io_in_bits_task_fwdNID,
  input  logic [11:0] io_in_bits_task_fwdTxnID,
  input  logic [6:0] io_in_bits_task_chiOpcode,
  input  logic [2:0] io_in_bits_task_resp,
  input  logic [2:0] io_in_bits_task_fwdState,
  input  logic [3:0] io_in_bits_task_pCrdType,
  input  logic io_in_bits_task_retToSrc,
  input  logic io_in_bits_task_likelyshared,
  input  logic io_in_bits_task_expCompAck,
  input  logic io_in_bits_task_allowRetry,
  input  logic io_in_bits_task_memAttr_allocate,
  input  logic io_in_bits_task_memAttr_cacheable,
  input  logic io_in_bits_task_memAttr_device,
  input  logic io_in_bits_task_memAttr_ewa,
  input  logic io_in_bits_task_traceTag,
  input  logic [511:0] io_in_bits_data_data,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [10:0] io_out_bits_tgtID,
  output logic [11:0] io_out_bits_txnID,
  output logic [10:0] io_out_bits_homeNID,
  output logic [3:0] io_out_bits_opcode,
  output logic [1:0] io_out_bits_respErr,
  output logic [2:0] io_out_bits_resp,
  output logic [3:0] io_out_bits_dataSource,
  output logic [11:0] io_out_bits_dbID,
  output logic [1:0] io_out_bits_ccID,
  output logic [1:0] io_out_bits_dataID,
  output logic io_out_bits_traceTag,
  output logic [31:0] io_out_bits_be,
  output logic [255:0] io_out_bits_data,
  output logic [31:0] io_out_bits_dataCheck,
  output logic [3:0] io_out_bits_poison,
  input  logic io_pipeStatusVec_1_valid,
  input  logic [2:0] io_pipeStatusVec_1_bits_channel,
  input  logic [2:0] io_pipeStatusVec_1_bits_txChannel,
  input  logic io_pipeStatusVec_1_bits_mshrTask,
  input  logic io_pipeStatusVec_2_valid,
  input  logic [2:0] io_pipeStatusVec_2_bits_channel,
  input  logic [2:0] io_pipeStatusVec_2_bits_txChannel,
  input  logic io_pipeStatusVec_2_bits_mshrTask,
  input  logic io_pipeStatusVec_3_valid,
  input  logic [2:0] io_pipeStatusVec_3_bits_channel,
  input  logic [2:0] io_pipeStatusVec_3_bits_txChannel,
  input  logic io_pipeStatusVec_3_bits_mshrTask,
  input  logic io_pipeStatusVec_4_valid,
  input  logic [2:0] io_pipeStatusVec_4_bits_channel,
  input  logic [2:0] io_pipeStatusVec_4_bits_txChannel,
  input  logic io_pipeStatusVec_4_bits_mshrTask,
  output logic io_toReqArb_blockMSHRReqEntrance,
  output logic io_toReqArb_blockSinkBReqEntrance
);

  logic         deqReady;
  logic         taskQ_valid;
  logic [4:0]   taskQ_count;
  logic [5:0]   taskQ_off;
  logic         taskQ_corrupt;
  logic [10:0]  taskQ_tgtID;
  logic [11:0]  taskQ_txnID;
  logic [10:0]  taskQ_homeNID;
  logic [11:0]  taskQ_dbID;
  logic [6:0]   taskQ_chiOpcode;
  logic [2:0]   taskQ_resp;
  logic [2:0]   taskQ_fwdState;
  logic         taskQ_traceTag;
  logic [255:0] dataQ0_beat;
  logic [255:0] dataQ1_beat;

  // 任务队列：整条 TaskBundle 入队（端口全留），出队只剩 10 个字段
  Queue16_TaskBundle queue (
    .clock                                         (clock),
    .reset                                         (reset),
    .io_enq_ready                                  (io_in_ready),
    .io_enq_valid                                  (io_in_valid),
    .io_enq_bits_channel                           (io_in_bits_task_channel),
    .io_enq_bits_txChannel                         (io_in_bits_task_txChannel),
    .io_enq_bits_set                               (io_in_bits_task_set),
    .io_enq_bits_tag                               (io_in_bits_task_tag),
    .io_enq_bits_off                               (io_in_bits_task_off),
    .io_enq_bits_alias                             (io_in_bits_task_alias),
    .io_enq_bits_vaddr                             (io_in_bits_task_vaddr),
    .io_enq_bits_isKeyword                         (io_in_bits_task_isKeyword),
    .io_enq_bits_opcode                            (io_in_bits_task_opcode),
    .io_enq_bits_param                             (io_in_bits_task_param),
    .io_enq_bits_size                              (io_in_bits_task_size),
    .io_enq_bits_sourceId                          (io_in_bits_task_sourceId),
    .io_enq_bits_bufIdx                            (io_in_bits_task_bufIdx),
    .io_enq_bits_needProbeAckData                  (io_in_bits_task_needProbeAckData),
    .io_enq_bits_denied                            (io_in_bits_task_denied),
    .io_enq_bits_corrupt                           (io_in_bits_task_corrupt),
    .io_enq_bits_mshrTask                          (io_in_bits_task_mshrTask),
    .io_enq_bits_mshrId                            (io_in_bits_task_mshrId),
    .io_enq_bits_aliasTask                         (io_in_bits_task_aliasTask),
    .io_enq_bits_useProbeData                      (io_in_bits_task_useProbeData),
    .io_enq_bits_mshrRetry                         (io_in_bits_task_mshrRetry),
    .io_enq_bits_readProbeDataDown                 (io_in_bits_task_readProbeDataDown),
    .io_enq_bits_fromL2pft                         (io_in_bits_task_fromL2pft),
    .io_enq_bits_needHint                          (io_in_bits_task_needHint),
    .io_enq_bits_dirty                             (io_in_bits_task_dirty),
    .io_enq_bits_way                               (io_in_bits_task_way),
    .io_enq_bits_meta_dirty                        (io_in_bits_task_meta_dirty),
    .io_enq_bits_meta_state                        (io_in_bits_task_meta_state),
    .io_enq_bits_meta_clients                      (io_in_bits_task_meta_clients),
    .io_enq_bits_meta_alias                        (io_in_bits_task_meta_alias),
    .io_enq_bits_meta_prefetch                     (io_in_bits_task_meta_prefetch),
    .io_enq_bits_meta_prefetchSrc                  (io_in_bits_task_meta_prefetchSrc),
    .io_enq_bits_meta_accessed                     (io_in_bits_task_meta_accessed),
    .io_enq_bits_meta_tagErr                       (io_in_bits_task_meta_tagErr),
    .io_enq_bits_meta_dataErr                      (io_in_bits_task_meta_dataErr),
    .io_enq_bits_metaWen                           (io_in_bits_task_metaWen),
    .io_enq_bits_tagWen                            (io_in_bits_task_tagWen),
    .io_enq_bits_dsWen                             (io_in_bits_task_dsWen),
    .io_enq_bits_wayMask                           (io_in_bits_task_wayMask),
    .io_enq_bits_replTask                          (io_in_bits_task_replTask),
    .io_enq_bits_cmoTask                           (io_in_bits_task_cmoTask),
    .io_enq_bits_cmoAll                            (io_in_bits_task_cmoAll),
    .io_enq_bits_reqSource                         (io_in_bits_task_reqSource),
    .io_enq_bits_mergeA                            (io_in_bits_task_mergeA),
    .io_enq_bits_aMergeTask_off                    (io_in_bits_task_aMergeTask_off),
    .io_enq_bits_aMergeTask_alias                  (io_in_bits_task_aMergeTask_alias),
    .io_enq_bits_aMergeTask_vaddr                  (io_in_bits_task_aMergeTask_vaddr),
    .io_enq_bits_aMergeTask_isKeyword              (io_in_bits_task_aMergeTask_isKeyword),
    .io_enq_bits_aMergeTask_opcode                 (io_in_bits_task_aMergeTask_opcode),
    .io_enq_bits_aMergeTask_param                  (io_in_bits_task_aMergeTask_param),
    .io_enq_bits_aMergeTask_sourceId               (io_in_bits_task_aMergeTask_sourceId),
    .io_enq_bits_aMergeTask_meta_dirty             (io_in_bits_task_aMergeTask_meta_dirty),
    .io_enq_bits_aMergeTask_meta_state             (io_in_bits_task_aMergeTask_meta_state),
    .io_enq_bits_aMergeTask_meta_clients           (io_in_bits_task_aMergeTask_meta_clients),
    .io_enq_bits_aMergeTask_meta_alias             (io_in_bits_task_aMergeTask_meta_alias),
    .io_enq_bits_aMergeTask_meta_prefetch          (io_in_bits_task_aMergeTask_meta_prefetch),
    .io_enq_bits_aMergeTask_meta_prefetchSrc       (io_in_bits_task_aMergeTask_meta_prefetchSrc),
    .io_enq_bits_aMergeTask_meta_accessed          (io_in_bits_task_aMergeTask_meta_accessed),
    .io_enq_bits_aMergeTask_meta_tagErr            (io_in_bits_task_aMergeTask_meta_tagErr),
    .io_enq_bits_aMergeTask_meta_dataErr           (io_in_bits_task_aMergeTask_meta_dataErr),
    .io_enq_bits_snpHitRelease                     (io_in_bits_task_snpHitRelease),
    .io_enq_bits_snpHitReleaseToInval              (io_in_bits_task_snpHitReleaseToInval),
    .io_enq_bits_snpHitReleaseToClean              (io_in_bits_task_snpHitReleaseToClean),
    .io_enq_bits_snpHitReleaseWithData             (io_in_bits_task_snpHitReleaseWithData),
    .io_enq_bits_snpHitReleaseIdx                  (io_in_bits_task_snpHitReleaseIdx),
    .io_enq_bits_snpHitReleaseMeta_dirty           (io_in_bits_task_snpHitReleaseMeta_dirty),
    .io_enq_bits_snpHitReleaseMeta_state           (io_in_bits_task_snpHitReleaseMeta_state),
    .io_enq_bits_snpHitReleaseMeta_clients         (io_in_bits_task_snpHitReleaseMeta_clients),
    .io_enq_bits_snpHitReleaseMeta_alias           (io_in_bits_task_snpHitReleaseMeta_alias),
    .io_enq_bits_snpHitReleaseMeta_prefetch        (io_in_bits_task_snpHitReleaseMeta_prefetch),
    .io_enq_bits_snpHitReleaseMeta_prefetchSrc     (io_in_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_snpHitReleaseMeta_accessed        (io_in_bits_task_snpHitReleaseMeta_accessed),
    .io_enq_bits_snpHitReleaseMeta_tagErr          (io_in_bits_task_snpHitReleaseMeta_tagErr),
    .io_enq_bits_snpHitReleaseMeta_dataErr         (io_in_bits_task_snpHitReleaseMeta_dataErr),
    .io_enq_bits_tgtID                             (io_in_bits_task_tgtID),
    .io_enq_bits_srcID                             (io_in_bits_task_srcID),
    .io_enq_bits_txnID                             (io_in_bits_task_txnID),
    .io_enq_bits_homeNID                           (io_in_bits_task_homeNID),
    .io_enq_bits_dbID                              (io_in_bits_task_dbID),
    .io_enq_bits_fwdNID                            (io_in_bits_task_fwdNID),
    .io_enq_bits_fwdTxnID                          (io_in_bits_task_fwdTxnID),
    .io_enq_bits_chiOpcode                         (io_in_bits_task_chiOpcode),
    .io_enq_bits_resp                              (io_in_bits_task_resp),
    .io_enq_bits_fwdState                          (io_in_bits_task_fwdState),
    .io_enq_bits_pCrdType                          (io_in_bits_task_pCrdType),
    .io_enq_bits_retToSrc                          (io_in_bits_task_retToSrc),
    .io_enq_bits_likelyshared                      (io_in_bits_task_likelyshared),
    .io_enq_bits_expCompAck                        (io_in_bits_task_expCompAck),
    .io_enq_bits_allowRetry                        (io_in_bits_task_allowRetry),
    .io_enq_bits_memAttr_allocate                  (io_in_bits_task_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable                 (io_in_bits_task_memAttr_cacheable),
    .io_enq_bits_memAttr_device                    (io_in_bits_task_memAttr_device),
    .io_enq_bits_memAttr_ewa                       (io_in_bits_task_memAttr_ewa),
    .io_enq_bits_traceTag                          (io_in_bits_task_traceTag),
    .io_deq_ready                                  (deqReady),
    .io_deq_valid                                  (taskQ_valid),
    .io_deq_bits_off                               (taskQ_off),
    .io_deq_bits_corrupt                           (taskQ_corrupt),
    .io_deq_bits_tgtID                             (taskQ_tgtID),
    .io_deq_bits_txnID                             (taskQ_txnID),
    .io_deq_bits_homeNID                           (taskQ_homeNID),
    .io_deq_bits_dbID                              (taskQ_dbID),
    .io_deq_bits_chiOpcode                         (taskQ_chiOpcode),
    .io_deq_bits_resp                              (taskQ_resp),
    .io_deq_bits_fwdState                          (taskQ_fwdState),
    .io_deq_bits_traceTag                          (taskQ_traceTag),
    .io_count                                      (taskQ_count)
  );

  // 两个数据队列：各存 512 位整块的一半
  Queue16_DSBeat queueData0 (
    .clock            (clock),
    .reset            (reset),
    .io_enq_valid     (io_in_valid),
    .io_enq_bits_data (io_in_bits_data_data[255:0]),
    .io_deq_ready     (deqReady),
    .io_deq_bits_data (dataQ0_beat)
  );
  Queue16_DSBeat queueData1 (
    .clock            (clock),
    .reset            (reset),
    .io_enq_valid     (io_in_valid),
    .io_enq_bits_data (io_in_bits_data_data[511:256]),
    .io_deq_ready     (deqReady),
    .io_deq_bits_data (dataQ1_beat)
  );

  xs_TXDAT_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .taskQ_valid           (taskQ_valid),
    .taskQ_count           (taskQ_count),
    .taskQ_off             (taskQ_off),
    .taskQ_corrupt         (taskQ_corrupt),
    .taskQ_tgtID           (taskQ_tgtID),
    .taskQ_txnID           (taskQ_txnID),
    .taskQ_homeNID         (taskQ_homeNID),
    .taskQ_dbID            (taskQ_dbID),
    .taskQ_chiOpcode       (taskQ_chiOpcode),
    .taskQ_resp            (taskQ_resp),
    .taskQ_fwdState        (taskQ_fwdState),
    .taskQ_traceTag        (taskQ_traceTag),
    .dataQ0_beat           (dataQ0_beat),
    .dataQ1_beat           (dataQ1_beat),
    .deqReady              (deqReady),
    .ps_valid              ('{io_pipeStatusVec_1_valid, io_pipeStatusVec_2_valid,
                              io_pipeStatusVec_3_valid, io_pipeStatusVec_4_valid}),
    .ps_channel            ('{io_pipeStatusVec_1_bits_channel, io_pipeStatusVec_2_bits_channel,
                              io_pipeStatusVec_3_bits_channel, io_pipeStatusVec_4_bits_channel}),
    .ps_txChannel          ('{io_pipeStatusVec_1_bits_txChannel, io_pipeStatusVec_2_bits_txChannel,
                              io_pipeStatusVec_3_bits_txChannel, io_pipeStatusVec_4_bits_txChannel}),
    .ps_mshrTask           ('{io_pipeStatusVec_1_bits_mshrTask, io_pipeStatusVec_2_bits_mshrTask,
                              io_pipeStatusVec_3_bits_mshrTask, io_pipeStatusVec_4_bits_mshrTask}),
    .out_ready             (io_out_ready),
    .out_valid             (io_out_valid),
    .out_tgtID             (io_out_bits_tgtID),
    .out_txnID             (io_out_bits_txnID),
    .out_homeNID           (io_out_bits_homeNID),
    .out_opcode            (io_out_bits_opcode),
    .out_respErr           (io_out_bits_respErr),
    .out_resp              (io_out_bits_resp),
    .out_dataSource        (io_out_bits_dataSource),
    .out_dbID              (io_out_bits_dbID),
    .out_ccID              (io_out_bits_ccID),
    .out_dataID            (io_out_bits_dataID),
    .out_traceTag          (io_out_bits_traceTag),
    .out_be                (io_out_bits_be),
    .out_data              (io_out_bits_data),
    .out_dataCheck         (io_out_bits_dataCheck),
    .out_poison            (io_out_bits_poison),
    .blockMSHRReqEntrance  (io_toReqArb_blockMSHRReqEntrance),
    .blockSinkBReqEntrance (io_toReqArb_blockSinkBReqEntrance)
  );

endmodule
