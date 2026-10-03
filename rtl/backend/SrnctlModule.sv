// SrnctlModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SrnctlModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_WFI_ENABLE,
  output logic regOut_FUSION_ENABLE
);
logic reg_WFI_ENABLE;
  logic reg_FUSION_ENABLE;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_WFI_ENABLE <= 1'h1;
      reg_FUSION_ENABLE <= 1'h1;
    end
    else if (w_wen) begin
      reg_WFI_ENABLE <= w_wdata[2];
      reg_FUSION_ENABLE <= w_wdata[0];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {61'h0, reg_WFI_ENABLE, 1'h0, reg_FUSION_ENABLE};
  end
  always_comb begin
    regOut_WFI_ENABLE = reg_WFI_ENABLE;
  end
  always_comb begin
    regOut_FUSION_ENABLE = reg_FUSION_ENABLE;
  end
endmodule

module SrnctlModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_WFI_ENABLE,
  output        regOut_FUSION_ENABLE
);
  xs_SrnctlModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_WFI_ENABLE(regOut_WFI_ENABLE),
    .regOut_FUSION_ENABLE(regOut_FUSION_ENABLE)
  );
endmodule
