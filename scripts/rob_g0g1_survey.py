#!/usr/bin/env python3
"""rob_g0g1_survey.py -- measure Rob in G0 and G1 golden. Pure measurement, no
implementation. Every number the Rob lane reports comes out of here.

  python3 scripts/rob_g0g1_survey.py [--g0 <dir>] [--g1 <dir>]

Prints, for each baseline: port counts/widths by direction, child instance
inventory, register count and register-bit budget grouped by family, and which
module drives each top-level output. Also prints the G0->G1 port-name delta.
"""
import argparse, collections, hashlib, re, sys


def read(path):
    with open(path) as f:
        return f.read().split('\n')


def header(lines):
    """Return (ports, index_of_closing_paren). ports = [(dir, width, name)]."""
    start = next(i for i, l in enumerate(lines) if l.startswith('module Rob('))
    end = next(i for i in range(start, len(lines)) if lines[i].strip() == ');')
    ports = []
    for l in lines[start:end + 1]:
        m = re.match(r'\s*(input|output)\s+(?:wire\s+)?(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)', l)
        if m:
            w = 1 if m.group(2) is None else int(m.group(2)) - int(m.group(3)) + 1
            ports.append((m.group(1), w, m.group(4)))
    return ports, end


def instances(lines, body_start):
    """firtool emits one instance per '  <Type> <name> (' line, pins one per line."""
    out, i = [], body_start
    while i < len(lines):
        m = re.match(r'^\s{0,4}([A-Za-z_]\w*)\s+(\w+)\s*\(\s*$', lines[i])
        if m:
            j, pins = i + 1, []
            while j < len(lines) and not re.match(r'^\s*\);', lines[j]):
                pm = re.match(r'\s*\.(\w+)\s*\(\s*([^)]*)\)', lines[j])
                if pm:
                    pins.append((pm.group(1), pm.group(2).strip()))
                j += 1
            out.append((m.group(1), m.group(2), i + 1, j + 1, pins))
            i = j
        i += 1
    return out


def registers(lines):
    """reg decls -> bits. firtool declares every register with a plain `reg`."""
    decl = {}
    for l in lines:
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)'
                     r'\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            d = 1 if m.group(4) is None else int(m.group(4)) - int(m.group(5)) + 1
            decl[m.group(3)] = w * d
    return decl


def reg_family(name):
    """Group the 160-entry arrays back together: strip firtool's index suffixes."""
    g = re.sub(r'_\d+', '', name)
    if g.startswith('debug'):
        return '_'.join(g.split('_')[:3])
    return g.split('_')[0]


def survey(tag, path):
    lines = read(path)
    blob = '\n'.join(lines).encode()
    print(f'===== {tag}  {path}')
    print(f'  sha256          {hashlib.sha256(blob).hexdigest()}')
    print(f'  lines           {len(lines) - 1}')

    ports, end = header(lines)
    ins = [p for p in ports if p[0] == 'input']
    outs = [p for p in ports if p[0] == 'output']
    outset = {p[2] for p in outs}
    print(f'  ports           {len(ports)}   in {len(ins)} ({sum(p[1] for p in ins)} b)'
          f'   out {len(outs)} ({sum(p[1] for p in outs)} b)')

    inst = instances(lines, end)
    print(f'  child instances {len(inst)}')
    for t, n, a, b, pins in inst:
        print(f'      {t:24s} {n:24s} lines {a}-{b}  pins {len(pins)}')

    decl = registers(lines)
    fam = collections.Counter()
    nreg = collections.Counter()
    for k, b in decl.items():
        fam[reg_family(k)] += b
        nreg[reg_family(k)] += 1
    tot = sum(decl.values())
    print(f'  registers       {len(decl)}   reg bits {tot}')
    for k, v in fam.most_common(10):
        print(f'      {v:8d} b ({100*v/tot:4.1f}%)  {nreg[k]:6d} regs  {k}')

    by_inst = collections.Counter()
    for t, n, a, b, pins in inst:
        for pin, net in pins:
            if net in outset:
                by_inst[t] += 1
    assign_driven = 0
    for l in lines[end:]:
        m = re.match(r'\s*assign\s+(\w+)', l)
        if m and m.group(1) in outset:
            assign_driven += 1
    print(f'  output drive:   from child pin {sum(by_inst.values())}'
          f'   from Rob body assign {assign_driven}'
          f'   other {len(outs) - sum(by_inst.values()) - assign_driven}')
    for k, v in by_inst.most_common():
        print(f'      {v:6d}  <- {k}')
    return {p[2] for p in ports}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--g0', default='/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv')
    ap.add_argument('--g1', default='/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
    a = ap.parse_args()
    n0 = survey('G0', a.g0)
    n1 = survey('G1', a.g1)
    print('===== G0 -> G1 port-name delta')
    print(f'  shared {len(n0 & n1)}   G0-only {len(n0 - n1)}   G1-only {len(n1 - n0)}')

    def top(names, k):
        c = collections.Counter(re.sub(r'_\d+.*$', '', x) for x in names)
        for kk, vv in c.most_common(k):
            print(f'      {vv:6d}  {kk}')
    print('    G0-only families:')
    top(n0 - n1, 6)
    print('    G1-only families:')
    top(n1 - n0, 6)
    return 0


if __name__ == '__main__':
    sys.exit(main())
