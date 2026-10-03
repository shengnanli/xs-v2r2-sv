// AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv — one bit of a 3-flop, reset-to-0 synchronizer (rocket-chip util).
// Scala: rocket-chip/src/main/scala/util/SynchronizerReg.scala, class SynchronizerPrimitiveShiftReg
// with sync = 3, init = false, resetType = Async (desiredName "AsyncResetSynchronizerPrimitiveShiftReg_d3_i0").
// AsyncResetSynchronizerShiftReg_w1_d3_i0 / _w4_d3_i0 instantiate one per bit.  Inside XSTile the user
// is IMSICGateWay (CSR -> IMSIC_WRAP -> IMSIC -> IMSICGateWay), which brings the incoming MSI-valid
// level into the core clock domain; the uncore (debug module, time sync, AXI IMSIC) uses it too.
// What it is: a plain shift register of depth 3 whose flops all share an
// *asynchronous* reset to 0.  io_d enters at the far end (sync_2), moves one
// stage per clock, and io_q is the last stage (sync_0):
//      io_d -> sync_2 -> sync_1 -> sync_0 -> io_q
// The first flop may go metastable when io_d changes asynchronously; the two
// following flops give it two full cycles to settle.  The asynchronous reset
// lets the synchronizer come out of reset at 0 without needing a clock.
// Note the stage numbering follows rocket-chip: index 0 is the *output* end.
module xs_AsyncResetSyncShiftReg_core #(
  parameter int unsigned DEPTH = 3,       // number of synchronizer flops
  parameter logic        INIT  = 1'b0     // asynchronous reset value
) (
  input  logic clock,
  input  logic reset,
  input  logic d,
  output logic q
);
  logic [DEPTH-1:0] sync;   // sync[DEPTH-1] samples d, sync[0] drives q

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      sync <= {DEPTH{INIT}};
    else
      sync <= {d, sync[DEPTH-1:1]};
  end

  assign q = sync[0];
endmodule

module AsyncResetSynchronizerPrimitiveShiftReg_d3_i0 (
  input  clock,
  input  reset,
  input  io_d,
  output io_q
);
  xs_AsyncResetSyncShiftReg_core #(.DEPTH(3), .INIT(1'b0)) u_core (
    .clock (clock),
    .reset (reset),
    .d     (io_d),
    .q     (io_q)
  );
endmodule
