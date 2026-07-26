// sbpctl UT variant (_xs): a name-distinct copy of the impl body for the UT
// double-instantiation (authoritative impl is FM-verified against golden).
module SbpctlModule_xs(
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
  reg reg_LOOP_ENABLE, reg_RAS_ENABLE, reg_SC_ENABLE, reg_TAGE_ENABLE;
  reg reg_BIM_ENABLE, reg_BTB_ENABLE, reg_UBTB_ENABLE;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_LOOP_ENABLE <= 1'h1; reg_RAS_ENABLE <= 1'h1; reg_SC_ENABLE <= 1'h1;
      reg_TAGE_ENABLE <= 1'h1; reg_BIM_ENABLE <= 1'h1; reg_BTB_ENABLE <= 1'h1;
      reg_UBTB_ENABLE <= 1'h1;
    end
    else if (w_wen) begin
      reg_LOOP_ENABLE <= w_wdata[6]; reg_RAS_ENABLE <= w_wdata[5];
      reg_SC_ENABLE <= w_wdata[4]; reg_TAGE_ENABLE <= w_wdata[3];
      reg_BIM_ENABLE <= w_wdata[2]; reg_BTB_ENABLE <= w_wdata[1];
      reg_UBTB_ENABLE <= w_wdata[0];
    end
  end
  assign rdata = {57'h0, reg_LOOP_ENABLE, reg_RAS_ENABLE, reg_SC_ENABLE,
                  reg_TAGE_ENABLE, reg_BIM_ENABLE, reg_BTB_ENABLE, reg_UBTB_ENABLE};
  assign regOut_LOOP_ENABLE = reg_LOOP_ENABLE;
  assign regOut_RAS_ENABLE  = reg_RAS_ENABLE;
  assign regOut_SC_ENABLE   = reg_SC_ENABLE;
  assign regOut_TAGE_ENABLE = reg_TAGE_ENABLE;
  assign regOut_BIM_ENABLE  = reg_BIM_ENABLE;
  assign regOut_BTB_ENABLE  = reg_BTB_ENABLE;
  assign regOut_UBTB_ENABLE = reg_UBTB_ENABLE;
endmodule
