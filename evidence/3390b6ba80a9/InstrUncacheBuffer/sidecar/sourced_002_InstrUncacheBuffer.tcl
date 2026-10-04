# vmucp 白名单条目：InstrUncacheBuffer
#
# ---- 加入依据（2026-10-04，agent/frontend-asm lane，commit efac4c05 字节上的 diagnostic-full 试跑，vmucp 关）----
#   native SUCCEEDED passing 612 / failing 0 / unmatched 0(0) / constant_reg 83，
#   Not Compared = Unread 277 对，全部 matched_nc，两侧路径逐字相同（<实例>/ram_ext/Memory_reg[e][b]）。
#   为什么是对称死位：A 通道第二级出口的 opcode/size/source/mask/data 被 Scala 在缓冲之后重新钉成常量（端口删除），这些字段在两级 ram 里写入却无人读；D 通道两级的 opcode/param/size/sink/denied 也不引出（InstrUncache 只读 source/data/corrupt）。第一级 A 的部分位因入口常量被判 constant_reg，故 A 第一级只剩 1 项计入。
#   两侧子模块都是 Queue2_TLBundle*（ref golden / impl 已签重写件 rtl/uncore），ram 是同一份 golden
#   行为级叶子 ram_2xN 两侧同源 inline；这些位写进去但出口无人读，两侧一模一样。配对是 FM 自己按
#   路径配上的，没有任何 set_user_match。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上述 ram 字段位，恰好 277 位，均 matched_nc。
#   (2) 双射：277 ref <-> 277 impl matched，两侧独占 0。
#   (3) 真比较：passing 612 -> 889，正好 +277；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 889、unread 归 0、unmatched 全零、constant_reg 83。

fm_target_vmucp_allow
