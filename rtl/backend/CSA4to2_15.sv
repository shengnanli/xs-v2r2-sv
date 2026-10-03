// Sixteen-bit 4:2 compressor for the multiplier reduction tree.
// The first three operands form a carry-save pair; operand D is folded with the
// shifted carry.  Even/odd columns are distributed to preserve the G1 layout.
module CSA4to2_15 (
  input  logic [15:0] io_in_a,
  input  logic [15:0] io_in_b,
  input  logic [15:0] io_in_c,
  input  logic [15:0] io_in_d,
  output logic [15:0] io_out_sum,
  output logic [15:0] io_out_car
);
  logic [15:0] first_sum;
  logic [15:0] first_carry;
  logic [15:0] second_sum;
  logic [15:0] second_carry;
  logic [15:0] carry_in;
  integer bit_index;

  always_comb begin
    first_sum = io_in_a ^ io_in_b ^ io_in_c;
    first_carry = (io_in_a & io_in_b) | (io_in_a & io_in_c) | (io_in_b & io_in_c);
    carry_in = {first_carry[14:0], 1'b0};
    second_sum = first_sum ^ io_in_d ^ carry_in;
    second_carry = (first_sum & io_in_d) | (first_sum & carry_in) | (io_in_d & carry_in);
    io_out_sum = '0;
    io_out_car = '0;
    for (bit_index = 0; bit_index < 16; bit_index = bit_index + 1) begin
      if ((bit_index % 2) == 0) begin
        io_out_sum[bit_index] = second_sum[bit_index];
        if (bit_index < 15) io_out_sum[bit_index + 1] = second_carry[bit_index];
      end else begin
        io_out_car[bit_index] = second_sum[bit_index];
        if (bit_index < 15) io_out_car[bit_index + 1] = second_carry[bit_index];
      end
    end
    // The top carry column is intentionally truncated, as in G1's 16-bit leaf.
  end
endmodule
