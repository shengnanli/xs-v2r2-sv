#!/usr/bin/env python3
"""gen_l2tlbwrapper.py —— L2TLBWrapper（共享 MMU 顶层 L2TLB 的 LazyModule 外壳）的重写文件。

src/main/scala/xiangshan/cache/mmu/L2TLB.scala 的 class L2TLBWrapper：`io <> ptw.module.io`，外加
HasPerfEvents.generatePerfEvent() —— 把 L2TLB 报上来的 19 个 perf 事件计数各打两拍再送出
（io.perf(n).value = RegNext(RegNext(ptw.io.perf(n).value))，不复位）。golden 1018 行里除了这 38 个寄存器，
全是 L2TLB 实例的逐端口连线。

本脚本从 golden 端口表生成 rtl/mmu/L2TLBWrapper.sv：
  * wrapper 端口 = golden 端口；L2TLB 实例的端口集合必须与之完全相同（逐名逐宽，从 golden L2TLB.sv 现读）；
  * 非 perf 端口直连 L2TLB 实例（实例名保持 golden 的 `ptw`，FM 两侧黑盒路径对称：r:/WORK/L2TLBWrapper/ptw
    与 i:/WORK/L2TLBWrapper/ptw）；
  * io_perf_<n>_value 从实例接到一根 wire，经两级不复位寄存器后出去；
  * 反向全覆盖：golden 每个端口都落进"perf 出口"或"直连"两种形状之一。

用法：python3 scripts/gen_l2tlbwrapper.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
MOD = 'L2TLBWrapper'
CHILD = 'L2TLB'
OUT = os.path.join(REPO, 'rtl', 'mmu', MOD + '.sv')


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


def emit():
    P, glines = ports(MOD)
    C, _ = ports(CHILD)
    assert [(d, w, n) for d, w, n in P] == [(d, w, n) for d, w, n in C], 'L2TLBWrapper 与 L2TLB 的端口表不同'
    perf = [(w, n) for d, w, n in P if re.match(r'io_perf_\d+_value$', n)]
    assert all(d == 'output' for d, w, n in P if n in dict((n, w) for w, n in perf))
    assert len(perf) == 19 and all(w == 6 for w, _ in perf), perf
    plain = [n for d, w, n in P if not re.match(r'io_perf_\d+_value$', n)]
    assert len(plain) + len(perf) == len(P)

    L = []
    W = L.append
    W('// %s.sv —— 共享 MMU 顶层 L2TLB 的外壳：端口直通 + perf 计数打两拍' % MOD)
    W('//')
    W('// 位置：MemBlock 里 L1 TLB 们的 PTW 口汇到这里（src/main/scala/xiangshan/cache/mmu/L2TLB.scala 的')
    W('//   class L2TLBWrapper，LazyModule 外壳）。它只做两件事：')
    W('//   1. `io <> ptw.module.io`：%d 个端口原样接到 L2TLB 实例 ptw；' % len(plain))
    W('//   2. HasPerfEvents.generatePerfEvent()：L2TLB 报上来的 %d 个 perf 事件计数（各 6 位）各打两拍再送出' % len(perf))
    W('//      （两级寄存器都不复位）。')
    W('// 子模块 L2TLB 是本仓的独立目标（rtl/memblock/L2TLB.sv），本层证明时两侧对称黑盒（实例名保持 golden 的 ptw）。')
    W('// golden %d 行 / %d 端口；本文件由 scripts/gen_l2tlbwrapper.py 从 golden 端口表生成（勿手改）。' % (glines, len(P)))
    W('')
    W('module %s (' % MOD)
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    W('  // ---- perf 计数打两拍（不复位）----')
    W('  localparam int unsigned NUM_PERF = %d;' % len(perf))
    W('  logic [5:0] ptw_perf    [NUM_PERF];   // L2TLB 实例报上来的计数')
    W('  logic [5:0] perf_stage1 [NUM_PERF];')
    W('  logic [5:0] perf_stage2 [NUM_PERF];')
    W('  always_ff @(posedge clock) begin')
    W('    for (int n = 0; n < NUM_PERF; n++) begin')
    W('      perf_stage1[n] <= ptw_perf[n];')
    W('      perf_stage2[n] <= perf_stage1[n];')
    W('    end')
    W('  end')
    for k, (w, n) in enumerate(perf):
        W('  assign %s = perf_stage2[%d];' % (n, k))
    W('')
    W('  // ---- L2TLB 本体：除 perf 外逐端口直通 ----')
    W('  %s ptw (' % CHILD)
    pad = max(len(n) for _, _, n in P)
    conns = []
    for d, w, n in P:
        m = re.match(r'io_perf_(\d+)_value$', n)
        conns.append('    .%-*s (%s)' % (pad, n, 'ptw_perf[%d]' % int(m.group(1)) if m else n))
    W(',\n'.join(conns))
    W('  );')
    W('')
    W('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    txt = emit()
    cur = open(OUT).read() if os.path.exists(OUT) else None
    if a.check:
        if cur != txt:
            print('DRIFT: %s' % OUT)
            return 1
        print('OK: %s' % OUT)
        return 0
    if cur != txt:
        open(OUT, 'w').write(txt)
        print('wrote %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
