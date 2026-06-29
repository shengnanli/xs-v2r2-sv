// =============================================================================
//  RXRSP_4 —— openLLC CHI RSP 接收通道 可读重写核 (xs_RXRSP_4_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/RXRSP.scala
//  LLC(L3) 侧: 把 CHI 互联回来的 RSP flit 转成内部 Resp(无数据响应), 经 ValidIO 投出。
//  单态化 (firtool RXRSP_4.sv): 纯组合, 无寄存器/SRAM/子模块。
//
//  语义 (fromCHIRSPtoResp 直通):
//    out.valid  = in.valid          (in.ready 恒 1, 已被 firtool 优化掉)
//    out.opcode = {2'b0, in.opcode} (5b CHI RSP opcode 零扩展到 7b 内部 opcode)
//    txnID/dbID/srcID = 同名直通
// =============================================================================
module xs_RXRSP_4_core (
  // ---- io.in (Flipped DecoupledIO CHIRSP, 来自 CHI 互联) ----
  input         io_in_valid,
  input  [10:0] io_in_bits_srcID,
  input  [11:0] io_in_bits_txnID,
  input  [4:0]  io_in_bits_opcode,
  input  [11:0] io_in_bits_dbID,
  // ---- io.out (ValidIO Resp, 投向 LLC 内部) ----
  output        io_out_valid,
  output [11:0] io_out_bits_txnID,
  output [11:0] io_out_bits_dbID,
  output [6:0]  io_out_bits_opcode,
  output [10:0] io_out_bits_srcID
);

  assign io_out_valid       = io_in_valid;
  assign io_out_bits_txnID  = io_in_bits_txnID;
  assign io_out_bits_dbID   = io_in_bits_dbID;
  assign io_out_bits_opcode = {2'h0, io_in_bits_opcode};
  assign io_out_bits_srcID  = io_in_bits_srcID;

endmodule
