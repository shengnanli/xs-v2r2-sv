#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— 生成 MSHR UT 的 tb.sv（golden MSHR vs 重写 MSHR_xs 双例化逐拍比对）。

端口表从 golden 解析；激励规则（哪些输入怎么偏置）写在 BIAS 表里。幂等：内容不变不写。
用法: python3 gen_tb.py [--check]
"""
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))
TOP = 'MSHR'

# golden 里没有复位的寄存器：+vcs+initreg+random 下两侧各摇各的初值（双例化假失配），
# tb 在第一个时钟沿之前把 golden 侧的初值 force 到重写侧再 release —— 两侧同初态，仍是随机值。
# 有复位的寄存器一个都不同步（复位域正确性仍由比对把关）。
NORESET_REGS = ['tgtid_rcompack', 'txnid_rcompack', 'tgtid_wcompack', 'txnid_wcompack',
                'srcid_retryack', 'acquire_ts', 'release_ts', 'acquire_period_valid_REG',
                'release_period_valid_REG', 'REG', 'REG_1', 'REG_2', 'REG_3']

# 覆盖探针：golden 内部线名（golden 已冻结，探针不会腐烂）
COVER = ['release_valid1', 'release_valid2', 'mp_grant_valid', 'mp_cbwrdata_valid',
         'mp_probeack_valid', 'mp_dct_valid', 'rcompack_valid', 'wcompack_valid',
         'nestedwb_match', 'nestedwb_hit_match', 'doRespData', 'req_promoteT',
         'isWriteBackFull', 'isWriteEvictOrEvict', 'isEvict', 'cmo_cbo',
         '_GEN_80',            # will_free & req_valid：一次事务完整结束
         'acquire_period_valid', 'release_period_valid', 'io_nestedwbData',
         'io_pCrd_query_valid']


def ports():
    src = (GOLDEN / (TOP + '.sv')).read_text()
    m = re.search(r'^module %s\(\n(.*?)\n\);\n' % TOP, src, re.S | re.M)
    out = []
    for ln in m.group(1).split('\n'):
        mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
        out.append((mm.group(1), int(mm.group(2)) + 1 if mm.group(2) else 1, mm.group(3)))
    return out


def drive_expr(name, w):
    """每个输入每拍的取值（偏置规则）。"""
    r = lambda: '$urandom'
    if name == 'io_alloc_valid':
        # 空闲时常分配；占用时极少重分配（MSHRCtl 只给空闲 MSHR 分配，但重写件对任意输入都得一致）
        return "u_g.req_valid ? ($urandom_range(0, 299) == 0) : ($urandom_range(0, 3) == 0)"
    if name.startswith('io_alloc_bits_state_'):
        return "($urandom_range(0, 2) != 0)"            # 2/3 概率"已完成"
    if name == 'io_alloc_bits_task_opcode':
        return "pick_a_opcode()"
    if name == 'io_alloc_bits_task_chiOpcode':
        return "$urandom_range(0, 23)"                  # 覆盖全部 snoop opcode
    if name == 'io_alloc_bits_task_channel':
        return "3'b1 << $urandom_range(0, 2)"
    if name in ('io_alloc_bits_dirResult_set', 'io_nestedwb_set'):
        return "(%s) ? u_g.dirResult_set : 9'($urandom_range(0, 3))" % coin(2) if name == 'io_nestedwb_set' \
            else "9'($urandom_range(0, 3))"
    if name in ('io_alloc_bits_dirResult_tag', 'io_nestedwb_tag', 'io_replResp_bits_tag'):
        if name == 'io_nestedwb_tag':
            return "(%s) ? u_g.dirResult_tag : 31'($urandom_range(0, 3))" % coin(2)
        return "31'($urandom_range(0, 3))"
    if name == 'io_resps_rxdat_bits_chiOpcode':
        return "pick(7'h4, 7'hB, 7'($urandom))"
    if name == 'io_resps_rxrsp_bits_chiOpcode':
        return "pick5(7'hB, 7'h4, 7'h5, 7'h3, 7'($urandom))"
    if name == 'io_resps_sinkC_bits_opcode':
        return "pick(3'h4, 3'h5, 3'($urandom))"
    if name.endswith('_valid') and name.startswith('io_resps_'):
        return "($urandom_range(0, 5) == 0)"
    if name in ('io_replResp_valid', 'io_pCrd_grant', 'io_dsResp_valid'):
        return "($urandom_range(0, 9) == 0)"
    if name == 'io_aMergeTask_valid':
        return "($urandom_range(0, 19) == 0)"
    if name.startswith('io_nestedwb_') and w == 1:
        return "($urandom_range(0, 7) == 0)"
    if name.endswith('_ready'):
        return "($urandom_range(0, 9) < 7)"
    if w <= 32:
        return "%d'($urandom)" % w
    return "{%s}" % ', '.join(['$urandom'] * ((w + 31) // 32))


def coin(n):
    return '$urandom_range(0, %d) == 0' % (n - 1)


def tb():
    ps = ports()
    ins = [(w, n) for d, w, n in ps if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ps if d == 'output']
    L = []
    A = L.append
    A('// =============================================================================')
    A('// tb —— MSHR UT：golden MSHR 与重写 MSHR_xs 双例化，同激励逐拍比对全部 %d 个输出。' % len(outs))
    A('//')
    A('// 激励（每拍全部输入重摇，偏置见 gen_tb.py 的 drive_expr）：')
    A('//   · 空闲时 1/4 概率分配、占用时 1/300 概率重分配；分配的 state 标志 2/3 为 1；')
    A('//   · TL opcode 偏向 Get/Hint/Acquire*/CBO*，snoop opcode 覆盖 0..23 全部；')
    A('//   · set/tag 取值域压到 0..3，nestedwb 的 set/tag 一半直接取 golden 当前 dirResult，')
    A('//     让嵌套写回匹配真正发生；RXDAT/RXRSP/SinkC 的 opcode 偏向本模块识别的那几个；')
    A('//   · 约 1/5000 拍一次单拍异步复位。')
    A('// 未复位寄存器：+vcs+initreg+random 下两侧初值不同，tb 在首个时钟沿前把 golden 侧')
    A('//   初值 force 到重写侧（见 NORESET_REGS），两侧同初态；有复位的寄存器不做任何同步。')
    A('// 覆盖：一组 golden 内部判断（release/grant/probeack/dct/cbwrdata/CompAck/嵌套写回/')
    A('//   事务结束 …）各自为真的拍数，任何一项为 0 即判 TEST FAILED。')
    A('//')
    A('// 本文件由 verif/ut/MSHR/gen_tb.py 生成，勿手改。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clock = 0; always #5 clock = ~clock;')
    A('  logic reset;')
    A('  longint errors = 0, checks = 0;')
    A('')
    for w, n in ins:
        A('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n))
    for w, n in outs:
        A('  logic %sg_%s, i_%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n, n))
    A('')
    for side, mod in (('g', TOP), ('i', TOP + '_xs')):
        A('  %s u_%s (' % (mod, side))
        conns = ['    .clock(clock)', '    .reset(reset)']
        for d, w, n in ps:
            if n in ('clock', 'reset'):
                continue
            conns.append('    .%s(%s)' % (n, n if d == 'input' else '%s_%s' % (side, n)))
        A(',\n'.join(conns))
        A('  );')
    A('')
    A('  function automatic logic [3:0] pick_a_opcode();')
    A('    case ($urandom_range(0, 9))')
    A("      0: return 4'h4;  1: return 4'h5;  2, 3: return 4'h6;  4: return 4'h7;")
    A("      5: return 4'hC;  6: return 4'hD;  7: return 4'hE;")
    A("      default: return 4'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('  function automatic logic [6:0] pick(input logic [6:0] a, input logic [6:0] b, input logic [6:0] c);')
    A('    case ($urandom_range(0, 2)) 0: return a; 1: return b; default: return c; endcase')
    A('  endfunction')
    A('  function automatic logic [6:0] pick5(input logic [6:0] a, input logic [6:0] b, input logic [6:0] c,')
    A('                                      input logic [6:0] d, input logic [6:0] e);')
    A('    case ($urandom_range(0, 4)) 0: return a; 1: return b; 2: return c; 3: return d;')
    A('      default: return e; endcase')
    A('  endfunction')
    A('')
    A('  task automatic drive();')
    for w, n in ins:
        A('    %s = %s;' % (n, drive_expr(n, w)))
    A("    reset = ($urandom_range(0, 4999) == 0);")
    A('  endtask')
    A('')
    A('  `define CK(nm) begin checks++; if (g_``nm !== i_``nm) begin errors++; \\')
    A('    if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, `"nm`", g_``nm, i_``nm); \\')
    A('    end end')
    A('  task automatic check();')
    for w, n in outs:
        A('    `CK(%s)' % n)
    A('  endtask')
    A('')
    A('  longint cov [%d];' % len(COVER))
    A("  localparam string COV_NAME [%d] = '{%s};" % (len(COVER), ', '.join('"%s"' % c for c in COVER)))
    A('  task automatic sample();')
    for k, c in enumerate(COVER):
        A('    if (u_g.%s) cov[%d]++;' % (c, k))
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A("    foreach (cov[k]) cov[k] = 0;")
    A("    reset = 1'b1;")
    A('    drive(); reset = 1\'b1;')
    A('    #1;')
    A('    // 未复位寄存器两侧同初值（见文件头）')
    for r in NORESET_REGS:
        A('    force u_i.u_core.%s = u_g.%s;' % (r, r))
    A('    #1;')
    for r in NORESET_REGS:
        A('    release u_i.u_core.%s;' % r)
    A('    repeat (4) @(posedge clock);')
    A("    #1; drive(); reset = 1'b0;")
    A('    repeat (NCYCLES) begin')
    A('      @(posedge clock); #1;')
    A('      check(); sample(); drive();')
    A('    end')
    A('    report();')
    A('    $finish;')
    A('  end')
    A('')
    A('  task automatic report();')
    A('    int bad = 0;')
    A('    $display("--- coverage（golden 内部判断为真的拍数）---");')
    A('    foreach (cov[k]) begin')
    A('      $display("  %-24s %0d", COV_NAME[k], cov[k]);')
    A('      if (cov[k] == 0) bad++;')
    A('    end')
    A('    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);')
    A('    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");')
    A('    else $display("TEST FAILED");')
    A('  endtask')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main():
    text = tb()
    p = HERE / 'tb.sv'
    cur = p.read_text() if p.exists() else None
    if '--check' in sys.argv:
        if cur != text:
            print('gen_tb(MSHR): DRIFT')
            return 1
        print('gen_tb(MSHR): OK')
        return 0
    if cur != text:
        p.write_text(text)
        print('gen_tb(MSHR): 更新 tb.sv')
    else:
        print('gen_tb(MSHR): 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
