// NewCSR tval family AUX wrappers (MtvalModule, StvalModule, Mtval2Module,
// MtinstModule, HtvalModule, HtinstModule, VStvalModule). All golden bodies are
// byte-identical apart from the trap-write port name; each is a thin wrapper
// over the readable primitive xs_tval (rtl/backend/newcsr_tval.sv). FM-verified
// strict, no black box.
//
// HtvalModule / HtinstModule (HS guest-fault value/instruction) and VStvalModule
// (virtual-supervisor trap value) are H-extension CSRs; Kunminghu V2R2 is
// hypervisor-capable so they are in scope. They share the same core with
// different trap pins.

module MtvalModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtval_valid,
  input  [63:0] trapToM_mtval_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToM_mtval_valid), .trap_bits_ALL(trapToM_mtval_bits_ALL));
endmodule

module StvalModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToHS_stval_valid,
  input  [63:0] trapToHS_stval_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToHS_stval_valid), .trap_bits_ALL(trapToHS_stval_bits_ALL));
endmodule

module Mtval2Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtval2_valid,
  input  [63:0] trapToM_mtval2_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToM_mtval2_valid), .trap_bits_ALL(trapToM_mtval2_bits_ALL));
endmodule

module MtinstModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtinst_valid,
  input  [63:0] trapToM_mtinst_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToM_mtinst_valid), .trap_bits_ALL(trapToM_mtinst_bits_ALL));
endmodule

module HtvalModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToHS_htval_valid,
  input  [63:0] trapToHS_htval_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToHS_htval_valid), .trap_bits_ALL(trapToHS_htval_bits_ALL));
endmodule

module HtinstModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToHS_htinst_valid,
  input  [63:0] trapToHS_htinst_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToHS_htinst_valid), .trap_bits_ALL(trapToHS_htinst_bits_ALL));
endmodule

module VStvalModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToVS_vstval_valid,
  input  [63:0] trapToVS_vstval_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToVS_vstval_valid), .trap_bits_ALL(trapToVS_vstval_bits_ALL));
endmodule
