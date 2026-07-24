// Pmpaddr0Module_xs —— UT 用变体(与 wrapper 同, 仅模块名改 _xs), 例化可读 primitive。
module Pmpaddr0Module_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_0
);
  xs_pmpaddr #(.IDX(0)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_0)
  );
endmodule
