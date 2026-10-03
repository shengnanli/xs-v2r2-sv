#!/usr/bin/env python3
"""Generate six readable carry-save and state-conversion arithmetic leaves."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


def csa3(name: str, width: int) -> str:
    hi = width - 1
    carry_hi = width - 2
    return f'''// {width}-bit 3:2 carry-save compressor.
// Each bit emits parity plus a majority carry shifted toward the next bit.
// The top carry is intentionally discarded by the fixed-width interface.
module xs_{name}_core (
  input  logic [{hi}:0] operand_a,
  input  logic [{hi}:0] operand_b,
  input  logic [{hi}:0] operand_c,
  output logic [{hi}:0] sum_bits,
  output logic [{hi}:0] carry_bits
);
  logic [{hi}:0] majority_bits;

  assign sum_bits = operand_a ^ operand_b ^ operand_c;
  assign majority_bits =
    (operand_a & operand_b) | (operand_a & operand_c) | (operand_b & operand_c);
  assign carry_bits = {{majority_bits[{carry_hi}:0], 1'b0}};
endmodule

module {name} (
  input  logic [{hi}:0] io_in_a,
  input  logic [{hi}:0] io_in_b,
  input  logic [{hi}:0] io_in_c,
  output logic [{hi}:0] io_out_sum,
  output logic [{hi}:0] io_out_car
);
  xs_{name}_core u_core (
    .operand_a(io_in_a),
    .operand_b(io_in_b),
    .operand_c(io_in_c),
    .sum_bits(io_out_sum),
    .carry_bits(io_out_car)
  );
endmodule
'''


def conversion(name: str, width: int) -> str:
    hi = width - 1
    payload_hi = width - 3
    return f'''// Convert one of five adjacent radix-4 states into the next A/B pair.
// Selection is deliberately OR-masked rather than priority encoded: the
// original interface permits any five-bit mask, including multi-hot values.
module xs_{name}_core (
  input  logic [4:0] selection_mask,
  input  logic [{hi}:0] previous_a,
  input  logic [{hi}:0] previous_b,
  output logic [{hi}:0] next_a,
  output logic [{hi}:0] next_b
);
  logic [{hi}:0] a_candidates [0:4];
  logic [{hi}:0] b_candidates [0:4];
  integer candidate;

  always_comb begin
    a_candidates[0] = {{previous_a[{payload_hi}:0], 2'b10}};
    a_candidates[1] = {{previous_a[{payload_hi}:0], 2'b01}};
    a_candidates[2] = {{previous_a[{payload_hi}:0], 2'b00}};
    a_candidates[3] = {{previous_b[{payload_hi}:0], 2'b11}};
    a_candidates[4] = {{previous_b[{payload_hi}:0], 2'b10}};

    b_candidates[0] = {{previous_a[{payload_hi}:0], 2'b01}};
    b_candidates[1] = {{previous_a[{payload_hi}:0], 2'b00}};
    b_candidates[2] = {{previous_b[{payload_hi}:0], 2'b11}};
    b_candidates[3] = {{previous_b[{payload_hi}:0], 2'b10}};
    b_candidates[4] = {{previous_b[{payload_hi}:0], 2'b01}};

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

module {name} (
  input  logic [4:0] io_q_j_1,
  input  logic [{hi}:0] io_pre_q_A,
  input  logic [{hi}:0] io_pre_q_B,
  output logic [{hi}:0] io_nxt_q_A,
  output logic [{hi}:0] io_nxt_q_B
);
  xs_{name}_core u_core (
    .selection_mask(io_q_j_1),
    .previous_a(io_pre_q_A),
    .previous_b(io_pre_q_B),
    .next_a(io_nxt_q_A),
    .next_b(io_nxt_q_B)
  );
endmodule
'''


CSA4TO2_16 = '''// Eight-bit 4:2 compressor used by the multiplier reduction tree.
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
'''


OUTPUTS = {
    "CSA3to2": csa3("CSA3to2", 107),
    "CSA3to2_132": csa3("CSA3to2_132", 8),
    "CSA4to2_16": CSA4TO2_16,
    "Conversion": conversion("Conversion", 16),
    "Conversion_8": conversion("Conversion_8", 32),
    "Conversion_12": conversion("Conversion_12", 64),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for module, contents in OUTPUTS.items():
        path = RTL_DIR / f"{module}.sv"
        if args.check:
            if not path.exists() or path.read_text() != contents:
                drift.append(str(path))
        else:
            path.write_text(contents)

    if drift:
        print("gen_arithmetic_leaves6 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_arithmetic_leaves6 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
