// NewCSR Hpmcounter pilot wrapper (index 0, golden Hpmcounter3Module).
// Thin wrapper over the readable primitive xs_hpmcounter (rtl/backend/
// newcsr_hpmcounter.sv). Binds golden per-instance port mHPM_hpmcounters_0 to
// the primitive's generic mhpm_src. FM-verified against golden in strict mode.
module Hpmcounter3Module(
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
