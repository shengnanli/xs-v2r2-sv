#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fm_passing_model.py —— FM `passing` 比较点的**跑前**预测器（通用版）。

## 模型

    passing = Σ_(golden 闭包里的每个**实例**) 该模块的寄存器位数
            + 顶层 output 端口位数

其中 `寄存器位数(mod)` = 该 `.sv` 里所有 `reg [h:l] name;` 声明的位宽之和。
直觉：FM 的比较点就是「触发器 + 顶层输出」，而 golden 是扁平层次、每个实例
各有一套触发器。

## 这个模型的战绩（都是**跑前**登记、跑后逐条对账的实测）

| 家族 | 结果 |
|---|---|
| TlbStorageWrapper_1 / TLBFA_1/_2/_3 / DelayN_7 / DelayN_9 | 逐位命中 |
| TLBNonBlock / _1 / _2 | 逐位命中 |
| Entries*（阵列档） | 模型 25013 实测 25001、模型 12264 实测 12136（差来自 Constant 寄存器） |
| OthersEntry* 18 个（单条目档） | **18/18 差全为 +0** |

★阵列/大件会略低于模型★：golden 里被 FM 判成 Constant 的寄存器不产生比较点。
所以模型是**上界**；实测高于模型一定是哪里算漏了，必须当 fail 查。

## 用法

    python3 scripts/fm_passing_model.py <target> [--deps a.sv b.sv ...]
    python3 scripts/fm_passing_model.py --from-ut <UT目录裸名>

`--from-ut` 直接读那个 UT 的 Makefile：`FM_VARIANTS` 逐个算，
依赖取 `FM_REF_DEPS_<名>`（没写就只算自己）。
"""
import argparse, collections, os, pathlib, re, sys

GOLDEN = pathlib.Path(os.environ.get('G1_CANONICAL',
                                     '/home/eda/xs-env/G1-canonical')) / 'golden-rtl'
REPO = pathlib.Path(__file__).resolve().parents[1]

REG_RE = re.compile(r'^\s*reg\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?[A-Za-z_]\w*\s*'
                    r'(?:\[[^\]]*\]\s*)?;', re.M)
OUT_RE = re.compile(r'^\s*output\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?[A-Za-z_]\w*\s*,?\s*$',
                    re.M)
INST_RE = re.compile(r'^\s{0,4}([A-Z][A-Za-z0-9_]*)\s+([a-zA-Z_]\w*)\s*\(\s*$', re.M)


def _txt(mod):
    return (GOLDEN / f'{mod}.sv').read_text(errors='replace')


def reg_bits(mod):
    n = 0
    for hi, lo in REG_RE.findall(_txt(mod)):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def out_bits(top):
    t = _txt(top)
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(top), t, re.S | re.M)
    if not m:
        sys.exit(f'{top}: 找不到 module 头')
    n = 0
    for hi, lo in OUT_RE.findall(m.group(1)):
        n += 1 if not hi else int(hi) - int(lo) + 1
    return n


def instance_counts(top, allowed):
    """从 top 往下数**实例**（不是模块）。allowed = 允许展开的模块集合。

    ★为什么按实例数而不是模块数★：golden 是扁平层次，同一个模块例化 N 份就有
    N 套触发器，FM 的比较点也是 N 份。只按模块数算会把大件严重低估。
    """
    cnt = collections.Counter({top: 1})
    stack = [top]
    while stack:
        cur = stack.pop()
        if not (GOLDEN / f'{cur}.sv').exists():
            continue
        for child, _inst in INST_RE.findall(_txt(cur)):
            if child in allowed and (GOLDEN / f'{child}.sv').exists():
                cnt[child] += 1
                stack.append(child)
    return cnt


def model(top, deps):
    allowed = set(deps)
    cnt = instance_counts(top, allowed)
    per = {m: reg_bits(m) for m in cnt}
    regs = sum(cnt[m] * per[m] for m in cnt)
    outs = out_bits(top)
    return dict(top=top, insts=dict(cnt), per_reg=per, regs=regs, outs=outs,
                model=regs + outs)


def from_ut(ut):
    mk = (REPO / 'verif' / 'ut' / ut / 'Makefile').read_text(errors='replace')
    mk = re.sub(r'\\\n', ' ', mk)          # 续行拼起来
    mv = re.search(r'^FM_VARIANTS\s*=\s*(.*)$', mk, re.M)
    if not mv:
        sys.exit(f'{ut}: Makefile 里没有 FM_VARIANTS')
    tops = mv.group(1).split()
    out = []
    for t in tops:
        d = re.search(r'^FM_REF_DEPS_%s\s*=\s*(.*)$' % re.escape(t), mk, re.M)
        deps = [x[:-3] for x in d.group(1).split() if x.endswith('.sv')] if d else []
        out.append(model(t, deps))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target', nargs='?')
    ap.add_argument('--deps', nargs='*', default=[])
    ap.add_argument('--from-ut')
    a = ap.parse_args()
    rows = from_ut(a.from_ut) if a.from_ut else [
        model(a.target, [d[:-3] if d.endswith('.sv') else d for d in a.deps])]
    print(f'{"target":<24}{"regs":>10}{"outs":>8}{"模型(上界)":>12}   实例构成')
    for r in rows:
        comp = ', '.join(f'{m}x{c}' for m, c in sorted(r['insts'].items())
                         if m != r['top'])
        print(f'{r["top"]:<24}{r["regs"]:>10}{r["outs"]:>8}{r["model"]:>12}   '
              f'{comp or "(无子实例)"}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
