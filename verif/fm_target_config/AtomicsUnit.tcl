# vmucp 白名单条目：AtomicsUnit
#
# 本文件 = AtomicsUnit 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（首跑 evidence/5a3282d30ab1/AtomicsUnit，impl commit 5a3282d3，vmucp 关）----
# signoff-strict native SUCCEEDED：passing 3958 / failing 0 / unmatched compare 0 / 无黑盒 / 无 dont_verify，
# constant_reg 4，unread 62 位 → strict 判 PARTIAL(strict_unread!=0)。62 位按机制分三族，两侧同为 cone-dead：
#   (a) tdata_<j>_tdata2[63:50] × 4 槽 = 56：触发器比较（TriggerCmp）只看 vaddr 低 50 位；golden 与核同为 64 位寄存器。
#       首跑里这 56 位两侧未配（数组名 vs 平铺名），由 verif/ut/AtomicsUnit/fm_pins_pre.tcl 一条规则钉上（4×64 全钉）。
#   (b) dcache_resp_id[5:1] = 5：success 只取 bit0。首跑已 matched_nc。
#   (c) difftest_fuop_r[8] = 1：difftest fuop 只取 [7:0]。首跑已 matched_nc。
# 六条：精确绑定（恰上面 62 位）/ 双射（62 ↔ 62）/ 真比较（passing 3958 → 4020，正好 +62）/
#   全零（failing / unverified / unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 /
#   本文件进 sidecar script_closure，receipt 记 sha256。
# constant_reg 4 是 tdata_<j>_timing（无写入口、只被写 0，两侧次态同为常量），跑前登记"可能出错处 3"已预写，不进比较点。

fm_target_vmucp_allow
