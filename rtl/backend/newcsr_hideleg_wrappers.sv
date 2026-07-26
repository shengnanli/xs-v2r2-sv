// NewCSR hideleg AUX wrapper (HidelegModule). Thin wrapper over the readable
// bespoke core xs_hideleg (rtl/backend/newcsr_hideleg.sv). FM-verified strict,
// no black box. Kunminghu V2R2 is hypervisor-capable so hideleg is in scope.

module HidelegModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSI,
  output        regOut_VSSI,
  output        regOut_MSI,
  output        regOut_STI,
  output        regOut_VSTI,
  output        regOut_MTI,
  output        regOut_SEI,
  output        regOut_VSEI,
  output        regOut_MEI,
  output        regOut_SGEI,
  output        regOut_LCOFI,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI
);
  xs_hideleg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SSI(regOut_SSI), .regOut_VSSI(regOut_VSSI), .regOut_MSI(regOut_MSI),
    .regOut_STI(regOut_STI), .regOut_VSTI(regOut_VSTI), .regOut_MTI(regOut_MTI),
    .regOut_SEI(regOut_SEI), .regOut_VSEI(regOut_VSEI), .regOut_MEI(regOut_MEI),
    .regOut_SGEI(regOut_SGEI), .regOut_LCOFI(regOut_LCOFI),
    .mideleg_SSI(mideleg_SSI), .mideleg_STI(mideleg_STI),
    .mideleg_SEI(mideleg_SEI), .mideleg_LCOFI(mideleg_LCOFI));
endmodule
