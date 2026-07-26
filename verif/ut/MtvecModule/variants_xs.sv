// tvec family UT variant (_xs): instantiate the readable primitive xs_tvec.
module MtvecModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [1:0] regOut_mode, output [61:0] regOut_addr
);
  xs_tvec u_core (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_mode(regOut_mode), .regOut_addr(regOut_addr));
endmodule
