#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— FuBusyTableWrite 家族的判别力负测（跑法见 scripts/mutant_harness.py）。

15 个变体共用一个核，变异全部注入 rtl/backend/FuBusyTableWrite.sv 的
`xs_FuBusyTableWrite_core`。本族有寄存器，所以除了功能变异之外还有一条
**只有 FM 看得见**的复位域变异（M7 / F1 一对）。
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[3] / 'scripts'))
from mutant_harness import Cfg, run

VARIANTS = ['FuBusyTableWrite'] + ['FuBusyTableWrite_%d' % i for i in
                                   [22, 26, 42, 43, 52, 53, 68, 69, 71, 73,
                                    75, 79, 80, 105]]

ASYNC = ("  always_ff @(posedge clock or posedge reset) begin\n"
         "    if (reset) fu_busy_table_q <= '0;")
SYNC = ("  always_ff @(posedge clock) begin\n"
        "    if (reset) fu_busy_table_q <= '0;")

MUTANTS = [
    ('CATCH', 'M1 og0 取消槽错位：清 s+1 改成清 s（晚一拍取消）',
     '      cancel_og0 = HAS_OG0 && og0_valid && slot_hit(og0_fu_type, s + 1);',
     '      cancel_og0 = HAS_OG0 && og0_valid && slot_hit(og0_fu_type, s);'),

    ('CATCH', 'M2 og1 的 resp==0 条件去掉（非 0 的回应也被当成取消）',
     "      cancel_og1 = HAS_OG1 && og1_valid && (og1_resp == 2'd0)",
     "      cancel_og1 = HAS_OG1 && og1_valid && (1'b1)"),

    ('CATCH', 'M3 发射登记槽错位：deq 写 s 改成写 s+1',
     '      fu_busy_table_d[s] = shifted | (deq_valid & slot_hit(deq_fu_type, s));',
     '      fu_busy_table_d[s] = shifted | (deq_valid & slot_hit(deq_fu_type, s + 1));'),

    ('CATCH', 'M4 最高位槽不再恒 0（改成保持上一拍，golden 那根死线被补活）',
     "    fu_busy_table_d = '0;                     // 最高位槽恒 0（见文件头）",
     '    fu_busy_table_d = fu_busy_table_q;'),

    ('CATCH', 'M5 复位值改成全 1（golden 一律复位到 0）',
     "    if (reset) fu_busy_table_q <= '0;",
     "    if (reset) fu_busy_table_q <= '1;"),

    ('CATCH', 'M6 og1 取消整条去掉（只留 og0）',
     '      shifted = fu_busy_table_q[s + 1] & ~cancel_og0 & ~cancel_og1;',
     '      shifted = fu_busy_table_q[s + 1] & ~cancel_og0;'),

    ('MISS_FM', 'M7 异步复位改同步复位 —— ★UT 结构上看不见（tb 的 rst 覆盖整拍），'
     '由 FM 的 F1 兜底★', ASYNC, SYNC),

    ('CATCH', 'M8 右移方向错：取 s+1 改成取 s（表原地不动，倒计时失效）',
     '      shifted = fu_busy_table_q[s + 1] & ~cancel_og0 & ~cancel_og1;',
     '      shifted = fu_busy_table_q[s] & ~cancel_og0 & ~cancel_og1;'),

    ('EQUIV', 'E1 ★空变异对照★：槽号越界判据 (slot >= 0 && slot < NSLOT) 去掉 slot>=0 —— '
     '调用点只用 s / s+1 / s+2（s >= 0），该项恒真，逐值等价',
     '    slot_hit = (slot >= 0 && slot < NSLOT) ? |(fu_type & SLOT_SEL[slot]) : 1\'b0;',
     '    slot_hit = (slot < NSLOT) ? |(fu_type & SLOT_SEL[slot]) : 1\'b0;'),
]

FM_MUTANTS = [
    ('F1 异步复位改同步复位（★UT 看不见，归 FM 管★）', ASYNC, SYNC, True),
    ('F2 og0 取消槽错位（正对照：UT 抓得到的 FM 也必须抓到）',
     '      cancel_og0 = HAS_OG0 && og0_valid && slot_hit(og0_fu_type, s + 1);',
     '      cancel_og0 = HAS_OG0 && og0_valid && slot_hit(og0_fu_type, s);', True),
    ('F3 空变异对照（★不该报警，也确实不报★）',
     '    slot_hit = (slot >= 0 && slot < NSLOT) ? |(fu_type & SLOT_SEL[slot]) : 1\'b0;',
     '    slot_hit = (slot < NSLOT) ? |(fu_type & SLOT_SEL[slot]) : 1\'b0;', False),
]

CFG = Cfg(__file__, 'FuBusyTableWriteVariants', 'backend', 'FuBusyTableWrite.sv',
          [('backend', v + '.sv') for v in VARIANTS], MUTANTS,
          fm_mutants=FM_MUTANTS, fm_top='FuBusyTableWrite_105')

if __name__ == '__main__':
    sys.exit(run(CFG))
