#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_perf_tier.py —— perf 分档台账的 fail-closed 闸（codex 0162 D3 第 4 条）。

## 这道闸挡的是什么

分档这件事一旦落成台账，就有三种"悄悄烂掉"的方式，每一种都不会自己报错：

  1. **台账过期**：golden 换一版、或 `docs/perf_bore_map.tsv` 重算了，而台账没跟着走。
     后果不是报错，是一张看着很权威的过期表。→ 判据 A（逐字节重算）。
  2. **冒出"未分类"**：golden 里出现本脚本没见过的写法，于是一批计数器既不是
     必须相等、也不是允许不同，就那么悬着。★这个状态不许存在★ → 判据 B。
  3. **豁免过期**：codex 0162 D3 的豁免有两个条件 —— C_DIAG **且**持有模块未重写。
     第二个条件是会变的：Tage_SC 一旦被重写，那 6 条 tage provider 差异就**不再**
     豁免。没有闸的话，`docs/perf_mismatch_ledger.tsv` 里那句 WAIVED 会一直挂着。
     → 判据 E（豁免逐条现算，不认台账里写死的那一列）。

## 逐条判据

  A 台账幂等      docs/perf_tier_ledger.tsv 与 docs/perf_gap_ledger.tsv 必须能从
                  golden + docs/perf_bore_map.tsv + rtl/ 现场逐字节重算（--recompute）。
  B 无未分类      tier 列必须落在封闭词表内，且 X_UNRESOLVED 计数必须为 0。
  C 两表自洽      gap 台账的行集合 ≡ tier 台账里 status=GAP 的行集合（双向，不许单边）。
  D 证据可复跑    mismatch 台账头部必须钉住 commit、两份 assert.log 的路径与
                  **完整 64 位** sha256、以及 dump_times_equal=True。
                  ★截断的 hash 不算证据（D62）★ —— 所以这里逐字符校验长度与字符集。
  E 豁免现算      mismatch 台账每一行：计数器必须在 tier 台账里；记录的 tier 与
                  owner_rewritten 必须与 tier 台账当前值一致；verdict 必须等于用
                  scripts/perf_compare.py 的 verdict_of() **现算**的结果；
                  且不许有任何 BLOCKING 行。
  F 代表性组      docs/perf_rep_counters.tsv 里的每一条都必须在 tier 台账里有档。

用法:
  python3 scripts/check_perf_tier.py                 # 全部判据（含 A，约 80 秒）
  python3 scripts/check_perf_tier.py --no-recompute  # 跳过 A（负测用，秒级）
  python3 scripts/check_perf_tier.py --dir DIR       # 换一套台账（负测用）
"""
from __future__ import print_function

import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))
import perf_compare as PC                                           # noqa: E402

TIERS = ('A_FUNC_ASSERT', 'B_CONTROL', 'C_DIAG', 'D_CONST', 'D_INVARIANT', 'X_UNRESOLVED')
STATUSES = ('MEASURED', 'GAP', 'BY_CONSTRUCTION')
SHA256 = re.compile(r'^[0-9a-f]{64}$')


def rows_of(path, skip_prefix):
    out = []
    for ln in path.read_text(errors='replace').splitlines():
        if not ln or ln.startswith('#') or ln.startswith(skip_prefix):
            continue
        out.append(ln.split('\t'))
    return out


def header_of(path):
    """`# key value` 形式的头部字段。"""
    d = {}
    for ln in path.read_text(errors='replace').splitlines():
        if not ln.startswith('#'):
            break
        m = re.match(r'#\s+(\w+)\s+(\S.*)$', ln)
        if m:
            d.setdefault(m.group(1), m.group(2).strip())
    return d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', default=str(REPO / 'docs'))
    ap.add_argument('--golden', default='/home/eda/xs-env/G1-canonical/golden-rtl')
    ap.add_argument('--no-recompute', action='store_true',
                    help='跳过判据 A（重算 golden，约 80 秒）—— 负测用')
    a = ap.parse_args()
    d = pathlib.Path(a.dir)
    tier_p, gap_p, mism_p = (d / 'perf_tier_ledger.tsv', d / 'perf_gap_ledger.tsv',
                             d / 'perf_mismatch_ledger.tsv')
    fails = []

    def check(name, cond, detail=''):
        if not cond:
            fails.append('%s: %s' % (name, detail))
        print('  %-40s %s' % (name, 'ok' if cond else '★FAIL ' + detail))

    for p in (tier_p, gap_p, mism_p):
        if not p.exists():
            print('  %-40s ★FAIL 不存在' % p.name)
            fails.append('%s 不存在' % p)
    if fails:
        print('check_perf_tier: %d 条判据未过' % len(fails))
        return 1

    # ---- A 台账幂等
    if a.no_recompute:
        print('  %-40s (--no-recompute 跳过)' % 'A 台账幂等')
    else:
        import perf_tier as PT
        led, gl, st, _n, _ng = PT.build(a.golden)
        check('A 台账幂等 tier', tier_p.read_text() == led, '与重算结果不一致（DRIFT）')
        check('A 台账幂等 gap', gap_p.read_text() == gl, '与重算结果不一致（DRIFT）')
        check('A 重算无未分类', st['X_UNRESOLVED'] == 0,
              '%d 个 X_UNRESOLVED' % st['X_UNRESOLVED'])

    tier_rows = rows_of(tier_p, 'kind\t')
    gap_rows = rows_of(gap_p, 'tier\t')
    mism_rows = rows_of(mism_p, 'tier\t')
    tier = {}
    for r in tier_rows:
        tier[(r[1], r[2])] = dict(kind=r[0], tier=r[3], status=r[4], owners=r[8],
                                  rewritten=r[9])

    # ---- B 无未分类
    badtier = [r for r in tier_rows if r[3] not in TIERS]
    check('B tier 词表封闭', not badtier,
          '%d 行 tier 不在词表: %s' % (len(badtier), badtier[0][3] if badtier else ''))
    unres = [r for r in tier_rows if r[3] == 'X_UNRESOLVED']
    check('B 无 X_UNRESOLVED 行', not unres,
          '%d 条未分类（%s: %s）' % (len(unres), unres[0][1], unres[0][2]) if unres else '')
    badst = [r for r in tier_rows if r[4] not in STATUSES]
    check('B status 词表封闭', not badst, '%d 行 status 不在词表' % len(badst))

    # ---- C 两表自洽
    gap_from_tier = set((r[1], r[2]) for r in tier_rows if r[4] == 'GAP')
    gap_listed = set((r[1], r[2]) for r in gap_rows)
    check('C gap 台账 ⊇ tier 台账的 GAP', not (gap_from_tier - gap_listed),
          '%d 条 GAP 没进 gap 台账' % len(gap_from_tier - gap_listed))
    check('C gap 台账 ⊆ tier 台账的 GAP', not (gap_listed - gap_from_tier),
          '%d 条 gap 台账行在 tier 台账里不是 GAP' % len(gap_listed - gap_from_tier))
    nolift = [r for r in gap_rows if len(r) < 9 or not r[8].strip()]
    check('C 每条 GAP 都有解除条件', not nolift, '%d 条 lift_condition 为空' % len(nolift))

    # ---- D 证据可复跑（D62）
    h = header_of(mism_p)
    for k in ('golden_log_sha256', 'impl_log_sha256', 'tier_ledger_sha256',
              'gap_ledger_sha256'):
        check('D %s 是完整 sha256' % k, bool(SHA256.match(h.get(k, ''))),
              '缺失或被截断: %r' % h.get(k, ''))
    for k in ('commit', 'golden_log', 'impl_log'):
        check('D 头部有 %s' % k, bool(h.get(k)), '缺失')
    check('D dump_times_equal', h.get('dump_times_equal') == 'True',
          '两侧 dump 时刻不同 ⇒ D_INVARIANT 档的前提失效，比对不可信')

    # ---- E 豁免现算
    miss_key, stale, bad_v, blocking = [], [], [], []
    for r in mism_rows:
        k = (r[1], r[2])
        cur = tier.get(k)
        if cur is None:
            miss_key.append(k)
            continue
        if r[0] != cur['tier'] or r[7] != cur['rewritten']:
            stale.append('%s: %s 记录 tier=%s/rewritten=%s，现算 %s/%s'
                         % (k[0].split('.')[-1], k[1], r[0], r[7],
                            cur['tier'], cur['rewritten']))
        v, _why = PC.verdict_of(cur)
        if r[8] != v:
            bad_v.append('%s: 记录 %s，现算 %s' % (k[1], r[8], v))
        if v == 'BLOCKING':
            blocking.append('%s %s: %s（%s，owner_rewritten=%s）'
                            % (k[0].split('.')[-1], k[1], cur['tier'], r[5],
                               cur['rewritten']))
    check('E mismatch 行都已分档', not miss_key,
          '%d 条不在 tier 台账里: %s' % (len(miss_key), miss_key[:2]))
    check('E mismatch 行的档位未过期', not stale, ' | '.join(stale[:3]))
    check('E verdict 与现算一致', not bad_v, ' | '.join(bad_v[:3]))
    check('E 无 BLOCKING 差异', not blocking,
          '%d 条必须相等的计数器实测不等: %s' % (len(blocking), ' | '.join(blocking[:3])))

    # ---- F 代表性组
    rep = REPO / 'docs' / 'perf_rep_counters.tsv'
    if rep.exists():
        missing = []
        for ln in rep.read_text().splitlines():
            if not ln.strip() or ln.startswith('#'):
                continue
            f = ln.split('\t')
            if len(f) >= 2 and (f[0], f[1]) not in tier:
                missing.append((f[0], f[1]))
        check('F 代表性组全部已分档', not missing,
              '%d 条没档: %s' % (len(missing), missing[:2]))

    if fails:
        print('check_perf_tier: ★%d 条判据未过★' % len(fails))
        return 1
    print('check_perf_tier: 全部判据 PASS（tier %d 行 / gap %d 行 / mismatch %d 行）'
          % (len(tier_rows), len(gap_rows), len(mism_rows)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
