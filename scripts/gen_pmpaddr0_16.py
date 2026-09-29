#!/usr/bin/env python3
"""Generate readable PMP-address CSR leaves for architectural slots 0..16."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
SLOTS = range(17)


def module_text(slot: int) -> str:
    name = f"Pmpaddr{slot}Module"
    return f"""// PMP address CSR slot {slot} exposes the implemented 46-bit physical address.
// The CSR read view zero-extends that architectural field to XLEN.
// This combinational leaf contains no local state or write-side policy.
module {name} (
  output logic [63:0] rdata,
  output logic [45:0] regOut_ADDRESS,
  input  logic [63:0] addrRData_{slot}
);
  assign regOut_ADDRESS = addrRData_{slot}[45:0];
  assign rdata = {{18'b0, addrRData_{slot}[45:0]}};
endmodule
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="report generated-file drift without modifying the tree",
    )
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
        print("gen_pmpaddr0_16 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_pmpaddr0_16 --check: OK ({len(tuple(SLOTS))} files)")


if __name__ == "__main__":
    main()
