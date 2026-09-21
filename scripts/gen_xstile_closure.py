#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_xstile_closure.py —— 从 G1 golden 算 XSTile 例化闭包，落成 docs/xstile_closure.tsv。

## 为什么要有它

覆盖率台账的 universe 是 `scripts/g1_configured_universe.py` 生成的，**根是 XSTop**
（见那张表的表头 `root=XSTop`）。XSTop 之下除了核，还挂着 L3（OpenLLC）、
TileLink/AXI 桥（TLToAXI4 / TLFIFOFixer）、NCB 家族、APLIC 等 SoC 级件。

而本轮重写的范围是**核**（XSTile 闭包）—— 用户的长期约束是「核外面的文件不要重写」。
两者混在一个分母里，后果有两条，第二条更贵：

  1. 百分比答的是「整个 SoC 重写了多少」，不是「核重写了多少」。
     实测差距不大（proven 41.2% -> 42.4%），所以**别拿这个当进展**。
  2. ★排期表会把核外大件排到核内大件前面★。实测 30 个候选里 7 个在核外，
     合计 210759 行（TLToAXI4 68788 / NCB200 36161 / Domain 26885 / …），
     一直夹在 Backend(79590) / LoadQueueUncache(59051) / CtrlBlock(57635) 中间。
     这是真损失：一条 lane 照表接活就接到范围外去了。

## 判据

从 `XSTile` 出发，沿**例化**关系做可达闭包。例化的识别只认
`<模块名> [#(...)] <实例名> (` 这种形态，并排掉 SV 关键字；
只把 golden 目录里**确实存在同名文件**的名字当子模块（黑盒 / 厂商宏没有文件，
自然不进闭包，这是对的 —— 它们不是我们要重写的件）。

★只判 golden 的层级，不判 impl★：`xs_*_core` 这类自研内层核 golden 里没有同名件，
它们是**核内模块的实现细节**，不该被判成"核外"。第一版审 lane 改动时忘了这条，
把 xs_Rob_core / xs_StoreQueue_core 报成核外 —— 错的是量具不是被量物。

## 用法

    python3 scripts/gen_xstile_closure.py           # 重生成
    python3 scripts/gen_xstile_closure.py --check   # 幂等校验（进 gate_all.sh）
"""
from __future__ import print_function

import argparse
import os
import re
import sys

REPO = os.environ.get('XSSV_HOME') or os.path.dirname(os.path.dirname(
    os.path.abspath(__file__)))
GOLDEN = '/home/eda/xs-env/G1-canonical/golden-rtl'
OUT = os.path.join(REPO, 'docs', 'xstile_closure.tsv')
ROOT = 'XSTile'

INST = re.compile(r'^[ \t]*([A-Za-z_]\w*)[ \t]*(?:#\s*\([^;]*?\)\s*)?'
                  r'([A-Za-z_]\w*)\s*\(', re.M)
KW = {'if', 'for', 'while', 'case', 'casex', 'casez', 'always', 'always_ff',
      'always_comb', 'always_latch', 'assign', 'initial', 'final', 'module',
      'endmodule', 'function', 'task', 'generate', 'endgenerate', 'begin',
      'end', 'return', 'assert', 'assume', 'cover', 'input', 'output', 'inout',
      'logic', 'wire', 'reg', 'localparam', 'parameter', 'typedef', 'import',
      'package', 'wor', 'automatic', 'static', 'defparam', 'specify', 'genvar',
      'integer', 'real', 'time', 'string', 'bit', 'byte', 'int', 'shortint',
      'longint', 'struct', 'union', 'enum', 'interface', 'modport'}


def golden_files():
    idx = {}
    for fn in sorted(os.listdir(GOLDEN)):
        if fn.endswith('.sv'):
            idx[fn[:-3]] = os.path.join(GOLDEN, fn)
        elif fn.endswith('.v'):
            idx.setdefault(fn[:-2], os.path.join(GOLDEN, fn))
    return idx


def _strip(t):
    t = re.sub(r'/\*.*?\*/', ' ', t, flags=re.S)
    return re.sub(r'//[^\n]*', '', t)


def closure(root, files):
    seen, stack = set(), [root]
    while stack:
        m = stack.pop()
        if m in seen:
            continue
        seen.add(m)
        p = files.get(m)
        if not p:
            continue
        with open(p, errors='replace') as f:
            txt = _strip(f.read())
        for g, _inst in INST.findall(txt):
            if g not in KW and g in files and g not in seen:
                stack.append(g)
    return seen


def render():
    files = golden_files()
    if ROOT not in files:
        sys.stderr.write('gen_xstile_closure: golden 里没有 %s.sv\n' % ROOT)
        return None
    tile = closure(ROOT, files)
    lines = {}
    for m in tile:
        with open(files[m], errors='replace') as f:
            lines[m] = sum(1 for _ in f)
    out = [
        '# XSTile 例化闭包（scripts/gen_xstile_closure.py 生成；禁止手工编辑）',
        '# 本轮重写范围 = 核 = 本表。覆盖率 universe 的根是 XSTop，包含 L3/桥/NCB 等',
        '# SoC 级件，**不在本轮范围内**；两者的差集见 rewrite_coverage.tsv 的核外一栏。',
        '# ★只列 golden 里存在同名文件的模块★：黑盒/厂商宏没有文件，不进闭包；',
        '#   xs_*_core 这类自研内层核 golden 里没有同名件，是核内模块的实现细节，',
        '#   判范围时不参与（判它们会把自己的实现细节误报成"核外"）。',
        '# root=%s  模块=%d  golden 行=%d' % (ROOT, len(tile),
                                              sum(lines.values())),
        '# module\tgolden_lines',
    ]
    for m in sorted(tile):
        out.append('%s\t%d' % (m, lines[m]))
    return '\n'.join(out) + '\n'


def load(path=None):
    """{模块名: golden 行数}。给 rewrite_coverage.py / coverage_three_axis.py 用。"""
    p = path or OUT
    d = {}
    if not os.path.isfile(p):
        return d
    with open(p, errors='replace') as f:
        for l in f:
            if l.startswith('#') or not l.strip():
                continue
            c = l.rstrip('\n').split('\t')
            if len(c) >= 2 and c[1].isdigit():
                d[c[0]] = int(c[1])
    return d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='幂等校验，不写文件')
    a = ap.parse_args()
    txt = render()
    if txt is None:
        return 1
    if a.check:
        cur = open(OUT, errors='replace').read() if os.path.isfile(OUT) else ''
        if cur != txt:
            print('gen_xstile_closure: ★--check 红★ docs/xstile_closure.tsv '
                  '不是当前脚本生成的（重跑本脚本）')
            return 1
        print('gen_xstile_closure: --check 一致（%d 个模块）'
              % sum(1 for l in txt.splitlines() if not l.startswith('#')))
        return 0
    with open(OUT, 'w') as f:
        f.write(txt)
    n = sum(1 for l in txt.splitlines() if not l.startswith('#'))
    print('写出 docs/xstile_closure.tsv：%s 闭包 %d 个模块' % (ROOT, n))
    return 0


if __name__ == '__main__':
    sys.exit(main())
