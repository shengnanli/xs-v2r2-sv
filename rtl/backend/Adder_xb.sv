// Carry-out detector for a 64-bit addition with carry-in set to one.
// Widening both operands makes the carry bit explicit instead of relying on
// expression sizing; only that carry is consumed by the surrounding datapath.
module xs_Adder_xb_core (
  input  logic [63:0] lhs,
  input  logic [63:0] rhs,
  output logic        carry_out
);
  logic [64:0] extended_sum;
  assign extended_sum = {1'b0, lhs} + {1'b0, rhs} + 65'd1;
  assign carry_out = extended_sum[64];
endmodule

module Adder_xb (
  input  logic [63:0] io_in1,
  input  logic [63:0] io_in2,
  output logic        io_cout
);
  xs_Adder_xb_core u_core (.lhs(io_in1), .rhs(io_in2), .carry_out(io_cout));
endmodule
