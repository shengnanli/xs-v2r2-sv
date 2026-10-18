#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_coverage_three_axis_priority.py —— 三轴轴一「floor 优先于 golden 用法」的正反测。

codex 0238 裁定 1：轴一回答「有没有可读实现、过没过 rewritten_floor」。
rtl/ 有定义的先过 floor；别的 UT / 证明 impl 侧还读着 golden，只进 golden_used_by
列，**不许**把已完成的实现盖成 GOLDEN_REUSE。rtl/ 没定义而 impl 侧读 golden 的仍是
GOLDEN_REUSE。

本文件验（全部用合成输入，秒级，不扫 golden、不跑 classify_rtl）：
  正例  rtl 有定义 + floor REWRITTEN + 被 UT 读 golden    → REWRITTEN（不是 GOLDEN_REUSE）
        rtl 没定义 + 被 UT/证明读 golden                  → GOLDEN_REUSE
        rtl 没定义 + 谁也没读                              → MISSING
        vendor 边界                                         → VENDOR_BOUNDARY（压过一切）
  反例  rtl 有定义但 floor 判 SKELETON/PARTIAL_DRIVE + 被读 golden
                                                            → 照 floor 落档，★不许★变成 REWRITTEN
                                                              也不许变成 GOLDEN_REUSE
        rtl 有定义、floor 表里查不到                        → SKELETON（fail-closed）
  用法列
        UT 依赖里指向 rtl/ 的本地件（ClockGate 这类）       → 不算 golden 用户
        UT 依赖经 make 变量间接（$(addprefix ...)）          → 必须展开后记上
        receipt：只取每 top 最新一份通过的；失败/provisional/dirty 不收；
                 kind=repo 的条目不算 golden 用户
"""
import json
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'scripts'))
import coverage_three_axis as C3  # noqa: E402

FAILS = []
N = [0]


def ck(name, ok, detail=''):
    N[0] += 1
    print('  [%s] %s%s' % ('OK' if ok else 'FAIL', name, ('  ' + detail) if detail else ''))
    if not ok:
        FAILS.append(name)


def t_axis1():
    vend = {'V'}
    rtl = {'A': 'rtl/a/A.sv', 'S': 'rtl/a/S.sv', 'P': 'rtl/a/P.sv',
           'U': 'rtl/a/U.sv', 'V': 'rtl/a/V.sv'}
    floor = {'A': ('REWRITTEN',), 'S': ('SKELETON',), 'P': ('PARTIAL_DRIVE',),
             'V': ('REWRITTEN',)}
    users = {'A': ['ut:XSCore'], 'S': ['ut:XSCore'], 'P': ['fm:X'],
             'G': ['ut:XSCore'], 'H': ['fm:CtrlBlock'], 'V': ['ut:XSCore']}
    f = lambda m: C3.axis1(m, vend, rtl, floor, users)
    ck('正例 rtl+REWRITTEN 被 golden 用 → REWRITTEN', f('A') == 'REWRITTEN', f('A'))
    ck('正例 无 rtl、UT 读 golden → GOLDEN_REUSE', f('G') == 'GOLDEN_REUSE', f('G'))
    ck('正例 无 rtl、证明读 golden → GOLDEN_REUSE', f('H') == 'GOLDEN_REUSE', f('H'))
    ck('正例 无 rtl、无人读 → MISSING', f('M') == 'MISSING', f('M'))
    ck('正例 vendor 压过一切', f('V') == 'VENDOR_BOUNDARY', f('V'))
    ck('反例 SKELETON 被 golden 用 → 仍 SKELETON', f('S') == 'SKELETON', f('S'))
    ck('反例 PARTIAL_DRIVE 被 golden 用 → 仍 PARTIAL_DRIVE',
       f('P') == 'PARTIAL_DRIVE', f('P'))
    ck('反例 floor 查不到 → SKELETON（fail-closed）', f('U') == 'SKELETON', f('U'))


def t_ut_users():
    with tempfile.TemporaryDirectory(prefix='c3p-', dir=str(REPO.parent)) as tmp:
        root = pathlib.Path(tmp)
        (root / 'X').mkdir()
        (root / 'X' / 'Makefile').write_text(
            'GOLDEN_RTL ?= /nowhere/golden-rtl\n'
            'LEAVES = Foo.sv Bar.sv\n'
            'RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \\\n'
            '    ../../rtl/memblock/Loc.sv \\\n'
            '    $(addprefix $(GOLDEN_RTL)/,$(LEAVES)) $(GOLDEN_RTL)/Baz.sv\n'
            'all:\n\t@true\n')
        (root / 'Y').mkdir()
        (root / 'Y' / 'Makefile').write_text('all:\n\t@true\n')
        u = C3.ut_golden_users(ut_root=root, repo=REPO)
        ck('用法 make 变量间接展开（Foo/Bar）',
           u.get('Foo') == {'ut:X'} and u.get('Bar') == {'ut:X'}, repr(u))
        ck('用法 直接写的 golden（Baz）', u.get('Baz') == {'ut:X'}, repr(u))
        ck('用法 rtl/ 本地件不算 golden 用户（ClockGate/Loc）',
           'ClockGate' not in u and 'Loc' not in u, repr(sorted(u)))
        ck('用法 没有 RTL_GOLDEN_DEPS 的 UT 不出现', not any('ut:Y' in v for v in u.values()))
        (root / 'Z').mkdir()
        (root / 'Z' / 'Makefile').write_text('RTL_GOLDEN_DEPS = $(error boom)\n')
        try:
            C3.ut_golden_users(ut_root=root, repo=REPO)
            ck('反例 make 展开失败必须 fail-closed', False, '没抛')
        except SystemExit:
            ck('反例 make 展开失败必须 fail-closed', True)


def t_receipt_users():
    g = lambda p: {'path': 'golden-rtl/%s.sv' % p, 'kind': 'golden', 'sha256': 'x'}
    r = lambda p: {'path': 'rtl/%s.sv' % p, 'kind': 'repo', 'sha256': 'x'}
    recs = [
        ('evidence/a/T/receipt.json', {'top': 'T', 'verdict': 'SUCCEEDED',
         'run_id': 'T-20261001T000000Z-a', 'impl_closure': [g('Old')]}),
        ('evidence/b/T/receipt.json', {'top': 'T', 'verdict': 'SUCCEEDED',
         'run_id': 'T-20261002T000000Z-b', 'impl_closure': [g('New'), r('Mine')]}),
        ('evidence/c/T/receipt.json', {'top': 'T', 'verdict': 'FAILED',
         'run_id': 'T-20261003T000000Z-c', 'impl_closure': [g('Fail')]}),
        ('evidence/d/Q/receipt.json', {'top': 'Q', 'verdict': 'PASS_DEAD_REF',
         'provisional': True, 'run_id': 'Q-20261003T000000Z-d',
         'impl_closure': [g('Prov')]}),
    ]
    u = C3.receipt_golden_users(recs)
    ck('receipt 取每 top 最新通过的一份', u.get('New') == {'fm:T'}, repr(u))
    ck('receipt 旧 run 用过 golden 不算现行用户', 'Old' not in u, repr(sorted(u)))
    ck('receipt FAILED 不收', 'Fail' not in u, repr(sorted(u)))
    ck('receipt provisional 不收', 'Prov' not in u, repr(sorted(u)))
    ck('receipt kind=repo 不是 golden 用户', 'Mine' not in u, repr(sorted(u)))


def t_real_rob():
    """真表上的锚点：Rob 是 rtl/ 有定义、floor REWRITTEN 的核内件，
    旧逻辑因 XSCore UT 读 golden 整棵子树把它记成 GOLDEN_REUSE。"""
    tsv = REPO / 'docs' / 'coverage_three_axis.tsv'
    hdr = [l for l in tsv.read_text().splitlines() if l.startswith('# module')]
    if not hdr or 'golden_used_by' not in hdr[0]:
        print('  [SKIP] docs/coverage_three_axis.tsv 尚未用新生成器重出（集成者重出后自动生效）')
        return
    rows = {l.split('\t')[0]: l.split('\t') for l in tsv.read_text().splitlines()
            if l and not l.startswith('#')}
    rob = rows.get('Rob')
    ck('真表 Rob 轴一 = REWRITTEN', rob is not None and rob[1] == 'REWRITTEN', repr(rob))
    ck('真表 Rob golden_used_by 保留 XSCore 仿真用法',
       rob is not None and 'ut:XSCore' in rob[4].split(','), repr(rob))


def main():
    t_axis1()
    t_ut_users()
    t_receipt_users()
    t_real_rob()
    print('test_coverage_three_axis_priority: %d 条，失败 %d' % (N[0], len(FAILS)))
    return 1 if FAILS else 0


if __name__ == '__main__':
    sys.exit(main())
