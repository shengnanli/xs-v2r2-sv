#!/usr/bin/env python3
"""Generate the eight PMA configuration CSR wrappers.

The register behavior is implemented once in ``xs_Pmacfg_core``.  These files
only preserve each G1 module name and exact port declaration while selecting the
corresponding PMA slot.  ``--check`` is byte-for-byte and never rewrites files.
"""

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "rtl/backend"
GOLDEN_DIR = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
SLOTS = tuple(range(8, 16))


def golden_port_header(slot: int) -> str:
    name = f"Pma{slot}cfgModule"
    source = (GOLDEN_DIR / f"{name}.sv").read_text()
    match = re.search(rf"module\s+{re.escape(name)}\s*\(.*?\n\);", source, re.S)
    if match is None:
        raise RuntimeError(f"cannot find port header for {name}")
    return match.group(0)


def wrapper_text(slot: int) -> str:
    name = f"Pma{slot}cfgModule"
    return f"""// {name} — PMA configuration CSR leaf {slot}.
// Parent: NewCSR. The shared readable core preserves golden reset, WARL,
// write priority, and field layout; this file is only the exact-name wrapper.
// BEGIN GENERATED(wrapper) — scripts/gen_pmacfg_leaves8b.py
{golden_port_header(slot)}
  xs_Pmacfg_core #(.PMA_INDEX({slot})) u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_R(regOut_R),
    .regOut_W(regOut_W),
    .regOut_X(regOut_X),
    .regOut_A(regOut_A),
    .regOut_ATOMIC(regOut_ATOMIC),
    .regOut_C(regOut_C),
    .regOut_L(regOut_L)
  );
endmodule
// END GENERATED(wrapper)
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="check generated wrappers without writing")
    args = parser.parse_args()

    expected = {
        RTL_DIR / f"Pma{slot}cfgModule.sv": wrapper_text(slot) for slot in SLOTS
    }
    drift = []
    for path, text in expected.items():
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path))
        else:
            path.write_text(text)

    if drift:
        print("gen_pmacfg_leaves8b --check: DRIFT: " + " ".join(drift))
        return 1
    if args.check:
        print(f"gen_pmacfg_leaves8b --check: OK ({len(SLOTS)} wrappers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
