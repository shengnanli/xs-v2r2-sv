#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_ctrlblock_ut.py —— CtrlBlock 双例化 UT 脚手架生成器（tb.sv + closure.mk）。

产出（可复跑、幂等，--check 是 gate_all 里的 UT 生成器幂等闸）：
  tb.sv       golden `CtrlBlock`（u_g）与重写 `CtrlBlock_xs`（u_i）同激励并跑：
              1559 个输入每拍 negedge 随机驱动（valid 类信号按 +valid_pct 概率），
              6729 个输出每拍 posedge 后逐端口比对；golden 侧为 X 的拍跳过（don't-care）。
              读 +ncycles（ut_common.mk 下发 200000）。
  closure.mk  golden 子模块闭包文件表（83 个模块，从 golden 现场按例化关系递归算出）：
              GOLDEN_CLOSURE_ALL / 被重写件替换的 7 个 / 其余 76 个（UT 两侧共用、FM 两侧同源）。

为什么不手写：端口表 8288 行、闭包 83 个文件，都是 golden 的机械函数；手抄漏一个文件
VCS 报的是 CFCILFBI 之类与 CtrlBlock 毫不相干的错（Rob UT 的教训）。
"""
import argparse
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
G1 = pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical') / 'golden-rtl'
TOP = 'CtrlBlock'
# impl 侧用 rtl/ 重写件替换的 child（golden 同名模块不进 impl 侧）
# （SnapshotGenerator_14 的重写件依赖 rtl/backend/SnapshotGenerator.sv 里的共享核，而那个文件同时定义
#   golden 同名的 SnapshotGenerator wrapper，会与本闭包里同源的 golden SnapshotGenerator.sv 撞名；
#   它在 FM 里本就是对称接口黑盒，UT/FM 的 impl 侧一律用 golden 体。）
REPLACED = ['Rob', 'SyncDataModuleTemplate_BackendPC_64entry', 'DelayN_15', 'DelayN_17',
            'PipelineConnectPipe', 'PipeGroupConnect']

INST_RE = re.compile(r'^  ([A-Za-z_][A-Za-z0-9_]*) ([A-Za-z_][A-Za-z0-9_]*) \($', re.M)


def closure():
    seen = []
    def rec(m):
        if m in seen:
            return
        seen.append(m)
        p = G1 / ('%s.sv' % m)
        if not p.exists():
            sys.exit('closure: 缺文件 %s' % p)
        for t, i in INST_RE.findall(p.read_text()):
            rec(t)
    for t, i in INST_RE.findall((G1 / ('%s.sv' % TOP)).read_text()):
        rec(t)
    return seen


def ports():
    t = (G1 / ('%s.sv' % TOP)).read_text()
    m = re.search(r'^module CtrlBlock\((.*?)\n\);', t, re.S | re.M)
    out = []
    for ln in m.group(1).split('\n'):
        pm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
        if pm:
            out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return out


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ps if d == 'output']
    L = ['// 自动生成：verif/ut/CtrlBlock/gen_ctrlblock_ut.py —— 勿手改（重生成后 --check 幂等）',
         '// CtrlBlock 双例化 UT：golden CtrlBlock (u_g) vs 重写 CtrlBlock_xs (u_i)，同激励逐拍比对全部输出。',
         '`timescale 1ns/1ps',
         'module tb;',
         '  int unsigned NCYCLES = 200000;',
         '  int unsigned VALID_PCT = 50;',
         '  bit clk = 0, rst;',
         '  int errors = 0, checks = 0, distinct_div = 0;',
         '  always #5 clk = ~clk;',
         '']
    def decl(w, n, pre=''):
        return '  logic %s%s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), pre, n)
    for w, n in ins:
        L.append(decl(w, n))
    for w, n in outs:
        L.append(decl(w, n, 'g_'))
        L.append(decl(w, n, 'i_'))
    L.append('')
    L.append('  // 随机激励：valid/en/wen 类信号按概率，其余全随机（宽信号按 32 位分段）')
    L.append('  function automatic logic pct(int p); return ($urandom_range(0, 99) < p); endfunction')
    L.append('  always @(negedge clk) begin')
    for w, n in ins:
        words = (w + 31) // 32
        if w == 1 and re.search(r'(_valid|_en|_wen|_ren|_fire|Valid|_stall|_enable)$', n):
            L.append('    %s = pct(VALID_PCT);' % n)
        elif w == 1:
            L.append('    %s = $urandom;' % n)
        else:
            L.append('    %s = {%s};' % (n, ', '.join(['$urandom'] * words)))
    L.append('  end')
    L.append('')
    for pre, mod in (('g_', 'CtrlBlock'), ('i_', 'CtrlBlock_xs')):
        L.append('  %s u_%s (' % (mod, pre[0]))
        conns = ['    .clock(clk)', '    .reset(rst)']
        for w, n in ins:
            conns.append('    .%s(%s)' % (n, n))
        for w, n in outs:
            conns.append('    .%s(%s%s)' % (n, pre, n))
        L.append(',\n'.join(conns))
        L.append('  );')
        L.append('')
    L.append('  // 逐端口比对：golden 为 X 的位置不判（don\'t-care），首次分叉的端口各报一次')
    L.append('  bit reported [%d];' % len(outs))
    L.append('  task automatic cmp(int idx, string name, logic [1023:0] g, logic [1023:0] i, int w);')
    L.append('    logic [1023:0] mask;')
    L.append('    mask = (1024\'h1 << w) - 1;')
    L.append('    checks++;')
    L.append('    if (!$isunknown(g & mask) && ((g & mask) !== (i & mask))) begin')
    L.append('      errors++;')
    L.append('      if (!reported[idx]) begin reported[idx] = 1; distinct_div++;')
    L.append('        if (distinct_div <= 40) $display("[MISMATCH %0t] %s g=%h i=%h", $time, name, g & mask, i & mask);')
    L.append('      end')
    L.append('    end')
    L.append('  endtask')
    L.append('  always @(posedge clk) if (!rst) begin #1;')
    for k, (w, n) in enumerate(outs):
        L.append('    cmp(%d, "%s", g_%s, i_%s, %d);' % (k, n, n, n, w))
    L.append('  end')
    L.append('')
    L.append('  initial begin')
    L.append('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    L.append('    if (!$value$plusargs("valid_pct=%d", VALID_PCT)) VALID_PCT = 50;')
    L.append('    rst = 1; repeat (16) @(posedge clk); rst = 0;')
    L.append('    repeat (NCYCLES) @(posedge clk);')
    L.append('    $display("distinct_diverging_ports=%%0d / %0d", distinct_div);' % len(outs))
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def gen_mk(cl):
    others = [m for m in cl if m not in REPLACED]
    L = ['# 自动生成：verif/ut/CtrlBlock/gen_ctrlblock_ut.py —— 勿手改。golden CtrlBlock 的子模块闭包（%d 个模块）。' % len(cl),
         '# GOLDEN_CLOSURE_REPLACED：impl 侧用 rtl/ 重写件替换的 child（只进 golden 侧）；',
         '# GOLDEN_CLOSURE_SHARED：其余 child，UT 两侧共用同一份定义，FM 两侧同源 elaborate（UNCHANGED_GOLDEN_DEP）。',
         'GOLDEN_CLOSURE_REPLACED = ' + ' '.join('%s.sv' % m for m in cl if m in REPLACED),
         'GOLDEN_CLOSURE_SHARED = \\']
    L += ['  %s.sv \\' % m for m in others[:-1]] + ['  %s.sv' % others[-1]]
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    cl = closure()
    if len(cl) != 83:
        sys.exit('closure: 模块数 %d != 83（golden 变了？）' % len(cl))
    outs = {'tb.sv': gen_tb(ports()), 'closure.mk': gen_mk(cl)}
    rc = 0
    for name, txt in outs.items():
        p = HERE / name
        if a.check:
            if not p.exists() or p.read_text() != txt:
                print('gen_ctrlblock_ut --check: %s 漂移' % name)
                rc = 1
        elif not p.exists() or p.read_text() != txt:
            p.write_text(txt)
            print('gen_ctrlblock_ut: 写入 %s' % name)
    if a.check and rc == 0:
        print('gen_ctrlblock_ut --check: OK')
    return rc


if __name__ == '__main__':
    sys.exit(main())
