// Hpmcounter28Module.sv — NewCSR read-only HPM counter 28 tail leaf.
// This wrapper preserves the exact G1 port contract and maps architectural
// counter 28 to parent mHPM_hpmcounters_25.  The shared core
// owns the asynchronous stopped-count snapshot and live/debug read selection.
// BEGIN GENERATED(hpmcounter-tail-wrapper)
module Hpmcounter28Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_25,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_Hpmcounter_core #(
    .COUNTER_INDEX (25),
    .COUNTER_WIDTH (64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     (mHPM_hpmcounters_25),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata             (rdata)
  );
endmodule
// END GENERATED(hpmcounter-tail-wrapper)
