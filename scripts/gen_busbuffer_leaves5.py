#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_busbuffer_leaves5.py —— 族 G（总线缓冲叶，5 个）薄文件生成器。

5 个目标分两个亚族，diff 过 5 份 golden，各自结构同构、只有 payload 字段表不同：

  * SpillRegister / SpillRegister_2 / SpillRegister_6：两级 skid buffer。
    控制逻辑逐字相同（reg1stValid/reg2ndValid 异步复位，两级 payload 寄存器不复位），
    差别只有字段表：AW/AR 通道（id/addr/len/size/burst[/cache]/qos）与 W 通道
    （data/strb/last）。共用共享核 rtl/uncore/xs_SpillRegister_core.sv。
  * Repeater_1 / Repeater_2：TileLink 握手 repeat（enq 被接受且 io_repeat=1 时存下
    payload，之后 deq 侧反复发同一份直到不再 repeat）。控制逻辑逐字相同；Repeater_1
    多一个 io_full 观测口，Repeater_2 多 data 字段、无 io_full。
    共用共享核 rtl/uncore/xs_Repeater_core.sv。

本脚本只生成每变体的薄文件：golden 端口表（逐字、含顺序）+ 字段按 golden 端口序
拼成整字（首字段在最高位）/ 拆回来 + 例化共享核。核体绝不复制。

机器校验（fail-closed，任何一条对不上就拒绝生成）：
  1. 端口表逐项解析；寄存器声明集合、两个 always 块的逐字模板、控制线定义、
     全部 assign 的集合都必须逐字命中所属亚族的模板（剩一条就报错——证明 golden
     里没有模板外的逻辑）；
  2. payload 字段 = 端口表里的 io_in_bits_* / io_enq_bits_*，逐个核对 golden 的
     reg 位宽与端口位宽一致，且每个入字段都有同名同宽的出字段；
  3. 拼字总宽 = 字段位宽之和，拆字切片与拼字布局逐字段一致（由同一份布局机械推出）。

用法：python3 scripts/gen_busbuffer_leaves5.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')

# 模块 -> (父模块, 一句话说明)
SPILLS = {
    'SpillRegister':   ('NCBDownstreamAW / NCBDownstreamAR',
                        'NCB 下游 AW/AR 通道的两级 skid buffer（6 位 id）'),
    'SpillRegister_2': ('NCBDownstreamW / NCBDownstreamW_1',
                        'NCB 下游 W 通道的两级 skid buffer（256 位 data）'),
    'SpillRegister_6': ('NCBDownstreamAW_1 / NCBDownstreamAR_1',
                        'NCB 下游 AW/AR 通道的两级 skid buffer（5 位 id，带 cache）'),
}
REPEATS = {
    'Repeater_1': ('TLFragmenter / TLFragmenter_1',
                   'TLFragmenter 的 A 通道 repeat 缓冲（4 位 mask，带 io_full 观测口）'),
    'Repeater_2': ('TLWidthWidget_1',
                   'TLWidthWidget_1 的 A 通道 repeat 缓冲（8 位 mask + 64 位 data）'),
}

PORT_RE = re.compile(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')
ASSIGN_RE = re.compile(r'assign\s+(\w+)\s*=\s*(.*?);', re.S)
WIREINIT_RE = re.compile(r'wire\s+(?:\[\d+:0\]\s+)?(\w+)\s*=\s*(.*?);', re.S)
REGDECL_RE = re.compile(r'reg\s+(?:\[(\d+):0\]\s+)?(\w+)\s*;')


def fail(mod, msg):
    raise SystemExit('gen_busbuffer_leaves5: %s: %s' % (mod, msg))


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


def ports(txt, mod):
    i = txt.index('module %s(' % mod)
    j = txt.index('\n);', i)
    out = []
    for line in txt[i:j].splitlines()[1:]:
        m = PORT_RE.match(line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1,
                        m.group(3)))
    if not out:
        fail(mod, '端口表解析为空')
    return out


def body_of(txt, mod):
    """模块体（端口表之后），剥掉初始随机化块（UT 编 +define+SYNTHESIS 时整块不在）。"""
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    return re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '\n',
                  body, flags=re.S)


def common_checks(mod, body, P):
    """两亚族共用：恰好一个异步复位 always 块 + 一个无复位 payload always 块。"""
    if body.count('always @(posedge clock or posedge reset)') != 1:
        fail(mod, '异步复位 always 块不是恰好一个')
    if body.count('always @(posedge clock)') != 1:
        fail(mod, 'payload 写 always 块不是恰好一个')
    names = {n for _, _, n in P}
    if 'clock' not in names or 'reset' not in names:
        fail(mod, '缺 clock/reset 端口')


def parse_spill(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    W = {n: w for _, w, n in P}
    body = body_of(txt, mod)
    body1 = norm(body)
    common_checks(mod, body, P)

    fields = [n[len('io_in_bits_'):] for d, _, n in P
              if d == 'input' and n.startswith('io_in_bits_')]
    if not fields:
        fail(mod, '没有 io_in_bits_* 端口')
    for f in fields:
        if ('io_out_bits_' + f) not in W:
            fail(mod, '字段 %s 没有对应的 io_out_bits_%s' % (f, f))
        if W['io_out_bits_' + f] != W['io_in_bits_' + f]:
            fail(mod, '字段 %s 出入位宽不一致' % f)

    # --- 寄存器声明集合：valid 两个 + 每字段两级 payload ---
    expect_regs = {'reg1stValid': 1, 'reg2ndValid': 1}
    for f in fields:
        expect_regs['reg1stData_' + f] = W['io_in_bits_' + f]
        expect_regs['reg2ndData_' + f] = W['io_in_bits_' + f]
    got_regs = {n: (int(w) + 1 if w else 1) for w, n in REGDECL_RE.findall(body)}
    if got_regs != expect_regs:
        fail(mod, '寄存器声明集合有模板外内容: 多 %s / 少 %s / 位宽异 %s'
                  % (sorted(set(got_regs) - set(expect_regs)),
                     sorted(set(expect_regs) - set(got_regs)),
                     sorted(n for n in set(got_regs) & set(expect_regs)
                            if got_regs[n] != expect_regs[n])))

    # --- 控制线与 valid 更新：逐字模板 ---
    for tpl in [
        'if (reset) begin reg1stValid <= 1\'h0; reg2ndValid <= 1\'h0; end',
        'reg1stValid <= _GEN | ~(io_out_ready & ~reg2ndValid) & reg1stValid;',
        'if (_GEN_0) reg2ndValid <= reg1stValid; else '
        'reg2ndValid <= ~io_out_ready & reg2ndValid;',
    ]:
        if norm(tpl) not in body1:
            fail(mod, 'valid 更新式不符模板: %s' % tpl)

    # --- payload 写：每字段两条（in→1st、1st→2nd），且都在正确的使能下 ---
    for f in fields:
        if 'reg1stData_%s <= io_in_bits_%s;' % (f, f) not in body1:
            fail(mod, '缺 reg1stData_%s 写入' % f)
        if 'reg2ndData_%s <= reg1stData_%s;' % (f, f) not in body1:
            fail(mod, '缺 reg2ndData_%s 写入' % f)
    m1 = re.search(r'if \(_GEN\) begin\s*(.*?)end', body, re.S)
    m2 = re.search(r'if \(_GEN_0\) begin\s*(.*?)end', body, re.S)
    if not m1 or not m2:
        fail(mod, 'payload 写使能块结构不符')
    w1 = sorted(norm(x) for x in re.findall(r'(\w+ <= \w+;)', m1.group(1)))
    w2 = sorted(norm(x) for x in re.findall(r'(\w+ <= \w+;)', m2.group(1)))
    if w1 != sorted('reg1stData_%s <= io_in_bits_%s;' % (f, f) for f in fields):
        fail(mod, 'reg1st 写块内容与字段表不一致')
    if w2 != sorted('reg2ndData_%s <= reg1stData_%s;' % (f, f) for f in fields):
        fail(mod, 'reg2nd 写块内容与字段表不一致')

    # --- 全部组合输出：assign + wire 初始化，集合必须恰好等于模板 ---
    expect = {
        '_GEN': '~reg2ndValid & io_in_valid',
        '_GEN_0': '_GEN & ~io_out_ready',
        'io_in_ready': '~reg2ndValid',
        'io_out_valid': 'reg1stValid | reg2ndValid',
    }
    for f in fields:
        expect['io_out_bits_' + f] = 'reg2ndValid ? reg2ndData_%s : reg1stData_%s' % (f, f)
    got = {n: norm(e) for n, e in ASSIGN_RE.findall(body)}
    got.update({n: norm(e) for n, e in WIREINIT_RE.findall(body)})
    if got != expect:
        fail(mod, '组合逻辑集合有模板外内容: 多 %s / 少 %s / 表达式异 %s'
                  % (sorted(set(got) - set(expect)),
                     sorted(set(expect) - set(got)),
                     sorted(n for n in set(got) & set(expect) if got[n] != expect[n])))

    return dict(mod=mod, fam='spill', P=P, fields=[(f, W['io_in_bits_' + f]) for f in fields],
                glines=len(txt.splitlines()))


def parse_repeat(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    W = {n: w for _, w, n in P}
    names = {n for _, _, n in P}
    body = body_of(txt, mod)
    body1 = norm(body)
    common_checks(mod, body, P)

    if 'io_repeat' not in names:
        fail(mod, '缺 io_repeat 端口')
    has_full = 'io_full' in names

    fields = [n[len('io_enq_bits_'):] for d, _, n in P
              if d == 'input' and n.startswith('io_enq_bits_')]
    if not fields:
        fail(mod, '没有 io_enq_bits_* 端口')
    for f in fields:
        if ('io_deq_bits_' + f) not in W:
            fail(mod, '字段 %s 没有对应的 io_deq_bits_%s' % (f, f))
        if W['io_deq_bits_' + f] != W['io_enq_bits_' + f]:
            fail(mod, '字段 %s 出入位宽不一致' % f)

    # --- 寄存器声明集合：full + 每字段 saved_* ---
    expect_regs = {'full': 1}
    for f in fields:
        expect_regs['saved_' + f] = W['io_enq_bits_' + f]
    got_regs = {n: (int(w) + 1 if w else 1) for w, n in REGDECL_RE.findall(body)}
    if got_regs != expect_regs:
        fail(mod, '寄存器声明集合有模板外内容: 多 %s / 少 %s / 位宽异 %s'
                  % (sorted(set(got_regs) - set(expect_regs)),
                     sorted(set(expect_regs) - set(got_regs)),
                     sorted(n for n in set(got_regs) & set(expect_regs)
                            if got_regs[n] != expect_regs[n])))

    # --- full 更新与 saved 写使能：逐字模板 ---
    tpl = ('full <= ~(io_deq_ready & io_deq_valid_0 & ~io_repeat) & (_GEN | full);')
    if norm(tpl) not in body1:
        fail(mod, 'full 更新式不符模板: %s' % tpl)
    if 'if (reset) full <= 1\'h0;' not in body1:
        fail(mod, 'full 异步复位不符模板')
    for f in fields:
        if 'saved_%s <= io_enq_bits_%s;' % (f, f) not in body1:
            fail(mod, '缺 saved_%s 写入' % f)
    ms = re.search(r'if \(_GEN\) begin\s*(.*?)end', body, re.S)
    if not ms:
        fail(mod, 'saved 写使能块结构不符')
    ws = sorted(norm(x) for x in re.findall(r'(\w+ <= \w+;)', ms.group(1)))
    if ws != sorted('saved_%s <= io_enq_bits_%s;' % (f, f) for f in fields):
        fail(mod, 'saved 写块内容与字段表不一致')

    # --- 全部组合输出：assign + wire 初始化，集合必须恰好等于模板 ---
    expect = {
        'io_deq_valid_0': 'io_enq_valid | full',
        'io_enq_ready_0': 'io_deq_ready & ~full',
        '_GEN': 'io_enq_ready_0 & io_enq_valid & io_repeat',
        'io_enq_ready': 'io_enq_ready_0',
        'io_deq_valid': 'io_deq_valid_0',
    }
    if has_full:
        expect['io_full'] = 'full'
    for f in fields:
        expect['io_deq_bits_' + f] = 'full ? saved_%s : io_enq_bits_%s' % (f, f)
    got = {n: norm(e) for n, e in ASSIGN_RE.findall(body)}
    got.update({n: norm(e) for n, e in WIREINIT_RE.findall(body)})
    if got != expect:
        fail(mod, '组合逻辑集合有模板外内容: 多 %s / 少 %s / 表达式异 %s'
                  % (sorted(set(got) - set(expect)),
                     sorted(set(expect) - set(got)),
                     sorted(n for n in set(got) & set(expect) if got[n] != expect[n])))

    return dict(mod=mod, fam='repeat', P=P, has_full=has_full,
                fields=[(f, W['io_enq_bits_' + f]) for f in fields],
                glines=len(txt.splitlines()))


def layout(R):
    """拼字布局：字段按 golden 端口序，首字段占最高位。返回 [(field, hi, lo)]。"""
    hi = sum(w for _, w in R['fields'])
    out = []
    for f, w in R['fields']:
        out.append((f, hi - 1, hi - w))
        hi -= w
    assert hi == 0
    return out


def header(R):
    m = R['mod']
    parent, what = dict(SPILLS, **REPEATS)[m]
    word_w = sum(w for _, w in R['fields'])
    L = ['// %s.sv —— %s' % (m, what), '//']
    fields = ' + '.join('%s[%d]' % (f, w) for f, w in R['fields'])
    L.append('// payload %d 位（%s），父模块 %s。' % (word_w, fields, parent))
    L.append('// 拼字布局（首字段在最高位）：' +
             '  '.join('%s[%d:%d]' % (f, a, b) if a != b else '%s[%d]' % (f, a)
                      for f, a, b in layout(R)))
    if R['fam'] == 'spill':
        L.append('// 控制 + 存储在共享核 rtl/uncore/xs_SpillRegister_core.sv（语义见该文件头，'
                 'SpillRegister / SpillRegister_2 / SpillRegister_6 三变体同用）；')
        L.append('// 本文件只做字段拼字/拆字与端口同名转发，两个 valid 异步复位、'
                 '两级 payload 寄存器照 golden 不复位。')
    else:
        L.append('// 控制 + 存储在共享核 rtl/uncore/xs_Repeater_core.sv（语义见该文件头，'
                 'Repeater_1 / Repeater_2 两变体同用）；')
        if R['has_full']:
            L.append('// 本变体带 io_full 观测口，直连核的 full；full 异步复位、'
                     'saved payload 寄存器照 golden 不复位。')
        else:
            L.append('// 本变体无 io_full 端口（golden 就没引出），核的 full 输出悬空；'
                     'full 异步复位、saved payload 寄存器照 golden 不复位。')
    L.append('// golden %d 行；端口表与连线由 scripts/gen_busbuffer_leaves5.py 从 golden '
             '机械生成并逐字段校验。' % R['glines'])
    return '\n'.join(L) + '\n\n'


def emit(R):
    m = R['mod']
    word_w = sum(w for _, w in R['fields'])
    lay = layout(R)
    pre = 'in' if R['fam'] == 'spill' else 'enq'
    post = 'out' if R['fam'] == 'spill' else 'deq'
    core = 'xs_SpillRegister_core' if R['fam'] == 'spill' else 'xs_Repeater_core'
    L = [header(R)]
    A = L.append
    A('// BEGIN GENERATED(%s) —— scripts/gen_busbuffer_leaves5.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n)
                 for d, w, n in R['P']))
    A(');')
    A('')
    A('  logic [%d:0] in_payload, out_payload;' % (word_w - 1))
    A('')
    A('  // 入侧拼字（首字段在最高位，字段顺序照 golden 端口序）')
    A('  assign in_payload = {')
    A(',\n'.join('    io_%s_bits_%s' % (pre, f) for f, _ in R['fields']))
    A('  };')
    A('')
    A('  %s #(.W(%d)) u_core (' % (core, word_w))
    conns = ['    .clock       (clock)',
             '    .reset       (reset)']
    if R['fam'] == 'repeat':
        conns.append('    .repeat_req  (io_repeat)')
        conns.append('    .full        (%s)' % ('io_full' if R['has_full'] else ''))
    conns += ['    .%s_ready   (io_%s_ready)' % (pre, pre),
              '    .%s_valid   (io_%s_valid)' % (pre, pre),
              '    .%s_payload (in_payload)' % pre,
              '    .%s_ready   (io_%s_ready)' % (post, post),
              '    .%s_valid   (io_%s_valid)' % (post, post),
              '    .%s_payload (out_payload)' % post]
    A(',\n'.join(conns))
    A('  );')
    A('')
    for f, a, b in lay:
        src = 'out_payload[%d]' % a if a == b else 'out_payload[%d:%d]' % (a, b)
        A('  assign io_%s_bits_%s = %s;' % (post, f, src))
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    mods = list(SPILLS) + list(REPEATS)
    for q in mods:
        R = parse_spill(q) if q in SPILLS else parse_repeat(q)
        txt = emit(R)
        p = os.path.join(REPO, 'rtl', 'uncore', q + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-16s fam=%-6s word=%-3d fields=%-2d full_port=%s'
              % (q, R['fam'], sum(w for _, w in R['fields']), len(R['fields']),
                 R.get('has_full', '-')))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
