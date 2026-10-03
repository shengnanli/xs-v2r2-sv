// McorepwrModule.sv — machine core power policy CSR.
// Both enable bits are reset and then replaced together by each valid CSR write.
// The wrapper preserves the exact machine CSR integration ports.
module xs_McorepwrModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata,
  output logic commit_stuck_check_enable,
  output logic power_down_enable
);
  logic commit_stuck_check_enable_q, power_down_enable_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      commit_stuck_check_enable_q <= 1'b0;
      power_down_enable_q <= 1'b0;
    end else if (csr_wen) begin
      commit_stuck_check_enable_q <= csr_wdata[1];
      power_down_enable_q <= csr_wdata[0];
    end
  end

  assign rdata = {62'h0, commit_stuck_check_enable_q, power_down_enable_q};
  assign commit_stuck_check_enable = commit_stuck_check_enable_q;
  assign power_down_enable = power_down_enable_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module McorepwrModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_COMMIT_STUCK_CHECK_ENABLE,
  output        regOut_POWER_DOWN_ENABLE
);

  xs_McorepwrModule_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .csr_wen                   (w_wen),
    .csr_wdata                 (w_wdata),
    .rdata                     (rdata),
    .commit_stuck_check_enable (regOut_COMMIT_STUCK_CHECK_ENABLE),
    .power_down_enable         (regOut_POWER_DOWN_ENABLE)
  );
endmodule
// END GENERATED
