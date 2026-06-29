// =============================================================================
//  Decoupled2LCredit_5 —— CHI 链路层 发送侧 握手转换 可读重写核 (xs_Decoupled2LCredit_5_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class Decoupled2LCredit)
//  与 Decoupled2LCredit 同型 (信用池 + flitv 打拍), 仅 flit 净荷不同: 本变体 = SNP(115b)。
//  控制逻辑见 Decoupled2LCredit.sv 注释; 此处只是 payload 字段拼装不同。无子模块。
//  LinkStates: STOP=0 ACTIVATE=1 RUN=2 DEACTIVATE=3。
// =============================================================================
module xs_Decoupled2LCredit_5_core(
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [3:0]   io_in_bits_qos,
  input  [10:0]  io_in_bits_srcID,
  input  [11:0]  io_in_bits_txnID,
  input  [10:0]  io_in_bits_fwdNID,
  input  [11:0]  io_in_bits_fwdTxnID,
  input  [4:0]   io_in_bits_opcode,
  input  [44:0]  io_in_bits_addr,
  input          io_in_bits_ns,
  input          io_in_bits_doNotGoToSD,
  input          io_in_bits_retToSrc,
  input          io_in_bits_traceTag,
  input          io_in_bits_mpam_perfMonGroup,
  input  [8:0]   io_in_bits_mpam_partID,
  input          io_in_bits_mpam_mpamNS,
  output         io_out_flitpend,
  output         io_out_flitv,
  output [114:0] io_out_flit,
  input          io_out_lcrdv,
  input  [1:0]   io_state_state
);

  reg  [3:0]   lcreditPool;
  reg          out_flitpend;
  reg          out_flitv;
  reg  [114:0] out_flit;

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
        ? {io_in_bits_mpam_perfMonGroup,
             io_in_bits_mpam_partID,
             io_in_bits_mpam_mpamNS,
             io_in_bits_traceTag,
             io_in_bits_retToSrc,
             io_in_bits_doNotGoToSD,
             io_in_bits_ns,
             io_in_bits_addr,
             io_in_bits_opcode,
             io_in_bits_fwdTxnID,
             io_in_bits_fwdNID,
             io_in_bits_txnID,
             io_in_bits_srcID,
             io_in_bits_qos}
        : 115'h0;   // 退还信用时发空 flit (LCrdReturn)
  end

  assign io_out_flitpend = out_flitpend;
  assign io_out_flitv    = out_flitv;
  assign io_out_flit     = out_flit;

endmodule
