// ShiftLeftPriorityWithLZDResult.sv — leading-zero-detect priority left shifter on the VectorFloatDividerR64 normalize path.
//
// io_priority_shiftValue is a per-shift-amount select vector (conceptually
// one-hot, but every bit pattern is legal): the highest set bit wins and
// io_src is shifted left by that amount.  io_lzd_result reports the shift amount directly (the leading-zero count of the select vector, 0..52).
// An all-zero select vector (the classic Chisel PriorityMux unconditional
// last arm) shifts by WIDTH: io_lshift_result = 0 and the side output takes
// the fallback value 53.
//
// Pure combinational: no registers, no submodules.  The readable core
// expresses the golden ternary chain as a leading-zero count plus a single
// barrel shift; the wrapper keeps the golden port names exactly.

module xs_ShiftLeftPriorityWithLZDResult_core (
  input  logic [52:0] src,
  input  logic [52:0] priority_select,
  output logic [52:0] lshift_result,
  output logic [5:0] lzd_result
);
  localparam int WIDTH   = 53;
  localparam int COUNT_W = 6;  // must hold 0..WIDTH (fallback count)

  logic [COUNT_W-1:0] shift_amount;

  always_comb begin
    // Highest set bit wins: scanning upward, each set bit overrides the
    // previous candidate, so the last (highest-index) match survives.
    // With no bit set, the fallback count WIDTH reproduces the golden
    // unconditional last arm (zero shift result, fallback side output).
    shift_amount = COUNT_W'(WIDTH);
    for (int idx = 0; idx < WIDTH; idx++)
      if (priority_select[idx])
        shift_amount = COUNT_W'(WIDTH - 1 - idx);

    lshift_result = src << shift_amount;
    lzd_result    = shift_amount;
  end
endmodule

module ShiftLeftPriorityWithLZDResult (
  input  logic [52:0] io_src,
  input  logic [52:0] io_priority_shiftValue,
  output logic [52:0] io_lshift_result,
  output logic [5:0] io_lzd_result
);
  xs_ShiftLeftPriorityWithLZDResult_core u_core (
    .src(io_src),
    .priority_select(io_priority_shiftValue),
    .lshift_result(io_lshift_result),
    .lzd_result(io_lzd_result)
  );
endmodule
