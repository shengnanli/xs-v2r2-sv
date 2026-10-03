// SbpctlModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SbpctlModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_LOOP_ENABLE,
  output logic regOut_RAS_ENABLE,
  output logic regOut_SC_ENABLE,
  output logic regOut_TAGE_ENABLE,
  output logic regOut_BIM_ENABLE,
  output logic regOut_BTB_ENABLE,
  output logic regOut_UBTB_ENABLE
);
logic reg_LOOP_ENABLE;
  logic reg_RAS_ENABLE;
  logic reg_SC_ENABLE;
  logic reg_TAGE_ENABLE;
  logic reg_BIM_ENABLE;
  logic reg_BTB_ENABLE;
  logic reg_UBTB_ENABLE;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_LOOP_ENABLE <= 1'h1;
      reg_RAS_ENABLE <= 1'h1;
      reg_SC_ENABLE <= 1'h1;
      reg_TAGE_ENABLE <= 1'h1;
      reg_BIM_ENABLE <= 1'h1;
      reg_BTB_ENABLE <= 1'h1;
      reg_UBTB_ENABLE <= 1'h1;
    end
    else if (w_wen) begin
      reg_LOOP_ENABLE <= w_wdata[6];
      reg_RAS_ENABLE <= w_wdata[5];
      reg_SC_ENABLE <= w_wdata[4];
      reg_TAGE_ENABLE <= w_wdata[3];
      reg_BIM_ENABLE <= w_wdata[2];
      reg_BTB_ENABLE <= w_wdata[1];
      reg_UBTB_ENABLE <= w_wdata[0];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {57'h0,
     reg_LOOP_ENABLE,
     reg_RAS_ENABLE,
     reg_SC_ENABLE,
     reg_TAGE_ENABLE,
     reg_BIM_ENABLE,
     reg_BTB_ENABLE,
     reg_UBTB_ENABLE};
  end
  always_comb begin
    regOut_LOOP_ENABLE = reg_LOOP_ENABLE;
  end
  always_comb begin
    regOut_RAS_ENABLE = reg_RAS_ENABLE;
  end
  always_comb begin
    regOut_SC_ENABLE = reg_SC_ENABLE;
  end
  always_comb begin
    regOut_TAGE_ENABLE = reg_TAGE_ENABLE;
  end
  always_comb begin
    regOut_BIM_ENABLE = reg_BIM_ENABLE;
  end
  always_comb begin
    regOut_BTB_ENABLE = reg_BTB_ENABLE;
  end
  always_comb begin
    regOut_UBTB_ENABLE = reg_UBTB_ENABLE;
  end
endmodule

module SbpctlModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_LOOP_ENABLE,
  output        regOut_RAS_ENABLE,
  output        regOut_SC_ENABLE,
  output        regOut_TAGE_ENABLE,
  output        regOut_BIM_ENABLE,
  output        regOut_BTB_ENABLE,
  output        regOut_UBTB_ENABLE
);
  xs_SbpctlModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_LOOP_ENABLE(regOut_LOOP_ENABLE),
    .regOut_RAS_ENABLE(regOut_RAS_ENABLE),
    .regOut_SC_ENABLE(regOut_SC_ENABLE),
    .regOut_TAGE_ENABLE(regOut_TAGE_ENABLE),
    .regOut_BIM_ENABLE(regOut_BIM_ENABLE),
    .regOut_BTB_ENABLE(regOut_BTB_ENABLE),
    .regOut_UBTB_ENABLE(regOut_UBTB_ENABLE)
  );
endmodule
