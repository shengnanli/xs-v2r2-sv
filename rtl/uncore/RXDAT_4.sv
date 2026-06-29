// =============================================================================
//  RXDAT_4 —— openLLC CHI DAT 接收通道 可读重写核 (xs_RXDAT_4_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/RXDAT.scala
//  LLC(L3) 侧: 把 CHI 互联回来的 DAT flit(CompData) 转成内部 RespWithData(带数据响应)。
//  单态化 (firtool RXDAT_4.sv): 纯组合, 无寄存器/SRAM/子模块。
//
//  语义 (fromCHIRSPtoRespWithData 直通):
//    out.valid     = in.valid             (in.ready 恒 1, 已被 firtool 优化掉)
//    out.opcode    = {3'b0, in.opcode}    (4b CHI DAT opcode 零扩展到 7b 内部 opcode)
//    out.data.data = in.data (256b 一拍数据), dataID/resp/srcID/txnID 同名直通
// =============================================================================
module xs_RXDAT_4_core (
  // ---- io.in (Flipped DecoupledIO CHIDAT, 来自 CHI 互联) ----
  input          io_in_valid,
  input  [10:0]  io_in_bits_srcID,
  input  [11:0]  io_in_bits_txnID,
  input  [3:0]   io_in_bits_opcode,
  input  [2:0]   io_in_bits_resp,
  input  [1:0]   io_in_bits_dataID,
  input  [255:0] io_in_bits_data,
  // ---- io.out (ValidIO RespWithData, 投向 LLC 内部) ----
  output         io_out_valid,
  output [11:0]  io_out_bits_txnID,
  output [6:0]   io_out_bits_opcode,
  output [2:0]   io_out_bits_resp,
  output [10:0]  io_out_bits_srcID,
  output [1:0]   io_out_bits_dataID,
  output [255:0] io_out_bits_data_data
);

  assign io_out_valid          = io_in_valid;
  assign io_out_bits_txnID     = io_in_bits_txnID;
  assign io_out_bits_opcode    = {3'h0, io_in_bits_opcode};
  assign io_out_bits_resp      = io_in_bits_resp;
  assign io_out_bits_srcID     = io_in_bits_srcID;
  assign io_out_bits_dataID    = io_in_bits_dataID;
  assign io_out_bits_data_data = io_in_bits_data;

endmodule
