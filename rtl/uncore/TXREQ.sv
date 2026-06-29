// =============================================================================
//  TXREQ —— coupledL2 (tl2chi) CHI REQ 发送通道 可读重写核 (xs_TXREQ_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/tl2chi/TXREQ.scala
//  汇聚两路 REQ 来源 (流水请求 pipeReq / MSHR 请求 mshrReq), 经一个 16 深 FIFO
//  (Queue16_CHIREQ, 本核黑盒) 缓冲后以 CHIREQ flit 发往 CHI 互联; 出队时把 sliceId
//  插回物理地址 (多 slice 地址恢复), 并按"在飞 REQ 计数"对 MSHR 入口反压。
//
//  ===== 在飞计数 inflightCnt =====
//    = popcount(s2~s5: valid & mshrTask & toTXREQ) + (1 - s2ReturnCredit) + queueCnt
//    toTXREQ = txChannel[0]
//    s2ReturnCredit = s2.valid & ~(s2.mshrTask & toTXREQ)  // s2 若不流入则归还 1 信用
//  单态化端口: io_pipeStatusVec_1 = s2, _2 = s3, _3 = s4, _4 = s5 (s1 未参与)。
//  (sum+1) ≥ 1 ≥ credit ⇒ 不下溢; 最大 4+1+16=21 < 32 ⇒ 5 位无溢出, FM 与 golden 等价。
//
//  ===== 反压 (mshrsAll=16) =====
//    noSpace = inflightCnt >= 16 (= inflightCnt[4]); blockMSHRReqEntrance = noSpace
//
//  ===== 入队/出队 =====
//    enq: pipeReq 优先 (pipeReq.ready=1); mshrReq 仅在 ~noSpace 时入。
//    out.addr = {deq.addr[45:6], sliceId(2b), deq.addr[5:0]}  (把 slice 号插回 bank 位)
// =============================================================================
module xs_TXREQ_core (
  input         clock,
  input         reset,
  // ---- io.pipeReq (Flipped DecoupledIO CHIREQ, 流水请求) ----
  input         io_pipeReq_valid,
  input  [10:0] io_pipeReq_bits_tgtID,
  input  [10:0] io_pipeReq_bits_srcID,
  input  [11:0] io_pipeReq_bits_txnID,
  input  [6:0]  io_pipeReq_bits_opcode,
  input  [47:0] io_pipeReq_bits_addr,
  input         io_pipeReq_bits_likelyshared,
  input         io_pipeReq_bits_allowRetry,
  input  [3:0]  io_pipeReq_bits_pCrdType,
  input         io_pipeReq_bits_memAttr_allocate,
  input         io_pipeReq_bits_memAttr_cacheable,
  input         io_pipeReq_bits_memAttr_device,
  input         io_pipeReq_bits_memAttr_ewa,
  input         io_pipeReq_bits_expCompAck,
  // ---- io.mshrReq (Flipped DecoupledIO CHIREQ, MSHR 请求) ----
  output        io_mshrReq_ready,
  input         io_mshrReq_valid,
  input  [3:0]  io_mshrReq_bits_qos,
  input  [10:0] io_mshrReq_bits_tgtID,
  input  [11:0] io_mshrReq_bits_txnID,
  input  [6:0]  io_mshrReq_bits_opcode,
  input  [2:0]  io_mshrReq_bits_size,
  input  [47:0] io_mshrReq_bits_addr,
  input         io_mshrReq_bits_likelyshared,
  input         io_mshrReq_bits_allowRetry,
  input  [3:0]  io_mshrReq_bits_pCrdType,
  input         io_mshrReq_bits_memAttr_allocate,
  input         io_mshrReq_bits_memAttr_cacheable,
  input         io_mshrReq_bits_memAttr_ewa,
  input         io_mshrReq_bits_snpAttr,
  input         io_mshrReq_bits_expCompAck,
  // ---- io.out (DecoupledIO CHIREQ, 发往 CHI 互联) ----
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_returnNID,
  output        io_out_bits_stashNIDValid,
  output [11:0] io_out_bits_returnTxnID,
  output [6:0]  io_out_bits_opcode,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_ns,
  output        io_out_bits_likelyshared,
  output        io_out_bits_allowRetry,
  output [1:0]  io_out_bits_order,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_allocate,
  output        io_out_bits_memAttr_cacheable,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa,
  output        io_out_bits_snpAttr,
  output [7:0]  io_out_bits_lpIDWithPadding,
  output        io_out_bits_snoopMe,
  output        io_out_bits_expCompAck,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  output        io_out_bits_mpam_perfMonGroup,
  output [8:0]  io_out_bits_mpam_partID,
  output        io_out_bits_mpam_mpamNS,
  output [3:0]  io_out_bits_rsvdc,
  // ---- io.pipeStatusVec (单态后仅 s2~s5) ----
  input         io_pipeStatusVec_1_valid,        // s2
  input  [2:0]  io_pipeStatusVec_1_bits_txChannel,
  input         io_pipeStatusVec_1_bits_mshrTask,
  input         io_pipeStatusVec_2_valid,        // s3
  input  [2:0]  io_pipeStatusVec_2_bits_txChannel,
  input         io_pipeStatusVec_2_bits_mshrTask,
  input         io_pipeStatusVec_3_valid,        // s4
  input  [2:0]  io_pipeStatusVec_3_bits_txChannel,
  input         io_pipeStatusVec_3_bits_mshrTask,
  input         io_pipeStatusVec_4_valid,        // s5
  input  [2:0]  io_pipeStatusVec_4_bits_txChannel,
  input         io_pipeStatusVec_4_bits_mshrTask,
  // ---- io.toReqArb / io.sliceId ----
  output        io_toReqArb_blockMSHRReqEntrance,
  input  [1:0]  io_sliceId
);

  wire [47:0] queue_deq_addr;
  wire [4:0]  queue_count;

  // ---- 在飞计数 ----
  // s2~s5: valid & mshrTask & toTXREQ(txChannel[0])
  wire c_s2 = io_pipeStatusVec_1_valid & io_pipeStatusVec_1_bits_mshrTask & io_pipeStatusVec_1_bits_txChannel[0];
  wire c_s3 = io_pipeStatusVec_2_valid & io_pipeStatusVec_2_bits_mshrTask & io_pipeStatusVec_2_bits_txChannel[0];
  wire c_s4 = io_pipeStatusVec_3_valid & io_pipeStatusVec_3_bits_mshrTask & io_pipeStatusVec_3_bits_txChannel[0];
  wire c_s5 = io_pipeStatusVec_4_valid & io_pipeStatusVec_4_bits_mshrTask & io_pipeStatusVec_4_bits_txChannel[0];
  // s2 不流入 TXREQ 时归还信用
  wire s2ReturnCredit = io_pipeStatusVec_1_valid & ~(io_pipeStatusVec_1_bits_mshrTask & io_pipeStatusVec_1_bits_txChannel[0]);

  // base = (popcount + 1) - credit  (恒 ≥ 0, 不下溢)
  wire [4:0] base = {4'h0, c_s2} + {4'h0, c_s3} + {4'h0, c_s4} + {4'h0, c_s5}
                  + 5'h1 - {4'h0, s2ReturnCredit};
  wire [4:0] inflightCnt = base + queue_count;

  // ---- 反压 ----
  wire noSpace = inflightCnt[4];                       // >= 16
  assign io_toReqArb_blockMSHRReqEntrance = noSpace;

  // ---- 入队仲裁 ----
  assign io_mshrReq_ready = ~io_pipeReq_valid & ~noSpace;
  wire   enq_valid = io_pipeReq_valid | (io_mshrReq_valid & ~noSpace);

  // 出队地址恢复: 把 sliceId 插回 addr 的 bank 位置 [7:6]
  assign io_out_bits_addr = {queue_deq_addr[45:6], io_sliceId, queue_deq_addr[5:0]};

  // enq.bits: pipeReq 优先 (pipeReq 缺省字段为常量, 见各 mux 的真值分支)
  Queue16_CHIREQ queue (
    .clock                         (clock),
    .reset                         (reset),
    .io_enq_valid                  (enq_valid),
    .io_enq_bits_qos               (io_pipeReq_valid ? 4'hF : io_mshrReq_bits_qos),
    .io_enq_bits_tgtID             (io_pipeReq_valid ? io_pipeReq_bits_tgtID : io_mshrReq_bits_tgtID),
    .io_enq_bits_srcID             (io_pipeReq_valid ? io_pipeReq_bits_srcID : 11'h0),
    .io_enq_bits_txnID             (io_pipeReq_valid ? io_pipeReq_bits_txnID : io_mshrReq_bits_txnID),
    .io_enq_bits_opcode            (io_pipeReq_valid ? io_pipeReq_bits_opcode : io_mshrReq_bits_opcode),
    .io_enq_bits_size              (io_pipeReq_valid ? 3'h0 : io_mshrReq_bits_size),
    .io_enq_bits_addr              (io_pipeReq_valid ? io_pipeReq_bits_addr : io_mshrReq_bits_addr),
    .io_enq_bits_likelyshared      (io_pipeReq_valid ? io_pipeReq_bits_likelyshared : io_mshrReq_bits_likelyshared),
    .io_enq_bits_allowRetry        (io_pipeReq_valid ? io_pipeReq_bits_allowRetry : io_mshrReq_bits_allowRetry),
    .io_enq_bits_pCrdType          (io_pipeReq_valid ? io_pipeReq_bits_pCrdType : io_mshrReq_bits_pCrdType),
    .io_enq_bits_memAttr_allocate  (io_pipeReq_valid ? io_pipeReq_bits_memAttr_allocate : io_mshrReq_bits_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable (io_pipeReq_valid ? io_pipeReq_bits_memAttr_cacheable : io_mshrReq_bits_memAttr_cacheable),
    .io_enq_bits_memAttr_device    (io_pipeReq_valid & io_pipeReq_bits_memAttr_device),
    .io_enq_bits_memAttr_ewa       (io_pipeReq_valid ? io_pipeReq_bits_memAttr_ewa : io_mshrReq_bits_memAttr_ewa),
    .io_enq_bits_snpAttr           (io_pipeReq_valid | io_mshrReq_bits_snpAttr),
    .io_enq_bits_expCompAck        (io_pipeReq_valid ? io_pipeReq_bits_expCompAck : io_mshrReq_bits_expCompAck),
    .io_deq_ready                  (io_out_ready),
    .io_deq_valid                  (io_out_valid),
    .io_deq_bits_qos               (io_out_bits_qos),
    .io_deq_bits_txnID             (io_out_bits_txnID),
    .io_deq_bits_returnNID         (io_out_bits_returnNID),
    .io_deq_bits_stashNIDValid     (io_out_bits_stashNIDValid),
    .io_deq_bits_returnTxnID       (io_out_bits_returnTxnID),
    .io_deq_bits_opcode            (io_out_bits_opcode),
    .io_deq_bits_addr              (queue_deq_addr),
    .io_deq_bits_ns                (io_out_bits_ns),
    .io_deq_bits_likelyshared      (io_out_bits_likelyshared),
    .io_deq_bits_allowRetry        (io_out_bits_allowRetry),
    .io_deq_bits_order             (io_out_bits_order),
    .io_deq_bits_pCrdType          (io_out_bits_pCrdType),
    .io_deq_bits_memAttr_allocate  (io_out_bits_memAttr_allocate),
    .io_deq_bits_memAttr_cacheable (io_out_bits_memAttr_cacheable),
    .io_deq_bits_memAttr_device    (io_out_bits_memAttr_device),
    .io_deq_bits_memAttr_ewa       (io_out_bits_memAttr_ewa),
    .io_deq_bits_snpAttr           (io_out_bits_snpAttr),
    .io_deq_bits_lpIDWithPadding   (io_out_bits_lpIDWithPadding),
    .io_deq_bits_snoopMe           (io_out_bits_snoopMe),
    .io_deq_bits_expCompAck        (io_out_bits_expCompAck),
    .io_deq_bits_tagOp             (io_out_bits_tagOp),
    .io_deq_bits_traceTag          (io_out_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (io_out_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID       (io_out_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS       (io_out_bits_mpam_mpamNS),
    .io_deq_bits_rsvdc             (io_out_bits_rsvdc),
    .io_count                      (queue_count)
  );

endmodule
