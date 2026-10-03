#!/usr/bin/env python3
"""Generate the eight small floating-point rounding leaves in this lane."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


FULL_ROUNDERS = {
    "RoundingUnit": 23,
    "RoundingUnit_1": 52,
    "RoundingUnit_2": 10,
}

DECISION_ROUNDERS = {
    "RoundingUnit_3": 64,
    "RoundingUnit_4": 23,
    "RoundingUnit_8": 24,
    "RoundingUnit_9": 10,
    "RoundingUnit_11": 11,
}


def full_rounder(name: str, width: int) -> str:
    high = width - 1
    return f'''// {width}-bit IEEE-style significand rounding leaf.
// Guard and sticky information select the increment for RNE, RTZ, RDN,
// RUP, and RMM; the fixed-width result reports a separate carry-out.
module xs_{name}_core (
  input  logic [{high}:0] significand,
  input  logic          guard_bit,
  input  logic          sticky_bit,
  input  logic          sign,
  input  logic [2:0]    rounding_mode,
  output logic [{high}:0] rounded_significand,
  output logic          inexact,
  output logic          carry_out
);
  logic increment;

  assign inexact = guard_bit | sticky_bit;

  always_comb begin
    increment = 1'b0;
    case (rounding_mode)
      3'd0: increment = guard_bit & (sticky_bit | significand[0]); // RNE
      3'd1: increment = 1'b0;                                    // RTZ
      3'd2: increment = inexact & sign;                           // RDN
      3'd3: increment = inexact & ~sign;                          // RUP
      3'd4: increment = guard_bit;                                // RMM
      default: increment = 1'b0;
    endcase
  end

  assign rounded_significand = significand + {{{{{high}{{1'b0}}}}, increment}};
  assign carry_out = increment & (&significand);
endmodule

module {name} (
  input  logic [{high}:0] io_in,
  input  logic          io_roundIn,
  input  logic          io_stickyIn,
  input  logic          io_signIn,
  input  logic [2:0]    io_rm,
  output logic [{high}:0] io_out,
  output logic          io_inexact,
  output logic          io_cout
);
  xs_{name}_core u_core (
    .significand(io_in),
    .guard_bit(io_roundIn),
    .sticky_bit(io_stickyIn),
    .sign(io_signIn),
    .rounding_mode(io_rm),
    .rounded_significand(io_out),
    .inexact(io_inexact),
    .carry_out(io_cout)
  );
endmodule
'''


def decision_rounder(name: str, width: int) -> str:
    high = width - 1
    return f'''// {width}-bit rounding-decision leaf for floating-point conversion.
// It implements the standard five rounding directions plus rm=6 round-to-odd,
// returning the decision separately so the caller can place the increment.
module xs_{name}_core (
  input  logic [{high}:0] retained_value,
  input  logic          guard_bit,
  input  logic          sticky_bit,
  input  logic          sign,
  input  logic [2:0]    rounding_mode,
  output logic          inexact,
  output logic          round_up
);
  assign inexact = guard_bit | sticky_bit;

  always_comb begin
    round_up = 1'b0;
    case (rounding_mode)
      3'd0: round_up = guard_bit & (sticky_bit | retained_value[0]); // RNE
      3'd1: round_up = 1'b0;                                       // RTZ
      3'd2: round_up = inexact & sign;                              // RDN
      3'd3: round_up = inexact & ~sign;                             // RUP
      3'd4: round_up = guard_bit;                                   // RMM
      3'd6: round_up = inexact & ~retained_value[0];                 // ROD
      default: round_up = 1'b0;
    endcase
  end
endmodule

module {name} (
  input  logic [{high}:0] io_in,
  input  logic          io_roundIn,
  input  logic          io_stickyIn,
  input  logic          io_signIn,
  input  logic [2:0]    io_rm,
  output logic          io_inexact,
  output logic          io_r_up
);
  xs_{name}_core u_core (
    .retained_value(io_in),
    .guard_bit(io_roundIn),
    .sticky_bit(io_stickyIn),
    .sign(io_signIn),
    .rounding_mode(io_rm),
    .inexact(io_inexact),
    .round_up(io_r_up)
  );
endmodule
'''


OUTPUTS = {
    **{name: full_rounder(name, width) for name, width in FULL_ROUNDERS.items()},
    **{
        name: decision_rounder(name, width)
        for name, width in DECISION_ROUNDERS.items()
    },
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
        print("gen_rounding8 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_rounding8 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
