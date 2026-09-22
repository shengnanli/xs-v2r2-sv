# vmucp 白名单条目：PTW
#
# 本文件 = PTW 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（跑前预登记，2026-09-22）----
# golden PTW.sv 里 perf 事件 mem_cycle 的 BoolStopWatch 被 firtool 留了**两份**同样的
# 寄存器：`perfEvents_5_2`（喂 io_perf_5_value 的两拍打拍链）与 `r`（只接到一根悬空的
# `wire r_probe = r;`，任何输出锥都不含它）。二者次态方程逐字相同：
#     <= perfEvents_4_2_probe | ~io_mem_resp_valid & <自身>      （PTW.sv:1441-1442）
# 可读核 rtl/mmu/PTW.sv 照抄两份：mem_cycle_watch（喂 perf_5）与 mem_cycle_watch_probe
# （无人读）。于是两侧各恰有 **1 个** matched-unread 点：
#     r:/WORK/PTW/r_reg  <->  i:/WORK/PTW/u_core/mem_cycle_watch_probe_reg
# 双射为 1↔1，非 matched_nc 的 unread 项预期为 0，无人工强配。打开 vmucp 后 FM 会把这一点
# 也证一遍（passing 应比关着时多 1），这是加强而不是放松。
# 复核判据（跑后对账）：receipt.native_facts.objects.matched_unread_notcompared_pairs 为空、
# unmatched.unread_ref == unmatched.unread_impl == 0、passing == fm_predict 登记数减 constant_reg。

fm_target_vmucp_allow
