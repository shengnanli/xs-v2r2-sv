#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— 生成 RRArbiterInit 家族的 14 个薄 wrapper + 本 UT 的 tb。

家族规矩（CONVENTIONS「变体家族」）：一个参数化核文件 + 每变体一个薄文件，
核体绝不复制。核 = rtl/common/RRArbiterInit.sv 里的
`xs_RRArbiterInit_core #(.N, .W)`，该文件同时带着家族里最朴素的那个变体
（RRArbiterInit 本身，N=8/W=36）作为手写范例；本脚本产出其余 14 个薄壳与 tb。

★所有维度都从 golden 端口表**实测**，不从记忆或注释里抄★
端口表逐行照抄 golden（端口契约闸 PORTLINT_ORDER=fail 要求逐位同名同序），
N / 字段宽度 / 有无 ready / 有无 chosen 全部由解析得到。两处 golden 自己的
不对称（见 ASYMMETRY 与 DERIVED_OUT）是**唯一**手工录入的常量，而且脚本会
校验它们与 golden 的实际端口缺口完全对应，对不上就报错退出，不会静默跑偏。

用法: python3 gen.py        （幂等：内容不变不碰文件）
"""
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = pathlib.Path(os.environ.get('XSSV_HOME') or HERE.parents[2])
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))

# 家族全体（15 个）。第一个由 rtl/common/RRArbiterInit.sv 手写，其余本脚本生成。
FAMILY = ['RRArbiterInit'] + ['RRArbiterInit_%d' % i for i in
                              [1, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 20]]
HANDWRITTEN = 'RRArbiterInit'

# 例化者（grep -lE '^  <名> ' golden/*.sv 实测）
USERS = {
    'RRArbiterInit':    'Bitmap.sv',
    'RRArbiterInit_1':  'LLPTW.sv',
    'RRArbiterInit_4':  'LLPTW.sv',
    'RRArbiterInit_5':  'PrefetchFilter.sv',
    'RRArbiterInit_6':  'PrefetchFilter.sv / MutiLevelPrefetchFilter.sv',
    'RRArbiterInit_7':  'MutiLevelPrefetchFilter.sv',
    'RRArbiterInit_8':  'MutiLevelPrefetchFilter.sv',
    'RRArbiterInit_9':  'MutiLevelPrefetchFilter.sv',
    'RRArbiterInit_11': 'LoadQueueUncache.sv',
    'RRArbiterInit_12': 'PTWNewFilter.sv',
    'RRArbiterInit_13': 'MMIOBridge.sv',
    'RRArbiterInit_14': 'PrefetchReqBuffer.sv',
    'RRArbiterInit_15': 'PrefetchReqBuffer.sv',
    'RRArbiterInit_16': 'SinkC.sv',
    'RRArbiterInit_20': 'TL2CHICoupledL2.sv',
}
# 一句话说清这一路仲裁的是什么（读者最想先知道的）
ROLE = {
    'RRArbiterInit':    'Bitmap（页表位图缓存）8 路 refill/查询请求的 ppn 仲裁',
    'RRArbiterInit_1':  'LLPTW（末级页表遍历）6 个条目的 hptw 回填结果仲裁',
    'RRArbiterInit_4':  'LLPTW 6 个条目发往 Bitmap 的查询仲裁',
    'RRArbiterInit_5':  'L2 预取过滤器 16 个表项的回收/淘汰请求仲裁',
    'RRArbiterInit_6':  'L2 预取过滤器 16 路 48 位裸总线仲裁（payload 无字段名）',
    'RRArbiterInit_7':  '多级预取过滤器 32 路表项请求仲裁（家族里最宽的一路）',
    'RRArbiterInit_8':  '多级预取过滤器 16 路预取请求（paddr/alias/confidence/来源）仲裁',
    'RRArbiterInit_9':  '多级预取过滤器 16 路 {addr, source} 请求仲裁',
    'RRArbiterInit_11': 'LoadQueueUncache 16 个 uncache 条目的发射仲裁',
    'RRArbiterInit_12': 'PTWNewFilter 3 路页表遍历请求仲裁（家族里最窄的一路）',
    'RRArbiterInit_13': 'MMIOBridge 16 个 MMIO 条目发往 CHI TXREQ 的仲裁',
    'RRArbiterInit_14': 'PrefetchReqBuffer 16 个表项的回收请求仲裁',
    'RRArbiterInit_15': 'PrefetchReqBuffer 16 个表项发往 L2 的预取请求仲裁',
    'RRArbiterInit_16': 'L2 SinkC 4 路 TaskBundle（94 字段）仲裁，payload 家族最宽',
    'RRArbiterInit_20': 'TL2CHICoupledL2 顶层 5 路 CHI TXREQ 通道仲裁',
}

# ---------------------------------------------------------------------------
# golden 自己的两处不对称 —— 必须照抄，不许"统一"掉（CONVENTIONS：看起来冗余的
# 结构一份都不许少；FM 不做可达性分析）。两处都在下面被 assert 校验。
# ---------------------------------------------------------------------------
# (1) 某些字段只有部分输入有真端口，其余输入在 golden 的选择表里是**常量**。
#     实测 RRArbiterInit_20：bits_tgtID 只有 io_in_4 有端口，其余 4 路填 11'h0；
#     bits_size 同理，其余 4 路填 3'h6（不是 0！）。
ASYMMETRY = {
    'RRArbiterInit_20': {'bits_tgtID': "11'h0", 'bits_size': "3'h6"},
}
# (2) 某些输出没有任何输入端口来源，golden 用一张「下标即取值」的常数表由 chosen
#     产生。实测 RRArbiterInit_11：io_out_bits_id = _GEN[chosen]，_GEN = 7'h0..7'hF。
DERIVED_OUT = {
    'RRArbiterInit_11': {'bits_id': 7},
}

# SV 保留字：golden 的字段名去掉 bits_ 前缀后可能撞上（实测只有 alias 一个，
# 出现在 RRArbiterInit_16 的 bits_alias）。撞上就加 _f 后缀，并在文件里注明。
SV_KEYWORDS = {
    'alias', 'always', 'and', 'assign', 'automatic', 'before', 'begin', 'bind',
    'bit', 'buf', 'byte', 'case', 'cell', 'chandle', 'class', 'config', 'const',
    'constraint', 'context', 'cover', 'default', 'disable', 'dist', 'do', 'edge',
    'else', 'end', 'enum', 'event', 'expect', 'export', 'extends', 'extern',
    'final', 'first', 'force', 'forkjoin', 'function', 'generate', 'genvar',
    'iff', 'if', 'implements', 'import', 'initial', 'inout', 'input', 'inside',
    'int', 'integer', 'interface', 'join', 'let', 'local', 'localparam', 'logic',
    'longint', 'matches', 'modport', 'module', 'new', 'nor', 'not', 'null', 'or',
    'output', 'package', 'parameter', 'posedge', 'negedge', 'priority', 'program',
    'property', 'protected', 'pure', 'rand', 'randc', 'real', 'realtime', 'ref',
    'reg', 'release', 'restrict', 'return', 'sequence', 'shortint', 'shortreal',
    'signed', 'solve', 'static', 'string', 'struct', 'super', 'table', 'tagged',
    'task', 'this', 'throughout', 'time', 'tri', 'type', 'typedef', 'union',
    'unique', 'unsigned', 'var', 'virtual', 'void', 'wait', 'wand', 'wire',
    'with', 'within', 'wor', 'xnor', 'xor',
}


class Variant:
    """从 golden 端口表解析出的一个变体。"""

    def __init__(self, name):
        self.name = name
        src = (GOLDEN / (name + '.sv')).read_text()
        m = re.search(r'^module %s\(\n(.*?)\n\);\n' % name, src, re.S | re.M)
        if not m:
            raise SystemExit('golden %s.sv 里找不到 module 端口表' % name)
        self.port_text = m.group(1)
        self.ports = []          # (dir, width, name) 按 golden 顺序
        for ln in self.port_text.split('\n'):
            mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
            if not mm:
                raise SystemExit('%s: 解析不了端口行 %r' % (name, ln))
            w = int(mm.group(2)) + 1 if mm.group(2) else 1
            self.ports.append((mm.group(1), w, mm.group(3)))

        pnames = [p[2] for p in self.ports]
        self.n = 1 + max(int(x) for x in
                         (re.match(r'io_in_(\d+)_', p).group(1)
                          for p in pnames if re.match(r'io_in_(\d+)_', p)))
        self.has_in_ready = any(re.fullmatch(r'io_in_\d+_ready', p) for p in pnames)
        self.has_out_ready = 'io_out_ready' in pnames
        self.chosen_w = next((w for d, w, p in self.ports if p == 'io_chosen'), None)

        # payload 字段：顺序 = golden **输出**端口顺序（= bundle 的规范顺序）
        self.fields = []         # (key, width)  key 形如 'bits_ppn' 或 'bits'
        for d, w, p in self.ports:
            mm = re.match(r'io_out_(bits.*)$', p)
            if mm:
                self.fields.append((mm.group(1), w))
        # 逐输入的字段端口是否存在
        self.have = {}           # key -> set(输入下标)
        for d, w, p in self.ports:
            mm = re.match(r'io_in_(\d+)_(bits.*)$', p)
            if mm:
                self.have.setdefault(mm.group(2), set()).add(int(mm.group(1)))

        derived = DERIVED_OUT.get(name, {})
        for k, w in derived.items():
            if (k, w) not in self.fields:
                raise SystemExit('%s: DERIVED_OUT 声明的 %s(%d 位) 不在输出端口表里'
                                 % (name, k, w))
        self.derived = derived
        self.fields = [(k, w) for k, w in self.fields if k not in derived]

        # 校验不对称表：凡是"不是每个输入都有"的字段，必须在 ASYMMETRY 里给出常量
        asym = ASYMMETRY.get(name, {})
        missing = {k: sorted(set(range(self.n)) - self.have.get(k, set()))
                   for k, _ in self.fields}
        missing = {k: v for k, v in missing.items() if v}
        if set(missing) != set(asym):
            raise SystemExit('%s: 字段缺口 %s 与 ASYMMETRY 表 %s 对不上'
                             % (name, sorted(missing), sorted(asym)))
        self.missing = missing
        self.asym = asym

        self.w = sum(w for _, w in self.fields)
        self.idx_w = max(1, (self.n - 1).bit_length())
        if self.chosen_w is not None and self.chosen_w != self.idx_w:
            raise SystemExit('%s: io_chosen 宽度 %d != $clog2(N=%d)=%d'
                             % (name, self.chosen_w, self.n, self.idx_w))

    def field_id(self, key):
        """struct 里的字段名：去掉 bits_ 前缀；裸 bits 记作 payload；撞保留字加 _f。"""
        s = 'payload' if key == 'bits' else key[len('bits_'):]
        return s + '_f' if s in SV_KEYWORDS else s

    def field_lsb(self, key):
        """字段在打平总线里的 LSB 位置（字段表靠前者占高位）。"""
        off = 0
        for k, w in reversed(self.fields):
            if k == key:
                return off
            off += w
        raise KeyError(key)

    def in_expr(self, i, key):
        """第 i 路输入的某字段表达式：有端口用端口，没有用 golden 的常量。"""
        if i in self.have.get(key, set()):
            return 'io_in_%d_%s' % (i, key)
        return self.asym[key]


# ---------------------------------------------------------------------------
# wrapper 生成
# ---------------------------------------------------------------------------
def pkg_name(v):
    return v.name.lower() + '_pkg'


def wrapper(v):
    multi = len(v.fields) > 1
    L = []
    A = L.append
    A('// =============================================================================')
    A('// %s.sv —— 轮转仲裁器家族薄 wrapper：%s' % (v.name, ROLE[v.name]))
    A('//')
    A('// 本变体规模：仲裁宽度 N=%d，payload 打平 W=%d 位（%d 个字段），'
      'chosen/lastGrant %d 位。' % (v.n, v.w, len(v.fields), v.idx_w))
    A('//   端口面：in_ready 输出%s、out_ready 输入%s、io_chosen 输出%s。'
      % ('有' if v.has_in_ready else '★无★',
         '有' if v.has_out_ready else '★无★',
         '有' if v.chosen_w else '无'))
    if not v.has_out_ready:
        A('//   （golden 里 io_out_ready 被常量 1 折掉了，所以端口表里没有它；'
          '本文件给核接 1\'b1。）')
    A('//   例化者：%s。' % USERS[v.name])
    if v.missing:
        A('//   ★golden 的不对称★：%s —— 只有部分输入有真端口，其余各路在 golden 的'
          % '、'.join('%s 仅 in_%s 有端口（其余填 %s）'
                      % (k, '/'.join(str(x) for x in sorted(v.have.get(k, set()))), v.asym[k])
                      for k in sorted(v.missing)))
        A('//   选择表里是常量。照抄，不许补齐成对称（FM 不做可达性分析）。')
    if v.derived:
        A('//   ★golden 的派生输出★：%s 没有任何输入端口来源，golden 用一张'
          % '、'.join(sorted(v.derived)))
        A('//   「下标即取值」的常数表按 chosen 取值（等价于把 chosen 零扩展）。照抄该结构。')
    A('//')
    A('// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv')
    A('// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由')
    A('// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。')
    A('//')
    A('// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)')
    A('// golden 对照：G1-canonical/golden-rtl/%s.sv' % v.name)
    A('// =============================================================================')
    if multi:
        A('package %s;' % pkg_name(v))
        A('  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。')
        A('  // 打平成 %d 位送进仲裁核，核只按 chosen 选一路，不看字段结构。' % v.w)
        kw = [k for k, _ in v.fields if v.field_id(k) != (
              'payload' if k == 'bits' else k[len('bits_'):])]
        if kw:
            A('  // 注：%s 去掉 bits_ 前缀后撞上 SV 保留字，加 _f 后缀。'
              % '、'.join(kw))
        A('  typedef struct packed {')
        wmax = max(len('logic [%d:0]' % (w - 1)) if w > 1 else len('logic')
                   for _, w in v.fields)
        for k, w in v.fields:
            decl = 'logic [%d:0]' % (w - 1) if w > 1 else 'logic'
            A('    %-*s %s;' % (wmax, decl, v.field_id(k)))
        A('  } payload_t;')
        A('endpackage')
        A('')
    hdr = 'module %s%s(' % (v.name, (' import %s::*; ' % pkg_name(v)) if multi else '')
    A(hdr)
    A(v.port_text)
    A(');')
    A('  localparam int N = %d;' % v.n)
    if multi:
        A('  localparam int W = $bits(payload_t);')
    else:
        A('  localparam int W = %d;' % v.w)
    A('')
    # ---- payload 打包 ----
    # ★打包维序必须是 [N-1:0][W-1:0]（外层路数、内层位宽）★：写反了就是 W 个
    # N 位元素，位数总和一样、编译器不报错，但每一路只拿到前 N 位 —— 本 UT 首跑
    # 就是被这个咬的（_5/_6/_7/_14 四个单字段变体 out_bits 全 X）。
    in_decl = ('payload_t [N-1:0]' if multi
               else 'logic [N-1:0][%d:0]' % (v.w - 1))
    out_decl = 'payload_t' if multi else 'logic [%d:0]' % (v.w - 1)
    A('  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。')
    A('  %s in_payload;' % in_decl)
    for i in range(v.n):
        exprs = [v.in_expr(i, k) for k, _ in v.fields]
        if len(exprs) == 1:
            A('  assign in_payload[%d] = %s;' % (i, exprs[0]))
        else:
            A('  assign in_payload[%d] = {' % i)
            for j, e in enumerate(exprs):
                A('    %s%s' % (e, ',' if j < len(exprs) - 1 else '};'))
    A('')
    # ---- 核例化 ----
    vlds = ', '.join('io_in_%d_valid' % i for i in reversed(range(v.n)))
    A('  %s out_payload;' % out_decl)
    if v.chosen_w is None and v.derived:
        A('  logic [%d:0] chosen;   // golden 没有 io_chosen 端口，但派生输出要用它'
          % (v.idx_w - 1))
    A('  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (')
    A('    .clock     (clock),')
    A('    .reset     (reset),')
    A('    .in_valid  (%s),' % _wrap_concat(vlds, 16))
    A('    .in_bits   (in_payload),')
    if v.has_in_ready:
        rdys = ', '.join('io_in_%d_ready' % i for i in reversed(range(v.n)))
        A('    .in_ready  (%s),' % _wrap_concat(rdys, 16))
    else:
        A('    .in_ready  (),                 // 本变体 golden 无 in_ready 输出端口')
    if v.has_out_ready:
        A('    .out_ready (io_out_ready),')
    else:
        A("    .out_ready (1'b1),             // 本变体 golden 无 io_out_ready 端口（恒 1）")
    A('    .out_valid (io_out_valid),')
    A('    .out_bits  (out_payload),')
    if v.chosen_w is not None:
        A('    .chosen    (io_chosen)')
    elif v.derived:
        A('    .chosen    (chosen)')
    else:
        A('    .chosen    ()                  // 本变体 golden 无 io_chosen 输出端口')
    A('  );')
    A('')
    # ---- 拆包 ----
    A('  // 拆包：与上面的打包共用同一张字段表。')
    for k, w in v.fields:
        if multi:
            A('  assign io_out_%s = out_payload.%s;' % (k, v.field_id(k)))
        else:
            A('  assign io_out_%s = out_payload;' % k)
    for k, w in sorted(v.derived.items()):
        A('')
        A('  // io_out_%s：golden 用一张常数表 `_GEN[chosen]`，第 idx 项恒等于 idx。' % k)
        A('  //   照抄这张表的结构（值上等于把 chosen 零扩展到 %d 位）。' % w)
        A('  logic [%d:0][%d:0] %s_by_index;' % ((1 << v.idx_w) - 1, w - 1, v.field_id(k)))
        A('  always_comb')
        A('    for (int idx = 0; idx < %d; idx++) %s_by_index[idx] = %d\'(idx);'
          % (1 << v.idx_w, v.field_id(k), w))
        A('  assign io_out_%s = %s_by_index[chosen];' % (k, v.field_id(k)))
    A('endmodule')
    return '\n'.join(L) + '\n'


def _wrap_concat(items, indent):
    """把 {a, b, c} 折行到 88 列以内。"""
    text = '{' + items + '}'
    if len(text) + indent <= 88:
        return text
    parts = items.split(', ')
    lines, cur = [], ''
    for p in parts:
        cand = (cur + ', ' + p) if cur else p
        if len(cand) + indent + 1 > 86:
            lines.append(cur + ',')
            cur = p
        else:
            cur = cand
    lines.append(cur)
    pad = '\n' + ' ' * (indent + 1)
    return '{' + pad.join(lines) + '}'


# ---------------------------------------------------------------------------
# tb 生成
# ---------------------------------------------------------------------------
MAXPAY = 384            # 32 的整数倍，便于按 32 位字随机填充
MAXIN = 32              # 家族最宽的一路（RRArbiterInit_7）


def tb(vs):
    payw = [0] * MAXIN
    for v in vs:
        for i in range(v.n):
            payw[i] = max(payw[i], v.w)
    L = []
    A = L.append
    A('// =============================================================================')
    A('// tb —— RRArbiterInit 轮转仲裁器家族 UT：%d 个 golden 变体与重写件逐个双例化比对。' % len(vs))
    A('//')
    A('// 全家族共用一套激励：32 位 valid 向量 + 32 路 payload 随机总线 + 每变体一位')
    A('// out_ready，各变体按自己的 N/W 取切片。轮转仲裁器的状态只有一个 lastGrant，')
    A('// 所以"测到位"的判据很具体：**每个变体的 lastGrant 必须把 0..N-1 全部取遍**')
    A('// —— 取到 k 就意味着第 k 路真的赢过一次仲裁并握手成功。这条与 out_valid 的')
    A('// 0/1、每一路 in_ready 的 0/1 一起写进 TEST PASSED，覆盖不全即判失败。')
    A('//')
    A('// 激励形状：valid 全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 均匀随机六种轮换 ——')
    A('// 全 1 逼出"每拍都换人"的轮转，单点逼出"回绕一整圈"，稀疏/稠密覆盖中间态。')
    A('// out_ready 三种模式（恒 1 / 恒 0 / 随机）区分"选中"与"握手"两件事：恒 0 时')
    A('// lastGrant 必须纹丝不动，而 chosen 照样要跟着 valid 变。')
    A('// 另有约 1/5000 的单拍复位脉冲，走的是异步复位路径（golden 与本核都是')
    A('// posedge reset 异步复位），把复位值 0 也纳入比对。')
    A('//')
    A('// 本文件由 verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  localparam int NV = %d;' % len(vs))
    A('  localparam int MAXPAY = %d;' % MAXPAY)
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clk = 0; always #5 clk = ~clk;')
    A('  longint errors = 0, checks = 0;')
    A('')
    A('  logic          rst;')
    A('  logic [%d:0]   vld;' % (MAXIN - 1))
    A('  logic [MAXPAY-1:0] pay [%d];' % MAXIN)
    A('  logic [NV-1:0] oready;')
    A('  // 每一路 payload 需要多少位（= 用到这一路的变体里最宽的那个 W）')
    A('  localparam int PAYW [%d] = \'{%s};'
      % (MAXIN, ', '.join(str(x) for x in payw)))
    A('  // 每变体的仲裁宽度 N（覆盖判据要用）')
    A('  localparam int NIN [NV] = \'{%s};' % ', '.join(str(v.n) for v in vs))
    A('  localparam bit HASRDY [NV] = \'{%s};'
      % ', '.join("1'b1" if v.has_in_ready else "1'b0" for v in vs))
    A('')
    # 每变体的输出信号
    for v in vs:
        nm = v.name
        A('  // ---- %s : N=%d W=%d ----' % (nm, v.n, v.w))
        A('  logic g_%s_valid, i_%s_valid;' % (nm, nm))
        for d, w, p in v.ports:
            mm = re.match(r'io_out_(bits.*)$', p)
            if mm:
                fid = v.field_id(mm.group(1)) if mm.group(1) not in v.derived \
                    else (mm.group(1)[len('bits_'):])
                A('  logic [%d:0] g_%s_%s, i_%s_%s;' % (w - 1, nm, fid, nm, fid))
        if v.chosen_w:
            A('  logic [%d:0] g_%s_chosen, i_%s_chosen;' % (v.chosen_w - 1, nm, nm))
        if v.has_in_ready:
            A('  logic [%d:0] g_%s_rdy, i_%s_rdy;' % (v.n - 1, nm, nm))
    A('')
    # 例化
    for vi, v in enumerate(vs):
        for side in ('g', 'i'):
            mod = v.name if side == 'g' else v.name + '_xs'
            A('  %s u_%s_%s (' % (mod, side, v.name))
            conns = []
            for d, w, p in v.ports:
                conns.append('    .%s (%s)' % (p, _tb_conn(v, vi, side, p)))
            A(',\n'.join(conns))
            A('  );')
    A('')
    A('  // ---- 覆盖 ----')
    A('  // cov_lg[v] 的第 k 位 = 变体 v 的 golden lastGrant 取到过 k')
    A('  // （探的是 golden 自己的寄存器名，golden 已冻结，探针不会腐烂）')
    A('  logic [%d:0] cov_lg [NV];' % (MAXIN - 1))
    A('  logic [1:0]  cov_ov [NV];')
    A('  logic [%d:0] cov_rdy0 [NV], cov_rdy1 [NV];' % (MAXIN - 1))
    A('')
    A('  `define CK(g,i,nm) \\')
    A('    begin checks++; if ((g) !== (i)) begin errors++; \\')
    A('      if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, nm, (g), (i)); \\')
    A('    end end')
    A('')
    A('  task automatic check();')
    for vi, v in enumerate(vs):
        nm = v.name
        A('    `CK(g_%s_valid, i_%s_valid, "%s.out_valid")' % (nm, nm, nm))
        for d, w, p in v.ports:
            mm = re.match(r'io_out_(bits.*)$', p)
            if mm:
                fid = v.field_id(mm.group(1)) if mm.group(1) not in v.derived \
                    else (mm.group(1)[len('bits_'):])
                A('    `CK(g_%s_%s, i_%s_%s, "%s.%s")' % (nm, fid, nm, fid, nm, fid))
        if v.chosen_w:
            A('    `CK(g_%s_chosen, i_%s_chosen, "%s.chosen")' % (nm, nm, nm))
        if v.has_in_ready:
            A('    `CK(g_%s_rdy, i_%s_rdy, "%s.in_ready")' % (nm, nm, nm))
        A('    cov_lg[%d][u_g_%s.ctrl_validMask_grantMask_lastGrant] = 1\'b1;' % (vi, nm))
        A('    cov_ov[%d][g_%s_valid] = 1\'b1;' % (vi, nm))
        if v.has_in_ready:
            A('    for (int k = 0; k < %d; k++)' % v.n)
            A('      if (g_%s_rdy[k]) cov_rdy1[%d][k] = 1\'b1; else cov_rdy0[%d][k] = 1\'b1;'
              % (nm, vi, vi))
    A('  endtask')
    A('')
    A('  task automatic drive();')
    A('    int mode;')
    A('    mode = $urandom_range(0, 5);')
    A('    case (mode)')
    A("      0: vld = '0;")
    A("      1: vld = '1;")
    A('      2: vld = 32\'b1 << $urandom_range(0, %d);' % (MAXIN - 1))
    A('      3: vld = $urandom & $urandom;          // 稀疏')
    A('      4: vld = $urandom | $urandom;          // 稠密')
    A('      default: vld = $urandom;')
    A('    endcase')
    A('    case ($urandom_range(0, 3))')
    A("      0: oready = '0;                        // 恒不收：lastGrant 必须不动")
    A("      1: oready = '1;")
    A('      default: oready = $urandom;')
    A('    endcase')
    A('    for (int i = 0; i < %d; i++)' % MAXIN)
    A('      for (int b = 0; b < MAXPAY; b += 32)')
    A('        if (b < PAYW[i]) pay[i][b+:32] = $urandom;')
    A('    // 约 1/5000 的单拍异步复位脉冲，把复位值也纳入比对')
    A("    rst = ($urandom_range(0, 4999) == 0);")
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    for (int v = 0; v < NV; v++) begin')
    A("      cov_lg[v] = '0; cov_ov[v] = '0; cov_rdy0[v] = '0; cov_rdy1[v] = '0;")
    A('    end')
    A("    rst = 1'b1; vld = '0; oready = '0;")
    A('    for (int i = 0; i < %d; i++) pay[i] = \'0;' % MAXIN)
    A('    repeat (8) @(posedge clk);')
    A('    #1; drive(); rst = 1\'b0;')
    A('    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end')
    A('    report();')
    A('    $finish;')
    A('  end')
    A('')
    A('  task automatic report();')
    A('    int bad = 0;')
    A('    $display("--- coverage: lastGrant 取值 / out_valid 0-1 / in_ready 逐路 0-1 ---");')
    A('    for (int v = 0; v < NV; v++) begin')
    A('      int nlg = 0, nr0 = 0, nr1 = 0;')
    A('      for (int k = 0; k < NIN[v]; k++) begin')
    A("        if (cov_lg[v][k]) nlg++;")
    A("        if (cov_rdy0[v][k]) nr0++;")
    A("        if (cov_rdy1[v][k]) nr1++;")
    A('      end')
    A("      if (nlg != NIN[v] || cov_ov[v] != 2'b11) bad++;")
    A('      if (HASRDY[v] && (nr0 != NIN[v] || nr1 != NIN[v])) bad++;')
    A('      $display("  variant[%0d] N=%0d : lastGrant %0d/%0d, out_valid cov=%b, in_ready 0:%0d 1:%0d",')
    A('               v, NIN[v], nlg, NIN[v], cov_ov[v], nr0, nr1);')
    A('    end')
    A('    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);')
    A('    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");')
    A('    else $display("TEST FAILED");')
    A('  endtask')
    A('endmodule')
    return '\n'.join(L) + '\n'


def _tb_conn(v, vi, side, p):
    if p == 'clock':
        return 'clk'
    if p == 'reset':
        return 'rst'
    if p == 'io_out_ready':
        return 'oready[%d]' % vi
    if p == 'io_out_valid':
        return '%s_%s_valid' % (side, v.name)
    if p == 'io_chosen':
        return '%s_%s_chosen' % (side, v.name)
    m = re.match(r'io_in_(\d+)_valid$', p)
    if m:
        return 'vld[%s]' % m.group(1)
    m = re.match(r'io_in_(\d+)_ready$', p)
    if m:
        return '%s_%s_rdy[%s]' % (side, v.name, m.group(1))
    m = re.match(r'io_in_(\d+)_(bits.*)$', p)
    if m:
        i, key = int(m.group(1)), m.group(2)
        lsb = v.field_lsb(key)
        w = dict(v.fields)[key]
        return 'pay[%d][%d:%d]' % (i, lsb + w - 1, lsb) if w > 1 \
            else 'pay[%d][%d]' % (i, lsb)
    m = re.match(r'io_out_(bits.*)$', p)
    if m:
        key = m.group(1)
        fid = v.field_id(key) if key not in v.derived else key[len('bits_'):]
        return '%s_%s_%s' % (side, v.name, fid)
    raise SystemExit('tb: 不认识的端口 %s' % p)


# ---------------------------------------------------------------------------
# README（差异维度矩阵）
# ---------------------------------------------------------------------------
def readme(vs):
    L = []
    A = L.append
    A('# RRArbiterInit 家族 UT（15 个变体）')
    A('')
    A('golden 里同一份 Chisel（rocket-chip `LockingRRArbiter`(count=1)）生成了 15 个模块。')
    A('本 UT 一口气双例化全部 15 个变体逐拍比对；FM 逐变体各出一份 receipt。')
    A('')
    A('## 差异维度矩阵（全部从 golden 端口表实测，见 gen.py 的解析）')
    A('')
    A('| 变体 | golden 行数 | N | payload W / 字段数 | chosen 位宽 | in_ready | out_ready | io_chosen | 例化者 |')
    A('|---|---|---|---|---|---|---|---|---|')
    for v in vs:
        nl = len((GOLDEN / (v.name + '.sv')).read_text().split('\n'))
        A('| `%s` | %d | %d | %d / %d | %d | %s | %s | %s | %s |'
          % (v.name, nl, v.n, v.w, len(v.fields), v.idx_w,
             '有' if v.has_in_ready else '无',
             '有' if v.has_out_ready else '无（常量 1）',
             '有' if v.chosen_w else '无', USERS[v.name]))
    A('')
    A('结论：**15/15 全部落在同一个核**（`xs_RRArbiterInit_core`，rtl/common/RRArbiterInit.sv）。')
    A('依据是上表只有 6 个维度在变，且每一个都能由参数或 wrapper 接线吸收：')
    A('')
    A('1. `N`（3/4/5/6/8/16/32）→ 核参数；')
    A('2. payload（36..383 位、1..94 个字段）→ 打平成核参数 `W`，wrapper 负责拼/拆；')
    A('3. `chosen` 位宽 = `$clog2(N)`，不是独立维度（脚本已 assert 15/15 相符）；')
    A('4. 无 `in_ready` 输出 → wrapper 把核的 `in_ready` 悬空；')
    A('5. 无 `out_ready` 输入 → wrapper 接 `1\'b1`（golden 里就是被常量 1 折掉的）；')
    A('6. 无 `io_chosen` 输出 → wrapper 把核的 `chosen` 悬空。')
    A('')
    A('另有两处 **golden 自己的不对称**，由 wrapper 逐字照抄，不许"补齐"：')
    A('')
    for name, d in sorted(ASYMMETRY.items()):
        v = next(x for x in vs if x.name == name)
        for k, c in sorted(d.items()):
            A('- `%s.%s`：只有 `io_in_%s` 有真端口，其余各路在 golden 的选择表里是常量 `%s`；'
              % (name, k, '/'.join(str(i) for i in sorted(v.have.get(k, set()))), c))
    for name, d in sorted(DERIVED_OUT.items()):
        for k, w in sorted(d.items()):
            A('- `%s.%s`：没有任何输入来源，golden 用一张「下标即取值」的 %d 位常数表按'
              ' `chosen` 取（等价于零扩展），wrapper 照抄该结构。' % (name, k, w))
    A('')
    A('还有一条实测结论：`RRArbiterInit_5` 与 `RRArbiterInit_14` 的 golden 文件**逐字节相同**')
    A('（`diff <(sed s/_5/XX/ RRArbiterInit_5.sv) <(sed s/_14/XX/ RRArbiterInit_14.sv)` 为空），')
    A('firtool 没有把它们 dedup 掉；本仓照样给两个薄 wrapper、各证一次。')
    A('')
    A('## 非 2 的幂的 N：选择表怎么补')
    A('')
    A('N=3/5/6 时 `chosen` 的取值域比请求方多。golden 把多出来的表项**填第 0 路**（实测')
    A('`RRArbiterInit_12` 的 `{in0, in2, in1, in0}`、`_4` 的 8 项表尾两项、`_20` 的尾三项），')
    A('核里照抄这条补法。')
    A('')
    A('★这一条**不要**拿"FM 不做可达性分析"去解释★ —— 实测不成立：`mutants.py` 的 F3')
    A('把填法改成填 0，FM 照样 `native SUCCEEDED / failing 0`。因为 `chosen` 不是自由变量，')
    A('它的取值域由逻辑本身决定（只会被赋 0..N-1），这些表项在任何输入组合下都选不中。')
    A('所以照抄是**零成本的忠实**，不是 FM 逼的；那条规矩真正管的是自由寄存器 `lastGrant`')
    A('（F1 实证：异步复位改同步复位，UT 全绿而 FM 当场 failing 2）。')
    A('')
    A('## 判别力负测（双向）')
    A('')
    A('`make mutants` 往核里逐个注入真 bug，要求 UT 全部抓到；`make mutants-cov` 反过来')
    A('考覆盖闸自己（跑 20 拍，errors=0 但覆盖不全 —— 闸必须判 TEST FAILED）；')
    A('`make mutants-fm` 在 FM 侧做同样的两个方向，其中一条是**只有 FM 看得见**的')
    A('复位域变异（异步复位改同步），另一条是**不该报警的对照**。表与口径见 mutants.py。')
    A('')
    A('## 跑法')
    A('')
    A('```')
    A('make run SEED=1 INITREG=random     # 3 seed × 2 initreg × 200k 拍')
    A('make fm                            # 15 个变体逐个 FM')
    A('make mutants && make mutants-cov   # 判别力负测（两个方向）')
    A('bash ../../../scripts/run_proof.sh RRArbiterInitVariants <变体名>...')
    A('```')
    return '\n'.join(L) + '\n'


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text() != text:
        path.write_text(text)
        return True
    return False


def main():
    vs = [Variant(n) for n in FAMILY]
    n = 0
    for v in vs:
        if v.name == HANDWRITTEN:
            continue
        if write(REPO / 'rtl' / 'common' / ('%s.sv' % v.name), wrapper(v)):
            n += 1
    if write(HERE / 'tb.sv', tb(vs)):
        n += 1
    if write(HERE / 'README.md', readme(vs)):
        n += 1
    print('gen.py: %d 个薄 wrapper + tb + README，已更新 %d 个文件'
          % (len(vs) - 1, n) if n else 'gen.py: 全部已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
