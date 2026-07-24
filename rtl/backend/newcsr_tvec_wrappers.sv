// NewCSR tvec family AUX wrappers (MtvecModule, StvecModule, VStvecModule).
// All three golden modules are byte-identical; each is a thin wrapper over the
// readable primitive xs_tvec (rtl/backend/newcsr_tvec.sv). FM-verified strict.

module MtvecModule(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [1:0] regOut_mode, output [61:0] regOut_addr
);
  xs_tvec u_core (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_mode(regOut_mode), .regOut_addr(regOut_addr));
endmodule

module StvecModule(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [1:0] regOut_mode, output [61:0] regOut_addr
);
  xs_tvec u_core (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_mode(regOut_mode), .regOut_addr(regOut_addr));
endmodule

module VStvecModule(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output [1:0] regOut_mode, output [61:0] regOut_addr
);
  xs_tvec u_core (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_mode(regOut_mode), .regOut_addr(regOut_addr));
endmodule
