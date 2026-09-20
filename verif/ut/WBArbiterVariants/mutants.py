#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— WBArbiter 家族的判别力负测（跑法见 scripts/mutant_harness.py）。

13 个变体共用一个核（rtl/backend/WBArbiter.sv 的 `xs_WBArbiter_core`）；优先级那一级
在共享件 rtl/common/xs_PriorityArbSelect.sv 里，所以本表里有两条变异打进那个文件
（条目末尾带 ('common', ...)）。

★本族有两条"UT 看不见、只有 FM 看得见"的变异，而且第二条是本轮量出来的新东西★：
  M7  异步复位改同步复位（经典款）；
  M9  把 starving 判据里的 has_full_q 换成 |is_full_q —— 这两个信号在**复位可达的
      状态空间里恒等**（两个寄存器同一复位值、次态都来自同一个 is_full_d），
      所以 UT 永远看不见；但 FM 把它们当两个自由寄存器比较，当场报不等价。
      它和「异步/同步复位」是同一类：判据差在**不可达状态上**。
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[3] / 'scripts'))
from mutant_harness import Cfg, run

VARIANTS = ['WBArbiter'] + ['WBArbiter_%d' % i for i in
                            [1, 2, 3, 30, 33, 38, 52, 55, 58, 64, 65, 66]]
SHARED = ('common', 'xs_PriorityArbSelect.sv')

ASYNC = '  always_ff @(posedge clock or posedge reset) begin\n    if (reset) begin'
SYNC = '  always_ff @(posedge clock) begin\n    if (reset) begin'

MUTANTS = [
    ('CATCH', 'M1 饥饿阈值改成 7（golden 是 cnt[2:1] 全 1，即 6 或 7）',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i][2:1]) : (~fired[i] & is_full_q[i]);',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i]) : (~fired[i] & is_full_q[i]);'),

    ('CATCH', 'M2 握手后不清 isFull（饿过一次就永远算饿）',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i][2:1]) : (~fired[i] & is_full_q[i]);',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i][2:1]) : is_full_q[i];'),

    ('CATCH', 'M3 计数器去掉饱和：7 之后回绕到 0',
     "        if (stalled[i])      cancel_cnt_q[i] <= (&cancel_cnt_q[i]) ? 3'h7\n"
     "                                                                   : cancel_cnt_q[i] + 3'h1;",
     "        if (stalled[i])      cancel_cnt_q[i] <= cancel_cnt_q[i] + 3'h1;"),

    ('CATCH', 'M4 反饥饿逃生口去掉：饿着的那几路也一起被挡（final_valid 丢掉 | is_full_q）',
     '  assign final_valid  = in_valid & ({N{~starving_now}} | is_full_q);',
     '  assign final_valid  = in_valid & {N{~starving_now}};'),

    ('CATCH', 'M5 握手不清计数器',
     "        else if (fired[i])   cancel_cnt_q[i] <= 3'h0;",
     "        else if (fired[i])   cancel_cnt_q[i] <= cancel_cnt_q[i];"),

    ('CATCH', 'M6 复位值改成全 1',
     "      cancel_cnt_q <= '0;\n      is_full_q    <= '0;",
     "      cancel_cnt_q <= '1;\n      is_full_q    <= '1;"),

    ('MISS_FM', 'M7 异步复位改同步复位 —— ★UT 结构上看不见，由 FM 的 F1 兜底★',
     ASYNC, SYNC),

    ('CATCH', 'M8 优先级链看错向量：共享法则里 none_higher 用 in_valid 而不是 eff_valid'
     '（反饥饿一开，被挡住的高优先级路仍然会压住低优先级路）',
     '      none_higher = none_higher & ~eff_valid[i];',
     '      none_higher = none_higher & ~in_valid[i];', SHARED),

    ('MISS_FM', 'M9 starving 判据里 has_full_q 换成 |is_full_q —— ★两者在复位可达状态里'
     '恒等（同复位值、同次态源），UT 看不见；FM 当两个自由寄存器比，F2 实证它报不等价★',
     '  assign starving_now = has_full_q & (|(in_valid & is_full_q));',
     '  assign starving_now = (|is_full_q) & (|(in_valid & is_full_q));'),

    ('CATCH', 'M10 payload 选择倒过来（共享法则里改成编号最大的赢）',
     '    for (int i = N - 1; i >= 0; i--)\n      if (eff_valid[i]) out_bits = in_bits[i];',
     '    for (int i = 0; i < N; i++)\n      if (eff_valid[i]) out_bits = in_bits[i];', SHARED),

    ('EQUIV', 'E1 ★空变异对照★：out_valid 由 |eff_valid 改成 |win —— win 是 eff_valid 的'
     '第一个 1 的 one-hot，两者恒等（有 1 才有 win）',
     '  assign out_valid = |eff_valid;', '  assign out_valid = |win;', SHARED),
]

FM_MUTANTS = [
    ('F1 异步复位改同步复位（★UT 看不见，归 FM 管★）', ASYNC, SYNC, True),
    ('F2 has_full_q 换成 |is_full_q（★UT 看不见，归 FM 管：不可达状态上不等价★）',
     '  assign starving_now = has_full_q & (|(in_valid & is_full_q));',
     '  assign starving_now = (|is_full_q) & (|(in_valid & is_full_q));', True),
    ('F3 饥饿阈值改成 7（正对照：UT 抓得到的 FM 也必须抓到）',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i][2:1]) : (~fired[i] & is_full_q[i]);',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i]) : (~fired[i] & is_full_q[i]);', True),
    ('F4 空变异对照（★不该报警，也确实不报★）',
     '  assign out_valid = |eff_valid;', '  assign out_valid = |win;', False,
     ('common', 'xs_PriorityArbSelect.sv')),
]

CFG = Cfg(__file__, 'WBArbiterVariants', 'backend', 'WBArbiter.sv',
          [('common', 'xs_PriorityArbSelect.sv')] +
          [('backend', v + '.sv') for v in VARIANTS], MUTANTS,
          fm_mutants=FM_MUTANTS, fm_top='WBArbiter_33')

if __name__ == '__main__':
    sys.exit(run(CFG))
