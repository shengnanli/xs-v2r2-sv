#!/usr/bin/env python3
"""Generate the four HPM counter leaf wrappers.

The G1 golden leaves are structurally identical apart from the leaf number and
its mHPM input name.  This generator reads each golden port list, asserts that
all four leaves retain the same shape, and updates only the marked port region
in the corresponding readable wrapper.  ``--check`` is deterministic and
reports drift without modifying any file.
"""
import argparse
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
RTL_DIR = REPO / "rtl" / "backend"
LEAVES = (3, 4, 5, 6)
BEGIN = "// BEGIN GENERATED(hpmcounter_wrapper)"
END = "// END GENERATED"
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$")


def golden_ports(leaf: int) -> List[Tuple[str, Optional[int], str]]:
    text = (GOLDEN / f"Hpmcounter{leaf}Module.sv").read_text()
    marker = f"module Hpmcounter{leaf}Module("
    start = text.index(marker)
    end = text.index("\n);", start)
    ports = []  # type: List[Tuple[str, Optional[int], str]]
    for line in text[start:end].splitlines()[1:]:
        match = PORT_RE.match(line)
        if not match:
            raise AssertionError(f"Hpmcounter{leaf}Module: cannot parse port line {line!r}")
        ports.append((match.group(1), int(match.group(2)) if match.group(2) else None, match.group(3)))
    if not ports:
        raise AssertionError(f"Hpmcounter{leaf}Module: empty port list")
    return ports


def generated_region(ports: List[Tuple[str, Optional[int], str]]) -> str:
    lines = []
    for index, (direction, msb, name) in enumerate(ports):
        width = f"[{msb}:0]" if msb is not None else ""
        comma = "" if index == len(ports) - 1 else ","
        lines.append(f"  {direction:<6} logic {width:<8}{name}{comma}")
    return BEGIN + "\n" + "\n".join(lines) + "\n" + END


def template(leaf: int, counter_index: int, ports: List[Tuple[str, Optional[int], str]]) -> str:
    source_name = f"mHPM_hpmcounters_{counter_index}"
    return f"""// Hpmcounter{leaf}Module.sv — NewCSR's read-only HPM counter {leaf} leaf.
// The leaf exposes the live mHPM counter normally and the stopped-count
// snapshot while debugModeStopCount is asserted.  Its asynchronous reset and
// one-cycle unprivCountUpdate capture are implemented by the shared readable core.
// This wrapper retains the exact G1 golden port names; the generated region is
// maintained by scripts/gen_hpmcounter_leaves4.py and must not be hand edited.
module Hpmcounter{leaf}Module (
{generated_region(ports)}
);
  xs_Hpmcounter_core #(
    .COUNTER_INDEX ({counter_index}),
    .COUNTER_WIDTH (64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     ({source_name}),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata             (rdata)
  );
endmodule
"""


def regenerate(path: Path, leaf: int, counter_index: int, ports: List[Tuple[str, Optional[int], str]]) -> str:
    region = generated_region(ports)
    if not path.exists():
        return template(leaf, counter_index, ports)
    text = path.read_text()
    begin = text.find(BEGIN)
    end = text.find(END)
    if begin < 0 or end < 0 or begin >= end:
        raise AssertionError(f"{path}: missing or malformed BEGIN/END GENERATED markers")
    return text[:begin] + region + text[end + len(END):]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="check generated files without writing")
    args = parser.parse_args()

    per_leaf = {leaf: golden_ports(leaf) for leaf in LEAVES}
    base = per_leaf[LEAVES[0]]
    for leaf, ports in per_leaf.items():
        normalized = [(direction, width, name.replace(f"_{leaf - 3}", "_N")) for direction, width, name in ports]
        normalized_base = [(direction, width, name.replace("_0", "_N")) for direction, width, name in base]
        if normalized != normalized_base:
            raise AssertionError(f"Hpmcounter{leaf}Module port shape differs from Hpmcounter3Module")

    drift = []  # type: List[str]
    for leaf in LEAVES:
        path = RTL_DIR / f"Hpmcounter{leaf}Module.sv"
        new_text = regenerate(path, leaf, leaf - 3, per_leaf[leaf])
        if args.check:
            if not path.exists() or path.read_text() != new_text:
                drift.append(str(path))
        elif not path.exists() or path.read_text() != new_text:
            path.write_text(new_text)

    if drift:
        print("gen_hpmcounter_leaves4 --check: DRIFT: " + " ".join(drift))
        return 1
    if args.check:
        print(f"gen_hpmcounter_leaves4 --check: OK ({len(LEAVES)} files)")
    else:
        print(f"gen_hpmcounter_leaves4: generated {len(LEAVES)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
