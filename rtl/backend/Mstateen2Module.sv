// Mstateen2Module.sv — one-bit machine state-enable CSR wrapper.
// Mstateen1/2/3 share xs_CsrStateEnable_core; this file preserves the
// exact G1 port contract.

module Mstateen2Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE
);
  xs_CsrStateEnable_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SE(regOut_SE)
  );
endmodule
