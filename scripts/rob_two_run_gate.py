#!/usr/bin/env python3
"""rob_two_run_gate.py -- Rob 的**诊断一致性报告**（不是验收判据）。

★2026-09-19 codex 0168 裁定收窄★
--------------------------------
本文件原先自称 "Rob's acceptance criterion" / "Rob is accepted when ..."。
codex 裁定原文：

    「默认 `binary:X` 仍是签核基线；`0` 仅作差异定位/敏感性实验，
      不能凭 `0` 的 SUCCEEDED 或"两次 verdict 相同"转绿。
      `rob_two_run_gate.py` 可以作为 Rob 的辅助诊断闸，但不要推广为通用签核协议；
      若它目前把 verdict 一致当作充分 PASS 条件，请收窄为"诊断一致性报告"，
      正式 PASS 仍须默认设置下的功能证明与无未解释残留。两次不一致必标红并逐点检查。」

所以本脚本的输出**只是一个诊断结论**：

    两次一致  -> 这个 appvar 没有藏东西（**不代表目标可以转绿**）
    两次不一致 -> ★必标红★，差集就是被藏的集合，逐点检查过之前不许用任何一个结果

★正式 PASS 的判据不在这里★：正式 PASS 仍然是**默认设置 `binary:X` 下**的
功能证明 + 无未解释残留，由 scripts/fm_verdict.py 出。本脚本退出码 0 只表示
"一致性检查通过"，**不构成、也不得被引用为签核依据**。

为什么要两跑（实测，见 evidence/rob-selfcompare-<golden sha256 前缀>/）
---------------------------------------------------------------------
golden 与自身逐字节相同的副本相比：

                         binary:X (默认)   0
      passing            108,209           108,669
      failing             20               0
      unmatched ref      460               0
      verdict            FAILED            SUCCEEDED

`0` 看起来严格更好，很容易想采用它。undriven_safety/ 的四跑量出了为什么不安全：
这个 appvar 对 **implementation 容器同样生效**，当重写件漏驱动一根线、
而 golden 对它的驱动恰好恒 0 时，`binary:X` 失败而 `0` 报 SUCCEEDED。
golden-vs-自身的探针**按构造**暴露不了这一点，因为两侧本来就相同。
所以 `0` 下的一次干净跑不是等价的证据，只说明 reference 侧没有留下不定值。

本脚本拦不住什么
----------------
拦不住有人直接 `make fm-Rob` 取单口径判决 —— 那需要在所有 lane 共用的
scripts/fm_eq.tcl 里加 FM_UNDRIVEN 开关，本 lane 没有擅自改。
它能做的是：凡是被调用到的地方，让"两跑"这件事机械化，且对任何不完整输入
fail-closed，而不是退回到"反正有一个过了"。

用法
  python3 scripts/rob_two_run_gate.py <run_dir_a> <run_dir_b>
  python3 scripts/rob_two_run_gate.py --selftest
每个 run 目录须有 fm_summary.txt，内含 `PROBE_UNDRIVEN <值>` 与 Formality 判决行。
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
         'two settings, both SUCCEEDED -> the only self-consistent case '
         '(一致性通过；★不构成签核依据★)'),
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
