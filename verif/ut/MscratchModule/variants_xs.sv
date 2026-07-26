// scratch family UT variant (_xs): instantiate the readable primitive xs_scratch.
module MscratchModule_xs(
  input clock, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [63:0] regOut_ALL
);
  xs_scratch u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL));
endmodule
