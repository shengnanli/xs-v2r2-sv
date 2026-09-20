#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— RealWBArbiter 家族的判别力负测（跑法见 scripts/mutant_harness.py）。

本族的核体就是共享的优先级法则 rtl/common/xs_PriorityArbSelect.sv，所以变异
全部注入那个文件。9 个变体一次注入全考。

★本表里有两条"看着像 bug、其实在本族逐值等价"的空变异（E1/E2）★：它们在
WBArbiter 族是真 bug（那边 eff_valid != in_valid），在本族因为 wrapper 把
eff_valid 直接接了 in_valid 而恒等。列出来是为了把「同一处改动在不同家族里
判别力不同」这件事变成可复跑的证据，而不是一句注释。
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[3] / 'scripts'))
from mutant_harness import Cfg, run

VARIANTS = ['RealWBArbiter'] + ['RealWBArbiter_%d' % i for i in
                                [1, 2, 3, 14, 15, 20, 21, 26]]

MUTANTS = [
    ('CATCH', 'M1 优先级倒过来：payload 选编号最大的那一路',
     '    for (int i = N - 1; i >= 0; i--)\n      if (eff_valid[i]) out_bits = in_bits[i];',
     '    for (int i = 0; i < N; i++)\n      if (eff_valid[i]) out_bits = in_bits[i];'),

    ('CATCH', 'M2 in_ready 丢掉"不请求即就绪"那一项',
     '  assign in_ready  = win | ~in_valid;', '  assign in_ready  = win;'),

    ('CATCH', 'M3 优先级链错位：win[i] 少与一次 none_higher（退化成 ready 恒等于 valid）',
     '      win[i]      = none_higher & eff_valid[i];',
     '      win[i]      = eff_valid[i];'),

    ('CATCH', 'M4 全不请求时的兜底档从最后一路改成第 0 路（golden 条件链末档是 in_bits[N-1]）',
     '    out_bits = in_bits[N-1];', '    out_bits = in_bits[0];'),

    ('CATCH', 'M5 out_valid 恒 0',
     '  assign out_valid = |eff_valid;', "  assign out_valid = 1'b0;"),

    ('EQUIV', 'E1 ★空变异对照★：none_higher 用 in_valid 代替 eff_valid —— 本族 wrapper 把'
     ' eff_valid 直接接了 in_valid，两者是同一根线（同一处改动在 WBArbiter 族是真 bug，'
     '见那边的 M8）',
     '      none_higher = none_higher & ~eff_valid[i];',
     '      none_higher = none_higher & ~in_valid[i];'),

    ('EQUIV', 'E2 ★空变异对照★：out_valid 由 |eff_valid 改成 |win（win 是第一个 1 的 one-hot）',
     '  assign out_valid = |eff_valid;', '  assign out_valid = |win;'),
]

CFG = Cfg(__file__, 'RealWBArbiterVariants', 'common', 'xs_PriorityArbSelect.sv',
          [('common', 'xs_PriorityArbSelect.sv')] +
          [('backend', v + '.sv') for v in VARIANTS], MUTANTS)

if __name__ == '__main__':
    sys.exit(run(CFG))
