// Five-bit modular subtractor used by compact index arithmetic.
// Overflow and borrow intentionally wrap at the five-bit interface width.
// A thin exact-name wrapper preserves the generated RTL integration contract.
module xs_Adder_18_core (
  input  logic [4:0] minuend,
  input  logic [4:0] subtrahend,
  output logic [4:0] difference
);
  assign difference = minuend - subtrahend;
endmodule

module Adder_18 (
  input  logic [4:0] io_a,
  input  logic [4:0] io_b,
  output logic [4:0] io_c
);
  xs_Adder_18_core u_core (
    .minuend   (io_a),
    .subtrahend(io_b),
    .difference(io_c)
  );
endmodule
