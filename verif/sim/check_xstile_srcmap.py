#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_xstile_srcmap.py —— 交付 4：整芯片清单对 XSTile 闭包的取源是否与 A 线源表一致。

源表 docs/xstile_srcmap.tsv（A 线 scripts/xstile_srcmap.py 生成；module/kind/source/sha256，
kind ∈ {RTL, MEMORY_MODEL}，source 为 rtl/... 或 $G1/<file>）。对一份 VCS 清单（-f 文件）检查：
  (a) 表内每个模块：清单里定义它的文件 == 表里的 source（RTL 行 = 本仓 rtl/...；MEMORY_MODEL 行 = $G1/<file>）；
      定义它的文件不在清单里 / 被别的文件定义 → 报；
  (b) 清单里有 golden 文件定义了闭包内模块，但该模块没有 MEMORY_MODEL 行 → 报。
可选 --build-log：VCS 编译日志里 `Parsing design file` / `Parsing library directory file` 实际读入的文件，
用来证明没有从 -y 库目录静默取件（impl 侧库目录只有 SimTop.sv）。

用法: check_xstile_srcmap.py [--srcmap <tsv>] --filelist <f> [--build-log <log>] [--label X] [--golden <dir>]
  --srcmap 默认读本仓 docs/xstile_srcmap.tsv（与脚本同一检出，任意 clone 路径都成立）；
  --golden 默认 $GOLDEN_RTL，否则 /home/eda/xs-env/G1-canonical/golden-rtl（源表里的 $G1）。
清单里的 rtl 项是绝对路径，记的是**生成清单那份检出**（例：在某个 lane worktree 里 build 的）。
若该根 != 本检出：rtl 项按「根之后的相对路径」对源表比，并逐文件比 sha256（清单那份 vs 本检出那份）——
内容不同 → INCONSISTENT；原文件已不存在（worktree 已清理）→ UNVERIFIABLE（rc=1，须从本检出重编）。
--filelist-root 可显式给根（默认从清单里含 /rtl/ 的项自动推断，须唯一）。
"""
import argparse
import hashlib
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
G1 = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
MODULE_RE = re.compile(r'^\s*module\s+(\w+)', re.M)


def main():
    global G1
    ap = argparse.ArgumentParser()
    ap.add_argument('--srcmap', default=str(REPO / 'docs' / 'xstile_srcmap.tsv'))
    ap.add_argument('--golden', default=G1)
    ap.add_argument('--filelist-root', help='生成清单那份检出的根目录（默认自动推断）')
    ap.add_argument('--filelist', required=True)
    ap.add_argument('--build-log')
    ap.add_argument('--label', default='')
    a = ap.parse_args()
    G1 = a.golden.rstrip('/')
    table = {}
    for l in open(a.srcmap, errors='replace'):
        if l.startswith('#') or l.startswith('module\t') or not l.strip():
            continue
        m, kind, src = l.rstrip('\n').split('\t')[:3]
        src = src.replace('$G1', G1)
        if not src.startswith('/'):
            src = str(REPO / src)
        table[m] = (kind, src)
    entries = [x.strip() for x in open(a.filelist) if x.strip()]
    if a.filelist_root:
        roots = {a.filelist_root.rstrip('/') + '/'}
    else:
        roots = {f[:f.index('/rtl/') + 1] for f in entries if not f.startswith(G1 + '/') and '/rtl/' in f}
    if len(roots) > 1:
        print(f'[{a.label}] 清单里 rtl 项来自多个检出根 {sorted(roots)}，无法判定；用 --filelist-root 指定')
        return 2
    root = roots.pop() if roots else str(REPO) + '/'
    relocated = pathlib.Path(root).resolve() != REPO
    content_diff, unverifiable = [], []

    def to_repo(f):  # 清单项 -> 本检出里对应的路径（不在该根下的原样返回）
        return str(REPO / f[len(root):]) if relocated and f.startswith(root) else f

    definer = {}
    for f in entries:
        g = to_repo(f)
        if g != f:
            if os.path.exists(f):
                if hashlib.sha256(open(f, 'rb').read()).digest() != hashlib.sha256(open(g, 'rb').read()).digest():
                    content_diff.append(f)
            else:
                unverifiable.append(f)
        for m in MODULE_RE.findall(pathlib.Path(f if os.path.exists(f) else g).read_text(errors='replace')):
            definer.setdefault(m, []).append(g)
    bad_a, bad_b, dup = [], [], []
    for m, (kind, src) in sorted(table.items()):
        got = definer.get(m, [])
        if len(got) > 1:
            dup.append((m, got))
        if got != [src]:
            bad_a.append((m, kind, src, got))
    for m, fs in sorted(definer.items()):
        for f in fs:
            if f.startswith(G1) and m in table and table[m][0] != 'MEMORY_MODEL':
                bad_b.append((m, f))
            if f.startswith(G1) and m not in table and m.split('__')[0] in table:
                pass  # 核外改名拷贝不在 G1 目录下，这里不会出现
    print(f'[{a.label}] 源表 {len(table)} 模块 (RTL {sum(k=="RTL" for k,_ in table.values())} / '
          f'MEMORY_MODEL {sum(k=="MEMORY_MODEL" for k,_ in table.values())})；清单定义模块 {len(definer)}')
    print(f'[{a.label}] (a) 取源与源表不一致: {len(bad_a)}')
    for x in bad_a[:20]:
        print('    ', x)
    print(f'[{a.label}] (b) golden 文件定义闭包内非存储模块: {len(bad_b)}')
    for x in bad_b[:20]:
        print('    ', x)
    print(f'[{a.label}] 清单内同名重复定义: {len(dup)}')
    rc = 0 if not (bad_a or bad_b or dup or content_diff) else 1
    if relocated:
        print(f'[{a.label}] 清单 rtl 项生成于另一份检出 {root}（本检出 {REPO}/）：按相对路径比对；'
              f'内容与本检出不同 {len(content_diff)}，原文件已不存在无法核内容 {len(unverifiable)}')
        for x in content_diff[:10]:
            print('     content differs:', x)
    if a.build_log:
        log = pathlib.Path(a.build_log).read_text(errors='replace')
        lib = sorted(set(re.findall(r"Parsing library directory file '([^']+)'", log)))
        des = set(re.findall(r"Parsing design file '([^']+)'", log))
        fl = {x.strip() for x in open(a.filelist) if x.strip()}
        print(f'[{a.label}] build.log: 读入 design file {len(des)}（清单 {len(fl)} 项，清单内未读入 {len(fl - des)}）；'
              f'从 -y 库目录读入 {len(lib)}: {lib[:5]}')
        if any(not p.endswith('/SimTop.sv') for p in lib):
            rc = 1
    if rc == 0 and unverifiable:
        print(f'[{a.label}] VERDICT: UNVERIFIABLE（{len(unverifiable)} 个清单文件已不存在；从本检出重编 impl 后再查）')
        return 1
    print(f'[{a.label}] VERDICT: {"CONSISTENT" if rc == 0 else "INCONSISTENT"}')
    return rc


if __name__ == '__main__':
    sys.exit(main())
