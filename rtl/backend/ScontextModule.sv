// ScontextModule.sv — supervisor context CSR (scontext).
// A 32-bit read/write register: writes store the low half of the 64-bit write
// data (w_wdata[31:0]); the CSR read data and regOut_ALL are both the raw
// 32-bit register (this CSR is narrower than the 64-bit bus by design).
// Reset: asynchronous, active-high, resets to 32'h0 (golden: always
// @(posedge clock or posedge reset)).
module xs_ScontextModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [31:0] value,
  output logic [31:0] mirror
);
  logic [31:0] context_q;

  always @(posedge clock or posedge reset) begin
    if (reset)
      context_q <= 32'h0;
    else if (wen)
      context_q <= wdata[31:0];
  end

  assign value  = context_q;
  assign mirror = context_q;
endmodule

module ScontextModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output [31:0] regOut_ALL
);
  xs_ScontextModule_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
