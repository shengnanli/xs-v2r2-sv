// 10-bit IEEE-style significand rounding leaf.
// Guard and sticky information select the increment for RNE, RTZ, RDN,
// RUP, and RMM; the fixed-width result reports a separate carry-out.
module xs_RoundingUnit_2_core (
  input  logic [9:0] significand,
  input  logic          guard_bit,
  input  logic          sticky_bit,
  input  logic          sign,
  input  logic [2:0]    rounding_mode,
  output logic [9:0] rounded_significand,
  output logic          inexact,
  output logic          carry_out
);
  logic increment;

  assign inexact = guard_bit | sticky_bit;

  always_comb begin
    increment = 1'b0;
    case (rounding_mode)
      3'd0: increment = guard_bit & (sticky_bit | significand[0]); // RNE
      3'd1: increment = 1'b0;                                    // RTZ
      3'd2: increment = inexact & sign;                           // RDN
      3'd3: increment = inexact & ~sign;                          // RUP
      3'd4: increment = guard_bit;                                // RMM
      default: increment = 1'b0;
    endcase
  end

  assign rounded_significand = significand + {{9{1'b0}}, increment};
  assign carry_out = increment & (&significand);
endmodule

module RoundingUnit_2 (
  input  logic [9:0] io_in,
  input  logic          io_roundIn,
  input  logic          io_stickyIn,
  input  logic          io_signIn,
  input  logic [2:0]    io_rm,
  output logic [9:0] io_out,
  output logic          io_inexact,
  output logic          io_cout
);
  xs_RoundingUnit_2_core u_core (
    .significand(io_in),
    .guard_bit(io_roundIn),
    .sticky_bit(io_stickyIn),
    .sign(io_signIn),
    .rounding_mode(io_rm),
    .rounded_significand(io_out),
    .inexact(io_inexact),
    .carry_out(io_cout)
  );
endmodule
