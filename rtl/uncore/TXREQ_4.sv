// =============================================================================
//  TXREQ_4 —— openLLC CHI REQ 发送通道 可读重写核 (xs_TXREQ_4_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/TXREQ.scala
//  LLC(L3) 侧: 接收内部 Task, 转成 CHI REQ flit 下发给 SN(内存/下游)。
//  单态化 (firtool TXREQ_4.sv): 纯组合, 无寄存器/SRAM/子模块。
//
//  语义 (直通映射):
//    req.valid  = task.valid, task.ready = req.ready (握手转接)
//    req.opcode = task.chiOpcode            (7b 内部 opcode 即 7b CHI REQ opcode)
//    req.addr   = {tag, set, bank, 6'b0}    (块地址重组: 物理地址低 6 位补零 = 64B 对齐)
//    tgtID/srcID/txnID/size/order/pCrdType/allowRetry/expCompAck/memAttr*/snpAttr 同名直通
// =============================================================================
module xs_TXREQ_4_core (
  // ---- io.req (DecoupledIO CHIREQ, 下发给 SN) ----
  input         io_req_ready,
  output        io_req_valid,
  output [10:0] io_req_bits_tgtID,
  output [10:0] io_req_bits_srcID,
  output [11:0] io_req_bits_txnID,
  output [6:0]  io_req_bits_opcode,
  output [2:0]  io_req_bits_size,
  output [47:0] io_req_bits_addr,
  output        io_req_bits_allowRetry,
  output [1:0]  io_req_bits_order,
  output [3:0]  io_req_bits_pCrdType,
  output        io_req_bits_memAttr_allocate,
  output        io_req_bits_memAttr_cacheable,
  output        io_req_bits_memAttr_device,
  output        io_req_bits_memAttr_ewa,
  output        io_req_bits_snpAttr,
  output        io_req_bits_expCompAck,
  // ---- io.task (Flipped DecoupledIO Task, 来自 LLC 内部) ----
  output        io_task_ready,
  input         io_task_valid,
  input  [11:0] io_task_bits_set,
  input  [1:0]  io_task_bits_bank,
  input  [27:0] io_task_bits_tag,
  input  [2:0]  io_task_bits_size,
  input  [10:0] io_task_bits_tgtID,
  input  [10:0] io_task_bits_srcID,
  input  [11:0] io_task_bits_txnID,
  input  [6:0]  io_task_bits_chiOpcode,
  input  [3:0]  io_task_bits_pCrdType,
  input         io_task_bits_expCompAck,
  input         io_task_bits_allowRetry,
  input  [1:0]  io_task_bits_order,
  input         io_task_bits_memAttr_allocate,
  input         io_task_bits_memAttr_cacheable,
  input         io_task_bits_memAttr_device,
  input         io_task_bits_memAttr_ewa,
  input         io_task_bits_snpAttr
);

  // 握手转接
  assign io_req_valid  = io_task_valid;
  assign io_task_ready = io_req_ready;

  // REQ flit 字段
  assign io_req_bits_tgtID            = io_task_bits_tgtID;
  assign io_req_bits_srcID            = io_task_bits_srcID;
  assign io_req_bits_txnID            = io_task_bits_txnID;
  assign io_req_bits_opcode           = io_task_bits_chiOpcode;
  assign io_req_bits_size             = io_task_bits_size;
  assign io_req_bits_addr             = {io_task_bits_tag, io_task_bits_set, io_task_bits_bank, 6'h0};
  assign io_req_bits_allowRetry       = io_task_bits_allowRetry;
  assign io_req_bits_order            = io_task_bits_order;
  assign io_req_bits_pCrdType         = io_task_bits_pCrdType;
  assign io_req_bits_memAttr_allocate = io_task_bits_memAttr_allocate;
  assign io_req_bits_memAttr_cacheable = io_task_bits_memAttr_cacheable;
  assign io_req_bits_memAttr_device   = io_task_bits_memAttr_device;
  assign io_req_bits_memAttr_ewa      = io_task_bits_memAttr_ewa;
  assign io_req_bits_snpAttr          = io_task_bits_snpAttr;
  assign io_req_bits_expCompAck       = io_task_bits_expCompAck;

endmodule
