#!/usr/bin/env python3
"""rob_deqgroup_blast.py -- 量一件事：把 robDeqGroup 这一族留空，核还能驱动多少输出？

背景
----
Rob 的重写被拆成"先写 12 族、robDeqGroup 等裁定"。等裁定的其实只是该族 45 个字段
里的 7 个（`debug_otherPdest_0..6`，56 个寄存器 / 448 bit / 56 个输出端口 ——
见 evidence/rob-selfcompare-4aa8838b/README.md 的 2026-09-20 附注）。
问题是：robDeqGroup 是**提交读口**（`commitInfo(i) = robDeqGroup(deqPtr(i)[2:0])`），
整条提交/异常/冲刷路径都从它出来。所以"留空一族"和"留空 7 个字段"代价差着数量级，
而这个差距不能靠印象判断，要量。

这个脚本就量这个：从 golden 出发做**传导染色**（组合网 + 寄存器次态），
算出有多少输出端口在 robDeqGroup 的下游。只读 golden，不产 RTL、不改任何文件。

用法
  python3 scripts/rob_deqgroup_blast.py            # 打印结论
  python3 scripts/rob_deqgroup_blast.py --list     # 连"仍可写"的输出清单一起打印
  python3 scripts/rob_deqgroup_blast.py --selftest # 两个坑的回归（不需要 golden 外的东西）

★两个会让这个数**偏小**且不报错的坑，都在这里踩过★
------------------------------------------------------
(1) **多维 packed wire**。firtool 写 `wire [7:0][6:0] _GEN_8 = {...};`
    —— 两个方括号。只允许一个方括号的驱动式正则会**静默漏掉**这一条，
    于是 `_GEN_8` 没有驱动式，染色在这里断掉。实测差别：
    517/667（正确）对 325/667（漏掉多维 wire）。两个数都"看着合理"。
(2) **折行的 if 头**。寄存器次态要从 always 块的语句树里取，而 firtool 会把长
    if 条件折行；分词器若按"累到分号为止"合并，条件头会和它的单语句体粘成一个
    token，整棵树错位（见 scripts/test_rob_fold_probe.py）。本脚本复用修好的
    rob_fold_probe，不自己再写一遍分词。
"""
import argparse, collections, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rob_fold_probe as fold

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')

# ★多个方括号★ -- 见文件头 (1)。`(?:\[[^\]]*\]\s*)*` 而不是 `(?:\[[^\]]*\])?`。
DRIVER = re.compile(
    r'^\s*(?:assign\s+|wire\s*(?:\[[^\]]*\]\s*)*)(\w+)\s*=\s*((?:[^;]|\n)*?);\s*$',
    re.M)
IDENT = re.compile(r'\b[A-Za-z_]\w*\b')


def ports(lines):
    s = next(i for i, l in enumerate(lines) if l.startswith('module Rob('))
    e = next(i for i in range(s, len(lines)) if lines[i].strip() == ');')
    out = {}
    for l in lines[s:e + 1]:
        m = re.match(r'\s*(input|output)\s+(?:wire\s+)?'
                     r'(?:\[\s*\d+\s*:\s*\d+\s*\])?\s*(\w+)', l)
        if m:
            out[m.group(2)] = m.group(1)
    return out


def child_driven(text, P):
    """输出端口里**不由 body 里的 assign 驱动**的那些。

    firtool 的输出端口一律用 `assign` 驱动（寄存器先写进内部 reg 再 assign 出去）。
    所以"body 里没有 assign 的输出" == "直接接在某个子模块输出引脚上"。
    这比"去每个子模块 golden 文件里查哪些引脚是 output"准：后者需要
    每个子模块都有 .sv 文件，而 dt_pcTransType_160x2 这种存储宏没有，
    当时它把 34 算成了 20。
    """
    driven = set()
    for m in re.finditer(r'^\s*assign\s+(\w+)\s*=', text, re.M):
        driven.add(m.group(1))
    return {n for n, d in P.items() if d == 'output' and n not in driven}


def analyse(golden, seed_re=r'\brobDeqGroup_\d+_\w+\b'):
    text = open(golden).read()
    lines = text.split('\n')
    P = ports(lines)
    drv = {m.group(1): m.group(2) for m in DRIVER.finditer(text)}
    seed = set(re.findall(seed_re, text))

    edges = collections.defaultdict(set)
    for blk in ('noreset', 'reset'):
        tree, _regs, _span = fold.load_tree(golden, blk)

        def walk(nodes, cond):
            for n in nodes:
                if n[0] == 'asg':
                    edges[n[1]] |= set(IDENT.findall(n[2])) | cond
                else:
                    c = cond | set(IDENT.findall(n[1]))
                    walk(n[2], c)
                    walk(n[3], c)
        walk(tree, set())

    t = set(seed)
    for _ in range(64):
        before = len(t)
        changed = True
        while changed:
            changed = False
            for n, ex in drv.items():
                if n not in t and (set(IDENT.findall(ex)) & t):
                    t.add(n)
                    changed = True
        for r, src in edges.items():
            if r not in t and (src & t):
                t.add(r)
        if len(t) == before:
            break

    outs = [n for n in P if P[n] == 'output']
    cd = child_driven(text, P)
    return {
        'drivers': len(drv), 'regs_with_edges': len(edges),
        'seed': len(seed), 'outputs': outs, 'tainted': t,
        'child_driven': cd & set(outs),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()

    r = analyse(a.golden)
    outs, t, cd = r['outputs'], r['tainted'], r['child_driven']
    hit = [n for n in outs if n in t]
    miss = [n for n in outs if n not in t]
    core_outs = [n for n in outs if n not in cd]
    core_writable = [n for n in core_outs if n not in t]
    print('golden               %s' % a.golden)
    print('drivers captured     %d  (assign + wire-with-init, multi-dim packed included)'
          % r['drivers'])
    print('registers w/ edges   %d' % r['regs_with_edges'])
    print('robDeqGroup seeds    %d registers' % r['seed'])
    print('')
    print('output ports                       %d' % len(outs))
    print('  driven straight from a child     %d  (not the core\'s obligation)' % len(cd))
    print('  the core must drive              %d' % len(core_outs))
    print('')
    print('downstream of robDeqGroup          %d of %d outputs (%.0f%%)'
          % (len(hit), len(outs), 100.0 * len(hit) / len(outs)))
    print('core outputs still writable        %d of %d (%.0f%%)'
          % (len(core_writable), len(core_outs),
             100.0 * len(core_writable) / len(core_outs)))
    print('')
    print('=> 把 robDeqGroup 整族留空，核只能驱动 %d/%d 个输出。'
          % (len(core_writable), len(core_outs)))
    print('   而真正等裁定的只有 debug_otherPdest_0..6 = 56 个寄存器 / 56 个输出端口。')
    # 对照组：只留空真正等裁定的那 7 个字段（debug_otherPdest_0..6）。
    # 这才是"未定设计选择"的真实射程；两个数放一起看才有意义。
    rn = analyse(a.golden, r'\brobDeqGroup_\d+_debug_otherPdest_\d+\b')
    n_core = [n for n in rn['outputs'] if n not in cd]
    n_writable = [n for n in n_core if n not in rn['tainted']]
    print('')
    print('对照：只留空 debug_otherPdest_0..6（%d 个寄存器）' % rn['seed'])
    print('  核可驱动输出                     %d of %d (%.0f%%)'
          % (len(n_writable), len(n_core), 100.0 * len(n_writable) / len(n_core)))
    print('  两者差距                         %d 个输出端口'
          % (len(n_writable) - len(core_writable)))
    if a.list:
        print('')
        c = collections.Counter(
            '_'.join(x for x in n.split('_') if not x.isdigit())
            for n in core_writable)
        for k, v in sorted(c.items(), key=lambda x: -x[1]):
            print('   writable  %-52s x%d' % (k, v))
    return 0


def selftest():
    """两条判据 + 各自的反测。不碰 golden 之外的东西。"""
    rows = []
    multi = "  wire [7:0][6:0]    _GEN_8 =\n    {robDeqGroup_7_realDestSize};\n"
    got = {m.group(1) for m in DRIVER.finditer(multi)}
    rows.append(('multidim_wire', got == {'_GEN_8'},
                 'wire [7:0][6:0] NAME = ... is captured as a driver'))
    narrow = re.compile(
        r'^\s*(?:assign\s+|wire\s*(?:\[[^\]]*\])?\s*)(\w+)\s*=\s*'
        r'((?:[^;]|\n)*?);\s*$', re.M)
    rows.append(('multidim_wire_NEG', not {m.group(1) for m in narrow.finditer(multi)},
                 'the single-bracket regex MISSES it -- that is the trap'))
    plain = "  assign io_x = _GEN_8[y];\n"
    rows.append(('plain_assign', {m.group(1) for m in DRIVER.finditer(plain)} == {'io_x'},
                 'ordinary assign still captured'))
    ok = all(g for _, g, _ in rows)
    for n, g, w in rows:
        print('%-20s %-5s %s' % (n, 'OK' if g else 'FAIL', w))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
