// BEGIN GENERATED(pmpcfg-leaves8)
// Pmp7cfgModule is PMP configuration CSR entry 7 in NewCSR.
// The shared core implements WARL permissions, lock behavior, and reset.
// This wrapper preserves the exact golden port contract for integration.
module Pmp7cfgModule (
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [7:0] rdata,
  output logic regOut_R,
  output logic regOut_W,
  output logic regOut_X,
  output logic [1:0] regOut_A,
  output logic regOut_L
);
  xs_Pmpcfg_core #(.SLOT(7)) u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_R(regOut_R),
    .regOut_W(regOut_W),
    .regOut_X(regOut_X),
    .regOut_A(regOut_A),
    .regOut_L(regOut_L)
  );
endmodule
// END GENERATED(pmpcfg-leaves8)
