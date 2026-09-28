// 200-bit carry-save compressor.  For every bit, sum is parity and carry is
// the majority bit shifted left by one; the least-significant carry is zero.
// No cross-bit propagation occurs, so this remains a single compressor stage.
module xs_CSA3to2_20_core (
  input  logic [199:0] operand_a,
  input  logic [199:0] operand_b,
  input  logic [199:0] operand_c,
  output logic [199:0] sum_bits,
  output logic [199:0] carry_bits
);
  logic [199:0] majority;
  assign sum_bits = operand_a ^ operand_b ^ operand_c;
  assign majority = (operand_a & operand_b) | (operand_a & operand_c) |
                    (operand_b & operand_c);
  assign carry_bits = {majority[198:0], 1'b0};
endmodule

module CSA3to2_20 (
  input  logic [199:0] io_in_a,
  input  logic [199:0] io_in_b,
  input  logic [199:0] io_in_c,
  output logic [199:0] io_out_sum,
  output logic [199:0] io_out_car
);
  xs_CSA3to2_20_core u_core (
    .operand_a(io_in_a), .operand_b(io_in_b), .operand_c(io_in_c),
    .sum_bits(io_out_sum), .carry_bits(io_out_car)
  );
endmodule
