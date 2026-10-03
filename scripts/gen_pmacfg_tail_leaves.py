#!/usr/bin/env python3
"""Generate the PMA configuration tail wrappers (Pma16..Pma31).

The behavioral implementation is the canonical ``xs_Pmacfg_core``.  This
family-specific generator only derives exact-name wrappers and their port
contracts from the read-only G1 golden RTL.  The architectural PMA slot is
passed unchanged as ``PMA_INDEX``; it is not renumbered within this family.

``--check`` is deterministic and byte-for-byte: it reports drift without
modifying any source file.
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "rtl" / "backend"
GOLDEN_DIR = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
SLOTS = tuple(range(16, 32))
BEGIN = "// BEGIN GENERATED(pmacfg-tail-wrapper)"
END = "// END GENERATED(pmacfg-tail-wrapper)"


def golden_header(slot):
    name = "Pma{}cfgModule".format(slot)
    text = (GOLDEN_DIR / (name + ".sv")).read_text()
    match = re.search(r"module\s+{}\s*\(.*?\n\);".format(re.escape(name)), text, re.S)
    if match is None:
        raise RuntimeError("missing golden port header for {}".format(name))
    return match.group(0)


def normalized_header(slot):
    return re.sub(r"module\s+Pma{}cfgModule".format(slot), "module PmaXcfgModule", golden_header(slot), count=1)


def port_contracts():
    contracts = {slot: normalized_header(slot) for slot in SLOTS}
    reference = contracts[SLOTS[0]]
    mismatches = [slot for slot, contract in contracts.items() if contract != reference]
    if mismatches:
        raise RuntimeError("golden PMA tail port contracts differ at slots {}".format(mismatches))
    return contracts


def wrapper_text(slot, contracts):
    name = "Pma{}cfgModule".format(slot)
    header = golden_header(slot)
    # Keep declarations readable while preserving the exact golden contract.
    header = header.replace("module {}(".format(name), "module {}(".format(name), 1)
    return """// {name}.sv — PMA configuration CSR leaf {slot}.
// This tail wrapper preserves the G1 module name and exact port contract while
// reusing the single canonical PMA state machine.  PMA_INDEX is the
// architectural entry number, including the 16..31 tail; it is not local.
// The shared core owns reset, WARL, write priority, and decoded outputs.
{begin}
{header}
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
{end}
""".format(name=name, slot=slot, begin=BEGIN, header=header, end=END)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    contracts = port_contracts()
    expected = {}
    for slot in SLOTS:
        expected[RTL_DIR / "Pma{}cfgModule.sv".format(slot)] = wrapper_text(slot, contracts)

    drift = []
    for path, text in expected.items():
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path))
        elif not path.exists() or path.read_text() != text:
            path.write_text(text)
    if drift:
        print("gen_pmacfg_tail_leaves --check: DRIFT: " + " ".join(drift))
        return 1
    print("gen_pmacfg_tail_leaves: {} ({})".format("--check OK" if args.check else "generated", len(SLOTS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
