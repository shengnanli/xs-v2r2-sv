#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_l2_slice.py —— 从 golden 端口表/实例连线机械生成 L2 Slice 家族（Slice / Slice_1..3）的连线区。

CoupledL2（tl2chi）的 Slice 在 Scala 里约 230 行，几乎全是 child 之间的 `<>` / `:=`；golden
每个变体 10,261 行，99% 是 18 个 child 实例的扁平连线。可读核 xs_Slice_core 的"真逻辑"
（几个打拍寄存器、TopDown/预取统计输出）手写在 rtl/uncore/Slice.sv 的手写区，这里只生成连线：

  core_ports   xs_Slice_core 端口表：golden 端口里核要用的那部分 + 与目录 / 数据阵列之间的接口
  core_wires   核内 child 输出线（golden `_<inst>_io_<port>` -> `<inst>_<port>`）
  children     核内 15 个 child 实例（按名连线；常量照 golden 原样）
  to_dir_ds   核 -> 目录 / 数据阵列的输入（dir_* / ds_*）
  wrapper      golden 同名 wrapper Slice：例化核 + 本变体的 Directory / DataStorage / L2Slice（MBIST）
  nav          本文件导航
  另外整份生成 rtl/uncore/Slice_1.sv / Slice_2.sv / Slice_3.sv（薄 wrapper，同一模板），
  以及 verif/ut/Slice/fm_pins_pre.tcl（FM「匹配前」钉点，见 pins_file 的说明）。

★为什么目录 / 数据阵列 / MBIST 分发放在 wrapper 里★：四个变体在 golden 里只差这三个 child 的
单态化版本（Directory_N / DataStorage_N / L2Slice_N）、MBIST bore 数组位宽、以及给 TXREQ 的
sliceId 常量。SV 不能用参数选模块名，把这三个 child 放进各变体的 wrapper（同 Directory_N 的
做法），核就只剩一个参数 SLICE_ID，核体不复制。

★fail-closed★（任一不满足即报错退出，不出文件）：
  1. 四个 golden 变体规整掉"已知差异维度"后逐字相同：模块名、Directory/DataStorage/L2Slice 的
     变体名、io_sliceId 常量、三处 MBIST array 位宽（且位宽 == 对应 child golden 端口宽度）；
  2. 每个 child 端口在 golden child 端口表里存在、方向已知；每条连线表达式恰好归入一类：
     顶层端口 / child 输出线（且其驱动者与名字一致、唯一）/ 常量 / 空（未用输出）/ MBIST 线 /
     手写区信号（HAND 表）；
  3. golden 用 `assign` 驱动的顶层输出集合 == 手写区 `assign` 驱动的顶层输出集合；
     手写区声明了 HAND 表里的每个信号。

用法:
  python3 scripts/gen_l2_slice.py          # 幂等写入
  python3 scripts/gen_l2_slice.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))
CORE_FILE = REPO / 'rtl' / 'uncore' / 'Slice.sv'
VARIANTS = ['Slice', 'Slice_1', 'Slice_2', 'Slice_3']
SFX = {'Slice': '', 'Slice_1': '_1', 'Slice_2': '_2', 'Slice_3': '_3'}
SLICE_ID = {'Slice': 0, 'Slice_1': 1, 'Slice_2': 2, 'Slice_3': 3}

# 放在 wrapper 里的三个 child（变体相关）
WRAP_INSTS = ('directory', 'dataStorage', 'mbistPl')
WRAP_PREFIX = {'directory': 'dir_', 'dataStorage': 'ds_'}

# 手写区信号：golden 名 -> 核里的名字（核里照 golden 名保留，便于 FM 按名配对）
HAND = {
    'mainPipe_io_releaseBufResp_s3_valid_REG': 'mainPipe_io_releaseBufResp_s3_valid_REG',
}

PROBE_WIRES = {'_probe': ('reqBuf', 'io_hasMergeA')}

# child 角色说明（对照 tl2chi/Slice.scala），进生成区的注释
ROLE = {
    'sinkA': 'SinkA：上层 A 通道（Get/Acquire/Hint/CMO）与 L2 预取请求的入口，转成内部 task 送 RequestBuffer',
    'sinkC': 'SinkC：上层 C 通道（Release/ProbeAck）入口；数据写 releaseBuf/refillBuf，task 送 RequestArb，'
             'ProbeAck 响应送 MSHRCtl',
    'grantBuf': 'GrantBuffer：上层 D 通道出口（Grant/AccessAck/HintAck）+ E 通道 GrantAck 回收；预取响应出口',
    'txreq': 'TXREQ：CHI 下行请求队列（MainPipe 的写回 / MSHR 的 Read*/Write* 请求），按 pipeStatusVec 反压',
    'txdat': 'TXDAT：CHI 下行数据队列（写回数据 / snoop 响应数据）',
    'txrsp': 'TXRSP：CHI 下行响应队列（MainPipe 的 SnpResp / MSHR 的 CompAck）',
    'rxsnp': 'RXSNP：CHI 上行 snoop 接收，转成 B 通道 task 送 RequestArb（与在途 MSHR 冲突时挡住）',
    'rxdat': 'RXDAT：CHI 上行数据（CompData），数据写 refillBuf、响应送 MSHRCtl',
    'rxrsp': 'RXRSP：CHI 上行响应（Comp/DBIDResp/RetryAck/PCrdGrant），送 MSHRCtl',
    'refillBuf': 'refillBuf（MSHRBuffer，2 写口）：refill 数据缓冲 —— 写口 0 = RXDAT，写口 1 = SinkC',
    'releaseBuf': 'releaseBuf（MSHRBuffer_1，3 写口）：release 数据缓冲 —— 写口 0 = 嵌套写回（MainPipe 数据 + '
                  'MSHRCtl 给 ID），1 = SinkC Release，2 = MainPipe 读出的被替换行',
    'reqArb': 'RequestArb：s0-s2 请求仲裁（MSHR 任务 > snoop > C > A），发目录读、读 refill/release 缓冲',
    'mainPipe': 'MainPipe：s2-s5 主流水，拿目录结果做决策：直接回应 / 分配 MSHR / 写目录与数据阵列',
    'reqBuf': 'RequestBuffer：A 通道请求缓冲，同 set 冲突的请求在这里等（并做 A 合并进 MSHR）',
    'mshrCtl': 'MSHRCtl：16 个 MSHR 的资源池，发 CHI 请求/响应、Probe（B 通道）与回 MainPipe 的任务',
}
ORDER_NOTE = {
    'reqArb': ('sinkB 的多数字段、mshrTask 的少数字段在源头（RXSNP / MSHRCtl 仲裁器）恒为常量，firtool 删了'
               '那些端口，常量留在这里（照 golden 原样）'),
}


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
def golden_text(mod):
    p = GOLDEN / (mod + '.sv')
    if not p.exists():
        raise SystemExit('golden 里没有 %s.sv' % mod)
    return p.read_text()


def golden_ports(mod, text=None):
    src = text if text is not None else golden_text(mod)
    m = re.search(r'^module %s\(\n(.*?)\n\);\n' % re.escape(mod), src, re.S | re.M)
    if not m:
        raise SystemExit('golden %s.sv 里找不到 module 端口表' % mod)
    ports = []
    for ln in m.group(1).split('\n'):
        mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
        if not mm:
            raise SystemExit('%s: 解析不了端口行 %r' % (mod, ln))
        ports.append((mm.group(1), int(mm.group(2)) + 1 if mm.group(2) else 1, mm.group(3)))
    return ports


def parse_body(mod, text):
    """返回 (instances, others)。instances = [(type, name, [(port, expr)])]。"""
    lines = text.split('\n')
    start = next(i for i, l in enumerate(lines) if l.startswith('module %s(' % mod))
    k = start + 1
    while not lines[k].startswith(');'):
        k += 1
    body = lines[k + 1:]
    insts, others = [], []
    j = 0
    while j < len(body):
        m = re.match(r'  (\w+) (\w+) \($', body[j])
        if m:
            buf = []
            j += 1
            while not body[j].startswith('  );'):
                buf.append(body[j].strip())
                j += 1
            joined = ' '.join(buf)
            conns = re.findall(r'\.(\w+)\s*\(([^()]*)\)', joined)
            if joined.count('.') < len(conns) or len(conns) != joined.count('('):
                raise SystemExit('%s.%s: 连线解析不完整' % (mod, m.group(2)))
            insts.append((m.group(1), m.group(2), [(p, e.strip()) for p, e in conns]))
        else:
            others.append(body[j])
        j += 1
    return insts, others


# ---------------------------------------------------------------------------
# 检查 1：四个变体只差已知维度
# ---------------------------------------------------------------------------
def normalize(var, text):
    s = SFX[var]
    rules = [
        (r'^module %s\(' % re.escape(var), 'module SLICE('),
        (r'^  Directory%s directory \(' % re.escape(s), '  DIRECTORY directory ('),
        (r'^  DataStorage%s dataStorage \(' % re.escape(s), '  DATASTORAGE dataStorage ('),
        (r'^  L2Slice%s mbistPl \(' % re.escape(s), '  L2SLICE mbistPl ('),
        (r"(\.io_sliceId\s+)\(2'h%d\)" % SLICE_ID[var], r'\1(SLICEID)'),
        (r'^(  input  )\[\d+:0\](\s+boreChildrenBd_bore_array,)$', r'\1[BDW]\2'),
        (r'^(  wire )\[\d+:0\](\s+bd_array = )', r'\1[BDW]\2'),
        (r'^(  wire )\[\d+:0\](\s+childBd_array;)$', r'\1[DIRW]\2'),
        (r'^(  wire )\[\d+:0\](\s+childBd_1_array;)$', r'\1[DSW]\2'),
    ]
    out = text
    for pat, rep in rules:
        out, n = re.subn(pat, rep, out, flags=re.M)
        if n != 1:
            raise SystemExit('%s: 规整规则 %r 命中 %d 次（应恰好 1 次）' % (var, pat, n))
    return out


def array_width(text, pat):
    m = re.search(pat, text, re.M)
    return int(m.group(1)) + 1


def check_variants():
    texts = {v: golden_text(v) for v in VARIANTS}
    base = normalize('Slice', texts['Slice'])
    widths = {}
    for v in VARIANTS:
        if normalize(v, texts[v]) != base:
            raise SystemExit('%s 与 Slice 的差异超出已知维度（模块名/变体名/sliceId/MBIST 位宽）' % v)
        t = texts[v]
        bd = array_width(t, r'^  input  \[(\d+):0\]\s+boreChildrenBd_bore_array,$')
        dw = array_width(t, r'^  wire \[(\d+):0\]\s+childBd_array;$')
        sw = array_width(t, r'^  wire \[(\d+):0\]\s+childBd_1_array;$')
        s = SFX[v]
        chk = [('L2Slice' + s, 'mbist_array', bd), ('Directory' + s, 'boreChildrenBd_bore_array', dw),
               ('DataStorage' + s, 'boreChildrenBd_bore_array', sw),
               ('L2Slice' + s, 'toNextPipeline_0_array', dw), ('L2Slice' + s, 'toNextPipeline_1_array', sw)]
        for mod, port, w in chk:
            gw = {n: ww for _, ww, n in golden_ports(mod)}[port]
            if gw != w:
                raise SystemExit('%s: %s.%s 宽 %d，Slice 里是 %d' % (v, mod, port, gw, w))
        widths[v] = (bd, dw, sw)
    return widths


# ---------------------------------------------------------------------------
# 连线模型
# ---------------------------------------------------------------------------
CONST_RE = re.compile(r"^\d+'h[0-9A-Fa-f]+$")


class Model:
    def __init__(self):
        text = golden_text('Slice')
        self.top_ports = golden_ports('Slice', text)
        self.top = {n: (d, w) for d, w, n in self.top_ports}
        self.insts, self.others = parse_body('Slice', text)
        self.child_ports = {}
        for t, n, _ in self.insts:
            self.child_ports[n] = {p: (d, w) for d, w, p in golden_ports(t)}
            self.child_ports[n]['__type__'] = t
        # child 输出线：_<inst>_<port>
        self.wires = {}            # golden 线名 -> (inst, port, width)
        # golden 里唯一不按 `_<inst>_<port>` 命名的 child 输出线：BoringUtils 探针 `_probe`
        # （reqBuf.io.hasMergeA，只喂调试探针，综合视图无读者）。改回规范名，fail-closed 核对。
        for i, (t, n, conns) in enumerate(self.insts):
            for j, (p, e) in enumerate(conns):
                if e in PROBE_WIRES:
                    if PROBE_WIRES[e] != (n, p):
                        raise SystemExit('探针线 %s 接在 %s.%s，预期 %r' % (e, n, p, PROBE_WIRES[e]))
                    conns[j] = (p, '_%s_%s' % (n, p))
        for t, n, conns in self.insts:
            for p, e in conns:
                d, w = self.child_ports[n][p]
                if d == 'output' and e.startswith('_'):
                    if e != '_%s_%s' % (n, p):
                        raise SystemExit('%s.%s 驱动的线名 %s 不是 _%s_%s' % (n, p, e, n, p))
                    if e in self.wires:
                        raise SystemExit('线 %s 多驱动' % e)
                    self.wires[e] = (n, p, w)
        # golden assign 驱动的顶层输出
        self.assign_outs = set()
        for ln in self.others:
            m = re.match(r'\s*assign (\w+) = ', ln)
            if m and m.group(1) in self.top and not m.group(1).startswith('boreChildrenBd_'):
                self.assign_outs.add(m.group(1))
        self.classify()

    def kind(self, inst, port, e):
        d, w = self.child_ports[inst][port]
        if e == '' or e == '/* unused */':
            if d != 'output':
                raise SystemExit('%s.%s 是输入却悬空' % (inst, port))
            return 'open'
        if CONST_RE.match(e):
            if d != 'input':
                raise SystemExit('%s.%s 是输出却接常量' % (inst, port))
            return 'const'
        if e in self.top:
            return 'top'
        if e in self.wires:
            return 'wire'
        if e in HAND:
            return 'hand'
        if re.match(r'^(bd|childBd|childBd_1)_\w+$', e):
            if inst not in WRAP_INSTS:
                raise SystemExit('MBIST 线 %s 接到了核内 child %s' % (e, inst))
            return 'mbist'
        raise SystemExit('%s.%s 的连线 %r 归不进任何一类' % (inst, port, e))

    def classify(self):
        self.core_insts = [x for x in self.insts if x[1] not in WRAP_INSTS]
        self.wrap_insts = [x for x in self.insts if x[1] in WRAP_INSTS]
        if [x[1] for x in self.wrap_insts] != list(WRAP_INSTS):
            raise SystemExit('wrapper child 顺序/集合不对: %r' % [x[1] for x in self.wrap_insts])
        for t, n, conns in self.insts:
            seen = set()
            for p, e in conns:
                if p not in self.child_ports[n]:
                    raise SystemExit('%s 没有端口 %s' % (n, p))
                if p in seen:
                    raise SystemExit('%s.%s 连了两次' % (n, p))
                seen.add(p)
                self.kind(n, p, e)
            missing = set(self.child_ports[n]) - {'__type__'} - seen
            if missing:
                raise SystemExit('%s 有端口没连: %s' % (n, sorted(missing)[:5]))
        # 谁用了什么
        self.users = collections.defaultdict(set)
        for t, n, conns in self.insts:
            for p, e in conns:
                if self.child_ports[n][p][0] == 'input':
                    self.users[e].add(n)
        # 核需要的顶层端口：核内 child 连到的 + 手写区用到的（由 HAND_TOP 给出）
        self.core_top = []
        for d, w, nme in self.top_ports:
            if nme in ('clock', 'reset'):
                self.core_top.append((d, w, nme))
                continue
            in_core = any(e == nme for _, _, conns in self.core_insts for _, e in conns)
            alias = 'bd_' + nme[len('boreChildrenBd_bore_'):] if nme.startswith('boreChildrenBd_bore_') else None
            in_wrap = any(e == nme or e == alias for _, _, conns in self.wrap_insts for _, e in conns)
            if nme in self.assign_outs or nme in HAND_TOP_READS:
                in_core = True
            if in_core:
                self.core_top.append((d, w, nme))
            elif not in_wrap:
                raise SystemExit('顶层端口 %s 谁都没接' % nme)
        # 目录 / 数据阵列 接口
        self.iface = []          # (dir_in_core, width, core_name, inst, port, golden_expr)
        for t, n, conns in self.wrap_insts:
            if n == 'mbistPl':
                continue
            for p, e in conns:
                d, w = self.child_ports[n][p]
                k = self.kind(n, p, e)
                cname = WRAP_PREFIX[n] + (p[3:] if p.startswith('io_') else p)
                if d == 'output' and k == 'wire':
                    # 目录输出 -> 核输入（核内有人用 / 手写区用）
                    self.iface.append(('input', w, cname, n, p, e))
                elif d == 'input' and k in ('wire', 'hand'):
                    self.iface.append(('output', w, cname, n, p, e))
                # 其余（顶层端口 / 常量 / 悬空 / MBIST）在 wrapper 里直接连
        self.iface_by_wire = {e: c for d, w, c, n, p, e in self.iface if d == 'input'}

    # 核里的名字
    def core_expr(self, e):
        if e in self.top:
            return e
        if e in self.wires:
            n, p, _ = self.wires[e]
            if n in WRAP_PREFIX:
                return self.iface_by_wire[e]
            return '%s_%s' % (n, p[3:] if p.startswith('io_') else p)
        if e in HAND:
            return HAND[e]
        if CONST_RE.match(e):
            return e
        raise SystemExit('core_expr: %r' % e)


# 手写区读的顶层输入（golden 里只在 assign 里出现、不连任何 child 的输入）
HAND_TOP_READS = {'io_prefetch_req_valid', 'io_prefetch_req_bits_pfSource'}


# ---------------------------------------------------------------------------
# 渲染
# ---------------------------------------------------------------------------
def wdecl(w):
    return '[%d:0]' % (w - 1) if w > 1 else ''


def port_decl_lines(ports, kw_logic=True):
    out = []
    for i, (d, w, n) in enumerate(ports):
        comma = ',' if i + 1 < len(ports) else ''
        out.append('  %-6s %s %-9s %s%s' % (d, 'logic' if kw_logic else '     ', wdecl(w), n, comma))
    return out


def region_core_ports(M):
    ports = [(d, w, n) for d, w, n in M.core_top]
    ports += [(d, w, c) for d, w, c, _, _, _ in M.iface]
    return port_decl_lines(ports)


def region_core_wires(M):
    L = ['  // 核内 child 的输出线：golden 的 `_<inst>_io_<port>` 在这里叫 `<inst>_<port>`']
    cur = None
    for e, (n, p, w) in M.wires.items():
        if n in WRAP_PREFIX or n == 'mbistPl':
            continue
        if n != cur:
            L.append('  // -- %s' % n)
            cur = n
        L.append('  logic %-9s %s_%s;' % (wdecl(w), n, p[3:] if p.startswith('io_') else p))
    return L


def inst_lines(M, t, n, conns, expr_fn, indent='  '):
    width = max(len(p) for p, _ in conns)
    L = ['%s%s %s (' % (indent, t, n)]
    for i, (p, e) in enumerate(conns):
        comma = ',' if i + 1 < len(conns) else ''
        L.append('%s  .%-*s (%s)%s' % (indent, width, p, expr_fn(e), comma))
    L.append('%s);' % indent)
    return L


def region_children(M):
    L = []
    for t, n, conns in M.core_insts:
        L.append('  // %s' % ROLE[n])
        if n in ORDER_NOTE:
            L.append('  //   注：%s' % ORDER_NOTE[n])
        if n == 'txreq':
            conns = [(p, 'SLICE_ID' if p == 'io_sliceId' else e) for p, e in conns]
        L += inst_lines(M, t, n, conns,
                        lambda e: '' if e in ('', '/* unused */') else
                        (e if e == 'SLICE_ID' else M.core_expr(e)))
        L.append('')
    return L[:-1]


def region_to_dir_ds(M):
    L = ['  // 核 -> 目录（dir_*）/ 数据阵列（ds_*）：这两个 child 在 wrapper 里']
    for d, w, c, n, p, e in M.iface:
        if d == 'output':
            L.append('  assign %s = %s;' % (c, M.core_expr(e)))
    return L


def wrapper_lines(M, var, widths):
    s = SFX[var]
    bd, dw, sw = widths[var]
    ports = []
    for d, w, n in M.top_ports:
        if n == 'boreChildrenBd_bore_array':
            w = bd
        ports.append((d, w, n))
    L = ['module %s(' % var]
    for i, (d, w, n) in enumerate(ports):
        comma = ',' if i + 1 < len(ports) else ''
        L.append('  %-6s %-9s %s%s' % (d, wdecl(w), n, comma))
    L.append(');')
    L.append('  // §W1 核 <-> 目录（dir_*）/ 数据阵列（ds_*）的接口线')
    for d, w, c, n, p, e in M.iface:
        L.append('  logic %-9s %s;' % (wdecl(w), c))
    L.append('  // §W2 MBIST 分发线：mbistPl 的两路下行（路 0 -> 目录，路 1 -> 数据阵列）')
    mbist_wire = {}
    for t, n, conns in M.wrap_insts:
        if n != 'mbistPl':
            continue
        for p, e in conns:
            if e.startswith('childBd'):
                m = re.match(r'toNextPipeline_(\d)_(\w+)$', p)
                if not m:
                    raise SystemExit('mbistPl.%s 接 %s 不认识' % (p, e))
                nm = ('mbist_dir_' if m.group(1) == '0' else 'mbist_ds_') + m.group(2)
                exp = ('childBd_' if m.group(1) == '0' else 'childBd_1_') + m.group(2)
                if e != exp:
                    raise SystemExit('mbistPl.%s 接 %s，应为 %s' % (p, e, exp))
                w = M.child_ports['mbistPl'][p][1]
                if m.group(2) == 'array':
                    w = dw if m.group(1) == '0' else sw
                mbist_wire[e] = nm
                L.append('  logic %-9s %s;' % (wdecl(w), nm))
    L.append('')
    # 核
    L.append('  // §W3 可读核（本变体 SLICE_ID = %d）：除目录 / 数据阵列 / MBIST 分发外的全部 child 与本层逻辑' % SLICE_ID[var])
    L.append('  xs_Slice_core #(.SLICE_ID(2\'d%d)) u_core (' % SLICE_ID[var])
    cp = [n for _, _, n in M.core_top] + [c for _, _, c, _, _, _ in M.iface]
    width = max(len(x) for x in cp)
    for i, x in enumerate(cp):
        L.append('    .%-*s (%s)%s' % (width, x, x, ',' if i + 1 < len(cp) else ''))
    L.append('  );')
    L.append('')

    def wexpr(n, p, e):
        if e in ('', '/* unused */'):
            return ''
        if e in M.top:
            return e
        if e.startswith('bd_'):
            tp = 'boreChildrenBd_bore_' + e[3:]
            if tp not in M.top:
                raise SystemExit('bd 线 %s 对不上顶层端口' % e)
            return tp
        if e in mbist_wire:
            return mbist_wire[e]
        if CONST_RE.match(e):
            return e
        cname = WRAP_PREFIX[n] + (p[3:] if p.startswith('io_') else p)
        return cname

    tnames = {'directory': 'Directory' + SFX[var], 'dataStorage': 'DataStorage' + SFX[var],
              'mbistPl': 'L2Slice' + SFX[var]}
    notes = {'directory': '§W4 目录（tag / meta / 替换状态），本变体 = %s' % tnames['directory'],
             'dataStorage': '§W5 数据阵列，本变体 = %s' % tnames['dataStorage'],
             'mbistPl': '§W6 MBIST 分发（%s）：顶层 bore -> 目录（路 0）/ 数据阵列（路 1）' % tnames['mbistPl']}
    for t, n, conns in M.wrap_insts:
        # 校验：wrapper 里能接的只有 顶层 / MBIST / 接口 / 空 / 常量
        for p, e in conns:
            k = M.kind(n, p, e)
            if k in ('wire', 'hand'):
                d = M.child_ports[n][p][0]
                cname = WRAP_PREFIX[n] + (p[3:] if p.startswith('io_') else p)
                if cname not in {c for _, _, c, _, _, _ in M.iface}:
                    if d == 'output':
                        # 输出线没人用 -> 悬空（只有 golden 也没人用才可能出现）
                        if M.users.get(e):
                            raise SystemExit('%s.%s -> %s 有用户却没进接口' % (n, p, e))
                    else:
                        raise SystemExit('%s.%s 输入没进接口' % (n, p))
        L.append('  // %s' % notes[n])
        iface_names = {c for _, _, c, _, _, _ in M.iface}
        conn2 = []
        for p, e in conns:
            x = wexpr(n, p, e)
            if n in WRAP_PREFIX and x == WRAP_PREFIX[n] + (p[3:] if p.startswith('io_') else p) \
                    and x not in iface_names:
                x = ''
            conn2.append((p, x))
        L += inst_lines(M, tnames[n], n, conn2, lambda e: e)
        L.append('')
    L[-1] = 'endmodule'
    return L


def variant_file(M, var, widths):
    bd, dw, sw = widths[var]
    s = SFX[var]
    hdr = [
        '// %s.sv —— CoupledL2（tl2chi）L2 第 %d 个 slice（sliceId = %d）' % (var, SLICE_ID[var], SLICE_ID[var]),
        '//',
        '// 薄 wrapper：逻辑全在 rtl/uncore/Slice.sv 的 xs_Slice_core（文件头讲清 slice 的数据流）。本变体与',
        '// Slice 的差别只有：给 TXREQ 的 sliceId = %d；目录 / 数据阵列 / MBIST 分发用 Directory%s /' % (SLICE_ID[var], s),
        '// DataStorage%s / L2Slice%s 这一组单态化（它们只差 MBIST 编号与 SRAM 宏实例）；MBIST bore 数组' % (s, s),
        '// 位宽 %d（目录路 %d、数据阵列路 %d）。golden %s.sv 10,261 行，规模与 Slice 相同。' % (bd, dw, sw, var),
        '// 本文件由 scripts/gen_l2_slice.py 整份生成（勿手改）；生成时核对四个 golden 变体只差上述维度。',
        '//',
        'NAV',
        '',
        '// BEGIN GENERATED(%s) —— scripts/gen_l2_slice.py' % var,
    ]
    body = wrapper_lines(M, var, widths) + ['// END GENERATED(%s)' % var, '']
    for _ in range(2):
        nav = region_nav('\n'.join(hdr + body))
        i = hdr.index('NAV') if 'NAV' in hdr else None
        if i is not None:
            hdr[i:i + 1] = nav
            nav_len = len(nav)
        else:
            start = hdr.index('// 本文件导航：')
            hdr[start:start + nav_len] = nav
    return '\n'.join(hdr + body)


NAV_RE = re.compile(r'^(  // §\w.*|  // BEGIN GENERATED\((core_wires|children|to_dir_ds)\).*|'
                    r'// BEGIN GENERATED\(wrapper\).*)$')


def region_nav(text):
    out = ['// 本文件导航：']
    for i, ln in enumerate(text.split('\n')):
        if NAV_RE.match(ln):
            label = re.sub(r'\s*——.*$', '', ln.strip().lstrip('/').strip())
            out.append('//   L%d %s' % (i + 1, label[:70]))
    return out


def replace_region(text, tag, lines):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED\(%s\)[^\n]*$)'
                     % (re.escape(tag), re.escape(tag)), re.S | re.M)
    m = pat.search(text)
    if not m:
        raise SystemExit('%s 里找不到 GENERATED(%s) 区' % (CORE_FILE, tag))
    return text[:m.start(2)] + '\n'.join(lines) + '\n' + text[m.end(2):]


def hand_region(text):
    """手写区 = 核里 GENERATED 区以外、wrapper 之前的部分。"""
    core = text[text.index('module xs_Slice_core'):text.index('// BEGIN GENERATED(wrapper)')]
    core = re.sub(r'// BEGIN GENERATED\((\w+)\).*?// END GENERATED\(\1\)', '', core, flags=re.S)
    return re.sub(r'//[^\n]*', '', core)


def check_hand(M, text):
    hand = hand_region(text)
    driven = set(re.findall(r'^\s*assign\s+(\w+)\s*=', hand, re.M))
    driven_top = {x for x in driven if x in M.top}
    if driven_top != M.assign_outs:
        raise SystemExit('手写区 assign 的顶层输出与 golden 不符：多 %s 少 %s'
                         % (sorted(driven_top - M.assign_outs), sorted(M.assign_outs - driven_top)))
    for g, c in HAND.items():
        if not re.search(r'\b%s\b' % re.escape(c), hand):
            raise SystemExit('手写区没有声明 %s' % c)


def render(M, widths):
    text = CORE_FILE.read_text()
    text = replace_region(text, 'core_ports', region_core_ports(M))
    text = replace_region(text, 'core_wires', region_core_wires(M))
    text = replace_region(text, 'children', region_children(M))
    text = replace_region(text, 'to_dir_ds', region_to_dir_ds(M))
    text = replace_region(text, 'wrapper', wrapper_lines(M, 'Slice', widths))
    for _ in range(2):
        text = replace_region(text, 'nav', region_nav(text))
    check_hand(M, text)
    out = {CORE_FILE: text}
    for v in VARIANTS[1:]:
        out[REPO / 'rtl' / 'uncore' / (v + '.sv')] = variant_file(M, v, widths)
    out[REPO / 'verif' / 'ut' / 'Slice' / 'fm_pins_pre.tcl'] = pins_file()
    return out


# ---------------------------------------------------------------------------
# FM 匹配前钉点：从各 child 自己签核时的 FM 配对报告（matched.rpt）**机械收割**，只改层次前缀
# ---------------------------------------------------------------------------
# 为什么要钉：Slice 闭包 85,315 个比较点里约 25k 个寄存器位两侧叶名不同（golden 扁平名
# `buffer_0_0_reg[k]` vs 重写数组 `u_core/buffer_reg[0][0][k]` 等），FM 只能靠签名配对——
# 第一次诊断跑 1.6 小时才配到 63%（60854/85315）、随后每 30 分钟不到 900 点，不收敛。
# child 单独签核时这些点 FM 都配上了（各自规模小）：它们的 matched.rpt 就是现成的、经 FM
# 核实过的配对表。放进 Slice 后对象没变、只多一层路径：
#   ref  <child>/x  ->  <Slice_N>/<inst>/x
#   impl <child>/y  ->  <Slice_N>/u_core/<inst>/y（目录 / 数据阵列 / MBIST 分发在 wrapper 里：<Slice_N>/<inst>/y）
# 流程：`--harvest` 读各 child UT 目录下 fm_work/<child>/matched.rpt（诊断跑产物，不入库），
# 只取**叶名不同**的 DFF 类配对，按位压成 (ref 基名, impl 基名, 位宽) 写进**入库**的
# verif/ut/Slice/child_pins.tsv；默认 / --check 只读该 tsv 出 fm_pins_pre.tcl，不碰 fm_work。
# 不是本层自己的寄存器（本层寄存器保留 golden 名，FM 按名配）。
CHILD_PINS = [   # (UT 目录, 本层实例名, 变体 -> child golden 名)
    ('MSHRCtl', 'mshrCtl', lambda v: 'MSHRCtl'),
    ('MainPipe_1', 'mainPipe', lambda v: 'MainPipe_1'),
    ('GrantBuffer', 'grantBuf', lambda v: 'GrantBuffer'),
    ('RequestBuffer', 'reqBuf', lambda v: 'RequestBuffer'),
    ('RequestArb', 'reqArb', lambda v: 'RequestArb'),
    ('SinkC', 'sinkC', lambda v: 'SinkC'),
    ('RXSNP', 'rxsnp', lambda v: 'RXSNP'),
    ('TXDAT', 'txdat', lambda v: 'TXDAT'),
    ('TXREQ', 'txreq', lambda v: 'TXREQ'),
    ('TXRSP', 'txrsp', lambda v: 'TXRSP'),
    ('MSHRBuffer', 'refillBuf', lambda v: 'MSHRBuffer'),
    ('MSHRBuffer', 'releaseBuf', lambda v: 'MSHRBuffer_1'),
    ('Directory', 'directory', lambda v: 'Directory' + SFX[v]),
    ('DataStorage', 'dataStorage', lambda v: 'DataStorage' + SFX[v]),
    ('L2Slice', 'mbistPl', lambda v: 'L2Slice' + SFX[v]),
]
PINS_TSV = REPO / 'verif' / 'ut' / 'Slice' / 'child_pins.tsv'
# 配对方式 Name / Func / User 都收（Func = FM 按功能配上的、User = child 自己的 set_user_match）。
PAIR_RE = re.compile(r'Ref\s+(\w+)\s+(?:Name|Func|User)\(Last\)\s+r:/WORK/(\w+)/(\S+)\n\s+Impl\s+(\w+)\s+(?:Name|Func|User)\(Last\)\s+i:/WORK/(\w+)/(\S+)')
# child 自带的钉点文件：钉的对象在 child 里可能是 not-compared（unread），不进 matched.rpt，
# 另用 tclsh 执行该文件收割（set_user_match 换成只打印的桩）。
CHILD_PIN_FILES = {'MSHRCtl': 'MSHRCtl', 'GrantBuffer': 'GrantBuffer', 'RequestBuffer': 'RequestBuffer',
                   'Directory': 'Directory', 'DataStorage': 'DataStorage'}
TCL_STUB = r'''
proc set_user_match {r i} { puts "PIN\t$r\t$i"; return 1 }
proc error {msg} { puts stderr "child pin file error: $msg"; exit 9 }
set top [lindex $argv 0]
source [lindex $argv 1]
'''


def child_pin_file_pairs(child, ut):
    import subprocess
    import tempfile
    pf = REPO / 'verif' / 'ut' / ut / 'fm_pins_pre.tcl'
    if ut not in CHILD_PIN_FILES or not pf.exists():
        return []
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
        f.write(TCL_STUB)
        stub = f.name
    try:
        r = subprocess.run(['tclsh', stub, child, str(pf)], stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, universal_newlines=True)
    finally:
        os.unlink(stub)
    if r.returncode != 0:
        raise SystemExit('收割 %s 钉点失败: %s' % (pf, r.stderr.strip()))
    out = []
    rp, ip = 'r:/WORK/%s/' % child, 'i:/WORK/%s/' % child
    for ln in r.stdout.splitlines():
        if ln.startswith('PIN\t'):
            _, rr, ii = ln.split('\t')
            if not rr.startswith(rp) or not ii.startswith(ip):
                raise SystemExit('%s: 钉点路径前缀不对: %s %s' % (pf, rr, ii))
            out.append((rr[len(rp):], ii[len(ip):]))
    return out


BIT_RE = re.compile(r'^(.*)\[(\d+)\]$')


def harvest_child(child, ut):
    """读 child 的 matched.rpt -> [(ref_base, impl_base, width)]；只取叶名不同的 DFF 类点。"""
    rpt = REPO / 'verif' / 'ut' / ut / 'fm_work' / child / 'matched.rpt'
    if not rpt.exists():
        raise SystemExit('缺 %s：先在 verif/ut/%s 跑 make fm-%s FM_MODE=diagnostic-full' % (rpt, ut, child))
    txt = rpt.read_text()
    groups = collections.OrderedDict()
    n = 0
    triples = PAIR_RE.findall(txt)
    seen_r = {r for _, _, r, _, _, _ in triples}
    for r, i in child_pin_file_pairs(child, ut):
        if r not in seen_r:
            triples.append(('DFF', child, r, 'DFF', child, i))
    for k1, t1, r, k2, t2, i in triples:
        if t1 != child or t2 != child:
            raise SystemExit('%s: 顶层名不是 %s' % (rpt, child))
        if not k1.startswith('DFF') and k1 != 'LAT':
            continue
        if r.split('/')[-1] == i.split('/')[-1]:
            continue                       # 叶名相同，FM 按名自配
        n += 1
        mr, mi = BIT_RE.match(r), BIT_RE.match(i)
        if mr and mi and mr.group(2) == mi.group(2):
            groups.setdefault((mr.group(1), mi.group(1)), set()).add(int(mr.group(2)))
        else:
            groups.setdefault((r, i), set()).add(-1)
    out = []
    for (rb, ib), bits in groups.items():
        if bits == {-1}:
            out.append((rb, ib, 0))
        elif bits == set(range(len(bits))):
            out.append((rb, ib, len(bits)))
        else:
            for b in sorted(bits):
                out.append(('%s[%d]' % (rb, b), '%s[%d]' % (ib, b), 0))
    if sum(max(w, 1) for _, _, w in out) != n:
        raise SystemExit('%s: 压缩后位数 %d != 收到 %d' % (child, sum(max(w, 1) for _, _, w in out), n))
    return out


def harvest_all():
    L = ['# child\tref_base\timpl_base\twidth  —— scripts/gen_l2_slice.py --harvest 从各 child fm_work/<child>/matched.rpt 收割（勿手改）',
         '# width 0 = 标量（名字已含位下标或本就是 1 位）；width W = 两侧都是 [0..W-1] 的位，按位展开。']
    seen = set()
    for ut, inst, gname in CHILD_PINS:
        for v in VARIANTS:
            child = gname(v)
            if child in seen:
                continue
            seen.add(child)
            rows = harvest_child(child, ut)
            for rb, ib, w in rows:
                L.append('%s\t%s\t%s\t%d' % (child, rb, ib, w))
    return '\n'.join(L) + '\n'


def load_pins_tsv():
    if not PINS_TSV.exists():
        raise SystemExit('缺 %s：先跑 gen_l2_slice.py --harvest' % PINS_TSV)
    rows = collections.defaultdict(list)
    for ln in PINS_TSV.read_text().splitlines():
        if not ln or ln.startswith('#'):
            continue
        c, rb, ib, w = ln.split('\t')
        rows[c].append((rb, ib, int(w)))
    return rows


def pins_file():
    rows = load_pins_tsv()
    L = ['# Slice 家族 FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_slice.py（勿手改）',
         '#',
         '# 内容 = 各 child 单独签核时 FM 已核实的配对（child_pins.tsv，由 --harvest 从 matched.rpt 收割），',
         '# 只改层次前缀。只钉两侧叶名不同的寄存器位；本层自己的寄存器保留 golden 名，FM 按名自配。',
         '# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
         '# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数不等于字面整数就 error。',
         '# 名字用花括号原样传（含 FM 报告里的 \\[ 转义），不做任何替换。',
         'set ::SLICE_PIN_OK 0',
         'set ::SLICE_PIN_BAD 0',
         'proc slice_pin {r i} {',
         '  if {[set_user_match $r $i]} { incr ::SLICE_PIN_OK } else {',
         '    incr ::SLICE_PIN_BAD',
         '    if {$::SLICE_PIN_BAD <= 10} { puts "SLICE_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'proc slice_pinw {r i w} {',
         '  for {set b 0} {$b < $w} {incr b} { slice_pin "${r}\\[$b\\]" "${i}\\[$b\\]" }',
         '}']
    for v in VARIANTS:
        total = 0
        body = []
        per = []
        for ut, inst, gname in CHILD_PINS:
            child = gname(v)
            ipath = inst if inst in WRAP_INSTS else 'u_core/%s' % inst
            n = 0
            for rb, ib, w in rows.get(child, []):
                r = 'r:/WORK/%s/%s/%s' % (v, inst, rb)
                i = 'i:/WORK/%s/%s/%s' % (v, ipath, ib)
                if '{' in r + i or '}' in r + i:
                    raise SystemExit('名字含花括号: %s %s' % (r, i))
                if w:
                    body.append('  slice_pinw {%s} {%s} %d' % (r, i, w))
                    n += w
                else:
                    body.append('  slice_pin {%s} {%s}' % (r, i))
                    n += 1
            per.append('%s %d' % (child, n))
            total += n
        L.append('if {$top eq "%s"} {' % v)
        L.append('  # %s' % ', '.join(per))
        L.append('  puts "SLICE_PIN_BEGIN %s expect=%d"' % (v, total))
        L += body
        L.append('  puts "SLICE_PIN_END %s ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD"' % v)
        L.append('  if {$::SLICE_PIN_BAD != 0 || $::SLICE_PIN_OK != %d} {' % total)
        L.append('    error "SLICE_PIN_MISMATCH ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD expect=%d"' % total)
        L.append('  }')
        L.append('}')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    ap.add_argument('--harvest', action='store_true',
                    help='从各 child fm_work/<child>/matched.rpt 重新收割 child_pins.tsv（需先跑 child 的诊断 FM）')
    args = ap.parse_args()
    if args.harvest:
        PINS_TSV.write_text(harvest_all())
        print('gen_l2_slice: 收割 %s' % PINS_TSV.relative_to(REPO))
    widths = check_variants()
    M = Model()
    files = render(M, widths)
    drift = 0
    for p, new in files.items():
        cur = p.read_text() if p.exists() else None
        if cur != new:
            drift += 1
            if args.check:
                print('gen_l2_slice: DRIFT %s' % p.relative_to(REPO))
            else:
                p.write_text(new)
                print('gen_l2_slice: 更新 %s' % p.relative_to(REPO))
    if args.check:
        if drift:
            return 1
        print('gen_l2_slice: OK (%d 个文件)' % len(files))
    elif not drift:
        print('gen_l2_slice: 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
