#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_fastarbiter_28.py —— 生成 FastArbiter_28（L2 PCredit 授予仲裁，80 路、无载荷、恒 ready）的薄 wrapper + UT tb。

家族规矩（CONVENTIONS「变体家族」）：一个参数化核 + 每变体一个薄文件，核体绝不复制。
  核   = rtl/common/xs_FastArbiter_core.sv（手写，utility.FastArbiter；本脚本不碰）
  薄壳 = rtl/uncore/FastArbiter_28.sv（本脚本生成）
  tb   = verif/ut/FastArbiter_28/tb.sv（本脚本生成）

为什么不并进 gen_fastarbiter_l2.py：FastArbiter_28 的端口面与那 5 个变体不同 ——
  · 载荷是 EmptyBundle（0 位），golden 没有任何 io_in_*_bits / io_out_bits 端口；
  · 例化者把 out.ready 恒接 true.B，firtool 把 io_out_ready 端口折掉了，
    于是 golden 的 io_in_k_ready 直接等于 chosenOH[k]、掩码更新条件退化成 |valids。
  那边的解析器对这两点都是 fail-closed 报错（它要求有 io_out_ready），
  改它会让 FastArbiter_3..7 的生成物与 UT tb 一起变动；单开一个脚本不影响已签目标。

★本脚本对上面两点做 fail-closed 核对★（解析 golden 原文，不符即报错退出）：
  (a) 端口表只有 clock / reset / io_in_<k>_{ready,valid}（k=0..N-1 连续）/ io_out_valid；
  (b) 每个 `assign io_in_<k>_ready = chosenOH[<k>];`（= out.ready 恒 1 时的 chosenOH & ready）；
  (c) 掩码更新条件字面为 `else if (|valids)`（= out.fire 在 ready 恒 1 下的形状）；
  (d) `assign io_out_valid = |valids;`。

用法:
  python3 scripts/gen_fastarbiter_28.py          # 幂等写入（内容不变不碰文件）
  python3 scripts/gen_fastarbiter_28.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))
NAME = 'FastArbiter_28'
UT_DIR = REPO / 'verif' / 'ut' / NAME


class Golden:
    def __init__(self):
        self.src = (GOLDEN / (NAME + '.sv')).read_text()
        m = re.search(r'^module %s\(\n(.*?)\n\);\n' % NAME, self.src, re.S | re.M)
        if not m:
            raise SystemExit('golden %s.sv 里找不到 module 端口表' % NAME)
        self.port_text = m.group(1)
        self.ports = []
        for ln in self.port_text.split('\n'):
            mm = re.match(r'\s*(input|output)\s+(\w+),?\s*$', ln)
            if not mm:
                raise SystemExit('%s: 解析不了端口行（本变体应全为 1 位端口）%r' % (NAME, ln))
            self.ports.append((mm.group(1), mm.group(2)))
        names = [p for _, p in self.ports]
        ks = sorted(int(re.match(r'io_in_(\d+)_valid$', p).group(1))
                    for p in names if re.match(r'io_in_(\d+)_valid$', p))
        self.n = len(ks)
        if ks != list(range(self.n)) or self.n < 2:
            raise SystemExit('%s: io_in_k_valid 下标不连续 %s' % (NAME, ks))
        want = ['clock', 'reset']
        for k in range(self.n):
            want += ['io_in_%d_ready' % k, 'io_in_%d_valid' % k]
        want += ['io_out_valid']
        if names != want:
            extra = sorted(set(names) - set(want))
            miss = sorted(set(want) - set(names))
            raise SystemExit('%s: 端口面不是"无载荷、恒 ready"的形状（多 %s / 缺 %s / 或顺序不同）'
                             % (NAME, extra, miss))
        dirs = dict((p, d) for d, p in self.ports)
        for k in range(self.n):
            if dirs['io_in_%d_ready' % k] != 'output' or dirs['io_in_%d_valid' % k] != 'input':
                raise SystemExit('%s: io_in_%d 方向不对' % (NAME, k))
        # (b) ready = chosenOH[k]
        for k in range(self.n):
            if not re.search(r'^\s*assign io_in_%d_ready = chosenOH\[%d\];$' % (k, k),
                             self.src, re.M):
                raise SystemExit('%s: 找不到 `assign io_in_%d_ready = chosenOH[%d];` —— '
                                 'out.ready 可能不是恒 1' % (NAME, k, k))
        # (c) 更新条件
        if len(re.findall(r'^\s*else if \(\|valids\) begin$', self.src, re.M)) != 1:
            raise SystemExit('%s: 掩码更新条件不是 `else if (|valids)`' % NAME)
        # (d)
        if not re.search(r'^\s*assign io_out_valid = \|valids;$', self.src, re.M):
            raise SystemExit('%s: 找不到 `assign io_out_valid = |valids;`' % NAME)


def concat(items, indent):
    """{a, b, c} 按行宽折行；items 按给定顺序（调用方负责高位在前）。"""
    lines, cur = [], ''
    for p in items:
        cand = (cur + ', ' + p) if cur else p
        if cur and len(cand) + indent + 2 > 96:
            lines.append(cur + ',')
            cur = p
        else:
            cur = cand
    lines.append(cur)
    return '{' + ('\n' + ' ' * (indent + 1)).join(lines) + '}'


def wrapper(g):
    n = g.n
    L = []
    A = L.append
    A('// =============================================================================')
    A('// %s.sv —— FastArbiter 家族薄 wrapper：L2 PCredit 授予仲裁（%d 路，无载荷，出口恒 ready）' % (NAME, n))
    A('//')
    A('// 例化者：TL2CHICoupledL2.sv（实例 pcrdgrant_arb；Scala coupledL2/tl2chi/TL2CHICoupledL2.scala')
    A('//   `fastArb(mshrPCrdArbIn, mshrPCrdArbOut, Some("pcrdgrant"))`）。')
    A('// 语义：CHI 下游回来一个 PCrdGrant（重试许可）进 pCrdQueue_s3 队头后，MMIOBridge 与')
    A('//   各 slice 的全部 MSHR（共 %d 个）里凡是"在等这种许可、且 pCrdType/srcID 对得上"的，' % n)
    A('//   都拉起自己那一路 valid；本仲裁器从中挑一个，把 ready 当作"授予"回给它。')
    A('//')
    A('// 与 FastArbiter_3..7 的两处端口面差别（golden 端口表实测，生成器 fail-closed 核对）：')
    A('//   · 载荷是 EmptyBundle（0 位）：golden 没有任何 bits 端口。核的 W 不能为 0，')
    A('//     这里给 W=1、每路喂常 0、out_bits 悬空 —— 这一位不进任何寄存器、不到任何输出。')
    A('//   · 例化者写死 out.ready := true.B，firtool 折掉了 io_out_ready 端口：')
    A('//     golden 里 io_in_k_ready = chosenOH[k]、掩码在 |valids 时就更新。')
    A('//     这里把核的 out_ready 接 1\'b1，得到的正是同一形状。')
    A('//')
    A('// 本文件只做端口对位；仲裁逻辑（轮转 + 挂起记忆）在 rtl/common/xs_FastArbiter_core.sv。')
    A('// 本文件由 scripts/gen_fastarbiter_28.py 生成，勿手改。')
    A('// golden 对照：G1-canonical/golden-rtl/%s.sv' % NAME)
    A('// =============================================================================')
    A('module %s (' % NAME)
    A(g.port_text)
    A(');')
    A('  localparam int N = %d;' % n)
    A('')
    A('  // ---- 打包：%d 路 valid 拼成向量（第 k 路在第 k 位）' % n)
    A('  logic [N-1:0] in_valid;')
    A('  logic [N-1:0] in_ready;')
    A('  assign in_valid = %s;' % concat(['io_in_%d_valid' % k for k in reversed(range(n))], 20))
    A('')
    A('  // ---- 核例化：W=1 的占位载荷恒 0、out_bits 不接；out_ready 恒 1')
    A('  xs_FastArbiter_core #(.N(N), .W(1)) u_core (')
    A('    .clock     (clock),')
    A('    .reset     (reset),')
    A('    .in_valid  (in_valid),')
    A("    .in_bits   ('0),")
    A('    .in_ready  (in_ready),')
    A("    .out_ready (1'b1),")
    A('    .out_valid (io_out_valid),')
    A('    .out_bits  ()')
    A('  );')
    A('')
    A('  // ---- 拆包：第 k 路的授予 = in_ready[k]')
    for k in range(n):
        A('  assign io_in_%d_ready = in_ready[%d];' % (k, k))
    A('endmodule')
    return '\n'.join(L) + '\n'


def tb(g):
    n = g.n
    L = []
    A = L.append
    A('// =============================================================================')
    A('// tb —— %s UT：golden 与重写件 %s_xs 双例化，同激励逐拍比全部输出。' % (NAME, NAME))
    A('//')
    A('// 比对：io_out_valid + %d 路 io_in_k_ready。' % n)
    A('// 覆盖判据（写进 TEST PASSED，不全即判失败），探 golden 自己的内部线：')
    A('//   · 每一路 k 都在"轮转命中"（rrSelOH&valids 非 0）时赢过一次（第 0 路按构造不可能）；')
    A('//   · 每一路 k 都在"固定优先级兜底"时赢过一次；')
    A('//   · out_valid 取过 0/1；每路 ready 取过 0/1。')
    A('// 激励：valid 全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 均匀随机 / "只留某一窗口" 轮换；')
    A('// 约 1/5000 的单拍异步复位脉冲。')
    A('// 为什么要"窗口"模式：兜底赢要求比 k 低的路全不 valid，均匀随机下高位几乎等不到。')
    A('//')
    A('// 本文件由 scripts/gen_fastarbiter_28.py 生成，勿手改。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  localparam int N = %d;' % n)
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clk = 0; always #5 clk = ~clk;')
    A('  longint errors = 0, checks = 0;')
    A('')
    A('  logic         rst;')
    A('  logic [N-1:0] vld;')
    A('  logic         g_ov, i_ov;')
    A('  logic [N-1:0] g_rdy, i_rdy;')
    A('')
    for side, mod in (('g', NAME), ('i', NAME + '_xs')):
        A('  %s u_%s (' % (mod, side))
        conns = ['    .clock (clk)', '    .reset (rst)']
        for k in range(n):
            conns.append('    .io_in_%d_ready (%s_rdy[%d])' % (k, side, k))
            conns.append('    .io_in_%d_valid (vld[%d])' % (k, k))
        conns.append('    .io_out_valid (%s_ov)' % side)
        A(',\n'.join(conns))
        A('  );')
    A('')
    A('  logic [N-1:0] cov_rr, cov_first, cov_rdy0, cov_rdy1;')
    A('  logic [1:0]   cov_ov;')
    A('')
    A('  task automatic check();')
    A('    checks++;')
    A('    if (g_ov !== i_ov) begin')
    A('      errors++;')
    A('      if (errors <= 40) $display("[%0t] MISMATCH out_valid golden=%b impl=%b", $time, g_ov, i_ov);')
    A('    end')
    A('    checks++;')
    A('    if (g_rdy !== i_rdy) begin')
    A('      errors++;')
    A('      if (errors <= 40) $display("[%0t] MISMATCH in_ready golden=%h impl=%h", $time, g_rdy, i_rdy);')
    A('    end')
    A("    cov_ov[g_ov] = 1'b1;")
    A('    for (int k = 0; k < N; k++) begin')
    A("      if (g_rdy[k]) cov_rdy1[k] = 1'b1; else cov_rdy0[k] = 1'b1;")
    A('      if (u_g.chosenOH[k]) begin')
    A("        if (|(u_g.rrSelOH & u_g.valids)) cov_rr[k] = 1'b1;")
    A("        else cov_first[k] = 1'b1;")
    A('      end')
    A('    end')
    A('  endtask')
    A('')
    A('  task automatic drive();')
    A('    int lo, hi;')
    A('    for (int b = 0; b < N; b += 32) vld[b +: 32] = $urandom;')
    A('    case ($urandom_range(0, 7))')
    A("      0: vld = '0;")
    A("      1: vld = '1;")
    A("      2: vld = {{(N-1){1'b0}}, 1'b1} << $urandom_range(0, N-1);")
    A('      3: for (int b = 0; b < N; b += 32) vld[b +: 32] = $urandom & $urandom & $urandom;  // 稀疏')
    A('      4: for (int b = 0; b < N; b += 32) vld[b +: 32] = $urandom | $urandom;             // 稠密')
    A('      5, 6: begin                                  // 只留 [lo,hi] 窗口（其余清零）')
    A('        lo = $urandom_range(0, N-1);')
    A('        hi = $urandom_range(lo, N-1);')
    A("        for (int k = 0; k < N; k++) if (k < lo || k > hi) vld[k] = 1'b0;")
    A('      end')
    A('      default: ;                                   // 均匀随机')
    A('    endcase')
    A("    rst = ($urandom_range(0, 4999) == 0);  // 单拍异步复位脉冲")
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A("    cov_rr = '0; cov_first = '0; cov_rdy0 = '0; cov_rdy1 = '0; cov_ov = '0;")
    A("    rst = 1'b1; vld = '0;")
    A('    repeat (8) @(posedge clk);')
    A("    #1; drive(); rst = 1'b0;")
    A('    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end')
    A('    report();')
    A('    $finish;')
    A('  end')
    A('')
    A('  task automatic report();')
    A('    int bad = 0, nrr = 0, nfi = 0, nr0 = 0, nr1 = 0;')
    A('    for (int k = 0; k < N; k++) begin')
    A('      nrr += cov_rr[k]; nfi += cov_first[k]; nr0 += cov_rdy0[k]; nr1 += cov_rdy1[k];')
    A('    end')
    A("    if (nfi != N || nr0 != N || nr1 != N || cov_ov != 2'b11) bad++;")
    A('    // 第 0 路永远不可能"轮转命中"（rrGrantMask[0] 恒 0），其余各路必须都命中过')
    A('    if (nrr != N - 1 || cov_rr[0]) bad++;')
    A('    $display("--- coverage: rr %0d/%0d  first %0d/%0d  rdy0 %0d rdy1 %0d  ov=%b",')
    A('             nrr, N-1, nfi, N, nr0, nr1, cov_ov);')
    A('    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);')
    A('    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");')
    A('    else $display("TEST FAILED");')
    A('  endtask')
    A('endmodule')
    return '\n'.join(L) + '\n'


def outputs():
    g = Golden()
    return {
        REPO / 'rtl' / 'uncore' / (NAME + '.sv'): wrapper(g),
        UT_DIR / 'tb.sv': tb(g),
    }


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
            print('gen_fastarbiter_28: DRIFT %s' % rel)
            return 1
        print('gen_fastarbiter_28: OK（%d 个文件与生成结果一致）' % len(out))
        return 0
    print('gen_fastarbiter_28: 更新 %s' % rel if drift else 'gen_fastarbiter_28: 全部已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
