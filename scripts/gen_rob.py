#!/usr/bin/env python3
"""gen_rob.py -- generate the mechanically-derived regions of rtl/backend/Rob.sv.

Rob's golden is 266,227 lines / 2200 ports / 8 child instances. Almost none of
that bulk is design intent: it is a port table and eight instance pin lists that
firtool flattened. Those are generated here and marked
`// BEGIN GENERATED(<tag>)` / `// END GENERATED`; everything outside the markers
is hand-written and this script must not touch it (CONVENTIONS 单文件规范).

Generated regions
  ports     the `module Rob` port declarations, name-for-name and width-for-width
            with golden, in golden's order.
  children  the 8 child instantiations. All 8 are SYMMETRIC BLACKBOXES: neither
            the ref nor the impl side is given a body for them (CONVENTIONS
            §子模块处理). That makes Rob a CONDITIONAL green -- it depends on all
            8 children being signed off independently. The receipt must carry
            that dependency; Rob must never be reported as an unconditional pass.

Child pin nets are rewritten as:
  * a top-level `io_*` port            -> used directly (576 of 868 pins)
  * `clock` / `reset`                  -> used directly (28)
  * a literal                          -> kept verbatim (8)
  * anything else                      -> `n_<golden net name>`, a wrapper-local
                                          net (256). Each such net is either
                                          driven by `xs_Rob_core` (child input)
                                          or by another child's output pin.

Usage
  python3 scripts/gen_rob.py --check        # regenerate into memory, diff, rc=1 on drift
  python3 scripts/gen_rob.py --write        # rewrite the GENERATED regions in place
  python3 scripts/gen_rob.py --manifest     # print the core<->wrapper net interface
"""
import argparse, collections, hashlib, os, re, sys

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
TARGET = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'rtl', 'backend', 'Rob.sv')

BEGIN = '// BEGIN GENERATED(%s)'
END = '// END GENERATED'


# --------------------------------------------------------------------------
# golden parsing
# --------------------------------------------------------------------------
def load_golden(path):
    with open(path) as f:
        text = f.read()
    return text, text.split('\n')


def parse_ports(lines):
    """Golden's port header, verbatim order. -> [(dir, hi, lo, name)]"""
    start = next(i for i, l in enumerate(lines) if l.startswith('module Rob('))
    end = next(i for i in range(start, len(lines)) if lines[i].strip() == ');')
    out = []
    for l in lines[start:end + 1]:
        m = re.match(r'\s*(input|output)\s+(?:wire\s+)?'
                     r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)', l)
        if m:
            hi = None if m.group(2) is None else int(m.group(2))
            lo = None if m.group(3) is None else int(m.group(3))
            out.append((m.group(1), hi, lo, m.group(4)))
    return out, end


def parse_children(lines, body_start):
    """The 8 child instances. -> [(type, inst, [(pin, net)])]"""
    out, i = [], body_start
    while i < len(lines):
        m = re.match(r'^\s{0,4}([A-Za-z_]\w*)\s+(\w+)\s*\(\s*$', lines[i])
        if m:
            j, pins = i + 1, []
            while j < len(lines) and not re.match(r'^\s*\);', lines[j]):
                pm = re.match(r'\s*\.(\w+)\s*\((.*?)\)\s*,?\s*$', lines[j])
                if pm:
                    pins.append((pm.group(1), pm.group(2).strip()))
                j += 1
            out.append((m.group(1), m.group(2), pins))
            i = j
        i += 1
    return out


def child_output_pins(golden_dir, ctype):
    """Read the child's own golden file to learn which pins are outputs.

    Needed to tell a net the core must DRIVE (child input) from one the core
    CONSUMES (child output). Guessing from the name would be exactly the
    'name matches so it must be the same thing' mistake the house rules ban.
    """
    path = os.path.join(golden_dir, ctype + '.sv')
    outs = set()
    with open(path) as f:
        for l in f:
            m = re.match(r'\s*output\s+(?:wire\s+)?(?:\[[^\]]*\])?\s*(\w+)', l)
            if m:
                outs.add(m.group(1))
            if re.match(r'\s*\);', l) and outs:
                break
    return outs


LITERAL = re.compile(r"^\d*'[hbdHBD][0-9a-fA-FxzXZ_]+$")


def classify(net, portnames):
    if net in portnames:
        return 'port', net
    if net in ('clock', 'reset'):
        return 'clk', net
    if LITERAL.match(net):
        return 'const', net
    return 'net', 'n_' + net


# --------------------------------------------------------------------------
# emitters
# --------------------------------------------------------------------------
def register_inventory(lines):
    """Golden's register spec, split into entry-indexed arrays and scalars.

    firtool flattens every array into `<prefix>_<idx>_<field>` scalars. Folding
    them back is what turns 11,695 register declarations into 13 array families
    plus 452 loose registers -- and it is also the pin map: each family gives
    `r:.../<prefix>_<i>_<field>_reg[<b>]` <-> `i:.../<prefix>_<field>_reg[<i>][<b>]`
    mechanically, so name-pinning is a nested loop rather than a hand-built
    table. (The previous round needed 16,161 hand-written pins because its
    packed-struct core had no such correspondence to generate.)
    """
    decl = {}
    for l in lines:
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            decl[m.group(3)] = w
    fam = collections.defaultdict(dict)
    scalars = {}
    for n, w in decl.items():
        m = re.match(r'^(.*?)_(\d+)_(.+)$', n)
        if m:
            fam[(m.group(1), m.group(3))][int(m.group(2))] = w
        else:
            scalars[n] = w
    byprefix = collections.defaultdict(list)
    for (pre, f), idxs in fam.items():
        widths = set(idxs.values())
        byprefix[pre].append((f, len(idxs), sorted(widths)))
    return byprefix, scalars


def emit_ports(ports):
    w = max(len(d) for d, _, _, _ in ports)
    rng = []
    for d, hi, lo, n in ports:
        rng.append('' if hi is None else '[%d:%d]' % (hi, lo))
    rw = max(len(r) for r in rng)
    lines = []
    for (d, hi, lo, n), r in zip(ports, rng):
        comma = ',' if (d, hi, lo, n) != ports[-1] else ''
        lines.append('  %-*s logic %-*s %s%s' % (w, d, rw, r, n, comma))
    return lines


def emit_children(children, portnames, golden_dir):
    lines = []
    for ctype, inst, pins in children:
        outs = child_output_pins(golden_dir, ctype)
        lines.append('  // %s -- symmetric blackbox (neither side gets a body);'
                     ' Rob is conditional on its own signoff.' % ctype)
        lines.append('  %s %s (' % (ctype, inst))
        pw = max(len(p) for p, _ in pins)
        for k, (pin, net) in enumerate(pins):
            kind, name = classify(net, portnames)
            tail = ',' if k != len(pins) - 1 else ''
            tag = '' if kind != 'net' else ('   // <- core' if pin not in outs
                                            else '   // -> core')
            lines.append('    .%-*s (%s)%s%s' % (pw, pin, name, tail, tag))
        lines.append('  );')
        lines.append('')
    return lines


def wrapper_nets(children, portnames, golden_dir):
    """Split the wrapper-local nets three ways.

    A net that a child OUTPUT pin drives is not the core's to produce, even
    when another child consumes it -- `n__exceptionGen_io_state_*` is driven by
    exceptionGen and read by deqPtrGenModule, so it is pure wrapper routing.
    Classifying by 'is some consumer an input pin' would have put those 7 nets
    in the core's obligation list. Drivers decide, consumers do not.
    """
    driven_by_child = {}
    consumed = collections.defaultdict(list)
    for ctype, inst, pins in children:
        outs = child_output_pins(golden_dir, ctype)
        for pin, net in pins:
            kind, name = classify(net, portnames)
            if kind != 'net':
                continue
            if pin in outs:
                driven_by_child[name] = (ctype, inst, pin)
            else:
                consumed[name].append((ctype, inst, pin))
    core_drives = {n: v[0] for n, v in consumed.items()
                   if n not in driven_by_child}
    core_reads = {n: v for n, v in driven_by_child.items()
                  if n not in consumed}
    routed = {n: (driven_by_child[n], consumed[n]) for n in driven_by_child
              if n in consumed}
    return core_drives, core_reads, routed


# --------------------------------------------------------------------------
# region splice
# --------------------------------------------------------------------------
def splice(target_lines, tag, new_body):
    b, e = BEGIN % tag, END
    try:
        i = next(k for k, l in enumerate(target_lines) if l.strip() == b)
    except StopIteration:
        raise SystemExit('gen_rob: marker %r not found in %s' % (b, TARGET))
    j = next(k for k in range(i + 1, len(target_lines))
             if target_lines[k].strip() == e)
    return target_lines[:i + 1] + new_body + target_lines[j:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    ap.add_argument('--target', default=TARGET)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--check', action='store_true')
    g.add_argument('--write', action='store_true')
    g.add_argument('--manifest', action='store_true')
    g.add_argument('--regmap', action='store_true')
    a = ap.parse_args()

    gtext, glines = load_golden(a.golden)
    print('# golden %s' % a.golden, file=sys.stderr)
    print('# sha256 %s' % hashlib.sha256(gtext.encode()).hexdigest(),
          file=sys.stderr)
    ports, hdr_end = parse_ports(glines)
    children = parse_children(glines, hdr_end)
    portnames = {p[3] for p in ports}
    golden_dir = os.path.dirname(os.path.abspath(a.golden))

    if a.regmap:
        byprefix, scalars = register_inventory(glines)
        tot = 0
        print('%-32s %7s %6s %10s  %s'
              % ('array prefix', '#fields', 'depth', 'bits', 'width anomalies'))
        for pre in sorted(byprefix,
                          key=lambda x: -sum(c * w[0] for _, c, w in byprefix[x])):
            flds = byprefix[pre]
            depth = max(c for _, c, _ in flds)
            bits = sum(c * w[0] for _, c, w in flds)
            tot += bits
            odd = [f for f, c, w in flds if len(w) > 1 or c != depth]
            print('%-32s %7d %6d %10d  %s'
                  % (pre, len(flds), depth, bits,
                     ('%d ragged: %s' % (len(odd), ','.join(odd[:3]))) if odd else '-'))
        print('# entry-indexed  %d families  %d fields  %d bits'
              % (len(byprefix), sum(len(v) for v in byprefix.values()), tot))
        print('# scalar         %d regs  %d bits' % (len(scalars), sum(scalars.values())))
        print('# grand total    %d bits' % (tot + sum(scalars.values())))
        return 0

    if a.manifest:
        drive, read, routed = wrapper_nets(children, portnames, golden_dir)
        print('# ports %d  children %d  child pins %d'
              % (len(ports), len(children),
                 sum(len(p) for _, _, p in children)))
        kinds = collections.Counter()
        for _, _, pins in children:
            for pin, net in pins:
                kinds[classify(net, portnames)[0]] += 1
        print('# child pin sources: %s' % dict(kinds))
        print('# NOTE: this lists CHILD PIN nets only. The core may also read'
              ' a `route` net; what it may not do is drive one.')
        print('# core MUST DRIVE %d nets, core READS %d nets, '
              'child->child routing %d nets'
              % (len(drive), len(read), len(routed)))
        for n in sorted(drive):
            print('drive\t%s\t%s.%s' % (n, drive[n][1], drive[n][2]))
        for n in sorted(read):
            print('read\t%s\t%s.%s' % (n, read[n][1], read[n][2]))
        for n in sorted(routed):
            src, dsts = routed[n]
            print('route\t%s\t%s.%s -> %s' % (
                n, src[1], src[2],
                ','.join('%s.%s' % (d[1], d[2]) for d in dsts)))
        return 0

    with open(a.target) as f:
        tgt = f.read().split('\n')
    new = splice(tgt, 'ports', emit_ports(ports))
    new = splice(new, 'children',
                 emit_children(children, portnames, golden_dir))
    out = '\n'.join(new)

    if a.write:
        with open(a.target, 'w') as f:
            f.write(out)
        print('gen_rob: wrote %s' % a.target, file=sys.stderr)
        return 0

    same = out == '\n'.join(tgt)
    print('gen_rob --check: %s' % ('OK (no drift)' if same else 'DRIFT'),
          file=sys.stderr)
    return 0 if same else 1


if __name__ == '__main__':
    sys.exit(main())
