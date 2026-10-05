#!/usr/bin/env python3
"""test_tl2chi_ucore_matcher.py —— scripts/gen_tl2chi_pins.py 里 nested-u_core 匹配器的合成用例（codex 0215 Q2）。

用 tclsh 真跑匹配器（MATCHER_TCL 原文），report_unmatched_points / set_user_match 换成桩：
  正例  multi_slice      2 个 slice × 两层 u_core × 数组展平：恰好 8 对，slice 不串
  正例  generate_kept    `mshrs[0].entry` 这种非 u_core 段原样保留 → 配不上（记 missing，不报错，不猜）
  负例  dup_key          impl 同时有 a/u_core/x_reg 与 a/x_reg（删 u_core 后同 key）→ UCM_FAIL ambiguous
  负例  dup_key_ref      ref 侧两个点展平后同 key（x_1_reg[2] 与 x_1_2_reg）→ UCM_FAIL ambiguous
  负例  cross_slice      ref slices_0、impl slices_1 → 不配（missing 各 1）
  负例  substring        my_u_core / u_core_q 段不是整段 u_core → 不删、不配
  负例  set_fail         set_user_match 返回 0 → UCM_FAIL set_fail
  负例  bad_path         点不在 top 下 → UCM_FAIL bad_path
每个用例同时核对"发生了哪些 set_user_match"与 UCM_SUMMARY 计数。任一不符 rc=1。
用法：python3 scripts/test_tl2chi_ucore_matcher.py
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_tl2chi_pins as gen  # noqa: E402

TOP = 'T'


def run(ref, impl, set_ok=True):
    stub = ['set top %s' % TOP,
            'set ::CALLS {}',
            'proc report_unmatched_points {args} {',
            '  if {[lsearch $args unread] >= 0} { return {} }',
            '  if {[lindex $args 0] eq "-reference"} { return {%s} }' % ' '.join('{%s}' % p for p in ref),
            '  return {%s}' % ' '.join('{%s}' % p for p in impl),
            '}',
            'proc set_user_match {r i} { lappend ::CALLS "$r|$i"; return %d }' % (1 if set_ok else 0),
            'if {[catch {source MATCHER} msg]} { puts "ERROR: $msg" }',
            'foreach c $::CALLS { puts "CALL $c" }']
    with tempfile.TemporaryDirectory() as d:
        mp = os.path.join(d, 'm.tcl')
        open(mp, 'w').write(gen.MATCHER_TCL)
        sp = os.path.join(d, 's.tcl')
        open(sp, 'w').write('\n'.join(stub).replace('MATCHER', mp) + '\n')
        out = subprocess.run(['tclsh', sp], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             universal_newlines=True).stdout
    calls = sorted(l[5:] for l in out.splitlines() if l.startswith('CALL '))
    summ = [l for l in out.splitlines() if l.startswith('UCM_SUMMARY')]
    err = [l for l in out.splitlines() if l.startswith('ERROR:')]
    return calls, (summ[0] if summ else ''), (err[0] if err else '')


R = 'r:/WORK/%s/' % TOP
I = 'i:/WORK/%s/' % TOP
CASES = []
ref = ['%sslices_%d/mshrCtl/q_%d_reg[%d]' % (R, k, j, b) for k in (0, 1) for j in (0, 1) for b in (0, 1)]
impl = ['%sslices_%d/u_core/mshrCtl/u_core/q_reg[%d][%d]' % (I, k, j, b) for k in (0, 1) for j in (0, 1) for b in (0, 1)]
want = sorted('%sslices_%d/mshrCtl/q_%d_reg[%d]|%sslices_%d/u_core/mshrCtl/u_core/q_reg[%d][%d]' % (R, k, j, b, I, k, j, b)
              for k in (0, 1) for j in (0, 1) for b in (0, 1))
CASES.append(('multi_slice', ref, impl, True, want, 'matched=8 ambiguous=0 missing_ref=0 missing_impl=0', ''))
CASES.append(('generate_kept', [R + 'mshrCtl/mshrs_0/t_reg'], [I + 'u_core/mshrCtl/u_core/mshrs[0].entry/u_core/t_reg'],
              True, [], 'matched=0 ambiguous=0 missing_ref=1 missing_impl=1', ''))
CASES.append(('dup_key', [R + 'a/x_reg'], [I + 'a/u_core/x_reg', I + 'a/x_reg'], True, [], 'ambiguous=1', 'UCM_FAIL'))
CASES.append(('dup_key_ref', [R + 'a/x_1_reg[2]', R + 'a/x_1_2_reg'], [I + 'a/u_core/x_reg[1][2]'], True, [],
              'ambiguous=1', 'UCM_FAIL'))
CASES.append(('cross_slice', [R + 'slices_0/x_reg'], [I + 'slices_1/u_core/x_reg'], True, [],
              'matched=0 ambiguous=0 missing_ref=1 missing_impl=1', ''))
CASES.append(('substring', [R + 'slices_0/x_reg', R + 'slices_0/y_reg'],
              [I + 'slices_0/my_u_core/x_reg', I + 'slices_0/u_core_q/y_reg'], True, [],
              'matched=0 ambiguous=0 missing_ref=2 missing_impl=2', ''))
CASES.append(('set_fail', [R + 'a/x_reg'], [I + 'u_core/a/x_reg'], False, [R + 'a/x_reg|' + I + 'u_core/a/x_reg'],
              'set_fail=1', 'UCM_FAIL'))
CASES.append(('bad_path', [R + 'a/x_reg', 'r:/WORK/OTHER/a/x_reg'], [I + 'u_core/a/x_reg'], True, None,
              'bad_path=1', 'UCM_FAIL'))


def main():
    rc = 0
    for name, ref, impl, ok, want_calls, want_summ, want_err in CASES:
        calls, summ, err = run(ref, impl, ok)
        good = all(tok in summ for tok in want_summ.split())
        if want_calls is not None and calls != want_calls:
            good = False
        if bool(want_err) != bool(err) or (want_err and want_err not in err):
            good = False
        print('%-14s %s  %s %s' % (name, 'PASS' if good else 'FAIL', summ, err))
        if not good:
            print('    calls=%s' % calls)
            rc = 1
    return rc


if __name__ == '__main__':
    sys.exit(main())
