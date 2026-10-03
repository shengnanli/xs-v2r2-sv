#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""perf_compare.py —— golden 与 impl 两侧的 perf 计数器逐条对比 + 分档裁定。

## 为什么不能直接 diff 两份日志

impl 侧有一部分 perf 观测**没能重绑**。那些 bore 在生成的 SimTop 里接的是 `'0`
—— 于是对应计数器会**打印出一个 0**。0 是一个合法的数字，肉眼和 `diff` 都分不出
「真的没发生过」和「根本没接上」。本脚本的第一层意义就是把这两件事分开：

  MATCH     两侧数值相同，且该计数器的每一条 bore 都绑上了 → 这是真的对上了
  MISMATCH  两侧数值不同（且全绑上了）→ 这是真差异，按档裁定（见下）
  EXCLUDED  该计数器落在 docs/perf_gap_ledger.tsv → **不判对错**。★不许拿 0==0 算 MATCH★
  MISSING   某一侧没打印这条 → 两侧 dump 触发时刻/配置不一致，先修环境

## 第二层：codex 0162 D3 的分档裁定

光说「24 条不等」没有回答 codex 的问题。判断一条差异挡不挡里程碑，要两个事实：

  1. **它属于哪一档**（`docs/perf_tier_ledger.tsv`，判据见 `scripts/perf_tier.py`）:
     A_FUNC_ASSERT / B_CONTROL 必须相等；C_DIAG 显式归类后允许不同。
  2. **持有它的 golden 模块本轮重写了没有**（同一张台账的 owner_rewritten 列）。
     codex 原话：内部诊断计数器 "do not block the current rewritten slice when the
     owning modules are unchanged"。

两条都满足才算豁免，写成一条：

    WAIVED  ⟺ tier == C_DIAG 且 owner_rewritten == no
    否则    BLOCKING

★这条比 codex D3 的最后一句**更严**，是故意的，要说清楚★
D3 最后一句是：「Once Predictor itself is rewritten, its functional predictions and
cycle behavior must match; identity of an internal provider table need not match
unless it affects a control/performance-contract output.」——按字面，C_DIAG 的
provider identity 在模块重写之后**仍可**不同。这里没有照搬，理由是本工程的上位目标
是与 golden **bug-for-bug** 一致（"良性差异文档化"这条路线已经被否决过一次）。
所以持有模块一旦被重写，豁免到期、翻红，逼一次人工复核。

翻红之后的正确处置**不是**放宽这里的判据，而是：
  1. 拿出"该差异不影响任何 control / perf-contract 输出"的**正面证据**
     （例如同族的 B_CONTROL 档计数器全等、mispredict 类计数器全等）；
  2. 带着那份证据改 verdict_of 并同步改 scripts/test_perf_tier_gate.py 的负测。
一次有记录的判据变更，好过一个能让任何人随手绕过的开关。

★豁免是**逐条**记账的，不是一句"都是微架构差异"★ —— 落在
`docs/perf_mismatch_ledger.tsv`，由 `scripts/check_perf_tier.py` 每次跑闸时复核。

退出码：有 BLOCKING 的 MISMATCH 或 MISSING 就非 0；WAIVED 与 EXCLUDED 不影响退出码
（但都会打印出来，且 EXCLUDED 的条数由 gap 台账钉住）。`--strict` 则任何 MISMATCH
都非 0（Predictor 这类模块重写完之后用它复查）。

## 第三层：初值设定闸（codex 0207 P1，Z0 口径）—— 比数之前先比"怎么跑的"

firtool 的 RANDOMIZE_*_INIT 用无种子 `$random`：全设计共用一条随机流，换掉任何一个
带 $random initial 的 golden 模块，后面所有 golden 寄存器的初值都会平移（与
+ntb_random_seed 无关）。原口径下的 tage provider 等差异就是这么来的
（docs/lanes/tage-initmem.md），是 simulation-only 伪差，不改 RTL。

所以主比较要求两侧都是 **Z0**：编译期无 RANDOMIZE_*、编译期 +vcs+initreg+random、
运行期 +vcs+initreg+0。凭据是 assert.log 里的 `[PERFCFG]` 行 —— 由
verif/sim/perf_cfg_stamp.sv 在仿真里**现场测得**（`ifdef 现查宏、无初值探针 reg/阵列
的实际值、plusarg 回显），与 [PERF ] 行同在一个被 sha256 钉住的文件里，不靠人填。
init_contract() 逐项判，任一缺失 / 不合 Z0 / 两侧 workload·seed·max_cycles 不一致
→ 不做比较，退出码 3。没有绕过开关。构建/运行用 verif/sim/run_perf_z0.sh。

用法:
  scripts/perf_compare.py golden/assert.log impl/assert.log          # 代表性组
  scripts/perf_compare.py golden/assert.log impl/assert.log --all    # 全量
  scripts/perf_compare.py ... --show 40                              # 多列几条差异
  scripts/perf_compare.py ... --all --emit-mismatch docs/perf_mismatch_ledger.tsv
"""
from __future__ import print_function

import argparse
import collections
import hashlib
import pathlib
import re
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
UNBOUND = REPO / 'docs' / 'perf_bore_unbound.tsv'
REP = REPO / 'docs' / 'perf_rep_counters.tsv'
TIER = REPO / 'docs' / 'perf_tier_ledger.tsv'
GAP = REPO / 'docs' / 'perf_gap_ledger.tsv'

LINE = re.compile(r'^\[PERF \]\[time=\s*(\d+)\]\s+([^:]+):\s+([^,]+),\s+(\d+)\s*$')

MISMATCH_COLS = ['tier', 'scope', 'name', 'golden', 'impl', 'delta',
                 'owner_modules', 'owner_rewritten', 'verdict', 'criterion']


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


CFG_LINE = re.compile(r'^\[PERFCFG\]\s+(.*)$')
CFG_KEYS = ('randomize_defines', 'initreg_plusarg', 'initreg_probe_reg', 'initreg_probe_mem',
            'workload', 'seed', 'max_cycles')
# 两侧必须逐字相同的运行条件（Z0 四项另外逐侧判）
CFG_SAME = ('randomize_defines', 'initreg_plusarg', 'workload', 'seed', 'max_cycles')


def load_cfg(path):
    """assert.log 里的 [PERFCFG] 行 → (dict 或 None, 原始行, 问题列表)。"""
    found = [CFG_LINE.match(ln.rstrip()) for ln in
             pathlib.Path(path).read_text(errors='replace').splitlines()
             if ln.startswith('[PERFCFG]')]
    if not found:
        return None, '', ['缺 [PERFCFG] 行（不是 verif/sim/run_perf_z0.sh 的构建？）']
    if len(found) != 1 or not found[0]:
        return None, '', ['[PERFCFG] 行有 %d 条（应恰好 1 条）' % len(found)]
    raw = found[0].group(1).strip()
    d = parse_cfg(raw)
    return d, raw, cfg_problems(d)


def parse_cfg(raw):
    d = {}
    for tok in raw.split():
        k, eq, v = tok.partition('=')
        if eq:
            d[k] = v
    return d


def cfg_problems(d):
    """单侧 Z0 判据。纯函数，check_perf_tier.py 判据 D 也用它复核台账头。"""
    p = []
    for k in CFG_KEYS:
        if k not in d or d[k] == '':
            p.append('缺字段 %s' % k)
    if p:
        return p
    if d['randomize_defines'] != 'none':
        p.append('编译期定义了 RANDOMIZE_*: %s' % d['randomize_defines'])
    if d['initreg_plusarg'] != '0':
        p.append('运行期 +vcs+initreg+%s（应为 +vcs+initreg+0）' % d['initreg_plusarg'])
    for k in ('initreg_probe_reg', 'initreg_probe_mem'):
        v = d[k].lower()
        if 'x' in v or 'z' in v:
            p.append('%s=%s：编译期没开 +vcs+initreg+random' % (k, d[k]))
        elif set(v) != {'0'}:
            p.append('%s=%s：上电初值不是 0' % (k, d[k]))
    if d['workload'] == 'absent':
        p.append('没有 +workload')
    if d['max_cycles'] in ('-1', ''):
        p.append('没有 +max-cycles')
    return p


def init_contract(gd, idd):
    """两侧设定闸 → 问题列表（空 = 通过）。gd/idd 是 load_cfg 的 dict（可为 None）。"""
    if gd is None or idd is None:
        return ['至少一侧没有可用的 [PERFCFG]']
    p = ['golden: ' + x for x in cfg_problems(gd)] + ['impl: ' + x for x in cfg_problems(idd)]
    for k in CFG_SAME:
        if gd.get(k) != idd.get(k):
            p.append('两侧 %s 不一致: golden=%s impl=%s' % (k, gd.get(k), idd.get(k)))
    return p


def load_tier():
    """docs/perf_tier_ledger.tsv -> {(scope,name): row}，只取 PERF 行。"""
    out = {}
    if not TIER.exists():
        return out
    for ln in TIER.read_text(errors='replace').splitlines():
        if not ln or ln.startswith('#') or ln.startswith('kind\t'):
            continue
        f = ln.split('\t')
        if f[0] != 'PERF':
            continue
        out[(f[1], f[2])] = dict(tier=f[3], status=f[4], owners=f[8], rewritten=f[9],
                                 criterion=f[10])
    return out


def load_unbound():
    """docs/perf_bore_unbound.tsv 的 PERF 行 —— perf_rebind 的口径（按同族整片排除）。

    保留它有两个理由：(1) `scripts/test_perf_rebind_gate.py` 钉的就是这张表的用法
    「未绑计数器两侧都是 0 也不算 MATCH」；(2) 分档台账不在时的退路。
    日常比对以 docs/perf_gap_ledger.tsv 为准（它是这张表的**真子集**，见 perf_tier.py）。
    """
    out = set()
    for ln in UNBOUND.read_text().splitlines():
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.split('\t')
        if len(f) >= 3 and f[0] == 'PERF':
            out.add((f[1], f[2]))
    return out


def load_gap():
    """docs/perf_gap_ledger.tsv -> {(scope,name)}；台账不在时退回旧的 unbound 表。"""
    if not GAP.exists():
        return load_unbound()
    out = set()
    for ln in GAP.read_text(errors='replace').splitlines():
        if not ln or ln.startswith('#') or ln.startswith('tier\t'):
            continue
        f = ln.split('\t')
        if f[0] != 'A_FUNC_ASSERT':
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


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def verdict_of(row):
    """codex 0162 D3 的豁免判据 —— 两个条件，缺一不可。"""
    if row is None:
        return 'BLOCKING', '该计数器不在 docs/perf_tier_ledger.tsv 里（未分档）'
    if row['tier'] == 'C_DIAG' and row['rewritten'] == 'no':
        return 'WAIVED', 'C_DIAG 且持有模块本轮未重写（codex 0162 D3）'
    if row['tier'] == 'C_DIAG':
        return 'BLOCKING', 'C_DIAG，但持有模块已重写(%s) —— 豁免不再成立' % row['rewritten']
    return 'BLOCKING', '%s 档必须相等' % row['tier']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('golden')
    ap.add_argument('impl')
    ap.add_argument('--all', action='store_true', help='比全部计数器（默认只比代表性组）')
    ap.add_argument('--show', type=int, default=20)
    ap.add_argument('--strict', action='store_true',
                    help='任何 MISMATCH 都算失败（不应用 D3 豁免）')
    ap.add_argument('--emit-mismatch', metavar='PATH',
                    help='把逐条 MISMATCH 裁定写成台账（要 --all）')
    a = ap.parse_args()

    gcfg, graw, gprob = load_cfg(a.golden)
    icfg, iraw, iprob = load_cfg(a.impl)
    probs = (['golden: ' + x for x in gprob] + ['impl: ' + x for x in iprob]
             if (gprob or iprob) else init_contract(gcfg, icfg))
    print('golden cfg : %s' % (graw or '（无）'))
    print('impl   cfg : %s' % (iraw or '（无）'))
    if probs:
        print('★初值设定闸（codex 0207 P1，Z0）未过 —— 不做比较：')
        for x in probs:
            print('  - ' + x)
        return 3
    print('初值设定闸: 两侧 Z0 且运行条件一致 ok')

    g, gt = load_dump(a.golden)
    i, it = load_dump(a.impl)
    gap = load_gap()
    tier = load_tier()
    print('golden dump: %d 个计数器，dump 时刻 %s' % (len(g), sorted(gt)[:4]))
    print('impl   dump: %d 个计数器，dump 时刻 %s' % (len(i), sorted(it)[:4]))
    same_time = sorted(gt) == sorted(it)
    if not same_time:
        print('★ 两侧 dump 时刻不同 —— 比对结果不可信，先把 +max-cycles/+e 对齐')
        print('  （D_INVARIANT 档「同 dump 时刻下恒等」的前提也随之失效）')

    keys = sorted(set(g) | set(i)) if a.all else load_rep()
    st = collections.Counter()
    tierst = collections.Counter()
    mism, miss = [], []
    for k in keys:
        row = tier.get(k)
        if row:
            tierst[row['tier']] += 1
        if k in gap:
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
            mism.append((k, g[k], i[k], row))

    print()
    print('比对范围: %s（%d 个）' % ('全量' if a.all else 'docs/perf_rep_counters.tsv 代表性组',
                                    len(keys)))
    for kk in ('MATCH', 'MISMATCH', 'EXCLUDED', 'MISSING'):
        print('  %-9s %6d' % (kk, st.get(kk, 0)))
    rc = 0
    if tier:
        print('  ---- 分档（docs/perf_tier_ledger.tsv）')
        for t in ('A_FUNC_ASSERT', 'B_CONTROL', 'C_DIAG', 'D_CONST', 'D_INVARIANT',
                  'X_UNRESOLVED'):
            if tierst.get(t):
                print('  %-14s %6d' % (t, tierst[t]))
        # ★"未分档"不许悄悄存在★：dump 里出现了分档台账没有的计数器，说明台账过期
        # （golden 换版 / perf_tier 没重跑）。这时候所有 MATCH 都失去了口径，必须红。
        unk = [k for k in keys if k not in tier]
        if unk:
            print('  ★%d 个计数器不在分档台账里 —— 先跑 scripts/perf_tier.py（例：%s: %s）'
                  % (len(unk), unk[0][0], unk[0][1]))
            rc = 1

    if mism:
        rows = []
        for (sc, nm), gv, iv, row in mism:
            v, why = verdict_of(row)
            if a.strict:
                v, why = 'BLOCKING', '--strict：不应用 D3 豁免'
            rows.append([row['tier'] if row else 'X_UNRESOLVED', sc, nm, str(gv), str(iv),
                         '%+d' % (iv - gv),
                         row['owners'] if row else '', row['rewritten'] if row else '',
                         v, why])
        nblk = sum(1 for r in rows if r[8] == 'BLOCKING')
        print()
        print('--- MISMATCH 裁定（codex 0162 D3）: WAIVED %d / BLOCKING %d ---'
              % (len(rows) - nblk, nblk))
        for r in sorted(rows, key=lambda r: (r[8] != 'BLOCKING', r[1], r[2]))[:a.show]:
            print('  [%-8s] %-13s %-52s golden=%-12s impl=%-12s owner=%s(%s)'
                  % (r[8], r[0], (r[1].split('.core.')[-1] + ': ' + r[2])[:52],
                     r[3], r[4], r[6][:28], r[7]))
        if nblk:
            rc = 1
    if not mism:
        rows, nblk = [], 0
    if a.emit_mismatch:
        if not a.all:
            print('★ --emit-mismatch 需要 --all（台账必须是全量口径）')
            return 2
        head = subprocess.check_output(['git', 'rev-parse', 'HEAD'],
                                       cwd=str(REPO)).decode().strip()
        hdr = [
            '# perf_mismatch_ledger.tsv —— 全量 perf 比对里**每一条**不等的逐条裁定。',
            '#（scripts/perf_compare.py --emit-mismatch 生成；禁止手改）',
            '# 这是一份**测量记录**，不是可以从 golden 现场重算的东西 —— 所以',
            '#   复跑命令、输入路径、输入 sha256、台账 sha256、commit 全部钉在下面（D62）。',
            '# 裁定判据（scripts/perf_compare.py verdict_of）：',
            '#   WAIVED   ⟺ tier == C_DIAG 且 owner_rewritten == no  (codex 0162 D3)',
            '#   BLOCKING 其余全部。★一旦持有模块被重写，豁免自动失效，闸会红★',
            '# 下面两个台账 sha256 是**出表当时**的版本号，不是闸的判据 ——',
            '#   台账会随 golden/rtl 变，靠比 hash 会在干净 checkout 里死锁（重发这张表',
            '#   要有那两份 assert.log）。currency 由 scripts/check_perf_tier.py 判据 E',
            '#   保证：它每次跑闸都拿**当前**台账重算 tier/owner_rewritten/verdict，',
            '#   与这里记的对不上就红。',
            '# 初值口径 Z0（codex 0207 P1）：两侧无 RANDOMIZE_*、编译期 +vcs+initreg+random、运行期',
            '#   +vcs+initreg+0，凭两份 assert.log 的 [PERFCFG] 行（下面 golden_cfg/impl_cfg 原样抄录）。',
            '#   原模式（RANDOMIZE_*）下的 tage provider 等差异来自 simulation-only 的无种子 $random',
            '#   初值流随模块替换平移，不据此改 RTL（docs/lanes/tage-initmem.md）。',
            '#',
            '# commit            %s' % head,
            '# golden_log        %s' % a.golden,
            '# golden_log_sha256 %s' % sha256(a.golden),
            '# impl_log          %s' % a.impl,
            '# impl_log_sha256   %s' % sha256(a.impl),
            '# tier_ledger_sha256 %s' % sha256(str(TIER)),
            '# gap_ledger_sha256  %s' % sha256(str(GAP)),
            '# dump_times_equal  %s' % same_time,
            '# init_contract     Z0',
            '# golden_cfg        %s' % graw,
            '# impl_cfg          %s' % iraw,
            '# compared          %d' % len(keys),
            '# MATCH %d / MISMATCH %d / EXCLUDED %d / MISSING %d'
            % (st.get('MATCH', 0), st.get('MISMATCH', 0), st.get('EXCLUDED', 0),
               st.get('MISSING', 0)),
            '# WAIVED %d / BLOCKING %d' % (len(rows) - nblk, nblk),
            '# 复跑:',
            '#   python3 scripts/perf_compare.py \\',
            '#     %s \\' % a.golden,
            '#     %s --all --emit-mismatch docs/perf_mismatch_ledger.tsv' % a.impl,
            '#',
            '\t'.join(MISMATCH_COLS),
        ]
        out = '\n'.join(hdr + ['\t'.join(r) for r in
                               sorted(rows, key=lambda r: (r[1], r[2]))]) + '\n'
        pathlib.Path(a.emit_mismatch).write_text(out)
        print('  已写 %s（%d 条）sha256 %s'
              % (a.emit_mismatch, len(rows),
                 hashlib.sha256(out.encode()).hexdigest()))
    if miss:
        rc = 1
        print('\n--- MISSING（前 %d 条）---' % min(a.show, len(miss)))
        for sc, nm in miss[:a.show]:
            print('  %s: %s  (golden=%s impl=%s)'
                  % (sc, nm, (sc, nm) in g, (sc, nm) in i))
    if st.get('EXCLUDED'):
        print()
        print('★ EXCLUDED %d 条不是"相等"也不是"不等"，是"没测"。'
              '逐条理由与解除条件见 docs/perf_gap_ledger.tsv。' % st['EXCLUDED'])
        print('  ——所以本次结果**不得**被表述为「perf 观测全等价」。')
    return rc


if __name__ == '__main__':
    sys.exit(main())
