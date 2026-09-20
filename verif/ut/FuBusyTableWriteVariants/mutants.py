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

    # ★预登记 CATCH，实测两边都不报 —— 重新分类的完整交代（2026-09-20）★
    # 上一轮把 M4 登记成 CATCH，是按"最高位槽从恒 0 变成保持上一拍，行为就变了"
    # 推的。这条推断错在**没算复位可达性**，而且错得比第一眼更彻底：
    #   本变异改的是 always_comb 的默认赋值（`fu_busy_table_d = '0;`），循环随后把
    #   槽 0..W-2 全部覆写，唯一吃到默认值的是最高位槽 W-1，于是
    #     原： d[W-1] = 0            变异后： d[W-1] = q[W-1]
    #   而 q[W-1] 异步复位到 0、且 SLOT_SEL[W-1] == 0（最高位槽是 Chisel Vec 顶端，
    #   golden 从不往它写）⇒ deq 永远打不中它 ⇒ 复位之后 q[W-1] 恒 0，
    #   `q[W-1]` 与常量 `0` 在**全部复位可达状态**上逐拍相同。
    #
    # 重分类走了两步，两步都留了证据（不是一步到位地改成好看的那一类）：
    #   第一步：按 M7/M9 的先例猜它是 MISS_FM（只在不可达状态上不同，归 FM 管），
    #           并在 FM_MUTANTS 里加了兑现条目 F4。
    #   第二步：F4 实测 **native=SUCCEEDED failing=0** —— ★FM 也判等价★。
    #           因为 FM 的常量寄存器传播能看出 q[W-1] 的次态是它自己、复位值为 0，
    #           直接折成常量 0，与 golden 一致。所以它不是"UT 看不见、FM 看得见"，
    #           而是**在本设计的复位语义下真的等价**。
    #   于是最终归 EQUIV（逻辑等价空变异），从分子分母**同时剔除**。
    # ★与 M7/M9 的区别要写清楚★：M7/M9 是 FM 实测报不等价（failing 3 / 20）的，
    #   M4 是 FM 实测报等价的 —— 同样"UT 不报"，证据方向相反，不能混为一类。
    # 分母从 8 降到 7 是有代价的：EQUIV 条目必须两侧都有实证
    # （UT errors=0 + FM_MUTANTS 里 expect_fail=False 的 F4 实测 SUCCEEDED），
    # 缺一就退回 MISSED 计入分母。逐条对账见汇报。
    ('EQUIV', 'E2 ★空变异（复位可达意义上）★：最高位槽默认值 0 改成保持上一拍 —— '
     'SLOT_SEL[W-1]==0 无写入源且复位到 0 ⇒ q[W-1] 恒 0，与常量 0 逐拍相同；'
     'UT errors=0 且 FM 的 F4 也判 SUCCEEDED，两侧同证等价',
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
    # F4 原本是按"M4 归 MISS_FM"加的、期望 True（FM 必须报不等价）。实测
    # native=SUCCEEDED failing=0 ⇒ 期望改成 False，条目保留：它现在是 E2
    # 「复位可达意义上等价」在 FM 侧的**实证**，与 UT 侧 errors=0 合起来才够格
    # 把 E2 从分子分母里剔除。★期望是被实测改的，改动连同理由留在这里，
    # 不是把不合意的条目删掉了事★。
    ('F4 最高位槽改成保持上一拍（★E2 的 FM 侧实证：FM 的常量寄存器传播把 q[W-1] '
     '折成常量 0，判等价；不该报警，也确实不报★）',
     "    fu_busy_table_d = '0;                     // 最高位槽恒 0（见文件头）",
     '    fu_busy_table_d = fu_busy_table_q;', False),
]

CFG = Cfg(__file__, 'FuBusyTableWriteVariants', 'backend', 'FuBusyTableWrite.sv',
          [('backend', v + '.sv') for v in VARIANTS], MUTANTS,
          fm_mutants=FM_MUTANTS, fm_top='FuBusyTableWrite_105')

if __name__ == '__main__':
    sys.exit(run(CFG))
