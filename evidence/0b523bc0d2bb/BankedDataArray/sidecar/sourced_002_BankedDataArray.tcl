# vmucp 白名单条目：BankedDataArray
#
# 本文件 = BankedDataArray 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/dcache lane，本 lane 实测）----
#   基线（vmucp 关，assembly，merge_dup 默认，钉点 2336 对（ecc_data_delayed 数据 / 采样使能），非正式试跑，
#   commit 86337753 + 钉点）：native SUCCEEDED / passing 7984 / failing 0 / unmatched compare 0 / 黑盒 64（array_7_ext 两侧各 32）
#   unread = 11 个 matched_nc + 两侧各 2347 个未配对（FM 不给无扇出的点做签名配对）：
#     · 断言寄存器 REG_8 / REG_9 / REG_10、data_banks_0_*/REG（8 个）——11 个 matched_nc，同名；
#     · 各 SRAMTemplate 的 MBIST 回读寄存器 rdataReg[71:0]（32 × 72 = 2304）与其采样使能
#       （golden respReg / 重写共享核 xs_SRAMTemplate_core 里与之同方程、merge_dup 后幸存的 rdata_last_REG，32 个）：
#       BankedDataArray 的 MBIST 回读借用整行读输出寄存器，DataSRAMBank 的 bore_rdata 在 golden 与重写件里都悬空；
#     · MbistPipeDCacheData 的 addrReg[8:0] / addrRdReg[8] / beReg（11 个），同 DuplicatedTagArray 那批 MBIST 死位。
#   后三类由 verif/ut/BankedDataArray/fm_pins_pre.tcl（scripts/gen_bankeddataarray.py 生成，按固定规则逐位钉，
#   fail-closed 计数 4683 = 2336 + 2304 + 32 + 11）钉成 matched，再由 vmucp 真比较。
# ---- 六条证据 ----
#   (1) 精确绑定：unread 集合 = 上述 11 + 2304 + 32 + 11 = 2358 位。
#   (2) 双射：2358 ref <-> 2358 impl，两侧独占 0（钉点单射、逐条 set_user_match 返回 1）。
#   (3) 真比较：passing 相对基线 7984 恰好增加被真比的点数；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：无 dont_verify / elab147 / relaxed appvar；黑盒只有审定过的厂商叶子 array_7_ext ×32。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据见 docs/lanes/dcache_prereg.md 第 4 节（跑前登记的 passing 数字）。

fm_target_vmucp_allow
