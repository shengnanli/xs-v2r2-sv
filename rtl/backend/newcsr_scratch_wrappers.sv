// NewCSR scratch family AUX wrappers (MscratchModule, SscratchModule,
// VSscratchModule). All golden bodies are byte-identical; each is a thin wrapper
// over the readable primitive xs_scratch (rtl/backend/newcsr_scratch.sv).
// FM-verified strict, no black box.
//
// VSscratchModule is the H-extension virtual-supervisor scratch register;
// Kunminghu V2R2 is hypervisor-capable so it is in scope. Same core, same pins.

module MscratchModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule

module SscratchModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule

module VSscratchModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule

// Debug-mode scratch registers and the M-mode RNMI scratch — all byte-identical
// to the xscratch primitive (plain 64-bit R/W, no reset).
module Dscratch0Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule

module Dscratch1Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule

module MnscratchModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule
