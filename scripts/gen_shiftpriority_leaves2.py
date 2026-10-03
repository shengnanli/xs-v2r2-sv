#!/usr/bin/env python3
"""Generate the two readable FP-normalize priority-shifter leaves.

Both golden modules are a Chisel PriorityMux chain over a per-shift-amount
select vector: the highest set bit k of the select wins, the data operand is
shifted left by (WIDTH-1-k), and a side output reports the shift amount
(directly as an LZD result, or folded into a biased f32 exponent).  The
lowest-priority arm is unconditional (classic Chisel PriorityMux fallback):
an all-zero select vector shifts by WIDTH, producing a zero lshift result.

Semantics re-derived from the G1 golden files, not transliterated:
  ShiftLeftPriorityWithF32EXPResult (WIDTH=10, FloatAdderWidenFormat):
      k = index of highest set bit of io_priority_shiftValue
      io_lshift_result = io_src << (9-k)        (10-bit truncation)
      io_exp_result    = 112 - (9-k)            (0x70..0x67 for k=9..0)
      all-zero select  -> lshift 0, exp 102 (8'h66), i.e. shift amount 10
  ShiftLeftPriorityWithLZDResult (WIDTH=53, VectorFloatDividerR64):
      io_lshift_result = io_src << (52-k)       (53-bit truncation)
      io_lzd_result    = 52-k                   (0..52)
      all-zero select  -> lshift 0, lzd 53 (6'h35 = {5'h1A, 1'b1})
"""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


def shift_priority(name: str, width: int, count_w: int, secondary: str,
                   role: str, side_desc: str) -> str:
    """Readable core + golden-named wrapper for one priority-shifter leaf.

    secondary: "exp" (side output = EXP_BIAS - shift_amount, f32 flavor)
               or "lzd" (side output = shift_amount itself).
    """
    hi = width - 1
    if secondary == "exp":
        side_w = 8
        side_port = "exp_result"
        side_assign = "exp_result    = 8'(EXP_BIAS - shift_amount);"
        extra_param = ("  localparam int EXP_BIAS = 112; "
                       "// golden constant: exp = EXP_BIAS - shift amount\n")
        fallback_side = "102 (= 112 - 10)"
    else:
        side_w = count_w
        side_port = "lzd_result"
        side_assign = "lzd_result    = shift_amount;"
        extra_param = ""
        fallback_side = str(width)
    return f'''// {name}.sv — {role}
//
// io_priority_shiftValue is a per-shift-amount select vector (conceptually
// one-hot, but every bit pattern is legal): the highest set bit wins and
// io_src is shifted left by that amount.  {side_desc}
// An all-zero select vector (the classic Chisel PriorityMux unconditional
// last arm) shifts by WIDTH: io_lshift_result = 0 and the side output takes
// the fallback value {fallback_side}.
//
// Pure combinational: no registers, no submodules.  The readable core
// expresses the golden ternary chain as a leading-zero count plus a single
// barrel shift; the wrapper keeps the golden port names exactly.

module xs_{name}_core (
  input  logic [{hi}:0] src,
  input  logic [{hi}:0] priority_select,
  output logic [{hi}:0] lshift_result,
  output logic [{side_w - 1}:0] {side_port}
);
  localparam int WIDTH   = {width};
  localparam int COUNT_W = {count_w};  // must hold 0..WIDTH (fallback count)
{extra_param}
  logic [COUNT_W-1:0] shift_amount;

  always_comb begin
    // Highest set bit wins: scanning upward, each set bit overrides the
    // previous candidate, so the last (highest-index) match survives.
    // With no bit set, the fallback count WIDTH reproduces the golden
    // unconditional last arm (zero shift result, fallback side output).
    shift_amount = COUNT_W'(WIDTH);
    for (int idx = 0; idx < WIDTH; idx++)
      if (priority_select[idx])
        shift_amount = COUNT_W'(WIDTH - 1 - idx);

    lshift_result = src << shift_amount;
    {side_assign}
  end
endmodule

module {name} (
  input  logic [{hi}:0] io_src,
  input  logic [{hi}:0] io_priority_shiftValue,
  output logic [{hi}:0] io_lshift_result,
  output logic [{side_w - 1}:0] io_{side_port}
);
  xs_{name}_core u_core (
    .src(io_src),
    .priority_select(io_priority_shiftValue),
    .lshift_result(io_lshift_result),
    .{side_port}(io_{side_port})
  );
endmodule
'''


OUTPUTS = {
    "ShiftLeftPriorityWithF32EXPResult": shift_priority(
        "ShiftLeftPriorityWithF32EXPResult", 10, 4, "exp",
        "f32 exponent-adjust priority left shifter on the FloatAdderWidenFormat "
        "normalize path.",
        "io_exp_result reports the rebased exponent 112 - shift_amount "
        "(8'h70 for the unshifted case down to 8'h67 for a shift of 9)."),
    "ShiftLeftPriorityWithLZDResult": shift_priority(
        "ShiftLeftPriorityWithLZDResult", 53, 6, "lzd",
        "leading-zero-detect priority left shifter on the VectorFloatDividerR64 "
        "normalize path.",
        "io_lzd_result reports the shift amount directly (the leading-zero "
        "count of the select vector, 0..52)."),
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
        print("gen_shiftpriority_leaves2 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_shiftpriority_leaves2 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
