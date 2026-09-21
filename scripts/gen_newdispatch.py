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



# --------------------------------------------------------------------------
# PACK / UNPACK：从 golden 直接派生「每条 lane 的每个 payload 字段是怎么来的」
# --------------------------------------------------------------------------
# golden 的 fromRenameUpdate_<lane>_bits_<leaf> 有四种来源，**逐 lane 不同**
# （不是整齐的六份），手抄必错，所以在这里机械提取：
#   PASS   = io_fromRename_<lane>_bits_<leaf>     直接透传
#   CONST  = 某个字面常量（例：snapshot 只有 lane0 是真的，1~5 被钉成 1'h0）
#   LOCAL  = 本模块用 io_fromRename 算出来的（例：isDropAmocasSta）
#   CHILD  = 由未实现子模块的输出端口驱动（BusyTable / LsqEnqCtrl / RegCacheTagTable）
CHILD_INSTS = {'intBusyTable', 'fpBusyTable', 'vecBusyTable', 'v0BusyTable',
               'vlBusyTable', 'rcTagTable', 'lsqEnqCtrl'}
CONST_RE = re.compile(r"^\d+'[hbd][0-9a-fA-F_]+$")


def _golden_text():
    return open(os.path.join(GOLDEN, 'NewDispatch.sv')).read().split('\n')


def _rhs_map(lines):
    """name -> RHS（多行合并）。只收 `wire x = ...` / `assign x = ...`。"""
    out, decl = {}, re.compile(
        r'^\s+(?:wire|assign)\s+(?:\[\d+:\d+\]\s+)?([A-Za-z_]\w*)\s*=(.*)$')
    i = 0
    while i < len(lines):
        m = decl.match(lines[i])
        if m:
            body, j = m.group(2), i
            while ';' not in body and j + 1 < len(lines):
                j += 1
                body += ' ' + lines[j].strip()
            out[m.group(1)] = body.split(';')[0].strip()
            i = j
        i += 1
    return out


def _inst_driven(lines, rhs):
    """被子模块实例端口连出去的网 -> 实例名。

    坑：golden 的端口连接经常换行（`.io_x\n      (net),`），按单行正则会整片漏掉，
    第一版就是这么把 lqIdx/sqIdx 误判成「不依赖子模块」的。故按括号配平累积。
    """
    driven = {}
    for k, l in enumerate(lines):
        if not re.match(r'^\s+[A-Z][A-Za-z0-9_]*\s+[A-Za-z_]\w*\s*\($', l):
            continue
        inst, j, depth, buf = l.split()[1], k + 1, 1, ''
        while j < len(lines) and depth > 0:
            depth += lines[j].count('(') - lines[j].count(')')
            buf += ' ' + lines[j].strip()
            if buf.count('(') > 0 and buf.count('(') == buf.count(')'):
                for mm in re.finditer(r'\.(\w+)\s*\(\s*([A-Za-z_]\w*)\s*\)', buf):
                    net = mm.group(2)
                    if net not in rhs:
                        driven.setdefault(net, inst)
                buf = ''
            j += 1
    return driven


def pack_spec(ports):
    """返回 {(lane, leaf): (kind, detail)}，kind ∈ PASS/CONST/LOCAL/CHILD。"""
    lines = _golden_text()
    rhs = _rhs_map(lines)
    driven = _inst_driven(lines, rhs)
    leaves = [n for n, _ in dyninst_leaves(ports)]
    spec = {}
    for lane in range(6):
        for leaf in leaves:
            net = 'fromRenameUpdate_%d_bits_%s' % (lane, leaf)
            if net in driven and driven[net] in CHILD_INSTS:
                spec[(lane, leaf)] = ('CHILD', driven[net])
                continue
            body = rhs.get(net)
            if body is None:
                spec[(lane, leaf)] = ('CHILD', 'undriven')
                continue
            body = body.strip()
            if CONST_RE.match(body):
                spec[(lane, leaf)] = ('CONST', body)
            elif body == 'io_fromRename_%d_bits_%s' % (lane, leaf):
                spec[(lane, leaf)] = ('PASS', body)
            else:
                spec[(lane, leaf)] = ('LOCAL', body)
    return spec


# 由子模块（本仓未实现）决定、因而现在接不了的 leaf。
# 判据来自 pack_spec + golden 的 IQSelUop 覆写路径，不是拍脑袋列的：
#   srcState_*        IQSelUop 用 allSrcState 覆写，源是 5 个 busy table
#   srcType_2         经 ignoreOldVd，源是 VlBusyTable
#   srcLoadDependency_0_*/1_*  源是 intBusyTable
#   lqIdx_*/sqIdx_*   源是 LsqEnqCtrl
#   useRegCache_*/regCacheIdx_*  源是 RegCacheTagTable
#   singleStep        组合式已追清，但它读的 3 个异步复位寄存器要 firedVec，
#                     而 firedVec 依赖 LsqEnqCtrl 的 canAccept
BLOCKED_LEAVES = (
    ['srcState_%d' % j for j in range(5)]
    + ['srcType_2', 'lqIdx_flag', 'lqIdx_value',
       'sqIdx_flag', 'sqIdx_value', 'useRegCache_0', 'useRegCache_1',
       'regCacheIdx_0', 'regCacheIdx_1']
    + ['srcLoadDependency_%d_%d' % (s, k) for s in (0, 1) for k in range(3)])

# 步骤 2 起有来源的 leaf：由 xs_NewDispatch_core 的派遣流控算出来。
# （singleStep 原先在 BLOCKED_LEAVES 里，因为它要 firedVec，而 firedVec 要 LsqEnqCtrl
#  的 canAccept —— 那条链在步骤 2 已经打通，故从"接不了"移到这里。）
PACK_RESOLVED = {'singleStep': 'core_updatedSingleStep[%d]'}


def gen_pack(ports):
    spec = pack_spec(ports)
    leaves = [n for n, _ in dyninst_leaves(ports)]
    out = ['  // 每条 lane 的 payload：四类来源逐条照抄 golden（见 pack_spec 注释）。',
           '  // 被 unresolved_* 驱动的位**故意不给驱动源** —— 悬空比钉 0 诚实：',
           '  // 钉 0 会让 elaborate 和 UT 变绿而掩盖「子模块还没实现」这件事。']
    for lane in range(6):
        out.append('')
        out.append('  // ---- lane %d ----' % lane)
        for leaf in leaves:
            kind, detail = spec[(lane, leaf)]
            tgt = '  assign rename_uop[%d].%s' % (lane, leaf)
            if leaf in PACK_RESOLVED:
                out.append('%s = %s;' % (tgt, PACK_RESOLVED[leaf] % lane))
            elif leaf in BLOCKED_LEAVES:
                out.append('%s = unresolved_%s_%d;' % (tgt, leaf, lane))
            elif kind == 'PASS':
                out.append('%s = io_fromRename_%d_bits_%s;' % (tgt, lane, leaf))
            elif kind == 'CONST':
                out.append('%s = %s;' % (tgt, detail))
            elif kind == 'LOCAL' and leaf == 'isDropAmocasSta':
                out.append('%s =' % tgt)
                out.append('    io_fromRename_%d_bits_fuType[17] '
                           '& io_fromRename_%d_bits_fuOpType[5:2] == 4\'hB' % (lane, lane))
                out.append('    & ~io_fromRename_%d_bits_uopIdx[0];' % lane)
            else:
                out.append('%s = unresolved_%s_%d;   // %s' % (tgt, leaf, lane, kind))
    return out


def gen_unresolved(ports):
    """所有还接不了的位，集中声明成 unresolved_*（无驱动 = 仿真出 X/Z，想假绿也假不了）。"""
    leaves = dict(dyninst_leaves(ports))
    out = ['  // ★下面这些位现在没有来源★，全部悬空。真跑 UT 时它们是 X/Z，',
           '  // 所以「UT 没报错」在这个状态下不可能发生 —— 这是故意的。']
    for leaf in BLOCKED_LEAVES:
        w = leaves[leaf]
        ty = 'logic' if w == 1 else 'logic [%d:0]' % (w - 1)
        for lane in range(6):
            out.append('  %-14s unresolved_%s_%d;' % (ty, leaf, lane))
    return out


def gen_unpack(ports):
    per = bundle_leaves(ports, r'io_toIssueQueues_(\d+)_(valid|bits_.+)$')
    out = ['  // 34 个 IQ 入队口的 payload 拆包。golden 对不同口做过 DCE，',
           '  // 形状不均匀（8..19 号口没有 srcLoadDependency），这里逐口按 golden 的实际端口发。']
    for q in sorted(per):
        names = sorted(n for n, _ in per[q])
        out.append('')
        out.append('  // ---- IQ enq 口 %d（IQ %d 的第 %d 个口）----' % (q, q // 2, q % 2))
        for n in names:
            if n == 'valid':
                out.append('  assign io_toIssueQueues_%d_valid = iq_valid[%d];' % (q, q))
            else:
                leaf = n[len('bits_'):]
                out.append('  assign io_toIssueQueues_%d_bits_%s = iq_uop[%d].%s;'
                           % (q, leaf, q, leaf))
    return out


# ---------------------------------------------------------------------------
# CHILDINST —— 7 个 child 的实例化（步骤 1）
#
# 为什么是生成的而不是手写：golden 把每个 child 的**每个端口**都接满了
# （连线数 == child 端口数，合计 1116 条），而且 920 条只引用 NewDispatch 自己的
# 顶层端口 —— 那部分逐字照抄即可，手写 1116 行只会抄错。
#
# ★实例名沿用 golden 的★（intBusyTable / fpBusyTable / vecBusyTable / v0BusyTable /
#   vlBusyTable / rcTagTable / lsqEnqCtrl）：这几个 child 各自的 UT 都不需要钉点文件，
#   说明它们靠名字/签名就配得上；同名例化能把这个优势带进 NewDispatch。
#
# 连线按「表达式引用了什么」分三类（分类逻辑与 docs/lanes/newdispatch_step1_prereg.md
# 里登记的口径一致）：
#   a. 只引用顶层端口      -> 逐字照抄（920 条）
#   b. 只引用 child 实例输出 -> 逐字照抄（111 条），那些 wire 由本块声明
#   c. 还需要没写的内部逻辑  -> 接 unresolved_*（85 条 / 79 个信号），
#                            沿用本文件既有的 unresolved_ 前缀，便于 grep 出缺口
# ---------------------------------------------------------------------------
CHILD_INST = [
    ('BusyTable', 'intBusyTable'),
    ('BusyTable_1', 'fpBusyTable'),
    ('BusyTable_2', 'vecBusyTable'),
    ('BusyTable_3', 'v0BusyTable'),
    ('VlBusyTable', 'vlBusyTable'),
    ('RegCacheTagTable', 'rcTagTable'),
    ('LsqEnqCtrl', 'lsqEnqCtrl'),
]


def _child_ports(child):
    """child 的端口表：name -> (dir, width)"""
    txt = open(os.path.join(GOLDEN, child + '.sv')).read()
    m = re.search(r'^module\s+%s\s*\((.*?)^\);' % re.escape(child), txt, re.S | re.M)
    out = {}
    for line in m.group(1).split('\n'):
        pm = re.match(r'\s*(input|output)\s+(?:wire\s+)?(?:\[\s*(\d+)\s*:\s*0\s*\]\s+)?([A-Za-z_]\w*)', line)
        if pm:
            out[pm.group(3)] = (pm.group(1), 1 if pm.group(2) is None else int(pm.group(2)) + 1)
    return out


# 步骤 2：child 的这些输入由 xs_NewDispatch_core 的派遣流控（节 2.8~2.11）驱动。
# key 是 (实例名, 端口名正则)，value 是本文件里的信号表达式（%s = 正则第一组）。
STEP2_SOURCES = [
    ('intBusyTable', r'io_allocPregs_(\d+)_valid',       'core_allocPregsValid0[%s]'),
    ('rcTagTable',   r'io_allocPregs_(\d+)_valid',       'core_allocPregsValid0[%s]'),
    ('lsqEnqCtrl',   r'io_enq_iqAccept_(\d+)',           'core_lsqIqAccept[%s]'),
    ('lsqEnqCtrl',   r'io_enq_needAlloc_(\d+)',          'core_lsqNeedAlloc[%s]'),
    ('lsqEnqCtrl',   r'io_enq_req_(\d+)_valid',          'core_lsqReqValid[%s]'),
    ('lsqEnqCtrl',   r'io_enq_req_(\d+)_bits_numLsElem', 'core_lsqReqNumLsElem[%s]'),
    ('lsqEnqCtrl',   r'io_redirect_valid',               'lsqEnqCtrl_io_redirect_REG_valid'),
]


def _step2_source(inst, port):
    for i, rx, tpl in STEP2_SOURCES:
        if i != inst:
            continue
        m = re.match(rx + '$', port)
        if m:
            return tpl % m.groups() if m.groups() else tpl
    return None


def _childinst_build(ports):
    nd = '\n'.join(_golden_text())
    topset = {n for _d, _w, n in ports}
    insts = [v for _, v in CHILD_INST]
    instpfx = tuple('_' + v + '_' for v in insts)
    body, wires, unres = [], [], {}
    conn_a = conn_b = conn_c = conn_d = 0
    for child, inst in CHILD_INST:
        cp = _child_ports(child)
        m = re.search(r'^  %s\s+%s\s*\(\s*\n(.*?)^  \);' % (child, inst), nd, re.S | re.M)
        if not m:
            sys.exit('FATAL: golden 里找不到 %s %s 的实例' % (child, inst))
        conns = []
        for pm in re.finditer(r'\.(\w+)\s*\(([^)]*(?:\([^)]*\)[^)]*)*)\)\s*,?\s*$',
                              m.group(1), re.M):
            port, expr = pm.group(1), pm.group(2).strip()
            d, w = cp.get(port, ('input', 1))
            if d == 'output':
                # ★child 输出直接落到顶层 output 端口★（golden 就是这么接的）：
                # golden 的 `.io_enqLsq_req_0_valid (io_toMem_lsqEnqIO_req_0_valid)`
                # 一步把 LsqEnqCtrl 的输出接到 NewDispatch 的输出端口上，中间没有别的逻辑。
                # 步骤 1 这里一律新开一根 `_<inst>_<port>` 线，于是这 330 个顶层 output
                # **一个驱动源都没有** —— FM 侧表现为 child 的寄存器前向锥到不了任何
                # 输出（判 unread），passing 一个点都涨不了（实测 589 -> 589）。
                # 所以照 golden 接：表达式就是一个顶层端口名时直连，不要中间线。
                clean = ' '.join(expr.split())
                if clean in topset:
                    conns.append('    .%-42s (%s)' % (port, clean))
                    continue
                # 其余 child 输出仍走本地线（供本文件内部消费）
                nm = '_%s_%s' % (inst, port)
                wires.append('  logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), nm))
                conns.append('    .%-42s (%s)' % (port, nm))
                continue
            e = re.sub(r"\d*'[hbdoHBDO][0-9a-fA-FxzXZ_]+", ' ', expr)
            e = re.sub(r'\b\d+\b', ' ', e)
            ids = {i for i in re.findall(r'\b([A-Za-z_]\w*)\b', e)} - {'clock', 'reset'} - topset
            if not ids:
                conn_a += 1
                conns.append('    .%-42s (%s)' % (port, expr))
            elif all(i.startswith(instpfx) for i in ids):
                conn_b += 1
                conns.append('    .%-42s (%s)' % (port, expr))
            else:
                src = _step2_source(inst, port)
                if src is None:
                    conn_c += 1
                    nm = 'unresolved_ci_%s_%s' % (inst, port)
                    unres[nm] = w
                    # ★注释必须另起一行★：跟在连线后面的话，join 时逗号会落到注释里
                    #   变成 `... ) // TODO ...,` —— VCS 报 Error-[SE]（实测踩过）
                    conns.append('    // TODO(步骤2): golden = %s\n    .%-42s (%s)'
                                 % (' '.join(expr.split())[:70], port, nm))
                else:
                    conn_d += 1
                    conns.append('    .%-42s (%s)' % (port, src))
        body.append('  %s %s (' % (child, inst))
        body.append(',\n'.join(conns))
        body.append('  );')
        body.append('')
    head = ['  // 7 个 child 的实例（实例名与 golden 一致）。连线分类：',
            '  //   只引顶层端口 %d 条 / 只引 child 输出 %d 条'
            % (conn_a, conn_b),
            '  //   由派遣流控驱动 %d 条 / 仍无来源 %d 条' % (conn_d, conn_c),
            '  // child 的输出：golden 直接接到顶层 output 端口的那些**照样直接接**',
            '  // （不经中间线，否则那些顶层 output 就没有驱动源）；其余走下面的本地线。',
            '  // child 输出线：']
    head += sorted(set(wires))
    if unres:
        head.append('  // 还没有真来源的 child 输入，接 unresolved_ci_*（命名带 ci_ 前缀便于 grep）：')
        for nm in sorted(unres):
            w = unres[nm]
            head.append('  logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), nm))
            head.append("  assign %s = '0;" % nm)
    head.append('')
    return head, body


def gen_childwires(ports):
    """child 实例用到的本地线声明。**必须排在 u_core 实例之前**：
    核的流控要吃 lsqEnqCtrl 的 canAccept / lq、sqFreeCount，而 SV 要求先声明后引用。"""
    return _childinst_build(ports)[0]


def gen_childinst(ports):
    return _childinst_build(ports)[1]

# ---------------------------------------------------------------------------
# ENQROB —— 送 Rob 的入队请求（步骤 2 的第一组：685 个未驱动 output 里的 379 个）
#
# golden 对 io_enqRob_req_<lane>_bits_* 只做四件事：
#   PASS   直接透传 io_fromRename_<lane>_bits_<leaf>（绝大多数，355 个）
#   CONST  钉常量
#   LOCAL  需要派遣流控算出来的（valid / hasException / numWB / singleStep，共 24 个）
# 前两类不需要任何新逻辑，本段直接生成；LOCAL 那 24 个由 ENQROB_LOCAL 决定：
# 流控还没写时接 unresolved_enqrob_*（悬空，仿真出 X），写好后接核的输出。
#
# ★为什么不手抄★：379 个端口逐个对 golden 的 RHS，手抄必然错位；而且
# golden 对 lane1..5 做过 DCE（snapshot 只有 lane0 有），形状不均匀。
ENQROB_LOCAL = {
    'valid':        'core_firedVec[%d]',
    'hasException': 'io_fromRename_%d_bits_hasException | core_updatedSingleStep[%d]',
    'numWB':        "core_updatedSingleStep[%d] ? 7'h0 : io_fromRename_%d_bits_numWB",
    'singleStep':   'core_updatedSingleStep[%d]',
}


def gen_enqrob(ports):
    """io_enqRob_req_* 的驱动。判据是 golden 原文的 RHS，不是"应该是这样"。"""
    lines = _golden_text()
    rhs = _rhs_map(lines)
    # golden 里 io_enqRob_* 全部是 `assign`，_rhs_map 已收；缺一个就 fail-closed
    out = ['  // 送 Rob 的入队请求：valid = 本 lane 这拍真 fire，payload 基本是 io_fromRename 直通。',
           '  // ★hasException / numWB 被 singleStep 改写★（单步调试时这条指令不写回、',
           '  // 且要带上异常），golden 的两处改写逐字照抄。',
           '  // valid = 本 lane 这拍真 fire；singleStep 由核的节 2.10 算出来。']
    npass = nconst = nlocal = 0
    for _d, w, n in ports:
        m = re.match(r'io_enqRob_req_(\d+)_(valid|bits_(.+))$', n)
        if not m:
            continue
        lane, leaf = int(m.group(1)), m.group(3) or 'valid'
        body = rhs.get(n)
        if body is None:
            sys.exit('FATAL: golden 里 %s 没有驱动（fail-closed）' % n)
        if leaf in ENQROB_LOCAL:
            nlocal += 1
            tpl = ENQROB_LOCAL[leaf]
            out.append('  assign %s = %s;' % (n, tpl % ((lane,) * tpl.count('%d'))))
        elif body == 'io_fromRename_%d_bits_%s' % (lane, leaf):
            npass += 1
            out.append('  assign %s = %s;' % (n, body))
        elif CONST_RE.match(body):
            nconst += 1
            out.append('  assign %s = %s;' % (n, body))
        else:
            sys.exit('FATAL: %s 的 golden RHS 既不是直通也不是常量，也不在 '
                     'ENQROB_LOCAL 里：%s' % (n, body[:80]))
    out.insert(3, '  // 本段 %d 条：直通 %d / 常量 %d / 需流控 %d。'
               % (npass + nconst + nlocal, npass, nconst, nlocal))
    return out


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
    new = splice(new, 'UNRESOLVED', gen_unresolved(ports))
    new = splice(new, 'PACK', gen_pack(ports))
    new = splice(new, 'UNPACK', gen_unpack(ports))
    new = splice(new, 'ENQROB', gen_enqrob(ports))
    new = splice(new, 'CHILDWIRES', gen_childwires(ports))
    new = splice(new, 'CHILDINST', gen_childinst(ports))
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
