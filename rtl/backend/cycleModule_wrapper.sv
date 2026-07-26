// NewCSR counter AUX wrapper (cycleModule). Single-module copy from newcsr_counter_wrappers.sv
// (scripts/gen_newcsr_counter.py). Thin wrapper over xs_ucounter/xs_mcounter/xs_rwlatch/xs_time.
// FM-verified against golden cycleModule.sv in signoff-strict mode. 铁律: wrapper 单独提交。
module cycleModule(
  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_cycle,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_ucounter u_core (
    .clock              (clock),
    .mhpm_src           (mHPM_cycle),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule
