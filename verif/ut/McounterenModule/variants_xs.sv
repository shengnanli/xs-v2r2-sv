// counteren UT variant (_xs): instantiate the readable primitive xs_counteren.
module McounterenModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata,
  output regOut_CY, output regOut_TM, output regOut_IR, output [28:0] regOut_HPM
);
  xs_counteren u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_CY(regOut_CY), .regOut_TM(regOut_TM),
    .regOut_IR(regOut_IR), .regOut_HPM(regOut_HPM));
endmodule
