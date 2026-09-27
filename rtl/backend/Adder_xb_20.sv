// Carry-out detector for an 8-bit addition with carry-in set to one.
// The explicit widened sum documents both truncation and carry position.
// The exact-name wrapper keeps the generated module's public port contract.
module xs_Adder_xb_20_core (
  input  logic [7:0] lhs,
  input  logic [7:0] rhs,
  output logic       carry_out
);
  logic [8:0] extended_sum;
  assign extended_sum = {1'b0, lhs} + {1'b0, rhs} + 9'd1;
  assign carry_out = extended_sum[8];
endmodule

module Adder_xb_20 (
  input  logic [7:0] io_in1,
  input  logic [7:0] io_in2,
  output logic       io_cout
);
  xs_Adder_xb_20_core u_core (.lhs(io_in1), .rhs(io_in2), .carry_out(io_cout));
endmodule
