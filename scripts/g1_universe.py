#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""g1_universe.py —— G1 主 universe 对账 + 台账归一化。

做三件事：
 1. **主 universe**：把上轮 306 目标逐个解析到 G1，得到本轮可比的主分母。
 2. **台账归一化**：append-only 台账压成每 target 唯一终态，按 MAIN / AUX 分栏。
 3. **守恒检查**：MAIN 各状态计数之和须等于主分母；AUX 之和须等于 AUX 目标数。

## 本轮修了什么（codex 0151 D58）

修之前这个脚本有四个硬伤，实测复现见 git log：

 1. ★同名优先★ `resolve()` 里 `if (G1/f'{name}.sv').exists(): return name,'same_name'`
    排在 manual / renumber 之前。firtool 的编号一平移，整族全部串位而毫无征兆。
    实测 SyncDataModuleTemplate__64entry 家族在 G1 里整体后移一位：

        G0 _1(30端口) _2(121) _3(106) _4(10)
        G1 _1(46)     _2(30)  _3(121) _4(106) _5(10)

    同名优先把 5 行全写成 `same_name`。**在正确映射下这 4 行两侧端口数逐位相同
    （30/121/106/10），任何"比端口总数"的闸都看不见**。
    → 改：身份解析统一走 scripts/g1_slotmap.py 的 Resolver，**槽位判据优先**，
      同名降到兜底。

 2. ★receipt 串位★ `status.get(t) or status.get(g1n)` —— **老名优先**。
    于是 `_4 → _5` 这一行拿的是 `_4` 的 receipt：G1 `_5` 没有实现、没有 UT、
    没有 receipt，却继承了一个 PASS。
    → 改：状态**只按 g1_name 取**。老名下的残留状态一律不继承，但会在
      `--report-dropped` 里逐条列出来，不静默丢弃。

 3. ★硬编码写主树★ `NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')`。
    任何 worktree 里跑这个脚本都会去改主树的 docs/。
    → 改：`--repo` 显式指定，默认取 $XSSV_HOME 或本脚本所在仓库。

 4. ★与 g1_configured_universe.py 各写各的★ 两个脚本对同一批 old→new 映射
    给出过互相矛盾的答案（FastArbiter_30/_31 双认领、NPC_31/_33 双认领）。
    → 改：两边 import 同一个 Resolver。

## 幂等

`--check` 重新生成一遍并与仓库里的文件逐字节比对，不一致即非零退出。
这是 D58「generator 重跑结果必须与冻结 TSV 字节一致」的机器闸。
"""
from __future__ import print_function

import argparse
import json
import os
import pathlib
import sys
from collections import Counter

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import g1_slotmap as SM                                            # noqa: E402

G0_DEFAULT = SM.G0_DEFAULT
G1_DEFAULT = SM.G1_DEFAULT
MANIFEST_DEFAULT = '/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json'
CANONICAL_DEFAULT = '/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt'

PASS_STATES = {'WORKING_PASS', 'WORKING_PASS_DEAD_REF', 'WORKING_MERGED_PASS',
               'REVALIDATED_PASS', 'REVALIDATED_PASS_DEAD_REF'}

UNI_HDR = [
    '# G1 主 universe 对账（scripts/g1_universe.py 生成；禁止手工编辑 ——',
    '#   手工改完下次重跑就没了，要改改生成器。`--check` 是这条的机器闸）。',
    '# 主分母 = 上轮 306 目标按**槽位判据**解析到 G1。',
    '# resolve 列 = 做决定的判据还有谁独立佐证：',
    '#   same_name   槽位判据的答案就是同名模块',
    '#   slot_map    槽位判据把它改判到了别的名字（仅有槽位判据支持）',
    '#   manual_map  槽位判据的答案与 docs/g1_manual_map.tsv 的人工结论一致',
    '#   renumbered  槽位判据的答案与「模块体字节全等」的纯重编号一致',
    '#   gone_in_g1  四条判据都不给答案（须人工定位，不得自动改判）',
    '# ★status 只按 g1_name 取★：老名下的残留状态不继承（见 --report-dropped）。',
    '# old_target\tg1_name\tresolve\tdelta_class\tstatus\tnote',
]

NORM_HDR = [
    '# 台账归一化（scripts/g1_universe.py 生成；每 target 唯一终态；',
    '#   bucket=MAIN 属主 universe / AUX 为本轮多覆盖的 G1 变体）',
    '# target\tbucket\tstatus\tnote',
]


def read_kv(path, key=0, val=2, sep='\t'):
    out = {}
    for ln in pathlib.Path(path).read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split(sep)
        if len(f) > max(key, val):
            out[f[key]] = f[val]
    return out


def load_status(repo, receipt_index, canonical_id):
    """target -> (status, note)。

    两个来源，**都只认 target 自己的名字**：
      fastlane_ledger.tsv   append-only 文本台账，同 target 取最后一行
      docs/receipt_index.tsv 由 evidence/**/receipt.json 机械派生的 receipt 索引
                            （REVALIDATED_* 只能从这里来，不接受手工写入）
    """
    status = {}
    lp = pathlib.Path(repo) / 'docs' / 'fastlane_ledger.tsv'
    for ln in lp.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split('\t')
        status[f[0]] = (f[1], f[2] if len(f) > 2 else '')

    n = 0
    ri = pathlib.Path(receipt_index)
    if ri.exists():
        for ln in ri.read_text().splitlines():
            if ln.startswith('#') or not ln.strip():
                continue
            c = ln.split('\t')
            if len(c) < 7:
                continue
            tgt, verdict, cid, commit, prov, _sha, path = c[:7]
            if prov != 'false' or cid != canonical_id:
                continue
            if verdict not in ('SUCCEEDED', 'PASS_DEAD_REF'):
                continue
            note = ('receipt %s @%s canonical=%s' % (path, commit[:12], cid[:16]))
            status[tgt] = ('REVALIDATED_' + verdict.replace('SUCCEEDED', 'PASS'), note)
            n += 1
    return status, n, ri.exists()


def build(args):
    repo = pathlib.Path(args.repo)
    g0 = SM.Baseline(args.g0, 'G0', include_v=not args.no_include_v)
    g1 = SM.Baseline(args.g1, 'G1', include_v=not args.no_include_v)
    res = SM.Resolver(g0, g1, args.g0, args.g1, SM.load_manual_map(repo))

    old_targets = [e['target'] for e in json.load(open(args.manifest))['entries']]
    delta = read_kv(repo / 'docs' / 'g0g1_delta.tsv', 0, 2)
    cid = pathlib.Path(args.canonical_id).read_text().strip()
    status, n_receipt, have_ri = load_status(repo, args.receipt_index, cid)

    rows, g1_of, dropped = [], {}, []
    for t in old_targets:
        g1n, label, crit = res.resolve(t)
        g1_of[t] = g1n
        # ★状态只按 g1_name 取★——老名下的状态是对**另一个模块**的结论。
        st, note = status.get(g1n, ('NOT_STARTED', '')) if g1n else ('NOT_STARTED', '')
        if g1n != t and t in status:
            dropped.append((t, g1n or '-', status[t][0]))
        bits = []
        if g1n and g1n != t:
            bits.append('槽位判据(%s)改判: 原名 %s；依据见 docs/g1_slot_map_evidence.tsv'
                        % (crit, t))
        bits.append(note if note else '无 receipt/无 fastlane 记录')
        rows.append((t, g1n or '-', label, delta.get(t, '?'), st, '；'.join(bits)))

    # ★MAIN = 被 old306 映射**覆盖到的 G1 模块**，不是 old306 的名字集合★
    # 改判之后，老名往往指向 G1 里的另一个模块（NewPipelineConnectPipe_27 的
    # 老名在 G1 里仍然存在，但它已经不是任何 old target 的映射目标了）。
    # 把老名算进 MAIN 会让这些模块以"主 universe 成员"的身份混进分母 —— 
    # check_universe_freeze C2 的 MAIN/AUX 判据正是按映射目标算的，两边必须一致。
    main_names = set(v for v in g1_of.values() if v)
    aux = sorted(set(status) - main_names)

    uni_txt = '\n'.join(UNI_HDR + ['\t'.join(r) for r in rows]) + '\n'
    norm_txt = '\n'.join(
        NORM_HDR + ['%s\t%s\t%s\t%s' % (t, 'AUX' if t in aux else 'MAIN',
                                        status[t][0], status[t][1][:120])
                    for t in sorted(status)]) + '\n'
    return dict(rows=rows, aux=aux, status=status, dropped=dropped,
                main_names=main_names,
                n_receipt=n_receipt, have_ri=have_ri,
                files={repo / 'docs' / 'g1_universe.tsv': uni_txt,
                       repo / 'docs' / 'ledger_normalized.tsv': norm_txt})


def emit(files, check):
    """写文件；`check` 模式下只比对，不写。返回不一致的文件列表。"""
    bad = []
    for p, txt in sorted(files.items()):
        if check:
            cur = p.read_text() if p.exists() else None
            if cur != txt:
                bad.append(p)
        else:
            p.write_text(txt)
    return bad


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or HERE.parent),
                    help='仓库根（默认 $XSSV_HOME 或本脚本所在仓库）。'
                         '★禁止硬编码主树★：多个 worktree 并行时写错树会互相覆盖。')
    ap.add_argument('--g0', default=G0_DEFAULT)
    ap.add_argument('--g1', default=G1_DEFAULT)
    ap.add_argument('--manifest', default=MANIFEST_DEFAULT)
    ap.add_argument('--canonical-id', default=CANONICAL_DEFAULT)
    ap.add_argument('--receipt-index', default=None,
                    help='默认 <repo>/docs/receipt_index.tsv')
    ap.add_argument('--no-include-v', action='store_true')
    ap.add_argument('--check', action='store_true',
                    help='不写文件，只校验仓库里的 TSV 与重新生成的结果逐字节一致'
                         '（D58 幂等闸）；不一致退出码 1')
    ap.add_argument('--report-dropped', action='store_true',
                    help='列出「老名下有状态、但因改判而未被继承」的 target')
    args = ap.parse_args(argv)
    if args.receipt_index is None:
        args.receipt_index = str(pathlib.Path(args.repo) / 'docs' / 'receipt_index.tsv')

    try:
        b = build(args)
    except (SM.InputError, IOError, OSError) as e:
        sys.stderr.write('INPUT/PARSE ERROR (fail-closed): %s\n' % e)
        return 2

    rows, aux, status = b['rows'], b['aux'], b['status']
    if not b['have_ri']:
        print('⚠ 没有 %s —— REVALIDATED_* 无从派生，本次输出会与带 receipt 的跑法不同。'
              % args.receipt_index)
        print('  （该文件在 .gitignore 里，clean clone 不可复现；见报告"可复现性缺口"）')
    print('由 receipt 机械派生 REVALIDATED_*: %d 个' % b['n_receipt'])

    cnt = Counter(r[2] for r in rows)
    main_cnt = Counter(r[4] for r in rows)
    aux_cnt = Counter(status[t][0] for t in aux)
    gone = [r[0] for r in rows if r[2] == 'gone_in_g1']
    print('主 universe（老 %d 解析到 G1）: %d 个  %s'
          % (len(rows), len(rows),
             ' / '.join('%s %d' % kv for kv in sorted(cnt.items()))))
    print('MAIN 状态分布:', dict(main_cnt.most_common()))
    print('AUX（本轮多覆盖的 G1 变体）:', len(aux), dict(aux_cnt.most_common()))
    mp = sum(v for k, v in main_cnt.items() if k in PASS_STATES)
    ap_ = sum(v for k, v in aux_cnt.items() if k in PASS_STATES)
    print('通过: MAIN %d/%d = %.1f%%   AUX %d/%d'
          % (mp, len(rows), 100.0 * mp / len(rows), ap_, len(aux)))
    if gone:
        print('G1 已消失（需人工定位去向，不得自动改判）:', ' '.join(gone))
    if b['dropped']:
        print('★改判后未继承老名状态的 target: %d 个（老名下的结论是对**另一个模块**的）'
              % len(b['dropped']))
        if args.report_dropped:
            for t, g, s in b['dropped']:
                print('    %s → %s  老名状态 %s 已丢弃' % (t, g, s))
        else:
            print('    （--report-dropped 逐条列出）')

    ok = (sum(main_cnt.values()) == len(rows)
          and sum(aux_cnt.values()) == len(aux))
    # 守恒的口径必须与 MAIN/AUX 的口径一致：MAIN = 映射目标集合。
    # 老名不算 —— 改判后老名指向的是 G1 里的另一个模块，它本来就该落 AUX。
    overlap = set(aux) & b['main_names']
    if overlap:
        print('★守恒失败：同时落入两栏:', ' '.join(sorted(overlap)[:5]))
        ok = False
    print('守恒检查:', 'PASS' if ok else 'FAIL')

    bad = emit(b['files'], args.check)
    if args.check:
        if bad:
            print('★幂等 FAIL★ 重新生成的结果与仓库里的文件不一致:')
            for p in bad:
                print('    -', p)
            return 1
        print('幂等 PASS: %d 个文件与重新生成的结果逐字节一致' % len(b['files']))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
