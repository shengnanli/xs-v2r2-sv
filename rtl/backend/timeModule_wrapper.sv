// NewCSR counter AUX wrapper (timeModule). Single-module copy from newcsr_counter_wrappers.sv
// (scripts/gen_newcsr_counter.py). Thin wrapper over xs_ucounter/xs_mcounter/xs_rwlatch/xs_time.
// FM-verified against golden timeModule.sv in signoff-strict mode. 铁律: wrapper 单独提交。
module timeModule(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input         mHPM_time_valid,
  input  [63:0] mHPM_time_bits,
  input         v,
  input         nextV,
  input  [63:0] htimedelta,
  input         debugModeStopTime,
  output        updated,
  output [63:0] stime,
  output [63:0] vstime
);
  xs_time u_core (
    .clock             (clock),
    .reset             (reset),
    .rdata             (rdata),
    .mHPM_time_valid   (mHPM_time_valid),
    .mHPM_time_bits    (mHPM_time_bits),
    .v                 (v),
    .nextV             (nextV),
    .htimedelta        (htimedelta),
    .debugModeStopTime (debugModeStopTime),
    .updated           (updated),
    .stime             (stime),
    .vstime            (vstime)
  );
endmodule
