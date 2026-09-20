#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_rob_iface.py —— 把 Rob 核的**接口契约**从 golden 机械算出来。

寄存器契约（docs/rob_core_contract.tsv）回答"核里要放哪些存储"。
这张表回答另外三个同样会出错、而且出错时**不报错**的问题：

1. **哪些 output 是核的义务，哪些不是。**
   667 个顶层 output 里有 20 个是某个子模块的输出脚**直接**驱动的
   （rab 的 logicPhyRegMap、vtypeBuffer 的 walkVType/commitVType、
   exceptionGen 的 readGPAMemAddr_bits）。核去驱动它们就是双驱动；
   核不驱动剩下的 647 个，产物就是 SCAFFOLD。这张表把这条线画死，
   gen_rob.py 的硬断言按它来判。

2. **868 个子模块引脚各自接的是什么。**
   不是每个引脚都接一根网：实测 576 个接顶层端口、271 根 wrapper 局部网、
   8 个接常量、★9 个悬空 `/* unused */`★、★4 个接表达式★。
   后两类被当成网处理过，长出 `n_/*` 和 `n_walkSizeSum[7:0]` 这种既非法
   又看着像正常记录的东西（见 gen_rob.py 的两次修复）。逐条入库，不许再糊。

3. **27 个写回口各自属于哪个子集。**
   Rob.scala 用 `io.exuWriteback.filter(...)` 切出 exuWBs / stdWBs /
   fflagsWBs / vxsatWBs / vldWBs / branchWBs，**Scala 源看不出下标**：
   它取决于 KunminghuV2Config。只有 golden 的端口表能告诉你。
   这里按"某个可选字段在不在"反推，并把下标集合逐条写出来。
   ★exceptionWBs 还多一层坑★：它在 io_writeback 的下标是
   {7,13,14,18..24}，而对应的 io_writebackNeedFlush 下标是
   {0,1,2,6,7,8,9,10,11,12} —— 两套编号，靠**位置**对齐，不靠名字。
   对错一位不会有任何工具响。

反向断言（CONVENTIONS「量到 0 和名字打错长得一模一样」那条）
------------------------------------------------------------
·  golden 的 2200 个端口必须**全部**落进分类，一个落不进就 rc≠0；
·  868 个子模块引脚同样必须全部落进分类；
·  每个写回下标都必须带 `valid`（缺了说明解析漏了半个端口族）；
·  每个子集的判定字段必须在 golden 里真的出现过 —— 打错一个字段名
   本来会安静地得到"这个子集是空的"，而空集合和真结论长得一模一样。
只问"我要的都找到了吗"不够，还要问"golden 里的都被我认出来了吗"。

★写这张表时被自己的反向断言否掉的一条假设，留在这里★：
原本断言"写回下标必须连续"，自测第一次跑就红了 —— io_writeback 的下标
真的是稀疏的 {1,3,5,7,13..24}：firtool 把 MixedVec 里整族没被用到的那几路
消掉了，剩下的**保持原编号**。io_exuWriteback 则是稠密的 0..26。
所以"连续"不是不变式。照下标当数组写会全错位，而且不会有工具响。

用法
  python3 scripts/gen_rob_iface.py --write
  python3 scripts/gen_rob_iface.py --check     # 幂等闸
  python3 scripts/gen_rob_iface.py --selftest  # 判据自测（含负例）
"""
import argparse
import collections
import hashlib
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_rob

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(REPO, 'docs', 'rob_iface_contract.tsv')

# 每个写回子集由「某个可选字段在不在」判定。字段名就是判据本身，写在这里而不是
# 藏在代码里，因为读表的人要能自己去 golden 里复核。
WB_SUBSETS = [
    # (子集名, 端口前缀, 判定字段, Rob.scala 里的来源)
    ('exuWBs',      'io_exuWriteback_', 'bits_debugInfo_writebackTime',
     'io.exuWriteback.filter(!_.bits.params.hasStdFu)'),
    ('fflagsWBs',   'io_exuWriteback_', 'bits_fflags',
     'io.exuWriteback.filter(x => x.bits.fflags.nonEmpty)'),
    ('vxsatWBs',    'io_exuWriteback_', 'bits_vxsat',
     'io.exuWriteback.filter(x => x.bits.vxsat.nonEmpty)'),
    ('vldWBs',      'io_exuWriteback_', 'bits_vls_vdIdx',
     'io.exuWriteback.filter(_.bits.params.hasVLoadFu)'),
    ('branchWBs',   'io_exuWriteback_', 'bits_redirect_bits_cfiUpdate_taken',
     'io.exuWriteback.filter(_.bits.params.hasBrhFu)'),
    ('exceptionWBs', 'io_writeback_',   'bits_exceptionVec_2',
     'io.writeback.filter(x => x.bits.exceptionVec.nonEmpty)'),
    ('redirectWBs', 'io_writeback_',    'bits_redirect_valid',
     'io.writeback.filter(x => x.bits.redirect.nonEmpty)'),
]


def _span(idxs):
    return '{%s}' % ','.join(map(str, idxs))


def port_index_fields(ports, prefix):
    """-> {idx: set(field)}；prefix 下的端口按下标聚。"""
    out = collections.defaultdict(set)
    pat = re.compile(re.escape(prefix) + r'(\d+)_(.*)$')
    for d, hi, lo, n in ports:
        m = pat.match(n)
        if m:
            out[int(m.group(1))].add(m.group(2))
    return out


def every_index_has_valid(pool, what):
    """每个出现过的下标都必须有 `valid` —— 没有就是解析漏了半个端口族。

    ★这里原本写的是"下标必须连续"，自测第一次跑就把它否掉了★：
    io_writeback 的下标真的是稀疏的 {1,3,5,7,13..24} —— firtool 把
    MixedVec 里没被用到的那几路整族消掉了，剩下的下标保持原编号。
    io_exuWriteback 则是稠密的 0..26。所以"连续"不是不变式，
    "每个下标都带 valid" 才是。稀疏与否本身作为**数据**记进表里，不作判据。
    """
    bad = sorted(i for i, f in pool.items() if 'valid' not in f)
    if bad:
        raise SystemExit('gen_rob_iface: %s 的下标 %s 有字段却没有 valid —— '
                         '解析漏了东西' % (what, bad))
    idxs = sorted(pool)
    return idxs, (idxs == list(range(len(idxs))))


def build():
    text, lines = gen_rob.load_golden(GOLDEN)
    ports, hdr_end = gen_rob.parse_ports(lines)
    children = gen_rob.parse_children(lines, hdr_end)
    portnames = {p[3] for p in ports}
    gdir = os.path.dirname(os.path.abspath(GOLDEN))

    # ---- 1. 每个顶层端口的归属 ----------------------------------------
    child_driven = {}          # top output -> (inst, pin)
    child_fed = collections.defaultdict(list)   # top input -> [(inst, pin)]
    for ctype, inst, pins in children:
        couts = gen_rob.child_output_pins(gdir, ctype)
        for pin, net in pins:
            if net not in portnames:
                continue
            if pin in couts:
                if net in child_driven:
                    raise SystemExit('gen_rob_iface: 顶层 output %r 被两个子模块驱动'
                                     % net)
                child_driven[net] = (inst, pin)
            else:
                child_fed[net].append((inst, pin))

    rows = []
    n_core_out = n_child_out = 0
    for d, hi, lo, n in ports:
        w = 1 if hi is None else hi - lo + 1
        if n in ('clock', 'reset'):
            owner, note = 'CLOCK', '-'
        elif d == 'output':
            if n in child_driven:
                owner = 'CHILD_DRIVES'
                note = '%s.%s' % child_driven[n]
                n_child_out += 1
            else:
                owner, note = 'CORE_DRIVES', '-'
                n_core_out += 1
        else:
            if n in child_fed:
                owner = 'INPUT_ALSO_TO_CHILD'
                note = ','.join('%s.%s' % x for x in sorted(child_fed[n]))
            else:
                owner, note = 'INPUT_CORE_ONLY', '-'
        rows.append('PORT\t%s\t%s\t%d\t%s\t%s' % (n, d, w, owner, note))

    # ★反向断言★：端口一个不许漏
    if len(rows) != len(ports):
        raise SystemExit('gen_rob_iface: 端口行数 %d != 端口数 %d'
                         % (len(rows), len(ports)))

    # ---- 2. 868 个子模块引脚的接法 ------------------------------------
    pin_rows = []
    kinds = collections.Counter()
    for ctype, inst, pins in children:
        couts = gen_rob.child_output_pins(gdir, ctype)
        for pin, net in pins:
            kind, nm = gen_rob.classify(net, portnames, inst, pin)
            kinds[kind] += 1
            pin_rows.append('PIN\t%s\t%s\t%s\t%s\t%s\t%s'
                            % (inst, ctype, pin,
                               'out' if pin in couts else 'in',
                               kind, nm if kind != 'const' else net))
    total_pins = sum(len(p) for _, _, p in children)
    if len(pin_rows) != total_pins:
        raise SystemExit('gen_rob_iface: 引脚行数 %d != 引脚数 %d'
                         % (len(pin_rows), total_pins))

    # ---- 3. 写回子集 --------------------------------------------------
    exu = port_index_fields(ports, 'io_exuWriteback_')
    wb = port_index_fields(ports, 'io_writeback_')
    exu_idx, exu_dense = every_index_has_valid(exu, 'io_exuWriteback')
    wb_idx, wb_dense = every_index_has_valid(wb, 'io_writeback')
    sub_rows = []
    members = {}
    for name, prefix, probe, src in WB_SUBSETS:
        pool = exu if prefix == 'io_exuWriteback_' else wb
        idxs = sorted(i for i, f in pool.items() if probe in f)
        if not idxs:
            raise SystemExit('gen_rob_iface: 子集 %s 的判定字段 %r 在 golden 里'
                             '一个都没有 —— 名字打错了，不是"这个子集是空的"'
                             % (name, probe))
        members[name] = idxs
        sub_rows.append('WBSUBSET\t%s\t%s\t%d\t%s\t%s\t%s'
                        % (name, prefix.rstrip('_'), len(idxs),
                           ','.join(map(str, idxs)), probe, src))
    # stdWBs = exuWriteback 里不属于 exuWBs 的那些（Rob.scala 是按 hasStdFu 切的）
    std = sorted(set(exu) - set(members['exuWBs']))
    members['stdWBs'] = std
    sub_rows.append('WBSUBSET\tstdWBs\tio_exuWriteback\t%d\t%s\t%s\t%s'
                    % (len(std), ','.join(map(str, std)),
                       '(exuWriteback 全集减去 exuWBs)',
                       'io.exuWriteback.filter(_.bits.params.hasStdFu)'))
    if set(members['exuWBs']) | set(std) != set(exu):
        raise SystemExit('gen_rob_iface: exuWBs + stdWBs 没覆盖全部 exuWriteback')

    # exceptionWBs <-> io_writebackNeedFlush 的位置对齐
    nf = sorted(int(m.group(1)) for m in
                (re.match(r'io_writebackNeedFlush_(\d+)$', p[3]) for p in ports)
                if m)
    if len(nf) != len(members['exceptionWBs']):
        raise SystemExit(
            'gen_rob_iface: io_writebackNeedFlush 有 %d 个，exceptionWBs 有 %d 个 —— '
            '两者必须等长（Rob.scala 里 require(exceptionWBs.length == '
            'exceptionGen.io.wb.length)）' % (len(nf), len(members['exceptionWBs'])))
    pair_rows = []
    for k, (e, f) in enumerate(zip(members['exceptionWBs'], nf)):
        pair_rows.append('EXCPWB\t%d\tio_writeback_%d\tio_writebackNeedFlush_%d'
                         % (k, e, f))

    hdr = [
        '# gen_rob_iface.py 生成，勿手改。重跑：python3 scripts/gen_rob_iface.py --write',
        '# golden %s' % GOLDEN,
        '# golden sha256 %s' % hashlib.sha256(text.encode()).hexdigest(),
        '# 顶层端口 %d（output %d：核驱动 %d / 子模块直接驱动 %d）'
        % (len(ports), n_core_out + n_child_out, n_core_out, n_child_out),
        '# 子模块引脚 %d，接法分布 %s'
        % (total_pins, ' '.join('%s=%d' % kv for kv in sorted(kinds.items()))),
        '# io_exuWriteback 下标 %s（%s）；io_writeback 下标 %s（%s）'
        % (_span(exu_idx), '稠密' if exu_dense else '★稀疏★',
           _span(wb_idx), '稠密' if wb_dense else '★稀疏★'),
        '#   io_writeback 的稀疏是真的：firtool 把 MixedVec 里整族没用到的那几路'
        '消掉了，剩下的保持原编号。照下标当数组写会全错位。',
        '# PORT   端口名 / 方向 / 位宽 / 归属 / 备注',
        '#        CORE_DRIVES         核必须驱动（少一个就是 SCAFFOLD）',
        '#        CHILD_DRIVES        子模块输出脚直接驱动，核不许碰（会双驱动）',
        '#        INPUT_ALSO_TO_CHILD 顶层输入，同时接到列出的子模块引脚',
        '#        INPUT_CORE_ONLY     顶层输入，没接任何子模块',
        '# PIN    实例 / 类型 / 引脚 / 方向 / 接法 / 线名或常量',
        '#        接法 port=接顶层端口 net=wrapper 局部网 const=常量',
        '#              unused=悬空（firtool 写成 /* unused */，不是网）',
        '#              expr=接表达式（不是网，核里给一根按引脚命名的线）',
        '# WBSUBSET 子集名 / 端口族 / 个数 / 下标集合 / 判定字段 / Rob.scala 来源',
        '#        ★下标只有 golden 能告诉你★：它由 KunminghuV2Config 决定，'
        'Scala 源里看不出来。',
        '# EXCPWB  第 k 个 exceptionWB 的两套编号对齐（靠位置，不靠名字）',
        'kind\tf1\tf2\tf3\tf4\tf5\tf6',
    ]
    return '\n'.join(hdr + rows + pin_rows + sub_rows + pair_rows) + '\n'


def selftest():
    """判据自测：正例 + 三个负例。负例都必须**红**，否则上面的断言是空转。"""
    ok = True

    def say(tag, good, why):
        nonlocal ok
        ok = ok and good
        print('  %-28s %-5s %s' % (tag, 'ok' if good else 'FAIL', why))

    text = build()
    say('positive', 'WBSUBSET\texuWBs' in text and 'PIN\t' in text,
        '正例能算出来，且三段都在')
    # 负例 1：判定字段名打错 -> 必须报"名字打错"，不是安静地给出空集合
    saved = list(WB_SUBSETS)
    try:
        WB_SUBSETS[:] = [('bogus', 'io_exuWriteback_', 'bits_no_such_field', '-')]
        try:
            build()
            say('bad_probe_name', False, '★没抓到：字段名打错被当成空子集★')
        except SystemExit as e:
            say('bad_probe_name', '打错了' in str(e), str(e)[:70])
    finally:
        WB_SUBSETS[:] = saved
    # 负例 2：有字段却没有 valid 的下标必须报错
    try:
        every_index_has_valid({0: {'valid'}, 2: {'bits_x'}}, 'demo')
        say('index_without_valid', False, '★没抓到：半个端口族照过★')
    except SystemExit as e:
        say('index_without_valid', '没有 valid' in str(e), str(e)[:70])
    # 负例 3（元负例）：把 classify 换成"什么都算 net"，PIN 段的分布必须变，
    # 证明那一段不是写死的常量。
    real = gen_rob.classify
    try:
        gen_rob.classify = lambda net, pn, inst=None, pin=None: ('net', 'n_x')
        blanket = build()
        say('meta_blanket', 'unused=9' not in blanket,
            '换掉 classify 后 PIN 分布确实变了（那一段不是写死的）')
    finally:
        gen_rob.classify = real
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--write', action='store_true')
    g.add_argument('--check', action='store_true')
    g.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        print('gen_rob_iface --selftest:')
        return selftest()
    text = build()
    if a.check:
        if not os.path.exists(TARGET):
            print('FAIL: %s 不存在' % TARGET)
            return 1
        with open(TARGET) as f:
            if f.read() != text:
                print('FAIL: %s 与重算结果不一致（DRIFT）' % TARGET)
                return 1
        print('gen_rob_iface --check: 逐字节一致')
        return 0
    with open(TARGET, 'w') as f:
        f.write(text)
    print('gen_rob_iface: 已写 %s（%d 行）' % (TARGET, text.count('\n')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
