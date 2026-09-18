#!/usr/bin/env python3
"""rob_warmup_coverage.py -- derive the UT warm-up obligation for Rob FROM GOLDEN.

The problem this solves
-----------------------
Golden Rob has two synthesised always blocks and they are disjoint:

    always @(posedge clock)                    9,359 registers -- NO reset
    always @(posedge clock or posedge reset)   2,280 registers -- async reset

9,359 registers come out of reset holding whatever `+vcs+initreg` put there. A
UT that opens its comparison window before those have been written is comparing
initial values, and whether it goes green depends on the seed. "3 seeds green"
is not evidence here: this round, StdFreeList needed a 40-seed sweep to hit its
3 failing seeds -- 1/7/42 were all green. So the warm-up must be ARGUED, not
observed.

The argument is available, because firtool leaves the write-enable of every
register visible in the source. This script walks the no-reset block, recovers
each register's innermost guard, resolves the `_GEN_*` wire behind it, and
groups the result. What comes out is small and checkable:

    robEntries_<i>_<field>              guard = canEnqueue_<p> & (allocatePtr_<p> == i)
    debug_microOp_debugReg_<i>_<field>  same six enqueue guards
    dt_exuDebug_<i>_<field>             guard = one of 8 store writeback ports
    debug_exuData_<i>                   guard = one of 25 exu writeback ports

So the warm-up obligation is not "run N cycles", it is a set of coverage
vectors the tb can assert are all-ones before the window opens:

    enq_seen[160]   entry i has been enqueued by some port
    wb_seen[160]    entry i has been written back by some exu port
    st_seen[160]    entry i has been written back by some store port
    plus one bit per single-event scalar register

Usage
  python3 scripts/rob_warmup_coverage.py            # summary per family
  python3 scripts/rob_warmup_coverage.py --detail   # every register's guards
"""
import argparse, collections, hashlib, os, re, sys

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')


def load(path):
    with open(path) as f:
        text = f.read()
    return text, text.split('\n')


def find_blocks(lines):
    """Locate the synthesised posedge blocks. The assertion block sits under
    `ifndef SYNTHESIS and is excluded -- both UT and FM compile with
    +define+SYNTHESIS, so it is not in either netlist."""
    out, stack = [], []
    for i, l in enumerate(lines):
        s = l.strip()
        if s.startswith('`ifdef') or s.startswith('`ifndef'):
            stack.append(s)
        elif s.startswith('`endif') and stack:
            stack.pop()
        elif s.startswith('always @(posedge') and not stack:
            out.append((i + 1, 'async' if 'posedge reset' in s else 'sync'))
    return out


def declared_regs(lines):
    regs = {}
    for l in lines:
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            regs[m.group(3)] = w
    return regs


def gen_defs(lines):
    """Resolve `wire X = <expr>;`, INCLUDING the multi-line form.

    firtool wraps long right-hand sides, so a large fraction of the interesting
    enables look like

        wire               _GEN_10134 =
          io_exuWriteback_20_valid & ~(|io_exuWriteback_20_bits_robIdx_value);

    A single-line regex silently misses every one of those. That is what put
    several families in the `<else>`/`<top>` bucket in the first version of this
    script -- the enable WAS recoverable, the parser just could not see it.
    Joining continuations until the terminating `;` fixes it.
    """
    d, i = {}, 0
    while i < len(lines):
        m = re.match(r'\s*wire\s+(?:\[[^\]]*\])?\s*(\w+)\s*=\s*(.*)$', lines[i])
        if m:
            name, rhs = m.group(1), m.group(2)
            while ';' not in rhs and i + 1 < len(lines):
                i += 1
                rhs += ' ' + lines[i].strip()
            d[name] = rhs.split(';')[0].strip()
        i += 1
    return d


IF_PATTERNS = [
    r'(?:end\s+)?else if \((.*?)\)\s*begin$', r'if \((.*?)\)\s*begin$',
    r'(?:end\s+)?else if \((.*?)\)$', r'if \((.*?)\)$',
]


def guards_in_block(lines, lo, hi, regs):
    """Innermost guard per assigned register. Indentation is firtool's, and it
    is consistent, so an indent stack is enough -- no expression parser."""
    stack, out = [], collections.defaultdict(set)
    for k in range(lo - 1, min(hi, len(lines))):
        raw = lines[k]
        s = raw.strip()
        if not s:
            continue
        ind = len(raw) - len(raw.lstrip())
        while stack and ind <= stack[-1][0]:
            stack.pop()
        hit = None
        for p in IF_PATTERNS:
            m = re.match(p, s)
            if m:
                hit = m.group(1)
                break
        if hit is not None:
            stack.append((ind, hit))
            continue
        if re.match(r'(?:end\s+)?else\s*begin$', s) or s == 'else':
            stack.append((ind, '<else>'))
            continue
        m = re.match(r'(\w+)\s*<=', s)
        if m and m.group(1) in regs:
            out[m.group(1)].add(stack[-1][1] if stack else '<top>')
    return out


def family(name):
    """Fold firtool's flattening back into <prefix>[<idx>].<field>.

    Both shapes occur and both must fold, or the summary explodes into 160
    one-row families: `robEntries_5_valid` (prefix_idx_field) and
    `debug_exuData_5` (prefix_idx, no field).
    """
    m = re.match(r'^(.*?)_(\d+)_(.+)$', name)
    if m:
        return m.group(1)
    m = re.match(r'^(.*?)_(\d+)$', name)
    if m:
        return m.group(1)
    return name


def resolve(expr, gens, depth=2):
    for _ in range(depth):
        nxt = re.sub(r'\b(_GEN_\d+)\b',
                     lambda mo: '(' + gens.get(mo.group(1), mo.group(1)) + ')',
                     expr)
        if nxt == expr:
            break
        expr = nxt
    return expr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    ap.add_argument('--detail', action='store_true')
    a = ap.parse_args()

    text, lines = load(a.golden)
    print('# golden %s' % a.golden)
    print('# sha256 %s' % hashlib.sha256(text.encode()).hexdigest())

    blocks = find_blocks(lines)
    print('# synthesised posedge blocks: %s'
          % ', '.join('line %d (%s)' % b for b in blocks))
    if len(blocks) != 2:
        print('# WARNING: expected exactly 2; the block split below may be wrong')

    regs = declared_regs(lines)
    gens = gen_defs(lines)
    (sync_ln, _), (async_ln, _) = blocks[0], blocks[1]
    g_sync = guards_in_block(lines, sync_ln, async_ln - 1, regs)
    g_async = guards_in_block(lines, async_ln, len(lines), regs)
    print('# no-reset block  %d registers   async-reset block %d registers'
          % (len(g_sync), len(g_async)))
    print('# overlap %d (must be 0 -- golden keeps the domains disjoint)'
          % len(set(g_sync) & set(g_async)))

    byfam = collections.defaultdict(lambda: [0, collections.Counter(), set()])
    for r, gs in g_sync.items():
        f = byfam[family(r)]
        f[0] += 1
        f[1][len(gs)] += 1
        for g in gs:
            f[2].add(g)
    print()
    print('%-30s %6s %-26s %s'
          % ('family', 'regs', 'guards/reg', 'representative enable'))
    print('# guards/reg {k: n} = n registers whose innermost enable had k distinct forms.')
    print('# A family showing only <else>/<top> = enable NOT recovered by this walker.')
    for fam in sorted(byfam, key=lambda x: -byfam[x][0]):
        n, hist, gs = byfam[fam]
        if n < 8 and not a.detail:
            continue
        # Prefer a real condition over the two bookkeeping markers. `<else>`
        # and `<top>` mean the indent stack lost the enclosing `if` -- firtool
        # wraps some conditions across lines, which this deliberately simple
        # walker does not rejoin. They are a PARSER limit, not evidence that
        # the write is unguarded; treat a family whose only representative is
        # one of them as "enable not recovered", and read it out of golden by
        # hand before relying on it.
        real = sorted(g for g in gs if not g.startswith('<'))
        rep = real[0] if real else sorted(gs)[0]
        print('%-30s %6d %-26s %s'
              % (fam, n, dict(hist), resolve(rep, gens)[:64]))
    small = sum(n for f, (n, _, _) in byfam.items() if n < 8)
    print('%-30s %6d %-26s %s'
          % ('(%d single-event scalars)' % sum(1 for f, (n, _, _) in byfam.items() if n < 8),
             small, '-', 'one coverage bit each'))

    if a.detail:
        print()
        for r in sorted(g_sync):
            for g in sorted(g_sync[r]):
                print('%s\t%s\t%s' % (r, g, resolve(g, gens)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
