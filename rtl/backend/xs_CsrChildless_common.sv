// xs_CsrChildless_common.sv — shared canonical cores for identical childless CSR leaves.
// Mstateen1/2/3 are architecturally identical one-bit state-enable banks in G1;
// each wrapper keeps its public module name while reusing this single core.

module xs_CsrStateEnable_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic        regOut_SE
);
  logic enabled_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      enabled_q <= 1'b0;
    else if (w_wen)
      enabled_q <= w_wdata[63];
  end
  always_comb begin
    rdata = {enabled_q, 63'h0};
    regOut_SE = enabled_q;
  end
endmodule
