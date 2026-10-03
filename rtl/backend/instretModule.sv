// instretModule.sv — unprivileged (instret) counter read view inside NewCSR.
// NewCSR keeps the architectural instret count in mHPM_instret; this leaf only
// holds the snapshot used while debug mode has stopped counting.
// Reset: the snapshot register has NO reset in golden (holds power-on value
// until the first unprivCountUpdate). Reproduced bug-for-bug.
// Read mux: debugModeStopCount=1 reads the frozen snapshot, 0 reads the live count.
module xs_instretModule_core (
  input  logic        clock,
  input  logic [63:0] live_count,      // mHPM_instret: live HPM counter value
  input  logic        debug_stop,      // debugModeStopCount: counting stopped in debug
  input  logic        count_update,    // unprivCountUpdate: snapshot load enable
  output logic [63:0] value
);
  // Snapshot of the counter, loaded only when the unprivileged view is updated.
  logic [63:0] snapshot_q;

  always @(posedge clock) begin
    if (count_update)
      snapshot_q <= live_count;
  end

  assign value = debug_stop ? snapshot_q : live_count;
endmodule

module instretModule (
  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_instret,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_instretModule_core u_core (
    .clock(clock),
    .live_count(mHPM_instret),
    .debug_stop(debugModeStopCount),
    .count_update(unprivCountUpdate),
    .value(rdata)
  );
endmodule
