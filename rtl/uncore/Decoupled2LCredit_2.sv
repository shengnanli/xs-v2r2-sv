// =============================================================================
//  Decoupled2LCredit_2 —— CHI 链路层 发送侧 握手转换 可读重写核 (xs_Decoupled2LCredit_2_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class Decoupled2LCredit)
//  与 Decoupled2LCredit 同型 (信用池 + flitv 打拍), 仅 flit 净荷不同: 本变体 = DAT(422b)。
//  控制逻辑见 Decoupled2LCredit.sv 注释; 此处只是 payload 字段拼装不同。无子模块。
//  LinkStates: STOP=0 ACTIVATE=1 RUN=2 DEACTIVATE=3。
// =============================================================================
module xs_Decoupled2LCredit_2_core(
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [3:0]   io_in_bits_qos,
  input  [10:0]  io_in_bits_tgtID,
  input  [10:0]  io_in_bits_srcID,
  input  [11:0]  io_in_bits_txnID,
  input  [10:0]  io_in_bits_homeNID,
  input  [3:0]   io_in_bits_opcode,
  input  [1:0]   io_in_bits_respErr,
  input  [2:0]   io_in_bits_resp,
  input  [3:0]   io_in_bits_dataSource,
  input  [2:0]   io_in_bits_cBusy,
  input  [11:0]  io_in_bits_dbID,
  input  [1:0]   io_in_bits_ccID,
  input  [1:0]   io_in_bits_dataID,
  input  [1:0]   io_in_bits_tagOp,
  input  [7:0]   io_in_bits_tag,
  input  [1:0]   io_in_bits_tu,
  input          io_in_bits_traceTag,
  input  [3:0]   io_in_bits_rsvdc,
  input  [31:0]  io_in_bits_be,
  input  [255:0] io_in_bits_data,
  input  [31:0]  io_in_bits_dataCheck,
  input  [3:0]   io_in_bits_poison,
  output         io_out_flitpend,
  output         io_out_flitv,
  output [421:0] io_out_flit,
  input          io_out_lcrdv,
  input  [1:0]   io_state_state
);

  reg  [3:0]   lcreditPool;
  reg          out_flitpend;
  reg          out_flitv;
  reg  [421:0] out_flit;

  wire disableFlit        = (io_state_state == 2'h0) | (io_state_state == 2'h1); // STOP/ACTIVATE
  wire disableLCredit     = (io_state_state == 2'h0);                            // STOP
  wire acceptLCredit      = io_out_lcrdv & ~disableLCredit;
  wire in_ready           = (|lcreditPool) & ~disableFlit;
  wire returnLCreditValid = ~io_in_valid & (io_state_state == 2'h3) & (|lcreditPool); // DEACTIVATE
  wire flitv              = (in_ready & io_in_valid) | returnLCreditValid;

  assign io_in_ready = in_ready;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      lcreditPool  <= 4'h0;
      out_flitpend <= 1'h0;
      out_flitv    <= 1'h0;
    end
    else begin
      if (acceptLCredit) begin
        if (~flitv) lcreditPool <= lcreditPool + 4'h1;
      end
      else if (flitv)
        lcreditPool <= lcreditPool - 4'h1;
      out_flitpend <= 1'h1;
      out_flitv    <= flitv;
    end
  end

  always @(posedge clock) begin
    if (flitv)
      out_flit <= io_in_valid
        ? {io_in_bits_poison,
             io_in_bits_dataCheck,
             io_in_bits_data,
             io_in_bits_be,
             io_in_bits_rsvdc,
             io_in_bits_traceTag,
             io_in_bits_tu,
             io_in_bits_tag,
             io_in_bits_tagOp,
             io_in_bits_dataID,
             io_in_bits_ccID,
             io_in_bits_dbID,
             io_in_bits_cBusy,
             io_in_bits_dataSource,
             io_in_bits_resp,
             io_in_bits_respErr,
             io_in_bits_opcode,
             io_in_bits_homeNID,
             io_in_bits_txnID,
             io_in_bits_srcID,
             io_in_bits_tgtID,
             io_in_bits_qos}
        : 422'h0;   // 退还信用时发空 flit (LCrdReturn)
  end

  assign io_out_flitpend = out_flitpend;
  assign io_out_flitv    = out_flitv;
  assign io_out_flit     = out_flit;

endmodule
