# vmucp 白名单条目：StreamBitVectorArray
#
# 本文件 = StreamBitVectorArray 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/mmuleaf lane) ----
#   关 vmucp 的诊断跑(diagnostic-full，不出证，commit cfd0ad0d)：native SUCCEEDED passing 1475 /
#   failing 0 / unmatched 全 0 / constant_reg 16，unread 319 全部是 matched_nc（两侧按钉点一一配上、
#   都没有读者），没有 unmatched unread。319 位分五族，全部由 golden 自身结构决定、重写核逐一照抄：
#     (a) array_<i>_tag[39:25] 16 x 15 = 240 位：区域哈希只看 tag 的低 25 位，表项却存满 40 位；
#     (b) s1_lookup_tag[39:25] 15 位：同理，stride 查询的 CAM 也只比哈希；
#     (c) s2_region_tag 40 位：只喂 hash_conflict 性能计数器（综合口径下计数器被删）；
#     (d) s2_pf_l{1,2,3}_incr_vaddr[5:0] 3 x 6 = 18 位：预取地址补的 6 位行内偏移，恒 0、无读者
#         （预取请求只取 [49:10] 作 region、[9:6] 作行号）；
#     (e) REG(1) / r(1) / r_1(4) = 6 位：断言 "replacement error" 专用的 RegNext(s0_valid) /
#         RegEnable(s0_hit) / RegEnable(replacement.way)，综合口径下断言被删。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面五族恰好 319 位(240 + 15 + 40 + 18 + 6)。
#   (2) 双射：319 ref <-> 319 impl，全部由 verif/ut/StreamBitVectorArray/fm_pins_pre.tcl 钉成对
#       （生成器 scripts/gen_mmuleaf.py，golden 顶层寄存器 1692 位逐位、字面计数、fail-closed）。
#   (3) 真比较：开 vmucp 后 passing 应为 1475 + 319 = 1794 = 模型 1810 - constant_reg 16
#       (16 = last_REG / last_REG_1..15，每项一份 RegNext(io.flush)，flush 在本配置恒 0)。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；golden 0 child，无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
