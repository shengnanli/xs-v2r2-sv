// =============================================================================
//  TXRSP_4 —— openLLC CHI RSP 发送通道 可读重写核 (xs_TXRSP_4_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/TXRSP.scala
//  LLC(L3) 侧: 接收内部 Task, 转成 CHI RSP flit 上发(如 SnpResp / CompAck 等)。
//  单态化 (firtool TXRSP_4.sv): 纯组合, 无寄存器/SRAM/子模块。
//
//  语义 (直通映射):
//    rsp.valid  = task.valid, task.ready = rsp.ready (握手转接)
//    rsp.opcode = task.chiOpcode[4:0]   (7b 内部 opcode 截到 5b CHI RSP opcode)
//    tgtID/srcID/txnID/resp/fwdState/dbID/pCrdType 同名直通
// =============================================================================
module xs_TXRSP_4_core (
  // ---- io.task (Flipped DecoupledIO Task, 来自 LLC 内部) ----
  output        io_task_ready,
  input         io_task_valid,
  input  [10:0] io_task_bits_tgtID,
  input  [10:0] io_task_bits_srcID,
  input  [11:0] io_task_bits_txnID,
  input  [11:0] io_task_bits_dbID,
  input  [6:0]  io_task_bits_chiOpcode,
  input  [2:0]  io_task_bits_resp,
  input  [2:0]  io_task_bits_fwdState,
  input  [3:0]  io_task_bits_pCrdType,
  // ---- io.rsp (DecoupledIO CHIRSP, 上发) ----
  input         io_rsp_ready,
  output        io_rsp_valid,
  output [10:0] io_rsp_bits_tgtID,
  output [10:0] io_rsp_bits_srcID,
  output [11:0] io_rsp_bits_txnID,
  output [4:0]  io_rsp_bits_opcode,
  output [2:0]  io_rsp_bits_resp,
  output [2:0]  io_rsp_bits_fwdState,
  output [11:0] io_rsp_bits_dbID,
  output [3:0]  io_rsp_bits_pCrdType
);

  // 握手转接
  assign io_task_ready = io_rsp_ready;
  assign io_rsp_valid  = io_task_valid;

  // RSP flit 字段
  assign io_rsp_bits_tgtID    = io_task_bits_tgtID;
  assign io_rsp_bits_srcID    = io_task_bits_srcID;
  assign io_rsp_bits_txnID    = io_task_bits_txnID;
  assign io_rsp_bits_opcode   = io_task_bits_chiOpcode[4:0];
  assign io_rsp_bits_resp     = io_task_bits_resp;
  assign io_rsp_bits_fwdState = io_task_bits_fwdState;
  assign io_rsp_bits_dbID     = io_task_bits_dbID;
  assign io_rsp_bits_pCrdType = io_task_bits_pCrdType;

endmodule
