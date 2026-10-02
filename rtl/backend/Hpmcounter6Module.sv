// Hpmcounter6Module.sv — NewCSR's read-only HPM counter 6 leaf.
// The leaf exposes the live mHPM counter normally and the stopped-count
// snapshot while debugModeStopCount is asserted.  Its asynchronous reset and
// one-cycle unprivCountUpdate capture are implemented by the shared readable core.
// This wrapper retains the exact G1 golden port names; the generated region is
// maintained by scripts/gen_hpmcounter_leaves4.py and must not be hand edited.
module Hpmcounter6Module (
// BEGIN GENERATED(hpmcounter_wrapper)
  input  logic         clock,
  input  logic         reset,
  output logic [63:0]  rdata,
  input  logic [63:0]  mHPM_hpmcounters_3,
  input  logic         debugModeStopCount,
  input  logic         unprivCountUpdate
// END GENERATED
);
  xs_Hpmcounter_core #(
    .COUNTER_INDEX (3),
    .COUNTER_WIDTH (64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     (mHPM_hpmcounters_3),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata             (rdata)
  );
endmodule
