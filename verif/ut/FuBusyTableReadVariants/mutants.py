#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— FuBusyTableRead 家族的判别力负测（跑法见 scripts/mutant_harness.py）。

18 个变体共用一个核，所以变异全部注入 rtl/backend/FuBusyTableRead.sv 的
`xs_FuBusyTableRead_core`，一次注入同时考验 18 个变体的双例化比对。

★小模块的变异体特别容易写成"空变异"★，本表每条都先自证改了电路（harness 里
锚点不存在/文本没变一律判 INVALID），并且**特意留了一条真正的空变异**（E1）
来验证这套口径本身：它逻辑上恒等，errors 必须为 0，分子分母都不计。
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[3] / 'scripts'))
from mutant_harness import Cfg, run

VARIANTS = ['FuBusyTableRead'] + ['FuBusyTableRead_%d' % i for i in
                                  [2, 22, 23, 26, 28, 42, 43, 52, 53, 68, 69,
                                   71, 73, 75, 79, 80, 105]]

MUTANTS = [
    ('CATCH', 'M1 槽之间由"或"改成"覆盖"：|= 改 =（多槽变体只剩编号最大的那槽算数）',
     '          busy_mask[e] |= |(fu_type[e] & FU_SEL[b]);',
     '          busy_mask[e] = |(fu_type[e] & FU_SEL[b]);'),

    ('CATCH', 'M2 槽号错位一格：FU_SEL[b] 取成 FU_SEL[b+1]',
     '          busy_mask[e] |= |(fu_type[e] & FU_SEL[b]);',
     '          busy_mask[e] |= |(fu_type[e] & FU_SEL[(b + 1) % 8]);'),

    ('CATCH', 'M3 忙表门控反相：if (fu_busy_table[b]) 改成 if (~fu_busy_table[b])',
     '      if (fu_busy_table[b])',
     '      if (~fu_busy_table[b])'),

    ('CATCH', 'M4 命中判据由"交集非空"改成"掩码非空"（& 改 |，等于忽略条目自身的 fuType）',
     '          busy_mask[e] |= |(fu_type[e] & FU_SEL[b]);',
     '          busy_mask[e] |= |(fu_type[e] | FU_SEL[b]);'),

    ('CATCH', 'M5 最后一个条目永不被屏蔽：e < NE 改成 e < NE-1',
     '        for (int e = 0; e < NE; e++)',
     '        for (int e = 0; e < NE - 1; e++)'),

    ('CATCH', 'M6 初值不清零：busy_mask 不再每拍从 0 起（组合环/残留）',
     "    busy_mask = '0;",
     "    busy_mask = {NE{1'b1}};"),

    ('EQUIV', 'E1 ★空变异对照★：|= 展开成 = a | b —— SystemVerilog 里逐字等价，'
     '用来验证 harness 不把"改了字面"误当成"改了电路"',
     '          busy_mask[e] |= |(fu_type[e] & FU_SEL[b]);',
     '          busy_mask[e] = busy_mask[e] | (|(fu_type[e] & FU_SEL[b]));'),
]

CFG = Cfg(__file__, 'FuBusyTableReadVariants', 'backend', 'FuBusyTableRead.sv',
          [('backend', v + '.sv') for v in VARIANTS], MUTANTS)

if __name__ == '__main__':
    sys.exit(run(CFG))
