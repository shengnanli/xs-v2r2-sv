// NewCSR mideleg AUX wrapper (MidelegModule). Thin wrapper over the readable
// bespoke core xs_mideleg (rtl/backend/newcsr_mideleg.sv). FM-verified strict,
// no black box.

module MidelegModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSI,
  output        regOut_STI,
  output        regOut_SEI,
  output        regOut_LCOFI
);
  xs_mideleg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SSI(regOut_SSI), .regOut_STI(regOut_STI),
    .regOut_SEI(regOut_SEI), .regOut_LCOFI(regOut_LCOFI));
endmodule
