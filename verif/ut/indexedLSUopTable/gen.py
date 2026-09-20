#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— indexedLSUopTable 家族的 7 个薄 wrapper 与 UT tb。

薄 wrapper 只做两件事：把 golden 的三根端口接到参数化核 xs_indexedLSUopTable_core，
以及把 UOP_IDX 设成本变体的值。之所以生成而不是手抄：每个文件头都要列出**本变体
自己的 16 项真值表**（读者打开 _5 就该看到 _5 的表，而不是一句「是某家族的变体」），
而那 16 行必须由算法算出来，手抄七遍必错。

tb.sv 对 7 个变体各做一次 **16 种输入全穷举** 比对 —— 这个模块的输入空间只有
2^4，随机激励在这里没有意义，穷举就是完全证明（仿真侧）。

用法：
    python3 gen.py            # 生成（幂等）
    python3 gen.py --check    # DRIFT 则非零退出
"""
import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
OUT = REPO / 'rtl' / 'backend'
VARIANTS = list(range(1, 8))


def offsets(uop_idx, emul, lmul):
    """Chisel genCsBundle_VEC_INDEXED_LDST 的等价实现（见核文件头）。"""
    if lmul < emul:
        offset = 1 << (emul - lmul)
        num = 1 << emul
        return (uop_idx, uop_idx // offset) if uop_idx < num else (0, 0)
    offset = 1 << (lmul - emul)
    num = 1 << lmul
    return (uop_idx // offset, uop_idx) if uop_idx < num else (0, 0)


def table_comment(u):
    L = []
    L.append('// ★ 本变体的完整真值表（EMUL/LMUL 为倍数的以 2 为底对数）★')
    L.append('//   src[3:2]=EMUL  src[1:0]=LMUL        uop 数   vs2 偏移  vd 偏移')
    for emul in range(4):
        for lmul in range(4):
            s = (emul << 2) | lmul
            num = (1 << emul) if lmul < emul else (1 << lmul)
            vs2, vd = offsets(u, emul, lmul)
            note = '' if u < num else '   （本变体超出 uop 数，两个偏移都是 0）'
            L.append(f'//   src=4\'h{s:X}  EMUL={1<<emul}  LMUL={1<<lmul}'
                     f'{"":2s}{num:6d}{vs2:10d}{vd:10d}{note}')
    return L


def emit_variant(u):
    L = []
    L.append(f'// =============================================================================')
    L.append(f'// indexedLSUopTable_{u}.sv —— 索引访存 uop 偏移表的第 {u} 个 uop 变体')
    L.append(f'// -----------------------------------------------------------------------------')
    L.append(f'// 家族核：rtl/backend/xs_indexedLSUopTable_core.sv（算法与整体说明都在那里）')
    L.append(f'// golden 对照：G1-canonical/golden-rtl/indexedLSUopTable_{u}.sv')
    L.append(f'//')
    L.append(f'// 本变体参数与规模：UOP_IDX = {u}；端口 3 根（src[3:0] 输入，')
    L.append(f'// outOffsetVs2[2:0] / outOffsetVd[2:0] 输出）；纯组合，无时钟无复位；')
    L.append(f'// 输入空间只有 2^4 = 16 种，UT 全穷举。')
    L.append(f'//')
    L.extend(table_comment(u))
    L.append(f'// =============================================================================')
    L.append('')
    L.append(f'module indexedLSUopTable_{u}(')
    L.append('  input  [3:0] src,')
    L.append('  output [2:0] outOffsetVs2,')
    L.append('  output [2:0] outOffsetVd')
    L.append(');')
    L.append('')
    L.append(f'  xs_indexedLSUopTable_core #(.UOP_IDX({u})) u_core (')
    L.append('    .src            (src),')
    L.append('    .out_offset_vs2 (outOffsetVs2),')
    L.append('    .out_offset_vd  (outOffsetVd)')
    L.append('  );')
    L.append('')
    L.append(f'endmodule : indexedLSUopTable_{u}')
    return '\n'.join(L) + '\n'


TB_HEAD = '''// =============================================================================
// indexedLSUopTable 家族 UT —— 7 个变体各一对 DUT（golden indexedLSUopTable_N
// 对重写 indexedLSUopTable_N_xs），把 src 的 **16 种取值全部穷举**，逐个比对
// outOffsetVs2 / outOffsetVd。
//
// ★ 为什么是穷举而不是随机 ★
// 本模块是纯组合的 4 入 6 出查找表，输入空间只有 16 个点。随机跑 200k 拍与
// 穷举 16 个点证明力完全相同，而穷举还额外保证「每个点都验到了」是事实而不是
// 概率。tb 仍按 +ncycles 跑满要求的拍数（每拍换一个 src，循环遍历），并在结束
// 时报告每个 (变体, src) 组合各被验了多少次 —— 任何一格为 0 即判失败。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  logic [3:0] src;
  longint cov [7][16];
'''


def emit_tb():
    L = [TB_HEAD]
    for u in VARIANTS:
        L.append(f'  logic [2:0] g{u}_vs2, g{u}_vd, x{u}_vs2, x{u}_vd;')
        L.append(f'  indexedLSUopTable_{u}    u_g{u} (.src(src), .outOffsetVs2(g{u}_vs2),'
                 f' .outOffsetVd(g{u}_vd));')
        L.append(f'  indexedLSUopTable_{u}_xs u_x{u} (.src(src), .outOffsetVs2(x{u}_vs2),'
                 f' .outOffsetVd(x{u}_vd));')
    L.append('''
  task automatic check_one(input int v, input logic [2:0] gv, gd, xv, xd);
    cov[v - 1][src]++;
    checks++;
    if (gv !== xv || gd !== xd) begin
      errors++;
      if (errors < 20)
        $display("MISMATCH variant=%0d src=%01h gold=(%0d,%0d) xs=(%0d,%0d)",
                 v, src, gv, gd, xv, xd);
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < 7; v++) for (int s = 0; s < 16; s++) cov[v][s] = 0;
    @(negedge clk);
    for (longint c = 0; c < NCYCLES; c++) begin
      src = 4'(c % 16);
      #1;''')
    for u in VARIANTS:
        L.append(f'      check_one({u}, g{u}_vs2, g{u}_vd, x{u}_vs2, x{u}_vd);')
    L.append('''      @(negedge clk);
    end

    $display("=== COVERAGE (indexedLSUopTable) ===");
    begin
      int holes = 0;
      for (int v = 0; v < 7; v++)
        for (int s = 0; s < 16; s++)
          if (cov[v][s] == 0) begin
            holes++;
            $display("  UNCOVERED variant=%0d src=%01h", v + 1, s);
          end
      $display("  variants=7 x src=16 = 112 格，未覆盖 %0d 格，checks=%0d", holes, checks);
      if (holes != 0) begin
        $display("COVERAGE INSUFFICIENT: 输入空间没穷举完");
        errors++;
      end
    end

    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end

endmodule
''')
    return '\n'.join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    outs = [(OUT / f'indexedLSUopTable_{u}.sv', emit_variant(u)) for u in VARIANTS]
    outs.append((HERE / 'tb.sv', emit_tb()))
    rc = 0
    for p, txt in outs:
        old = p.read_text() if p.exists() else None
        if old == txt:
            print(f'  same  {p.relative_to(REPO)}')
        elif a.check:
            print(f'  DRIFT {p.relative_to(REPO)}')
            rc = 1
        else:
            p.write_text(txt)
            print(f'  write {p.relative_to(REPO)}')
    return rc


if __name__ == '__main__':
    sys.exit(main())
