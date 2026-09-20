# vmucp 白名单条目：LoadQueueReplay
#
# 本文件 = LoadQueueReplay 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
# ★本目标进白名单时没有把依据写进 fm_eq.tcl★（拆分时如实记录，不补写）。
# 依据只能到 git log 里找：`git log -SLoadQueueReplay -- scripts/fm_eq.tcl`。

fm_target_vmucp_allow
# ---- 目标专属 appvar（原样搬自 scripts/fm_eq.tcl，未改一字）----
# ★目标专属 appvar：LoadQueueReplay★（2026-09-20，由一次受控重跑定下来的）
#
# 这两项原先藏在 verif/ut/LoadQueueReplay/fm_pins_pre.tcl 里。放在钉点文件里是错的
# （钉点文件只许消名差，`test_fm_pins_wellformed.py` 的 P1 判据就是这条），
# 而且藏在那里没人会去 review 它改了什么。挪到这里，并附上实测依据。
#
# ★依据是一次把它们拿掉的整跑，不是推断★：
#   run #3 @75e1d8be（两项都设，evidence/75e1d8be8148）
#       verdict SUCCEEDED / passing 114160 / failing 0 / unmatched 六项全 0 /
#       Constant reg 0 / constant_reg_toggle_assumed=false
#   run #4 @14cf2a80（两项都不设 = 工具默认，evidence/14cf2a808442）
#       verdict FAILED  / passing 114010 / failing 3 / unmatched.compare_ref 3 /
#       Constant reg 147 / constant_reg_toggle_assumed=true
#   守恒逐位对得上：114010 + 3(failing) + 147(Constant reg) = 114160
#   —— 离开 passing 的 150 个点，147 个落进「不比较」的 Constant reg，3 个变成 failing。
#
# 逐项归因（按 FM 自己打的类别标签，不是猜的）：
#   · verification_assume_reg_init none（默认 Auto）
#     Auto 那一跑 FM 打出 "Constant registers have been identified that were
#     initialized by some objects that were assumed to toggle"，并给出 Constant reg 147。
#     也就是说 Auto 会**基于一个 toggle 假设**把 147 个寄存器判成常数、移出比较集合。
#     设成 none 取消该假设 ⇒ 这 147 个点**真的被比**。★方向是加强：比较点只增不减。★
#   · verification_set_undriven_signals BINARY（默认 binary:X）
#     默认那一跑多出 3 个 ref 侧 unmatched（类别 Und）
#     `_freeList_io_canAllocate_0/1/2`，并直接导致 3 个 BBPin 比较点 failing
#     （`freeList/io_canAllocate_0..2`）。它们是黑盒 FreeList_5 边界上的网线。
#     ☆这一项我只证明了"拿掉会红"，**没有**证明它安全☆：Rob 那次实测过
#     把本 appvar 收窄（设成 0）会遮住"impl 漏驱动"的缺陷；BINARY 同样是收窄
#     （从 binary:X 去掉 X）。我做的三档探针（binary:X / BINARY / 0 × 两种 ref）
#     只显示 BINARY 与 binary:X 在**那个**机制上同行为，
#     **对这里这个"未驱动网线配对"机制没有分辨力** —— 所以遮蔽风险未排除。
#     ★留作缺口：这一项值得一条专门的 appvar lane 按 Rob 的四跑格式重做双向负测。★

fm_target_appvar verification_assume_reg_init none
fm_target_appvar verification_set_undriven_signals BINARY
