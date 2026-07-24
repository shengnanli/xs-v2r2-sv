// Mhpmcounter3Module_xs —— UT 用变体(与 wrapper 同, 仅模块名改 _xs), 例化可读 primitive。
module Mhpmcounter3Module_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
  xs_mhpmcounter #(.IDX(0)) u_core (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (w_wen),
    .w_wdata            (w_wdata),
    .rdata              (rdata),
    .regOut_ALL         (regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_CY),
    .mcountinhibit_IR   (mcountinhibit_IR),
    .mcountinhibit_HPM3 (mcountinhibit_HPM3),
    .countingEn         (countingEn),
    .perf_value         (perf_value),
    .toMhpmeventOF      (toMhpmeventOF)
  );
endmodule
