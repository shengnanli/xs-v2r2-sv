#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tlbsw_passing_model.py —— FM passing 预测模型 + 自校准（只读 golden）。

模型：passing = 证明闭包的触发器位数 + 顶层 output 端口位数。
校准点是 TLBFA 家族 4 个 + TlbStorageWrapper/_1 两个，全部已签核。
详见 docs/tlbsw23_passing_prediction.md（该文件在跑 FM 之前写定）。

用法: python3 scripts/tlbsw_passing_model.py [--check]
      --check 要求 6 个校准点全部逐位命中，否则 rc=1。
"""
import re, sys, os

G = '/home/eda/xs-env/G1-canonical/golden-rtl/'
# 已签核实测值（来源见 docs/tlbsw23_passing_prediction.md）
KNOWN = {'TLBFA': 8182, 'TLBFA_1': 8663, 'TLBFA_2': 8233, 'TLBFA_3': 8229,
         'TlbStorageWrapper': 8208, 'TlbStorageWrapper_1': 8682}
# 目标：父 wrapper -> 内层阵列
CHILD = {'TlbStorageWrapper': 'TLBFA', 'TlbStorageWrapper_1': 'TLBFA_1',
         'TlbStorageWrapper_2': 'TLBFA_2', 'TlbStorageWrapper_3': 'TLBFA_3'}


def _w(d):
    m = re.match(r'\[(\d+):(\d+)\]', (d or '').strip())
    return abs(int(m.group(1)) - int(m.group(2))) + 1 if m else 1


def port_bits(mod):
    s = open(G + mod + '.sv').read()
    m = re.search(r'^module \w+\(\s*$', s, re.M)
    body = s[m.end(): s.index('\n);', m.end())]
    i = o = 0
    for ln in body.split('\n'):
        mm = re.match(r'(input|output)\s+(.*?)\s*([A-Za-z_]\w*)$', ln.strip().rstrip(','))
        if not mm:
            continue
        b = _w(mm.group(2))
        if mm.group(1) == 'output':
            o += b
        else:
            i += b
    return i, o


def ff_bits(mod):
    """firtool 产出里 `reg` 声明就是触发器；数组 reg 乘深度。"""
    s = open(G + mod + '.sv').read()
    tot = 0
    for m in re.finditer(r'^\s*reg\s+(\[\d+:\d+\]\s+)?(\w+)(\s*\[(\d+):(\d+)\])?\s*;', s, re.M):
        d = abs(int(m.group(4)) - int(m.group(5))) + 1 if m.group(3) else 1
        tot += _w(m.group(1)) * d
    return tot


def predict(mod):
    ff = ff_bits(mod)
    if mod in CHILD:
        ff += ff_bits(CHILD[mod])
    return ff + port_bits(mod)[1]


def main():
    check = '--check' in sys.argv
    rc = 0
    print('%-22s %8s %8s %10s %10s %s' % ('module', 'out_bits', 'ff_bits', 'predicted', 'measured', ''))
    for mod in ['TLBFA', 'TLBFA_1', 'TLBFA_2', 'TLBFA_3',
                'TlbStorageWrapper', 'TlbStorageWrapper_1',
                'TlbStorageWrapper_2', 'TlbStorageWrapper_3']:
        ff = ff_bits(mod) + (ff_bits(CHILD[mod]) if mod in CHILD else 0)
        p = predict(mod)
        k = KNOWN.get(mod)
        tag = '' if k is None else ('HIT' if k == p else '★MISS★')
        if k is not None and k != p:
            rc = 1
        print('%-22s %8d %8d %10d %10s %s' % (mod, port_bits(mod)[1], ff, p,
                                              '-' if k is None else k, tag))
    if check and rc:
        print('校准点未全部命中 —— 模型或量法有问题，先别信预测')
    return rc if check else 0


if __name__ == '__main__':
    sys.exit(main())
