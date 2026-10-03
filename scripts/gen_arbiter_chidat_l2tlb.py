#!/usr/bin/env python3
"""gen_arbiter_chidat_l2tlb.py —— 两个 chisel3 固定优先级 Arbiter 的薄文件（lane mmiobridge-xbar-l2tlbwrap）。

  Arbiter16_CHIDAT        rtl/uncore/  MMIOBridge 把 16 个事务槽的 CHI TXDAT（写数据）并成一路
  Arbiter3_L2TLBImp_Anon  rtl/mmu/     L2TLB 把 cache 命中 / PTW / LLPTW 三个来源的应答并成一路（两处例化：
                                       mergeArb 的两个出口各一个）

两者都是 chisel3 Arbiter（lowest-index-wins，纯组合）。核是已签核的 rtl/frontend/xs_FixedPriorityArbiter_core.sv
（语义与"一路都没请求时给最后一路载荷"的细节讲在那里，本脚本不改核），这里只从 golden 端口表生成薄文件：
  * 载荷按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼；
  * 某一路**没有**的字段（上游把它钉成常量 0，firtool 把端口删了）在拼载荷时填 1'b0 —— 这正是 golden 里
    `~io_in_0_valid & (...)` 那种式子的来历：第 0 路被选中时该字段输出 0。只允许"缺字段"，不允许多字段，
    且最后一路必须字段齐全（核的兜底分支用它）；
  * 端口数恒等式：现存端口 = 2*NUM_IN + 2 + 全部 *_bits_* 端口。

用法：python3 scripts/gen_arbiter_chidat_l2tlb.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')

# 模块名 -> (输出目录, 入口数, 一句话说明)
VARIANTS = {
    'Arbiter16_CHIDAT': (
        'uncore', 16,
        'MMIOBridge 的 TXDAT 汇流：16 个事务槽（MMIOBridgeEntry）的 CHI 写数据并成一路，槽号小的优先'),
    'Arbiter3_L2TLBImp_Anon': (
        'mmu', 3,
        'L2TLB 的应答汇流：页表 cache 命中 / PTW / LLPTW 三个来源给同一个请求方的应答并成一路'),
}


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('\nmodule %s(' % mod) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            raise SystemExit('%s: 端口行解析失败: %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t.count('\n') + 1


def emit(mod):
    sub, num_in, desc = VARIANTS[mod]
    P, glines = ports(mod)
    names = [n for _, _, n in P]
    width_of = {n: w for _, w, n in P}
    outf = [(n[len('io_out_bits_'):], w) for _, w, n in P if n.startswith('io_out_bits_')]
    width = sum(w for _, w in outf)
    missing = []                      # 每一路缺的字段
    for k in range(num_in):
        pre = 'io_in_%d_bits_' % k
        have = [(n[len(pre):], w) for _, w, n in P if n.startswith(pre)]
        # 现存字段必须是出口字段表的保序子序列（逐名逐宽）
        it = iter(outf)
        assert all(f in it for f in have), '%s 第 %d 路字段不是出口字段表的保序子集' % (mod, k)
        missing.append([f for f, _ in outf if (f, width_of.get('io_out_bits_' + f)) not in have])
        assert 'io_in_%d_valid' % k in names and 'io_in_%d_ready' % k in names, (mod, k)
    assert not missing[-1], '%s 最后一路字段不全，核的兜底分支用不了' % mod
    assert 'io_out_ready' in names and 'io_out_valid' in names
    bits_ports = sum(1 for n in names if '_bits_' in n)
    assert len(P) == 2 * num_in + 2 + bits_ports, (mod, len(P), bits_ports)
    # 反向全覆盖：golden 的每个端口都落在已知形状里
    known = set(['io_out_ready', 'io_out_valid'] + ['io_out_bits_' + f for f, _ in outf])
    for k in range(num_in):
        known |= set(['io_in_%d_ready' % k, 'io_in_%d_valid' % k])
        known |= set('io_in_%d_bits_%s' % (k, f) for f, _ in outf if f not in missing[k])
    assert known == set(names), sorted(set(names) ^ known)[:5]

    def cat(k, ind):
        """第 k 路（k=None 为出口）的载荷拼接，一个字段一行；缺的字段填常量 0。"""
        items = []
        for f, w in outf:
            if k is not None and f in missing[k]:
                items.append("%d'h0 /* 本路无 %s */" % (w, f))
            else:
                items.append(('io_out_bits_' if k is None else 'io_in_%d_bits_' % k) + f)
        return '{' + (',\n' + ' ' * ind).join(items) + '}'

    # 头注释与模块体分开拼：模块体里埋分节注释，>1500 行的文件按可读性闸要配"本文件导航"
    # （导航行号必须真落在分节注释上），所以先拼体、再算行号、最后拼头。
    B = []
    W = B.append
    marks = []                                   # (体内下标, 导航文字)

    def section(title):
        marks.append((len(B), title))
        W('  // ' + '-' * 74)
        W('  // ' + title)
        W('  // ' + '-' * 74)
    W('module %s (' % mod)
    section('端口表（与 golden 逐名逐宽相同，%d 个）' % len(P))
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    section('入口载荷拼接：%d 路 × %d 位，位 NUM_IN-1 = 第 0 路（优先级最高）' % (num_in, width))
    W('  localparam int unsigned NUM_IN = %d;' % num_in)
    W('  localparam int unsigned WIDTH  = %d;' % width)
    W('')
    W('  logic [NUM_IN-1:0]       in_valid_vec;')
    W('  logic [NUM_IN-1:0]       in_ready_vec;')
    W('  logic [NUM_IN*WIDTH-1:0] in_bits_flat;')
    W('  logic [WIDTH-1:0]        out_bits_flat;')
    W('  assign in_valid_vec = {%s};' % ', '.join('io_in_%d_valid' % k for k in range(num_in)))
    W('  assign in_bits_flat = {')
    W(',\n'.join('    %s' % cat(k, 5) for k in range(num_in)))
    W('  };')
    for k in range(num_in):
        W('  assign io_in_%d_ready = in_ready_vec[%d];' % (k, num_in - 1 - k))
    W('')
    section('核例化（xs_FixedPriorityArbiter_core，端口数恒等式在核里自检）')
    W('  xs_FixedPriorityArbiter_core #(')
    W('    .WIDTH            (WIDTH),')
    W('    .NUM_IN           (NUM_IN),')
    W('    .PORT_BITS_OUT    ($bits(%s)),' % cat(None, 25))
    W('    .PORT_BITS_LAST_IN($bits(%s)),' % cat(num_in - 1, 25))
    W('    .GOLDEN_PORTS     (%d),' % len(P))
    W('    .GOLDEN_BITS_PORTS(%d)' % bits_ports)
    W('  ) u_core (')
    W('    .in_valid (in_valid_vec),')
    W('    .in_ready (in_ready_vec),')
    W('    .in_bits  (in_bits_flat),')
    W('    .out_ready(io_out_ready),')
    W('    .out_valid(io_out_valid),')
    W('    .out_bits (out_bits_flat)')
    W('  );')
    W('')
    section('出口载荷拆分')
    W('  assign %s = out_bits_flat;' % cat(None, 10))
    W('')
    W('endmodule')

    H = []
    W = H.append
    W('// %s.sv —— %s' % (mod, desc))
    W('//')
    W('// chisel3 Arbiter（%d 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv（已签核，' % num_in)
    W('// 语义讲在那里：in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路的载荷）。')
    W('// 载荷 = %d 个字段、%d 位，按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼。' % (len(outf), width))
    if any(missing):
        W('// ★有的入口缺字段★：上游把这些字段钉成 0，firtool 就把端口删了；拼载荷时在原位置填 0，')
        W('// 于是该路被选中时出口对应字段为 0（golden 里写成 `~io_in_0_valid & (...)` 的那些式子）。')
        for k in range(num_in):
            if missing[k]:
                W('//   第 %d 路缺 %d 个：%s' % (k, len(missing[k]), ' '.join(missing[k])))
    W('// golden %d 行 / %d 端口；本文件由 scripts/gen_arbiter_chidat_l2tlb.py 从 golden 端口表生成（勿手改）。'
      % (glines, len(P)))
    body_lines = '\n'.join(B).splitlines()
    # 先用占位导航拼出全文，再在全文里找分节标题行号回填（导航自身行数固定，行号不会再漂）
    nav = ['// 本文件导航（共 %d 行；一个 golden 模块一个文件、不拆分，用下面的分节定位）：'
           % (len(H) + 1 + len(marks) + 1 + len(body_lines))] + ['' for _ in marks]
    L = H + nav + [''] + body_lines
    for k, (_, title) in enumerate(marks):
        L[len(H) + 1 + k] = '//   L%-5d %s' % (L.index('  // ' + title) + 1, title)
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for mod in VARIANTS:
        txt = emit(mod)
        p = os.path.join(REPO, 'rtl', VARIANTS[mod][0], mod + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad = 1
        elif cur != txt:
            open(p, 'w').write(txt)
            print('wrote %s' % p)
    if a.check and not bad:
        print('OK: gen_arbiter_chidat_l2tlb.py（%d 个薄文件与生成结果一致）' % len(VARIANTS))
    return bad


if __name__ == '__main__':
    sys.exit(main())
