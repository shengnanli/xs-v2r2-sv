// =============================================================================
//  RXRSP —— coupledL2 (tl2chi) CHI RSP 接收通道 可读重写核 (xs_RXRSP_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/tl2chi/RXRSP.scala
//  把 CHI 互联回来的 RSP flit (Comp / CompDBIDResp / RetryAck / PCrdGrant) 拆成
//  内部 RespBundle, 投给 MSHRCtl 按 txnID(=mshrId) 路由。
//  单态化 (firtool RXRSP.sv): 纯组合, 无寄存器/SRAM/子模块。
//
//  语义 (全部直通映射):
//    in.valid              = out.valid                 (out.ready 恒 1, 已被 firtool 优化掉)
//    in.mshrId             = out.txnID[7:0]            (CHI txnID 低 8 位即 MSHR 号)
//    in.respInfo.chiOpcode = {2'b0, out.opcode}        (5b CHI opcode 零扩展到 7b)
//    其余 respInfo 字段     = 同名 out 字段直通; set/tag/last 在 Scala 里为常量(此处无端口)
// =============================================================================
module xs_RXRSP_core (
  // ---- io.out (Flipped DecoupledIO CHIRSP, 来自 CHI 互联的 RSP flit) ----
  input         io_out_valid,
  input  [10:0] io_out_bits_srcID,
  input  [11:0] io_out_bits_txnID,
  input  [4:0]  io_out_bits_opcode,
  input  [1:0]  io_out_bits_respErr,
  input  [2:0]  io_out_bits_resp,
  input  [11:0] io_out_bits_dbID,
  input  [3:0]  io_out_bits_pCrdType,
  input         io_out_bits_traceTag,
  // ---- io.in (Output RespBundle, 投向 MSHRCtl) ----
  output        io_in_valid,
  output [7:0]  io_in_mshrId,
  output [6:0]  io_in_respInfo_chiOpcode,
  output [10:0] io_in_respInfo_srcID,
  output [11:0] io_in_respInfo_dbID,
  output [2:0]  io_in_respInfo_resp,
  output [3:0]  io_in_respInfo_pCrdType,
  output [1:0]  io_in_respInfo_respErr,
  output        io_in_respInfo_traceTag
);

  assign io_in_valid              = io_out_valid;
  assign io_in_mshrId             = io_out_bits_txnID[7:0];
  assign io_in_respInfo_chiOpcode = {2'h0, io_out_bits_opcode};
  assign io_in_respInfo_srcID     = io_out_bits_srcID;
  assign io_in_respInfo_dbID      = io_out_bits_dbID;
  assign io_in_respInfo_resp      = io_out_bits_resp;
  assign io_in_respInfo_pCrdType  = io_out_bits_pCrdType;
  assign io_in_respInfo_respErr   = io_out_bits_respErr;
  assign io_in_respInfo_traceTag  = io_out_bits_traceTag;

endmodule
