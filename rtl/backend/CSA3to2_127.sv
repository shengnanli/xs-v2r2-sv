// 16-bit carry-save compressor with a shifted majority carry vector.
// Sum is per-bit parity; carry is the per-bit majority shifted toward MSB.
// No cross-bit propagation occurs inside this compressor stage.
module xs_CSA3to2_127_core (
  input  logic [15:0] operand_a, operand_b, operand_c,
  output logic [15:0] sum_bits, carry_bits
);
  logic [15:0] majority;
  assign sum_bits = operand_a ^ operand_b ^ operand_c;
  assign majority = (operand_a & operand_b) | (operand_a & operand_c) |
                    (operand_b & operand_c);
  assign carry_bits = {majority[14:0], 1'b0};
endmodule

module CSA3to2_127 (
  input  logic [15:0] io_in_a,
  input  logic [15:0] io_in_b,
  input  logic [15:0] io_in_c,
  output logic [15:0] io_out_sum,
  output logic [15:0] io_out_car
);
  xs_CSA3to2_127_core u_core (
    .operand_a(io_in_a), .operand_b(io_in_b), .operand_c(io_in_c),
    .sum_bits(io_out_sum), .carry_bits(io_out_car)
  );
endmodule
