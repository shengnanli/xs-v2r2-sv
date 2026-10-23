# vmucp 白名单条目：ICacheCtrlBuffer
#
# ---- 加入依据（2026-10-04，agent/frontend-asm lane，commit efac4c05 字节上的 diagnostic-full 试跑，vmucp 关）----
#   native SUCCEEDED passing 976 / failing 0 / unmatched 0(0) / constant_reg 5，
#   Not Compared = Unread 16 对，全部 matched_nc，两侧路径逐字相同（<实例>/ram_ext/Memory_reg[e][b]）。
#   为什么是对称死位：A 通道两级 Queue2 的 param[6:4] / corrupt[116] 字段（ICacheCtrlUnit 的 A 口不引出 param/corrupt）。2 级 × 2 项 × 4 位 = 16。
#   两侧子模块都是 Queue2_TLBundle*（ref golden / impl 已签重写件 rtl/uncore），ram 是同一份 golden
#   行为级叶子 ram_2xN 两侧同源 inline；这些位写进去但出口无人读，两侧一模一样。配对是 FM 自己按
#   路径配上的，没有任何 set_user_match。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上述 ram 字段位，恰好 16 位，均 matched_nc。
#   (2) 双射：16 ref <-> 16 impl matched，两侧独占 0。
#   (3) 真比较：passing 976 -> 992，正好 +16；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 992、unread 归 0、unmatched 全零、constant_reg 5。

fm_target_vmucp_allow
