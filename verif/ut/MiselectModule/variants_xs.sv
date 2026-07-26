// iselect UT variants (_xs): the readable parametric primitive at both widths.
module MiselectModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [8:0] regOut_ALL, output inIMSICRange
);
  xs_iselect #(.WIDTH(9), .RANGE_HI(1'b0)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL), .inIMSICRange(inIMSICRange));
endmodule

module SiselectModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [12:0] regOut_ALL, output inIMSICRange
);
  xs_iselect #(.WIDTH(13), .RANGE_HI(1'b1)) u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL), .inIMSICRange(inIMSICRange));
endmodule
