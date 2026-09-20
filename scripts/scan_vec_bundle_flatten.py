#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""scan_vec_bundle_flatten.py —— 扫 golden，量出「下标在字段名中间」这一族展平形态的适用范围。

## 由来（2026-09-20，InterruptFilter lane 发现，集成者裁定 1 要求量化）

`scripts/fm_eq.tcl` 的 `auto_match_flattened_arrays` 只认**下标在末尾**的形态：

    ref   name_1_0_reg / array_0_reg[2]      <->  impl  name_reg[1][0] / array_reg[0][2]

它是为 `Reg(Vec(N, UInt))`（Vec of 标量）写的。但 firtool 对
**`Reg(Vec(N, Bundle))`（Vec of Bundle）** 展平出来的是**下标在字段名中间**：

    ref   mipriosReg_0_idx / mipriosReg_0_enable / mipriosReg_0_prioNum
    impl  mipriosReg_idx[0] / mipriosReg_enable[0] / mipriosReg_prioNum[0]   (可读核按 SoA 存)

两条规则的字符串形状不同，`auto_match_flattened_arrays` 对后者逐条
`AUTO_MATCH_FAIL`。InterruptFilter 就是这么撞上的（85(85) 个孤儿点），
当时在模块本地 `verif/ut/InterruptFilter/fm_pins.tcl` 里补了规则。

★集成者裁定：先不并回 `fm_eq.tcl`★ —— 它在**每个目标的证明闭包里**，改匹配规则
不是纯增量（原先落在 unmatched/unread 的点可能被配上，每个目标的 passing 都可能动），
会让全部既有 receipt 退化成旧前提。但这条发现要记账，于是有了这张表：
**将来谁要做这件事，先看这张表知道要重证哪些、值不值得。**

## 判据（纯静态，只读 golden，不读任何 FM 产物）

对每个 golden 模块里的 `reg` 声明名 `R`：
  1. 按 `^(?P<base>.+?)_(?P<idx>\\d+)_(?P<field>.+)$` 拆（最短 base，贪到第一个纯数字段）；
  2. 要求 `field` **不是纯数字** —— 纯数字说明是多维 Vec of 标量（`name_1_0`），
     那是下标在末尾的形态，`auto_match_flattened_arrays` 已经认得，不算；
  3. 把 `(base, field)` 归组，同一个 `base` 下必须出现 **>= 2 个不同 idx**
     且 **>= 2 个不同 field** —— 只有一个 field 的话与 Vec of 标量无法区分，
     从严不计（宁可漏报也不虚报范围）。

满足的 `base` 记为一个「Vec-of-Bundle 族」。

## 输出

`docs/vec_bundle_flatten_scope.tsv`，每个**命中的 golden 模块**一行：
    module  families  regs_in_shape  is_fm_target  ut_dir  has_local_pins  example

  · `is_fm_target` —— 该模块名是否出现在某个 `verif/ut/*/Makefile` 的 `FM_VARIANTS` 里
    （只有 FM 目标才谈得上"要重证"）；
  · `has_local_pins` —— 该 UT 目录下有没有 `fm_pins.tcl` / `fm_pins_pre.tcl`
    （已经在本地补过规则的，并回共享脚本时最可能受影响）。

## 这张表**不**回答什么（别拿它当结论）

它量的是 **golden 一侧的形态**。某个目标会不会真的因为这条规则产生孤儿点，
还取决于**重写件怎么存**（按 per-field 数组存才会撞上；若重写件逐字同名、
或干脆没重写，就不会）。所以这张表是**上界/候选集**，不是"受影响目标清单"。

用法: python3 scripts/scan_vec_bundle_flatten.py [--check]
"""
import argparse
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
GOLDEN = pathlib.Path(os.environ.get('G1_CANONICAL',
                                     '/home/eda/xs-env/G1-canonical')) / 'golden-rtl'
OUT = REPO / 'docs' / 'vec_bundle_flatten_scope.tsv'

REG_RE = re.compile(r'^\s*reg\s+(?:\[\s*\d+\s*:\s*\d+\s*\]\s*)?([A-Za-z_]\w*)\s*;', re.M)
SPLIT_RE = re.compile(r'^(?P<base>.+?)_(?P<idx>\d+)_(?P<field>.+)$')


def families_of(text):
    """返回 {base: (idx 集合, field 集合, 命中 reg 数)}，只保留满足判据的 base。"""
    acc = collections.defaultdict(lambda: [set(), set(), 0])
    for name in REG_RE.findall(text):
        m = SPLIT_RE.match(name)
        if not m:
            continue
        field = m.group('field')
        if field.isdigit():
            continue                     # 多维 Vec of 标量：下标在末尾，不算
        b = acc[m.group('base')]
        b[0].add(int(m.group('idx')))
        b[1].add(field)
        b[2] += 1
    return {k: v for k, v in acc.items() if len(v[0]) >= 2 and len(v[1]) >= 2}


def fm_target_index():
    """{golden 顶层名: UT 目录名}，从各 UT Makefile 的 FM_VARIANTS 现读。"""
    idx = {}
    for mk in sorted((REPO / 'verif' / 'ut').glob('*/Makefile')):
        txt = re.sub(r'\\\n', ' ', mk.read_text(errors='replace'))
        m = re.search(r'^FM_VARIANTS\s*=\s*(.*)$', txt, re.M)
        if m:
            for t in m.group(1).split():
                idx.setdefault(t, mk.parent.name)
    return idx


def build():
    targets = fm_target_index()
    rows = []
    for f in sorted(GOLDEN.glob('*.sv')):
        fams = families_of(f.read_text(errors='replace'))
        if not fams:
            continue
        mod = f.stem
        nregs = sum(v[2] for v in fams.values())
        ut = targets.get(mod, '')
        pins = ''
        if ut:
            d = REPO / 'verif' / 'ut' / ut
            hits = [p.name for p in (d / 'fm_pins.tcl', d / 'fm_pins_pre.tcl') if p.exists()]
            pins = ','.join(hits)
        # 例子取 reg 最多的那个族
        top = max(fams.items(), key=lambda kv: kv[1][2])
        ex = '%s_<i>_{%s}' % (top[0], ','.join(sorted(top[1][1])[:3]) +
                              ('...' if len(top[1][1]) > 3 else ''))
        rows.append((mod, len(fams), nregs, 'yes' if ut else 'no', ut or '-',
                     pins or '-', ex))
    rows.sort(key=lambda r: (-r[2], r[0]))
    lines = ['# scan_vec_bundle_flatten.py —— 「下标在字段名中间」的 Vec-of-Bundle 展平形态',
             '# 判据与边界见脚本 docstring；这是**候选集/上界**，不是受影响目标清单。',
             '# golden = %s' % GOLDEN,
             '\t'.join(['module', 'families', 'regs_in_shape', 'is_fm_target',
                        'ut_dir', 'has_local_pins', 'example'])]
    lines += ['\t'.join(str(x) for x in r) for r in rows]
    tgt = [r for r in rows if r[3] == 'yes']
    pinned = [r for r in tgt if r[5] != '-']
    lines.append('# 命中 golden 模块 %d 个；其中 FM 目标 %d 个（非 FM 目标 %d 个，'
                 '谈不上"要重证"）；FM 目标里已带本地钉点文件的 %d 个、没有的 %d 个'
                 % (len(rows), len(tgt), len(rows) - len(tgt),
                    len(pinned), len(tgt) - len(pinned)))
    lines.append('# ★"没有本地钉点文件"的那 %d 个最值得注意★：它们现在是 FM 自己把点配上的，'
                 '并回共享规则后 passing 最可能变动。' % (len(tgt) - len(pinned)))
    fam = collections.Counter(re.sub(r'_\d+$', '', r[0]) for r in tgt)
    lines.append('# FM 目标按家族（去掉变体尾号）前 6： '
                 + '  '.join('%s x%d' % (k, v) for k, v in fam.most_common(6)))
    return '\n'.join(lines) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    txt = build()
    if a.check:
        if not OUT.exists() or OUT.read_text() != txt:
            print('scan_vec_bundle_flatten --check: %s 与重算结果不一致（DRIFT）' % OUT)
            return 1
        print('scan_vec_bundle_flatten --check: 逐字节一致')
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(txt)
    print('写出 %s' % OUT.relative_to(REPO))
    print(txt.strip().split('\n')[-1])
    return 0


if __name__ == '__main__':
    sys.exit(main())
