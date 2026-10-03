#!/usr/bin/env python3
"""gen_busperfmonitor.py —— BusPerfMonitor（TileLink 总线性能监视节点）的重写文件。

BusPerfMonitor（src/main/scala/top/BusPerfMonitor.scala）是插在 L1→L2 总线上的一个透明节点：
`out <> in` 原样直连，另外按通道 / opcode 统计握手次数、阻塞拍数与延迟（XSPerfAccumulate / XSPerfHistogram）。
G1 golden 是综合配置，perf 计数全部不落地（golden 里只剩一堆没人读的 `_GEN_n` 握手线），所以模块体就是
97 根直连线。这里没有可写的"核"：整个文件由 golden 端口表生成，生成时断言
  * 每个 output 都能在对侧找到同名同宽的 input（in<->out 互换前缀）；
  * 每个 input 恰好被用一次（不多不少），即端口表是完全配对的；
  * golden 的 assign 条数 == output 个数（golden 体里除了直连没有别的驱动）。

用法：python3 scripts/gen_busperfmonitor.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
MOD = 'BusPerfMonitor'
OUT = os.path.join(REPO, 'rtl', 'uncore', MOD + '.sv')

# 三个上游主口各是谁（XSTile：L1 的三个 TileLink 主设备汇进 L2 之前各过一个监视点）
PORT_DESC = {
    '0': 'DCache（TL-C：A/B/C/D/E 五通道，带 alias/vaddr/needHint/isKeyword）',
    '1': 'ICache（TL-UH：A/D 两通道）',
    '2': 'PTW（L2TLB 的访存口，TL-UH：A/D 两通道）',
}
CHAN_DESC = {'a': 'A 请求  in -> out', 'b': 'B 探测  out -> in', 'c': 'C 释放  in -> out',
             'd': 'D 应答  out -> in', 'e': 'E 确认  in -> out'}


def ports():
    t = open(os.path.join(G, MOD + '.sv')).read()
    i = t.index('\nmodule %s(' % MOD) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            raise SystemExit('端口行解析失败: %r' % line)
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t


def emit():
    P, gtxt = ports()
    inputs = {n: w for d, w, n in P if d == 'input'}
    outputs = [(n, w) for d, w, n in P if d == 'output']
    used = set()
    groups = {}                       # (端口号, 通道) -> [(dst, src)]
    for n, w in outputs:
        m = re.match(r'auto_(in|out)_(\d)_([a-e])_(\w+)$', n)
        assert m, n
        src = 'auto_%s_%s_%s_%s' % ('out' if m.group(1) == 'in' else 'in', m.group(2), m.group(3), m.group(4))
        assert inputs.get(src) == w, '%s 找不到同宽的对侧输入 %s' % (n, src)
        assert src not in used
        used.add(src)
        groups.setdefault((m.group(2), m.group(3)), []).append((n, src))
    assert used == set(inputs), sorted(set(inputs) - used)[:5]
    n_assign = len(re.findall(r'^  assign ', gtxt, re.M))
    assert n_assign == len(outputs), (n_assign, len(outputs))
    assert sorted(set(k[0] for k in groups)) == sorted(PORT_DESC), sorted(groups)

    L = []
    W = L.append
    W('// %s.sv —— L1→L2 TileLink 总线上的性能监视节点（综合配置下是一段直连线）' % MOD)
    W('//')
    W('// 位置：XSTile 里 DCache / ICache / PTW 三个 TileLink 主设备汇入 L2 之前各过本节点的一个口')
    W('//   （src/main/scala/top/BusPerfMonitor.scala，`out <> in`）。Scala 里它另外按通道与 opcode 统计握手次数、')
    W('//   阻塞拍数和请求-应答延迟，全是 XSPerfAccumulate / XSPerfHistogram；G1 golden 是综合配置，这些计数')
    W('//   不落地，golden 体里只留下一批没人读的握手线，对端口没有任何影响。')
    W('// 所以本模块没有状态、没有逻辑：%d 个 output 各自直连对侧同名 input（A/C/E 由 in 到 out，B/D 由 out 到 in，' % len(outputs))
    W('//   valid/bits 与 ready 方向相反）。无时钟、无复位。')
    W('// golden %d 行 / %d 端口；本文件由 scripts/gen_busperfmonitor.py 从 golden 端口表生成（勿手改）。'
      % (gtxt.count('\n') + 1, len(P)))
    W('')
    W('module %s (' % MOD)
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    for port in sorted(PORT_DESC):
        W('')
        W('  // ===== 口 %s：%s =====' % (port, PORT_DESC[port]))
        for ch in 'abcde':
            if (port, ch) not in groups:
                continue
            W('  // ---- %s ----' % CHAN_DESC[ch])
            g = groups[(port, ch)]
            pad = max(len(d) for d, _ in g)
            for d, s in g:
                W('  assign %-*s = %s;' % (pad, d, s))
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
