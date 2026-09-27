#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— 生成 MEFreeList 的双例化逐拍比对 tb.sv。

激励协议与 verif/ut/StdFreeList/tb.sv 同一口径(含 8 拍快照暖机窗口)，差别只在：
  * commit 侧字段是 rfWen + isMove(archHeadPtr 只按 rfWen & ~isMove 推进)；
  * 多了 32 个 io_debug_rat_N 输入(喂 debug 影子寄存器，综合口径下是死位)；
  * 回收物理号域是整数池 [0, 223]；
  * 探针多比 tailPtr(MEFreeList 没有 lastTailPtr)与 debug 影子寄存器
    (它们不是输出，UT 唯一能看见它们的地方就是层次探针)。
端口表从 G1 golden 读，生成时核对 io_debug_rat_0..31 齐全。

用法: python3 gen_tb.py [--check]
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
MOD = 'MEFreeList'
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')


def width(rng):
    if not rng:
        return 1
    m = re.fullmatch(r'\[(\d+):0\]', rng)
    if not m:
        raise SystemExit('不认识的位宽写法: %r' % rng)
    return int(m.group(1)) + 1


def ports():
    text = (GOLDEN / (MOD + '.sv')).read_text()
    m = re.search(r'^module %s\((.*?)\n\);' % MOD, text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if pm:
            res.append((pm.group(1), width(pm.group(2)), pm.group(3)))
    names = {n for _, _, n in res}
    for k in range(32):
        if 'io_debug_rat_%d' % k not in names:
            raise SystemExit('golden MEFreeList 缺 io_debug_rat_%d' % k)
    return res


def make_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ps if d == 'output']
    L = []
    A = L.append
    A('// ★本文件由 gen_tb.py 生成，改请改生成器★')
    A('// MEFreeList(整数 move-elimination 空闲列表)双例化逐拍比对。')
    A('// 快照暖机窗口(WARM_CYCLES)的理由见 verif/ut/StdFreeList/tb.sv 文件头：')
    A('//   快照槽 payload 寄存器不复位，+vcs+initreg+random 下两侧初值各异，先把 4 槽写满再随机读。')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clk = 0, rst;')
    A('  int errors = 0, checks = 0;')
    A('  localparam int WARM_CYCLES = 8;')
    A('  int cyc = 0;')
    A('  always @(negedge clk) if (!rst) cyc <= cyc + 1;')
    A('  always #5 clk = ~clk;')
    A('')
    for w, n in ins:
        A('  logic %s%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', n))
    for w, n in outs:
        for p in ('g', 'i'):
            A('  logic %s%s_%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', p, n))

    def inst(m, p):
        c = ['.clock(clk)', '.reset(rst)']
        c += ['.%s(%s)' % (n, n) for _, n in ins]
        c += ['.%s(%s_%s)' % (n, p, n) for _, n in outs]
        return '  %s %s_u (%s);' % (m, p, ', '.join(c))
    A(inst(MOD, 'g'))
    A(inst(MOD + '_xs', 'i'))
    A('')
    A('  // 回收的物理号取整数池全域 [0, 223]')
    A("  function automatic logic [7:0] rnd_preg(); return 8'($urandom_range(0,223)); endfunction")
    A('  always @(negedge clk) begin')
    A('    if (rst) begin')
    for w, n in ins:
        A('      %s <= 0;' % n)
    A('    end else begin')
    A("      io_redirect <= (cyc < WARM_CYCLES) ? 1'b0 : ($urandom_range(0,99) < 3);")
    A('      io_walk     <= ($urandom_range(0,99) < 25);')
    A('      io_doAllocate <= $urandom_range(0,1);')
    for k in range(6):
        A('      io_allocateReq_%d <= $urandom_range(0,1);' % k)
        A('      io_walkReq_%d <= $urandom_range(0,1);' % k)
        A('      io_freeReq_%d <= ($urandom_range(0,99)<30);' % k)
        A('      io_freePhyReg_%d <= rnd_preg();' % k)
        A('      io_commit_commitValid_%d <= $urandom_range(0,1);' % k)
        A('      io_commit_info_%d_rfWen <= $urandom_range(0,1);' % k)
        A('      io_commit_info_%d_isMove <= ($urandom_range(0,99)<30);' % k)
    A('      io_commit_isCommit <= $urandom_range(0,1);')
    for k in range(32):
        A('      io_debug_rat_%d <= rnd_preg();' % k)
    A('      if (cyc < WARM_CYCLES) begin')
    A("        io_snpt_snptEnq <= 1'b1; io_snpt_snptDeq <= 1'b0;")
    A("        io_snpt_useSnpt <= 1'b0; io_snpt_snptSelect <= 2'd0;")
    A('      end else begin')
    A('        io_snpt_snptEnq <= ($urandom_range(0,99)<15); io_snpt_snptDeq <= ($urandom_range(0,99)<15);')
    A('        io_snpt_useSnpt <= $urandom_range(0,1); io_snpt_snptSelect <= $urandom_range(0,3);')
    A('      end')
    for k in range(4):
        A('      io_snpt_flushVec_%d <= ($urandom_range(0,99)<5);' % k)
    A('    end')
    A('  end')
    A('')
    A('  always @(negedge clk) if (!rst) begin')
    A('    #4; checks++;')
    for w, n in outs:
        A('    if (!$isunknown(g_%s) && g_%s !== i_%s) begin errors++;' % (n, n, n))
        A('      if(errors<=80) $display("[%%0t] %s g=%%h i=%%h", $time, g_%s, i_%s); end' % (n, n, n))
    A('    // 内部指针探针：golden 展平名 vs 核里的 struct(golden 的 shiftAmount 就是 headPtr.value)')
    for gf, gv, iname in (('headPtr_flag', 'shiftAmount', 'headPtr'),
                          ('archHeadPtr_flag', 'archHeadPtr_value', 'archHeadPtr'),
                          ('tailPtr_flag', 'tailPtr_value', 'tailPtr')):
        A('    if (!$isunknown(g_u.%s)) begin' % gf)
        A('      if (g_u.%s !== i_u.u_core.%s.flag) begin errors++;' % (gf, iname))
        A('        if(errors<=80) $display("[%%0t] %s.flag g=%%h i=%%h", $time, g_u.%s, i_u.u_core.%s.flag); end' % (iname, gf, iname))
        A('      if (g_u.%s !== i_u.u_core.%s.value) begin errors++;' % (gv, iname))
        A('        if(errors<=80) $display("[%%0t] %s.value g=%%h i=%%h", $time, g_u.%s, i_u.u_core.%s.value); end' % (iname, gv, iname))
        A('    end')
    A('    // debug 影子 head 指针(死位，核里为对齐 golden 展平名拆成 _flag/_value 标量)')
    for nm in ('debugArchHeadPtr_flag', 'debugArchHeadPtr_value'):
        A('    if (!$isunknown(g_u.%s) && g_u.%s !== i_u.u_core.%s) begin errors++;' % (nm, nm, nm))
        A('      if(errors<=80) $display("[%%0t] %s g=%%h i=%%h", $time, g_u.%s, i_u.u_core.%s); end' % (nm, nm, nm))
    A('    // debug 影子 RAT(死位，只有探针能看见)：32 项逐拍比')
    for k in range(32):
        A('    if (!$isunknown(g_u.debugArchRAT_%d) && g_u.debugArchRAT_%d !== i_u.u_core.debugArchRAT[%d]) begin errors++;' % (k, k, k))
        A('      if(errors<=80) $display("[%%0t] debugArchRAT_%d g=%%h i=%%h", $time, g_u.debugArchRAT_%d, i_u.u_core.debugArchRAT[%d]); end' % (k, k, k))
    A('  end')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    rst = 1; repeat (8) @(posedge clk); rst = 0;')
    A('    repeat (NCYCLES) @(posedge clk);')
    A('    $display("checks=%0d errors=%0d", checks, errors);')
    A('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main(argv):
    content = make_tb(ports())
    out = HERE / 'tb.sv'
    if '--check' in argv:
        if not out.exists() or out.read_text() != content:
            print('gen_tb --check: tb.sv 与生成器不一致(手改了？改生成器并重跑)')
            return 1
        print('gen_tb --check: tb.sv 与生成器一致')
        return 0
    out.write_text(content)
    print('生成', out.relative_to(REPO))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
