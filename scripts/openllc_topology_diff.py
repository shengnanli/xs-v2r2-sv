#!/usr/bin/env python3
"""openllc_topology_diff.py —— 逐项机械对比 golden 与重写的 OpenLLC **顶层拓扑**。

存在理由（2026-09-21）：本目标第一次跑 FM（merge_duplicated_registers 用默认 true）
报了 20 个 failing port，全在 io_rn_0_rx_snp_flit[27..46]，同时有 6 个 ref-only
未配对寄存器。"FM 报失配"和"重写有 bug"在输出里长得一模一样，不能靠读代码下结论。
这个脚本把"两侧顶层完全同构"这句话变成可复跑的机械判定：

  ① 顶层例化的实例集合（名字 + 模块类型）
  ② 每个实例的**每一条端口绑定**（端口名 -> 连接网名，去空白后逐字比较）
  ③ 顶层 wire/logic/reg 声明（名字 -> 位宽）
  ④ 顶层 assign 语句（左值 -> 右值，去空白后逐字比较）

四项全等 => 顶层拓扑同构 => FM 的失配只可能来自 FM 侧的建模选择（本例是按名合并
复制寄存器时两侧层次深度不同），而不是这一层的重写。

用法:
    python3 scripts/openllc_topology_diff.py            # 用默认路径
    python3 scripts/openllc_topology_diff.py <golden.sv> <impl.sv>
退出码 0 = 同构；1 = 有差异（差异逐条打印）。两个输入都只读。
"""
import os
import re
import sys

DEF_GOLDEN = os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical') + '/golden-rtl/OpenLLC.sv'
DEF_IMPL = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        'rtl/l2/OpenLLC.sv')

INST_START = re.compile(r'^  ([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\($')
INST_END = re.compile(r'^  \);')
PORT = re.compile(r'\.(\w+)\s*\(\s*([^()]*?)\s*\)', re.S)
DECL = re.compile(r'^\s*(?:wire|logic|reg)\s*(\[[^\]]*\])?\s*([A-Za-z_]\w*)\s*;', re.M)
ASSIGN = re.compile(r'^\s*assign\s+([A-Za-z_][\w\[\]:]*)\s*=\s*(.*?);\s*$', re.M | re.S)


def _nows(s):
    return re.sub(r'\s+', '', s)


def instances(path):
    """顶层（缩进两格）的实例 -> (模块类型, {端口: 连接网})。

    重写侧的 golden 同名 wrapper 只有一个 u_core 实例，调用方负责把它排除；
    这里不做特判，避免"脚本悄悄跳过了什么"。
    """
    lines = open(path).read().split('\n')
    out, i = {}, 0
    while i < len(lines):
        m = INST_START.match(lines[i])
        if m:
            typ, inst = m.groups()
            body, i = [], i + 1
            while i < len(lines) and not INST_END.match(lines[i]):
                body.append(lines[i])
                i += 1
            out[inst] = (typ, {p: _nows(n) for p, n in PORT.findall('\n'.join(body))})
        i += 1
    return out


def decls(path):
    return {m.group(2): _nows(m.group(1) or '[0:0]') for m in DECL.finditer(open(path).read())}


def assigns(path):
    return {m.group(1): _nows(m.group(2)) for m in ASSIGN.finditer(open(path).read())}


def main(golden, impl):
    bad = 0
    gi, ii = instances(golden), instances(impl)
    # 重写侧多出的 wrapper->core 实例不参与对比（golden 没有这一层），但要显式报出来。
    extra = sorted(set(ii) - set(gi))
    missing = sorted(set(gi) - set(ii))
    if missing:
        print('实例缺失（golden 有、impl 没有）: %s' % missing)
        bad = 1
    if extra:
        print('impl 侧多出的实例（应当只有 wrapper 的核实例）: %s' % extra)
    for inst in sorted(set(gi) & set(ii)):
        (gt, gd), (it, idd) = gi[inst], ii[inst]
        if gt != it:
            print('实例 %s 模块类型不同: golden=%s impl=%s' % (inst, gt, it))
            bad = 1
        for p in sorted(set(gd) ^ set(idd)):
            print('实例 %s 端口集合不同: %s (golden=%s impl=%s)'
                  % (inst, p, p in gd, p in idd))
            bad = 1
        for p in sorted(set(gd) & set(idd)):
            if gd[p] != idd[p]:
                print('实例 %s 端口绑定不同: .%s golden=%s impl=%s' % (inst, p, gd[p], idd[p]))
                bad = 1
        print('  实例 %-14s %-16s 端口 %d 条，绑定全同' % (inst, gt, len(gd)) if not bad else '', end='')
        if not bad:
            print()
    gdc, idc = decls(golden), decls(impl)
    for n in sorted(set(gdc) ^ set(idc)):
        print('网声明只在一侧: %s (golden=%s impl=%s)' % (n, n in gdc, n in idc))
        bad = 1
    for n in sorted(set(gdc) & set(idc)):
        if gdc[n] != idc[n]:
            print('网位宽不同: %s golden=%s impl=%s' % (n, gdc[n], idc[n]))
            bad = 1
    ga, ia = assigns(golden), assigns(impl)
    for n in sorted(set(ga) ^ set(ia)):
        print('assign 只在一侧: %s (golden=%s impl=%s)' % (n, n in ga, n in ia))
        bad = 1
    for n in sorted(set(ga) & set(ia)):
        if ga[n] != ia[n]:
            print('assign 右值不同: %s\n  golden: %s\n  impl  : %s' % (n, ga[n], ia[n]))
            bad = 1
    print('--- 汇总: 实例 %d 个 / 网声明 %d 条 / assign %d 条 ---' % (len(gi), len(gdc), len(ga)))
    print('结论: %s' % ('有差异' if bad else '顶层拓扑同构（实例/端口绑定/网声明/assign 四项全等）'))
    return bad


if __name__ == '__main__':
    a = sys.argv[1:]
    sys.exit(main(a[0] if a else DEF_GOLDEN, a[1] if len(a) > 1 else DEF_IMPL))
