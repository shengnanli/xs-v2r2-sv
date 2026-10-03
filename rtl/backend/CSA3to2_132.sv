// 8-bit 3:2 carry-save compressor.
// Each bit emits parity plus a majority carry shifted toward the next bit.
// The top carry is intentionally discarded by the fixed-width interface.
module xs_CSA3to2_132_core (
  input  logic [7:0] operand_a,
  input  logic [7:0] operand_b,
  input  logic [7:0] operand_c,
  output logic [7:0] sum_bits,
  output logic [7:0] carry_bits
);
  logic [7:0] majority_bits;

  assign sum_bits = operand_a ^ operand_b ^ operand_c;
  assign majority_bits =
    (operand_a & operand_b) | (operand_a & operand_c) | (operand_b & operand_c);
  assign carry_bits = {majority_bits[6:0], 1'b0};
endmodule

module CSA3to2_132 (
  input  logic [7:0] io_in_a,
  input  logic [7:0] io_in_b,
  input  logic [7:0] io_in_c,
  output logic [7:0] io_out_sum,
  output logic [7:0] io_out_car
);
  xs_CSA3to2_132_core u_core (
    .operand_a(io_in_a),
    .operand_b(io_in_b),
    .operand_c(io_in_c),
    .sum_bits(io_out_sum),
    .carry_bits(io_out_car)
  );
endmodule
