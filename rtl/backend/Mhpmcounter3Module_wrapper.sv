// NewCSR Mhpmcounter AUX wrapper (index 0, golden Mhpmcounter3Module).
// Thin wrapper over the readable primitive xs_mhpmcounter (rtl/backend/
// newcsr_mhpmcounter.sv) with IDX=0. FM-verified against golden in strict mode.
// (Extracted per-index copy of newcsr_mhpmcounter_wrappers.sv for the AUX FM;
//  the wrapper file itself must be committed — pilot omission caused a false
//  FAILED in independent AUX verification.)
module Mhpmcounter3Module(
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
