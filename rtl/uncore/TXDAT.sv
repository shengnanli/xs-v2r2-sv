// =============================================================================
//  TXDAT —— coupledL2 (tl2chi) CHI DAT 发送通道 可读重写核 (xs_TXDAT_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/tl2chi/TXDAT.scala
//  把一条携带整行 (512b = 2 个 256b beat) 数据的流水任务先进三条 16 深 FIFO
//  (Queue16_TaskBundle 存头部 + 两个 Queue16_DSBeat 各存一个 beat, 均本核黑盒),
//  再经单条目 2-beat 输出缓冲逐 beat 发往 CHI 互联; 并按在飞计数对 ReqArb 反压。
//
//  ===== 在飞计数 inflightCnt (同 TXRSP, 2 位截位; toTXDAT=txChannel[2], fromB=channel[1]) =====
//    s3~s5: valid & toTXDAT & (fromB | mshrTask)
//    s2   : valid & (mshrTask ? toTXDAT : fromB)
//    pipe_cnt = (上述四项之和) 截到 2 位 (4 回绕 0); inflightCnt = pipe_cnt + queueCnt
//    blockMSHRReqEntrance = inflightCnt > 13 ; blockSinkBReqEntrance = inflightCnt[4] (>=16)
//
//  ===== 输出 2-beat 缓冲 =====
//    缓冲空(beatsOH==0)且头队列有数据 ⇒ load_buffer: 一次载入整行(两 beat 全有效)+ 头部锁存。
//    out_ready 时逐 beat 发出: 先 beat0(低 256b) 后 beat1(高 256b); dataID={~beat0_valid,0}。
//    deassertBE: 特定 opcode/resp 组合下 BE 全 0 且数据清零 (CHI 无数据写)。
//    dataCheck: 每字节输出 ~(该字节奇偶); poison/respErr 由 corrupt 展开。
// =============================================================================
module xs_TXDAT_core(
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [2:0]   io_in_bits_task_channel,
  input  [2:0]   io_in_bits_task_txChannel,
  input  [8:0]   io_in_bits_task_set,
  input  [30:0]  io_in_bits_task_tag,
  input  [5:0]   io_in_bits_task_off,
  input  [1:0]   io_in_bits_task_alias,
  input  [43:0]  io_in_bits_task_vaddr,
  input          io_in_bits_task_isKeyword,
  input  [3:0]   io_in_bits_task_opcode,
  input  [2:0]   io_in_bits_task_param,
  input  [2:0]   io_in_bits_task_size,
  input  [6:0]   io_in_bits_task_sourceId,
  input  [1:0]   io_in_bits_task_bufIdx,
  input          io_in_bits_task_needProbeAckData,
  input          io_in_bits_task_denied,
  input          io_in_bits_task_corrupt,
  input          io_in_bits_task_mshrTask,
  input  [7:0]   io_in_bits_task_mshrId,
  input          io_in_bits_task_aliasTask,
  input          io_in_bits_task_useProbeData,
  input          io_in_bits_task_mshrRetry,
  input          io_in_bits_task_readProbeDataDown,
  input          io_in_bits_task_fromL2pft,
  input          io_in_bits_task_needHint,
  input          io_in_bits_task_dirty,
  input  [2:0]   io_in_bits_task_way,
  input          io_in_bits_task_meta_dirty,
  input  [1:0]   io_in_bits_task_meta_state,
  input          io_in_bits_task_meta_clients,
  input  [1:0]   io_in_bits_task_meta_alias,
  input          io_in_bits_task_meta_prefetch,
  input  [2:0]   io_in_bits_task_meta_prefetchSrc,
  input          io_in_bits_task_meta_accessed,
  input          io_in_bits_task_meta_tagErr,
  input          io_in_bits_task_meta_dataErr,
  input          io_in_bits_task_metaWen,
  input          io_in_bits_task_tagWen,
  input          io_in_bits_task_dsWen,
  input  [7:0]   io_in_bits_task_wayMask,
  input          io_in_bits_task_replTask,
  input          io_in_bits_task_cmoTask,
  input          io_in_bits_task_cmoAll,
  input  [4:0]   io_in_bits_task_reqSource,
  input          io_in_bits_task_mergeA,
  input  [5:0]   io_in_bits_task_aMergeTask_off,
  input  [1:0]   io_in_bits_task_aMergeTask_alias,
  input  [43:0]  io_in_bits_task_aMergeTask_vaddr,
  input          io_in_bits_task_aMergeTask_isKeyword,
  input  [2:0]   io_in_bits_task_aMergeTask_opcode,
  input  [2:0]   io_in_bits_task_aMergeTask_param,
  input  [6:0]   io_in_bits_task_aMergeTask_sourceId,
  input          io_in_bits_task_aMergeTask_meta_dirty,
  input  [1:0]   io_in_bits_task_aMergeTask_meta_state,
  input          io_in_bits_task_aMergeTask_meta_clients,
  input  [1:0]   io_in_bits_task_aMergeTask_meta_alias,
  input          io_in_bits_task_aMergeTask_meta_prefetch,
  input  [2:0]   io_in_bits_task_aMergeTask_meta_prefetchSrc,
  input          io_in_bits_task_aMergeTask_meta_accessed,
  input          io_in_bits_task_aMergeTask_meta_tagErr,
  input          io_in_bits_task_aMergeTask_meta_dataErr,
  input          io_in_bits_task_snpHitRelease,
  input          io_in_bits_task_snpHitReleaseToInval,
  input          io_in_bits_task_snpHitReleaseToClean,
  input          io_in_bits_task_snpHitReleaseWithData,
  input  [7:0]   io_in_bits_task_snpHitReleaseIdx,
  input          io_in_bits_task_snpHitReleaseMeta_dirty,
  input  [1:0]   io_in_bits_task_snpHitReleaseMeta_state,
  input          io_in_bits_task_snpHitReleaseMeta_clients,
  input  [1:0]   io_in_bits_task_snpHitReleaseMeta_alias,
  input          io_in_bits_task_snpHitReleaseMeta_prefetch,
  input  [2:0]   io_in_bits_task_snpHitReleaseMeta_prefetchSrc,
  input          io_in_bits_task_snpHitReleaseMeta_accessed,
  input          io_in_bits_task_snpHitReleaseMeta_tagErr,
  input          io_in_bits_task_snpHitReleaseMeta_dataErr,
  input  [10:0]  io_in_bits_task_tgtID,
  input  [10:0]  io_in_bits_task_srcID,
  input  [11:0]  io_in_bits_task_txnID,
  input  [10:0]  io_in_bits_task_homeNID,
  input  [11:0]  io_in_bits_task_dbID,
  input  [10:0]  io_in_bits_task_fwdNID,
  input  [11:0]  io_in_bits_task_fwdTxnID,
  input  [6:0]   io_in_bits_task_chiOpcode,
  input  [2:0]   io_in_bits_task_resp,
  input  [2:0]   io_in_bits_task_fwdState,
  input  [3:0]   io_in_bits_task_pCrdType,
  input          io_in_bits_task_retToSrc,
  input          io_in_bits_task_likelyshared,
  input          io_in_bits_task_expCompAck,
  input          io_in_bits_task_allowRetry,
  input          io_in_bits_task_memAttr_allocate,
  input          io_in_bits_task_memAttr_cacheable,
  input          io_in_bits_task_memAttr_device,
  input          io_in_bits_task_memAttr_ewa,
  input          io_in_bits_task_traceTag,
  input          io_in_bits_task_dataCheckErr,
  input  [511:0] io_in_bits_data_data,
  input          io_out_ready,
  output         io_out_valid,
  output [10:0]  io_out_bits_tgtID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_homeNID,
  output [3:0]   io_out_bits_opcode,
  output [1:0]   io_out_bits_respErr,
  output [2:0]   io_out_bits_resp,
  output [3:0]   io_out_bits_dataSource,
  output [11:0]  io_out_bits_dbID,
  output [1:0]   io_out_bits_ccID,
  output [1:0]   io_out_bits_dataID,
  output         io_out_bits_traceTag,
  output [31:0]  io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0]  io_out_bits_dataCheck,
  output [3:0]   io_out_bits_poison,
  input          io_pipeStatusVec_1_valid,
  input  [2:0]   io_pipeStatusVec_1_bits_channel,
  input  [2:0]   io_pipeStatusVec_1_bits_txChannel,
  input          io_pipeStatusVec_1_bits_mshrTask,
  input          io_pipeStatusVec_2_valid,
  input  [2:0]   io_pipeStatusVec_2_bits_channel,
  input  [2:0]   io_pipeStatusVec_2_bits_txChannel,
  input          io_pipeStatusVec_2_bits_mshrTask,
  input          io_pipeStatusVec_3_valid,
  input  [2:0]   io_pipeStatusVec_3_bits_channel,
  input  [2:0]   io_pipeStatusVec_3_bits_txChannel,
  input          io_pipeStatusVec_3_bits_mshrTask,
  input          io_pipeStatusVec_4_valid,
  input  [2:0]   io_pipeStatusVec_4_bits_channel,
  input  [2:0]   io_pipeStatusVec_4_bits_txChannel,
  input          io_pipeStatusVec_4_bits_mshrTask,
  output         io_toReqArb_blockMSHRReqEntrance,
  output         io_toReqArb_blockSinkBReqEntrance
);

  // ===== 在飞计数 =====
  wire cnt_s5 = io_pipeStatusVec_4_valid & io_pipeStatusVec_4_bits_txChannel[2]
                & (io_pipeStatusVec_4_bits_channel[1] | io_pipeStatusVec_4_bits_mshrTask);
  wire cnt_s4 = io_pipeStatusVec_3_valid & io_pipeStatusVec_3_bits_txChannel[2]
                & (io_pipeStatusVec_3_bits_channel[1] | io_pipeStatusVec_3_bits_mshrTask);
  wire cnt_s3 = io_pipeStatusVec_2_valid & io_pipeStatusVec_2_bits_txChannel[2]
                & (io_pipeStatusVec_2_bits_channel[1] | io_pipeStatusVec_2_bits_mshrTask);
  wire cnt_s2 = io_pipeStatusVec_1_valid
                & (io_pipeStatusVec_1_bits_mshrTask ? io_pipeStatusVec_1_bits_txChannel[2]
                                                    : io_pipeStatusVec_1_bits_channel[1]);
  wire [1:0] pipe_cnt = {1'b0, cnt_s2} + {1'b0, cnt_s3} + {1'b0, cnt_s4} + {1'b0, cnt_s5}; // 2 位截位
  wire [4:0] queue_count;
  wire [4:0] inflightCnt = {3'h0, pipe_cnt} + queue_count;
  assign io_toReqArb_blockMSHRReqEntrance  = inflightCnt > 5'hD;
  assign io_toReqArb_blockSinkBReqEntrance = inflightCnt[4];

  // ===== 输出 2-beat 缓冲状态 =====
  reg          beat0_valid, beat1_valid;
  wire [1:0]   beatsOH = {beat1_valid, beat0_valid};
  wire         buffer_empty = ~(|beatsOH);
  wire         queue_deq_valid;
  wire         load_buffer = buffer_empty & queue_deq_valid;   // 缓冲空且头队列有数据 ⇒ 载入整行
  wire         send_beat   = io_out_ready & (|beatsOH);          // 本拍发出一个 beat

  // 头部锁存 + 整行数据
  reg  [5:0]   taskR_task_off;
  reg          taskR_task_corrupt;
  reg  [10:0]  taskR_task_tgtID;
  reg  [11:0]  taskR_task_txnID;
  reg  [10:0]  taskR_task_homeNID;
  reg  [11:0]  taskR_task_dbID;
  reg  [6:0]   taskR_task_chiOpcode;
  reg  [2:0]   taskR_task_resp;
  reg  [2:0]   taskR_task_fwdState;
  reg          taskR_task_traceTag;
  reg  [511:0] taskR_data_data;

  // 队列出线
  wire         queue_enq_ready;
  wire [5:0]   queue_deq_off;
  wire         queue_deq_corrupt;
  wire [10:0]  queue_deq_tgtID;
  wire [11:0]  queue_deq_txnID;
  wire [10:0]  queue_deq_homeNID;
  wire [11:0]  queue_deq_dbID;
  wire [6:0]   queue_deq_chiOpcode;
  wire [2:0]   queue_deq_resp;
  wire [2:0]   queue_deq_fwdState;
  wire         queue_deq_traceTag;
  wire [255:0] queueData0_deq, queueData1_deq;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      beat0_valid <= 1'b0; beat1_valid <= 1'b0;
      taskR_task_off <= 6'h0; taskR_task_corrupt <= 1'b0;
      taskR_task_tgtID <= 11'h0; taskR_task_txnID <= 12'h0; taskR_task_homeNID <= 11'h0;
      taskR_task_dbID <= 12'h0; taskR_task_chiOpcode <= 7'h0; taskR_task_resp <= 3'h0;
      taskR_task_fwdState <= 3'h0; taskR_task_traceTag <= 1'b0; taskR_data_data <= 512'h0;
    end
    else begin
      // beat 有效位推进: 发 beat 时先清 beat0 后清 beat1; 载入时两 beat 全置
      if (send_beat) begin
        if (beat0_valid) begin beat0_valid <= 1'b0;        beat1_valid <= beat1_valid; end
        else             begin beat0_valid <= beat0_valid; beat1_valid <= 1'b0;        end
      end
      else begin
        beat0_valid <= load_buffer | beat0_valid;
        beat1_valid <= load_buffer | beat1_valid;
      end
      // 载入头部 + 整行数据 (两 beat 拼成 512b)
      if (load_buffer) begin
        taskR_task_off       <= queue_deq_off;
        taskR_task_corrupt   <= queue_deq_corrupt;
        taskR_task_tgtID     <= queue_deq_tgtID;
        taskR_task_txnID     <= queue_deq_txnID;
        taskR_task_homeNID   <= queue_deq_homeNID;
        taskR_task_dbID      <= queue_deq_dbID;
        taskR_task_chiOpcode <= queue_deq_chiOpcode;
        taskR_task_resp      <= queue_deq_resp;
        taskR_task_fwdState  <= queue_deq_fwdState;
        taskR_task_traceTag  <= queue_deq_traceTag;
        taskR_data_data      <= {queueData1_deq, queueData0_deq};
      end
    end
  end

  // 当前要发的 beat: beat0(低 256b) 优先, 否则 beat1(高 256b)
  wire [255:0] beat = beat0_valid ? taskR_data_data[255:0] : taskR_data_data[511:256];
  // CHI 无数据写场景: BE 全 0 且数据清零 (CopyBackWrData w/ resp==0, 或 opcode 7)
  wire deassertBE = (taskR_task_chiOpcode == 7'h2 & taskR_task_resp == 3'h0)
                  | (taskR_task_chiOpcode == 7'h7);

  // 逐字节 DataCheck = ~(该字节奇偶)
  wire [31:0] beat_dataCheck;
  genvar gi;
  generate
    for (gi = 0; gi < 32; gi = gi + 1) begin : g_datacheck
      assign beat_dataCheck[gi] = ~(^beat[8*gi +: 8]);
    end
  endgenerate

  // ===== 输出 =====
  assign io_in_ready            = queue_enq_ready;
  assign io_out_valid           = |beatsOH;
  assign io_out_bits_tgtID      = taskR_task_tgtID;
  assign io_out_bits_txnID      = taskR_task_txnID;
  assign io_out_bits_homeNID    = taskR_task_homeNID;
  assign io_out_bits_opcode     = taskR_task_chiOpcode[3:0];
  assign io_out_bits_respErr    = {taskR_task_corrupt, 1'h0};
  assign io_out_bits_resp       = taskR_task_resp;
  assign io_out_bits_dataSource = {1'h0, taskR_task_fwdState};
  assign io_out_bits_dbID       = taskR_task_dbID;
  assign io_out_bits_ccID       = taskR_task_off[5:4];
  assign io_out_bits_dataID     = {~beat0_valid, 1'h0};
  assign io_out_bits_traceTag   = taskR_task_traceTag;
  assign io_out_bits_be         = {32{~deassertBE}};
  assign io_out_bits_data       = {256{~deassertBE}} & beat;
  assign io_out_bits_dataCheck  = beat_dataCheck;
  assign io_out_bits_poison     = {4{taskR_task_corrupt}};


  Queue16_TaskBundle queue (
    .clock                                     (clock),
    .reset                                     (reset),
    .io_enq_ready                              (queue_enq_ready),
    .io_enq_valid                              (io_in_valid),
    .io_enq_bits_channel                       (io_in_bits_task_channel),
    .io_enq_bits_txChannel                     (io_in_bits_task_txChannel),
    .io_enq_bits_set                           (io_in_bits_task_set),
    .io_enq_bits_tag                           (io_in_bits_task_tag),
    .io_enq_bits_off                           (io_in_bits_task_off),
    .io_enq_bits_alias                         (io_in_bits_task_alias),
    .io_enq_bits_vaddr                         (io_in_bits_task_vaddr),
    .io_enq_bits_isKeyword                     (io_in_bits_task_isKeyword),
    .io_enq_bits_opcode                        (io_in_bits_task_opcode),
    .io_enq_bits_param                         (io_in_bits_task_param),
    .io_enq_bits_size                          (io_in_bits_task_size),
    .io_enq_bits_sourceId                      (io_in_bits_task_sourceId),
    .io_enq_bits_bufIdx                        (io_in_bits_task_bufIdx),
    .io_enq_bits_needProbeAckData              (io_in_bits_task_needProbeAckData),
    .io_enq_bits_denied                        (io_in_bits_task_denied),
    .io_enq_bits_corrupt                       (io_in_bits_task_corrupt),
    .io_enq_bits_mshrTask                      (io_in_bits_task_mshrTask),
    .io_enq_bits_mshrId                        (io_in_bits_task_mshrId),
    .io_enq_bits_aliasTask                     (io_in_bits_task_aliasTask),
    .io_enq_bits_useProbeData                  (io_in_bits_task_useProbeData),
    .io_enq_bits_mshrRetry                     (io_in_bits_task_mshrRetry),
    .io_enq_bits_readProbeDataDown             (io_in_bits_task_readProbeDataDown),
    .io_enq_bits_fromL2pft                     (io_in_bits_task_fromL2pft),
    .io_enq_bits_needHint                      (io_in_bits_task_needHint),
    .io_enq_bits_dirty                         (io_in_bits_task_dirty),
    .io_enq_bits_way                           (io_in_bits_task_way),
    .io_enq_bits_meta_dirty                    (io_in_bits_task_meta_dirty),
    .io_enq_bits_meta_state                    (io_in_bits_task_meta_state),
    .io_enq_bits_meta_clients                  (io_in_bits_task_meta_clients),
    .io_enq_bits_meta_alias                    (io_in_bits_task_meta_alias),
    .io_enq_bits_meta_prefetch                 (io_in_bits_task_meta_prefetch),
    .io_enq_bits_meta_prefetchSrc              (io_in_bits_task_meta_prefetchSrc),
    .io_enq_bits_meta_accessed                 (io_in_bits_task_meta_accessed),
    .io_enq_bits_meta_tagErr                   (io_in_bits_task_meta_tagErr),
    .io_enq_bits_meta_dataErr                  (io_in_bits_task_meta_dataErr),
    .io_enq_bits_metaWen                       (io_in_bits_task_metaWen),
    .io_enq_bits_tagWen                        (io_in_bits_task_tagWen),
    .io_enq_bits_dsWen                         (io_in_bits_task_dsWen),
    .io_enq_bits_wayMask                       (io_in_bits_task_wayMask),
    .io_enq_bits_replTask                      (io_in_bits_task_replTask),
    .io_enq_bits_cmoTask                       (io_in_bits_task_cmoTask),
    .io_enq_bits_cmoAll                        (io_in_bits_task_cmoAll),
    .io_enq_bits_reqSource                     (io_in_bits_task_reqSource),
    .io_enq_bits_mergeA                        (io_in_bits_task_mergeA),
    .io_enq_bits_aMergeTask_off                (io_in_bits_task_aMergeTask_off),
    .io_enq_bits_aMergeTask_alias              (io_in_bits_task_aMergeTask_alias),
    .io_enq_bits_aMergeTask_vaddr              (io_in_bits_task_aMergeTask_vaddr),
    .io_enq_bits_aMergeTask_isKeyword          (io_in_bits_task_aMergeTask_isKeyword),
    .io_enq_bits_aMergeTask_opcode             (io_in_bits_task_aMergeTask_opcode),
    .io_enq_bits_aMergeTask_param              (io_in_bits_task_aMergeTask_param),
    .io_enq_bits_aMergeTask_sourceId           (io_in_bits_task_aMergeTask_sourceId),
    .io_enq_bits_aMergeTask_meta_dirty         (io_in_bits_task_aMergeTask_meta_dirty),
    .io_enq_bits_aMergeTask_meta_state         (io_in_bits_task_aMergeTask_meta_state),
    .io_enq_bits_aMergeTask_meta_clients       (io_in_bits_task_aMergeTask_meta_clients),
    .io_enq_bits_aMergeTask_meta_alias         (io_in_bits_task_aMergeTask_meta_alias),
    .io_enq_bits_aMergeTask_meta_prefetch      (io_in_bits_task_aMergeTask_meta_prefetch),
    .io_enq_bits_aMergeTask_meta_prefetchSrc
      (io_in_bits_task_aMergeTask_meta_prefetchSrc),
    .io_enq_bits_aMergeTask_meta_accessed      (io_in_bits_task_aMergeTask_meta_accessed),
    .io_enq_bits_aMergeTask_meta_tagErr        (io_in_bits_task_aMergeTask_meta_tagErr),
    .io_enq_bits_aMergeTask_meta_dataErr       (io_in_bits_task_aMergeTask_meta_dataErr),
    .io_enq_bits_snpHitRelease                 (io_in_bits_task_snpHitRelease),
    .io_enq_bits_snpHitReleaseToInval          (io_in_bits_task_snpHitReleaseToInval),
    .io_enq_bits_snpHitReleaseToClean          (io_in_bits_task_snpHitReleaseToClean),
    .io_enq_bits_snpHitReleaseWithData         (io_in_bits_task_snpHitReleaseWithData),
    .io_enq_bits_snpHitReleaseIdx              (io_in_bits_task_snpHitReleaseIdx),
    .io_enq_bits_snpHitReleaseMeta_dirty       (io_in_bits_task_snpHitReleaseMeta_dirty),
    .io_enq_bits_snpHitReleaseMeta_state       (io_in_bits_task_snpHitReleaseMeta_state),
    .io_enq_bits_snpHitReleaseMeta_clients
      (io_in_bits_task_snpHitReleaseMeta_clients),
    .io_enq_bits_snpHitReleaseMeta_alias       (io_in_bits_task_snpHitReleaseMeta_alias),
    .io_enq_bits_snpHitReleaseMeta_prefetch
      (io_in_bits_task_snpHitReleaseMeta_prefetch),
    .io_enq_bits_snpHitReleaseMeta_prefetchSrc
      (io_in_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_snpHitReleaseMeta_accessed
      (io_in_bits_task_snpHitReleaseMeta_accessed),
    .io_enq_bits_snpHitReleaseMeta_tagErr      (io_in_bits_task_snpHitReleaseMeta_tagErr),
    .io_enq_bits_snpHitReleaseMeta_dataErr
      (io_in_bits_task_snpHitReleaseMeta_dataErr),
    .io_enq_bits_tgtID                         (io_in_bits_task_tgtID),
    .io_enq_bits_srcID                         (io_in_bits_task_srcID),
    .io_enq_bits_txnID                         (io_in_bits_task_txnID),
    .io_enq_bits_homeNID                       (io_in_bits_task_homeNID),
    .io_enq_bits_dbID                          (io_in_bits_task_dbID),
    .io_enq_bits_fwdNID                        (io_in_bits_task_fwdNID),
    .io_enq_bits_fwdTxnID                      (io_in_bits_task_fwdTxnID),
    .io_enq_bits_chiOpcode                     (io_in_bits_task_chiOpcode),
    .io_enq_bits_resp                          (io_in_bits_task_resp),
    .io_enq_bits_fwdState                      (io_in_bits_task_fwdState),
    .io_enq_bits_pCrdType                      (io_in_bits_task_pCrdType),
    .io_enq_bits_retToSrc                      (io_in_bits_task_retToSrc),
    .io_enq_bits_likelyshared                  (io_in_bits_task_likelyshared),
    .io_enq_bits_expCompAck                    (io_in_bits_task_expCompAck),
    .io_enq_bits_allowRetry                    (io_in_bits_task_allowRetry),
    .io_enq_bits_memAttr_allocate              (io_in_bits_task_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable             (io_in_bits_task_memAttr_cacheable),
    .io_enq_bits_memAttr_device                (io_in_bits_task_memAttr_device),
    .io_enq_bits_memAttr_ewa                   (io_in_bits_task_memAttr_ewa),
    .io_enq_bits_traceTag                      (io_in_bits_task_traceTag),
    .io_enq_bits_dataCheckErr                  (io_in_bits_task_dataCheckErr),
    .io_deq_ready                              (buffer_empty),
    .io_deq_valid                              (queue_deq_valid),
    .io_deq_bits_off                           (queue_deq_off),
    .io_deq_bits_corrupt                       (queue_deq_corrupt),
    .io_deq_bits_tgtID                         (queue_deq_tgtID),
    .io_deq_bits_txnID                         (queue_deq_txnID),
    .io_deq_bits_homeNID                       (queue_deq_homeNID),
    .io_deq_bits_dbID                          (queue_deq_dbID),
    .io_deq_bits_chiOpcode                     (queue_deq_chiOpcode),
    .io_deq_bits_resp                          (queue_deq_resp),
    .io_deq_bits_fwdState                      (queue_deq_fwdState),
    .io_deq_bits_traceTag                      (queue_deq_traceTag),
    .io_count                                  (queue_count)
  );
  Queue16_DSBeat queueData0 (
    .clock            (clock),
    .reset            (reset),
    .io_enq_valid     (io_in_valid),
    .io_enq_bits_data (io_in_bits_data_data[255:0]),
    .io_deq_ready     (buffer_empty),
    .io_deq_bits_data (queueData0_deq)
  );
  Queue16_DSBeat queueData1 (
    .clock            (clock),
    .reset            (reset),
    .io_enq_valid     (io_in_valid),
    .io_enq_bits_data (io_in_bits_data_data[511:256]),
    .io_deq_ready     (buffer_empty),
    .io_deq_bits_data (queueData1_deq)
  );
endmodule
