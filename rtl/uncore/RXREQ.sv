// =============================================================================
//  RXREQ —— openLLC CHI REQ 接收通道 可读重写核 (xs_RXREQ_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/RXREQ.scala
//  LLC(L3) 侧: 接收来自上游 RN 的 CHI REQ flit, 解析地址并转成内部 Task。
//  单态化 (firtool RXREQ.sv): 仅一个 9-bit 计数器 id_pool, 无 SRAM/子模块。
//
//  ===== reqID(内部 txnID 空间) 编码 =====
//    cacheable: { 0.U(1.W), bank(2b), id_pool(9b) }  共 12b
//    本单态只生成 cacheable 路径 ⇒ reqID = {1'b0, addr[7:6], id_pool}
//    id_pool 每当 task 握手成功(fire) 自增, 给同 bank 的在飞请求分配不同内部 ID。
//
//  ===== 地址切分 parseAddress(48b 物理地址) =====
//    tag = addr[47:20] (28b), set = addr[19:8] (12b), bank = addr[7:6] (2b), off = addr[5:0]
// =============================================================================
module xs_RXREQ_core (
  input         clock,
  input         reset,
  // ---- io.req (Flipped DecoupledIO CHIREQ, 来自上游 RN) ----
  output        io_req_ready,
  input         io_req_valid,
  input  [10:0] io_req_bits_tgtID,
  input  [10:0] io_req_bits_srcID,
  input  [11:0] io_req_bits_txnID,
  input  [6:0]  io_req_bits_opcode,
  input  [2:0]  io_req_bits_size,
  input  [47:0] io_req_bits_addr,
  input         io_req_bits_allowRetry,
  input  [1:0]  io_req_bits_order,
  input  [3:0]  io_req_bits_pCrdType,
  input         io_req_bits_memAttr_allocate,
  input         io_req_bits_memAttr_cacheable,
  input         io_req_bits_memAttr_device,
  input         io_req_bits_memAttr_ewa,
  input         io_req_bits_snpAttr,
  input         io_req_bits_expCompAck,
  // ---- io.task (DecoupledIO Task, 投向 LLC 内部) ----
  input         io_task_ready,
  output        io_task_valid,
  output [11:0] io_task_bits_set,
  output [1:0]  io_task_bits_bank,
  output [27:0] io_task_bits_tag,
  output [5:0]  io_task_bits_off,
  output [2:0]  io_task_bits_size,
  output [11:0] io_task_bits_reqID,
  output [10:0] io_task_bits_tgtID,
  output [10:0] io_task_bits_srcID,
  output [11:0] io_task_bits_txnID,
  output [6:0]  io_task_bits_chiOpcode,
  output [3:0]  io_task_bits_pCrdType,
  output        io_task_bits_expCompAck,
  output        io_task_bits_allowRetry,
  output [1:0]  io_task_bits_order,
  output        io_task_bits_memAttr_allocate,
  output        io_task_bits_memAttr_cacheable,
  output        io_task_bits_memAttr_device,
  output        io_task_bits_memAttr_ewa,
  output        io_task_bits_snpAttr
);

  // 握手转接: task.valid=req.valid, req.ready=task.ready ⇒ fire=req.valid&task.ready
  assign io_task_valid = io_req_valid;
  assign io_req_ready  = io_task_ready;
  wire   task_fire = io_req_valid & io_task_ready;

  // 内部 ID 池: 每次 task 握手成功自增 (异步复位, 与 golden 一致)
  reg [8:0] id_pool;
  always @(posedge clock or posedge reset) begin
    if (reset)
      id_pool <= 9'h0;
    else if (task_fire)
      id_pool <= id_pool + 9'h1;
  end

  // 地址切分
  wire [27:0] tag  = io_req_bits_addr[47:20];
  wire [11:0] set  = io_req_bits_addr[19:8];
  wire [1:0]  bank = io_req_bits_addr[7:6];
  wire [5:0]  off  = io_req_bits_addr[5:0];

  assign io_task_bits_tag  = tag;
  assign io_task_bits_set  = set;
  assign io_task_bits_bank = bank;
  assign io_task_bits_off  = off;
  assign io_task_bits_size = io_req_bits_size;
  // cacheable 内部 txnID: {0, bank, id_pool}
  assign io_task_bits_reqID = {1'h0, bank, id_pool};

  // 其余字段照 CHIREQ → Task 直通
  assign io_task_bits_tgtID            = io_req_bits_tgtID;
  assign io_task_bits_srcID            = io_req_bits_srcID;
  assign io_task_bits_txnID            = io_req_bits_txnID;
  assign io_task_bits_chiOpcode        = io_req_bits_opcode;
  assign io_task_bits_pCrdType         = io_req_bits_pCrdType;
  assign io_task_bits_expCompAck       = io_req_bits_expCompAck;
  assign io_task_bits_allowRetry       = io_req_bits_allowRetry;
  assign io_task_bits_order            = io_req_bits_order;
  assign io_task_bits_memAttr_allocate = io_req_bits_memAttr_allocate;
  assign io_task_bits_memAttr_cacheable = io_req_bits_memAttr_cacheable;
  assign io_task_bits_memAttr_device   = io_req_bits_memAttr_device;
  assign io_task_bits_memAttr_ewa      = io_req_bits_memAttr_ewa;
  assign io_task_bits_snpAttr          = io_req_bits_snpAttr;

endmodule
