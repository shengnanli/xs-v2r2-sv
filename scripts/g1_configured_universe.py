#!/usr/bin/env python3
"""g1_configured_universe.py —— G1 当前 configured target universe 的机械枚举（codex 0141 §48）。

不再拿"上轮 306"当分母（里面含 G1 已消失的目标）。本脚本从 G1 golden RTL 机械推导
本轮真正该覆盖的模块集合，并给出 old→new / removed / merged / new-target 的守恒映射。

**universe 定义（全部可机器判定，逐条可复算）**
  候选 = G1 golden-rtl 下每个 `<M>.sv` 里声明的 module M，且满足：
    1. 从 SimTop 出发的例化图可达（不可达 = 本 config 没用到，不计入分母）；
    2. 非厂商宏叶子：模块名不以 `_ext` 结尾、且其定义文件不是 `.v`
       （array_*_ext 等是签过字的 vendor 边界，两侧同源黑盒，不作为重写目标）；
    3. 非 difftest 基础设施（Difftest* / *_dpic* / gateway 桩）——那是验证脚手架，
       不属被验证设计；
    4. 非纯行为级存储模型（ram_<N>x<W> / data_mem_* / mem_*_ext）——golden 提供的
       存储行为模型，同样两侧同源。
  其余全部计入 MAIN 分母。

**守恒**：old306 = same + renumbered + merged_away + removed；
         universe = covered_from_old + new_targets；两式各自打印并校验。
"""
import hashlib
import json
import pathlib
import re
import sys
from collections import defaultdict, deque

G0 = pathlib.Path('/home/eda/xs-env/G0-canonical/golden-rtl')
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = pathlib.Path(__file__).resolve().parent.parent
OLD_MANIFEST = pathlib.Path('/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json')
SCALA = re.compile(rb'\.scala:\d+')
INST = re.compile(r'^\s{2,}([A-Za-z_]\w*)\s+[A-Za-z_]\w*\s*\(\s*$', re.MULTILINE)

EXCL_PATTERNS = [
    (re.compile(r'_ext$'), 'vendor_macro_leaf'),
    (re.compile(r'^Difftest'), 'difftest_infra'),
    (re.compile(r'_dpic', re.I), 'difftest_infra'),
    (re.compile(r'^ram_\d+x\d+$'), 'behavioral_ram'),
    (re.compile(r'^data_mem_'), 'behavioral_ram'),
    (re.compile(r'^array(_\d+)?$'), 'vendor_macro_wrapper'),
    (re.compile(r'^sram_array_'), 'vendor_macro_wrapper'),
]


def excluded(name):
    for pat, why in EXCL_PATTERNS:
        if pat.search(name):
            return why
    return None


def norm(p, self_name):
    return SCALA.sub(b'.scala:0', p.read_bytes()).replace(self_name.encode(), b'@S@')


def main():
    files = {p.stem: p for p in G1.glob('*.sv')}
    # 例化图
    children = defaultdict(set)
    for name, p in files.items():
        for m in INST.finditer(p.read_text(errors='replace')):
            c = m.group(1)
            if c in files and c != name:
                children[name].add(c)
    # 从 SimTop 可达
    root = 'SimTop' if 'SimTop' in files else ('XSTop' if 'XSTop' in files else None)
    if root is None:
        sys.exit('ERROR: G1 里找不到 SimTop/XSTop 根')
    seen, q = {root}, deque([root])
    while q:
        n = q.popleft()
        for c in children[n]:
            if c not in seen:
                seen.add(c)
                q.append(c)

    universe, excl = {}, defaultdict(list)
    for n in sorted(seen):
        why = excluded(n)
        if why:
            excl[why].append(n)
        else:
            universe[n] = files[n]

    # old 306 → G1 映射
    old = [e['target'] for e in json.load(OLD_MANIFEST.open())['entries']]
    manual = {}
    mp = REPO / 'docs' / 'g1_manual_map.tsv'
    if mp.exists():
        for ln in mp.read_text().splitlines():
            if not ln.startswith('#') and ln.strip():
                f = ln.split('\t')
                manual[f[0]] = f[1]

    rows = []
    same = renum = removed = 0
    g1_hash = {}
    for n, p in files.items():
        g1_hash.setdefault(hashlib.sha256(norm(p, n)).hexdigest(), []).append(n)

    mapped_to = defaultdict(list)
    for t in old:
        if t in files:
            rows.append((t, t, 'same_name')); same += 1; mapped_to[t].append(t)
        elif t in manual and manual[t] in files:
            rows.append((t, manual[t], 'manual_renumber')); renum += 1; mapped_to[manual[t]].append(t)
        elif (G0 / f'{t}.sv').exists():
            h = hashlib.sha256(norm(G0 / f'{t}.sv', t)).hexdigest()
            cand = [c for c in g1_hash.get(h, [])]
            if cand:
                rows.append((t, cand[0], 'auto_renumber')); renum += 1; mapped_to[cand[0]].append(t)
            else:
                rows.append((t, '-', 'removed_in_g1')); removed += 1
        else:
            rows.append((t, '-', 'no_g0_file')); removed += 1

    merged = {k: v for k, v in mapped_to.items() if len(v) > 1}
    covered = {r[1] for r in rows if r[1] != '-' and r[1] in universe}
    new_targets = sorted(set(universe) - covered)
    # 映射到 G1 但不在 universe（被排除类，如 vendor/difftest）
    out_of_universe = sorted({r[1] for r in rows if r[1] != '-'} - set(universe))

    up = REPO / 'docs' / 'g1_configured_universe.tsv'
    with up.open('w') as f:
        f.write('# G1 configured target universe（机械枚举；见脚本 docstring 的四条排除规则）\n')
        f.write(f'# root={root}  reachable={len(seen)}  universe={len(universe)}\n')
        f.write('# module\tin_universe\tsource\n')
        for n in sorted(universe):
            src = 'from_old_306' if n in covered else 'new_target'
            f.write(f'{n}\tyes\t{src}\n')
        for why, names in sorted(excl.items()):
            for n in sorted(names):
                f.write(f'{n}\tno\texcluded:{why}\n')

    mp2 = REPO / 'docs' / 'g1_old_to_new_map.tsv'
    with mp2.open('w') as f:
        f.write('# old306 → G1 守恒映射（same_name / manual_renumber / auto_renumber / '
                'removed_in_g1 / no_g0_file）\n')
        f.write('# old_target\tg1_name\tdisposition\tin_universe\n')
        for o, n, how in rows:
            f.write(f'{o}\t{n}\t{how}\t{"yes" if n in universe else "no"}\n')

    print(f'root={root}  从根可达模块={len(seen)}')
    print('排除:', {k: len(v) for k, v in sorted(excl.items())})
    print(f'★MAIN 分母（G1 configured universe）= {len(universe)}')
    print(f'old306 处置: same_name={same} renumber={renum} removed/no_g0={removed}'
          f'  合计={same + renum + removed}/{len(old)}'
          f'  {"守恒 PASS" if same + renum + removed == len(old) else "★守恒 FAIL★"}')
    print(f'universe 拆分: 来自 old306={len(covered)} + 新目标={len(new_targets)}'
          f' = {len(covered) + len(new_targets)}'
          f'  {"守恒 PASS" if len(covered) + len(new_targets) == len(universe) else "★守恒 FAIL★"}')
    if merged:
        print('merged（多个 old 映到同一 G1 模块）:',
              '; '.join(f'{k}<-{",".join(v)}' for k, v in list(merged.items())[:5]))
    print(f'映射到 G1 但不在 universe（落在排除类）: {len(out_of_universe)}'
          + ('  ' + ' '.join(out_of_universe[:8]) if out_of_universe else ''))
    print(f'新目标示例: {" ".join(new_targets[:10])} …')
    ok = (same + renum + removed == len(old)
          and len(covered) + len(new_targets) == len(universe))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
