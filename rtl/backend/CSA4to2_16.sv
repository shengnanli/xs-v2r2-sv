// Eight-bit 4:2 compressor used by the multiplier reduction tree.
// First compress A/B/C per bit.  The resulting majority is the carry-in of
// the next bit when D is folded in.  Even and odd columns are split between
// the two outputs, preserving sum + carry modulo 2^8 without a ripple adder.
module xs_CSA4to2_16_core (
  input  logic [7:0] operand_a,
  input  logic [7:0] operand_b,
  input  logic [7:0] operand_c,
  input  logic [7:0] operand_d,
  output logic [7:0] sum_lane,
  output logic [7:0] carry_lane
);
  logic [7:0] first_sum;
  logic [7:0] first_carry;
  logic [7:0] second_sum;
  logic [7:0] second_carry;
  logic [7:0] carry_in;
  integer bit_index;

  always_comb begin
    first_sum = operand_a ^ operand_b ^ operand_c;
    first_carry =
      (operand_a & operand_b) | (operand_a & operand_c) | (operand_b & operand_c);
    carry_in = {first_carry[6:0], 1'b0};
    second_sum = first_sum ^ operand_d ^ carry_in;
    second_carry =
      (first_sum & operand_d) | (first_sum & carry_in) | (operand_d & carry_in);

    sum_lane = '0;
    carry_lane = '0;
    for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
      if ((bit_index % 2) == 0)
        sum_lane[bit_index] = second_sum[bit_index];
      else
        carry_lane[bit_index] = second_sum[bit_index];

      if (bit_index < 7) begin
        if ((bit_index % 2) == 0)
          sum_lane[bit_index + 1] = second_carry[bit_index];
        else
          carry_lane[bit_index + 1] = second_carry[bit_index];
      end
    end
  end
endmodule

module CSA4to2_16 (
  input  logic [7:0] io_in_a,
  input  logic [7:0] io_in_b,
  input  logic [7:0] io_in_c,
  input  logic [7:0] io_in_d,
  output logic [7:0] io_out_sum,
  output logic [7:0] io_out_car
);
  xs_CSA4to2_16_core u_core (
    .operand_a(io_in_a),
    .operand_b(io_in_b),
    .operand_c(io_in_c),
    .operand_d(io_in_d),
    .sum_lane(io_out_sum),
    .carry_lane(io_out_car)
  );
endmodule
