// 8-bit modular subtractor used by compact datapath/index arithmetic.
// Borrow and overflow intentionally wrap at the public interface width.
// A semantic core and exact-name wrapper separate behavior from integration.
module xs_Adder_2_core (
  input logic [7:0] minuend, subtrahend,
  output logic [7:0] difference
);
  assign difference = minuend - subtrahend;
endmodule
module Adder_2 (
  input logic [7:0] io_a,
  input logic [7:0] io_b,
  output logic [7:0] io_c
);
  xs_Adder_2_core u_core (.minuend(io_a), .subtrahend(io_b), .difference(io_c));
endmodule
