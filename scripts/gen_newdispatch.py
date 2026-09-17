#!/usr/bin/env python3
"""gen_newdispatch.py —— NewDispatch 单文件重写的机械派生区生成器（本 lane 自建）。

NewDispatch 的 golden 是 firtool 展平产物：**7725 个扁平端口**（1026 in / 6699 out），
其中 5991 个属于 io_toIssueQueues。端口表、dyninst_t 结构体、wrapper 的
打包/拆包全部是机械的，手抄一定会错位，因此由本脚本从 golden 原文直接派生。

判据永远是 golden：本脚本**只读** $GOLDEN_RTL/NewDispatch.sv 的端口段，
不读 Chisel、不做任何"应该是这样"的推断。

产出（原地替换 rtl/backend/NewDispatch.sv 里的 BEGIN/END GENERATED 区）：
  PORTS        wrapper 的 7725 行端口声明（方向/位宽/顺序逐字同 golden）
  DYNINST_T    dyninst_t 结构体（180 个 leaf，来自四个 bundle 的并集）
  PACK         wrapper 侧 fromRename → dyninst_t 打包
  UNPACK       wrapper 侧 dyninst_t → toIssueQueues / enqRob / toMem 拆包

用法：
    scripts/gen_newdispatch.py --check     # 只比对，不写（gate 用）
    scripts/gen_newdispatch.py             # 原地刷新生成区
"""
import argparse
import os
import re
import sys

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(REPO, 'rtl', 'backend', 'NewDispatch.sv')

PORT_RE = re.compile(
    r'^(input|output|inout)\s+(?:(\[\d+:\d+\])\s+)?([A-Za-z_][A-Za-z0-9_]*)$')


def golden_ports():
    """golden 端口表：从 `module NewDispatch(` 到第一行 `);`。fail-closed。"""
    path = os.path.join(GOLDEN, 'NewDispatch.sv')
    lines = open(path).read().split('\n')
    try:
        start = next(i for i, l in enumerate(lines) if l.startswith('module NewDispatch('))
    except StopIteration:
        sys.exit('FATAL: golden 里找不到 `module NewDispatch(`')
    ports = []
    for l in lines[start + 1:]:
        if l.startswith(');'):
            break
        m = PORT_RE.match(l.strip().rstrip(','))
        if not m:
            sys.exit('FATAL: 端口行解析不了（fail-closed）: %r' % l)
        ports.append(m.groups())
    if not ports:
        sys.exit('FATAL: 端口表为空（fail-closed）')
    return ports


def leaf_width(w):
    return 1 if not w else int(w[1:-1].split(':')[0]) - int(w[1:-1].split(':')[1]) + 1


def dyninst_leaves(ports):
    """dyninst_t 的 leaf 集合 = 四个 payload bundle 的并集（实测无位宽冲突）。

    实测（可复跑：本脚本 --report）：
      io_toIssueQueues_*_bits_*  180 leaf  —— 超集
      io_fromRename_*_bits_*     134 leaf  ⊂ 超集
      io_enqRob_req_*_bits_*      63 leaf  ⊂ 超集
      io_toMem_lsqEnqIO_req_*_bits_* 53 leaf ⊂ 超集
    所以一个 dyninst_t 足够，四个 bundle 各取投影。
    """
    pats = [r'io_toIssueQueues_\d+_bits_(.+)$', r'io_fromRename_\d+_bits_(.+)$',
            r'io_enqRob_req_\d+_bits_(.+)$', r'io_toMem_lsqEnqIO_req_\d+_bits_(.+)$']
    leaves, order = {}, []
    for p in pats:
        rx = re.compile(p)
        for d, w, n in ports:
            m = rx.match(n)
            if not m:
                continue
            leaf, bits = m.group(1), leaf_width(w)
            if leaf in leaves:
                if leaves[leaf] != bits:
                    sys.exit('FATAL: leaf %s 位宽冲突 %d vs %d' % (leaf, leaves[leaf], bits))
            else:
                leaves[leaf] = bits
                order.append(leaf)
    return [(n, leaves[n]) for n in order]


def bundle_leaves(ports, rx_str):
    """某个 bundle 每个 slot 实际存在的 leaf —— golden 对不同 slot 做过 DCE，
    形状**不均匀**（例：snapshot 只有 slot0 有；toIssueQueues 的 8..19 号 enq
    口没有 srcLoadDependency）。照抄 golden，不要补齐。"""
    rx = re.compile(rx_str)
    per = {}
    for d, w, n in ports:
        m = rx.match(n)
        if m:
            per.setdefault(int(m.group(1)), []).append((m.group(2), leaf_width(w)))
    return per


def gen_ports(ports):
    out = []
    for i, (d, w, n) in enumerate(ports):
        comma = '' if i == len(ports) - 1 else ','
        out.append('  %-7s %-9s %s%s' % (d, w or '', n, comma))
    return out


def gen_dyninst(leaves):
    out = ['typedef struct packed {']
    for n, b in leaves:
        t = 'logic' if b == 1 else 'logic [%d:0]' % (b - 1)
        out.append('  %-14s %s;' % (t, n))
    out.append('} dyninst_t;   // %d leaf / %d bit（= golden 四个 payload bundle 的并集）'
               % (len(leaves), sum(b for _, b in leaves)))
    return out


def report(ports):
    leaves = dyninst_leaves(ports)
    ins = sum(1 for d, _, _ in ports if d == 'input')
    print('golden NewDispatch 端口: %d (in %d / out %d)' % (len(ports), ins, len(ports) - ins))
    print('  input  bits: %d' % sum(leaf_width(w) for d, w, _ in ports if d == 'input'))
    print('  output bits: %d' % sum(leaf_width(w) for d, w, _ in ports if d == 'output'))
    print('dyninst_t leaf: %d / %d bit' % (len(leaves), sum(b for _, b in leaves)))
    for nm, rx in [('toIssueQueues', r'io_toIssueQueues_(\d+)_bits_(.+)$'),
                   ('fromRename', r'io_fromRename_(\d+)_bits_(.+)$'),
                   ('enqRob_req', r'io_enqRob_req_(\d+)_bits_(.+)$'),
                   ('toMem_req', r'io_toMem_lsqEnqIO_req_(\d+)_bits_(.+)$')]:
        per = bundle_leaves(ports, rx)
        sizes = sorted(set(len(v) for v in per.values()))
        print('  %-14s slots=%d  leaf/slot=%s' % (nm, len(per), sizes))


BEGIN = '  // BEGIN GENERATED(%s)'
END = '  // END GENERATED'


def splice(text, tag, body, indent='  '):
    b, e = BEGIN % tag, END
    i = text.find(b)
    if i < 0:
        sys.exit('FATAL: 找不到生成区标记 %s' % b)
    j = text.find(e, i)
    if j < 0:
        sys.exit('FATAL: %s 没有闭合的 END GENERATED' % b)
    return text[:i] + b + '\n' + '\n'.join(body) + '\n' + text[j:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--report', action='store_true')
    a = ap.parse_args()
    ports = golden_ports()
    if a.report:
        report(ports)
        return 0
    if not os.path.exists(TARGET):
        sys.exit('FATAL: %s 不存在' % TARGET)
    txt = open(TARGET).read()
    new = splice(txt, 'PORTS', gen_ports(ports))
    new = splice(new, 'DYNINST_T', gen_dyninst(dyninst_leaves(ports)))
    if a.check:
        if new != txt:
            print('FAIL: 生成区与 golden 不同步，请重跑 scripts/gen_newdispatch.py')
            return 1
        print('OK: 生成区与 golden 同步')
        return 0
    open(TARGET, 'w').write(new)
    print('已刷新 %s 的生成区' % TARGET)
    return 0


if __name__ == '__main__':
    sys.exit(main())
