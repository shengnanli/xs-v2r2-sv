// Pma8cfgModule — PMA configuration CSR leaf 8.
// Parent: NewCSR. The shared readable core preserves golden reset, WARL,
// write priority, and field layout; this file is only the exact-name wrapper.
// BEGIN GENERATED(wrapper) — scripts/gen_pmacfg_leaves8b.py
module Pma8cfgModule(
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
  xs_Pmacfg_core #(.PMA_INDEX(8)) u_core (
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
// END GENERATED(wrapper)
