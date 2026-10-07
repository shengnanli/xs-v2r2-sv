# vmucp 白名单条目：Predictor
#
# 本文件 = Predictor 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   Predictor(2026-09-17 加): 8333 个 unread 点全是两侧对称 matched_nc，其中
#          7169 个在 golden Composer 实例 predictors 子树里(两侧是**同一份**
#          Composer.sv，TAGE/ITTAGE/FTB 的 io_update_ghist_r / update_meta_r 等
#          更新通路寄存器天然逐位同构)，1164 个在 u_core 里
#          (pred_cycle_q 576 / s*_folded_gh 464 / s*_afhob 60 / s*_ghist_ptr 12 /
#          power_on_reset_state 1 —— 这 1113 个由 verif/ut/Predictor/fm_pins_pre.tcl
#          逐位钉死；外加 prev_s2 50 + upc_seg2 1 是 FM 自己按名字配上的)。
#          impl 侧单边未读 585 个不受本开关影响(无对家, 属 PASS_DEAD_IMPL 范畴)。
#          ★复核判据★: passing 520634 -> 528967(正好 +8333)、failing 仍 0、
#          unread 归 0、unmatched 0(0)。passing 不增而 unread 归 0 = 点被吞掉, 不算过。

fm_target_vmucp_allow
