#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_datapath_arb.py —— DataPath 的 10 个读口/写口仲裁装配壳的 GENERATED 区。

对象（全部是 DataPath 的直接 child，golden 里本层只有 WBArbiter 例化 + 常量 ready）：
  *RFWBCollideChecker ×5（Int/Fp/Vf/V0/Vl）：写回口撞口检查
  *RFReadArbiter      ×5（Int/Fp/Vf/V0/Vl）：寄存器堆读口仲裁

每个文件 = 手写文件头（机制/边界/怪癖，本脚本不碰） + 一段
`// BEGIN GENERATED(dp_arb)` … `// END GENERATED`，内容为：
  1. golden 同名模块的端口表（逐行照抄 golden，端口契约闸 PORTLINT_ORDER=fail 要求逐位同名同序）；
  2. 每个读口/写口一个 WBArbiter 例化（类型名、实例名 arbiters_<k>、接线全部由 golden 解析），
     例化前一行注释写明"这个口由谁竞争、优先级顺序"——这是本层唯一的设计信息；
  3. 不参与本寄存器堆的输入（NoRD / NoWB）ready 恒 1。

★不照抄的东西★：IntRFReadArbiter 里 golden 有一段 XSPerfAccumulate 残留的冲突计数组合逻辑
（hasConflict / hasRead0 / hasSameAddr），firtool 保留了线网但**没有任何负载**（不到端口、
不进寄存器）。它不产生任何比较点，本仓不生成（见该文件头）。本脚本断言：golden 里除
WBArbiter 例化、`assign <port> = 1'h1` 与这类无负载线网外没有别的语句，情况变了当场退出。

用法: python3 scripts/gen_datapath_arb.py [--check]
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

TARGETS = [f'{rf}RFWBCollideChecker' for rf in ('Int', 'Fp', 'Vf', 'V0', 'Vl')] + \
          [f'{rf}RFReadArbiter' for rf in ('Int', 'Fp', 'Vf', 'V0', 'Vl')]
OUT_DIR = REPO / 'rtl' / 'backend'
BEGIN = '// BEGIN GENERATED(dp_arb) —— 由 scripts/gen_datapath_arb.py 从 golden 例化表产出，勿手改'
END = '// END GENERATED'


def die(msg):
    sys.exit(f'gen_datapath_arb: {msg}')


def parse_golden(top):
    txt = (GOLDEN / f'{top}.sv').read_text()
    m = re.search(r'^module ' + top + r'\(\n(.*?)\n\);\n(.*?)^endmodule', txt, re.S | re.M)
    if not m:
        die(f'{top}: 找不到 module 体')
    port_lines = m.group(1).split('\n')
    body = m.group(2)
    ports = []
    for ln in port_lines:
        pm = re.match(r'^\s+(input|output)\s+(\[\d+:0\]\s+)?(\w+),?$', ln)
        if not pm:
            die(f'{top}: 端口行形状不认识: {ln!r}')
        ports.append((pm.group(1), (pm.group(2) or '').strip(), pm.group(3)))

    insts = []
    for im in re.finditer(r'^  (WBArbiter(?:_\d+)?) (arbiters_(\d+)) \(\n(.*?)\n  \);\n', body, re.S | re.M):
        conns = re.findall(r'\.(\w+)\s+\((\w+)\)', im.group(4))
        if len(conns) != im.group(4).count('\n') + 1:
            die(f'{top}: {im.group(2)} 接线行数与解析数不符')
        insts.append((im.group(1), im.group(2), int(im.group(3)), conns))
    consts = re.findall(r'^  assign (\w+) = 1\'h1;$', body, re.M)

    # 断言：除上面三类之外只允许出现无负载的线网声明（Int 读仲裁的 perf 残留）
    rest = re.sub(r'^  (WBArbiter(?:_\d+)?) arbiters_\d+ \(\n.*?\n  \);\n', '', body, flags=re.S | re.M)
    rest = re.sub(r'^  assign \w+ = 1\'h1;\n', '', rest, flags=re.M)
    wires = re.findall(r'^  wire\s+(?:\[\d+:0\]\s+)?(\w+)\s*=', rest, re.M)
    stripped = re.sub(r'^  wire\s+(?:\[\d+:0\]\s+)?\w+\s*=.*?;\n', '', rest, flags=re.S | re.M)
    if stripped.strip():
        die(f'{top}: golden 里有未预期的语句:\n{stripped.strip()[:400]}')
    # 这些线网必须无负载：只在彼此之间被引用，不出现在例化接线或 assign 里
    used_by_inst = {s for (_, _, _, cs) in insts for (_, s) in cs}
    for w in wires:
        if w in used_by_inst or w in consts:
            die(f'{top}: 线网 {w} 有负载，不能省略')
    return ports, insts, consts, wires


def src_label(sig):
    """io_in_<iq>_<exu>[_<src>]_<ready|valid|bits_addr> -> 'iq<iq>.exu<exu>[.src<src>]'"""
    m = re.match(r'^io_in_(\d+)_(\d+)(?:_(\d+))?_(?:ready|valid|bits_addr)$', sig)
    if not m:
        die(f'不认识的输入名 {sig}')
    s = f'IQ{m.group(1)}.EXU{m.group(2)}'
    if m.group(3) is not None:
        s += f'.src{m.group(3)}'
    return s


def gen_block(top):
    ports, insts, consts, wires = parse_golden(top)
    is_read = top.endswith('RFReadArbiter')
    kind = '读口' if is_read else '写口'
    out = [BEGIN, f'module {top}(']
    w_dir = max(len(d) for d, _, _ in ports)
    w_rng = max(len(r) for _, r, _ in ports)
    for i, (d, r, n) in enumerate(ports):
        sep = ',' if i < len(ports) - 1 else ''
        line = f'  {d.ljust(w_dir)} {r.ljust(w_rng)} {n}{sep}' if w_rng else f'  {d.ljust(w_dir)} {n}{sep}'
        out.append(line)
    out.append(');')
    out.append('')
    # 例化按 golden 的 arbiters_<k> 编号顺序（k = 读口/写口号）
    insts_sorted = sorted(insts, key=lambda x: x[2])
    ks = [k for (_, _, k, _) in insts_sorted]
    if ks != list(range(len(ks))):
        die(f'{top}: arbiters_<k> 编号不连续: {ks}')
    for typ, name, k, conns in insts_sorted:
        cmap = dict(conns)
        n_in = len([p for p, _ in conns if re.match(r'io_in_\d+_valid$', p)])
        srcs = [src_label(cmap[f'io_in_{j}_valid']) for j in range(n_in)]
        if n_in == 1:
            out.append(f'  // {kind} {k}：只有 {srcs[0]} 一路，永不冲突')
        else:
            out.append(f'  // {kind} {k}：{n_in} 路竞争，优先级 ' + ' > '.join(srcs))
        wp = max(len(p) for p, _ in conns)
        out.append(f'  {typ} {name} (')
        for i, (p, s) in enumerate(conns):
            sep = ',' if i < len(conns) - 1 else ''
            out.append(f'    .{p.ljust(wp)} ({s}){sep}')
        out.append('  );')
    if consts:
        out.append('')
        nothing = 'NoRD' if is_read else 'NoWB'
        out.append(f'  // 不经过本寄存器堆的输入（{nothing}）：不参与任何仲裁，ready 恒 1')
        for c in consts:
            out.append(f"  assign {c} = 1'b1;")
    out.append('endmodule')
    out.append(END)
    return '\n'.join(out) + '\n', len(insts), len(consts), len(wires)


TB_PATH = REPO / 'verif' / 'ut' / 'DataPathArb' / 'tb.sv'


def gen_tb():
    """双例化 tb：10 对 golden(原名) vs 重写件(_xs)，同激励，逐拍比全部输出。"""
    L = []
    L.append('// DataPathArb UT —— DataPath 的 10 个读口/写口仲裁装配壳，golden vs 重写件双例化逐拍比全部输出')
    L.append('// ★本文件由 scripts/gen_datapath_arb.py 生成（勿手改，--check 进闸）★')
    L.append('//')
    L.append('// 激励：每个请求输入的 valid 以"本段压力"为概率置 1，压力每 1000 拍换一档（20/50/90/100%），')
    L.append('//   高压段让低优先级路连续被拒、触发 WBArbiter 的反饥饿（hasFull）；addr 全宽随机。')
    L.append('//   约每 25k 拍随机插一次 2 拍异步复位脉冲（打复位域）。')
    L.append('// 覆盖（golden 侧计数）：conflict = 有请求被拒的拍数；starve = 有仲裁器 hasFull=1 的拍数。')
    L.append('// 本层的寄存器全在 WBArbiter 里且全部异步复位，initreg 各档只影响第一次复位之前（不比对）。')
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clk = 0, rst = 1;')
    L.append('  int errors = 0, checks = 0, cyc = 0;')
    L.append('  int unsigned pct = 50;')
    L.append('  always #5 clk = ~clk;')
    L.append('')
    cov_names = []
    for top in TARGETS:
        ports, insts, _, _ = parse_golden(top)
        t = top
        L.append(f'  // ---------------- {t} ----------------')
        ins = [(r, n) for d, r, n in ports if d == 'input' and n not in ('clock', 'reset')]
        outs = [(r, n) for d, r, n in ports if d == 'output']
        for r, n in ins:
            L.append(f'  logic {r + " " if r else ""}{t}__{n};')
        for r, n in outs:
            L.append(f'  wire {r + " " if r else ""}{t}__{n}__g, {t}__{n}__x;')
        for suf, mod in (('g', t), ('x', t + '_xs')):
            L.append(f'  {mod} u_{t}_{suf} (')
            conns = ['    .clock(clk)', '    .reset(rst)']
            conns += [f'    .{n}({t}__{n})' for _, n in ins]
            conns += [f'    .{n}({t}__{n}__{suf})' for _, n in outs]
            L.append(',\n'.join(conns))
            L.append('  );')
        L.append(f'  int cov_{t}_conflict = 0, cov_{t}_starve = 0;')
        cov_names.append(t)
        # 驱动
        L.append('  always @(posedge clk) begin')
        for r, n in ins:
            if n.endswith('_valid'):
                L.append(f'    {t}__{n} <= ($urandom_range(0, 99) < pct);')
            else:
                L.append(f'    {t}__{n} <= $urandom;')
        L.append('  end')
        # 比对 + 覆盖
        L.append('  always @(negedge clk) if (cyc > 4) begin')
        for r, n in outs:
            L.append(f'    if ({t}__{n}__g !== {t}__{n}__x) begin errors++;'
                     f' if (errors <= 40) $display("[cyc %0d] {t}.{n} g=%h x=%h", cyc, {t}__{n}__g, {t}__{n}__x); end')
        rej = ' | '.join(f'({t}__{n[:-6]}_valid & ~{t}__{n}__g)' for _, n in outs if n.endswith('_ready'))
        L.append(f'    if ({rej}) cov_{t}_conflict++;')
        hf = ' | '.join(f'u_{t}_g.{nm}.hasFull' for (_, nm, _, _) in insts)
        L.append(f'    if ({hf}) cov_{t}_starve++;')
        L.append('  end')
        L.append('')
    L.append('  always @(negedge clk) if (cyc > 4) checks++;')
    L.append('  initial begin')
    L.append('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    L.append('    rst = 1; repeat (4) @(posedge clk); rst = 0;')
    L.append('    repeat (NCYCLES) begin')
    L.append('      @(posedge clk); cyc++;')
    L.append('      if (cyc % 1000 == 0) begin')
    L.append('        case ($urandom_range(0, 3)) 0: pct = 20; 1: pct = 50; 2: pct = 90; default: pct = 100; endcase')
    L.append('      end')
    L.append('      if ($urandom_range(0, 24999) == 0) begin #2 rst = 1; @(posedge clk); @(posedge clk); #2 rst = 0; end')
    L.append('    end')
    ok = []
    for t in cov_names:
        L.append(f'    $display("COV {t} conflict=%0d starve=%0d", cov_{t}_conflict, cov_{t}_starve);')
        # 全部仲裁器都是 N=1 的目标（VlRFWBCollideChecker）按构造不可能冲突：不设冲突下限，
        # 改为断言它确实 0 冲突（否则说明 tb 或模型错了）
        if all(len([p for p, _ in c if re.match(r'io_in_\d+_valid$', p)]) == 1 for (_, _, _, c) in parse_golden(t)[1]):
            ok.append(f'cov_{t}_conflict == 0')
        else:
            ok.append(f'cov_{t}_conflict > 100 && cov_{t}_starve > 100')
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000 && ' + ' && '.join(ok) + ')')
    L.append('      $display("TEST PASSED");')
    L.append('    else')
    L.append('      $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    drift = 0
    for top in TARGETS:
        path = OUT_DIR / f'{top}.sv'
        block, ni, nc, nw = gen_block(top)
        if not path.exists():
            die(f'{path} 不存在：手写文件头要先写好（本脚本只替换 GENERATED 区）')
        txt = path.read_text()
        if txt.count(BEGIN) != 1 or txt.count(END) != 1:
            die(f'{path}: GENERATED 标记必须各恰好一个')
        head, rest = txt.split(BEGIN, 1)
        _, tail = rest.split(END + '\n', 1)
        new = head + block + tail
        if new != txt:
            drift += 1
            if args.check:
                print(f'DRIFT {path.relative_to(REPO)}')
            else:
                path.write_text(new)
                print(f'wrote {path.relative_to(REPO)}')
        print(f'  {top}: {ni} 个 WBArbiter、{nc} 个常量 ready、省略无负载线网 {nw} 条')
    tb = gen_tb()
    if not TB_PATH.exists() or TB_PATH.read_text() != tb:
        drift += 1
        if args.check:
            print(f'DRIFT {TB_PATH.relative_to(REPO)}')
        else:
            TB_PATH.parent.mkdir(parents=True, exist_ok=True)
            TB_PATH.write_text(tb)
            print(f'wrote {TB_PATH.relative_to(REPO)}')
    if args.check and drift:
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
