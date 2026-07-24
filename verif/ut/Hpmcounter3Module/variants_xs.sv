// Hpmcounter3Module_xs —— UT 用变体(与 wrapper 同, 仅模块名改 _xs), 例化可读 primitive。
module Hpmcounter3Module_xs(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_0,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(0)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_0),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule
