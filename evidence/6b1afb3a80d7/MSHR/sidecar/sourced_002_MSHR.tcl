# vmucp 白名单条目：MSHR（CoupledL2 tl2chi MSHR 表项，agent/mshrctl lane）
#
# 本文件 = MSHR 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/mshrctl，commit ea8f5e84 同 RTL 字节的非正式试跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 1372 / failing 0 / unmatched 0(0)，
#   Not Compared = Constant reg 1 + Unread 69 → strict 判 PARTIAL(strict_unread!=0)。
#   69 个 unread 点全是 matched_nc（两侧同名，FM 按名自动配对，两侧独占 0）：
#     validCnt_reg[0..63]      —— 死锁检测计数，只喂 `ifndef SYNTHESIS` 里的断言（MSHR.scala:1438-1449）
#     REG_reg / REG_1_reg / REG_2_reg / REG_3_reg —— RegNext(evict/wb/wc/weFire)，只喂断言（:1451-1462）
#     state_w_pprobeackfirst_reg —— Scala 只写不读（读的是 w_pprobeacklast）
#   ★为什么是对称死位★：FM 按 SYNTHESIS 读两侧，断言块消失；golden 仍保留这些寄存器，
#   重写核按"寄存器字段逐字照搬"同样保留，同名、同位宽、同一批没有读者的位。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = validCnt[63:0] ∪ {REG, REG_1, REG_2, REG_3, state_w_pprobeackfirst}，恰 69 位。
#   (2) 双射：69 ref <-> 69 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 恰 +69（登记值见 docs/lanes/mshrctl_prereg.md §3）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
