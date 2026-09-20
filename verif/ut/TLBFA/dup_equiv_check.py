#!/usr/bin/env python3
"""证明 golden TLBFA_1 的 dup1 输出与 dup0 是**逐字同一份方程**。

Predictor 教训：golden 里带 dup 后缀的信号可能"部分共用、部分分份"，不能想当然。
做法：把 wire/assign 定义做成字典，从输出端口的 RHS 出发递归展开成规范表达式
（展开到寄存器/输入端口/常量为止），再把 dup0 与 dup1 的规范式逐字比较。
"""
import re, sys
src = open('/home/eda/xs-env/G1-canonical/golden-rtl/TLBFA_1.sv').read()
defs = {}
for m in re.finditer(r'^\s*(?:wire|assign)\s+(?:\[[^\]]+\]\s*)?(\w+)\s*=\s*(.*?);\s*$',
                     src, re.S | re.M):
    name, expr = m.group(1), m.group(2)
    assert name not in defs, name
    defs[name] = ' '.join(expr.split())

LEAF = re.compile(r'^(io_|entries_|hitVecReg|reqVpn|refill_wayIdx_reg|REG$|v_\d)')
ID = re.compile(r'\b([A-Za-z_]\w*)\b')
sys.setrecursionlimit(100000)
memo = {}

def expand(expr):
    return ID.sub(lambda m: canon(m.group(1)) if (m.group(1) in defs
                  and not LEAF.match(m.group(1))) else m.group(1), expr)

def canon(name):
    if name in memo: return memo[name]
    memo[name] = '<cycle>'
    memo[name] = '(' + expand(defs[name]) + ')'
    return memo[name]

hdr = re.search(r'^module TLBFA_1\(\n(.*?)^\);', src, re.S | re.M).group(1)
ports = re.findall(r'^\s*output\s+(?:\[[^\]]+\]\s*)?(\w+),?$', hdr, re.M)

pairs = []
for p in ports:
    m = re.fullmatch(r'(io_r_resp_\d+_bits_(?:ppn|pbmt|g_pbmt|s2xlate))_1', p)
    if m: pairs.append((m.group(1) + '_0', p)); continue
    m = re.fullmatch(r'(io_r_resp_\d+_bits_g?_?perm)_1_(\w+)', p)
    if m: pairs.append((m.group(1) + '_0_' + m.group(2), p))

print(f'dup1 输出端口 {len(pairs)} 对')
bad = same = 0
for p0, p1 in pairs:
    if p0 not in defs or p1 not in defs:
        print(f'  ?? 找不到定义 {p0} / {p1}'); bad += 1; continue
    a, b = expand(defs[p0]), expand(defs[p1])
    if a == b:
        same += 1
        print(f'  同一份方程（{len(a)} 字符）: {p0} == {p1}')
    else:
        bad += 1
        print(f'  ★不同: {p0} vs {p1}  (len {len(a)} / {len(b)})')
        for i in range(min(len(a), len(b))):
            if a[i] != b[i]:
                print(f'     首差@{i}: ...{a[max(0,i-80):i+80]}')
                print(f'              ...{b[max(0,i-80):i+80]}')
                break
print(f'--- 逐字相同 {same} / 不同 {bad}')
sys.exit(1 if bad else 0)
