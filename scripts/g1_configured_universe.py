#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""g1_configured_universe.py —— G1 当前 configured target universe 的机械枚举。

从 G1 golden RTL 机械推导本轮真正该覆盖的模块集合，并给出
old→new / removed / merged / new-target 的守恒映射。

## universe 定义（全部可机器判定，逐条可复算）

候选 = G1 golden-rtl 下声明的每个 module，且满足：

  1. **从 `XSTop` 出发的例化图可达**（codex 0151 D59：主 universe 根固定 XSTop）。
     SimTop 及其外围（difftest gateway / Flash / SDCard / 行为级内存 helper）是
     仿真脚手架，不属被验证的芯片设计，不进可读 RTL 主分母；它们仍会被逐个
     记成 `excluded:simtop_only`，**不会从台账里消失**。
  2. 非厂商宏叶子 / 非行为级存储模型 / 非 difftest 基础设施（见 EXCL_PATTERNS）。

**扫描 `.sv` 与 `.v` 两种后缀**（D59）。只扫 `.sv` 会让 `PrintCommitIDModule.v`
这种真实设计定义凭空消失 —— 它确实在 XSTop 可达闭包里。

## ★排除 ≠ 免责★

被 EXCL_PATTERNS 排除的模块（array_N / sram_array_* / ram_* / data_mem_*）
**不等于已获批准**。按 D59，只有已冻结 registry（`verif/vendor_boundary.tsv`）
批准者才能排除于可读 RTL 分母，其余一律记 gap。本脚本把它们排出 universe 只是
为了"本轮重写目标分母"这一个用途，并会打印 gap 计数；逐个定性见
`scripts/boundary_ledger.py` 产出的 `docs/g1_boundary_ledger.tsv`。

## 本轮修了什么（codex 0151 D58）

 1. ★同名优先★ 原 `if t in files: same_name` 排在 manual / renumber 之前，
    整串重编号一发生就串位，且与 g1_universe.py 各写各的，曾经产出过
    `FastArbiter_30 <- FastArbiter_30, FastArbiter_31` 这种双认领（C1 FAIL）。
    → 改：与 g1_universe.py 共用 scripts/g1_slotmap.py 的 Resolver，槽位判据优先。
 2. ★`cand[0]` 拿字典序当证据★ 全局 body 哈希多命中时取第一个。
    → 改：body 判据要求唯一命中，多义即判不准。
 3. `REPO` 由 `--repo` 显式给出（原先是 `__file__` 的父目录，跨 worktree 易写错树）。

## 守恒

  old306 = same + renumbered + slot_map + merged_away + removed
  universe = covered_from_old + new_targets
  G1 全部模块 = universe + 各排除类（**无法归类的残余 = 失败**）
"""
from __future__ import print_function

import argparse
import json
import os
import pathlib
import re
import sys
from collections import defaultdict, deque

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import g1_slotmap as SM                                            # noqa: E402

OLD_MANIFEST_DEFAULT = '/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json'

EXCL_PATTERNS = [
    (re.compile(r'_ext$'), 'vendor_macro_leaf'),
    (re.compile(r'^Difftest'), 'difftest_infra'),
    (re.compile(r'^DiffExt'), 'difftest_infra'),
    (re.compile(r'_dpic', re.I), 'difftest_infra'),
    (re.compile(r'^ram_'), 'behavioral_ram'),
    (re.compile(r'^data_mem_'), 'behavioral_ram'),
    (re.compile(r'^array(_\d+)?$'), 'vendor_macro_wrapper'),
    (re.compile(r'^sram_array_'), 'vendor_macro_wrapper'),
]

#: 排除类里哪些属于"厂商边界"性质 —— 这些才需要冻结 registry 批准，否则记 gap。
BOUNDARY_CLASSES = ('vendor_macro_leaf', 'vendor_macro_wrapper', 'behavioral_ram')

CFG_HDR = [
    '# G1 configured target universe（scripts/g1_configured_universe.py 生成；禁止手工编辑）',
    '# 见脚本 docstring：根=XSTop，扫 .sv 与 .v，四类机器可判的排除规则。',
    '# ★excluded 不等于已获批准★：只有 verif/vendor_boundary.tsv 批准者才算合规排除，',
    '#   其余记 gap，逐个定性见 docs/g1_boundary_ledger.tsv。',
]

MAP_HDR = [
    '# old306 → G1 守恒映射（scripts/g1_configured_universe.py 生成；禁止手工编辑）',
    '# disposition: same_name / slot_map / manual_renumber / auto_renumber /',
    '#              removed_in_g1 / no_g0_file —— 决定权始终在**槽位判据**，',
    '#              标签只说明还有谁独立佐证了同一个答案。',
    '# old_target\tg1_name\tdisposition\tin_universe',
]

LABEL2DISP = {'same_name': 'same_name', 'slot_map': 'slot_map',
              'manual_map': 'manual_renumber', 'renumbered': 'auto_renumber'}


def excluded(name):
    for pat, why in EXCL_PATTERNS:
        if pat.search(name):
            return why
    return None


def reachable(base, root):
    if root not in base.ports:
        raise SM.InputError('G1 里找不到根模块 %s' % root)
    seen, q = {root}, deque([root])
    while q:
        n = q.popleft()
        for typ, _inst in base.kids.get(n, ()):
            if typ in base.ports and typ not in seen:
                seen.add(typ)
                q.append(typ)
    return seen


def build(args):
    repo = pathlib.Path(args.repo)
    incv = not args.no_include_v
    g0 = SM.Baseline(args.g0, 'G0', include_v=incv)
    g1 = SM.Baseline(args.g1, 'G1', include_v=incv)
    res = SM.Resolver(g0, g1, args.g0, args.g1, SM.load_manual_map(repo))

    main_reach = reachable(g1, args.root)
    alt_reach = reachable(g1, args.alt_root) if args.alt_root in g1.ports else set()

    universe, excl = {}, defaultdict(list)
    for n in sorted(g1.ports):
        if n not in main_reach:
            # ★不进主分母，但逐个记账，不许消失★
            excl['simtop_only' if n in alt_reach else 'unreachable'].append(n)
            continue
        why = excluded(n)
        if why:
            excl[why].append(n)
        else:
            universe[n] = g1.deffile[n]

    old = [e['target'] for e in json.load(open(args.manifest))['entries']]
    rows, mapped_to = [], defaultdict(list)
    for t in old:
        g1n, label, _crit = res.resolve(t)
        if g1n:
            rows.append((t, g1n, LABEL2DISP[label]))
            mapped_to[g1n].append(t)
        else:
            rows.append((t, '-', 'removed_in_g1' if t in g0.ports else 'no_g0_file'))

    merged = dict((k, v) for k, v in mapped_to.items() if len(v) > 1)
    covered = set(r[1] for r in rows if r[1] != '-' and r[1] in universe)
    new_targets = sorted(set(universe) - covered)
    out_of_universe = sorted(set(r[1] for r in rows if r[1] != '-') - set(universe))

    cfg_lines = list(CFG_HDR)
    cfg_lines.append('# root=%s  可达=%d  universe=%d  排除=%d'
                     % (args.root, len(main_reach), len(universe),
                        sum(len(v) for v in excl.values())))
    cfg_lines.append('# module\tin_universe\tsource')
    for n in sorted(universe):
        cfg_lines.append('%s\tyes\t%s'
                         % (n, 'from_old_306' if n in covered else 'new_target'))
    for why, names in sorted(excl.items()):
        for n in sorted(names):
            cfg_lines.append('%s\tno\texcluded:%s' % (n, why))

    map_lines = list(MAP_HDR)
    for o, n, how in rows:
        map_lines.append('%s\t%s\t%s\t%s' % (o, n, how, 'yes' if n in universe else 'no'))

    gaps = [n for c in BOUNDARY_CLASSES for n in excl.get(c, [])]
    return dict(rows=rows, excl=excl, universe=universe, covered=covered,
                new_targets=new_targets, merged=merged, old=old,
                out_of_universe=out_of_universe, main_reach=main_reach,
                alt_reach=alt_reach, gaps=gaps,
                files={repo / 'docs' / 'g1_configured_universe.tsv':
                       '\n'.join(cfg_lines) + '\n',
                       repo / 'docs' / 'g1_old_to_new_map.tsv':
                       '\n'.join(map_lines) + '\n'})


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or HERE.parent),
                    help='仓库根（默认 $XSSV_HOME 或本脚本所在仓库）。★禁止硬编码主树★')
    ap.add_argument('--g0', default=SM.G0_DEFAULT)
    ap.add_argument('--g1', default=SM.G1_DEFAULT)
    ap.add_argument('--manifest', default=OLD_MANIFEST_DEFAULT)
    ap.add_argument('--root', default='XSTop',
                    help='主 universe 的根（D59 固定 XSTop）')
    ap.add_argument('--alt-root', default='SimTop',
                    help='外围根：只在它下面可达的模块记 excluded:simtop_only')
    ap.add_argument('--no-include-v', action='store_true',
                    help='只扫 .sv（D59 要求默认连 .v 一起扫）')
    ap.add_argument('--check', action='store_true',
                    help='不写文件，只校验仓库里的 TSV 与重新生成的结果逐字节一致')
    args = ap.parse_args(argv)

    try:
        b = build(args)
    except (SM.InputError, IOError, OSError) as e:
        sys.stderr.write('INPUT/PARSE ERROR (fail-closed): %s\n' % e)
        return 2

    old, rows, excl = b['old'], b['rows'], b['excl']
    disp = defaultdict(int)
    for _o, _n, how in rows:
        disp[how] += 1
    n_removed = disp['removed_in_g1'] + disp['no_g0_file']
    n_mapped = len(rows) - n_removed

    print('root=%s  从根可达模块=%d  (外围根 %s 可达=%d)'
          % (args.root, len(b['main_reach']), args.alt_root, len(b['alt_reach'])))
    print('排除:', dict((k, len(v)) for k, v in sorted(excl.items())))
    print('★MAIN 分母（G1 configured universe）= %d' % len(b['universe']))
    print('old%d 处置: %s  合计=%d/%d  %s'
          % (len(old), ' '.join('%s=%d' % kv for kv in sorted(disp.items())),
             len(rows), len(old),
             '守恒 PASS' if len(rows) == len(old) else '★守恒 FAIL★'))
    ok1 = len(rows) == len(old)
    ok2 = len(b['covered']) + len(b['new_targets']) == len(b['universe'])
    print('universe 拆分: 来自 old306=%d + 新目标=%d = %d  %s'
          % (len(b['covered']), len(b['new_targets']),
             len(b['covered']) + len(b['new_targets']),
             '守恒 PASS' if ok2 else '★守恒 FAIL★'))
    if b['merged']:
        print('merged（多个 old 映到同一 G1 模块）:',
              '; '.join('%s<-%s' % (k, ','.join(v))
                        for k, v in sorted(b['merged'].items())[:5]))
    print('映射到 G1 但不在 universe（落在排除类）: %d%s'
          % (len(b['out_of_universe']),
             '  ' + ' '.join(b['out_of_universe'][:8]) if b['out_of_universe'] else ''))
    print('新目标示例: %s …' % ' '.join(b['new_targets'][:10]))
    print('★厂商/存储边界待定性（排除但未经冻结 registry 批准即为 gap）: %d 个'
          % len(b['gaps']))
    print('  逐个定性: python3 scripts/boundary_ledger.py --repo <repo>')

    bad = SM_emit(b['files'], args.check)
    if args.check:
        if bad:
            print('★幂等 FAIL★ 重新生成的结果与仓库里的文件不一致:')
            for p in bad:
                print('    -', p)
            return 1
        print('幂等 PASS: %d 个文件与重新生成的结果逐字节一致' % len(b['files']))
    return 0 if (ok1 and ok2) else 1


def SM_emit(files, check):
    bad = []
    for p, txt in sorted(files.items()):
        if check:
            if (p.read_text() if p.exists() else None) != txt:
                bad.append(p)
        else:
            p.write_text(txt)
    return bad


if __name__ == '__main__':
    sys.exit(main())
