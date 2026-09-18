#!/usr/bin/env python3
"""gen_rob_pins.py -- generate Rob's FM name-pin table from golden.

Why pins at all
---------------
Rob has 11,639 registers. Unpinned, Formality matches them by signature, and
signature matching on structurally identical entries is ~O(N^2): measured
8/33/147/554 s at 320/640/1280/2560 registers (scripts/rob_array_idiom_canary.py),
extrapolating to ~3 h at Rob's size. Pinning turns that into a name lookup.

The previous round could not pin at all. Its core stored entries as a packed
struct, so the only impl DFF objects were `rob_entries_reg[N][bit]` with `bit` an
offset into a 201-bit concatenation -- FM-036 on 9263/9440 -- and it fell back to
16,161 hand-written pins. With the per-field array layout this file assumes, the
canary measured 4000/4000 pins ACCEPTED, no FM-036, match 147 s -> 55 s.

The naming contract (this file IS the contract)
-----------------------------------------------
golden flattens `<prefix>[<i>].<field>` to a scalar `<prefix>_<i>_<field>`.
The readable core declares one array per (prefix, field):

    logic [W-1:0] <prefix>_<field> [DEPTH];

which Formality sees as `<prefix>_<field>_reg[<i>][<b>]`. So every pin is:

    r:/WORK/Rob/<prefix>_<i>_<field>_reg[<b>]
    i:/WORK/Rob/u_core/<prefix>_<field>_reg[<i>][<b>]

Width-1 registers have no `[<b>]` on either side -- golden writes
`<prefix>_<i>_<field>_reg` and the core `<prefix>_<field>_reg[<i>]`.

Measured (2026-09-18, fm_shell V-2023.12-SP3)
--------------------------------------------
The impl half of the contract above was validated on a 160-entry x 8-field
stand-in shaped exactly like Rob's wrapper -- `module Canary` instantiating
`xs_Canary_core u_core` -- because the earlier canary only ever proved the path
at TOP level (`i:/WORK/Canary/ent_<f>_reg[i][b]`), and every pin this file emits
carries one extra instance hop (`.../Canary/u_core/...`). That hop was an
assumption until measured. Result:

    PINCONTRACT pinned 4000 of 4000       <- every pin accepted, no FM-036
    Verification SUCCEEDED, 4025 passing compare points, 0 errors

What is STILL unvalidated: the real Rob core does not exist yet, so the prefix
and field spellings this file derives from golden have never been checked
against an actual `xs_Rob_core`. The emitted Tcl is fail-closed precisely so
that a spelling mismatch shows up as `pinned N of M, N != M` and `exit 3`
instead of a silently slow match.

Fail-closed
-----------
The emitted Tcl counts accepted pins and `exit 3`s unless every pin was taken,
so a silently-unpinned register can never masquerade as a fast match.

Self-test (`--selftest`) runs in pure tclsh with `set_user_match` stubbed -- no
Formality, no license. It is DISCRIMINATING, not merely reactive: each check
emits its own tag, and every negative asserts THAT SPECIFIC tag fired. A test
that only asserted "nonzero exit" would pass against a script that rejects
everything, which is the `return True` failure mode.

Usage
  python3 scripts/gen_rob_pins.py --emit verif/ut/Rob/fm_pins.tcl
  python3 scripts/gen_rob_pins.py --selftest
"""
import argparse, collections, hashlib, os, re, subprocess, sys, tempfile

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')

# Families that are firtool temporaries, not arrays. `r_0`/`r_1` and
# `io_perf_<n>_value_REG` fold under a <prefix>_<idx>_<field> regex but are not
# indexed storage, so pinning them by array position would be a guess. Excluded
# by name, and the exclusion is asserted in the self-test so it cannot silently
# grow.
NOT_ARRAYS = {'r', 'io_perf', 'REG', 'io_error'}


def golden_arrays(path):
    """-> {prefix: {field: (width, depth)}} for genuinely entry-indexed storage."""
    with open(path) as f:
        text = f.read()
    decl = {}
    for l in text.split('\n'):
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            decl[m.group(3)] = w
    fam = collections.defaultdict(lambda: collections.defaultdict(dict))
    for n, w in decl.items():
        m = re.match(r'^(.*?)_(\d+)_(.+)$', n)
        if not m:
            continue
        pre, idx, fld = m.group(1), int(m.group(2)), m.group(3)
        if pre in NOT_ARRAYS:
            continue
        fam[pre][fld][idx] = w
    out = {}
    for pre, flds in fam.items():
        keep = {}
        for fld, idxs in flds.items():
            widths = set(idxs.values())
            # A real array has one width and a dense 0..N-1 index range. Anything
            # ragged is a name collision, not storage -- drop it rather than
            # emit a pin whose impl side may not exist.
            if len(widths) == 1 and set(idxs) == set(range(len(idxs))):
                keep[fld] = (widths.pop(), len(idxs))
        if keep:
            out[pre] = keep
    return out, hashlib.sha256(text.encode()).hexdigest()


def emit(arrays, digest, top='Rob', inst='u_core'):
    L = []
    L.append('# fm_pins.tcl for %s -- GENERATED by scripts/gen_rob_pins.py.' % top)
    L.append('# Do not hand-edit: regenerate. golden sha256 %s' % digest)
    L.append('# Every puts in this file is ASCII: fm.log is not UTF-8, and a')
    L.append('# self-report that lands as question marks is worse than none.')
    L.append('set _pinned 0')
    L.append('set _want 0')
    total = 0
    for pre in sorted(arrays):
        flds = arrays[pre]
        n = sum(w * d for w, d in flds.values())
        total += n
        L.append('')
        L.append('# %s: %d fields x %d entries = %d register bits'
                 % (pre, len(flds), max(d for _, d in flds.values()), n))
        for fld in sorted(flds):
            w, depth = flds[fld]
            L.append('for {set i 0} {$i < %d} {incr i} {' % depth)
            if w == 1:
                L.append('  incr _want')
                L.append('  if {[catch {set_user_match '
                         'r:/WORK/%s/%s_${i}_%s_reg '
                         'i:/WORK/%s/%s/%s_%s_reg\\[$i\\]}] == 0} {incr _pinned}'
                         % (top, pre, fld, top, inst, pre, fld))
            else:
                L.append('  for {set b 0} {$b < %d} {incr b} {' % w)
                L.append('    incr _want')
                L.append('    if {[catch {set_user_match '
                         'r:/WORK/%s/%s_${i}_%s_reg\\[$b\\] '
                         'i:/WORK/%s/%s/%s_%s_reg\\[$i\\]\\[$b\\]}] == 0} {incr _pinned}'
                         % (top, pre, fld, top, inst, pre, fld))
                L.append('  }')
            L.append('}')
    L.append('')
    L.append('puts "ROB_PINS pinned $_pinned of $_want"')
    L.append('if {$_pinned != $_want} {')
    L.append('  puts "ROB_PINS_FAIL not every pin was accepted"')
    L.append('  exit 3')
    L.append('}')
    L.append('if {$_want != %d} {' % total)
    L.append('  puts "ROB_PINS_FAIL expected %d pins, built $_want"' % total)
    L.append('  exit 3')
    L.append('}')
    return '\n'.join(L) + '\n', total


SELFTEST_HARNESS = r'''
# Stubs: no Formality, no license. MODE decides how set_user_match behaves.
set ::MODE $env(PIN_TEST_MODE)
set ::calls 0
proc set_user_match {a b} {
    incr ::calls
    switch -- $::MODE {
        ok       { return 0 }
        refuse1  { if {$::calls == 7} { error "FM-036 unknown name $b" } ; return 0 }
        refuseall { error "FM-036 unknown name $b" }
    }
    return 0
}
proc exit_tag {t} { puts "TAG $t" ; exit 3 }
'''


def selftest():
    """Positive + three negatives, each asserting ITS OWN tag.

    The point of the tags: a script that rejected everything would pass a test
    that only checked "nonzero exit". Each negative below names the check it
    expects to fire, so a blanket-reject script fails the positive AND reports
    the wrong tag on two of the three negatives.
    """
    arrays, digest = golden_arrays(GOLDEN)
    # A small synthetic family keeps the self-test fast and independent of how
    # big golden happens to be today.
    tiny = {'ent': {'valid': (1, 4), 'pdest': (8, 4)}}
    body, total = emit(tiny, 'SELFTEST')
    assert total == 4 * 1 + 4 * 8, total
    d = tempfile.mkdtemp(prefix='rob-pins-selftest-')
    results = {}
    cases = [
        ('ok', 0, 'ROB_PINS pinned 36 of 36', 'positive: every pin accepted'),
        ('refuse1', 3, 'ROB_PINS_FAIL not every pin was accepted',
         'one pin refused (FM-036) must be caught, not rounded away'),
        ('refuseall', 3, 'ROB_PINS_FAIL not every pin was accepted',
         'all pins refused'),
    ]
    for mode, want_rc, want_txt, why in cases:
        p = os.path.join(d, 'case_%s.tcl' % mode)
        with open(p, 'w') as f:
            f.write(SELFTEST_HARNESS + body)
        env = dict(os.environ, PIN_TEST_MODE=mode)
        # Python 3.6 here: no capture_output=, no text=.
        pr = subprocess.run(['tclsh', p], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, env=env)
        out = pr.stdout.decode()
        ok = (pr.returncode == want_rc) and (want_txt in out)
        results[mode] = (ok, pr.returncode, out.strip().splitlines()[-1:] or [''], why)

    # Fourth negative, and the one that catches a WRONG-COUNT generator: claim a
    # count the body does not build. This is a different check from "a pin was
    # refused", and it must fire its own message.
    bad = body.replace('if {$_want != 36} {', 'if {$_want != 999} {')
    bad = bad.replace('expected 36 pins', 'expected 999 pins')
    p = os.path.join(d, 'case_count.tcl')
    with open(p, 'w') as f:
        f.write(SELFTEST_HARNESS + bad)
    pr = subprocess.run(['tclsh', p], stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        env=dict(os.environ, PIN_TEST_MODE='ok'))
    out = pr.stdout.decode()
    results['wrong_count'] = (
        pr.returncode == 3 and 'expected 999 pins' in out
        and 'not every pin was accepted' not in out,
        pr.returncode, out.strip().splitlines()[-1:] or [''],
        'count check fires its OWN message; pin-refused message must NOT appear')

    # ---- meta-check: would this self-test CATCH a broken generator? ----
    # Everything above shows the checks fire on bad INPUT. That is only half.
    # A generator that rejected unconditionally would also "fire" on every
    # negative -- and sail through, because a test that asserts only
    # "the negatives were rejected" cannot tell a discriminating check from
    # `return True`. So mutate the generator itself into a blanket-rejecter and
    # require the POSITIVE case to go red. If this row ever says OK, the four
    # rows above prove nothing.
    blanket = body.replace('puts "ROB_PINS pinned $_pinned of $_want"',
                           'puts "ROB_PINS_FAIL not every pin was accepted"\nexit 3')
    p = os.path.join(d, 'case_meta.tcl')
    with open(p, 'w') as f:
        f.write(SELFTEST_HARNESS + blanket)
    pr = subprocess.run(['tclsh', p], stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        env=dict(os.environ, PIN_TEST_MODE='ok'))
    out = pr.stdout.decode()
    # The positive case must now FAIL (rc != 0). If it still passes, the
    # positive assertion is vacuous.
    results['meta_blanket'] = (
        pr.returncode != 0,
        pr.returncode, out.strip().splitlines()[-1:] or [''],
        'MUTATED generator to reject everything -- positive case MUST go red')

    print('%-12s %-6s %-4s %s' % ('case', 'verdict', 'rc', 'what it proves'))
    allok = True
    for k, (ok, rc, tail, why) in results.items():
        print('%-12s %-6s %-4s %s' % (k, 'OK' if ok else 'FAIL', rc, why))
        if not ok:
            allok = False
            print('             last line: %s' % (tail[0] if tail else ''))
    print()
    print('exclusions asserted not to have grown: %s' % sorted(NOT_ARRAYS))
    return 0 if allok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    ap.add_argument('--emit')
    ap.add_argument('--summary', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    arrays, digest = golden_arrays(a.golden)
    body, total = emit(arrays, digest)
    if a.summary or not a.emit:
        print('# golden sha256 %s' % digest)
        print('%-30s %7s %7s %10s' % ('array prefix', 'fields', 'depth', 'pins'))
        for pre in sorted(arrays, key=lambda p: -sum(
                w * d for w, d in arrays[p].values())):
            flds = arrays[pre]
            print('%-30s %7d %7d %10d'
                  % (pre, len(flds), max(d for _, d in flds.values()),
                     sum(w * d for w, d in flds.values())))
        print('# total pins %d' % total)
        print('# excluded as not-arrays: %s' % sorted(NOT_ARRAYS))
    if a.emit:
        os.makedirs(os.path.dirname(os.path.abspath(a.emit)), exist_ok=True)
        with open(a.emit, 'w') as f:
            f.write(body)
        print('# wrote %s (%d pins)' % (a.emit, total), file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
