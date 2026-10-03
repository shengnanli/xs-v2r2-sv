#!/usr/bin/env python3
"""Generate eight readable combinational shift leaves and their exact wrappers."""

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl/backend"
CHECK = "--check" in sys.argv[1:]
drift = []
count = 0


def put(name: str, text: str) -> None:
    """Write one generated RTL file, or compare it byte-for-byte in check mode."""
    global count
    count += 1
    path = RTL / f"{name}.sv"
    if CHECK:
        if not path.exists() or path.read_text() != text:
            drift.append(str(path.relative_to(ROOT)))
    else:
        path.write_text(text)


def close_left(name: str, width: int, shift_width: int) -> None:
    put(name, f"""// Fixed-width logical left shifter used by the floating-point close path.
// Bits shifted beyond the {width}-bit result are intentionally discarded.
// The shift amount remains unsigned and includes all encoded boundary values.
module xs_{name}_core (
  input  logic [{width - 1}:0]       source,
  input  logic [{shift_width - 1}:0] shift_amount,
  output logic [{width - 1}:0]       result
);
  assign result = source << shift_amount;
endmodule

module {name} (
  input  logic [{width - 1}:0]       io_src,
  input  logic [{shift_width - 1}:0] io_shiftValue,
  output logic [{width - 1}:0]       io_result
);
  xs_{name}_core u_core (
    .source       (io_src),
    .shift_amount (io_shiftValue),
    .result       (io_result)
  );
endmodule
""")


def far_right(name: str, width: int, shift_width: int) -> None:
    put(name, f"""// Fixed-width right shifter used by the floating-point far path.
// fill_bit is prepended as a sign bit, making it the value shifted into every
// vacated upper position without interpreting the source payload as signed.
module xs_{name}_core (
  input  logic [{width - 1}:0]       source,
  input  logic [{shift_width - 1}:0] shift_amount,
  input  logic                       fill_bit,
  output logic [{width - 1}:0]       result
);
  logic signed [{width}:0] source_with_fill;

  assign source_with_fill = {{fill_bit, source}};
  assign result = source_with_fill >>> shift_amount;
endmodule

module {name} (
  input  logic [{width - 1}:0]       io_src,
  input  logic [{shift_width - 1}:0] io_shiftValue,
  output logic [{width - 1}:0]       io_result,
  input  logic                       io_EOP
);
  xs_{name}_core u_core (
    .source       (io_src),
    .shift_amount (io_shiftValue),
    .fill_bit     (io_EOP),
    .result       (io_result)
  );
endmodule
""")


def dual_left(name: str, width: int, shift_width: int, normal_port: str, reverse_port: str) -> None:
    put(name, f"""// Two independent fixed-width logical left shifts of one source operand.
// Each result wraps naturally at {width} bits; no wider carry state is retained.
// Separate shift controls serve the normal and bit-reversed ALU data paths.
module xs_{name}_core (
  input  logic [{width - 1}:0]       source,
  input  logic [{shift_width - 1}:0] shift_amount,
  input  logic [{shift_width - 1}:0] reverse_shift_amount,
  output logic [{width - 1}:0]       shifted,
  output logic [{width - 1}:0]       reverse_shifted
);
  assign shifted = source << shift_amount;
  assign reverse_shifted = source << reverse_shift_amount;
endmodule

module {name} (
  input  logic [{shift_width - 1}:0] io_shamt,
  input  logic [{shift_width - 1}:0] io_revShamt,
  input  logic [{width - 1}:0]       io_sllSrc,
  output logic [{width - 1}:0]       {normal_port},
  output logic [{width - 1}:0]       {reverse_port}
);
  xs_{name}_core u_core (
    .source               (io_sllSrc),
    .shift_amount         (io_shamt),
    .reverse_shift_amount (io_revShamt),
    .shifted              ({normal_port}),
    .reverse_shifted      ({reverse_port})
  );
endmodule
""")


close_left("CloseShiftLeftWithMux", 54, 6)
close_left("CloseShiftLeftWithMux_1", 25, 5)
close_left("CloseShiftLeftWithMux_9", 12, 4)
far_right("FarShiftRightWithMuxInvFirst", 110, 6)
far_right("FarShiftRightWithMuxInvFirst_2", 52, 5)
far_right("FarShiftRightWithMuxInvFirst_18", 26, 4)
dual_left("LeftShiftModule", 64, 6, "io_sll", "io_revSll")
dual_left("LeftShiftWordModule", 32, 5, "io_sllw", "io_revSllw")

if CHECK:
    if drift:
        print("gen_shift_math8 --check: DRIFT " + " ".join(drift))
        sys.exit(1)
    print(f"gen_shift_math8 --check: OK ({count} files)")
else:
    print(f"gen_shift_math8: wrote {count} files")
