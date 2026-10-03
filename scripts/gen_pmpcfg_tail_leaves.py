#!/usr/bin/env python3
"""Generate exact-name PMP configuration tail wrappers (Pmp21..Pmp31).

The canonical ``xs_Pmpcfg_core`` is the only behavioral implementation.  This
script derives each wrapper's exact G1 port contract and passes its architectural
PMP slot unchanged as ``SLOT``.  ``--check`` is byte-for-byte and read-only.
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "rtl" / "backend"
GOLDEN_DIR = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
SLOTS = tuple(range(21, 32))
BEGIN = "// BEGIN GENERATED(pmpcfg-tail-wrapper)"
END = "// END GENERATED(pmpcfg-tail-wrapper)"


def golden_header(slot):
    name = "Pmp{}cfgModule".format(slot)
    text = (GOLDEN_DIR / (name + ".sv")).read_text()
    match = re.search(r"module\s+{}\s*\(.*?\n\);".format(re.escape(name)), text, re.S)
    if match is None:
        raise RuntimeError("missing golden port header for {}".format(name))
    return match.group(0)


def normalized_header(slot):
    return re.sub(r"module\s+Pmp{}cfgModule".format(slot), "module PmpXcfgModule", golden_header(slot), count=1)


def port_contracts():
    contracts = {slot: normalized_header(slot) for slot in SLOTS}
    reference = contracts[SLOTS[0]]
    mismatches = [slot for slot, contract in contracts.items() if contract != reference]
    if mismatches:
        raise RuntimeError("golden PMP tail port contracts differ at slots {}".format(mismatches))
    return contracts


def wrapper_text(slot, contracts):
    name = "Pmp{}cfgModule".format(slot)
    return """// {name}.sv — PMP configuration CSR leaf {slot}.
// This tail wrapper preserves the G1 module name and exact port contract while
// reusing the single canonical PMP state machine.  SLOT is the architectural
// PMP entry number, including the 21..31 tail; it is not local.
// The shared core owns asynchronous reset, WARL, reserved R/W handling, and
// decoded outputs.
{begin}
{header}
  xs_Pmpcfg_core #(.SLOT({slot})) u_core (
    .clk     (clock),
    .rst     (reset),
    .wr_en   (w_wen),
    .wr_data (w_wdata),
    .rd_data (rdata),
    .cfg_r   (regOut_R),
    .cfg_w   (regOut_W),
    .cfg_x   (regOut_X),
    .cfg_a   (regOut_A),
    .cfg_l   (regOut_L)
  );
endmodule
{end}
""".format(name=name, slot=slot, begin=BEGIN, header=golden_header(slot), end=END)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    contracts = port_contracts()
    expected = {}
    for slot in SLOTS:
        expected[RTL_DIR / "Pmp{}cfgModule.sv".format(slot)] = wrapper_text(slot, contracts)

    drift = []
    for path, text in expected.items():
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path))
        elif not path.exists() or path.read_text() != text:
            path.write_text(text)
    if drift:
        print("gen_pmpcfg_tail_leaves --check: DRIFT: " + " ".join(drift))
        return 1
    print("gen_pmpcfg_tail_leaves: {} ({})".format("--check OK" if args.check else "generated", len(SLOTS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
