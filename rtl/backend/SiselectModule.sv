// SiselectModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SiselectModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [12:0] regOut_ALL,
  output logic inIMSICRange
);
logic [12:0] value;
  always @(posedge clock or posedge reset) begin
    if (reset)
      value <= 13'h0;
    else if (w_wen & ~(w_wdata[12]))
      value <= w_wdata[12:0];
  end // always @(posedge, posedge)
always_comb begin
    rdata = {51'h0, value};
  end
  always_comb begin
    regOut_ALL = value;
  end
  always_comb begin
    inIMSICRange = value > 13'h6F & value < 13'h100;
  end
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
  xs_SiselectModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_ALL(regOut_ALL),
    .inIMSICRange(inIMSICRange)
  );
endmodule
