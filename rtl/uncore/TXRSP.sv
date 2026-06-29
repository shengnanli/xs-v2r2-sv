// =============================================================================
//  TXRSP —— coupledL2 (tl2chi) CHI RSP 发送通道 可读重写核 (xs_TXRSP_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/tl2chi/TXRSP.scala
//  汇聚两路 RSP 来源 (流水回应 pipeRsp / MSHR 回应 mshrRsp), 经一个 16 深 FIFO
//  (Queue16_CHIRSP, 本核黑盒) 缓冲后以 CHIRSP flit 发往 CHI 互联;
//  同时按"在飞 RSP 计数"对 ReqArb 做反压 (block MSHR / SinkB 入口)。
//
//  ===== 在飞计数 inflightCnt (反压核心) =====
//    = 队列里已缓存的条数 queueCnt
//    + 流水线 s3~s5 上"将很快流入 TXRSP"的请求数
//    + 流水线 s2 上"将很快流入 TXRSP"的请求数
//  这里 golden 把 io.pipeStatusVec(5 项 s1~s5) 单态化, 只用到 s2~s5 ⇒ 端口为
//    io_pipeStatusVec_1 = s2, _2 = s3, _3 = s4, _4 = s5  (s1 未参与, 无端口)。
//  判据: toTXRSP = txChannel[1] ; fromB = channel[1]
//    s3~s5: valid & toTXRSP & (fromB | mshrTask)
//    s2   : valid & (mshrTask ? toTXRSP : fromB)
//  各项均 0/1, 加 queueCnt(≤16) 总和 ≤20 < 32, 5 位无溢出 (FM 与 golden 嵌套截位等价)。
//
//  ===== 反压门限 (mshrsAll=16) =====
//    noSpaceForMSHRReq  = inflightCnt >  13   (>= mshrsAll-2 = 14)
//    noSpaceForSinkBReq = inflightCnt >= 16   (= inflightCnt[4])
//
//  ===== 入队仲裁 =====
//    pipeRsp 恒可入 (pipeRsp.ready=1, 流水永不被堵); mshrRsp 仅在无空间压力且
//    pipeRsp 不占用时入队。enq.bits: pipeRsp 优先, 其字段由 TaskBundle 转 CHIRSP。
// =============================================================================
module xs_TXRSP_core (
  input         clock,
  input         reset,
  // ---- io.pipeRsp (Flipped DecoupledIO TaskBundle, 流水线回应) ----
  input         io_pipeRsp_valid,
  input  [2:0]  io_pipeRsp_bits_txChannel,
  input         io_pipeRsp_bits_denied,
  input  [10:0] io_pipeRsp_bits_tgtID,
  input  [10:0] io_pipeRsp_bits_srcID,
  input  [11:0] io_pipeRsp_bits_txnID,
  input  [11:0] io_pipeRsp_bits_dbID,
  input  [6:0]  io_pipeRsp_bits_chiOpcode,
  input  [2:0]  io_pipeRsp_bits_resp,
  input  [2:0]  io_pipeRsp_bits_fwdState,
  input  [3:0]  io_pipeRsp_bits_pCrdType,
  input         io_pipeRsp_bits_traceTag,
  // ---- io.mshrRsp (Flipped DecoupledIO CHIRSP, MSHR 回应) ----
  output        io_mshrRsp_ready,
  input         io_mshrRsp_valid,
  input  [10:0] io_mshrRsp_bits_tgtID,
  input  [11:0] io_mshrRsp_bits_txnID,
  input  [4:0]  io_mshrRsp_bits_opcode,
  input         io_mshrRsp_bits_traceTag,
  // ---- io.out (DecoupledIO CHIRSP, 发往 CHI 互联) ----
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [4:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_respErr,
  output [2:0]  io_out_bits_resp,
  output [2:0]  io_out_bits_fwdState,
  output [2:0]  io_out_bits_cBusy,
  output [11:0] io_out_bits_dbID,
  output [3:0]  io_out_bits_pCrdType,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  // ---- io.pipeStatusVec (Flipped Vec, 单态后仅 s2~s5) ----
  input         io_pipeStatusVec_1_valid,       // s2
  input  [2:0]  io_pipeStatusVec_1_bits_channel,
  input  [2:0]  io_pipeStatusVec_1_bits_txChannel,
  input         io_pipeStatusVec_1_bits_mshrTask,
  input         io_pipeStatusVec_2_valid,       // s3
  input  [2:0]  io_pipeStatusVec_2_bits_channel,
  input  [2:0]  io_pipeStatusVec_2_bits_txChannel,
  input         io_pipeStatusVec_2_bits_mshrTask,
  input         io_pipeStatusVec_3_valid,       // s4
  input  [2:0]  io_pipeStatusVec_3_bits_channel,
  input  [2:0]  io_pipeStatusVec_3_bits_txChannel,
  input         io_pipeStatusVec_3_bits_mshrTask,
  input         io_pipeStatusVec_4_valid,       // s5
  input  [2:0]  io_pipeStatusVec_4_bits_channel,
  input  [2:0]  io_pipeStatusVec_4_bits_txChannel,
  input         io_pipeStatusVec_4_bits_mshrTask,
  // ---- io.toReqArb (反压输出) ----
  output        io_toReqArb_blockMSHRReqEntrance,
  output        io_toReqArb_blockSinkBReqEntrance
);

  wire [4:0] queue_count;

  // ---- 在飞计数 ----
  // s3~s5: valid & toTXRSP(txChannel[1]) & (fromB(channel[1]) | mshrTask)
  wire cnt_s5 = io_pipeStatusVec_4_valid & io_pipeStatusVec_4_bits_txChannel[1]
                & (io_pipeStatusVec_4_bits_channel[1] | io_pipeStatusVec_4_bits_mshrTask);
  wire cnt_s4 = io_pipeStatusVec_3_valid & io_pipeStatusVec_3_bits_txChannel[1]
                & (io_pipeStatusVec_3_bits_channel[1] | io_pipeStatusVec_3_bits_mshrTask);
  wire cnt_s3 = io_pipeStatusVec_2_valid & io_pipeStatusVec_2_bits_txChannel[1]
                & (io_pipeStatusVec_2_bits_channel[1] | io_pipeStatusVec_2_bits_mshrTask);
  // s2: valid & (mshrTask ? toTXRSP : fromB)
  wire cnt_s2 = io_pipeStatusVec_1_valid
                & (io_pipeStatusVec_1_bits_mshrTask ? io_pipeStatusVec_1_bits_txChannel[1]
                                                    : io_pipeStatusVec_1_bits_channel[1]);

  // 关键: golden 把流水贡献截成 2 位 (Chisel `+` 取 max 位宽截位): 四项全 1 时 4 回绕成 0。
  wire [1:0] pipe_cnt = {1'b0, cnt_s2} + {1'b0, cnt_s3} + {1'b0, cnt_s4} + {1'b0, cnt_s5};
  wire [4:0] inflightCnt = {3'h0, pipe_cnt} + queue_count;

  // ---- 反压门限 (mshrsAll=16) ----
  wire noSpaceForSinkBReq = inflightCnt[4];          // >= 16
  wire noSpaceForMSHRReq  = inflightCnt > 5'hD;       // >= 14
  assign io_toReqArb_blockSinkBReqEntrance = noSpaceForSinkBReq;
  assign io_toReqArb_blockMSHRReqEntrance  = noSpaceForMSHRReq;

  // ---- 入队仲裁: pipeRsp 优先, mshrRsp 仅在有空间时入 ----
  wire mshrRsp_accept = ~io_pipeRsp_valid & ~noSpaceForSinkBReq & ~noSpaceForMSHRReq;
  assign io_mshrRsp_ready = mshrRsp_accept;
  wire   enq_valid = io_pipeRsp_valid | (io_mshrRsp_valid & ~noSpaceForSinkBReq & ~noSpaceForMSHRReq);

  // enq.bits: TaskBundle → CHIRSP (pipeRsp 优先, 否则取 mshrRsp 的少数字段)
  // respErr: denied 时两位置 1 (golden {2{denied}}), 否则 0
  Queue16_CHIRSP queue (
    .clock                (clock),
    .reset                (reset),
    .io_enq_valid         (enq_valid),
    .io_enq_bits_tgtID    (io_pipeRsp_valid ? io_pipeRsp_bits_tgtID    : io_mshrRsp_bits_tgtID),
    .io_enq_bits_srcID    (io_pipeRsp_valid ? io_pipeRsp_bits_srcID    : 11'h0),
    .io_enq_bits_txnID    (io_pipeRsp_valid ? io_pipeRsp_bits_txnID    : io_mshrRsp_bits_txnID),
    .io_enq_bits_opcode   (io_pipeRsp_valid ? io_pipeRsp_bits_chiOpcode[4:0] : io_mshrRsp_bits_opcode),
    .io_enq_bits_respErr  (io_pipeRsp_valid ? {2{io_pipeRsp_bits_denied}} : 2'h0),
    .io_enq_bits_resp     (io_pipeRsp_valid ? io_pipeRsp_bits_resp     : 3'h0),
    .io_enq_bits_fwdState (io_pipeRsp_valid ? io_pipeRsp_bits_fwdState : 3'h0),
    .io_enq_bits_dbID     (io_pipeRsp_valid ? io_pipeRsp_bits_dbID     : 12'h0),
    .io_enq_bits_pCrdType (io_pipeRsp_valid ? io_pipeRsp_bits_pCrdType : 4'h0),
    .io_enq_bits_traceTag (io_pipeRsp_valid ? io_pipeRsp_bits_traceTag : io_mshrRsp_bits_traceTag),
    .io_deq_ready         (io_out_ready),
    .io_deq_valid         (io_out_valid),
    .io_deq_bits_qos      (io_out_bits_qos),
    .io_deq_bits_tgtID    (io_out_bits_tgtID),
    .io_deq_bits_txnID    (io_out_bits_txnID),
    .io_deq_bits_opcode   (io_out_bits_opcode),
    .io_deq_bits_respErr  (io_out_bits_respErr),
    .io_deq_bits_resp     (io_out_bits_resp),
    .io_deq_bits_fwdState (io_out_bits_fwdState),
    .io_deq_bits_cBusy    (io_out_bits_cBusy),
    .io_deq_bits_dbID     (io_out_bits_dbID),
    .io_deq_bits_pCrdType (io_out_bits_pCrdType),
    .io_deq_bits_tagOp    (io_out_bits_tagOp),
    .io_deq_bits_traceTag (io_out_bits_traceTag),
    .io_count             (queue_count)
  );

endmodule
