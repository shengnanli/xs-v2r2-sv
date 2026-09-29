// 64-bit rounding-decision leaf for floating-point conversion.
// It implements the standard five rounding directions plus rm=6 round-to-odd,
// returning the decision separately so the caller can place the increment.
module xs_RoundingUnit_3_core (
  input  logic [63:0] retained_value,
  input  logic          guard_bit,
  input  logic          sticky_bit,
  input  logic          sign,
  input  logic [2:0]    rounding_mode,
  output logic          inexact,
  output logic          round_up
);
  assign inexact = guard_bit | sticky_bit;

  always_comb begin
    round_up = 1'b0;
    case (rounding_mode)
      3'd0: round_up = guard_bit & (sticky_bit | retained_value[0]); // RNE
      3'd1: round_up = 1'b0;                                       // RTZ
      3'd2: round_up = inexact & sign;                              // RDN
      3'd3: round_up = inexact & ~sign;                             // RUP
      3'd4: round_up = guard_bit;                                   // RMM
      3'd6: round_up = inexact & ~retained_value[0];                 // ROD
      default: round_up = 1'b0;
    endcase
  end
endmodule

module RoundingUnit_3 (
  input  logic [63:0] io_in,
  input  logic          io_roundIn,
  input  logic          io_stickyIn,
  input  logic          io_signIn,
  input  logic [2:0]    io_rm,
  output logic          io_inexact,
  output logic          io_r_up
);
  xs_RoundingUnit_3_core u_core (
    .retained_value(io_in),
    .guard_bit(io_roundIn),
    .sticky_bit(io_stickyIn),
    .sign(io_signIn),
    .rounding_mode(io_rm),
    .inexact(io_inexact),
    .round_up(io_r_up)
  );
endmodule
