// NewCSR tval family AUX wrappers (MtvalModule, StvalModule, Mtval2Module,
// MtinstModule). All golden bodies are byte-identical apart from the trap-write
// port name; each is a thin wrapper over the readable primitive xs_tval
// (rtl/backend/newcsr_tval.sv). FM-verified strict, no black box.
//
// (HtvalModule / HtinstModule / VStvalModule are H-extension guest variants,
// out of scope for this wave; they share the same core with different pins.)

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
