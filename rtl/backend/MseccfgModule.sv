// MseccfgModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_MseccfgModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [1:0]  regOut_PMM
);
logic [1:0] reg_PMM;
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_PMM <= 2'h0;
    else if (w_wen
             & (w_wdata[33:32] == 2'h0 | w_wdata[33:32] == 2'h2 | (&(w_wdata[33:32]))))
      reg_PMM <= w_wdata[33:32];
  end // always @(posedge, posedge)
always_comb begin
    rdata = {30'h0, reg_PMM, 32'h0};
  end
  always_comb begin
    regOut_PMM = reg_PMM;
  end
endmodule

module MseccfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_PMM
);
  xs_MseccfgModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_PMM(regOut_PMM)
  );
endmodule
