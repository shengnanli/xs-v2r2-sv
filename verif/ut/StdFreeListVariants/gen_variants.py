#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_variants.py —— 生成 StdFreeList 家族 3 个参数变体的薄 wrapper + 本目录的 tb.sv。

★为什么机械生成★ StdFreeList_1/_2/_3 与基线 StdFreeList 是 Scala 同一个 class 用不同
参数例化出来的(Rename.scala 的 fpFreeList/vecFreeList/v0FreeList/vlFreeList)。
它们的 wrapper 里没有一行设计决策：端口表与基线只差 `io_commit_info_N_<Wen>` 的字段名，
逻辑全在参数化共核 xs_StdFreeList_core(rtl/backend/StdFreeList.sv)里。所以 wrapper 从
**G1 golden 的端口表**生成，并在生成时做四项机械核对(任何一项不符就拒绝生成)：

  1. 端口集合：把 golden 端口名里的 `_<Wen>` 归一成 `_regWen` 后，必须与基线 StdFreeList
     的端口集合(含方向、位宽)逐项相同——这是"共核撑得住"的前提；
  2. 参数：SIZE 从 golden 的回绕常量 `_tailPtr_diff_T_4 = N'(... - N'hSIZE)` 读出，
     NUM_LOGIC_REGS 从复位臂 `freeList_0 <= 8'hNUM_LOGIC` 读出，必须等于
     stdfreelist_pkg 里登记的 {VEC,V0,VL}_{SIZE,NUM_LOGIC}(两处独立来源互证)；
  3. 池容量：golden 里 `freeList_<k>` 的最大下标 + 1 必须等于 SIZE；
  4. 指针宽：golden `reg [W-1:0] archHeadPtr_value` 的 W 必须等于 $clog2(SIZE)。

用法: python3 gen_variants.py           生成 rtl/backend/StdFreeList_{1,2,3}.sv + tb.sv
      python3 gen_variants.py --check   只核对，产物与当前文件逐字节不同则非零退出
      (Makefile 的 gencheck 目标调用后者；改了本文件要手动重跑并提交产物)
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = REPO / 'rtl' / 'backend'
PKG = REPO / 'rtl' / 'backend' / 'StdFreeList.sv'

# 变体表：(golden 顶层, commit 侧 Wen 字段名, 包里参数名前缀, 一句话说明)
# 数字**不写在这里**：SIZE/NUM_LOGIC 现场从 golden 与 stdfreelist_pkg 两处读出并互证。
VARIANTS = [
    ('StdFreeList_1', 'vecWen', 'VEC', '向量寄存器 Reg_V(VfPhyRegs-VecLogicRegs)'),
    ('StdFreeList_2', 'v0Wen',  'V0',  'v0 掩码寄存器 Reg_V0(V0PhyRegs-V0LogicRegs)'),
    ('StdFreeList_3', 'vlWen',  'VL',  'vl 寄存器 Reg_Vl(VlPhyRegs-VlLogicRegs)'),
]
BASE = 'StdFreeList'
BASE_WEN = 'fpWen'
COMMIT_WIDTH = 6

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')


def die(msg):
    raise SystemExit('gen_variants: ★拒绝生成★ ' + msg)


def width(rng):
    if not rng:
        return 1
    m = re.fullmatch(r'\[(\d+):0\]', rng)
    if not m:
        die('不认识的位宽写法: %r' % rng)
    return int(m.group(1)) + 1


def ports(mod):
    text = (GOLDEN / (mod + '.sv')).read_text()
    m = re.search(r'^module %s\((.*?)\n\);' % re.escape(mod), text, re.S | re.M)
    if not m:
        die('golden %s 没有找到 module 头' % mod)
    res = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if pm:
            res.append((pm.group(1), width(pm.group(2)), pm.group(3)))
    return res, text


def golden_params(mod, text):
    m = re.search(r"_tailPtr_diff_T_4 = \d+'\(\{1'h0, tailPtr_new_value\} - \d+'h([0-9A-Fa-f]+)\)", text)
    if not m:
        die('%s: 找不到回绕常量 _tailPtr_diff_T_4' % mod)
    size = int(m.group(1), 16)
    m = re.search(r"^\s+freeList_0 <= 8'h([0-9A-Fa-f]+);", text, re.M)
    if not m:
        die('%s: 找不到复位臂 freeList_0 <= 8\'hXX' % mod)
    num_logic = int(m.group(1), 16)
    idx = [int(x) for x in re.findall(r'\bfreeList_(\d+)\b', text)]
    if max(idx) + 1 != size:
        die('%s: freeList_<k> 最大下标+1 = %d，与回绕常量 SIZE=%d 不符' % (mod, max(idx) + 1, size))
    m = re.search(r'^\s+reg\s+\[(\d+):0\]\s+archHeadPtr_value;', text, re.M)
    if not m:
        die('%s: 找不到 reg archHeadPtr_value' % mod)
    ptr_w = int(m.group(1)) + 1
    if ptr_w != (size - 1).bit_length():
        die('%s: 指针宽 %d != $clog2(%d)' % (mod, ptr_w, size))
    return size, num_logic


def pkg_params(prefix):
    text = PKG.read_text()
    m = re.search(r'localparam int %s_SIZE\s*=\s*(\d+),\s*%s_NUM_LOGIC\s*=\s*(\d+);' % (prefix, prefix), text)
    if not m:
        die('stdfreelist_pkg 里没有 %s_SIZE / %s_NUM_LOGIC' % (prefix, prefix))
    return int(m.group(1)), int(m.group(2))


def normalized(ps, wen):
    return sorted((d, w, re.sub(r'_%s$' % wen, '_regWen', n)) for d, w, n in ps)


def make_wrapper(mod, wen, prefix, blurb, ps, size, num_logic):
    L = []
    A = L.append
    A('// =============================================================================')
    A('// %s —— StdFreeList 家族参数变体：%s' % (mod, blurb))
    A('// 本文件只做参数化与端口展平；核体见 rtl/backend/StdFreeList.sv(xs_StdFreeList_core，')
    A('//   含家族 4 个变体的参数表与机制说明)。')
    A('// golden 对照：G1-canonical/golden-rtl/%s.sv —— SIZE=%d(回绕常量)、' % (mod, size))
    A('//   NUM_LOGIC_REGS=%d(复位初值基数)、commit 侧看 %s；控制逻辑与基线变体逐字相同。' % (num_logic, wen))
    A('// ★本文件由 verif/ut/StdFreeListVariants/gen_variants.py 生成，改请改生成器★')
    A('// =============================================================================')
    A('module %s(' % mod)
    decls = []
    for d, w, n in ps:
        ws = ('[%d:0] ' % (w - 1)) if w > 1 else '      '
        decls.append('  %s %s%s' % ('input ' if d == 'input' else 'output', ws, n))
    A(',\n'.join(decls))
    A(');')
    A('  import stdfreelist_pkg::*;')
    A('')
    A('  logic [5:0] io_allocateReq;')
    A('  logic [5:0] io_walkReq;')
    A('  logic [7:0] allocatePhyReg [6];')
    A('  logic [5:0] io_freeReq;')
    A('  logic [7:0] freePhyReg [6];')
    A('  logic [5:0] io_commit_commitValid;')
    A('  logic [5:0] io_commit_info_regWen;')
    A('  logic [3:0] io_snpt_flushVec;')
    A('  logic [5:0] perf_value [4];')
    A('')
    A('  assign io_allocateReq = {io_allocateReq_5, io_allocateReq_4, io_allocateReq_3,')
    A('                           io_allocateReq_2, io_allocateReq_1, io_allocateReq_0};')
    A('  assign io_walkReq     = {io_walkReq_5, io_walkReq_4, io_walkReq_3,')
    A('                           io_walkReq_2, io_walkReq_1, io_walkReq_0};')
    A('  assign io_freeReq     = {io_freeReq_5, io_freeReq_4, io_freeReq_3,')
    A('                           io_freeReq_2, io_freeReq_1, io_freeReq_0};')
    A("  assign freePhyReg     = '{io_freePhyReg_0, io_freePhyReg_1, io_freePhyReg_2,")
    A('                            io_freePhyReg_3, io_freePhyReg_4, io_freePhyReg_5};')
    A('  assign io_commit_commitValid = {io_commit_commitValid_5, io_commit_commitValid_4,')
    A('                                  io_commit_commitValid_3, io_commit_commitValid_2,')
    A('                                  io_commit_commitValid_1, io_commit_commitValid_0};')
    A('  assign io_commit_info_regWen = {%s};' % ', '.join(
        'io_commit_info_%d_%s' % (k, wen) for k in range(COMMIT_WIDTH - 1, -1, -1)))
    A('  assign io_snpt_flushVec = {io_snpt_flushVec_3, io_snpt_flushVec_2,')
    A('                             io_snpt_flushVec_1, io_snpt_flushVec_0};')
    A('')
    for k in range(6):
        A('  assign io_allocatePhyReg_%d = allocatePhyReg[%d];' % (k, k))
    for k in range(4):
        A('  assign io_perf_%d_value = perf_value[%d];' % (k, k))
    A('')
    A('  xs_StdFreeList_core #(.SIZE(%s_SIZE), .NUM_LOGIC_REGS(%s_NUM_LOGIC)) u_core (' % (prefix, prefix))
    A('    .clock(clock),')
    A('    .reset(reset),')
    A('    .io_redirect(io_redirect),')
    A('    .io_walk(io_walk),')
    A('    .io_allocateReq(io_allocateReq),')
    A('    .io_walkReq(io_walkReq),')
    A('    .io_allocatePhyReg(allocatePhyReg),')
    A('    .io_canAllocate(io_canAllocate),')
    A('    .io_doAllocate(io_doAllocate),')
    A('    .io_freeReq(io_freeReq),')
    A('    .io_freePhyReg(freePhyReg),')
    A('    .io_commit_isCommit(io_commit_isCommit),')
    A('    .io_commit_commitValid(io_commit_commitValid),')
    A('    .io_commit_info_regWen(io_commit_info_regWen),')
    A('    .io_snpt_snptEnq(io_snpt_snptEnq),')
    A('    .io_snpt_snptDeq(io_snpt_snptDeq),')
    A('    .io_snpt_useSnpt(io_snpt_useSnpt),')
    A('    .io_snpt_snptSelect(io_snpt_snptSelect),')
    A('    .io_snpt_flushVec(io_snpt_flushVec),')
    A('    .io_perf_value(perf_value)')
    A('  );')
    A('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# tb：三个变体各一对(golden / _xs)例化，各自独立随机激励，逐拍比对全部输出 + 三个指针探针。
# 激励协议与 verif/ut/StdFreeList/tb.sv 同一口径(含 8 拍快照暖机窗口——理由见那里)。
# ---------------------------------------------------------------------------
def make_tb(specs):
    L = []
    A = L.append
    A('// ★本文件由 gen_variants.py 生成，改请改生成器★')
    A('// StdFreeList_1/_2/_3 三个参数变体的双例化逐拍比对；每个变体一套独立随机激励。')
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
    for tag, mod, wen, ps, size, num_logic in specs:
        ins = [(w, n) for d, w, n in ps if d == 'input' and n not in ('clock', 'reset')]
        outs = [(w, n) for d, w, n in ps if d == 'output']
        A('  // ================= %s (SIZE=%d, NUM_LOGIC=%d, Wen=%s) =================' % (mod, size, num_logic, wen))
        for w, n in ins:
            A('  logic %s%s_%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', tag, n))
        for w, n in outs:
            for p in ('g', 'i'):
                A('  logic %s%s_%s_%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', tag, p, n))

        def inst(m, p):
            c = ['.clock(clk)', '.reset(rst)']
            c += ['.%s(%s_%s)' % (n, tag, n) for _, n in ins]
            c += ['.%s(%s_%s_%s)' % (n, tag, p, n) for _, n in outs]
            return '  %s %s_%s (%s);' % (m, tag, p, ', '.join(c))
        A(inst(mod, 'g'))
        A(inst(mod + '_xs', 'i'))
        A('')
        # 激励
        lo, hi = num_logic, num_logic + size - 1
        A('  // 回收的物理号取本变体池的合法域 [%d, %d]' % (lo, hi))
        A("  function automatic logic [7:0] %s_rnd_preg(); return 8'(%d + $urandom_range(0,%d)); endfunction" % (tag, lo, size - 1))
        A('  always @(negedge clk) begin')
        A('    if (rst) begin')
        for w, n in ins:
            A('      %s_%s <= 0;' % (tag, n))
        A('    end else begin')
        A("      %s_io_redirect <= (cyc < WARM_CYCLES) ? 1'b0 : ($urandom_range(0,99) < 3);" % tag)
        A('      %s_io_walk     <= ($urandom_range(0,99) < 25);' % tag)
        A('      %s_io_doAllocate <= $urandom_range(0,1);' % tag)
        for k in range(6):
            A('      %s_io_allocateReq_%d <= $urandom_range(0,1);' % (tag, k))
            A('      %s_io_walkReq_%d <= $urandom_range(0,1);' % (tag, k))
            A('      %s_io_freeReq_%d <= ($urandom_range(0,99)<30);' % (tag, k))
            A('      %s_io_freePhyReg_%d <= %s_rnd_preg();' % (tag, k, tag))
            A('      %s_io_commit_commitValid_%d <= $urandom_range(0,1);' % (tag, k))
            A('      %s_io_commit_info_%d_%s <= $urandom_range(0,1);' % (tag, k, wen))
        A('      %s_io_commit_isCommit <= $urandom_range(0,1);' % tag)
        A('      if (cyc < WARM_CYCLES) begin')
        A("        %s_io_snpt_snptEnq <= 1'b1; %s_io_snpt_snptDeq <= 1'b0;" % (tag, tag))
        A("        %s_io_snpt_useSnpt <= 1'b0; %s_io_snpt_snptSelect <= 2'd0;" % (tag, tag))
        A('      end else begin')
        A('        %s_io_snpt_snptEnq <= ($urandom_range(0,99)<15); %s_io_snpt_snptDeq <= ($urandom_range(0,99)<15);' % (tag, tag))
        A('        %s_io_snpt_useSnpt <= $urandom_range(0,1); %s_io_snpt_snptSelect <= $urandom_range(0,3);' % (tag, tag))
        A('      end')
        for k in range(4):
            A('      %s_io_snpt_flushVec_%d <= ($urandom_range(0,99)<5);' % (tag, k))
        A('    end')
        A('  end')
        A('')
        # 比对
        A('  always @(negedge clk) if (!rst) begin')
        A('    #4; checks++;')
        for w, n in outs:
            A('    if (!$isunknown(%s_g_%s) && %s_g_%s !== %s_i_%s) begin errors++;' % (tag, n, tag, n, tag, n))
            A('      if(errors<=80) $display("[%%0t] %s %s g=%%h i=%%h", $time, %s_g_%s, %s_i_%s); end' % (mod, n, tag, n, tag, n))
        A('    // 内部指针探针：golden 展平名 vs 核里的 struct(golden 的 shiftAmount 就是 headPtr.value)')
        for gf, gv, iname in (('headPtr_flag', 'shiftAmount', 'headPtr'),
                              ('archHeadPtr_flag', 'archHeadPtr_value', 'archHeadPtr'),
                              ('lastTailPtr_flag', 'lastTailPtr_value', 'lastTailPtr')):
            A('    if (!$isunknown(%s_g.%s)) begin' % (tag, gf))
            A('      if (%s_g.%s !== %s_i.u_core.%s.flag) begin errors++;' % (tag, gf, tag, iname))
            A('        if(errors<=80) $display("[%%0t] %s %s.flag g=%%h i=%%h", $time, %s_g.%s, %s_i.u_core.%s.flag); end' % (mod, iname, tag, gf, tag, iname))
            A('      if (%s_g.%s !== %s_i.u_core.%s.value) begin errors++;' % (tag, gv, tag, iname))
            A('        if(errors<=80) $display("[%%0t] %s %s.value g=%%h i=%%h", $time, %s_g.%s, %s_i.u_core.%s.value); end' % (mod, iname, tag, gv, tag, iname))
            A('    end')
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
    check = '--check' in argv
    base_ps, _ = ports(BASE)
    base_norm = normalized(base_ps, BASE_WEN)
    outputs = {}
    specs = []
    for k, (mod, wen, prefix, blurb) in enumerate(VARIANTS, 1):
        ps, text = ports(mod)
        if normalized(ps, wen) != base_norm:
            die('%s 的端口集合(归一 %s→regWen 后)与基线 StdFreeList 不同' % (mod, wen))
        g_size, g_nl = golden_params(mod, text)
        p_size, p_nl = pkg_params(prefix)
        if (g_size, g_nl) != (p_size, p_nl):
            die('%s: golden 量出 SIZE=%d/NUM_LOGIC=%d，stdfreelist_pkg 登记 %d/%d' % (mod, g_size, g_nl, p_size, p_nl))
        outputs[OUT_DIR / (mod + '.sv')] = make_wrapper(mod, wen, prefix, blurb, ps, g_size, g_nl)
        specs.append(('v%d' % k, mod, wen, ps, g_size, g_nl))
    outputs[HERE / 'tb.sv'] = make_tb(specs)

    stale = []
    for path, content in outputs.items():
        if check:
            if not path.exists() or path.read_text() != content:
                stale.append(path)
        else:
            path.write_text(content)
            print('生成', path.relative_to(REPO))
    if check:
        if stale:
            print('gen_variants --check: 以下产物与生成器不一致(手改了？改生成器并重跑)：')
            for p in stale:
                print('  ' + str(p.relative_to(REPO)))
            return 1
        print('gen_variants --check: %d 个产物与生成器一致' % len(outputs))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
