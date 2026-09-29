// Convert one of five adjacent radix-4 states into the next A/B pair.
// Selection is deliberately OR-masked rather than priority encoded: the
// original interface permits any five-bit mask, including multi-hot values.
module xs_Conversion_8_core (
  input  logic [4:0] selection_mask,
  input  logic [31:0] previous_a,
  input  logic [31:0] previous_b,
  output logic [31:0] next_a,
  output logic [31:0] next_b
);
  logic [31:0] a_candidates [0:4];
  logic [31:0] b_candidates [0:4];
  integer candidate;

  always_comb begin
    a_candidates[0] = {previous_a[29:0], 2'b10};
    a_candidates[1] = {previous_a[29:0], 2'b01};
    a_candidates[2] = {previous_a[29:0], 2'b00};
    a_candidates[3] = {previous_b[29:0], 2'b11};
    a_candidates[4] = {previous_b[29:0], 2'b10};

    b_candidates[0] = {previous_a[29:0], 2'b01};
    b_candidates[1] = {previous_a[29:0], 2'b00};
    b_candidates[2] = {previous_b[29:0], 2'b11};
    b_candidates[3] = {previous_b[29:0], 2'b10};
    b_candidates[4] = {previous_b[29:0], 2'b01};

    next_a = '0;
    next_b = '0;
    for (candidate = 0; candidate < 5; candidate = candidate + 1) begin
      if (selection_mask[candidate]) begin
        next_a = next_a | a_candidates[candidate];
        next_b = next_b | b_candidates[candidate];
      end
    end
  end
endmodule

module Conversion_8 (
  input  logic [4:0] io_q_j_1,
  input  logic [31:0] io_pre_q_A,
  input  logic [31:0] io_pre_q_B,
  output logic [31:0] io_nxt_q_A,
  output logic [31:0] io_nxt_q_B
);
  xs_Conversion_8_core u_core (
    .selection_mask(io_q_j_1),
    .previous_a(io_pre_q_A),
    .previous_b(io_pre_q_B),
    .next_a(io_nxt_q_A),
    .next_b(io_nxt_q_B)
  );
endmodule
