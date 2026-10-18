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

用法: check_xstile_srcmap.py --srcmap <tsv> --filelist <f> [--build-log <log>] [--label X]
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
G1 = '/home/eda/xs-env/G1-canonical/golden-rtl'
MODULE_RE = re.compile(r'^\s*module\s+(\w+)', re.M)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--srcmap', required=True)
    ap.add_argument('--filelist', required=True)
    ap.add_argument('--build-log')
    ap.add_argument('--label', default='')
    a = ap.parse_args()
    table = {}
    for l in open(a.srcmap, errors='replace'):
        if l.startswith('#') or l.startswith('module\t') or not l.strip():
            continue
        m, kind, src = l.rstrip('\n').split('\t')[:3]
        src = src.replace('$G1', G1)
        if not src.startswith('/'):
            src = str(REPO / src)
        table[m] = (kind, src)
    definer = {}
    for f in [x.strip() for x in open(a.filelist) if x.strip()]:
        for m in MODULE_RE.findall(pathlib.Path(f).read_text(errors='replace')):
            definer.setdefault(m, []).append(f)
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
    rc = 0 if not (bad_a or bad_b or dup) else 1
    if a.build_log:
        log = pathlib.Path(a.build_log).read_text(errors='replace')
        lib = sorted(set(re.findall(r"Parsing library directory file '([^']+)'", log)))
        des = set(re.findall(r"Parsing design file '([^']+)'", log))
        fl = {x.strip() for x in open(a.filelist) if x.strip()}
        print(f'[{a.label}] build.log: 读入 design file {len(des)}（清单 {len(fl)} 项，清单内未读入 {len(fl - des)}）；'
              f'从 -y 库目录读入 {len(lib)}: {lib[:5]}')
        if any(not p.endswith('/SimTop.sv') for p in lib):
            rc = 1
    print(f'[{a.label}] VERDICT: {"CONSISTENT" if rc == 0 else "INCONSISTENT"}')
    return rc


if __name__ == '__main__':
    sys.exit(main())
