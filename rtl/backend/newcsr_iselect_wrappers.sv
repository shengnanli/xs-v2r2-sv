// NewCSR iselect family AUX wrappers (MiselectModule, SiselectModule,
// VSiselectModule). Thin wrappers over the readable parametric primitive
// xs_iselect (rtl/backend/newcsr_iselect.sv). FM-verified strict, no black box.
//
//   MiselectModule  : WIDTH=9,  RANGE_HI=0  (Machine indirect select)
//   SiselectModule  : WIDTH=13, RANGE_HI=1  (Supervisor indirect select)
//   VSiselectModule : WIDTH=13, RANGE_HI=1  (Virtual-supervisor, H-extension)

module MiselectModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [8:0]  regOut_ALL,
  output        inIMSICRange
);
  xs_iselect #(.WIDTH(9), .RANGE_HI(1'b0)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL), .inIMSICRange(inIMSICRange));
endmodule

module SiselectModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [12:0] regOut_ALL,
  output        inIMSICRange
);
  xs_iselect #(.WIDTH(13), .RANGE_HI(1'b1)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL), .inIMSICRange(inIMSICRange));
endmodule

module VSiselectModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [12:0] regOut_ALL,
  output        inIMSICRange
);
  xs_iselect #(.WIDTH(13), .RANGE_HI(1'b1)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL), .inIMSICRange(inIMSICRange));
endmodule
