#!/usr/bin/env python3
"""g0g1_delta.py —— G0(v2r2 基线) ↔ G1(kunminghu-v2 @b36a1a2a5) golden 逐模块 delta。

对上轮 306 签核目标分类，回答"哪些重写可直接继承、哪些要对照新 golden 重做"：
  own  = SAME / DIFF / MISSING       目标自身 golden 文件是否逐字一致
  闭包 = CLEAN / DEPS_CHANGED / N.A. 该目标在 G1 例化闭包内是否有任何文件变化
最终类：
  INHERIT       own=SAME 且闭包 CLEAN —— 上轮重写+证明结构可整体继承（快车道）
  GLUE_INHERIT  own=SAME 但闭包有变 —— 本体可继承，但其子树有变化目标需先处理；
                （上轮 assembly 模式黑盒子模块的目标，本体证明仍可平移）
  REWRITE       own=DIFF —— 对照 G1 真重写
  RESTRUCTURED  own=MISSING —— G1 里该模块名消失（改名/单态化重排），需人工定位
"""
import json
import pathlib
import re
import sys
from collections import defaultdict

G0 = pathlib.Path('/home/eda/xs-env/G0-canonical/golden-rtl')
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
MANIFEST = pathlib.Path('/home/eda/xs-env/xs-signoff/scripts/sidecar/manifest_305.json')
OUT_TSV = pathlib.Path('/home/eda/xs-env/xs-v2-sv/docs/g0g1_delta.tsv')

INST_RE = re.compile(r'^\s+([A-Za-z_]\w*)\s+[A-Za-z_]\w*\s+\($')


def main():
    targets = [e['target'] for e in json.load(MANIFEST.open())['entries']]

    g0_files = {p.name: p for p in G0.glob('*.sv')}
    g1_files = {p.name: p for p in G1.glob('*.sv')}

    # 1) 逐文件字节比对
    status = {}  # name -> SAME/DIFF/ONLY_G0/ONLY_G1
    for name in set(g0_files) | set(g1_files):
        if name not in g0_files:
            status[name] = 'ONLY_G1'
        elif name not in g1_files:
            status[name] = 'ONLY_G0'
        else:
            status[name] = ('SAME' if g0_files[name].read_bytes() == g1_files[name].read_bytes()
                            else 'DIFF')

    n_same = sum(1 for v in status.values() if v == 'SAME')
    n_diff = sum(1 for v in status.values() if v == 'DIFF')
    n_g0 = sum(1 for v in status.values() if v == 'ONLY_G0')
    n_g1 = sum(1 for v in status.values() if v == 'ONLY_G1')
    print(f'文件级: SAME={n_same} DIFF={n_diff} ONLY_G0={n_g0} ONLY_G1={n_g1}')

    # 2) G1 例化图（模块名 = 文件名去 .sv；firtool 一模块一文件）
    modnames = {n[:-3] for n in g1_files}
    children = defaultdict(set)
    for name, p in g1_files.items():
        mod = name[:-3]
        for line in p.read_text(errors='replace').splitlines():
            m = INST_RE.match(line)
            if m and m.group(1) in modnames and m.group(1) != mod:
                children[mod].add(m.group(1))

    # 3) 传递闭包: 模块子树内是否有 DIFF/ONLY_G1 文件
    memo = {}

    def closure_dirty(mod, stack=()):
        if mod in memo:
            return memo[mod]
        if mod in stack:
            return set()
        st = status.get(mod + '.sv', 'ONLY_G1')
        dirty = {mod} if st in ('DIFF', 'ONLY_G1') else set()
        for c in children.get(mod, ()):
            dirty |= closure_dirty(c, stack + (mod,))
        memo[mod] = dirty
        return dirty

    # 4) DIFF 目标细分: 归一化断言源码行号后重比 + diff 规模分档
    scala_ln = re.compile(rb'\.scala:\d+')

    def norm(p):
        return scala_ln.sub(b'.scala:0', p.read_bytes())

    def diff_lines(a, b):
        import subprocess
        p = subprocess.run(['diff', str(a), str(b)], stdout=subprocess.PIPE,
                           stderr=subprocess.DEVNULL, universal_newlines=True)
        return sum(1 for ln in p.stdout.splitlines() if ln[:1] in '<>')

    rows = []
    counts = defaultdict(int)
    for t in sorted(targets):
        own = status.get(t + '.sv')
        nl = ''
        if own in (None, 'ONLY_G0'):
            cls, dirty = 'RESTRUCTURED', []
            cand = sorted(n[:-3] for n in g1_files if n.startswith(t))[:4]
            note = 'G1候选:' + ','.join(cand) if cand else ''
        else:
            dirty = sorted(closure_dirty(t) - {t})
            note = ''
            if own == 'SAME':
                cls = 'INHERIT' if not dirty else 'GLUE_INHERIT'
            elif norm(g0_files[t + '.sv']) == norm(g1_files[t + '.sv']):
                cls = 'TRIVIAL'   # 仅断言 .scala 行号漂移, 功能逐字一致
                nl = '0'
            else:
                n = diff_lines(g0_files[t + '.sv'], g1_files[t + '.sv'])
                nl = str(n)
                cls = 'REWRITE_S' if n < 50 else ('REWRITE_M' if n < 500 else 'REWRITE_L')
        counts[cls] += 1
        rows.append((t, own or 'MISSING', cls, nl, str(len(dirty)),
                     ','.join(dirty[:6]) + ('…' if len(dirty) > 6 else ''), note))

    OUT_TSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_TSV.open('w') as f:
        f.write('# G0<->G1 306目标delta  G0=v2r2(c8bbd5c6)  G1=kunminghu-v2(b36a1a2a5)\n')
        f.write('# target\town_file\tclass\tdiff_lines\tn_dirty_deps\tdirty_deps_sample\tnote\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')

    print('目标分类:', dict(sorted(counts.items())))
    print(f'台账已写 {OUT_TSV}')
    for cls in ('TRIVIAL', 'REWRITE_S', 'REWRITE_M', 'REWRITE_L', 'RESTRUCTURED'):
        names = [r[0] for r in rows if r[2] == cls]
        print(f'{cls}({len(names)}): {" ".join(names)}')


if __name__ == '__main__':
    sys.exit(main())
