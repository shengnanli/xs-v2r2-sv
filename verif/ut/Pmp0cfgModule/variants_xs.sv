// pmpentrycfg UT variant (_xs): instantiate the readable primitive xs_pmpentrycfg.
module Pmp0cfgModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [7:0] rdata,
  output regOut_R, output regOut_W, output regOut_X,
  output [1:0] regOut_A, output regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule
