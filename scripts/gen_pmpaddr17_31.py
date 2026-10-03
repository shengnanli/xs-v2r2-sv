#!/usr/bin/env python3
"""Generate the readable PMP-address CSR leaves for slots 17 through 31."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
SLOTS = range(17, 32)


def module_text(slot: int) -> str:
    name = f"Pmpaddr{slot}Module"
    return f"""// PMP address CSR slot {slot}.
// The architectural value is the low 46 address bits, zero-extended on CSR reads.
// This combinational leaf has no hidden state or side effects.
module {name} (
  output logic [63:0] rdata,
  output logic [45:0] regOut_ADDRESS,
  input  logic [63:0] addrRData_{slot}
);
  assign regOut_ADDRESS = addrRData_{slot}[45:0];
  assign rdata = {{18'b0, regOut_ADDRESS}};
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
        print("gen_pmpaddr17_31 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_pmpaddr17_31 --check: OK ({len(tuple(SLOTS))} files)")


if __name__ == "__main__":
    main()
