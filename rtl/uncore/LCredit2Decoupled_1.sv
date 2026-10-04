// LCredit2Decoupled_1.sv — CHI link-layer receiver for the RXRSP channel of the L2 (non-blocking, 15 L-Credits).
// Scala: coupledL2/tl2chi/chi/LinkLayer.scala (class LCredit2Decoupled, blocking = false),
// instantiated by LinkMonitor as `LCredit2Decoupled_rxrsp` (LinkLayer.scala:398,
// `LCredit2Decoupled(io.out.rx.rsp, io.in.rx.rsp, ..., Some("rxrsp"), 15, false)`).
// Same mechanism as LCredit2Decoupled_2 (RXDAT); only the flit type differs (CHIRSP, 73 bits).
//
// CHI link layer flow control: the receiver hands out L-Credits (one per flit
// it can accept); the sender may only send a flit while it holds a credit.
//   pool      credits still held here (reset = 15)
//   inflight  credits handed out and not yet used by a flit (reset = 0)
//   invariant pool + inflight == 15 (LinkLayer.scala:155 assert, off under SYNTHESIS)
//   give      a credit is sent (io_in_lcrdv, one cycle later) when the pool is
//             non-empty, the link is in RUN, *and* the consumer is ready —
//             this non-blocking variant has no queue, so a flit that arrives
//             must be taken by io_out in the same cycle.
//   accept    a flit arrives (flitv) while some credit is in flight.
//   give & accept in the same cycle cancel out; otherwise one credit moves.
//   reclaimLCredit = no credit in flight (LinkMonitor may drop rx.linkactiveack).
// The flit is unpacked field by field into io_out_bits (no buffering).  A flit
// with opcode 0 is an RSPLCrdReturn: it returns a credit but carries no
// response, so it is accepted and dropped (io_out_valid stays low).
// LinkMonitor counts RetryAck (opcode 3) / PCrdGrant (opcode 7) off io_out.
// Reset: asynchronous; the two counters and the lcrdv flop.
package lcredit2decoupled_1_pkg;
  // CHIRSP flit as it travels on the wire: the Scala bundle elements packed
  // LSB-first in declaration order, i.e. qos at bit 0 ... traceTag at bit 72.
  typedef struct packed {
    logic         traceTag;
    logic [1:0]   tagOp;
    logic [3:0]   pCrdType;
    logic [11:0]  dbID;
    logic [2:0]   cBusy;
    logic [2:0]   fwdState;
    logic [2:0]   resp;
    logic [1:0]   respErr;
    logic [4:0]   opcode;
    logic [11:0]  txnID;
    logic [10:0]  srcID;
    logic [10:0]  tgtID;
    logic [3:0]   qos;
  } chi_rsp_flit_t;

  localparam int unsigned LCREDIT_NUM = 15;
  localparam int unsigned LCREDIT_W   = $clog2(LCREDIT_NUM) + 1;   // log2Up(15)+1 = 5
  localparam logic [1:0]  LINK_RUN    = 2'h2;                      // LinkStates.RUN
endpackage

module xs_LCredit2Decoupled_1_core
  import lcredit2decoupled_1_pkg::*;
(
  input  logic          clock,
  input  logic          reset,
  input  logic          in_flitv,
  input  chi_rsp_flit_t in_flit,
  output logic          in_lcrdv,
  input  logic          out_ready,
  output logic          out_valid,
  output chi_rsp_flit_t out_bits,
  input  logic [1:0]    link_state,
  output logic          reclaim_lcredit
);
  // ---------------------------------------------------------------------------
  // L-Credit bookkeeping
  // ---------------------------------------------------------------------------
  logic [LCREDIT_W-1:0] lcredit_inflight;
  logic [LCREDIT_W-1:0] lcredit_pool;
  logic                 accept;       // a flit arrives against an in-flight credit
  logic                 give_credit;  // hand one credit to the sender this cycle
  logic                 lcrdv_q;

  assign accept      = (lcredit_inflight != '0) & in_flitv;
  assign give_credit = (lcredit_pool != '0) & (link_state == LINK_RUN) & out_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      lcredit_inflight <= '0;
      lcredit_pool     <= LCREDIT_W'(LCREDIT_NUM);
      lcrdv_q          <= 1'b0;
    end else begin
      if (give_credit & ~accept) begin
        lcredit_inflight <= lcredit_inflight + 1'b1;
        lcredit_pool     <= lcredit_pool - 1'b1;
      end else if (~give_credit & accept) begin
        lcredit_inflight <= lcredit_inflight - 1'b1;
        lcredit_pool     <= lcredit_pool + 1'b1;
      end
      lcrdv_q <= give_credit;       // RegNext(lcreditOut, false.B)
    end
  end

  assign in_lcrdv        = lcrdv_q;
  assign reclaim_lcredit = (lcredit_inflight == '0);

  // ---------------------------------------------------------------------------
  // Unpack (no queue) and drop LCrdReturn flits (opcode 0)
  // ---------------------------------------------------------------------------
  assign out_bits  = in_flit;
  assign out_valid = accept & (in_flit.opcode != '0);
endmodule

// golden-named wrapper: the flit is a bare 73-bit vector, the output a list
// of per-field ports.
module LCredit2Decoupled_1
  import lcredit2decoupled_1_pkg::*;
(
  input         clock,
  input         reset,
  input         io_in_flitv,
  input  [72:0] io_in_flit,
  output        io_in_lcrdv,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
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
  input  [1:0]  io_state_state,
  output        io_reclaimLCredit
);
  chi_rsp_flit_t out_bits;

  xs_LCredit2Decoupled_1_core u_core (
    .clock           (clock),
    .reset           (reset),
    .in_flitv        (io_in_flitv),
    .in_flit         (io_in_flit),
    .in_lcrdv        (io_in_lcrdv),
    .out_ready       (io_out_ready),
    .out_valid       (io_out_valid),
    .out_bits        (out_bits),
    .link_state      (io_state_state),
    .reclaim_lcredit (io_reclaimLCredit)
  );

  assign io_out_bits_qos      = out_bits.qos;
  assign io_out_bits_tgtID    = out_bits.tgtID;
  assign io_out_bits_srcID    = out_bits.srcID;
  assign io_out_bits_txnID    = out_bits.txnID;
  assign io_out_bits_opcode   = out_bits.opcode;
  assign io_out_bits_respErr  = out_bits.respErr;
  assign io_out_bits_resp     = out_bits.resp;
  assign io_out_bits_fwdState = out_bits.fwdState;
  assign io_out_bits_cBusy    = out_bits.cBusy;
  assign io_out_bits_dbID     = out_bits.dbID;
  assign io_out_bits_pCrdType = out_bits.pCrdType;
  assign io_out_bits_tagOp    = out_bits.tagOp;
  assign io_out_bits_traceTag = out_bits.traceTag;
endmodule
