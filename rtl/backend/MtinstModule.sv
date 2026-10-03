// MtinstModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_MtinstModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input         trapToM_mtinst_valid,
  input  [63:0] trapToM_mtinst_bits_ALL
);
logic [63:0] reg_ALL;
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_ALL <= 64'h0;
    else if (w_wen | trapToM_mtinst_valid)
      reg_ALL <=
        (trapToM_mtinst_valid ? trapToM_mtinst_bits_ALL : 64'h0)
        | (w_wen ? w_wdata : 64'h0);
  end // always @(posedge, posedge)
always_comb begin
    rdata = reg_ALL;
  end
  always_comb begin
    regOut_ALL = reg_ALL;
  end
endmodule

module MtinstModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         trapToM_mtinst_valid,
  input  [63:0] trapToM_mtinst_bits_ALL
);
  xs_MtinstModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_ALL(regOut_ALL),
    .trapToM_mtinst_valid(trapToM_mtinst_valid),
    .trapToM_mtinst_bits_ALL(trapToM_mtinst_bits_ALL)
  );
endmodule
