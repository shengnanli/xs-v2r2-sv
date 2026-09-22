#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_shared_impl_impact.py —— 改了 rtl/ 文件，就说出它让哪些 receipt 失效（codex 0170）。

## 这道闸在防什么（实测事故，不是假想）

`609baba5`「perfWakeupByWB 门控改用 currentStatus」是一次**正当且必须做的**一行 bug 修复。
它同时让 9 个 Entries* 变体的绿 receipt 失效 —— 那 9 份证明认证的是**带着那个 bug 的那版核**。
合计约 40 万 golden 行的"已证明"当场变成"未知"，★而此前没有任何东西发声★。

另一个实测反例更硬：`29dd150a`（改共享核参数 API）与 `809aebb6`（OthersEntry 签核）
★互不为祖先★ —— 两条并行 lane，各自内部都自洽，谁都没做错。
分别合入 main 之后凑成「新核 + 旧 wrapper」，整族坏到连 elaborate 都过不去
（`FMR_VLOG-273 Parameter 'IQ_TYPE_BIT' not defined`），而 30 份 tracked receipt 照样让台账记绿，
直到 `check_param_override` 偶然撞见。

★并行 lane 模型必然产生这种状态，靠"下次注意"防不住，只能靠机器判据。★

## 它做什么 / 不做什么

做：拿每份 tracked receipt 的 `impl_closure`（kind=repo 的文件 + 其 sha256）反查——
    给定一组改动过的 rtl/ 文件，列出**受影响的目标集合与数量**。
不做：★不自动启动 Formal★（codex 0170 明确：「只做 hash/依赖检查，不自动启动 Formal，
    不把每次提交变成长阻塞闸」）。受影响目标由 `rewrite_coverage.py` 自动归
    `STALE_IMPL_NEEDS_RERUN`、不计当前 proven；重验由 integrator 按共享核家族批量安排。

## 用法

    python3 scripts/check_shared_impl_impact.py                 # 对比工作树 vs HEAD
    python3 scripts/check_shared_impl_impact.py --rev A..B      # 对比两个 commit
    python3 scripts/check_shared_impl_impact.py --file <路径>…  # 直接问指定文件
    python3 scripts/check_shared_impl_impact.py --shared-only   # 只列被 2 份以上 receipt 共用的文件
    python3 scripts/check_shared_impl_impact.py --selftest      # 判据自身正反测

退出码：0 = 没有受影响目标；1 = 有（★这不是"错"，是"有账要记"★）。
"""
from __future__ import print_function

import argparse
import collections
import json
import os
import subprocess
import sys

REPO = os.environ.get('XSSV_HOME') or os.path.dirname(os.path.dirname(
    os.path.abspath(__file__)))


def _sh(args):
    try:
        return subprocess.check_output(args, cwd=REPO,
                                       stderr=subprocess.DEVNULL).decode()
    except Exception:
        return ''


def receipt_index():
    """{rtl 文件相对路径: {目标名: [sha256, …]}}，只看已跟踪的 receipt。"""
    idx = collections.defaultdict(lambda: collections.defaultdict(list))
    for rel in _sh(['git', 'ls-files', 'evidence/*/receipt.json']).split():
        p = os.path.join(REPO, rel)
        try:
            with open(p) as f:
                d = json.load(f)
        except Exception:
            continue
        tgt = rel.split('/')[2] if rel.count('/') >= 3 else None
        if not tgt:
            continue
        for e in (d.get('impl_closure') or []):
            if e.get('kind') != 'repo':
                continue
            path = e.get('path') or ''
            if path.startswith('rtl/'):
                idx[path][tgt].append(e.get('sha256'))
    return idx


def changed_files(rev=None):
    if rev:
        out = _sh(['git', 'diff', '--name-only', rev])
    else:
        out = _sh(['git', 'diff', '--name-only', 'HEAD'])
    return [f for f in out.split() if f.startswith('rtl/')]


def report(files, idx, shared_only=False):
    hit = collections.defaultdict(set)
    for f in files:
        owners = idx.get(f) or {}
        if shared_only and len(owners) < 2:
            continue
        for tgt in owners:
            hit[tgt].add(f)
    return hit


_SELF_RECEIPT = {
    'impl_closure': [
        {'kind': 'repo', 'path': 'rtl/backend/_probe_shared.sv', 'sha256': 'a' * 64},
        {'kind': 'repo', 'path': 'rtl/backend/_probe_own.sv', 'sha256': 'b' * 64},
        {'kind': 'golden', 'path': 'golden/x.sv', 'sha256': 'c' * 64},
    ]
}


def selftest():
    """★判据既要证明它会响，也要证明它不会乱响★"""
    bad = 0
    idx = collections.defaultdict(lambda: collections.defaultdict(list))
    for e in _SELF_RECEIPT['impl_closure']:
        if e['kind'] == 'repo':
            idx[e['path']]['T1'].append(e['sha256'])
    idx['rtl/backend/_probe_shared.sv']['T2'].append('a' * 64)

    cases = [
        ('正例 改共享件 -> 两个目标都受影响',
         ['rtl/backend/_probe_shared.sv'], False, {'T1', 'T2'}),
        ('正例 改私有件 -> 只影响它自己',
         ['rtl/backend/_probe_own.sv'], False, {'T1'}),
        ('负例 改无关文件 -> 一个都不影响',
         ['rtl/backend/_nobody_cares.sv'], False, set()),
        ('负例 golden 侧文件不参与反查',
         ['golden/x.sv'], False, set()),
        ('--shared-only 只认被 2 份以上共用的',
         ['rtl/backend/_probe_own.sv'], True, set()),
        ('--shared-only 共享件仍要报',
         ['rtl/backend/_probe_shared.sv'], True, {'T1', 'T2'}),
    ]
    for name, files, so, want in cases:
        got = set(report(files, idx, so))
        ok = got == want
        print('  %-40s %s' % (name, 'ok' if ok else
                              '★FAIL 期望 %s 实得 %s' % (sorted(want), sorted(got))))
        bad += (not ok)
    # 元负测：判据写空时正例必须转红
    empty = collections.defaultdict(lambda: collections.defaultdict(list))
    if set(report(['rtl/backend/_probe_shared.sv'], empty, False)):
        print('  ★FAIL 元负测：索引为空时仍报出受影响目标★')
        bad += 1
    else:
        print('  %-40s ok' % '元负测 索引为空时正例必须转红')
    print('check_shared_impl_impact --selftest: %s'
          % ('全过' if not bad else '★%d 条未过★' % bad))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rev', help='形如 A..B；缺省对比工作树与 HEAD')
    ap.add_argument('--file', nargs='*', help='直接指定 rtl/ 文件')
    ap.add_argument('--shared-only', action='store_true',
                    help='只看被 2 份以上 receipt 共用的文件')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()

    idx = receipt_index()
    files = a.file if a.file else changed_files(a.rev)
    if not files:
        print('check_shared_impl_impact: 没有改动过的 rtl/ 文件，无账可记')
        return 0

    hit = report(files, idx, a.shared_only)
    print('check_shared_impl_impact: 改动 %d 个 rtl/ 文件' % len(files))
    if not hit:
        print('  受影响目标 0 个 —— 这些文件不在任何已跟踪 receipt 的 impl_closure 里')
        return 0

    print('  ★受影响目标 %d 个★（它们在新 receipt 产生前一律 STALE_IMPL_NEEDS_RERUN，'
          '不计当前 proven）：' % len(hit))
    for tgt in sorted(hit):
        print('    %-46s 经由 %s' % (tgt, ','.join(sorted(hit[tgt])[:2])))
    # 共享度最高的几个文件，便于按家族批量安排重验
    deg = sorted(((len(idx.get(f) or {}), f) for f in files), reverse=True)
    top = [(n, f) for n, f in deg if n >= 2][:5]
    if top:
        print('  共享度最高的改动文件（按家族批量重验的入口）：')
        for n, f in top:
            print('    %-52s 被 %d 份 receipt 共用' % (f, n))
    print('  ★本闸只做 hash/依赖检查，不自动启动 Formal（codex 0170）★')
    return 1


if __name__ == '__main__':
    sys.exit(main())
