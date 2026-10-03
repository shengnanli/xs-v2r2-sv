#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fastarbiter_l2.py —— 生成 L2（CoupledL2 tl2chi）里 5 个 FastArbiter 变体的薄 wrapper + UT tb。

家族规矩（CONVENTIONS「变体家族」）：一个参数化核 + 每变体一个薄文件，核体绝不复制。
  核   = rtl/common/xs_FastArbiter_core.sv（手写，utility.FastArbiter）
  薄壳 = rtl/uncore/FastArbiter_{3,4,5,6,7}.sv（本脚本生成）
  tb   = verif/ut/FastArbiterL2/tb.sv（本脚本生成）

五个变体的例化者（golden 实测 `grep -n '^  FastArbiter_N ' *.sv`）：
  FastArbiter_3  MSHRCtl.txreq_arb      16 个 MSHR → CHI TXREQ
  FastArbiter_4  MSHRCtl.txrsp_arb      16 个 MSHR → CHI TXRSP（CompAck）
  FastArbiter_5  SourceB.issueArb        4 个 probe 表项 → TileLink B 通道
  FastArbiter_6  MSHRCtl.source_b_arb   16 个 MSHR → SourceB.task（Probe 请求）
  FastArbiter_7  MSHRCtl.mshr_task_arb  16 个 MSHR → RequestArb（mshrTask）

★维度全部从 golden 端口表实测★：N、字段名/宽度/顺序都由解析得到。唯一手工录入的
是 CONST 表（golden 里"没有输入端口、却有输出端口"的字段 —— 16 个 MSHR 给这些字段
喂的都是同一个常量，firtool 于是把输入端口删掉、把输出折成 `K & |chosenOH`）。
脚本对 CONST 表做双向核对（fail-closed）：
  (a) 表里的字段集合 == golden 里"有输出无输入"的字段集合；
  (b) 逐字段解析 golden 的 `assign io_out_bits_<f> = ...`，在 |chosenOH=1 时求值
      必须等于表中常量，在 |chosenOH=0 时必须为 0（否则它不是"常量走 Mux1H"）。

用法:
  python3 scripts/gen_fastarbiter_l2.py          # 幂等写入（内容不变不碰文件）
  python3 scripts/gen_fastarbiter_l2.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))
UT_DIR = REPO / 'verif' / 'ut' / 'FastArbiterL2'

FAMILY = ['FastArbiter_3', 'FastArbiter_4', 'FastArbiter_5',
          'FastArbiter_6', 'FastArbiter_7']

USERS = {
    'FastArbiter_3': 'MSHRCtl.sv（实例 txreq_arb）',
    'FastArbiter_4': 'MSHRCtl.sv（实例 txrsp_arb）',
    'FastArbiter_5': 'SourceB.sv（实例 issueArb）',
    'FastArbiter_6': 'MSHRCtl.sv（实例 source_b_arb）',
    'FastArbiter_7': 'MSHRCtl.sv（实例 mshr_task_arb）',
}
ROLE = {
    'FastArbiter_3': 'L2 MSHRCtl 16 个 MSHR 发往 CHI TXREQ（Acquire/读写请求）的仲裁',
    'FastArbiter_4': 'L2 MSHRCtl 16 个 MSHR 发往 CHI TXRSP（CompAck）的仲裁',
    'FastArbiter_5': 'L2 SourceB 4 个 probe 缓冲表项发往上层 B 通道的仲裁',
    'FastArbiter_6': 'L2 MSHRCtl 16 个 MSHR 发往 SourceB 的 Probe 请求仲裁',
    'FastArbiter_7': 'L2 MSHRCtl 16 个 MSHR 发往 RequestArb 的 mshrTask 仲裁（载荷最宽）',
}

# golden "有输出无输入"的常量字段：值 + 出处（coupledL2/tl2chi/MSHR.scala）
CONST = {
    'FastArbiter_3': {
        'bits_qos': ("4'hE", 'MSHR.scala:367 oa.qos := Fill(QOS_WIDTH, 1) - 1'),
        'bits_size': ("3'h6", 'MSHR.scala:394 oa.size := log2Ceil(blockBytes)（64B 行）'),
        'bits_memAttr_cacheable': ("1'h1", 'MSHR.scala:416 MemAttr(cacheable = true)'),
        'bits_memAttr_ewa': ("1'h1", 'MSHR.scala:419 MemAttr(ewa = true)'),
        'bits_snpAttr': ("1'h1", 'MSHR.scala:421 oa.snpAttr := true.B'),
    },
    'FastArbiter_4': {
        'bits_opcode': ("5'h2", 'MSHR.scala:347 orsp.opcode := CompAck'),
    },
    'FastArbiter_5': {},
    'FastArbiter_6': {
        'bits_opcode': ("3'h6", 'MSHR.scala:435 ob.opcode := Probe'),
    },
    'FastArbiter_7': {
        'bits_mshrTask': ("1'h1", 'MSHR.scala mp_* 各分支 mshrTask := true.B'),
    },
}

SV_KEYWORDS = {
    'alias', 'always', 'and', 'assign', 'bit', 'buf', 'byte', 'case', 'cell',
    'config', 'const', 'default', 'disable', 'do', 'edge', 'else', 'end', 'enum',
    'event', 'final', 'first', 'force', 'function', 'generate', 'if', 'import',
    'initial', 'inout', 'input', 'int', 'integer', 'interface', 'local', 'logic',
    'module', 'new', 'not', 'null', 'or', 'output', 'package', 'parameter',
    'priority', 'rand', 'real', 'ref', 'reg', 'return', 'signed', 'static',
    'string', 'struct', 'table', 'task', 'time', 'type', 'union', 'unique',
    'var', 'void', 'wait', 'wire', 'with', 'xor',
}


def lit(s):
    """解析 SV 定宽字面量 N'hX / N'bX / N'dX → (value, width)。"""
    m = re.fullmatch(r"(\d+)'([hbd])([0-9a-fA-F_]+)", s.strip())
    if not m:
        raise ValueError(s)
    base = {'h': 16, 'b': 2, 'd': 10}[m.group(2)]
    return int(m.group(3).replace('_', ''), base), int(m.group(1))


def eval_const_expr(expr, any_grant):
    """在 |chosenOH = any_grant 下求 golden 常量输出表达式的值。

    只认三种形状（遇到别的就报错，fail-closed）：
      `|chosenOH`                       —— 1 位
      `(|chosenOH) ? K : 0`             —— 三目
      `{lit, |chosenOH, lit, ...}`      —— 拼接
    返回 (value, width)。"""
    g = "1'h%d" % (1 if any_grant else 0)
    e = re.sub(r'\s+', ' ', expr).strip()
    e = e.replace('(|chosenOH)', g).replace('|chosenOH', g)
    m = re.fullmatch(r"(1'h[01]) \? (\S+) : (\S+)", e)
    if m:
        c, _ = lit(m.group(1))
        return lit(m.group(2) if c else m.group(3))
    m = re.fullmatch(r'\{(.*)\}', e)
    if m:
        val, wid = 0, 0
        for part in m.group(1).split(','):
            v, w = lit(part)
            val, wid = (val << w) | v, wid + w
        return val, wid
    return lit(e)


class Variant:
    def __init__(self, name):
        self.name = name
        self.src = (GOLDEN / (name + '.sv')).read_text()
        m = re.search(r'^module %s\(\n(.*?)\n\);\n' % name, self.src, re.S | re.M)
        if not m:
            raise SystemExit('golden %s.sv 里找不到 module 端口表' % name)
        self.port_text = m.group(1)
        self.ports = []
        for ln in self.port_text.split('\n'):
            mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
            if not mm:
                raise SystemExit('%s: 解析不了端口行 %r' % (name, ln))
            w = int(mm.group(2)) + 1 if mm.group(2) else 1
            self.ports.append((mm.group(1), w, mm.group(3)))
        pn = [p for _, _, p in self.ports]
        for need in ('clock', 'reset', 'io_out_ready', 'io_out_valid'):
            if need not in pn:
                raise SystemExit('%s: 端口表缺 %s —— 不是标准 FastArbiter 端口面' % (name, need))
        extra = [p for p in pn if not re.match(r'(clock|reset|io_in_\d+_|io_out_)', p)]
        if extra:
            raise SystemExit('%s: 有核不认识的端口 %s（如 io_chosen）' % (name, extra))
        self.n = 1 + max(int(re.match(r'io_in_(\d+)_valid$', p).group(1))
                         for p in pn if re.match(r'io_in_(\d+)_valid$', p))
        for i in range(self.n):
            for s in ('valid', 'ready'):
                if 'io_in_%d_%s' % (i, s) not in pn:
                    raise SystemExit('%s: 缺 io_in_%d_%s' % (name, i, s))
        # 字段：顺序 = golden 输出端口顺序
        self.fields = [(re.match(r'io_out_(bits.*)$', p).group(1), w)
                       for d, w, p in self.ports if p.startswith('io_out_bits')]
        have = {}
        for d, w, p in self.ports:
            mm = re.match(r'io_in_(\d+)_(bits.*)$', p)
            if mm:
                have.setdefault(mm.group(2), set()).add(int(mm.group(1)))
        width = dict(self.fields)
        for k, idx in have.items():
            if k not in width:
                raise SystemExit('%s: 输入字段 %s 没有对应输出' % (name, k))
            if idx != set(range(self.n)):
                raise SystemExit('%s: 字段 %s 只有部分输入有端口 %s（本族不应出现）'
                                 % (name, k, sorted(idx)))
            for i in range(self.n):
                wi = next(w for d, w, p in self.ports if p == 'io_in_%d_%s' % (i, k))
                if wi != width[k]:
                    raise SystemExit('%s: io_in_%d_%s 宽 %d != 输出宽 %d'
                                     % (name, i, k, wi, width[k]))
        const_fields = {k for k, _ in self.fields if k not in have}
        self.const = CONST[name]
        if const_fields != set(self.const):
            raise SystemExit('%s: golden 常量字段 %s 与 CONST 表 %s 对不上'
                             % (name, sorted(const_fields), sorted(self.const)))
        for k, (val, _) in self.const.items():
            m2 = re.search(r'assign io_out_%s =(.*?);' % k, self.src, re.S)
            if not m2:
                raise SystemExit('%s: golden 里找不到 io_out_%s 的 assign' % (name, k))
            v1, w1 = eval_const_expr(m2.group(1), True)
            v0, w0 = eval_const_expr(m2.group(1), False)
            kv, kw = lit(val)
            if (v1, w1) != (kv, kw) or v0 != 0 or w0 != kw or kw != width[k]:
                raise SystemExit('%s: io_out_%s golden=%r 与 CONST %s 不符'
                                 % (name, k, m2.group(1).strip(), val))
        self.w = sum(w for _, w in self.fields)

    def fid(self, key):
        s = key[len('bits_'):]
        return s + '_f' if s in SV_KEYWORDS else s


def pkg_name(v):
    return v.name.lower() + '_pkg'


def wrapper(v):
    L = []
    A = L.append
    A('// =============================================================================')
    A('// %s.sv —— FastArbiter 家族薄 wrapper：%s' % (v.name, ROLE[v.name]))
    A('//')
    A('// 本变体规模：N=%d 路，载荷打平 W=%d 位（%d 个字段，其中 %d 个常量字段）。'
      % (v.n, v.w, len(v.fields), len(v.const)))
    A('//   例化者：%s。' % USERS[v.name])
    if v.const:
        A('//   常量字段：每个请求方给这些字段喂的都是同一个常量，firtool 于是删掉了它们')
        A('//   的输入端口、把输出折成 `K & |chosenOH`。本文件把常量喂进每一路，核里的')
        A('//   Mux1H 自然得出同一结果：')
        for k, (val, why) in v.const.items():
            A('//     %-24s = %-5s  —— %s' % (k[len('bits_'):], val, why))
    kw = [k for k, _ in v.fields if v.fid(k) != k[len('bits_'):]]
    if kw:
        A('//   注：%s 去掉 bits_ 前缀后撞上 SV 保留字，struct 成员名加 _f 后缀。'
          % '、'.join(kw))
    A('//')
    A('// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）')
    A('// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。')
    A('// 本文件由 scripts/gen_fastarbiter_l2.py 生成，勿手改。')
    A('// golden 对照：G1-canonical/golden-rtl/%s.sv' % v.name)
    A('// =============================================================================')
    A('package %s;' % pkg_name(v))
    A('  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。')
    A('  typedef struct packed {')
    wmax = max(len('logic [%d:0]' % (w - 1)) if w > 1 else 5 for _, w in v.fields)
    fmax = max(len(v.fid(k)) for k, _ in v.fields)
    for k, w in v.fields:
        decl = 'logic [%d:0]' % (w - 1) if w > 1 else 'logic'
        if k in v.const:
            A('    %-*s %-*s // 常量 %s' % (wmax, decl, fmax + 1, v.fid(k) + ';', v.const[k][0]))
        else:
            A('    %-*s %s;' % (wmax, decl, v.fid(k)))
    A('  } payload_t;')
    A('endpackage')
    A('')
    A('module %s import %s::*; (' % (v.name, pkg_name(v)))
    A(v.port_text)
    A(');')
    A('  localparam int N = %d;' % v.n)
    A('  localparam int W = $bits(payload_t);')
    A('')
    A('  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t（常量字段每路都喂同一个值）')
    A('  payload_t [N-1:0] in_payload;')
    for i in range(v.n):
        A('  assign in_payload[%d] = \'{' % i)
        items = []
        for k, _ in v.fields:
            rhs = v.const[k][0] if k in v.const else 'io_in_%d_%s' % (i, k)
            items.append('    %s: %s' % (v.fid(k), rhs))
        A(',\n'.join(items))
        A('  };')
    A('')
    A('  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core')
    A('  payload_t out_payload;')
    A('  xs_FastArbiter_core #(.N(N), .W(W)) u_core (')
    A('    .clock     (clock),')
    A('    .reset     (reset),')
    A('    .in_valid  (%s),' % concat(['io_in_%d_valid' % i for i in reversed(range(v.n))]))
    A('    .in_bits   (in_payload),')
    A('    .in_ready  (%s),' % concat(['io_in_%d_ready' % i for i in reversed(range(v.n))]))
    A('    .out_ready (io_out_ready),')
    A('    .out_valid (io_out_valid),')
    A('    .out_bits  (out_payload)')
    A('  );')
    A('')
    A('  // ---- 拆包：与打包共用同一张字段表')
    for k, _ in v.fields:
        A('  assign io_out_%s = out_payload.%s;' % (k, v.fid(k)))
    A('endmodule')
    return add_nav(L)


NAV_SECTIONS = ('// ---- 打包', '// ---- 核例化', '// ---- 拆包')


def add_nav(L):
    """>1500 行的文件按 readability_audit E 类要求在头注释末尾插「本文件导航」。

    导航占的行数固定（1 + 段数），先插占位再按插入后的实际行号回填，
    行号落在分节注释行上（审计会复核）。"""
    L = '\n'.join(L).split('\n')   # 端口表等元素自带换行，先摊平成真实行
    if len(L) + 1 + len(NAV_SECTIONS) <= 1500:
        return '\n'.join(L) + '\n'
    at = next(i for i, x in enumerate(L) if x.startswith('// golden 对照：')) + 1
    nav = ['// 本文件导航：'] + [''] * len(NAV_SECTIONS)
    L2 = L[:at] + nav + L[at:]
    for j, sec in enumerate(NAV_SECTIONS):
        ln = next(i for i, x in enumerate(L2) if x.strip().startswith(sec)) + 1
        L2[at + 1 + j] = '//   L%d %s' % (ln, sec[len('// ---- '):])
    return '\n'.join(L2) + '\n'


def concat(items, indent=16):
    text = '{' + ', '.join(items) + '}'
    if len(text) + indent <= 88:
        return text
    lines, cur = [], ''
    for p in items:
        cand = (cur + ', ' + p) if cur else p
        if len(cand) + indent + 1 > 86:
            lines.append(cur + ',')
            cur = p
        else:
            cur = cand
    lines.append(cur)
    return '{' + ('\n' + ' ' * (indent + 1)).join(lines) + '}'


# ---------------------------------------------------------------------------
# tb：五个变体各自双例化 golden vs <名>_xs，共用一套激励
# ---------------------------------------------------------------------------
def tb(vs):
    maxin = max(v.n for v in vs)
    maxpay = ((max(v.w for v in vs) + 31) // 32) * 32
    L = []
    A = L.append
    A('// =============================================================================')
    A('// tb —— L2 FastArbiter 家族 UT：%d 个 golden 变体与重写件逐个双例化逐拍比对。' % len(vs))
    A('//')
    A('// 共用一套激励：%d 位 valid 向量 + %d 路随机载荷 + 每变体一位 out_ready，' % (maxin, maxin))
    A('// 各变体按自己的 N/W 取切片。比对全部输出（out_valid / 每个 out 字段 / 每路 in_ready）。')
    A('//')
    A('// 覆盖判据（写进 TEST PASSED，不全即判失败），探 golden 自己的内部线：')
    A('//   · 每一路 k 都在"轮转命中"（rrSelOH&valids 非 0）时赢过一次握手；')
    A('//   · 每一路 k 都在"固定优先级兜底"时赢过一次握手；')
    A('//   · out_valid 取过 0/1；每路 in_ready 取过 0/1。')
    A('// 激励：valid 全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 均匀随机轮换；out_ready 恒 0 / 恒 1 /')
    A('// 随机三模式（恒 0 时两张掩码必须不动）；约 1/5000 的单拍异步复位脉冲。')
    A('//')
    A('// 本文件由 scripts/gen_fastarbiter_l2.py 生成，勿手改。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  localparam int NV = %d;' % len(vs))
    A('  localparam int MAXIN = %d;' % maxin)
    A('  localparam int MAXPAY = %d;' % maxpay)
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clk = 0; always #5 clk = ~clk;')
    A('  longint errors = 0, checks = 0;')
    A('')
    A('  logic              rst;')
    A('  logic [MAXIN-1:0]  vld;')
    A('  logic [MAXPAY-1:0] pay [MAXIN];')
    A('  logic [NV-1:0]     oready;')
    A("  localparam int NIN [NV] = '{%s};" % ', '.join(str(v.n) for v in vs))
    A('')
    for v in vs:
        nm = v.name
        A('  // ---- %s : N=%d W=%d ----' % (nm, v.n, v.w))
        A('  logic g_%s_valid, i_%s_valid;' % (nm, nm))
        A('  logic [%d:0] g_%s_rdy, i_%s_rdy;' % (v.n - 1, nm, nm))
        for k, w in v.fields:
            A('  logic [%d:0] g_%s_%s, i_%s_%s;' % (w - 1, nm, v.fid(k), nm, v.fid(k)))
    A('')
    for vi, v in enumerate(vs):
        for side in ('g', 'i'):
            mod = v.name if side == 'g' else v.name + '_xs'
            A('  %s u_%s_%s (' % (mod, side, v.name))
            A(',\n'.join('    .%s (%s)' % (p, tb_conn(v, vi, side, p))
                         for _, _, p in v.ports))
            A('  );')
    A('')
    A('  logic [MAXIN-1:0] cov_rr [NV], cov_first [NV], cov_rdy0 [NV], cov_rdy1 [NV];')
    A('  logic [1:0]       cov_ov [NV];')
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
        A('    `CK(g_%s_rdy, i_%s_rdy, "%s.in_ready")' % (nm, nm, nm))
        for k, _ in v.fields:
            A('    `CK(g_%s_%s, i_%s_%s, "%s.%s")' % (nm, v.fid(k), nm, v.fid(k), nm, v.fid(k)))
        A('    cov_ov[%d][g_%s_valid] = 1\'b1;' % (vi, nm))
        A('    for (int k = 0; k < %d; k++) begin' % v.n)
        A('      if (g_%s_rdy[k]) cov_rdy1[%d][k] = 1\'b1; else cov_rdy0[%d][k] = 1\'b1;'
          % (nm, vi, vi))
        A('      if (u_g_%s.chosenOH[k] && oready[%d]) begin' % (nm, vi))
        A('        if (|(u_g_%s.rrSelOH & u_g_%s.valids)) cov_rr[%d][k] = 1\'b1;'
          % (nm, nm, vi))
        A('        else cov_first[%d][k] = 1\'b1;' % vi)
        A('      end')
        A('    end')
    A('  endtask')
    A('')
    A('  task automatic drive();')
    A('    case ($urandom_range(0, 5))')
    A("      0: vld = '0;")
    A("      1: vld = '1;")
    A('      2: vld = %d\'b1 << $urandom_range(0, MAXIN-1);' % maxin)
    A('      3: vld = $urandom & $urandom;          // 稀疏')
    A('      4: vld = $urandom | $urandom;          // 稠密')
    A('      default: vld = $urandom;')
    A('    endcase')
    A('    case ($urandom_range(0, 3))')
    A("      0: oready = '0;                        // 恒不收：掩码必须不动")
    A("      1: oready = '1;")
    A('      default: oready = $urandom;')
    A('    endcase')
    A('    for (int i = 0; i < MAXIN; i++)')
    A('      for (int b = 0; b < MAXPAY; b += 32) pay[i][b+:32] = $urandom;')
    A("    rst = ($urandom_range(0, 4999) == 0);  // 单拍异步复位脉冲")
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    for (int v = 0; v < NV; v++) begin')
    A("      cov_rr[v] = '0; cov_first[v] = '0; cov_rdy0[v] = '0; cov_rdy1[v] = '0; cov_ov[v] = '0;")
    A('    end')
    A("    rst = 1'b1; vld = '0; oready = '0;")
    A("    for (int i = 0; i < MAXIN; i++) pay[i] = '0;")
    A('    repeat (8) @(posedge clk);')
    A("    #1; drive(); rst = 1'b0;")
    A('    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end')
    A('    report();')
    A('    $finish;')
    A('  end')
    A('')
    A('  task automatic report();')
    A('    int bad = 0;')
    A('    $display("--- coverage: 轮转命中赢 / 兜底赢 / in_ready 0 / in_ready 1（各路计数）---");')
    A('    for (int v = 0; v < NV; v++) begin')
    A('      int nrr = 0, nfi = 0, nr0 = 0, nr1 = 0;')
    A('      for (int k = 0; k < NIN[v]; k++) begin')
    A('        nrr += cov_rr[v][k]; nfi += cov_first[v][k];')
    A('        nr0 += cov_rdy0[v][k]; nr1 += cov_rdy1[v][k];')
    A('      end')
    A("      if (nfi != NIN[v] || nr0 != NIN[v] || nr1 != NIN[v] || cov_ov[v] != 2'b11) bad++;")
    A('      // 第 0 路永远不可能"轮转命中"（rrGrantMask[0] 恒 0），其余各路必须都命中过')
    A('      if (nrr != NIN[v] - 1 || cov_rr[v][0]) bad++;')
    A('      $display("  variant[%0d] N=%0d : rr %0d/%0d  first %0d/%0d  rdy0 %0d rdy1 %0d  ov=%b",')
    A('               v, NIN[v], nrr, NIN[v]-1, nfi, NIN[v], nr0, nr1, cov_ov[v]);')
    A('    end')
    A('    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);')
    A('    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");')
    A('    else $display("TEST FAILED");')
    A('  endtask')
    A('endmodule')
    return '\n'.join(L) + '\n'


def field_lsb(v, key):
    off = 0
    for k, w in reversed(v.fields):
        if k == key:
            return off
        off += w
    raise KeyError(key)


def tb_conn(v, vi, side, p):
    if p == 'clock':
        return 'clk'
    if p == 'reset':
        return 'rst'
    if p == 'io_out_ready':
        return 'oready[%d]' % vi
    if p == 'io_out_valid':
        return '%s_%s_valid' % (side, v.name)
    m = re.match(r'io_in_(\d+)_valid$', p)
    if m:
        return 'vld[%s]' % m.group(1)
    m = re.match(r'io_in_(\d+)_ready$', p)
    if m:
        return '%s_%s_rdy[%s]' % (side, v.name, m.group(1))
    m = re.match(r'io_in_(\d+)_(bits.*)$', p)
    if m:
        i, key = int(m.group(1)), m.group(2)
        lsb, w = field_lsb(v, key), dict(v.fields)[key]
        return 'pay[%d][%d:%d]' % (i, lsb + w - 1, lsb) if w > 1 else 'pay[%d][%d]' % (i, lsb)
    m = re.match(r'io_out_(bits.*)$', p)
    if m:
        return '%s_%s_%s' % (side, v.name, v.fid(m.group(1)))
    raise SystemExit('tb: 不认识的端口 %s' % p)


def outputs():
    vs = [Variant(n) for n in FAMILY]
    out = {REPO / 'rtl' / 'uncore' / ('%s.sv' % v.name): wrapper(v) for v in vs}
    out[UT_DIR / 'tb.sv'] = tb(vs)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    out = outputs()
    drift = []
    for path, text in out.items():
        cur = path.read_text() if path.exists() else None
        if cur != text:
            drift.append(path)
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)
    rel = [str(p.relative_to(REPO)) for p in drift]
    if args.check:
        if drift:
            print('gen_fastarbiter_l2: DRIFT %s' % rel)
            return 1
        print('gen_fastarbiter_l2: OK（%d 个文件与生成结果一致）' % len(out))
        return 0
    print('gen_fastarbiter_l2: 更新 %s' % rel if drift else 'gen_fastarbiter_l2: 全部已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
