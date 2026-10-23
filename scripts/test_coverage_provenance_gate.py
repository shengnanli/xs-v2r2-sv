#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_coverage_provenance.py 的双向负测。

规矩（CONVENTIONS.md「闸的负测必须是双向的」）：
  正向——该报的必须报（每条判据各造一例真缺陷）
  反向——不该报的一个也不许报

反向那一半是这道闸的重点，因为它第一版**就是在反向上错的**：
把 11 个 DelayReg 误报成"有 receipt 却没记账"，而 DelayReg 是
excluded:simtop_only（只被 SimTop 下的 GatewayEndpoint 例化，在 XSTop 根之外），
本来就不该进这张表。有 receipt 而无表行是**正常**的。
"""
import io
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
GATE = os.path.join(HERE, 'check_coverage_provenance.py')


def run_in(sandbox):
    """在沙箱副本里跑闸，返回 (rc, stdout+stderr)。

    ★必须跑**沙箱里那份副本**，不能跑原始路径的闸★
    闸最后一行是 `os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))`
    —— 它按**自己文件的位置**定位仓库根，所以只改 subprocess 的 cwd 完全没用，
    跑原始路径就会去读真仓库。本负测第一版正是这么写错的：四个正向用例全部
    "通过"，实际上读的是真仓库的 250/1814，跟沙箱里造的缺陷毫无关系。
    """
    gate = os.path.join(sandbox, 'scripts', 'check_coverage_provenance.py')
    r = subprocess.run([sys.executable, gate, '--strict'],
                       cwd=sandbox, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    return r.returncode, r.stdout.decode('utf-8', 'replace')


def make_sandbox(tmp):
    """做一份最小沙箱：docs/ 两张表 + 一个假的 git 仓库（含 evidence）。

    闸用 `git ls-files` 读 tracked receipt，所以沙箱必须是真 git 仓库。
    """
    sb = os.path.join(tmp, 'repo')
    os.makedirs(os.path.join(sb, 'docs'))
    os.makedirs(os.path.join(sb, 'scripts'))
    shutil.copy(GATE, os.path.join(sb, 'scripts', 'check_coverage_provenance.py'))
    subprocess.run(['git', 'init', '-q'], cwd=sb, check=True)
    subprocess.run(['git', 'config', 'user.email', 't@t'], cwd=sb, check=True)
    subprocess.run(['git', 'config', 'user.name', 't'], cwd=sb, check=True)
    return sb


def write(sb, rel, text):
    p = os.path.join(sb, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    io.open(p, 'w', encoding='utf-8').write(text)
    return p


def receipt(top, verdict='SUCCEEDED'):
    return '{"top": "%s", "verdict": "%s"}\n' % (top, verdict)


def scenario(tmp, coverage, universe, receipts):
    """receipts: {commit_dir: [(top, verdict, tracked?)]}"""
    sb = make_sandbox(tmp)
    write(sb, 'docs/coverage_three_axis.tsv', coverage)
    write(sb, 'docs/g1_configured_universe.tsv', universe)
    to_add = []
    for i, (top, verdict, tracked) in enumerate(receipts):
        rel = 'evidence/c%04d/%s/receipt.json' % (i, top)
        write(sb, rel, receipt(top, verdict))
        if tracked:
            to_add.append(rel)
    if to_add:
        subprocess.run(['git', 'add', '-f'] + to_add, cwd=sb, check=True)
    return run_in(sb)


# 表头分母 = universe 里 yes 的条数
COV_HDR = '# 三轴覆盖（分母 = .../g1_configured_universe.tsv 的 in_universe=yes，共 %d）\n' \
          '# module\trewrite_coverage\tformal_coverage\timpl_file\n'


COV_HDR6 = '# 三轴覆盖（分母 = .../g1_configured_universe.tsv 的 in_universe=yes，共 %d）\n' \
           '# module\trewrite_coverage\tformal_coverage\timpl_file\tgolden_used_by\tproof_status\n'


def main():
    cases = []

    # ---------- 正向：该报的 ----------
    # A：表里 PROVEN_DIRECT，但 receipt 没进版本库（只在磁盘上）
    cases.append((
        'A 证据只在磁盘未进库',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', False)],
        True, '判据 A 失败',
    ))
    # A：receipt 进了库但 verdict 不是通过
    cases.append((
        'A receipt 存在但没通过',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'PARTIAL', True)],
        True, '判据 A 失败',
    ))
    # B：表头分母过期
    cases.append((
        'B 分母过期',
        (COV_HDR % 99) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True)],
        True, '判据 B 失败',
    ))
    # C：universe 内的目标有通过 receipt，表里却没记
    cases.append((
        'C universe 内漏记',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True), ('Bar', 'SUCCEEDED', True)],
        True, '判据 C 失败',
    ))

    # ★ledger-cv★ D：PROVEN_DIRECT 但 proof_status 不是 current_valid（手改一侧）
    cases.append((
        'D PROVEN_DIRECT 却记 not_current',
        (COV_HDR6 % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\t-\tnot_current:x\n'
                         'Bar\tMISSING\tUNPROVEN\t-\t-\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True)],
        True, '判据 D 失败',
    ))
    # D 反方向：proof_status 说 current_valid，formal 却不是 PROVEN_DIRECT
    cases.append((
        'D current_valid 却没记 PROVEN_DIRECT',
        (COV_HDR6 % 2) + 'Foo\tREWRITTEN\tPROVEN_IN_CONE\trtl/Foo.sv\t-\tcurrent_valid:certificate\n'
                         'Bar\tMISSING\tUNPROVEN\t-\t-\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True)],
        True, '判据 D 失败',
    ))
    # C（6 列表）：有通过 receipt、formal 非 DIRECT、proof_status 也是 - → 仍是漏记
    cases.append((
        'C 6 列表 proof_status 为 - 仍算漏记',
        (COV_HDR6 % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\t-\tcurrent_valid:certificate\n'
                         'Bar\tMISSING\tUNPROVEN\t-\t-\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True), ('Bar', 'SUCCEEDED', True)],
        True, '判据 C 失败',
    ))

    # ---------- 反向：不许误报 ----------
    # ★ledger-cv★ 证明不 current-valid 的根：记 superseded_by / not_current 就算记过账，不许报 C
    cases.append((
        '反向 不 current-valid 的根记 superseded_by / not_current 不算漏记',
        (COV_HDR6 % 3) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\t-\tcurrent_valid:certificate\n'
                         'Old\tREWRITTEN\tPROVEN_IN_CONE\trtl/Old.sv\t-\tsuperseded_by=Foo\n'
                         'Gone\tREWRITTEN\tUNPROVEN\trtl/Gone.sv\t-\tnot_current:green_child_script_closure_changed\n',
        'Foo\tyes\tr\nOld\tyes\tr\nGone\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True), ('Old', 'SUCCEEDED', True), ('Gone', 'SUCCEEDED', True)],
        False, None,
    ))
    # 全都对上
    cases.append((
        '反向 全部一致',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'SUCCEEDED', True)],
        False, None,
    ))
    # ★关键反例★：universe 之外的目标有通过 receipt、表里没有它 —— 不许报
    # （真实原型：DelayReg×11 是 excluded:simtop_only）
    cases.append((
        '反向 universe 外的目标有 receipt 不算漏记',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\nSimOnly\tno\texcluded:simtop_only\n',
        [('Foo', 'SUCCEEDED', True), ('SimOnly', 'SUCCEEDED', True)],
        False, None,
    ))
    # PASS_DEAD_REF 也算通过
    cases.append((
        '反向 PASS_DEAD_REF 算通过',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_DIRECT\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [('Foo', 'PASS_DEAD_REF', True)],
        False, None,
    ))
    # PROVEN_IN_CONE 不是 PROVEN_DIRECT，不要求直接 receipt
    cases.append((
        '反向 PROVEN_IN_CONE 不要求直接 receipt',
        (COV_HDR % 2) + 'Foo\tREWRITTEN\tPROVEN_IN_CONE\trtl/Foo.sv\nBar\tMISSING\tUNPROVEN\t-\n',
        'Foo\tyes\tr\nBar\tyes\tr\n',
        [],
        False, None,
    ))

    bad = []
    with tempfile.TemporaryDirectory() as tmp:
        for i, (name, cov, uni, rcp, want_fail, want_msg) in enumerate(cases):
            d = os.path.join(tmp, 'case%d' % i)
            os.makedirs(d)
            rc, out = scenario(d, cov, uni, rcp)
            got_fail = (rc != 0)
            if got_fail != want_fail:
                bad.append((name, want_fail, got_fail, out))
            elif want_msg and want_msg not in out:
                bad.append((name, '含 "%s"' % want_msg, '没有', out))

    if bad:
        print('test_coverage_provenance_gate: 失败 —— %d 例不符' % len(bad), file=sys.stderr)
        for name, want, got, out in bad:
            print('  %s  期望=%s 实际=%s' % (name, want, got), file=sys.stderr)
            for l in out.splitlines()[:4]:
                print('      %s' % l, file=sys.stderr)
        return 1

    fwd = sum(1 for c in cases if c[4])
    rev = len(cases) - fwd
    print('test_coverage_provenance_gate: OK —— 正向 %d 例全拦下，反向 %d 例全不误报'
          % (fwd, rev))
    return 0


if __name__ == '__main__':
    sys.exit(main())
