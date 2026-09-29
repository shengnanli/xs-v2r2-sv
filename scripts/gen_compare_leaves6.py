#!/usr/bin/env python3
"""Generate the six readable two-way and three-way compare leaves."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"

TWO_WAY = {
    "compare_2to1": 32,
    "compare_2to1_2": 8,
}

THREE_WAY = {
    "compare_3to1": 64,
    "compare_3to1_1": 32,
    "compare_3to1_2": 16,
    "compare_3to1_6": 8,
}


def two_way(name: str, width: int) -> str:
    return f'''// Select the signed or unsigned minimum/maximum of two values.
// Ties select A for maximum and B for minimum, matching the architectural
// priority encoded by the generated reference implementation.
module {name} (
  input  logic [{width - 1}:0] io_a,
  input  logic [{width - 1}:0] io_b,
  input  logic               io_max,
  input  logic               io_signed,
  output logic [{width - 1}:0] io_c
);
  logic a_less_than_b;

  always_comb begin
    if (io_signed)
      a_less_than_b = $signed(io_a) < $signed(io_b);
    else
      a_less_than_b = io_a < io_b;
  end

  always_comb begin
    if (io_max)
      io_c = a_less_than_b ? io_b : io_a;
    else
      io_c = a_less_than_b ? io_a : io_b;
  end
endmodule
'''


def three_way(name: str, width: int) -> str:
    return f'''// Select the signed or unsigned minimum/maximum of three values.
// Maximum ties prefer A, then B, then C. Minimum ties use the reverse
// priority: C, then B, then A. Naming every relation keeps that policy visible.
module {name} (
  input  logic [{width - 1}:0] io_a,
  input  logic [{width - 1}:0] io_b,
  input  logic [{width - 1}:0] io_c,
  input  logic               io_max,
  input  logic               io_signed,
  output logic [{width - 1}:0] io_d
);
  logic a_less_than_b;
  logic a_less_than_c;
  logic b_less_than_c;

  always_comb begin
    if (io_signed) begin
      a_less_than_b = $signed(io_a) < $signed(io_b);
      a_less_than_c = $signed(io_a) < $signed(io_c);
      b_less_than_c = $signed(io_b) < $signed(io_c);
    end else begin
      a_less_than_b = io_a < io_b;
      a_less_than_c = io_a < io_c;
      b_less_than_c = io_b < io_c;
    end
  end

  always_comb begin
    if (io_max) begin
      if (!a_less_than_b && !a_less_than_c)
        io_d = io_a;
      else if (!b_less_than_c)
        io_d = io_b;
      else
        io_d = io_c;
    end else begin
      if (a_less_than_b && a_less_than_c)
        io_d = io_a;
      else if (b_less_than_c)
        io_d = io_b;
      else
        io_d = io_c;
    end
  end
endmodule
'''


OUTPUTS = {
    **{name: two_way(name, width) for name, width in TWO_WAY.items()},
    **{name: three_way(name, width) for name, width in THREE_WAY.items()},
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for name, source in OUTPUTS.items():
        path = RTL_DIR / f"{name}.sv"
        if args.check:
            if not path.exists() or path.read_text() != source:
                drift.append(str(path))
        else:
            path.write_text(source)

    if drift:
        print("gen_compare_leaves6 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_compare_leaves6 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
