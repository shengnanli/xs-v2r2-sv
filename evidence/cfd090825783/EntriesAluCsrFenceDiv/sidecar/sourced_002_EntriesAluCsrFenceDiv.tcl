# vmucp 白名单条目：EntriesAluCsrFenceDiv
#
# 本文件 = EntriesAluCsrFenceDiv 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   EntriesAluCsrFenceDiv(2026-09-17 加，canary): 6220 个 unread 点**全部是 matched_nc**
#          （unread_points.txt 6220 行逐行核过，未配对未读点为 0 —— FM 连那一行都没打印）。
#          构成 = 8 条目（2 enq + 6 simp）× 776 位死负载 + 12 个 enqDelay 影子位。
#          ★顺序★：钉点在先、加强在后。本轮先补了 24 个 enqDelay srcLoadDependency
#          钉点把 12(12) unmatched unread 打成 0(0)，否则按 TLBFA 的实测
#          （unmatched unread 单开 vmucp 必然空转）这一轮会白跑。
#          配对按构造：6220/6220 全部是 20308 对钉点的子集，**FM 自行猜配 0 对**；
#          钉点由 gen_fm_pins.py 从 golden 实例连线机械提取，不是人工列表。
#          ☆一个读数陷阱，lane 查清后才敢写期望值☆：结果表里
#          `Constant reg 12` 与 `Unread 6220` 是**两行**、合计 6232，而 vmucp 只清 6220；
#          那 12 个常量寄存器留着**不拦 verdict**（fm_verdict.py 的 strict PARTIAL 判据
#          只看 unverified/unmatched/aborted/unread 四项）。所以期望值是 +6220 不是 +6232。
#          ★复核判据★: passing 18781 -> 25001（正好 +6220）、failing 仍 0、unread 归 0、
#          unmatched 保持全零。passing 不增即空转，不算过。
#          同族先例见上面的 EntriesVfdivVidiv 条目；本条的数字全部是 canary 自己实测的。

fm_target_vmucp_allow
