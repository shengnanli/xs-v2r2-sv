// Pipeline_13.sv —— coupledL2 tl2chi/TL2CHICoupledL2.scala:269 `Pipeline(linkMonitor.io.in.rx.rsp)`：RXRSP 打一拍
//
// utility.Pipeline(gen, depth = 1, pipe = true) 的单态化；例化处：TL2CHICoupledL2.rxrspPipe_pipeline。
//   utility/Pipeline.scala：depth 个 Queue(gen, entries = 1, pipe = true, flow = false) 首尾相接。
// 本模块没有自己的逻辑：唯一一级就是已签核的深度 1 队列 Queue1_CHIRSP（rtl/uncore/Queue1_CHIRSP.sv，
// 控制+存储在共享核 rtl/common/xs_ChiselQueue1_core.sv），这里按 golden 实例名 stages_0 接上，
// io_in_* -> io_enq_*、io_deq_* -> io_out_* 逐口同名。
// golden 157 行；由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐口校验。

// BEGIN GENERATED(Pipeline_13) —— scripts/gen_uncore_queues.py
module Pipeline_13 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [3:0] io_in_bits_qos,
  input  logic [10:0] io_in_bits_tgtID,
  input  logic [10:0] io_in_bits_srcID,
  input  logic [11:0] io_in_bits_txnID,
  input  logic [4:0] io_in_bits_opcode,
  input  logic [1:0] io_in_bits_respErr,
  input  logic [2:0] io_in_bits_resp,
  input  logic [2:0] io_in_bits_fwdState,
  input  logic [2:0] io_in_bits_cBusy,
  input  logic [11:0] io_in_bits_dbID,
  input  logic [3:0] io_in_bits_pCrdType,
  input  logic [1:0] io_in_bits_tagOp,
  input  logic io_in_bits_traceTag,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [3:0] io_out_bits_qos,
  output logic [10:0] io_out_bits_tgtID,
  output logic [10:0] io_out_bits_srcID,
  output logic [11:0] io_out_bits_txnID,
  output logic [4:0] io_out_bits_opcode,
  output logic [1:0] io_out_bits_respErr,
  output logic [2:0] io_out_bits_resp,
  output logic [2:0] io_out_bits_fwdState,
  output logic [2:0] io_out_bits_cBusy,
  output logic [11:0] io_out_bits_dbID,
  output logic [3:0] io_out_bits_pCrdType,
  output logic [1:0] io_out_bits_tagOp,
  output logic io_out_bits_traceTag
);

  Queue1_CHIRSP stages_0 (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (io_in_ready),
    .io_enq_valid         (io_in_valid),
    .io_enq_bits_qos      (io_in_bits_qos),
    .io_enq_bits_tgtID    (io_in_bits_tgtID),
    .io_enq_bits_srcID    (io_in_bits_srcID),
    .io_enq_bits_txnID    (io_in_bits_txnID),
    .io_enq_bits_opcode   (io_in_bits_opcode),
    .io_enq_bits_respErr  (io_in_bits_respErr),
    .io_enq_bits_resp     (io_in_bits_resp),
    .io_enq_bits_fwdState (io_in_bits_fwdState),
    .io_enq_bits_cBusy    (io_in_bits_cBusy),
    .io_enq_bits_dbID     (io_in_bits_dbID),
    .io_enq_bits_pCrdType (io_in_bits_pCrdType),
    .io_enq_bits_tagOp    (io_in_bits_tagOp),
    .io_enq_bits_traceTag (io_in_bits_traceTag),
    .io_deq_ready         (io_out_ready),
    .io_deq_valid         (io_out_valid),
    .io_deq_bits_qos      (io_out_bits_qos),
    .io_deq_bits_tgtID    (io_out_bits_tgtID),
    .io_deq_bits_srcID    (io_out_bits_srcID),
    .io_deq_bits_txnID    (io_out_bits_txnID),
    .io_deq_bits_opcode   (io_out_bits_opcode),
    .io_deq_bits_respErr  (io_out_bits_respErr),
    .io_deq_bits_resp     (io_out_bits_resp),
    .io_deq_bits_fwdState (io_out_bits_fwdState),
    .io_deq_bits_cBusy    (io_out_bits_cBusy),
    .io_deq_bits_dbID     (io_out_bits_dbID),
    .io_deq_bits_pCrdType (io_out_bits_pCrdType),
    .io_deq_bits_tagOp    (io_out_bits_tagOp),
    .io_deq_bits_traceTag (io_out_bits_traceTag)
  );

endmodule
// END GENERATED(Pipeline_13)
