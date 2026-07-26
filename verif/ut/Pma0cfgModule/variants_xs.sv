// PMA family UT variants (_xs): instantiate the readable primitives.
// Representative shapes: config-entry (two distinct reset values), the 128->64
// cfg slice, and the addr pass-through.

module Pma0cfgModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [7:0] rdata, output regOut_R, regOut_W, regOut_X, output [1:0] regOut_A,
  output regOut_ATOMIC, regOut_C, regOut_L
);
  xs_pmacfg_entry #(.RESET_VAL(8'h00)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata),
    .regOut_R(regOut_R), .regOut_W(regOut_W), .regOut_X(regOut_X), .regOut_A(regOut_A),
    .regOut_ATOMIC(regOut_ATOMIC), .regOut_C(regOut_C), .regOut_L(regOut_L));
endmodule

// Pma14 exercises a non-trivial reset default (0x6F: R,W,X,A=1,ATOMIC,C).
module Pma14cfgModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [7:0] rdata, output regOut_R, regOut_W, regOut_X, output [1:0] regOut_A,
  output regOut_ATOMIC, regOut_C, regOut_L
);
  xs_pmacfg_entry #(.RESET_VAL(8'h6F)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata),
    .regOut_R(regOut_R), .regOut_W(regOut_W), .regOut_X(regOut_X), .regOut_A(regOut_A),
    .regOut_ATOMIC(regOut_ATOMIC), .regOut_C(regOut_C), .regOut_L(regOut_L));
endmodule

module Pmacfg0Module_xs(output [63:0] rdata, input [127:0] cfgRData);
  xs_pmacfg_slice #(.HI(1'b0)) u_core (.rdata(rdata), .cfgRData(cfgRData));
endmodule

module Pmaaddr0Module_xs(output [63:0] rdata, input [63:0] addrRData_0);
  xs_pmaaddr u_core (.rdata(rdata), .addr_rdata(addrRData_0));
endmodule
