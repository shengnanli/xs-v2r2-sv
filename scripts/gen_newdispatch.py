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
    + ['srcType_2', 'singleStep', 'lqIdx_flag', 'lqIdx_value',
       'sqIdx_flag', 'sqIdx_value', 'useRegCache_0', 'useRegCache_1',
       'regCacheIdx_0', 'regCacheIdx_1']
    + ['srcLoadDependency_%d_%d' % (s, k) for s in (0, 1) for k in range(3)])


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
            if leaf in BLOCKED_LEAVES:
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
