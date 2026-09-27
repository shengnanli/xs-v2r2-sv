// Carry-out detector for a 32-bit addition with carry-in set to one.
// The explicit widened sum documents both truncation and carry position.
// The exact-name wrapper keeps the generated module's public port contract.
module xs_Adder_xb_3_core (
  input  logic [31:0] lhs,
  input  logic [31:0] rhs,
  output logic        carry_out
);
  logic [32:0] extended_sum;
  assign extended_sum = {1'b0, lhs} + {1'b0, rhs} + 33'd1;
  assign carry_out = extended_sum[32];
endmodule

module Adder_xb_3 (
  input  logic [31:0] io_in1,
  input  logic [31:0] io_in2,
  output logic        io_cout
);
  xs_Adder_xb_3_core u_core (.lhs(io_in1), .rhs(io_in2), .carry_out(io_cout));
endmodule
