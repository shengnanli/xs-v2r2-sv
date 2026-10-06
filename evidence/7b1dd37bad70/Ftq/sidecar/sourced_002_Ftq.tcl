# vmucp 白名单条目：Ftq
#
# 本文件 = Ftq 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# Ftq 加入依据(2026-09-14, agent/ftq 实测)：本目标的 matched-not-compared unread
# 共 3395 点，**全部**是两侧同路径同名的对称死位，严格双射(ref 唯一点 3395 ↔
# impl 唯一点 3395，非 matched_nc 项为 0——ref 侧另有 4282 个 unmatched-unread，
# 那是 golden-only 的 perf/difftest 仪表寄存器，走 verif/dead_ref/Ftq.json 的
# PASS_DEAD_REF 通道，与本加强互不重叠)。3395 点构成：
#   update_target_<0..63>_reg[0..49]        3200  每项最新跳转目标
#   pred_stage_<0..63>_reg[0..1]             128  该项由 BPU 哪一级产生
#   ftq_pd_mem/dataBanks_*/data_*_jalTarget   65  两侧同源 elaborate 的 golden 子模块内部
#   last_cycle_bpu_in_stage_reg[0..1]          2
# 死因：这三族的**唯一**下游是 golden 里已被 firtool 裁掉的 difftest/XSPerf 消费者
# （update_target → diff_commit_target 比较；pred_stage → commit_pred_stage →
#  jalr_correct_stage_map 统计；jalTarget 在 KunminghuV2Config 下无人读），
# 可读核照抄了同一组存储，于是两侧同为死位、逐点同名配对。
# 实开比较的效果(同一份 RTL、同一组 pin，仅切 appvar)：matched_nc 3395 → 0，
# 比对点总数 63056 → 66481(=63056+3395+30 个由 pin 新配上的点)，passing 随之
# 增加、failing 不因这 3395 点新增(诊断跑 failing_point_limit=0 的完整清单里
# 只有 6 个 io_toPrefetch_req_bits_startAddr 位，与本加强无关)。

fm_target_vmucp_allow
