// Trigger family UT variants (_xs): instantiate the readable primitives.
// Representative shapes: tdata read, mcontrol6 tdata1 (WARL), tdata2 register.

module Tdata1Module_xs(
  output [63:0] rdata, output [63:0] regOut_ALL, input [63:0] tdataRead_tdata1
);
  xs_tdata_read u_core (.rdata(rdata), .regOut_ALL(regOut_ALL), .tdata_read(tdataRead_tdata1));
endmodule

module Trigger0_Tdata1Module_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, input canWriteDmode, input chainable
);
  xs_trigger_tdata1 u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .canWriteDmode(canWriteDmode), .chainable(chainable));
endmodule

module Trigger0_Tdata2Module_xs(
  input clock, input w_wen, input [63:0] w_wdata, output [63:0] rdata
);
  xs_trigger_tdata2 u_core (.clock(clock), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata));
endmodule
