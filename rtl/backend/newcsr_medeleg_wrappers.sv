// NewCSR medeleg AUX wrapper (MedelegModule). Thin wrapper over the readable
// bespoke core xs_medeleg (rtl/backend/newcsr_medeleg.sv). FM-verified strict,
// no black box.

module MedelegModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_EX_IAM,
  output        regOut_EX_IAF,
  output        regOut_EX_II,
  output        regOut_EX_BP,
  output        regOut_EX_LAM,
  output        regOut_EX_LAF,
  output        regOut_EX_SAM,
  output        regOut_EX_SAF,
  output        regOut_EX_UCALL,
  output        regOut_EX_HSCALL,
  output        regOut_EX_VSCALL,
  output        regOut_EX_IPF,
  output        regOut_EX_LPF,
  output        regOut_EX_SPF,
  output        regOut_EX_SWC,
  output        regOut_EX_HWE,
  output        regOut_EX_IGPF,
  output        regOut_EX_LGPF,
  output        regOut_EX_VI,
  output        regOut_EX_SGPF
);
  xs_medeleg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_EX_IAM(regOut_EX_IAM), .regOut_EX_IAF(regOut_EX_IAF),
    .regOut_EX_II(regOut_EX_II), .regOut_EX_BP(regOut_EX_BP),
    .regOut_EX_LAM(regOut_EX_LAM), .regOut_EX_LAF(regOut_EX_LAF),
    .regOut_EX_SAM(regOut_EX_SAM), .regOut_EX_SAF(regOut_EX_SAF),
    .regOut_EX_UCALL(regOut_EX_UCALL), .regOut_EX_HSCALL(regOut_EX_HSCALL),
    .regOut_EX_VSCALL(regOut_EX_VSCALL), .regOut_EX_IPF(regOut_EX_IPF),
    .regOut_EX_LPF(regOut_EX_LPF), .regOut_EX_SPF(regOut_EX_SPF),
    .regOut_EX_SWC(regOut_EX_SWC), .regOut_EX_HWE(regOut_EX_HWE),
    .regOut_EX_IGPF(regOut_EX_IGPF), .regOut_EX_LGPF(regOut_EX_LGPF),
    .regOut_EX_VI(regOut_EX_VI), .regOut_EX_SGPF(regOut_EX_SGPF));
endmodule
