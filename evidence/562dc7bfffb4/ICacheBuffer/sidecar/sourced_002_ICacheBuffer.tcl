# vmucp 白名单条目：ICacheBuffer
#
# ---- 加入依据（2026-10-04，agent/frontend-asm lane，commit efac4c05 字节上的 diagnostic-full 试跑，vmucp 关）----
#   native SUCCEEDED passing 2844 / failing 0 / unmatched 0(0) / constant_reg 307，
#   Not Compared = Unread 52 对，全部 matched_nc，两侧路径逐字相同（<实例>/ram_ext/Memory_reg[e][b]）。
#   为什么是对称死位：D 通道两级 Queue2 的 param[5:4] / sink[23:14] 字段（ICache 侧 D 口不引出 param/sink，第二级出口悬空；第一级的这几位只喂第二级的同名死位）。2 级 × 2 项 × 13 位 = 52。
#   两侧子模块都是 Queue2_TLBundle*（ref golden / impl 已签重写件 rtl/uncore），ram 是同一份 golden
#   行为级叶子 ram_2xN 两侧同源 inline；这些位写进去但出口无人读，两侧一模一样。配对是 FM 自己按
#   路径配上的，没有任何 set_user_match。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上述 ram 字段位，恰好 52 位，均 matched_nc。
#   (2) 双射：52 ref <-> 52 impl matched，两侧独占 0。
#   (3) 真比较：passing 2844 -> 2896，正好 +52；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 2896、unread 归 0、unmatched 全零、constant_reg 307。

fm_target_vmucp_allow
