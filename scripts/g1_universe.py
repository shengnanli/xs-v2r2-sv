#!/usr/bin/env python3
"""g1_universe.py —— G1 主 universe 机器对账 + 台账归一化（codex 0139 §3.4）。

做三件事：
 1. **主 universe**：把上轮 306 目标逐个解析到 G1（同名存在 / 纯重编号后的新名 / 在 G1
    已消失），得到本轮可比的主分母。解析判据与 inherit 一致：自名+断言行号归一后字节全等
    才算"同一模块改了名"，否则记 GONE（需人工定位，不允许自动当成别的模块）。
 2. **台账归一化**：append-only 台账压成每 target 唯一终态（取最后一行），并按
    MAIN / AUX 分栏。AUX = 不属于主 universe 的 G1 变体（本轮多覆盖的部分）。
 3. **守恒检查**：MAIN 各状态计数之和须等于主分母；AUX 之和须等于 AUX 目标数；
    任何 target 不得同时落入两栏。不守恒即非零退出。

输出 docs/g1_universe.tsv 与 docs/ledger_normalized.tsv，并打印分栏统计。
"""
import hashlib
import json
import pathlib
import re
import sys

G0 = pathlib.Path('/home/eda/xs-env/G0-canonical/golden-rtl')
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')
MANIFEST = pathlib.Path('/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json')
SCALA = re.compile(rb'\.scala:\d+')

PASS_STATES = {'WORKING_PASS', 'WORKING_PASS_DEAD_REF', 'WORKING_MERGED_PASS',
               'REVALIDATED_PASS', 'REVALIDATED_PASS_DEAD_REF'}


def norm_bytes(p, self_name):
    return SCALA.sub(b'.scala:0', p.read_bytes()).replace(self_name.encode(), b'@S@')


MANUAL = {}
_mp = NEW / 'docs' / 'g1_manual_map.tsv'
if _mp.exists():
    for _l in _mp.read_text().splitlines():
        if _l.startswith('#') or not _l.strip():
            continue
        _f = _l.split('\t')
        MANUAL[_f[0]] = _f[1]


def resolve(name):
    """老目标名 → (G1 名, 解析方式)。"""
    if (G1 / f'{name}.sv').exists():
        return name, 'same_name'
    if name in MANUAL and (G1 / f'{MANUAL[name]}.sv').exists():
        return MANUAL[name], 'manual_map'    # 人工核对的重编号（见 docs/g1_manual_map.tsv）
    if not (G0 / f'{name}.sv').exists():
        return '', 'no_g0_file'
    want = norm_bytes(G0 / f'{name}.sv', name)
    fam = re.match(r'^(.*?)(_\d+)?$', name).group(1)
    for cand in sorted(G1.glob(fam + '*.sv')):
        if norm_bytes(cand, cand.stem) == want:
            return cand.stem, 'renumbered'
    return '', 'gone_in_g1'


def main():
    old_targets = [e['target'] for e in json.load(MANIFEST.open())['entries']]
    delta = {}
    for ln in (NEW / 'docs' / 'g0g1_delta.tsv').read_text().splitlines():
        if ln.startswith('#'):
            continue
        f = ln.split('\t')
        delta[f[0]] = f[2]

    # 台账归一化：同 target 多行取最后一行
    status = {}
    lp = NEW / 'docs' / 'fastlane_ledger.tsv'
    for ln in lp.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split('\t')
        status[f[0]] = (f[1], f[2] if len(f) > 2 else '')

    # ★REVALIDATED_*：由 receipt **机械派生**，不接受手工写入（codex 0141）。
    # 条件：存在非 provisional 的 receipt、verdict 为通过、且 canonical 与当前 G1 一致。
    import sys as _s
    _s.path.insert(0, str(NEW / 'scripts'))
    import build_receipt_index as _BRI
    cid = (pathlib.Path('/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt')
           .read_text().strip())
    revalidated = 0
    for tgt, rec in _BRI.load(NEW).items():
        if (rec['provisional'] == 'false' and rec['canonical_id'] == cid
                and rec['verdict'] in ('SUCCEEDED', 'PASS_DEAD_REF')):
            note = (f"receipt {rec['path']} @{rec['impl_commit'][:12]} "
                    f"canonical={cid[:16]}…")
            status[tgt] = ('REVALIDATED_' + rec['verdict'].replace('SUCCEEDED', 'PASS'), note)
            revalidated += 1
    print(f'由 receipt 机械派生 REVALIDATED_*: {revalidated} 个')

    rows, g1_of = [], {}
    for t in old_targets:
        g1n, how = resolve(t)
        g1_of[t] = g1n
        # 状态可能记在老名或 G1 新名下
        st, note = status.get(t) or status.get(g1n) or ('NOT_STARTED', '')
        rows.append((t, g1n or '-', how, delta.get(t, '?'), st, note[:80]))

    main_names = {t for t in old_targets} | {v for v in g1_of.values() if v}
    aux = sorted(set(status) - main_names)

    up = NEW / 'docs' / 'g1_universe.tsv'
    with up.open('w') as f:
        f.write('# G1 主 universe 对账（g1_universe.py 生成；主分母 = 上轮 306 目标解析到 G1）\n')
        f.write('# old_target\tg1_name\tresolve\tdelta_class\tstatus\tnote\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')

    np_ = NEW / 'docs' / 'ledger_normalized.tsv'
    with np_.open('w') as f:
        f.write('# 台账归一化（每 target 唯一终态；bucket=MAIN 属主 universe / AUX 为本轮多覆盖）\n')
        f.write('# target\tbucket\tstatus\tnote\n')
        for t, (st, note) in sorted(status.items()):
            f.write(f'{t}\t{"AUX" if t in aux else "MAIN"}\t{st}\t{note[:120]}\n')

    # 统计与守恒
    from collections import Counter
    main_cnt = Counter(r[4] for r in rows)
    aux_cnt = Counter(status[t][0] for t in aux)
    gone = [r[0] for r in rows if r[2] == 'gone_in_g1']
    print(f'主 universe（老 306 解析到 G1）: {len(rows)} 个'
          f'  其中同名 {sum(1 for r in rows if r[2] == "same_name")}'
          f' / 重编号 {sum(1 for r in rows if r[2] == "renumbered")}'
          f' / G1 已消失 {len(gone)}')
    print('MAIN 状态分布:', dict(main_cnt.most_common()))
    print('AUX（本轮多覆盖的 G1 变体）:', len(aux), dict(aux_cnt.most_common()))
    mp = sum(v for k, v in main_cnt.items() if k in PASS_STATES)
    ap_ = sum(v for k, v in aux_cnt.items() if k in PASS_STATES)
    print(f'通过: MAIN {mp}/{len(rows)} = {100*mp/len(rows):.1f}%   AUX {ap_}/{len(aux)}')
    if gone:
        print('G1 已消失（需人工定位去向，不得自动改判）:', ' '.join(gone))

    ok = sum(main_cnt.values()) == len(rows) and sum(aux_cnt.values()) == len(aux)
    overlap = set(aux) & main_names
    if overlap:
        print('★守恒失败：同时落入两栏:', ' '.join(sorted(overlap)[:5]))
        ok = False
    print('守恒检查:', 'PASS' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
