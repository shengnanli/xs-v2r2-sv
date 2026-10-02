// Hpmcounter8Module — NewCSR read-only HPM counter leaf 8.
// Parent: NewCSR.  The shared core captures the live source on update_valid;
// debug stop selects that snapshot, while normal reads stay on the live source.
// The port declaration and wrapper body below are generated from G1 golden.
// BEGIN GENERATED(hpmcounter_leaves4b)
module Hpmcounter8Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_5,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_Hpmcounter_core #(
    .COUNTER_INDEX(5),
    .COUNTER_WIDTH(64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     (mHPM_hpmcounters_5),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata            (rdata)
  );
endmodule
// END GENERATED(hpmcounter_leaves4b)
