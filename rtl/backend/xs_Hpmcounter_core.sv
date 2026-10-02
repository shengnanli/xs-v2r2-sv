// xs_Hpmcounter_core — readable shared HPM counter leaf for NewCSR.
// The stopped value is a snapshot captured only on unprivCountUpdate; while
// debugModeStopCount is low, the architectural read remains the live counter.
// Reset is asynchronous and high-active, matching every HpmcounterNModule leaf.
module xs_Hpmcounter_core #(
  parameter int HPM_INDEX = 0
) (
  input  logic        clock,
  input  logic        reset,
  input  logic [63:0] live_source,
  input  logic        debug_stop_count,
  input  logic        update_valid,
  output logic [63:0] rdata
);
  // HPM_INDEX documents the parent-array slot selected by the thin wrapper.
  // The slot is already encoded by live_source at this leaf's interface.
  logic [63:0] stopped_value;

  // The source is live during normal execution.  On entry to a stopped
  // debugging interval, NewCSR presents update_valid for one clock so this
  // register captures the final live count.  There is deliberately no
  // software-write path: these HPM CSRs are read-only in the golden design.
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      stopped_value <= 64'h0;
    else if (update_valid)
      stopped_value <= live_source;
  end

  assign rdata = debug_stop_count ? stopped_value : live_source;
endmodule
