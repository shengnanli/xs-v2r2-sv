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

    # M9 的兜底说法在本轮被实测收窄（2026-09-20）：
    #   · 无钉点配置下（沙箱旧行为）：FM verify 直接报 Verification FAILED / failing 20
    #     —— 说明这两个信号在 FM 眼里确实不等价，不是靠谁"顺手拦下"的。
    #   · 真实签核配置下（带 fm_pins.tcl）：走不到 verify —— has_full_q 被改成无人读，
    #     impl 侧多出一个 golden 没有的 unread 点，双射自检当场拒绝、不出 receipt。
    # 两条都是"签核流程不会让它过去"，但抓它的闸不同，F2 记的是后者（GATE）。
    ('MISS_FM', 'M9 starving 判据里 has_full_q 换成 |is_full_q —— ★两者在复位可达状态里'
     '恒等（同复位值、同次态源），UT 看不见；FM 侧由 F2 实证拦得住：无钉点时 verify '
     '报 failing 20，带钉点时双射自检拒绝、不出 receipt★',
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
    # ★F2 的期望在本轮被实测改过，改动与理由留在这里（2026-09-20）★
    # 原来写的是 True（FM 必须报 Verification FAILED），在**没有钉点**的沙箱里
    # 确实跑出 failing=20。但那个沙箱配置与真实签核不一致（见 mutant_harness.prepare
    # 里的说明）：补上 fm_pins.tcl 之后，这条变异根本走不到 verify ——
    # has_full_q 被改成无人读，impl 侧于是多出一个 golden 没有的 unread 点，
    # fm_pins.tcl 的双射自检当场拒绝（WBARBITER_PIN_ERROR: pinned 0 but impl has 1
    # unread points -- not a bijection），fm_shell 停在那里，日志里没有 Verification 行。
    # ★这是被抓到了，只是抓它的是钉点闸不是 verify★，所以期望改成点名那道闸的
    # GATE:<marker>，而不是笼统的"非 SUCCEEDED"（那会把 license 挂了也读成抓到）。
    # 顺带记一条坑：fm_pins.tcl 在 sidecar 的受限 safe interp 里跑，**`exit` 这个命令
    # 不存在**（日志里是 `Error: invalid command name "exit"`）。脚本里的 `exit 3`
    # 于是变成抛错 —— 仍然 fail-closed（不 verify、make rc!=0、verdict=ERROR、不出
    # receipt），但退出码不是写的那个。本仓其它 fm_pins.tcl 是同一个写法，同一个行为。
    ('F2 has_full_q 换成 |is_full_q（★UT 看不见；在真实签核配置下由 fm_pins.tcl 的'
     '双射自检拦下，不是由 verify 拦下★）',
     '  assign starving_now = has_full_q & (|(in_valid & is_full_q));',
     '  assign starving_now = (|is_full_q) & (|(in_valid & is_full_q));',
     'GATE:WBARBITER_PIN_ERROR'),
    ('F3 饥饿阈值改成 7（正对照：UT 抓得到的 FM 也必须抓到）',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i][2:1]) : (~fired[i] & is_full_q[i]);',
     '      is_full_d[i] = stalled[i] ? (&cancel_cnt_q[i]) : (~fired[i] & is_full_q[i]);', True),
    ('F4 空变异对照（★不该报警，也确实不报★）',
     '  assign out_valid = |eff_valid;', '  assign out_valid = |win;', False,
     ('common', 'xs_PriorityArbSelect.sv')),

    # ★F5：给"Not Compared / Constant reg"那一个点做负控（2026-09-20 实测）★
    # N=1 的四个变体签核时钉了 2 个死位点，结果是 **1 个进 passing（hasFull）、
    # 1 个被 FM 判成 Constant reg 落进 Not Compared（cancelCounter_0[0]）**。
    # "Not Compared" 听起来就像被吞掉了，所以必须证明它不是盲区：把 cancelCounter
    # 的复位值从 0 改成 1，这个寄存器就不再是常量（N=1 下 next = fired ? 0 : hold，
    # 从 7 开始、首次握手后清零），FM 立刻把它当真 DFF 比较并报不等价。
    # 实测：clean 跑 Passing 2 Port + 1 DFF = 3 / Constant reg 1；
    #       本变异跑 Verification FAILED，Failing DFF = 1。
    # ★必须跑在 WBArbiter_3 上★：家族默认 fm_top 是 WBArbiter_33（N=4），那里
    # 这些寄存器全部可达、根本没有 Constant reg 那一行，负控就考不到要考的东西。
    ('F5 N=1 的 cancelCounter 复位值 0->1（★负控：签核时它落在 Not Compared/'
     'Constant reg，这里证明"常量"不是盲区——一旦它不再是常量，FM 当场报不等价★）',
     "      cancel_cnt_q <= '0;", "      cancel_cnt_q <= '1;", True, None, 'WBArbiter_3'),
]

CFG = Cfg(__file__, 'WBArbiterVariants', 'backend', 'WBArbiter.sv',
          [('common', 'xs_PriorityArbSelect.sv')] +
          [('backend', v + '.sv') for v in VARIANTS], MUTANTS,
          fm_mutants=FM_MUTANTS, fm_top='WBArbiter_33')

if __name__ == '__main__':
    sys.exit(run(CFG))
