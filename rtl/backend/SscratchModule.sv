// SscratchModule.sv — supervisor scratch CSR (sscratch).
// A plain 64-bit read/write CSR storage register: a write strobe latches the
// full write data; both the CSR read data and the regOut_ALL view read the
// register directly. All 64 bits are writable, none hardwired.
// Reset: golden gives this register NO reset (holds its power-on value until
// the first write). Reproduced bug-for-bug — do not "fix" by adding one.
module xs_SscratchModule_core (
  input  logic        clock,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [63:0] value,
  output logic [63:0] mirror
);
  logic [63:0] scratch_q;

  always @(posedge clock) begin
    if (wen)
      scratch_q <= wdata;
  end

  assign value  = scratch_q;
  assign mirror = scratch_q;
endmodule

module SscratchModule (
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_SscratchModule_core u_core (
    .clock(clock),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
