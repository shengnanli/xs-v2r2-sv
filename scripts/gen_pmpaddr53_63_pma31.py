#!/usr/bin/env python3
"""Generate the readable PMP-address 53..63 and PMA-address 31 leaves."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
PMP_SLOTS = range(53, 64)


def pmp_text(slot: int) -> str:
    return f"""// PMP address slot {slot} is outside this configuration's implemented PMP range.
// Both architectural views therefore return zero, with no hidden state.
// The named wrapper preserves the generated CSR interface used by the parent block.
module Pmpaddr{slot}Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  assign rdata = 64'b0;
  assign regOut_ALL = 64'b0;
endmodule
"""


def pma_text() -> str:
    return """// PMA address slot 31 exposes the address value supplied by the shared PMA bank.
// The software-visible read port and the internal mirror are intentionally identical.
// This leaf is combinational and contains no local architectural state.
module Pmaaddr31Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_31
);
  assign rdata = addrRData_31;
  assign regOut_ALL = addrRData_31;
endmodule
"""


def generated_files():
    outputs = {
        RTL_DIR / f"Pmpaddr{slot}Module.sv": pmp_text(slot)
        for slot in PMP_SLOTS
    }
    outputs[RTL_DIR / "Pmaaddr31Module.sv"] = pma_text()
    return outputs


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
        print("gen_pmpaddr53_63_pma31 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print("gen_pmpaddr53_63_pma31 --check: OK (12 files)")


if __name__ == "__main__":
    main()
