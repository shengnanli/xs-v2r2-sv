// NewCSR counteren family AUX wrappers (McounterenModule, ScounterenModule,
// HcounterenModule). All three golden bodies are byte-identical; each is a thin
// wrapper over the readable primitive xs_counteren
// (rtl/backend/newcsr_counteren.sv). FM-verified strict, no black box.
// HcounterenModule is H-extension (Kunminghu V2R2 is hypervisor-capable).

module McounterenModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
  xs_counteren u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_CY(regOut_CY), .regOut_TM(regOut_TM),
    .regOut_IR(regOut_IR), .regOut_HPM(regOut_HPM));
endmodule
module ScounterenModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
  xs_counteren u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_CY(regOut_CY), .regOut_TM(regOut_TM),
    .regOut_IR(regOut_IR), .regOut_HPM(regOut_HPM));
endmodule
module HcounterenModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
  xs_counteren u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_CY(regOut_CY), .regOut_TM(regOut_TM),
    .regOut_IR(regOut_IR), .regOut_HPM(regOut_HPM));
endmodule
