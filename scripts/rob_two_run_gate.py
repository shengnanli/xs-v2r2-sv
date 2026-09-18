#!/usr/bin/env python3
"""rob_two_run_gate.py -- Rob's acceptance criterion, made fail-closed.

Rob is accepted when the SAME proof agrees under BOTH treatments of dangling
nets, not when one run passes. This script is that criterion in executable form:
it refuses to report success unless it is handed two runs, under two DIFFERENT
`verification_set_undriven_signals` settings, whose verdicts agree.

Why the criterion is two runs (measured, see
evidence/rob-selfcompare-4aa8838b/):

    golden vs a byte-identical copy of itself
                         binary:X (default)   0
      passing            108,209              108,669
      failing             20                  0
      unmatched ref      460                  0
      verdict            FAILED               SUCCEEDED

`0` looks strictly better and it is tempting to adopt it. The four runs in
evidence/rob-selfcompare-4aa8838b/undriven_safety/ measure why that is unsafe:
the app var applies to the IMPLEMENTATION container too, and when the rewrite
leaves a net undriven while golden's driver for it is identically 0, `binary:X`
FAILS and `0` reports SUCCEEDED. A golden-vs-self probe cannot expose that,
because both sides are identical by construction. So a single clean run under
`0` is not evidence of equivalence -- it is evidence only that nothing on the
reference side was left indeterminate.

  verdicts agree     -> nothing was hidden by the setting
  verdicts disagree  -> the difference IS the hidden set; look at it before
                        using either result

What this gate can and cannot do
--------------------------------
It CANNOT stop someone invoking `make fm-Rob` directly and taking the single
verdict that comes out: that would require an `FM_UNDRIVEN` knob inside
scripts/fm_eq.tcl, which every lane shares and which this lane did not modify
unilaterally. It CAN make the two-run acceptance mechanical wherever it is
invoked, and it fails closed on every incomplete input rather than falling back
to "well, one of them passed".

Usage
  python3 scripts/rob_two_run_gate.py <run_dir_a> <run_dir_b>
  python3 scripts/rob_two_run_gate.py --selftest
Each run dir must contain an fm_summary.txt carrying `PROBE_UNDRIVEN <value>`
and a Formality verdict line.
"""
import argparse, os, re, subprocess, sys, tempfile

VERDICT = re.compile(r'Verification\s+(SUCCEEDED|FAILED|INCONCLUSIVE)')
UNDRIVEN = re.compile(r'^PROBE_UNDRIVEN\s+(\S+)\s*$', re.M)
PASSING = re.compile(r'^\s*(\d+)\s+Passing compare points', re.M)


class Bad(Exception):
    """Carries a tag so a negative test can assert WHICH check fired, not just
    that something did. A test that only asserts non-zero exit passes against a
    gate that rejects everything."""
    def __init__(self, tag, msg):
        super().__init__(msg)
        self.tag = tag


def read_run(d):
    p = os.path.join(d, 'fm_summary.txt')
    if not os.path.isfile(p):
        raise Bad('MISSING_SUMMARY', 'no fm_summary.txt in %s' % d)
    txt = open(p).read()
    m = UNDRIVEN.search(txt)
    if not m:
        raise Bad('NO_UNDRIVEN_TAG',
                  '%s does not record PROBE_UNDRIVEN -- cannot tell which '
                  'setting produced it' % p)
    v = VERDICT.search(txt)
    if not v:
        raise Bad('NO_VERDICT', '%s has no Formality verdict line' % p)
    pas = PASSING.search(txt)
    return {'dir': d, 'undriven': m.group(1), 'verdict': v.group(1),
            'passing': int(pas.group(1)) if pas else None}


def gate(dir_a, dir_b):
    a, b = read_run(dir_a), read_run(dir_b)
    if a['undriven'] == b['undriven']:
        raise Bad('SAME_SETTING',
                  'both runs used verification_set_undriven_signals=%s; the '
                  'criterion needs two DIFFERENT settings' % a['undriven'])
    if a['verdict'] != b['verdict']:
        raise Bad('VERDICTS_DISAGREE',
                  'verdicts differ: %s=%s vs %s=%s. That difference IS the set '
                  'the setting hides -- examine it before using either result.'
                  % (a['undriven'], a['verdict'], b['undriven'], b['verdict']))
    if a['verdict'] != 'SUCCEEDED':
        raise Bad('AGREE_BUT_FAILED',
                  'both runs agree on %s -- consistent, but not a pass'
                  % a['verdict'])
    return a, b


def main_gate(argv):
    a, b = gate(argv[0], argv[1])
    print('two-run gate OK: %s and %s both SUCCEEDED (passing %s / %s)'
          % (a['undriven'], b['undriven'], a['passing'], b['passing']))
    return 0


SUMMARY = ('PROBE_MERGE_DUP false\nPROBE_UNDRIVEN %s\n'
           'Verification %s\n %d Passing compare points\n')


def selftest():
    d = tempfile.mkdtemp(prefix='rob-two-run-gate-')

    def mk(name, undriven, verdict, passing=100):
        p = os.path.join(d, name)
        os.makedirs(p, exist_ok=True)
        if undriven is not None:
            with open(os.path.join(p, 'fm_summary.txt'), 'w') as f:
                f.write(SUMMARY % (undriven, verdict, passing))
        return p

    ok_a = mk('ok_a', 'binary:X', 'SUCCEEDED', 108669)
    ok_b = mk('ok_b', '0', 'SUCCEEDED', 108669)
    dis_a = mk('dis_a', 'binary:X', 'FAILED', 108209)
    same_a = mk('same_a', '0', 'SUCCEEDED')
    same_b = mk('same_b', '0', 'SUCCEEDED')
    both_f_a = mk('bf_a', 'binary:X', 'FAILED')
    both_f_b = mk('bf_b', '0', 'FAILED')
    empty = mk('empty', None, None)
    notag = os.path.join(d, 'notag')
    os.makedirs(notag, exist_ok=True)
    with open(os.path.join(notag, 'fm_summary.txt'), 'w') as f:
        f.write('Verification SUCCEEDED\n 1 Passing compare points\n')

    cases = [
        ('positive', (ok_a, ok_b), None,
         'two settings, both SUCCEEDED -> the only accepting case'),
        ('disagree', (dis_a, ok_b), 'VERDICTS_DISAGREE',
         'the real Rob numbers: FAILED under binary:X, SUCCEEDED under 0'),
        ('same_setting', (same_a, same_b), 'SAME_SETTING',
         'running the SAME setting twice must not count as two runs'),
        ('both_failed', (both_f_a, both_f_b), 'AGREE_BUT_FAILED',
         'agreeing on FAILED is consistent but is not a pass'),
        ('missing_run', (ok_a, empty), 'MISSING_SUMMARY',
         'only one run present -> refuse, never fall back to the one verdict'),
        ('untagged', (ok_a, notag), 'NO_UNDRIVEN_TAG',
         'a run that does not say which setting produced it is unusable'),
    ]
    rows = []
    for name, dirs, want_tag, why in cases:
        try:
            gate(*dirs)
            got = None
        except Bad as e:
            got = e.tag
        rows.append((name, got == want_tag, got, want_tag, why))

    # Meta: a gate that rejected everything would satisfy all five negatives.
    # Only the positive distinguishes it, so assert the positive is not vacuous
    # by checking it is the ONLY case that accepts.
    accepts = sum(1 for n, ok, got, want, why in rows if got is None)
    rows.append(('meta_one_accept', accepts == 1, '%d accepting' % accepts,
                 '1 accepting', 'exactly ONE case may accept; a blanket-reject '
                 'gate would show 0 and a blanket-accept gate 6'))

    print('%-16s %-6s %-18s %s' % ('case', 'result', 'tag', 'what it proves'))
    allok = True
    for name, good, got, want, why in rows:
        print('%-16s %-6s %-18s %s'
              % (name, 'OK' if good else 'FAIL', str(got), why))
        if not good:
            allok = False
            print('%-16s   expected %s' % ('', want))
    return 0 if allok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('dirs', nargs='*')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if len(a.dirs) != 2:
        print('usage: rob_two_run_gate.py <run_dir_a> <run_dir_b>', file=sys.stderr)
        return 2
    try:
        return main_gate(a.dirs)
    except Bad as e:
        print('TWO_RUN_GATE_FAIL[%s]: %s' % (e.tag, e), file=sys.stderr)
        return 3


if __name__ == '__main__':
    sys.exit(main())
