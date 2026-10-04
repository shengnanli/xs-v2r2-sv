# vmucp 白名单条目：ICache
#
# 本文件 = ICache 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-03，agent/fe-mem-misc）----
#   ICache 8 个子模块两侧白盒（impl 读重写件直到厂商宏）。lane 内诊断跑（merge_dup 默认，未钉 missUnit）：
#   unread 两类，全是两侧对称死位：
#   (a) matched_nc 197 位（按名配上）—— 各子模块单独签核时 vmucp 集合在父级的再现（MainPipe / IPrefetchPipe /
#       MetaArray / DataArray 的 MBIST addrReg 高位、打拍寄存器的零扇出切片等）；
#   (b) 两侧各 33 位未配上（零扇出、名字不同）：DataArray 32 块 SRAM 读保持寄存器补位 [65]
#       + missUnit 断言专用计数器 refill_done_r_counter / grant_beat_left_q；
#       由 scripts/gen_icache_pins.py 生成的 verif/ut/ICache/fm_pins.tcl 一一钉上（字面 33，fail-closed）。
#   missUnit 的 MSHR blkPaddr / vSetIdx 与优先级 FIFO regFiles（740 位）由 fm_pins_pre.tcl 钉（活位，消名差）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = (a) 197 ∪ (b) 33 = 230 位（钉点生效后以正式跑 receipt 为准）。
#   (2) 双射：(a) 按名配上，(b) 钉点字面 33，拒一条即 error。
#   (3) 真比较：开 vmucp 后 unread 归零、passing 增加恰为 unread 位数。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/ICache.json
#       声明的厂商宏叶子 array_ext / array_0_ext（vendor_macro，两侧各 36）。
#   (6) 摘要：本文件与两个钉点文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
