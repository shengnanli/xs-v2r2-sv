// Pma24cfgModule.sv — PMA configuration CSR leaf 24.
// This tail wrapper preserves the G1 module name and exact port contract while
// reusing the single canonical PMA state machine.  PMA_INDEX is the
// architectural entry number, including the 16..31 tail; it is not local.
// The shared core owns reset, WARL, write priority, and decoded outputs.
// BEGIN GENERATED(pmacfg-tail-wrapper)
module Pma24cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_ATOMIC,
  output        regOut_C,
  output        regOut_L
);
  xs_Pmacfg_core #(.PMA_INDEX(24)) u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_R(regOut_R),
    .regOut_W(regOut_W),
    .regOut_X(regOut_X),
    .regOut_A(regOut_A),
    .regOut_ATOMIC(regOut_ATOMIC),
    .regOut_C(regOut_C),
    .regOut_L(regOut_L)
  );
endmodule
// END GENERATED(pmacfg-tail-wrapper)
