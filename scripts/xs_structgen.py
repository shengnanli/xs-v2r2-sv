#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""xs_structgen.py —— "扁平 golden 端口/寄存器 ↔ 可读核的 struct" 机械派生的公共件（库，不单独运行）。

给 scripts/gen_vsplit.py / gen_vsegmentunit.py 这类生成器用。它只做三件机械的事：
  1. 读 golden 模块的端口表与 reg 声明（字段集合只能从 golden 现数，CONVENTIONS）；
  2. 按"前缀 → struct 类型"把扁平名归组，登记成 packed struct 的成员（多个变体 / 多个接口
     共用一个类型时取并集，同名成员位宽不一致直接拒绝）；
  3. 产出拆装代码：输入组 `always_comb x = '0; x.f = io_..._f;`（golden 没有的字段补 0）、
     输出组 `assign io_..._f = x.f;`、寄存器组（声明 golden 展平名 + 使能装载 + 读回成 struct）。
寄存器一律保持 golden 的展平名，FM 按名配对。任何核对不上的情况都 SystemExit（fail-closed）。
"""
import collections
import pathlib
import re

GOLDEN_DIR = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
REG_RE = re.compile(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+)\s*;')
EXC_W = 24


class GenError(SystemExit):
    pass


def die(msg):
    raise GenError('xs_structgen: ★拒绝生成★ ' + msg)


class Golden:
    """一个 golden 模块的端口表（有序）与寄存器表（有序）。"""

    def __init__(self, mod):
        self.mod = mod
        text = (GOLDEN_DIR / (mod + '.sv')).read_text()
        m = re.search(r'^module %s\((.*?)\n\);(.*?)^endmodule' % re.escape(mod), text, re.S | re.M)
        if not m:
            die('golden 里找不到 module %s' % mod)
        self.port_text = m.group(1).strip('\n')
        self.ports = []
        for line in self.port_text.splitlines():
            if not line.strip():
                continue
            pm = PORT_RE.match(line)
            if not pm:
                die('%s: 不认识的端口行 %r' % (mod, line))
            self.ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        self.regs = collections.OrderedDict()
        for line in m.group(2).splitlines():
            rm = REG_RE.match(line)
            if rm:
                self.regs[rm.group(2)] = int(rm.group(1)) + 1 if rm.group(1) else 1
        self.pw = {n: w for _, w, n in self.ports}
        self.pd = {n: d for d, _, n in self.ports}


def wdecl(w):
    return 'logic' if w == 1 else 'logic [%d:0]' % (w - 1)


def core_name(port):
    return port[3:] if port.startswith('io_') else port


class TypeSpace:
    """一组 packed struct。docs: 类型名 → 一句话说明（顺序 = 输出顺序，被嵌套者在前）。
    nest: 类型名 → [(扁平前缀, 成员名, 成员类型)]，如 flow_t: [('uop_', 'uop', 'uop_t')]。"""

    def __init__(self, docs, nest):
        self.docs = docs
        self.nest = nest
        self.members = collections.OrderedDict((n, collections.OrderedDict()) for n in docs)
        for typ, rules in nest.items():
            for _, member, sub in rules:
                self.members[typ][member] = sub

    def _add(self, typ, name, width):
        old = self.members[typ].get(name)
        if old is not None and old != width:
            die('%s.%s 位宽不一致 %r vs %r' % (typ, name, old, width))
        self.members[typ][name] = width

    def resolve(self, typ, field, width, declare):
        """扁平字段名 → 成员访问路径（如 '.uop.exceptionVec[3]'）。declare=True 时登记成员。"""
        for prefix, member, sub in self.nest.get(typ, ()):
            if field.startswith(prefix):
                return '.' + member + self.resolve(sub, field[len(prefix):], width, declare)
        m = re.fullmatch(r'exceptionVec_(\d+)', field)
        if m:
            if width != 1 or int(m.group(1)) >= EXC_W:
                die('%s.%s 不是合法的 exceptionVec 位' % (typ, field))
            if declare:
                self._add(typ, 'exceptionVec', EXC_W)
            elif self.members[typ].get('exceptionVec') != EXC_W:
                die('%s 没有 exceptionVec' % typ)
            return '.exceptionVec[%s]' % m.group(1)
        if declare:
            self._add(typ, field, width)
        elif self.members[typ].get(field) != width:
            die('%s.%s 不存在或位宽不符（要 %d，有 %r）' % (typ, field, width, self.members[typ].get(field)))
        return '.' + field

    def emit(self, indent='  '):
        out = []
        for name, doc in self.docs.items():
            mem = self.members[name]
            if not mem:
                die('类型 %s 没有成员' % name)
            out.append('%s// %s' % (indent, doc))
            out.append('%stypedef struct packed {' % indent)
            for mn, w in mem.items():
                out.append('%s  %-14s %s;' % (indent, w if isinstance(w, str) else wdecl(w), mn))
            out.append('%s} %s;' % (indent, name))
            out.append('')
        return out[:-1]


def classify_ports(g, groups, ts, declare=True):
    """groups: [(前缀, 类型, 核端口名)]。返回 [(dir, w, name, group_or_None, field)]；最长前缀优先。"""
    order = sorted(groups, key=lambda x: -len(x[0]))
    res = []
    gdir = {}
    for d, w, n in g.ports:
        for grp in order:
            if n.startswith(grp[0]):
                f = n[len(grp[0]):]
                ts.resolve(grp[1], f, w, declare)
                if gdir.setdefault(grp[2], d) != d:
                    die('%s: 接口组 %s 方向不一致' % (g.mod, grp[2]))
                res.append((d, w, n, grp, f))
                break
        else:
            res.append((d, w, n, None, None))
    return res


def classify_regs(g, groups, ts, declare=True):
    """groups: [(前缀, 类型, ...)]。返回 OrderedDict 前缀 → [(寄存器名, w, field)]；最长前缀优先。"""
    order = sorted(groups, key=lambda x: -len(x[0]))
    res = collections.OrderedDict((grp[0], []) for grp in groups)
    for n, w in g.regs.items():
        for grp in order:
            if n.startswith(grp[0]):
                f = n[len(grp[0]):]
                ts.resolve(grp[1], f, w, declare)
                res[grp[0]].append((n, w, f))
                break
    return res


def emit_reg_group(ts, regs, typ, sig, en, src, doc, ind='  ', const_zero=(), reset=False, readback=True):
    """一个整包打拍寄存器组：声明（golden 展平名）+ en 时从 src 装载 + 读回成 struct sig。
    const_zero: golden 里次态恒 0 的寄存器名集合（装载常量 0 而不是 src 的成员）。
    reset: True = 异步复位到 0（golden 的 RegInit）；readback=False 时不生成读回块。"""
    out = ['%s// ---- %s：golden 留下的 %d 个字段 ----' % (ind, doc, len(regs))]
    for n, w, f in regs:
        out.append('%s%-14s %s;' % (ind, wdecl(w), n))
    if reset:
        out.append('%salways_ff @(posedge clock or posedge reset) begin' % ind)
        out.append('%s  if (reset) begin' % ind)
        for n, w, f in regs:
            out.append("%s    %s <= '0;" % (ind, n))
        out.append('%s  end else if (%s) begin' % (ind, en))
    else:
        out.append('%salways_ff @(posedge clock) begin' % ind)
        out.append('%s  if (%s) begin' % (ind, en))
    for n, w, f in regs:
        if n in const_zero:
            out.append("%s    %s <= '0;" % (ind, n))
        else:
            out.append('%s    %s <= %s%s;' % (ind, n, src, ts.resolve(typ, f, w, False)))
    out.append('%s  end' % ind)
    out.append('%send' % ind)
    if readback:
        out.append('%salways_comb begin' % ind)
        out.append("%s  %s = '0;" % (ind, sig))
        for n, w, f in regs:
            out.append('%s  %s%s = %s;' % (ind, sig, ts.resolve(typ, f, w, False), n))
        out.append('%send' % ind)
    return out


def emit_group_glue(ts, cports, ind='  ', skip=()):
    """wrapper 里每个接口组的 struct 声明 + 拆装。skip: 不在这里声明的组名。"""
    by_group = collections.OrderedDict()
    for d, w, n, grp, f in cports:
        if grp and grp[2] not in skip:
            by_group.setdefault(grp[2], []).append((d, w, n, grp, f))
    out = []
    for gname, lst in by_group.items():
        typ = lst[0][3][1]
        out.append('%s%-14s %s;' % (ind, typ, gname))
        if lst[0][0] == 'input':
            out.append('%salways_comb begin' % ind)
            out.append("%s  %s = '0;" % (ind, gname))
            for d, w, n, grp, f in lst:
                out.append('%s  %s%s = %s;' % (ind, gname, ts.resolve(typ, f, w, False), n))
            out.append('%send' % ind)
        else:
            for d, w, n, grp, f in lst:
                out.append('%sassign %s = %s%s;' % (ind, n, gname, ts.resolve(typ, f, w, False)))
        out.append('')
    return out


def core_port_list(variants_cports, extra=()):
    """家族核的端口表 = 各变体端口的并集（按首次出现顺序）。
    variants_cports: [cports, ...]；extra: [(dir, type_or_width, name)] 追加在末尾（寄存器桥等）。
    返回 [(dir, 类型文本, 核端口名)]。同名口在不同变体里方向 / 类型必须一致。"""
    res = collections.OrderedDict()
    for cports in variants_cports:
        for d, w, n, grp, f in cports:
            name, typ = (grp[2], grp[1]) if grp else (core_name(n), wdecl(w))
            old = res.get(name)
            if old is not None and old != (d, typ):
                die('核端口 %s 在各变体里不一致: %r vs %r' % (name, old, (d, typ)))
            res[name] = (d, typ)
    out = [(d, typ, name) for name, (d, typ) in res.items()]
    for d, t, name in extra:
        out.append((d, t if isinstance(t, str) else wdecl(t), name))
    return out


def emit_core_ports(plist, ind='  '):
    lines = ['%s%-6s %-14s %s' % (ind, d, typ, name) for d, typ, name in plist]
    return [ln + ',' for ln in lines[:-1]] + [lines[-1]]


def emit_core_inst(core, params, plist, cports, bridge, ind='  '):
    """wrapper 里例化核。本变体没有的输入口接 '0，没有的输出口悬空。bridge: 名字集合（同名直连）。"""
    have = {}
    for d, w, n, grp, f in cports:
        if grp:
            have[grp[2]] = grp[2]
        else:
            have[core_name(n)] = n
    for b in bridge:
        have[b] = b
    out = ['%s%s%s u_core (' % (ind, core, (' #(%s)' % params) if params else '')]
    conns = []
    for d, typ, name in plist:
        if name in have:
            conns.append((name, have[name]))
        elif d == 'input':
            conns.append((name, "'0"))
        else:
            conns.append((name, ''))
    for i, (p, s) in enumerate(conns):
        out.append('%s  .%-44s (%s)%s' % (ind, p, s, ',' if i < len(conns) - 1 else ''))
    out.append('%s);' % ind)
    return out


def replace_region(text, tag, body):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED\(%s\))'
                     % (re.escape(tag), re.escape(tag)), re.S | re.M)
    if len(pat.findall(text)) != 1:
        die('GENERATED(%s) 标记不是恰好一对' % tag)
    return pat.sub(lambda m: m.group(1) + ''.join(ln + '\n' for ln in body) + m.group(3), text)


def strip_comments(text):
    return re.sub(r'//[^\n]*', '', text)


def nb_assigned(code):
    """一段（已去注释的）代码里被 `<=` 非阻塞赋值的标识符集合（含 `{a, b} <=` 拼接左值）。"""
    names = set(re.findall(r'^\s*(?:if\s*\([^\n]*\)\s*|else\s+)?(\w+)\s*<=', code, re.M))
    for m in re.finditer(r'^\s*(?:if\s*\([^\n]*\)\s*|else\s+)?\{([\w,\s]+)\}\s*<=', code, re.M):
        names |= {x.strip() for x in m.group(1).split(',')}
    return names


def has_firtool_names(text):
    return bool(re.search(r'_GEN_|_T_\d|\b_T\b|\b_GEN\b', strip_comments(text)))


def gen_nav(text, anchors):
    """anchors: [(标题, 行首正则)]，每个正则必须恰好命中 1 行。"""
    lines = text.split('\n')
    out = []
    for label, pat in anchors:
        idx = [i for i, ln in enumerate(lines) if re.match(pat, ln)]
        if len(idx) != 1:
            die('导航锚点 %r 命中 %d 处（要求恰好 1 处）' % (pat, len(idx)))
        out.append('//   L%-5d %s' % (idx[0] + 1, label))
    return out


# ---------------------------------------------------------------------------
# golden 例化块解析（装配壳用）
# ---------------------------------------------------------------------------
def golden_instances(mod):
    """返回 [(子模块名, 实例名, [(pin, 表达式文本)])]，按 golden 里出现的顺序。"""
    text = (GOLDEN_DIR / (mod + '.sv')).read_text()
    m = re.search(r'^module %s\(.*?\n\);(.*?)^endmodule' % re.escape(mod), text, re.S | re.M)
    body = m.group(1)
    res = []
    for im in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)^  \);', body, re.S | re.M):
        pins = []
        for pm in re.finditer(r'^\s*\.(\w+)\s*\(', im.group(3), re.M):
            start = pm.end()
            depth, i = 1, start
            while depth:
                c = im.group(3)[i]
                depth += (c == '(') - (c == ')')
                i += 1
            pins.append((pm.group(1), ' '.join(im.group(3)[start:i - 1].split())))
        res.append((im.group(1), im.group(2), pins))
    return res


def golden_assigns(mod):
    """golden 模块体里形如 `assign a = b;`（单标识符到单标识符）的连续赋值。"""
    text = (GOLDEN_DIR / (mod + '.sv')).read_text()
    m = re.search(r'^module %s\(.*?\n\);(.*?)^endmodule' % re.escape(mod), text, re.S | re.M)
    return re.findall(r'^  assign (\w+) = (\w+);', m.group(1), re.M)


# ---------------------------------------------------------------------------
# 双例化 tb 的机械部分
# ---------------------------------------------------------------------------
def rnd_expr(w, name):
    if 'exceptionVec' in name:
        return '($urandom_range(0, 7) == 0)'
    if w <= 32:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * ((w + 31) // 32)))


def emit_tb(g, head, hand):
    """head: 文件头注释（不含 timescale）；hand: 手写的激励整形 / 覆盖 / 主 initial（到 endmodule）。
    机械部分：信号声明、u_golden / u_impl 例化、drive_random、compare。"""
    ins = [(w, n) for d, w, n in g.ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in g.ports if d == 'output']
    o = [head.rstrip('\n'), '`timescale 1ns/1ps', '', 'module tb;', '',
         '  int unsigned NCYCLES = 200000;', '  int unsigned WARMUP  = 0;',
         '  int      errors = 0;', '  longint  checks = 0;', '',
         '  logic clock = 0;', '  logic reset;', '  always #5 clock = ~clock;', '',
         '  // ---- 输入（两侧共用）----']
    for w, n in ins:
        o.append('  %-14s %s;' % (wdecl(w), n))
    o.append('  // ---- 输出：g_ = golden，x_ = 重写 ----')
    for w, n in outs:
        o.append('  wire %-13s g_%s, x_%s;' % ('' if w == 1 else '[%d:0]' % (w - 1), n, n))
    for inst, mod, pfx in (('u_golden', g.mod, 'g_'), ('u_impl', g.mod + '_xs', 'x_')):
        o.append('')
        o.append('  %s %s (' % (mod, inst))
        o.append(',\n'.join('    .%s (%s)' % (n, n if d == 'input' else pfx + n) for d, w, n in g.ports))
        o.append('  );')
    o += ['', '  // ---- 所有输入整体随机（整形在 drive 里）----', '  task automatic drive_random();']
    for w, n in ins:
        o.append('    %s = %s;' % (n, rnd_expr(w, n)))
    o += ['  endtask', '', '  // ---- 逐根比较 ----', '`define CMP(SIG) \\',
          '    if (g_``SIG !== x_``SIG) begin \\', '      errors++; \\',
          '      if (errors < 30) $display("MISMATCH @%0d %s g=%h x=%h", checks, `"SIG`", g_``SIG, x_``SIG); \\',
          '    end', '  task automatic compare();', '    checks++;']
    for w, n in outs:
        o.append('    `CMP(%s)' % n)
    o.append('  endtask')
    o.append(hand.rstrip('\n'))
    return '\n'.join(o) + '\n', len(outs)


TB_MAIN = r'''
  initial begin
    int bad = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if (!$value$plusargs("warmup=%d", WARMUP))   WARMUP  = 0;
    for (int i = 0; i < NCOV; i++) cov[i] = 0;
    reset = 1'b1;
    drive();
    quiesce();
    repeat (5) @(negedge clock);
    reset = 1'b0;
    for (int c = 0; c < NCYCLES + WARMUP; c++) begin
      drive();
      #4;
      if (c >= WARMUP) begin
        compare();
        collect_cov();
      end
      @(negedge clock);
    end
    for (int i = 0; i < NCOV; i++) begin
      $display("  cov %-24s = %0d (min %0d)%s", cov_names[i], cov[i], cov_min[i],
               (cov[i] < cov_min[i]) ? "  <-- LOW" : "");
      if (cov[i] < cov_min[i]) bad++;
    end
    $display("=== COVERAGE (@MOD@) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("@MOD@ UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
'''


def tb_cov_block(items):
    """items: [(名字, 下限, 条件表达式)] → 覆盖计数的声明与 collect_cov 任务。"""
    n = len(items)
    o = ['  localparam int NCOV = %d;' % n, '  longint cov [NCOV];',
         '  string  cov_names [NCOV] = \'{%s};' % ', '.join('"%s"' % nm for nm, _, _ in items),
         '  int     cov_min   [NCOV] = \'{%s};' % ', '.join(str(mn) for _, mn, _ in items),
         '  task automatic collect_cov();']
    for i, (nm, mn, cond) in enumerate(items):
        o.append('    if (%s) cov[%d]++;' % (cond, i))
    o.append('  endtask')
    return '\n'.join(o) + '\n'
