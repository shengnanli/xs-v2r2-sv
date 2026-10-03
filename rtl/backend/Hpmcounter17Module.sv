// Hpmcounter17Module.sv — NewCSR read-only HPM counter 17 tail leaf.
// This wrapper preserves the exact G1 port contract and maps architectural
// counter 17 to parent mHPM_hpmcounters_14.  The shared core
// owns the asynchronous stopped-count snapshot and live/debug read selection.
// BEGIN GENERATED(hpmcounter-tail-wrapper)
module Hpmcounter17Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_14,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_Hpmcounter_core #(
    .COUNTER_INDEX (14),
    .COUNTER_WIDTH (64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     (mHPM_hpmcounters_14),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata             (rdata)
  );
endmodule
// END GENERATED(hpmcounter-tail-wrapper)
