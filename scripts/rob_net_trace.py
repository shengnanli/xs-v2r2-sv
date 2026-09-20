#!/usr/bin/env python3
"""rob_net_trace.py -- 展开 golden Rob 里某个网名的驱动式（按需逐层）。

golden 是 firtool 展平输出：中间量全叫 `_GEN_<n>` / `_T_<n>`，一个名字一次赋值。
写可读核时必须知道这些名字**语义上**是什么，否则就只能照抄（照抄=转写，本仓不收）。
这个脚本只做一件事：给定网名，打印它的 assign，并可按深度继续展开它引用的网。
纯查询工具，不产 RTL。
"""
import argparse, re, sys, collections

def load(path):
    txt = open(path).read()
    asg = {}
    # firtool: `  assign <name> = <expr>;`  可能折行
    for m in re.finditer(r'^\s*assign\s+(\w+)\s*=\s*((?:[^;]|\n)*?);\s*$', txt, re.M):
        asg[m.group(1)] = ' '.join(m.group(2).split())
    wires = set(re.findall(r'^\s*wire\s*(?:\[[^\]]*\])?\s*(\w+)\s*=\s*', txt, re.M))
    winit = {}
    for m in re.finditer(r'^\s*wire\s*(?:\[[^\]]*\])?\s*(\w+)\s*=\s*((?:[^;]|\n)*?);\s*$', txt, re.M):
        winit[m.group(1)] = ' '.join(m.group(2).split())
    asg.update(winit)
    return asg

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default='/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
    ap.add_argument('--depth', type=int, default=1)
    ap.add_argument('--only-gen', action='store_true',
                    help='只继续展开 _GEN_/_T_ 这类无语义名')
    ap.add_argument('nets', nargs='+')
    a = ap.parse_args()
    asg = load(a.golden)
    seen = set()
    def show(n, d, ind=0):
        if n in seen or d < 0:
            return
        seen.add(n)
        e = asg.get(n)
        if e is None:
            print('%s%s = <port/reg/undriven>' % (' ' * ind, n)); return
        print('%s%s = %s' % (' ' * ind, n, e if len(e) < 400 else e[:400] + ' ...'))
        if d == 0:
            return
        for r in sorted(set(re.findall(r'\b[A-Za-z_]\w*\b', e))):
            if r in asg and (not a.only_gen or re.match(r'^_(GEN|T)', r)):
                show(r, d - 1, ind + 2)
    for n in a.nets:
        show(n, a.depth)
        print()
    return 0

sys.exit(main())
