#!/usr/bin/env python3
"""Generate six readable logical/arithmetic right-shift leaves."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


def jam_text(name: str, width: int, shamt_width: int) -> str:
    return f"""// Shift a {width}-bit value right and report whether any discarded bit was one.
// A shift equal to the data width discards every bit; a larger shift also returns zero.
// The explicit discarded-bit mask keeps the IEEE-style sticky/jam behavior visible.
module {name} (
  input  logic [{width - 1}:0] io_in,
  input  logic [{shamt_width - 1}:0] io_shamt,
  output logic [{width - 1}:0] io_out,
  output logic                 io_sticky
);
  logic [{width - 1}:0] discarded_mask;
  logic                 exceeds_input_width;

  assign exceeds_input_width = io_shamt > {shamt_width}'d{width};
  assign discarded_mask = exceeds_input_width
    ? {{{width}{{1'b1}}}}
    : (({{{{{width - 1}{{1'b0}}}}, 1'b1}} << io_shamt) - 1'b1);

  assign io_out = exceeds_input_width ? {width}'b0 : io_in >> io_shamt;
  assign io_sticky = |(io_in & discarded_mask);
endmodule
"""


def right_shift_text(name: str, width: int, shamt_width: int, suffix: str) -> str:
    return f"""// Compute logical, arithmetic, and reverse-control right shifts for {width}-bit operands.
// Logical paths shift zeroes in; the arithmetic path propagates the source sign bit.
// Separate shift controls preserve the generated ALU leaf interface without hidden state.
module {name} (
  input  logic [{shamt_width - 1}:0] io_shamt,
  input  logic [{shamt_width - 1}:0] io_revShamt,
  input  logic [{width - 1}:0] io_srlSrc,
  input  logic [{width - 1}:0] io_sraSrc,
  output logic [{width - 1}:0] io_srl{suffix},
  output logic [{width - 1}:0] io_sra{suffix},
  output logic [{width - 1}:0] io_revSrl{suffix}
);
  assign io_srl{suffix} = io_srlSrc >> io_shamt;
  assign io_sra{suffix} = $signed(io_sraSrc) >>> io_shamt;
  assign io_revSrl{suffix} = io_srlSrc >> io_revShamt;
endmodule
"""


def generated_files():
    specs = {
        "ShiftRightJam": jam_text("ShiftRightJam", 65, 11),
        "ShiftRightJam_2": jam_text("ShiftRightJam_2", 25, 8),
        "ShiftRightJam_3": jam_text("ShiftRightJam_3", 12, 8),
        "ShiftRightJam_4": jam_text("ShiftRightJam_4", 12, 5),
        "RightShiftModule": right_shift_text("RightShiftModule", 64, 6, ""),
        "RightShiftWordModule": right_shift_text("RightShiftWordModule", 32, 5, "w"),
    }
    return {RTL_DIR / f"{name}.sv": text for name, text in specs.items()}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for path, expected in generated_files().items():
        if args.check:
            if not path.exists() or path.read_text() != expected:
                drift.append(str(path))
        else:
            path.write_text(expected)

    if drift:
        print("gen_shift_right_leaves6 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print("gen_shift_right_leaves6 --check: OK (6 files)")


if __name__ == "__main__":
    main()
