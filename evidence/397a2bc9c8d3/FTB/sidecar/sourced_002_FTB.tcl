# vmucp 白名单条目：FTB
#
# 本文件 = FTB 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（跑前登记见 docs/lanes/fe-mem-misc-ftb_prereg.md）----
# 两侧同为死位（matched_nc），全部按 fm_pins_pre.tcl 逐位一一配对（双射），来源：
#   (a) FTB 本层：update_meta_r 存满 516 位、只读 [66:64]（FTBMeta 的 writeWay/hit）；
#       REG / REG_1（s0_fire 打一拍，只喂 perf 探针 ftb_read_hits/misses）。
#   (b) 子模块 delay2_pc_pipMod：两级 50 位 PC 打拍，写 FTB 只用 pc[29:1]，其余位零扇出。
#   (c) 子模块 ftbBank 内部的对称死位（与 FTBBank 自己签核时同一批，见 FTBBank.tcl）。
# 判据（standing rule 六条）：精确绑定/双射（钉点 fail-closed 计数）、开 vmucp 后 passing
# 正好增加 unread_notcompared 数、failing/unverified/unmatched 全零、无 dont_verify 无新黑盒、
# 本文件进 sidecar/script_closure.list。golden-only 死位（ftbBank 的 4 份断言专用 req_pc_reg*）
# 不在此列，走 verif/dead_ref/FTB.json。
fm_target_vmucp_allow
