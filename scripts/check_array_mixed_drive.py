#!/usr/bin/env python3
"""check_array_mixed_drive.py -- an unpacked array must not mix continuous and
procedural drivers, because VCS then silently stops initialising ALL of it.

The hazard (measured, VCS W-2024.09-SP1)
----------------------------------------
Two arrays, identical except that one element of the second is driven by
`assign` instead of by the `always_ff`:

    logic [7:0] pure_arr  [4];       // all four written in always_ff
    logic [7:0] mixed_arr [4];
    assign mixed_arr[3] = 8'hFF;     // <-- one offending element
    always_ff @(posedge clock) ...   // the other three

    +vcs+initreg+0        pure_arr = 00 00 00 00    mixed_arr = xx xx xx ff
    +vcs+initreg+random   pure_arr = 00 36 44 dd    mixed_arr = xx xx xx ff

`+vcs+initreg` is silently disabled for the WHOLE array. VCS compiles with 0
errors and 0 warnings. Found first by the TLBNonBlock lane; reproduced here
before writing Rob's core, which stores its 160 entries as 13 families of
unpacked per-field arrays and would have been exposed to exactly this.

Why it deserves a gate rather than a note
-----------------------------------------
The X does not announce itself at the array. It propagates, so the failure
shows up on some downstream signal with no obvious connection to the
declaration that caused it -- and the two initreg rounds, which exist precisely
to catch uninitialised state, are the thing being disabled. A round that should
have been discriminating quietly becomes vacuous.

★What this checker CANNOT see★
------------------------------
It is line-based and knows nothing about `generate`. Two drivers sitting in
MUTUALLY EXCLUSIVE generate branches look identical to two drivers that are both
live -- and only the latter is the hazard. `t1_raddr` in RenameTable.sv is the
real example: it is a register in the normal case and a continuously-assigned
constant when ADDR_W==0, in different branches, so it is fine. Every hit must
therefore be read by hand before it is called a defect; this checker narrows the
search, it does not decide. A hit is a question, not a verdict.

Usage
  python3 scripts/check_array_mixed_drive.py            # scan rtl/
  python3 scripts/check_array_mixed_drive.py --selftest # both directions
"""
import argparse, os, pathlib, re, sys, tempfile

REPO = pathlib.Path(os.environ.get('XSSV_HOME') or
                    pathlib.Path(__file__).resolve().parent.parent)

# `logic [7:0] name [4];` / `logic name [0:159];` -- an UNPACKED array only.
# Only VARIABLES. A `wire` array cannot be initialised by +vcs+initreg in the
# first place, so it cannot suffer this hazard -- including `wire` here produced
# three false positives on the first run against rtl/ (layer_out, r_word, ...),
# every one of them a pure-continuous wire array that is perfectly fine.
DECL = re.compile(
    r'^\s*(?:logic|reg|bit)\s*(?:\[[^\]]*\]\s*)?'
    r'(\w+)\s*\[[^\]]*\]\s*;')
ASSIGN = re.compile(r'\bassign\s+(\w+)\s*\[')
# Non-blocking assignment is unambiguous: it can only be procedural, never a
# continuous assign. Searched ANYWHERE in the line, not anchored to its start --
# firtool and hand-written RTL both put `always_ff @(posedge c) begin a[0] <= ..`
# on one line, and a line-anchored pattern captures `always_ff` and sees no
# array write at all. That is the same mistake CONVENTIONS already records for
# an earlier gate ("赋值正则按行首锚定 ⇒ 一行里捕到的是 for"), and this
# checker's own self-test caught it before it shipped.
NBA = re.compile(r'\b(\w+)\s*\[[^\]]*\]\s*(?:\[[^\]]*\]\s*)?<=')
BLOCKING = re.compile(r'\b(\w+)\s*\[[^\]]*\]\s*(?:\[[^\]]*\]\s*)?=(?!=)')


def scan_text(text):
    """-> {array_name: (has_continuous, has_clocked)} for declared arrays.

    Only CLOCKED (always_ff / always @(posedge ...)) writes count as the
    procedural side. The hazard is that +vcs+initreg stops initialising the
    array, and initreg only ever initialises registers -- an array written from
    always_comb is recomputed from its inputs, so an X at time 0 is transient
    and harmless. Counting always_comb writes flagged `corr` in
    ArrayMulDataModule, which is purely combinational and perfectly fine.
    """
    arrays, cont, proc = set(), set(), set()
    in_clocked = False
    depth = 0
    for raw in text.split('\n'):
        line = raw.split('//')[0]
        m = DECL.match(line)
        if m:
            arrays.add(m.group(1))
        # Track whether we are inside a clocked block. Crude but sufficient:
        # firtool and this repo both open a clocked block on its own line.
        if re.search(r'always_ff\b|always\s*@\s*\(\s*posedge', line):
            in_clocked, depth = True, 0
        elif re.match(r'\s*(always_comb|always_latch|assign|end(module|case|generate))\b', line):
            in_clocked = False
        if in_clocked:
            depth += line.count('begin') - line.count('end')
            if depth < 0:
                in_clocked = False
        rest = line
        for m in ASSIGN.finditer(line):
            cont.add(m.group(1))
        # Strip `assign <lhs>` so its `=` is not counted as a blocking
        # procedural write to the same array.
        # Strip `assign <lhs> =` however many index/range brackets the lhs
        # carries. The first version handled exactly one, so
        #   assign layer_out[L][MAXTOT-1:TOT_NEXT] = '0;
        # kept its second bracket and was miscounted as a BLOCKING procedural
        # write -- a false positive that looked exactly like a real finding.
        rest = re.sub(r'\bassign\s+\w+(?:\s*\[[^\]]*\])+\s*=', ' ', rest)
        if in_clocked:
            for m in NBA.finditer(rest):
                proc.add(m.group(1))
            for m in BLOCKING.finditer(rest):
                proc.add(m.group(1))
    return {a: (a in cont, a in proc) for a in arrays}


def scan_file(p):
    return [(a, p) for a, (c, pr) in scan_text(pathlib.Path(p).read_text()).items()
            if c and pr]


def load_allow(path):
    out = set()
    if path and os.path.isfile(path):
        for ln in open(path):
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.rstrip('\n').split('\t')
            if len(f) >= 2:
                out.add((f[0], f[1]))
    return out


def main_scan(root, allow_path=None):
    allow = load_allow(allow_path)
    bad = []
    files = sorted(pathlib.Path(root).rglob('*.sv'))
    for f in files:
        for a, p in scan_file(f):
            rel = os.path.relpath(str(p), str(REPO))
            if (a, rel) not in allow:
                bad.append((a, rel))
    print('scanned %d .sv files under %s (%d adjudicated in allow file)'
          % (len(files), root, len(allow)))
    if bad:
        print('★REVIEW REQUIRED -- clocked array with a continuous driver★')
        for a, p in bad:
            print('    %-40s %s' % (a, p))
        print('A hit is a QUESTION, not a verdict: this checker cannot see')
        print('`generate`, so exclusive branches look like live ones. Read the')
        print('source. If it is the real hazard, drive every element the same')
        print('way; if the drivers are exclusive, add a row (with the reason)')
        print('to scripts/array_mixed_drive_allow.tsv.')
        return 1
    print('check_array_mixed_drive: OK -- no unpacked array mixes '
          'continuous and procedural drivers')
    return 0


PURE = """module m(input c, output logic [7:0] o);
  logic [7:0] a [4];
  always_ff @(posedge c) begin a[0] <= 8'h1; a[1] <= 8'h2; end
  assign o = a[0];
endmodule
"""
MIXED = """module m(input c, output logic [7:0] o);
  logic [7:0] a [4];
  assign a[3] = 8'hFF;
  always_ff @(posedge c) begin a[0] <= 8'h1; a[1] <= 8'h2; end
  assign o = a[0];
endmodule
"""
# A pure array plus a DIFFERENT, non-array signal that is continuously
# assigned: the checker must not confuse the two.
NEARMISS = """module m(input c, output logic [7:0] o);
  logic [7:0] a [4];
  logic [7:0] b;
  assign b = 8'hFF;
  always_ff @(posedge c) begin a[0] <= 8'h1; end
  assign o = b;
endmodule
"""


def selftest():
    d = tempfile.mkdtemp(prefix='array-mixed-selftest-')
    rows = []
    for name, src, want in (('pure', PURE, 0), ('mixed', MIXED, 1),
                            ('near_miss', NEARMISS, 0)):
        p = os.path.join(d, name + '.sv')
        open(p, 'w').write(src)
        got = len(scan_file(p))
        rows.append((name, got == want, got, want))
    # both directions: it must fire on `mixed` AND stay silent on the two
    # clean cases. A checker that flagged every array would pass only the
    # first, which is why `near_miss` is here -- an `assign` to a non-array
    # signal in the same file must not drag the array in with it.
    ok = all(r[1] for r in rows)
    print('%-12s %-6s %s' % ('case', 'result', 'flagged / expected'))
    for name, good, got, want in rows:
        print('%-12s %-6s %d / %d' % (name, 'OK' if good else 'FAIL', got, want))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=str(REPO / 'rtl'))
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--allow', default=str(REPO / 'scripts' /
                                           'array_mixed_drive_allow.tsv'))
    a = ap.parse_args()
    return selftest() if a.selftest else main_scan(a.root, a.allow)


if __name__ == '__main__':
    sys.exit(main())
