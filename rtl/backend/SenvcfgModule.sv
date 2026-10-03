// SenvcfgModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SenvcfgModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [1:0]  regOut_PMM,
  output logic regOut_CBZE,
  output logic regOut_CBCFE,
  output logic [1:0]  regOut_CBIE
);
logic [1:0] reg_PMM;
  logic       reg_CBZE;
  logic       reg_CBCFE;
  logic [1:0] reg_CBIE;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_PMM <= 2'h0;
      reg_CBZE <= 1'h1;
      reg_CBCFE <= 1'h1;
      reg_CBIE <= 2'h3;
    end
    else begin
      if (w_wen & (w_wdata[33:32] == 2'h0 | w_wdata[33:32] == 2'h2 | (&(w_wdata[33:32]))))
        reg_PMM <= w_wdata[33:32];
      if (w_wen) begin
        reg_CBZE <= w_wdata[7];
        reg_CBCFE <= w_wdata[6];
      end
      if (w_wen & (w_wdata[5:4] == 2'h0 | w_wdata[5:4] == 2'h1 | (&(w_wdata[5:4]))))
        reg_CBIE <= w_wdata[5:4];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {30'h0, reg_PMM, 24'h0, reg_CBZE, reg_CBCFE, reg_CBIE, 4'h0};
  end
  always_comb begin
    regOut_PMM = reg_PMM;
  end
  always_comb begin
    regOut_CBZE = reg_CBZE;
  end
  always_comb begin
    regOut_CBCFE = reg_CBCFE;
  end
  always_comb begin
    regOut_CBIE = reg_CBIE;
  end
endmodule

module SenvcfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [1:0]  regOut_PMM,
  output        regOut_CBZE,
  output        regOut_CBCFE,
  output [1:0]  regOut_CBIE
);
  xs_SenvcfgModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_PMM(regOut_PMM),
    .regOut_CBZE(regOut_CBZE),
    .regOut_CBCFE(regOut_CBCFE),
    .regOut_CBIE(regOut_CBIE)
  );
endmodule
