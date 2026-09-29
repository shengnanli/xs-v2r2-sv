#!/usr/bin/env python3
"""gen_l2_arbiter3.py —— MainPipe_1（L2 tl2chi 主流水）的三个 3 入口固定优先级仲裁器薄文件。

  Arbiter3_CHIREQ        toTXREQ_arb   （s3 / s4 / s5 三级的 CHI 请求并成一路）
  Arbiter3_TaskBundle    toTXRSP_arb   （同上，CHI 响应）
  Arbiter3_TaskWithData  toSourceD_arb / toTXDAT_arb（带数据的任务）

三者都是 chisel3 Arbiter（lowest-index-wins，纯组合），核是已签核的 rtl/frontend/xs_FixedPriorityArbiter_core.sv
（语义与"一路都没请求时给最后一路载荷"的细节讲在那里），本脚本只从 golden 端口表生成薄文件：
  * 每一路的字段表必须与 io_out_bits_* 完全相同（逐名逐宽断言），载荷 MSB 优先按 golden 端口顺序拼；
  * firtool 删掉的 ready 端口：MainPipe 对 toTXREQ / toTXRSP 的 out.ready 恒 1（下游是本拍就收的队列入口
    判定已在 MainPipe 里做完），于是 io_out_ready 与 io_in_0_ready（= out_ready）都不存在 —— 这里把核的
    out_ready 接 1'b1、in_ready 最高位悬空，端口数恒等式把删掉的根数加回去。

用法：python3 scripts/gen_l2_arbiter3.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = os.path.join(REPO, 'rtl', 'uncore')
NUM_IN = 3
VARIANTS = {
    'Arbiter3_CHIREQ':       'MainPipe_1 的 toTXREQ_arb：s3/s4/s5 三级发往 CHI TXREQ 的请求（CHIREQ）并成一路',
    'Arbiter3_TaskBundle':   'MainPipe_1 的 toTXRSP_arb：s3/s4/s5 三级发往 CHI TXRSP 的响应任务并成一路',
    'Arbiter3_TaskWithData': 'MainPipe_1 的 toSourceD_arb / toTXDAT_arb：s3/s4/s5 三级带数据的任务并成一路',
}


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('module %s(' % mod)
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t.count('\n') + 1


def emit(mod, desc):
    P, glines = ports(mod)
    names = [n for _, _, n in P]
    outf = [(n[len('io_out_bits_'):], w) for _, w, n in P if n.startswith('io_out_bits_')]
    for k in range(NUM_IN):
        f = [(n[len('io_in_%d_bits_' % k):], w) for _, w, n in P if n.startswith('io_in_%d_bits_' % k)]
        assert f == outf, '%s 第 %d 路字段表与出口不同' % (mod, k)
        assert 'io_in_%d_valid' % k in names
    width = sum(w for _, w in outf)
    has_out_ready = 'io_out_ready' in names
    ready_present = ['io_in_%d_ready' % k in names for k in range(NUM_IN)]
    missing = (0 if has_out_ready else 1) + ready_present.count(False)
    if not has_out_ready:
        # 只认得这一种删法：out_ready 恒 1 时 in_0_ready = out_ready 也恒 1，被一起删掉
        assert ready_present == [False, True, True], (mod, ready_present)
    else:
        assert all(ready_present), (mod, ready_present)
    bits_ports = sum(1 for n in names if '_bits_' in n)
    assert len(P) + missing == 2 * NUM_IN + 2 + bits_ports

    def cat(prefix, ind=6):
        # 一个字段一行，免得 95 个字段挤成一行
        sep = ',\n' + ' ' * ind
        return '{' + sep.join(prefix + f for f, _ in outf) + '}'

    L = []
    W = L.append
    W('// %s.sv —— %s' % (mod, desc))
    W('//')
    W('// chisel3 Arbiter（3 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv（已签核）。')
    W('// 载荷 = 每一路 %d 个字段、%d 位，字段表与 io_out_bits_* 逐名逐宽相同，按 golden 端口顺序 MSB 优先拼。' % (len(outf), width))
    if not has_out_ready:
        W('// ★少两根 ready★：MainPipe 对这一路的 out.ready 恒 1，firtool 把 io_out_ready 与 io_in_0_ready（= out_ready）一起删了；')
        W('// 核的 out_ready 接 1\'b1，in_ready 最高位（第 0 路）悬空，端口数恒等式把这两根加回去。')
    W('// golden %d 行；本文件由 scripts/gen_l2_arbiter3.py 从 golden 端口表生成（勿手改）。' % glines)
    W('')
    W('module %s (' % mod)
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    W('  localparam int unsigned NUM_IN = %d;' % NUM_IN)
    W('  localparam int unsigned WIDTH  = %d;' % width)
    W('')
    W('  // 位 NUM_IN-1 = 第 0 路（优先级最高），与核的 in_valid 位序一致')
    W('  logic [NUM_IN-1:0]       in_valid_vec;')
    W('  logic [NUM_IN-1:0]       in_ready_vec;')
    W('  logic [NUM_IN*WIDTH-1:0] in_bits_flat;')
    W('  logic [WIDTH-1:0]        out_bits_flat;')
    W('  assign in_valid_vec = {%s};' % ', '.join('io_in_%d_valid' % k for k in range(NUM_IN)))
    W('  assign in_bits_flat = {')
    W(',\n'.join('    %s' % cat('io_in_%d_bits_' % k, 5) for k in range(NUM_IN)))
    W('  };')
    for k in range(NUM_IN):
        if ready_present[k]:
            W('  assign io_in_%d_ready = in_ready_vec[%d];' % (k, NUM_IN - 1 - k))
    W('')
    W('  xs_FixedPriorityArbiter_core #(')
    W('    .WIDTH            (WIDTH),')
    W('    .NUM_IN           (NUM_IN),')
    W('    .PORT_BITS_OUT    ($bits(%s)),' % cat('io_out_bits_', 25))
    W('    .PORT_BITS_LAST_IN($bits(%s)),' % cat('io_in_%d_bits_' % (NUM_IN - 1), 25))
    W('    .GOLDEN_PORTS     (%d + %d),   // 现存端口 + firtool 删掉的 ready' % (len(P), missing))
    W('    .GOLDEN_BITS_PORTS(%d)' % bits_ports)
    W('  ) u_core (')
    W('    .in_valid (in_valid_vec),')
    W('    .in_ready (in_ready_vec),')
    W('    .in_bits  (in_bits_flat),')
    W("    .out_ready(%s)," % ('io_out_ready' if has_out_ready else "1'b1"))
    W('    .out_valid(io_out_valid),')
    W('    .out_bits (out_bits_flat)')
    W('  );')
    W('')
    W('  assign %s = out_bits_flat;' % cat('io_out_bits_', 10))
    W('')
    W('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for mod, desc in VARIANTS.items():
        txt = emit(mod, desc)
        p = os.path.join(OUT_DIR, mod + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad = 1
        elif cur != txt:
            open(p, 'w').write(txt)
            print('wrote %s' % p)
    return bad


if __name__ == '__main__':
    sys.exit(main())
