#!/usr/bin/env python3
"""Generate the ten implemented PMA-address CSR leaves (slots 1..10)."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
SLOTS = range(1, 11)


def module_text(slot: int) -> str:
    name = f"Pmaaddr{slot}Module"
    return f"""// Expose PMA address slot {slot} through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same
// address value supplied by the shared PMA register bank.
module {name} (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_{slot}
);
  assign rdata = addrRData_{slot};
  assign regOut_ALL = addrRData_{slot};
endmodule
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for slot in SLOTS:
        path = RTL_DIR / f"Pmaaddr{slot}Module.sv"
        expected = module_text(slot)
        if args.check:
            if not path.exists() or path.read_text() != expected:
                drift.append(str(path))
        else:
            path.write_text(expected)

    if drift:
        print("gen_pmaaddr_leaves10 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_pmaaddr_leaves10 --check: OK ({len(tuple(SLOTS))} files)")


if __name__ == "__main__":
    main()
