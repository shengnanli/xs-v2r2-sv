#!/usr/bin/env python3
"""Generate the four HPM counter NewCSR wrappers.

The G1 leaves differ only in the module name and live-source port suffix.  The
state machine is shared by ``xs_Hpmcounter_core``; this generator preserves the
exact golden port declaration in each thin wrapper and keeps the generated
regions deterministic.  ``--check`` compares bytes without writing files.
"""

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "rtl/backend"
GOLDEN_DIR = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
COUNTERS = tuple(range(7, 11))
BEGIN = "// BEGIN GENERATED(hpmcounter_leaves4b)"
END = "// END GENERATED(hpmcounter_leaves4b)"


def golden_module_header(counter: int) -> str:
    """Return the exact top-level module/port declaration from G1 golden."""
    name = f"Hpmcounter{counter}Module"
    source = (GOLDEN_DIR / f"{name}.sv").read_text()
    match = re.search(rf"module\s+{re.escape(name)}\s*\(.*?\n\);", source, re.S)
    if match is None:
        raise RuntimeError(f"cannot find port header for {name}")
    return match.group(0)


def wrapper_text(counter: int) -> str:
    name = f"Hpmcounter{counter}Module"
    source_index = counter - 3
    return f"""// {name} — NewCSR read-only HPM counter leaf {counter}.
// Parent: NewCSR.  The shared core captures the live source on update_valid;
// debug stop selects that snapshot, while normal reads stay on the live source.
// The port declaration and wrapper body below are generated from G1 golden.
{BEGIN}
{golden_module_header(counter)}
  xs_Hpmcounter_core #(.HPM_INDEX({source_index})) u_core (
    .clock            (clock),
    .reset            (reset),
    .live_source      (mHPM_hpmcounters_{source_index}),
    .debug_stop_count (debugModeStopCount),
    .update_valid     (unprivCountUpdate),
    .rdata            (rdata)
  );
endmodule
{END}
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="check generated wrappers without writing")
    args = parser.parse_args()

    drift = []
    for counter in COUNTERS:
        path = RTL_DIR / f"Hpmcounter{counter}Module.sv"
        expected = wrapper_text(counter)
        if args.check:
            if not path.exists() or path.read_text() != expected:
                drift.append(str(path))
        else:
            if not path.exists() or path.read_text() != expected:
                path.write_text(expected)
                print(f"wrote {path.relative_to(ROOT)}")

    if drift:
        print("gen_hpmcounter_leaves4b --check: DRIFT: " + " ".join(drift))
        return 1
    if args.check:
        print(f"gen_hpmcounter_leaves4b --check: OK ({len(COUNTERS)} wrappers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
