#!/usr/bin/env python3
"""Generate the eight Pmp13..20cfgModule wrapper regions from G1 golden ports.

The eight leaves are structurally identical childless NewCSR leaves.  Golden is
read-only and is the source of the exact port contract; --check is deterministic
and reports any generated-region drift without modifying files.
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path('/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = REPO / 'rtl' / 'backend'
SLOTS = tuple(range(13, 21))
BEGIN = '// BEGIN GENERATED(pmpcfg-leaves8b-wrapper)'
END = '// END GENERATED'
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')


def ports_for(slot: int):
    text = (GOLDEN / f'Pmp{slot}cfgModule.sv').read_text()
    match = re.search(rf'module Pmp{slot}cfgModule\((.*?)\n\);', text, re.S)
    if not match:
        raise SystemExit(f'Pmp{slot}cfgModule: missing golden module port list')
    ports = []
    for line in match.group(1).splitlines():
        if not line.strip():
            continue
        parsed = PORT_RE.match(line)
        if not parsed:
            raise SystemExit(f'Pmp{slot}cfgModule: unparseable port line: {line!r}')
        direction, msb, name = parsed.groups()
        ports.append((direction, int(msb) if msb is not None else None, name))
    if not ports:
        raise SystemExit(f'Pmp{slot}cfgModule: empty golden port list')
    return ports


def region(ports):
    lines = [BEGIN]
    for index, (direction, msb, name) in enumerate(ports):
        width = f'[{msb}:0] ' if msb is not None else '       '
        comma = ',' if index != len(ports) - 1 else ''
        lines.append(f'  {direction:<6} logic {width:<8}{name}{comma}')
    lines.append(END); return '\n'.join(lines)


def template(slot, ports):
    port_block = region(ports)
    return f'''// Pmp{slot}cfgModule.sv — NewCSR PMP configuration byte {slot}.
// This childless CSR leaf stores the R/W/X/A/L fields and exposes both the
// packed CSR read view and decoded fields to the parent NewCSR module.
// All Pmpcfg variants share the canonical xs_Pmpcfg_core; only the golden wrapper
// name and parent address decode differ.  The core preserves asynchronous reset,
// A=2 WARL conversion to NAPOT, and the reserved R=0/W=1 write rule exactly.
// The port contract and instance wiring below are generated from read-only G1
// golden RTL by scripts/gen_pmpcfg_leaves8b.py; do not hand-edit that region.
module Pmp{slot}cfgModule (
{port_block});
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
'''


def regenerate(path: Path, slot: int, ports):
    if not path.exists():
        return template(slot, ports)
    text = path.read_text()
    start, end = text.find(BEGIN), text.find(END)
    if start < 0 or end < start:
        raise SystemExit(f'{path}: missing generated-region markers')
    # Replace only the marked region, preserving all hand-written text.
    return text[:start] + region(ports) + text[end + len(END):]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    all_ports = {slot: ports_for(slot) for slot in SLOTS}
    reference = all_ports[SLOTS[0]]
    for slot, ports in all_ports.items():
        if ports != reference:
            raise SystemExit(f'Pmp{slot}cfgModule: golden port contract differs from Pmp13')
    drift = []
    for slot in SLOTS:
        path = RTL / f'Pmp{slot}cfgModule.sv'
        new = regenerate(path, slot, reference)
        if args.check:
            if not path.exists() or path.read_text() != new:
                drift.append(str(path))
        elif not path.exists() or path.read_text() != new:
            path.write_text(new)
    if drift:
        print('gen_pmpcfg_leaves8b --check: DRIFT: ' + ' '.join(drift))
        return 1
    print(f'gen_pmpcfg_leaves8b: {"--check OK" if args.check else "generated"} ({len(SLOTS)} files)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
