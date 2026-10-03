#!/usr/bin/env python3
"""Generate the HPM CSR tail wrappers (Hpmcounter11..31 and Mhpmcounter3..31).

The G1 golden files are the only source for each wrapper port contract.  The
Hpmcounter leaves reuse xs_Hpmcounter_core and map architectural N to parent
source slot N-3.  The Mhpmcounter leaves reuse the canonical xs_mhpmcounter
core and map N to mcountinhibit_HPM3[N-3].  ``--check`` is deterministic and
never writes.
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "rtl" / "backend"
GOLDEN_DIR = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
HPM_COUNTERS = tuple(range(11, 32))
MHPM_COUNTERS = tuple(range(3, 32))
BEGIN_HPM = "// BEGIN GENERATED(hpmcounter-tail-wrapper)"
END_HPM = "// END GENERATED(hpmcounter-tail-wrapper)"
BEGIN_MHPM = "// BEGIN GENERATED(mhpmcounter-tail-wrapper)"
END_MHPM = "// END GENERATED(mhpmcounter-tail-wrapper)"


def golden_header(name: str) -> str:
    text = (GOLDEN_DIR / (name + ".sv")).read_text()
    match = re.search(r"module\s+" + re.escape(name) + r"\s*\(.*?\n\);", text, re.S)
    if match is None:
        raise RuntimeError("missing golden port header for " + name)
    return match.group(0)


def normalized_header(name: str, family_pattern: str) -> str:
    header = re.sub(r"module\s+" + re.escape(name), "module " + family_pattern,
                    golden_header(name), count=1)
    if family_pattern == "HpmcounterXModule":
        header = re.sub(r"mHPM_hpmcounters_\d+", "mHPM_hpmcounters_X", header)
    return header


def assert_same_headers(names, family_pattern: str) -> None:
    contracts = [normalized_header(name, family_pattern) for name in names]
    if any(contract != contracts[0] for contract in contracts[1:]):
        raise RuntimeError("golden port contracts differ in " + family_pattern + " family")


def hpm_wrapper(counter: int) -> str:
    name = f"Hpmcounter{counter}Module"
    source_index = counter - 3
    return f"""// {name}.sv — NewCSR read-only HPM counter {counter} tail leaf.
// This wrapper preserves the exact G1 port contract and maps architectural
// counter {counter} to parent mHPM_hpmcounters_{source_index}.  The shared core
// owns the asynchronous stopped-count snapshot and live/debug read selection.
{BEGIN_HPM}
{golden_header(name)}
  xs_Hpmcounter_core #(
    .COUNTER_INDEX ({source_index}),
    .COUNTER_WIDTH (64)
  ) u_core (
    .clk               (clock),
    .rst               (reset),
    .counter_value     (mHPM_hpmcounters_{source_index}),
    .debug_stop_count  (debugModeStopCount),
    .count_update      (unprivCountUpdate),
    .rdata             (rdata)
  );
endmodule
{END_HPM}
"""


def mhpm_wrapper(counter: int) -> str:
    name = f"Mhpmcounter{counter}Module"
    source_index = counter - 3
    return f"""// {name}.sv — machine-mode HPM counter {counter} CSR leaf.
// The architectural index {counter} selects HPM3[{source_index}]; this is the
// parent-array mapping, not a local tail index.  The canonical shared core
// preserves asynchronous reset, CSR-write priority, six-bit event increment,
// and carry.
{BEGIN_MHPM}
{golden_header(name)}
  xs_mhpmcounter #(.IDX({source_index})) u_core (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (w_wen),
    .w_wdata            (w_wdata),
    .rdata              (rdata),
    .regOut_ALL         (regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_CY),
    .mcountinhibit_IR   (mcountinhibit_IR),
    .mcountinhibit_HPM3 (mcountinhibit_HPM3),
    .countingEn         (countingEn),
    .perf_value         (perf_value),
    .toMhpmeventOF      (toMhpmeventOF)
  );
endmodule
{END_MHPM}
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="check without writing")
    args = parser.parse_args()

    assert_same_headers([f"Hpmcounter{n}Module" for n in HPM_COUNTERS], "HpmcounterXModule")
    assert_same_headers([f"Mhpmcounter{n}Module" for n in MHPM_COUNTERS], "MhpmcounterXModule")

    expected = {}
    expected.update({RTL_DIR / f"Hpmcounter{n}Module.sv": hpm_wrapper(n) for n in HPM_COUNTERS})
    expected.update({RTL_DIR / f"Mhpmcounter{n}Module.sv": mhpm_wrapper(n) for n in MHPM_COUNTERS})

    drift = []
    for path, text in expected.items():
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path))
        elif not path.exists() or path.read_text() != text:
            path.write_text(text)

    if drift:
        print("gen_hpmcounter_tail_leaves --check: DRIFT: " + " ".join(drift))
        return 1
    state = "--check OK" if args.check else "generated"
    print(f"gen_hpmcounter_tail_leaves: {state} ({len(expected)} wrappers)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
