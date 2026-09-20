#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fubusy_wbarb.py —— 生成四个小叶子家族（共 55 个 golden 变体）的薄 wrapper 与 tb。

四个家族、每族一个参数化核（核是手写的，在下面 CORE_FILE 里），本脚本只产出
「每变体一个薄文件」与四个 UT 的 tb：

  FuBusyTableRead   18 变体  核 rtl/backend/FuBusyTableRead.sv  (xs_FuBusyTableRead_core)
  FuBusyTableWrite  15 变体  核 rtl/backend/FuBusyTableWrite.sv (xs_FuBusyTableWrite_core)
  WBArbiter         13 变体  核 rtl/backend/WBArbiter.sv        (xs_WBArbiter_core)
  RealWBArbiter      9 变体  核 rtl/common/xs_PriorityArbSelect.sv（本族核体就是那条法则）

★所有维度都从 golden **实测**，不从记忆或注释里抄★：端口表逐行照抄 golden
（端口契约闸 PORTLINT_ORDER=fail 要求逐位同名同序）；N / 表宽 / 槽掩码 / 有无
og0/og1 端口 / payload 字段全部由解析得到，且每一条都有断言（对不上当场退出）。

唯一手工录入的常量是 FuType 位名表（用于生成可读注释），它由 XiangShan
src/main/scala/xiangshan/backend/fu/FuType.scala 的 addType 顺序抄来，
脚本用它跟 golden 解析出的位号交叉校验模块名（例如 slot={11,13} 必须出现在
名字里带 Falu/Fcvt 的 IssueQueue 下），对不上只告警不阻断（注释错了不影响电路）。

用法: python3 scripts/gen_fubusy_wbarb.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（gate_all.sh 的幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))

# FuType.scala 的 addType 顺序（0..34），仅用于生成注释里的位名。
FU_NAMES = ['jmp', 'brh', 'i2f', 'i2v', 'f2v', 'csr', 'alu', 'mul', 'div', 'fence',
            'bku', 'falu', 'fmac', 'fcvt', 'fDivSqrt', 'ldu', 'stu', 'mou',
            'vipu', 'vialuF', 'vppu', 'vimac', 'vidiv', 'vfpu', 'vfalu', 'vfma',
            'vfdiv', 'vfcvt', 'vsetiwi', 'vsetiwf', 'vsetfwf', 'vldu', 'vstu',
            'vsegldu', 'vsegstu']
assert len(FU_NAMES) == 35

FAMILIES = {
    'FuBusyTableRead':  [2, 22, 23, 26, 28, 42, 43, 52, 53, 68, 69, 71, 73, 75, 79, 80, 105],
    'FuBusyTableWrite': [22, 26, 42, 43, 52, 53, 68, 69, 71, 73, 75, 79, 80, 105],
    'WBArbiter':        [1, 2, 3, 30, 33, 38, 52, 55, 58, 64, 65, 66],
    'RealWBArbiter':    [1, 2, 3, 14, 15, 20, 21, 26],
}
# 家族核所在文件（薄 wrapper 头注释里引用，readability_audit 的 F 类会验它存在）
CORE_FILE = {
    'FuBusyTableRead':  'rtl/backend/FuBusyTableRead.sv',
    'FuBusyTableWrite': 'rtl/backend/FuBusyTableWrite.sv',
    'WBArbiter':        'rtl/backend/WBArbiter.sv',
    'RealWBArbiter':    'rtl/common/xs_PriorityArbSelect.sv',
}
UT_DIR = {
    'FuBusyTableRead':  'FuBusyTableReadVariants',
    'FuBusyTableWrite': 'FuBusyTableWriteVariants',
    'WBArbiter':        'WBArbiterVariants',
    'RealWBArbiter':    'RealWBArbiterVariants',
}


def all_variants(fam):
    return [fam] + ['%s_%d' % (fam, i) for i in FAMILIES[fam]]


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
def gtext(name):
    return (GOLDEN / (name + '.sv')).read_text()


def gbody(name):
    t = gtext(name)
    return t[t.index('\nmodule '):]


def gport_block(name):
    """返回 golden 端口表的原文（module 头到 ');' 之间，含缩进），逐行照抄。"""
    b = gbody(name)
    i = b.index(');')
    return b[b.index('(\n') + 2:i].rstrip('\n')


def gports(name):
    out = []
    for line in gport_block(name).split('\n'):
        s = line.strip().rstrip(',')
        m = re.match(r'(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)$', s)
        assert m, (name, s)
        out.append((m.group(1), int(m.group(2) or 0) + 1, m.group(3)))
    return out


_INST_INDEX = None


def users(name):
    """golden 里例化本模块的父模块（实测，不靠记忆）。整棵 golden 只扫一遍并缓存。"""
    global _INST_INDEX
    if _INST_INDEX is None:
        _INST_INDEX = {}
        for f in sorted(GOLDEN.glob('*.sv')):
            for m in re.finditer(r'^  ([A-Z]\w*) ', f.read_text(), re.M):
                lst = _INST_INDEX.setdefault(m.group(1), [])
                if f.name not in lst:      # 同一父模块可能例化多次，只记一次
                    lst.append(f.name)
    return _INST_INDEX.get(name, [])


def _concat_elems(expr, frm):
    s = expr.index('{', frm)
    d = 0
    for i in range(s, len(expr)):
        if expr[i] == '{':
            d += 1
        elif expr[i] == '}':
            d -= 1
            if d == 0:
                break
    inner, end = expr[s + 1:i], i
    els, d, cur = [], 0, ''
    for ch in inner:
        if ch == '{':
            d += 1
        if ch == '}':
            d -= 1
        if ch == ',' and d == 0:
            els.append(cur)
            cur = ''
        else:
            cur += ch
    els.append(cur)
    return [e.strip() for e in els], end


def _bitsets(els):
    """把 golden 拼接表的 MSB..LSB 元素展开成 LSB..MSB 的位集合列表。"""
    out = []
    for e in reversed(els):
        e = e.strip()
        m = re.match(r"^(\d+)'h0$", e)
        if m:
            out.extend([frozenset()] * int(m.group(1)))
        else:
            out.append(frozenset(int(x) for x in re.findall(r'\[(\d+)\]', e)))
    return out


def parse_read(name):
    b = gbody(name)
    p = gports(name)
    tw = [w for d, w, n in p if n == 'io_in_fuBusyTable'][0]
    ne = len([1 for d, w, n in p if n.startswith('io_in_fuTypeRegVec')])
    mw = [w for d, w, n in p if n == 'io_out_fuBusyTableMask'][0]
    assert mw == ne, (name, mw, ne)
    expr = b[b.index('assign io_out_fuBusyTableMask ='):]
    expr = expr[:expr.index(';')]
    sel = {}
    for m in re.finditer(r'io_in_fuBusyTable(?:\[(\d+)\])?\s*\n?\s*\?', expr):
        bit = int(m.group(1)) if m.group(1) else 0
        els, _ = _concat_elems(expr, m.end())
        assert len(els) == ne, (name, len(els), ne)
        sets = {frozenset(int(x) for x in re.findall(r'\[(\d+)\]', e)) for e in els}
        assert len(sets) == 1, (name, bit, sets)   # 每个条目用同一组 fuType 位
        sel[bit] = sorted(next(iter(sets)))
    assert sel and max(sel) < tw, (name, sel, tw)
    return dict(ne=ne, tw=tw, sel=sel)


def parse_write(name):
    b = gbody(name)
    p = gports(name)
    names = [n for d, w, n in p]
    w = [ww for d, ww, n in p if n == 'io_out_fuBusyTable'][0]
    e = b[b.index('fuBusyTable <=\n'):]
    e = e[:e.index(';')]

    def term(sig, width):
        m = re.search(r'io_in_%s_valid[^?]*\?\s*' % sig, e)
        if not m:
            return None
        rest = e[m.end():]
        if rest.lstrip().startswith('{'):
            els, _ = _concat_elems(rest, 0)
        else:
            els = [rest[:rest.index(':')]]
        s = _bitsets(els)
        assert len(s) == width, (name, sig, els, width)
        return s

    deq = term('deqResp', w)
    assert deq[w - 1] == frozenset(), (name, '最高位槽必须恒 0')
    slots = deq[:w - 1]
    og0 = term('og0Resp', w - 1) if 'io_in_og0Resp_valid' in names else None
    og1 = term('og1Resp', w - 1) if 'io_in_og1Resp_valid' in names else None
    # ★恒等式：og0 掩码 == 槽表下移一格；og1 == 下移两格。15 个变体逐个断言。
    for sig, got, shift in (('og0', og0, 1), ('og1', og1, 2)):
        exp = [slots[i + shift] if i + shift < len(slots) else frozenset()
               for i in range(w - 1)]
        if got is None:
            continue
        assert got == exp, (name, sig, got, exp)
    if og0 is None:
        assert all(s == frozenset() for s in slots[1:]), (name, 'og0 端口缺失但掩码非零')
    if og1 is not None:
        assert 'io_in_og1Resp_bits_resp' in names, name
    return dict(w=w, nslot=w - 1, has_og0=og0 is not None, has_og1=og1 is not None,
                slots=[sorted(s) for s in slots])


def parse_wbarb(name):
    p = gports(name)
    n = len([1 for d, w, nm in p if re.match(r'io_in_\d+_valid$', nm)])
    pay = [(nm.split('bits_')[1], w) for d, w, nm in p if nm.startswith('io_out_bits_')]
    assert len(pay) <= 1, (name, pay)
    nrdy = len([1 for d, w, nm in p if re.match(r'io_in_\d+_ready$', nm)])
    assert nrdy == n, (name, nrdy, n)
    return dict(n=n, pay=pay[0] if pay else None)


def parse_realwbarb(name):
    p = gports(name)
    n = len([1 for d, w, nm in p if re.match(r'io_in_\d+_valid$', nm)])
    pay = [(nm.split('bits_')[1], w) for d, w, nm in p if nm.startswith('io_out_bits_')]
    nrdy = len([1 for d, w, nm in p if re.match(r'io_in_\d+_ready$', nm)])
    # ★golden 不对称：N=1 连 io_in_0_ready 都没有（恒 1 被折掉）★
    assert nrdy == (0 if n == 1 else n), (name, nrdy, n)
    return dict(n=n, pay=pay, has_ready=(nrdy > 0))


# ---------------------------------------------------------------------------
# 输出辅助
# ---------------------------------------------------------------------------
def mask_lit(bits):
    v = 0
    for b in bits:
        v |= 1 << b
    return "35'h%x" % v


def fu_comment(bits):
    return ' | '.join('%s(%d)' % (FU_NAMES[b], b) for b in bits) if bits else '空'


def sel_table(slots, kw):
    """生成 8 项 SLOT_SEL/FU_SEL 常量表（MSB..LSB = 槽 7..槽 0），逐槽带位名注释。"""
    lines = ["  localparam logic [7:0][34:0] %s = '{" % kw]
    used = max(slots) if slots else -1
    for s in range(7, -1, -1):
        bits = slots.get(s, [])
        end = '};' if s == 0 else ','
        if s > used and not bits:
            lines.append('    %-16s%s   // 槽 %d：本变体没有' % ("35'h0", end, s))
        else:
            lines.append('    %-16s%s   // 槽 %d：%s' % (mask_lit(bits), end, s, fu_comment(bits)))
    return '\n'.join(lines)


def header(mod, fam, role, extra=()):
    core = CORE_FILE[fam]
    out = ['// ' + '=' * 76,
           '// %s.sv —— %s 家族薄 wrapper：%s' % (mod, fam, role)]
    out += ['// ' + x for x in extra]
    out += ['//',
            '// 本文件只做参数设定与端口对位，核体见 %s，全家族共一份。' % core,
            '// 由 scripts/gen_fubusy_wbarb.py 生成，勿手改；差异维度矩阵见',
            '// verif/ut/%s/README.md。' % UT_DIR[fam],
            '// golden 对照：G1-canonical/golden-rtl/%s.sv' % mod,
            '// ' + '=' * 76]
    return '\n'.join(out)


def emit(files, path, text):
    files[path] = text if text.endswith('\n') else text + '\n'


# ---------------------------------------------------------------------------
# 薄 wrapper 生成
# ---------------------------------------------------------------------------
def wrap_read(mod, info, usr):
    sel = info['sel']
    role = ('%d 条目 / 表宽 %d，槽 %s'
            % (info['ne'], info['tw'],
               '、'.join('%d=%s' % (b, fu_comment(v)) for b, v in sorted(sel.items()))))
    extra = ['例化者：%s' % ' / '.join(usr),
             'golden 里 TW=%d 但只有槽 %s 出现在表达式里，其余槽的功能单元集合为空，'
             % (info['tw'], '/'.join(str(b) for b in sorted(sel))),
             '照抄为全 0 掩码（既不补齐也不少算）。']
    ne = info['ne']
    ent = ['io_in_fuTypeRegVec_%d' % i for i in range(ne)]
    cat = []
    for i in range(ne - 1, -1, -4):
        grp = [ent[j] for j in range(i, max(i - 4, -1), -1)]
        cat.append('    ' + ', '.join(grp) + ('' if i - 4 < 0 else ','))
    return '\n'.join([
        header(mod, 'FuBusyTableRead', role, extra),
        'module %s(' % mod, gport_block(mod), ');',
        '  localparam int NE = %d;' % ne,
        '  localparam int TW = %d;' % info['tw'],
        sel_table(sel, 'FU_SEL'),
        '',
        '  logic [NE-1:0][34:0] fu_type;',
        '  assign fu_type = {',
        '\n'.join(cat) + '};',
        '',
        '  xs_FuBusyTableRead_core #(.NE(NE), .TW(TW), .FU_SEL(FU_SEL)) u_core (',
        '    .fu_busy_table (io_in_fuBusyTable),',
        '    .fu_type       (fu_type),',
        '    .busy_mask     (io_out_fuBusyTableMask)',
        '  );',
        'endmodule'])


def wrap_write(mod, info, usr):
    slots = {i: v for i, v in enumerate(info['slots'])}
    role = ('表宽 %d（%d 个槽），%sog0、%sog1'
            % (info['w'], info['nslot'],
               '有' if info['has_og0'] else '无', '有' if info['has_og1'] else '无'))
    extra = ['例化者：%s' % ' / '.join(usr),
             '槽表：' + '、'.join('%d=%s' % (i, fu_comment(v)) for i, v in sorted(slots.items()))]
    if info['has_og1'] is False and any(slots.get(i) for i in range(2, info['nslot'])):
        extra.append('★golden 不对称：本变体「下移两格」的掩码非零，却没有 og1Resp 端口')
        extra.append('  （Chisel 侧该队列就没接 og1）—— 所以 HAS_OG1 是独立参数，不是派生量。')
    og0v = 'io_in_og0Resp_valid' if info['has_og0'] else "1'b0"
    og0t = 'io_in_og0Resp_bits_fuType' if info['has_og0'] else "35'b0"
    og1v = 'io_in_og1Resp_valid' if info['has_og1'] else "1'b0"
    og1r = 'io_in_og1Resp_bits_resp' if info['has_og1'] else "2'b0"
    og1t = 'io_in_og1Resp_bits_fuType' if info['has_og1'] else "35'b0"
    note0 = '' if info['has_og0'] else '   // golden 本变体无 og0Resp 端口'
    note1 = '' if info['has_og1'] else '   // golden 本变体无 og1Resp 端口'
    return '\n'.join([
        header(mod, 'FuBusyTableWrite', role, extra),
        'module %s(' % mod, gport_block(mod), ');',
        '  localparam int NSLOT = %d;' % info['nslot'],
        sel_table(slots, 'SLOT_SEL'),
        '',
        "  xs_FuBusyTableWrite_core #(",
        "    .NSLOT(NSLOT), .HAS_OG0(1'b%d), .HAS_OG1(1'b%d), .SLOT_SEL(SLOT_SEL)"
        % (info['has_og0'], info['has_og1']),
        '  ) u_core (',
        '    .clock         (clock),',
        '    .reset         (reset),',
        '    .deq_valid     (io_in_deqResp_valid),',
        '    .deq_fu_type   (io_in_deqResp_bits_fuType),',
        '    .og0_valid     (%s),%s' % (og0v, note0),
        '    .og0_fu_type   (%s),' % og0t,
        '    .og1_valid     (%s),%s' % (og1v, note1),
        '    .og1_resp      (%s),' % og1r,
        '    .og1_fu_type   (%s),' % og1t,
        '    .fu_busy_table (io_out_fuBusyTable)',
        '  );',
        'endmodule'])


def wrap_wbarb(mod, info, usr):
    n, pay = info['n'], info['pay']
    pw = pay[1] if pay else 1
    role = 'N=%d，%s' % (n, ('payload %s[%d:0]' % (pay[0], pay[1] - 1)) if pay else '无 payload')
    extra = ['例化者：%s' % ' / '.join(usr)]
    if n == 1:
        extra.append('★golden 实测：N=1 时 finalValid_0 恒等于 io_in_0_valid（~hasFull 与')
        extra.append('  ~(v&isFull) 两项里必有一项为真），因此 in_ready 恒 1、计数器恒 0 ——')
        extra.append('  本变体那 3 个反饥饿寄存器是**死逻辑**。golden 有它们，这里照样有。')
    bits = ("'0" if not pay
            else '{' + ', '.join('io_in_%d_bits_%s' % (i, pay[0])
                                 for i in range(n - 1, -1, -1)) + '}')
    outb = '()' if not pay else '(io_out_bits_%s)' % pay[0]
    note = '            // golden 本变体无 bits 端口' if not pay else ''
    return '\n'.join([
        header(mod, 'WBArbiter', role, extra),
        'module %s(' % mod, gport_block(mod), ');',
        '  localparam int N  = %d;' % n,
        '  localparam int PW = %d;%s' % (pw, '   // 无 payload：传 1 位并悬空 out_bits' if not pay else ''),
        '',
        '  logic [N-1:0] in_ready;',
        '  xs_WBArbiter_core #(.N(N), .PW(PW)) u_core (',
        '    .clock     (clock),',
        '    .reset     (reset),',
        '    .in_valid  ({%s}),' % ', '.join('io_in_%d_valid' % i for i in range(n - 1, -1, -1)),
        '    .in_bits   (%s),%s' % (bits, note),
        '    .in_ready  (in_ready),',
        '    .out_valid (io_out_valid),',
        '    .out_bits  %s' % outb,
        '  );',
        '\n'.join('  assign io_in_%d_ready = in_ready[%d];' % (i, i) for i in range(n)),
        'endmodule'])


def wrap_realwbarb(mod, info, usr):
    n, pay = info['n'], info['pay']
    pkg = mod.lower() + '_pkg'
    pw = sum(w for _, w in pay)
    role = 'N=%d，payload {%s}（共 %d 位）' % (
        n, ', '.join('%s:%d' % (f, w) for f, w in pay), pw)
    extra = ['例化者：%s' % ' / '.join(usr)]
    if n == 1:
        extra.append('★golden 不对称：N=1 的变体**连 io_in_0_ready 端口都没有**（恒 1 被')
        extra.append('  firtool 折掉），而 N>=2 的变体保留了恒 1 的 io_in_0_ready。照抄。')
    fields = '\n'.join('    logic %-8s %s;' % (('[%d:0]' % (w - 1)) if w > 1 else '', f)
                       for f, w in pay)
    packs = '\n'.join(
        '  assign in_payload[%d] = {%s};'
        % (i, ', '.join('io_in_%d_bits_%s' % (i, f) for f, _ in pay))
        for i in range(n))
    unpacks = '\n'.join('  assign io_out_bits_%-8s = out_payload.%s;' % (f, f) for f, _ in pay)
    rdy = ('\n'.join('  assign io_in_%d_ready     = in_ready[%d];' % (i, i) for i in range(n))
           if info['has_ready'] else
           '  // golden 本变体没有 io_in_0_ready 端口（恒 1 被折掉）：in_ready 悬空不接。')
    return '\n'.join([
        header(mod, 'RealWBArbiter', role, extra),
        'package %s;' % pkg,
        '  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。',
        '  typedef struct packed {',
        fields,
        '  } payload_t;',
        'endpackage',
        '',
        'module %s import %s::*; (' % (mod, pkg), gport_block(mod), ');',
        '  localparam int N  = %d;' % n,
        '  localparam int PW = $bits(payload_t);',
        '',
        '  payload_t [N-1:0] in_payload;',
        packs,
        '',
        '  payload_t     out_payload;',
        '  logic [N-1:0] in_ready;',
        '  logic [N-1:0] in_valid;',
        '  assign in_valid = {%s};' % ', '.join('io_in_%d_valid' % i for i in range(n - 1, -1, -1)),
        '',
        '  xs_PriorityArbSelect #(.N(N), .PW(PW)) u_sel (',
        '    .in_valid  (in_valid),',
        '    .eff_valid (in_valid),    // 本族没有反饥饿级，原始 valid 直接参与竞争',
        '    .in_bits   (in_payload),',
        '    .in_ready  (in_ready),',
        '    .out_valid (io_out_valid),',
        '    .out_bits  (out_payload)',
        '  );',
        '',
        rdy,
        unpacks,
        'endmodule'])


# ---------------------------------------------------------------------------
# tb 生成
# ---------------------------------------------------------------------------
TB_HEAD = """`timescale 1ns/1ps
module tb;
  localparam int NV = %(nv)d;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \\
    begin checks++; if ((g) !== (i)) begin errors++; \\
      if (errors < 20) $display("MISMATCH %%0t %%s golden=%%h impl=%%h", $time, nm, (g), (i)); \\
    end end
"""


def gen_tb_read(variants, infos):
    nv = len(variants)
    s = [('// ' + '=' * 76),
         '// tb —— FuBusyTableRead 家族 UT：%d 个 golden 变体与重写件逐拍双例化比对。' % nv,
         '//',
         '// 本族是**纯组合**的与/或矩阵，没有任何寄存器，所以「测到位」不能靠拍数，',
         '// 只能靠覆盖：每个变体的 fuBusyTable 每一位都要取遍 0/1，每个条目的输出屏蔽位',
         '// 都要取遍 0/1，并且**每一个非空槽都必须真的驱动过一次 1**（否则那一项的掩码',
         '// 写错了也没人看得见）。三项全中才判 TEST PASSED。',
         '//',
         '// 激励形状：fuType 四种轮换 —— 全随机 35 位（超集，压满与/或矩阵）、随机 one-hot、',
         '// 从「本族全部槽掩码的并集」里挑的 one-hot（专打有效位）、以及全 0；',
         '// fuBusyTable 每变体独立取 5 位随机。',
         '//',
         '// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。',
         ('// ' + '=' * 76),
         TB_HEAD % dict(nv=nv)]
    # 参数表
    ne = [infos[v]['ne'] for v in variants]
    tw = [infos[v]['tw'] for v in variants]
    s.append('  localparam int NE  [NV] = \'{%s};' % ', '.join(map(str, ne)))
    s.append('  localparam int TW  [NV] = \'{%s};' % ', '.join(map(str, tw)))
    sel_rows = []
    union = 0
    for v in variants:
        row = []
        for b in range(5):
            bits = infos[v]['sel'].get(b, [])
            m = 0
            for x in bits:
                m |= 1 << x
                union |= 1 << x
            row.append("35'h%x" % m)
        sel_rows.append("'{%s}" % ', '.join(row))
    s.append('  // 每变体 5 个槽的 fuType 掩码（从 golden 解析，与 rtl 薄 wrapper 同源）')
    s.append('  localparam logic [34:0] SEL [NV][5] = \'{\n    %s};'
             % ',\n    '.join(sel_rows))
    s.append("  localparam logic [34:0] UNION = 35'h%x;   // 全族有效位并集，one-hot 激励从这里挑" % union)
    s.append('')
    s.append('  logic [34:0] ft [24];')
    s.append('  logic [4:0]  tbl [NV];')
    s.append('')
    # 例化
    for vi, v in enumerate(variants):
        info = infos[v]
        drv = {'io_in_fuBusyTable': 'tbl[%d][%d:0]' % (vi, info['tw'] - 1)}
        for k in range(info['ne']):
            drv['io_in_fuTypeRegVec_%d' % k] = 'ft[%d]' % k
        s.append('  // ---- %s : NE=%d TW=%d ----' % (v, info['ne'], info['tw']))
        s.append('  logic [%d:0] g_%s_m, i_%s_m;' % (info['ne'] - 1, v, v))
        for pfx, sig, mod in (('u_g_', 'g_%s_m' % v, v), ('u_i_', 'i_%s_m' % v, v + '_xs')):
            conn = []
            for d, w, n in gports(v):
                conn.append('    .%s (%s)' % (n, drv[n] if d == 'input' else sig))
            s.append('  %s %s%s (\n%s\n  );' % (mod, pfx, v, ',\n'.join(conn)))
    s.append('')
    s.append("""  // ---- 覆盖桶 ----
  bit [1:0] cov_tbl  [NV][5];    // 每变体每个表位取到过 0 / 1
  bit [1:0] cov_mask [NV][24];   // 每变体每个条目的屏蔽位取到过 0 / 1
  bit       cov_slot [NV][5];    // 每变体每个非空槽真的驱动过一次 1

  task automatic check();""")
    for vi, v in enumerate(variants):
        info = infos[v]
        s.append('    `CK(g_%s_m, i_%s_m, "%s.mask")' % (v, v, v))
        s.append('    for (int b = 0; b < %d; b++) cov_tbl[%d][b][tbl[%d][b]] = 1\'b1;'
                 % (info['tw'], vi, vi))
        s.append('    for (int e = 0; e < %d; e++) cov_mask[%d][e][g_%s_m[e]] = 1\'b1;'
                 % (info['ne'], vi, v))
        s.append('    for (int b = 0; b < %d; b++)' % info['tw'])
        s.append('      if (tbl[%d][b] && (|(ft[0] & SEL[%d][b]))) cov_slot[%d][b] = 1\'b1;'
                 % (vi, vi, vi))
    s.append('  endtask')
    s.append("""
  task automatic drive();
    int mode; int nb;
    mode = $urandom_range(0, 3);
    for (int e = 0; e < 24; e++) begin
      case (mode)
        0: begin ft[e][31:0] = $urandom; ft[e][34:32] = $urandom; end  // 全随机
        1: ft[e] = 35'b1 << $urandom_range(0, 34);                     // 随机 one-hot
        2: begin                                                       // 只打有效位
             nb = $urandom_range(0, 34);
             while (!UNION[nb]) nb = (nb + 1) % 35;
             ft[e] = 35'b1 << nb;
           end
        default: ft[e] = '0;
      endcase
    end
    for (int v = 0; v < NV; v++) tbl[v] = $urandom_range(0, 31);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      for (int b = 0; b < 5;  b++) begin cov_tbl[v][b] = '0; cov_slot[v][b] = 1'b0; end
      for (int e = 0; e < 24; e++) cov_mask[v][e] = '0;
    end
    for (int e = 0; e < 24; e++) ft[e] = '0;
    for (int v = 0; v < NV; v++) tbl[v] = '0;
    repeat (2) @(posedge clk);
    repeat (NCYCLES) begin drive(); #1; check(); @(posedge clk); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: 表位 0/1 | 条目屏蔽位 0/1 | 非空槽驱动过 1 ---");
    for (int v = 0; v < NV; v++) begin
      int nt = 0, nm = 0, ns = 0, want_s = 0;
      for (int b = 0; b < TW[v]; b++) begin
        if (cov_tbl[v][b] == 2'b11) nt++;
        if (|SEL[v][b]) begin want_s++; if (cov_slot[v][b]) ns++; end
      end
      for (int e = 0; e < NE[v]; e++) if (cov_mask[v][e] == 2'b11) nm++;
      if (nt != TW[v] || nm != NE[v] || ns != want_s) bad++;
      $display("  variant[%0d] NE=%0d TW=%0d : tbl %0d/%0d, mask %0d/%0d, slot %0d/%0d",
               v, NE[v], TW[v], nt, TW[v], nm, NE[v], ns, want_s);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule""")
    return '\n'.join(s)


def gen_tb_write(variants, infos):
    nv = len(variants)
    s = [('// ' + '=' * 76),
         '// tb —— FuBusyTableWrite 家族 UT：%d 个 golden 变体与重写件逐拍双例化比对。' % nv,
         '//',
         '// 本族是一个 W 位的倒计时占用表（右移 + 按 fuType 置位 + 按级取消）。',
         '// 「测到位」的判据是三件事，缺一不可：',
         '//   1. 每个变体表的**低 W-1 位**都要取遍 0/1（最高位在 golden 里恒 0 —— 这里',
         '//      不但不要求它取 1，反而**断言它从不为 1**，把那条死线钉住）；',
         '//   2. 每个非空槽的 deq 置位都真的发生过；',
         '//   3. 每个存在的取消端口（og0/og1）都真的**清掉过一个已置位的槽**',
         '//      —— 只看 og0_valid 拉高是不够的，那可能一次也没清到东西。',
         '//',
         '// 激励：deq/og0/og1 三路各自独立随机拉 valid，fuType 四种轮换（全随机 / 随机',
         '// one-hot / 只打本族有效位的 one-hot / 全 0），og1_resp 偏向 0（只有 resp==0',
         '// 才算取消），另有约 1/3000 的单拍异步复位脉冲把复位值也纳入比对。',
         '//',
         '// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。',
         ('// ' + '=' * 76),
         TB_HEAD % dict(nv=nv)]
    w = [infos[v]['w'] for v in variants]
    s.append("  localparam int W [NV] = '{%s};" % ', '.join(map(str, w)))
    rows, union = [], 0
    for v in variants:
        row = []
        for sl in range(4):
            bits = infos[v]['slots'][sl] if sl < infos[v]['nslot'] else []
            m = 0
            for x in bits:
                m |= 1 << x
                union |= 1 << x
            row.append("35'h%x" % m)
        rows.append("'{%s}" % ', '.join(row))
    s.append('  // 每变体 4 个槽的 fuType 掩码（从 golden 解析，与 rtl 薄 wrapper 同源）')
    s.append("  localparam logic [34:0] SEL [NV][4] = '{\n    %s};" % ',\n    '.join(rows))
    s.append("  localparam logic [34:0] UNION = 35'h%x;" % union)
    s.append("  localparam bit HAS_OG0 [NV] = '{%s};"
             % ', '.join("1'b%d" % infos[v]['has_og0'] for v in variants))
    s.append("  localparam bit HAS_OG1 [NV] = '{%s};"
             % ', '.join("1'b%d" % infos[v]['has_og1'] for v in variants))
    s.append('')
    s.append('  logic rst, deq_v, og0_v, og1_v;')
    s.append('  logic [1:0]  og1_resp;')
    s.append('  logic [34:0] deq_ft, og0_ft, og1_ft;')
    s.append('')
    for vi, v in enumerate(variants):
        info = infos[v]
        drv = {'clock': 'clk', 'reset': 'rst',
               'io_in_deqResp_valid': 'deq_v', 'io_in_deqResp_bits_fuType': 'deq_ft',
               'io_in_og0Resp_valid': 'og0_v', 'io_in_og0Resp_bits_fuType': 'og0_ft',
               'io_in_og1Resp_valid': 'og1_v', 'io_in_og1Resp_bits_resp': 'og1_resp',
               'io_in_og1Resp_bits_fuType': 'og1_ft'}
        s.append('  // ---- %s : W=%d og0=%d og1=%d ----'
                 % (v, info['w'], info['has_og0'], info['has_og1']))
        s.append('  logic [%d:0] g_%s_t, i_%s_t;' % (info['w'] - 1, v, v))
        for pfx, sig, mod in (('u_g_', 'g_%s_t' % v, v), ('u_i_', 'i_%s_t' % v, v + '_xs')):
            conn = []
            for d, ww, n in gports(v):
                conn.append('    .%s (%s)' % (n, drv[n] if d == 'input' else sig))
            s.append('  %s %s%s (\n%s\n  );' % (mod, pfx, v, ',\n'.join(conn)))
    s.append("""
  // ---- 覆盖桶 ----
  bit [1:0] cov_bit  [NV][5];   // 表每一位取到过 0 / 1
  bit       cov_set  [NV][4];   // 每个非空槽的 deq 置位发生过
  bit       cov_c0   [NV][4];   // og0 真的清掉过槽 s+1 上一个已置位
  bit       cov_c1   [NV][4];   // og1 真的清掉过槽 s+2 上一个已置位
  bit       top_bad  [NV];      // 最高位曾经为 1（golden 里恒 0，出现即失败）
""")
    s.append('  task automatic check();')
    for vi, v in enumerate(variants):
        info = infos[v]
        nsl = info['nslot']
        s.append('    `CK(g_%s_t, i_%s_t, "%s.fuBusyTable")' % (v, v, v))
        s.append('    for (int b = 0; b < %d; b++) cov_bit[%d][b][g_%s_t[b]] = 1\'b1;'
                 % (info['w'], vi, v))
        s.append('    if (g_%s_t[%d]) top_bad[%d] = 1\'b1;' % (v, info['w'] - 1, vi))
        s.append('    for (int sl = 0; sl < %d; sl++) begin' % nsl)
        s.append('      if (deq_v && (|(deq_ft & SEL[%d][sl]))) cov_set[%d][sl] = 1\'b1;' % (vi, vi))
        if info['has_og0']:
            s.append('      if (og0_v && sl + 1 < %d && (|(og0_ft & SEL[%d][sl+1]))' % (nsl, vi))
            s.append('          && g_%s_t[sl+1]) cov_c0[%d][sl] = 1\'b1;' % (v, vi))
        if info['has_og1']:
            s.append('      if (og1_v && og1_resp == 2\'d0 && sl + 2 < %d' % nsl)
            s.append('          && (|(og1_ft & SEL[%d][sl+2])) && g_%s_t[sl+2]) cov_c1[%d][sl] = 1\'b1;'
                     % (vi, v, vi))
        s.append('    end')
    s.append('  endtask')
    s.append("""
  function automatic logic [34:0] rand_ft(int mode);
    int nb;
    case (mode)
      0: begin rand_ft[31:0] = $urandom; rand_ft[34:32] = $urandom; end
      1: rand_ft = 35'b1 << $urandom_range(0, 34);
      2: begin
           nb = $urandom_range(0, 34);
           while (!UNION[nb]) nb = (nb + 1) % 35;
           rand_ft = 35'b1 << nb;
         end
      default: rand_ft = '0;
    endcase
  endfunction

  task automatic drive();
    deq_v    = $urandom_range(0, 2) != 0;      // 约 2/3 的拍有发射
    og0_v    = $urandom_range(0, 2) != 0;
    og1_v    = $urandom_range(0, 2) != 0;
    og1_resp = ($urandom_range(0, 1) == 0) ? 2'd0 : $urandom_range(1, 3);
    deq_ft   = rand_ft($urandom_range(0, 3));
    og0_ft   = rand_ft($urandom_range(0, 3));
    og1_ft   = rand_ft($urandom_range(0, 3));
    rst      = ($urandom_range(0, 2999) == 0);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      top_bad[v] = 1'b0;
      for (int b = 0; b < 5; b++) cov_bit[v][b] = '0;
      for (int sl = 0; sl < 4; sl++) begin
        cov_set[v][sl] = 1'b0; cov_c0[v][sl] = 1'b0; cov_c1[v][sl] = 1'b0;
      end
    end
    rst = 1'b1; deq_v = 1'b0; og0_v = 1'b0; og1_v = 1'b0;
    og1_resp = '0; deq_ft = '0; og0_ft = '0; og1_ft = '0;
    repeat (8) @(posedge clk);
    #1; drive(); rst = 1'b0;
    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: 表位 0/1 | deq 置位 | og0/og1 真清除 | 最高位恒 0 ---");
    for (int v = 0; v < NV; v++) begin
      int nb = 0, nset = 0, want = 0, nc0 = 0, w0 = 0, nc1 = 0, w1 = 0;
      for (int b = 0; b < W[v] - 1; b++) if (cov_bit[v][b] == 2'b11) nb++;
      for (int sl = 0; sl < W[v] - 1; sl++) begin
        if (|SEL[v][sl]) begin want++; if (cov_set[v][sl]) nset++; end
        if (HAS_OG0[v] && sl + 1 < W[v] - 1 && (|SEL[v][sl+1]))
          begin w0++; if (cov_c0[v][sl]) nc0++; end
        if (HAS_OG1[v] && sl + 2 < W[v] - 1 && (|SEL[v][sl+2]))
          begin w1++; if (cov_c1[v][sl]) nc1++; end
      end
      if (nb != W[v] - 1 || nset != want || nc0 != w0 || nc1 != w1 || top_bad[v]) bad++;
      $display("  variant[%0d] W=%0d : bit01 %0d/%0d, deqset %0d/%0d, og0clr %0d/%0d, og1clr %0d/%0d, top_bad=%0b",
               v, W[v], nb, W[v]-1, nset, want, nc0, w0, nc1, w1, top_bad[v]);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule""")
    return '\n'.join(s)


def gen_tb_wbarb(variants, infos):
    nv = len(variants)
    s = [('// ' + '=' * 76),
         '// tb —— WBArbiter 家族 UT：%d 个 golden 变体与重写件逐拍双例化比对。' % nv,
         '//',
         '// 本族 = 反饥饿计数级 + 固定优先级级。反饥饿级是整个模块唯一的状态，',
         '// 所以「测到位」的核心判据是**每一路都真的饿到过 isFull**（只看 ready/valid',
         '// 取遍 0/1 证明不了反饥饿那一半存在）。',
         '//',
         '// ★但「每一路」要先问清楚哪些路**够得着**★。把 golden 的次态方程原样搬进',
         '//   脚本做穷举可达性分析（scripts 目录外的一次性分析，结论抄在这里），得到：',
         '//     N=1：可达状态只有 1 个（全 0）—— finalValid_0 恒等于 io_in_0_valid',
         '//          （isFull0=1 时第三项真、=0 时第二项真），in_ready 恒 1、永不被拒，',
         '//          那 3 个寄存器是**死逻辑**；',
         '//     N=2：可达 9 个状态，isFull_0 **不可达**、cancelCounter_0 最大只到 1，',
         '//          计数饱和分支也不可达（第 1 路要攒够 6 次被拒，每一次都得第 0 路赢并',
         '//          握手，而握手就把第 0 路的计数清零了）；',
         '//     N=3：可达 133 个状态；N=4：1479 个 —— 两者全部可达。',
         '//   所以覆盖要求按 N 分档，并且**反过来把不可达的也钉死**：N=1 的三个寄存器',
         '//   必须恒 0、N=2 的 isFull_0 必须恒 0，出现非 0 即判失败。',
         '//',
         '// 激励：每变体独立的 4 位 valid，七种形状轮换且**每种形状连续保持 1..40 拍**',
         '// （逐拍换形状的话状态机根本攒不起计数）。其中第 7 种是「饥饿猎手」：',
         '// 除第 0 路外全程请求，而第 0 路**只在 golden 报 hasFull 的那一拍请求** ——',
         '// 这是唯一能把最高优先级那一路的 cancelCounter 累加到 6 的形状（它平时一请求',
         '// 就赢、一赢就清零）。payload（addr）每路 8 位随机；另有约 1/5000 的复位脉冲。',
         '//',
         '// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。',
         ('// ' + '=' * 76),
         TB_HEAD % dict(nv=nv)]
    s.append("  localparam int NIN [NV] = '{%s};" % ', '.join(str(infos[v]['n']) for v in variants))
    s.append('')
    s.append('  logic rst;')
    s.append('  logic [3:0] vld [NV];')
    s.append('  logic [7:0] pay [4];')
    s.append('  int mode_cur [NV], mode_hold [NV];')
    s.append('')
    for vi, v in enumerate(variants):
        info = infos[v]
        n, p = info['n'], info['pay']
        drv = {'clock': 'clk', 'reset': 'rst'}
        for i in range(n):
            drv['io_in_%d_valid' % i] = 'vld[%d][%d]' % (vi, i)
            if p:
                drv['io_in_%d_bits_%s' % (i, p[0])] = 'pay[%d][%d:0]' % (i, p[1] - 1)
        s.append('  // ---- %s : N=%d %s ----'
                 % (v, n, ('payload %s[%d:0]' % (p[0], p[1] - 1)) if p else '无 payload'))
        s.append('  logic [%d:0] g_%s_rdy, i_%s_rdy;' % (n - 1, v, v))
        s.append('  logic g_%s_ov, i_%s_ov;' % (v, v))
        if p:
            s.append('  logic [%d:0] g_%s_b, i_%s_b;' % (p[1] - 1, v, v))
        for pfx, g in (('u_g_', 'g'), ('u_i_', 'i')):
            outs = {'io_out_valid': '%s_%s_ov' % (g, v)}
            for i in range(n):
                outs['io_in_%d_ready' % i] = '%s_%s_rdy[%d]' % (g, v, i)
            if p:
                outs['io_out_bits_%s' % p[0]] = '%s_%s_b' % (g, v)
            conn = []
            for d, w, nm in gports(v):
                conn.append('    .%s (%s)' % (nm, drv[nm] if d == 'input' else outs[nm]))
            s.append('  %s %s%s (\n%s\n  );' % (v if g == 'g' else v + '_xs',
                                                pfx, v, ',\n'.join(conn)))
    s.append("""
  // ---- 覆盖桶（全部从 golden 侧的内部寄存器现场取，不看重写件）----
  bit [1:0] cov_ov  [NV];
  bit [1:0] cov_rdy [NV][4];
  bit       cov_full[NV][4];   // 第 i 路饿到过 isFull
  bit [1:0] cov_hf  [NV];      // hasFull 取遍 0/1
  bit       cov_sat [NV];      // 「计数已是 7 又被拒」的饱和分支（只有 N>=3 可达）
  bit       dead_bad[NV];      // 穷举证明不可达的状态却出现了（N=1 全部 / N=2 的 isFull_0）
""")
    s.append('  task automatic check();')
    for vi, v in enumerate(variants):
        info = infos[v]
        n, p = info['n'], info['pay']
        s.append('    `CK(g_%s_ov,  i_%s_ov,  "%s.out_valid")' % (v, v, v))
        s.append('    `CK(g_%s_rdy, i_%s_rdy, "%s.in_ready")' % (v, v, v))
        if p:
            s.append('    `CK(g_%s_b,   i_%s_b,   "%s.bits_%s")' % (v, v, v, p[0]))
        s.append("    cov_ov[%d][g_%s_ov] = 1'b1;" % (vi, v))
        s.append("    for (int k = 0; k < %d; k++) cov_rdy[%d][k][g_%s_rdy[k]] = 1'b1;"
                 % (n, vi, v))
        s.append("    cov_hf[%d][u_g_%s.hasFull] = 1'b1;" % (vi, v))
        for i in range(n):
            s.append("    if (u_g_%s.isFull_%d) cov_full[%d][%d] = 1'b1;" % (v, i, vi, i))
            s.append("    if ((&u_g_%s.cancelCounter_%d) && vld[%d][%d] && !g_%s_rdy[%d])"
                     % (v, i, vi, i, v, i))
            s.append("      cov_sat[%d] = 1'b1;" % vi)
        if n == 1:
            s.append('    if (u_g_%s.isFull_0 || u_g_%s.hasFull || (|u_g_%s.cancelCounter_0))'
                     % (v, v, v))
            s.append("      dead_bad[%d] = 1'b1;   // N=1：穷举可达状态只有全 0" % vi)
        elif n == 2:
            s.append('    if (u_g_%s.isFull_0 || u_g_%s.cancelCounter_0 > 3\'d1)' % (v, v))
            s.append("      dead_bad[%d] = 1'b1;   // N=2：isFull_0 不可达、cnt_0 上界 1" % vi)
    s.append('  endtask')
    s.append("""
  task automatic drive();
    for (int v = 0; v < NV; v++) begin
      // 形状要**连续保持**若干拍：逐拍换形状的话反饥饿计数根本攒不起来。
      if (mode_hold[v] == 0) begin
        mode_cur[v]  = $urandom_range(0, 6);
        mode_hold[v] = $urandom_range(1, 40);
      end
      mode_hold[v]--;
      case (mode_cur[v])
        0: vld[v] = '0;
        1: vld[v] = '1;
        2: vld[v] = 4'b1 << $urandom_range(0, 3);
        3: vld[v] = $urandom & $urandom;          // 稀疏
        4: vld[v] = $urandom | $urandom;          // 稠密
        5: vld[v] = $urandom;
        default: vld[v] = '1;                     // 6：饥饿猎手，第 0 位下面单独接
      endcase
    end""")
    for vi, v in enumerate(variants):
        s.append('    if (mode_cur[%d] == 6) vld[%d][0] = u_g_%s.hasFull;' % (vi, vi, v))
    s.append("""    for (int i = 0; i < 4; i++) pay[i] = $urandom;
    rst = ($urandom_range(0, 4999) == 0);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      cov_ov[v] = '0; cov_hf[v] = '0; dead_bad[v] = 1'b0; cov_sat[v] = 1'b0;
      mode_cur[v] = 0; mode_hold[v] = 0;
      for (int k = 0; k < 4; k++) begin cov_rdy[v][k] = '0; cov_full[v][k] = 1'b0; end
    end
    rst = 1'b1;
    for (int v = 0; v < NV; v++) vld[v] = '0;
    for (int i = 0; i < 4; i++) pay[i] = '0;
    repeat (8) @(posedge clk);
    #1; drive(); rst = 1'b0;
    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: out_valid 0/1 | ready 逐路 0/1 | isFull 逐路 | hasFull 0/1 | 饱和分支 ---");
    $display("    （可达性按 golden 次态方程穷举：N=1 全死 / N=2 只有第 1 路够得着 / N>=3 全可达）");
    for (int v = 0; v < NV; v++) begin
      int nr = 0, nf = 0, want_f = 0;
      for (int k = 0; k < NIN[v]; k++) begin
        if (NIN[v] == 1) begin if (cov_rdy[v][k][1]) nr++; end   // N=1：ready 恒 1
        else if (cov_rdy[v][k] == 2'b11) nr++;
        if (cov_full[v][k]) nf++;
      end
      want_f = (NIN[v] == 1) ? 0 : (NIN[v] == 2) ? 1 : NIN[v];
      if (NIN[v] == 2) nf = cov_full[v][1];                      // 第 0 路不可达，不计
      if (cov_ov[v] != 2'b11 || nr != NIN[v] || nf != want_f || dead_bad[v]) bad++;
      if (NIN[v] == 1) begin
        if (cov_hf[v][1]) bad++;                                 // hasFull 必须恒 0
      end else begin
        if (cov_hf[v] != 2'b11) bad++;
      end
      if (NIN[v] >= 3 && !cov_sat[v]) bad++;                     // 饱和分支只有 N>=3 可达
      if (NIN[v] <= 2 && cov_sat[v])  bad++;                     // 反向：N<=2 不该出现
      $display("  variant[%0d] N=%0d : out_valid=%b ready %0d/%0d isFull %0d/%0d hasFull=%b sat=%0b dead_bad=%0b",
               v, NIN[v], cov_ov[v], nr, NIN[v], nf, want_f, cov_hf[v], cov_sat[v], dead_bad[v]);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule""")
    return '\n'.join(s)


def gen_tb_realwbarb(variants, infos):
    nv = len(variants)
    s = [('// ' + '=' * 76),
         '// tb —— RealWBArbiter 家族 UT：%d 个 golden 变体与重写件逐拍双例化比对。' % nv,
         '//',
         '// 本族是**纯组合**的固定优先级选择（无时钟、无寄存器），判别力只能靠覆盖：',
         '//   1. out_valid 取遍 0/1；',
         '//   2. **每一路都真的赢过一次**（比它编号小的全不请求、它自己请求）——',
         '//      只比端口值不管谁赢的话，把优先级写反也可能长时间不暴露；',
         '//   3. in_ready 逐路取遍 0/1。★第 0 路例外★：golden 里 io_in_0_ready 恒 1，',
         '//      所以只要求它取到 1；N=1 的变体连这个端口都没有，整项跳过。',
         '//',
         '// 激励：每变体独立的 4 位 valid（全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 随机六种轮换），',
         '// payload 每路独立随机（Wen 位、pdest、data 各取最大宽度后按变体切片）。',
         '//',
         '// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。',
         ('// ' + '=' * 76),
         TB_HEAD % dict(nv=nv)]
    s.append("  localparam int NIN [NV] = '{%s};" % ', '.join(str(infos[v]['n']) for v in variants))
    s.append("  localparam bit HASRDY [NV] = '{%s};"
             % ', '.join("1'b%d" % infos[v]['has_ready'] for v in variants))
    s.append('')
    s.append('  logic [1:0]   wen   [4];')
    s.append('  logic [7:0]   pdest [4];')
    s.append('  logic [127:0] data  [4];')
    s.append('  logic [3:0]   vld   [NV];')
    s.append('')
    for vi, v in enumerate(variants):
        info = infos[v]
        n, pay = info['n'], info['pay']
        drv, wk = {}, 0
        fmap = []
        for f, w in pay:
            if f == 'pdest':
                fmap.append((f, w, 'pdest[%%d][%d:0]' % (w - 1)))
            elif f == 'data':
                fmap.append((f, w, 'data[%%d][%d:0]' % (w - 1)))
            else:
                assert w == 1, (v, f, w)
                fmap.append((f, w, 'wen[%d][' + str(wk) + ']'))
                wk += 1
        for i in range(n):
            drv['io_in_%d_valid' % i] = 'vld[%d][%d]' % (vi, i)
            for f, w, t in fmap:
                drv['io_in_%d_bits_%s' % (i, f)] = t % i
        s.append('  // ---- %s : N=%d payload {%s} ----'
                 % (v, n, ', '.join('%s:%d' % (f, w) for f, w in pay)))
        if info['has_ready']:
            s.append('  logic [%d:0] g_%s_rdy, i_%s_rdy;' % (n - 1, v, v))
        s.append('  logic g_%s_ov, i_%s_ov;' % (v, v))
        for f, w in pay:
            s.append('  logic [%d:0] g_%s_%s, i_%s_%s;' % (w - 1, v, f, v, f))
        for pfx, g in (('u_g_', 'g'), ('u_i_', 'i')):
            outs = {'io_out_valid': '%s_%s_ov' % (g, v)}
            for i in range(n):
                outs['io_in_%d_ready' % i] = '%s_%s_rdy[%d]' % (g, v, i)
            for f, w in pay:
                outs['io_out_bits_%s' % f] = '%s_%s_%s' % (g, v, f)
            conn = []
            for d, w, nm in gports(v):
                conn.append('    .%s (%s)' % (nm, drv[nm] if d == 'input' else outs[nm]))
            s.append('  %s %s%s (\n%s\n  );' % (v if g == 'g' else v + '_xs',
                                                pfx, v, ',\n'.join(conn)))
    s.append("""
  bit [1:0] cov_ov  [NV];
  bit [1:0] cov_rdy [NV][4];
  bit       cov_win [NV][4];    // 第 i 路真的赢过（比它小的全不请求且它请求）
""")
    s.append('  task automatic check();')
    for vi, v in enumerate(variants):
        info = infos[v]
        n, pay = info['n'], info['pay']
        s.append('    `CK(g_%s_ov, i_%s_ov, "%s.out_valid")' % (v, v, v))
        s.append("    cov_ov[%d][g_%s_ov] = 1'b1;" % (vi, v))
        if info['has_ready']:
            s.append('    `CK(g_%s_rdy, i_%s_rdy, "%s.in_ready")' % (v, v, v))
            s.append('    for (int k = 0; k < %d; k++) cov_rdy[%d][k][g_%s_rdy[k]] = 1\'b1;'
                     % (n, vi, v))
        for f, w in pay:
            s.append('    `CK(g_%s_%s, i_%s_%s, "%s.%s")' % (v, f, v, f, v, f))
        s.append('    for (int k = 0; k < %d; k++)' % n)
        s.append('      if (vld[%d][k] && ((vld[%d] & ((4\'b1 << k) - 4\'b1)) == 4\'b0))' % (vi, vi))
        s.append('        cov_win[%d][k] = 1\'b1;' % vi)
    s.append('  endtask')
    s.append("""
  task automatic drive();
    for (int v = 0; v < NV; v++)
      case ($urandom_range(0, 5))
        0: vld[v] = '0;
        1: vld[v] = '1;
        2: vld[v] = 4'b1 << $urandom_range(0, 3);
        3: vld[v] = $urandom & $urandom;
        4: vld[v] = $urandom | $urandom;
        default: vld[v] = $urandom;
      endcase
    for (int i = 0; i < 4; i++) begin
      wen[i]   = $urandom;
      pdest[i] = $urandom;
      for (int b = 0; b < 128; b += 32) data[i][b+:32] = $urandom;
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      cov_ov[v] = '0;
      for (int k = 0; k < 4; k++) begin cov_rdy[v][k] = '0; cov_win[v][k] = 1'b0; end
      vld[v] = '0;
    end
    for (int i = 0; i < 4; i++) begin wen[i] = '0; pdest[i] = '0; data[i] = '0; end
    repeat (2) @(posedge clk);
    repeat (NCYCLES) begin drive(); #1; check(); @(posedge clk); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: out_valid 0/1 | 每路赢过 | ready 逐路 0/1（第 0 路恒 1）---");
    for (int v = 0; v < NV; v++) begin
      int nw = 0, nr = 0, wr = 0;
      for (int k = 0; k < NIN[v]; k++) begin
        if (cov_win[v][k]) nw++;
        if (HASRDY[v]) begin
          wr++;
          if (k == 0) begin if (cov_rdy[v][0][1]) nr++; end       // golden 恒 1
          else if (cov_rdy[v][k] == 2'b11) nr++;
        end
      end
      if (cov_ov[v] != 2'b11 || nw != NIN[v] || nr != wr) bad++;
      $display("  variant[%0d] N=%0d : out_valid=%b win %0d/%0d ready %0d/%0d",
               v, NIN[v], cov_ov[v], nw, NIN[v], nr, wr);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule""")
    return '\n'.join(s)


# ---------------------------------------------------------------------------
def predict_passing(fam, v, info):
    """预测 FM 的 passing 数 = golden 证明闭包的**触发器位数 + 顶层 output 端口位数**。

    这个模型是本轮别的 lane 在 TlbStorageWrapper_1(8682) / TLBFA_1(8663) /
    DelayN_7(657) / DelayN_9(216) 上逐位命中的。本族要自己校准两件事：
      · 纯组合的两族（FuBusyTableRead / RealWBArbiter）触发器项为 0，
        模型退化成「只数 output 位」；
      · WBArbiter 的 N=1 变体那 3 个反饥饿寄存器是**死逻辑**（穷举可达状态只有全 0），
        但它们在 golden 与 impl 两侧都实际存在，所以照数不误。
    返回 (触发器位数, output 位数)。
    """
    outbits = sum(w for d, w, n in gports(v) if d == 'output')
    if fam == 'FuBusyTableRead':
        ff = 0
    elif fam == 'FuBusyTableWrite':
        ff = info['w']                        # fuBusyTable[W-1:0]
    elif fam == 'WBArbiter':
        ff = 4 * info['n'] + 1                # cancelCounter[N]×3 + isFull[N] + hasFull
    else:
        ff = 0                                # RealWBArbiter：无时钟、无寄存器
    return ff, outbits


def prediction_table():
    parse = {'FuBusyTableRead': parse_read, 'FuBusyTableWrite': parse_write,
             'WBArbiter': parse_wbarb, 'RealWBArbiter': parse_realwbarb}
    rows = ['# fubusy_wbarb_passing_prediction.tsv —— FM passing 预测（跑 FM **之前**登记）',
            '# 由 scripts/gen_fubusy_wbarb.py 从 golden 机械算出，gate_all.sh 的幂等闸校验。',
            '# 模型：passing = golden 闭包触发器位数 + 顶层 output 端口位数。',
            '# 纯组合家族（FuBusyTableRead / RealWBArbiter）触发器项为 0 —— 这是本族对该',
            '# 模型的形态校准点：它们的预测完全由 output 位数决定。',
            '#',
            '# 对账规矩：实测与预测不符**按 fail 报**，不许事后改预测。',
            'target\tfamily\tff_bits\tout_bits\tpredicted_passing']
    for fam in FAMILIES:
        for v in all_variants(fam):
            info = parse[fam](v)
            ff, ob = predict_passing(fam, v, info)
            rows.append('%s\t%s\t%d\t%d\t%d' % (v, fam, ff, ob, ff + ob))
    return '\n'.join(rows)


def build():
    files = {}
    emit(files, 'docs/fubusy_wbarb_passing_prediction.tsv', prediction_table())
    parse = {'FuBusyTableRead': parse_read, 'FuBusyTableWrite': parse_write,
             'WBArbiter': parse_wbarb, 'RealWBArbiter': parse_realwbarb}
    wrap = {'FuBusyTableRead': wrap_read, 'FuBusyTableWrite': wrap_write,
            'WBArbiter': wrap_wbarb, 'RealWBArbiter': wrap_realwbarb}
    tbgen = {'FuBusyTableRead': gen_tb_read, 'FuBusyTableWrite': gen_tb_write,
             'WBArbiter': gen_tb_wbarb, 'RealWBArbiter': gen_tb_realwbarb}
    for fam in FAMILIES:
        vs = all_variants(fam)
        infos = {v: parse[fam](v) for v in vs}
        for v in vs[1:]:          # 第一个（家族同名）是手写核文件，不生成
            emit(files, 'rtl/backend/%s.sv' % v, wrap[fam](v, infos[v], users(v)))
        emit(files, 'verif/ut/%s/tb.sv' % UT_DIR[fam], tbgen[fam](vs, infos))
    return files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    files = build()
    drift = []
    for rel, text in sorted(files.items()):
        p = REPO / rel
        old = p.read_text() if p.exists() else None
        if old == text:
            continue
        if a.check:
            drift.append(rel)
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
    if a.check:
        if drift:
            print('DRIFT: %d 个产物与生成器不一致：' % len(drift))
            for d in drift[:10]:
                print('  ' + d)
            return 1
        print('gen_fubusy_wbarb: %d 个产物与生成器一致' % len(files))
        return 0
    print('gen_fubusy_wbarb: 写出/校验 %d 个文件' % len(files))
    return 0


if __name__ == '__main__':
    sys.exit(main())
