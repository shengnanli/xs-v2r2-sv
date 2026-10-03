// StimecmpModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_StimecmpModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [63:0] regOut_stimecmp
);
logic [63:0] reg_stimecmp;
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_stimecmp <= 64'hFFFFFFFFFFFFFFFF;
    else if (w_wen)
      reg_stimecmp <= w_wdata;
  end // always @(posedge, posedge)
always_comb begin
    rdata = reg_stimecmp;
  end
  always_comb begin
    regOut_stimecmp = reg_stimecmp;
  end
endmodule

module StimecmpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_stimecmp
);
  xs_StimecmpModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_stimecmp(regOut_stimecmp)
  );
endmodule
