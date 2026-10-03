// Hpmcounter31Module.sv — NewCSR read-only HPM counter 31 tail leaf.
// This wrapper preserves the exact G1 port contract and maps architectural
// counter 31 to parent mHPM_hpmcounters_28.  The shared core
// owns the asynchronous stopped-count snapshot and live/debug read selection.
// BEGIN GENERATED(hpmcounter-tail-wrapper)
module Hpmcounter31Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_28,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_Hpmcounter_core #(
    .COUNTER_INDEX (28),
    .COUNTER_WIDTH (64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     (mHPM_hpmcounters_28),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata             (rdata)
  );
endmodule
// END GENERATED(hpmcounter-tail-wrapper)
