// epc family UT variant (_xs): instantiate the readable primitive xs_epc.
module MepcModule_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [62:0] regOut_epc,
  input trapToM_mepc_valid, input [62:0] trapToM_mepc_bits_epc
);
  xs_epc u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_epc(regOut_epc),
    .trap_valid(trapToM_mepc_valid), .trap_bits_epc(trapToM_mepc_bits_epc));
endmodule
