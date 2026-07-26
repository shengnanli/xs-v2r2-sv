// tval family UT variant (_xs): instantiate the readable primitive xs_tval.
module MtvalModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [63:0] regOut_ALL,
  input trapToM_mtval_valid, input [63:0] trapToM_mtval_bits_ALL
);
  xs_tval u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_ALL(regOut_ALL),
    .trap_valid(trapToM_mtval_valid), .trap_bits_ALL(trapToM_mtval_bits_ALL));
endmodule
