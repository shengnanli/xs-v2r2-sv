#!/usr/bin/env python3
"""Generate the twenty unimplemented PMP-address CSR leaves (slots 33..52)."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
SLOTS = range(33, 53)


def module_text(slot: int) -> str:
    name = f"Pmpaddr{slot}Module"
    return f"""// PMP address slot {slot} is outside this configuration's implemented PMP range.
// Both architectural views therefore read as zero; this leaf has no state.
// Keeping one named wrapper per CSR slot preserves the generated top-level interface.
module {name}(
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  assign rdata = 64'b0;
  assign regOut_ALL = 64'b0;
endmodule
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = []
    for slot in SLOTS:
        path = RTL_DIR / f"Pmpaddr{slot}Module.sv"
        expected = module_text(slot)
        if args.check:
            if not path.exists() or path.read_text() != expected:
                drift.append(str(path))
        else:
            path.write_text(expected)
    if drift:
        print("gen_pmpaddr_leaves20 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_pmpaddr_leaves20 --check: OK ({len(tuple(SLOTS))} files)")


if __name__ == "__main__":
    main()
