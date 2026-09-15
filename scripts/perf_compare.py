#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""perf_compare.py —— golden 与 impl 两侧的 perf 计数器逐条对比。

## 为什么不能直接 diff 两份日志

impl 侧有一部分 perf 观测**没能重绑**（docs/perf_bore_unbound.tsv）。那些 bore 在
生成的 SimTop 里接的是 `'0` —— 于是对应计数器会**打印出一个 0**。0 是一个合法的
数字，肉眼和 `diff` 都分不出「真的没发生过」和「根本没接上」。

本脚本的全部意义就是把这两件事分开：

  MATCH     两侧数值相同，且该计数器的每一条 bore 都绑上了 → 这是真的对上了
  MISMATCH  两侧数值不同（且全绑上了）→ 这是真差异，要查
  EXCLUDED  该计数器含未绑 bore → **不判对错**，直接排除。★不许拿 0==0 算 MATCH★
  MISSING   某一侧没打印这条 → 两侧 dump 触发时刻/配置不一致，先修环境

退出码：有 MISMATCH 或 MISSING 就非 0；EXCLUDED 不影响退出码（它是已知缺口，
数量由 docs/perf_bore_unbound.tsv 钉住，不是本次运行的失败）。

用法:
  scripts/perf_compare.py golden/assert.log impl/assert.log          # 代表性组
  scripts/perf_compare.py golden/assert.log impl/assert.log --all    # 全量
  scripts/perf_compare.py ... --show 40                              # 多列几条差异
"""
from __future__ import print_function

import argparse
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
UNBOUND = REPO / 'docs' / 'perf_bore_unbound.tsv'
REP = REPO / 'docs' / 'perf_rep_counters.tsv'

LINE = re.compile(r'^\[PERF \]\[time=\s*(\d+)\]\s+([^:]+):\s+([^,]+),\s+(\d+)\s*$')


def load_dump(path):
    """读 PERF dump。同一个计数器可能被 dump 多次（warmup/tick），取**最后一次**。"""
    out, times = {}, collections.Counter()
    for ln in pathlib.Path(path).read_text(errors='replace').splitlines():
        m = LINE.match(ln.rstrip())
        if not m:
            continue
        times[int(m.group(1))] += 1
        out[(m.group(2).strip(), m.group(3).strip())] = int(m.group(4))
    return out, times


def load_unbound():
    if not UNBOUND.exists():
        return set()
    out = set()
    for ln in UNBOUND.read_text().splitlines():
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.split('\t')
        if len(f) >= 3 and f[0] == 'PERF':
            out.add((f[1], f[2]))
    return out


def load_rep():
    out = []
    for ln in REP.read_text().splitlines():
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.split('\t')
        if len(f) >= 2:
            out.append((f[0], f[1]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('golden')
    ap.add_argument('impl')
    ap.add_argument('--all', action='store_true', help='比全部计数器（默认只比代表性组）')
    ap.add_argument('--show', type=int, default=20)
    a = ap.parse_args()

    g, gt = load_dump(a.golden)
    i, it = load_dump(a.impl)
    unb = load_unbound()
    print('golden dump: %d 个计数器，dump 时刻 %s' % (len(g), sorted(gt)[:4]))
    print('impl   dump: %d 个计数器，dump 时刻 %s' % (len(i), sorted(it)[:4]))
    if sorted(gt) != sorted(it):
        print('★ 两侧 dump 时刻不同 —— 比对结果不可信，先把 +max-cycles/+e 对齐')

    keys = sorted(set(g) | set(i)) if a.all else load_rep()
    st = collections.Counter()
    mism, miss = [], []
    for k in keys:
        if k in unb:
            st['EXCLUDED'] += 1
            continue
        if k not in g or k not in i:
            st['MISSING'] += 1
            miss.append(k)
            continue
        if g[k] == i[k]:
            st['MATCH'] += 1
        else:
            st['MISMATCH'] += 1
            mism.append((k, g[k], i[k]))

    print()
    print('比对范围: %s（%d 个）' % ('全量' if a.all else 'docs/perf_rep_counters.tsv 代表性组',
                                    len(keys)))
    for kk in ('MATCH', 'MISMATCH', 'EXCLUDED', 'MISSING'):
        print('  %-9s %6d' % (kk, st.get(kk, 0)))
    if mism:
        print('\n--- MISMATCH（前 %d 条）---' % min(a.show, len(mism)))
        for (sc, nm), gv, iv in mism[:a.show]:
            print('  %-72s golden=%-12d impl=%-12d  Δ=%+d' % (sc.split('.core.')[-1] + ': ' + nm,
                                                              gv, iv, iv - gv))
    if miss:
        print('\n--- MISSING（前 %d 条）---' % min(a.show, len(miss)))
        for sc, nm in miss[:a.show]:
            print('  %s: %s  (golden=%s impl=%s)'
                  % (sc, nm, (sc, nm) in g, (sc, nm) in i))
    return 1 if (st.get('MISMATCH') or st.get('MISSING')) else 0


if __name__ == '__main__':
    sys.exit(main())
