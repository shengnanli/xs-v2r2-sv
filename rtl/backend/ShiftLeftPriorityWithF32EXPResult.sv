// ShiftLeftPriorityWithF32EXPResult.sv — f32 exponent-adjust priority left shifter on the FloatAdderWidenFormat normalize path.
//
// io_priority_shiftValue is a per-shift-amount select vector (conceptually
// one-hot, but every bit pattern is legal): the highest set bit wins and
// io_src is shifted left by that amount.  io_exp_result reports the rebased exponent 112 - shift_amount (8'h70 for the unshifted case down to 8'h67 for a shift of 9).
// An all-zero select vector (the classic Chisel PriorityMux unconditional
// last arm) shifts by WIDTH: io_lshift_result = 0 and the side output takes
// the fallback value 102 (= 112 - 10).
//
// Pure combinational: no registers, no submodules.  The readable core
// expresses the golden ternary chain as a leading-zero count plus a single
// barrel shift; the wrapper keeps the golden port names exactly.

module xs_ShiftLeftPriorityWithF32EXPResult_core (
  input  logic [9:0] src,
  input  logic [9:0] priority_select,
  output logic [9:0] lshift_result,
  output logic [7:0] exp_result
);
  localparam int WIDTH   = 10;
  localparam int COUNT_W = 4;  // must hold 0..WIDTH (fallback count)
  localparam int EXP_BIAS = 112; // golden constant: exp = EXP_BIAS - shift amount

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
    exp_result    = 8'(EXP_BIAS - shift_amount);
  end
endmodule

module ShiftLeftPriorityWithF32EXPResult (
  input  logic [9:0] io_src,
  input  logic [9:0] io_priority_shiftValue,
  output logic [9:0] io_lshift_result,
  output logic [7:0] io_exp_result
);
  xs_ShiftLeftPriorityWithF32EXPResult_core u_core (
    .src(io_src),
    .priority_select(io_priority_shiftValue),
    .lshift_result(io_lshift_result),
    .exp_result(io_exp_result)
  );
endmodule
